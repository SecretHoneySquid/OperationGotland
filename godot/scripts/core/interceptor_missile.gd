class_name InterceptorMissile
extends Node2D

## Interceptor Missile
##
## A specialized missile fired by Patriot systems to intercept incoming enemy missiles.
## Has a success chance roll when it reaches its target.
## Uses ATACMS visual model with heavy smoke trail.

signal intercept_result(success: bool, missile_pos: Vector2, interceptor_pos: Vector2)

@export var speed := 800.0
@export var turn_rate := 8.0  # Base turn rate (radians/sec) - slow enough to see the curve
@export var lifetime := 6.0
@export var hit_radius := 15.0
@export var launch_sideways_angle := 1.6  # How far sideways to launch (radians, ~90 degrees)
@export var launch_phase_duration := 1.0  # How long before full guidance kicks in
@export var lead_factor := 0.6  # How much to lead the target
@export var self_destruct_time := 4.5  # Explode in air after this many seconds
@export var success_chance := 0.85
@export var color := Color(0.9, 1.0, 0.9, 1.0)
@export var trail_color := Color(0.9, 0.9, 0.85, 0.8)
@export var trail_length := 24.0
@export var team_id := ""
@export var visual_scene_path := "res://scenes/missiles/atacms_visual.tscn"
@export var visual_base_radius := 0.8
@export var render_2d := true
@export var interceptable := false  # Interceptors cannot be intercepted
@export var source_kind := "interceptor"  # For 3D visual sync identification
@export var warhead_size := "medium"  # For 3D visual scaling

# Smoke trail settings - heavy smoke for interceptor missiles
@export var smoke_enabled := true
@export var smoke_interval := 0.008  # Spawn smoke very frequently for thick trail
@export var smoke_lifetime := 2.5  # Longer lasting smoke
@export var smoke_start_size := 6.0  # Bigger initial smoke
@export var smoke_end_size := 28.0  # Much bigger final smoke
@export var smoke_color := Color(0.75, 0.75, 0.7, 0.95)  # Denser smoke

var target_missile: Missile
var _velocity := Vector2.RIGHT
var _origin := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _visual_node: Node
var _smoke_timer := 0.0
var _smoke_particles: Array[Dictionary] = []
var _flight_time := 0.0  # Time since launch
var _launch_direction := 1  # 1 = right, -1 = left (randomly chosen)
var _to_target_direction := Vector2.RIGHT  # Direction toward target at launch

func _ready() -> void:
	add_to_group("interceptor_missiles")
	add_to_group("missiles")  # Add to missiles group for 3D visual sync
	_rng.randomize()
	if _origin == Vector2.ZERO:
		_origin = global_position

	# Randomly choose left or right launch direction
	_launch_direction = 1 if _rng.randf() > 0.5 else -1

	if target_missile != null and is_instance_valid(target_missile):
		# Store the direction toward target
		_to_target_direction = (target_missile.global_position - global_position).normalized()
		# Launch sideways (perpendicular + angle) - creates the "?" shape
		_velocity = _to_target_direction.rotated(launch_sideways_angle * _launch_direction)

	_setup_visual()
	print("[INTERCEPTOR] Created at ", global_position, " launching ", ("RIGHT" if _launch_direction > 0 else "LEFT"))

func _process(delta: float) -> void:
	lifetime -= delta
	_flight_time += delta

	# Self-destruct after flying too long - explode in air
	if _flight_time >= self_destruct_time:
		_self_destruct()
		return

	if lifetime <= 0.0:
		# Timed out - intercept failed (silent removal)
		emit_signal("intercept_result", false, global_position, global_position)
		queue_free()
		return

	# Check if target is still valid
	if target_missile == null or not is_instance_valid(target_missile):
		# Target destroyed or lost - self destruct
		_self_destruct()
		return

	# Check if target is still interceptable
	if not target_missile.is_interceptable():
		# Target no longer interceptable - self destruct
		_self_destruct()
		return

	# Guide toward target - upside down "?" trajectory
	_update_guidance_questionmark(delta)

	# Move
	global_position += _velocity.normalized() * speed * delta

	# Update smoke trail
	_update_smoke(delta)

	# Update visual rotation
	_update_visual_rotation()

	# Check for intercept
	_check_intercept()

	queue_redraw()

func _update_guidance_questionmark(delta: float) -> void:
	# Creates an upside-down "?" trajectory:
	# 1. Launch phase: fly sideways (left or right randomly)
	# 2. Turn phase: curve around toward the target
	# 3. Intercept phase: home in on target

	if target_missile == null or not is_instance_valid(target_missile):
		return

	var target_pos := target_missile.global_position
	var to_target := (target_pos - global_position).normalized()

	# Calculate current turn rate based on flight phase
	var current_turn_rate := turn_rate

	if _flight_time < launch_phase_duration:
		# Phase 1: Launch phase - maintain sideways direction, start curving
		# Gradually increase turn rate as we exit launch phase
		var phase_progress := _flight_time / launch_phase_duration
		# Start turning slowly, ramp up
		current_turn_rate = turn_rate * (0.3 + phase_progress * 0.7)
	else:
		# Phase 2+: Full guidance toward target
		# Increase turn rate when closer for terminal guidance
		var dist := global_position.distance_to(target_pos)
		var proximity_boost := clampf(1.5 - dist / 600.0, 1.0, 1.8)
		current_turn_rate = turn_rate * proximity_boost

	# Always try to turn toward target (with lead prediction)
	var dist_to_target := global_position.distance_to(target_pos)
	var time_to_intercept := dist_to_target / speed

	# Simple lead prediction - aim ahead of moving target
	var target_vel := Vector2.ZERO
	if target_missile.has_method("get") and target_missile.get("_velocity") != null:
		target_vel = target_missile.get("_velocity")
	var lead_pos := target_pos + (target_vel * time_to_intercept * lead_factor)

	var desired_dir := (lead_pos - global_position).normalized()
	var angle := _velocity.angle_to(desired_dir)
	var max_turn := current_turn_rate * delta

	_velocity = _velocity.rotated(clampf(angle, -max_turn, max_turn))

func _check_intercept() -> void:
	if target_missile == null or not is_instance_valid(target_missile):
		return

	var dist := global_position.distance_to(target_missile.global_position)
	if dist <= hit_radius:
		# Reached target - roll for intercept success
		var roll := _rng.randf()
		var success := roll < success_chance

		var missile_pos := target_missile.global_position

		if success:
			# Successfully intercepted!
			target_missile.intercept()
			print("[PATRIOT] Missile intercepted at ", missile_pos)
		else:
			print("[PATRIOT] Intercept FAILED at ", missile_pos)

		emit_signal("intercept_result", success, missile_pos, global_position)
		queue_free()

func _self_destruct() -> void:
	# Explode in the air - creates a visual explosion
	# Emit a fake "intercepted" signal to trigger the explosion effect in visual_sync_3d
	# We use the Missile class's impact signal pattern
	print("[INTERCEPTOR] Self-destruct at ", global_position)

	# Find visual_sync_3d and trigger explosion effect directly
	var visual_syncs := get_tree().get_nodes_in_group("visual_sync_3d")
	for sync in visual_syncs:
		if sync.has_method("_on_missile_impact"):
			# Trigger a smaller explosion for self-destruct (not a full intercept explosion)
			sync.call("_on_missile_impact", global_position, Color(1.0, 0.6, 0.2, 1.0), "small", "self_destruct")

	emit_signal("intercept_result", false, global_position, global_position)
	queue_free()

func set_origin(pos: Vector2) -> void:
	_origin = pos

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("InterceptorMissile: missing visual scene at %s" % visual_scene_path)
		return
	if packed is PackedScene:
		var instance = packed.instantiate()
		if instance is Node2D or instance is Node3D:
			_visual_node = instance
			add_child(_visual_node)
			_visual_node.visible = true
			_update_visual_transform()

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	if visual_base_radius > 0.0:
		var scale_val := 1.0 / visual_base_radius
		if _visual_node is Node3D:
			_visual_node.scale = Vector3.ONE * scale_val
		else:
			_visual_node.scale = Vector2.ONE * scale_val

func _update_visual_rotation() -> void:
	if _visual_node == null:
		return
	if _visual_node is Node3D:
		# Tilt missile upward as it flies (interceptors go up to meet targets)
		var pitch := PI * 0.15  # 15 degree upward pitch
		_visual_node.rotation = Vector3(pitch, -_velocity.angle() + PI/2, 0)
	else:
		_visual_node.rotation = _velocity.angle()

func _update_smoke(delta: float) -> void:
	if not smoke_enabled:
		return

	# Spawn new smoke particles
	_smoke_timer += delta
	while _smoke_timer >= smoke_interval:
		_smoke_timer -= smoke_interval
		_spawn_smoke_particle()

	# Update existing smoke particles
	var i := 0
	while i < _smoke_particles.size():
		var particle: Dictionary = _smoke_particles[i]
		particle["age"] += delta
		if particle["age"] >= smoke_lifetime:
			_smoke_particles.remove_at(i)
		else:
			i += 1

func _spawn_smoke_particle() -> void:
	# Add random offset for thick, billowing smoke trail
	var offset := Vector2(_rng.randf_range(-5.0, 5.0), _rng.randf_range(-5.0, 5.0))
	var smoke_pos := global_position - _velocity.normalized() * 10.0 + offset
	_smoke_particles.append({
		"pos": smoke_pos,
		"age": 0.0,
		"offset_x": _rng.randf_range(-4.0, 4.0),
		"offset_y": _rng.randf_range(-4.0, 4.0),
		"size_mult": _rng.randf_range(0.8, 1.3),  # Random size variation
	})

func _draw() -> void:
	if not render_2d:
		return

	# Draw smoke trail first (behind missile)
	for particle in _smoke_particles:
		var local_pos: Vector2 = particle["pos"] - global_position
		var age: float = particle["age"]
		var t := clampf(age / smoke_lifetime, 0.0, 1.0)

		# Size grows over time with random variation
		var size_mult: float = particle.get("size_mult", 1.0)
		var size := lerpf(smoke_start_size, smoke_end_size, t) * size_mult

		# Alpha fades over time - slower fade for thicker smoke
		var alpha := smoke_color.a * (1.0 - t * t * 0.8)  # Slower quadratic fade

		# Color shifts to gray as it ages
		var col := Color(
			lerpf(smoke_color.r, 0.55, t * 0.6),
			lerpf(smoke_color.g, 0.55, t * 0.6),
			lerpf(smoke_color.b, 0.52, t * 0.6),
			alpha
		)

		# Add drift - more dramatic spreading
		local_pos.x += particle["offset_x"] * t * 15.0
		local_pos.y += particle["offset_y"] * t * 15.0 - t * 12.0  # Upward drift

		draw_circle(local_pos, size, col)

	# Draw missile body
	var radius := 4.0
	draw_circle(Vector2.ZERO, radius, color)

	# Draw bright exhaust/flame
	var flame_color := Color(1.0, 0.8, 0.3, 1.0)
	var flame_pos := -_velocity.normalized() * 6.0
	draw_circle(flame_pos, 3.5, flame_color)
	draw_circle(flame_pos - _velocity.normalized() * 3.0, 2.5, Color(1.0, 0.5, 0.1, 0.9))

	# Draw trail line
	var trail := maxf(12.0, trail_length)
	draw_line(flame_pos, flame_pos - _velocity.normalized() * trail, trail_color, 3.0)

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()
