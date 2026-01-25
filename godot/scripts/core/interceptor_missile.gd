class_name InterceptorMissile
extends Node2D

## Interceptor Missile
##
## A specialized missile fired by Patriot systems to intercept incoming enemy missiles.
## Has a success chance roll when it reaches its target.
## Uses ATACMS visual model with heavy smoke trail.

signal intercept_result(success: bool, missile_pos: Vector2, interceptor_pos: Vector2)

@export var speed := 800.0
@export var seek_speed_mult := 1.1
@export var turn_rate := 8.0  # Base turn rate (radians/sec) - slow enough to see the curve
@export var lifetime := 6.0
@export var hit_radius := 15.0
@export var body_radius := 4.0
@export var launch_sideways_angle := 0.0  # Disabled: interceptor launches straight
@export var launch_phase_duration := 0.4  # Minimum straight-climb time before seeking
@export var lead_factor := 1.0  # 0 = chase, 1 = full intercept lead
@export var cruise_height := 120.0  # Height to reach before seeker engages
@export var hard_turn_angle := deg_to_rad(120.0)  # Self-destruct if turning harder than this
@export var launch_heading_spread := deg_to_rad(3.0)  # Random initial heading offset
@export var climb_duration := 0.9
@export var climb_curve_x_min := 0.2
@export var climb_curve_x_max := 1.0
@export var climb_curve_y_offset := 5.0
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
var target_aircraft: Unit  # Alternative target for anti-aircraft mode
var _velocity := Vector2.RIGHT
var _origin := Vector2.ZERO
var _last_known_target_pos := Vector2.ZERO  # Used when target is destroyed by another interceptor
var _flying_to_last_pos := false  # True when target lost, flying to last known position
var _rng := RandomNumberGenerator.new()
static var _spawn_rng := RandomNumberGenerator.new()
static var _spawn_rng_ready := false
var _visual_node: Node
var _smoke_timer := 0.0
var _smoke_particles: Array[Dictionary] = []
var _flight_time := 0.0  # Time since launch
var _to_target_direction := Vector2.RIGHT  # Direction toward target at launch
var _flight_height := 0.0  # Current height above ground for 3D visual
var _start_height := 9.0  # Starting height (turret height)

func _ready() -> void:
	add_to_group("interceptor_missiles")
	add_to_group("missiles")  # Add to missiles group for 3D visual sync
	var fuel_time := GameBalance.MISSILE_FUEL_TIME
	if fuel_time > 0.0:
		if lifetime <= 0.0 or lifetime > fuel_time:
			lifetime = fuel_time
		if self_destruct_time <= 0.0 or self_destruct_time > fuel_time:
			self_destruct_time = fuel_time
	if not _spawn_rng_ready:
		_spawn_rng.randomize()
		_spawn_rng_ready = true
	_rng.seed = _spawn_rng.randi()
	if _origin == Vector2.ZERO:
		_origin = global_position

	# Initialize flight height at turret height
	_flight_height = _start_height

	# Get target position from either missile or aircraft
	var target_pos := _get_target_position()
	if target_pos != Vector2.ZERO:
		# Store the direction toward target
		_to_target_direction = (target_pos - global_position).normalized()
		# Launch straight toward the target direction (climb handled separately)
		_velocity = _to_target_direction.rotated(launch_sideways_angle)
		if launch_heading_spread > 0.0:
			var jitter := _rng.randf_range(-launch_heading_spread, launch_heading_spread)
			_velocity = _velocity.rotated(jitter)

	_setup_visual()

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

	# Check if target is still valid (either missile or aircraft)
	if not _has_valid_target():
		# Target destroyed or lost - fly to last known position then explode
		if not _flying_to_last_pos and _last_known_target_pos != Vector2.ZERO:
			_flying_to_last_pos = true
		if _flying_to_last_pos:
			# Check if we reached the last known position
			var dist_to_last := global_position.distance_to(_last_known_target_pos)
			if dist_to_last <= hit_radius:
				_self_destruct()
				return
			# Continue flying toward last known position
			_update_guidance_to_position(delta, _last_known_target_pos)
		else:
			# No last known position, just self destruct
			_self_destruct()
			return
	else:
		# Target still valid - update last known position
		_last_known_target_pos = _get_target_position()

		# Check if missile target is still interceptable
		if target_missile != null and not target_missile.is_interceptable():
			# Target no longer interceptable - fly to last known position then explode
			_flying_to_last_pos = true
		else:
			# Guide toward target - straight climb then seeker
			_update_guidance_climb_seek(delta)

	# Move
	global_position += _velocity.normalized() * _get_current_speed() * delta

	# Update flight height based on the inverse curve y = (-1/x) + 5 (x > 0.2).
	var target_height := maxf(_start_height, cruise_height)
	if _flight_height < target_height:
		var climb_span := maxf(0.1, target_height - _start_height)
		var duration := maxf(0.05, climb_duration)
		var progress := clampf(_flight_time / duration, 0.0, 1.0)
		var x_min := maxf(0.001, climb_curve_x_min)
		var x_max := maxf(x_min + 0.001, climb_curve_x_max)
		var x := lerpf(x_min, x_max, progress)
		var min_val := (-1.0 / x_min) + climb_curve_y_offset
		var max_val := (-1.0 / x_max) + climb_curve_y_offset
		var curve_val := (-1.0 / x) + climb_curve_y_offset
		var span_val := max_val - min_val
		var norm := 0.0
		if absf(span_val) > 0.0001:
			norm = (curve_val - min_val) / span_val
		var target_flight := _start_height + (climb_span * clampf(norm, 0.0, 1.0))
		_flight_height = minf(maxf(_flight_height, target_flight), target_height)

	# Update smoke trail
	_update_smoke(delta)

	# Update visual rotation
	_update_visual_rotation()

	# Check for intercept
	_check_intercept()

	queue_redraw()

func _update_guidance_climb_seek(delta: float) -> void:
	# Straight climb until cruise height, then seek target with limited turn capability.
	if not _has_valid_target():
		return
	var target_height := maxf(_start_height, cruise_height)
	if _flight_height < target_height:
		return
	if launch_phase_duration > 0.0 and _flight_time < launch_phase_duration:
		return

	var target_pos := _get_target_position()
	var target_vel := _get_target_velocity()
	var intercept_dir := _compute_intercept_direction(target_pos, target_vel, _get_current_speed())
	var chase_dir := (target_pos - global_position).normalized()
	var mix := clampf(lead_factor, 0.0, 1.0)
	var desired_dir := chase_dir.lerp(intercept_dir, mix).normalized()
	if desired_dir.length_squared() <= 0.0001:
		desired_dir = chase_dir

	var angle := _velocity.angle_to(desired_dir)
	if absf(angle) > hard_turn_angle:
		_self_destruct()
		return

	var max_turn := turn_rate * delta
	_velocity = _velocity.rotated(clampf(angle, -max_turn, max_turn))

func _update_guidance_to_position(delta: float, target_pos: Vector2) -> void:
	# Guide toward a fixed position (used when target is lost)
	var target_height := maxf(_start_height, cruise_height)
	if _flight_height < target_height:
		return
	if launch_phase_duration > 0.0 and _flight_time < launch_phase_duration:
		return

	var desired_dir := (target_pos - global_position).normalized()
	if desired_dir.length_squared() <= 0.0001:
		return

	var angle := _velocity.angle_to(desired_dir)
	# No hard turn self-destruct when flying to last position - just turn as best we can
	var max_turn := turn_rate * delta
	_velocity = _velocity.rotated(clampf(angle, -max_turn, max_turn))

func _has_valid_target() -> bool:
	if target_missile != null and is_instance_valid(target_missile):
		return true
	if target_aircraft != null and is_instance_valid(target_aircraft):
		return true
	return false

func _get_target_position() -> Vector2:
	if target_missile != null and is_instance_valid(target_missile):
		return target_missile.global_position
	if target_aircraft != null and is_instance_valid(target_aircraft):
		return target_aircraft.global_position
	return Vector2.ZERO

func _get_target_velocity() -> Vector2:
	if target_missile != null and is_instance_valid(target_missile):
		var vel_value: Variant = target_missile.get("_velocity") if target_missile.has_method("get") else null
		if vel_value is Vector2:
			return vel_value
	if target_aircraft != null and is_instance_valid(target_aircraft):
		var vel_value: Variant = target_aircraft.get("_velocity") if target_aircraft.has_method("get") else null
		if vel_value is Vector2:
			return vel_value
	return Vector2.ZERO

func _compute_intercept_direction(target_pos: Vector2, target_vel: Vector2, interceptor_speed: float) -> Vector2:
	if target_vel.length_squared() <= 0.0001:
		return (target_pos - global_position).normalized()
	var rel := target_pos - global_position
	var speed_sq := interceptor_speed * interceptor_speed
	var a := target_vel.dot(target_vel) - speed_sq
	var b := 2.0 * rel.dot(target_vel)
	var c := rel.dot(rel)
	var t := _solve_intercept_time(a, b, c)
	if t <= 0.0:
		return rel.normalized()
	var aim_pos := target_pos + (target_vel * t)
	return (aim_pos - global_position).normalized()

func _solve_intercept_time(a: float, b: float, c: float) -> float:
	if absf(a) < 0.0001:
		if absf(b) < 0.0001:
			return 0.0
		return -c / b
	var disc := b * b - 4.0 * a * c
	if disc < 0.0:
		return 0.0
	var sqrt_disc := sqrt(disc)
	var t1 := (-b - sqrt_disc) / (2.0 * a)
	var t2 := (-b + sqrt_disc) / (2.0 * a)
	var best := 0.0
	if t1 > 0.0:
		best = t1
	if t2 > 0.0 and (best <= 0.0 or t2 < best):
		best = t2
	return best

func _is_seeking() -> bool:
	var target_height := maxf(_start_height, cruise_height)
	if _flight_height < target_height:
		return false
	if launch_phase_duration > 0.0 and _flight_time < launch_phase_duration:
		return false
	return true

func _get_current_speed() -> float:
	var mult := seek_speed_mult if _is_seeking() else 1.0
	return speed * maxf(0.0, mult)

func _check_intercept() -> void:
	# Check missile intercept
	if target_missile != null and is_instance_valid(target_missile):
		_check_missile_intercept()
		return

	# Check aircraft intercept
	if target_aircraft != null and is_instance_valid(target_aircraft):
		_check_aircraft_intercept()
		return

func _check_missile_intercept() -> void:
	var dist := global_position.distance_to(target_missile.global_position)
	var target_radius := 0.0
	if target_missile.has_method("get_warhead_radius"):
		target_radius = float(target_missile.get_warhead_radius())
	var collision_distance := maxf(0.0, body_radius) + maxf(0.0, target_radius)
	var effective_hit := maxf(hit_radius, collision_distance)
	if dist <= effective_hit:
		# Reached target - roll for intercept success
		var collided := dist <= collision_distance
		var success := collided
		if not success:
			var roll := _rng.randf()
			success = roll < success_chance

		var missile_pos := target_missile.global_position
		var impact_pos := missile_pos.lerp(global_position, 0.5)

		if success:
			# Successfully intercepted!
			# Trigger the explosion at our flight height directly
			_spawn_intercept_explosion_at_height(impact_pos)
			# Tell the missile it was intercepted (this will queue_free it without explosion)
			target_missile.intercept_silent()
		else:
			# Missed intercept, still explode
			_spawn_intercept_explosion_at_height(impact_pos)

		emit_signal("intercept_result", success, missile_pos, global_position)
		queue_free()

func _check_aircraft_intercept() -> void:
	var dist := global_position.distance_to(target_aircraft.global_position)
	var target_radius := 12.0  # Aircraft hit radius
	var collision_distance := maxf(0.0, body_radius) + target_radius
	var effective_hit := maxf(hit_radius, collision_distance)
	if dist <= effective_hit:
		# Reached target - roll for intercept success
		var collided := dist <= collision_distance
		var success := collided
		if not success:
			var roll := _rng.randf()
			success = roll < success_chance

		var aircraft_pos := target_aircraft.global_position
		var impact_pos := aircraft_pos.lerp(global_position, 0.5)

		# Always spawn explosion
		_spawn_intercept_explosion_at_height(impact_pos)

		if success:
			# Successfully hit aircraft - deal heavy damage
			if target_aircraft.has_method("take_damage"):
				target_aircraft.take_damage(target_aircraft.max_hp * 0.8, "interceptor")

		emit_signal("intercept_result", success, aircraft_pos, global_position)
		queue_free()

func _spawn_intercept_explosion_at_height(pos: Vector2) -> void:
	# Trigger the intercept explosion at our flight height
	var visual_syncs := get_tree().get_nodes_in_group("visual_sync_3d")
	for sync in visual_syncs:
		if sync.has_method("_on_missile_impact"):
			sync.call("_on_missile_impact", pos, Color(1.0, 0.5, 0.2, 1.0), "large", "intercepted", _flight_height)

func _self_destruct() -> void:
	# Explode in the air - creates a visual explosion
	# Emit a fake "intercepted" signal to trigger the explosion effect in visual_sync_3d
	# We use the Missile class's impact signal pattern

	# Find visual_sync_3d and trigger explosion effect directly
	var visual_syncs := get_tree().get_nodes_in_group("visual_sync_3d")
	for sync in visual_syncs:
		if sync.has_method("_on_missile_impact"):
			# Trigger a smaller explosion for self-destruct (not a full intercept explosion)
			# Pass the flight height so the explosion occurs at the correct altitude
			sync.call("_on_missile_impact", global_position, Color(1.0, 0.6, 0.2, 1.0), "small", "self_destruct", _flight_height)

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
	var radius := maxf(1.0, body_radius)
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
