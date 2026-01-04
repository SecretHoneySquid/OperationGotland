class_name DefenseTurret
extends Node2D

signal shot_fired(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, lifetime: float)

@export var team_id := "p1"
@export var attack_range := 260.0
@export var damage := 10.0
@export var fire_rate := 0.8
@export var hitscan_enabled := false
@export var shot_tracer_enabled := true
@export var shot_color := Color(1.0, 0.9, 0.6, 0.85)
@export var shot_width := 2.5
@export var shot_lifetime := 0.16
@export var missile_speed := 260.0
@export var missile_turn_rate := 10.0
@export var missile_lifetime := 4.0
@export var missile_hit_radius := 0.0
@export var missile_color := Color(1.0, 0.6, 0.2, 1.0)
@export var missile_warhead_size := "medium"
@export var prefers_infantry := false
@export var prefers_vehicle := false
@export var damage_vs_infantry := 1.0
@export var damage_vs_vehicle := 1.0
@export var damage_vs_structure := 1.0
@export var base_radius := 16.0
@export var barrel_length := 18.0
@export var base_color := Color(0.6, 0.6, 0.6, 1.0):
	set(value):
		base_color = value
		_update_visual_color()
		queue_redraw()
@export var visual_scene_path := ""
@export var visual_base_radius := 16.0
@export var visual_offset := Vector2.ZERO
@export var render_2d := true

var _cooldown := 0.0
var _target: Node2D
var _facing := Vector2.RIGHT
var _visual_node: Node2D

func _ready() -> void:
	add_to_group("defense_turret")
	add_to_group("defense_turret_%s" % team_id)
	_setup_visual()

func update_targeting(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _target == null or not is_instance_valid(_target):
		_target = _find_target()
	if _target == null:
		return
	var to_target := _target.global_position - global_position
	if to_target.length_squared() > attack_range * attack_range:
		_target = null
		return
	_facing = to_target.normalized()
	_sync_visual_rotation()
	if _cooldown <= 0.0:
		if hitscan_enabled:
			_fire_hitscan()
		else:
			_fire_missile()
		_cooldown = fire_rate
	queue_redraw()

func _find_target() -> Node2D:
	var best: Unit = null
	var best_priority := 999
	var best_dist := attack_range * attack_range
	for node in get_tree().get_nodes_in_group("units"):
		if node is Unit and node.team_id != team_id:
			var dist := global_position.distance_squared_to(node.global_position)
			if dist > best_dist:
				continue
			var priority := _target_priority(node)
			if priority < best_priority or (priority == best_priority and dist < best_dist):
				best_dist = dist
				best_priority = priority
				best = node
	return best

func _target_priority(enemy: Unit) -> int:
	var priority := 0
	if prefers_vehicle and (enemy.unit_kind == "vehicle" or enemy.unit_kind == "aircraft"):
		priority -= 2
	if prefers_infantry and enemy.unit_kind == "infantry":
		priority -= 2
	return priority

func _fire_missile() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var missile := Missile.new()
	missile.speed = missile_speed
	var final_damage := damage
	if _target is Unit:
		var enemy := _target as Unit
		if enemy.unit_kind == "vehicle" or enemy.unit_kind == "aircraft":
			final_damage *= damage_vs_vehicle
		else:
			final_damage *= damage_vs_infantry
	else:
		final_damage *= damage_vs_structure
	missile.damage = final_damage
	missile.turn_rate = missile_turn_rate
	missile.lifetime = missile_lifetime
	missile.warhead_size = missile_warhead_size
	var hit := missile_hit_radius
	if hit <= 0.0:
		hit = missile.get_warhead_radius()
	missile.hit_radius = hit
	missile.range = attack_range
	missile.max_distance = attack_range
	missile.team_id = team_id
	missile.color = missile_color
	missile.target = _target
	missile.global_position = global_position + (_facing * (base_radius + 4.0))
	missile.set_origin(global_position)
	if get_parent() != null:
		get_parent().add_child(missile)

func _fire_hitscan() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var final_damage := damage
	if _target is Unit:
		var enemy := _target as Unit
		if enemy.unit_kind == "vehicle" or enemy.unit_kind == "aircraft":
			final_damage *= damage_vs_vehicle
		else:
			final_damage *= damage_vs_infantry
	else:
		final_damage *= damage_vs_structure
	if _target.has_method("take_damage"):
		_target.take_damage(final_damage, "turret")
	if shot_tracer_enabled and _target is Node2D:
		var target_pos: Vector2 = (_target as Node2D).global_position
		_spawn_tracer(target_pos)
		emit_signal("shot_fired", global_position, target_pos, shot_color, shot_width, shot_lifetime)

func _spawn_tracer(target_pos: Vector2) -> void:
	var tracer := ShotTracer.new()
	tracer.duration = shot_lifetime
	tracer.width = shot_width
	tracer.color = shot_color
	tracer.set_points(global_position, target_pos)
	if get_parent() != null:
		get_parent().add_child(tracer)

func _draw() -> void:
	if not render_2d:
		return
	if _visual_node == null:
		var base_col := base_color
		draw_circle(Vector2(2.0, 3.0), base_radius * 0.95, Color(0.0, 0.0, 0.0, 0.25))
		var hull := _get_base_points()
		var base_points := _transform_points(hull, 0.0, base_radius)
		var top_points := _transform_points(hull, 0.0, base_radius * 0.72, Vector2(-1.0, -1.0))
		draw_colored_polygon(base_points, _shade(base_col, -0.08))
		draw_colored_polygon(top_points, _shade(base_col, 0.14))
		var outline := base_points.duplicate()
		if outline.size() > 0:
			outline.append(base_points[0])
			draw_polyline(outline, _shade(base_col, -0.35), 1.6)
		var turret_color := _shade(base_col, 0.2)
		draw_circle(Vector2.ZERO, base_radius * 0.3, turret_color)
		draw_line(Vector2.ZERO, _facing * barrel_length, _shade(base_col, 0.35), 3.0)

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("Turret: missing visual scene at %s" % visual_scene_path)
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
		push_warning("Turret: visual scene is not a PackedScene at %s" % visual_scene_path)

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	_visual_node.position = visual_offset
	if visual_base_radius > 0.0:
		var scale := base_radius / visual_base_radius
		_visual_node.scale = Vector2.ONE * scale

func _update_visual_color() -> void:
	if _visual_node == null:
		return
	_visual_node.modulate = base_color

func _sync_visual_rotation() -> void:
	if _visual_node == null:
		return
	_visual_node.rotation = _facing.angle()

func set_render_2d(value: bool) -> void:
	render_2d = value
	_set_canvas_children_visible(value)
	queue_redraw()

func _set_canvas_children_visible(value: bool) -> void:
	for child in get_children():
		if child is CanvasItem:
			child.visible = value

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

func _get_base_points() -> Array:
	return [
		Vector2(1.0, 0.0),
		Vector2(0.7, -0.7),
		Vector2(0.0, -1.0),
		Vector2(-0.7, -0.7),
		Vector2(-1.0, 0.0),
		Vector2(-0.7, 0.7),
		Vector2(0.0, 1.0),
		Vector2(0.7, 0.7),
	]
