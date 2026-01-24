extends Node3D

@export var map_path := "res://data/maps/test_map.json"
@export var focus_from_map := true
@export var focus_team_id := "p1"
@export var focus_use_build_zone := true
@export var pan_speed := 900.0
@export var pan_drag_speed := 1.0
@export var zoom_step := 15.0
@export_range(0.75, 2.0, 0.05) var view_scale := 1.25
@export var pan_hold_speed := 900.0
@export var pan_hold_deadzone := 2.0
@export var pan_hold_distance_for_max := 120.0
@export var pan_hold_min_multiplier := 0.2
@export var pan_hold_max_multiplier := 2.0
@export var min_distance := 180.0
@export var max_distance := 18000.0
@export var pitch_deg := 45.0
@export var rotate_drag_speed := 0.3

var _dragging := false
var _distance := 420.0
var _pan_dragging := false
var _pan_hold_origin := Vector2.ZERO
var _pan_hold_dir := Vector2.ZERO
var _pan_hold_speed_scale := 0.0

@onready var _camera := $"Camera3D" as Camera3D

func _ready() -> void:
	add_to_group("camera_controller")
	if focus_from_map:
		var focus := _load_map_focus(map_path, focus_team_id, focus_use_build_zone)
		if focus != Vector2.ZERO:
			position = Vector3(focus.x, 0.0, focus.y)
		else:
			var size := _load_map_size(map_path)
			if size != Vector2.ZERO:
				position = Vector3(size.x * 0.5, 0.0, size.y * 0.5)
	var scale := _scale_factor()
	var min_dist := min_distance / scale
	var max_dist := max_distance / scale
	_distance = clampf(_distance / scale, min_dist, max_dist)
	_apply_camera()

func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.z += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.z -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector3.ZERO:
		var forward := -global_transform.basis.z
		var right := global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		position += (right * dir.x + forward * dir.z) * pan_speed * delta / _scale_factor()
	if _pan_dragging and _pan_hold_dir != Vector2.ZERO and _pan_hold_speed_scale > 0.0:
		var forward := -global_transform.basis.z
		var right := global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		var world_dir := (right * _pan_hold_dir.x) + (forward * -_pan_hold_dir.y)
		position += world_dir * pan_hold_speed * _pan_hold_speed_scale * delta / _scale_factor()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom_step)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_pan_dragging = true
			_pan_hold_origin = event.position
			_pan_hold_dir = Vector2.ZERO
			_pan_hold_speed_scale = 0.0
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = false
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_pan_dragging = false
		_pan_hold_dir = Vector2.ZERO
		_pan_hold_speed_scale = 0.0
	elif event is InputEventMouseMotion and _dragging:
		rotate_y(deg_to_rad(-event.relative.x * rotate_drag_speed))
		_apply_camera()
	elif event is InputEventMouseMotion and _pan_dragging:
		var motion := event as InputEventMouseMotion
		var delta := motion.position - _pan_hold_origin
		var distance := delta.length()
		if distance < pan_hold_deadzone:
			_pan_hold_dir = Vector2.ZERO
			_pan_hold_speed_scale = 0.0
			return
		_pan_hold_dir = delta.normalized()
		var max_distance := maxf(1.0, pan_hold_distance_for_max)
		var t := clampf(distance / max_distance, 0.0, 1.0)
		_pan_hold_speed_scale = lerpf(pan_hold_min_multiplier, pan_hold_max_multiplier, t)

func _zoom(amount: float) -> void:
	var scale := _scale_factor()
	var min_dist := min_distance / scale
	var max_dist := max_distance / scale
	_distance = clampf(_distance + amount / scale, min_dist, max_dist)
	_apply_camera()

func _apply_camera() -> void:
	if _camera == null:
		return
	var pitch_rad := deg_to_rad(pitch_deg)
	var height := sin(pitch_rad) * _distance
	var back := cos(pitch_rad) * _distance
	_camera.position = Vector3(0.0, height, back)
	_camera.look_at(global_transform.origin, Vector3.UP)

func _scale_factor() -> float:
	return maxf(0.01, view_scale)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if _camera == null:
		return Vector2.ZERO
	var origin := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, 0.0)
	var hit = plane.intersects_ray(origin, dir)
	if hit == null:
		return Vector2.ZERO
	return Vector2(hit.x, hit.z)

func _load_map_size(path: String) -> Vector2:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Vector2.ZERO
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return Vector2.ZERO
	var size_data: Dictionary = data.get("size", {})
	return Vector2(float(size_data.get("width", 0.0)), float(size_data.get("height", 0.0)))

# =============================================================================
# PUBLIC API - For minimap integration
# =============================================================================

func move_to_position(world_pos: Vector2) -> void:
	position = Vector3(world_pos.x, 0.0, world_pos.y)

func get_visible_world_rect() -> Rect2:
	if _camera == null:
		return Rect2()

	# Get viewport corners in screen space
	var viewport := get_viewport()
	if viewport == null:
		return Rect2()

	var viewport_size := viewport.get_visible_rect().size
	var corners := [
		Vector2(0, 0),
		Vector2(viewport_size.x, 0),
		Vector2(viewport_size.x, viewport_size.y),
		Vector2(0, viewport_size.y)
	]

	# Convert to world positions
	var world_corners: Array[Vector2] = []
	for corner in corners:
		var world_pos := _screen_to_world(corner)
		if world_pos != Vector2.ZERO:
			world_corners.append(world_pos)

	if world_corners.is_empty():
		return Rect2()

	# Find bounding rect
	var min_x := world_corners[0].x
	var max_x := world_corners[0].x
	var min_y := world_corners[0].y
	var max_y := world_corners[0].y

	for corner in world_corners:
		min_x = minf(min_x, corner.x)
		max_x = maxf(max_x, corner.x)
		min_y = minf(min_y, corner.y)
		max_y = maxf(max_y, corner.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func get_world_position() -> Vector2:
	return Vector2(position.x, position.z)

# =============================================================================
# MAP LOADING
# =============================================================================

func _load_map_focus(path: String, team_id: String, use_build_zone: bool) -> Vector2:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Vector2.ZERO
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return Vector2.ZERO
	var parsed: Dictionary = data
	if use_build_zone:
		var zones: Array = parsed.get("build_zones", [])
		for zone in zones:
			if typeof(zone) != TYPE_DICTIONARY:
				continue
			if str(zone.get("id", "")) != team_id:
				continue
			var x := float(zone.get("x", 0.0))
			var y := float(zone.get("y", 0.0))
			var w := float(zone.get("width", 0.0))
			var h := float(zone.get("height", 0.0))
			return Vector2(x + (w * 0.5), y + (h * 0.5))
	var starts: Array = parsed.get("start_positions", [])
	for start in starts:
		if typeof(start) != TYPE_DICTIONARY:
			continue
		if str(start.get("id", "")) != team_id:
			continue
		return Vector2(float(start.get("x", 0.0)), float(start.get("y", 0.0)))
	return Vector2.ZERO
