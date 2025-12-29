class_name BaseVision
extends Node2D

@export var vision_radius := 400.0
@export var light_energy := 2.2
@export var light_color := Color(1.0, 1.0, 1.0, 1.0)

var _light: PointLight2D

func _ready() -> void:
	if vision_radius <= 0.0:
		return
	add_to_group("vision_p1")
	_light = VisionHelper.create_light(vision_radius)
	_light.energy = light_energy
	_light.color = light_color
	add_child(_light)

func get_vision_radius() -> float:
	return vision_radius
