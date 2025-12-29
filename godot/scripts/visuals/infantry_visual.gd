@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var hull := PackedVector2Array([
		Vector2(8, 0),
		Vector2(4, -6),
		Vector2(-6, -4),
		Vector2(-8, 0),
		Vector2(-6, 4),
		Vector2(4, 6),
	])
	var cap := PackedVector2Array([
		Vector2(4, 0),
		Vector2(2, -3),
		Vector2(-3, -2),
		Vector2(-4, 0),
		Vector2(-3, 2),
		Vector2(2, 3),
	])
	var pack := PackedVector2Array([
		Vector2(-1, -3),
		Vector2(-4, -2),
		Vector2(-5, 0),
		Vector2(-4, 2),
		Vector2(-1, 3),
	])
	var extrude := Vector2(3.5, 6.0)
	var base := Helpers.offset_points(hull, extrude)
	Helpers.add_mesh(self, base, Color(0.28, 0.28, 0.28, 1.0))
	Helpers.add_quad(self, hull[4], hull[5], base[5], base[4], Color(0.42, 0.42, 0.42, 1.0))
	Helpers.add_quad(self, hull[5], hull[0], base[0], base[5], Color(0.36, 0.36, 0.36, 1.0))
	Helpers.add_mesh(self, hull, Color(0.65, 0.65, 0.65, 1.0))
	Helpers.add_mesh(self, cap, Color(0.82, 0.82, 0.82, 1.0))
	Helpers.add_mesh(self, pack, Color(0.32, 0.32, 0.32, 1.0))
	var gun := Line2D.new()
	gun.width = 2.0
	gun.default_color = Color(0.9, 0.9, 0.9, 1.0)
	gun.points = PackedVector2Array([Vector2(0, 0), Vector2(13, 0)])
	add_child(gun)
	var outline := Helpers.make_outline(hull, Color(0.12, 0.12, 0.12, 0.9), 1.4)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
