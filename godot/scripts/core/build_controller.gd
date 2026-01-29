class_name BuildController
extends Node2D

signal build_mode_changed(active_id: String)

@export var map_path := "res://data/maps/test_map.json"
@export var build_zone_id := "p1"
@export var team_id := "p1"
@export var placement_snap := 10.0
@export var show_ghost := true
@export var render_2d := true
@export var vision_based_building := true  ## Allow building anywhere with vision

@export var ghost_valid_fill := Color(0.2, 0.9, 0.2, 0.3)
@export var ghost_invalid_fill := Color(0.9, 0.2, 0.2, 0.3)
@export var ghost_outline := Color(0.95, 0.95, 0.95, 0.7)
@export var ghost_outline_width := 2.0
@export var defense_range_multiplier := 1.5
@export var defense_fire_rate_multiplier := 0.75
@export var cancel_drag_threshold := 8.0

# Ocean water level (Y position of Ocean mesh in main_3d.tscn)
const OCEAN_WATER_LEVEL := 50.0

var _build_zones: Array = []
var _terrain: Node = null
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
	"defense_laser",
	"defense_patriot",
	"radar",
	"missile_carrier"
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
		"size": Vector2(648, 432),
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
	"defense_patriot": {
		"name": "Patriot SAM",
		"size": Vector2(90, 90),
		"cost": 450,
		"hp": 280.0,
		"color": Color(0.3, 0.45, 0.3, 1.0),
	},
	"radar": {
		"name": "Radar Station",
		"size": Vector2(90, 90),
		"cost": 350,
		"hp": 240.0,
		"color": Color(0.2, 0.55, 0.7, 1.0),
		"vision_radius": 0.0,
		"range": 2400.0,
		"support_radius": 600.0,
	},
	"missile_carrier": {
		"name": "Missile Carrier",
		"size": Vector2(120, 50),
		"cost": 600,
		"hp": 320.0,
		"color": Color(0.25, 0.35, 0.55, 1.0),
		"water_only": true,
		"vision_radius": 300.0,
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
		"missile_turn_rate": 10.0,
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
		"missile_turn_rate": 10.0,
		"missile_color": Color(1.0, 0.6, 0.2, 1.0),
		"warhead_size": "medium",
		"prefers_vehicle": true,
		"damage_vs_infantry": 0.7,
		"damage_vs_vehicle": 1.6,
	},
	"defense_patriot": {
		"range": 900.0,
		"damage": 0.0,
		"fire_rate": 1.5,
		"missile_speed": 800.0,
		"missile_turn_rate": 20.0,
		"missile_color": Color(0.9, 1.0, 0.9, 1.0),
		"warhead_size": "small",
		"is_interceptor": true,
		"intercept_success_base": 0.3,
		"max_simultaneous_intercepts": 2,
		"max_interceptors_per_missile": 4,
	},
}

func _ready() -> void:
	_load_build_zones(map_path, build_zone_id)
	_world_input = _find_world_input()
	_terrain = _find_terrain()

func _process(_delta: float) -> void:
# DEBUG: Press B key to force build mode for testing	if Input.is_key_pressed(KEY_B):		if _active_build_id == "":			start_placement("barracks")			print("[BuildController] BUILD MODE ACTIVATED - Press B was detected")	# DEBUG: Press ESC to cancel build mode	if Input.is_key_pressed(KEY_ESCAPE):		if _active_build_id != "":			cancel_placement()			print("[BuildController] BUILD MODE CANCELLED")
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
	if data.has("vision_radius"):
		building.vision_radius = float(data.get("vision_radius", building.vision_radius))
	building.team_id = team_id
	building.visual_scene_path = _get_building_visual_path(_active_build_id)
	building.visual_base_size = _get_building_visual_base_size(_active_build_id)
	if _active_build_id == "barracks":
		building.production_type = "mixed"
		building.wait_mode = false
	if _active_build_id == "factory":
		building.vehicle_production_type = "mixed"
	if _active_build_id == "airfield":
		building.set_meta("aircraft_tier", "f16")
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
	elif _active_build_id == "radar":
		var radar := _spawn_radar_station(_ghost_pos, data)
		building.set_meta("linked_turret", radar)
	elif _active_build_id == "missile_carrier":
		var carrier := _spawn_missile_carrier(_ghost_pos)
		building.set_meta("linked_turret", carrier)
	cancel_placement()

func _can_place(pos: Vector2, size: Vector2) -> bool:
	var rect := Rect2(pos - (size / 2.0), size)
	var build_data: Dictionary = _build_defs.get(_active_build_id, {})
	var is_water_only: bool = build_data.get("water_only", false)

	# Check water-only requirement for naval buildings
	if is_water_only:
		if not _is_on_water(pos):
			return false
		# Water buildings still need vision to place
		if vision_based_building and not _is_in_vision(pos):
			return false
	else:
		# Non-water buildings must be on land (in build zone or vision)
		if _is_on_water(pos):
			return false
		if not _is_inside_build_zone(rect):
			return false

	if _get_team_credits() < int(_build_defs[_active_build_id]["cost"]):
		return false
	for building in _buildings:
		if building == null or not is_instance_valid(building):
			continue
		if building is Building:
			var other_rect := Rect2(building.position - (building.size / 2.0), building.size)
			if rect.intersects(other_rect):
				return false
	return true

func _is_inside_build_zone(rect: Rect2) -> bool:
	# Check fixed build zones first
	for zone in _build_zones:
		if zone is Rect2 and zone.encloses(rect):
			return true
	# Check vision-based building if enabled
	if vision_based_building:
		if _is_in_vision(rect.get_center()):
			return true
	return false

func _is_in_vision(pos: Vector2) -> bool:
	## Check if position is visible via any vision source
	var vision_group := "vision_" + team_id
	for node in get_tree().get_nodes_in_group(vision_group):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_vision_radius"):
			continue
		var radius := float(node.get_vision_radius())
		if radius <= 0.0:
			continue
		var dist_sq := pos.distance_squared_to(node.global_position)
		if dist_sq <= radius * radius:
			return true
	return false

var _water_debug_printed := false
var _terrain_data: Object = null

func _is_on_water(pos: Vector2) -> bool:
	## Check if position is on water by checking terrain height vs water surface.
	## Water = terrain below water surface level OR no terrain data within water mesh.

	# First, try to get terrain height at this position
	if _terrain == null:
		_terrain = _find_terrain()
		if not _water_debug_printed:
			if _terrain == null:
				print("[WATER_CHECK] Terrain NOT found!")
			else:
				print("[WATER_CHECK] Terrain found: ", _terrain.name, " at ", _terrain.get_path())
				# Terrain3D uses terrain.data.get_height() not terrain.get_height()
				var data_value: Variant = _terrain.get("data")
				if data_value is Object:
					_terrain_data = data_value
					print("[WATER_CHECK] Terrain data found, has get_height: ", _terrain_data.has_method("get_height"))
				else:
					print("[WATER_CHECK] Terrain has no 'data' property")

	var world_pos := Vector3(pos.x, 0, pos.y)
	var height := NAN

	# Try to get height from terrain data (Terrain3D uses data.get_height)
	if _terrain_data != null and _terrain_data.has_method("get_height"):
		# Convert to local space if terrain has transform
		var local_pos := world_pos
		if _terrain is Node3D:
			local_pos = (_terrain as Node3D).to_local(world_pos)
		var height_value: Variant = _terrain_data.call("get_height", Vector3(local_pos.x, 0.0, local_pos.z))
		if height_value is float or height_value is int:
			height = float(height_value)
			# Convert back to global Y if needed
			if _terrain is Node3D and is_finite(height):
				height = (_terrain as Node3D).to_global(Vector3(local_pos.x, height, local_pos.z)).y
	elif _terrain != null and _terrain.has_method("get_height"):
		# Fallback: direct get_height on terrain node
		height = _terrain.get_height(world_pos)

	# Determine water surface level from any water mesh at this position
	var water_info := _get_water_mesh_at_position(pos)
	var water_surface_y: float = OCEAN_WATER_LEVEL
	var within_water_mesh := not water_info.is_empty()
	if within_water_mesh:
		water_surface_y = water_info.get("surface_y", OCEAN_WATER_LEVEL)

	# Debug output (first few calls only)
	if not _water_debug_printed:
		_water_debug_printed = true
		print("[WATER_CHECK] pos=", pos, " height=", height, " water_y=", water_surface_y, " in_mesh=", within_water_mesh)
		if is_nan(height):
			print("[WATER_CHECK] Height is NaN - no terrain data at this position")
		elif height >= water_surface_y:
			print("[WATER_CHECK] Height >= water level = LAND")
		else:
			print("[WATER_CHECK] Height < water level = WATER")

	# If we have valid terrain height data, use it to determine water vs land
	if not is_nan(height):
		# Terrain above or at water surface = land (not water)
		if height >= water_surface_y:
			return false
		# Terrain below water surface AND within water mesh = water
		if height < water_surface_y and within_water_mesh:
			return true
		# Below water level but no water mesh = unusual, treat as land
		return false

	# No terrain data (NaN) - be conservative, require explicit water mesh
	# ONLY allow water building in areas clearly marked as ocean/water
	# AND where there's no terrain data (meaning it's outside the island)
	if within_water_mesh:
		# Check if we're far enough from terrain coverage to be "real" ocean
		# This is a heuristic - if terrain doesn't cover this point but ocean does,
		# it's likely deep water outside the island
		return true

	# No terrain and no water mesh = definitely not water
	return false

func _get_water_mesh_at_position(pos: Vector2) -> Dictionary:
	## Find any water mesh that contains this 2D position and return its info.
	## Returns empty dict if no water mesh found.

	# Search for water meshes in the scene (Ocean, lakes, etc.)
	var water_nodes := []
	var root := get_tree().root
	_find_water_nodes_recursive(root, water_nodes)

	for water_node in water_nodes:
		if water_node is MeshInstance3D:
			var mesh_inst := water_node as MeshInstance3D
			var mesh := mesh_inst.mesh
			if mesh == null:
				continue

			# Get the mesh AABB and transform it to global space
			var aabb := mesh.get_aabb()
			var global_transform := mesh_inst.global_transform
			var global_pos := global_transform.origin
			var global_scale := global_transform.basis.get_scale()

			# Calculate bounds in 2D (XZ plane)
			var half_size_x := (aabb.size.x * global_scale.x) / 2.0
			var half_size_z := (aabb.size.z * global_scale.z) / 2.0
			var min_x := global_pos.x - half_size_x
			var max_x := global_pos.x + half_size_x
			var min_z := global_pos.z - half_size_z
			var max_z := global_pos.z + half_size_z

			# Check if position is within this water mesh bounds
			if pos.x >= min_x and pos.x <= max_x and pos.y >= min_z and pos.y <= max_z:
				return {
					"node": water_node,
					"surface_y": global_pos.y
				}

	return {}

func _find_water_nodes_recursive(node: Node, result: Array) -> void:
	## Find all nodes that are likely water meshes
	var node_name := node.name.to_lower()
	if "water" in node_name or "ocean" in node_name or "lake" in node_name or "sea" in node_name:
		if node is MeshInstance3D:
			result.append(node)
	for child in node.get_children():
		_find_water_nodes_recursive(child, result)

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

func _find_terrain() -> Node:
	## Find the Terrain3D node in the scene tree
	# Try common paths first
	var paths := [
		"/root/Main3D/World3D/NavigationRegion3D/Ground/Terrain3D",
		"../../World3D/NavigationRegion3D/Ground/Terrain3D",
		"../World3D/NavigationRegion3D/Ground/Terrain3D",
	]
	for path in paths:
		var terrain := get_node_or_null(path)
		if terrain != null and _is_valid_terrain(terrain):
			return terrain
	# Fallback: search for Terrain3D node by name
	var root := get_tree().root
	return _find_terrain_recursive(root)

func _find_terrain_recursive(node: Node) -> Node:
	# Look for node named "Terrain3D" or with Terrain3D class
	if _is_valid_terrain(node):
		return node
	for child in node.get_children():
		var found := _find_terrain_recursive(child)
		if found != null:
			return found
	return null

func _is_valid_terrain(node: Node) -> bool:
	## Check if node is a valid Terrain3D that can query height
	if node == null:
		return false
	# Check by class name or node name
	var node_class := node.get_class()
	if node_class == "Terrain3D" or "Terrain3D" in node.name:
		if node.has_method("get_height"):
			return true
	return false

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
	var profile: Dictionary = _defense_profiles.get(build_id, _defense_profiles.get("defense", {}))

	# Spawn PatriotTurret for missile interception
	if build_id == "defense_patriot":
		return _spawn_patriot_turret(pos, profile)

	var turret := DefenseTurret.new()
	turret.team_id = team_id
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

func _spawn_radar_station(pos: Vector2, data: Dictionary) -> RadarStation:
	var radar := RadarStation.new()
	radar.team_id = team_id
	radar.attack_range = float(data.get("range", 1200.0))
	radar.support_radius = float(data.get("support_radius", radar.support_radius))
	radar.damage = 0.0
	radar.fire_rate = 999.0
	radar.hitscan_enabled = false
	radar.base_radius = 22.0
	var radar_color = data.get("color", Color(0.2, 0.55, 0.7, 1.0))
	if radar_color is Color:
		radar.base_color = radar_color
	radar.visual_base_radius = 22.0
	radar.position = pos
	add_child(radar)
	return radar

func _spawn_patriot_turret(pos: Vector2, profile: Dictionary) -> PatriotTurret:
	var turret := PatriotTurret.new()
	turret.team_id = team_id
	# Patriot has longer range - use full range, not clamped to build zone
	turret.attack_range = float(profile.get("range", 600.0))
	turret.damage = 0.0  # Patriot doesn't deal direct damage
	turret.fire_rate = float(profile.get("fire_rate", 1.5))
	turret.interceptor_speed = float(profile.get("missile_speed", 800.0))
	turret.interceptor_turn_rate = float(profile.get("missile_turn_rate", 20.0))
	turret.intercept_success_base = float(profile.get("intercept_success_base", 0.3))
	turret.max_simultaneous_intercepts = int(profile.get("max_simultaneous_intercepts", 2))
	turret.max_interceptors_per_missile = int(profile.get("max_interceptors_per_missile", turret.max_interceptors_per_missile))
	var missile_color = profile.get("missile_color")
	if missile_color is Color:
		turret.missile_color = missile_color
	turret.base_radius = 24.0  # Larger base for Patriot
	turret.base_color = Color(0.3, 0.45, 0.3, 1.0)
	turret.visual_scene_path = _get_turret_visual_path("defense_patriot")
	turret.visual_base_radius = 24.0
	turret.position = pos
	add_child(turret)
	return turret

func _spawn_missile_carrier(pos: Vector2) -> MissileCarrierTurret:
	var carrier := MissileCarrierTurret.new()
	carrier.team_id = team_id
	carrier.bombardment_range = 1200.0
	carrier.bombardment_missile_damage = 80.0
	carrier.bombardment_missile_speed = 400.0
	carrier.bombardment_reload_time = 15.0
	carrier.base_radius = 30.0
	carrier.base_color = Color(0.25, 0.35, 0.55, 1.0)
	carrier.visual_scene_path = _get_turret_visual_path("missile_carrier")
	carrier.visual_base_radius = 30.0
	carrier.position = pos
	add_child(carrier)
	return carrier

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
	if build_id == "defense_patriot":
		# Use the GLB directly for 3D visual sync
		return "res://assets/models/Patriot/mim-104_patriot_air_defense_system.glb"
	if build_id == "missile_carrier":
		# Naval missile carrier - procedural visual for now
		return ""
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
