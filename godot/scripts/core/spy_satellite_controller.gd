class_name SpySatelliteController
extends Node2D

signal satellite_mode_changed(active: bool, hq: HQ)

@export var team_id := "p1"
@export var render_2d := true
@export var cancel_drag_threshold := 8.0

@export var ghost_fill := Color(0.1, 0.5, 0.9, 0.3)
@export var ghost_outline := Color(0.2, 0.6, 1.0, 0.7)
@export var ghost_outline_width := 3.0

var _active := false
var _active_hq: HQ = null
var _ghost_pos := Vector2.ZERO
var _ghost_radius := 400.0
var _world_input: Node
var _cancel_dragging := false
var _cancel_start := Vector2.ZERO
var _game_controller: GameController

func _ready() -> void:
	_world_input = _find_world_input()
	_ghost_radius = GameBalance.SPY_SATELLITE_VISION_RADIUS
	add_to_group("spy_satellite_controller")

func _process(_delta: float) -> void:
	if not _active or _active_hq == null:
		return
	if not is_instance_valid(_active_hq):
		cancel_satellite_mode()
		return
	_ghost_pos = _get_mouse_world_pos()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_activate()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_cancel_dragging = true
			_cancel_start = event.position
		else:
			if not _cancel_dragging:
				return
			_cancel_dragging = false
			if _cancel_start.distance_to(event.position) <= cancel_drag_threshold:
				cancel_satellite_mode()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_satellite_mode()

func _draw() -> void:
	if not render_2d or not _active:
		return
	# Draw circular ghost preview showing vision radius
	draw_circle(_ghost_pos, _ghost_radius, ghost_fill, true)
	draw_circle(_ghost_pos, _ghost_radius, ghost_outline, false, ghost_outline_width)
	# Draw crosshair in center
	var crosshair_size := 20.0
	draw_line(_ghost_pos + Vector2(-crosshair_size, 0), _ghost_pos + Vector2(crosshair_size, 0), ghost_outline, 2.0)
	draw_line(_ghost_pos + Vector2(0, -crosshair_size), _ghost_pos + Vector2(0, crosshair_size), ghost_outline, 2.0)

func start_satellite_mode(hq: HQ) -> void:
	if hq == null or not is_instance_valid(hq):
		return
	_active_hq = hq
	_active = true
	emit_signal("satellite_mode_changed", true, hq)
	queue_redraw()

func cancel_satellite_mode() -> void:
	_active = false
	_active_hq = null
	emit_signal("satellite_mode_changed", false, null)
	queue_redraw()

func is_active() -> bool:
	return _active

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func _try_activate() -> void:
	if _active_hq == null or not is_instance_valid(_active_hq):
		cancel_satellite_mode()
		return
	# Find game controller and activate satellite
	var game_controller := _find_game_controller()
	if game_controller != null:
		var success := game_controller.activate_spy_satellite(_active_hq.team_id, _ghost_pos)
		if success:
			print("[SPY SATELLITE] Activated at: ", _ghost_pos)
		else:
			print("[SPY SATELLITE] Failed to activate - insufficient credits or on cooldown")
	cancel_satellite_mode()

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

func _find_game_controller() -> GameController:
	if _game_controller != null and is_instance_valid(_game_controller):
		return _game_controller
	var nodes := get_tree().get_nodes_in_group("game_controller")
	if nodes.is_empty():
		# Try to get parent if it's a GameController
		var parent := get_parent()
		if parent is GameController:
			_game_controller = parent
			return _game_controller
		return null
	_game_controller = nodes[0] as GameController
	return _game_controller
