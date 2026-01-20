extends Node

@export var camera_path := NodePath("../World3D/CameraRig/Camera3D")
@export var ground_height := 0.0
@export var terrain_path := NodePath("../Terrain3D")
@export var use_terrain_raycast := false
@export var raycast_distance := 10000.0

var _last_valid := Vector2.ZERO
var _camera: Camera3D = null

func _ready() -> void:
	add_to_group("world_input")
	# Try to find camera using multiple methods
	_camera = get_node_or_null(camera_path)
	if _camera == null:
		print("[WorldInput] Camera not found at exported path: ", camera_path)
		# Try alternative paths
		_camera = get_node_or_null("../World3D/CameraRig/Camera3D")
		if _camera == null:
			_camera = get_node_or_null("/root/Main/World3D/CameraRig/Camera3D")
		if _camera == null:
			# Try finding it through the scene tree
			var main = get_parent()
			if main:
				var world3d = main.get_node_or_null("World3D")
				if world3d:
					var camera_rig = world3d.get_node_or_null("CameraRig")
					if camera_rig:
						_camera = camera_rig.get_node_or_null("Camera3D")
	
	if _camera != null:
		print("[WorldInput] Camera found successfully at: ", _camera.get_path())
	else:
		print("[WorldInput] ERROR: Could not find Camera3D anywhere!")

func screen_to_world(screen_pos: Vector2) -> Vector2:
	if _camera == null:
		print("[WorldInput] ERROR: Camera is null")
		return _last_valid

	var origin := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)

	# Try raycasting to terrain first if enabled
	if use_terrain_raycast:
		var terrain := get_node_or_null(terrain_path)
		if terrain != null and terrain.has_method("get_height"):
			var temp_plane := Plane(Vector3.UP, 1000.0)
			var temp_hit = temp_plane.intersects_ray(origin, dir)
			if temp_hit != null:
				var world_pos := Vector3(temp_hit.x, 0, temp_hit.z)
				var height = terrain.get_height(world_pos)
				if not is_nan(height):
					var pos := Vector2(temp_hit.x, temp_hit.z)
					_last_valid = pos
					return pos

	# Use flat plane (default behavior)
	var plane := Plane(Vector3.UP, ground_height)
	var hit = plane.intersects_ray(origin, dir)
	if hit == null:
		return _last_valid
	var pos := Vector2(hit.x, hit.z)
	_last_valid = pos
	return pos


func world_to_screen(world_pos: Vector2) -> Vector2:
	if _camera == null:
		return Vector2.ZERO
	# Convert 2D world position (x, z) to 3D position on ground plane
	var world_3d := Vector3(world_pos.x, ground_height, world_pos.y)
	# Project to screen
	if not _camera.is_position_behind(world_3d):
		return _camera.unproject_position(world_3d)
	return Vector2(-1000, -1000)  # Off screen
