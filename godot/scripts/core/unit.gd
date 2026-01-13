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
@export var missile_visual_path := ""

@export var aircraft_missile_capacity := 2
@export var aircraft_gun_capacity := 0  # Guns disabled for aircraft
@export var aircraft_reload_time := 15.0  # Increased from 7.0 for more realistic rearm time
@export var aircraft_missile_range := 2500.0  # Reduced from 12000
@export var aircraft_missile_speed := 520.0
@export var aircraft_missile_turn_rate := 6.0
@export var aircraft_missile_damage := 32.0
@export var aircraft_missile_cooldown := 2.4
@export var aircraft_missile_lock_time := 0.25  # Reduced by 50% from 0.5 for faster engagement
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
@export var aircraft_retreat_duration := 8.0  # Increased from 5.0 - includes 5s retreat + 3s cooldown
@export var aircraft_turn_rate := 2.2
@export var aircraft_circulate_speed_mult := 3.0
@export var aircraft_engage_speed_mult := 4.0
@export var aircraft_min_engagement_distance := 400.0  # Minimum safe distance when engaging
@export var aircraft_retreat_after_gun := true  # Retreat after gun run
@export var aircraft_circulation_spread_enabled := true
@export var aircraft_circulation_spacing := 16.0
@export var aircraft_circulation_avoid_radius := 28.0
@export var aircraft_circulation_avoid_strength := 0.8
@export var aircraft_landing_radius := 2.0
@export var aircraft_landing_path_length := 720.0
@export var aircraft_landing_path_entry_radius := 18.0
@export var aircraft_runway_offset_ratio := 0.0
@export var aircraft_landing_slot_spacing := 32.0
@export var aircraft_landing_cap := 4
@export var aircraft_queue_radius := 0.0
@export var aircraft_squad_enabled := false  # Disabled - each plane fires independently
@export var aircraft_squad_spacing := 80.0
@export var aircraft_squad_lateral_ratio := 0.6

@export var vehicle_turn_rate := 3.0  # Radians per second for ground vehicles (0 = instant)

@export var is_uav := false  # UAV reconnaissance drone (no weapons, just vision)
@export var is_himars := false
@export var bombardment_range := 800.0
@export var bombardment_missile_damage := 80.0
@export var bombardment_missile_speed := 400.0
@export var bombardment_missile_lifetime := 12.0
@export var bombardment_missile_splash_radius := 60.0
@export var bombardment_missiles_per_salvo := 2
@export var bombardment_salvo_interval := 1.0
@export var bombardment_reload_time := 15.0

var hp := 0.0
var unit_kind := "infantry"
var _bombardment_ready := true
var _bombardment_cooldown := 0.0
var _bombardment_salvo_count := 0
var _bombardment_salvo_timer := 0.0
var _bombardment_salvo_target := Vector2.ZERO
var _bombardment_area_active := false
var _bombardment_area_target := Vector2.ZERO
var _himars_ground_marker: Node2D = null  # Visual marker on ground showing target area
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
var _aircraft_retreat_phase := 0  # 0 = turn away, 1 = arc back to airfield
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

# Aircraft behavior component (used when unit_kind == "aircraft")
var _aircraft_behavior: AircraftBehavior = null

# HIMARS Launcher Control
var _himars_launcher_node: Node3D = null
var _himars_visual_proxy: Node3D = null  # Reference to 3D visual for getting rotation
var _himars_launcher_angle := 0.0
var _himars_setup_timer := 0.0
var _himars_setup_done := false

# HIMARS Firing State Machine
enum HimarsState { IDLE, ROTATING, DEPLOYING, READY, FIRING, RETRACTING }
var _himars_state := HimarsState.IDLE
var _himars_state_timer := 0.0
var _himars_pending_target := Vector2.ZERO
var _himars_target_facing := Vector2.RIGHT  # Target _facing direction for rotation
var _himars_animation_player: AnimationPlayer = null
const HIMARS_DEPLOY_TIME_FALLBACK := 2.5  # Fallback if no animation found
const HIMARS_RETRACT_TIME_FALLBACK := 2.5  # Fallback if no animation found
const HIMARS_FIRE_DELAY := 0.5  # Delay after animation completes before first shot
const HIMARS_LAUNCHER_OFFSET_ANGLE := 45.0  # Launcher rotates 45 deg RIGHT during raise (degrees)
const HIMARS_ROTATION_SPEED := 3.0  # Radians per second for rotating to target
var _himars_animation_length := 2.5  # Will be set from actual animation

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
		# Create aircraft behavior component and delegate initialization
		_aircraft_behavior = AircraftBehavior.new(self)
		_aircraft_behavior.landing_reserved = _aircraft_landing_reserved
		_aircraft_behavior.landing_slot = _aircraft_landing_slot
		_aircraft_behavior.initialize()
		# Sync state back to unit for compatibility with existing visual sync code
		aircraft_missile_ammo = _aircraft_behavior.missile_ammo
		aircraft_gun_ammo = _aircraft_behavior.gun_ammo
		aircraft_altitude_factor = _aircraft_behavior.altitude_factor
		aircraft_circulating = _aircraft_behavior.circulating
		aircraft_afterburner_active = _aircraft_behavior.afterburner_active
		_aircraft_landing_reserved = _aircraft_behavior.landing_reserved
		_aircraft_landing_slot = _aircraft_behavior.landing_slot
		_aircraft_takeoff_active = _aircraft_behavior.takeoff_active
		_aircraft_reloading = _aircraft_behavior.reloading
	_setup_visual()
	if is_himars:
		_himars_setup_timer = 0.15  # Try setup after 0.15 seconds

func _setup_himars_launcher() -> void:
	"""Find the HIMARS launcher mesh and AnimationPlayer for animation control"""
	print("[HIMARS] Setting up launcher...")

	# The visual proxies are in World3D/VisualSync, not directly in World3D
	var visual_sync = get_tree().root.get_node_or_null("Main/World3D/VisualSync")
	if visual_sync == null:
		print("[HIMARS] ERROR: Could not find VisualSync node")
		return

	print("[HIMARS] Found VisualSync with ", visual_sync.get_child_count(), " children")

	var visual_proxy = _find_visual_proxy_in_world(visual_sync)
	if visual_proxy == null:
		print("[HIMARS] ERROR: Could not find visual proxy for unit ID ", get_instance_id())
		# Debug: list all children with unit_id meta
		for child in visual_sync.get_children():
			if child.has_meta("unit_id"):
				print("[HIMARS] Found proxy with unit_id: ", child.get_meta("unit_id"))
		return

	print("[HIMARS] Found visual proxy: ", visual_proxy.name)
	_himars_visual_proxy = visual_proxy  # Store reference for getting rotation later

	# Debug: print the full tree structure
	_debug_print_tree(visual_proxy, 0)

	# Find launcher mesh by name keywords
	_himars_launcher_node = _find_launcher_mesh(visual_proxy)
	if _himars_launcher_node != null:
		_himars_launcher_angle = 0.0  # Start lowered
		print("[HIMARS] Found launcher node: ", _himars_launcher_node.name)

	# Find AnimationPlayer in the model hierarchy
	_himars_animation_player = _find_animation_player_in_tree(visual_proxy)
	if _himars_animation_player != null:
		print("[HIMARS] Found AnimationPlayer: ", _himars_animation_player.name)
		var anim_list = _himars_animation_player.get_animation_list()
		print("[HIMARS] Animations available: ", anim_list)
		# Get the actual animation length
		for anim_name in anim_list:
			if "CINEMA" in anim_name or "cinema" in anim_name.to_lower():
				var anim = _himars_animation_player.get_animation(anim_name)
				if anim:
					_himars_animation_length = anim.length
					print("[HIMARS] Animation length: ", _himars_animation_length, " seconds")
				break
		# Fallback: check first animation
		if _himars_animation_length <= 0.1 and anim_list.size() > 0:
			var anim = _himars_animation_player.get_animation(anim_list[0])
			if anim:
				_himars_animation_length = anim.length
				print("[HIMARS] Animation length (fallback): ", _himars_animation_length, " seconds")
	else:
		print("[HIMARS] No AnimationPlayer found, will use manual rotation")

func _debug_print_tree(node: Node, depth: int) -> void:
	"""Debug helper to print node tree"""
	var indent = "  ".repeat(depth)
	var type_info = ""
	if node is AnimationPlayer:
		type_info = " [ANIMPLAYER]"
	elif node is MeshInstance3D:
		type_info = " [MESH]"
	print("[HIMARS] ", indent, "- ", node.name, " (", node.get_class(), ")", type_info)
	if depth < 4:  # Limit depth to avoid spam
		for child in node.get_children():
			_debug_print_tree(child, depth + 1)

func _find_visual_proxy_in_world(world_node: Node) -> Node3D:
	"""Find the 3D visual proxy node that represents this unit"""
	var my_id = get_instance_id()
	for child in world_node.get_children():
		if child.has_meta("unit_id") and child.get_meta("unit_id") == my_id:
			return child as Node3D
	return null

func _find_launcher_mesh(node: Node) -> Node3D:
	"""Recursively search for launcher mesh node"""
	var name_lower = node.name.to_lower()
	var keywords = ["missle", "rocket", "launcher", "pod", "tube"]  # Note: model has "missle" typo

	for keyword in keywords:
		if keyword in name_lower and node is Node3D:
			return node as Node3D

	for child in node.get_children():
		var found = _find_launcher_mesh(child)
		if found != null:
			return found

	return null

func _find_animation_player_in_tree(node: Node) -> AnimationPlayer:
	"""Recursively search for AnimationPlayer in node tree"""
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found = _find_animation_player_in_tree(child)
		if found != null:
			return found
	return null

func _exit_tree() -> void:
	GameState.unit_count = maxi(0, GameState.unit_count - 1)
	if unit_kind == "aircraft" and _aircraft_behavior != null:
		_aircraft_behavior.cleanup()
	if is_himars:
		_remove_ground_marker()

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

	# HIMARS launcher setup (delayed to ensure 3D visual is ready)
	if is_himars and not _himars_setup_done and _himars_setup_timer > 0.0:
		_himars_setup_timer -= delta
		if _himars_setup_timer <= 0.0:
			_setup_himars_launcher()
			_himars_setup_done = true

	_cooldown = maxf(0.0, _cooldown - delta)
	if unit_kind == "aircraft":
		_aircraft_missile_timer = maxf(0.0, _aircraft_missile_timer - delta)
	if is_himars:
		_bombardment_cooldown = maxf(0.0, _bombardment_cooldown - delta)
		if _bombardment_cooldown <= 0.0:
			_bombardment_ready = true

		# Handle rotation towards target (only when IDLE or auto-targeting)
		if _himars_state == HimarsState.IDLE:
			_update_himars_deployment(delta)

		# HIMARS State Machine
		_update_himars_state_machine(delta)

		# HIMARS auto-bombardment behavior (only start new salvo if IDLE and ready)
		if _himars_state == HimarsState.IDLE and _bombardment_ready:
			# Priority 1: Area bombardment if active
			if _bombardment_area_active and _bombardment_area_target != Vector2.ZERO:
				var dist := global_position.distance_to(_bombardment_area_target)
				if dist <= bombardment_range:
					_request_bombardment(_bombardment_area_target)
			# Priority 2: Auto-engage enemies (only when not in manual control)
			elif not manual_active:
				var enemy := _find_bombardment_target()
				if enemy != null:
					_request_bombardment(enemy.global_position)
	_update_hold(delta)
	if unit_kind == "aircraft":
		_update_aircraft_state(delta)
		return
	# HIMARS has different behavior - only moves when manually commanded or moving to rally point
	# AND only when not in a firing sequence (IDLE or RETRACTING allowed)
	if is_himars:
		# HIMARS only moves for: manual commands OR rally target
		# It does NOT auto-chase enemies or auto-move to HQ
		# CRITICAL: Cannot move while deploying, ready, or firing
		var can_move := _himars_state == HimarsState.IDLE
		var has_rally := not _reached_rally and rally_target != Vector2.ZERO
		var needs_to_move := (manual_active and manual_target != Vector2.ZERO) or has_rally

		if can_move and needs_to_move:
			_move_toward_target(delta)
	else:
		# Normal unit behavior
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
	# Apply gentle separation for overlapping units
	_apply_unit_separation(delta)
	_sync_visual_rotation()

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
			_visual_node.visible = false  # 2D visuals are hidden - 3D used instead
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
	if _aircraft_behavior == null:
		return

	# Delegate to aircraft behavior component
	_aircraft_behavior.update(delta)

	# Sync state back to unit for compatibility with existing visual sync code
	aircraft_missile_ammo = _aircraft_behavior.missile_ammo
	aircraft_gun_ammo = _aircraft_behavior.gun_ammo
	aircraft_altitude_factor = _aircraft_behavior.altitude_factor
	aircraft_circulating = _aircraft_behavior.circulating
	aircraft_afterburner_active = _aircraft_behavior.afterburner_active
	_aircraft_landing_reserved = _aircraft_behavior.landing_reserved
	_aircraft_landing_slot = _aircraft_behavior.landing_slot
	_aircraft_landing_on_path = _aircraft_behavior.landing_on_path
	_aircraft_landing_taxi = _aircraft_behavior.landing_taxi
	_aircraft_takeoff_active = _aircraft_behavior.takeoff_active
	_aircraft_takeoff_taxi = _aircraft_behavior.takeoff_taxi
	_aircraft_reloading = _aircraft_behavior.reloading
	_aircraft_speed_mult = _aircraft_behavior.speed_mult

	_sync_visual_rotation()

# Legacy aircraft state update - kept for reference but no longer used
func _update_aircraft_state_legacy(delta: float) -> void:
	_refresh_aircraft_squad_state()

	# UAVs don't engage in combat, they just loiter for reconnaissance
	if is_uav:
		# But UAVs still need to take off from the runway first!
		if _update_aircraft_takeoff(delta):
			_sync_visual_rotation()
			return
		# Once airborne, loiter for reconnaissance
		_update_aircraft_loiter_reload(delta, null, null)
		_move_toward_aircraft_loiter(delta)
		_sync_visual_rotation()
		return

	# Don't look for targets while retreating!
	var missile_target: Node2D = null
	var gun_target: Node2D = null
	if _aircraft_retreat_timer <= 0.0:
		missile_target = _find_aircraft_missile_target()
		gun_target = _find_attack_target()
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
	# Don't update missile lock or engage targets while retreating
	if _aircraft_retreat_timer <= 0.0:
		_update_aircraft_missile_lock(delta, missile_target)
	else:
		# Clear missile lock during retreat
		_aircraft_missile_lock_timer = 0.0
		_aircraft_missile_lock_id = 0

	aircraft_altitude_factor = 1.0
	_aircraft_landing_on_path = false
	_aircraft_landing_taxi = false
	aircraft_circulating = false
	var fired := false
	var gun_in_range := gun_target != null and _aircraft_gun_target_in_range(gun_target)

	# Fire weapons if in position (but not while retreating!)
	if missile_target != null and _aircraft_retreat_timer <= 0.0:
		_face_aircraft_toward(missile_target.global_position, delta)
		if _aircraft_missile_lock_timer >= aircraft_missile_lock_time and _can_fire_aircraft_missile():
			_fire_aircraft_missile(missile_target)
			_aircraft_missile_lock_timer = 0.0
			fired = true
	if not fired and gun_target != null and aircraft_gun_ammo > 0 and gun_in_range and _aircraft_retreat_timer <= 0.0:
		_face_aircraft_toward(gun_target.global_position, delta)
		_fire_aircraft_gun(gun_target)
		# Trigger retreat after gun run if enabled
		if aircraft_retreat_after_gun:
			_aircraft_retreat_timer = aircraft_retreat_duration
		fired = true

	# SIMPLE MOVEMENT LOGIC: Circle back, approach, fire, retreat
	if manual_active or _hold_active:
		_set_aircraft_speed(aircraft_engage_speed_mult, true)  # Full speed with afterburner for manual control
		var manual_target_pos := _resolve_target()
		if manual_target_pos != Vector2.ZERO:
			_move_toward_aircraft_target(manual_target_pos, delta)
	elif _aircraft_retreat_timer > 0.0:
		# RETREATING: Turn away 45 degrees, then arc back to airfield
		_set_aircraft_speed(aircraft_engage_speed_mult, true)

		if _aircraft_retreat_phase == 0:
			# Phase 0: Turn away from enemies for 1.5 seconds
			if _aircraft_retreat_timer < aircraft_retreat_duration - 1.5:
				_aircraft_retreat_phase = 1
			else:
				# Keep turning away
				var to_loiter := (aircraft_loiter_pos - global_position).normalized()
				# Turn 45 degrees from direct loiter direction
				var turn_away := to_loiter.rotated(PI * 0.25)  # 45 degrees
				var away_target := global_position + (turn_away * 500.0)
				_move_toward_aircraft_target(away_target, delta)
		else:
			# Phase 1: Arc back towards airfield
			_move_toward_aircraft_loiter(delta)
	elif missile_target != null:
		# HAS TARGET: Approach from safe distance and fire
		_set_aircraft_speed(aircraft_engage_speed_mult, true)
		var dist := global_position.distance_to(missile_target.global_position)

		# If too close, orbit around at safe distance
		if dist < aircraft_min_engagement_distance * 0.8:
			_move_toward_aircraft_orbit_standoff(missile_target.global_position, aircraft_min_engagement_distance, delta)
		# If at good distance, approach in a wide arc
		else:
			var approach_pos := _calculate_standoff_position(missile_target.global_position, aircraft_min_engagement_distance * 0.7)
			_move_toward_aircraft_target(approach_pos, delta)
	else:
		# NO TARGET: Circle around perimeter looking for targets
		aircraft_circulating = true
		_set_aircraft_speed(aircraft_circulate_speed_mult, false)
		_move_toward_aircraft_perimeter(delta)

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
				_set_aircraft_speed(aircraft_engage_speed_mult, true)  # Fast speed while waiting
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
			# Speed up return to base - use engage speed with afterburner
			_set_aircraft_speed(aircraft_engage_speed_mult, true)
			_move_toward_position(start, delta)
			return true
		_aircraft_landing_on_path = true
	var landing_radius := maxf(0.5, aircraft_landing_radius)
	if not _aircraft_landing_taxi:
		# Gradual deceleration during landing approach
		var dist_to_rollout := global_position.distance_to(rollout)
		var remaining := maxf(0.0, (global_position - touchdown).dot(path_dir))

		# Calculate deceleration based on distance to rollout
		if dist_to_rollout > landing_radius * 10.0:
			# Far from rollout - maintain high speed
			_set_aircraft_speed(aircraft_engage_speed_mult, true)
		else:
			# Close to rollout - gradually slow down
			var slowdown_progress := 1.0 - (dist_to_rollout / (landing_radius * 10.0))
			var speed_mult := lerpf(aircraft_engage_speed_mult, aircraft_circulate_speed_mult * 0.6, slowdown_progress)
			_set_aircraft_speed(speed_mult, slowdown_progress < 0.3)

		_move_toward_position(rollout, delta)
		aircraft_altitude_factor = clampf(remaining / maxf(1.0, path_length), 0.0, 1.0)
		if global_position.distance_to(rollout) > landing_radius:
			_aircraft_reload_timer = 0.0
			return true
		_aircraft_landing_taxi = true
	aircraft_altitude_factor = 0.0
	_set_aircraft_speed(aircraft_circulate_speed_mult * 0.5, false)  # Slow taxi speed
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
	# For takeoff, aircraft move WITH the runway direction (opposite of landing)
	# Landing: start -> touchdown -> rollout -> slot (moving AGAINST runway_dir)
	# Takeoff: slot -> rollout -> touchdown -> beyond (moving WITH runway_dir)
	var runway_dir := Vector2.RIGHT
	var dir_value: Variant = landing_path.get("dir", Vector2.RIGHT)
	if dir_value is Vector2:
		runway_dir = dir_value
	# Get the touchdown point (this is the runway exit for takeoff)
	var touchdown := home
	var touchdown_value: Variant = landing_path.get("touchdown", home)
	if touchdown_value is Vector2:
		touchdown = touchdown_value
	# Calculate airborne point beyond touchdown, going WITH runway_dir
	var path_length := aircraft_landing_path_length
	var size2d := _get_airfield_size()
	if size2d != Vector2.ZERO:
		path_length = maxf(path_length, size2d.x * 1.4)
	var airborne_point := touchdown + (runway_dir * path_length)
	var landing_radius := maxf(0.5, aircraft_landing_radius)

	# Calculate runway start position (opposite end from touchdown)
	var runway_start := home - (runway_dir * (size2d.x * 0.5)) if size2d != Vector2.ZERO else home

	# Phase 0: Taxi from parking to runway start, then turn around
	if not _aircraft_takeoff_taxi:
		aircraft_altitude_factor = 0.0
		_set_aircraft_speed(aircraft_circulate_speed_mult * 0.5, false)  # Slow taxi speed

		# First, taxi to runway start
		var dist_to_start := global_position.distance_to(runway_start)
		if dist_to_start > landing_radius:
			_move_toward_position(runway_start, delta)
			return true

		# At runway start - now turn around to face down the runway
		var current_dir := Vector2.RIGHT.rotated(rotation)
		var angle_diff := current_dir.angle_to(runway_dir)

		# If not aligned yet, rotate in place
		if absf(angle_diff) > 0.1:
			var turn_speed := 2.0 * delta  # Slow turn rate for ground taxi
			var turn_amount := clampf(angle_diff, -turn_speed, turn_speed)
			rotation += turn_amount
			return true

		# Aligned and ready for takeoff
		_aircraft_takeoff_taxi = true
		return true

	# Calculate continuous altitude throughout takeoff based on distance traveled along runway
	var runway_length := size2d.x if size2d != Vector2.ZERO else 100.0

	# Measure progress along the runway direction from a reference point
	# Use the airfield position as the starting reference (behind the aircraft at spawn)
	var spawn_point := home - (runway_dir * runway_length * 0.5)
	var traveled_total := (global_position - spawn_point).dot(runway_dir)

	# Define takeoff phases based on total distance traveled
	var lift_start := runway_length * 0.6  # Start lifting at 60% down runway
	var lift_end := runway_length * 1.0    # Finish initial lift at runway end (touchdown point)
	var climb_end := runway_length * 1.8   # Reach full altitude at 1.8x runway length

	# Calculate altitude and speed continuously based on distance traveled
	if traveled_total < lift_start:
		# Phase 1: Ground acceleration - gradually increase from slow start
		var accel_progress := traveled_total / lift_start
		var min_speed := aircraft_circulate_speed_mult * 0.4  # Start at 40% of circulate speed
		var speed_mult := lerpf(min_speed, aircraft_circulate_speed_mult, accel_progress)
		aircraft_altitude_factor = 0.0
		_set_aircraft_speed(speed_mult, false)
	elif traveled_total < lift_end:
		# Phase 2: Lift-off (0.0 -> 0.25 altitude) - continue accelerating
		var lift_progress := (traveled_total - lift_start) / (lift_end - lift_start)
		aircraft_altitude_factor = clampf(lift_progress * 0.25, 0.0, 0.25)
		var speed_mult := lerpf(aircraft_circulate_speed_mult, aircraft_engage_speed_mult, lift_progress)
		_set_aircraft_speed(speed_mult, lift_progress > 0.5)
	else:
		# Phase 3: Climb (0.25 -> 1.0 altitude) - full speed
		var climb_progress := (traveled_total - lift_end) / (climb_end - lift_end)
		aircraft_altitude_factor = clampf(0.25 + (climb_progress * 0.75), 0.25, 1.0)
		_set_aircraft_speed(aircraft_engage_speed_mult, true)

	# Movement: head toward airborne point throughout entire takeoff
	_move_toward_position(airborne_point, delta)

	# Continue takeoff until fully airborne and far enough from touchdown
	if aircraft_altitude_factor < 0.99 or traveled_total < climb_end:
		return true

	# Takeoff complete
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
		missile.visual_base_radius = 0.1  # EXTREMELY LARGE for testing (1.0/0.1 = 10.0 scale = 1000% size!!)
	if get_parent() != null:
		get_parent().add_child(missile)
	_aircraft_retreat_timer = aircraft_retreat_duration  # Start retreat after firing
	_aircraft_retreat_phase = 0  # Reset to turn-away phase
	print("[Aircraft] Missile fired! Starting retreat for ", aircraft_retreat_duration, "s. Ammo remaining: ", aircraft_missile_ammo - 1)
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

func _face_toward(pos: Vector2, delta: float = 0.0) -> void:
	var delta_vec := pos - global_position
	if delta_vec.length_squared() <= 0.1:
		return
	var desired := delta_vec.normalized()

	# Apply smooth turning for vehicles
	if delta > 0.0 and unit_kind != "aircraft" and unit_kind != "infantry" and vehicle_turn_rate > 0.0:
		_facing = _apply_vehicle_turn(desired, delta)
	else:
		_facing = desired

func _face_aircraft_toward(pos: Vector2, delta: float) -> void:
	var delta_vec := pos - global_position
	if delta_vec.length_squared() <= 0.1:
		return
	var desired := delta_vec.normalized()
	if _aircraft_allow_instant_turn() or aircraft_turn_rate <= 0.0:
		_facing = desired
		return
	_facing = _apply_aircraft_turn(desired, delta)

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

	# Apply smooth turning based on unit type
	if unit_kind == "aircraft" and not _aircraft_allow_instant_turn() and aircraft_turn_rate > 0.0:
		direction = _apply_aircraft_turn(direction, delta)
	elif unit_kind != "aircraft" and unit_kind != "infantry" and vehicle_turn_rate > 0.0:
		direction = _apply_vehicle_turn(direction, delta)

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

func _apply_unit_separation(delta: float) -> void:
	# Gentle separation for overlapping units
	if unit_kind == "aircraft":
		return  # Aircraft handle their own spacing

	var separation_radius := body_radius * 2.2  # Start separating when units get close
	var separation_strength := 15.0  # Gentle push force
	var separation_force := Vector2.ZERO
	var nearby_count := 0

	# Check nearby units of the same team
	var group_name := "units_%s" % team_id
	var units := get_tree().get_nodes_in_group(group_name)

	for other_node in units:
		if other_node == self:
			continue
		if not (other_node is Unit):
			continue
		var other := other_node as Unit
		if other.unit_kind == "aircraft":
			continue  # Don't separate from aircraft

		var to_other := other.global_position - global_position
		var dist := to_other.length()

		# If units are overlapping or very close
		if dist < separation_radius and dist > 0.1:
			# Push away from the other unit
			var push_strength := 1.0 - (dist / separation_radius)
			separation_force -= to_other.normalized() * push_strength
			nearby_count += 1

	# Apply the separation force gently
	if nearby_count > 0:
		separation_force = separation_force.normalized()
		global_position += separation_force * separation_strength * delta

func _move_toward_aircraft_target(target: Vector2, delta: float) -> void:
	var adjusted := _get_aircraft_formation_target(target)
	_move_toward_position(adjusted, delta)

func _set_aircraft_speed(mult: float, afterburner: bool) -> void:
	_aircraft_speed_mult = maxf(0.0, mult)
	aircraft_afterburner_active = afterburner

func _aircraft_allow_instant_turn() -> bool:
	return _aircraft_landing_on_path or _aircraft_landing_taxi or _aircraft_takeoff_active

func _calculate_standoff_position(target_pos: Vector2, standoff_dist: float) -> Vector2:
	# Calculate a position at standoff distance from target, on our approach vector
	var to_target := (target_pos - global_position).normalized()
	return target_pos - (to_target * standoff_dist)

func _move_toward_aircraft_orbit_standoff(target_pos: Vector2, orbit_radius: float, delta: float) -> void:
	# Orbit around the target at a specific radius (standoff distance)
	var to_me := global_position - target_pos
	var current_dist := to_me.length()

	# Calculate tangential direction for orbiting
	var tangent := Vector2(-to_me.y, to_me.x).normalized()

	# If too close, move outward while orbiting
	# If too far, move inward while orbiting
	var radial_adjust := Vector2.ZERO
	if current_dist < orbit_radius * 0.9:
		radial_adjust = to_me.normalized() * 0.3  # Push out
	elif current_dist > orbit_radius * 1.1:
		radial_adjust = -to_me.normalized() * 0.3  # Pull in

	# Combine tangential orbit with radial adjustment
	var orbit_dir := (tangent + radial_adjust).normalized()
	var orbit_target := global_position + (orbit_dir * 200.0)

	_move_toward_aircraft_target(orbit_target, delta)

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

func _apply_vehicle_turn(desired: Vector2, delta: float) -> Vector2:
	var desired_dir := desired.normalized()
	if _facing.length_squared() <= 0.01:
		return desired_dir
	var angle := _facing.angle_to(desired_dir)
	var max_turn := vehicle_turn_rate * delta
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
	# For 4 slots: arrange as 2 pairs side by side
	# Slots 0,1 on left (-1 spacing), Slots 2,3 on right (+1 spacing)
	# Then offset along runway direction to separate front/back
	var side := -1.0 if slot_index < 2 else 1.0  # Left side for 0,1, right side for 2,3
	var row := float(slot_index % 2)  # 0 for front, 1 for back

	# Calculate lateral offset (perpendicular to runway)
	var lateral_offset := lateral * (side * spacing)

	# Calculate longitudinal offset (along runway direction) for front/back positioning
	var longitudinal_offset := runway_dir * (row * spacing * 0.8)

	return lateral_offset + longitudinal_offset

func _get_airfield_landing_path(home: Vector2) -> Dictionary:
	var size2d := _get_airfield_size()
	var runway_dir := _get_airfield_runway_dir().normalized()
	if runway_dir.length_squared() <= 0.0:
		runway_dir = Vector2.RIGHT
	var offset := _get_airfield_runway_offset(size2d)
	# Touchdown point is at the far end of the runway (entry side)
	var touchdown := home + offset
	if size2d != Vector2.ZERO:
		touchdown = home + (runway_dir * (size2d.x * 0.5)) + offset
	# Rollout is the midpoint where aircraft slow down and prepare to taxi to parking
	# Position it slightly before center so aircraft have room to turn into parking spots
	var rollout := home + offset
	if size2d != Vector2.ZERO:
		rollout = home - (runway_dir * (size2d.x * 0.15)) + offset
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

	# HIMARS prioritizes rally target over combat targets
	if is_himars and not _reached_rally and rally_target != Vector2.ZERO:
		return rally_target

	if _chase_target != null and is_instance_valid(_chase_target):
		target = _chase_target.global_position
	elif _structure_target != null and is_instance_valid(_structure_target):
		target = _structure_target.global_position
	elif not _reached_rally and rally_target != Vector2.ZERO:
		target = rally_target
	elif is_himars:
		# HIMARS stays at rally point, doesn't auto-move to HQ
		target = global_position
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

# ========== HIMARS STATE MACHINE ==========

func _request_bombardment(target_pos: Vector2) -> bool:
	"""Request a bombardment - this starts the deploy sequence instead of firing immediately"""
	if not is_himars:
		return false
	if not _bombardment_ready:
		return false
	if _himars_state != HimarsState.IDLE:
		return false  # Already in a firing sequence
	var dist := global_position.distance_to(target_pos)
	if dist > bombardment_range:
		return false

	print("[HIMARS] Bombardment requested at ", target_pos, " - starting rotation")
	_himars_pending_target = target_pos

	# Calculate the direction to target
	var dir_to_target := (target_pos - global_position).normalized()

	# The launcher rotates during the raise animation by HIMARS_LAUNCHER_OFFSET_ANGLE degrees
	# So we need to pre-rotate the vehicle in the opposite direction
	# so that after the animation, the launcher points at the target
	var offset_radians := deg_to_rad(HIMARS_LAUNCHER_OFFSET_ANGLE)
	_himars_target_facing = dir_to_target.rotated(-offset_radians)

	print("[HIMARS] Direction to target: ", dir_to_target, " | Target facing (with offset): ", _himars_target_facing)

	_himars_state = HimarsState.ROTATING

	return true

func _update_himars_state_machine(delta: float) -> void:
	"""Process the HIMARS firing state machine"""
	match _himars_state:
		HimarsState.IDLE:
			# Animate launcher back to stowed position if needed
			_update_himars_launcher_angle(delta, 0.0)

		HimarsState.ROTATING:
			# Rotate the HIMARS to face the target by updating _facing
			# The visual_sync_3d system reads _facing and rotates the 3D proxy accordingly
			var current_angle := atan2(_facing.y, _facing.x)
			var target_angle := atan2(_himars_target_facing.y, _himars_target_facing.x)
			var angle_diff := target_angle - current_angle

			# Normalize angle difference to -PI to PI
			while angle_diff > PI:
				angle_diff -= TAU
			while angle_diff < -PI:
				angle_diff += TAU

			# Check if we're close enough
			if abs(angle_diff) < 0.05:  # About 3 degrees tolerance
				_facing = _himars_target_facing
				print("[HIMARS] Rotation complete - starting deploy")
				_himars_state = HimarsState.DEPLOYING
				# Use actual animation length if available, otherwise fallback
				_himars_state_timer = _himars_animation_length if _himars_animation_length > 0.1 else HIMARS_DEPLOY_TIME_FALLBACK
				print("[HIMARS] Deploy timer set to: ", _himars_state_timer, " seconds")
				# Start the raise animation
				_play_himars_animation("raise")
			else:
				# Rotate towards target
				var rot_step := HIMARS_ROTATION_SPEED * delta
				if angle_diff > 0:
					current_angle += min(rot_step, angle_diff)
				else:
					current_angle -= min(rot_step, -angle_diff)
				_facing = Vector2(cos(current_angle), sin(current_angle))

		HimarsState.DEPLOYING:
			# Raising the launcher - wait for animation to complete
			_update_himars_launcher_angle(delta, -45.0)
			_himars_state_timer -= delta
			# Check if animation finished OR timer expired (whichever is longer for safety)
			var anim_done := _himars_animation_player == null or not _himars_animation_player.is_playing()
			var timer_done := _himars_state_timer <= 0.0
			if anim_done and timer_done:
				print("[HIMARS] Launcher raised - ready to fire")
				_himars_state = HimarsState.READY
				_himars_state_timer = HIMARS_FIRE_DELAY

		HimarsState.READY:
			# Small delay after raising before firing
			_himars_state_timer -= delta
			if _himars_state_timer <= 0.0:
				print("[HIMARS] Starting salvo of ", bombardment_missiles_per_salvo, " missiles")
				_himars_state = HimarsState.FIRING
				_bombardment_salvo_target = _himars_pending_target
				_bombardment_salvo_count = bombardment_missiles_per_salvo
				_bombardment_salvo_timer = 0.0  # Fire first missile immediately

		HimarsState.FIRING:
			# Fire missiles in salvo
			_bombardment_salvo_timer -= delta
			if _bombardment_salvo_timer <= 0.0 and _bombardment_salvo_count > 0:
				_fire_single_missile(_bombardment_salvo_target)
				_bombardment_salvo_count -= 1
				_bombardment_salvo_timer = bombardment_salvo_interval

			# Check if salvo is complete
			if _bombardment_salvo_count <= 0:
				print("[HIMARS] Salvo complete - retracting launcher")
				_himars_state = HimarsState.RETRACTING
				# Use actual animation length if available, otherwise fallback
				_himars_state_timer = _himars_animation_length if _himars_animation_length > 0.1 else HIMARS_RETRACT_TIME_FALLBACK
				# Start cooldown after firing
				_bombardment_ready = false
				_bombardment_cooldown = bombardment_reload_time
				# Start the lower animation
				_play_himars_animation("lower")

		HimarsState.RETRACTING:
			# Lowering the launcher - wait for animation to complete
			_update_himars_launcher_angle(delta, 0.0)
			_himars_state_timer -= delta
			# Check if animation finished OR timer expired (whichever is longer for safety)
			var anim_done := _himars_animation_player == null or not _himars_animation_player.is_playing()
			var timer_done := _himars_state_timer <= 0.0
			if anim_done and timer_done:
				print("[HIMARS] Launcher stowed - returning to IDLE")
				_himars_state = HimarsState.IDLE
				_himars_pending_target = Vector2.ZERO

func _update_himars_launcher_angle(delta: float, target_angle: float) -> void:
	"""Smoothly animate the launcher angle (fallback for when no AnimationPlayer)"""
	if _himars_launcher_node == null:
		return
	# Only use manual rotation if we don't have an AnimationPlayer controlling it
	if _himars_animation_player == null or not _himars_animation_player.is_playing():
		_himars_launcher_angle = move_toward(_himars_launcher_angle, target_angle, 60.0 * delta)
		_himars_launcher_node.rotation_degrees.x = _himars_launcher_angle

func _play_himars_animation(action: String) -> void:
	"""Play HIMARS animation - tries AnimationPlayer first, falls back to manual rotation"""
	if _himars_animation_player == null:
		return

	var anim_list := _himars_animation_player.get_animation_list()
	print("[HIMARS] Available animations: ", anim_list)

	# The GLB model has a single animation from Cinema 4D export (CINEMA_4D_________)
	# Find it by looking for "CINEMA" or just use the first animation available
	var main_anim := ""
	for anim_name in anim_list:
		if "CINEMA" in anim_name or "cinema" in anim_name.to_lower():
			main_anim = anim_name
			break
	# Fallback: just use the first animation if no CINEMA_4D found
	if main_anim == "" and anim_list.size() > 0:
		main_anim = anim_list[0]

	if main_anim == "":
		print("[HIMARS] No animation found!")
		return

	if action == "raise":
		# Play the animation forward to raise the launcher
		_himars_animation_player.play(main_anim)
		print("[HIMARS] Playing animation forward: ", main_anim)

	elif action == "lower":
		# Play the animation backwards to lower the launcher
		_himars_animation_player.play_backwards(main_anim)
		print("[HIMARS] Playing animation backwards: ", main_anim)

func is_himars_firing() -> bool:
	"""Returns true if HIMARS is in a firing sequence (cannot move)"""
	return is_himars and _himars_state != HimarsState.IDLE

func _get_himars_launch_direction() -> Vector2:
	"""Get the 2D direction the HIMARS launcher is pointing based on vehicle facing + launcher offset"""
	# The launcher has rotated by HIMARS_LAUNCHER_OFFSET_ANGLE during the raise animation
	# So the launch direction is the vehicle's _facing rotated by that offset
	var offset_radians := deg_to_rad(HIMARS_LAUNCHER_OFFSET_ANGLE)
	var launch_dir := _facing.rotated(offset_radians)

	print("[HIMARS] Vehicle facing: ", _facing, " + offset ", HIMARS_LAUNCHER_OFFSET_ANGLE, " deg = launch dir: ", launch_dir)

	return launch_dir.normalized()

func launch_bombardment(target_pos: Vector2) -> bool:
	"""Legacy function - now redirects to state machine"""
	return _request_bombardment(target_pos)

func _fire_single_missile(target_pos: Vector2) -> void:
	# Get the launcher's actual facing direction from the 3D visual
	var direction := _get_himars_launch_direction()

	# Calculate spawn position at the rear of the HIMARS (where the launcher is)
	# The launcher is at the back of the truck, offset behind and to the right of vehicle center
	const LAUNCHER_OFFSET_BACK := 20.0  # Distance behind center
	const LAUNCHER_OFFSET_RIGHT := 10.0  # Distance to the right
	var right_dir := Vector2(_facing.y, -_facing.x)  # Perpendicular to facing (right side)
	var spawn_offset := -_facing * LAUNCHER_OFFSET_BACK + right_dir * LAUNCHER_OFFSET_RIGHT
	var spawn_pos := global_position + spawn_offset

	# Calculate target position based on launcher direction (missiles fire where launcher points)
	# The missile still needs a target_pos for its ballistic arc calculation
	var launch_distance := global_position.distance_to(target_pos)
	var actual_target := spawn_pos + direction * launch_distance

	print("[HIMARS] Launcher direction: ", direction, " | Spawn pos: ", spawn_pos, " | Target: ", actual_target)

	# Create ATACMS missile - ballistic, not heat-seeking
	var missile := Missile.new()
	missile.global_position = spawn_pos
	missile.damage = bombardment_missile_damage
	missile.speed = bombardment_missile_speed
	missile.lifetime = bombardment_missile_lifetime
	missile.turn_rate = 0.5  # Small turn rate for minor corrections
	missile.target = null  # No target tracking
	missile.warhead_size = "large"
	missile.splash_enabled = true
	missile.splash_damage_scale = 1.0  # Full damage in splash zone
	missile.splash_radius = bombardment_missile_splash_radius
	missile.team_id = team_id
	missile.source_kind = "aircraft"  # Use aircraft explosions for larger visual effect
	missile.color = Color(1.0, 0.4, 0.1, 1.0)
	missile.trail_color = Color(1.0, 0.7, 0.4, 0.8)
	missile.source_altitude = 0.0  # Not used for visual height
	missile.visual_scene_path = "res://scenes/missiles/atacms_visual.tscn"
	missile.visual_base_radius = 1.0  # Smaller visual
	missile.render_2d = true  # Enable 2D rendering for trail visibility
	missile.trail_length = 40.0  # Longer trail for visibility
	missile.ballistic_arc = 120.0  # Very high ballistic arc for dramatic ground-launched trajectory
	missile._target_pos = actual_target  # Use the adjusted target based on launcher direction
	missile.set_origin(spawn_pos)  # Origin at the launcher position

	# Initialize velocity to point in launcher direction
	missile._velocity = direction

	get_parent().add_child(missile)
	print("[BOMBARDMENT] ATACMS missile fired to ", actual_target)

func is_bombardment_ready() -> bool:
	return is_himars and _bombardment_ready

func get_bombardment_range() -> float:
	return bombardment_range if is_himars else 0.0

func _find_bombardment_target() -> Node2D:
	if not is_himars:
		return null
	# Find enemy units or structures within bombardment range
	var range_sq := bombardment_range * bombardment_range
	var best_target: Node2D = null
	var best_dist := INF

	# Check enemy units
	for node in get_tree().get_nodes_in_group("units"):
		if node == self:
			continue
		var enemy := node as Unit
		if enemy == null or enemy.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist > range_sq:
			continue
		if dist < best_dist:
			best_dist = dist
			best_target = enemy

	# Check enemy structures
	for node in get_tree().get_nodes_in_group("buildings"):
		var building := node as Building
		if building == null or building.team_id == team_id:
			continue
		var dist := global_position.distance_squared_to(building.global_position)
		if dist > range_sq:
			continue
		if dist < best_dist:
			best_dist = dist
			best_target = building

	return best_target

func set_bombardment_area(target_area: Vector2) -> void:
	if not is_himars:
		return
	_bombardment_area_active = true
	_bombardment_area_target = target_area
	#print("[HIMARS] Area bombardment set to: ", target_area)

	# Create ground marker
	_create_ground_marker(target_area)

func clear_bombardment_area() -> void:
	_bombardment_area_active = false
	_bombardment_area_target = Vector2.ZERO
	#print("[HIMARS] Area bombardment cleared")

	# Remove ground marker
	_remove_ground_marker()

func is_area_bombardment_active() -> bool:
	return _bombardment_area_active

func _create_ground_marker(position: Vector2) -> void:
	# Remove existing marker if any
	_remove_ground_marker()

	# Load and instantiate marker script
	var marker_script = load("res://scripts/core/bombardment_marker.gd")
	if marker_script == null:
		#print("[HIMARS] Warning: Could not load bombardment_marker.gd")
		return

	var marker = Node2D.new()
	marker.set_script(marker_script)
	marker.global_position = position
	marker.target_unit = self

	# Add to parent (game world)
	if get_parent() != null:
		get_parent().add_child(marker)
		_himars_ground_marker = marker
	else:
		pass  # No parent for ground marker

func _remove_ground_marker() -> void:
	if _himars_ground_marker != null and is_instance_valid(_himars_ground_marker):
		_himars_ground_marker.queue_free()
		_himars_ground_marker = null
		#print("[HIMARS] Ground marker removed")

func _update_himars_deployment(_delta: float) -> void:
	# HIMARS rotation is now handled entirely by the ROTATING state when firing is requested
	# No auto-rotation when IDLE - the vehicle stays in its current orientation
	# This prevents unnecessary spinning after retracting the launcher
	pass
