extends Node
class_name VisualConfig

## Visual Configuration Constants
##
## Centralized location for all visual settings including heights, colors,
## scales, and rendering parameters.

# =============================================================================
# UNIT HEIGHTS
# =============================================================================

const UNIT_HEIGHT := 6.0
const VEHICLE_HEIGHT := 10.0
const AIRCRAFT_HEIGHT := 160.0
const AIRCRAFT_HEIGHT_SMOOTH := 4.0
const AIRCRAFT_BASE_HEIGHT := 220.0

# =============================================================================
# BUILDING HEIGHTS
# =============================================================================

const COLLECTOR_HEIGHT := 7.0
const TURRET_HEIGHT := 9.0
const BUILDING_HEIGHT := 18.0
const HQ_HEIGHT := 26.0

# =============================================================================
# UI OVERLAY SETTINGS
# =============================================================================

const HEALTH_BAR_HEIGHT := 6.0
const HEALTH_BAR_OFFSET := 8.0
const HEALTH_BAR_COLOR := Color(0.2, 0.85, 0.25, 0.9)
const HEALTH_BAR_BACK_COLOR := Color(0.12, 0.12, 0.12, 0.8)

# =============================================================================
# GHOST BUILDING PREVIEW
# =============================================================================

const GHOST_HEIGHT := 2.0
const GHOST_Y_OFFSET := 0.2
const GHOST_VALID_COLOR := Color(0.2, 0.9, 0.2, 0.35)
const GHOST_INVALID_COLOR := Color(0.95, 0.75, 0.2, 0.35)

# =============================================================================
# BUILD ZONE VISUALIZATION
# =============================================================================

const BUILD_ZONE_HEIGHT := 0.4
const BUILD_ZONE_Y_OFFSET := 0.05
const BUILD_ZONE_COLOR := Color(0.1, 0.6, 0.2, 0.2)
const BUILD_ZONE_OUTLINE_COLOR := Color(0.1, 0.8, 0.3, 0.6)

# =============================================================================
# AIRCRAFT VISUAL EFFECTS
# =============================================================================

## Aircraft model scaling
const AIRCRAFT_MODEL_SCALE := 1.0
const AIRCRAFT_MODEL_SCALE_F35 := 1.0

## Aircraft banking (rolling in turns)
const AIRCRAFT_BANK_MAX_DEG := 32.0
const AIRCRAFT_BANK_STRENGTH := 0.45
const AIRCRAFT_BANK_SMOOTH := 6.0

## Aircraft roll maneuvers
const AIRCRAFT_ROLL_INTERVAL_MIN := 10.0
const AIRCRAFT_ROLL_INTERVAL_MAX := 20.0
const AIRCRAFT_ROLL_DURATION := 1.6
const AIRCRAFT_ROLL_MIN_ALTITUDE := 0.4

## Afterburner smoke trail
const AIRCRAFT_AFTERBURNER_SMOKE_INTERVAL := 0.12
const AIRCRAFT_AFTERBURNER_SMOKE_SIZE := 1.1
const AIRCRAFT_AFTERBURNER_SMOKE_DURATION := 0.6
const AIRCRAFT_AFTERBURNER_SMOKE_SPREAD := 1.0
const AIRCRAFT_AFTERBURNER_SMOKE_OFFSET := 8.0
const AIRCRAFT_AFTERBURNER_SMOKE_COLOR := Color(0.9, 0.9, 0.95, 0.5)

## Missile smoke trail
const AIRCRAFT_MISSILE_SMOKE_COLOR := Color(0.2, 0.2, 0.2, 0.6)
const MISSILE_SMOKE_COLOR := Color(0.9, 0.9, 0.9, 0.35)

# =============================================================================
# BUILDING MODEL SCALES
# =============================================================================

const BARRACKS_MODEL_SCALE := 1.0
const FACTORY_MODEL_SCALE := 1.0
const AIRFIELD_MODEL_SCALE := 1.0
const SUPPLY_MODEL_SCALE := 1.0
const POWER_MODEL_SCALE := 1.0
const COMMAND_CENTER_MODEL_SCALE := 1.0
const DEFENSE_GUN_MODEL_SCALE := 1.0
const DEFENSE_MISSILE_MODEL_SCALE := 1.0
const DEFENSE_LASER_MODEL_SCALE := 1.0

# =============================================================================
# BUILDING COMPOUND LAYOUTS
# =============================================================================

## Barracks compound (multiple small buildings)
const BARRACKS_COMPOUND_ROWS := 3
const BARRACKS_COMPOUND_COLS := 4
const BARRACKS_COMPOUND_SPACING := 2.0

## Factory compound
const FACTORY_COMPOUND_ROWS := 2
const FACTORY_COMPOUND_COLS := 2
const FACTORY_COMPOUND_SPACING := 4.0

# =============================================================================
# HQ PENTAGON MODEL
# =============================================================================

const HQ_PENTAGON_MODEL_SCALE := 1.0
const HQ_PENTAGON_CENTER_MODEL_SCALE := 1.0
const HQ_PENTAGON_CENTER_SIZE_SCALE := 0.45
const HQ_PENTAGON_RADIUS_SCALE := 0.42
const HQ_PENTAGON_WING_DEPTH_SCALE := 0.22

# =============================================================================
# AIRFIELD VISUALS
# =============================================================================

const AIRFIELD_RUNWAY_COLOR := Color(0.12, 0.12, 0.14, 1.0)
const AIRFIELD_MARKING_COLOR := Color(0.9, 0.9, 0.9, 0.85)

# =============================================================================
# TERRAIN
# =============================================================================

const TERRAIN_HEIGHT_BIAS := 0.0

# =============================================================================
# FOG OF WAR
# =============================================================================

const FOG_COLOR := Color(0.05, 0.06, 0.08, 0.75)

# =============================================================================
# SELECTION AND UI
# =============================================================================

const SELECTION_RING_COLOR := Color(0.2, 0.9, 1.0, 0.75)
const BUILDING_PAD_COLOR := Color(0.08, 0.08, 0.08, 0.55)
const TURRET_RANGE_COLOR := Color(0.0, 0.0, 0.0, 0.65)

# =============================================================================
# DEFAULT FALLBACK COLORS
# =============================================================================

const DEFAULT_UNIT_COLOR := Color(0.7, 0.7, 0.7, 1.0)
const DEFAULT_BUILDING_COLOR := Color(0.7, 0.7, 0.7, 1.0)
const DEFAULT_MISSILE_COLOR := Color(0.9, 0.55, 0.2, 1.0)
