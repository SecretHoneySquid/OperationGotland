class_name Unit
extends Node2D

signal shot_fired(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, lifetime: float)

@export var team_id := "p1"
@export var color := Color(0.2, 0.5, 1.0, 1.0):
	set(value):
		color = value
		_update_visual_color()
		queue_redraw()

@export var speed := 90.0
@export var max_hp := 30.0
@export var attack_damage := 6.0
@export var attack_range := 26.0
@export var aggro_range := 220.0
@export var chase_leash := 320.0
@export var attack_cooldown := 0.6
@export var body_radius := 8.0
@export var structure_aggro_range := 260.0
@export var shot_tracer_enabled := true
@export var shot_color := Color(1.0, 1.0, 1.0, 0.7)
@export var shot_width := 2.0
@export var shot_lifetime := 0.12
@export var vision_radius := 220.0
@export var range_role := "short"
@export var range_multiplier := 1.0
@export var unit_type := "rifle"
@export var prefers_vehicle := false
@export var prefers_infantry := false
@export var damage_vs_infantry := 1.0
@export var damage_vs_vehicle := 1.0
@export var damage_vs_structure := 1.0
@export var combat_spread_enabled := true
@export var combat_spread_radius := 24.0
@export var combat_spread_min_interval := 0.6
@export var combat_spread_max_interval := 1.2
@export var visual_scene_path := ""
@export var visual_base_radius := 10.0
@export var visual_offset := Vector2.ZERO
@export var render_2d := true

var hp := 0.0
var unit_kind := "infantry"
var home_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var rally_target := Vector2.ZERO
var _reached_rally := false
var manual_target := Vector2.ZERO
var manual_active := false
var is_selected := false
var enemy_hq: HQ
var _cooldown := 0.0
var _facing := Vector2.RIGHT
var _chase_target: Node2D
var _structure_target: Node2D
var _combat_offset := Vector2.ZERO
var _combat_timer := 0.0
var _combat_rng := RandomNumberGenerator.new()
var _hold_active := false
var _hold_timer := 0.0
var _hold_pos := Vector2.ZERO
var _hold_reached := false
var _visual_node: Node2D

func _ready() -> void:
	hp = max_hp
	add_to_group("units")
	add_to_group("units_%s" % team_id)
	GameState.unit_count += 1
	_combat_rng.randomize()
	if team_id == "p1" and vision_radius > 0.0:
		add_to_group("vision_p1")
		var light := VisionHelper.create_light(vision_radius)
		add_child(light)
	_setup_visual()

func _exit_tree() -> void:
	GameState.unit_count = maxi(0, GameState.unit_count - 1)

func take_damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		queue_free()

func get_vision_radius() -> float:
	return vision_radius

func _process(delta: float) -> void:
	if hp <= 0.0:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	_update_hold(delta)
	if not manual_active and not _hold_active:
		_update_chase_target()
		_update_structure_target()
	if not manual_active:
		_update_combat_spread(delta)
	var target := _find_attack_target()
	if target != null:
		_face_toward(target.global_position)
		_attack(target)
	else:
		_move_toward_target(delta)
	_sync_visual_rotation()

func _draw() -> void:
	if not render_2d:
		return
	if _visual_node == null:
		var angle := _facing.angle()
		var base_color := color
		var scale := body_radius / (10.0 if unit_kind == "vehicle" else 8.0)
		var hull := _get_hull_points()
		var shadow_color := Color(0.0, 0.0, 0.0, 0.22)
		draw_circle(Vector2(2.0, 3.0), body_radius * 0.95, shadow_color)
		var base_points := _transform_points(hull, angle, scale)
		var top_points := _transform_points(hull, angle, scale * 0.7, Vector2(-1.0, -1.0))
		draw_colored_polygon(base_points, _shade(base_color, -0.12))
		draw_colored_polygon(top_points, _shade(base_color, 0.12))
		var outline := base_points.duplicate()
		if outline.size() > 0:
			outline.append(base_points[0])
			draw_polyline(outline, _shade(base_color, -0.35), 1.5)
		if unit_kind == "vehicle":
			_draw_vehicle_details(angle, base_color)
		else:
			_draw_infantry_details(angle, base_color)
	if is_selected:
		draw_circle(Vector2.ZERO, body_radius + 5.0, Color(0.2, 0.9, 1.0, 0.6), false, 2.0)

func set_render_2d(value: bool) -> void:
	render_2d = value
	_set_canvas_children_visible(value)
	queue_redraw()

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("Unit: missing visual scene at %s" % visual_scene_path)
		return
	if packed is PackedScene:
		var instance = packed.instantiate()
		if instance is Node2D:
			_visual_node = instance
			add_child(_visual_node)
			_visual_node.visible = render_2d
			_update_visual_transform()
			_update_visual_color()
	else:
		push_warning("Unit: visual scene is not a PackedScene at %s" % visual_scene_path)

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	_visual_node.position = visual_offset
	if visual_base_radius > 0.0:
		var scale := body_radius / visual_base_radius
		_visual_node.scale = Vector2.ONE * scale

func _update_visual_color() -> void:
	if _visual_node == null:
		return
	_visual_node.modulate = color

func _sync_visual_rotation() -> void:
	if _visual_node == null:
		return
	_visual_node.rotation = _facing.angle()

func _set_canvas_children_visible(value: bool) -> void:
	for child in get_children():
		if child is CanvasItem:
			child.visible = value

func _face_toward(pos: Vector2) -> void:
	var delta_vec := pos - global_position
	if delta_vec.length_squared() <= 0.1:
		return
	_facing = delta_vec.normalized()

func _shade(src: Color, amount: float) -> Color:
	return Color(
		clampf(src.r + amount, 0.0, 1.0),
		clampf(src.g + amount, 0.0, 1.0),
		clampf(src.b + amount, 0.0, 1.0),
		src.a
	)

func _transform_points(points: Array, angle: float, scale: float, offset := Vector2.ZERO) -> PackedVector2Array:
	var transformed := PackedVector2Array()
	for point in points:
		if point is Vector2:
			transformed.append((point * scale).rotated(angle) + offset)
	return transformed

func _get_hull_points() -> Array:
	if unit_kind == "vehicle":
		return [
			Vector2(11, 0),
			Vector2(7, -6),
			Vector2(-7, -6),
			Vector2(-11, 0),
			Vector2(-7, 6),
			Vector2(7, 6),
		]
	return [
		Vector2(8, 0),
		Vector2(3, -5),
		Vector2(-6, -4),
		Vector2(-8, 0),
		Vector2(-6, 4),
		Vector2(3, 5),
	]

func _draw_infantry_details(angle: float, base_color: Color) -> void:
	var weapon_len := body_radius * 0.9
	var weapon_width := 2.0
	if unit_type == "sniper":
		weapon_len = body_radius * 1.35
		weapon_width = 2.0
	elif unit_type == "rocket":
		weapon_len = body_radius * 1.05
		weapon_width = 3.0
	var weapon_color := _shade(base_color, 0.35)
	draw_line(Vector2.ZERO, Vector2(weapon_len, 0.0).rotated(angle), weapon_color, weapon_width)

func _draw_vehicle_details(angle: float, base_color: Color) -> void:
	var turret_radius := body_radius * 0.35
	var turret_color := _shade(base_color, 0.2)
	draw_circle(Vector2.ZERO, turret_radius, turret_color)
	draw_line(Vector2.ZERO, Vector2(body_radius * 0.9, 0.0).rotated(angle), _shade(base_color, 0.4), 2.5)
	var track_offset := Vector2(0.0, body_radius * 0.55).rotated(angle)
	var track_half := Vector2(body_radius * 0.7, 0.0).rotated(angle)
	draw_line(-track_offset - track_half, -track_offset + track_half, _shade(base_color, -0.25), 1.5)
	draw_line(track_offset - track_half, track_offset + track_half, _shade(base_color, -0.25), 1.5)

func _find_attack_target() -> Node2D:
	var unit_target := _find_enemy_unit_in_range(attack_range)
	if unit_target != null:
		return unit_target
	var structure_target := _find_enemy_structure_in_range(attack_range)
	if structure_target != null:
		return structure_target
	return null

func _find_enemy_unit_in_range(range: float) -> Node2D:
	var range_sq := range * range
	var best_target: Unit = null
	var best_priority := 999
	var best_dist := range_sq
	var best_hp := INF
	for node in get_tree().get_nodes_in_group("units"):
		if node == self:
			continue
		var enemy := node as Unit
		if enemy == null or enemy.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist > range_sq:
			continue
		var priority := _target_priority(enemy)
		var enemy_hp := enemy.hp
		if (
			priority < best_priority
			or (priority == best_priority and enemy_hp < best_hp)
			or (priority == best_priority and enemy_hp == best_hp and dist < best_dist)
		):
			best_priority = priority
			best_dist = dist
			best_hp = enemy_hp
			best_target = enemy
	return best_target

func _find_enemy_structure_in_range(range: float) -> Node2D:
	var range_sq := range * range
	var best_target: Node2D = null
	var best_dist := range_sq
	for node in get_tree().get_nodes_in_group("building"):
		if not (node is Building):
			continue
		if node.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(node.global_position)
		if dist <= best_dist:
			best_dist = dist
			best_target = node
	for node in get_tree().get_nodes_in_group("hq"):
		if not (node is HQ):
			continue
		if node.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(node.global_position)
		if dist <= best_dist:
			best_dist = dist
			best_target = node
	return best_target

func _attack(target: Node) -> void:
	if _cooldown > 0.0:
		return
	if target.has_method("take_damage"):
		var final_damage := attack_damage
		if target is Unit:
			var enemy := target as Unit
			if enemy.unit_kind == "vehicle":
				final_damage *= damage_vs_vehicle
			else:
				final_damage *= damage_vs_infantry
		elif target is Building or target is HQ:
			final_damage *= damage_vs_structure
		target.take_damage(final_damage)
	if shot_tracer_enabled and target is Node2D:
		var target_pos: Vector2 = (target as Node2D).global_position
		_spawn_tracer(target_pos)
		emit_signal("shot_fired", global_position, target_pos, shot_color, shot_width, shot_lifetime)
	_cooldown = attack_cooldown

func _spawn_tracer(target_pos: Vector2) -> void:
	var tracer := ShotTracer.new()
	tracer.duration = shot_lifetime
	tracer.width = shot_width
	tracer.color = shot_color
	tracer.set_points(global_position, target_pos)
	if get_parent() != null:
		get_parent().add_child(tracer)

func _move_toward_target(delta: float) -> void:
	var target := _resolve_target()
	if target == Vector2.ZERO:
		return
	var delta_vec := target - global_position
	if delta_vec.length() <= 1.0:
		if _hold_active:
			_hold_reached = true
			return
		if manual_active:
			manual_active = false
			manual_target = Vector2.ZERO
		elif not _reached_rally and rally_target != Vector2.ZERO:
			_reached_rally = true
			rally_target = Vector2.ZERO
		return
	var direction := delta_vec.normalized()
	global_position += direction * speed * delta
	_facing = direction

func _resolve_target() -> Vector2:
	if manual_active and manual_target != Vector2.ZERO:
		return manual_target
	if _hold_active:
		return _hold_pos
	var target := Vector2.ZERO
	if _chase_target != null and is_instance_valid(_chase_target):
		target = _chase_target.global_position
	elif _structure_target != null and is_instance_valid(_structure_target):
		target = _structure_target.global_position
	elif not _reached_rally and rally_target != Vector2.ZERO:
		target = rally_target
	elif enemy_hq != null and is_instance_valid(enemy_hq):
		target = enemy_hq.global_position
	else:
		target = target_pos
	if _is_combat_active() and _combat_offset != Vector2.ZERO:
		return target + _combat_offset
	return target

func issue_move(target: Vector2) -> void:
	manual_target = target
	manual_active = true
	_hold_active = false
	_hold_timer = 0.0
	_hold_pos = Vector2.ZERO
	_hold_reached = false
	_chase_target = null

func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

func _update_chase_target() -> void:
	if _chase_target != null:
		if not is_instance_valid(_chase_target):
			_chase_target = null
		else:
			var dist := global_position.distance_to(_chase_target.global_position)
			if dist > chase_leash:
				_chase_target = null
	if _chase_target == null:
		_chase_target = _find_enemy_in_aggro()

func _update_structure_target() -> void:
	if _chase_target != null and is_instance_valid(_chase_target):
		_structure_target = null
		return
	if structure_aggro_range <= 0.0:
		_structure_target = null
		return
	if _structure_target != null:
		if not is_instance_valid(_structure_target):
			_structure_target = null
		else:
			var dist := global_position.distance_to(_structure_target.global_position)
			if dist > structure_aggro_range:
				_structure_target = null
	if _structure_target == null:
		_structure_target = _find_enemy_structure_in_range(structure_aggro_range)

func _find_enemy_in_aggro() -> Node2D:
	return _find_enemy_unit_in_range(aggro_range)

func _target_priority(enemy: Unit) -> int:
	var priority := 0
	if range_role == "long":
		if enemy.range_role == "short":
			priority = 1
		elif enemy.range_role == "mid":
			priority = 2
		else:
			priority = 0
	if prefers_vehicle and enemy.unit_kind == "vehicle":
		priority -= 2
	if prefers_infantry and enemy.unit_kind == "infantry":
		priority -= 2
	return priority

func _update_combat_spread(delta: float) -> void:
	if not combat_spread_enabled:
		_combat_offset = Vector2.ZERO
		_combat_timer = 0.0
		return
	if not _is_combat_active():
		_combat_offset = Vector2.ZERO
		_combat_timer = 0.0
		return
	_combat_timer -= delta
	if _combat_timer > 0.0:
		return
	var max_radius := _get_combat_spread_radius()
	var angle := _combat_rng.randf_range(0.0, TAU)
	var radius := sqrt(_combat_rng.randf()) * max_radius
	_combat_offset = Vector2(cos(angle), sin(angle)) * radius
	_combat_timer = _combat_rng.randf_range(combat_spread_min_interval, combat_spread_max_interval)

func _get_combat_spread_radius() -> float:
	var scaled := combat_spread_radius * sqrt(maxf(1.0, range_multiplier))
	var cap := maxf(12.0, attack_range * 0.6)
	return minf(scaled, cap)

func _is_combat_active() -> bool:
	if manual_active:
		return false
	if _chase_target != null and is_instance_valid(_chase_target):
		return true
	if _structure_target != null and is_instance_valid(_structure_target):
		return true
	return false

func assign_hold(pos: Vector2, duration: float) -> void:
	_hold_active = true
	_hold_timer = duration
	_hold_pos = pos
	_hold_reached = false
	_chase_target = null
	_structure_target = null

func _update_hold(delta: float) -> void:
	if not _hold_active:
		return
	if not _hold_reached:
		if global_position.distance_to(_hold_pos) <= 4.0:
			_hold_reached = true
		return
	_hold_timer -= delta
	if _hold_timer <= 0.0:
		_hold_active = false
		_hold_timer = 0.0
		_hold_pos = Vector2.ZERO
		_hold_reached = false
