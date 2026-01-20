class_name Missile
extends Node2D

signal impact(pos: Vector2, color: Color, warhead_size: String, source_kind: String)

@export var speed := 260.0
@export var range := 0.0
@export var damage := 10.0
@export var turn_rate := 10.0
@export var lifetime := 4.0
@export var hit_radius := 6.0
@export var max_distance := 0.0
@export var color := Color(1.0, 0.6, 0.2, 1.0)
@export var trail_color := Color(1.0, 0.9, 0.6, 0.6)
@export var trail_length := 12.0
@export var warhead_size := "medium"
@export var render_2d := true
@export var team_id := ""
@export var source_kind := ""
@export var source_altitude := 0.0
@export var splash_enabled := true
@export var splash_damage_scale := 0.6
@export var splash_radius := 0.0
@export var visual_scene_path := ""
@export var visual_base_radius := 1.0
@export var ballistic_arc := 0.0  # Height of ballistic arc (0 = straight, >0 = arcing trajectory)
@export var interceptable := false  # Can be intercepted by air defense systems (e.g., Patriot)
@export var intercept_difficulty := 1.0  # Higher = harder to intercept (affects success chance)

var target: Node2D
var _intercepted := false  # Set to true when hit by an interceptor
var _velocity := Vector2.RIGHT
var _origin := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _target_lost := false
var _initial_distance := 0.0
var _source_altitude_start := 1.0
var _visual_node: Node  # Can be either Node2D or Node3D
var _ballistic_height := 0.0  # Current height in ballistic arc
var _ballistic_velocity_z := 0.0  # Vertical velocity for ballistic arc
var _base_speed := 0.0  # Store original speed for acceleration

const _WARHEAD_RADII = {
	"small": 4.0,
	"medium": 6.0,
	"large": 9.0,
}
const _WARHEAD_SPLASH = {
	"small": 18.0,
	"medium": 28.0,
	"large": 40.0,
}

func _ready() -> void:
	add_to_group("missiles")
	if _origin == Vector2.ZERO:
		_origin = global_position
	_source_altitude_start = clampf(source_altitude, 0.0, 1.0)
	if target != null and is_instance_valid(target):
		_target_pos = target.global_position
		_initial_distance = maxf(_origin.distance_to(_target_pos), 0.01)
	elif _target_pos != Vector2.ZERO:
		# Set initial distance for position-targeted missiles (like ATACMS)
		_initial_distance = maxf(_origin.distance_to(_target_pos), 0.01)
	_apply_warhead_settings()
	_setup_visual()
	# Store base speed before applying ballistic acceleration
	_base_speed = speed
	if ballistic_arc > 0.0:
		speed = _base_speed * 0.5  # Start at 50% speed
	_init_ballistic_arc()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if target != null and is_instance_valid(target):
		_target_pos = target.global_position
		if _initial_distance <= 0.0 and _origin != Vector2.ZERO:
			_initial_distance = maxf(_origin.distance_to(_target_pos), 0.01)
	elif not _target_lost and _target_pos != Vector2.ZERO:
		_target_lost = true
		target = null
	var effective_range := max_distance
	if range > 0.0:
		effective_range = range
	if _origin != Vector2.ZERO and effective_range > 0.0:
		if global_position.distance_squared_to(_origin) > effective_range * effective_range:
			queue_free()
			return
	if target != null and is_instance_valid(target):
		_update_guidance(target.global_position, delta)
		_check_hit(target)
	elif _target_pos != Vector2.ZERO:
		_update_guidance(_target_pos, delta)
		_check_ground_hit()
	_update_altitude_factor()
	_update_ballistic_arc(delta)
	global_position += _velocity.normalized() * speed * delta
	_update_visual_rotation()
	queue_redraw()

func _update_guidance(target_pos: Vector2, delta: float) -> void:
	var desired := target_pos - global_position
	if desired.length_squared() > 0.1:
		var desired_dir := desired.normalized()
		if _velocity.length_squared() < 0.1:
			_velocity = desired_dir
		else:
			var angle := _velocity.angle_to(desired_dir)
			var max_turn := turn_rate * delta
			_velocity = _velocity.rotated(clampf(angle, -max_turn, max_turn))

func _update_altitude_factor() -> void:
	if _target_pos == Vector2.ZERO or _initial_distance <= 0.0:
		source_altitude = _source_altitude_start
		return
	var remaining := global_position.distance_to(_target_pos)
	var ratio := clampf(remaining / _initial_distance, 0.0, 1.0)
	source_altitude = _source_altitude_start * ratio

func _check_hit(target_node: Node2D) -> void:
	if global_position.distance_squared_to(target_node.global_position) <= hit_radius * hit_radius:
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage, "missile")
		_apply_splash_damage(target_node)
		emit_signal("impact", global_position, color, warhead_size, source_kind)
		queue_free()

func _check_ground_hit() -> void:
	if _target_pos == Vector2.ZERO:
		return
	if global_position.distance_squared_to(_target_pos) <= hit_radius * hit_radius:
		# Apply splash damage even for ground hits
		_apply_splash_damage(null)
		emit_signal("impact", _target_pos, color, warhead_size, source_kind)
		queue_free()

func _draw() -> void:
	if not render_2d:
		return
	var radius := maxf(2.0, _get_warhead_radius() * 0.6)
	var trail := maxf(8.0, trail_length)
	draw_circle(Vector2.ZERO, radius, color)
	draw_line(Vector2.ZERO, -_velocity.normalized() * trail, trail_color, 2.0)

func set_origin(pos: Vector2) -> void:
	_origin = pos

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func get_warhead_radius() -> float:
	return _get_warhead_radius()

func _apply_warhead_settings() -> void:
	var radius := _get_warhead_radius()
	if hit_radius <= 0.0:
		hit_radius = radius

func _get_warhead_radius() -> float:
	var key := warhead_size.to_lower()
	if _WARHEAD_RADII.has(key):
		return float(_WARHEAD_RADII[key])
	return float(_WARHEAD_RADII["medium"])

func _get_warhead_splash_radius() -> float:
	var key := warhead_size.to_lower()
	if _WARHEAD_SPLASH.has(key):
		return float(_WARHEAD_SPLASH[key])
	return float(_WARHEAD_SPLASH["medium"])

func _apply_splash_damage(primary: Node2D) -> void:
	if not splash_enabled:
		return
	var radius := splash_radius
	if radius <= 0.0:
		radius = _get_warhead_splash_radius()
	if radius <= 0.0:
		return
	var radius_sq := radius * radius
	var groups := ["units", "building", "hq"]
	for group_name in groups:
		for node in get_tree().get_nodes_in_group(group_name):
			if node == primary or not (node is Node2D):
				continue
			if not node.has_method("take_damage"):
				continue
			if not _can_damage(node):
				continue
			var other := node as Node2D
			var dist_sq := global_position.distance_squared_to(other.global_position)
			if dist_sq > radius_sq:
				continue
			var dist := sqrt(dist_sq)
			var falloff := clampf(1.0 - (dist / radius), 0.0, 1.0)
			var amount := damage * splash_damage_scale * falloff
			if amount > 0.0:
				other.take_damage(amount, "missile")

func _can_damage(node: Node) -> bool:
	if team_id == "":
		return true
	var value: Variant = node.get("team_id")
	if value is String:
		return value != team_id
	return true

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("Missile: missing visual scene at %s" % visual_scene_path)
		return
	print("[Missile Visual] Loading: ", visual_scene_path, " | Type: ", packed.get_class())
	if packed is PackedScene:
		var instance = packed.instantiate()
		if instance is Node2D or instance is Node3D:
			_visual_node = instance
			add_child(_visual_node)
			_visual_node.visible = true  # Always visible for debugging
			_update_visual_transform()
			print("[Missile Visual] Successfully loaded as ", instance.get_class(), " | Scale: ", _visual_node.scale, " | Visible: ", _visual_node.visible)
		else:
			print("[Missile Visual] WARNING: Instantiated node is not Node2D/Node3D, it's: ", instance.get_class())
	else:
		print("[Missile Visual] WARNING: Not a PackedScene, it's: ", packed.get_class())

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	if visual_base_radius > 0.0:
		var scale := 1.0 / visual_base_radius
		if _visual_node is Node3D:
			_visual_node.scale = Vector3.ONE * scale
		else:
			_visual_node.scale = Vector2.ONE * scale
	if _visual_node is Node3D:
		# For 3D models, rotate around Y axis (vertical) to face direction
		_visual_node.rotation = Vector3(0, -_velocity.angle() + PI/2, 0)
	else:
		_visual_node.rotation = _velocity.angle()

func _update_visual_rotation() -> void:
	if _visual_node == null:
		return
	if _visual_node is Node3D:
		# Calculate pitch based on ballistic velocity if active
		var pitch := 0.0
		if ballistic_arc > 0.0 and _initial_distance > 0.0:
			# Tilt missile based on vertical velocity
			var horizontal_speed := speed
			if horizontal_speed > 0.0:
				pitch = atan2(_ballistic_velocity_z, horizontal_speed)
		_visual_node.rotation = Vector3(pitch, -_velocity.angle() + PI/2, 0)
	else:
		_visual_node.rotation = _velocity.angle()

func _init_ballistic_arc() -> void:
	if ballistic_arc <= 0.0 or _target_pos == Vector2.ZERO:
		return

	# Calculate proper ballistic trajectory
	# We want the missile to reach peak height at midpoint and land at target
	# Use average speed (between 50% and 150%) for flight time estimate
	var avg_speed := _base_speed if _base_speed > 0.0 else speed
	var flight_time := _initial_distance / avg_speed if avg_speed > 0.0 else 1.0

	# For a parabolic arc: h = (v0 * t/2) - (g * (t/2)^2) / 2
	# At peak (t/2): v_vertical = 0
	# So: v0 = g * t/2
	# And: h = (g * t/2) * (t/2) - (g * (t/2)^2) / 2 = g * t^2 / 8
	# Therefore: g = 8h / t^2
	var gravity := (8.0 * ballistic_arc) / (flight_time * flight_time)

	# Initial vertical velocity to reach peak at midpoint
	_ballistic_velocity_z = gravity * (flight_time * 0.5)

func _update_ballistic_arc(delta: float) -> void:
	if ballistic_arc <= 0.0 or _target_pos == Vector2.ZERO or _initial_distance <= 0.0:
		return

	# Use distance-based parabolic arc instead of time-based physics
	# This ensures the missile lands at the target regardless of speed changes
	var dist_to_target := global_position.distance_to(_target_pos)
	var progress := 1.0 - clampf(dist_to_target / _initial_distance, 0.0, 1.0)

	# Parabolic arc: height = 4h * progress * (1 - progress)
	# This creates a perfect parabola that starts at 0, peaks at 0.5, and returns to 0 at 1.0
	var arc_height := 4.0 * ballistic_arc * progress * (1.0 - progress)
	_ballistic_height = arc_height

	# Calculate vertical velocity for visual rotation (derivative of parabola)
	# d/dx[4h * x * (1 - x)] = 4h * (1 - 2x)
	var velocity_factor := 4.0 * ballistic_arc * (1.0 - 2.0 * progress)
	_ballistic_velocity_z = velocity_factor

	# Accelerate missile based on height (50% at peak, 150% at ground)
	if _base_speed > 0.0:
		var height_ratio := clampf(_ballistic_height / ballistic_arc, 0.0, 1.0)
		# At peak (height_ratio = 1.0): speed_mult = 0.5
		# At ground (height_ratio = 0.0): speed_mult = 1.5
		var speed_mult := lerpf(1.5, 0.5, height_ratio)
		speed = _base_speed * speed_mult

func set_visual_scene_path(path: String) -> void:
	visual_scene_path = path

func intercept() -> void:
	if _intercepted:
		return
	_intercepted = true
	# Emit impact at current position (for explosion visual)
	emit_signal("impact", global_position, color, warhead_size, "intercepted")
	queue_free()

func is_interceptable() -> bool:
	return interceptable and not _intercepted

func get_intercept_difficulty() -> float:
	return intercept_difficulty
