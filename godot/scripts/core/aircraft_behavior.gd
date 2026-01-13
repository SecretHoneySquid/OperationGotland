extends RefCounted
class_name AircraftBehavior

## Aircraft Behavior Component
##
## Encapsulates all aircraft-specific logic extracted from unit.gd.
## This includes: missile firing, gun runs, landing/takeoff, reloading,
## squad management, loitering, and retreat behavior.

# =============================================================================
# REFERENCES
# =============================================================================

var unit: Unit  # Reference to the parent unit

# =============================================================================
# STATE VARIABLES
# =============================================================================

var missile_ammo := 0
var gun_ammo := 0
var missile_timer := 0.0
var reloading := false
var reload_timer := 0.0
var loiter_angle := 0.0
var orbit_phase := 0.0
var altitude_factor := 1.0
var circulating := false
var no_missile_timer := 0.0
var retreat_timer := 0.0
var retreat_phase := 0
var force_reload := false
var landing_reserved := false
var landing_on_path := false
var landing_taxi := false
var landing_slot := -1
var takeoff_active := false
var takeoff_taxi := false
var missile_lock_timer := 0.0
var missile_lock_id := 0
var speed_mult := 1.0
var afterburner_active := false
var squad_index := -1
var squad_leader_id := 0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(parent_unit: Unit) -> void:
	unit = parent_unit

func initialize() -> void:
	orbit_phase = unit._combat_rng.randf_range(0.0, TAU)
	if missile_ammo <= 0:
		missile_ammo = maxi(0, unit.aircraft_missile_capacity)
	if gun_ammo <= 0:
		gun_ammo = maxi(0, unit.aircraft_gun_capacity)
	if unit.aircraft_loiter_pos == Vector2.ZERO:
		if unit.rally_target != Vector2.ZERO:
			unit.aircraft_loiter_pos = unit.rally_target
		else:
			unit.aircraft_loiter_pos = get_home_pos()
	# Check if we spawned with a reserved slot
	if landing_reserved and landing_slot >= 0:
		takeoff_active = true
		takeoff_taxi = false
		altitude_factor = 0.0
	else:
		altitude_factor = 1.0
	_register_squad()

func cleanup() -> void:
	_unregister_squad()
	_release_landing_slot()
	_release_airfield_slot()
	_release_airfield_f35()

# =============================================================================
# MAIN UPDATE
# =============================================================================

func update(delta: float) -> void:
	missile_timer = maxf(0.0, missile_timer - delta)
	_refresh_squad_state()

	# UAVs don't engage in combat
	if unit.is_uav:
		if _update_takeoff(delta):
			return
		_update_loiter_reload(delta, null, null)
		_move_toward_loiter(delta)
		return

	# Don't look for targets while retreating
	var missile_target: Node2D = null
	var gun_target: Node2D = null
	if retreat_timer <= 0.0:
		missile_target = _find_missile_target()
		gun_target = unit._find_attack_target()
		if unit.aircraft_squad_enabled:
			if _is_squad_leader() and missile_target == null and _squad_has_missiles():
				missile_target = _find_missile_target(true)
			if _is_squad_leader():
				var shared := missile_target if missile_target != null else gun_target
				_set_squad_target(shared)
			else:
				var shared := _get_squad_target()
				if shared != null:
					missile_target = shared
					gun_target = shared

	_set_speed(1.0, false)
	_update_loiter_reload(delta, missile_target, gun_target)

	# Update retreat timer
	if retreat_timer > 0.0:
		retreat_timer -= delta

	if _update_reload(delta):
		missile_lock_timer = 0.0
		missile_lock_id = 0
		return

	if _update_takeoff(delta):
		missile_lock_timer = 0.0
		missile_lock_id = 0
		return

	# Don't update missile lock while retreating
	if retreat_timer <= 0.0:
		_update_missile_lock(delta, missile_target)
	else:
		missile_lock_timer = 0.0
		missile_lock_id = 0

	altitude_factor = 1.0
	landing_on_path = false
	landing_taxi = false
	circulating = false
	var fired := false
	var gun_in_range := gun_target != null and _gun_target_in_range(gun_target)

	# Fire weapons if in position (but not while retreating)
	if missile_target != null and retreat_timer <= 0.0:
		_face_toward(missile_target.global_position, delta)
		if missile_lock_timer >= unit.aircraft_missile_lock_time and _can_fire_missile():
			_fire_missile(missile_target)
			missile_lock_timer = 0.0
			fired = true

	if not fired and gun_target != null and gun_ammo > 0 and gun_in_range and retreat_timer <= 0.0:
		_face_toward(gun_target.global_position, delta)
		_fire_gun(gun_target)
		if unit.aircraft_retreat_after_gun:
			retreat_timer = unit.aircraft_retreat_duration
		fired = true

	# Movement logic
	if unit.manual_active or unit._hold_active:
		_set_speed(unit.aircraft_engage_speed_mult, true)
		var manual_target_pos := unit._resolve_target()
		if manual_target_pos != Vector2.ZERO:
			_move_toward_target(manual_target_pos, delta)
	elif retreat_timer > 0.0:
		_set_speed(unit.aircraft_engage_speed_mult, true)
		if retreat_phase == 0:
			if retreat_timer < unit.aircraft_retreat_duration - 1.5:
				retreat_phase = 1
			else:
				var to_loiter := (unit.aircraft_loiter_pos - unit.global_position).normalized()
				var turn_away := to_loiter.rotated(PI * 0.25)
				var away_target := unit.global_position + (turn_away * 500.0)
				_move_toward_target(away_target, delta)
		else:
			_move_toward_loiter(delta)
	elif missile_target != null:
		_set_speed(unit.aircraft_engage_speed_mult, true)
		var dist := unit.global_position.distance_to(missile_target.global_position)
		if dist < unit.aircraft_min_engagement_distance * 0.8:
			_move_toward_orbit_standoff(missile_target.global_position, unit.aircraft_min_engagement_distance, delta)
		else:
			var approach_pos := _calculate_standoff_position(missile_target.global_position, unit.aircraft_min_engagement_distance * 0.7)
			_move_toward_target(approach_pos, delta)
	else:
		circulating = true
		_set_speed(unit.aircraft_circulate_speed_mult, false)
		_move_toward_perimeter(delta)

# =============================================================================
# RELOAD & LANDING
# =============================================================================

func _update_reload(delta: float) -> bool:
	var needs_reload := force_reload or missile_ammo <= 0
	if not reloading and not needs_reload:
		return false

	if not reloading:
		reloading = true
		reload_timer = 0.0
		landing_on_path = false
		landing_taxi = false
		takeoff_active = false
		takeoff_taxi = false
		unit.manual_active = false
		unit.manual_target = Vector2.ZERO
		unit._hold_active = false
		unit._hold_timer = 0.0
		unit._hold_pos = Vector2.ZERO

	var home := get_home_pos()
	var distance := unit.global_position.distance_to(home)

	if unit.aircraft_home != null and is_instance_valid(unit.aircraft_home) and unit.aircraft_landing_cap > 0:
		if not landing_reserved:
			if not _reserve_landing_slot():
				altitude_factor = 1.0
				_set_speed(unit.aircraft_engage_speed_mult, true)
				_move_toward_queue(delta, home, _get_queue_radius())
				return true

	var landing_path := _get_landing_path(home)
	var touchdown := home
	var touchdown_value: Variant = landing_path.get("touchdown", home)
	if touchdown_value is Vector2:
		touchdown = touchdown_value
	var start := home
	var start_value: Variant = landing_path.get("start", home)
	if start_value is Vector2:
		start = start_value
	var rollout := touchdown
	var rollout_value: Variant = landing_path.get("rollout", touchdown)
	if rollout_value is Vector2:
		rollout = rollout_value
	var slot := rollout
	var slot_value: Variant = landing_path.get("slot", rollout)
	if slot_value is Vector2:
		slot = slot_value
	var path_dir := Vector2.RIGHT
	var dir_value: Variant = landing_path.get("dir", Vector2.RIGHT)
	if dir_value is Vector2:
		path_dir = dir_value
	var path_length := float(landing_path.get("length", unit.aircraft_landing_path_length))
	var entry_radius := maxf(unit.aircraft_landing_path_entry_radius, unit.aircraft_landing_radius * 2.0)

	unit.manual_active = false
	unit.manual_target = Vector2.ZERO

	if not landing_on_path:
		if unit.global_position.distance_to(start) > entry_radius:
			altitude_factor = 1.0
			_set_speed(unit.aircraft_engage_speed_mult, true)
			_move_toward_position(start, delta)
			return true
		landing_on_path = true

	var landing_radius := maxf(0.5, unit.aircraft_landing_radius)

	if not landing_taxi:
		var dist_to_rollout := unit.global_position.distance_to(rollout)
		var remaining := maxf(0.0, (unit.global_position - touchdown).dot(path_dir))

		if dist_to_rollout > landing_radius * 10.0:
			_set_speed(unit.aircraft_engage_speed_mult, true)
		else:
			var slowdown_progress := 1.0 - (dist_to_rollout / (landing_radius * 10.0))
			var speed_val := lerpf(unit.aircraft_engage_speed_mult, unit.aircraft_circulate_speed_mult * 0.6, slowdown_progress)
			_set_speed(speed_val, slowdown_progress < 0.3)

		_move_toward_position(rollout, delta)
		altitude_factor = clampf(remaining / maxf(1.0, path_length), 0.0, 1.0)
		if unit.global_position.distance_to(rollout) > landing_radius:
			reload_timer = 0.0
			return true
		landing_taxi = true

	altitude_factor = 0.0
	_set_speed(unit.aircraft_circulate_speed_mult * 0.5, false)
	_move_toward_position(slot, delta)

	if unit.global_position.distance_to(slot) > landing_radius:
		reload_timer = 0.0
		return true

	if reload_timer <= 0.0:
		reload_timer = unit.aircraft_reload_time

	reload_timer -= delta
	if reload_timer <= 0.0:
		_reload_ammo()
		reloading = false
		reload_timer = 0.0
		force_reload = false
		no_missile_timer = 0.0
		landing_on_path = false
		_release_landing_slot()
		unit._reached_rally = false
		takeoff_active = true
		takeoff_taxi = false

	return true

func _update_takeoff(delta: float) -> bool:
	if not takeoff_active:
		return false

	if unit.aircraft_home == null or not is_instance_valid(unit.aircraft_home):
		takeoff_active = false
		takeoff_taxi = false
		return false

	var home := get_home_pos()
	var landing_path := _get_landing_path(home)
	var runway_dir := Vector2.RIGHT
	var dir_value: Variant = landing_path.get("dir", Vector2.RIGHT)
	if dir_value is Vector2:
		runway_dir = dir_value
	var touchdown := home
	var touchdown_value: Variant = landing_path.get("touchdown", home)
	if touchdown_value is Vector2:
		touchdown = touchdown_value

	var path_length := unit.aircraft_landing_path_length
	var size2d := _get_airfield_size()
	if size2d != Vector2.ZERO:
		path_length = maxf(path_length, size2d.x * 1.4)

	var airborne_point := touchdown + (runway_dir * path_length)
	var landing_radius := maxf(0.5, unit.aircraft_landing_radius)
	var runway_start := home - (runway_dir * (size2d.x * 0.5)) if size2d != Vector2.ZERO else home

	if not takeoff_taxi:
		altitude_factor = 0.0
		_set_speed(unit.aircraft_circulate_speed_mult * 0.5, false)

		var dist_to_start := unit.global_position.distance_to(runway_start)
		if dist_to_start > landing_radius:
			_move_toward_position(runway_start, delta)
			return true

		var current_dir := Vector2.RIGHT.rotated(unit.rotation)
		var angle_diff := current_dir.angle_to(runway_dir)

		if absf(angle_diff) > 0.1:
			var turn_speed := 2.0 * delta
			var turn_amount := clampf(angle_diff, -turn_speed, turn_speed)
			unit.rotation += turn_amount
			return true

		takeoff_taxi = true
		return true

	var runway_length := size2d.x if size2d != Vector2.ZERO else 100.0
	var spawn_point := home - (runway_dir * runway_length * 0.5)
	var traveled_total := (unit.global_position - spawn_point).dot(runway_dir)

	var lift_start := runway_length * 0.6
	var lift_end := runway_length * 1.0
	var climb_end := runway_length * 1.8

	if traveled_total < lift_start:
		var accel_progress := traveled_total / lift_start
		var min_speed := unit.aircraft_circulate_speed_mult * 0.4
		var speed_val := lerpf(min_speed, unit.aircraft_circulate_speed_mult, accel_progress)
		altitude_factor = 0.0
		_set_speed(speed_val, false)
	elif traveled_total < lift_end:
		var lift_progress := (traveled_total - lift_start) / (lift_end - lift_start)
		altitude_factor = clampf(lift_progress * 0.25, 0.0, 0.25)
		var speed_val := lerpf(unit.aircraft_circulate_speed_mult, unit.aircraft_engage_speed_mult, lift_progress)
		_set_speed(speed_val, lift_progress > 0.5)
	else:
		var climb_progress := (traveled_total - lift_end) / (climb_end - lift_end)
		altitude_factor = clampf(0.25 + (climb_progress * 0.75), 0.25, 1.0)
		_set_speed(unit.aircraft_engage_speed_mult, true)

	_move_toward_position(airborne_point, delta)

	if altitude_factor < 0.99 or traveled_total < climb_end:
		return true

	takeoff_active = false
	takeoff_taxi = false
	altitude_factor = 1.0
	return true

func _reload_ammo() -> void:
	missile_ammo = maxi(0, unit.aircraft_missile_capacity)
	gun_ammo = maxi(0, unit.aircraft_gun_capacity)
	force_reload = false
	no_missile_timer = 0.0

# =============================================================================
# TARGETING
# =============================================================================

func _update_loiter_reload(delta: float, missile_target: Node2D, gun_target: Node2D) -> void:
	if reloading:
		no_missile_timer = 0.0
		force_reload = false
		return
	if missile_ammo > 0:
		no_missile_timer = 0.0
		force_reload = false
		return
	if unit.manual_active or unit._hold_active:
		no_missile_timer = 0.0
		force_reload = false
		return
	if missile_target != null or gun_target != null:
		no_missile_timer = 0.0
		return
	if unit.aircraft_loiter_reload_delay <= 0.0:
		force_reload = true
		return
	no_missile_timer += delta
	if no_missile_timer >= unit.aircraft_loiter_reload_delay:
		force_reload = true

func _update_missile_lock(delta: float, missile_target: Node2D) -> void:
	if unit.manual_active or unit._hold_active or takeoff_active:
		missile_lock_timer = 0.0
		missile_lock_id = 0
		return
	if missile_target == null or not is_instance_valid(missile_target):
		missile_lock_timer = 0.0
		missile_lock_id = 0
		return
	var target_id := int(missile_target.get_instance_id())
	if target_id != missile_lock_id:
		missile_lock_id = target_id
		missile_lock_timer = 0.0
		return
	missile_lock_timer = minf(unit.aircraft_missile_lock_time, missile_lock_timer + delta)

func _find_missile_target(ignore_ammo: bool = false) -> Node2D:
	if missile_ammo <= 0 and not ignore_ammo:
		return null

	var range := unit.aircraft_missile_range
	var range_sq := range * range if range > 0.0 else INF
	var incoming := _get_incoming_missiles()
	var focus_limit := maxi(1, unit.aircraft_missile_focus_limit)
	var best: Node2D = null
	var best_priority := 999
	var best_dist := range_sq
	var fallback: Node2D = null
	var fallback_priority := 999
	var fallback_dist := range_sq
	var groups := ["units", "building", "hq"]

	for group_name in groups:
		for node in unit.get_tree().get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node):
				continue
			if node is not Node2D:
				continue
			if node is Unit and (node as Unit).team_id == unit.team_id:
				continue
			if node is Building and (node as Building).team_id == unit.team_id:
				continue
			if node is HQ and (node as HQ).team_id == unit.team_id:
				continue
			if node is CanvasItem and not (node as CanvasItem).visible:
				continue
			var dist := unit.global_position.distance_squared_to((node as Node2D).global_position)
			if range > 0.0 and dist > range_sq:
				continue
			var priority := _target_priority(node as Node2D)
			if priority < fallback_priority or (priority == fallback_priority and dist < fallback_dist):
				fallback_priority = priority
				fallback_dist = dist
				fallback = node as Node2D
			var incoming_count := int(incoming.get(int(node.get_instance_id()), 0))
			if incoming_count >= focus_limit:
				continue
			if priority < best_priority or (priority == best_priority and dist < best_dist):
				best_priority = priority
				best_dist = dist
				best = node as Node2D

	if best != null:
		return best
	return fallback

func _get_incoming_missiles() -> Dictionary:
	var incoming := {}
	for node in unit.get_tree().get_nodes_in_group("missiles"):
		var missile := node as Missile
		if missile == null or not is_instance_valid(missile):
			continue
		if missile.team_id != unit.team_id:
			continue
		if str(missile.source_kind) != "aircraft":
			continue
		var target := missile.target
		if target == null or not is_instance_valid(target):
			continue
		var target_id := int(target.get_instance_id())
		incoming[target_id] = int(incoming.get(target_id, 0)) + 1
	return incoming

func _target_priority(target: Node2D) -> int:
	if target is Unit:
		var enemy := target as Unit
		if enemy.unit_kind == "vehicle":
			return 0
		if enemy.unit_kind == "aircraft":
			return 1
		return 2
	if target is HQ:
		return 1
	if target is Building:
		return 1
	return 3

func _gun_target_in_range(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var range := unit.attack_range
	if unit.vision_radius > 0.0:
		if range > 0.0:
			range = minf(range, unit.vision_radius)
		else:
			range = unit.vision_radius
	if range <= 0.0:
		return true
	return unit.global_position.distance_squared_to(target.global_position) <= range * range

# =============================================================================
# WEAPONS
# =============================================================================

func _can_fire_missile() -> bool:
	return missile_ammo > 0 and missile_timer <= 0.0 and _can_fire_squad_missile()

func _fire_missile(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	var missile := Missile.new()
	missile.speed = unit.aircraft_missile_speed
	missile.damage = unit.aircraft_missile_damage
	missile.turn_rate = unit.aircraft_missile_turn_rate
	missile.lifetime = unit.aircraft_missile_lifetime
	missile.warhead_size = unit.aircraft_missile_warhead_size
	if unit.aircraft_missile_hit_radius > 0.0:
		missile.hit_radius = unit.aircraft_missile_hit_radius
	if unit.aircraft_missile_splash_radius > 0.0:
		missile.splash_radius = unit.aircraft_missile_splash_radius
	missile.splash_damage_scale = unit.aircraft_missile_splash_scale
	if unit.aircraft_missile_range > 0.0:
		missile.range = unit.aircraft_missile_range
		missile.max_distance = unit.aircraft_missile_range
	missile.team_id = unit.team_id
	missile.color = unit.aircraft_missile_color
	missile.source_kind = "aircraft"
	missile.source_altitude = altitude_factor
	missile.target = target
	missile.global_position = unit.global_position + (unit._facing * (unit.body_radius + 6.0))
	missile.set_origin(unit.global_position)
	if unit.missile_visual_path != "":
		missile.visual_scene_path = unit.missile_visual_path
		missile.visual_base_radius = 0.1

	if unit.get_parent() != null:
		unit.get_parent().add_child(missile)

	retreat_timer = unit.aircraft_retreat_duration
	retreat_phase = 0
	missile_ammo = maxi(0, missile_ammo - 1)
	missile_timer = unit.aircraft_missile_cooldown
	if missile_ammo <= 0:
		_advance_squad_fire_index()

func _fire_gun(target: Node) -> void:
	if gun_ammo <= 0 or unit._cooldown > 0.0:
		return

	if target.has_method("take_damage"):
		var final_damage := unit.attack_damage
		if target is Unit:
			var enemy := target as Unit
			if enemy.unit_kind == "vehicle" or enemy.unit_kind == "aircraft":
				final_damage *= unit.damage_vs_vehicle
			else:
				final_damage *= unit.damage_vs_infantry
		elif target is Building or target is HQ:
			final_damage *= unit.damage_vs_structure
		target.take_damage(final_damage, unit.unit_type)

	if unit.shot_tracer_enabled and target is Node2D:
		var target_pos: Vector2 = (target as Node2D).global_position
		unit._spawn_tracer(target_pos)
		unit.emit_signal("shot_fired", unit.global_position, target_pos, unit.shot_color, unit.shot_width, unit.shot_lifetime)

	unit._cooldown = unit.attack_cooldown
	gun_ammo = maxi(0, gun_ammo - 1)

# =============================================================================
# MOVEMENT
# =============================================================================

func _move_toward_target(target: Vector2, delta: float) -> void:
	var adjusted := _get_formation_target(target)
	_move_toward_position(adjusted, delta)

func _move_toward_position(target: Vector2, delta: float) -> void:
	var delta_vec := target - unit.global_position
	if delta_vec.length() <= 1.0:
		return

	var direction := delta_vec.normalized()
	if not _allow_instant_turn() and unit.aircraft_turn_rate > 0.0:
		direction = _apply_turn(direction, delta)

	var move_speed := unit.speed * maxf(0.0, speed_mult)
	unit.global_position += direction * move_speed * delta
	unit._facing = direction

func _move_toward_loiter(delta: float) -> void:
	_move_toward_orbit(unit.aircraft_loiter_pos, unit.aircraft_loiter_radius, delta)

func _move_toward_perimeter(delta: float) -> void:
	var perimeter := _get_vision_perimeter()
	if not perimeter.is_empty():
		var center_value = perimeter.get("center", Vector2.ZERO)
		var radius_value = perimeter.get("radius", 0.0)
		if center_value is Vector2 and (radius_value is float or radius_value is int):
			_move_toward_orbit(center_value, float(radius_value), delta)
			return
	_move_toward_loiter(delta)

func _move_toward_orbit(center: Vector2, radius: float, delta: float) -> void:
	if center == Vector2.ZERO:
		return

	var orbit_center := _get_formation_target(center)
	var use_radius := maxf(0.0, radius) * maxf(0.1, unit.aircraft_orbit_radius_scale)
	loiter_angle = fmod(loiter_angle + (unit.aircraft_loiter_orbit_speed * delta), TAU)
	var angle := loiter_angle
	var wobble_amp := use_radius * maxf(0.0, unit.aircraft_orbit_wobble_ratio)
	var wobble := 0.0
	if wobble_amp > 0.0 and unit.aircraft_orbit_wobble_speed > 0.0:
		wobble = sin((angle * unit.aircraft_orbit_wobble_speed) + orbit_phase) * wobble_amp

	var orbit_target := orbit_center + Vector2(cos(angle), sin(angle)) * (use_radius + wobble)
	if circulating and unit.aircraft_circulation_spread_enabled:
		orbit_target += _get_circulation_offset()

	_move_toward_position(orbit_target, delta)

func _move_toward_orbit_standoff(target_pos: Vector2, orbit_radius: float, delta: float) -> void:
	var to_me := unit.global_position - target_pos
	var current_dist := to_me.length()
	var tangent := Vector2(-to_me.y, to_me.x).normalized()
	var radial_adjust := Vector2.ZERO

	if current_dist < orbit_radius * 0.9:
		radial_adjust = to_me.normalized() * 0.3
	elif current_dist > orbit_radius * 1.1:
		radial_adjust = -to_me.normalized() * 0.3

	var orbit_dir := (tangent + radial_adjust).normalized()
	var orbit_target := unit.global_position + (orbit_dir * 200.0)
	_move_toward_target(orbit_target, delta)

func _move_toward_queue(delta: float, center: Vector2, radius: float) -> void:
	if center == Vector2.ZERO:
		return
	var use_radius := maxf(0.0, radius)
	loiter_angle = fmod(loiter_angle + (unit.aircraft_loiter_orbit_speed * delta), TAU)
	var orbit_target := center + Vector2(cos(loiter_angle), sin(loiter_angle)) * use_radius
	_move_toward_position(orbit_target, delta)

func _calculate_standoff_position(target_pos: Vector2, standoff_dist: float) -> Vector2:
	var to_target := (target_pos - unit.global_position).normalized()
	return target_pos - (to_target * standoff_dist)

func _get_circulation_offset() -> Vector2:
	var min_spacing := maxf(0.0, unit.aircraft_circulation_spacing)
	var avoid_radius := maxf(min_spacing, unit.aircraft_circulation_avoid_radius)
	if min_spacing <= 0.0 or avoid_radius <= 0.0:
		return Vector2.ZERO

	var push := Vector2.ZERO
	var count := 0
	var radius_sq := avoid_radius * avoid_radius

	for node in unit.get_tree().get_nodes_in_group("units"):
		var other := node as Unit
		if other == null or other == unit:
			continue
		if other.unit_kind != "aircraft" or other.team_id != unit.team_id:
			continue
		if not other.aircraft_circulating:
			continue
		var delta := unit.global_position - other.global_position
		var dist_sq := delta.length_squared()
		if dist_sq <= 0.01 or dist_sq > radius_sq:
			continue
		var dist := sqrt(dist_sq)
		var away := delta / dist
		var strength := 1.0 - clampf(dist / avoid_radius, 0.0, 1.0)
		if dist < min_spacing:
			strength = 1.0
		push += away * strength
		count += 1

	if count <= 0:
		return Vector2.ZERO

	push /= float(count)
	var max_push := min_spacing * maxf(0.0, unit.aircraft_circulation_avoid_strength)
	if push.length() > max_push:
		push = push.normalized() * max_push
	return push

# =============================================================================
# TURNING
# =============================================================================

func _face_toward(pos: Vector2, delta: float) -> void:
	var delta_vec := pos - unit.global_position
	if delta_vec.length_squared() <= 0.1:
		return
	var desired := delta_vec.normalized()
	if _allow_instant_turn() or unit.aircraft_turn_rate <= 0.0:
		unit._facing = desired
		return
	unit._facing = _apply_turn(desired, delta)

func _apply_turn(desired: Vector2, delta: float) -> Vector2:
	var desired_dir := desired.normalized()
	if unit._facing.length_squared() <= 0.01:
		return desired_dir
	var angle := unit._facing.angle_to(desired_dir)
	var max_turn := unit.aircraft_turn_rate * delta
	var clamped := clampf(angle, -max_turn, max_turn)
	var turned := unit._facing.rotated(clamped)
	if turned.length_squared() <= 0.01:
		return desired_dir
	return turned.normalized()

func _allow_instant_turn() -> bool:
	return landing_on_path or landing_taxi or takeoff_active

func _set_speed(mult: float, afterburner: bool) -> void:
	speed_mult = maxf(0.0, mult)
	afterburner_active = afterburner

# =============================================================================
# FORMATION
# =============================================================================

func _should_use_formation() -> bool:
	return unit.aircraft_squad_enabled and squad_index > 0

func _get_formation_offset_local() -> Vector2:
	if squad_index <= 0:
		return Vector2.ZERO
	var row := int((squad_index - 1) / 2) + 1
	var side := -1 if (squad_index % 2) == 1 else 1
	var back := float(row) * unit.aircraft_squad_spacing
	var lateral := float(row) * unit.aircraft_squad_spacing * unit.aircraft_squad_lateral_ratio
	return Vector2(-back, lateral * float(side))

func _get_formation_target(base: Vector2) -> Vector2:
	if not _should_use_formation():
		return base
	var leader := _get_squad_leader()
	if leader == null or not is_instance_valid(leader):
		return base
	var dir := base - leader.global_position
	if dir.length_squared() <= 0.01:
		dir = leader._facing
	if dir.length_squared() <= 0.01:
		dir = Vector2.RIGHT
	var forward := dir.normalized()
	var right := Vector2(-forward.y, forward.x)
	var offset := _get_formation_offset_local()
	return base + (forward * offset.x) + (right * offset.y)

# =============================================================================
# SQUAD MANAGEMENT
# =============================================================================

func _get_squad_home() -> Node2D:
	if not unit.aircraft_squad_enabled:
		return null
	if unit.aircraft_home == null or not is_instance_valid(unit.aircraft_home):
		return null
	return unit.aircraft_home

func _get_squad_member_ids() -> Array:
	var home := _get_squad_home()
	if home == null:
		return []
	var members_value: Variant = home.get_meta("air_squad_members", [])
	var members: Array = members_value if members_value is Array else []
	var cleaned: Array = []
	for value in members:
		var id := int(value)
		var inst := instance_from_id(id)
		if inst == null or not is_instance_valid(inst):
			continue
		if inst is not Unit:
			continue
		var u := inst as Unit
		if u.unit_kind != "aircraft":
			continue
		if u.aircraft_home != home:
			continue
		cleaned.append(id)
	if cleaned.size() != members.size():
		home.set_meta("air_squad_members", cleaned)
	return cleaned

func _register_squad() -> void:
	var home := _get_squad_home()
	if home == null:
		return
	var members := _get_squad_member_ids()
	var id := unit.get_instance_id()
	if not members.has(id):
		members.append(id)
		home.set_meta("air_squad_members", members)
	if not home.has_meta("air_squad_fire_index"):
		home.set_meta("air_squad_fire_index", 0)
	_refresh_squad_state()

func _unregister_squad() -> void:
	var home := _get_squad_home()
	if home == null:
		return
	var members := _get_squad_member_ids()
	var id := unit.get_instance_id()
	if members.has(id):
		members.erase(id)
		home.set_meta("air_squad_members", members)
	if members.is_empty():
		home.set_meta("air_squad_target_id", 0)
		home.set_meta("air_squad_fire_index", 0)
	squad_index = -1
	squad_leader_id = 0

func _refresh_squad_state() -> void:
	var members := _get_squad_member_ids()
	if members.is_empty():
		squad_index = -1
		squad_leader_id = 0
		return
	squad_leader_id = int(members[0])
	squad_index = members.find(unit.get_instance_id())

func _is_squad_leader() -> bool:
	return squad_leader_id == unit.get_instance_id()

func _get_squad_leader() -> Unit:
	if squad_leader_id <= 0:
		return null
	var inst := instance_from_id(squad_leader_id)
	if inst is Unit:
		return inst as Unit
	return null

func _set_squad_target(target: Node2D) -> void:
	var home := _get_squad_home()
	if home == null:
		return
	if target == null or not is_instance_valid(target):
		home.set_meta("air_squad_target_id", 0)
		return
	home.set_meta("air_squad_target_id", target.get_instance_id())

func _get_squad_target() -> Node2D:
	var home := _get_squad_home()
	if home == null:
		return null
	var target_id := int(home.get_meta("air_squad_target_id", 0))
	if target_id <= 0:
		return null
	var inst := instance_from_id(target_id)
	if inst == null or not is_instance_valid(inst):
		home.set_meta("air_squad_target_id", 0)
		return null
	if inst is not Node2D:
		home.set_meta("air_squad_target_id", 0)
		return null
	return inst as Node2D

func _get_squad_missile_owner_id() -> int:
	var home := _get_squad_home()
	if home == null:
		return unit.get_instance_id()
	var members := _get_squad_member_ids()
	if members.is_empty():
		return unit.get_instance_id()
	var index := int(home.get_meta("air_squad_fire_index", 0))
	if index < 0 or index >= members.size():
		index = 0
	var current_id := int(members[index])
	var current := instance_from_id(current_id) as Unit
	if current != null and is_instance_valid(current) and current._aircraft_behavior != null and current._aircraft_behavior.missile_ammo > 0:
		home.set_meta("air_squad_fire_index", index)
		return current_id
	for offset in range(1, members.size() + 1):
		var next_index := (index + offset) % members.size()
		var next_id := int(members[next_index])
		var next := instance_from_id(next_id) as Unit
		if next != null and is_instance_valid(next) and next._aircraft_behavior != null and next._aircraft_behavior.missile_ammo > 0:
			home.set_meta("air_squad_fire_index", next_index)
			return next_id
	home.set_meta("air_squad_fire_index", index)
	return current_id

func _can_fire_squad_missile() -> bool:
	if not unit.aircraft_squad_enabled:
		return true
	return _get_squad_missile_owner_id() == unit.get_instance_id()

func _advance_squad_fire_index() -> void:
	var home := _get_squad_home()
	if home == null:
		return
	var members := _get_squad_member_ids()
	if members.is_empty():
		return
	var index := int(home.get_meta("air_squad_fire_index", 0))
	if index < 0 or index >= members.size():
		index = 0
	for offset in range(1, members.size() + 1):
		var next_index := (index + offset) % members.size()
		var next_id := int(members[next_index])
		var next := instance_from_id(next_id) as Unit
		if next != null and is_instance_valid(next) and next._aircraft_behavior != null and next._aircraft_behavior.missile_ammo > 0:
			home.set_meta("air_squad_fire_index", next_index)
			return
	home.set_meta("air_squad_fire_index", index)

func _squad_has_missiles() -> bool:
	if not unit.aircraft_squad_enabled:
		return missile_ammo > 0
	var members := _get_squad_member_ids()
	for member_id in members:
		var u := instance_from_id(int(member_id)) as Unit
		if u != null and is_instance_valid(u) and u._aircraft_behavior != null and u._aircraft_behavior.missile_ammo > 0:
			return true
	return false

# =============================================================================
# AIRFIELD HELPERS
# =============================================================================

func get_home_pos() -> Vector2:
	if unit.aircraft_home != null and is_instance_valid(unit.aircraft_home):
		return unit.aircraft_home.global_position
	if unit.aircraft_home_pos != Vector2.ZERO:
		return unit.aircraft_home_pos
	return unit.home_pos

func _get_queue_radius() -> float:
	if unit.aircraft_queue_radius > 0.0:
		return unit.aircraft_queue_radius
	if unit.aircraft_home != null and is_instance_valid(unit.aircraft_home):
		var size_value: Variant = unit.aircraft_home.get("size")
		if size_value is Vector2:
			var size: Vector2 = size_value
			return maxf(size.x, size.y) * 0.65
	return maxf(unit.aircraft_reload_radius * 1.2, unit.aircraft_loiter_radius)

func _get_airfield_size() -> Vector2:
	if unit.aircraft_home != null and is_instance_valid(unit.aircraft_home):
		var size_value: Variant = unit.aircraft_home.get("size")
		if size_value is Vector2:
			return size_value
	return Vector2.ZERO

func _get_runway_dir() -> Vector2:
	if unit.team_id == "p2":
		return Vector2(-1.0, 0.0)
	return Vector2(1.0, 0.0)

func _get_runway_offset(size2d: Vector2) -> Vector2:
	if size2d == Vector2.ZERO:
		return Vector2.ZERO
	var runway_dir := _get_runway_dir()
	if runway_dir.length_squared() <= 0.0:
		runway_dir = Vector2.RIGHT
	var lateral := Vector2(-runway_dir.y, runway_dir.x).normalized()
	return lateral * (size2d.y * unit.aircraft_runway_offset_ratio)

func _get_landing_slot_offset(size2d: Vector2, runway_dir: Vector2) -> Vector2:
	if landing_slot < 0:
		return Vector2.ZERO
	var slot_count := maxi(1, unit.aircraft_landing_cap)
	if slot_count <= 1:
		return Vector2.ZERO
	var lateral := Vector2(-runway_dir.y, runway_dir.x)
	if lateral.length_squared() <= 0.0:
		return Vector2.ZERO
	lateral = lateral.normalized()
	var spacing := unit.aircraft_landing_slot_spacing
	if spacing <= 0.0:
		spacing = maxf(unit.body_radius * 2.6, unit.aircraft_landing_radius * 6.0)
	if size2d != Vector2.ZERO:
		var max_spacing := (size2d.y * 0.6) / float(slot_count - 1)
		spacing = minf(spacing, max_spacing)
	var slot_index := clampi(landing_slot, 0, slot_count - 1)
	var side := -1.0 if slot_index < 2 else 1.0
	var row := float(slot_index % 2)
	var lateral_offset := lateral * (side * spacing)
	var longitudinal_offset := runway_dir * (row * spacing * 0.8)
	return lateral_offset + longitudinal_offset

func _get_landing_path(home: Vector2) -> Dictionary:
	var size2d := _get_airfield_size()
	var runway_dir := _get_runway_dir().normalized()
	if runway_dir.length_squared() <= 0.0:
		runway_dir = Vector2.RIGHT
	var offset := _get_runway_offset(size2d)
	var touchdown := home + offset
	if size2d != Vector2.ZERO:
		touchdown = home + (runway_dir * (size2d.x * 0.5)) + offset
	var rollout := home + offset
	if size2d != Vector2.ZERO:
		rollout = home - (runway_dir * (size2d.x * 0.15)) + offset
	var slot_offset := _get_landing_slot_offset(size2d, runway_dir)
	var slot := rollout + slot_offset
	var base_length := unit.aircraft_landing_path_length
	if size2d != Vector2.ZERO:
		base_length = maxf(base_length, size2d.x * 1.4)
	var start := touchdown + runway_dir * base_length
	return {
		"start": start,
		"touchdown": touchdown,
		"rollout": rollout,
		"slot": slot,
		"dir": runway_dir,
		"length": base_length,
	}

func _reserve_landing_slot() -> bool:
	if landing_reserved:
		return true
	if unit.aircraft_landing_cap <= 0:
		landing_reserved = true
		return true
	if unit.aircraft_home == null or not is_instance_valid(unit.aircraft_home):
		landing_reserved = true
		return true

	var slot_map: Dictionary = {}
	var slot_value: Variant = unit.aircraft_home.get_meta("aircraft_landing_slots", {})
	if slot_value is Dictionary:
		slot_map = slot_value.duplicate()

	var dead_slots: Array = []
	for key in slot_map.keys():
		var slot_id := int(slot_map.get(key, -1))
		if slot_id < 0:
			dead_slots.append(key)
			continue
		var inst = instance_from_id(slot_id)
		if inst == null or not is_instance_valid(inst):
			dead_slots.append(key)

	for key in dead_slots:
		slot_map.erase(key)

	var slot_count := maxi(1, unit.aircraft_landing_cap)
	for i in range(slot_count):
		if slot_map.has(i):
			continue
		slot_map[i] = unit.get_instance_id()
		unit.aircraft_home.set_meta("aircraft_landing_slots", slot_map)
		unit.aircraft_home.set_meta("aircraft_landing", slot_map.size())
		landing_reserved = true
		landing_slot = i
		return true
	return false

func _release_landing_slot() -> void:
	if not landing_reserved:
		return
	landing_reserved = false

	if unit.aircraft_home == null or not is_instance_valid(unit.aircraft_home):
		landing_slot = -1
		return

	var slot_value: Variant = unit.aircraft_home.get_meta("aircraft_landing_slots", {})
	if slot_value is Dictionary:
		var slot_map: Dictionary = slot_value.duplicate()
		var id := unit.get_instance_id()
		if landing_slot >= 0 and slot_map.has(landing_slot):
			if int(slot_map.get(landing_slot, -1)) == id:
				slot_map.erase(landing_slot)
		else:
			for key in slot_map.keys():
				if int(slot_map.get(key, -1)) == id:
					slot_map.erase(key)
					break
		unit.aircraft_home.set_meta("aircraft_landing_slots", slot_map)
		unit.aircraft_home.set_meta("aircraft_landing", slot_map.size())
	else:
		var current := int(unit.aircraft_home.get_meta("aircraft_landing", 0))
		if current > 0:
			unit.aircraft_home.set_meta("aircraft_landing", current - 1)

	landing_slot = -1

func _release_airfield_slot() -> void:
	if unit.aircraft_home == null or not is_instance_valid(unit.aircraft_home):
		return
	var current = int(unit.aircraft_home.get_meta("aircraft_active", 0))
	if current <= 0:
		return
	unit.aircraft_home.set_meta("aircraft_active", current - 1)

func _release_airfield_f35() -> void:
	if unit.unit_type != "f35":
		return
	if unit.aircraft_home == null or not is_instance_valid(unit.aircraft_home):
		return
	var current := int(unit.aircraft_home.get_meta("f35_active", 0))
	if current == unit.get_instance_id():
		unit.aircraft_home.set_meta("f35_active", 0)

# =============================================================================
# VISION PERIMETER
# =============================================================================

func _get_vision_perimeter() -> Dictionary:
	var group_name := ""
	if unit.team_id == "p1":
		group_name = "vision_p1"
	if group_name == "":
		return {}

	var nodes: Array = unit.get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		return {}

	var center := Vector2.ZERO
	var count := 0
	var base_center := Vector2.ZERO
	var base_radius := 0.0

	for node in nodes:
		if node is BaseVision:
			base_center = (node as BaseVision).global_position
			var base_value = (node as BaseVision).get_vision_radius()
			if base_value is float or base_value is int:
				base_radius = float(base_value)
			break

	for node in nodes:
		if node is Node2D and node.has_method("get_vision_radius"):
			center += (node as Node2D).global_position
			count += 1

	if count <= 0:
		return {}

	center /= float(count)
	if base_center != Vector2.ZERO:
		center = base_center

	if unit.aircraft_perimeter_forward_bias > 0.0 and unit.enemy_hq != null and is_instance_valid(unit.enemy_hq):
		var bias := clampf(unit.aircraft_perimeter_forward_bias, 0.0, 1.0)
		var enemy_pos := unit.enemy_hq.global_position
		center += (enemy_pos - center) * bias

	var max_radius := base_radius
	for node in nodes:
		if node is Node2D and node.has_method("get_vision_radius"):
			var radius_value = node.get_vision_radius()
			var radius := 0.0
			if radius_value is float or radius_value is int:
				radius = float(radius_value)
			var pos: Vector2 = (node as Node2D).global_position
			var dist := center.distance_to(pos)
			max_radius = maxf(max_radius, dist + radius)

	if max_radius <= 0.0:
		return {}

	max_radius += maxf(0.0, unit.aircraft_perimeter_padding)
	return {
		"center": center,
		"radius": max_radius,
	}
