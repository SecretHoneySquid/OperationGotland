class_name BattalionPlacementPreview
extends Control

## Draws a ghost formation preview during battalion placement.
## Must be added as a child of a CanvasLayer to be visible over 3D.

var _battalion_controller: BattalionController
var _placing := false
var _placing_type: Battalion.Type = Battalion.Type.ASSAULT
var _mouse_pos := Vector2.ZERO
var _world_input: Node

@export var dot_color := Color(0.2, 0.8, 1.0, 0.6)
@export var dot_radius := 6.0


func configure(battalion_ctrl: BattalionController) -> void:
	_battalion_controller = battalion_ctrl
	if _battalion_controller != null:
		_battalion_controller.placement_started.connect(_on_placement_started)
		_battalion_controller.placement_cancelled.connect(_on_placement_cancelled)
		_battalion_controller.battalion_spawned.connect(_on_battalion_spawned)


func _ready() -> void:
	# Make sure we cover the full screen and don't block input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = Control.PRESET_FULL_RECT
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if not _placing:
		visible = false
		return

	visible = true
	_mouse_pos = _get_world_mouse_pos()
	queue_redraw()


func _get_world_mouse_pos() -> Vector2:
	if _world_input == null or not is_instance_valid(_world_input):
		var nodes := get_tree().get_nodes_in_group("world_input")
		if not nodes.is_empty():
			_world_input = nodes[0]
	if _world_input != null and _world_input.has_method("screen_to_world"):
		return _world_input.screen_to_world(get_viewport().get_mouse_position())
	return get_global_mouse_position()


func _world_to_screen(world_pos: Vector2) -> Vector2:
	# Convert world position to screen position for drawing on CanvasLayer
	if _world_input == null or not is_instance_valid(_world_input):
		var nodes := get_tree().get_nodes_in_group("world_input")
		if not nodes.is_empty():
			_world_input = nodes[0]
	if _world_input != null and _world_input.has_method("world_to_screen"):
		return _world_input.world_to_screen(world_pos)
	# Fallback - just return the position (won't work correctly but better than nothing)
	return world_pos


func _draw() -> void:
	if not _placing:
		return

	# Get formation positions for the current type
	var facing := Vector2.RIGHT  # Default facing
	var positions: Array[Vector2] = BattalionFormation.get_positions(_placing_type, _mouse_pos, facing)

	# Draw each unit position as a small dot (convert world to screen)
	for pos in positions:
		var screen_pos: Vector2 = _world_to_screen(pos)
		draw_circle(screen_pos, dot_radius, dot_color)

	# Draw a larger circle at the center (target position)
	var center_screen: Vector2 = _world_to_screen(_mouse_pos)
	draw_circle(center_screen, dot_radius * 2, Color(1.0, 1.0, 1.0, 0.7))
	draw_arc(center_screen, dot_radius * 3, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.5), 2.0)


func _on_placement_started(type: Battalion.Type) -> void:
	print("BattalionPlacementPreview: placement_started signal received, type=", type)
	_placing = true
	_placing_type = type


func _on_placement_cancelled() -> void:
	print("BattalionPlacementPreview: placement_cancelled signal received")
	_placing = false


func _on_battalion_spawned(_battalion: Battalion) -> void:
	print("BattalionPlacementPreview: battalion_spawned signal received")
	_placing = false
