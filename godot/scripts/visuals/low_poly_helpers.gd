class_name LowPolyHelpers
extends RefCounted

static func make_mesh(points: PackedVector2Array, color: Color) -> MeshInstance2D:
	if points.size() < 3:
		return null
	var indices := Geometry2D.triangulate_polygon(points)
	if indices.is_empty():
		return null
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(points.size())
	colors.resize(points.size())
	for i in range(points.size()):
		var point := points[i]
		vertices[i] = Vector3(point.x, point.y, 0.0)
		colors[i] = color
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance2D.new()
	instance.mesh = mesh
	return instance

static func add_mesh(parent: Node, points: PackedVector2Array, color: Color, offset := Vector2.ZERO) -> MeshInstance2D:
	var instance := make_mesh(points, color)
	if instance == null:
		return null
	if instance is Node2D:
		instance.position = offset
	parent.add_child(instance)
	return instance

static func make_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> MeshInstance2D:
	var points := PackedVector2Array([a, b, c, d])
	return make_mesh(points, color)

static func add_quad(parent: Node, a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> MeshInstance2D:
	var instance := make_quad(a, b, c, d, color)
	if instance == null:
		return null
	parent.add_child(instance)
	return instance

static func offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	shifted.resize(points.size())
	for i in range(points.size()):
		shifted[i] = points[i] + offset
	return shifted

static func make_outline(points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	var line_points := PackedVector2Array()
	line_points.append_array(points)
	if points.size() > 0:
		line_points.append(points[0])
	line.points = line_points
	return line
