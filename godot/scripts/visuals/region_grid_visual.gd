class_name RegionGridVisual
extends Node3D

## Region Grid Visual
##
## Renders the region grid overlay on the map, showing:
## - Grid lines between regions
## - Color-coded region ownership (blue/red/grey/yellow)
## - Resource region markers

# =============================================================================
# EXPORTS
# =============================================================================

@export var grid_line_color := Color(0.4, 0.4, 0.4, 0.5)
@export var grid_line_width := 2.0
@export var grid_line_height := 0.5  # Height above ground

@export var region_overlay_height := 0.3  # Slightly above ground
@export var region_overlay_alpha := 0.25

@export var p1_color := Color(0.2, 0.5, 1.0)  # Blue
@export var p2_color := Color(1.0, 0.3, 0.3)  # Red
@export var neutral_color := Color(0.5, 0.5, 0.5)  # Grey
@export var contested_color := Color(1.0, 1.0, 0.0)  # Yellow

@export var resource_marker_height := 5.0
@export var resource_marker_size := 15.0
@export var mine_marker_color := Color(0.6, 0.4, 0.2)  # Brown
@export var oil_marker_color := Color(0.1, 0.1, 0.1)  # Black

@export var border_thickness := 3.0
@export var border_height := 1.0

@export var update_interval := 0.5  # How often to update colors

# =============================================================================
# STATE
# =============================================================================

var _region_controller: RegionController = null
var _grid_lines: Node3D = null
var _region_overlays: Dictionary = {}  # region_id -> MeshInstance3D
var _region_borders: Dictionary = {}   # region_id -> MeshInstance3D
var _resource_markers: Dictionary = {} # region_id -> MeshInstance3D
var _update_timer := 0.0
var _initialized := false

# =============================================================================
# INITIALIZATION
# =============================================================================

func configure(region_controller: RegionController) -> void:
	_region_controller = region_controller
	_region_controller.region_state_changed.connect(_on_region_state_changed)
	_region_controller.region_controller_changed.connect(_on_region_controller_changed)

func initialize() -> void:
	if _region_controller == null:
		push_error("RegionGridVisual: No region controller configured")
		return

	_create_grid_lines()
	_create_region_overlays()
	_create_resource_markers()
	_initialized = true
	print("[RegionGridVisual] Initialized with %d regions" % _region_overlays.size())

# =============================================================================
# UPDATE
# =============================================================================

func _process(delta: float) -> void:
	if not _initialized:
		return

	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_all_region_colors()

# =============================================================================
# GRID LINES
# =============================================================================

func _create_grid_lines() -> void:
	_grid_lines = Node3D.new()
	_grid_lines.name = "GridLines"
	add_child(_grid_lines)

	var map_size := _region_controller.map_size
	var region_size := _region_controller.region_size

	# Create vertical lines
	for col in range(RegionController.GRID_COLS + 1):
		var x := col * region_size.x
		_create_line(
			Vector3(x, grid_line_height, 0),
			Vector3(x, grid_line_height, map_size.y)
		)

	# Create horizontal lines
	for row in range(RegionController.GRID_ROWS + 1):
		var z := row * region_size.y
		_create_line(
			Vector3(0, grid_line_height, z),
			Vector3(map_size.x, grid_line_height, z)
		)

func _create_line(start: Vector3, end: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()

	# Calculate line properties
	var delta := end - start
	var length := delta.length()
	var center := (start + end) * 0.5

	# Create box mesh for the line
	var box := BoxMesh.new()
	if abs(delta.x) > abs(delta.z):
		# Horizontal line
		box.size = Vector3(length, 0.1, grid_line_width)
	else:
		# Vertical line
		box.size = Vector3(grid_line_width, 0.1, length)

	mesh_instance.mesh = box
	mesh_instance.position = center

	# Create material
	var material := StandardMaterial3D.new()
	material.albedo_color = grid_line_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	_grid_lines.add_child(mesh_instance)

# =============================================================================
# REGION OVERLAYS
# =============================================================================

func _create_region_overlays() -> void:
	for region in _region_controller.get_all_regions():
		_create_region_overlay(region)
		_create_region_border(region)

func _create_region_overlay(region: Region) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Overlay_" + region.id

	# Create plane mesh for the region
	var plane := PlaneMesh.new()
	plane.size = Vector2(region.world_rect.size.x * 0.95, region.world_rect.size.y * 0.95)
	mesh_instance.mesh = plane

	# Position at region center
	var center := region.get_center()
	mesh_instance.position = Vector3(center.x, region_overlay_height, center.y)

	# Create material
	var material := StandardMaterial3D.new()
	material.albedo_color = _get_region_color(region)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material

	add_child(mesh_instance)
	_region_overlays[region.id] = mesh_instance

func _create_region_border(region: Region) -> void:
	var border_node := Node3D.new()
	border_node.name = "Border_" + region.id

	var rect := region.world_rect
	var half_thickness := border_thickness * 0.5

	# Create four border segments
	var segments := [
		# Top border
		{
			"pos": Vector3(rect.position.x + rect.size.x * 0.5, border_height, rect.position.y),
			"size": Vector3(rect.size.x, 0.2, border_thickness)
		},
		# Bottom border
		{
			"pos": Vector3(rect.position.x + rect.size.x * 0.5, border_height, rect.position.y + rect.size.y),
			"size": Vector3(rect.size.x, 0.2, border_thickness)
		},
		# Left border
		{
			"pos": Vector3(rect.position.x, border_height, rect.position.y + rect.size.y * 0.5),
			"size": Vector3(border_thickness, 0.2, rect.size.y)
		},
		# Right border
		{
			"pos": Vector3(rect.position.x + rect.size.x, border_height, rect.position.y + rect.size.y * 0.5),
			"size": Vector3(border_thickness, 0.2, rect.size.y)
		}
	]

	var material := StandardMaterial3D.new()
	material.albedo_color = _get_border_color(region)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	for seg in segments:
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = seg["size"]
		mesh_instance.mesh = box
		mesh_instance.position = seg["pos"]
		mesh_instance.material_override = material.duplicate()
		border_node.add_child(mesh_instance)

	add_child(border_node)
	_region_borders[region.id] = border_node

# =============================================================================
# RESOURCE MARKERS
# =============================================================================

func _create_resource_markers() -> void:
	for region in _region_controller.get_all_regions():
		if region.is_resource_region():
			_create_resource_marker(region)

func _create_resource_marker(region: Region) -> void:
	var marker := Node3D.new()
	marker.name = "ResourceMarker_" + region.id

	var center := region.get_center()
	marker.position = Vector3(center.x, resource_marker_height, center.y)

	# Create marker mesh (diamond shape for resources)
	var mesh_instance := MeshInstance3D.new()

	if region.type == Region.Type.RESOURCE_OIL:
		# Oil: cylinder/barrel shape
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = resource_marker_size * 0.4
		cylinder.bottom_radius = resource_marker_size * 0.5
		cylinder.height = resource_marker_size * 0.8
		mesh_instance.mesh = cylinder

		var material := StandardMaterial3D.new()
		material.albedo_color = oil_marker_color
		material.emission_enabled = true
		material.emission = oil_marker_color
		material.emission_energy_multiplier = 0.3
		mesh_instance.material_override = material

	else:  # Mine
		# Mine: crystal/prism shape
		var prism := PrismMesh.new()
		prism.size = Vector3(resource_marker_size, resource_marker_size * 1.2, resource_marker_size)
		mesh_instance.mesh = prism

		var material := StandardMaterial3D.new()
		material.albedo_color = mine_marker_color
		material.emission_enabled = true
		material.emission = mine_marker_color
		material.emission_energy_multiplier = 0.3
		mesh_instance.material_override = material

	marker.add_child(mesh_instance)
	add_child(marker)
	_resource_markers[region.id] = marker

# =============================================================================
# COLOR UPDATES
# =============================================================================

func _update_all_region_colors() -> void:
	for region_id in _region_overlays:
		var region := _region_controller.get_region(region_id)
		if region == null:
			continue

		_update_region_overlay_color(region)
		_update_region_border_color(region)

func _update_region_overlay_color(region: Region) -> void:
	var mesh_instance: MeshInstance3D = _region_overlays.get(region.id)
	if mesh_instance == null:
		return

	var material: StandardMaterial3D = mesh_instance.material_override
	if material == null:
		return

	material.albedo_color = _get_region_color(region)

func _update_region_border_color(region: Region) -> void:
	var border_node: Node3D = _region_borders.get(region.id)
	if border_node == null:
		return

	var border_color := _get_border_color(region)
	for child in border_node.get_children():
		if child is MeshInstance3D:
			var material: StandardMaterial3D = child.material_override
			if material != null:
				material.albedo_color = border_color

func _get_region_color(region: Region) -> Color:
	var base_color: Color
	match region.state:
		Region.State.CONTROLLED_P1:
			base_color = p1_color
		Region.State.CONTROLLED_P2:
			base_color = p2_color
		Region.State.CONTESTED:
			base_color = contested_color
		_:
			base_color = neutral_color

	# Adjust alpha
	base_color.a = region_overlay_alpha

	# Make resource regions slightly more visible
	if region.is_resource_region():
		base_color.a *= 1.5

	return base_color

func _get_border_color(region: Region) -> Color:
	var base_color: Color
	match region.state:
		Region.State.CONTROLLED_P1:
			base_color = p1_color
		Region.State.CONTROLLED_P2:
			base_color = p2_color
		Region.State.CONTESTED:
			base_color = contested_color
		_:
			base_color = neutral_color

	base_color.a = 0.7
	return base_color

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_region_state_changed(region_id: String, _old_state: Region.State, _new_state: Region.State) -> void:
	var region := _region_controller.get_region(region_id)
	if region != null:
		_update_region_overlay_color(region)
		_update_region_border_color(region)

func _on_region_controller_changed(region_id: String, _old_controller: String, _new_controller: String) -> void:
	var region := _region_controller.get_region(region_id)
	if region != null:
		_update_region_overlay_color(region)
		_update_region_border_color(region)

# =============================================================================
# VISIBILITY
# =============================================================================

func set_grid_visible(visible: bool) -> void:
	if _grid_lines != null:
		_grid_lines.visible = visible

func set_overlays_visible(visible: bool) -> void:
	for mesh_instance in _region_overlays.values():
		mesh_instance.visible = visible

func set_borders_visible(visible: bool) -> void:
	for border_node in _region_borders.values():
		border_node.visible = visible

func set_markers_visible(visible: bool) -> void:
	for marker in _resource_markers.values():
		marker.visible = visible
