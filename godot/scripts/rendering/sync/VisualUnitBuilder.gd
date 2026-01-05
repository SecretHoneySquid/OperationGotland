extends Node
class_name VisualUnitBuilder

## Visual Unit Builder
##
## Handles building visual proxies for units (vehicles, aircraft, infantry)
## Creates 3D representations including collectors and missiles

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Unit Heights")
@export var unit_height := 6.0
@export var vehicle_height := 10.0
@export var collector_height := 7.0

@export_group("Aircraft Settings")
@export var aircraft_height := 160.0
@export var aircraft_height_smooth := 4.0
@export var aircraft_follow_terrain := false
@export var aircraft_base_height := 220.0

@export_group("Aircraft Model - Gripen")
@export var aircraft_model_path := "res://assets/models/gripen.glb"
@export var aircraft_model_scale := 1.0
@export var aircraft_model_rotation := Vector3(0.0, 90.0, 0.0)
@export var aircraft_model_offset := Vector3.ZERO

@export_group("Aircraft Model - F-35")
@export var aircraft_model_path_f35 := "res://assets/models/f-35_lightning_ii_-_fighter_jet_-_free.glb"
@export var aircraft_model_scale_f35 := 1.0
@export var aircraft_model_rotation_f35 := Vector3(0.0, 90.0, 0.0)
@export var aircraft_model_offset_f35 := Vector3.ZERO

@export_group("Aircraft Banking")
@export var aircraft_bank_enabled := true
@export var aircraft_bank_max_deg := 32.0
@export var aircraft_bank_strength := 0.45
@export var aircraft_bank_smooth := 6.0

@export_group("Aircraft Roll")
@export var aircraft_roll_enabled := true
@export var aircraft_roll_interval_min := 10.0
@export var aircraft_roll_interval_max := 20.0
@export var aircraft_roll_duration := 1.6
@export var aircraft_roll_min_altitude := 0.4

@export_group("Aircraft Afterburner Smoke")
@export var aircraft_afterburner_smoke_enabled := true
@export var aircraft_afterburner_smoke_interval := 0.12
@export var aircraft_afterburner_smoke_color := Color(0.9, 0.9, 0.95, 0.5)
@export var aircraft_afterburner_smoke_size := 1.1
@export var aircraft_afterburner_smoke_duration := 0.6
@export var aircraft_afterburner_smoke_spread := 1.0
@export var aircraft_afterburner_smoke_offset := 8.0
@export var aircraft_afterburner_smoke_height_offset := -1.5

@export_group("Missile Settings")
@export var missile_height := 6.0
@export var missile_body_radius := 0.7
@export var missile_body_length := 4.6
@export var missile_nose_length := 1.6
@export var missile_fin_length := 1.2
@export var missile_fin_thickness := 0.25
@export var missile_model_path := "res://scenes/props/missile_visual.tscn"
@export var missile_model_scale := 1.0

@export_group("Missile Warhead Scales")
@export var missile_small_scale := 1.0
@export var missile_medium_scale := 1.35
@export var missile_large_scale := 1.7

@export_group("Health Bar Settings")
@export var show_unit_health := true
@export var unit_health_selected_only := false
@export var unit_health_height := 4.0
@export var unit_health_offset := 6.0
@export var unit_health_width_scale := 2.4

@export_group("Selection Ring Settings")
@export var selection_ring_vehicle_scale := 1.5
@export var selection_ring_infantry_scale := 1.1

# =============================================================================
# UNIT PROXY BUILDERS
# =============================================================================

func build_unit_proxy(proxy: Node3D, unit, ui_overlays: VisualUIOverlays) -> void:
	var radius := maxf(3.0, VisualUtilities.get_float(unit, "body_radius", 6.0))
	var unit_kind := str(VisualUtilities.get_value(unit, "unit_kind", "infantry"))
	var base_color := VisualUtilities.get_color(unit, "color", Color(0.7, 0.7, 0.7, 1.0))

	if unit_kind == "vehicle":
		_build_vehicle(proxy, radius, base_color)
		if show_unit_health:
			var hull_height := vehicle_height * 0.45
			var turret_section := vehicle_height * 0.25
			var bar_width := maxf(12.0, radius * unit_health_width_scale)
			var bar_height := hull_height + turret_section + (radius * 0.6)
			ui_overlays.attach_health_bar(proxy, bar_width, bar_height, unit_health_height, unit_health_offset)
		ui_overlays.attach_selection_ring(proxy, radius * selection_ring_vehicle_scale, base_color)

	elif unit_kind == "aircraft":
		_build_aircraft(proxy, unit, radius, base_color)
		if show_unit_health:
			var bar_width := maxf(14.0, radius * unit_health_width_scale * 1.1)
			var model_height := _get_aircraft_model_height(proxy)
			var body_height := maxf(1.4, radius * 0.7)
			var bar_height := model_height if model_height > 0.0 else body_height + body_height * 1.2
			ui_overlays.attach_health_bar(proxy, bar_width, bar_height, unit_health_height, unit_health_offset)
		ui_overlays.attach_selection_ring(proxy, radius * selection_ring_vehicle_scale * 1.2, base_color)

	else:
		_build_infantry(proxy, radius, unit, base_color)
		if show_unit_health:
			var body_radius := radius * 0.35
			var body_height := maxf(2.0, unit_height * 0.6)
			var total_height := body_height + (body_radius * 2.0)
			var head_radius := body_radius * 0.7
			var bar_width := maxf(10.0, radius * unit_health_width_scale)
			var bar_height := total_height + head_radius * 0.8
			ui_overlays.attach_health_bar(proxy, bar_width, bar_height, unit_health_height, unit_health_offset)
		ui_overlays.attach_selection_ring(proxy, radius * selection_ring_infantry_scale, base_color)

func build_collector_proxy(proxy: Node3D, collector) -> void:
	var radius := maxf(3.0, VisualUtilities.get_float(collector, "body_radius", 6.0))
	var height := collector_height
	var base_color := VisualUtilities.get_color(collector, "color", Color(0.7, 0.7, 0.7, 1.0))

	var base_height := height * 0.45
	var base := VisualUtilities.make_box(Vector3(radius * 2.0, base_height, radius * 2.4), base_color.darkened(0.08))
	base.position = Vector3(0, base_height * 0.5, 0)
	proxy.add_child(base)

	var cab := VisualUtilities.make_box(Vector3(radius * 1.0, base_height * 0.7, radius * 1.0), base_color.lightened(0.1))
	cab.position = Vector3(0, base_height * 0.9, -radius * 0.4)
	proxy.add_child(cab)

	var tank := VisualUtilities.make_cylinder(radius * 0.5, height * 0.5, base_color.lightened(0.2))
	tank.position = Vector3(0, base_height + height * 0.25, radius * 0.4)
	proxy.add_child(tank)

func build_missile_proxy(proxy: Node3D, missile) -> void:
	var base_color := VisualUtilities.get_color(missile, "color", Color(0.9, 0.55, 0.2, 1.0))
	var scale := VisualUtilities.get_missile_scale(missile, missile_small_scale, missile_medium_scale, missile_large_scale)

	if _add_missile_model(proxy, missile, base_color, scale):
		return

	var body_radius := missile_body_radius * scale
	var body_length := missile_body_length * scale
	var nose_length := missile_nose_length * scale
	var fin_length := missile_fin_length * scale
	var fin_thickness := missile_fin_thickness * scale

	var body := VisualUtilities.make_cylinder(body_radius, body_length, base_color)
	body.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	proxy.add_child(body)

	var nose := VisualUtilities.make_cone(body_radius, nose_length, base_color.lightened(0.2))
	nose.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	nose.position = Vector3(0.0, 0.0, -body_length * 0.5 - nose_length * 0.5)
	proxy.add_child(nose)

	var tail_offset := body_length * 0.5 - fin_length * 0.45
	var fin_color := base_color.darkened(0.2)

	var fin_a := VisualUtilities.make_box(Vector3(body_radius * 2.4, fin_thickness, fin_length), fin_color)
	fin_a.position = Vector3(0.0, 0.0, tail_offset)
	proxy.add_child(fin_a)

	var fin_b := VisualUtilities.make_box(Vector3(fin_thickness, body_radius * 2.4, fin_length), fin_color)
	fin_b.position = Vector3(0.0, 0.0, tail_offset)
	proxy.add_child(fin_b)

	var exhaust := VisualUtilities.make_sphere(body_radius * 0.35, base_color.lightened(0.4))
	exhaust.position = Vector3(0.0, 0.0, body_length * 0.5 + body_radius * 0.2)
	proxy.add_child(exhaust)

# =============================================================================
# VEHICLE BUILDER
# =============================================================================

func _build_vehicle(proxy: Node3D, radius: float, base_color: Color) -> void:
	var hull_height := vehicle_height * 0.45
	var hull_size := Vector3(radius * 2.1, hull_height, radius * 2.6)
	var hull := VisualUtilities.make_box(hull_size, base_color.darkened(0.12))
	hull.position = Vector3(0, hull_height * 0.5, 0)
	proxy.add_child(hull)

	var cabin := VisualUtilities.make_box(Vector3(radius * 1.3, hull_height * 0.6, radius * 1.2), base_color.lightened(0.12))
	cabin.position = Vector3(0, hull_height * 0.9, -radius * 0.2)
	proxy.add_child(cabin)

	var turret_section := vehicle_height * 0.25
	var turret := VisualUtilities.make_cylinder(radius * 0.55, turret_section, base_color.lightened(0.2))
	turret.position = Vector3(0, hull_height + turret_section * 0.5, 0)
	proxy.add_child(turret)

	var barrel := VisualUtilities.make_cylinder(radius * 0.12, radius * 1.4, base_color.lightened(0.35))
	barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	barrel.position = Vector3(0, hull_height + turret_section * 0.6, -radius * 1.1)
	proxy.add_child(barrel)

	var track_size := Vector3(radius * 0.55, hull_height * 0.7, radius * 2.8)
	var track_color := base_color.darkened(0.35)
	var track_left := VisualUtilities.make_box(track_size, track_color)
	track_left.position = Vector3(-radius * 0.95, track_size.y * 0.5, 0)
	proxy.add_child(track_left)

	var track_right := VisualUtilities.make_box(track_size, track_color)
	track_right.position = Vector3(radius * 0.95, track_size.y * 0.5, 0)
	proxy.add_child(track_right)

# =============================================================================
# AIRCRAFT BUILDER
# =============================================================================

func _build_aircraft(proxy: Node3D, unit, radius: float, base_color: Color) -> void:
	var airframe := Node3D.new()
	airframe.name = "Airframe"
	proxy.add_child(airframe)
	proxy.set_meta("airframe", airframe)

	var type_id := str(VisualUtilities.get_value(unit, "unit_type", ""))
	# Use visual_scene_path from unit if available, otherwise fall back to hardcoded paths
	var visual_path := str(VisualUtilities.get_value(unit, "visual_scene_path", ""))
	var model_path := visual_path if visual_path != "" else aircraft_model_path
	var model_scale := aircraft_model_scale
	var model_rotation := aircraft_model_rotation
	var model_offset := aircraft_model_offset

	# Per-aircraft-type rotation settings
	if type_id == "f16":
		model_rotation = Vector3(0.0, 0.0, 0.0)  # F16: 270° + 90° right = 0°
	elif type_id == "gripen":
		model_rotation = Vector3(0.0, 90.0, 0.0)
	elif type_id == "f22":
		model_rotation = Vector3(0.0, 270.0, 0.0)  # F22: 0° - 90° left = 270°
	# Legacy fallback for F35
	elif type_id == "f35" and visual_path == "" and aircraft_model_path_f35 != "":
		model_path = aircraft_model_path_f35
		model_scale = aircraft_model_scale_f35
		model_rotation = aircraft_model_rotation_f35
		model_offset = aircraft_model_offset_f35

	var body_length := radius * 3.4
	var body_height := maxf(1.4, radius * 0.7)
	var body_width := radius * 0.6
	var wing_span := radius * 3.6
	var wing_depth := radius * 1.5

	var model_height := 0.0
	if model_path != "" and ResourceLoader.exists(model_path):
		var target_size := Vector2(wing_span, body_length)
		model_height = _add_scene_model(
			airframe,
			model_path,
			target_size,
			0.0,
			model_scale,
			model_offset,
			model_rotation
		)

	if model_height <= 0.0:
		_build_aircraft_fallback(airframe, base_color, body_width, body_height, body_length, wing_span, wing_depth)

func _build_aircraft_fallback(airframe: Node3D, base_color: Color, body_width: float, body_height: float, body_length: float, wing_span: float, wing_depth: float) -> void:
	var fuselage := VisualUtilities.make_box(Vector3(body_width, body_height, body_length), base_color)
	fuselage.position = Vector3(0, body_height * 0.5, 0)
	airframe.add_child(fuselage)

	var nose := VisualUtilities.make_cone(body_width * 0.55, body_height * 1.3, base_color.lightened(0.2))
	nose.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	nose.position = Vector3(0, body_height * 0.5, -body_length * 0.5 - body_height * 0.65)
	airframe.add_child(nose)

	var wing := VisualUtilities.make_box(Vector3(wing_span, body_height * 0.15, wing_depth), base_color.lightened(0.1))
	wing.position = Vector3(0, body_height * 0.35, -body_length * 0.05)
	airframe.add_child(wing)

	var tail_span := wing_span * 0.35
	var tail_depth := wing_depth * 0.55
	var tail := VisualUtilities.make_box(Vector3(tail_span, body_height * 0.12, tail_depth), base_color.lightened(0.15))
	tail.position = Vector3(0, body_height * 0.55, body_length * 0.35)
	airframe.add_child(tail)

	var fin := VisualUtilities.make_box(Vector3(body_width * 0.35, body_height * 0.9, body_width * 0.6), base_color.darkened(0.05))
	fin.position = Vector3(0, body_height * 0.5 + body_height * 0.45, body_length * 0.32)
	airframe.add_child(fin)

	var engine := VisualUtilities.make_cylinder(body_width * 0.3, body_height * 0.6, base_color.darkened(0.2))
	engine.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	engine.position = Vector3(0, body_height * 0.45, body_length * 0.45)
	airframe.add_child(engine)

func _get_aircraft_model_height(proxy: Node3D) -> float:
	if not proxy.has_meta("airframe"):
		return 0.0
	var airframe = proxy.get_meta("airframe")
	if airframe == null or not is_instance_valid(airframe):
		return 0.0
	for child in airframe.get_children():
		if child.has_meta("model_height"):
			return float(child.get_meta("model_height"))
	return 0.0

# =============================================================================
# INFANTRY BUILDER
# =============================================================================

func _build_infantry(proxy: Node3D, radius: float, unit, base_color: Color) -> void:
	var body_radius := radius * 0.35
	var body_height := maxf(2.0, unit_height * 0.6)
	var body := VisualUtilities.make_capsule(body_radius, body_height, base_color.darkened(0.1))
	var total_height := body_height + (body_radius * 2.0)
	body.position = Vector3(0, total_height * 0.5, 0)
	proxy.add_child(body)

	var head_radius := body_radius * 0.7
	var head := VisualUtilities.make_sphere(head_radius, base_color.lightened(0.25))
	head.position = Vector3(0, total_height + head_radius * 0.6, 0)
	proxy.add_child(head)

	var pack_size := Vector3(body_radius * 1.2, body_radius * 1.4, body_radius * 0.6)
	var pack := VisualUtilities.make_box(pack_size, base_color.darkened(0.35))
	pack.position = Vector3(0, total_height * 0.6, body_radius * 0.7)
	proxy.add_child(pack)

	var unit_type := str(VisualUtilities.get_value(unit, "unit_type", "rifle"))
	var weapon_len := radius * 1.1
	var weapon_thick := body_radius * 0.35

	if unit_type == "sniper":
		weapon_len = radius * 1.8
		weapon_thick = body_radius * 0.3
	elif unit_type == "rocket":
		weapon_len = radius * 1.4
		weapon_thick = body_radius * 0.55

	var weapon := VisualUtilities.make_box(Vector3(weapon_thick, weapon_thick, weapon_len), base_color.lightened(0.3))
	weapon.position = Vector3(0, total_height * 0.6, -weapon_len * 0.5 - body_radius * 0.2)
	proxy.add_child(weapon)

# =============================================================================
# MODEL LOADING HELPERS
# =============================================================================

func _add_missile_model(proxy: Node3D, missile, base_color: Color, scale: float) -> bool:
	# Use visual_scene_path from missile if available, otherwise fall back to hardcoded path
	var visual_path := str(VisualUtilities.get_value(missile, "visual_scene_path", ""))
	var model_path := visual_path if visual_path != "" else missile_model_path

	if model_path == "" or not ResourceLoader.exists(model_path):
		return false

	var target_size := Vector2(
		maxf(0.5, missile_body_radius * 2.6 * scale),
		maxf(0.5, (missile_body_length + missile_nose_length) * scale)
	)

	var model := _add_scene_model_instance(
		proxy,
		model_path,
		target_size,
		0.0,
		missile_model_scale
	)

	if model == null:
		return false

	_tint_model(model, base_color)
	return true

func _tint_model(root: Node3D, base_color: Color) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)

		if not (node is MeshInstance3D):
			continue

		var mesh_instance := node as MeshInstance3D
		var part := mesh_instance.name.to_lower()
		var part_color := base_color

		if part.find("nose") >= 0:
			part_color = base_color.lightened(0.2)
		elif part.find("fin") >= 0:
			part_color = base_color.darkened(0.2)
		elif part.find("exhaust") >= 0:
			part_color = base_color.lightened(0.4)

		mesh_instance.material_override = VisualUtilities.make_material(part_color)

func _add_scene_model(
	proxy: Node3D,
	scene_path: String,
	target_size: Vector2,
	target_height: float,
	scale_hint: float,
	offset := Vector3.ZERO,
	rotation_degrees := Vector3.ZERO
) -> float:
	var packed: Resource = load(scene_path)
	if packed == null or not (packed is PackedScene):
		return 0.0

	var instance := (packed as PackedScene).instantiate()
	if instance == null or not (instance is Node3D):
		return 0.0

	var model := instance as Node3D
	proxy.add_child(model)

	var bounds := _calc_model_aabb(model)
	if bounds.size == Vector3.ZERO:
		return 0.0

	var scale := scale_hint if scale_hint > 0.0 else 1.0
	if bounds.size.x > 0.0 and bounds.size.z > 0.0:
		scale *= minf(target_size.x / bounds.size.x, target_size.y / bounds.size.z)
	if target_height > 0.0 and bounds.size.y > 0.0:
		scale = minf(scale, target_height / bounds.size.y)

	model.scale = Vector3.ONE * scale
	var center := bounds.position + (bounds.size * 0.5)
	model.position = Vector3(-center.x * scale, -bounds.position.y * scale, -center.z * scale) + offset
	model.rotation_degrees = rotation_degrees

	var height := bounds.size.y * scale
	model.set_meta("model_height", height)
	return height

func _add_scene_model_instance(
	proxy: Node3D,
	scene_path: String,
	target_size: Vector2,
	target_height: float,
	scale_hint: float,
	offset := Vector3.ZERO,
	rotation_degrees := Vector3.ZERO
) -> Node3D:
	var packed: Resource = load(scene_path)
	if packed == null or not (packed is PackedScene):
		return null

	var instance := (packed as PackedScene).instantiate()
	if instance == null or not (instance is Node3D):
		return null

	var model := instance as Node3D
	proxy.add_child(model)

	var bounds := _calc_model_aabb(model)
	if bounds.size == Vector3.ZERO:
		return model

	var scale := scale_hint if scale_hint > 0.0 else 1.0
	if bounds.size.x > 0.0 and bounds.size.z > 0.0:
		scale *= minf(target_size.x / bounds.size.x, target_size.y / bounds.size.z)
	if target_height > 0.0 and bounds.size.y > 0.0:
		scale = minf(scale, target_height / bounds.size.y)

	model.scale = Vector3.ONE * scale
	var center := bounds.position + (bounds.size * 0.5)
	model.position = Vector3(-center.x * scale, -bounds.position.y * scale, -center.z * scale) + offset
	model.rotation_degrees = rotation_degrees

	return model

func _calc_model_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO
	var root_inv := root.global_transform.affine_inverse()

	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)

		if not (node is MeshInstance3D):
			continue

		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		var local_aabb := mesh_instance.mesh.get_aabb()
		var xform := root_inv * mesh_instance.global_transform

		for corner in _get_aabb_corners(local_aabb):
			var p := xform * corner
			if first:
				min_v = p
				max_v = p
				first = false
			else:
				min_v = Vector3(minf(min_v.x, p.x), minf(min_v.y, p.y), minf(min_v.z, p.z))
				max_v = Vector3(maxf(max_v.x, p.x), maxf(max_v.y, p.y), maxf(max_v.z, p.z))

	if first:
		return AABB()

	combined.position = min_v
	combined.size = max_v - min_v
	return combined

func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	var pos := aabb.position
	var size := aabb.size
	return [
		pos,
		pos + Vector3(size.x, 0.0, 0.0),
		pos + Vector3(0.0, size.y, 0.0),
		pos + Vector3(0.0, 0.0, size.z),
		pos + Vector3(size.x, size.y, 0.0),
		pos + Vector3(size.x, 0.0, size.z),
		pos + Vector3(0.0, size.y, size.z),
		pos + size,
	]
