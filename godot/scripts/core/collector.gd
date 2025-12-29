class_name Collector
extends Node2D

@export var team_id := "p1"
@export var speed := 90.0
@export var carry_capacity := 100.0
@export var harvest_time := 1.0
@export var body_radius := 6.0
@export var vision_radius := 180.0
@export var color := Color(0.9, 0.85, 0.2, 1.0):
	set(value):
		color = value
		_update_visual_color()
		queue_redraw()
@export var visual_scene_path := ""
@export var visual_base_radius := 8.0
@export var visual_offset := Vector2.ZERO
@export var render_2d := true

var economy: GameController
var base_pos := Vector2.ZERO
var resource_pos := Vector2.ZERO
var resource_index := -1
var _state := "idle"
var _cargo := 0.0
var _harvest_timer := 0.0
var _facing := Vector2.RIGHT
var _visual_node: Node2D

func _ready() -> void:
	add_to_group("collectors")
	add_to_group("collectors_%s" % team_id)
	if team_id == "p1" and vision_radius > 0.0:
		add_to_group("vision_p1")
		var light := VisionHelper.create_light(vision_radius)
		add_child(light)
	_setup_visual()

func configure(economy_ref: GameController, team: String, base: Vector2) -> void:
	economy = economy_ref
	team_id = team
	base_pos = base
	_assign_resource()

func _process(delta: float) -> void:
	if economy == null:
		return
	match _state:
		"to_node":
			_move_toward(resource_pos, delta)
			if global_position.distance_to(resource_pos) <= 4.0:
				_state = "harvest"
				_harvest_timer = harvest_time
		"harvest":
			_harvest_timer -= delta
			if _harvest_timer <= 0.0:
				_cargo = economy.harvest_resource(resource_index, carry_capacity)
				if _cargo <= 0.0:
					_assign_resource()
				else:
					_state = "to_base"
		"to_base":
			_move_toward(base_pos, delta)
			if global_position.distance_to(base_pos) <= 4.0:
				economy.deposit_credits(team_id, int(_cargo))
				_cargo = 0.0
				_assign_resource()
		"idle":
			_assign_resource()
	_sync_visual_rotation()

func _draw() -> void:
	if not render_2d:
		return
	if _visual_node == null:
		var angle := _facing.angle()
		var base_color := color
		var scale := body_radius / 7.0
		var hull := _get_hull_points()
		draw_circle(Vector2(2.0, 3.0), body_radius * 0.9, Color(0.0, 0.0, 0.0, 0.2))
		var base_points := _transform_points(hull, angle, scale)
		var top_points := _transform_points(hull, angle, scale * 0.72, Vector2(-1.0, -1.0))
		draw_colored_polygon(base_points, _shade(base_color, -0.1))
		draw_colored_polygon(top_points, _shade(base_color, 0.12))
		var outline := base_points.duplicate()
		if outline.size() > 0:
			outline.append(base_points[0])
			draw_polyline(outline, _shade(base_color, -0.3), 1.4)
		var cargo_offset := Vector2(-body_radius * 0.4, -body_radius * 0.15).rotated(angle)
		draw_circle(cargo_offset, body_radius * 0.35, _shade(base_color, 0.25))
		draw_line(Vector2.ZERO, Vector2(body_radius * 0.7, 0.0).rotated(angle), _shade(base_color, 0.35), 2.0)

func _shade(src: Color, amount: float) -> Color:
	return Color(
		clampf(src.r + amount, 0.0, 1.0),
		clampf(src.g + amount, 0.0, 1.0),
		clampf(src.b + amount, 0.0, 1.0),
		src.a
	)

func _transform_points(points: Array, angle: float, scale: float, offset := Vector2.ZERO) -> PackedVector2Array:
	var transformed := PackedVector2Array()
	for point in points:
		if point is Vector2:
			transformed.append((point * scale).rotated(angle) + offset)
	return transformed

func _get_hull_points() -> Array:
	return [
		Vector2(8, 0),
		Vector2(4, -4),
		Vector2(-6, -4),
		Vector2(-8, 0),
		Vector2(-6, 4),
		Vector2(4, 4),
	]

func _assign_resource() -> void:
	if economy == null:
		_state = "idle"
		return
	var assignment: Dictionary = economy.request_resource_node(team_id)
	if assignment.is_empty():
		_state = "idle"
		return
	resource_index = int(assignment.get("index", -1))
	resource_pos = assignment.get("pos", Vector2.ZERO) as Vector2
	_state = "to_node"

func _move_toward(target: Vector2, delta: float) -> void:
	var delta_vec := target - global_position
	if delta_vec.length() <= 1.0:
		return
	var direction := delta_vec.normalized()
	global_position += direction * speed * delta
	_facing = direction

func get_vision_radius() -> float:
	return vision_radius

func set_render_2d(value: bool) -> void:
	render_2d = value
	_set_canvas_children_visible(value)
	queue_redraw()

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("Collector: missing visual scene at %s" % visual_scene_path)
		return
	if packed is PackedScene:
		var instance = packed.instantiate()
		if instance is Node2D:
			_visual_node = instance
			add_child(_visual_node)
			_visual_node.visible = render_2d
			_update_visual_transform()
			_update_visual_color()
	else:
		push_warning("Collector: visual scene is not a PackedScene at %s" % visual_scene_path)

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	_visual_node.position = visual_offset
	if visual_base_radius > 0.0:
		var scale := body_radius / visual_base_radius
		_visual_node.scale = Vector2.ONE * scale

func _update_visual_color() -> void:
	if _visual_node == null:
		return
	_visual_node.modulate = color

func _sync_visual_rotation() -> void:
	if _visual_node == null:
		return
	_visual_node.rotation = _facing.angle()

func _set_canvas_children_visible(value: bool) -> void:
	for child in get_children():
		if child is CanvasItem:
			child.visible = value
