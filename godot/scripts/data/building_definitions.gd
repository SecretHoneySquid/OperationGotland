extends Node
class_name BuildingDefinitions

## Building Definitions
##
## Centralized location for all building type definitions.
## Extracted from game_controller.gd for better organization.

# =============================================================================
# BUILDING HP
# =============================================================================

const BUILDING_HP := {
	"barracks": 220.0,
	"factory": 260.0,
	"airfield": 260.0,
	"supply": 200.0,
	"power": 180.0,
	"command_center": 280.0,
	"defense_gun": 220.0,
	"defense_missile": 240.0,
	"defense_laser": 230.0,
	"defense": 240.0,
	"defense_patriot": 280.0,
}

static func get_building_hp(build_id: String) -> float:
	return BUILDING_HP.get(build_id, 200.0)

# =============================================================================
# BUILDING SIZES
# =============================================================================

const BUILDING_SIZE := {
	"barracks": Vector2(90, 90),
	"factory": Vector2(140, 110),
	"airfield": Vector2(432, 288),
	"supply": Vector2(100, 80),
	"power": Vector2(80, 80),
	"command_center": Vector2(130, 110),
	"defense": Vector2(70, 70),
	"defense_gun": Vector2(70, 70),
	"defense_missile": Vector2(70, 70),
	"defense_laser": Vector2(70, 70),
	"defense_patriot": Vector2(90, 90),
}

static func get_building_size(build_id: String) -> Vector2:
	return BUILDING_SIZE.get(build_id, Vector2(80, 80))

# =============================================================================
# BUILDING VISUAL BASE SIZES
# =============================================================================

const BUILDING_VISUAL_BASE_SIZE := {
	"barracks": Vector2(100, 90),
	"factory": Vector2(140, 110),
	"airfield": Vector2(432, 288),
	"supply": Vector2(100, 80),
	"power": Vector2(80, 80),
	"command_center": Vector2(130, 110),
}

static func get_building_visual_base_size(build_id: String) -> Vector2:
	return BUILDING_VISUAL_BASE_SIZE.get(build_id, Vector2.ZERO)

# =============================================================================
# BUILDING COLORS
# =============================================================================

const BUILDING_COLOR := {
	"factory": Color(0.6, 0.45, 0.2, 1.0),
	"airfield": Color(0.28, 0.38, 0.55, 1.0),
	"supply": Color(0.7, 0.6, 0.2, 1.0),
	"command_center": Color(0.35, 0.35, 0.5, 1.0),
	"defense_gun": Color(0.35, 0.5, 0.35, 1.0),
	"defense_laser": Color(0.2, 0.6, 0.65, 1.0),
	"defense": Color(0.7, 0.7, 0.7, 1.0),
	"defense_missile": Color(0.7, 0.7, 0.7, 1.0),
	"defense_patriot": Color(0.3, 0.45, 0.3, 1.0),
}

static func get_building_color(build_id: String, team_hq_color: Color) -> Color:
	# Barracks uses team HQ color
	if build_id == "barracks":
		return team_hq_color
	return BUILDING_COLOR.get(build_id, Color(0.2, 0.6, 0.35, 1.0))

static func get_defense_color(build_id: String) -> Color:
	match build_id:
		"defense_gun":
			return Color(0.35, 0.5, 0.35, 1.0)
		"defense_laser":
			return Color(0.2, 0.6, 0.65, 1.0)
		"defense_patriot":
			return Color(0.3, 0.45, 0.3, 1.0)
		_:
			return Color(0.7, 0.7, 0.7, 1.0)

# =============================================================================
# DEFENSE TURRET PROFILES
# =============================================================================

static func get_defense_profile(build_id: String) -> Dictionary:
	match build_id:
		"defense_gun":
			return {
				"range": 150.0,
				"damage": 6.0,
				"fire_rate": 0.25,
				"missile_speed": 320.0,
				"missile_turn_rate": 12.0,
				"missile_color": Color(1.0, 0.95, 0.7, 0.9),
				"warhead_size": "small",
				"hitscan": true,
				"shot_color": Color(1.0, 0.95, 0.7, 0.9),
				"shot_width": 2.2,
				"shot_lifetime": 0.1,
				"prefers_infantry": true,
				"prefers_vehicle": false,
				"damage_vs_infantry": 1.5,
				"damage_vs_vehicle": 0.6,
			}
		"defense_laser":
			return {
				"range": 190.0,
				"damage": 16.0,
				"fire_rate": 1.1,
				"missile_speed": 340.0,
				"missile_turn_rate": 14.0,
				"missile_color": Color(0.4, 0.9, 1.0, 1.0),
				"warhead_size": "small",
				"hitscan": false,
				"prefers_infantry": false,
				"prefers_vehicle": false,
				"damage_vs_infantry": 1.1,
				"damage_vs_vehicle": 1.0,
			}
		"defense_missile", "defense":
			return {
				"range": 260.0,
				"damage": 10.0,
				"fire_rate": 0.8,
				"missile_speed": 260.0,
				"missile_turn_rate": 9.0,
				"missile_color": Color(1.0, 0.6, 0.2, 1.0),
				"warhead_size": "medium",
				"hitscan": false,
				"prefers_infantry": false,
				"prefers_vehicle": true,
				"damage_vs_infantry": 0.7,
				"damage_vs_vehicle": 1.6,
			}
		"defense_patriot":
			return {
				"range": 900.0,  # Long range for missile interception (50% longer)
				"damage": 0.0,  # Doesn't attack units directly
				"fire_rate": 1.5,  # Time between interceptions
				"missile_speed": 800.0,  # Fast interceptor missiles
				"missile_turn_rate": 18.0,  # High maneuverability
				"missile_color": Color(0.9, 1.0, 0.9, 1.0),  # Light green/white
				"warhead_size": "small",
				"hitscan": false,
				"prefers_infantry": false,
				"prefers_vehicle": false,
				"damage_vs_infantry": 0.0,
				"damage_vs_vehicle": 0.0,
				"is_interceptor": true,  # Special flag for missile interception
				"intercept_success_base": 0.85,  # 85% base success rate
				"max_simultaneous_intercepts": 2,  # Can track 2 missiles at once
			}
	# Default fallback
	return {
		"range": 260.0,
		"damage": 10.0,
		"fire_rate": 0.8,
		"missile_speed": 260.0,
		"missile_turn_rate": 9.0,
		"missile_color": Color(1.0, 0.6, 0.2, 1.0),
		"warhead_size": "medium",
		"hitscan": false,
		"prefers_infantry": false,
		"prefers_vehicle": true,
		"damage_vs_infantry": 0.7,
		"damage_vs_vehicle": 1.6,
	}

# =============================================================================
# HQ CONFIGURATION
# =============================================================================

const HQ_SIZE := Vector2(140, 140)
const HQ_HP := 500.0
const HQ_VISUAL_BASE_SIZE := Vector2(140, 140)

static func get_hq_size() -> Vector2:
	return HQ_SIZE

static func get_hq_hp() -> float:
	return HQ_HP

static func get_hq_visual_base_size() -> Vector2:
	return HQ_VISUAL_BASE_SIZE
