class_name BuildController
extends Node2D

signal build_mode_changed(active_id: String)

@export var map_path := "res://data/maps/test_map.json"
@export var build_zone_id := "p1"
@export var team_id := "p1"
@export var placement_snap := 10.0
@export var show_ghost := true
@export var render_2d := true

@export var ghost_valid_fill := Color(0.2, 0.9, 0.2, 0.3)
@export var ghost_invalid_fill := Color(0.9, 0.2, 0.2, 0.3)
@export var ghost_outline := Color(0.95, 0.95, 0.95, 0.7)
@export var ghost_outline_width := 2.0
@export var defense_range_multiplier := 1.5
@export var defense_fire_rate_multiplier := 0.75
@export var cancel_drag_threshold := 8.0

var _build_zones: Array = []
var _buildings: Array = []
var _active_build_id := ""
var _ghost_pos := Vector2.ZERO
var _ghost_valid := false
var _primary_zone := Rect2()
var _world_input: Node
var _cancel_dragging := false
var _cancel_start := Vector2.ZERO

var _build_order := [
	"barracks",
	"factory",
	"airfield",
	"supply",
	"power",
	"command_center",
	"defense_gun",
	"defense_missile",
	"defense_laser"
]
var _build_defs := {
	"barracks": {
		"name": "Barracks",
		"size": Vector2(90, 90),
		"cost": 150,
		"hp": 220.0,
		"color": Color(0.25, 0.35, 0.7, 1.0),
	},
	"factory": {
		"name": "Factory",
		"size": Vector2(140, 110),
		"cost": 300,
		"hp": 260.0,
		"color": Color(0.6, 0.45, 0.2, 1.0),
	},
	"airfield": {
		"name": "Airfield",
		"size": Vector2(432, 288),
		"cost": 250,
		"hp": 260.0,
		"color": Color(0.28, 0.38, 0.55, 1.0),
	},
	"supply": {
		"name": "Supply Depot",
		"size": Vector2(100, 80),
		"cost": 200,
		"hp": 200.0,
		"color": Color(0.7, 0.6, 0.2, 1.0),
	},
	"power": {
		"name": "Power Plant",
		"size": Vector2(80, 80),
		"cost": 120,
		"hp": 180.0,
		"color": Color(0.2, 0.6, 0.35, 1.0),
	},
	"command_center": {
		"name": "Command Center",
		"size": Vector2(130, 110),
		"cost": 300,
		"hp": 280.0,
		"color": Color(0.35, 0.35, 0.5, 1.0),
	},
	"defense_gun": {
		"name": "Gun Turret",
		"size": Vector2(70, 70),
		"cost": 180,
		"hp": 220.0,
		"color": Color(0.35, 0.5, 0.35, 1.0),
	},
	"defense_missile": {
		"name": "Missile Turret",
		"size": Vector2(70, 70),
		"cost": 240,
		"hp": 240.0,
		"color": Color(0.6, 0.6, 0.6, 1.0),
	},
	"defense_laser": {
		"name": "Laser Turret",
		"size": Vector2(70, 70),
		"cost": 260,
		"hp": 230.0,
		"color": Color(0.2, 0.6, 0.65, 1.0),
	},
	"defense": {
		"name": "Missile Turret",
		"size": Vector2(70, 70),
		"cost": 240,
		"hp": 240.0,
		"color": Color(0.6, 0.6, 0.6, 1.0),
	},
}

var _defense_profiles := {
	"defense_gun": {
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
	},
	"defense_missile": {
		"range": 230.0,
		"damage": 12.0,
		"fire_rate": 0.8,
		"missile_speed": 260.0,
		"missile_turn_rate": 9.0,
		"missile_color": Color(1.0, 0.6, 0.2, 1.0),
		"warhead_size": "medium",
		"prefers_vehicle": true,
		"damage_vs_infantry": 0.7,
		"damage_vs_vehicle": 1.6,
	},
	"defense_laser": {
		"range": 190.0,
		"damage": 16.0,
		"fire_rate": 1.1,
		"missile_speed": 340.0,
		"missile_turn_rate": 14.0,
		"missile_color": Color(0.4, 0.9, 1.0, 1.0),
		"warhead_size": "small",
		"damage_vs_infantry": 1.1,
		"damage_vs_vehicle": 1.0,
	},
	"defense": {
		"range": 230.0,
		"damage": 12.0,
		"fire_rate": 0.8,
		"missile_speed": 260.0,
		"missile_turn_rate": 9.0,
		"missile_color": Color(1.0, 0.6, 0.2, 1.0),
		"warhead_size": "medium",
		"prefers_vehicle": true,
		"damage_vs_infantry": 0.7,
		"damage_vs_vehicle": 1.6,
	},
}

func _ready() -> void:
	_load_build_zones(map_path, build_zone_id)
	_world_input = _find_world_input()

func _process(_delta: float) -> void:
	if _active_build_id == "":
		return
	_ghost_pos = _get_mouse_world_pos()
	_ghost_pos = _snap_position(_ghost_pos)
	_ghost_valid = _can_place(_ghost_pos, _build_defs[_active_build_id]["size"])
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _active_build_id == "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_place()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_cancel_dragging = true
			_cancel_start = event.position
		else:
			if not _cancel_dragging:
				return
			_cancel_dragging = false
			if _cancel_start.distance_to(event.position) <= cancel_drag_threshold:
				cancel_placement()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_placement()

func _draw() -> void:
	if not render_2d:
		return
	if not show_ghost or _active_build_id == "":
		return
	var size: Vector2 = _build_defs[_active_build_id]["size"]
	var rect := Rect2(_ghost_pos - (size / 2.0), size)
	var fill := ghost_valid_fill if _ghost_valid else ghost_invalid_fill
	draw_rect(rect, fill, true)
	draw_rect(rect, ghost_outline, false, ghost_outline_width)

func get_build_options() -> Array:
	var options: Array = []
	for build_id in _build_order:
		if not _build_defs.has(build_id):
			continue
		var data: Dictionary = _build_defs[build_id]
		options.append({
			"id": build_id,
			"name": data["name"],
			"cost": data["cost"],
			"size": data["size"],
		})
	return options

func get_active_build_id() -> String:
	return _active_build_id

func start_placement(build_id: String) -> void:
	if not _build_defs.has(build_id):
		return
	_active_build_id = build_id
	emit_signal("build_mode_changed", _active_build_id)
	queue_redraw()

func cancel_placement() -> void:
	_active_build_id = ""
	emit_signal("build_mode_changed", _active_build_id)
	queue_redraw()

func is_placing() -> bool:
	return _active_build_id != ""

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func get_ghost_state() -> Dictionary:
	if _active_build_id == "":
		return {}
	var data: Dictionary = _build_defs.get(_active_build_id, {})
	return {
		"pos": _ghost_pos,
		"size": data.get("size", Vector2.ZERO),
		"valid": _ghost_valid,
		"build_id": _active_build_id,
	}

func _try_place() -> void:
	if not _ghost_valid:
		return
	var data: Dictionary = _build_defs[_active_build_id]
	var cost: int = data["cost"]
	var credits := _get_team_credits()
	if credits < cost:
		return
	var building := Building.new()
	building.build_id = _active_build_id
	building.size = data["size"]
	building.fill_color = data["color"]
	building.max_hp = float(data.get("hp", 200.0))
	building.team_id = team_id
	building.visual_scene_path = _get_building_visual_path(_active_build_id)
	building.visual_base_size = _get_building_visual_base_size(_active_build_id)
	if _active_build_id == "barracks":
		building.production_type = "mixed"
		building.wait_mode = false
	if _active_build_id == "factory":
		building.vehicle_production_type = "mixed"
	if _active_build_id == "airfield":
		building.set_meta("aircraft_active", 0)
		building.set_meta("aircraft_landing", 0)
	building.position = _ghost_pos
	add_child(building)
	_buildings.append(building)
	_set_team_credits(credits - cost)
	_increment_building_count(_active_build_id)
	if _active_build_id.begins_with("defense"):
		var turret := _spawn_defense_turret(_active_build_id, _ghost_pos)
		building.set_meta("linked_turret", turret)
	cancel_placement()

func _can_place(pos: Vector2, size: Vector2) -> bool:
	var rect := Rect2(pos - (size / 2.0), size)
	if not _is_inside_build_zone(rect):
		return false
	if _get_team_credits() < int(_build_defs[_active_build_id]["cost"]):
		return false
	for building in _buildings:
		if building is Building and is_instance_valid(building):
			var other_rect := Rect2(building.position - (building.size / 2.0), building.size)
			if rect.intersects(other_rect):
				return false
	return true

func _is_inside_build_zone(rect: Rect2) -> bool:
	for zone in _build_zones:
		if zone is Rect2 and zone.encloses(rect):
			return true
	return false

func _get_mouse_world_pos() -> Vector2:
	var input := _world_input
	if input == null or not is_instance_valid(input):
		input = _find_world_input()
		_world_input = input
	if input != null and input.has_method("screen_to_world"):
		return input.screen_to_world(get_viewport().get_mouse_position())
	return get_global_mouse_position()

func _snap_position(pos: Vector2) -> Vector2:
	if placement_snap <= 0.0:
		return pos
	return Vector2(
		round(pos.x / placement_snap) * placement_snap,
		round(pos.y / placement_snap) * placement_snap
	)

func _find_world_input() -> Node:
	var nodes := get_tree().get_nodes_in_group("world_input")
	if nodes.is_empty():
		return null
	return nodes[0] as Node

func _load_build_zones(path: String, zone_id: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("BuildController: Failed to open map at %s" % path)
		return
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("BuildController: Invalid JSON in %s" % path)
		return
	_build_zones.clear()
	_primary_zone = Rect2()
	var zones = data.get("build_zones", [])
	for zone in zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		if str(zone.get("id", "")) != zone_id:
			continue
		var rect := Rect2(
			Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
			Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
		)
		_build_zones.append(rect)
		if _primary_zone == Rect2():
			_primary_zone = rect

func _get_team_credits() -> int:
	return GameState.p1_credits if team_id == "p1" else GameState.p2_credits

func _set_team_credits(value: int) -> void:
	if team_id == "p1":
		GameState.p1_credits = value
	else:
		GameState.p2_credits = value

func _spawn_defense_turret(build_id: String, pos: Vector2) -> DefenseTurret:
	var turret := DefenseTurret.new()
	turret.team_id = team_id
	var profile: Dictionary = _defense_profiles.get(build_id, _defense_profiles.get("defense", {}))
	var base_range := float(profile.get("range", 140.0)) * defense_range_multiplier
	turret.attack_range = minf(base_range, _compute_defense_range(pos))
	turret.damage = float(profile.get("damage", 10.0))
	turret.fire_rate = float(profile.get("fire_rate", 0.8)) * defense_fire_rate_multiplier
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
	add_child(turret)
	return turret

func _compute_defense_range(pos: Vector2) -> float:
	if _primary_zone == Rect2():
		return 140.0
	var left := pos.x - _primary_zone.position.x
	var right := (_primary_zone.position.x + _primary_zone.size.x) - pos.x
	var top := pos.y - _primary_zone.position.y
	var bottom := (_primary_zone.position.y + _primary_zone.size.y) - pos.y
	var min_edge := minf(minf(left, right), minf(top, bottom))
	return maxf(0.0, min_edge * 0.9)

func _increment_building_count(build_id: String) -> void:
	if team_id == "p1":
		GameState.p1_building_count += 1
		match build_id:
			"barracks":
				GameState.p1_barracks += 1
			"factory":
				GameState.p1_factory += 1
			"airfield":
				GameState.p1_airfield += 1
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
			"airfield":
				GameState.p2_airfield += 1
			"supply":
				GameState.p2_supply += 1
			"power":
				GameState.p2_power += 1
			"command_center":
				GameState.p2_command_center += 1
			_:
				if build_id.begins_with("defense"):
					GameState.p2_defense += 1

func _get_building_visual_path(build_id: String) -> String:
	match build_id:
		"barracks":
			return "res://scenes/buildings/barracks_visual.tscn"
		"factory":
			return "res://scenes/buildings/factory_visual.tscn"
		"airfield":
			return "res://scenes/buildings/airfield_visual.tscn"
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
		"airfield":
			return Vector2(432, 288)
		"supply":
			return Vector2(100, 80)
		"power":
			return Vector2(80, 80)
		"command_center":
			return Vector2(130, 110)
	return Vector2.ZERO
