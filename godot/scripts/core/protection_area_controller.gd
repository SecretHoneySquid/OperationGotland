class_name ProtectionAreaController
extends Node2D

## Protection Area Controller
##
## Handles single-click selection of a pie-shaped protection area for Patriot turrets.
## User moves mouse to aim the direction, left-click confirms, right-click cancels.

signal protection_mode_changed(active: bool, target: Node2D)

@export var team_id := "p1"
@export var render_2d := true
@export var cancel_drag_threshold := 8.0

@export var preview_fill_color := Color(0.2, 0.6, 0.9, 0.2)
@export var preview_outline_color := Color(0.3, 0.7, 1.0, 0.8)
@export var preview_outline_width := 2.5
@export var preview_direction_color := Color(1.0, 1.0, 0.3, 0.8)
@export var fixed_arc_half_angle := deg_to_rad(30.0)  # Fixed 60 degree arc (30 degrees each side)

var _active := false
var _active_turret: Node2D = null
var _direction_angle := 0.0  # Angle from turret toward mouse
var _world_input: Node
var _cancel_dragging := false
var _cancel_start := Vector2.ZERO

func _ready() -> void:
	add_to_group("protection_area_controller")
	_world_input = _find_world_input()

func _process(_delta: float) -> void:
	if not _active:
		return
	if _active_turret == null or not is_instance_valid(_active_turret):
		cancel_selection()
		return

	# Update direction to point toward mouse
	var mouse_pos := _get_mouse_world_pos()
	var turret_pos := _active_turret.global_position
	var to_mouse := mouse_pos - turret_pos
	if to_mouse.length_squared() > 1.0:
		_direction_angle = to_mouse.angle()

	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Left click confirms the direction
		_apply_protection_area()
		get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_cancel_dragging = true
			_cancel_start = event.position
		else:
			if not _cancel_dragging:
				return
			_cancel_dragging = false
			if _cancel_start.distance_to(event.position) <= cancel_drag_threshold:
				cancel_selection()
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_selection()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if not render_2d:
		return
	if not _active:
		return
	if _active_turret == null or not is_instance_valid(_active_turret):
		return

	var turret_pos := _active_turret.global_position
	var range_radius := 0.0
	var range_value: Variant = _active_turret.get("attack_range") if _active_turret.has_method("get") else null
	if range_value is float or range_value is int:
		range_radius = float(range_value)
	if range_radius <= 0.0:
		return

	# Draw the pie preview
	var start_angle := _direction_angle - fixed_arc_half_angle
	var end_angle := _direction_angle + fixed_arc_half_angle

	# Draw filled pie
	_draw_pie(turret_pos, range_radius, start_angle, end_angle, preview_fill_color)

	# Draw pie outline
	_draw_pie_outline(turret_pos, range_radius, start_angle, end_angle, preview_outline_color, preview_outline_width)

	# Draw center direction line
	var direction := Vector2.from_angle(_direction_angle)
	draw_line(turret_pos, turret_pos + direction * range_radius, preview_direction_color, 3.0)

	# Draw direction indicator at the end
	var arrow_pos := turret_pos + direction * range_radius
	draw_circle(arrow_pos, 10.0, preview_direction_color)

	# Draw instruction text near turret
	_draw_instruction(turret_pos, "Click to confirm direction")

func _draw_instruction(pos: Vector2, text: String) -> void:
	var offset := Vector2(0, -60)
	var font := ThemeDB.fallback_font
	var font_size := 16
	draw_string(font, pos + offset, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _draw_pie(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	points.append(center)
	var segments := 32
	var angle_step := (end_angle - start_angle) / float(segments)
	for i in range(segments + 1):
		var angle := start_angle + angle_step * float(i)
		points.append(center + Vector2.from_angle(angle) * radius)
	draw_colored_polygon(points, color)

func _draw_pie_outline(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, width: float) -> void:
	# Draw the arc
	draw_arc(center, radius, start_angle, end_angle, 32, color, width)
	# Draw the two radial lines
	draw_line(center, center + Vector2.from_angle(start_angle) * radius, color, width)
	draw_line(center, center + Vector2.from_angle(end_angle) * radius, color, width)

func start_protection_selection(turret: Node2D) -> void:
	if turret == null or not is_instance_valid(turret):
		return
	_active_turret = turret
	_active = true

	# Initialize direction: use current protection direction if configured, otherwise turret facing
	var configured := false
	var configured_value: Variant = turret.get("protection_configured") if turret.has_method("get") else false
	if configured_value is bool:
		configured = configured_value
	if configured:
		var dir_value: Variant = turret.get("protection_direction") if turret.has_method("get") else null
		if dir_value is Vector2:
			_direction_angle = (dir_value as Vector2).angle()
	else:
		var facing_value: Variant = turret.get("_facing") if turret.has_method("get") else Vector2.RIGHT
		if facing_value is Vector2:
			_direction_angle = (facing_value as Vector2).angle()
		else:
			_direction_angle = Vector2.RIGHT.angle()

	emit_signal("protection_mode_changed", true, turret)
	queue_redraw()

func cancel_selection() -> void:
	_active = false
	var prev_turret := _active_turret
	_active_turret = null
	emit_signal("protection_mode_changed", false, prev_turret)
	queue_redraw()

func _apply_protection_area() -> void:
	if _active_turret == null or not is_instance_valid(_active_turret):
		cancel_selection()
		return

	if _active_turret.has_method("set_protection_area"):
		_active_turret.call("set_protection_area", _direction_angle, fixed_arc_half_angle)
	else:
		cancel_selection()
		return
	cancel_selection()

func is_active() -> bool:
	return _active

func get_active_turret() -> Node2D:
	return _active_turret

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func _get_mouse_world_pos() -> Vector2:
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
