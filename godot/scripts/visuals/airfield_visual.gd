@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var base := PackedVector2Array([
		Vector2(-90, -60),
		Vector2(90, -60),
		Vector2(90, 60),
		Vector2(-90, 60),
	])
	Helpers.add_mesh(self, base, Color(0.25, 0.25, 0.28, 1.0))
	var runway := PackedVector2Array([
		Vector2(-80, 4),
		Vector2(80, 4),
		Vector2(80, 20),
		Vector2(-80, 20),
	])
	Helpers.add_mesh(self, runway, Color(0.14, 0.14, 0.16, 1.0))
	for i in range(4):
		var x := -40 + (i * 26)
		var stripe := PackedVector2Array([
			Vector2(x, 10),
			Vector2(x + 12, 10),
			Vector2(x + 12, 14),
			Vector2(x, 14),
		])
		Helpers.add_mesh(self, stripe, Color(0.9, 0.9, 0.9, 0.9))
	var hangar := PackedVector2Array([
		Vector2(-82, -52),
		Vector2(-12, -52),
		Vector2(-12, -12),
		Vector2(-82, -12),
	])
	Helpers.add_mesh(self, hangar, Color(0.6, 0.62, 0.68, 1.0))
	var hangar_roof := PackedVector2Array([
		Vector2(-82, -56),
		Vector2(-12, -56),
		Vector2(-12, -52),
		Vector2(-82, -52),
	])
	Helpers.add_mesh(self, hangar_roof, Color(0.72, 0.74, 0.78, 1.0))
	var tower := PackedVector2Array([
		Vector2(46, -52),
		Vector2(66, -52),
		Vector2(66, -16),
		Vector2(46, -16),
	])
	Helpers.add_mesh(self, tower, Color(0.55, 0.58, 0.65, 1.0))
	var tower_cabin := PackedVector2Array([
		Vector2(40, -60),
		Vector2(72, -60),
		Vector2(72, -52),
		Vector2(40, -52),
	])
	Helpers.add_mesh(self, tower_cabin, Color(0.75, 0.78, 0.82, 1.0))
	var outline := Helpers.make_outline(base, Color(0.1, 0.1, 0.1, 0.85), 2.0)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
