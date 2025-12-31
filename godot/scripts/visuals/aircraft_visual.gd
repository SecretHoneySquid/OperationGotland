@tool
extends Node2D

const Helpers = preload("res://scripts/visuals/low_poly_helpers.gd")

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	_clear_children()
	var fuselage := PackedVector2Array([
		Vector2(20, 0),
		Vector2(8, -4),
		Vector2(-8, -4),
		Vector2(-14, 0),
		Vector2(-8, 4),
		Vector2(8, 4),
	])
	Helpers.add_mesh(self, fuselage, Color(0.7, 0.72, 0.75, 1.0))
	var wing := PackedVector2Array([
		Vector2(-4, -16),
		Vector2(4, -16),
		Vector2(12, -6),
		Vector2(12, 6),
		Vector2(4, 16),
		Vector2(-4, 16),
		Vector2(-12, 6),
		Vector2(-12, -6),
	])
	Helpers.add_mesh(self, wing, Color(0.6, 0.62, 0.68, 1.0))
	var tail := PackedVector2Array([
		Vector2(-10, -8),
		Vector2(-4, -8),
		Vector2(0, -2),
		Vector2(0, 2),
		Vector2(-4, 8),
		Vector2(-10, 8),
	])
	Helpers.add_mesh(self, tail, Color(0.62, 0.64, 0.7, 1.0))
	var nose := PackedVector2Array([
		Vector2(20, 0),
		Vector2(14, -3),
		Vector2(14, 3),
	])
	Helpers.add_mesh(self, nose, Color(0.85, 0.85, 0.86, 1.0))
	var outline := Helpers.make_outline(fuselage, Color(0.1, 0.1, 0.1, 0.85), 1.6)
	add_child(outline)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
