class_name GameController
extends Node2D

## Game Controller
##
## Main orchestrator for the game. Delegates to specialized controllers:
## - SpawnController: Unit and building spawning
## - ProductionController: Production pools and queues
## - VisibilityController: Fog of war
##
## Uses TeamState to consolidate per-team state.

# =============================================================================
# EXPORTS - Configuration
# =============================================================================

@export var map_path := "res://data/maps/test_map.json"
@export var structures_path := NodePath("Structures")
@export var units_path := NodePath("Units")

@export var unit_spawn_limit := 50
@export var ai_queue_interval := 2.5
@export var collectors_per_supply := 1
@export var supply_bonus := 25


# Airfield settings
@export var airfield_aircraft_cap := 3
@export var f35_airfield_cap := 1
@export var f35_cost := 100
@export var aircraft_upgrade_cost := 500

# Unit costs (for UI compatibility - values from GameBalance)
var vehicle_unit_cost: int:
	get: return GameBalance.VEHICLE_UNIT_COST
var infantry_unit_cost: int:
	get: return GameBalance.INFANTRY_UNIT_COST
var aircraft_unit_cost: int:
	get: return GameBalance.AIRCRAFT_UNIT_COST
var factory_queue_max: int:
	get: return _production_controller.factory_queue_max if _production_controller else 6

# Fog of war settings (delegated to visibility controller for UI compatibility)
var fog_enabled: bool:
	get: return _visibility_controller.fog_enabled if _visibility_controller else true
	set(value):
		if _visibility_controller:
			_visibility_controller.fog_enabled = value
var fog_hide_enemies: bool:
	get: return _visibility_controller.fog_hide_enemies if _visibility_controller else true
	set(value):
		if _visibility_controller:
			_visibility_controller.fog_hide_enemies = value

# =============================================================================
# STATE
# =============================================================================

var _structures: Node2D
var _units: Node2D
var _p1: TeamState
var _p2: TeamState
var _resource_nodes: Array[Dictionary] = []
var _supply_remaining := 0.0
var _map_size := Vector2(6144, 6144)  # Default, loaded from map data
var _region_income_accum_p1 := 0.0  # Accumulator for fractional region income
var _region_income_accum_p2 := 0.0
var _rally_mode_team := ""
var _rng := RandomNumberGenerator.new()
var _ai_queue_timer := 0.0
var _world_input: Node

# Controllers
var _spawn_controller: SpawnController
var _production_controller: ProductionController
var _visibility_controller: VisibilityController
var _battalion_controller: BattalionController
var _region_controller: RegionController
var _region_grid_visual: RegionGridVisual

# Rally line 3D visualization
var _rally_line_3d: Node3D = null
var _rally_line_mesh: MeshInstance3D = null
var _rally_marker: MeshInstance3D = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_structures = get_node_or_null(structures_path) as Node2D
	if _structures == null:
		_structures = self
	_units = get_node_or_null(units_path) as Node2D
	if _units == null:
		_units = self

	_rng.randomize()
	_init_teams()
	_init_controllers()
	_load_map_data(map_path)
	_init_region_system()
	_visibility_controller.setup_base_vision(self)
	_spawn_hqs()
	_spawn_starting_buildings()
	_sync_collectors("p1")
	_sync_collectors("p2")
	_ai_queue_timer = ai_queue_interval
	_world_input = _find_world_input()
	_setup_rally_line_3d()

	var selection_controller = get_node_or_null("../SelectionController")
	if selection_controller != null and selection_controller.has_signal("building_selected"):
		selection_controller.building_selected.connect(_on_building_selected)

func _init_teams() -> void:
	_p1 = TeamState.new("p1")
	_p2 = TeamState.new("p2")
	GameState.reset(700, 700)  # starting credits

func _init_controllers() -> void:
	var teams := {"p1": _p1, "p2": _p2}

	_spawn_controller = SpawnController.new()
	_spawn_controller.configure(_units, _structures, teams)
	add_child(_spawn_controller)

	_production_controller = ProductionController.new()
	_production_controller.configure(teams)
	_production_controller.infantry_ready.connect(_on_infantry_ready)
	_production_controller.vehicle_ready.connect(_on_vehicle_ready)
	_production_controller.aircraft_ready.connect(_on_aircraft_ready)
	add_child(_production_controller)

	_visibility_controller = VisibilityController.new()
	_visibility_controller.configure(teams)
	add_child(_visibility_controller)

	# Battalion controller - needs a container for battalions
	var battalions_container := Node2D.new()
	battalions_container.name = "Battalions"
	add_child(battalions_container)

	_battalion_controller = BattalionController.new()
	_battalion_controller.name = "BattalionController"
	_battalion_controller.configure(_spawn_controller, battalions_container, teams)
	add_child(_battalion_controller)

	# Battalion placement preview - add to UI CanvasLayer so it renders over 3D
	var placement_preview := BattalionPlacementPreview.new()
	placement_preview.name = "BattalionPlacementPreview"
	placement_preview.configure(_battalion_controller)
	var ui_layer := get_node_or_null("UI")
	if ui_layer != null:
		ui_layer.add_child(placement_preview)
	else:
		# Fallback - create our own CanvasLayer
		var canvas := CanvasLayer.new()
		canvas.layer = 50  # Below main UI (100) but above game
		add_child(canvas)
		canvas.add_child(placement_preview)

	# Region controller - manages territory control and income
	_region_controller = RegionController.new()
	_region_controller.name = "RegionController"
	_region_controller.configure(teams, _visibility_controller)
	add_child(_region_controller)

func _process(delta: float) -> void:
	_update_hq_state()
	_production_controller.update(delta)
	_sync_collectors("p1")
	_sync_collectors("p2")
	_update_defenses(delta)
	_update_ai_queue(delta)
	_update_state_counters()
	_visibility_controller.update()
	_update_rally_line()
	_update_region_control(delta)

func _unhandled_input(event: InputEvent) -> void:
	# Handle battalion placement mode
	if _battalion_controller != null and _battalion_controller.is_placing():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("GameController: Left click during battalion placement at ", _get_world_mouse_pos())
			var battalion := _battalion_controller.confirm_placement(_get_world_mouse_pos())
			print("GameController: confirm_placement returned: ", battalion)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			print("GameController: Right click - cancelling placement")
			_battalion_controller.cancel_placement()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			print("GameController: Escape - cancelling placement")
			_battalion_controller.cancel_placement()
		return

	# Handle rally mode
	if _rally_mode_team == "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_rally_point(_rally_mode_team, _get_world_mouse_pos())
		_rally_mode_team = ""
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_set_rally_point(_rally_mode_team, Vector2.ZERO)
		_rally_mode_team = ""
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_rally_mode_team = ""

# =============================================================================
# PUBLIC API - Rally Points
# =============================================================================

func start_rally_mode(team_id: String) -> void:
	if _rally_mode_team == team_id:
		_rally_mode_team = ""
	else:
		_rally_mode_team = team_id

func is_rally_mode(team_id: String) -> bool:
	return _rally_mode_team == team_id

func get_rally_point(team_id: String) -> Vector2:
	return _get_team(team_id).rally_pos

# =============================================================================
# PUBLIC API - Vehicle Queue
# =============================================================================

func queue_vehicle(team_id: String, vehicle_type: String = "mixed", factory: Building = null) -> bool:
	return _production_controller.queue_vehicle(team_id, vehicle_type, factory)

func queue_himars(team_id: String, factory: Building = null) -> bool:
	return _production_controller.queue_himars(team_id, factory)

# =============================================================================
# PUBLIC API - Airfield
# =============================================================================

func buy_airfield_f35(team_id: String, airfield: Building) -> bool:
	if airfield == null or not is_instance_valid(airfield):
		return false
	if airfield.build_id != "airfield" or airfield.team_id != team_id:
		return false
	var team := _get_team(team_id)
	if not team.has_credits(f35_cost):
		return false
	if unit_spawn_limit > 0 and _count_units(team_id) >= unit_spawn_limit:
		return false
	if f35_airfield_cap > 0:
		var current_id := int(airfield.get_meta("f35_active", 0))
		if current_id > 0:
			var inst = instance_from_id(current_id)
			if inst != null and is_instance_valid(inst):
				return false
			airfield.set_meta("f35_active", 0)
	if airfield_aircraft_cap > 0:
		var current_aircraft := int(airfield.get_meta("aircraft_active", 0))
		if current_aircraft >= airfield_aircraft_cap:
			return false
	team.deduct_credits(f35_cost)
	var unit := _spawn_controller.spawn_unit(team_id, "aircraft", airfield, "f35")
	if unit == null:
		return false
	_register_airfield_aircraft(airfield)
	airfield.set_meta("f35_active", unit.get_instance_id())
	return true

func upgrade_airfield_aircraft(team_id: String, airfield: Building) -> bool:
	if airfield == null or not is_instance_valid(airfield):
		return false
	if airfield.build_id != "airfield" or airfield.team_id != team_id:
		return false
	var team := _get_team(team_id)
	if not team.has_credits(aircraft_upgrade_cost):
		return false
	var current_tier := str(airfield.get_meta("aircraft_tier", "f16"))
	var new_tier := ""
	if current_tier == "f16":
		new_tier = "gripen"
	elif current_tier == "gripen":
		new_tier = "f22"
	else:
		return false
	team.deduct_credits(aircraft_upgrade_cost)
	airfield.set_meta("aircraft_tier", new_tier)
	return true

func get_airfield_aircraft_tier(airfield: Building) -> String:
	if airfield == null or not is_instance_valid(airfield):
		return "f16"
	if not airfield.has_meta("aircraft_tier"):
		airfield.set_meta("aircraft_tier", "f16")
	return str(airfield.get_meta("aircraft_tier", "f16"))

func cycle_airfield_production_type(team_id: String, airfield: Building) -> bool:
	if airfield == null or not is_instance_valid(airfield):
		return false
	if airfield.build_id != "airfield" or airfield.team_id != team_id:
		return false
	if airfield.aircraft_production_type == "fighter":
		airfield.aircraft_production_type = "uav"
	else:
		airfield.aircraft_production_type = "fighter"
	print("[Airfield] Production type changed to: ", airfield.aircraft_production_type)
	return true

func spawn_aircraft(team_id: String, airfield: Building = null, aircraft_type: String = "") -> bool:
	var target_airfield := airfield if airfield != null else _get_airfield_for_spawn(team_id)
	if target_airfield == null:
		return false
	var type_to_spawn := aircraft_type if aircraft_type != "" else (
		"uav" if target_airfield.aircraft_production_type == "uav" else get_airfield_aircraft_tier(target_airfield)
	)
	var slot_map_value: Variant = target_airfield.get_meta("aircraft_landing_slots", {})
	var slot_map: Dictionary = slot_map_value if slot_map_value is Dictionary else {}
	var assigned_slot := -1
	for i in range(4):
		if not slot_map.has(i):
			assigned_slot = i
			break
	if assigned_slot >= 0:
		target_airfield.set_meta("_spawn_slot_temp", assigned_slot)
		target_airfield.set_meta("_spawn_slot_reserved", true)
	var unit := _spawn_controller.spawn_unit(team_id, "aircraft", target_airfield, type_to_spawn)
	if unit != null and target_airfield != null and assigned_slot >= 0:
		slot_map[assigned_slot] = unit.get_instance_id()
		target_airfield.set_meta("aircraft_landing_slots", slot_map)
		target_airfield.remove_meta("_spawn_slot_temp")
		target_airfield.remove_meta("_spawn_slot_reserved")
	return unit != null

# =============================================================================
# PUBLIC API - Credits & Resources
# =============================================================================

func deposit_credits(team_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var bonus := supply_bonus if supply_bonus > 0 else 0
	var total := amount + bonus
	_get_team(team_id).add_income(total)

func debug_add_credits(team_id: String, amount: int) -> void:
	if amount == 0:
		return
	_get_team(team_id).add_credits(amount)

func debug_spawn_unit(team_id: String, unit_kind: String, count: int = 1, unit_type_id: String = "") -> int:
	if count <= 0:
		return 0
	if GameState.winner != "":
		return 0
	var spawned := 0
	for _i in range(count):
		if unit_spawn_limit > 0 and _count_units(team_id) >= unit_spawn_limit:
			break
		var unit := _spawn_controller.spawn_unit(team_id, unit_kind, null, unit_type_id)
		if unit == null:
			break
		spawned += 1
	return spawned

func debug_clear_units() -> void:
	for group_name in ["units", "collectors", "missiles"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node != null and is_instance_valid(node):
				node.queue_free()

func request_resource_node(team_id: String) -> Dictionary:
	var team := _get_team(team_id)
	var best_index := -1
	var best_dist := INF
	for i in range(_resource_nodes.size()):
		var node: Dictionary = _resource_nodes[i]
		var remaining := float(node.get("amount", 0.0))
		if remaining <= 0.0:
			continue
		var pos := node.get("pos", Vector2.ZERO) as Vector2
		var dist := team.start_pos.distance_squared_to(pos)
		if dist < best_dist:
			best_dist = dist
			best_index = i
	if best_index == -1:
		return {}
	return {
		"index": best_index,
		"pos": _resource_nodes[best_index].get("pos", Vector2.ZERO)
	}

func harvest_resource(index: int, amount: float) -> float:
	if index < 0 or index >= _resource_nodes.size():
		return 0.0
	var node: Dictionary = _resource_nodes[index]
	var remaining := float(node.get("amount", 0.0))
	if remaining <= 0.0:
		return 0.0
	var taken: float = minf(remaining, amount)
	node["amount"] = remaining - taken
	_resource_nodes[index] = node
	_supply_remaining = maxf(0.0, _supply_remaining - taken)
	GameState.total_supply_remaining = _supply_remaining
	return taken

# =============================================================================
# PUBLIC API - Type Options
# =============================================================================

func get_infantry_type_options() -> Array:
	return UnitDefinitions.get_infantry_type_options()

func get_vehicle_type_options() -> Array:
	return UnitDefinitions.get_vehicle_type_options()

# =============================================================================
# PRODUCTION SIGNAL HANDLERS
# =============================================================================

func _on_infantry_ready(team: TeamState) -> void:
	if unit_spawn_limit > 0 and _count_units(team.team_id) >= unit_spawn_limit:
		return
	var barracks := _get_barracks_for_spawn(team.team_id)
	if barracks == null:
		return
	_spawn_controller.spawn_unit(team.team_id, "infantry", barracks)

func _on_vehicle_ready(team: TeamState, entry: Dictionary) -> void:
	if unit_spawn_limit > 0 and _count_units(team.team_id) >= unit_spawn_limit:
		return
	var vehicle_type := str(entry.get("type", "mixed"))
	var factory: Building = null
	var candidate = entry.get("factory")
	if candidate is Building and is_instance_valid(candidate):
		factory = candidate
	_spawn_controller.spawn_unit(team.team_id, "vehicle", factory, vehicle_type)

func _on_aircraft_ready(team: TeamState) -> void:
	if unit_spawn_limit > 0 and _count_units(team.team_id) >= unit_spawn_limit:
		return
	var airfield := _get_airfield_for_spawn(team.team_id)
	if airfield == null:
		return
	var slot_map_value: Variant = airfield.get_meta("aircraft_landing_slots", {})
	var slot_map: Dictionary = slot_map_value if slot_map_value is Dictionary else {}
	var assigned_slot := -1
	for i in range(4):
		if not slot_map.has(i):
			assigned_slot = i
			break
	if assigned_slot >= 0:
		airfield.set_meta("_spawn_slot_temp", assigned_slot)
		airfield.set_meta("_spawn_slot_reserved", true)
	var aircraft_type := "uav" if airfield.aircraft_production_type == "uav" else get_airfield_aircraft_tier(airfield)
	var unit := _spawn_controller.spawn_unit(team.team_id, "aircraft", airfield, aircraft_type)
	if unit != null and airfield != null and assigned_slot >= 0:
		slot_map[assigned_slot] = unit.get_instance_id()
		airfield.set_meta("aircraft_landing_slots", slot_map)
		airfield.remove_meta("_spawn_slot_temp")
		airfield.remove_meta("_spawn_slot_reserved")
	_register_airfield_aircraft(airfield)

# =============================================================================
# SPAWNING
# =============================================================================

func _spawn_hqs() -> void:
	_spawn_controller.spawn_hq(_p1)
	_spawn_controller.spawn_hq(_p2)

func _spawn_starting_buildings() -> void:
	var offsets := {
		"barracks": {"p1": Vector2(160, -100), "p2": Vector2(-160, -100), "spacing": 100},
		"factory": {"p1": Vector2(260, -120), "p2": Vector2(-260, -120), "spacing": 120},
		"airfield": {"p1": Vector2(340, -80), "p2": Vector2(-340, -80), "spacing": 140},
		"supply": {"p1": Vector2(120, 140), "p2": Vector2(-120, 140), "spacing": 90},
	}
	var starting_counts := {
		"barracks": {"p1": 0, "p2": 1},
		"factory": {"p1": 0, "p2": 1},
		"airfield": {"p1": 0, "p2": 1},
		"supply": {"p1": 0, "p2": 1},
	}
	for build_id in starting_counts:
		var counts: Dictionary = starting_counts[build_id]
		var offs: Dictionary = offsets[build_id]
		for i in range(counts["p1"]):
			_spawn_controller.spawn_building("p1", build_id, _p1.start_pos + offs["p1"] + Vector2(0, i * offs["spacing"]))
		for i in range(counts["p2"]):
			_spawn_controller.spawn_building("p2", build_id, _p2.start_pos + offs["p2"] + Vector2(0, i * offs["spacing"]))

# =============================================================================
# BUILDING HELPERS
# =============================================================================

func _get_barracks_for_spawn(team_id: String) -> Building:
	var team := _get_team(team_id)
	var group_name := "building_barracks_%s" % team_id
	var nodes := get_tree().get_nodes_in_group(group_name)
	var barracks_list: Array[Building] = []
	for node in nodes:
		var barracks := node as Building
		if barracks != null and is_instance_valid(barracks):
			barracks_list.append(barracks)
	if barracks_list.is_empty():
		return null
	var index := team.barracks_spawn_index % barracks_list.size()
	var chosen := barracks_list[index]
	team.barracks_spawn_index = (index + 1) % barracks_list.size()
	return chosen

func _get_airfield_for_spawn(team_id: String) -> Building:
	var team := _get_team(team_id)
	var group_name := "building_airfield_%s" % team_id
	var nodes := get_tree().get_nodes_in_group(group_name)
	var airfield_list: Array[Building] = []
	for node in nodes:
		var airfield := node as Building
		if airfield != null and is_instance_valid(airfield):
			airfield_list.append(airfield)
	if airfield_list.is_empty():
		return null
	var index := team.airfield_spawn_index
	var total := airfield_list.size()
	index = index % total
	var chosen: Building = null
	for offset in range(total):
		var idx := (index + offset) % total
		var candidate := airfield_list[idx]
		if _airfield_has_capacity(candidate):
			chosen = candidate
			team.airfield_spawn_index = (idx + 1) % total
			break
	return chosen

func _airfield_has_capacity(airfield: Building) -> bool:
	if airfield == null or not is_instance_valid(airfield):
		return false
	if airfield_aircraft_cap <= 0:
		return true
	var current = int(airfield.get_meta("aircraft_active", 0))
	return current < airfield_aircraft_cap

func _register_airfield_aircraft(airfield: Building) -> void:
	if airfield == null or not is_instance_valid(airfield):
		return
	var current = int(airfield.get_meta("aircraft_active", 0))
	airfield.set_meta("aircraft_active", current + 1)

# =============================================================================
# COLLECTORS
# =============================================================================

func _sync_collectors(team_id: String) -> void:
	var team := _get_team(team_id)
	var desired := team.get_supply_count() * collectors_per_supply
	while team.collectors.size() < desired:
		var supply := _get_supply_for_spawn(team_id)
		var base_pos := team.start_pos
		if supply != null and is_instance_valid(supply):
			base_pos = supply.global_position
		var collector := _spawn_controller.spawn_collector(team, base_pos)
		collector.configure(self, team_id, base_pos)

func _get_supply_for_spawn(team_id: String) -> Building:
	var team := _get_team(team_id)
	var group_name := "building_supply_%s" % team_id
	var nodes := get_tree().get_nodes_in_group(group_name)
	var supply_list: Array[Building] = []
	for node in nodes:
		var supply := node as Building
		if supply != null and is_instance_valid(supply):
			supply_list.append(supply)
	if supply_list.is_empty():
		return null
	var index := team.supply_spawn_index % supply_list.size()
	var chosen := supply_list[index]
	team.supply_spawn_index = (index + 1) % supply_list.size()
	return chosen

# =============================================================================
# UPDATE HELPERS
# =============================================================================

func _update_hq_state() -> void:
	if _p1.hq != null and not is_instance_valid(_p1.hq):
		_p1.hq = null
	if _p2.hq != null and not is_instance_valid(_p2.hq):
		_p2.hq = null
	GameState.p1_hq_hp = int(_p1.hq.hp) if _p1.is_hq_alive() else 0
	GameState.p2_hq_hp = int(_p2.hq.hp) if _p2.is_hq_alive() else 0
	if not _p1.is_hq_alive() and GameState.winner == "":
		GameState.winner = "P2"
	elif not _p2.is_hq_alive() and GameState.winner == "":
		GameState.winner = "P1"

func _update_defenses(delta: float) -> void:
	for turret in get_tree().get_nodes_in_group("defense_turret"):
		if turret is DefenseTurret:
			turret.update_targeting(delta)

func _update_ai_queue(delta: float) -> void:
	_ai_queue_timer -= delta
	if _ai_queue_timer > 0.0:
		return
	_ai_queue_timer = ai_queue_interval
	if GameState.p2_factory <= 0:
		return
	if _production_controller.get_factory_queue_size("p2") >= mini(3, 6):
		return
	queue_vehicle("p2", "mixed")

func _update_state_counters() -> void:
	_p1.sync_to_game_state()
	_p2.sync_to_game_state()
	GameState.total_supply_remaining = _supply_remaining

func _count_units(team_id: String) -> int:
	return get_tree().get_nodes_in_group("units_%s" % team_id).size()

# =============================================================================
# RALLY POINTS
# =============================================================================

func _set_rally_point(team_id: String, pos: Vector2) -> void:
	_get_team(team_id).rally_pos = pos
	_update_rally_line()

func _get_team(team_id: String) -> TeamState:
	return _p1 if team_id == "p1" else _p2

func _get_world_mouse_pos() -> Vector2:
	var input := _world_input
	if input == null or not is_instance_valid(input):
		input = _find_world_input()
		_world_input = input
	if input != null and input.has_method("screen_to_world"):
		return input.screen_to_world(get_viewport().get_mouse_position())
	return get_global_mouse_position()

func _find_world_input() -> Node:
	var nodes := get_tree().get_nodes_in_group("world_input")
	if nodes.is_empty():
		return null
	return nodes[0] as Node

# =============================================================================
# MAP LOADING
# =============================================================================

func _load_map_data(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameController: Failed to open map at %s" % path)
		return
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameController: Invalid JSON in %s" % path)
		return
	var data: Dictionary = parsed
	_load_map_size(data)
	_load_start_positions(data)
	_load_build_zones(data)
	_load_rally_targets(data)
	_load_resource_nodes(data)

func _load_map_size(data: Dictionary) -> void:
	var size_data: Dictionary = data.get("size", {})
	_map_size.x = float(size_data.get("width", 6144))
	_map_size.y = float(size_data.get("height", 6144))

func _load_start_positions(data: Dictionary) -> void:
	var starts: Array = data.get("start_positions", [])
	for start in starts:
		if typeof(start) != TYPE_DICTIONARY:
			continue
		var id := str(start.get("id", ""))
		var pos := Vector2(float(start.get("x", 0.0)), float(start.get("y", 0.0)))
		if id == "p1":
			_p1.start_pos = pos
		elif id == "p2":
			_p2.start_pos = pos

func _load_build_zones(data: Dictionary) -> void:
	var zones: Array = data.get("build_zones", [])
	for zone in zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		var zone_id := str(zone.get("id", ""))
		var rect := Rect2(
			Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
			Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
		)
		if zone_id == "p1":
			_p1.build_zone = rect
			_visibility_controller.set_build_zone("p1", rect)
		elif zone_id == "p2":
			_p2.build_zone = rect

func _load_rally_targets(data: Dictionary) -> void:
	var rally_targets: Array = data.get("rally_targets", [])
	for target in rally_targets:
		if typeof(target) != TYPE_DICTIONARY:
			continue
		var id := str(target.get("id", ""))
		var pos := Vector2(float(target.get("x", 0.0)), float(target.get("y", 0.0)))
		if id == "p1_push":
			_p1.rally_pos = pos
		elif id == "p2_push":
			_p2.rally_pos = pos
	if _p1.rally_pos == Vector2.ZERO:
		_p1.rally_pos = _p2.start_pos
	if _p2.rally_pos == Vector2.ZERO:
		_p2.rally_pos = _p1.start_pos

func _load_resource_nodes(data: Dictionary) -> void:
	_resource_nodes.clear()
	_supply_remaining = 0.0
	var nodes: Array = data.get("resource_nodes", [])
	for node in nodes:
		if typeof(node) != TYPE_DICTIONARY:
			continue
		var pos := Vector2(float(node.get("x", 0.0)), float(node.get("y", 0.0)))
		var amount := float(node.get("amount", 0.0))
		_resource_nodes.append({
			"pos": pos,
			"amount": amount,
			"initial": amount,
		})
		_supply_remaining += amount
	GameState.total_supply_remaining = _supply_remaining

# =============================================================================
# REGION CONTROL SYSTEM
# =============================================================================

func _init_region_system() -> void:
	if _region_controller == null:
		push_error("GameController: Region controller not initialized")
		return

	# Initialize region grid with map size
	_region_controller.initialize(_map_size.x, _map_size.y)

	# Create the 3D visual for the region grid
	_create_region_grid_visual()

	# Debug: print region grid
	_region_controller.debug_print_grid()

	print("[GameController] Region system initialized")

func _create_region_grid_visual() -> void:
	# Find the World3D node to add the visual to
	var world_3d := _find_world_3d()
	if world_3d == null:
		push_warning("GameController: Could not find World3D node for region grid visual")
		return

	# Create the region grid visual
	_region_grid_visual = RegionGridVisual.new()
	_region_grid_visual.name = "RegionGridVisual"
	_region_grid_visual.configure(_region_controller)

	# Add to the 3D world
	world_3d.add_child(_region_grid_visual)

	# Initialize after adding to tree
	_region_grid_visual.initialize()

	print("[GameController] Region grid visual created")

func _find_world_3d() -> Node3D:
	# The scene structure is: Main3D -> Logic2D (main.tscn) -> GameController
	# World3D is a sibling of Logic2D under Main3D
	# Path from GameController: ../../World3D

	# Direct path approach
	var world_3d := get_node_or_null("../../World3D")
	if world_3d != null and world_3d is Node3D:
		return world_3d as Node3D

	# Fallback: navigate via parents
	var parent := get_parent()  # Logic2D (main.tscn root)
	if parent == null:
		return null

	var main_3d := parent.get_parent()  # Main3D
	if main_3d == null:
		return null

	world_3d = main_3d.get_node_or_null("World3D")
	if world_3d != null:
		return world_3d as Node3D

	# Final fallback: search entire tree for a Node3D named World3D
	var root := get_tree().root
	return _find_node_recursive(root, "World3D") as Node3D

func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_recursive(child, target_name)
		if found != null:
			return found
	return null

func _update_region_control(delta: float) -> void:
	if _region_controller == null:
		return

	# Update region presence and control states
	_region_controller.update(delta)

	# Apply income from controlled regions
	var p1_region_income := _region_controller.get_income_for_team("p1")
	var p2_region_income := _region_controller.get_income_for_team("p2")

	# Accumulate fractional income, only add whole credits
	_region_income_accum_p1 += p1_region_income * delta
	_region_income_accum_p2 += p2_region_income * delta

	# Add whole credits when accumulator >= 1
	if _region_income_accum_p1 >= 1.0:
		var whole := int(_region_income_accum_p1)
		_p1.add_credits(whole)
		_region_income_accum_p1 -= whole

	if _region_income_accum_p2 >= 1.0:
		var whole := int(_region_income_accum_p2)
		_p2.add_credits(whole)
		_region_income_accum_p2 -= whole

	# Update GameState for UI display
	GameState.p1_regions_controlled = _region_controller.get_controlled_region_count("p1")
	GameState.p2_regions_controlled = _region_controller.get_controlled_region_count("p2")
	GameState.regions_contested = _region_controller.get_contested_region_count()
	GameState.p1_region_income = p1_region_income
	GameState.p2_region_income = p2_region_income

func get_region_controller() -> RegionController:
	return _region_controller

# =============================================================================
# RALLY LINE 3D
# =============================================================================

func _setup_rally_line_3d() -> void:
	_rally_line_3d = Node3D.new()
	add_child(_rally_line_3d)
	_rally_line_3d.visible = false

	_rally_line_mesh = MeshInstance3D.new()
	_rally_line_3d.add_child(_rally_line_mesh)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 1.0)
	material.emission_energy_multiplier = 1.5
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rally_line_mesh.material_override = material

	_rally_marker = MeshInstance3D.new()
	_rally_line_3d.add_child(_rally_marker)
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 4.0
	marker_mesh.height = 8.0
	_rally_marker.mesh = marker_mesh
	_rally_marker.material_override = material

func _update_rally_line() -> void:
	if _rally_line_3d == null or _rally_line_mesh == null or _rally_marker == null:
		return
	if _p1.selected_factory != null and is_instance_valid(_p1.selected_factory):
		var factory_pos := _p1.selected_factory.global_position
		var rally_target: Vector2
		if _p1.rally_pos != Vector2.ZERO:
			rally_target = _p1.rally_pos
		else:
			rally_target = factory_pos + Vector2(200.0, 0.0)
		var height := 15.0
		var start3 := Vector3(factory_pos.x, height, factory_pos.y)
		var end3 := Vector3(rally_target.x, height, rally_target.y)
		var delta := end3 - start3
		var line_length := delta.length()
		_rally_line_3d.global_position = (start3 + end3) * 0.5
		_rally_line_3d.look_at(end3, Vector3.UP)
		var thickness := 1.5
		var mesh := BoxMesh.new()
		mesh.size = Vector3(thickness, thickness, line_length)
		_rally_line_mesh.mesh = mesh
		_rally_marker.position = Vector3(0, 0, line_length * 0.5)
		_rally_line_3d.visible = true
	else:
		_rally_line_3d.visible = false

func _on_building_selected(building: Building) -> void:
	if building != null and is_instance_valid(building) and building.build_id == "factory" and building.team_id == "p1":
		_p1.selected_factory = building
	else:
		_p1.selected_factory = null
	_update_rally_line()
