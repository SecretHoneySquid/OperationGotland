extends Node

@export var camera_path := NodePath("../World3D/CameraRig/Camera3D")
@export var ground_height := 0.0

var _last_valid := Vector2.ZERO

func _ready() -> void:
	add_to_group("world_input")

func screen_to_world(screen_pos: Vector2) -> Vector2:
	var camera := get_node_or_null(camera_path) as Camera3D
	if camera == null:
		return _last_valid
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, ground_height)
	var hit = plane.intersects_ray(origin, dir)
	if hit == null:
		return _last_valid
	var pos := Vector2(hit.x, hit.z)
	_last_valid = pos
	return pos
