class_name Collector
extends Node2D

@export var team_id := "p1"
@export var speed := 90.0
@export var ground_slope_max_deg := 28.0
@export var ground_slope_sample_distance := 0.0
@export var navigation_enabled := true
@export var navigation_layers := 1
@export var navigation_optimize := true
@export var navigation_repath_interval := 0.6
@export var navigation_repath_distance := 120.0
@export var navigation_point_reach_dist := 14.0
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
var _ground_height_provider: Node
var _nav_provider: Node
var _nav_path := PackedVector2Array()
var _nav_index := 0
var _nav_target := Vector2.ZERO
var _nav_repath_timer := 0.0

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
					_clear_nav_path()
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
	_clear_nav_path()
	_state = "to_node"

func _move_toward(target: Vector2, delta: float) -> void:
	var move_target := target
	if _should_use_navigation(target):
		move_target = _get_nav_move_target(target, delta)
	var delta_vec := move_target - global_position
	if delta_vec.length() <= 1.0:
		return
	var direction := delta_vec.normalized()
	var step := direction * speed * delta
	if _should_limit_ground_slope():
		var sample_dist := step.length()
		if ground_slope_sample_distance > 0.0:
			sample_dist = maxf(sample_dist, ground_slope_sample_distance)
		if sample_dist > 0.0:
			var sample_pos := global_position + direction * sample_dist
			if _is_uphill_too_steep(global_position, sample_pos):
				_facing = direction
				return
	global_position += step
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

func _should_limit_ground_slope() -> bool:
	return ground_slope_max_deg > 0.0

func _is_uphill_too_steep(from_pos: Vector2, to_pos: Vector2) -> bool:
	var delta := to_pos - from_pos
	var dist := delta.length()
	if dist <= 0.001:
		return false
	var height_from := _get_ground_height(from_pos)
	var height_to := _get_ground_height(to_pos)
	if not is_finite(height_from) or not is_finite(height_to):
		return false
	if height_to <= height_from:
		return false
	var slope := (height_to - height_from) / dist
	var max_slope := tan(deg_to_rad(ground_slope_max_deg))
	return slope > max_slope

func _get_ground_height(pos: Vector2) -> float:
	var provider := _get_ground_height_provider()
	if provider != null and provider.has_method("get_ground_height_at"):
		var value: Variant = provider.call("get_ground_height_at", pos)
		if value is float or value is int:
			return float(value)
	return 0.0

func _get_ground_height_provider() -> Node:
	if _ground_height_provider != null and is_instance_valid(_ground_height_provider):
		return _ground_height_provider
	var providers := get_tree().get_nodes_in_group("ground_height_provider")
	if not providers.is_empty():
		_ground_height_provider = providers[0]
		return _ground_height_provider
	return null

func _should_use_navigation(target: Vector2) -> bool:
	return navigation_enabled and target != Vector2.ZERO

func _get_nav_move_target(target: Vector2, delta: float) -> Vector2:
	_nav_repath_timer = maxf(0.0, _nav_repath_timer - delta)
	var needs_repath := _nav_path.is_empty() or _nav_target == Vector2.ZERO
	if not needs_repath and navigation_repath_distance > 0.0:
		needs_repath = _nav_target.distance_to(target) > navigation_repath_distance
	if needs_repath and _nav_repath_timer <= 0.0:
		_build_nav_path(target)
	_advance_nav_index()
	if _nav_path.is_empty():
		return target
	return _nav_path[_nav_index]

func _build_nav_path(target: Vector2) -> void:
	_nav_repath_timer = maxf(0.0, navigation_repath_interval)
	_nav_target = target
	_nav_index = 0
	_nav_path = PackedVector2Array()
	var provider := _get_nav_provider()
	if provider == null or not provider.has_method("get_navigation_path"):
		return
	var path_value: Variant = provider.call("get_navigation_path", global_position, target, navigation_layers, navigation_optimize)
	if path_value is PackedVector2Array:
		_nav_path = path_value
	elif path_value is Array:
		var converted := PackedVector2Array()
		for point in path_value:
			if point is Vector2:
				converted.append(point)
		_nav_path = converted
	_advance_nav_index()

func _advance_nav_index() -> void:
	if _nav_path.is_empty():
		return
	var reach_dist := maxf(1.0, navigation_point_reach_dist)
	while _nav_index < _nav_path.size() and global_position.distance_to(_nav_path[_nav_index]) <= reach_dist:
		_nav_index += 1
	if _nav_index >= _nav_path.size():
		_clear_nav_path()

func _clear_nav_path() -> void:
	_nav_path = PackedVector2Array()
	_nav_index = 0
	_nav_target = Vector2.ZERO

func _get_nav_provider() -> Node:
	if _nav_provider != null and is_instance_valid(_nav_provider):
		return _nav_provider
	var providers := get_tree().get_nodes_in_group("navigation_provider")
	if not providers.is_empty():
		_nav_provider = providers[0]
		return _nav_provider
	return null
