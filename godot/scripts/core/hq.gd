class_name HQ
extends Node2D

@export var team_id := "p1"
@export var size := Vector2(140, 140):
	set(value):
		size = value
		_update_visual_transform()
		queue_redraw()

@export var fill_color := Color(0.25, 0.25, 0.25, 1.0):
	set(value):
		fill_color = value
		_update_visual_color()
		queue_redraw()

@export var outline_color := Color(0.95, 0.95, 0.95, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

@export var outline_width := 2.0:
	set(value):
		outline_width = value
		queue_redraw()

@export var max_hp := 500.0
@export var show_health := true
@export var health_bar_height := 8.0
@export var health_bar_offset := 12.0
@export var vision_radius := 280.0
@export var visual_scene_path := ""
@export var visual_base_size := Vector2.ZERO
@export var visual_offset := Vector2.ZERO
@export var render_2d := true

var hp := 0.0
var _visual_node: Node2D

func _ready() -> void:
	hp = max_hp
	add_to_group("hq")
	add_to_group("hq_%s" % team_id)
	if team_id == "p1" and vision_radius > 0.0:
		add_to_group("vision_p1")
		var light := VisionHelper.create_light(vision_radius)
		add_child(light)
	_setup_visual()

func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	queue_redraw()
	if hp <= 0.0:
		queue_free()

func get_vision_radius() -> float:
	return vision_radius

func _draw() -> void:
	if not render_2d:
		return
	var height := minf(22.0, size.y * 0.22)
	if _visual_node == null:
		var base_rect := Rect2(-size / 2.0, size)
		var top_offset := Vector2(-height * 0.4, -height)
		var b_tl := base_rect.position
		var b_tr := base_rect.position + Vector2(size.x, 0.0)
		var b_br := base_rect.position + size
		var b_bl := base_rect.position + Vector2(0.0, size.y)
		var t_tl := b_tl + top_offset
		var t_tr := b_tr + top_offset
		var t_br := b_br + top_offset
		var t_bl := b_bl + top_offset
		draw_colored_polygon(
			PackedVector2Array([b_tl + Vector2(4.0, 5.0), b_tr + Vector2(4.0, 5.0), b_br + Vector2(4.0, 5.0), b_bl + Vector2(4.0, 5.0)]),
			Color(0.0, 0.0, 0.0, 0.22)
		)
		draw_colored_polygon(PackedVector2Array([b_tr, b_br, t_br, t_tr]), _shade(fill_color, -0.08))
		draw_colored_polygon(PackedVector2Array([b_bl, b_br, t_br, t_bl]), _shade(fill_color, -0.18))
		draw_colored_polygon(PackedVector2Array([t_tl, t_tr, t_br, t_bl]), _shade(fill_color, 0.12))
		var outline := PackedVector2Array([t_tl, t_tr, t_br, t_bl, t_tl])
		draw_polyline(outline, _shade(outline_color, -0.25), outline_width)
		_draw_details(t_tl, t_tr, t_br, t_bl, height)
	if show_health and max_hp > 0.0:
		var bar_width := size.x
		var bar_pos := Vector2(-bar_width / 2.0, -size.y / 2.0 - health_bar_offset - height)
		var bar_rect := Rect2(bar_pos, Vector2(bar_width, health_bar_height))
		draw_rect(bar_rect, Color(0.2, 0.2, 0.2, 0.8), true)
		var pct := clampf(hp / max_hp, 0.0, 1.0)
		var fill_rect := Rect2(bar_pos, Vector2(bar_width * pct, health_bar_height))
		draw_rect(fill_rect, Color(0.2, 0.85, 0.25, 0.9), true)

func _shade(src: Color, amount: float) -> Color:
	return Color(
		clampf(src.r + amount, 0.0, 1.0),
		clampf(src.g + amount, 0.0, 1.0),
		clampf(src.b + amount, 0.0, 1.0),
		src.a
	)

func _draw_details(t_tl: Vector2, t_tr: Vector2, t_br: Vector2, t_bl: Vector2, height: float) -> void:
	var accent := _shade(fill_color, 0.24)
	var top_center := (t_tl + t_br) * 0.5
	var pad_size := size * 0.32
	var pad_rect := Rect2(top_center - pad_size * 0.5, pad_size)
	draw_rect(pad_rect, accent, true)
	var ring_radius := minf(size.x, size.y) * 0.12
	draw_circle(top_center, ring_radius, _shade(fill_color, 0.32))
	var mast_top := top_center + Vector2(0.0, -height * 1.6)
	draw_line(top_center, mast_top, accent, 2.0)
	draw_circle(mast_top, height * 0.3, accent)

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("HQ: missing visual scene at %s" % visual_scene_path)
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
		push_warning("HQ: visual scene is not a PackedScene at %s" % visual_scene_path)

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	_visual_node.position = visual_offset
	if visual_base_size != Vector2.ZERO:
		var scale_x := size.x / visual_base_size.x
		var scale_y := size.y / visual_base_size.y
		_visual_node.scale = Vector2(scale_x, scale_y)

func _update_visual_color() -> void:
	if _visual_node == null:
		return
	_visual_node.modulate = fill_color

func set_render_2d(value: bool) -> void:
	render_2d = value
	_set_canvas_children_visible(value)
	queue_redraw()

func _set_canvas_children_visible(value: bool) -> void:
	for child in get_children():
		if child is CanvasItem:
			child.visible = value
