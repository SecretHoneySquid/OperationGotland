class_name GameController
extends Node2D

@export var map_path := "res://data/maps/test_map.json"
@export var structures_path := NodePath("Structures")
@export var units_path := NodePath("Units")

@export var unit_spawn_limit := 50
@export var unit_spawn_spread := 22.0
@export var max_infantry_pool := 5.0

@export var starting_p1_credits := 700
@export var starting_p2_credits := 700
@export var starting_p1_barracks := 0
@export var starting_p2_barracks := 1
@export var starting_p1_factory := 0
@export var starting_p2_factory := 1
@export var starting_p1_supply := 0
@export var starting_p2_supply := 1

@export var barracks_infantry_rate := 0.6
@export var factory_vehicle_rate := 0.25
@export var infantry_unit_cost := 25
@export var vehicle_unit_cost := 60
@export var factory_queue_max := 6

@export var unit_speed := 63.0
@export var unit_hp := 30.0
@export var unit_damage := 6.0
@export var unit_attack_range := 26.0
@export var infantry_long_multiplier := 10.0
@export var infantry_mid_multiplier := 5.0
@export var infantry_long_ratio := 0.2
@export var infantry_mid_ratio := 0.3
@export var unit_attack_cooldown := 0.6
@export var unit_body_radius := 8.0
@export var infantry_wait_duration := 10.0
@export var wait_edge_padding := 12.0

@export var vehicle_speed := 49.0
@export var vehicle_hp := 60.0
@export var vehicle_damage := 12.0
@export var vehicle_attack_range := 34.0
@export var vehicle_long_multiplier := 10.0
@export var vehicle_mid_multiplier := 5.0
@export var vehicle_long_ratio := 0.2
@export var vehicle_mid_ratio := 0.3
@export var vehicle_attack_cooldown := 0.9
@export var vehicle_body_radius := 11.0

@export var collector_speed := 80.0
@export var collector_capacity := 100.0
@export var collector_harvest_time := 1.0
@export var collectors_per_supply := 1
@export var supply_bonus := 25

@export var defense_range := 260.0
@export var defense_damage := 10.0
@export var defense_fire_rate := 0.8
@export var defense_range_multiplier := 1.5
@export var defense_fire_rate_multiplier := 0.75
@export var defense_color := Color(0.7, 0.7, 0.7, 1.0)

@export var hq_size := Vector2(140, 140)
@export var hq_hp := 500.0

@export var p1_unit_color := Color(0.2, 0.5, 1.0, 1.0)
@export var p2_unit_color := Color(1.0, 0.3, 0.3, 1.0)
@export var p1_vehicle_color := Color(0.25, 0.7, 1.0, 1.0)
@export var p2_vehicle_color := Color(1.0, 0.45, 0.3, 1.0)
@export var p1_hq_color := Color(0.2, 0.35, 0.7, 1.0)
@export var p2_hq_color := Color(0.7, 0.2, 0.2, 1.0)
@export var p1_collector_color := Color(0.9, 0.85, 0.2, 1.0)
@export var p2_collector_color := Color(0.9, 0.6, 0.2, 1.0)

@export var show_rally_marker := true
@export var rally_marker_radius := 12.0
@export var rally_marker_outline := Color(0.9, 0.9, 0.9, 0.8)
@export var rally_line_color := Color(0.8, 0.8, 0.8, 0.4)

@export var show_resource_nodes := true
@export var resource_full_color := Color(0.95, 0.75, 0.2, 0.9)
@export var resource_empty_color := Color(0.25, 0.25, 0.25, 0.7)
@export var resource_min_radius := 6.0
@export var resource_max_radius := 18.0

@export var ai_queue_interval := 2.5
@export var fog_enabled := true
@export var fog_hide_enemies := true
@export var base_vision_enabled := true
@export var base_vision_padding := 40.0
@export var base_vision_energy := 2.2

var _structures: Node2D
var _units: Node2D
var _infantry_pool_p1 := 0.0
var _infantry_pool_p2 := 0.0
var _vehicle_progress_p1 := 0.0
var _vehicle_progress_p2 := 0.0
var _factory_queue_p1: Array[Dictionary] = []
var _factory_queue_p2: Array[Dictionary] = []
var _collectors_p1: Array[Collector] = []
var _collectors_p2: Array[Collector] = []
var _resource_nodes: Array[Dictionary] = []
var _supply_remaining := 0.0
var _hq_p1: HQ
var _hq_p2: HQ
var _start_p1 := Vector2(200, 600)
var _start_p2 := Vector2(1800, 600)
var _rally_p1 := Vector2.ZERO
var _rally_p2 := Vector2.ZERO
var _rally_mode_team := ""
var _rng := RandomNumberGenerator.new()
var _ai_queue_timer := 0.0
var _income_accum_p1 := 0.0
var _income_accum_p2 := 0.0
var _income_timer := 0.0
var _p1_build_zone := Rect2()
var _p2_build_zone := Rect2()
var _base_vision: BaseVision
var _barracks_spawn_index_p1 := 0
var _barracks_spawn_index_p2 := 0
var _supply_spawn_index_p1 := 0
var _supply_spawn_index_p2 := 0
var _world_input: Node

func _ready() -> void:
	_structures = get_node_or_null(structures_path) as Node2D
	if _structures == null:
		_structures = self
	_units = get_node_or_null(units_path) as Node2D
	if _units == null:
		_units = self
	GameState.reset(starting_p1_credits, starting_p2_credits)
	_rng.randomize()
	_load_map_data(map_path)
	_setup_base_vision()
	_spawn_hqs()
	_spawn_starting_buildings()
	_sync_collectors("p1")
	_sync_collectors("p2")
	_ai_queue_timer = ai_queue_interval
	_world_input = _find_world_input()
	queue_redraw()

func _process(delta: float) -> void:
	_update_hq_state()
	_update_production()
	_update_income_rate(delta)
	_sync_collectors("p1")
	_sync_collectors("p2")
	_update_defenses(delta)
	_update_infantry(delta)
	_update_factory_queue(delta)
	_update_ai_queue(delta)
	_update_state_counters()
	_update_visibility()

func _unhandled_input(event: InputEvent) -> void:
	if _rally_mode_team == "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_rally_point(_rally_mode_team, _get_world_mouse_pos())
		_rally_mode_team = ""
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_rally_mode_team = ""
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_rally_mode_team = ""

func _draw() -> void:
	if not show_rally_marker:
		pass
	else:
		if _rally_p1 != Vector2.ZERO:
			draw_circle(_rally_p1, rally_marker_radius, p1_unit_color)
			draw_circle(_rally_p1, rally_marker_radius, rally_marker_outline, false, 2.0)
			draw_line(_start_p1, _rally_p1, rally_line_color, 2.0)
		if _rally_p2 != Vector2.ZERO:
			draw_circle(_rally_p2, rally_marker_radius, p2_unit_color)
			draw_circle(_rally_p2, rally_marker_radius, rally_marker_outline, false, 2.0)
			draw_line(_start_p2, _rally_p2, rally_line_color, 2.0)
	if show_resource_nodes:
		_draw_resource_nodes()

func start_rally_mode(team_id: String) -> void:
	if _rally_mode_team == team_id:
		_rally_mode_team = ""
	else:
		_rally_mode_team = team_id

func is_rally_mode(team_id: String) -> bool:
	return _rally_mode_team == team_id

func get_rally_point(team_id: String) -> Vector2:
	return _rally_p1 if team_id == "p1" else _rally_p2

func queue_vehicle(team_id: String, vehicle_type: String = "mixed", factory: Building = null) -> bool:
	if not _has_team_credits(team_id, vehicle_unit_cost):
		return false
	if _get_factory_count(team_id) <= 0:
		return false
	if _get_factory_queue(team_id).size() >= factory_queue_max:
		return false
	var chosen_factory: Building = null
	if factory != null and is_instance_valid(factory):
		if factory.build_id == "factory" and factory.team_id == team_id:
			chosen_factory = factory
	var type_id := vehicle_type
	if type_id == "" and chosen_factory != null:
		type_id = chosen_factory.vehicle_production_type
	_deduct_team_credits(team_id, vehicle_unit_cost)
	var entry := {
		"type": type_id,
		"factory": chosen_factory,
	}
	if team_id == "p1":
		_factory_queue_p1.append(entry)
	else:
		_factory_queue_p2.append(entry)
	return true

func deposit_credits(team_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var bonus := supply_bonus if supply_bonus > 0 else 0
	var total := amount + bonus
	if team_id == "p1":
		GameState.p1_credits += total
		_income_accum_p1 += total
	else:
		GameState.p2_credits += total
		_income_accum_p2 += total

func request_resource_node(team_id: String) -> Dictionary:
	var base := _start_p1 if team_id == "p1" else _start_p2
	var best_index := -1
	var best_dist := INF
	for i in range(_resource_nodes.size()):
		var node: Dictionary = _resource_nodes[i]
		var remaining := float(node.get("amount", 0.0))
		if remaining <= 0.0:
			continue
		var pos := node.get("pos", Vector2.ZERO) as Vector2
		var dist := base.distance_squared_to(pos)
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
	queue_redraw()
	return taken

func _spawn_hqs() -> void:
	_hq_p1 = HQ.new()
	_hq_p1.team_id = "p1"
	_hq_p1.visual_scene_path = _get_hq_visual_path()
	_hq_p1.visual_base_size = Vector2(140, 140)
	_hq_p1.position = _start_p1
	_hq_p1.size = hq_size
	_hq_p1.max_hp = hq_hp
	_hq_p1.fill_color = p1_hq_color
	_structures.add_child(_hq_p1)

	_hq_p2 = HQ.new()
	_hq_p2.team_id = "p2"
	_hq_p2.visual_scene_path = _get_hq_visual_path()
	_hq_p2.visual_base_size = Vector2(140, 140)
	_hq_p2.position = _start_p2
	_hq_p2.size = hq_size
	_hq_p2.max_hp = hq_hp
	_hq_p2.fill_color = p2_hq_color
	_structures.add_child(_hq_p2)

func _spawn_starting_buildings() -> void:
	for i in range(starting_p1_barracks):
		_spawn_building("p1", "barracks", _start_p1 + Vector2(160, -100 + i * 100))
	for i in range(starting_p2_barracks):
		_spawn_building("p2", "barracks", _start_p2 + Vector2(-160, -100 + i * 100))
	for i in range(starting_p1_factory):
		_spawn_building("p1", "factory", _start_p1 + Vector2(260, -120 + i * 120))
	for i in range(starting_p2_factory):
		_spawn_building("p2", "factory", _start_p2 + Vector2(-260, -120 + i * 120))
	for i in range(starting_p1_supply):
		_spawn_building("p1", "supply", _start_p1 + Vector2(120, 140 + i * 90))
	for i in range(starting_p2_supply):
		_spawn_building("p2", "supply", _start_p2 + Vector2(-120, 140 + i * 90))

func _spawn_building(team_id: String, build_id: String, pos: Vector2) -> void:
	var building := Building.new()
	building.team_id = team_id
	building.build_id = build_id
	building.visual_scene_path = _get_building_visual_path(build_id)
	building.visual_base_size = _get_building_visual_base_size(build_id)
	if build_id == "barracks":
		building.size = Vector2(90, 90)
		building.fill_color = p1_hq_color if team_id == "p1" else p2_hq_color
		building.production_type = "mixed"
		building.wait_mode = false
	elif build_id == "factory":
		building.size = Vector2(140, 110)
		building.fill_color = Color(0.6, 0.45, 0.2, 1.0)
		building.vehicle_production_type = "mixed"
	elif build_id == "supply":
		building.size = Vector2(100, 80)
		building.fill_color = Color(0.7, 0.6, 0.2, 1.0)
	elif build_id == "command_center":
		building.size = Vector2(130, 110)
		building.fill_color = Color(0.35, 0.35, 0.5, 1.0)
	elif build_id.begins_with("defense"):
		building.size = Vector2(70, 70)
		building.fill_color = _get_defense_color(build_id)
		var turret := _spawn_defense_turret(team_id, pos, build_id)
		building.set_meta("linked_turret", turret)
	else:
		building.size = Vector2(80, 80)
		building.fill_color = Color(0.2, 0.6, 0.35, 1.0)
	building.max_hp = _get_building_hp(build_id)
	building.position = pos
	_structures.add_child(building)
	_increment_building_count(team_id, build_id)

func _update_infantry(delta: float) -> void:
	if GameState.winner != "":
		return
	_infantry_pool_p1 = minf(_infantry_pool_p1 + GameState.p1_infantry_prod * delta, max_infantry_pool)
	_infantry_pool_p2 = minf(_infantry_pool_p2 + GameState.p2_infantry_prod * delta, max_infantry_pool)
	_infantry_pool_p1 = _spawn_from_pool("p1", _infantry_pool_p1)
	_infantry_pool_p2 = _spawn_from_pool("p2", _infantry_pool_p2)
	GameState.p1_infantry_pool = _infantry_pool_p1
	GameState.p2_infantry_pool = _infantry_pool_p2
	GameState.p1_infantry_eta = _pool_eta(GameState.p1_infantry_prod, _infantry_pool_p1)
	GameState.p2_infantry_eta = _pool_eta(GameState.p2_infantry_prod, _infantry_pool_p2)

func _update_factory_queue(delta: float) -> void:
	if GameState.winner != "":
		return
	if _factory_queue_p1.is_empty():
		_vehicle_progress_p1 = 0.0
	else:
		_vehicle_progress_p1 += GameState.p1_vehicle_prod * delta
		_vehicle_progress_p1 = _spawn_from_factory_queue("p1", _vehicle_progress_p1)
	if _factory_queue_p2.is_empty():
		_vehicle_progress_p2 = 0.0
	else:
		_vehicle_progress_p2 += GameState.p2_vehicle_prod * delta
		_vehicle_progress_p2 = _spawn_from_factory_queue("p2", _vehicle_progress_p2)

func _update_ai_queue(delta: float) -> void:
	_ai_queue_timer -= delta
	if _ai_queue_timer > 0.0:
		return
	_ai_queue_timer = ai_queue_interval
	if GameState.p2_factory <= 0:
		return
	if _factory_queue_p2.size() >= mini(3, factory_queue_max):
		return
	queue_vehicle("p2", "mixed")

func _spawn_from_pool(team_id: String, pool: float) -> float:
	if pool < 1.0:
		return pool
	if not _hq_alive(_hq_p1) and team_id == "p1":
		return 0.0
	if not _hq_alive(_hq_p2) and team_id == "p2":
		return 0.0
	while pool >= 1.0:
		if unit_spawn_limit > 0 and _count_units(team_id) >= unit_spawn_limit:
			break
		if not _has_team_credits(team_id, infantry_unit_cost):
			break
		if not _spawn_infantry(team_id):
			break
		_deduct_team_credits(team_id, infantry_unit_cost)
		pool -= 1.0
	return pool

func _spawn_infantry(team_id: String) -> bool:
	var barracks := _get_barracks_for_spawn(team_id)
	if barracks == null:
		return false
	_spawn_unit(team_id, "infantry", barracks)
	return true

func _spawn_from_factory_queue(team_id: String, progress: float) -> float:
	var queue := _get_factory_queue(team_id)
	if queue.is_empty():
		return 0.0
	while progress >= 1.0 and not queue.is_empty():
		if unit_spawn_limit > 0 and _count_units(team_id) >= unit_spawn_limit:
			break
		var entry = queue[0]
		var vehicle_type := "mixed"
		var factory: Building = null
		if typeof(entry) == TYPE_DICTIONARY:
			vehicle_type = str(entry.get("type", "mixed"))
			var candidate = entry.get("factory")
			if candidate is Building and is_instance_valid(candidate):
				factory = candidate
		elif typeof(entry) == TYPE_STRING:
			vehicle_type = str(entry)
		_spawn_unit(team_id, "vehicle", factory, vehicle_type)
		queue.remove_at(0)
		progress -= 1.0
	_set_factory_queue(team_id, queue)
	return progress

func _pool_eta(rate: float, pool: float) -> float:
	if rate <= 0.0:
		return -1.0
	if pool >= 1.0:
		return 0.0
	return maxf(0.0, (1.0 - pool) / rate)

func _spawn_unit(team_id: String, unit_kind: String, source_building: Building = null, unit_type_id: String = "") -> void:
	var unit := Unit.new()
	unit.team_id = team_id
	unit.home_pos = _start_p1 if team_id == "p1" else _start_p2
	if unit_kind == "vehicle":
		var factory := source_building
		var production_type := unit_type_id
		if production_type == "" and factory != null and is_instance_valid(factory):
			production_type = factory.vehicle_production_type
		var type_id := _resolve_vehicle_type(production_type)
		var stats := _get_vehicle_def(type_id)
		var range_role := str(stats.get("range_role", "short"))
		var range_mult := _range_multiplier(range_role, vehicle_long_multiplier, vehicle_mid_multiplier)
		var attack_range := vehicle_attack_range * range_mult
		unit.unit_kind = "vehicle"
		unit.unit_type = type_id
		unit.range_role = range_role
		unit.range_multiplier = range_mult
		unit.prefers_vehicle = bool(stats.get("prefers_vehicle", false))
		unit.prefers_infantry = bool(stats.get("prefers_infantry", false))
		unit.damage_vs_infantry = float(stats.get("damage_vs_infantry", 1.0))
		unit.damage_vs_vehicle = float(stats.get("damage_vs_vehicle", 1.0))
		unit.damage_vs_structure = float(stats.get("damage_vs_structure", 1.0))
		unit.speed = float(stats.get("speed", vehicle_speed))
		unit.max_hp = float(stats.get("max_hp", vehicle_hp))
		unit.attack_damage = float(stats.get("damage", vehicle_damage))
		unit.attack_range = attack_range
		unit.attack_cooldown = float(stats.get("cooldown", vehicle_attack_cooldown))
		unit.body_radius = vehicle_body_radius
		unit.color = p1_vehicle_color if team_id == "p1" else p2_vehicle_color
		unit.aggro_range = maxf(260.0, attack_range * 1.05)
		unit.chase_leash = maxf(360.0, attack_range * 1.1)
		unit.structure_aggro_range = maxf(320.0, attack_range * 1.1)
		unit.shot_width = float(stats.get("shot_width", 3.0))
		unit.shot_lifetime = float(stats.get("shot_lifetime", 0.14))
		var shot_color = stats.get("shot_color", Color(1.0, 0.8, 0.5, 0.8))
		if shot_color is Color:
			unit.shot_color = shot_color
		unit.position = _spawn_at_factory(team_id, factory)
		unit.visual_scene_path = _get_unit_visual_path("vehicle")
		unit.visual_base_radius = 14.0
	else:
		var barracks := source_building
		var production_type := "mixed"
		var wait_mode := false
		var spawn_origin := unit.home_pos
		if barracks != null and is_instance_valid(barracks):
			production_type = barracks.production_type
			wait_mode = barracks.wait_mode
			spawn_origin = barracks.global_position
		var type_id := _resolve_infantry_type(production_type)
		var stats := _get_infantry_def(type_id)
		var range_role := str(stats.get("range_role", "short"))
		var range_mult := _range_multiplier(range_role, infantry_long_multiplier, infantry_mid_multiplier)
		var attack_range := unit_attack_range * range_mult
		unit.unit_kind = "infantry"
		unit.unit_type = type_id
		unit.range_role = range_role
		unit.range_multiplier = range_mult
		unit.prefers_vehicle = bool(stats.get("prefers_vehicle", false))
		unit.prefers_infantry = bool(stats.get("prefers_infantry", false))
		unit.damage_vs_infantry = float(stats.get("damage_vs_infantry", 1.0))
		unit.damage_vs_vehicle = float(stats.get("damage_vs_vehicle", 1.0))
		unit.damage_vs_structure = float(stats.get("damage_vs_structure", 1.0))
		unit.speed = float(stats.get("speed", unit_speed))
		unit.max_hp = float(stats.get("max_hp", unit_hp))
		unit.attack_damage = float(stats.get("damage", unit_damage))
		unit.attack_range = attack_range
		unit.attack_cooldown = float(stats.get("cooldown", unit_attack_cooldown))
		unit.body_radius = unit_body_radius
		unit.color = p1_unit_color if team_id == "p1" else p2_unit_color
		unit.aggro_range = maxf(220.0, attack_range * 1.05)
		unit.chase_leash = maxf(320.0, attack_range * 1.1)
		unit.structure_aggro_range = maxf(260.0, attack_range * 1.1)
		unit.shot_width = float(stats.get("shot_width", 2.0))
		unit.shot_lifetime = float(stats.get("shot_lifetime", 0.12))
		var shot_color = stats.get("shot_color", Color(1.0, 1.0, 1.0, 0.75))
		if shot_color is Color:
			unit.shot_color = shot_color
		unit.position = _spawn_at_barracks(team_id, barracks)
		if wait_mode:
			var wait_pos := _get_wait_point(team_id, spawn_origin)
			unit.assign_hold(wait_pos, infantry_wait_duration)
		unit.visual_scene_path = _get_unit_visual_path("infantry")
		unit.visual_base_radius = 8.0
	unit.enemy_hq = _hq_p2 if team_id == "p1" else _hq_p1
	unit.rally_target = _rally_p1 if team_id == "p1" else _rally_p2
	_units.add_child(unit)

func _spawn_at_barracks(team_id: String, barracks: Building = null) -> Vector2:
	if barracks != null and is_instance_valid(barracks):
		return _offset_spawn(barracks.global_position)
	return _spawn_at_building(team_id, "barracks", _start_p1 if team_id == "p1" else _start_p2)

func _spawn_at_factory(team_id: String, factory: Building = null) -> Vector2:
	if factory != null and is_instance_valid(factory):
		return _offset_spawn(factory.global_position)
	return _spawn_at_building(team_id, "factory", _start_p1 if team_id == "p1" else _start_p2)

func _spawn_at_building(team_id: String, build_id: String, fallback: Vector2) -> Vector2:
	var group_name := "building_%s_%s" % [build_id, team_id]
	var buildings := get_tree().get_nodes_in_group(group_name)
	if buildings.is_empty():
		return _offset_spawn(fallback)
	var index := _rng.randi_range(0, buildings.size() - 1)
	var building := buildings[index] as Node2D
	if building == null:
		return _offset_spawn(fallback)
	return _offset_spawn(building.global_position)

func _get_barracks_for_spawn(team_id: String) -> Building:
	var group_name := "building_barracks_%s" % team_id
	var nodes := get_tree().get_nodes_in_group(group_name)
	var barracks_list: Array[Building] = []
	for node in nodes:
		var barracks := node as Building
		if barracks != null and is_instance_valid(barracks):
			barracks_list.append(barracks)
	if barracks_list.is_empty():
		return null
	var index := _barracks_spawn_index_p1 if team_id == "p1" else _barracks_spawn_index_p2
	index = index % barracks_list.size()
	var chosen := barracks_list[index]
	if team_id == "p1":
		_barracks_spawn_index_p1 = (index + 1) % barracks_list.size()
	else:
		_barracks_spawn_index_p2 = (index + 1) % barracks_list.size()
	return chosen

func _get_wait_point(team_id: String, origin: Vector2) -> Vector2:
	var zone := _p1_build_zone if team_id == "p1" else _p2_build_zone
	var enemy_pos := _start_p2 if team_id == "p1" else _start_p1
	if zone == Rect2():
		var dir := (enemy_pos - origin).normalized()
		return origin + dir * 120.0
	var edge_x := zone.position.x + zone.size.x if enemy_pos.x >= origin.x else zone.position.x
	var pad := maxf(0.0, wait_edge_padding)
	var inside_x := edge_x - pad if enemy_pos.x >= origin.x else edge_x + pad
	var min_y := zone.position.y + pad
	var max_y := zone.position.y + zone.size.y - pad
	var clamped_y := clampf(origin.y, min_y, max_y)
	return Vector2(inside_x, clamped_y)

func _offset_spawn(pos: Vector2) -> Vector2:
	return pos + Vector2(
		_rng.randf_range(-unit_spawn_spread, unit_spawn_spread),
		_rng.randf_range(-unit_spawn_spread, unit_spawn_spread)
	)

func _count_units(team_id: String) -> int:
	var group_name := "units_%s" % team_id
	return get_tree().get_nodes_in_group(group_name).size()

func _update_production() -> void:
	GameState.p1_infantry_prod = GameState.p1_barracks * barracks_infantry_rate
	GameState.p2_infantry_prod = GameState.p2_barracks * barracks_infantry_rate
	GameState.p1_vehicle_prod = GameState.p1_factory * factory_vehicle_rate
	GameState.p2_vehicle_prod = GameState.p2_factory * factory_vehicle_rate
	GameState.p1_total_prod = GameState.p1_infantry_prod + GameState.p1_vehicle_prod
	GameState.p2_total_prod = GameState.p2_infantry_prod + GameState.p2_vehicle_prod

func _update_income_rate(delta: float) -> void:
	_income_timer += delta
	if _income_timer < 1.0:
		return
	var sample_time := _income_timer
	GameState.p1_income_rate = _income_accum_p1 / sample_time
	GameState.p2_income_rate = _income_accum_p2 / sample_time
	_income_accum_p1 = 0.0
	_income_accum_p2 = 0.0
	_income_timer = 0.0

func _sync_collectors(team_id: String) -> void:
	var desired := _get_supply_count(team_id) * collectors_per_supply
	var collectors := _collectors_p1 if team_id == "p1" else _collectors_p2
	while collectors.size() < desired:
		var collector := Collector.new()
		collector.team_id = team_id
		collector.speed = collector_speed
		collector.carry_capacity = collector_capacity
		collector.harvest_time = collector_harvest_time
		collector.color = p1_collector_color if team_id == "p1" else p2_collector_color
		collector.visual_scene_path = _get_unit_visual_path("collector")
		collector.visual_base_radius = 10.0
		var base_pos := _start_p1 if team_id == "p1" else _start_p2
		var supply := _get_supply_for_spawn(team_id)
		if supply != null and is_instance_valid(supply):
			base_pos = supply.global_position
		collector.global_position = _offset_spawn(base_pos)
		collector.configure(self, team_id, base_pos)
		_units.add_child(collector)
		collectors.append(collector)
	if team_id == "p1":
		_collectors_p1 = collectors
	else:
		_collectors_p2 = collectors

func _get_supply_for_spawn(team_id: String) -> Building:
	var group_name := "building_supply_%s" % team_id
	var nodes := get_tree().get_nodes_in_group(group_name)
	var supply_list: Array[Building] = []
	for node in nodes:
		var supply := node as Building
		if supply != null and is_instance_valid(supply):
			supply_list.append(supply)
	if supply_list.is_empty():
		return null
	var index := _supply_spawn_index_p1 if team_id == "p1" else _supply_spawn_index_p2
	index = index % supply_list.size()
	var chosen := supply_list[index]
	if team_id == "p1":
		_supply_spawn_index_p1 = (index + 1) % supply_list.size()
	else:
		_supply_spawn_index_p2 = (index + 1) % supply_list.size()
	return chosen

func _update_state_counters() -> void:
	GameState.p1_collectors = _collectors_p1.size()
	GameState.p2_collectors = _collectors_p2.size()
	GameState.p1_factory_queue = _factory_queue_p1.size()
	GameState.p2_factory_queue = _factory_queue_p2.size()
	GameState.total_supply_remaining = _supply_remaining

func _update_hq_state() -> void:
	if _hq_p1 != null and not is_instance_valid(_hq_p1):
		_hq_p1 = null
	if _hq_p2 != null and not is_instance_valid(_hq_p2):
		_hq_p2 = null
	var p1_alive := _hq_alive(_hq_p1)
	var p2_alive := _hq_alive(_hq_p2)
	GameState.p1_hq_hp = int(_hq_p1.hp) if p1_alive else 0
	GameState.p2_hq_hp = int(_hq_p2.hp) if p2_alive else 0
	if not p1_alive and GameState.winner == "":
		GameState.winner = "P2"
	elif not p2_alive and GameState.winner == "":
		GameState.winner = "P1"

func _hq_alive(hq) -> bool:
	return hq != null and is_instance_valid(hq) and hq.hp > 0.0

func _has_team_credits(team_id: String, cost: int) -> bool:
	return GameState.p1_credits >= cost if team_id == "p1" else GameState.p2_credits >= cost

func _deduct_team_credits(team_id: String, cost: int) -> void:
	if team_id == "p1":
		GameState.p1_credits = maxi(0, GameState.p1_credits - cost)
	else:
		GameState.p2_credits = maxi(0, GameState.p2_credits - cost)

func _get_factory_queue(team_id: String) -> Array[Dictionary]:
	return _factory_queue_p1 if team_id == "p1" else _factory_queue_p2

func _set_factory_queue(team_id: String, queue: Array[Dictionary]) -> void:
	if team_id == "p1":
		_factory_queue_p1 = queue
	else:
		_factory_queue_p2 = queue

func _get_factory_count(team_id: String) -> int:
	return GameState.p1_factory if team_id == "p1" else GameState.p2_factory

func _get_supply_count(team_id: String) -> int:
	return GameState.p1_supply if team_id == "p1" else GameState.p2_supply

func _set_rally_point(team_id: String, pos: Vector2) -> void:
	if team_id == "p1":
		_rally_p1 = pos
	else:
		_rally_p2 = pos
	queue_redraw()

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
	_load_start_positions(data)
	_load_build_zones(data)
	_load_rally_targets(data)
	_load_resource_nodes(data)

func _load_start_positions(data: Dictionary) -> void:
	var starts: Array = data.get("start_positions", [])
	for start in starts:
		if typeof(start) != TYPE_DICTIONARY:
			continue
		var id := str(start.get("id", ""))
		var pos := Vector2(float(start.get("x", 0.0)), float(start.get("y", 0.0)))
		if id == "p1":
			_start_p1 = pos
		elif id == "p2":
			_start_p2 = pos

func _load_build_zones(data: Dictionary) -> void:
	_p1_build_zone = Rect2()
	_p2_build_zone = Rect2()
	var zones: Array = data.get("build_zones", [])
	for zone in zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		var zone_id := str(zone.get("id", ""))
		if zone_id != "p1" and zone_id != "p2":
			continue
		if zone_id == "p1":
			_p1_build_zone = Rect2(
				Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
				Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
			)
		else:
			_p2_build_zone = Rect2(
				Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
				Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
			)

func _load_rally_targets(data: Dictionary) -> void:
	var rally_targets: Array = data.get("rally_targets", [])
	for target in rally_targets:
		if typeof(target) != TYPE_DICTIONARY:
			continue
		var id := str(target.get("id", ""))
		var pos := Vector2(float(target.get("x", 0.0)), float(target.get("y", 0.0)))
		if id == "p1_push":
			_rally_p1 = pos
		elif id == "p2_push":
			_rally_p2 = pos
	if _rally_p1 == Vector2.ZERO:
		_rally_p1 = _start_p2
	if _rally_p2 == Vector2.ZERO:
		_rally_p2 = _start_p1

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

func _setup_base_vision() -> void:
	if not base_vision_enabled:
		return
	if _p1_build_zone == Rect2():
		return
	var center := _p1_build_zone.position + (_p1_build_zone.size * 0.5)
	var radius := (_p1_build_zone.size.length() * 0.5) + base_vision_padding
	if _base_vision != null and is_instance_valid(_base_vision):
		_base_vision.queue_free()
	_base_vision = BaseVision.new()
	_base_vision.vision_radius = radius
	_base_vision.light_energy = base_vision_energy
	_base_vision.position = center
	add_child(_base_vision)

func _draw_resource_nodes() -> void:
	for node in _resource_nodes:
		var pos := node.get("pos", Vector2.ZERO) as Vector2
		var remaining := float(node.get("amount", 0.0))
		var initial := float(node.get("initial", remaining))
		if initial <= 0.0:
			continue
		var ratio := clampf(remaining / initial, 0.0, 1.0)
		var radius := lerpf(resource_min_radius, resource_max_radius, ratio)
		var color := resource_full_color.lerp(resource_empty_color, 1.0 - ratio)
		var poly := _regular_polygon_points(pos, radius, 6, TAU / 12.0)
		draw_colored_polygon(poly, color)
		var outline := poly.duplicate()
		if outline.size() > 0:
			outline.append(poly[0])
			draw_polyline(outline, Color(0.1, 0.1, 0.1, 0.6), 2.0)

func _regular_polygon_points(center: Vector2, radius: float, sides: int, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if sides < 3 or radius <= 0.0:
		return points
	for i in range(sides):
		var ang := rotation + TAU * float(i) / float(sides)
		points.append(center + Vector2(cos(ang), sin(ang)) * radius)
	return points

func _increment_building_count(team_id: String, build_id: String) -> void:
	if team_id == "p1":
		GameState.p1_building_count += 1
		match build_id:
			"barracks":
				GameState.p1_barracks += 1
			"factory":
				GameState.p1_factory += 1
			"supply":
				GameState.p1_supply += 1
			"power":
				GameState.p1_power += 1
			"command_center":
				GameState.p1_command_center += 1
			_:
				if build_id.begins_with("defense"):
					GameState.p1_defense += 1
	else:
		GameState.p2_building_count += 1
		match build_id:
			"barracks":
				GameState.p2_barracks += 1
			"factory":
				GameState.p2_factory += 1
			"supply":
				GameState.p2_supply += 1
			"power":
				GameState.p2_power += 1
			"command_center":
				GameState.p2_command_center += 1
			_:
				if build_id.begins_with("defense"):
					GameState.p2_defense += 1

func _spawn_defense_turret(team_id: String, pos: Vector2, build_id: String = "defense") -> DefenseTurret:
	var turret := DefenseTurret.new()
	turret.team_id = team_id
	var profile := _get_defense_profile(build_id)
	var base_range := float(profile.get("range", defense_range)) * defense_range_multiplier
	turret.attack_range = _compute_defense_range(team_id, pos, base_range)
	turret.damage = float(profile.get("damage", defense_damage))
	turret.fire_rate = float(profile.get("fire_rate", defense_fire_rate)) * defense_fire_rate_multiplier
	turret.missile_speed = float(profile.get("missile_speed", 260.0))
	turret.missile_turn_rate = float(profile.get("missile_turn_rate", 10.0))
	var missile_color = profile.get("missile_color")
	if missile_color is Color:
		turret.missile_color = missile_color
	turret.missile_warhead_size = str(profile.get("warhead_size", "medium"))
	turret.prefers_infantry = bool(profile.get("prefers_infantry", false))
	turret.prefers_vehicle = bool(profile.get("prefers_vehicle", false))
	turret.damage_vs_infantry = float(profile.get("damage_vs_infantry", 1.0))
	turret.damage_vs_vehicle = float(profile.get("damage_vs_vehicle", 1.0))
	turret.hitscan_enabled = bool(profile.get("hitscan", false))
	var shot_color = profile.get("shot_color")
	if shot_color is Color:
		turret.shot_color = shot_color
	turret.shot_width = float(profile.get("shot_width", turret.shot_width))
	turret.shot_lifetime = float(profile.get("shot_lifetime", turret.shot_lifetime))
	turret.visual_scene_path = _get_turret_visual_path(build_id)
	turret.visual_base_radius = 16.0
	turret.position = pos
	_structures.add_child(turret)
	return turret

func _get_defense_profile(build_id: String) -> Dictionary:
	match build_id:
		"defense_gun":
			return {
				"range": 150.0,
				"damage": 6.0,
				"fire_rate": 0.25,
				"missile_speed": 320.0,
				"missile_turn_rate": 12.0,
				"missile_color": Color(1.0, 0.95, 0.7, 0.9),
				"warhead_size": "small",
				"hitscan": true,
				"shot_color": Color(1.0, 0.95, 0.7, 0.9),
				"shot_width": 2.2,
				"shot_lifetime": 0.1,
				"prefers_infantry": true,
				"damage_vs_infantry": 1.5,
				"damage_vs_vehicle": 0.6,
			}
		"defense_laser":
			return {
				"range": 190.0,
				"damage": 16.0,
				"fire_rate": 1.1,
				"missile_speed": 340.0,
				"missile_turn_rate": 14.0,
				"missile_color": Color(0.4, 0.9, 1.0, 1.0),
				"warhead_size": "small",
				"damage_vs_infantry": 1.1,
				"damage_vs_vehicle": 1.0,
			}
		"defense_missile", "defense":
			return {
				"range": defense_range,
				"damage": defense_damage,
				"fire_rate": defense_fire_rate,
				"missile_speed": 260.0,
				"missile_turn_rate": 9.0,
				"missile_color": Color(1.0, 0.6, 0.2, 1.0),
				"warhead_size": "medium",
				"prefers_vehicle": true,
				"damage_vs_infantry": 0.7,
				"damage_vs_vehicle": 1.6,
			}
	return {
		"range": defense_range,
		"damage": defense_damage,
		"fire_rate": defense_fire_rate,
		"missile_speed": 260.0,
		"missile_turn_rate": 9.0,
		"missile_color": Color(1.0, 0.6, 0.2, 1.0),
		"warhead_size": "medium",
		"prefers_vehicle": true,
		"damage_vs_infantry": 0.7,
		"damage_vs_vehicle": 1.6,
	}

func _get_defense_color(build_id: String) -> Color:
	match build_id:
		"defense_gun":
			return Color(0.35, 0.5, 0.35, 1.0)
		"defense_laser":
			return Color(0.2, 0.6, 0.65, 1.0)
		_:
			return defense_color

func _compute_defense_range(team_id: String, pos: Vector2, base_range: float) -> float:
	var zone := _p1_build_zone if team_id == "p1" else _p2_build_zone
	if zone == Rect2():
		return base_range
	var left := pos.x - zone.position.x
	var right := (zone.position.x + zone.size.x) - pos.x
	var top := pos.y - zone.position.y
	var bottom := (zone.position.y + zone.size.y) - pos.y
	var min_edge := minf(minf(left, right), minf(top, bottom))
	var capped := maxf(0.0, min_edge * 0.9)
	return minf(base_range, capped)

func _get_building_hp(build_id: String) -> float:
	match build_id:
		"barracks":
			return 220.0
		"factory":
			return 260.0
		"supply":
			return 200.0
		"power":
			return 180.0
		"command_center":
			return 280.0
		"defense_gun":
			return 220.0
		"defense_missile":
			return 240.0
		"defense_laser":
			return 230.0
		"defense":
			return 240.0
	return 200.0

func _roll_range_role(long_ratio: float, mid_ratio: float) -> String:
	var roll := _rng.randf()
	if roll < long_ratio:
		return "long"
	if roll < long_ratio + mid_ratio:
		return "mid"
	return "short"

func _range_multiplier(role: String, long_mult: float, mid_mult: float) -> float:
	if role == "long":
		return long_mult
	if role == "mid":
		return mid_mult
	return 1.0

func _resolve_infantry_type(requested: String) -> String:
	if requested == "mixed":
		var long_ratio := clampf(infantry_long_ratio, 0.0, 1.0)
		var mid_ratio := clampf(infantry_mid_ratio, 0.0, 1.0 - long_ratio)
		var roll := _rng.randf()
		if roll < long_ratio:
			return "sniper"
		if roll < long_ratio + mid_ratio:
			return "rocket"
		return "rifle"
	if requested in ["rifle", "sniper", "rocket"]:
		return requested
	return "rifle"

func _resolve_vehicle_type(requested: String) -> String:
	if requested == "mixed" or requested == "":
		var long_ratio := clampf(vehicle_long_ratio, 0.0, 1.0)
		var mid_ratio := clampf(vehicle_mid_ratio, 0.0, 1.0 - long_ratio)
		var roll := _rng.randf()
		if roll < long_ratio:
			return "artillery"
		if roll < long_ratio + mid_ratio:
			return "ifv"
		return "tank"
	if requested == "apc":
		return "ifv"
	if requested in ["tank", "artillery", "ifv"]:
		return requested
	return "tank"

func _get_infantry_def(type_id: String) -> Dictionary:
	match type_id:
		"sniper":
			return {
				"range_role": "long",
				"max_hp": unit_hp * 0.8,
				"damage": unit_damage * 2.2,
				"cooldown": unit_attack_cooldown * 1.8,
				"speed": unit_speed * 0.85,
				"shot_color": Color(1.0, 0.95, 0.6, 0.85),
				"shot_width": 2.5,
				"shot_lifetime": 0.2,
				"prefers_infantry": true,
				"damage_vs_infantry": 2.0,
				"damage_vs_vehicle": 0.5,
				"damage_vs_structure": 0.6,
			}
		"rocket":
			return {
				"range_role": "mid",
				"max_hp": unit_hp * 1.15,
				"damage": unit_damage * 1.6,
				"cooldown": unit_attack_cooldown * 1.4,
				"speed": unit_speed * 0.8,
				"shot_color": Color(1.0, 0.7, 0.3, 0.85),
				"shot_width": 3.0,
				"shot_lifetime": 0.18,
				"prefers_vehicle": true,
				"damage_vs_infantry": 0.7,
				"damage_vs_vehicle": 1.8,
				"damage_vs_structure": 1.2,
			}
		_:
			return {
				"range_role": "short",
				"max_hp": unit_hp,
				"damage": unit_damage * 0.6,
				"cooldown": unit_attack_cooldown * 0.45,
				"speed": unit_speed,
				"shot_color": Color(1.0, 1.0, 1.0, 0.7),
				"shot_width": 1.6,
				"shot_lifetime": 0.08,
				"prefers_infantry": true,
				"damage_vs_infantry": 1.3,
				"damage_vs_vehicle": 0.6,
				"damage_vs_structure": 0.8,
			}

func _get_vehicle_def(type_id: String) -> Dictionary:
	match type_id:
		"artillery":
			return {
				"range_role": "long",
				"max_hp": vehicle_hp * 0.85,
				"damage": vehicle_damage * 2.4,
				"cooldown": vehicle_attack_cooldown * 1.8,
				"speed": vehicle_speed * 0.75,
				"shot_color": Color(1.0, 0.6, 0.35, 0.9),
				"shot_width": 4.0,
				"shot_lifetime": 0.22,
				"damage_vs_infantry": 1.1,
				"damage_vs_vehicle": 1.3,
				"damage_vs_structure": 1.8,
			}
		"ifv":
			return {
				"range_role": "mid",
				"max_hp": vehicle_hp * 1.1,
				"damage": vehicle_damage * 1.2,
				"cooldown": vehicle_attack_cooldown * 1.1,
				"speed": vehicle_speed * 1.1,
				"shot_color": Color(1.0, 0.8, 0.5, 0.85),
				"shot_width": 3.0,
				"shot_lifetime": 0.16,
				"prefers_infantry": true,
				"damage_vs_infantry": 1.6,
				"damage_vs_vehicle": 0.7,
				"damage_vs_structure": 0.8,
			}
		_:
			return {
				"range_role": "short",
				"max_hp": vehicle_hp,
				"damage": vehicle_damage,
				"cooldown": vehicle_attack_cooldown,
				"speed": vehicle_speed,
				"shot_color": Color(1.0, 0.85, 0.6, 0.8),
				"shot_width": 3.0,
				"shot_lifetime": 0.14,
				"prefers_vehicle": true,
				"damage_vs_infantry": 0.9,
				"damage_vs_vehicle": 1.2,
				"damage_vs_structure": 1.1,
			}

func get_infantry_type_options() -> Array:
	return [
		{"id": "mixed", "name": "Mixed"},
		{"id": "rifle", "name": "Rifle"},
		{"id": "sniper", "name": "Sniper"},
		{"id": "rocket", "name": "Rocket"},
	]

func get_vehicle_type_options() -> Array:
	return [
		{"id": "mixed", "name": "Mixed"},
		{"id": "tank", "name": "Tank"},
		{"id": "artillery", "name": "Artillery"},
		{"id": "ifv", "name": "IFV"},
	]

func _get_unit_visual_path(unit_kind: String) -> String:
	match unit_kind:
		"infantry":
			return "res://scenes/units/infantry_visual.tscn"
		"vehicle":
			return "res://scenes/units/vehicle_visual.tscn"
		"collector":
			return "res://scenes/units/collector_visual.tscn"
	return ""

func _get_building_visual_path(build_id: String) -> String:
	match build_id:
		"barracks":
			return "res://scenes/buildings/barracks_visual.tscn"
		"factory":
			return "res://scenes/buildings/factory_visual.tscn"
		"supply":
			return "res://scenes/buildings/supply_visual.tscn"
		"power":
			return "res://scenes/buildings/power_visual.tscn"
		"command_center":
			return "res://scenes/buildings/command_center_visual.tscn"
	return ""

func _get_turret_visual_path(build_id: String) -> String:
	if build_id.begins_with("defense"):
		return "res://scenes/buildings/turret_visual.tscn"
	return ""

func _get_building_visual_base_size(build_id: String) -> Vector2:
	match build_id:
		"barracks":
			return Vector2(100, 90)
		"factory":
			return Vector2(140, 110)
		"supply":
			return Vector2(100, 80)
		"power":
			return Vector2(80, 80)
		"command_center":
			return Vector2(130, 110)
	return Vector2.ZERO

func _get_hq_visual_path() -> String:
	return "res://scenes/buildings/hq_visual.tscn"

func _update_defenses(delta: float) -> void:
	for turret in get_tree().get_nodes_in_group("defense_turret"):
		if turret is DefenseTurret:
			turret.update_targeting(delta)

func _update_visibility() -> void:
	if not fog_enabled or not fog_hide_enemies:
		_set_enemy_visibility(true)
		return
	var sources := _get_vision_sources()
	_apply_visibility_to_group("units_p2", sources)
	_apply_visibility_to_group("collectors_p2", sources)
	_apply_visibility_to_group("defense_turret_p2", sources)
	_apply_visibility_to_buildings("p2", sources)
	_apply_visibility_to_hq("p2", sources)

func _get_vision_sources() -> Array:
	var sources: Array = []
	for node in get_tree().get_nodes_in_group("vision_p1"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_vision_radius"):
			continue
		var radius := float(node.get_vision_radius())
		if radius <= 0.0:
			continue
		sources.append({
			"pos": node.global_position,
			"radius_sq": radius * radius,
		})
	return sources

func _apply_visibility_to_group(group_name: String, sources: Array) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node == null or not is_instance_valid(node):
			continue
		node.visible = _is_in_vision(node.global_position, sources)

func _apply_visibility_to_buildings(team_id: String, sources: Array) -> void:
	for node in get_tree().get_nodes_in_group("building"):
		if not (node is Building):
			continue
		if node.team_id != team_id:
			continue
		node.visible = _is_in_vision(node.global_position, sources)

func _apply_visibility_to_hq(team_id: String, sources: Array) -> void:
	for node in get_tree().get_nodes_in_group("hq"):
		if not (node is HQ):
			continue
		if node.team_id != team_id:
			continue
		node.visible = _is_in_vision(node.global_position, sources)

func _is_in_vision(pos: Vector2, sources: Array) -> bool:
	if _p1_build_zone != Rect2():
		var base_rect := _p1_build_zone.grow(base_vision_padding)
		if base_rect.has_point(pos):
			return true
	if sources.is_empty():
		return false
	for source in sources:
		var src_pos := source.get("pos", Vector2.ZERO) as Vector2
		var radius_sq := float(source.get("radius_sq", 0.0))
		if pos.distance_squared_to(src_pos) <= radius_sq:
			return true
	return false

func _set_enemy_visibility(is_visible: bool) -> void:
	for node in get_tree().get_nodes_in_group("units_p2"):
		if node != null and is_instance_valid(node):
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("collectors_p2"):
		if node != null and is_instance_valid(node):
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("defense_turret_p2"):
		if node != null and is_instance_valid(node):
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("building"):
		if node is Building and node.team_id == "p2":
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("hq"):
		if node is HQ and node.team_id == "p2":
			node.visible = is_visible
