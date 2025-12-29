class_name ShotTracer
extends Node2D

@export var duration := 0.12
@export var width := 2.0
@export var color := Color(1.0, 1.0, 1.0, 0.7)

var _time := 0.0
var _end := Vector2.ZERO

func set_points(start: Vector2, end: Vector2) -> void:
	global_position = start
	_end = end - start
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if duration <= 0.0:
		return
	var t := clampf(1.0 - (_time / duration), 0.0, 1.0)
	var draw_color := color
	draw_color.a = color.a * t
	draw_line(Vector2.ZERO, _end, draw_color, width)
