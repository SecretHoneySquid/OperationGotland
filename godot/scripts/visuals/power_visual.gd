@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var b_tl := Vector2(-40, -40)
	var b_tr := Vector2(40, -40)
	var b_br := Vector2(40, 40)
	var b_bl := Vector2(-40, 40)
	var top_offset := Vector2(-6, -10)
	var t_tl := b_tl + top_offset
	var t_tr := b_tr + top_offset
	var t_br := b_br + top_offset
	var t_bl := b_bl + top_offset
	Helpers.add_mesh(self, PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.8, 0.8, 0.8, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_tr, b_br, t_br, t_tr]), Color(0.55, 0.55, 0.55, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_bl, b_br, t_br, t_bl]), Color(0.42, 0.42, 0.42, 1.0))
	var tower_left := PackedVector2Array([
		Vector2(-26, -28),
		Vector2(-14, -28),
		Vector2(-14, 6),
		Vector2(-26, 6),
	])
	var tower_right := PackedVector2Array([
		Vector2(14, -28),
		Vector2(26, -28),
		Vector2(26, 6),
		Vector2(14, 6),
	])
	Helpers.add_mesh(self, tower_left, Color(0.88, 0.88, 0.88, 1.0))
	Helpers.add_mesh(self, tower_right, Color(0.88, 0.88, 0.88, 1.0))
	var bolt := Line2D.new()
	bolt.width = 2.2
	bolt.default_color = Color(0.95, 0.95, 0.95, 1.0)
	bolt.points = PackedVector2Array([
		Vector2(-4, -8),
		Vector2(4, -2),
		Vector2(-2, 6),
		Vector2(6, 12),
	])
	add_child(bolt)
	var outline := Helpers.make_outline(PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.1, 0.1, 0.1, 0.85), 2.0)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
