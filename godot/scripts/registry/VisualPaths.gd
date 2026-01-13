extends Node
class_name VisualPaths

## Visual Paths Registry
##
## Centralized location for all visual scene and model paths.
## Extracted from game_controller.gd for better organization.
## Follows the pattern established by ModelPaths.gd.

# =============================================================================
# UNIT VISUAL SCENES
# =============================================================================

const UNIT_VISUALS := {
	"infantry": "res://scenes/units/infantry_visual.tscn",
	"vehicle": "res://scenes/units/vehicle_visual.tscn",
	"aircraft": "res://scenes/units/aircraft_visual.tscn",
	"collector": "res://scenes/units/collector_visual.tscn",
}

static func get_unit_visual_path(unit_kind: String, unit_type: String = "") -> String:
	match unit_kind:
		"infantry":
			return UNIT_VISUALS["infantry"]
		"vehicle":
			return UNIT_VISUALS["vehicle"]
		"aircraft":
			return get_aircraft_visual_path(unit_type)
		"collector":
			return UNIT_VISUALS["collector"]
	return ""

# =============================================================================
# AIRCRAFT MODELS
# =============================================================================

const AIRCRAFT_MODELS := {
	"gripen": "res://assets/models/gripen.glb",
	"f16": "res://assets/models/F16/F16-Plane.glb",
	"f22": "res://assets/models/F22/F22-Plane.glb",
	"f35": "res://scenes/units/aircraft_visual.tscn",  # Uses generic 2D visual
	"uav": "res://assets/models/Drones/mq-9_reaper_uav_drone.glb",
}

static func get_aircraft_visual_path(aircraft_type: String) -> String:
	return AIRCRAFT_MODELS.get(aircraft_type, "res://scenes/units/aircraft_visual.tscn")

# =============================================================================
# AIRCRAFT MISSILES
# =============================================================================

const MISSILE_MODELS := {
	"gripen": "res://assets/models/Gripen/Gripen-ATG.glb",
	"f16": "res://assets/models/F16/F16-ATG.glb",
	"f22": "res://assets/models/F22/F22-ATG.glb",
}

static func get_missile_visual_path(aircraft_type: String, _target_type: String = "ground") -> String:
	# target_type can be "ground" or "air" for future expansion
	return MISSILE_MODELS.get(aircraft_type, "")

# =============================================================================
# BUILDING VISUAL SCENES
# =============================================================================

const BUILDING_VISUALS := {
	"barracks": "res://scenes/buildings/barracks_visual.tscn",
	"factory": "res://scenes/buildings/factory_visual.tscn",
	"airfield": "res://scenes/buildings/airfield_visual.tscn",
	"supply": "res://scenes/buildings/supply_visual.tscn",
	"power": "res://scenes/buildings/power_visual.tscn",
	"command_center": "res://scenes/buildings/command_center_visual.tscn",
}

static func get_building_visual_path(build_id: String) -> String:
	return BUILDING_VISUALS.get(build_id, "")

# =============================================================================
# TURRET VISUALS
# =============================================================================

const TURRET_VISUAL := "res://scenes/buildings/turret_visual.tscn"

static func get_turret_visual_path(build_id: String) -> String:
	if build_id.begins_with("defense"):
		return TURRET_VISUAL
	return ""

# =============================================================================
# HQ VISUAL
# =============================================================================

const HQ_VISUAL := "res://scenes/buildings/hq_visual.tscn"

static func get_hq_visual_path() -> String:
	return HQ_VISUAL

# =============================================================================
# SPECIAL UNIT VISUALS
# =============================================================================

const HIMARS_VISUAL := "res://scenes/units/himars_visual_animated.tscn"

static func get_himars_visual_path() -> String:
	return HIMARS_VISUAL
