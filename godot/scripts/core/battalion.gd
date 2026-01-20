class_name Battalion
extends Node2D

enum Type { ASSAULT, DEFENSE, CONTROL, AIR_DEFENSE }
enum State { DEPLOYING, ACTIVE, WITHDRAWING }

signal strength_changed(active: int, reserves: int)
signal battalion_destroyed

@export var battalion_type: Type = Type.ASSAULT
@export var team_id := "p1"

var target_position := Vector2.ZERO
var state: State = State.DEPLOYING

var active_units: Array[Unit] = []
var reserve_count: int = GameBalance.BATTALION_RESERVE_SIZE

var _reinforce_timer := 0.0
var _pending_reinforcements := 0
var _facing := Vector2.RIGHT
var _spawn_controller: Node = null
var _barracks: Node2D = null


func _ready() -> void:
	_facing = (target_position - global_position).normalized()
	if _facing.length_squared() < 0.01:
		_facing = Vector2.RIGHT


func setup(spawn_ctrl: Node, barracks: Node2D) -> void:
	_spawn_controller = spawn_ctrl
	_barracks = barracks


func spawn_initial_units() -> void:
	if not _spawn_controller:
		push_error("Battalion: No spawn controller set")
		return

	var positions: Array[Vector2] = BattalionFormation.get_positions(battalion_type, target_position, _facing)

	for i: int in range(mini(positions.size(), GameBalance.BATTALION_ACTIVE_SIZE)):
		var unit: Unit = _spawn_unit_at_slot(i, positions[i])
		if unit:
			active_units.append(unit)

	strength_changed.emit(active_units.size(), reserve_count)


func _spawn_unit_at_slot(slot: int, formation_pos: Vector2) -> Unit:
	if not _spawn_controller or not _barracks:
		return null

	var unit_type: String = _get_unit_type_for_slot(slot)
	var unit: Unit = _spawn_controller.spawn_battalion_unit(team_id, unit_type, _barracks.global_position)

	if unit:
		unit.set_meta("battalion", self)
		unit.set_meta("formation_slot", slot)
		unit.set_meta("formation_target", formation_pos)
		unit.set_meta("battalion_type", battalion_type)
		unit.tree_exiting.connect(_on_unit_died.bind(unit))

	return unit


func _get_unit_type_for_slot(slot: int) -> String:
	# For 8-unit squads, distribute types appropriately
	match battalion_type:
		Type.ASSAULT:
			# 5 rifle, 2 rocket, 1 sniper
			if slot < 5:
				return "rifle"
			elif slot < 7:
				return "rocket"
			else:
				return "sniper"
		Type.DEFENSE:
			# 4 rifle, 3 rocket, 1 sniper
			if slot < 4:
				return "rifle"
			elif slot < 7:
				return "rocket"
			else:
				return "sniper"
		Type.CONTROL:
			# 6 rifle, 2 sniper (no rockets - patrol focus)
			if slot < 6:
				return "rifle"
			else:
				return "sniper"
		Type.AIR_DEFENSE:
			# 3 rifle, 5 rocket (heavy AA focus)
			if slot < 3:
				return "rifle"
			else:
				return "rocket"
	return "rifle"


func _on_unit_died(unit: Unit) -> void:
	var idx: int = active_units.find(unit)
	if idx >= 0:
		active_units.remove_at(idx)

	if reserve_count > 0:
		reserve_count -= 1
		_pending_reinforcements += 1

	strength_changed.emit(active_units.size(), reserve_count)

	if active_units.is_empty() and reserve_count <= 0 and _pending_reinforcements <= 0:
		battalion_destroyed.emit()
		queue_free()


func _process(delta: float) -> void:
	_update_facing()
	_process_reinforcements(delta)
	_process_state(delta)


func _update_facing() -> void:
	var new_facing := _facing
	var nearest_enemy: Node2D = _find_nearest_enemy()
	if nearest_enemy:
		var center: Vector2 = _get_center()
		new_facing = (nearest_enemy.global_position - center).normalized()
	elif state == State.DEPLOYING or state == State.ACTIVE:
		var center2: Vector2 = _get_center()
		if center2.distance_squared_to(target_position) > 100:
			new_facing = (target_position - center2).normalized()

	# Only update facing if the angle change is significant (> 10 degrees)
	# This prevents constant micro-adjustments that cause units to never settle
	var angle_diff := absf(_facing.angle_to(new_facing))
	if angle_diff > 0.175:  # ~10 degrees in radians
		_facing = new_facing


func _find_nearest_enemy() -> Node2D:
	var enemy_team: String = "p2" if team_id == "p1" else "p1"
	var enemies: Array[Node] = get_tree().get_nodes_in_group(enemy_team + "_units")

	var center: Vector2 = _get_center()
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy: Node in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node: Node2D = enemy as Node2D
		if enemy_node == null:
			continue
		var dist: float = center.distance_squared_to(enemy_node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy_node

	return nearest


func _get_center() -> Vector2:
	if active_units.is_empty():
		return target_position

	var sum := Vector2.ZERO
	var count: int = 0
	for unit: Unit in active_units:
		if is_instance_valid(unit):
			sum += unit.global_position
			count += 1

	return sum / maxf(count, 1)


func _process_reinforcements(delta: float) -> void:
	if _pending_reinforcements <= 0:
		return

	_reinforce_timer -= delta
	if _reinforce_timer <= 0.0:
		_reinforce_timer = GameBalance.BATTALION_REINFORCE_DELAY
		_spawn_reinforcement()


func _spawn_reinforcement() -> void:
	if _pending_reinforcements <= 0:
		return

	_pending_reinforcements -= 1

	var slot: int = active_units.size()
	var positions: Array[Vector2] = BattalionFormation.get_positions(battalion_type, target_position, _facing)

	if slot < positions.size():
		var unit: Unit = _spawn_unit_at_slot(slot, positions[slot])
		if unit:
			active_units.append(unit)
			strength_changed.emit(active_units.size(), reserve_count)


func _process_state(_delta: float) -> void:
	match state:
		State.DEPLOYING:
			_update_formation_targets()
			if _formation_settled():
				state = State.ACTIVE
		State.ACTIVE:
			_update_formation_targets()
		State.WITHDRAWING:
			_update_withdraw_targets()
			if _is_safe():
				state = State.ACTIVE


func _update_formation_targets() -> void:
	var positions: Array[Vector2] = BattalionFormation.get_positions(battalion_type, target_position, _facing)

	for i: int in range(active_units.size()):
		var unit: Unit = active_units[i]
		if is_instance_valid(unit) and i < positions.size():
			unit.set_meta("formation_target", positions[i])


func _update_withdraw_targets() -> void:
	var nearest_enemy: Node2D = _find_nearest_enemy()
	if not nearest_enemy:
		return

	var center: Vector2 = _get_center()
	var retreat_dir: Vector2 = (center - nearest_enemy.global_position).normalized()
	var retreat_target: Vector2 = center + retreat_dir * 100.0

	for unit: Unit in active_units:
		if is_instance_valid(unit):
			unit.set_meta("formation_target", retreat_target + Vector2(randf_range(-30, 30), randf_range(-30, 30)))


func _formation_settled() -> bool:
	var settled_count: int = 0
	for unit: Unit in active_units:
		if not is_instance_valid(unit):
			continue
		var target_pos: Vector2 = unit.get_meta("formation_target", unit.global_position)
		if unit.global_position.distance_squared_to(target_pos) < 400:
			settled_count += 1

	return settled_count >= active_units.size() * 0.7


func _is_safe() -> bool:
	var nearest: Node2D = _find_nearest_enemy()
	if not nearest:
		return true
	var center: Vector2 = _get_center()
	return center.distance_to(nearest.global_position) > GameBalance.BATTALION_WITHDRAW_SAFE_DISTANCE


func withdraw() -> void:
	state = State.WITHDRAWING


func get_strength() -> Dictionary:
	return {
		"active": active_units.size(),
		"reserves": reserve_count,
		"max": GameBalance.BATTALION_ACTIVE_SIZE
	}


func get_battalion_name() -> String:
	match battalion_type:
		Type.ASSAULT:
			return "Assault Battalion"
		Type.DEFENSE:
			return "Defense Battalion"
		Type.CONTROL:
			return "Control Battalion"
		Type.AIR_DEFENSE:
			return "Air Defense Battalion"
	return "Battalion"


func get_state_name() -> String:
	match state:
		State.DEPLOYING:
			return "Deploying"
		State.ACTIVE:
			return "Active"
		State.WITHDRAWING:
			return "Withdrawing"
	return "Unknown"


func get_cost() -> int:
	match battalion_type:
		Type.ASSAULT:
			return GameBalance.ASSAULT_BATTALION_COST
		Type.DEFENSE:
			return GameBalance.DEFENSE_BATTALION_COST
		Type.CONTROL:
			return GameBalance.CONTROL_BATTALION_COST
		Type.AIR_DEFENSE:
			return GameBalance.AIR_DEFENSE_BATTALION_COST
	return 0


static func get_cost_for_type(type: Type) -> int:
	match type:
		Type.ASSAULT:
			return GameBalance.ASSAULT_BATTALION_COST
		Type.DEFENSE:
			return GameBalance.DEFENSE_BATTALION_COST
		Type.CONTROL:
			return GameBalance.CONTROL_BATTALION_COST
		Type.AIR_DEFENSE:
			return GameBalance.AIR_DEFENSE_BATTALION_COST
	return 0
