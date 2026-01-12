class_name BombardmentController
extends Node2D

signal bombardment_mode_changed(active: bool, unit: Unit)

@export var team_id := "p1"
@export var placement_snap := 10.0
@export var show_ghost := true
@export var render_2d := true

@export var ghost_valid_fill := Color(0.9, 0.3, 0.1, 0.3)
@export var ghost_invalid_fill := Color(0.5, 0.1, 0.05, 0.3)
@export var ghost_outline := Color(1.0, 0.5, 0.2, 0.7)
@export var ghost_outline_width := 3.0
@export var range_indicator_color := Color(1.0, 0.6, 0.3, 0.4)
@export var range_indicator_outline := Color(1.0, 0.4, 0.1, 0.6)
@export var ghost_radius := 20.0
@export var cancel_drag_threshold := 8.0

var _active_unit: Unit = null
var _ghost_pos := Vector2.ZERO
var _ghost_valid := false
var _world_input: Node
var _cancel_dragging := false
var _cancel_start := Vector2.ZERO

func _ready() -> void:
	_world_input = _find_world_input()

func _process(_delta: float) -> void:
	if _active_unit == null or not is_instance_valid(_active_unit):
		if _active_unit != null:
			cancel_bombardment()
		return
	_ghost_pos = _get_mouse_world_pos()
	_ghost_pos = _snap_position(_ghost_pos)
	_ghost_valid = _can_place(_ghost_pos)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _active_unit == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_launch()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_cancel_dragging = true
			_cancel_start = event.position
		else:
			if not _cancel_dragging:
				return
			_cancel_dragging = false
			if _cancel_start.distance_to(event.position) <= cancel_drag_threshold:
				cancel_bombardment()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_bombardment()

func _draw() -> void:
	if not render_2d:
		return
	if _active_unit == null or not is_instance_valid(_active_unit):
		return

	# Draw range indicator around HIMARS
	var unit_pos := _active_unit.global_position
	var range := _active_unit.get_bombardment_range()
	draw_circle(unit_pos, range, range_indicator_color, true)
	draw_circle(unit_pos, range, range_indicator_outline, false, 2.0)

	# Draw ghost target
	if show_ghost:
		var fill := ghost_valid_fill if _ghost_valid else ghost_invalid_fill
		draw_circle(_ghost_pos, ghost_radius, fill, true)
		draw_circle(_ghost_pos, ghost_radius, ghost_outline, false, ghost_outline_width)

		# Draw crosshair
		var crosshair_size := ghost_radius * 0.6
		draw_line(_ghost_pos + Vector2(-crosshair_size, 0), _ghost_pos + Vector2(crosshair_size, 0), ghost_outline, 2.0)
		draw_line(_ghost_pos + Vector2(0, -crosshair_size), _ghost_pos + Vector2(0, crosshair_size), ghost_outline, 2.0)

func start_bombardment(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if not unit.is_himars:
		return
	_active_unit = unit
	emit_signal("bombardment_mode_changed", true, unit)
	queue_redraw()

func cancel_bombardment() -> void:
	_active_unit = null
	emit_signal("bombardment_mode_changed", false, null)
	queue_redraw()

func is_active() -> bool:
	return _active_unit != null and is_instance_valid(_active_unit)

func get_active_unit() -> Unit:
	return _active_unit

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func _try_launch() -> void:
	if not _ghost_valid:
		return
	if _active_unit == null or not is_instance_valid(_active_unit):
		cancel_bombardment()
		return

	# Check if area bombardment is already active - if so, toggle it off
	if _active_unit.is_area_bombardment_active():
		_active_unit.clear_bombardment_area()
		cancel_bombardment()
		print("[BOMBARDMENT] Area bombardment cancelled")
	else:
		# Set area bombardment target - HIMARS will spam this location
		_active_unit.set_bombardment_area(_ghost_pos)
		cancel_bombardment()
		print("[BOMBARDMENT] Area bombardment activated at: ", _ghost_pos)

func _can_place(pos: Vector2) -> bool:
	if _active_unit == null or not is_instance_valid(_active_unit):
		return false
	var dist := _active_unit.global_position.distance_to(pos)
	var range := _active_unit.get_bombardment_range()
	if dist > range:
		return false
	if not _active_unit.is_bombardment_ready():
		return false
	return true

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
