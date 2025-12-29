extends Node3D

@export var map_path := "res://data/maps/test_map.json"
@export var ground_color := Color(0.18, 0.22, 0.17, 1.0)
@export var grid_color := Color(0.1, 0.12, 0.1, 1.0)
@export var grid_spacing := 0.0
@export var grid_line_width := 2.0
@export var grid_opacity := 0.0
@export var noise_strength := 0.0
@export var noise_scale := 280.0
@export var patch_count := 0
@export var patch_radius_min := 12.0
@export var patch_radius_max := 44.0
@export var patch_softness := 1.6
@export var patch_color := Color(0.14, 0.17, 0.13, 1.0)
@export var ground_albedo_path := ""
@export var ground_normal_path := ""
@export var ground_roughness_path := ""
@export var ground_overlay_enabled := false
@export var ground_uv_scale := Vector2(320.0, 320.0)
@export var heightmap_path := ""
@export var heightmap_base_height := 14.0
@export var heightmap_strength := 58.0
@export var heightmap_resolution := 512
@export var heightmap_flatten_build_zones := true
@export var heightmap_flatten_padding := 70.0
@export var heightmap_flatten_falloff := 1.3
@export var mountain_enabled := true
@export var mountain_center_ratio := Vector2(0.5, 0.12)
@export var mountain_radius_ratio := 0.16
@export var mountain_height := 210.0
@export var mountain_falloff := 1.85
@export var ridge_enabled := true
@export var ridge_band_ratio := 0.16
@export var ridge_height := 110.0
@export var ridge_falloff := 1.4
@export var valley_enabled := true
@export var valley_width := 1400.0
@export var valley_depth := 120.0
@export var valley_falloff := 1.5
@export var heightmap_noise_enabled := true
@export var heightmap_noise_seed := 1337
@export var heightmap_noise_frequency := 0.0014
@export var heightmap_noise_octaves := 3
@export var heightmap_noise_gain := 0.5
@export var heightmap_noise_lacunarity := 2.0
@export var heightmap_noise_curve := 1.35
@export var roads_enabled := true
@export var road_color := Color(0.2, 0.18, 0.16, 1.0)
@export var road_world_width := 280.0
@export var road_softness := 140.0
@export var road_curve_offset := 1100.0
@export var road_cross_offset := 0.0
@export var road_opacity := 0.48
@export var road_max_height_ratio := 0.32
@export var road_max_slope := 0.12
@export var fields_enabled := false
@export var field_seed := 2249
@export var field_color := Color(0.23, 0.27, 0.16, 1.0)
@export var field_count := 8
@export var field_world_min_size := Vector2(360.0, 280.0)
@export var field_world_max_size := Vector2(1200.0, 720.0)
@export var field_softness := 180.0
@export var field_opacity := 0.35
@export var field_max_height_ratio := 0.32
@export var field_max_slope := 0.1
@export var field_noise_scale := 260.0
@export var field_noise_strength := 0.35
@export var terrain_tint_strength := 0.0
@export var terrain_low_color := Color(0.17, 0.24, 0.16, 1.0)
@export var terrain_mid_color := Color(0.22, 0.23, 0.18, 1.0)
@export var terrain_high_color := Color(0.32, 0.3, 0.26, 1.0)
@export var terrain_peak_color := Color(0.46, 0.44, 0.4, 1.0)
@export var slope_rock_color := Color(0.38, 0.36, 0.33, 1.0)
@export var slope_rock_threshold := 0.15
@export var slope_rock_max := 0.34
@export var slope_rock_strength := 0.62
@export var props_enabled := true
@export var prop_seed := 4782
@export var tree_count := 260
@export var rock_count := 160
@export var tree_min_scale := 0.8
@export var tree_max_scale := 1.6
@export var rock_min_scale := 0.7
@export var rock_max_scale := 1.8
@export var tree_height := 26.0
@export var tree_canopy_radius := 12.0
@export var tree_trunk_radius := 1.8
@export var tree_color := Color(0.14, 0.28, 0.18, 1.0)
@export var tree_trunk_color := Color(0.25, 0.2, 0.16, 1.0)
@export var rock_color := Color(0.32, 0.3, 0.28, 1.0)
@export var tree_min_height_ratio := 0.04
@export var tree_max_height_ratio := 0.38
@export var tree_max_slope := 0.09
@export var rock_min_height_ratio := 0.08
@export var rock_max_height_ratio := 0.8
@export var rock_max_slope := 0.32
@export var forest_enabled := true
@export var forest_cluster_count := 8
@export var forest_cluster_radius := 520.0
@export var forest_scatter_ratio := 0.18
@export var forest_cluster_min_spacing := 520.0
@export var forest_cluster_height_min := 0.06
@export var forest_cluster_height_max := 0.32
@export var lake_enabled := true
@export var lake_center_ratio := Vector2(0.5, 0.25)
@export var lake_radius := 520.0
@export var lake_depth := 70.0
@export var lake_falloff := 1.8
@export var lake_surface_offset := 0.8
@export var lake_color := Color(0.08, 0.18, 0.26, 0.8)
@export var oilfield_enabled := true
@export var oilfield_center_ratio := Vector2(0.5, 0.78)
@export var oilfield_radius := 360.0
@export var oilfield_tank_count := 8
@export var oilfield_tank_radius := 14.0
@export var oilfield_tank_height := 22.0
@export var oilfield_color := Color(0.28, 0.26, 0.24, 1.0)
@export var oilfield_pad_color := Color(0.14, 0.12, 0.1, 1.0)
@export var feature_seed := 8342
@export var prop_clear_build_zones := true
@export var prop_clear_roads := true
@export var prop_road_buffer := 180.0
@export var prop_clear_start_radius := 280.0
@export var texture_size := Vector2i(2048, 2048)

@onready var _mesh_instance := $"MeshInstance3D" as MeshInstance3D
var _map_size := Vector2.ZERO
var _grid_x := 0
var _grid_z := 0
var _height_grid := PackedFloat32Array()
var _height_min := 0.0
var _height_max := 0.0
var _build_zones: Array[Rect2] = []
var _start_positions: Dictionary = {}
var _prop_root: Node3D
var _feature_root: Node3D
var _forest_centers: Array[Vector2] = []

func _ready() -> void:
	_apply_ground()

func _apply_ground() -> void:
	if _mesh_instance == null:
		return
	_load_map_data(map_path)
	if _map_size == Vector2.ZERO:
		_map_size = Vector2(2000, 1200)
	_grid_x = maxi(8, heightmap_resolution)
	var aspect := _map_size.y / maxf(1.0, _map_size.x)
	_grid_z = maxi(8, int(round(float(_grid_x) * aspect)))
	_height_grid = _build_height_grid(_map_size, _grid_x, _grid_z)
	var mesh := _build_height_mesh(_map_size, _grid_x, _grid_z, _height_grid)
	_mesh_instance.mesh = mesh
	_mesh_instance.position = Vector3(_map_size.x * 0.5, 0.0, _map_size.y * 0.5)
	_mesh_instance.material_override = _build_ground_material(_map_size)
	_spawn_props()
	_spawn_features()

func get_height_at(world_pos: Vector2) -> float:
	if _height_grid.is_empty() or _map_size == Vector2.ZERO:
		return 0.0
	return _sample_height_grid(_height_grid, _map_size, _grid_x, _grid_z, world_pos)

func get_max_height() -> float:
	return _height_max

func _load_map_data(path: String) -> void:
	_build_zones.clear()
	_start_positions.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_map_size = Vector2.ZERO
		return
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_map_size = Vector2.ZERO
		return
	var data: Dictionary = parsed
	var size_data: Dictionary = data.get("size", {})
	var width := float(size_data.get("width", 0.0))
	var height := float(size_data.get("height", 0.0))
	_map_size = Vector2(width, height)
	var zones: Array = data.get("build_zones", [])
	for zone in zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		var rect := Rect2(
			Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
			Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
		)
		_build_zones.append(rect)
	var starts: Array = data.get("start_positions", [])
	for entry in starts:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var start: Dictionary = entry
		var id := str(start.get("id", ""))
		var pos := Vector2(float(start.get("x", 0.0)), float(start.get("y", 0.0)))
		if id != "":
			_start_positions[id] = pos

func _build_height_grid(size: Vector2, grid_x: int, grid_z: int) -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize((grid_x + 1) * (grid_z + 1))
	var image: Image = _load_heightmap_image(grid_x + 1, grid_z + 1)
	var noise: FastNoiseLite = null
	if image == null and heightmap_noise_enabled:
		noise = _build_noise()
	for z in range(grid_z + 1):
		var vz := float(z) / float(grid_z)
		var world_z := vz * size.y
		for x in range(grid_x + 1):
			var vx := float(x) / float(grid_x)
			var world_x := vx * size.x
			var height_value := 0.0
			if image != null:
				height_value = _sample_height_image(image, x, z)
			elif noise != null:
				var n := noise.get_noise_2d(world_x, world_z)
				height_value = (n + 1.0) * 0.5
				if heightmap_noise_curve != 1.0:
					height_value = pow(height_value, heightmap_noise_curve)
			var height: float = heightmap_base_height + (height_value * heightmap_strength)
			if ridge_enabled:
				height += _ridge_height(world_z, size)
			if mountain_enabled:
				height += _mountain_height(world_x, world_z, size)
			if valley_enabled:
				height -= _valley_depth(world_x, world_z, size)
			if lake_enabled:
				height -= _lake_depth(world_x, world_z, size)
			heights[_height_index(x, z, grid_x)] = height
	if heightmap_flatten_build_zones:
		_flatten_build_zones(heights, size, grid_x, grid_z)
	_update_height_bounds(heights)
	return heights

func _load_heightmap_image(width: int, height: int) -> Image:
	if heightmap_path == "" or not ResourceLoader.exists(heightmap_path):
		return null
	var tex = load(heightmap_path)
	if not (tex is Texture2D):
		return null
	var image := (tex as Texture2D).get_image()
	if image == null:
		return null
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() != width or image.get_height() != height:
		image.resize(width, height, Image.INTERPOLATE_CUBIC)
	return image

func _sample_height_image(image: Image, x: int, z: int) -> float:
	var col := image.get_pixel(x, z)
	return (col.r + col.g + col.b) / 3.0

func _build_noise() -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = heightmap_noise_seed
	noise.frequency = heightmap_noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = heightmap_noise_octaves
	noise.fractal_gain = heightmap_noise_gain
	noise.fractal_lacunarity = heightmap_noise_lacunarity
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	return noise

func _flatten_build_zones(heights: PackedFloat32Array, size: Vector2, grid_x: int, grid_z: int) -> void:
	if _build_zones.is_empty():
		return
	var padding := maxf(0.0, heightmap_flatten_padding)
	for zone in _build_zones:
		var center := zone.position + zone.size * 0.5
		var target := _sample_height_grid(heights, size, grid_x, grid_z, center)
		var outer := zone.grow(padding)
		for z in range(grid_z + 1):
			var world_z := (float(z) / float(grid_z)) * size.y
			for x in range(grid_x + 1):
				var world_x := (float(x) / float(grid_x)) * size.x
				var pos := Vector2(world_x, world_z)
				if not outer.has_point(pos):
					continue
				var weight := 1.0
				if not zone.has_point(pos):
					if padding <= 0.0:
						weight = 0.0
					else:
						var dx := 0.0
						if world_x < zone.position.x:
							dx = zone.position.x - world_x
						elif world_x > zone.position.x + zone.size.x:
							dx = world_x - (zone.position.x + zone.size.x)
						var dz := 0.0
						if world_z < zone.position.y:
							dz = zone.position.y - world_z
						elif world_z > zone.position.y + zone.size.y:
							dz = world_z - (zone.position.y + zone.size.y)
						var dist := maxf(dx, dz)
						weight = clampf(1.0 - (dist / padding), 0.0, 1.0)
						if heightmap_flatten_falloff != 1.0:
							weight = pow(weight, heightmap_flatten_falloff)
				if weight > 0.0:
					var idx := _height_index(x, z, grid_x)
					heights[idx] = lerpf(float(heights[idx]), target, weight)

func _update_height_bounds(heights: PackedFloat32Array) -> void:
	if heights.is_empty():
		_height_min = 0.0
		_height_max = 0.0
		return
	var min_h: float = INF
	var max_h: float = -INF
	for i in range(heights.size()):
		var h: float = float(heights[i])
		if h < min_h:
			min_h = h
		if h > max_h:
			max_h = h
	_height_min = min_h if min_h != INF else 0.0
	_height_max = max_h if max_h != -INF else 0.0

func _ridge_height(world_z: float, size: Vector2) -> float:
	if not ridge_enabled:
		return 0.0
	var band := size.y * clampf(ridge_band_ratio, 0.01, 0.45)
	if band <= 0.0:
		return 0.0
	var dist_top := world_z
	var dist_bottom := size.y - world_z
	var t_top := 1.0 - clampf(dist_top / band, 0.0, 1.0)
	var t_bottom := 1.0 - clampf(dist_bottom / band, 0.0, 1.0)
	var t := maxf(t_top, t_bottom)
	if t <= 0.0:
		return 0.0
	var falloff := maxf(0.1, ridge_falloff)
	return pow(t, falloff) * ridge_height

func _valley_depth(world_x: float, world_z: float, size: Vector2) -> float:
	if not valley_enabled:
		return 0.0
	var width := maxf(1.0, valley_width)
	var p1: Vector2 = _get_start_position("p1", Vector2(size.x * 0.1, size.y * 0.5))
	var p2: Vector2 = _get_start_position("p2", Vector2(size.x * 0.9, size.y * 0.5))
	var dist := _distance_to_segment(Vector2(world_x, world_z), p1, p2)
	if dist >= width:
		return 0.0
	var t := 1.0 - (dist / width)
	var falloff := maxf(0.1, valley_falloff)
	return pow(t, falloff) * valley_depth

func _lake_depth(world_x: float, world_z: float, size: Vector2) -> float:
	if not lake_enabled:
		return 0.0
	var radius := maxf(1.0, lake_radius)
	var center := _get_lake_center(size)
	var dist := Vector2(world_x, world_z).distance_to(center)
	if dist >= radius:
		return 0.0
	var t := 1.0 - (dist / radius)
	var falloff := maxf(0.1, lake_falloff)
	return pow(t, falloff) * lake_depth

func _get_lake_center(size: Vector2) -> Vector2:
	return Vector2(
		clampf(lake_center_ratio.x, 0.0, 1.0) * size.x,
		clampf(lake_center_ratio.y, 0.0, 1.0) * size.y
	)

func _get_oilfield_center(size: Vector2) -> Vector2:
	return Vector2(
		clampf(oilfield_center_ratio.x, 0.0, 1.0) * size.x,
		clampf(oilfield_center_ratio.y, 0.0, 1.0) * size.y
	)

func _get_start_position(id: String, fallback: Vector2) -> Vector2:
	var value: Variant = _start_positions.get(id, fallback)
	return value if value is Vector2 else fallback

func _mountain_height(world_x: float, world_z: float, size: Vector2) -> float:
	var radius_ratio := clampf(mountain_radius_ratio, 0.01, 0.9)
	var radius := minf(size.x, size.y) * radius_ratio
	if radius <= 0.0:
		return 0.0
	var center := Vector2(
		clampf(mountain_center_ratio.x, 0.0, 1.0) * size.x,
		clampf(mountain_center_ratio.y, 0.0, 1.0) * size.y
	)
	var dist := Vector2(world_x, world_z).distance_to(center)
	if dist >= radius:
		return 0.0
	var t := 1.0 - (dist / radius)
	var falloff := maxf(0.1, mountain_falloff)
	return pow(t, falloff) * mountain_height

func _uses_generated_ground_texture() -> bool:
	var has_base := ground_albedo_path != "" and ResourceLoader.exists(ground_albedo_path)
	if not has_base:
		return true
	return ground_overlay_enabled or roads_enabled or fields_enabled or noise_strength > 0.0 or patch_count > 0

func _build_height_mesh(size: Vector2, grid_x: int, grid_z: int, heights: PackedFloat32Array) -> ArrayMesh:
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	var step_x := size.x / float(grid_x)
	var step_z := size.y / float(grid_z)
	var uv_scale := ground_uv_scale
	if _uses_generated_ground_texture():
		uv_scale = Vector2(maxf(1.0, size.x), maxf(1.0, size.y))
	else:
		if uv_scale.x <= 0.0:
			uv_scale.x = maxf(1.0, size.x)
		if uv_scale.y <= 0.0:
			uv_scale.y = maxf(1.0, size.y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(grid_z):
		for x in range(grid_x):
			var x0 := -half_x + float(x) * step_x
			var z0 := -half_z + float(z) * step_z
			var x1 := x0 + step_x
			var z1 := z0 + step_z
			var idx00 := _height_index(x, z, grid_x)
			var idx10 := _height_index(x + 1, z, grid_x)
			var idx01 := _height_index(x, z + 1, grid_x)
			var idx11 := _height_index(x + 1, z + 1, grid_x)
			var v00 := Vector3(x0, heights[idx00], z0)
			var v10 := Vector3(x1, heights[idx10], z0)
			var v01 := Vector3(x0, heights[idx01], z1)
			var v11 := Vector3(x1, heights[idx11], z1)
			var uv00 := Vector2((x0 + half_x) / uv_scale.x, (z0 + half_z) / uv_scale.y)
			var uv10 := Vector2((x1 + half_x) / uv_scale.x, (z0 + half_z) / uv_scale.y)
			var uv01 := Vector2((x0 + half_x) / uv_scale.x, (z1 + half_z) / uv_scale.y)
			var uv11 := Vector2((x1 + half_x) / uv_scale.x, (z1 + half_z) / uv_scale.y)
			st.set_uv(uv00)
			st.add_vertex(v00)
			st.set_uv(uv10)
			st.add_vertex(v10)
			st.set_uv(uv11)
			st.add_vertex(v11)
			st.set_uv(uv00)
			st.add_vertex(v00)
			st.set_uv(uv11)
			st.add_vertex(v11)
			st.set_uv(uv01)
			st.add_vertex(v01)
	st.generate_normals()
	return st.commit()

func _build_ground_material(size: Vector2) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var base_texture := _load_texture(ground_albedo_path)
	var use_overlay := ground_overlay_enabled or roads_enabled or fields_enabled or noise_strength > 0.0 or patch_count > 0
	if base_texture != null and not use_overlay:
		material.albedo_texture = base_texture
		material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	else:
		var base_image: Image = null
		if base_texture != null and use_overlay:
			base_image = _load_ground_base_image(base_texture, texture_size)
		var fallback := _make_ground_texture(size, base_image)
		if fallback != null:
			material.albedo_texture = fallback
			material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		else:
			material.albedo_color = ground_color
	var normal_tex := _load_texture(ground_normal_path)
	if normal_tex != null:
		material.normal_enabled = true
		material.normal_texture = normal_tex
	var roughness_tex := _load_texture(ground_roughness_path)
	if roughness_tex != null:
		material.roughness_texture = roughness_tex
	material.roughness = 0.95
	material.metallic = 0.0
	material.vertex_color_use_as_albedo = false
	return material

func _spawn_props() -> void:
	if not props_enabled:
		_clear_props()
		return
	_clear_props()
	_prop_root = Node3D.new()
	_prop_root.name = "TerrainProps"
	add_child(_prop_root)
	var size := _map_size
	if size == Vector2.ZERO:
		size = Vector2(2000, 1200)
	var roads: Array[Dictionary] = []
	if prop_clear_roads:
		roads = _make_roads()
	var rng := RandomNumberGenerator.new()
	rng.seed = prop_seed
	var forest_centers: Array[Vector2] = []
	if forest_enabled and tree_count > 0:
		forest_centers = _make_forest_centers(size, rng, roads)
	_forest_centers = forest_centers
	var placed_tree := 0
	var placed_rock := 0
	var height_span := maxf(0.0, _height_max - _height_min)
	var tries := maxi(10, (tree_count + rock_count) * 8)
	for i in range(tries):
		if placed_tree >= tree_count and placed_rock >= rock_count:
			break
		var remaining_tree: int = tree_count - placed_tree
		var remaining_rock: int = rock_count - placed_rock
		var total_remaining: int = remaining_tree + remaining_rock
		if total_remaining <= 0:
			break
		var pick_tree := rng.randf() <= (float(remaining_tree) / float(total_remaining))
		var pos := Vector2(rng.randf_range(0.0, size.x), rng.randf_range(0.0, size.y))
		if pick_tree and forest_enabled and not forest_centers.is_empty() and rng.randf() > forest_scatter_ratio:
			pos = _sample_forest_position(rng, forest_centers, size)
		if prop_clear_build_zones and _point_in_build_zones(pos):
			continue
		if prop_clear_roads and not roads.is_empty():
			var road_dist := _distance_to_roads(pos, roads)
			if road_dist < prop_road_buffer:
				continue
		if prop_clear_start_radius > 0.0 and _near_starts(pos, prop_clear_start_radius):
			continue
		if _is_in_lake(pos):
			continue
		if _is_in_oilfield(pos):
			continue
		var height: float = get_height_at(pos)
		var height_ratio: float = 0.0
		if height_span > 0.0:
			height_ratio = clampf((height - _height_min) / height_span, 0.0, 1.0)
		var slope: float = _sample_slope(pos)
		if pick_tree and placed_tree < tree_count:
			if height_ratio < tree_min_height_ratio or height_ratio > tree_max_height_ratio:
				continue
			if slope > tree_max_slope:
				continue
			var scale: float = rng.randf_range(tree_min_scale, tree_max_scale)
			_add_tree(pos, height, scale)
			placed_tree += 1
		elif placed_rock < rock_count:
			if height_ratio < rock_min_height_ratio or height_ratio > rock_max_height_ratio:
				continue
			if slope > rock_max_slope:
				continue
			var scale: float = rng.randf_range(rock_min_scale, rock_max_scale)
			_add_rock(pos, height, scale, rng)
			placed_rock += 1

func _clear_props() -> void:
	if _prop_root != null and is_instance_valid(_prop_root):
		_prop_root.queue_free()
	_prop_root = null

func _spawn_features() -> void:
	_clear_features()
	if not lake_enabled and not oilfield_enabled:
		return
	_feature_root = Node3D.new()
	_feature_root.name = "TerrainFeatures"
	add_child(_feature_root)
	if lake_enabled:
		_spawn_lake()
	if oilfield_enabled:
		_spawn_oilfield()

func _clear_features() -> void:
	if _feature_root != null and is_instance_valid(_feature_root):
		_feature_root.queue_free()
	_feature_root = null

func _add_tree(pos: Vector2, height: float, scale: float) -> void:
	if _prop_root == null:
		return
	var tree := Node3D.new()
	tree.position = Vector3(pos.x, height, pos.y)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = tree_trunk_radius * 0.6 * scale
	trunk_mesh.bottom_radius = tree_trunk_radius * scale
	trunk_mesh.height = tree_height * 0.45 * scale
	trunk.mesh = trunk_mesh
	trunk.material_override = _make_prop_material(tree_trunk_color)
	trunk.position = Vector3(0.0, trunk_mesh.height * 0.5, 0.0)
	tree.add_child(trunk)
	var canopy := MeshInstance3D.new()
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = tree_canopy_radius * scale
	canopy.mesh = canopy_mesh
	canopy.material_override = _make_prop_material(tree_color)
	canopy.position = Vector3(0.0, trunk_mesh.height + canopy_mesh.radius * 0.6, 0.0)
	tree.add_child(canopy)
	_prop_root.add_child(tree)

func _add_rock(pos: Vector2, height: float, scale: float, rng: RandomNumberGenerator) -> void:
	if _prop_root == null:
		return
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 6.0 * scale
	rock.mesh = mesh
	rock.material_override = _make_prop_material(rock_color)
	var stretch := Vector3(
		rng.randf_range(0.6, 1.2),
		rng.randf_range(0.5, 1.0),
		rng.randf_range(0.6, 1.3)
	)
	rock.scale = stretch
	rock.position = Vector3(pos.x, height + (mesh.radius * stretch.y * 0.5), pos.y)
	_prop_root.add_child(rock)

func _spawn_lake() -> void:
	if _feature_root == null:
		return
	var size := _map_size
	if size == Vector2.ZERO:
		size = Vector2(2000, 1200)
	var center := _get_lake_center(size)
	var base_height := get_height_at(center)
	var mesh := CylinderMesh.new()
	mesh.top_radius = lake_radius
	mesh.bottom_radius = lake_radius
	mesh.height = 1.0
	mesh.radial_segments = 64
	var water := MeshInstance3D.new()
	water.mesh = mesh
	water.material_override = _make_water_material(lake_color)
	water.position = Vector3(center.x, base_height + lake_surface_offset + (mesh.height * 0.5), center.y)
	_feature_root.add_child(water)

func _spawn_oilfield() -> void:
	if _feature_root == null:
		return
	var size := _map_size
	if size == Vector2.ZERO:
		size = Vector2(2000, 1200)
	var center := _get_oilfield_center(size)
	var base_height := get_height_at(center)
	var pad := MeshInstance3D.new()
	var pad_mesh := BoxMesh.new()
	var pad_size := Vector3(oilfield_radius * 1.8, 2.0, oilfield_radius * 1.4)
	pad_mesh.size = pad_size
	pad.mesh = pad_mesh
	pad.material_override = _make_prop_material(oilfield_pad_color)
	pad.position = Vector3(center.x, base_height + (pad_size.y * 0.5), center.y)
	_feature_root.add_child(pad)
	var rng := RandomNumberGenerator.new()
	rng.seed = feature_seed
	for i in range(oilfield_tank_count):
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(0.2, 0.9) * oilfield_radius
		var pos := center + Vector2(cos(angle), sin(angle)) * dist
		var tank := MeshInstance3D.new()
		var tank_mesh := CylinderMesh.new()
		tank_mesh.top_radius = oilfield_tank_radius
		tank_mesh.bottom_radius = oilfield_tank_radius
		tank_mesh.height = oilfield_tank_height
		tank_mesh.radial_segments = 24
		tank.mesh = tank_mesh
		tank.material_override = _make_prop_material(oilfield_color)
		var tank_y := get_height_at(pos) + (oilfield_tank_height * 0.5)
		tank.position = Vector3(pos.x, tank_y, pos.y)
		_feature_root.add_child(tank)
	for i in range(3):
		var pump := MeshInstance3D.new()
		var pump_mesh := BoxMesh.new()
		pump_mesh.size = Vector3(18.0, 8.0, 10.0)
		pump.mesh = pump_mesh
		pump.material_override = _make_prop_material(oilfield_color.darkened(0.2))
		var offset := Vector2(rng.randf_range(-oilfield_radius * 0.4, oilfield_radius * 0.4), rng.randf_range(-oilfield_radius * 0.4, oilfield_radius * 0.4))
		var pump_pos := center + offset
		var pump_y := get_height_at(pump_pos) + (pump_mesh.size.y * 0.5)
		pump.position = Vector3(pump_pos.x, pump_y, pump_pos.y)
		_feature_root.add_child(pump)

func _make_water_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.2
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_prop_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	material.metallic = 0.0
	return material

func _point_in_build_zones(pos: Vector2) -> bool:
	for zone in _build_zones:
		if zone.has_point(pos):
			return true
	return false

func _near_starts(pos: Vector2, radius: float) -> bool:
	if radius <= 0.0:
		return false
	for key in _start_positions.keys():
		var value: Variant = _start_positions[key]
		if value is Vector2 and pos.distance_to(value) <= radius:
			return true
	return false

func _distance_to_roads(pos: Vector2, roads: Array[Dictionary]) -> float:
	var min_dist: float = INF
	for road in roads:
		var a_value: Variant = road.get("a", Vector2.ZERO)
		var b_value: Variant = road.get("b", Vector2.ZERO)
		if a_value is not Vector2 or b_value is not Vector2:
			continue
		var d := _distance_to_segment(pos, a_value, b_value)
		if d < min_dist:
			min_dist = d
	return min_dist if min_dist != INF else 1e9

func _make_forest_centers(size: Vector2, rng: RandomNumberGenerator, roads: Array[Dictionary]) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	if forest_cluster_count <= 0:
		return centers
	var height_span := maxf(0.0, _height_max - _height_min)
	var attempts := forest_cluster_count * 8
	for i in range(attempts):
		if centers.size() >= forest_cluster_count:
			break
		var pos := Vector2(rng.randf_range(0.0, size.x), rng.randf_range(0.0, size.y))
		if prop_clear_build_zones and _point_in_build_zones(pos):
			continue
		if prop_clear_roads and not roads.is_empty():
			if _distance_to_roads(pos, roads) < prop_road_buffer:
				continue
		if prop_clear_start_radius > 0.0 and _near_starts(pos, prop_clear_start_radius):
			continue
		if _is_in_lake(pos) or _is_in_oilfield(pos):
			continue
		if height_span > 0.0:
			var height: float = get_height_at(pos)
			var height_ratio: float = clampf((height - _height_min) / height_span, 0.0, 1.0)
			if height_ratio < forest_cluster_height_min or height_ratio > forest_cluster_height_max:
				continue
			var slope: float = _sample_slope(pos)
			if slope > tree_max_slope:
				continue
		if _forest_center_too_close(pos, centers):
			continue
		centers.append(pos)
	return centers

func _forest_center_too_close(pos: Vector2, centers: Array[Vector2]) -> bool:
	var min_spacing := maxf(0.0, forest_cluster_min_spacing)
	if min_spacing <= 0.0:
		return false
	for center in centers:
		if center.distance_to(pos) < min_spacing:
			return true
	return false

func _sample_forest_position(rng: RandomNumberGenerator, centers: Array[Vector2], size: Vector2) -> Vector2:
	if centers.is_empty():
		return Vector2(rng.randf_range(0.0, size.x), rng.randf_range(0.0, size.y))
	var index := rng.randi_range(0, centers.size() - 1)
	var center := centers[index]
	var angle := rng.randf() * TAU
	var dist := sqrt(rng.randf()) * forest_cluster_radius
	var pos := center + Vector2(cos(angle), sin(angle)) * dist
	pos.x = clampf(pos.x, 0.0, size.x)
	pos.y = clampf(pos.y, 0.0, size.y)
	return pos

func _is_in_lake(pos: Vector2) -> bool:
	if not lake_enabled:
		return false
	var size := _map_size
	if size == Vector2.ZERO:
		size = Vector2(2000, 1200)
	var center := _get_lake_center(size)
	return pos.distance_to(center) <= lake_radius

func _is_in_oilfield(pos: Vector2) -> bool:
	if not oilfield_enabled:
		return false
	var size := _map_size
	if size == Vector2.ZERO:
		size = Vector2(2000, 1200)
	var center := _get_oilfield_center(size)
	return pos.distance_to(center) <= oilfield_radius

func _load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex = load(path)
	if tex is Texture2D:
		return tex as Texture2D
	return null

func _load_ground_base_image(texture: Texture2D, target_size: Vector2i) -> Image:
	var image := texture.get_image()
	if image == null:
		return null
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() != target_size.x or image.get_height() != target_size.y:
		image.resize(target_size.x, target_size.y, Image.INTERPOLATE_CUBIC)
	return image

func _sample_height_grid(
	heights: PackedFloat32Array,
	size: Vector2,
	grid_x: int,
	grid_z: int,
	world_pos: Vector2
) -> float:
	if heights.is_empty():
		return 0.0
	var local_x := (world_pos.x / maxf(1.0, size.x)) * float(grid_x)
	var local_z := (world_pos.y / maxf(1.0, size.y)) * float(grid_z)
	local_x = clampf(local_x, 0.0, float(grid_x))
	local_z = clampf(local_z, 0.0, float(grid_z))
	var x0 := int(floor(local_x))
	var z0 := int(floor(local_z))
	var x1 := mini(x0 + 1, grid_x)
	var z1 := mini(z0 + 1, grid_z)
	var tx: float = local_x - float(x0)
	var tz: float = local_z - float(z0)
	var h00: float = float(heights[_height_index(x0, z0, grid_x)])
	var h10: float = float(heights[_height_index(x1, z0, grid_x)])
	var h01: float = float(heights[_height_index(x0, z1, grid_x)])
	var h11: float = float(heights[_height_index(x1, z1, grid_x)])
	var hx0: float = lerpf(h00, h10, tx)
	var hx1: float = lerpf(h01, h11, tx)
	return lerpf(hx0, hx1, tz)

func _height_index(x: int, z: int, grid_x: int) -> int:
	return z * (grid_x + 1) + x

func _terrain_color_by_height(height_ratio: float) -> Color:
	var h := clampf(height_ratio, 0.0, 1.0)
	if h <= 0.45:
		return terrain_low_color.lerp(terrain_mid_color, h / 0.45)
	if h <= 0.8:
		return terrain_mid_color.lerp(terrain_high_color, (h - 0.45) / 0.35)
	return terrain_high_color.lerp(terrain_peak_color, (h - 0.8) / 0.2)

func _sample_slope(world_pos: Vector2) -> float:
	if _height_grid.is_empty() or _map_size == Vector2.ZERO:
		return 0.0
	var step_x := _map_size.x / maxf(1.0, float(_grid_x))
	var step_z := _map_size.y / maxf(1.0, float(_grid_z))
	var base := _sample_height_grid(_height_grid, _map_size, _grid_x, _grid_z, world_pos)
	var sample_x := _sample_height_grid(_height_grid, _map_size, _grid_x, _grid_z, world_pos + Vector2(step_x, 0.0))
	var sample_z := _sample_height_grid(_height_grid, _map_size, _grid_x, _grid_z, world_pos + Vector2(0.0, step_z))
	var dx := absf(sample_x - base) / maxf(1.0, step_x)
	var dz := absf(sample_z - base) / maxf(1.0, step_z)
	return maxf(dx, dz)

func _make_ground_texture(size: Vector2, base_image: Image = null) -> ImageTexture:
	if texture_size.x <= 2 or texture_size.y <= 2:
		return null
	var tex_w := texture_size.x
	var tex_h := texture_size.y
	var img: Image = base_image
	var use_base := base_image != null
	if img == null:
		img = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
	var line_width := maxf(0.5, grid_line_width)
	var patches := _make_patches(tex_w, tex_h)
	var roads: Array[Dictionary] = _make_roads()
	var fields: Array[Rect2] = _make_fields()
	var height_span := maxf(0.0, _height_max - _height_min)
	for y in range(tex_h):
		var world_y := (float(y) / float(tex_h - 1)) * size.y
		for x in range(tex_w):
			var world_x := (float(x) / float(tex_w - 1)) * size.x
			var col: Color = img.get_pixel(x, y) if use_base else ground_color
			var height_ratio: float = 0.0
			var slope: float = 0.0
			if not _height_grid.is_empty():
				var height: float = _sample_height_grid(_height_grid, _map_size, _grid_x, _grid_z, Vector2(world_x, world_y))
				if height_span > 0.0:
					height_ratio = clampf((height - _height_min) / height_span, 0.0, 1.0)
				if ground_overlay_enabled or roads_enabled or fields_enabled:
					slope = _sample_slope(Vector2(world_x, world_y))
			if ground_overlay_enabled:
				if not use_base:
					if noise_strength > 0.0 and noise_scale > 0.0:
						var n := _hash_noise(world_x / noise_scale, world_y / noise_scale)
						var shade := (n - 0.5) * 2.0 * noise_strength
						col = _shade_color(col, shade)
					if not patches.is_empty():
						var blend := _sample_patches(Vector2(float(x), float(y)), patches)
						if blend > 0.0:
							col = col.lerp(patch_color, blend)
					if grid_spacing > 0.0:
						var mx := fposmod(world_x, grid_spacing)
						var my := fposmod(world_y, grid_spacing)
						if mx < line_width or mx > grid_spacing - line_width or my < line_width or my > grid_spacing - line_width:
							col = col.lerp(grid_color, clampf(grid_opacity, 0.0, 1.0))
				if terrain_tint_strength > 0.0:
					var tint: Color = _terrain_color_by_height(height_ratio)
					col = col.lerp(tint, clampf(terrain_tint_strength, 0.0, 1.0))
				if slope_rock_strength > 0.0 and slope > slope_rock_threshold:
					var denom := maxf(0.001, slope_rock_max - slope_rock_threshold)
					var t := clampf((slope - slope_rock_threshold) / denom, 0.0, 1.0)
					col = col.lerp(slope_rock_color, t * slope_rock_strength)
			if fields_enabled and not fields.is_empty():
				if height_ratio <= field_max_height_ratio and slope <= field_max_slope:
					var field_alpha: float = _sample_fields(Vector2(world_x, world_y), fields)
					if field_alpha > 0.0:
						col = col.lerp(field_color, field_alpha * field_opacity)
			if roads_enabled and not roads.is_empty():
				if height_ratio <= road_max_height_ratio and slope <= road_max_slope and not _is_in_lake(Vector2(world_x, world_y)) and not _is_in_oilfield(Vector2(world_x, world_y)):
					var road_alpha: float = _sample_roads(Vector2(world_x, world_y), roads)
					if road_alpha > 0.0:
						col = col.lerp(road_color, road_alpha * road_opacity)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _hash_noise(x: float, y: float) -> float:
	var n := sin(x * 12.9898 + y * 78.233) * 43758.5453
	return n - floor(n)

func _shade_color(color: Color, amount: float) -> Color:
	return Color(
		clampf(color.r + amount, 0.0, 1.0),
		clampf(color.g + amount, 0.0, 1.0),
		clampf(color.b + amount, 0.0, 1.0),
		color.a
	)

func _make_patches(tex_w: int, tex_h: int) -> Array[Dictionary]:
	var patches: Array[Dictionary] = []
	if patch_count <= 0:
		return patches
	var min_radius := maxf(1.0, patch_radius_min)
	var max_radius := maxf(min_radius, patch_radius_max)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tex_w * 92821 + tex_h * 68917)
	for i in range(patch_count):
		var pos := Vector2(rng.randf_range(0.0, float(tex_w - 1)), rng.randf_range(0.0, float(tex_h - 1)))
		var radius := rng.randf_range(min_radius, max_radius)
		patches.append({"pos": pos, "radius": radius})
	return patches

func _sample_patches(pos: Vector2, patches: Array[Dictionary]) -> float:
	var blend := 0.0
	var softness := maxf(0.1, patch_softness)
	for patch in patches:
		var center_value: Variant = patch.get("pos", Vector2.ZERO)
		var radius_value: Variant = patch.get("radius", 0.0)
		if center_value is not Vector2:
			continue
		var radius := float(radius_value)
		if radius <= 0.0:
			continue
		var dist := pos.distance_to(center_value)
		if dist > radius:
			continue
		var t := 1.0 - (dist / radius)
		var weight := pow(t, softness)
		if weight > blend:
			blend = weight
	return clampf(blend, 0.0, 1.0)

func _make_roads() -> Array[Dictionary]:
	var roads: Array[Dictionary] = []
	if not roads_enabled:
		return roads
	var size := _map_size
	if size == Vector2.ZERO:
		size = Vector2(2000, 1200)
	var default_p1 := Vector2(size.x * 0.1, size.y * 0.5)
	var default_p2 := Vector2(size.x * 0.9, size.y * 0.5)
	var p1: Vector2 = _get_start_position("p1", default_p1)
	var p2: Vector2 = _get_start_position("p2", default_p2)
	var mid := (p1 + p2) * 0.5
	var curve := Vector2(0.0, road_curve_offset)
	var main_points: Array[Vector2] = [p1, mid + curve, p2]
	_add_road_segments(roads, main_points)
	if road_cross_offset > 0.0:
		var cross_y := size.y * 0.5
		var cross_a := Vector2(0.0, cross_y + road_cross_offset)
		var cross_b := Vector2(size.x, cross_y + road_cross_offset)
		var cross_c := Vector2(0.0, cross_y - road_cross_offset)
		var cross_d := Vector2(size.x, cross_y - road_cross_offset)
		roads.append({"a": cross_a, "b": cross_b})
		roads.append({"a": cross_c, "b": cross_d})
	return roads

func _add_road_segments(roads: Array[Dictionary], points: Array[Vector2]) -> void:
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		roads.append({"a": points[i], "b": points[i + 1]})

func _sample_roads(pos: Vector2, roads: Array[Dictionary]) -> float:
	var min_dist: float = INF
	for road in roads:
		var a_value: Variant = road.get("a", Vector2.ZERO)
		var b_value: Variant = road.get("b", Vector2.ZERO)
		if a_value is not Vector2 or b_value is not Vector2:
			continue
		var a: Vector2 = a_value
		var b: Vector2 = b_value
		var d := _distance_to_segment(pos, a, b)
		if d < min_dist:
			min_dist = d
	if min_dist == INF:
		return 0.0
	var half_width := maxf(1.0, road_world_width * 0.5)
	if min_dist > (half_width + road_softness):
		return 0.0
	var t := clampf(1.0 - ((min_dist - half_width) / maxf(1.0, road_softness)), 0.0, 1.0)
	return t

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq <= 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / len_sq, 0.0, 1.0)
	var proj := a + ab * t
	return point.distance_to(proj)

func _make_fields() -> Array[Rect2]:
	var fields: Array[Rect2] = []
	if not fields_enabled or field_count <= 0:
		return fields
	var size := _map_size
	if size == Vector2.ZERO:
		size = Vector2(2000, 1200)
	var rng := RandomNumberGenerator.new()
	rng.seed = field_seed
	var attempts := field_count * 4
	for i in range(attempts):
		if fields.size() >= field_count:
			break
		var w := rng.randf_range(field_world_min_size.x, field_world_max_size.x)
		var h := rng.randf_range(field_world_min_size.y, field_world_max_size.y)
		var x := rng.randf_range(0.0, maxf(0.0, size.x - w))
		var y := rng.randf_range(0.0, maxf(0.0, size.y - h))
		var rect := Rect2(Vector2(x, y), Vector2(w, h))
		if _intersects_build_zones(rect):
			continue
		fields.append(rect)
	return fields

func _intersects_build_zones(rect: Rect2) -> bool:
	for zone in _build_zones:
		if rect.intersects(zone):
			return true
	return false

func _sample_fields(pos: Vector2, fields: Array[Rect2]) -> float:
	var softness := maxf(0.0, field_softness)
	for rect in fields:
		if not rect.has_point(pos):
			continue
		var left := pos.x - rect.position.x
		var right := rect.position.x + rect.size.x - pos.x
		var top := pos.y - rect.position.y
		var bottom := rect.position.y + rect.size.y - pos.y
		var edge := minf(minf(left, right), minf(top, bottom))
		if softness <= 0.0:
			return 1.0
		var t := clampf(edge / softness, 0.0, 1.0)
		if field_noise_strength > 0.0 and field_noise_scale > 0.0:
			var n := _hash_noise(pos.x / field_noise_scale, pos.y / field_noise_scale)
			var noise_gain := lerpf(1.0 - field_noise_strength, 1.0, n)
			t *= noise_gain
		return t
	return 0.0
