@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var hull := PackedVector2Array([
		Vector2(14, 0),
		Vector2(9, -7),
		Vector2(-9, -7),
		Vector2(-14, 0),
		Vector2(-9, 7),
		Vector2(9, 7),
	])
	var cap := PackedVector2Array([
		Vector2(6, 0),
		Vector2(4, -3),
		Vector2(-4, -3),
		Vector2(-6, 0),
		Vector2(-4, 3),
		Vector2(4, 3),
	])
	var turret := PackedVector2Array([
		Vector2(3.5, 0),
		Vector2(2.5, -2.5),
		Vector2(0, -3.5),
		Vector2(-2.5, -2.5),
		Vector2(-3.5, 0),
		Vector2(-2.5, 2.5),
		Vector2(0, 3.5),
		Vector2(2.5, 2.5),
	])
	var track_top := PackedVector2Array([
		Vector2(-11, -9),
		Vector2(11, -9),
		Vector2(10, -7),
		Vector2(-10, -7),
	])
	var track_bottom := PackedVector2Array([
		Vector2(-10, 7),
		Vector2(10, 7),
		Vector2(11, 9),
		Vector2(-11, 9),
	])
	var extrude := Vector2(5.5, 8.0)
	var base := Helpers.offset_points(hull, extrude)
	Helpers.add_mesh(self, base, Color(0.25, 0.25, 0.25, 1.0))
	Helpers.add_quad(self, hull[4], hull[5], base[5], base[4], Color(0.42, 0.42, 0.42, 1.0))
	Helpers.add_quad(self, hull[5], hull[0], base[0], base[5], Color(0.36, 0.36, 0.36, 1.0))
	Helpers.add_mesh(self, hull, Color(0.6, 0.6, 0.6, 1.0))
	Helpers.add_mesh(self, track_top, Color(0.25, 0.25, 0.25, 1.0))
	Helpers.add_mesh(self, track_bottom, Color(0.25, 0.25, 0.25, 1.0))
	Helpers.add_mesh(self, cap, Color(0.78, 0.78, 0.78, 1.0))
	Helpers.add_mesh(self, turret, Color(0.88, 0.88, 0.88, 1.0))
	var barrel := Line2D.new()
	barrel.width = 2.6
	barrel.default_color = Color(0.9, 0.9, 0.9, 1.0)
	barrel.points = PackedVector2Array([Vector2(0, 0), Vector2(18, 0)])
	add_child(barrel)
	var outline := Helpers.make_outline(hull, Color(0.1, 0.1, 0.1, 0.9), 1.6)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
