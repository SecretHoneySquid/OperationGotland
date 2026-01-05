extends Node
class_name VisualUtilities

## Visual Utilities
##
## Static utility functions for creating meshes, materials, and helpers
## Used by all visual synchronization components

# =============================================================================
# MESH PRIMITIVE CREATORS
# =============================================================================

static func make_box(size: Vector3, color: Color) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = make_material(color)
	return mesh

static func make_cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.material_override = make_material(color)
	return mesh

static func make_cone(radius: float, height: float, color: Color) -> MeshInstance3D:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	var mesh := MeshInstance3D.new()
	mesh.mesh = cone
	mesh.material_override = make_material(color)
	return mesh

static func make_pentagon_prism(radius: float, height: float, color: Color) -> MeshInstance3D:
	var prism := CylinderMesh.new()
	prism.top_radius = radius
	prism.bottom_radius = radius
	prism.height = height
	prism.radial_segments = 5
	prism.rings = 1
	var mesh := MeshInstance3D.new()
	mesh.mesh = prism
	mesh.material_override = make_material(color)
	return mesh

static func make_capsule(radius: float, height: float, color: Color) -> MeshInstance3D:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	var mesh := MeshInstance3D.new()
	mesh.mesh = capsule
	mesh.material_override = make_material(color)
	return mesh

static func make_sphere(radius: float, color: Color) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = make_material(color)
	return mesh

# =============================================================================
# MATERIAL FACTORIES
# =============================================================================

static func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.metallic = 0.05
	return material

static func make_pad_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func make_ui_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func make_ghost_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func make_zone_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func make_fog_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func make_tracer_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func make_fx_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func make_ring_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

# =============================================================================
# PROPERTY GETTERS (TYPE-SAFE)
# =============================================================================

static func get_color(node, property: String, fallback: Color) -> Color:
	var value: Variant = node.get(property)
	return value if value is Color else fallback

static func get_float(node, property: String, fallback: float) -> float:
	var value: Variant = node.get(property)
	return float(value) if value is float or value is int else fallback

static func get_vec2(node, property: String, fallback: Vector2) -> Vector2:
	var value: Variant = node.get(property)
	return value if value is Vector2 else fallback

static func get_value(node, property: String, fallback):
	var value: Variant = node.get(property)
	return value if value != null else fallback

static func get_missile_scale(missile, small_scale: float, medium_scale: float, large_scale: float) -> float:
	var size := str(get_value(missile, "warhead_size", "medium")).to_lower()
	return warhead_scale(size, small_scale, medium_scale, large_scale)

static func warhead_scale(size: String, small_scale: float, medium_scale: float, large_scale: float) -> float:
	match size:
		"small":
			return small_scale
		"large":
			return large_scale
	return medium_scale

# =============================================================================
# GROUND & TERRAIN HELPERS
# =============================================================================

static func get_ground_height(ground_node: Node, pos: Vector2, terrain_follow_enabled: bool) -> float:
	if not terrain_follow_enabled:
		return 0.0
	if ground_node == null:
		return 0.0
	if not ground_node.has_method("get_height_at"):
		var data_value: Variant = ground_node.get("data")
		if data_value is Object and data_value.has_method("get_height"):
			var world_pos := Vector3(pos.x, 0.0, pos.y)
			var local_pos := world_pos
			if ground_node is Node3D:
				local_pos = (ground_node as Node3D).to_local(world_pos)
			var height_value: Variant = data_value.call("get_height", Vector3(local_pos.x, 0.0, local_pos.z))
			if height_value is float or height_value is int:
				var height := float(height_value)
				if not is_finite(height):
					return 0.0
				if ground_node is Node3D:
					return (ground_node as Node3D).to_global(Vector3(local_pos.x, height, local_pos.z)).y
				return height
		return 0.0
	var height_value: Variant = ground_node.call("get_height_at", pos)
	if height_value is float or height_value is int:
		var height := float(height_value)
		return height if is_finite(height) else 0.0
	return 0.0

static func get_ground_max_height(ground_node: Node, terrain_follow_enabled: bool, fog_height_follow_terrain: bool) -> float:
	if not terrain_follow_enabled:
		return 0.0
	if not fog_height_follow_terrain:
		return 0.0
	if ground_node == null:
		return 0.0
	if not ground_node.has_method("get_max_height"):
		var data_value: Variant = ground_node.get("data")
		if data_value is Object and data_value.has_method("get_height_range"):
			var range_value: Variant = data_value.call("get_height_range")
			if range_value is Vector2:
				var max_height := float(range_value.y)
				if not is_finite(max_height):
					return 0.0
				if ground_node is Node3D:
					return (ground_node as Node3D).to_global(Vector3(0.0, max_height, 0.0)).y
				return max_height
		return 0.0
	var height_value: Variant = ground_node.call("get_max_height")
	if height_value is float or height_value is int:
		var height := float(height_value)
		return height if is_finite(height) else 0.0
	return 0.0

static func get_navigation_path(world: World3D, from_pos: Vector2, to_pos: Vector2, ground_node: Node, terrain_follow_enabled: bool, nav_layers: int = 1, optimize: bool = true) -> PackedVector2Array:
	if world == null:
		return PackedVector2Array()
	var nav_map := world.navigation_map
	if nav_map == RID():
		return PackedVector2Array()
	var from_height := get_ground_height(ground_node, from_pos, terrain_follow_enabled)
	var to_height := get_ground_height(ground_node, to_pos, terrain_follow_enabled)
	var from_3d := Vector3(from_pos.x, from_height, from_pos.y)
	var to_3d := Vector3(to_pos.x, to_height, to_pos.y)
	var path_3d := NavigationServer3D.map_get_path(nav_map, from_3d, to_3d, optimize, nav_layers)
	if path_3d.is_empty():
		return PackedVector2Array()
	var path_2d := PackedVector2Array()
	for point in path_3d:
		path_2d.append(Vector2(point.x, point.z))
	return path_2d

# =============================================================================
# RENDER CONTROL
# =============================================================================

static func disable_2d_render(node) -> void:
	if node.has_method("set_render_2d"):
		node.set_render_2d(false)

static func disable_map_render(scene_tree: SceneTree) -> void:
	for node in scene_tree.get_nodes_in_group("map_loader"):
		disable_2d_render(node)
