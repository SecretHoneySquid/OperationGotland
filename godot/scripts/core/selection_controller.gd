class_name SelectionController
extends Node2D

signal building_selected(building: Building)
signal units_selected(units: Array[Unit])
signal battalion_selected(battalion: Battalion)

@export var team_id := "p1"
@export var build_controller_path := NodePath("../BuildController")
@export var game_controller_path := NodePath("../GameController")
@export var bombardment_controller_path := NodePath("../BombardmentController")
@export var battalion_controller_path := NodePath("../BattalionController")
@export var ui_block_rect := Rect2(0.0, 100.0, 280.0, 820.0)
@export var selection_radius := 32.0
@export var drag_threshold := 6.0
@export var selection_fill := Color(0.2, 0.8, 1.0, 0.15)
@export var selection_outline := Color(0.2, 0.8, 1.0, 0.7)
@export var move_spread := 18.0
@export var render_2d := true
@export var command_drag_threshold := 8.0
@export var selection_box_overlay_path := NodePath("../UI/SelectionBoxOverlay")

var _build_controller: BuildController
var _game_controller: GameController
var _bombardment_controller: BombardmentController
var _battalion_controller: BattalionController
var _selected: Array[Unit] = []
var _selected_building: Building
var _selected_battalion: Battalion
var _dragging := false
var _drag_start := Vector2.ZERO
var _drag_end := Vector2.ZERO
var _rmb_dragging := false
var _rmb_start := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _world_input: Node
var _selection_box_overlay: Control

func _ready() -> void:
	_build_controller = get_node_or_null(build_controller_path) as BuildController
	_game_controller = get_node_or_null(game_controller_path) as GameController
	_bombardment_controller = get_node_or_null(bombardment_controller_path) as BombardmentController
	_battalion_controller = get_node_or_null(battalion_controller_path) as BattalionController
	_selection_box_overlay = get_node_or_null(selection_box_overlay_path) as Control
	_rng.randomize()
	_world_input = _find_world_input()

func _unhandled_input(event: InputEvent) -> void:
	if _build_controller != null and _build_controller.is_placing():
		return
	if _bombardment_controller != null and _bombardment_controller.is_active():
		return
	if _game_controller != null and _game_controller.is_rally_mode(team_id):
		return
	if _battalion_controller != null and _battalion_controller.is_placing():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if ui_block_rect.has_point(event.position):
				return
			_dragging = true
			_drag_start = _screen_to_world(event.position)
			_drag_end = _drag_start
			if _selection_box_overlay != null and _selection_box_overlay.has_method("start_drag"):
				_selection_box_overlay.start_drag(event.position)
			queue_redraw()
		else:
			if not _dragging:
				return
			_dragging = false
			_drag_end = _screen_to_world(event.position)
			_finalize_selection(event)
			if _selection_box_overlay != null and _selection_box_overlay.has_method("end_drag"):
				_selection_box_overlay.end_drag()
			queue_redraw()
	elif event is InputEventMouseMotion and _dragging:
		_drag_end = _screen_to_world(event.position)
		if _selection_box_overlay != null and _selection_box_overlay.has_method("update_drag"):
			_selection_box_overlay.update_drag(event.position)
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if ui_block_rect.has_point(event.position):
				return
			_rmb_dragging = true
			_rmb_start = event.position
		else:
			if not _rmb_dragging:
				return
			_rmb_dragging = false
			if _rmb_start.distance_to(event.position) <= command_drag_threshold:
				_issue_move(_screen_to_world(event.position))

func _draw() -> void:
	if not render_2d:
		return
	if not _dragging:
		return
	var rect := Rect2(_drag_start, _drag_end - _drag_start).abs()
	draw_rect(rect, selection_fill, true)
	draw_rect(rect, selection_outline, false, 2.0)

func _finalize_selection(event: InputEventMouseButton) -> void:
	var rect := Rect2(_drag_start, _drag_end - _drag_start).abs()
	var shift := Input.is_key_pressed(KEY_SHIFT)
	if rect.size.length() < drag_threshold:
		_select_single(_drag_end, shift)
	else:
		_select_box(rect, shift)

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func _select_single(pos: Vector2, add: bool) -> void:
	var building := _pick_building(pos)
	if building != null:
		_clear_selection()
		_clear_selected_battalion()
		_set_selected_building(building)
		return

	# Check for battalion selection
	var battalion := _pick_battalion(pos)
	if battalion != null:
		_clear_selection()
		_clear_selected_building()
		_set_selected_battalion(battalion)
		return

	var best: Unit = null
	var best_dist := selection_radius * selection_radius
	for unit in _get_units():
		var dist := unit.global_position.distance_squared_to(pos)
		if dist <= best_dist:
			best = unit
			best_dist = dist
	if not add:
		_clear_selection()
	if best != null:
		_toggle_select(best, add)
		_clear_selected_building()
		_clear_selected_battalion()
	else:
		_clear_selected_building()
		_clear_selected_battalion()

func _select_box(rect: Rect2, add: bool) -> void:
	if not add:
		_clear_selection()
		_clear_selected_building()
	for unit in _get_units():
		if rect.has_point(unit.global_position):
			_add_selected(unit)

func _issue_move(target: Vector2) -> void:
	if _selected.is_empty():
		return
	for unit in _selected:
		if not is_instance_valid(unit):
			continue
		var offset := Vector2(
			_rng.randf_range(-move_spread, move_spread),
			_rng.randf_range(-move_spread, move_spread)
		)
		unit.issue_move(target + offset)

func _toggle_select(unit: Unit, add: bool) -> void:
	if add and _selected.has(unit):
		_remove_selected(unit)
		return
	_add_selected(unit)

func _add_selected(unit: Unit) -> void:
	if _selected.has(unit):
		return
	_selected.append(unit)
	unit.set_selected(true)
	emit_signal("units_selected", _selected)

func _remove_selected(unit: Unit) -> void:
	_selected.erase(unit)
	unit.set_selected(false)
	emit_signal("units_selected", _selected)

func _clear_selection() -> void:
	for unit in _selected:
		if is_instance_valid(unit):
			unit.set_selected(false)
	_selected.clear()
	emit_signal("units_selected", _selected)

func _set_selected_building(building: Building) -> void:
	if _selected_building == building:
		return
	# Deselect previous building
	if _selected_building != null and is_instance_valid(_selected_building):
		_selected_building.set_selected(false)
	_selected_building = building
	# Select new building
	if _selected_building != null and is_instance_valid(_selected_building):
		_selected_building.set_selected(true)
	emit_signal("building_selected", building)

func _clear_selected_building() -> void:
	if _selected_building == null:
		return
	# Deselect the building
	if is_instance_valid(_selected_building):
		_selected_building.set_selected(false)
	_selected_building = null
	emit_signal("building_selected", null)

func _get_units() -> Array[Unit]:
	var group_name := "units_%s" % team_id
	var nodes := get_tree().get_nodes_in_group(group_name)
	var units: Array[Unit] = []
	for node in nodes:
		if node is Unit:
			units.append(node)
	return units

func _pick_building(pos: Vector2) -> Building:
	var best: Building = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("building"):
		var building := node as Building
		if building == null:
			continue
		if building.team_id != team_id:
			continue
		if not building.visible:
			continue
		var rect := Rect2(building.global_position - (building.size / 2.0), building.size)
		if not rect.has_point(pos):
			continue
		var dist := building.global_position.distance_squared_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = building
	return best

func _screen_to_world(pos: Vector2) -> Vector2:
	var input := _world_input
	if input == null or not is_instance_valid(input):
		input = _find_world_input()
		_world_input = input
	if input != null and input.has_method("screen_to_world"):
		return input.screen_to_world(pos)
	# get_global_mouse_position already accounts for the active Camera2D.
	return get_global_mouse_position()

func _find_world_input() -> Node:
	var nodes := get_tree().get_nodes_in_group("world_input")
	if nodes.is_empty():
		return null
	return nodes[0] as Node


func _pick_battalion(pos: Vector2) -> Battalion:
	if _battalion_controller == null:
		return null
	return _battalion_controller.get_battalion_at(pos)


func _set_selected_battalion(battalion: Battalion) -> void:
	if _selected_battalion == battalion:
		return
	_selected_battalion = battalion
	if _battalion_controller != null:
		_battalion_controller.select_battalion(battalion)
	emit_signal("battalion_selected", battalion)


func _clear_selected_battalion() -> void:
	if _selected_battalion == null:
		return
	_selected_battalion = null
	if _battalion_controller != null:
		_battalion_controller.clear_selection()
	emit_signal("battalion_selected", null)
