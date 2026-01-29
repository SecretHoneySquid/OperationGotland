class_name BuildingBombardmentController
extends Node2D

## Controller for missile carrier bombardment targeting.
## Similar to BombardmentController but for building-based bombardment.

signal bombardment_mode_changed(active: bool, carrier: MissileCarrierTurret)

@export var team_id := "p1"
@export var placement_snap := 10.0
@export var show_ghost := true
@export var render_2d := true

@export var ghost_valid_fill := Color(0.2, 0.5, 0.9, 0.3)
@export var ghost_invalid_fill := Color(0.5, 0.1, 0.05, 0.3)
@export var ghost_outline := Color(0.3, 0.6, 1.0, 0.7)
@export var ghost_outline_width := 3.0
@export var range_indicator_color := Color(0.3, 0.5, 0.9, 0.25)
@export var range_indicator_outline := Color(0.2, 0.4, 0.8, 0.6)
@export var ghost_radius := 25.0
@export var cancel_drag_threshold := 8.0

var _active_carrier: MissileCarrierTurret = null
var _ghost_pos := Vector2.ZERO
var _ghost_valid := false
var _world_input: Node
var _cancel_dragging := false
var _cancel_start := Vector2.ZERO

func _ready() -> void:
	add_to_group("building_bombardment_controller")
	_world_input = _find_world_input()

func _process(_delta: float) -> void:
	if _active_carrier == null or not is_instance_valid(_active_carrier):
		if _active_carrier != null:
			cancel_bombardment()
		return
	_ghost_pos = _get_mouse_world_pos()
	_ghost_pos = _snap_position(_ghost_pos)
	_ghost_valid = _can_target(_ghost_pos)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _active_carrier == null:
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
	if _active_carrier == null or not is_instance_valid(_active_carrier):
		return

	# Draw range indicator around carrier
	var carrier_pos := _active_carrier.global_position
	var range := _active_carrier.get_bombardment_range()
	draw_circle(carrier_pos, range, range_indicator_color, true)
	draw_circle(carrier_pos, range, range_indicator_outline, false, 2.0)

	# Draw ghost target
	if show_ghost:
		var fill := ghost_valid_fill if _ghost_valid else ghost_invalid_fill
		draw_circle(_ghost_pos, ghost_radius, fill, true)
		draw_circle(_ghost_pos, ghost_radius, ghost_outline, false, ghost_outline_width)

		# Draw crosshair
		var crosshair_size := ghost_radius * 0.6
		draw_line(_ghost_pos + Vector2(-crosshair_size, 0), _ghost_pos + Vector2(crosshair_size, 0), ghost_outline, 2.0)
		draw_line(_ghost_pos + Vector2(0, -crosshair_size), _ghost_pos + Vector2(0, crosshair_size), ghost_outline, 2.0)

		# Draw line from carrier to target
		if _ghost_valid:
			draw_line(carrier_pos, _ghost_pos, ghost_outline, 1.5)

func start_bombardment(carrier: MissileCarrierTurret) -> void:
	print("[BUILDING_BOMBARDMENT] start_bombardment called with carrier: ", carrier)
	if carrier == null or not is_instance_valid(carrier):
		print("[BUILDING_BOMBARDMENT] Aborted: invalid carrier")
		return
	_active_carrier = carrier
	print("[BUILDING_BOMBARDMENT] Bombardment mode ACTIVATED for carrier at ", carrier.global_position)
	emit_signal("bombardment_mode_changed", true, carrier)
	queue_redraw()

func cancel_bombardment() -> void:
	_active_carrier = null
	emit_signal("bombardment_mode_changed", false, null)
	queue_redraw()

func is_active() -> bool:
	return _active_carrier != null and is_instance_valid(_active_carrier)

func get_active_carrier() -> MissileCarrierTurret:
	return _active_carrier

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func _try_launch() -> void:
	print("[BUILDING_BOMBARDMENT] _try_launch called, ghost_valid=", _ghost_valid, " pos=", _ghost_pos)
	if not _ghost_valid:
		print("[BUILDING_BOMBARDMENT] Aborted: ghost not valid")
		return
	if _active_carrier == null or not is_instance_valid(_active_carrier):
		print("[BUILDING_BOMBARDMENT] Aborted: no active carrier")
		cancel_bombardment()
		return

	# Request bombardment from carrier
	print("[BUILDING_BOMBARDMENT] Requesting bombardment from carrier...")
	var success := _active_carrier.request_bombardment(_ghost_pos)
	if success:
		print("[BUILDING_BOMBARDMENT] Strike ACCEPTED at: ", _ghost_pos)
	else:
		print("[BUILDING_BOMBARDMENT] Strike REJECTED")
	cancel_bombardment()

func _can_target(pos: Vector2) -> bool:
	if _active_carrier == null or not is_instance_valid(_active_carrier):
		return false
	var dist := _active_carrier.global_position.distance_to(pos)
	var range := _active_carrier.get_bombardment_range()
	if dist > range:
		return false
	if not _active_carrier.is_bombardment_ready():
		return false
	# Check true vision requirement
	if not _active_carrier._is_in_true_vision(pos):
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
