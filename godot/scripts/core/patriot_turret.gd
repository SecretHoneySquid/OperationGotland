class_name PatriotTurret
extends DefenseTurret

## Patriot Air Defense System
##
## Specialized defense turret that intercepts incoming missiles (ATACMS, aircraft missiles).
## Does not attack ground units - purely a missile defense system.

signal missile_intercepted(missile_pos: Vector2, interceptor_pos: Vector2)

@export var intercept_success_base := 0.85  # Base success chance (85%)
@export var max_simultaneous_intercepts := 2  # Max missiles tracked at once
@export var interceptor_speed := 800.0
@export var interceptor_turn_rate := 18.0
@export var interceptor_lifetime := 6.0  # Longer lifetime for 900 range

var _tracked_missiles: Array[Missile] = []
var _active_interceptors: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("defense_turret")
	add_to_group("defense_turret_%s" % team_id)
	add_to_group("patriot_turret")
	_rng.randomize()
	# Note: 3D visual is handled by visual_sync_3d.gd, 2D visual by _draw()
	_setup_visual()  # This sets up 2D visual only
	print("[PATRIOT] Ready! team=", team_id, " range=", attack_range)

func update_targeting(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

	# Clean up invalid tracked missiles
	_cleanup_tracked_missiles()

	# Find new interceptable missiles if we have capacity
	if _tracked_missiles.size() < max_simultaneous_intercepts:
		_find_interceptable_missiles()

	# Update facing toward closest tracked missile
	if not _tracked_missiles.is_empty():
		var closest := _get_closest_tracked_missile()
		if closest != null:
			var to_target := closest.global_position - global_position
			_facing = to_target.normalized()
			_sync_visual_rotation()

	# Fire interceptors at tracked missiles
	if _cooldown <= 0.0 and not _tracked_missiles.is_empty():
		var target_missile := _get_highest_priority_missile()
		if target_missile != null:
			_fire_interceptor(target_missile)
			_cooldown = fire_rate

	queue_redraw()

func _cleanup_tracked_missiles() -> void:
	var valid_missiles: Array[Missile] = []
	for missile in _tracked_missiles:
		if is_instance_valid(missile) and missile.is_interceptable():
			var dist := global_position.distance_to(missile.global_position)
			# Keep tracking missiles within extended range (1.5x) to allow interception
			if dist <= attack_range * 1.5:
				valid_missiles.append(missile)
	_tracked_missiles = valid_missiles

	# Clean up finished interceptors
	var valid_interceptors: Array[Node2D] = []
	for interceptor in _active_interceptors:
		if is_instance_valid(interceptor):
			valid_interceptors.append(interceptor)
	_active_interceptors = valid_interceptors

func _find_interceptable_missiles() -> void:
	var slots_available := max_simultaneous_intercepts - _tracked_missiles.size()
	if slots_available <= 0:
		return

	var candidates: Array[Missile] = []
	var all_missiles := get_tree().get_nodes_in_group("missiles")

	for node in all_missiles:
		if not (node is Missile):
			continue
		var missile := node as Missile

		# Skip if not interceptable or already tracked
		if not missile.is_interceptable():
			continue
		if _tracked_missiles.has(missile):
			continue

		# Skip friendly missiles
		if missile.team_id == team_id:
			continue

		# Check range - use extended detection range (1.5x attack range) for early warning
		var dist := global_position.distance_to(missile.global_position)
		if dist > attack_range * 1.5:
			continue

		candidates.append(missile)

	# Sort by priority (distance, threat level)
	candidates.sort_custom(_compare_missile_priority)

	# Track up to available slots
	for i in range(mini(slots_available, candidates.size())):
		_tracked_missiles.append(candidates[i])
		print("[PATRIOT] Now tracking NEW missile, total tracked: ", _tracked_missiles.size())

func _compare_missile_priority(a: Missile, b: Missile) -> bool:
	# Priority: closer missiles first, higher difficulty missiles lower priority
	var dist_a := global_position.distance_to(a.global_position)
	var dist_b := global_position.distance_to(b.global_position)

	# Factor in intercept difficulty
	var priority_a := dist_a * a.get_intercept_difficulty()
	var priority_b := dist_b * b.get_intercept_difficulty()

	return priority_a < priority_b

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

	for missile in _tracked_missiles:
		if not is_instance_valid(missile):
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

		var dist := global_position.distance_to(missile.global_position)
		var score := dist * missile.get_intercept_difficulty()

		if score < best_score:
			best_score = score
			best = missile

	return best

func _fire_interceptor(target_missile: Missile) -> void:
	if target_missile == null or not is_instance_valid(target_missile):
		return

	print("[PATRIOT] FIRING INTERCEPTOR at missile at ", target_missile.global_position)

	var interceptor := InterceptorMissile.new()
	interceptor.speed = interceptor_speed
	interceptor.turn_rate = interceptor_turn_rate
	interceptor.lifetime = interceptor_lifetime
	interceptor.target_missile = target_missile
	interceptor.success_chance = _calculate_intercept_chance(target_missile)
	interceptor.color = missile_color
	interceptor.trail_color = Color(missile_color.r, missile_color.g, missile_color.b, 0.6)
	interceptor.team_id = team_id
	interceptor.set_origin(global_position)

	# Connect to intercept result
	interceptor.intercept_result.connect(_on_intercept_result)

	if get_parent() != null:
		get_parent().add_child(interceptor)
		# Set position AFTER adding to scene tree
		interceptor.global_position = global_position + (_facing * (base_radius + 4.0))
		print("[PATRIOT] Interceptor spawned at ", interceptor.global_position)
		_active_interceptors.append(interceptor)
		print("[PATRIOT] Interceptor launched! Active interceptors: ", _active_interceptors.size())

func _calculate_intercept_chance(target_missile: Missile) -> float:
	var chance := intercept_success_base

	# Reduce chance based on missile's intercept difficulty
	chance /= target_missile.get_intercept_difficulty()

	# Reduce chance based on distance (further = harder)
	var dist := global_position.distance_to(target_missile.global_position)
	var dist_factor := 1.0 - (dist / attack_range) * 0.2  # Max 20% penalty at max range
	chance *= dist_factor

	return clampf(chance, 0.1, 0.95)  # Clamp between 10% and 95%

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

		# Range indicator (faint circle)
		if _tracked_missiles.size() > 0:
			draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(0.5, 1.0, 0.5, 0.15), 2.0)
