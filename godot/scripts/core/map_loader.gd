@tool
class_name MapLoader
extends Node2D

@export var map_path := "res://data/maps/test_map.json":
	set(value):
		map_path = value
		if is_inside_tree():
			load_map(map_path)
@export var show_map_bounds := true
@export var map_fill := Color(0.18, 0.22, 0.17, 1.0)
@export var map_outline := Color(0.1, 0.12, 0.1, 1.0)
@export var render_2d := false
@export var show_facets := true
@export var facet_size := 220.0:
	set(value):
		facet_size = value
		if is_inside_tree():
			_build_facets()
			queue_redraw()
@export var facet_variation := 0.05:
	set(value):
		facet_variation = value
		if is_inside_tree():
			_build_facets()
			queue_redraw()
@export var facet_seed := 1337:
	set(value):
		facet_seed = value
		if is_inside_tree():
			_build_facets()
			queue_redraw()

@export var show_grid := true
@export var grid_spacing := 100.0
@export var grid_color := Color(0.18, 0.2, 0.16, 0.25)
@export var grid_width := 1.0

@export var build_zone_fill := Color(0.12, 0.5, 0.25, 0.14)
@export var build_zone_outline := Color(0.16, 0.65, 0.32, 0.55)
@export var build_zone_hatch := true
@export var build_zone_hatch_spacing := 26.0
@export var build_zone_hatch_color := Color(0.16, 0.65, 0.32, 0.25)

@export var show_resource_nodes := true
@export var resource_color := Color(0.92, 0.76, 0.32, 0.9)
@export var resource_radius := 18.0
@export var resource_outline := Color(0.4, 0.3, 0.12, 0.9)
@export var resource_cross := Color(0.25, 0.2, 0.08, 0.9)

@export var start_color_p1 := Color(0.2, 0.5, 1.0, 0.9)
@export var start_color_p2 := Color(1.0, 0.3, 0.3, 0.9)
@export var start_color_neutral := Color(0.8, 0.8, 0.8, 0.9)
@export var start_radius := 12.0
@export var hq_size := Vector2(36, 36)
@export var hq_outline := Color(0.9, 0.9, 0.9, 0.9)

@export var rally_color := Color(0.7, 0.7, 0.7, 0.9)
@export var rally_radius := 10.0
@export var show_rally_lines := true
@export var rally_line_color := Color(0.8, 0.8, 0.8, 0.4)
@export var rally_line_width := 2.0

var _map_size := Vector2.ZERO
var _build_zones: Array = []
var _resource_nodes: Array = []
var _start_positions: Array = []
var _rally_targets: Array = []
var _facets: Array = []

func _ready() -> void:
	add_to_group("map_loader")
	# Prefer a centralized map selection from the autoload `GameState` when available
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		map_path = gs.map_path

	# If a 3D camera is present on the viewport, we're running the 3D main scene;
	# disable the 2D map rendering to avoid overlaying the 3D terrain.
	if Engine.has_singleton("SceneTree"):
		var cam3d: Camera3D = null
		if get_viewport() != null:
			cam3d = get_viewport().get_camera_3d()
		if cam3d != null:
			render_2d = false

	load_map(map_path)

func _process(delta: float) -> void:
	# Continuously ensure we don't draw the 2D map when a 3D camera is active
	if get_tree() == null:
		return
	var cam3d: Camera3D = null
	if get_viewport() != null:
		cam3d = get_viewport().get_camera_3d()
	if cam3d != null and render_2d:
		render_2d = false
		queue_redraw()
	elif cam3d == null and not render_2d:
		# If no 3D camera and this MapLoader instance is part of a 2D scene, enable rendering
		# (some scenes explicitly set `render_2d` to true in the scene file; respect that)
		# We only auto-enable if the node has a parent CanvasItem or is in a known 2D context.
		var in_2d_context := false
		var node := self
		while node != null:
			if node is CanvasItem:
				in_2d_context = true
				break
			node = node.get_parent()
		if in_2d_context:
			render_2d = true
			queue_redraw()

func load_map(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MapLoader: Failed to open map at %s" % path)
		return
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("MapLoader: Invalid JSON in %s" % path)
		return
	_map_size = _read_size(data.get("size", {}))
	_build_zones = data.get("build_zones", [])
	_resource_nodes = data.get("resource_nodes", [])
	_start_positions = data.get("start_positions", [])
	_rally_targets = data.get("rally_targets", [])
	_build_facets()
	queue_redraw()

func _draw() -> void:
	if not render_2d:
		return
	if show_map_bounds and _map_size != Vector2.ZERO:
		var map_rect := Rect2(Vector2.ZERO, _map_size)
		draw_rect(map_rect, map_fill, true)
		if show_facets:
			for facet in _facets:
				if typeof(facet) == TYPE_DICTIONARY:
					var points = facet.get("points")
					var color = facet.get("color")
					if points is PackedVector2Array and color is Color:
						draw_colored_polygon(points, color)
		draw_rect(map_rect, map_outline, false, 2.0)

	if show_grid and _map_size != Vector2.ZERO and grid_spacing > 0.0:
		_draw_grid(_map_size, grid_spacing, grid_color, grid_width)

	for zone in _build_zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		var rect := Rect2(
			Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
			Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
		)
		draw_rect(rect, build_zone_fill, true)
		draw_rect(rect, build_zone_outline, false, 2.0)
		if build_zone_hatch:
			_draw_hatch(rect, build_zone_hatch_spacing, build_zone_hatch_color)

	if show_rally_lines:
		_draw_rally_lines()

	if show_resource_nodes:
		for node in _resource_nodes:
			if typeof(node) != TYPE_DICTIONARY:
				continue
			var pos := _vec2_from(node)
			draw_circle(pos, resource_radius, resource_color)
			draw_circle(pos, resource_radius, resource_outline, false, 2.0)
			draw_line(pos + Vector2(-resource_radius * 0.6, 0.0), pos + Vector2(resource_radius * 0.6, 0.0), resource_cross, 2.0)
			draw_line(pos + Vector2(0.0, -resource_radius * 0.6), pos + Vector2(0.0, resource_radius * 0.6), resource_cross, 2.0)

	for start in _start_positions:
		if typeof(start) != TYPE_DICTIONARY:
			continue
		var id := str(start.get("id", ""))
		var color := start_color_neutral
		if id == "p1":
			color = start_color_p1
		elif id == "p2":
			color = start_color_p2
		var pos := _vec2_from(start)
		var hq_rect := Rect2(pos - (hq_size / 2.0), hq_size)
		draw_rect(hq_rect, color, true)
		draw_rect(hq_rect, hq_outline, false, 2.0)
		draw_circle(pos, start_radius, color)

	for target in _rally_targets:
		if typeof(target) != TYPE_DICTIONARY:
			continue
		draw_circle(_vec2_from(target), rally_radius, rally_color)

func _read_size(data: Dictionary) -> Vector2:
	var width := float(data.get("width", 0.0))
	var height := float(data.get("height", 0.0))
	return Vector2(width, height)

func _vec2_from(data: Dictionary) -> Vector2:
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))

func _draw_grid(size: Vector2, spacing: float, color: Color, width: float) -> void:
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), color, width)
		x += spacing
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), color, width)
		y += spacing

func _draw_hatch(rect: Rect2, spacing: float, color: Color) -> void:
	if spacing <= 0.0:
		return
	var start := rect.position.x - rect.size.y
	var end := rect.position.x + rect.size.x
	var x := start
	while x <= end:
		var from := Vector2(x, rect.position.y)
		var to := Vector2(x + rect.size.y, rect.position.y + rect.size.y)
		draw_line(from, to, color, 1.0)
		x += spacing

func _draw_rally_lines() -> void:
	if _rally_targets.is_empty() or _start_positions.is_empty():
		return
	var rally_points: Array = []
	for target in _rally_targets:
		if typeof(target) == TYPE_DICTIONARY:
			rally_points.append(_vec2_from(target))
	if rally_points.is_empty():
		return
	for start in _start_positions:
		if typeof(start) != TYPE_DICTIONARY:
			continue
		var start_pos := _vec2_from(start)
		var best_point := Vector2.ZERO
		var best_dist := INF
		for rally_pos in rally_points:
			var dist := start_pos.distance_squared_to(rally_pos)
			if dist < best_dist:
				best_dist = dist
				best_point = rally_pos
		draw_line(start_pos, best_point, rally_line_color, rally_line_width)

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()

func _build_facets() -> void:
	_facets.clear()
	if _map_size == Vector2.ZERO or facet_size <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(facet_seed)
	var cols := int(ceil(_map_size.x / facet_size))
	var rows := int(ceil(_map_size.y / facet_size))
	for y in range(rows):
		for x in range(cols):
			var x0 := x * facet_size
			var y0 := y * facet_size
			var x1 := minf(x0 + facet_size, _map_size.x)
			var y1 := minf(y0 + facet_size, _map_size.y)
			var p0 := Vector2(x0, y0)
			var p1 := Vector2(x1, y0)
			var p2 := Vector2(x1, y1)
			var p3 := Vector2(x0, y1)
			var shade_a := rng.randf_range(-facet_variation, facet_variation)
			var shade_b := rng.randf_range(-facet_variation, facet_variation)
			var col_a := _shade(map_fill, shade_a)
			var col_b := _shade(map_fill, shade_b)
			if rng.randf() < 0.5:
				_facets.append({"points": PackedVector2Array([p0, p1, p2]), "color": col_a})
				_facets.append({"points": PackedVector2Array([p0, p2, p3]), "color": col_b})
			else:
				_facets.append({"points": PackedVector2Array([p0, p1, p3]), "color": col_a})
				_facets.append({"points": PackedVector2Array([p1, p2, p3]), "color": col_b})

func _shade(src: Color, amount: float) -> Color:
	return Color(
		clampf(src.r + amount, 0.0, 1.0),
		clampf(src.g + amount, 0.0, 1.0),
		clampf(src.b + amount, 0.0, 1.0),
		src.a
	)
