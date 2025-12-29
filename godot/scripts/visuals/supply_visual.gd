@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var b_tl := Vector2(-50, -40)
	var b_tr := Vector2(50, -40)
	var b_br := Vector2(50, 40)
	var b_bl := Vector2(-50, 40)
	var top_offset := Vector2(-8, -12)
	var t_tl := b_tl + top_offset
	var t_tr := b_tr + top_offset
	var t_br := b_br + top_offset
	var t_bl := b_bl + top_offset
	Helpers.add_mesh(self, PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.78, 0.78, 0.78, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_tr, b_br, t_br, t_tr]), Color(0.55, 0.55, 0.55, 1.0))
	Helpers.add_mesh(self, PackedVector2Array([b_bl, b_br, t_br, t_bl]), Color(0.42, 0.42, 0.42, 1.0))
	var tank := PackedVector2Array([
		Vector2(12, -6),
		Vector2(8, -12),
		Vector2(0, -14),
		Vector2(-8, -12),
		Vector2(-12, -6),
		Vector2(-12, 2),
		Vector2(0, 4),
		Vector2(12, 2),
	])
	Helpers.add_mesh(self, tank, Color(0.9, 0.9, 0.9, 1.0))
	var pipe := Line2D.new()
	pipe.width = 2.0
	pipe.default_color = Color(0.25, 0.25, 0.25, 1.0)
	pipe.points = PackedVector2Array([Vector2(-20, 6), Vector2(-34, 14), Vector2(-42, 12)])
	add_child(pipe)
	var outline := Helpers.make_outline(PackedVector2Array([t_tl, t_tr, t_br, t_bl]), Color(0.1, 0.1, 0.1, 0.85), 2.0)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
