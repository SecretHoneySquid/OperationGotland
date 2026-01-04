extends Node3D

@export var map_path := "res://data/maps/test_map.json"
@export var focus_from_map := true
@export var focus_team_id := "p1"
@export var focus_use_build_zone := true
@export var pan_speed := 900.0
@export var pan_drag_speed := 1.0
@export var zoom_step := 15.0
@export var min_distance := 180.0
@export var max_distance := 18000.0
@export var pitch_deg := 45.0
@export var rotate_drag_speed := 0.3

var _dragging := false
var _distance := 420.0
var _pan_dragging := false
var _pan_last_screen := Vector2.ZERO

@onready var _camera := $"Camera3D" as Camera3D

func _ready() -> void:
	if focus_from_map:
		var focus := _load_map_focus(map_path, focus_team_id, focus_use_build_zone)
		if focus != Vector2.ZERO:
			position = Vector3(focus.x, 0.0, focus.y)
		else:
			var size := _load_map_size(map_path)
			if size != Vector2.ZERO:
				position = Vector3(size.x * 0.5, 0.0, size.y * 0.5)
	_distance = clampf(_distance, min_distance, max_distance)
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
		position += (right * dir.x + forward * dir.z) * pan_speed * delta

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
			_pan_last_screen = event.position
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = false
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_pan_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		rotate_y(deg_to_rad(-event.relative.x * rotate_drag_speed))
		_apply_camera()
	elif event is InputEventMouseMotion and _pan_dragging:
		_pan_from_drag(event.position)

func _zoom(amount: float) -> void:
	_distance = clampf(_distance + amount, min_distance, max_distance)
	_apply_camera()

func _pan_from_drag(screen_pos: Vector2) -> void:
	if _camera == null:
		return
	var last_world := _screen_to_world(_pan_last_screen)
	var current_world := _screen_to_world(screen_pos)
	var delta := current_world - last_world
	if delta == Vector2.ZERO:
		_pan_last_screen = screen_pos
		return
	position += Vector3(delta.x, 0.0, delta.y) * pan_drag_speed
	_pan_last_screen = screen_pos

func _apply_camera() -> void:
	if _camera == null:
		return
	var pitch_rad := deg_to_rad(pitch_deg)
	var height := sin(pitch_rad) * _distance
	var back := cos(pitch_rad) * _distance
	_camera.position = Vector3(0.0, height, back)
	_camera.look_at(global_transform.origin, Vector3.UP)

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
