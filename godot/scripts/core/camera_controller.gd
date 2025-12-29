extends Camera2D

@export var pan_speed := 900.0
@export var zoom_step := 0.1
@export var min_zoom := 0.4
@export var max_zoom := 1.6
@export var drag_speed := 1.0
@export var use_perspective_tilt := true:
	set(value):
		use_perspective_tilt = value
		_apply_tilt()
@export var tilt_down_axis_deg := 135.0:
	set(value):
		tilt_down_axis_deg = value
		_apply_tilt()
@export var use_down_axis_pitch := true:
	set(value):
		use_down_axis_pitch = value
		_apply_tilt()
@export var tilt_pitch_deg := 45.0:
	set(value):
		tilt_pitch_deg = value
		_apply_tilt()
@export var tilt_skew_strength := 0.6:
	set(value):
		tilt_skew_strength = value
		_apply_tilt()
@export var tilt_yaw_deg := 0.0:
	set(value):
		tilt_yaw_deg = value
		_apply_tilt()
@export var rotate_drag_speed := 0.2
@export var middle_drag_mode := "rotate"

var _dragging := false
var _base_zoom := 1.0
var _drag_mode := ""

func _ready() -> void:
	_base_zoom = zoom.x
	_apply_tilt()

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * pan_speed * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom - Vector2.ONE * zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(zoom + Vector2.ONE * zoom_step)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = true
			_drag_mode = _get_middle_drag_mode()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = false
		_drag_mode = ""
	elif event is InputEventMouseMotion and _dragging:
		if _drag_mode == "rotate":
			_rotate_from_drag(event.relative.x)
		else:
			position -= event.relative * drag_speed * zoom.x

func _set_zoom(value: Vector2) -> void:
	var z := clampf(value.x, min_zoom, max_zoom)
	_base_zoom = z
	_apply_tilt()

func _get_middle_drag_mode() -> String:
	if Input.is_key_pressed(KEY_SHIFT):
		return "pan"
	return middle_drag_mode

func _rotate_from_drag(delta_x: float) -> void:
	if absf(delta_x) <= 0.01:
		return
	tilt_yaw_deg = fposmod(tilt_yaw_deg + (delta_x * rotate_drag_speed), 360.0)
	_apply_tilt()

func _apply_tilt() -> void:
	if not use_perspective_tilt:
		rotation = deg_to_rad(tilt_yaw_deg)
		skew = 0.0
		zoom = Vector2(_base_zoom, _base_zoom)
		return
	var pitch := tilt_pitch_deg
	if use_down_axis_pitch:
		pitch = abs(tilt_down_axis_deg - 90.0)
	pitch = clampf(pitch, 0.0, 80.0)
	var pitch_rad := deg_to_rad(pitch)
	var y_scale := maxf(0.25, cos(pitch_rad))
	rotation = deg_to_rad(tilt_yaw_deg)
	skew = -pitch_rad * tilt_skew_strength
	zoom = Vector2(_base_zoom, _base_zoom * y_scale)
