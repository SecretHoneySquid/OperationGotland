@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var b_tl := Vector2(-70, -55)
	var b_tr := Vector2(70, -55)
	var b_br := Vector2(70, 55)
	var b_bl := Vector2(-70, 55)
	var top_offset := Vector2(-12, -16)
	var t_tl := b_tl + top_offset
	var t_tr := b_tr + top_offset
	var t_br := b_br + top_offset
	var t_bl := b_bl + top_offset
	Helpers.add_mesh(self, PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.76, 0.76, 0.76, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_tr, b_br, t_br, t_tr]), Color(0.52, 0.52, 0.52, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_bl, b_br, t_br, t_bl]), Color(0.4, 0.4, 0.4, 1.0))
	var door := PackedVector2Array([
		Vector2(-22, 15),
		Vector2(22, 15),
		Vector2(22, 42),
		Vector2(-22, 42),
	])
	Helpers.add_mesh(self, door, Color(0.18, 0.18, 0.18, 1.0))
	var vent := PackedVector2Array([
		Vector2(18, -50),
		Vector2(42, -50),
		Vector2(42, -36),
		Vector2(18, -36),
	])
	Helpers.add_mesh(self, vent, Color(0.88, 0.88, 0.88, 1.0))
	var stack := PackedVector2Array([
		Vector2(-58, -54),
		Vector2(-40, -54),
		Vector2(-40, -28),
		Vector2(-58, -28),
	])
	Helpers.add_mesh(self, stack, Color(0.6, 0.6, 0.6, 1.0))
	var outline := Helpers.make_outline(PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.1, 0.1, 0.1, 0.85), 2.0)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
