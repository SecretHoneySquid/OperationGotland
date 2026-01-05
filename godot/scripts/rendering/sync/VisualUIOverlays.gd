extends Node
class_name VisualUIOverlays

## Visual UI Overlays
##
## Manages UI elements attached to entities:
## - Health bars (billboard quads)
## - Selection rings (torus meshes)
## - Turret range indicators (dashed rings)

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Health Bar Settings")
@export var health_bar_height := 6.0
@export var health_bar_offset := 8.0
@export var health_bar_color := Color(0.2, 0.85, 0.25, 0.9)
@export var health_bar_back := Color(0.12, 0.12, 0.12, 0.8)

@export_group("Selection Ring Settings")
@export var selection_ring_color := Color(0.2, 0.9, 1.0, 0.75)
@export var selection_ring_height := 1.5
@export var selection_ring_thickness := 0.5
@export var selection_ring_vehicle_scale := 1.5
@export var selection_ring_infantry_scale := 1.1
@export var selection_ring_use_unit_color := true

@export_group("Turret Range Settings")
@export var turret_range_enabled := true
@export var turret_range_color := Color(0.0, 0.0, 0.0, 0.65)
@export var turret_range_height := 0.12
@export var turret_range_thickness := 0.8
@export var turret_range_dash_count := 64
@export var turret_range_dash_ratio := 0.55

# =============================================================================
# SELECTION RINGS
# =============================================================================

func attach_selection_ring(proxy: Node3D, radius: float, base_color: Color) -> void:
	if proxy.has_meta("selection_ring"):
		return

	var ring_color := selection_ring_color
	if selection_ring_use_unit_color:
		ring_color = base_color.lightened(0.5)
		ring_color.a = selection_ring_color.a

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	var outer := maxf(0.5, radius)
	var inner := maxf(0.05, outer - selection_ring_thickness)
	torus.outer_radius = outer
	torus.inner_radius = inner
	torus.rings = 64
	torus.ring_segments = 12
	ring.mesh = torus
	ring.material_override = VisualUtilities.make_ring_material(ring_color)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false
	ring.position = Vector3(0.0, selection_ring_height, 0.0)
	proxy.add_child(ring)
	proxy.set_meta("selection_ring", ring)

func update_selection_ring(proxy: Node3D, visible: bool) -> void:
	if not proxy.has_meta("selection_ring"):
		return
	var ring: MeshInstance3D = proxy.get_meta("selection_ring") as MeshInstance3D
	if ring == null:
		return
	ring.visible = visible

# =============================================================================
# TURRET RANGE INDICATORS
# =============================================================================

func attach_turret_range(proxy: Node3D, radius: float) -> void:
	if proxy.has_meta("turret_range_ring"):
		return
	var ring := build_turret_range_ring(radius)
	proxy.add_child(ring)
	proxy.set_meta("turret_range_ring", ring)
	proxy.set_meta("turret_range_radius", radius)

func update_turret_range(proxy: Node3D, turret) -> void:
	if not turret_range_enabled:
		if proxy.has_meta("turret_range_ring"):
			var ring_hidden: MultiMeshInstance3D = proxy.get_meta("turret_range_ring") as MultiMeshInstance3D
			if ring_hidden != null:
				ring_hidden.visible = false
		return

	var radius := VisualUtilities.get_float(turret, "attack_range", 0.0)
	if radius <= 0.0:
		return

	if not proxy.has_meta("turret_range_ring"):
		attach_turret_range(proxy, radius)

	var ring: MultiMeshInstance3D = proxy.get_meta("turret_range_ring") as MultiMeshInstance3D
	if ring == null:
		return

	ring.visible = true
	ring.position = Vector3(0.0, turret_range_height, 0.0)

	var last_radius: float = float(proxy.get_meta("turret_range_radius", -1.0))
	if absf(last_radius - radius) > 0.1:
		set_turret_range_mesh(ring, radius)
		proxy.set_meta("turret_range_radius", radius)

	ring.material_override = VisualUtilities.make_ring_material(turret_range_color)

func build_turret_range_ring(radius: float) -> MultiMeshInstance3D:
	var ring := MultiMeshInstance3D.new()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = turret_range_enabled
	set_turret_range_mesh(ring, radius)
	return ring

func set_turret_range_mesh(ring: MultiMeshInstance3D, radius: float) -> void:
	var use_radius := maxf(0.5, radius)
	var dash_count := maxi(6, turret_range_dash_count)
	var dash_ratio := clampf(turret_range_dash_ratio, 0.1, 0.9)
	var circumference := TAU * use_radius
	var dash_length := maxf(0.3, (circumference / float(dash_count)) * dash_ratio)
	var thickness := maxf(0.1, turret_range_thickness)
	var height := maxf(0.02, thickness * 0.2)

	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(thickness, height, dash_length)

	var multi := MultiMesh.new()
	multi.mesh = dash_mesh
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = dash_count

	var step := TAU / float(dash_count)
	for i in range(dash_count):
		var angle := step * float(i)
		var pos := Vector3(cos(angle) * use_radius, 0.0, sin(angle) * use_radius)
		var forward := Vector3(-sin(angle), 0.0, cos(angle))
		var right := Vector3.UP.cross(forward).normalized()
		var basis := Basis(right, Vector3.UP, forward)
		var xform := Transform3D(basis, pos)
		multi.set_instance_transform(i, xform)

	ring.multimesh = multi

# =============================================================================
# HEALTH BARS
# =============================================================================

func attach_health_bar(proxy: Node3D, width: float, height: float, bar_height: float, y_offset: float) -> void:
	if proxy.has_meta("health_bar_root"):
		return

	var use_height := bar_height if bar_height > 0.0 else health_bar_height
	var use_offset := y_offset if y_offset >= 0.0 else health_bar_offset

	var bar := Node3D.new()
	bar.name = "HealthBar3D"
	bar.position = Vector3(0, height + use_offset, 0)

	# Background
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(width, use_height)
	var bg := MeshInstance3D.new()
	bg.mesh = bg_mesh
	bg.material_override = VisualUtilities.make_ui_material(health_bar_back)
	bg.sorting_offset = -0.5
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.add_child(bg)

	# Fill (health indicator)
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(width, use_height)
	var fill := MeshInstance3D.new()
	fill.mesh = fill_mesh
	fill.material_override = VisualUtilities.make_ui_material(health_bar_color)
	fill.position = Vector3(0, 0.0, 0.01)
	fill.sorting_offset = 0.5
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.add_child(fill)

	proxy.add_child(bar)
	proxy.set_meta("health_bar_root", bar)
	proxy.set_meta("health_bar_bg", bg)
	proxy.set_meta("health_bar_fill", fill)
	proxy.set_meta("health_bar_width", width)
	proxy.set_meta("health_bar_height", use_height)

func update_health_bar(node, proxy: Node3D, allow_visible: bool, viewport: Viewport) -> void:
	if not proxy.has_meta("health_bar_root"):
		return

	var bar: Node3D = proxy.get_meta("health_bar_root") as Node3D
	if bar == null:
		return

	var fill: MeshInstance3D = proxy.get_meta("health_bar_fill") as MeshInstance3D
	if fill == null:
		return

	if not allow_visible:
		bar.visible = false
		return

	bar.visible = true

	# Billboard - always face camera
	var camera := viewport.get_camera_3d()
	if camera != null:
		var xform := bar.global_transform
		xform.basis = camera.global_transform.basis
		bar.global_transform = xform

	var max_hp := float(VisualUtilities.get_float(node, "max_hp", 0.0))
	if max_hp <= 0.0:
		bar.visible = false
		return

	var hp := float(VisualUtilities.get_float(node, "hp", max_hp))
	var pct := clampf(hp / max_hp, 0.0, 1.0)

	var width: float = float(proxy.get_meta("health_bar_width", 0.0))
	var bar_height: float = float(proxy.get_meta("health_bar_height", health_bar_height))

	if pct <= 0.0:
		bar.visible = false
		return

	fill.visible = true
	var fill_mesh: QuadMesh = fill.mesh as QuadMesh
	if fill_mesh == null:
		fill_mesh = QuadMesh.new()
		fill.mesh = fill_mesh

	fill_mesh.size = Vector2(width * pct, bar_height)
	fill.position = Vector3(-(width - fill_mesh.size.x) * 0.5, 0.0, 0.01)
