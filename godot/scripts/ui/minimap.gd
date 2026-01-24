extends Control
class_name Minimap

## Minimap UI Component
##
## Displays a top-down view of the game world showing:
## - Units (friendly and enemy within vision)
## - Buildings
## - HQ positions
## - Camera viewport indicator
## - Resource nodes

# =============================================================================
# CONFIGURATION
# =============================================================================

@export var minimap_size := Vector2(200, 200)
@export var ui_scale := 1.0
@export var world_size := Vector2(6144, 6144)
@export var border_width := 2.0
@export var border_color := Color(0.3, 0.3, 0.3, 1.0)
@export var background_color := Color(0.1, 0.15, 0.1, 0.85)
@export var p1_unit_color := Color(0.2, 0.6, 1.0, 1.0)
@export var p2_unit_color := Color(1.0, 0.3, 0.3, 1.0)
@export var p1_building_color := Color(0.3, 0.7, 1.0, 0.9)
@export var p2_building_color := Color(1.0, 0.4, 0.4, 0.9)
@export var hq_color := Color(1.0, 1.0, 0.3, 1.0)
@export var resource_color := Color(0.3, 0.9, 0.3, 0.7)
@export var camera_rect_color := Color(1.0, 1.0, 1.0, 0.6)
@export var camera_rect_width := 1.5
@export var build_zone_color := Color(0.2, 0.4, 0.8, 0.15)
@export var unit_dot_size := 3.0
@export var building_dot_size := 5.0
@export var hq_dot_size := 8.0
@export var resource_dot_size := 4.0
@export var aircraft_dot_size := 4.0
@export var update_interval := 0.1

# =============================================================================
# STATE
# =============================================================================

var _game_controller: GameController
var _camera_controller: Node
var _update_timer := 0.0
var _units_p1: Array[Dictionary] = []
var _units_p2: Array[Dictionary] = []
var _buildings_p1: Array[Dictionary] = []
var _buildings_p2: Array[Dictionary] = []
var _hqs: Array[Dictionary] = []
var _resources: Array[Dictionary] = []
var _camera_rect := Rect2()
var _build_zones: Array[Rect2] = []
var _fog_enabled := true

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_apply_ui_scale()
	custom_minimum_size = minimap_size
	size = minimap_size
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Find game controller
	_game_controller = _find_node_by_class("GameController") as GameController

	# Find camera controller
	_camera_controller = _find_camera_controller()

	# Load map configuration
	_load_map_config()

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_minimap_data()
		queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)

	# Build zones
	for zone in _build_zones:
		var mini_rect := _world_rect_to_minimap(zone)
		draw_rect(mini_rect, build_zone_color)

	# Resource nodes
	for resource in _resources:
		var pos: Vector2 = resource.get("pos", Vector2.ZERO)
		var mini_pos := _world_to_minimap(pos)
		draw_circle(mini_pos, resource_dot_size, resource_color)

	# Buildings P1
	for building in _buildings_p1:
		var pos: Vector2 = building.get("pos", Vector2.ZERO)
		var is_hq: bool = building.get("is_hq", false)
		var mini_pos := _world_to_minimap(pos)
		if is_hq:
			draw_circle(mini_pos, hq_dot_size, hq_color)
		else:
			draw_rect(Rect2(mini_pos - Vector2(building_dot_size * 0.5, building_dot_size * 0.5), Vector2(building_dot_size, building_dot_size)), p1_building_color)

	# Buildings P2 (only if visible)
	for building in _buildings_p2:
		var pos: Vector2 = building.get("pos", Vector2.ZERO)
		var is_hq: bool = building.get("is_hq", false)
		var visible: bool = building.get("visible", true)
		if not visible and _fog_enabled:
			continue
		var mini_pos := _world_to_minimap(pos)
		if is_hq:
			draw_circle(mini_pos, hq_dot_size, hq_color)
		else:
			draw_rect(Rect2(mini_pos - Vector2(building_dot_size * 0.5, building_dot_size * 0.5), Vector2(building_dot_size, building_dot_size)), p2_building_color)

	# Units P1
	for unit_data in _units_p1:
		var pos: Vector2 = unit_data.get("pos", Vector2.ZERO)
		var is_aircraft: bool = unit_data.get("is_aircraft", false)
		var mini_pos := _world_to_minimap(pos)
		var dot_size := aircraft_dot_size if is_aircraft else unit_dot_size
		var color := p1_unit_color
		if is_aircraft:
			# Draw aircraft as triangles pointing in their direction
			var facing: Vector2 = unit_data.get("facing", Vector2.RIGHT)
			_draw_aircraft_icon(mini_pos, facing, color, dot_size)
		else:
			draw_circle(mini_pos, dot_size, color)

	# Units P2 (only if visible)
	for unit_data in _units_p2:
		var pos: Vector2 = unit_data.get("pos", Vector2.ZERO)
		var is_aircraft: bool = unit_data.get("is_aircraft", false)
		var visible: bool = unit_data.get("visible", true)
		if not visible and _fog_enabled:
			continue
		var mini_pos := _world_to_minimap(pos)
		var dot_size := aircraft_dot_size if is_aircraft else unit_dot_size
		var color := p2_unit_color
		if is_aircraft:
			var facing: Vector2 = unit_data.get("facing", Vector2.RIGHT)
			_draw_aircraft_icon(mini_pos, facing, color, dot_size)
		else:
			draw_circle(mini_pos, dot_size, color)

	# Camera viewport rectangle
	if _camera_rect.size != Vector2.ZERO:
		var mini_rect := _world_rect_to_minimap(_camera_rect)
		draw_rect(mini_rect, camera_rect_color, false, camera_rect_width)

	# Border
	draw_rect(Rect2(Vector2.ZERO, minimap_size), border_color, false, border_width)

func _draw_aircraft_icon(pos: Vector2, facing: Vector2, color: Color, size: float) -> void:
	var forward := facing.normalized() * size
	var left := Vector2(-facing.y, facing.x).normalized() * size * 0.5
	var points := PackedVector2Array([
		pos + forward,
		pos - forward * 0.5 + left,
		pos - forward * 0.5 - left
	])
	draw_colored_polygon(points, color)

# =============================================================================
# SCALING
# =============================================================================

func _apply_ui_scale() -> void:
	var scale := maxf(0.01, ui_scale)
	if is_equal_approx(scale, 1.0):
		return
	minimap_size *= scale
	border_width *= scale
	unit_dot_size *= scale
	building_dot_size *= scale
	hq_dot_size *= scale
	resource_dot_size *= scale
	aircraft_dot_size *= scale
	camera_rect_width *= scale

# =============================================================================
# INPUT
# =============================================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var click_pos: Vector2 = mouse_event.position
			var world_pos := _minimap_to_world(click_pos)
			_move_camera_to(world_pos)
			get_viewport().set_input_as_handled()

# =============================================================================
# DATA UPDATE
# =============================================================================

func _update_minimap_data() -> void:
	_units_p1.clear()
	_units_p2.clear()
	_buildings_p1.clear()
	_buildings_p2.clear()
	_resources.clear()

	# Update fog setting
	if _game_controller != null:
		_fog_enabled = _game_controller.fog_enabled

	# Gather units
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null:
			continue
		var data := {
			"pos": unit.global_position,
			"is_aircraft": unit.unit_kind == "aircraft",
			"facing": unit._facing if "_facing" in unit else Vector2.RIGHT,
			"visible": _is_position_visible(unit.global_position)
		}
		if unit.team_id == "p1":
			_units_p1.append(data)
		else:
			_units_p2.append(data)

	# Gather buildings
	for node in get_tree().get_nodes_in_group("building"):
		var building := node as Building
		if building == null:
			continue
		var data := {
			"pos": building.global_position,
			"is_hq": false,
			"visible": _is_position_visible(building.global_position)
		}
		if building.team_id == "p1":
			_buildings_p1.append(data)
		else:
			_buildings_p2.append(data)

	# Gather HQs
	for node in get_tree().get_nodes_in_group("hq"):
		var hq := node as HQ
		if hq == null:
			continue
		var data := {
			"pos": hq.global_position,
			"is_hq": true,
			"visible": _is_position_visible(hq.global_position)
		}
		if hq.team_id == "p1":
			_buildings_p1.append(data)
		else:
			_buildings_p2.append(data)

	# Update camera rect
	_update_camera_rect()

func _update_camera_rect() -> void:
	if _camera_controller == null:
		_camera_rect = Rect2()
		return

	# Try to get camera bounds from 3D camera
	if _camera_controller.has_method("get_visible_world_rect"):
		_camera_rect = _camera_controller.get_visible_world_rect()
	elif "visible_rect" in _camera_controller:
		_camera_rect = _camera_controller.visible_rect
	else:
		# Estimate from camera position
		var cam_pos := Vector2.ZERO
		if "global_position" in _camera_controller:
			var pos3d = _camera_controller.global_position
			if pos3d is Vector3:
				cam_pos = Vector2(pos3d.x, pos3d.z)
			elif pos3d is Vector2:
				cam_pos = pos3d

		# Estimate viewport size based on camera height
		var view_size := Vector2(1200, 800)  # Default estimate
		if "position" in _camera_controller:
			var pos: Variant = _camera_controller.position
			if pos is Vector3:
				var height: float = (pos as Vector3).y
				view_size = Vector2(height * 2.0, height * 1.5)

		_camera_rect = Rect2(cam_pos - view_size * 0.5, view_size)

func _is_position_visible(world_pos: Vector2) -> bool:
	# For P1 units/buildings, always visible
	# For P2, check if within P1 vision
	if not _fog_enabled:
		return true

	# Check against P1 vision sources
	for node in get_tree().get_nodes_in_group("vision_p1"):
		if node is Node2D and node.has_method("get_vision_radius"):
			var vision_radius = node.get_vision_radius()
			if vision_radius is float or vision_radius is int:
				var dist := (node as Node2D).global_position.distance_to(world_pos)
				if dist <= float(vision_radius):
					return true

	return false

# =============================================================================
# COORDINATE CONVERSION
# =============================================================================

func _world_to_minimap(world_pos: Vector2) -> Vector2:
	var normalized := world_pos / world_size
	return normalized * minimap_size

func _minimap_to_world(minimap_pos: Vector2) -> Vector2:
	var normalized := minimap_pos / minimap_size
	return normalized * world_size

func _world_rect_to_minimap(world_rect: Rect2) -> Rect2:
	var pos := _world_to_minimap(world_rect.position)
	var size_ratio := minimap_size / world_size
	var mini_size := world_rect.size * size_ratio
	return Rect2(pos, mini_size)

# =============================================================================
# CAMERA CONTROL
# =============================================================================

func _move_camera_to(world_pos: Vector2) -> void:
	if _camera_controller == null:
		return

	if _camera_controller.has_method("move_to_position"):
		_camera_controller.move_to_position(world_pos)
	elif _camera_controller.has_method("set_target_position"):
		_camera_controller.set_target_position(Vector3(world_pos.x, 0, world_pos.y))
	elif "target_position" in _camera_controller:
		_camera_controller.target_position = Vector3(world_pos.x, 0, world_pos.y)

# =============================================================================
# SETUP HELPERS
# =============================================================================

func _load_map_config() -> void:
	_build_zones.clear()

	var map_path := "res://data/maps/test_map.json"
	if _game_controller != null and "map_path" in _game_controller:
		map_path = _game_controller.map_path

	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed

	# Load world size
	var size_data: Dictionary = data.get("size", {})
	if not size_data.is_empty():
		world_size = Vector2(
			float(size_data.get("width", 6144)),
			float(size_data.get("height", 6144))
		)

	# Load build zones
	var zones: Array = data.get("build_zones", [])
	for zone in zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		var rect := Rect2(
			Vector2(float(zone.get("x", 0)), float(zone.get("y", 0))),
			Vector2(float(zone.get("width", 0)), float(zone.get("height", 0)))
		)
		_build_zones.append(rect)

	# Load resource nodes
	var resources: Array = data.get("resource_nodes", [])
	for resource in resources:
		if typeof(resource) != TYPE_DICTIONARY:
			continue
		_resources.append({
			"pos": Vector2(float(resource.get("x", 0)), float(resource.get("y", 0)))
		})

func _find_node_by_class(class_name_str: String) -> Node:
	return _find_node_by_class_recursive(get_tree().root, class_name_str)

func _find_node_by_class_recursive(node: Node, class_name_str: String) -> Node:
	if node.get_class() == class_name_str:
		return node
	for child in node.get_children():
		var result := _find_node_by_class_recursive(child, class_name_str)
		if result != null:
			return result
	return null

func _find_camera_controller() -> Node:
	# Try to find 3D camera controller first
	var controllers := get_tree().get_nodes_in_group("camera_controller")
	if not controllers.is_empty():
		return controllers[0]

	# Search for CameraController3D
	var cam_3d := _find_node_by_class("CameraController3D")
	if cam_3d != null:
		return cam_3d

	# Search for Camera3D
	var cam := _find_node_by_class("Camera3D")
	if cam != null:
		return cam.get_parent() if cam.get_parent() != null else cam

	return null
