class_name RegionController
extends Node

## Region Controller
##
## Manages all regions on the map, including:
## - Region grid creation and initialization
## - Ground presence calculation (fog of war / stationed units)
## - Air dominance calculation (aircraft patrols) - Phase 2
## - Control state transitions
## - Income generation from controlled regions

# =============================================================================
# CONSTANTS
# =============================================================================

const GRID_COLS := 7
const GRID_ROWS := 7

## Time to capture a neutral region (seconds)
const CAPTURE_TIME := 5.0

## Time for contested region to decay to neutral (seconds)
const CONTEST_DECAY_TIME := 5.0

## Dominance threshold - need 50% advantage for control
const DOMINANCE_THRESHOLD := 1.5

## Minimum presence required to claim a region
const MIN_PRESENCE_THRESHOLD := 0.5

## Income rates
const INCOME_NORMAL := 1.0
const INCOME_MINE := 3.0
const INCOME_OIL := 5.0

# =============================================================================
# SIGNALS
# =============================================================================

signal region_state_changed(region_id: String, old_state: Region.State, new_state: Region.State)
signal region_controller_changed(region_id: String, old_controller: String, new_controller: String)

# =============================================================================
# STATE
# =============================================================================

## Dictionary of region_id -> Region
var regions: Dictionary = {}

## 2D array for grid access [row][col]
var region_grid: Array = []

## Map dimensions
var map_size: Vector2 = Vector2(6144, 6144)

## Region size (calculated from map size and grid dimensions)
var region_size: Vector2 = Vector2.ZERO

## Teams reference
var _teams: Dictionary = {}

## Visibility controller reference for fog of war queries
var _visibility_controller: VisibilityController = null

# =============================================================================
# RESOURCE REGION CONFIGURATION
# =============================================================================

## Resource region definitions - symmetric layout
## Format: [grid_col, grid_row, type]
const RESOURCE_REGIONS := [
	# Oil fields - center column
	[3, 0, Region.Type.RESOURCE_OIL],   # A4 - North oil
	[3, 3, Region.Type.RESOURCE_OIL],   # D4 - Center oil
	[3, 6, Region.Type.RESOURCE_OIL],   # G4 - South oil
	# Mines - symmetric on both sides
	[1, 1, Region.Type.RESOURCE_MINE],  # B2 - P1 side mine
	[5, 1, Region.Type.RESOURCE_MINE],  # B6 - P2 side mine
	[1, 5, Region.Type.RESOURCE_MINE],  # F2 - P1 side mine
	[5, 5, Region.Type.RESOURCE_MINE],  # F6 - P2 side mine
]

## Base region definitions - corners
## Format: [grid_col, grid_row, owner]
const BASE_REGIONS := [
	[0, 0, "p1"],  # A1 - P1 base
	[0, 6, "p1"],  # G1 - P1 rear
	[6, 0, "p2"],  # A7 - P2 base
	[6, 6, "p2"],  # G7 - P2 rear
]

# =============================================================================
# INITIALIZATION
# =============================================================================

func configure(teams: Dictionary, visibility_controller: VisibilityController = null) -> void:
	_teams = teams
	_visibility_controller = visibility_controller

func initialize(map_width: float, map_height: float) -> void:
	map_size = Vector2(map_width, map_height)
	region_size = Vector2(map_width / GRID_COLS, map_height / GRID_ROWS)

	_create_region_grid()
	_configure_resource_regions()
	_configure_base_regions()

	print("[RegionController] Initialized %d regions (%dx%d grid)" % [regions.size(), GRID_COLS, GRID_ROWS])
	print("[RegionController] Region size: %s" % region_size)

func _create_region_grid() -> void:
	regions.clear()
	region_grid.clear()

	# Row labels: A, B, C, D, E, F, G
	var row_labels := ["A", "B", "C", "D", "E", "F", "G"]

	for row in range(GRID_ROWS):
		var grid_row: Array = []
		for col in range(GRID_COLS):
			# Create region ID (e.g., "A1", "B3", "G7")
			var region_id := "%s%d" % [row_labels[row], col + 1]

			# Calculate world rect
			var rect := Rect2(
				col * region_size.x,
				row * region_size.y,
				region_size.x,
				region_size.y
			)

			var region := Region.create(region_id, Vector2i(col, row), rect)
			regions[region_id] = region
			grid_row.append(region)

		region_grid.append(grid_row)

func _configure_resource_regions() -> void:
	for config in RESOURCE_REGIONS:
		var col: int = config[0]
		var row: int = config[1]
		var type: Region.Type = config[2]

		var region := get_region_at_grid(col, row)
		if region != null:
			region.type = type
			region.base_income = Region._get_base_income_for_type(type)
			print("[RegionController] Configured resource region %s as %s" % [region.id, _type_to_string(type)])

func _configure_base_regions() -> void:
	for config in BASE_REGIONS:
		var col: int = config[0]
		var row: int = config[1]
		var owner: String = config[2]

		var region := get_region_at_grid(col, row)
		if region != null:
			region.type = Region.Type.BASE
			region.base_income = 0.0
			region.set_controller(owner)
			print("[RegionController] Configured base region %s for %s" % [region.id, owner])

func _type_to_string(type: Region.Type) -> String:
	match type:
		Region.Type.NORMAL: return "NORMAL"
		Region.Type.RESOURCE_MINE: return "MINE"
		Region.Type.RESOURCE_OIL: return "OIL"
		Region.Type.BASE: return "BASE"
	return "UNKNOWN"

# =============================================================================
# UPDATE LOOP
# =============================================================================

func update(delta: float) -> void:
	_update_all_presence()
	_update_all_control(delta)

func _update_all_presence() -> void:
	for region in regions.values():
		region.reset_presence()
		_calculate_ground_presence(region)
		_calculate_air_dominance(region)

func _calculate_ground_presence(region: Region) -> void:
	if region.is_base_region():
		# Base regions are always controlled by their owner
		return

	if region.is_resource_region():
		# Resource regions require stationed units
		region.p1_ground_presence = _count_stationed_units(region, "p1")
		region.p2_ground_presence = _count_stationed_units(region, "p2")
	else:
		# Normal regions: fog of war visibility is enough
		region.p1_ground_presence = _get_vision_coverage(region, "p1")
		region.p2_ground_presence = _get_vision_coverage(region, "p2")

	# Buildings always count (with higher weight)
	region.p1_ground_presence += _count_buildings(region, "p1") * 2.0
	region.p2_ground_presence += _count_buildings(region, "p2") * 2.0

func _count_stationed_units(region: Region, team_id: String) -> float:
	var count := 0.0
	var group_name := "units_%s" % team_id

	for node in get_tree().get_nodes_in_group(group_name):
		if node == null or not is_instance_valid(node):
			continue
		var pos := Vector2(node.global_position.x, node.global_position.y)
		# Handle 3D positions (x, z plane)
		if node.global_position is Vector3:
			pos = Vector2(node.global_position.x, node.global_position.z)

		if region.contains_point(pos):
			count += 1.0

	# Also count collectors
	var collector_group := "collectors_%s" % team_id
	for node in get_tree().get_nodes_in_group(collector_group):
		if node == null or not is_instance_valid(node):
			continue
		var pos := Vector2(node.global_position.x, node.global_position.y)
		if node.global_position is Vector3:
			pos = Vector2(node.global_position.x, node.global_position.z)

		if region.contains_point(pos):
			count += 0.5  # Collectors count less

	return count

func _get_vision_coverage(region: Region, team_id: String) -> float:
	# For now, check if any vision source covers the region center
	# This will be enhanced when we integrate with VisibilityController
	var center := region.get_center()
	var coverage := 0.0

	var vision_group := "vision_%s" % team_id
	for node in get_tree().get_nodes_in_group(vision_group):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_vision_radius"):
			continue

		var pos := Vector2(node.global_position.x, node.global_position.y)
		if node.global_position is Vector3:
			pos = Vector2(node.global_position.x, node.global_position.z)

		var radius := float(node.get_vision_radius())
		var distance := pos.distance_to(center)

		if distance < radius:
			# Full coverage if center is within vision
			coverage += 1.0
		elif distance < radius + region_size.x * 0.5:
			# Partial coverage if vision overlaps region
			coverage += 0.5

	return coverage

func _calculate_air_dominance(region: Region) -> void:
	if region.is_base_region():
		# Base regions have inherent air dominance from owner
		if region.controller == "p1":
			region.p1_air_dominance = 5.0
		elif region.controller == "p2":
			region.p2_air_dominance = 5.0
		return

	var region_center := region.get_center()

	# Check all aircraft
	for node in get_tree().get_nodes_in_group("units"):
		if node == null or not is_instance_valid(node):
			continue

		var unit := node as Unit
		if unit == null or unit.unit_kind != "aircraft":
			continue

		# Get aircraft position
		var pos := Vector2(unit.global_position.x, unit.global_position.y)

		# Get air power and influence radius from behavior component
		var air_power := 0.0
		var influence_radius := 1000.0

		if unit._aircraft_behavior != null:
			air_power = unit._aircraft_behavior.get_air_power()
			influence_radius = unit._aircraft_behavior.get_influence_radius()
		else:
			# Fallback for aircraft without behavior component
			air_power = 2.0

		if air_power <= 0.0:
			continue

		# Calculate influence on this region
		var distance := pos.distance_to(region_center)
		if distance > influence_radius:
			continue

		# Influence decreases with distance
		var influence := air_power * (1.0 - (distance / influence_radius))

		if unit.team_id == "p1":
			region.p1_air_dominance += influence
		else:
			region.p2_air_dominance += influence

func _count_buildings(region: Region, team_id: String) -> float:
	var count := 0.0

	for node in get_tree().get_nodes_in_group("building"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get") or node.get("team_id") != team_id:
			# Try direct property access
			if "team_id" in node and node.team_id != team_id:
				continue
			elif not ("team_id" in node):
				continue

		var pos := Vector2(node.global_position.x, node.global_position.y)
		if node.global_position is Vector3:
			pos = Vector2(node.global_position.x, node.global_position.z)

		if region.contains_point(pos):
			count += 1.0

	# Also count HQ
	for node in get_tree().get_nodes_in_group("hq"):
		if node == null or not is_instance_valid(node):
			continue
		if "team_id" in node and node.team_id != team_id:
			continue

		var pos := Vector2(node.global_position.x, node.global_position.y)
		if node.global_position is Vector3:
			pos = Vector2(node.global_position.x, node.global_position.z)

		if region.contains_point(pos):
			count += 2.0  # HQ counts more

	return count

# =============================================================================
# CONTROL STATE UPDATES
# =============================================================================

func _update_all_control(delta: float) -> void:
	for region in regions.values():
		if region.is_base_region():
			continue  # Base regions don't change control
		_update_region_control(region, delta)

func _update_region_control(region: Region, delta: float) -> void:
	var p1_total := region.get_total_presence("p1")
	var p2_total := region.get_total_presence("p2")

	# Determine who should control based on presence
	var new_controller := ""
	if p1_total > p2_total * DOMINANCE_THRESHOLD and p1_total >= MIN_PRESENCE_THRESHOLD:
		new_controller = "p1"
	elif p2_total > p1_total * DOMINANCE_THRESHOLD and p2_total >= MIN_PRESENCE_THRESHOLD:
		new_controller = "p2"

	var old_state := region.state
	var old_controller := region.controller

	match region.state:
		Region.State.NEUTRAL:
			if new_controller != "":
				region.transition_timer += delta
				if region.transition_timer >= CAPTURE_TIME:
					region.set_controller(new_controller)
			else:
				region.transition_timer = 0.0

		Region.State.CONTROLLED_P1, Region.State.CONTROLLED_P2:
			var current := region.controller
			var enemy := "p2" if current == "p1" else "p1"
			var enemy_presence := p2_total if current == "p1" else p1_total

			if enemy_presence >= MIN_PRESENCE_THRESHOLD:
				# Enemy is contesting
				region.set_contested()

		Region.State.CONTESTED:
			if new_controller == region.previous_controller and new_controller != "":
				# Original controller pushing back
				region.transition_timer += delta
				if region.transition_timer >= CONTEST_DECAY_TIME:
					region.set_controller(new_controller)
			elif new_controller != "" and new_controller != region.previous_controller:
				# New controller taking over
				region.transition_timer += delta
				if region.transition_timer >= CAPTURE_TIME:
					region.set_controller(new_controller)
			elif p1_total < MIN_PRESENCE_THRESHOLD and p2_total < MIN_PRESENCE_THRESHOLD:
				# No one present, decay to neutral
				region.transition_timer += delta
				if region.transition_timer >= CONTEST_DECAY_TIME * 2:
					region.set_neutral()
			else:
				# Still contested, reset timer
				region.transition_timer = 0.0

	# Emit signals if state changed
	if region.state != old_state:
		emit_signal("region_state_changed", region.id, old_state, region.state)
	if region.controller != old_controller:
		emit_signal("region_controller_changed", region.id, old_controller, region.controller)

# =============================================================================
# INCOME CALCULATION
# =============================================================================

func get_income_for_team(team_id: String) -> float:
	var total_income := 0.0

	for region in regions.values():
		if region.is_controlled_by(team_id):
			total_income += region.get_income_for_controller()

	return total_income

func get_controlled_region_count(team_id: String) -> int:
	var count := 0
	for region in regions.values():
		if region.is_controlled_by(team_id):
			count += 1
	return count

func get_contested_region_count() -> int:
	var count := 0
	for region in regions.values():
		if region.is_contested():
			count += 1
	return count

# =============================================================================
# QUERIES
# =============================================================================

func get_region(region_id: String) -> Region:
	return regions.get(region_id) as Region

func get_region_at_grid(col: int, row: int) -> Region:
	if row < 0 or row >= GRID_ROWS or col < 0 or col >= GRID_COLS:
		return null
	return region_grid[row][col] as Region

func get_region_at_world_pos(world_pos: Vector2) -> Region:
	var col := int(world_pos.x / region_size.x)
	var row := int(world_pos.y / region_size.y)
	return get_region_at_grid(col, row)

func get_all_regions() -> Array:
	return regions.values()

func get_regions_by_type(type: Region.Type) -> Array:
	var result: Array = []
	for region in regions.values():
		if region.type == type:
			result.append(region)
	return result

func get_regions_by_state(state: Region.State) -> Array:
	var result: Array = []
	for region in regions.values():
		if region.state == state:
			result.append(region)
	return result

# =============================================================================
# DEBUG
# =============================================================================

func debug_print_grid() -> void:
	print("\n=== REGION GRID ===")
	var row_labels := ["A", "B", "C", "D", "E", "F", "G"]

	print("    1   2   3   4   5   6   7")
	for row in range(GRID_ROWS):
		var line := "%s " % row_labels[row]
		for col in range(GRID_COLS):
			var region := get_region_at_grid(col, row)
			var symbol := "."
			if region.is_base_region():
				symbol = "B" if region.controller == "p1" else "b"
			elif region.is_resource_region():
				if region.type == Region.Type.RESOURCE_OIL:
					symbol = "O"
				else:
					symbol = "M"

			match region.state:
				Region.State.CONTROLLED_P1:
					symbol = "[%s]" % symbol
				Region.State.CONTROLLED_P2:
					symbol = "<%s>" % symbol
				Region.State.CONTESTED:
					symbol = "!%s!" % symbol
				_:
					symbol = " %s " % symbol

			line += symbol + " "
		print(line)
	print("===================\n")
