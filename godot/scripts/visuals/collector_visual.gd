@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var body := PackedVector2Array([
		Vector2(10, 0),
		Vector2(5, -5),
		Vector2(-8, -5),
		Vector2(-10, 0),
		Vector2(-8, 5),
		Vector2(5, 5),
	])
	var cap := PackedVector2Array([
		Vector2(6, 0),
		Vector2(3, -3),
		Vector2(-5, -3),
		Vector2(-6, 0),
		Vector2(-5, 3),
		Vector2(3, 3),
	])
	var cargo := PackedVector2Array([
		Vector2(-1, -2),
		Vector2(-4, -1),
		Vector2(-6, 0),
		Vector2(-5, 2),
		Vector2(-2, 3),
		Vector2(-1, 1),
	])
	var extrude := Vector2(4.0, 6.5)
	var base := Helpers.offset_points(body, extrude)
	Helpers.add_mesh(self, base, Color(0.26, 0.26, 0.26, 1.0))
	Helpers.add_quad(self, body[4], body[5], base[5], base[4], Color(0.4, 0.4, 0.4, 1.0))
	Helpers.add_quad(self, body[5], body[0], base[0], base[5], Color(0.34, 0.34, 0.34, 1.0))
	Helpers.add_mesh(self, body, Color(0.62, 0.62, 0.62, 1.0))
	Helpers.add_mesh(self, cap, Color(0.8, 0.8, 0.8, 1.0))
	Helpers.add_mesh(self, cargo, Color(0.9, 0.9, 0.9, 1.0))
	var cab := Line2D.new()
	cab.width = 2.0
	cab.default_color = Color(0.9, 0.9, 0.9, 1.0)
	cab.points = PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	add_child(cab)
	var outline := Helpers.make_outline(body, Color(0.1, 0.1, 0.1, 0.9), 1.4)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
