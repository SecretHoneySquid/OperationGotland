extends Node
class_name VisualEffectsManager

## Visual Effects Manager
##
## Handles all visual effects including tracers, impacts, explosions, and smoke
## Manages effect lifecycles and signal connections

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Tracer Settings")
@export var tracer_follow_terrain := true
@export var tracer_height := 6.0
@export var tracer_width_scale := 0.4
@export var tracer_min_width := 0.5

@export_group("Impact Settings")
@export var impact_enabled := true
@export var impact_follow_terrain := true
@export var impact_height := 6.2
@export var impact_flash_size := 1.4
@export var impact_flash_duration := 0.16

@export_group("Missile Impact Settings")
@export var missile_impact_flash_size := 2.8
@export var missile_impact_duration := 0.35
@export var aircraft_missile_impact_scale := 1.8
@export var aircraft_missile_impact_duration := 0.45
@export var aircraft_missile_shockwave_size := 2.6
@export var aircraft_missile_shockwave_duration := 0.4

@export_group("Missile Impact Smoke")
@export var aircraft_missile_smoke_burst := 7
@export var aircraft_missile_smoke_color := Color(0.2, 0.2, 0.2, 0.6)
@export var aircraft_missile_smoke_size := 2.4
@export var aircraft_missile_smoke_duration := 0.9
@export var aircraft_missile_smoke_spread := 2.2

@export_group("Missile Trail Smoke")
@export var missile_smoke_enabled := true
@export var missile_smoke_color := Color(0.9, 0.9, 0.9, 0.35)
@export var missile_smoke_size := 1.4
@export var missile_smoke_duration := 0.25
@export var missile_smoke_interval := 0.05
@export var missile_smoke_spread := 0.35
@export var missile_smoke_grow := 2.0
@export var missile_smoke_height_offset := 0.0
@export var missile_smoke_use_warhead_scale := true
@export var missile_body_length := 4.0

@export_group("Warhead Scales")
@export var missile_small_scale := 0.6
@export var missile_medium_scale := 1.0
@export var missile_large_scale := 1.6

# =============================================================================
# STATE
# =============================================================================

var _tracers: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _smokes: Array[Dictionary] = []
var _missile_trails: Dictionary = {}
var _shot_connected: Dictionary = {}
var _missile_connected: Dictionary = {}

var _smoke_rng := RandomNumberGenerator.new()
var _parent_node: Node3D = null
var _ground_getter: Callable = Callable()
var _frame_delta: float = 0.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func setup(parent: Node3D, ground_height_getter: Callable) -> void:
	_parent_node = parent
	_ground_getter = ground_height_getter
	_smoke_rng.randomize()

# =============================================================================
# SIGNAL CONNECTIONS
# =============================================================================

func ensure_shot_connection(node: Node, id: int) -> void:
	if _shot_connected.has(id):
		return
	if not node.has_signal("shot_fired"):
		return
	var callable := Callable(self, "_on_unit_shot")
	if node.is_connected("shot_fired", callable):
		_shot_connected[id] = true
		return
	node.connect("shot_fired", callable)
	_shot_connected[id] = true

func ensure_missile_connection(node: Node, id: int) -> void:
	if _missile_connected.has(id):
		return
	if not node.has_signal("impact"):
		return
	var callable := Callable(self, "_on_missile_impact")
	if node.is_connected("impact", callable):
		_missile_connected[id] = true
		return
	node.connect("impact", callable)
	_missile_connected[id] = true

func _on_unit_shot(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, lifetime: float) -> void:
	spawn_tracer(start_pos, end_pos, color, width, lifetime)
	spawn_impact(end_pos, color, width)

func _on_missile_impact(pos: Vector2, color: Color, warhead_size: String, source_kind: String) -> void:
	spawn_missile_impact(pos, color, warhead_size, source_kind)

# =============================================================================
# TRACER EFFECTS
# =============================================================================

func spawn_tracer(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, lifetime: float) -> void:
	if _parent_node == null:
		return

	var start_y := tracer_height
	var end_y := tracer_height
	if tracer_follow_terrain and _ground_getter.is_valid():
		start_y += _ground_getter.call(start_pos)
		end_y += _ground_getter.call(end_pos)

	var start3 := Vector3(start_pos.x, start_y, start_pos.y)
	var end3 := Vector3(end_pos.x, end_y, end_pos.y)
	var delta := end3 - start3
	var line_length := delta.length()
	if line_length <= 0.1:
		return

	var root := Node3D.new()
	_parent_node.add_child(root)
	root.global_position = (start3 + end3) * 0.5
	root.look_at(end3, Vector3.UP)

	var thickness := maxf(tracer_min_width, width * tracer_width_scale)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, thickness, line_length)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := VisualUtilities.make_tracer_material(color)
	instance.material_override = material
	root.add_child(instance)

	var tracer: Dictionary = {
		"node": root,
		"material": material,
		"time": 0.0,
		"duration": maxf(0.05, lifetime),
		"alpha": color.a,
	}
	_tracers.append(tracer)

func update_tracers(delta: float) -> void:
	_frame_delta = delta
	if _tracers.is_empty():
		return

	var alive: Array[Dictionary] = []
	for tracer in _tracers:
		var node: Node3D = tracer.get("node") as Node3D
		var material: StandardMaterial3D = tracer.get("material") as StandardMaterial3D
		var duration: float = float(tracer.get("duration", 0.0))
		var time: float = float(tracer.get("time", 0.0)) + delta
		if node == null or not is_instance_valid(node) or duration <= 0.0 or time >= duration:
			if node != null and is_instance_valid(node):
				node.queue_free()
			continue

		var alpha: float = float(tracer.get("alpha", 1.0))
		var t := clampf(1.0 - (time / duration), 0.0, 1.0)
		if material != null:
			var col := material.albedo_color
			col.a = alpha * t
			material.albedo_color = col

		tracer["time"] = time
		alive.append(tracer)
	_tracers = alive

# =============================================================================
# IMPACT EFFECTS
# =============================================================================

func spawn_impact(end_pos: Vector2, color: Color, width: float) -> void:
	spawn_impact_custom(end_pos, color, width, impact_flash_duration, impact_flash_size)

func spawn_missile_impact(end_pos: Vector2, color: Color, warhead_size: String, source_kind: String) -> void:
	var scale: float = VisualUtilities.warhead_scale(warhead_size, missile_small_scale, missile_medium_scale, missile_large_scale)

	# Main flash
	var flash_width: float = missile_impact_flash_size * scale * 6.0
	var flash_color: Color = color.lightened(0.35)
	flash_color.a = clampf(color.a, 0.5, 0.95)
	spawn_impact_custom(end_pos, flash_color, flash_width, missile_impact_duration, missile_impact_flash_size * scale)

	# Aircraft-specific enhanced effects
	if source_kind != "aircraft":
		return

	var boost_scale: float = maxf(0.1, aircraft_missile_impact_scale)
	var effect_scale: float = scale * boost_scale

	# Hot core
	var hot_color: Color = color.lightened(0.55)
	hot_color.a = clampf(color.a, 0.55, 0.95)
	var hot_width: float = missile_impact_flash_size * effect_scale * 8.5
	spawn_impact_custom(end_pos, hot_color, hot_width, aircraft_missile_impact_duration, missile_impact_flash_size * effect_scale)

	# Shockwave
	var shock_color: Color = color.lightened(0.2)
	shock_color.a = clampf(color.a * 0.75, 0.35, 0.85)
	var shock_width: float = aircraft_missile_shockwave_size * effect_scale * 7.5
	spawn_impact_custom(end_pos, shock_color, shock_width, aircraft_missile_shockwave_duration, aircraft_missile_shockwave_size * effect_scale)

	# Smoke burst
	var impact_y := impact_height
	if impact_follow_terrain and _ground_getter.is_valid():
		impact_y += _ground_getter.call(end_pos)

	var smoke_pos := Vector3(end_pos.x, impact_y + 0.25, end_pos.y)
	var burst: int = maxi(0, aircraft_missile_smoke_burst)
	if burst > 0:
		var spread: float = aircraft_missile_smoke_spread * effect_scale
		spawn_smoke_burst(smoke_pos, burst, aircraft_missile_smoke_color, aircraft_missile_smoke_size * effect_scale, aircraft_missile_smoke_duration, spread)

	spawn_smoke(smoke_pos, aircraft_missile_smoke_color, aircraft_missile_smoke_size * effect_scale * 1.4, aircraft_missile_smoke_duration * 1.15)

func spawn_impact_custom(
	end_pos: Vector2,
	color: Color,
	width: float,
	duration: float,
	base_size: float
) -> void:
	if not impact_enabled:
		return
	if _parent_node == null:
		return

	var root := Node3D.new()
	_parent_node.add_child(root)

	var impact_y := impact_height
	if impact_follow_terrain and _ground_getter.is_valid():
		impact_y += _ground_getter.call(end_pos)

	root.global_position = Vector3(end_pos.x, impact_y, end_pos.y)

	var flash_radius := maxf(0.35, base_size + width * 0.15)
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	flash.mesh = sphere

	var flash_color := color.lightened(0.25)
	flash_color.a = clampf(color.a, 0.4, 0.95)
	var material := VisualUtilities.make_fx_material(flash_color)
	flash.material_override = material
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(flash)
	root.scale = Vector3.ONE * flash_radius

	var impact: Dictionary = {
		"node": root,
		"material": material,
		"time": 0.0,
		"duration": maxf(0.06, duration),
		"alpha": flash_color.a,
		"start_scale": flash_radius,
	}
	_impacts.append(impact)

func update_impacts(delta: float) -> void:
	if _impacts.is_empty():
		return

	var alive: Array[Dictionary] = []
	for impact in _impacts:
		var node: Node3D = impact.get("node") as Node3D
		var material: StandardMaterial3D = impact.get("material") as StandardMaterial3D
		var duration: float = float(impact.get("duration", 0.0))
		var time: float = float(impact.get("time", 0.0)) + delta
		if node == null or not is_instance_valid(node) or duration <= 0.0 or time >= duration:
			if node != null and is_instance_valid(node):
				node.queue_free()
			continue

		var alpha: float = float(impact.get("alpha", 1.0))
		var t := clampf(1.0 - (time / duration), 0.0, 1.0)
		if material != null:
			var col := material.albedo_color
			col.a = alpha * t
			material.albedo_color = col

		var start_scale := float(impact.get("start_scale", 1.0))
		var scale := start_scale * (0.7 + t * 0.3)
		node.scale = Vector3.ONE * scale

		impact["time"] = time
		alive.append(impact)
	_impacts = alive

# =============================================================================
# SMOKE EFFECTS
# =============================================================================

func spawn_smoke(pos: Vector3, color: Color, size: float, duration: float) -> void:
	if duration <= 0.0:
		return
	if _parent_node == null:
		return

	var root := Node3D.new()
	_parent_node.add_child(root)
	root.global_position = pos

	var puff := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	puff.mesh = sphere

	var smoke_color := color
	smoke_color.a = clampf(smoke_color.a, 0.1, 0.9)
	var material := VisualUtilities.make_fx_material(smoke_color)
	puff.material_override = material
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(puff)
	root.scale = Vector3.ONE * maxf(0.1, size)

	var smoke: Dictionary = {
		"node": root,
		"material": material,
		"time": 0.0,
		"duration": duration,
		"alpha": smoke_color.a,
		"start_scale": maxf(0.1, size),
	}
	_smokes.append(smoke)

func spawn_smoke_burst(pos: Vector3, count: int, color: Color, size: float, duration: float, spread: float) -> void:
	if count <= 0 or duration <= 0.0:
		return

	var spread_radius: float = maxf(0.0, spread)
	for i in range(count):
		var offset := Vector3.ZERO
		if spread_radius > 0.0:
			offset = Vector3(
				_smoke_rng.randf_range(-spread_radius, spread_radius),
				_smoke_rng.randf_range(-spread_radius, spread_radius) * 0.2,
				_smoke_rng.randf_range(-spread_radius, spread_radius)
			)
		spawn_smoke(pos + offset, color, size, duration)

func update_smokes(delta: float) -> void:
	if _smokes.is_empty():
		return

	var alive: Array[Dictionary] = []
	for smoke in _smokes:
		var node: Node3D = smoke.get("node") as Node3D
		var material: StandardMaterial3D = smoke.get("material") as StandardMaterial3D
		var duration: float = float(smoke.get("duration", 0.0))
		var time: float = float(smoke.get("time", 0.0)) + delta
		if node == null or not is_instance_valid(node) or duration <= 0.0 or time >= duration:
			if node != null and is_instance_valid(node):
				node.queue_free()
			continue

		var alpha: float = float(smoke.get("alpha", 1.0))
		var t := clampf(time / duration, 0.0, 1.0)
		if material != null:
			var col := material.albedo_color
			col.a = alpha * (1.0 - t)
			material.albedo_color = col

		var start_scale := float(smoke.get("start_scale", 1.0))
		var end_scale := start_scale * maxf(1.0, missile_smoke_grow)
		var scale := lerpf(start_scale, end_scale, t)
		node.scale = Vector3.ONE * scale

		smoke["time"] = time
		alive.append(smoke)
	_smokes = alive

# =============================================================================
# MISSILE TRAILS
# =============================================================================

func update_missile_trail(missile, proxy: Node3D, id: int) -> void:
	if not missile_smoke_enabled:
		return

	var info: Dictionary = _missile_trails.get(id, {})
	var timer := float(info.get("timer", 0.0)) - _frame_delta
	if timer > 0.0:
		info["timer"] = timer
		_missile_trails[id] = info
		return

	info["timer"] = maxf(0.01, missile_smoke_interval)
	_missile_trails[id] = info

	var scale := VisualUtilities.get_missile_scale(missile, missile_small_scale, missile_medium_scale, missile_large_scale)
	if not missile_smoke_use_warhead_scale:
		scale = 1.0

	var pos := proxy.global_position
	var velocity: Variant = missile.get("_velocity")
	if velocity is Vector2 and velocity.length() > 0.1:
		var back := Vector3(-velocity.x, 0.0, -velocity.y).normalized()
		pos += back * (missile_body_length * 0.3 * scale)

	if missile_smoke_spread > 0.0:
		var jitter := Vector3(
			_smoke_rng.randf_range(-missile_smoke_spread, missile_smoke_spread),
			_smoke_rng.randf_range(-missile_smoke_spread, missile_smoke_spread) * 0.4,
			_smoke_rng.randf_range(-missile_smoke_spread, missile_smoke_spread)
		)
		pos += jitter

	pos.y += missile_smoke_height_offset
	var smoke_color := missile_smoke_color
	var source_kind := ""
	var source_value: Variant = missile.get("source_kind")
	if source_value is String:
		source_kind = source_value
	if source_kind == "aircraft":
		var trail_value: Variant = missile.get("trail_color")
		if trail_value is Color:
			smoke_color = trail_value
	spawn_smoke(pos, smoke_color, missile_smoke_size * scale, missile_smoke_duration)

# =============================================================================
# UPDATE ALL EFFECTS
# =============================================================================

func update_all(delta: float) -> void:
	_frame_delta = delta
	update_tracers(delta)
	update_impacts(delta)
	update_smokes(delta)

# =============================================================================
# CLEANUP
# =============================================================================

func cleanup_connection(id: int) -> void:
	_shot_connected.erase(id)
	_missile_connected.erase(id)
	_missile_trails.erase(id)
