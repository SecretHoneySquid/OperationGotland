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

var target: Node2D
var _velocity := Vector2.RIGHT
var _origin := Vector2.ZERO

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
	_apply_warhead_settings()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var effective_range := max_distance
	if range > 0.0:
		effective_range = range
	if _origin != Vector2.ZERO and effective_range > 0.0:
		if global_position.distance_squared_to(_origin) > effective_range * effective_range:
			queue_free()
			return
	if target != null and is_instance_valid(target):
		var desired := target.global_position - global_position
		if desired.length_squared() > 0.1:
			var desired_dir := desired.normalized()
			if _velocity.length_squared() < 0.1:
				_velocity = desired_dir
			else:
				var angle := _velocity.angle_to(desired_dir)
				var max_turn := turn_rate * delta
				_velocity = _velocity.rotated(clampf(angle, -max_turn, max_turn))
		_check_hit(target)
	global_position += _velocity.normalized() * speed * delta
	queue_redraw()

func _check_hit(target_node: Node2D) -> void:
	if global_position.distance_squared_to(target_node.global_position) <= hit_radius * hit_radius:
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage)
		_apply_splash_damage(target_node)
		emit_signal("impact", global_position, color, warhead_size, source_kind)
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
				other.take_damage(amount)

func _can_damage(node: Node) -> bool:
	if team_id == "":
		return true
	var value: Variant = node.get("team_id")
	if value is String:
		return value != team_id
	return true
