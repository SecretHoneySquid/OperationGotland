extends Node
class_name VisualBuildTools

## Visual Build Tools
##
## Handles build mode visualization including:
## - Build ghost (placement preview)
## - Build zones (territorial restrictions)
## - Fog of war rendering
## - Map data loading

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Build Ghost")
@export var show_build_ghost := true
@export var ghost_height := 2.0
@export var ghost_y_offset := 0.2
@export var ghost_valid_color := Color(0.2, 0.9, 0.2, 0.35)
@export var ghost_invalid_color := Color(0.95, 0.75, 0.2, 0.35)

@export_group("Build Zone")
@export var show_build_zone := true
@export var build_zone_team_id := "p1"
@export var build_zone_height := 0.4
@export var build_zone_y_offset := 0.05
@export var build_zone_color := Color(0.1, 0.6, 0.2, 0.2)

@export_group("Build Zone Outline")
@export var show_build_zone_outline := true
@export var build_zone_outline_color := Color(0.1, 0.8, 0.3, 0.6)
@export var build_zone_outline_width := 4.0
@export var build_zone_outline_height := 0.6
@export var build_zone_outline_y_offset := 0.3

@export_group("Fog of War")
@export var show_fog_of_war := true
@export var fog_vision_group := "vision_p1"
@export var fog_y_offset := 0.25
@export var fog_height_follow_terrain := false
@export var fog_height_extra := 8.0
@export var fog_texture_size := Vector2i(256, 256)
@export var fog_update_interval := 0.2
@export var fog_softness := 0.25
@export var fog_color := Color(0.05, 0.06, 0.08, 0.75)

@export_group("Map Data")
@export var map_path := "res://data/maps/test_map.json"

# =============================================================================
# STATE
# =============================================================================

var _ghost_root: Node3D
var _ghost_mesh: MeshInstance3D
var _ghost_mat_valid: StandardMaterial3D
var _ghost_mat_invalid: StandardMaterial3D

var _build_zone_root: Node3D
var _build_zone_mesh: MeshInstance3D
var _build_zone_material: StandardMaterial3D
var _build_zone_outline_root: Node3D
var _build_zone_outline_edges: Array[MeshInstance3D] = []

var _fog_root: Node3D
var _fog_mesh: MeshInstance3D
var _fog_material: StandardMaterial3D
var _fog_image: Image
var _fog_texture: ImageTexture
var _fog_timer := 0.0

var _map_loaded := false
var _map_size := Vector2.ZERO
var _build_zones: Dictionary = {}

var _parent_node: Node3D = null
var _ground_getter: Callable = Callable()
var _ground_max_getter: Callable = Callable()

# =============================================================================
# INITIALIZATION
# =============================================================================

func setup(parent: Node3D, ground_height_getter: Callable, ground_max_height_getter: Callable) -> void:
	_parent_node = parent
	_ground_getter = ground_height_getter
	_ground_max_getter = ground_max_height_getter

# =============================================================================
# BUILD GHOST
# =============================================================================

func update_build_ghost(build_controller_path: NodePath, scene_tree: SceneTree) -> void:
	if not show_build_ghost:
		_set_ghost_visible(false)
		return

	var controller := _parent_node.get_node_or_null(build_controller_path)
	if controller == null or not controller.has_method("get_ghost_state"):
		_set_ghost_visible(false)
		return

	var state: Dictionary = controller.get_ghost_state()
	if state.is_empty():
		_set_ghost_visible(false)
		return

	var size_value: Variant = state.get("size", Vector2.ZERO)
	if size_value is not Vector2 or size_value == Vector2.ZERO:
		_set_ghost_visible(false)
		return

	var pos_value: Variant = state.get("pos", Vector2.ZERO)
	if pos_value is not Vector2:
		_set_ghost_visible(false)
		return

	var size: Vector2 = size_value
	var pos: Vector2 = pos_value

	_ensure_ghost()
	_ghost_root.visible = true

	var base_y := 0.0
	if _ground_getter.is_valid():
		base_y = _ground_getter.call(pos)

	_ghost_root.position = Vector3(pos.x, base_y + (ghost_height * 0.5) + ghost_y_offset, pos.y)

	var box: BoxMesh = _ghost_mesh.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		_ghost_mesh.mesh = box
	box.size = Vector3(size.x, ghost_height, size.y)

	var valid := bool(state.get("valid", false))
	_ghost_mesh.material_override = _ghost_mat_valid if valid else _ghost_mat_invalid

func _ensure_ghost() -> void:
	if _ghost_root != null and is_instance_valid(_ghost_root):
		return

	_ghost_root = Node3D.new()
	_ghost_root.name = "BuildGhost3D"
	_parent_node.add_child(_ghost_root)

	_ghost_mesh = MeshInstance3D.new()
	_ghost_mesh.mesh = BoxMesh.new()
	_ghost_root.add_child(_ghost_mesh)

	_ghost_mat_valid = VisualUtilities.make_ghost_material(ghost_valid_color)
	_ghost_mat_invalid = VisualUtilities.make_ghost_material(ghost_invalid_color)

func _set_ghost_visible(value: bool) -> void:
	if _ghost_root != null and is_instance_valid(_ghost_root):
		_ghost_root.visible = value

# =============================================================================
# BUILD ZONE
# =============================================================================

func update_build_zone() -> void:
	if not show_build_zone:
		_set_build_zone_visible(false)
		_set_build_zone_outline_visible(false)
		return

	_ensure_map_data()

	if _map_size == Vector2.ZERO:
		_set_build_zone_visible(false)
		_set_build_zone_outline_visible(false)
		return

	var rect_value: Variant = _build_zones.get(build_zone_team_id, null)
	if rect_value is not Rect2:
		_set_build_zone_visible(false)
		_set_build_zone_outline_visible(false)
		return

	var rect: Rect2 = rect_value
	_ensure_build_zone()
	_build_zone_root.visible = true

	var center := rect.position + rect.size * 0.5
	var base_y := 0.0
	if _ground_getter.is_valid():
		base_y = _ground_getter.call(center)

	_build_zone_root.position = Vector3(center.x, base_y + build_zone_y_offset + (build_zone_height * 0.5), center.y)

	var box: BoxMesh = _build_zone_mesh.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		_build_zone_mesh.mesh = box
	box.size = Vector3(rect.size.x, build_zone_height, rect.size.y)

	if _build_zone_material != null:
		_build_zone_mesh.material_override = _build_zone_material

	_update_build_zone_outline(rect)

func _ensure_build_zone() -> void:
	if _build_zone_root != null and is_instance_valid(_build_zone_root):
		return

	_build_zone_root = Node3D.new()
	_build_zone_root.name = "BuildZone3D"
	_parent_node.add_child(_build_zone_root)

	_build_zone_mesh = MeshInstance3D.new()
	_build_zone_mesh.mesh = BoxMesh.new()
	_build_zone_root.add_child(_build_zone_mesh)

	_build_zone_material = VisualUtilities.make_zone_material(build_zone_color)

func _set_build_zone_visible(value: bool) -> void:
	if _build_zone_root != null and is_instance_valid(_build_zone_root):
		_build_zone_root.visible = value

# =============================================================================
# BUILD ZONE OUTLINE
# =============================================================================

func _update_build_zone_outline(rect: Rect2) -> void:
	if not show_build_zone_outline:
		_set_build_zone_outline_visible(false)
		return

	_ensure_build_zone_outline()
	if _build_zone_outline_root == null:
		return

	_build_zone_outline_root.visible = true

	var center := rect.position + rect.size * 0.5
	var base_y := 0.0
	if _ground_getter.is_valid():
		base_y = _ground_getter.call(center)

	var y := base_y + build_zone_outline_y_offset + (build_zone_outline_height * 0.5)
	var half_w := rect.size.x * 0.5
	var half_h := rect.size.y * 0.5
	var edge_w := build_zone_outline_width
	var edge_h := build_zone_outline_height

	var top_z := rect.position.y + (edge_w * 0.5)
	var bottom_z := rect.position.y + rect.size.y - (edge_w * 0.5)
	var left_x := rect.position.x + (edge_w * 0.5)
	var right_x := rect.position.x + rect.size.x - (edge_w * 0.5)

	_set_outline_edge(0, Vector3(center.x, y, top_z), Vector3(rect.size.x, edge_h, edge_w))
	_set_outline_edge(1, Vector3(center.x, y, bottom_z), Vector3(rect.size.x, edge_h, edge_w))
	_set_outline_edge(2, Vector3(left_x, y, center.y), Vector3(edge_w, edge_h, rect.size.y))
	_set_outline_edge(3, Vector3(right_x, y, center.y), Vector3(edge_w, edge_h, rect.size.y))

func _ensure_build_zone_outline() -> void:
	if _build_zone_outline_root != null and is_instance_valid(_build_zone_outline_root):
		return

	_build_zone_outline_root = Node3D.new()
	_build_zone_outline_root.name = "BuildZoneOutline3D"
	_parent_node.add_child(_build_zone_outline_root)

	_build_zone_outline_edges.clear()
	for _i in range(4):
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.material_override = VisualUtilities.make_zone_material(build_zone_outline_color)
		_build_zone_outline_root.add_child(mesh_instance)
		_build_zone_outline_edges.append(mesh_instance)

func _set_outline_edge(index: int, pos: Vector3, size: Vector3) -> void:
	if index < 0 or index >= _build_zone_outline_edges.size():
		return

	var mesh_instance: MeshInstance3D = _build_zone_outline_edges[index]
	if mesh_instance == null:
		return

	mesh_instance.position = pos
	var box: BoxMesh = mesh_instance.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		mesh_instance.mesh = box
	box.size = size

func _set_build_zone_outline_visible(value: bool) -> void:
	if _build_zone_outline_root != null and is_instance_valid(_build_zone_outline_root):
		_build_zone_outline_root.visible = value

# =============================================================================
# FOG OF WAR
# =============================================================================

func update_fog_of_war(delta: float, scene_tree: SceneTree) -> void:
	if not show_fog_of_war:
		_set_fog_visible(false)
		return

	_ensure_map_data()

	if _map_size == Vector2.ZERO:
		_set_fog_visible(false)
		return

	_ensure_fog_plane()
	_fog_root.visible = true

	if _fog_mesh != null and is_instance_valid(_fog_mesh):
		var fog_y := fog_y_offset + fog_height_extra
		if _ground_max_getter.is_valid():
			fog_y += _ground_max_getter.call()
		_fog_mesh.position = Vector3(_map_size.x * 0.5, fog_y, _map_size.y * 0.5)

	_fog_timer += delta
	if _fog_timer < fog_update_interval:
		return

	_fog_timer = 0.0
	_render_fog_texture(scene_tree)

func _ensure_fog_plane() -> void:
	if _fog_root != null and is_instance_valid(_fog_root):
		return

	_fog_root = Node3D.new()
	_fog_root.name = "FogOfWar3D"
	_parent_node.add_child(_fog_root)

	_fog_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = _map_size
	_fog_mesh.mesh = plane

	var fog_y := fog_y_offset + fog_height_extra
	if _ground_max_getter.is_valid():
		fog_y += _ground_max_getter.call()
	_fog_mesh.position = Vector3(_map_size.x * 0.5, fog_y, _map_size.y * 0.5)

	_fog_root.add_child(_fog_mesh)

	_fog_material = VisualUtilities.make_fog_material(Color(1.0, 1.0, 1.0, 1.0))
	_fog_mesh.material_override = _fog_material

	_fog_image = Image.create(fog_texture_size.x, fog_texture_size.y, false, Image.FORMAT_RGBA8)
	_fog_image.fill(fog_color)
	_fog_texture = ImageTexture.create_from_image(_fog_image)
	_fog_material.albedo_texture = _fog_texture

func _set_fog_visible(value: bool) -> void:
	if _fog_root != null and is_instance_valid(_fog_root):
		_fog_root.visible = value

func _render_fog_texture(scene_tree: SceneTree) -> void:
	if _fog_image == null or _fog_texture == null:
		return

	_fog_image.fill(fog_color)

	var tex_w := fog_texture_size.x
	var tex_h := fog_texture_size.y
	if tex_w <= 1 or tex_h <= 1:
		return

	var map_w := maxf(1.0, _map_size.x)
	var map_h := maxf(1.0, _map_size.y)

	var base_r := fog_color.r
	var base_g := fog_color.g
	var base_b := fog_color.b
	var base_a := fog_color.a

	var edge := clampf(1.0 - fog_softness, 0.0, 1.0)

	for node in scene_tree.get_nodes_in_group(fog_vision_group):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_vision_radius"):
			continue
		if node is not Node2D:
			continue

		var pos2d: Vector2 = node.global_position
		var radius := float(node.get_vision_radius())
		if radius <= 0.0:
			continue

		var cx := int(clampf((pos2d.x / map_w) * float(tex_w - 1), 0.0, float(tex_w - 1)))
		var cy := int(clampf((pos2d.y / map_h) * float(tex_h - 1), 0.0, float(tex_h - 1)))
		var rx := int(maxf(1.0, (radius / map_w) * float(tex_w)))
		var ry := int(maxf(1.0, (radius / map_h) * float(tex_h)))

		var y0 := maxi(0, cy - ry)
		var y1 := mini(tex_h - 1, cy + ry)
		var x0 := maxi(0, cx - rx)
		var x1 := mini(tex_w - 1, cx + rx)

		for y in range(y0, y1 + 1):
			var dy := float(y - cy) / float(ry)
			var dy2 := dy * dy
			for x in range(x0, x1 + 1):
				var dx := float(x - cx) / float(rx)
				var dist := sqrt(dx * dx + dy2)
				if dist > 1.0:
					continue

				var alpha := 0.0
				if dist > edge:
					var t := (dist - edge) / maxf(0.0001, (1.0 - edge))
					alpha = base_a * clampf(t, 0.0, 1.0)

				var current := _fog_image.get_pixel(x, y)
				if alpha < current.a:
					_fog_image.set_pixel(x, y, Color(base_r, base_g, base_b, alpha))

	_fog_texture.update(_fog_image)

# =============================================================================
# MAP DATA LOADING
# =============================================================================

func _ensure_map_data() -> void:
	if _map_loaded:
		return

	_map_loaded = true

	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed
	var size_data: Dictionary = data.get("size", {})
	_map_size = Vector2(float(size_data.get("width", 0.0)), float(size_data.get("height", 0.0)))

	_build_zones.clear()
	var zones: Array = data.get("build_zones", [])
	for zone in zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		var zone_id := str(zone.get("id", ""))
		var rect := Rect2(
			Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
			Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
		)
		_build_zones[zone_id] = rect

func get_map_size() -> Vector2:
	_ensure_map_data()
	return _map_size

func get_build_zones() -> Dictionary:
	_ensure_map_data()
	return _build_zones.duplicate()
