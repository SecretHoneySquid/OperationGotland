class_name BattalionController
extends Node

signal battalion_spawned(battalion: Battalion)
signal battalion_destroyed(battalion: Battalion)
signal battalion_selected(battalion: Battalion)
signal placement_started(type: Battalion.Type)
signal placement_cancelled

var _spawn_controller: SpawnController
var _battalions_container: Node2D
var _teams: Dictionary  # team_id -> TeamState

var _battalions: Dictionary = {
	"p1": [] as Array,
	"p2": [] as Array
}

var _selected_battalion: Battalion = null

# Placement mode
var _placing := false
var _placing_type: Battalion.Type = Battalion.Type.ASSAULT
var _placing_team := "p1"

# AI behavior
var _ai_timer := 0.0


func configure(spawn_ctrl: SpawnController, battalions_container: Node2D, teams: Dictionary) -> void:
	_spawn_controller = spawn_ctrl
	_battalions_container = battalions_container
	_teams = teams


func _process(delta: float) -> void:
	_process_ai(delta)


# =============================================================================
# BATTALION SPAWNING
# =============================================================================

func spawn_battalion(team_id: String, type: Battalion.Type, target_pos: Vector2, barracks: Building = null) -> Battalion:
	var team: TeamState = _teams.get(team_id)
	if team == null:
		push_error("BattalionController: Invalid team_id " + team_id)
		return null

	# Find a barracks to spawn from if not provided
	if barracks == null:
		barracks = _find_barracks(team_id)
	if barracks == null:
		push_warning("BattalionController: No barracks for team " + team_id)
		return null

	# Deduct cost
	var cost := Battalion.get_cost_for_type(type)
	if team_id == "p1":
		if GameState.p1_credits < cost:
			return null
		GameState.p1_credits -= cost
	else:
		if GameState.p2_credits < cost:
			return null
		GameState.p2_credits -= cost

	# Create battalion
	var battalion := Battalion.new()
	battalion.battalion_type = type
	battalion.team_id = team_id
	battalion.target_position = target_pos
	battalion.setup(_spawn_controller, barracks)

	_battalions_container.add_child(battalion)
	battalion.spawn_initial_units()

	# Connect signals
	battalion.battalion_destroyed.connect(_on_battalion_destroyed.bind(battalion))

	# Track it
	_battalions[team_id].append(battalion)

	battalion_spawned.emit(battalion)
	return battalion


func _find_barracks(team_id: String) -> Building:
	var group_name := "building_barracks_" + team_id
	var buildings := get_tree().get_nodes_in_group(group_name)
	if buildings.is_empty():
		return null
	return buildings[0] as Building


func _on_battalion_destroyed(battalion: Battalion) -> void:
	var team_id := battalion.team_id
	var idx: int = _battalions[team_id].find(battalion)
	if idx >= 0:
		_battalions[team_id].remove_at(idx)

	if _selected_battalion == battalion:
		_selected_battalion = null

	battalion_destroyed.emit(battalion)


# =============================================================================
# SELECTION
# =============================================================================

func get_battalion_at(world_pos: Vector2) -> Battalion:
	# Check if click is on any unit that belongs to a battalion
	for team_id in _battalions:
		for battalion in _battalions[team_id]:
			if not is_instance_valid(battalion):
				continue

			# Check center distance
			var center: Vector2 = battalion._get_center()
			if center.distance_to(world_pos) < 150:
				return battalion

			# Check individual units
			for unit in battalion.active_units:
				if not is_instance_valid(unit):
					continue
				if unit.global_position.distance_to(world_pos) < 30:
					return battalion

	return null


func select_battalion(battalion: Battalion) -> void:
	_selected_battalion = battalion
	battalion_selected.emit(battalion)


func get_selected_battalion() -> Battalion:
	return _selected_battalion


func clear_selection() -> void:
	_selected_battalion = null


func get_battalions_for_team(team_id: String) -> Array:
	return _battalions.get(team_id, [])


# =============================================================================
# PLACEMENT MODE
# =============================================================================

var _placing_barracks: Building = null

func start_placement(team_id: String, type: Battalion.Type, barracks: Building = null) -> bool:
	print("BattalionController.start_placement called: team=", team_id, " type=", type)
	var cost := Battalion.get_cost_for_type(type)
	var credits := GameState.p1_credits if team_id == "p1" else GameState.p2_credits
	print("  Cost: ", cost, " Credits: ", credits)

	if credits < cost:
		print("  FAILED: Not enough credits")
		return false

	if barracks == null:
		print("  No barracks passed, searching...")
		barracks = _find_barracks(team_id)
	if barracks == null:
		print("  FAILED: No barracks found")
		return false

	print("  SUCCESS: Starting placement mode")
	_placing = true
	_placing_type = type
	_placing_team = team_id
	_placing_barracks = barracks
	placement_started.emit(type)
	return true


func _has_barracks(team_id: String) -> bool:
	if team_id == "p1":
		return GameState.p1_barracks > 0
	return GameState.p2_barracks > 0


func cancel_placement() -> void:
	_placing = false
	placement_cancelled.emit()


func is_placing() -> bool:
	return _placing


func get_placing_type() -> Battalion.Type:
	return _placing_type


func confirm_placement(target_pos: Vector2) -> Battalion:
	if not _placing:
		return null

	var battalion := spawn_battalion(_placing_team, _placing_type, target_pos, _placing_barracks)
	_placing = false
	_placing_barracks = null
	return battalion


# =============================================================================
# AI BEHAVIOR
# =============================================================================

func _process_ai(delta: float) -> void:
	_ai_timer -= delta
	if _ai_timer > 0:
		return

	_ai_timer = GameBalance.AI_BATTALION_CHECK_INTERVAL

	# Simple AI: buy battalions and send to middle of map
	_ai_try_buy_battalion("p2")


func _ai_try_buy_battalion(team_id: String) -> void:
	var credits := GameState.p2_credits if team_id == "p2" else GameState.p1_credits

	# Pick a random battalion type that we can afford
	var affordable: Array[Battalion.Type] = []

	if credits >= GameBalance.ASSAULT_BATTALION_COST:
		affordable.append(Battalion.Type.ASSAULT)
		affordable.append(Battalion.Type.ASSAULT)  # Weight assault more
	if credits >= GameBalance.DEFENSE_BATTALION_COST:
		affordable.append(Battalion.Type.DEFENSE)
	if credits >= GameBalance.CONTROL_BATTALION_COST:
		affordable.append(Battalion.Type.CONTROL)
	if credits >= GameBalance.AIR_DEFENSE_BATTALION_COST:
		affordable.append(Battalion.Type.AIR_DEFENSE)

	if affordable.is_empty():
		return

	var type := affordable[randi() % affordable.size()]

	# Target: middle of map (between the two HQs)
	var p1_team: TeamState = _teams.get("p1")
	var p2_team: TeamState = _teams.get("p2")
	if p1_team == null or p2_team == null:
		return

	var middle := (p1_team.start_pos + p2_team.start_pos) / 2.0
	# Add some randomness
	middle += Vector2(randf_range(-200, 200), randf_range(-200, 200))

	spawn_battalion(team_id, type, middle)
