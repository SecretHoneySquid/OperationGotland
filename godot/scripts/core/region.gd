class_name Region
extends RefCounted

## Region
##
## Represents a single region/sector on the map grid.
## Regions can be controlled by teams based on air dominance and ground presence.

# =============================================================================
# ENUMS
# =============================================================================

enum State { NEUTRAL, CONTROLLED_P1, CONTROLLED_P2, CONTESTED }
enum Type { NORMAL, RESOURCE_MINE, RESOURCE_OIL, BASE }

# =============================================================================
# PROPERTIES
# =============================================================================

## Unique identifier (e.g., "A1", "D4")
var id: String = ""

## Grid position (column, row) - 0-indexed
var grid_pos: Vector2i = Vector2i.ZERO

## World coordinates rectangle
var world_rect: Rect2 = Rect2()

## Type of region (affects income and control requirements)
var type: Type = Type.NORMAL

## Current control state
var state: State = State.NEUTRAL

## Current controller ("", "p1", or "p2")
var controller: String = ""

## Previous controller (used for contested state transitions)
var previous_controller: String = ""

# =============================================================================
# CONTROL FACTORS
# =============================================================================

## Air dominance scores (from aircraft patrols)
var p1_air_dominance: float = 0.0
var p2_air_dominance: float = 0.0

## Ground presence scores (from units, buildings, fog of war)
var p1_ground_presence: float = 0.0
var p2_ground_presence: float = 0.0

# =============================================================================
# STATE TRANSITION
# =============================================================================

## Timer for state transitions (capture/decay)
var transition_timer: float = 0.0

# =============================================================================
# INCOME
# =============================================================================

## Base income rate when controlled (credits per second)
var base_income: float = 1.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(region_id: String = "", pos: Vector2i = Vector2i.ZERO, rect: Rect2 = Rect2()) -> void:
	id = region_id
	grid_pos = pos
	world_rect = rect

static func create(region_id: String, pos: Vector2i, rect: Rect2, region_type: Type = Type.NORMAL) -> Region:
	var region := Region.new(region_id, pos, rect)
	region.type = region_type
	region.base_income = _get_base_income_for_type(region_type)
	return region

static func _get_base_income_for_type(region_type: Type) -> float:
	match region_type:
		Type.NORMAL:
			return 1.0
		Type.RESOURCE_MINE:
			return 3.0
		Type.RESOURCE_OIL:
			return 5.0
		Type.BASE:
			return 0.0  # Base regions don't generate map income
	return 1.0

# =============================================================================
# QUERIES
# =============================================================================

func get_center() -> Vector2:
	return world_rect.get_center()

func contains_point(point: Vector2) -> bool:
	return world_rect.has_point(point)

func is_controlled() -> bool:
	return state == State.CONTROLLED_P1 or state == State.CONTROLLED_P2

func is_controlled_by(team_id: String) -> bool:
	if team_id == "p1":
		return state == State.CONTROLLED_P1
	elif team_id == "p2":
		return state == State.CONTROLLED_P2
	return false

func is_contested() -> bool:
	return state == State.CONTESTED

func is_neutral() -> bool:
	return state == State.NEUTRAL

func is_base_region() -> bool:
	return type == Type.BASE

func is_resource_region() -> bool:
	return type == Type.RESOURCE_MINE or type == Type.RESOURCE_OIL

func get_total_presence(team_id: String) -> float:
	if team_id == "p1":
		return p1_air_dominance + p1_ground_presence
	elif team_id == "p2":
		return p2_air_dominance + p2_ground_presence
	return 0.0

# =============================================================================
# CONTROL
# =============================================================================

func set_controller(team_id: String) -> void:
	previous_controller = controller
	controller = team_id
	transition_timer = 0.0

	if team_id == "p1":
		state = State.CONTROLLED_P1
	elif team_id == "p2":
		state = State.CONTROLLED_P2
	else:
		state = State.NEUTRAL

func set_contested() -> void:
	if state != State.CONTESTED:
		previous_controller = controller
		state = State.CONTESTED
		transition_timer = 0.0

func set_neutral() -> void:
	previous_controller = controller
	controller = ""
	state = State.NEUTRAL
	transition_timer = 0.0

func reset_presence() -> void:
	p1_air_dominance = 0.0
	p2_air_dominance = 0.0
	p1_ground_presence = 0.0
	p2_ground_presence = 0.0

# =============================================================================
# INCOME
# =============================================================================

func get_income_for_controller() -> float:
	if state == State.CONTESTED:
		return 0.0  # No income when contested
	if not is_controlled():
		return 0.0
	return base_income

func get_display_color() -> Color:
	match state:
		State.CONTROLLED_P1:
			return Color(0.2, 0.5, 1.0, 0.3)  # Blue
		State.CONTROLLED_P2:
			return Color(1.0, 0.3, 0.3, 0.3)  # Red
		State.CONTESTED:
			return Color(1.0, 1.0, 0.0, 0.3)  # Yellow
		State.NEUTRAL:
			return Color(0.5, 0.5, 0.5, 0.2)  # Grey
	return Color(0.5, 0.5, 0.5, 0.2)

func get_border_color() -> Color:
	match state:
		State.CONTROLLED_P1:
			return Color(0.3, 0.6, 1.0, 0.8)  # Blue
		State.CONTROLLED_P2:
			return Color(1.0, 0.4, 0.4, 0.8)  # Red
		State.CONTESTED:
			return Color(1.0, 1.0, 0.2, 0.8)  # Yellow
		State.NEUTRAL:
			return Color(0.6, 0.6, 0.6, 0.5)  # Grey
	return Color(0.6, 0.6, 0.6, 0.5)
