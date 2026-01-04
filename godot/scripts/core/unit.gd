class_name Unit
extends Node2D

signal shot_fired(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, lifetime: float)

@export var team_id := "p1"
@export var color := Color(0.2, 0.5, 1.0, 1.0):
	set(value):
		color = value
		_update_visual_color()
		queue_redraw()

@export var speed := 90.0
@export var ground_slope_max_deg := 28.0
@export var ground_slope_sample_distance := 0.0
@export var navigation_enabled := true
@export var navigation_layers := 1
@export var navigation_optimize := true
@export var navigation_repath_interval := 0.6
@export var navigation_repath_distance := 120.0
@export var navigation_point_reach_dist := 14.0
@export var max_hp := 30.0
@export var attack_damage := 6.0
@export var attack_range := 26.0
@export var aggro_range := 220.0
@export var chase_leash := 320.0
@export var attack_cooldown := 0.6
@export var body_radius := 8.0
@export var structure_aggro_range := 260.0
@export var shot_tracer_enabled := true
@export var shot_color := Color(1.0, 1.0, 1.0, 0.7)
@export var shot_width := 2.0
@export var shot_lifetime := 0.12
@export var vision_radius := 220.0
@export var range_role := "short"
@export var range_multiplier := 1.0
@export var unit_type := "rifle"
@export var prefers_vehicle := false
@export var prefers_infantry := false
@export var damage_vs_infantry := 1.0
@export var damage_vs_vehicle := 1.0
@export var damage_vs_structure := 1.0
@export var combat_spread_enabled := true
@export var combat_spread_radius := 24.0
@export var combat_spread_min_interval := 0.6
@export var combat_spread_max_interval := 1.2
@export var visual_scene_path := ""
@export var visual_base_radius := 10.0
@export var visual_offset := Vector2.ZERO
@export var render_2d := true
@export var missile_visual_path := ""

@export var aircraft_missile_capacity := 2
@export var aircraft_gun_capacity := 20
@export var aircraft_reload_time := 7.0
@export var aircraft_missile_range := 2500.0  # Reduced from 12000
@export var aircraft_missile_speed := 520.0
@export var aircraft_missile_turn_rate := 6.0
@export var aircraft_missile_damage := 32.0
@export var aircraft_missile_cooldown := 2.4
@export var aircraft_missile_lock_time := 2.0
@export var aircraft_missile_focus_limit := 1
@export var aircraft_missile_color := Color(1.0, 0.55, 0.25, 1.0)
@export var aircraft_missile_warhead_size := "large"
@export var aircraft_missile_hit_radius := 12.0
@export var aircraft_missile_splash_radius := 80.0
@export var aircraft_missile_splash_scale := 0.85
@export var aircraft_missile_lifetime := 24.0
@export var aircraft_reload_radius := 18.0
@export var aircraft_loiter_radius := 120.0
@export var aircraft_loiter_orbit_speed := 0.4
@export var aircraft_orbit_radius_scale := 10.0
@export var aircraft_orbit_wobble_ratio := 0.08
@export var aircraft_orbit_wobble_speed := 3.0
@export var aircraft_perimeter_padding := 60.0
@export var aircraft_perimeter_forward_bias := 0.2
@export var aircraft_loiter_reload_delay := 5.0
@export var aircraft_retreat_duration := 3.0  # Time to retreat after firing missile
@export var aircraft_turn_rate := 2.2
@export var aircraft_circulate_speed_mult := 1.5
@export var aircraft_engage_speed_mult := 2.0
@export var aircraft_circulation_spread_enabled := true
@export var aircraft_circulation_spacing := 16.0
@export var aircraft_circulation_avoid_radius := 28.0
@export var aircraft_circulation_avoid_strength := 0.8
@export var aircraft_landing_radius := 2.0
@export var aircraft_landing_path_length := 720.0
@export var aircraft_landing_path_entry_radius := 18.0
@export var aircraft_runway_offset_ratio := 0.0
@export var aircraft_landing_slot_spacing := 32.0
@export var aircraft_landing_cap := 2
@export var aircraft_queue_radius := 0.0
@export var aircraft_squad_enabled := true
@export var aircraft_squad_spacing := 80.0
@export var aircraft_squad_lateral_ratio := 0.6

var hp := 0.0
var unit_kind := "infantry"
var home_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var rally_target := Vector2.ZERO
var _reached_rally := false
var manual_target := Vector2.ZERO
var manual_active := false
var is_selected := false
var enemy_hq: HQ
var _cooldown := 0.0
var _facing := Vector2.RIGHT
var _chase_target: Node2D
var _structure_target: Node2D
var _combat_offset := Vector2.ZERO
var _combat_timer := 0.0
var _combat_rng := RandomNumberGenerator.new()
var _hold_active := false
var _hold_timer := 0.0
var _hold_pos := Vector2.ZERO
var _hold_reached := false
var _visual_node: Node2D
var aircraft_home: Node2D
var aircraft_home_pos := Vector2.ZERO
var aircraft_loiter_pos := Vector2.ZERO
var aircraft_missile_ammo := 0
var aircraft_gun_ammo := 0
var _aircraft_missile_timer := 0.0
var _aircraft_reloading := false
var _aircraft_reload_timer := 0.0
var _aircraft_loiter_angle := 0.0
var _aircraft_orbit_phase := 0.0
var aircraft_altitude_factor := 1.0
var aircraft_circulating := false
var _aircraft_no_missile_timer := 0.0
var _aircraft_retreat_timer := 0.0  # Timer for post-missile retreat behavior
var _aircraft_retreat_direction := Vector2.ZERO  # Direction to flee when retreating
var _aircraft_force_reload := false
var _aircraft_landing_reserved := false
var _aircraft_landing_on_path := false
var _aircraft_landing_taxi := false
var _aircraft_landing_slot := -1
var _aircraft_takeoff_active := false
var _aircraft_takeoff_taxi := false
var _aircraft_missile_lock_timer := 0.0
var _aircraft_missile_lock_id := 0
var _aircraft_speed_mult := 1.0
var aircraft_afterburner_active := false
var _aircraft_squad_index := -1
var _aircraft_squad_leader_id := 0
var _ground_height_provider: Node
var _nav_provider: Node
var _nav_path := PackedVector2Array()
var _nav_index := 0
var _nav_target := Vector2.ZERO
var _nav_repath_timer := 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("units")
	add_to_group("units_%s" % team_id)
	GameState.unit_count += 1
	_combat_rng.randomize()
	_aircraft_orbit_phase = _combat_rng.randf_range(0.0, TAU)
	if team_id == "p1" and vision_radius > 0.0:
		add_to_group("vision_p1")
		var light := VisionHelper.create_light(vision_radius)
		add_child(light)
	if unit_kind == "aircraft":
		if aircraft_missile_ammo <= 0:
			aircraft_missile_ammo = maxi(0, aircraft_missile_capacity)
		if aircraft_gun_ammo <= 0:
			aircraft_gun_ammo = maxi(0, aircraft_gun_capacity)
		if aircraft_loiter_pos == Vector2.ZERO:
			if rally_target != Vector2.ZERO:
				aircraft_loiter_pos = rally_target
			else:
				aircraft_loiter_pos = _get_aircraft_home_pos()
		if aircraft_home != null and is_instance_valid(aircraft_home):
			_aircraft_takeoff_active = true
			_aircraft_takeoff_taxi = false
			aircraft_altitude_factor = 0.0
		_register_aircraft_squad()
	_setup_visual()

func _exit_tree() -> void:
	GameState.unit_count = maxi(0, GameState.unit_count - 1)
	if unit_kind == "aircraft":
		_unregister_aircraft_squad()
		_release_landing_slot()
		_release_airfield_slot()
		_release_airfield_f35()

func take_damage(amount: float, attacker_type: String = "") -> void:
	var final_damage := amount

	# Aircraft take 90% less damage from infantry weapons (riflemen and snipers)
	if (unit_type == "gripen" or unit_type == "f35") and (attacker_type == "rifle" or attacker_type == "sniper"):
		final_damage *= 0.1

	hp = maxf(0.0, hp - final_damage)
	if hp <= 0.0:
		queue_free()

func get_vision_radius() -> float:
	return vision_radius

func _process(delta: float) -> void:
	if hp <= 0.0:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if unit_kind == "aircraft":
		_aircraft_missile_timer = maxf(0.0, _aircraft_missile_timer - delta)
	_update_hold(delta)
	if unit_kind == "aircraft":
		_update_aircraft_state(delta)
		return
	if not manual_active and not _hold_active:
		_update_chase_target()
		_update_structure_target()
	if not manual_active:
		_update_combat_spread(delta)
	var target := _find_attack_target()
	if target != null:
		_face_toward(target.global_position)
		_attack(target)
	else:
		_move_toward_target(delta)
	_sync_visual_rotation()

func _draw() -> void:
	if not render_2d:
		return
	if _visual_node == null:
		var angle := _facing.angle()
		var base_color := color
		var scale := body_radius / (10.0 if unit_kind == "vehicle" else 8.0)
		var hull := _get_hull_points()
		var shadow_color := Color(0.0, 0.0, 0.0, 0.22)
		draw_circle(Vector2(2.0, 3.0), body_radius * 0.95, shadow_color)
		var base_points := _transform_points(hull, angle, scale)
		var top_points := _transform_points(hull, angle, scale * 0.7, Vector2(-1.0, -1.0))
		draw_colored_polygon(base_points, _shade(base_color, -0.12))
		draw_colored_polygon(top_points, _shade(base_color, 0.12))
		var outline := base_points.duplicate()
		if outline.size() > 0:
			outline.append(base_points[0])
			draw_polyline(outline, _shade(base_color, -0.35), 1.5)
		if unit_kind == "vehicle":
			_draw_vehicle_details(angle, base_color)
		else:
			_draw_infantry_details(angle, base_color)
	if is_selected:
		draw_circle(Vector2.ZERO, body_radius + 5.0, Color(0.2, 0.9, 1.0, 0.6), false, 2.0)

func set_render_2d(value: bool) -> void:
	render_2d = value
	_set_canvas_children_visible(value)
	queue_redraw()

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("Unit: missing visual scene at %s" % visual_scene_path)
		return
	if packed is PackedScene:
		var instance = packed.instantiate()
		if instance is Node2D:
			_visual_node = instance
			add_child(_visual_node)
			_visual_node.visible = render_2d
			_update_visual_transform()
			_update_visual_color()
	else:
		push_warning("Unit: visual scene is not a PackedScene at %s" % visual_scene_path)

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	_visual_node.position = visual_offset
	if visual_base_radius > 0.0:
		var scale := body_radius / visual_base_radius
		_visual_node.scale = Vector2.ONE * scale

func _update_visual_color() -> void:
	if _visual_node == null:
		return
	_visual_node.modulate = color

func _sync_visual_rotation() -> void:
	if _visual_node == null:
		return
	_visual_node.rotation = _facing.angle()

func _update_aircraft_state(delta: float) -> void:
	_refresh_aircraft_squad_state()
	var missile_target := _find_aircraft_missile_target()
	var gun_target := _find_attack_target()
	if aircraft_squad_enabled:
		if _is_aircraft_squad_leader() and missile_target == null and _aircraft_squad_has_missiles():
			missile_target = _find_aircraft_missile_target(true)
		if _is_aircraft_squad_leader():
			var shared := missile_target if missile_target != null else gun_target
			_set_aircraft_squad_target(shared)
		else:
			var shared := _get_aircraft_squad_target()
			if shared != null:
				missile_target = shared
				gun_target = shared
	_set_aircraft_speed(1.0, false)
	_update_aircraft_loiter_reload(delta, missile_target, gun_target)
	# Update retreat timer
	if _aircraft_retreat_timer > 0.0:
		_aircraft_retreat_timer -= delta
	if _update_aircraft_reload(delta):
		_aircraft_missile_lock_timer = 0.0
		_aircraft_missile_lock_id = 0
		_sync_visual_rotation()
		return
	if _update_aircraft_takeoff(delta):
		_aircraft_missile_lock_timer = 0.0
		_aircraft_missile_lock_id = 0
		_sync_visual_rotation()
		return
	_update_aircraft_missile_lock(delta, missile_target)
	aircraft_altitude_factor = 1.0
	_aircraft_landing_on_path = false
	_aircraft_landing_taxi = false
	aircraft_circulating = false
	var fired := false
	var gun_in_range := gun_target != null and _aircraft_gun_target_in_range(gun_target)
	if missile_target != null:
		_face_aircraft_toward(missile_target.global_position, delta)
		if _aircraft_missile_lock_timer >= aircraft_missile_lock_time and _can_fire_aircraft_missile():
			_fire_aircraft_missile(missile_target)
			_aircraft_missile_lock_timer = 0.0
			fired = true
	if not fired and gun_target != null and aircraft_gun_ammo > 0 and gun_in_range:
		_face_aircraft_toward(gun_target.global_position, delta)
		_fire_aircraft_gun(gun_target)
		fired = true
	if manual_active or _hold_active:
		var manual_target_pos := _resolve_target()
		if manual_target_pos != Vector2.ZERO:
			_move_toward_aircraft_target(manual_target_pos, delta)
	elif _aircraft_retreat_timer > 0.0:
		# Retreat after firing missile - fly away from target
		_set_aircraft_speed(aircraft_engage_speed_mult, true)
		if _aircraft_retreat_direction != Vector2.ZERO:
			var retreat_target := global_position + (_aircraft_retreat_direction * 1000.0)
			_move_toward_aircraft_target(retreat_target, delta)
		else:
			_move_toward_aircraft_loiter(delta)
	elif missile_target != null and _aircraft_missile_lock_timer < aircraft_missile_lock_time:
		_set_aircraft_speed(aircraft_engage_speed_mult, true)
		_move_toward_aircraft_target(missile_target.global_position, delta)
	elif missile_target == null and gun_target == null:
		aircraft_circulating = true
		_set_aircraft_speed(aircraft_circulate_speed_mult, false)
		_move_toward_aircraft_perimeter(delta)
	elif gun_target != null and aircraft_gun_ammo > 0:
		if global_position.distance_to(gun_target.global_position) > attack_range * 0.9:
			_set_aircraft_speed(aircraft_engage_speed_mult, true)
			_move_toward_aircraft_target(gun_target.global_position, delta)
	elif missile_target != null and aircraft_gun_ammo > 0 and aircraft_missile_ammo <= 0:
		_set_aircraft_speed(aircraft_engage_speed_mult, true)
		_move_toward_aircraft_target(missile_target.global_position, delta)
	else:
		_move_toward_aircraft_loiter(delta)
	_sync_visual_rotation()

func _update_aircraft_reload(delta: float) -> bool:
	var needs_reload := _aircraft_force_reload or aircraft_missile_ammo <= 0  # Reload when missiles depleted
	if not _aircraft_reloading and not needs_reload:
		return false
	if not _aircraft_reloading:
		_aircraft_reloading = true
		_aircraft_reload_timer = 0.0
		_aircraft_landing_on_path = false
		_aircraft_landing_taxi = false
		_aircraft_takeoff_active = false
		_aircraft_takeoff_taxi = false
		manual_active = false
		manual_target = Vector2.ZERO
		_hold_active = false
		_hold_timer = 0.0
		_hold_pos = Vector2.ZERO
	var home := _get_aircraft_home_pos()
	var distance := global_position.distance_to(home)
	if aircraft_home != null and is_instance_valid(aircraft_home) and aircraft_landing_cap > 0:
		if not _aircraft_landing_reserved:
			if not _reserve_landing_slot():
				aircraft_altitude_factor = 1.0
				_move_toward_aircraft_queue(delta, home, _get_airfield_queue_radius())
				return true
	var landing_path := _get_airfield_landing_path(home)
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
	var path_length := float(landing_path.get("length", aircraft_landing_path_length))
	var entry_radius := maxf(aircraft_landing_path_entry_radius, aircraft_landing_radius * 2.0)
	manual_active = false
	manual_target = Vector2.ZERO
	if not _aircraft_landing_on_path:
		if global_position.distance_to(start) > entry_radius:
			aircraft_altitude_factor = 1.0
			_move_toward_position(start, delta)
			return true
		_aircraft_landing_on_path = true
	var landing_radius := maxf(0.5, aircraft_landing_radius)
	if not _aircraft_landing_taxi:
		_move_toward_position(rollout, delta)
		var remaining := maxf(0.0, (global_position - touchdown).dot(path_dir))
		aircraft_altitude_factor = clampf(remaining / maxf(1.0, path_length), 0.0, 1.0)
		if global_position.distance_to(rollout) > landing_radius:
			_aircraft_reload_timer = 0.0
			return true
		_aircraft_landing_taxi = true
	aircraft_altitude_factor = 0.0
	_move_toward_position(slot, delta)
	if global_position.distance_to(slot) > landing_radius:
		_aircraft_reload_timer = 0.0
		return true
	if _aircraft_reload_timer <= 0.0:
		_aircraft_reload_timer = aircraft_reload_time
	_aircraft_reload_timer -= delta
	if _aircraft_reload_timer <= 0.0:
		_reload_aircraft_ammo()
		_aircraft_reloading = false
		_aircraft_reload_timer = 0.0
		_aircraft_force_reload = false
		_aircraft_no_missile_timer = 0.0
		_aircraft_landing_on_path = false
		_release_landing_slot()
		_reached_rally = false
		_aircraft_takeoff_active = true
		_aircraft_takeoff_taxi = false
	return true

func _update_aircraft_takeoff(delta: float) -> bool:
	if not _aircraft_takeoff_active:
		return false
	if aircraft_home == null or not is_instance_valid(aircraft_home):
		_aircraft_takeoff_active = false
		_aircraft_takeoff_taxi = false
		return false
	var home := _get_aircraft_home_pos()
	var landing_path: Dictionary = _get_airfield_landing_path(home)
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
	var path_dir := Vector2.RIGHT
	var dir_value: Variant = landing_path.get("dir", Vector2.RIGHT)
	if dir_value is Vector2:
		path_dir = dir_value
	var path_length := float(landing_path.get("length", aircraft_landing_path_length))
	var landing_radius := maxf(0.5, aircraft_landing_radius)
	if not _aircraft_takeoff_taxi:
		aircraft_altitude_factor = 0.0
		_move_toward_position(rollout, delta)
		if global_position.distance_to(rollout) > landing_radius:
			return true
		_aircraft_takeoff_taxi = true
	_move_toward_position(start, delta)
	var traveled := maxf(0.0, (global_position - rollout).dot(path_dir))
	aircraft_altitude_factor = clampf(traveled / maxf(1.0, path_length), 0.0, 1.0)
	if global_position.distance_to(start) > landing_radius and aircraft_altitude_factor < 1.0:
		return true
	_aircraft_takeoff_active = false
	_aircraft_takeoff_taxi = false
	aircraft_altitude_factor = 1.0
	return true

func _get_aircraft_home_pos() -> Vector2:
	if aircraft_home != null and is_instance_valid(aircraft_home):
		return aircraft_home.global_position
	if aircraft_home_pos != Vector2.ZERO:
		return aircraft_home_pos
	return home_pos

func _reload_aircraft_ammo() -> void:
	aircraft_missile_ammo = maxi(0, aircraft_missile_capacity)
	aircraft_gun_ammo = maxi(0, aircraft_gun_capacity)
	_aircraft_force_reload = false
	_aircraft_no_missile_timer = 0.0

func _update_aircraft_loiter_reload(delta: float, missile_target: Node2D, gun_target: Node2D) -> void:
	if _aircraft_reloading:
		_aircraft_no_missile_timer = 0.0
		_aircraft_force_reload = false
		return
	if aircraft_missile_ammo > 0:
		_aircraft_no_missile_timer = 0.0
		_aircraft_force_reload = false
		return
	if manual_active or _hold_active:
		_aircraft_no_missile_timer = 0.0
		_aircraft_force_reload = false
		return
	if missile_target != null or gun_target != null:
		_aircraft_no_missile_timer = 0.0
		return
	if aircraft_loiter_reload_delay <= 0.0:
		_aircraft_force_reload = true
		return
	_aircraft_no_missile_timer += delta
	if _aircraft_no_missile_timer >= aircraft_loiter_reload_delay:
		_aircraft_force_reload = true

func _update_aircraft_missile_lock(delta: float, missile_target: Node2D) -> void:
	if manual_active or _hold_active or _aircraft_takeoff_active:
		_aircraft_missile_lock_timer = 0.0
		_aircraft_missile_lock_id = 0
		return
	if missile_target == null or not is_instance_valid(missile_target):
		_aircraft_missile_lock_timer = 0.0
		_aircraft_missile_lock_id = 0
		return
	var target_id := int(missile_target.get_instance_id())
	if target_id != _aircraft_missile_lock_id:
		_aircraft_missile_lock_id = target_id
		_aircraft_missile_lock_timer = 0.0
		return
	_aircraft_missile_lock_timer = minf(
		aircraft_missile_lock_time,
		_aircraft_missile_lock_timer + delta
	)

func _get_aircraft_squad_home() -> Node2D:
	if not aircraft_squad_enabled:
		return null
	if aircraft_home == null or not is_instance_valid(aircraft_home):
		return null
	return aircraft_home

func _get_aircraft_squad_member_ids() -> Array:
	var home := _get_aircraft_squad_home()
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
		var unit := inst as Unit
		if unit.unit_kind != "aircraft":
			continue
		if unit.aircraft_home != home:
			continue
		cleaned.append(id)
	if cleaned.size() != members.size():
		home.set_meta("air_squad_members", cleaned)
	return cleaned

func _register_aircraft_squad() -> void:
	var home := _get_aircraft_squad_home()
	if home == null:
		return
	var members := _get_aircraft_squad_member_ids()
	var id := get_instance_id()
	if not members.has(id):
		members.append(id)
		home.set_meta("air_squad_members", members)
	if not home.has_meta("air_squad_fire_index"):
		home.set_meta("air_squad_fire_index", 0)
	_refresh_aircraft_squad_state()

func _unregister_aircraft_squad() -> void:
	var home := _get_aircraft_squad_home()
	if home == null:
		return
	var members := _get_aircraft_squad_member_ids()
	var id := get_instance_id()
	if members.has(id):
		members.erase(id)
		home.set_meta("air_squad_members", members)
	if members.is_empty():
		home.set_meta("air_squad_target_id", 0)
		home.set_meta("air_squad_fire_index", 0)
	_aircraft_squad_index = -1
	_aircraft_squad_leader_id = 0

func _refresh_aircraft_squad_state() -> void:
	var members := _get_aircraft_squad_member_ids()
	if members.is_empty():
		_aircraft_squad_index = -1
		_aircraft_squad_leader_id = 0
		return
	_aircraft_squad_leader_id = int(members[0])
	_aircraft_squad_index = members.find(get_instance_id())

func _is_aircraft_squad_leader() -> bool:
	return _aircraft_squad_leader_id == get_instance_id()

func _get_aircraft_squad_leader() -> Unit:
	if _aircraft_squad_leader_id <= 0:
		return null
	var inst := instance_from_id(_aircraft_squad_leader_id)
	if inst is Unit:
		return inst as Unit
	return null

func _set_aircraft_squad_target(target: Node2D) -> void:
	var home := _get_aircraft_squad_home()
	if home == null:
		return
	if target == null or not is_instance_valid(target):
		home.set_meta("air_squad_target_id", 0)
		return
	home.set_meta("air_squad_target_id", target.get_instance_id())

func _get_aircraft_squad_target() -> Node2D:
	var home := _get_aircraft_squad_home()
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

func _get_aircraft_squad_missile_owner_id() -> int:
	var home := _get_aircraft_squad_home()
	if home == null:
		return get_instance_id()
	var members := _get_aircraft_squad_member_ids()
	if members.is_empty():
		return get_instance_id()
	var index := int(home.get_meta("air_squad_fire_index", 0))
	if index < 0 or index >= members.size():
		index = 0
	var current_id := int(members[index])
	var current := instance_from_id(current_id) as Unit
	if current != null and is_instance_valid(current) and current.aircraft_missile_ammo > 0:
		home.set_meta("air_squad_fire_index", index)
		return current_id
	for offset in range(1, members.size() + 1):
		var next_index := (index + offset) % members.size()
		var next_id := int(members[next_index])
		var next := instance_from_id(next_id) as Unit
		if next != null and is_instance_valid(next) and next.aircraft_missile_ammo > 0:
			home.set_meta("air_squad_fire_index", next_index)
			return next_id
	home.set_meta("air_squad_fire_index", index)
	return current_id

func _aircraft_can_fire_squad_missile() -> bool:
	if not aircraft_squad_enabled:
		return true
	return _get_aircraft_squad_missile_owner_id() == get_instance_id()

func _advance_aircraft_squad_fire_index() -> void:
	var home := _get_aircraft_squad_home()
	if home == null:
		return
	var members := _get_aircraft_squad_member_ids()
	if members.is_empty():
		return
	var index := int(home.get_meta("air_squad_fire_index", 0))
	if index < 0 or index >= members.size():
		index = 0
	for offset in range(1, members.size() + 1):
		var next_index := (index + offset) % members.size()
		var next_id := int(members[next_index])
		var next := instance_from_id(next_id) as Unit
		if next != null and is_instance_valid(next) and next.aircraft_missile_ammo > 0:
			home.set_meta("air_squad_fire_index", next_index)
			return
	home.set_meta("air_squad_fire_index", index)

func _aircraft_squad_has_missiles() -> bool:
	if not aircraft_squad_enabled:
		return aircraft_missile_ammo > 0
	var members := _get_aircraft_squad_member_ids()
	for member_id in members:
		var unit := instance_from_id(int(member_id)) as Unit
		if unit != null and is_instance_valid(unit) and unit.aircraft_missile_ammo > 0:
			return true
	return false

func _get_incoming_aircraft_missiles() -> Dictionary:
	var incoming := {}
	for node in get_tree().get_nodes_in_group("missiles"):
		var missile := node as Missile
		if missile == null or not is_instance_valid(missile):
			continue
		if missile.team_id != team_id:
			continue
		if str(missile.source_kind) != "aircraft":
			continue
		var target := missile.target
		if target == null or not is_instance_valid(target):
			continue
		var target_id := int(target.get_instance_id())
		incoming[target_id] = int(incoming.get(target_id, 0)) + 1
	return incoming

func _find_aircraft_missile_target(ignore_ammo: bool = false) -> Node2D:
	if aircraft_missile_ammo <= 0 and not ignore_ammo:
		return null
	var range := aircraft_missile_range
	var range_sq := range * range if range > 0.0 else INF
	var incoming := _get_incoming_aircraft_missiles()
	var focus_limit := maxi(1, aircraft_missile_focus_limit)
	var best: Node2D = null
	var best_priority := 999
	var best_dist := range_sq
	var fallback: Node2D = null
	var fallback_priority := 999
	var fallback_dist := range_sq
	var groups := ["units", "building", "hq"]
	for group_name in groups:
		for node in get_tree().get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node):
				continue
			if node is not Node2D:
				continue
			if node is Unit and (node as Unit).team_id == team_id:
				continue
			if node is Building and (node as Building).team_id == team_id:
				continue
			if node is HQ and (node as HQ).team_id == team_id:
				continue
			if node is CanvasItem and not (node as CanvasItem).visible:
				continue
			var dist := global_position.distance_squared_to((node as Node2D).global_position)
			if range > 0.0 and dist > range_sq:
				continue
			var priority := _aircraft_target_priority(node as Node2D)
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

func _aircraft_target_priority(target: Node2D) -> int:
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

func _aircraft_gun_target_in_range(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var range := attack_range
	if vision_radius > 0.0:
		if range > 0.0:
			range = minf(range, vision_radius)
		else:
			range = vision_radius
	if range <= 0.0:
		return true
	return global_position.distance_squared_to(target.global_position) <= range * range

func _can_fire_aircraft_missile() -> bool:
	return aircraft_missile_ammo > 0 and _aircraft_missile_timer <= 0.0 and _aircraft_can_fire_squad_missile()

func _fire_aircraft_missile(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var missile := Missile.new()
	missile.speed = aircraft_missile_speed
	missile.damage = aircraft_missile_damage
	missile.turn_rate = aircraft_missile_turn_rate
	missile.lifetime = aircraft_missile_lifetime
	missile.warhead_size = aircraft_missile_warhead_size
	if aircraft_missile_hit_radius > 0.0:
		missile.hit_radius = aircraft_missile_hit_radius
	if aircraft_missile_splash_radius > 0.0:
		missile.splash_radius = aircraft_missile_splash_radius
	missile.splash_damage_scale = aircraft_missile_splash_scale
	if aircraft_missile_range > 0.0:
		missile.range = aircraft_missile_range
		missile.max_distance = aircraft_missile_range
	missile.team_id = team_id
	missile.color = aircraft_missile_color
	missile.source_kind = "aircraft"
	missile.source_altitude = aircraft_altitude_factor
	missile.target = target
	missile.global_position = global_position + (_facing * (body_radius + 6.0))
	missile.set_origin(global_position)
	if missile_visual_path != "":
		missile.visual_scene_path = missile_visual_path
		missile.visual_base_radius = 10.0
	if get_parent() != null:
		get_parent().add_child(missile)
	_aircraft_retreat_timer = aircraft_retreat_duration  # Start retreat after firing
	# Set retreat direction: turn 120-180 degrees away from target
	var to_target := (target.global_position - global_position).normalized()
	var retreat_angle := randf_range(2.094, PI)  # 120 to 180 degrees
	if randf() < 0.5:
		retreat_angle = -retreat_angle
	_aircraft_retreat_direction = to_target.rotated(retreat_angle)
	aircraft_missile_ammo = maxi(0, aircraft_missile_ammo - 1)
	_aircraft_missile_timer = aircraft_missile_cooldown
	if aircraft_missile_ammo <= 0:
		_advance_aircraft_squad_fire_index()

func _fire_aircraft_gun(target: Node) -> void:
	if aircraft_gun_ammo <= 0 or _cooldown > 0.0:
		return
	if target.has_method("take_damage"):
		var final_damage := attack_damage
		if target is Unit:
			var enemy := target as Unit
			if enemy.unit_kind == "vehicle" or enemy.unit_kind == "aircraft":
				final_damage *= damage_vs_vehicle
			else:
				final_damage *= damage_vs_infantry
		elif target is Building or target is HQ:
			final_damage *= damage_vs_structure
		target.take_damage(final_damage, unit_type)
	if shot_tracer_enabled and target is Node2D:
		var target_pos: Vector2 = (target as Node2D).global_position
		_spawn_tracer(target_pos)
		emit_signal("shot_fired", global_position, target_pos, shot_color, shot_width, shot_lifetime)
	_cooldown = attack_cooldown
	aircraft_gun_ammo = maxi(0, aircraft_gun_ammo - 1)

func _set_canvas_children_visible(value: bool) -> void:
	for child in get_children():
		if child is CanvasItem:
			child.visible = value

func _face_toward(pos: Vector2) -> void:
	var delta_vec := pos - global_position
	if delta_vec.length_squared() <= 0.1:
		return
	_facing = delta_vec.normalized()

func _face_aircraft_toward(pos: Vector2, delta: float) -> void:
	var delta_vec := pos - global_position
	if delta_vec.length_squared() <= 0.1:
		return
	var desired := delta_vec.normalized()
	if _aircraft_allow_instant_turn() or aircraft_turn_rate <= 0.0:
		_facing = desired
		return
	_facing = _apply_aircraft_turn(desired, delta)

func _shade(src: Color, amount: float) -> Color:
	return Color(
		clampf(src.r + amount, 0.0, 1.0),
		clampf(src.g + amount, 0.0, 1.0),
		clampf(src.b + amount, 0.0, 1.0),
		src.a
	)

func _transform_points(points: Array, angle: float, scale: float, offset := Vector2.ZERO) -> PackedVector2Array:
	var transformed := PackedVector2Array()
	for point in points:
		if point is Vector2:
			transformed.append((point * scale).rotated(angle) + offset)
	return transformed

func _get_hull_points() -> Array:
	if unit_kind == "vehicle":
		return [
			Vector2(11, 0),
			Vector2(7, -6),
			Vector2(-7, -6),
			Vector2(-11, 0),
			Vector2(-7, 6),
			Vector2(7, 6),
		]
	return [
		Vector2(8, 0),
		Vector2(3, -5),
		Vector2(-6, -4),
		Vector2(-8, 0),
		Vector2(-6, 4),
		Vector2(3, 5),
	]

func _draw_infantry_details(angle: float, base_color: Color) -> void:
	var weapon_len := body_radius * 0.9
	var weapon_width := 2.0
	if unit_type == "sniper":
		weapon_len = body_radius * 1.35
		weapon_width = 2.0
	elif unit_type == "rocket":
		weapon_len = body_radius * 1.05
		weapon_width = 3.0
	var weapon_color := _shade(base_color, 0.35)
	draw_line(Vector2.ZERO, Vector2(weapon_len, 0.0).rotated(angle), weapon_color, weapon_width)

func _draw_vehicle_details(angle: float, base_color: Color) -> void:
	var turret_radius := body_radius * 0.35
	var turret_color := _shade(base_color, 0.2)
	draw_circle(Vector2.ZERO, turret_radius, turret_color)
	draw_line(Vector2.ZERO, Vector2(body_radius * 0.9, 0.0).rotated(angle), _shade(base_color, 0.4), 2.5)
	var track_offset := Vector2(0.0, body_radius * 0.55).rotated(angle)
	var track_half := Vector2(body_radius * 0.7, 0.0).rotated(angle)
	draw_line(-track_offset - track_half, -track_offset + track_half, _shade(base_color, -0.25), 1.5)
	draw_line(track_offset - track_half, track_offset + track_half, _shade(base_color, -0.25), 1.5)

func _find_attack_target() -> Node2D:
	var unit_target := _find_enemy_unit_in_range(attack_range)
	if unit_target != null:
		return unit_target
	var structure_target := _find_enemy_structure_in_range(attack_range)
	if structure_target != null:
		return structure_target
	return null

func _find_enemy_unit_in_range(range: float) -> Node2D:
	var range_sq := range * range
	var best_target: Unit = null
	var best_priority := 999
	var best_dist := range_sq
	var best_hp := INF
	for node in get_tree().get_nodes_in_group("units"):
		if node == self:
			continue
		var enemy := node as Unit
		if enemy == null or enemy.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist > range_sq:
			continue
		var priority := _target_priority(enemy)
		var enemy_hp := enemy.hp
		if (
			priority < best_priority
			or (priority == best_priority and enemy_hp < best_hp)
			or (priority == best_priority and enemy_hp == best_hp and dist < best_dist)
		):
			best_priority = priority
			best_dist = dist
			best_hp = enemy_hp
			best_target = enemy
	return best_target

func _find_enemy_structure_in_range(range: float) -> Node2D:
	var range_sq := range * range
	var best_target: Node2D = null
	var best_dist := range_sq
	for node in get_tree().get_nodes_in_group("building"):
		if not (node is Building):
			continue
		if node.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(node.global_position)
		if dist <= best_dist:
			best_dist = dist
			best_target = node
	for node in get_tree().get_nodes_in_group("hq"):
		if not (node is HQ):
			continue
		if node.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(node.global_position)
		if dist <= best_dist:
			best_dist = dist
			best_target = node
	return best_target

func _attack(target: Node) -> void:
	if _cooldown > 0.0:
		return
	if target.has_method("take_damage"):
		var final_damage := attack_damage
		if target is Unit:
			var enemy := target as Unit
			if enemy.unit_kind == "vehicle" or enemy.unit_kind == "aircraft":
				final_damage *= damage_vs_vehicle
			else:
				final_damage *= damage_vs_infantry
		elif target is Building or target is HQ:
			final_damage *= damage_vs_structure
		target.take_damage(final_damage, unit_type)
	if shot_tracer_enabled and target is Node2D:
		var target_pos: Vector2 = (target as Node2D).global_position
		_spawn_tracer(target_pos)
		emit_signal("shot_fired", global_position, target_pos, shot_color, shot_width, shot_lifetime)
	_cooldown = attack_cooldown

func _spawn_tracer(target_pos: Vector2) -> void:
	var tracer := ShotTracer.new()
	tracer.duration = shot_lifetime
	tracer.width = shot_width
	tracer.color = shot_color
	tracer.set_points(global_position, target_pos)
	if get_parent() != null:
		get_parent().add_child(tracer)

func _move_toward_target(delta: float) -> void:
	var target := _resolve_target()
	if target == Vector2.ZERO:
		return
	var move_target := target
	var allow_completion := true
	if _should_use_navigation(target):
		move_target = _get_nav_move_target(target, delta)
		allow_completion = _nav_path.is_empty()
	_move_toward_position(move_target, delta, allow_completion)

func _move_toward_position(target: Vector2, delta: float, allow_completion: bool = true) -> void:
	var delta_vec := target - global_position
	if delta_vec.length() <= 1.0:
		if allow_completion:
			_clear_nav_path()
			if _hold_active:
				_hold_reached = true
				return
			if manual_active:
				manual_active = false
				manual_target = Vector2.ZERO
			elif not _reached_rally and rally_target != Vector2.ZERO:
				_reached_rally = true
				rally_target = Vector2.ZERO
		return
	var direction := delta_vec.normalized()
	if unit_kind == "aircraft" and not _aircraft_allow_instant_turn() and aircraft_turn_rate > 0.0:
		direction = _apply_aircraft_turn(direction, delta)
	var move_speed := speed
	if unit_kind == "aircraft":
		move_speed *= maxf(0.0, _aircraft_speed_mult)
	var step := direction * move_speed * delta
	if _should_limit_ground_slope():
		var sample_dist := step.length()
		if ground_slope_sample_distance > 0.0:
			sample_dist = maxf(sample_dist, ground_slope_sample_distance)
		if sample_dist > 0.0:
			var sample_pos := global_position + direction * sample_dist
			if _is_uphill_too_steep(global_position, sample_pos):
				_facing = direction
				return
	global_position += step
	_facing = direction

func _move_toward_aircraft_target(target: Vector2, delta: float) -> void:
	var adjusted := _get_aircraft_formation_target(target)
	_move_toward_position(adjusted, delta)

func _set_aircraft_speed(mult: float, afterburner: bool) -> void:
	_aircraft_speed_mult = maxf(0.0, mult)
	aircraft_afterburner_active = afterburner

func _aircraft_allow_instant_turn() -> bool:
	return _aircraft_landing_on_path or _aircraft_landing_taxi or _aircraft_takeoff_active

func _should_limit_ground_slope() -> bool:
	return unit_kind != "aircraft" and ground_slope_max_deg > 0.0

func _is_uphill_too_steep(from_pos: Vector2, to_pos: Vector2) -> bool:
	var delta := to_pos - from_pos
	var dist := delta.length()
	if dist <= 0.001:
		return false
	var height_from := _get_ground_height(from_pos)
	var height_to := _get_ground_height(to_pos)
	if not is_finite(height_from) or not is_finite(height_to):
		return false
	if height_to <= height_from:
		return false
	var slope := (height_to - height_from) / dist
	var max_slope := tan(deg_to_rad(ground_slope_max_deg))
	return slope > max_slope

func _get_ground_height(pos: Vector2) -> float:
	var provider := _get_ground_height_provider()
	if provider != null and provider.has_method("get_ground_height_at"):
		var value: Variant = provider.call("get_ground_height_at", pos)
		if value is float or value is int:
			return float(value)
	return 0.0

func _get_ground_height_provider() -> Node:
	if _ground_height_provider != null and is_instance_valid(_ground_height_provider):
		return _ground_height_provider
	var providers := get_tree().get_nodes_in_group("ground_height_provider")
	if not providers.is_empty():
		_ground_height_provider = providers[0]
		return _ground_height_provider
	return null

func _should_use_navigation(target: Vector2) -> bool:
	return navigation_enabled and unit_kind != "aircraft" and target != Vector2.ZERO

func _get_nav_move_target(target: Vector2, delta: float) -> Vector2:
	_nav_repath_timer = maxf(0.0, _nav_repath_timer - delta)
	var needs_repath := _nav_path.is_empty() or _nav_target == Vector2.ZERO
	if not needs_repath and navigation_repath_distance > 0.0:
		needs_repath = _nav_target.distance_to(target) > navigation_repath_distance
	if needs_repath and _nav_repath_timer <= 0.0:
		_build_nav_path(target)
	_advance_nav_index()
	if _nav_path.is_empty():
		return target
	return _nav_path[_nav_index]

func _build_nav_path(target: Vector2) -> void:
	_nav_repath_timer = maxf(0.0, navigation_repath_interval)
	_nav_target = target
	_nav_index = 0
	_nav_path = PackedVector2Array()
	var provider := _get_nav_provider()
	if provider == null or not provider.has_method("get_navigation_path"):
		return
	var path_value: Variant = provider.call("get_navigation_path", global_position, target, navigation_layers, navigation_optimize)
	if path_value is PackedVector2Array:
		_nav_path = path_value
	elif path_value is Array:
		var converted := PackedVector2Array()
		for point in path_value:
			if point is Vector2:
				converted.append(point)
		_nav_path = converted
	_advance_nav_index()

func _advance_nav_index() -> void:
	if _nav_path.is_empty():
		return
	var reach_dist := maxf(1.0, navigation_point_reach_dist)
	while _nav_index < _nav_path.size() and global_position.distance_to(_nav_path[_nav_index]) <= reach_dist:
		_nav_index += 1
	if _nav_index >= _nav_path.size():
		_clear_nav_path()

func _clear_nav_path() -> void:
	_nav_path = PackedVector2Array()
	_nav_index = 0
	_nav_target = Vector2.ZERO

func _get_nav_provider() -> Node:
	if _nav_provider != null and is_instance_valid(_nav_provider):
		return _nav_provider
	var providers := get_tree().get_nodes_in_group("navigation_provider")
	if not providers.is_empty():
		_nav_provider = providers[0]
		return _nav_provider
	return null

func _apply_aircraft_turn(desired: Vector2, delta: float) -> Vector2:
	var desired_dir := desired.normalized()
	if _facing.length_squared() <= 0.01:
		return desired_dir
	var angle := _facing.angle_to(desired_dir)
	var max_turn := aircraft_turn_rate * delta
	var clamped := clampf(angle, -max_turn, max_turn)
	var turned := _facing.rotated(clamped)
	if turned.length_squared() <= 0.01:
		return desired_dir
	return turned.normalized()

func _should_use_aircraft_formation() -> bool:
	return unit_kind == "aircraft" and aircraft_squad_enabled and _aircraft_squad_index > 0

func _get_aircraft_formation_offset_local() -> Vector2:
	if _aircraft_squad_index <= 0:
		return Vector2.ZERO
	var row := int((_aircraft_squad_index - 1) / 2) + 1
	var side := -1 if (_aircraft_squad_index % 2) == 1 else 1
	var back := float(row) * aircraft_squad_spacing
	var lateral := float(row) * aircraft_squad_spacing * aircraft_squad_lateral_ratio
	return Vector2(-back, lateral * float(side))

func _get_aircraft_formation_target(base: Vector2) -> Vector2:
	if not _should_use_aircraft_formation():
		return base
	var leader := _get_aircraft_squad_leader()
	if leader == null or not is_instance_valid(leader):
		return base
	var dir := base - leader.global_position
	if dir.length_squared() <= 0.01:
		dir = leader._facing
	if dir.length_squared() <= 0.01:
		dir = Vector2.RIGHT
	var forward := dir.normalized()
	var right := Vector2(-forward.y, forward.x)
	var offset := _get_aircraft_formation_offset_local()
	return base + (forward * offset.x) + (right * offset.y)

func _move_toward_aircraft_loiter(delta: float) -> void:
	_move_toward_aircraft_orbit(aircraft_loiter_pos, aircraft_loiter_radius, delta)

func _move_toward_aircraft_perimeter(delta: float) -> void:
	var perimeter: Dictionary = _get_team_vision_perimeter()
	if not perimeter.is_empty():
		var center_value = perimeter.get("center", Vector2.ZERO)
		var radius_value = perimeter.get("radius", 0.0)
		if center_value is Vector2 and (radius_value is float or radius_value is int):
			var center: Vector2 = center_value
			var radius := float(radius_value)
			_move_toward_aircraft_orbit(center, radius, delta)
			return
	_move_toward_aircraft_loiter(delta)

func _move_toward_aircraft_orbit(center: Vector2, radius: float, delta: float) -> void:
	if center == Vector2.ZERO:
		return
	var orbit_center := _get_aircraft_formation_target(center)
	var use_radius := maxf(0.0, radius) * maxf(0.1, aircraft_orbit_radius_scale)
	_aircraft_loiter_angle = fmod(_aircraft_loiter_angle + (aircraft_loiter_orbit_speed * delta), TAU)
	var angle := _aircraft_loiter_angle
	var wobble_amp := use_radius * maxf(0.0, aircraft_orbit_wobble_ratio)
	var wobble := 0.0
	if wobble_amp > 0.0 and aircraft_orbit_wobble_speed > 0.0:
		wobble = sin((angle * aircraft_orbit_wobble_speed) + _aircraft_orbit_phase) * wobble_amp
	var orbit_target := orbit_center + Vector2(cos(angle), sin(angle)) * (use_radius + wobble)
	if aircraft_circulating and aircraft_circulation_spread_enabled:
		orbit_target += _get_aircraft_circulation_offset()
	_move_toward_position(orbit_target, delta)

func _get_aircraft_circulation_offset() -> Vector2:
	var min_spacing := maxf(0.0, aircraft_circulation_spacing)
	var avoid_radius := maxf(min_spacing, aircraft_circulation_avoid_radius)
	if min_spacing <= 0.0 or avoid_radius <= 0.0:
		return Vector2.ZERO
	var push := Vector2.ZERO
	var count := 0
	var radius_sq := avoid_radius * avoid_radius
	for node in get_tree().get_nodes_in_group("units"):
		var other := node as Unit
		if other == null or other == self:
			continue
		if other.unit_kind != "aircraft" or other.team_id != team_id:
			continue
		if not other.aircraft_circulating:
			continue
		var delta := global_position - other.global_position
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
	var max_push := min_spacing * maxf(0.0, aircraft_circulation_avoid_strength)
	if push.length() > max_push:
		push = push.normalized() * max_push
	return push

func _move_toward_aircraft_queue(delta: float, center: Vector2, radius: float) -> void:
	if center == Vector2.ZERO:
		return
	var use_radius := maxf(0.0, radius)
	_aircraft_loiter_angle = fmod(_aircraft_loiter_angle + (aircraft_loiter_orbit_speed * delta), TAU)
	var orbit_target := center + Vector2(cos(_aircraft_loiter_angle), sin(_aircraft_loiter_angle)) * use_radius
	_move_toward_position(orbit_target, delta)

func _get_airfield_queue_radius() -> float:
	if aircraft_queue_radius > 0.0:
		return aircraft_queue_radius
	if aircraft_home != null and is_instance_valid(aircraft_home):
		var size_value: Variant = aircraft_home.get("size")
		if size_value is Vector2:
			var size: Vector2 = size_value
			return maxf(size.x, size.y) * 0.65
	return maxf(aircraft_reload_radius * 1.2, aircraft_loiter_radius)

func _get_team_vision_perimeter() -> Dictionary:
	var group_name := ""
	if team_id == "p1":
		group_name = "vision_p1"
	if group_name == "":
		return {}
	var nodes: Array = get_tree().get_nodes_in_group(group_name)
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
	if aircraft_perimeter_forward_bias > 0.0 and enemy_hq != null and is_instance_valid(enemy_hq):
		var bias := clampf(aircraft_perimeter_forward_bias, 0.0, 1.0)
		var enemy_pos := enemy_hq.global_position
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
	max_radius += maxf(0.0, aircraft_perimeter_padding)
	return {
		"center": center,
		"radius": max_radius,
	}

func _get_airfield_size() -> Vector2:
	if aircraft_home != null and is_instance_valid(aircraft_home):
		var size_value: Variant = aircraft_home.get("size")
		if size_value is Vector2:
			return size_value
	return Vector2.ZERO

func _get_airfield_runway_dir() -> Vector2:
	if team_id == "p2":
		return Vector2(-1.0, 0.0)
	return Vector2(1.0, 0.0)

func _get_airfield_runway_offset(size2d: Vector2) -> Vector2:
	if size2d == Vector2.ZERO:
		return Vector2.ZERO
	var runway_dir := _get_airfield_runway_dir()
	if runway_dir.length_squared() <= 0.0:
		runway_dir = Vector2.RIGHT
	var lateral := Vector2(-runway_dir.y, runway_dir.x).normalized()
	return lateral * (size2d.y * aircraft_runway_offset_ratio)

func _get_airfield_landing_slot_offset(size2d: Vector2, runway_dir: Vector2) -> Vector2:
	if _aircraft_landing_slot < 0:
		return Vector2.ZERO
	var slot_count := maxi(1, aircraft_landing_cap)
	if slot_count <= 1:
		return Vector2.ZERO
	var lateral := Vector2(-runway_dir.y, runway_dir.x)
	if lateral.length_squared() <= 0.0:
		return Vector2.ZERO
	lateral = lateral.normalized()
	var spacing := aircraft_landing_slot_spacing
	if spacing <= 0.0:
		spacing = maxf(body_radius * 2.6, aircraft_landing_radius * 6.0)
	if size2d != Vector2.ZERO:
		var max_spacing := (size2d.y * 0.6) / float(slot_count - 1)
		spacing = minf(spacing, max_spacing)
	var slot_index := clampi(_aircraft_landing_slot, 0, slot_count - 1)
	var center_index := float(slot_count - 1) * 0.5
	var offset_amount := (float(slot_index) - center_index) * spacing
	return lateral * offset_amount

func _get_airfield_landing_path(home: Vector2) -> Dictionary:
	var size2d := _get_airfield_size()
	var runway_dir := _get_airfield_runway_dir().normalized()
	if runway_dir.length_squared() <= 0.0:
		runway_dir = Vector2.RIGHT
	var offset := _get_airfield_runway_offset(size2d)
	var touchdown := home + offset
	if size2d != Vector2.ZERO:
		touchdown = home + (runway_dir * (size2d.x * 0.5)) + offset
	var rollout := home + offset
	var slot_offset := _get_airfield_landing_slot_offset(size2d, runway_dir)
	var slot := rollout + slot_offset
	var base_length := aircraft_landing_path_length
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
	if _aircraft_landing_reserved:
		return true
	if aircraft_landing_cap <= 0:
		_aircraft_landing_reserved = true
		return true
	if aircraft_home == null or not is_instance_valid(aircraft_home):
		_aircraft_landing_reserved = true
		return true
	var slot_map: Dictionary = {}
	var slot_value: Variant = aircraft_home.get_meta("aircraft_landing_slots", {})
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
	var slot_count := maxi(1, aircraft_landing_cap)
	for i in range(slot_count):
		if slot_map.has(i):
			continue
		slot_map[i] = get_instance_id()
		aircraft_home.set_meta("aircraft_landing_slots", slot_map)
		aircraft_home.set_meta("aircraft_landing", slot_map.size())
		_aircraft_landing_reserved = true
		_aircraft_landing_slot = i
		return true
	return false

func _release_landing_slot() -> void:
	if not _aircraft_landing_reserved:
		return
	_aircraft_landing_reserved = false
	if aircraft_home == null or not is_instance_valid(aircraft_home):
		_aircraft_landing_slot = -1
		return
	var slot_value: Variant = aircraft_home.get_meta("aircraft_landing_slots", {})
	if slot_value is Dictionary:
		var slot_map: Dictionary = slot_value.duplicate()
		var id := get_instance_id()
		if _aircraft_landing_slot >= 0 and slot_map.has(_aircraft_landing_slot):
			if int(slot_map.get(_aircraft_landing_slot, -1)) == id:
				slot_map.erase(_aircraft_landing_slot)
		else:
			for key in slot_map.keys():
				if int(slot_map.get(key, -1)) == id:
					slot_map.erase(key)
					break
		aircraft_home.set_meta("aircraft_landing_slots", slot_map)
		aircraft_home.set_meta("aircraft_landing", slot_map.size())
	else:
		var current := int(aircraft_home.get_meta("aircraft_landing", 0))
		if current > 0:
			aircraft_home.set_meta("aircraft_landing", current - 1)
	_aircraft_landing_slot = -1

func _release_airfield_slot() -> void:
	if aircraft_home == null or not is_instance_valid(aircraft_home):
		return
	var current = int(aircraft_home.get_meta("aircraft_active", 0))
	if current <= 0:
		return
	aircraft_home.set_meta("aircraft_active", current - 1)

func _release_airfield_f35() -> void:
	if unit_type != "f35":
		return
	if aircraft_home == null or not is_instance_valid(aircraft_home):
		return
	var current := int(aircraft_home.get_meta("f35_active", 0))
	if current == get_instance_id():
		aircraft_home.set_meta("f35_active", 0)

func _resolve_target() -> Vector2:
	if manual_active and manual_target != Vector2.ZERO:
		return manual_target
	if _hold_active:
		return _hold_pos
	var target := Vector2.ZERO
	if _chase_target != null and is_instance_valid(_chase_target):
		target = _chase_target.global_position
	elif _structure_target != null and is_instance_valid(_structure_target):
		target = _structure_target.global_position
	elif not _reached_rally and rally_target != Vector2.ZERO:
		target = rally_target
	elif enemy_hq != null and is_instance_valid(enemy_hq):
		target = enemy_hq.global_position
	else:
		target = target_pos
	if _is_combat_active() and _combat_offset != Vector2.ZERO:
		return target + _combat_offset
	return target

func issue_move(target: Vector2) -> void:
	manual_target = target
	manual_active = true
	_clear_nav_path()
	if unit_kind == "aircraft":
		aircraft_loiter_pos = target
	_hold_active = false
	_hold_timer = 0.0
	_hold_pos = Vector2.ZERO
	_hold_reached = false
	_chase_target = null

func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

func _update_chase_target() -> void:
	if _chase_target != null:
		if not is_instance_valid(_chase_target):
			_chase_target = null
		else:
			var dist := global_position.distance_to(_chase_target.global_position)
			if dist > chase_leash:
				_chase_target = null
	if _chase_target == null:
		_chase_target = _find_enemy_in_aggro()

func _update_structure_target() -> void:
	if _chase_target != null and is_instance_valid(_chase_target):
		_structure_target = null
		return
	if structure_aggro_range <= 0.0:
		_structure_target = null
		return
	if _structure_target != null:
		if not is_instance_valid(_structure_target):
			_structure_target = null
		else:
			var dist := global_position.distance_to(_structure_target.global_position)
			if dist > structure_aggro_range:
				_structure_target = null
	if _structure_target == null:
		_structure_target = _find_enemy_structure_in_range(structure_aggro_range)

func _find_enemy_in_aggro() -> Node2D:
	return _find_enemy_unit_in_range(aggro_range)

func _target_priority(enemy: Unit) -> int:
	var priority := 0
	if range_role == "long":
		if enemy.range_role == "short":
			priority = 1
		elif enemy.range_role == "mid":
			priority = 2
		else:
			priority = 0
	if prefers_vehicle and (enemy.unit_kind == "vehicle" or enemy.unit_kind == "aircraft"):
		priority -= 2
	if prefers_infantry and enemy.unit_kind == "infantry":
		priority -= 2
	return priority

func _update_combat_spread(delta: float) -> void:
	if not combat_spread_enabled:
		_combat_offset = Vector2.ZERO
		_combat_timer = 0.0
		return
	if not _is_combat_active():
		_combat_offset = Vector2.ZERO
		_combat_timer = 0.0
		return
	_combat_timer -= delta
	if _combat_timer > 0.0:
		return
	var max_radius := _get_combat_spread_radius()
	var angle := _combat_rng.randf_range(0.0, TAU)
	var radius := sqrt(_combat_rng.randf()) * max_radius
	_combat_offset = Vector2(cos(angle), sin(angle)) * radius
	_combat_timer = _combat_rng.randf_range(combat_spread_min_interval, combat_spread_max_interval)

func _get_combat_spread_radius() -> float:
	var scaled := combat_spread_radius * sqrt(maxf(1.0, range_multiplier))
	var cap := maxf(12.0, attack_range * 0.6)
	return minf(scaled, cap)

func _is_combat_active() -> bool:
	if manual_active:
		return false
	if _chase_target != null and is_instance_valid(_chase_target):
		return true
	if _structure_target != null and is_instance_valid(_structure_target):
		return true
	return false

func assign_hold(pos: Vector2, duration: float) -> void:
	_hold_active = true
	_hold_timer = duration
	_hold_pos = pos
	_hold_reached = false
	_chase_target = null
	_structure_target = null

func _update_hold(delta: float) -> void:
	if not _hold_active:
		return
	if not _hold_reached:
		if global_position.distance_to(_hold_pos) <= 4.0:
			_hold_reached = true
		return
	_hold_timer -= delta
	if _hold_timer <= 0.0:
		_hold_active = false
		_hold_timer = 0.0
		_hold_pos = Vector2.ZERO
		_hold_reached = false
