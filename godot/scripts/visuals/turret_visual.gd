@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var base := PackedVector2Array([
		Vector2(16, 0),
		Vector2(11, -11),
		Vector2(0, -16),
		Vector2(-11, -11),
		Vector2(-16, 0),
		Vector2(-11, 11),
		Vector2(0, 16),
		Vector2(11, 11),
	])
	var top := PackedVector2Array([
		Vector2(10, 0),
		Vector2(7, -7),
		Vector2(0, -10),
		Vector2(-7, -7),
		Vector2(-10, 0),
		Vector2(-7, 7),
		Vector2(0, 10),
		Vector2(7, 7),
	])
	var core := PackedVector2Array([
		Vector2(5, 0),
		Vector2(3.5, -3.5),
		Vector2(0, -5),
		Vector2(-3.5, -3.5),
		Vector2(-5, 0),
		Vector2(-3.5, 3.5),
		Vector2(0, 5),
		Vector2(3.5, 3.5),
	])
	var extrude := Vector2(5.0, 7.0)
	var base_shadow := Helpers.offset_points(base, extrude)
	Helpers.add_mesh(self, base_shadow, Color(0.26, 0.26, 0.26, 1.0))
	Helpers.add_quad(self, base[6], base[7], base_shadow[7], base_shadow[6], Color(0.42, 0.42, 0.42, 1.0))
	Helpers.add_quad(self, base[7], base[0], base_shadow[0], base_shadow[7], Color(0.36, 0.36, 0.36, 1.0))
	Helpers.add_mesh(self, base, Color(0.62, 0.62, 0.62, 1.0))
	Helpers.add_mesh(self, top, Color(0.78, 0.78, 0.78, 1.0))
	Helpers.add_mesh(self, core, Color(0.9, 0.9, 0.9, 1.0))
	var barrel := Line2D.new()
	barrel.width = 3.0
	barrel.default_color = Color(0.92, 0.92, 0.92, 1.0)
	barrel.points = PackedVector2Array([Vector2(0, 0), Vector2(20, 0)])
	add_child(barrel)
	var outline := Helpers.make_outline(base, Color(0.1, 0.1, 0.1, 0.9), 1.6)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
