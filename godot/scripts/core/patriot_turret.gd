class_name PatriotTurret
extends DefenseTurret

## Patriot Air Defense System
##
## Specialized defense turret that intercepts incoming missiles (ATACMS, aircraft missiles).
## Does not attack ground units - purely a missile defense system.

signal missile_intercepted(missile_pos: Vector2, interceptor_pos: Vector2)

@export var intercept_success_base := 0.3  # Base success chance when solo without radar
@export var max_simultaneous_intercepts := 2  # Max missiles tracked at once
@export var max_interceptors_per_missile := 4
@export var interceptor_speed := 800.0
@export var interceptor_turn_rate := 20.0
@export var interceptor_lifetime := 6.0  # Longer lifetime for 900 range
@export var interceptor_salvo_count := 2
@export var interceptor_salvo_spacing := 6.0
@export var interceptor_salvo_delay := 0.5
@export var interceptor_shots_per_reload := 4
@export var interceptor_reload_time := 10.0
@export var radar_support_range := 600.0
@export var patriot_coordination_range := 600.0
@export var turret_turn_rate := 4.5  # Radians/sec for facing rotation
@export var protection_color_no_radar_low := Color(0.28, 0.38, 0.22, 0.11)
@export var protection_color_no_radar_high := Color(0.35, 0.7, 0.4, 0.2)
@export var protection_color_radar_low := Color(0.18, 0.4, 0.55, 0.12)
@export var protection_color_radar_high := Color(0.2, 0.75, 0.85, 0.22)
@export var protection_outline_alpha := 0.4
@export var protection_tracking_tint := Color(0.6, 0.3, 0.25, 1.0)
@export var protection_tracking_blend := 0.2
@export var protection_union_segments := 36
@export var protection_pulse_enabled := true
@export var protection_pulse_speed := 0.75
@export var protection_pulse_alpha := 0.45
@export var protection_pulse_outline_boost := 0.7
@export var protection_pulse_lighten := 0.12
@export var protection_pulse_no_radar_multiplier := 1.3

var _tracked_missiles: Array[Missile] = []
var _tracked_aircraft: Array[Unit] = []
var _active_interceptors: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()
var _shots_remaining: int = 0
var _reloading := false
var _reload_timer := 0.0

# Protection area configuration
var protection_configured := false  # Turret inactive until configured
var protection_direction := Vector2.RIGHT  # Center direction of the pie
var protection_arc_half_angle := deg_to_rad(30.0)  # 30 degrees each side = 60 degree arc total

func _ready() -> void:
	add_to_group("defense_turret")
	add_to_group("defense_turret_%s" % team_id)
	add_to_group("patriot_turret")
	_rng.randomize()
	_shots_remaining = maxi(0, interceptor_shots_per_reload)
	# Note: 3D visual is handled by visual_sync_3d.gd, 2D visual by _draw()
	_setup_visual()  # This sets up 2D visual only

func update_targeting(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_update_reload(delta)

	# If not configured, do nothing
	if not protection_configured:
		queue_redraw()
		return

	# Clean up invalid tracked targets
	_cleanup_tracked_missiles()
	_cleanup_tracked_aircraft()

	# Calculate total tracked targets
	var total_tracked := _tracked_missiles.size() + _tracked_aircraft.size()

	# Find new interceptable missiles if we have capacity
	if total_tracked < max_simultaneous_intercepts:
		_find_interceptable_missiles()

	# Find new targetable aircraft if we have capacity (requires radar)
	total_tracked = _tracked_missiles.size() + _tracked_aircraft.size()
	if total_tracked < max_simultaneous_intercepts:
		_find_targetable_aircraft()

	# Update facing toward closest tracked target (prioritize missiles)
	var closest_target: Node2D = null
	if not _tracked_missiles.is_empty():
		closest_target = _get_closest_tracked_missile()
	elif not _tracked_aircraft.is_empty():
		closest_target = _get_closest_tracked_aircraft()

	if closest_target != null:
		var to_target := closest_target.global_position - global_position
		_rotate_facing_toward(to_target, delta)
		_sync_visual_rotation()

	# Fire interceptors at tracked targets (prioritize missiles)
	if _cooldown <= 0.0 and (not _tracked_missiles.is_empty() or not _tracked_aircraft.is_empty()):
		if _reloading:
			queue_redraw()
			return
		if _shots_remaining <= 0:
			_start_reload()
			queue_redraw()
			return

		# Prioritize missiles over aircraft
		var target_missile := _get_highest_priority_missile()
		if target_missile != null:
			var fired := _fire_interceptor_at_missile(target_missile)
			if fired:
				_shots_remaining -= 1
				if _shots_remaining <= 0:
					_start_reload()
				_cooldown = fire_rate
		else:
			# No missiles, try aircraft
			var target_aircraft := _get_highest_priority_aircraft()
			if target_aircraft != null:
				var fired := _fire_interceptor_at_aircraft(target_aircraft)
				if fired:
					_shots_remaining -= 1
					if _shots_remaining <= 0:
						_start_reload()
					_cooldown = fire_rate

	queue_redraw()

func _update_reload(delta: float) -> void:
	if not _reloading:
		return
	_reload_timer -= delta
	if _reload_timer <= 0.0:
		_reloading = false
		_reload_timer = 0.0
		_shots_remaining = maxi(0, interceptor_shots_per_reload)

func _start_reload() -> void:
	if _reloading:
		return
	if interceptor_reload_time <= 0.0:
		_shots_remaining = maxi(0, interceptor_shots_per_reload)
		return
	_reloading = true
	_reload_timer = interceptor_reload_time

func _cleanup_tracked_missiles() -> void:
	var valid_missiles: Array[Missile] = []
	var detection_range := _get_detection_range()
	for missile in _tracked_missiles:
		if is_instance_valid(missile) and missile.is_interceptable():
			if _is_missile_saturated(missile):
				continue
			var dist := global_position.distance_to(missile.global_position)
			# Keep tracking missiles within detection range to allow interception
			if dist <= detection_range:
				valid_missiles.append(missile)
	_tracked_missiles = valid_missiles

	# Clean up finished interceptors
	var valid_interceptors: Array[Node2D] = []
	for interceptor in _active_interceptors:
		if is_instance_valid(interceptor):
			valid_interceptors.append(interceptor)
	_active_interceptors = valid_interceptors

func _cleanup_tracked_aircraft() -> void:
	var valid_aircraft: Array[Unit] = []
	var detection_range := _get_detection_range()
	for aircraft in _tracked_aircraft:
		if not is_instance_valid(aircraft):
			continue
		if aircraft.hp <= 0:
			continue
		# Must still be radar detected or we have radar support
		if not _has_radar_support() and aircraft.radar_detected_timer <= 0:
			continue
		var dist := global_position.distance_to(aircraft.global_position)
		if dist <= detection_range:
			valid_aircraft.append(aircraft)
	_tracked_aircraft = valid_aircraft

func _rotate_facing_toward(to_target: Vector2, delta: float) -> void:
	if to_target.length_squared() <= 0.0001:
		return
	var desired := to_target.normalized()
	var current := _facing
	if current.length_squared() <= 0.0001:
		current = desired
	var current_angle := current.angle()
	var desired_angle := desired.angle()
	var delta_angle := angle_difference(current_angle, desired_angle)
	var max_turn := maxf(0.0, turret_turn_rate) * delta
	if max_turn <= 0.0001:
		_facing = desired
		return
	var turn := clampf(delta_angle, -max_turn, max_turn)
	_facing = Vector2.from_angle(current_angle + turn)

func _find_interceptable_missiles() -> void:
	var slots_available := max_simultaneous_intercepts - _tracked_missiles.size()
	if slots_available <= 0:
		return

	# If not configured, don't track any missiles
	if not protection_configured:
		return

	var candidates: Array[Missile] = []
	var all_missiles := get_tree().get_nodes_in_group("missiles")
	var detection_range := _get_detection_range()

	for node in all_missiles:
		if node == null or not is_instance_valid(node):
			continue
		if not (node is Missile):
			continue
		var missile := node as Missile

		# Skip if not interceptable or already tracked
		if not missile.is_interceptable():
			continue
		if _tracked_missiles.has(missile):
			continue
		if _is_missile_saturated(missile):
			continue

		# Skip friendly missiles
		if missile.team_id == team_id:
			continue

		# Check range - use detection range for early warning
		var dist := global_position.distance_to(missile.global_position)
		if dist > detection_range:
			continue

		# Check if missile is in or will pass through protection area
		if not will_pass_through_protection_area(missile):
			continue

		candidates.append(missile)

	# Sort by priority (distance, threat level)
	candidates.sort_custom(_compare_missile_priority)

	# Track up to available slots
	for i in range(mini(slots_available, candidates.size())):
		_tracked_missiles.append(candidates[i])

func _compare_missile_priority(a: Missile, b: Missile) -> bool:
	# Priority: fewer interceptors assigned, then closer missiles, then difficulty
	var interceptors_a := _count_interceptors_targeting(a)
	var interceptors_b := _count_interceptors_targeting(b)
	if interceptors_a != interceptors_b:
		return interceptors_a < interceptors_b

	var dist_a := global_position.distance_to(a.global_position)
	var dist_b := global_position.distance_to(b.global_position)

	# Factor in intercept difficulty
	var priority_a := dist_a * a.get_intercept_difficulty()
	var priority_b := dist_b * b.get_intercept_difficulty()

	return priority_a < priority_b

func _find_targetable_aircraft() -> void:
	# Only target aircraft if we have radar support or aircraft is radar detected
	var slots_available := max_simultaneous_intercepts - _tracked_missiles.size() - _tracked_aircraft.size()
	if slots_available <= 0:
		return

	if not protection_configured:
		return

	var candidates: Array[Unit] = []
	var all_units := get_tree().get_nodes_in_group("units")
	var detection_range := _get_detection_range()
	var has_radar := _has_radar_support()

	for node in all_units:
		if node == null or not is_instance_valid(node):
			continue
		if not (node is Unit):
			continue
		var unit := node as Unit

		# Only target aircraft
		if unit.unit_kind != "aircraft":
			continue

		# Skip friendly aircraft
		if unit.team_id == team_id:
			continue

		# Skip dead aircraft
		if unit.hp <= 0:
			continue

		# Skip already tracked
		if _tracked_aircraft.has(unit):
			continue

		# Must have radar support OR aircraft must be radar detected
		if not has_radar and unit.radar_detected_timer <= 0:
			continue

		# Check range
		var dist := global_position.distance_to(unit.global_position)
		if dist > detection_range:
			continue

		# Check if aircraft is in protection area
		if not is_in_protection_area(unit.global_position):
			continue

		candidates.append(unit)

	# Sort by distance (closest first)
	candidates.sort_custom(_compare_aircraft_priority)

	# Track up to available slots
	for i in range(mini(slots_available, candidates.size())):
		_tracked_aircraft.append(candidates[i])

func _compare_aircraft_priority(a: Unit, b: Unit) -> bool:
	var dist_a := global_position.distance_to(a.global_position)
	var dist_b := global_position.distance_to(b.global_position)
	return dist_a < dist_b

func _get_closest_tracked_aircraft() -> Unit:
	var closest: Unit = null
	var closest_dist := INF
	for aircraft in _tracked_aircraft:
		if not is_instance_valid(aircraft):
			continue
		var dist := global_position.distance_to(aircraft.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = aircraft
	return closest

func _get_highest_priority_aircraft() -> Unit:
	var best: Unit = null
	var best_dist := INF
	for aircraft in _tracked_aircraft:
		if not is_instance_valid(aircraft):
			continue
		if aircraft.hp <= 0:
			continue
		var dist := global_position.distance_to(aircraft.global_position)
		if dist < best_dist:
			best_dist = dist
			best = aircraft
	return best

func _count_interceptors_targeting(missile: Missile) -> int:
	if missile == null:
		return 0
	var tree := get_tree()
	if tree == null:
		return 0
	var count := 0
	for node in tree.get_nodes_in_group("interceptor_missiles"):
		if node == null or not is_instance_valid(node):
			continue
		if node is not InterceptorMissile:
			continue
		var interceptor := node as InterceptorMissile
		if interceptor.team_id != team_id:
			continue
		if interceptor.target_missile == missile:
			count += 1
	return count

func _is_missile_saturated(missile: Missile) -> bool:
	if max_interceptors_per_missile <= 0:
		return false
	return _count_interceptors_targeting(missile) >= max_interceptors_per_missile

func _get_closest_tracked_missile() -> Missile:
	var closest: Missile = null
	var closest_dist := INF
	for missile in _tracked_missiles:
		if not is_instance_valid(missile):
			continue
		var dist := global_position.distance_to(missile.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = missile
	return closest

func _get_highest_priority_missile() -> Missile:
	# Get the missile that needs interception most urgently
	# Consider: distance, time to impact, whether already being intercepted
	var best: Missile = null
	var best_score := INF
	var best_interceptors := 9999

	for missile in _tracked_missiles:
		if not is_instance_valid(missile):
			continue
		if _is_missile_saturated(missile):
			continue

		# Check if already being targeted by one of our interceptors
		var already_targeted := false
		for interceptor in _active_interceptors:
			if is_instance_valid(interceptor):
				var int_missile = interceptor as InterceptorMissile
				if int_missile != null and int_missile.target_missile == missile:
					already_targeted = true
					break

		if already_targeted:
			continue

		var interceptors := _count_interceptors_targeting(missile)
		var dist := global_position.distance_to(missile.global_position)
		var score := dist * missile.get_intercept_difficulty()

		if interceptors < best_interceptors or (interceptors == best_interceptors and score < best_score):
			best_interceptors = interceptors
			best_score = score
			best = missile

	return best

func _fire_interceptor_at_missile(target_missile: Missile) -> bool:
	if target_missile == null or not is_instance_valid(target_missile):
		return false

	var count := maxi(1, interceptor_salvo_count)
	if max_interceptors_per_missile > 0:
		var available := max_interceptors_per_missile - _count_interceptors_targeting(target_missile)
		if available <= 0:
			return false
		count = mini(count, available)

	if count <= 0:
		return false


	var spacing := maxf(0.0, interceptor_salvo_spacing)
	var start_pos := global_position + (_facing * (base_radius + 4.0))
	var lateral := _facing.rotated(PI * 0.5)
	var success_chance := _calculate_intercept_chance(target_missile)
	for i in range(count):
		var offset := Vector2.ZERO
		if count > 1 and spacing > 0.0:
			var step := float(i) - (float(count - 1) * 0.5)
			offset = lateral * (spacing * step)
		var delay := maxf(0.0, interceptor_salvo_delay) * float(i)
		_queue_interceptor_spawn(target_missile, start_pos + offset, success_chance, delay)
	return true

func _spawn_interceptor_instance(target_missile: Missile, spawn_pos: Vector2, success_chance: float) -> void:
	if target_missile == null or not is_instance_valid(target_missile):
		return
	if not target_missile.is_interceptable():
		return
	if _is_missile_saturated(target_missile):
		return
	if get_parent() == null:
		return
	var interceptor := InterceptorMissile.new()
	interceptor.speed = interceptor_speed
	interceptor.turn_rate = interceptor_turn_rate
	interceptor.lifetime = interceptor_lifetime
	interceptor.target_missile = target_missile
	interceptor.success_chance = success_chance
	interceptor.color = missile_color
	interceptor.trail_color = Color(missile_color.r, missile_color.g, missile_color.b, 0.6)
	interceptor.team_id = team_id
	interceptor.set_origin(global_position)

	# Connect to intercept result
	interceptor.intercept_result.connect(_on_intercept_result)

	get_parent().add_child(interceptor)
	# Set position AFTER adding to scene tree
	interceptor.global_position = spawn_pos
	_active_interceptors.append(interceptor)

func _queue_interceptor_spawn(target_missile: Missile, spawn_pos: Vector2, success_chance: float, delay: float) -> void:
	if delay <= 0.0:
		_spawn_interceptor_instance(target_missile, spawn_pos, success_chance)
		return
	var tree := get_tree()
	if tree == null:
		return
	var timer := tree.create_timer(delay)
	if timer == null:
		return
	timer.timeout.connect(Callable(self, "_on_delayed_interceptor_spawn").bind(target_missile, spawn_pos, success_chance))

func _on_delayed_interceptor_spawn(target_missile: Missile, spawn_pos: Vector2, success_chance: float) -> void:
	if not is_inside_tree():
		return
	_spawn_interceptor_instance(target_missile, spawn_pos, success_chance)

func _fire_interceptor_at_aircraft(target_aircraft: Unit) -> bool:
	if target_aircraft == null or not is_instance_valid(target_aircraft):
		return false
	if target_aircraft.hp <= 0:
		return false

	# Fire a single interceptor at aircraft (no salvo like missiles)
	var start_pos := global_position + (_facing * (base_radius + 4.0))
	var success_chance := _calculate_aircraft_intercept_chance(target_aircraft)
	_spawn_interceptor_at_aircraft(target_aircraft, start_pos, success_chance)
	return true

func _spawn_interceptor_at_aircraft(target_aircraft: Unit, spawn_pos: Vector2, success_chance: float) -> void:
	if target_aircraft == null or not is_instance_valid(target_aircraft):
		return
	if target_aircraft.hp <= 0:
		return
	if get_parent() == null:
		return
	var interceptor := InterceptorMissile.new()
	interceptor.speed = interceptor_speed
	interceptor.turn_rate = interceptor_turn_rate
	interceptor.lifetime = interceptor_lifetime
	interceptor.target_aircraft = target_aircraft
	interceptor.success_chance = success_chance
	interceptor.color = missile_color
	interceptor.trail_color = Color(missile_color.r, missile_color.g, missile_color.b, 0.6)
	interceptor.team_id = team_id
	interceptor.set_origin(global_position)

	# Connect to intercept result
	interceptor.intercept_result.connect(_on_intercept_result)

	get_parent().add_child(interceptor)
	interceptor.global_position = spawn_pos
	_active_interceptors.append(interceptor)

func _calculate_aircraft_intercept_chance(target_aircraft: Unit) -> float:
	var chance := _get_teamwork_intercept_base()

	# Aircraft are harder to intercept than missiles
	chance *= 0.7

	# Reduce chance based on distance
	var dist := global_position.distance_to(target_aircraft.global_position)
	var dist_factor := 1.0 - (dist / attack_range) * 0.3
	chance *= dist_factor

	return clampf(chance, 0.1, 0.85)

func _count_nearby_patriots() -> int:
	if patriot_coordination_range <= 0.0:
		return 1
	var tree := get_tree()
	if tree == null:
		return 1
	var range_sq := patriot_coordination_range * patriot_coordination_range
	var count := 0
	for node in tree.get_nodes_in_group("patriot_turret"):
		if node == null or not is_instance_valid(node):
			continue
		if node is not PatriotTurret:
			continue
		var patriot := node as PatriotTurret
		if patriot.team_id != team_id:
			continue
		if not patriot.protection_configured:
			continue
		if global_position.distance_squared_to(patriot.global_position) > range_sq:
			continue
		count += 1
	return maxi(1, count)

func _has_radar_support() -> bool:
	return _get_radar_support_range() > 0.0

func _get_teamwork_intercept_base() -> float:
	# Solo 0.3, 2+ Patriots 0.5, radar adds 0.3 + 0.1 per extra Patriot (cap 0.9).
	var patriots := _count_nearby_patriots()
	var base := intercept_success_base
	if _has_radar_support():
		base += 0.3 + (0.1 * float(maxi(0, patriots - 1)))
		return minf(base, intercept_success_base + 0.6)
	if patriots >= 2:
		base += 0.2
	return base

func get_teamwork_intercept_base() -> float:
	return _get_teamwork_intercept_base()

func get_teamwork_strength_normalized() -> float:
	var min_base := intercept_success_base
	var max_base := intercept_success_base + 0.6
	var span := maxf(0.001, max_base - min_base)
	return clampf((_get_teamwork_intercept_base() - min_base) / span, 0.0, 1.0)

func get_ground_marking_colors(is_tracking: bool) -> Dictionary:
	var strength := get_teamwork_strength_normalized()
	var use_radar := _has_radar_support()
	var low := protection_color_radar_low if use_radar else protection_color_no_radar_low
	var high := protection_color_radar_high if use_radar else protection_color_no_radar_high
	var fill := low.lerp(high, strength)
	var blend := clampf(protection_tracking_blend, 0.0, 1.0)
	if is_tracking and blend > 0.0:
		fill = fill.lerp(protection_tracking_tint, blend)
	var base_alpha := fill.a
	var outline := fill
	outline.a = clampf(maxf(base_alpha * 2.6, protection_outline_alpha), 0.0, 1.0)
	if protection_pulse_enabled and protection_pulse_speed > 0.0:
		var pulse := _get_pulse_value()
		var depth := protection_pulse_alpha
		if not use_radar:
			depth *= protection_pulse_no_radar_multiplier
		var alpha_mult := lerpf(1.0 - depth, 1.0 + depth, pulse)
		var outline_mult := lerpf(1.0, 1.0 + protection_pulse_outline_boost, pulse)
		if protection_pulse_lighten > 0.0:
			fill = fill.lerp(fill.lightened(protection_pulse_lighten), pulse * 0.6)
			outline = outline.lerp(outline.lightened(protection_pulse_lighten * 0.4), pulse * 0.4)
		fill.a = clampf(base_alpha * alpha_mult, 0.0, 1.0)
		outline.a = clampf(outline.a * outline_mult, 0.0, 1.0)
	return {
		"fill": fill,
		"outline": outline,
	}

func _get_pulse_value() -> float:
	var t := float(Time.get_ticks_msec()) * 0.001
	return 0.5 + 0.5 * sin(t * TAU * protection_pulse_speed)

func _get_connected_patriots() -> Array[PatriotTurret]:
	var connected: Array[PatriotTurret] = []
	if patriot_coordination_range <= 0.0:
		connected.append(self)
		return connected
	var tree := get_tree()
	if tree == null:
		connected.append(self)
		return connected
	var candidates: Array[PatriotTurret] = []
	for node in tree.get_nodes_in_group("patriot_turret"):
		if node == null or not is_instance_valid(node):
			continue
		if node is not PatriotTurret:
			continue
		var patriot := node as PatriotTurret
		if patriot.team_id != team_id:
			continue
		if not patriot.protection_configured:
			continue
		candidates.append(patriot)
	if candidates.is_empty():
		connected.append(self)
		return connected
	var range_sq := patriot_coordination_range * patriot_coordination_range
	var queue: Array[PatriotTurret] = []
	queue.append(self)
	while queue.size() > 0:
		var current: PatriotTurret = queue.pop_front() as PatriotTurret
		if connected.has(current):
			continue
		connected.append(current)
		for other in candidates:
			if connected.has(other):
				continue
			if current.global_position.distance_squared_to(other.global_position) <= range_sq:
				queue.append(other)
	return connected

func should_render_unified_protection() -> bool:
	if not protection_configured:
		return false
	if patriot_coordination_range <= 0.0:
		return true
	var connected := _get_connected_patriots()
	var leader_id := get_instance_id()
	for patriot in connected:
		var id := patriot.get_instance_id()
		if id < leader_id:
			leader_id = id
	return get_instance_id() == leader_id

func _make_protection_polygon_global(patriot: PatriotTurret, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	if patriot == null:
		return points
	var use_segments: int = maxi(3, segments)
	var range := patriot.get_protection_render_range()
	if range <= 0.0:
		return points
	points.resize(use_segments + 2)
	points[0] = patriot.global_position
	var dir_angle := patriot.protection_direction.angle()
	var start_angle := dir_angle - patriot.protection_arc_half_angle
	var end_angle := dir_angle + patriot.protection_arc_half_angle
	for i in range(use_segments + 1):
		var t := float(i) / float(use_segments)
		var angle := lerpf(start_angle, end_angle, t)
		var offset := Vector2(cos(angle), sin(angle)) * range
		points[i + 1] = patriot.global_position + offset
	return points

func _polygon_bounds(poly: PackedVector2Array) -> Rect2:
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for point in poly:
		min_pt.x = minf(min_pt.x, point.x)
		min_pt.y = minf(min_pt.y, point.y)
		max_pt.x = maxf(max_pt.x, point.x)
		max_pt.y = maxf(max_pt.y, point.y)
	if min_pt.x == INF:
		return Rect2()
	return Rect2(min_pt, max_pt - min_pt)

func _polygons_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() < 3 or b.size() < 3:
		return false
	var bounds_a := _polygon_bounds(a)
	var bounds_b := _polygon_bounds(b)
	if not bounds_a.intersects(bounds_b):
		return false
	if Geometry2D.has_method("intersect_polygons"):
		var res: Variant = Geometry2D.intersect_polygons(a, b)
		if res is Array and (res as Array).size() > 0:
			return true
	if Geometry2D.has_method("clip_polygons"):
		var res_clip: Variant = Geometry2D.clip_polygons(a, b)
		if res_clip is Array and (res_clip as Array).size() > 0:
			return true
	if Geometry2D.has_method("is_point_in_polygon"):
		for point in a:
			if Geometry2D.is_point_in_polygon(point, b):
				return true
		for point in b:
			if Geometry2D.is_point_in_polygon(point, a):
				return true
	return false

func _merge_polygons(a: PackedVector2Array, b: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var merged: Variant = Geometry2D.merge_polygons(a, b)
	if merged is Array:
		for poly in merged:
			if poly is PackedVector2Array and (poly as PackedVector2Array).size() >= 3:
				result.append(poly as PackedVector2Array)
	return result

func _union_polygons(polys: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for poly in polys:
		if poly.size() < 3:
			continue
		var pending: Array[PackedVector2Array] = [poly]
		var i := 0
		while i < result.size():
			var existing: PackedVector2Array = result[i]
			var merged_any := false
			var next_pending: Array[PackedVector2Array] = []
			for candidate in pending:
				if _polygons_overlap(existing, candidate):
					var merged := _merge_polygons(existing, candidate)
					if merged.is_empty():
						next_pending.append(candidate)
					else:
						for m in merged:
							next_pending.append(m)
					merged_any = true
				else:
					next_pending.append(candidate)
			if merged_any:
				result.remove_at(i)
				pending = next_pending
				i = 0
			else:
				pending = next_pending
				i += 1
		for candidate in pending:
			result.append(candidate)
	return result

func get_union_protection_polygons() -> Array[PackedVector2Array]:
	if not protection_configured:
		return []
	var connected: Array[PatriotTurret] = _get_connected_patriots()
	if connected.size() <= 1:
		return []
	var segments: int = maxi(6, protection_union_segments)
	var global_polys: Array[PackedVector2Array] = []
	for patriot: PatriotTurret in connected:
		var poly := _make_protection_polygon_global(patriot, segments)
		if poly.size() >= 3:
			global_polys.append(poly)
	var union_polys: Array[PackedVector2Array] = _union_polygons(global_polys)
	var local_polys: Array[PackedVector2Array] = []
	for poly in union_polys:
		var local := PackedVector2Array()
		local.resize(poly.size())
		for i in range(poly.size()):
			local[i] = to_local(poly[i])
		local_polys.append(local)
	return local_polys

func _calculate_intercept_chance(target_missile: Missile) -> float:
	var chance := _get_teamwork_intercept_base()

	# Reduce chance based on missile's intercept difficulty
	chance /= target_missile.get_intercept_difficulty()

	# Reduce chance based on distance (further = harder)
	var dist := global_position.distance_to(target_missile.global_position)
	var dist_factor := 1.0 - (dist / attack_range) * 0.2  # Max 20% penalty at max range
	chance *= dist_factor

	return clampf(chance, 0.1, 0.95)  # Clamp between 10% and 95%

func get_detection_range() -> float:
	return _get_detection_range()

func get_base_detection_range() -> float:
	return attack_range * 1.5

func get_protection_render_range() -> float:
	var render_range := attack_range
	if is_radar_extended():
		render_range = maxf(render_range, get_detection_range())
	return render_range

func is_radar_extended() -> bool:
	var base_range := attack_range * 1.5
	var radar_range := _get_radar_support_range()
	return radar_range > base_range + 0.1

func _get_detection_range() -> float:
	var range := attack_range * 1.5
	var radar_range := _get_radar_support_range()
	if radar_range > 0.0:
		range = maxf(range, radar_range)
	return range

func _get_radar_support_range() -> float:
	if radar_support_range <= 0.0:
		return 0.0
	var tree := get_tree()
	if tree == null:
		return 0.0
	var best_range := 0.0
	var group_name := "radar_station_%s" % team_id
	for node in tree.get_nodes_in_group(group_name):
		if node == null or not is_instance_valid(node):
			continue
		if node is not Node2D:
			continue
		var radar := node as Node2D
		var configured_value: Variant = radar.get("protection_configured") if radar.has_method("get") else true
		if configured_value is bool and not configured_value:
			continue
		var support_radius := radar_support_range
		var support_value: Variant = radar.get("support_radius") if radar.has_method("get") else null
		if support_value is float or support_value is int:
			support_radius = float(support_value)
		if support_radius <= 0.0:
			continue
		var support_radius_sq := support_radius * support_radius
		if global_position.distance_squared_to(radar.global_position) > support_radius_sq:
			continue
		var range_value: Variant = radar.get("attack_range") if radar.has_method("get") else null
		var radar_range := 0.0
		if range_value is float or range_value is int:
			radar_range = float(range_value)
		best_range = maxf(best_range, radar_range)
	return best_range

func _on_intercept_result(success: bool, missile_pos: Vector2, interceptor_pos: Vector2) -> void:
	if success:
		emit_signal("missile_intercepted", missile_pos, interceptor_pos)

# Override to prevent attacking ground units
func _find_target() -> Node2D:
	return null  # Patriot doesn't target ground units

func _fire_missile() -> void:
	pass  # Patriot uses interceptors, not regular missiles

func _fire_hitscan() -> void:
	pass  # Patriot doesn't use hitscan

# Custom draw for Patriot (radar dish style)
func _draw() -> void:
	if not render_2d:
		return
	if _visual_node == null:
		var base_col := base_color
		# Shadow
		draw_circle(Vector2(2.0, 3.0), base_radius * 0.95, Color(0.0, 0.0, 0.0, 0.25))

		# Base platform (larger for Patriot)
		var hull := _get_base_points()
		var base_points := _transform_points(hull, 0.0, base_radius)
		var top_points := _transform_points(hull, 0.0, base_radius * 0.72, Vector2(-1.0, -1.0))
		draw_colored_polygon(base_points, _shade(base_col, -0.08))
		draw_colored_polygon(top_points, _shade(base_col, 0.14))

		# Outline
		var outline := base_points.duplicate()
		if outline.size() > 0:
			outline.append(base_points[0])
			draw_polyline(outline, _shade(base_col, -0.35), 1.6)

		# Radar/launcher array (rectangle shape)
		var launcher_color := _shade(base_col, 0.25)
		var launcher_width := base_radius * 0.5
		var launcher_height := base_radius * 0.8
		var launcher_rect := Rect2(-launcher_width/2, -launcher_height, launcher_width, launcher_height)
		var rotated_points := PackedVector2Array()
		var corners := [
			Vector2(launcher_rect.position.x, launcher_rect.position.y),
			Vector2(launcher_rect.position.x + launcher_rect.size.x, launcher_rect.position.y),
			Vector2(launcher_rect.position.x + launcher_rect.size.x, launcher_rect.position.y + launcher_rect.size.y),
			Vector2(launcher_rect.position.x, launcher_rect.position.y + launcher_rect.size.y),
		]
		for corner in corners:
			rotated_points.append(corner.rotated(_facing.angle()))
		draw_colored_polygon(rotated_points, launcher_color)

		# Center turret
		draw_circle(Vector2.ZERO, base_radius * 0.25, _shade(base_col, 0.3))

	# Draw protection area pie
	if protection_configured and should_render_unified_protection():
		var is_tracking := _tracked_missiles.size() > 0
		var colors := get_ground_marking_colors(is_tracking)
		var pie_color: Color = colors.get("fill", Color(0.3, 0.7, 0.3, 0.12))
		var outline_color: Color = colors.get("outline", Color(0.5, 1.0, 0.5, 0.35))
		var union_polys: Array[PackedVector2Array] = get_union_protection_polygons()
		if union_polys.size() > 0:
			for poly in union_polys:
				if poly.size() < 3:
					continue
				draw_colored_polygon(poly, pie_color)
				var outline := PackedVector2Array()
				outline.append_array(poly)
				outline.append(poly[0])
				draw_polyline(outline, outline_color, 2.0)
		else:
			var start_angle := protection_direction.angle() - protection_arc_half_angle
			var end_angle := protection_direction.angle() + protection_arc_half_angle
			var render_range := get_protection_render_range()
			if render_range <= 0.0:
				return
			_draw_protection_pie(pie_color, start_angle, end_angle, render_range)
			draw_arc(Vector2.ZERO, render_range, start_angle, end_angle, 64, outline_color, 2.0)
			draw_line(Vector2.ZERO, Vector2.from_angle(start_angle) * render_range, outline_color, 2.0)
			draw_line(Vector2.ZERO, Vector2.from_angle(end_angle) * render_range, outline_color, 2.0)

func _draw_protection_pie(color: Color, start_angle: float, end_angle: float, radius: float) -> void:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var segments := 32
	var angle_step := (end_angle - start_angle) / float(segments)
	for i in range(segments + 1):
		var angle := start_angle + angle_step * float(i)
		points.append(Vector2.from_angle(angle) * radius)
	draw_colored_polygon(points, color)

# Override to prevent 2D visual loading - 3D visual is handled by visual_sync_3d.gd
func _setup_visual() -> void:
	# Do not call super._setup_visual() - we don't want the 2D visual node
	# The 2D representation is handled by _draw() for the fallback case
	# The 3D representation is handled by visual_sync_3d.gd
	pass

# Protection area configuration
func set_protection_area(direction_angle: float, arc_half_angle: float) -> void:
	protection_direction = Vector2.from_angle(direction_angle)
	protection_arc_half_angle = arc_half_angle
	protection_configured = true

func is_in_protection_area(pos: Vector2, range_override := -1.0) -> bool:
	if not protection_configured:
		return false

	var to_pos := pos - global_position
	var dist := to_pos.length()
	var range := range_override if range_override > 0.0 else _get_detection_range()

	# Check if within range
	if dist > range:
		return false

	# Check if within the arc
	var pos_angle := to_pos.angle()
	var dir_angle := protection_direction.angle()
	var angle_diff := absf(angle_difference(dir_angle, pos_angle))

	return angle_diff <= protection_arc_half_angle

func will_pass_through_protection_area(missile: Missile) -> bool:
	if not protection_configured:
		return false
	var detection_range := _get_detection_range()

	# Check if missile is currently in the protection area
	if is_in_protection_area(missile.global_position, detection_range):
		return true

	# Predict missile trajectory - check if it will enter the protection area
	var velocity := missile._velocity if missile._velocity != null else Vector2.ZERO
	if velocity.length_squared() < 1.0:
		return is_in_protection_area(missile.global_position, detection_range)

	# Check several points along predicted path
	var prediction_time := 3.0
	var check_steps := 6
	var time_step := prediction_time / float(check_steps)

	for i in range(check_steps):
		var future_pos := missile.global_position + velocity * (time_step * float(i + 1))
		if is_in_protection_area(future_pos, detection_range):
			return true

	return false
