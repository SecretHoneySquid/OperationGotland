class_name MissileCarrierTurret
extends DefenseTurret

## Naval Missile Carrier Turret
## Static building with ATACMS bombardment capability.
## Can only target areas with TRUE vision (not radar or satellite).

signal bombardment_ready_changed(ready: bool)
signal bombardment_fired(target_pos: Vector2)

@export var bombardment_range := 1200.0
@export var bombardment_missile_damage := 80.0
@export var bombardment_missile_speed := 400.0
@export var bombardment_missile_lifetime := 12.0
@export var bombardment_missile_splash_radius := 60.0
@export var bombardment_reload_time := 15.0
@export var ballistic_arc_height := 800.0

var _bombardment_ready := true
var _bombardment_cooldown := 0.0
var _pending_target := Vector2.ZERO

enum CarrierState { IDLE, READY, FIRING, RELOADING }
var _state := CarrierState.IDLE

func _ready() -> void:
	super._ready()
	add_to_group("missile_carrier")
	add_to_group("missile_carrier_%s" % team_id)
	# Add to vision group since carrier provides vision
	add_to_group("vision_%s" % team_id)
	# Ensure we're in the defense_turret group for selection (redundant but safe)
	if not is_in_group("defense_turret"):
		add_to_group("defense_turret")
	if not is_in_group("defense_turret_%s" % team_id):
		add_to_group("defense_turret_%s" % team_id)
	# Disable normal turret targeting - carrier only uses manual bombardment
	attack_range = 0.0
	_bombardment_ready = true
	_state = CarrierState.READY
	print("[MISSILE_CARRIER] Initialized - groups: ", get_groups())

func _process(delta: float) -> void:
	# Don't call super._process() - we don't want auto-targeting
	_update_bombardment_cooldown(delta)
	_update_state_machine(delta)
	queue_redraw()

func _update_bombardment_cooldown(delta: float) -> void:
	if not _bombardment_ready:
		_bombardment_cooldown = maxf(0.0, _bombardment_cooldown - delta)
		if _bombardment_cooldown <= 0.0:
			_bombardment_ready = true
			_state = CarrierState.READY
			emit_signal("bombardment_ready_changed", true)

func _update_state_machine(_delta: float) -> void:
	match _state:
		CarrierState.IDLE:
			pass  # Waiting for activation
		CarrierState.READY:
			pass  # Ready to fire, waiting for target
		CarrierState.FIRING:
			_fire_bombardment_missile()
			_state = CarrierState.RELOADING
			_bombardment_ready = false
			_bombardment_cooldown = bombardment_reload_time
			emit_signal("bombardment_ready_changed", false)
		CarrierState.RELOADING:
			pass  # Handled by cooldown

func request_bombardment(target_pos: Vector2) -> bool:
	## Request a bombardment strike at the given position.
	## Returns true if the request was accepted.
	print("[MISSILE_CARRIER] request_bombardment called for target: ", target_pos)
	if not _bombardment_ready:
		print("[MISSILE_CARRIER] REJECTED: Not ready")
		return false
	if not _is_in_true_vision(target_pos):
		print("[MISSILE_CARRIER] REJECTED: Not in true vision")
		return false
	var dist := global_position.distance_to(target_pos)
	if dist > bombardment_range:
		print("[MISSILE_CARRIER] REJECTED: Out of range (", dist, " > ", bombardment_range, ")")
		return false

	print("[MISSILE_CARRIER] ACCEPTED: Firing at ", target_pos)
	_pending_target = target_pos
	_state = CarrierState.FIRING
	return true

func _is_in_true_vision(pos: Vector2) -> bool:
	## Check if position is visible via TRUE vision (not radar, not satellite).
	## Only units and buildings with actual vision radius count.
	var vision_group := "vision_" + team_id
	var nodes_checked := 0
	for node in get_tree().get_nodes_in_group(vision_group):
		if node == null or not is_instance_valid(node):
			continue
		# Skip satellite vision sources
		if node.get_class() == "SpySatelliteVision" or node.is_in_group("spy_satellite"):
			continue
		# Skip radar stations (they provide detection, not true vision)
		if node is RadarStation:
			continue
		if not node.has_method("get_vision_radius"):
			continue
		var radius := float(node.get_vision_radius())
		if radius <= 0.0:
			continue
		nodes_checked += 1
		var dist_sq := pos.distance_squared_to(node.global_position)
		if dist_sq <= radius * radius:
			print("[MISSILE_CARRIER] Vision check PASSED via: ", node.name, " radius=", radius)
			return true
	print("[MISSILE_CARRIER] Vision check FAILED - checked ", nodes_checked, " vision sources")
	return false

func _fire_bombardment_missile() -> void:
	var missile := Missile.new()
	missile.team_id = team_id
	missile.damage = bombardment_missile_damage
	missile.speed = bombardment_missile_speed
	missile.lifetime = bombardment_missile_lifetime
	missile._target_pos = _pending_target
	missile.ballistic_arc = ballistic_arc_height
	missile.color = Color(1.0, 0.4, 0.1, 1.0)
	missile.trail_color = Color(1.0, 0.8, 0.5, 0.7)
	missile.trail_length = 20.0
	missile.warhead_size = "large"
	missile.splash_enabled = true
	missile.splash_radius = bombardment_missile_splash_radius
	missile.splash_damage_scale = 0.7
	missile.interceptable = true
	missile.intercept_difficulty = 1.2
	missile.source_kind = "atacms"
	missile.source_altitude = 1.0
	missile.hit_radius = 12.0
	missile.turn_rate = 0.5  # Minimal guidance for ballistic missile
	missile.set_origin(global_position)
	missile.global_position = global_position
	# Point missile toward target
	var to_target := (_pending_target - global_position).normalized()
	missile._velocity = to_target
	if get_parent() != null:
		get_parent().add_child(missile)
	emit_signal("bombardment_fired", _pending_target)
	print("[MISSILE_CARRIER] ATACMS fired to ", _pending_target)

func is_bombardment_ready() -> bool:
	return _bombardment_ready

func get_bombardment_range() -> float:
	return bombardment_range

func get_cooldown_remaining() -> float:
	return _bombardment_cooldown

func get_cooldown_progress() -> float:
	## Returns 0.0 when reloading starts, 1.0 when ready
	if _bombardment_ready:
		return 1.0
	if bombardment_reload_time <= 0.0:
		return 1.0
	return 1.0 - (_bombardment_cooldown / bombardment_reload_time)

func get_vision_radius() -> float:
	## Missile carriers provide vision around them
	return 300.0

func _draw() -> void:
	if not render_2d:
		return
	# Draw ship-like shape
	var ship_length := base_radius * 2.0
	var ship_width := base_radius * 0.8

	# Hull
	var hull_color := base_color
	var hull_points := PackedVector2Array([
		Vector2(-ship_length * 0.5, -ship_width * 0.5),
		Vector2(ship_length * 0.4, -ship_width * 0.5),
		Vector2(ship_length * 0.5, 0),
		Vector2(ship_length * 0.4, ship_width * 0.5),
		Vector2(-ship_length * 0.5, ship_width * 0.5),
	])
	draw_colored_polygon(hull_points, hull_color)
	draw_polyline(hull_points, _shade(hull_color, -0.3), 2.0)

	# Superstructure
	var tower_color := _shade(hull_color, 0.15)
	draw_rect(Rect2(-ship_length * 0.1, -ship_width * 0.25, ship_length * 0.25, ship_width * 0.5), tower_color)

	# VLS launcher
	var vls_color := _shade(hull_color, -0.1)
	draw_rect(Rect2(ship_length * 0.15, -ship_width * 0.3, ship_length * 0.2, ship_width * 0.6), vls_color)

	# Reload indicator
	if not _bombardment_ready:
		var progress := get_cooldown_progress()
		var indicator_width := ship_length * 0.6
		var indicator_height := 4.0
		var bg_rect := Rect2(-indicator_width * 0.5, -ship_width * 0.5 - 10, indicator_width, indicator_height)
		var fg_rect := Rect2(-indicator_width * 0.5, -ship_width * 0.5 - 10, indicator_width * progress, indicator_height)
		draw_rect(bg_rect, Color(0.2, 0.2, 0.2, 0.8))
		draw_rect(fg_rect, Color(0.3, 0.7, 1.0, 0.9))
