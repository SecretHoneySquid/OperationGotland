@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var b_tl := Vector2(-65, -55)
	var b_tr := Vector2(65, -55)
	var b_br := Vector2(65, 55)
	var b_bl := Vector2(-65, 55)
	var top_offset := Vector2(-10, -16)
	var t_tl := b_tl + top_offset
	var t_tr := b_tr + top_offset
	var t_br := b_br + top_offset
	var t_bl := b_bl + top_offset
	Helpers.add_mesh(self, PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.8, 0.8, 0.8, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_tr, b_br, t_br, t_tr]), Color(0.56, 0.56, 0.56, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_bl, b_br, t_br, t_bl]), Color(0.42, 0.42, 0.42, 1.0))
	var pad := PackedVector2Array([
		Vector2(18, -8),
		Vector2(12, -14),
		Vector2(0, -16),
		Vector2(-12, -14),
		Vector2(-18, -8),
		Vector2(-18, 2),
		Vector2(0, 6),
		Vector2(18, 2),
	])
	Helpers.add_mesh(self, pad, Color(0.9, 0.9, 0.9, 1.0))
	var mast := Line2D.new()
	mast.width = 2.0
	mast.default_color = Color(0.9, 0.9, 0.9, 1.0)
	mast.points = PackedVector2Array([Vector2(0, -12), Vector2(0, -34)])
	add_child(mast)
	var dish := PackedVector2Array([
		Vector2(6, -34),
		Vector2(2, -38),
		Vector2(-4, -38),
		Vector2(-6, -34),
		Vector2(-4, -30),
		Vector2(2, -30),
	])
	Helpers.add_mesh(self, dish, Color(0.95, 0.95, 0.95, 1.0))
	var outline := Helpers.make_outline(PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.1, 0.1, 0.1, 0.85), 2.0)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
