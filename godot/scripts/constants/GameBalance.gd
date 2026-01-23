extends Node
class_name GameBalance

## Game Balance Constants
##
## Centralized location for all game balance values to avoid magic numbers
## and make balance tuning easier.

# =============================================================================
# UNIT STATS - Infantry
# =============================================================================

const INFANTRY_SPEED := 45.0
const INFANTRY_MAX_HP := 30.0
const INFANTRY_DAMAGE := 6.0
const INFANTRY_ATTACK_RANGE := 26.0
const INFANTRY_ATTACK_COOLDOWN := 0.6
const INFANTRY_BODY_RADIUS := 8.0
const INFANTRY_VISION_RADIUS := 220.0
const INFANTRY_AGGRO_RANGE := 220.0
const INFANTRY_STRUCTURE_AGGRO_RANGE := 260.0
const INFANTRY_CHASE_LEASH := 320.0
const INFANTRY_UNIT_COST := 25

## Long-range infantry spawning
const INFANTRY_LONG_MULTIPLIER := 10.0
const INFANTRY_MID_MULTIPLIER := 5.75  # 15% increase for rocket soldiers
const INFANTRY_LONG_RATIO := 0.2
const INFANTRY_MID_RATIO := 0.3
const INFANTRY_WAIT_DURATION := 10.0

# =============================================================================
# UNIT STATS - Vehicles
# =============================================================================

const VEHICLE_SPEED := 49.0
const VEHICLE_MAX_HP := 60.0
const VEHICLE_DAMAGE := 12.0
const VEHICLE_ATTACK_RANGE := 34.0
const VEHICLE_ATTACK_COOLDOWN := 0.9
const VEHICLE_BODY_RADIUS := 11.0
const VEHICLE_UNIT_COST := 60

## Vehicle spawning
const VEHICLE_LONG_MULTIPLIER := 10.0
const VEHICLE_MID_MULTIPLIER := 5.0
const VEHICLE_LONG_RATIO := 0.2
const VEHICLE_MID_RATIO := 0.3

# =============================================================================
# UNIT STATS - HIMARS
# =============================================================================

const HIMARS_SPEED := 55.0
const HIMARS_MAX_HP := 50.0
const HIMARS_BODY_RADIUS := 14.0
const HIMARS_UNIT_COST := 200
const HIMARS_VISION_RADIUS := 560.0  # Doubled vision like aircraft
const HIMARS_BOMBARDMENT_RANGE := 1600.0  # Doubled range for long-distance fire
const HIMARS_MISSILE_DAMAGE := 200.0  # Devastating strikes
const HIMARS_MISSILE_SPEED := 500.0
const HIMARS_MISSILE_LIFETIME := 12.0
const HIMARS_MISSILE_SPLASH_RADIUS := 180.0  # Massive blast radius
const HIMARS_MISSILES_PER_SALVO := 2  # Fire 2 missiles per salvo
const HIMARS_SALVO_INTERVAL := 1.0  # 1 second between missiles in salvo
const HIMARS_RELOAD_TIME := 10.0  # 10 seconds reload

# =============================================================================
# UNIT STATS - Aircraft
# =============================================================================

const AIRCRAFT_SPEED := 93.75
const AIRCRAFT_MAX_HP := 70.0
const AIRCRAFT_BODY_RADIUS := 12.0
const AIRCRAFT_VISION_RADIUS := 560.0  # Doubled fog sight
const AIRCRAFT_TURN_RATE := 2.2
const AIRCRAFT_UNIT_COST := 120

## Aircraft gun combat
const AIRCRAFT_GUN_DAMAGE := 4.5
const AIRCRAFT_GUN_ATTACK_RANGE := 700.0  # Medium range so planes don't need to fly to frontline
const AIRCRAFT_GUN_ATTACK_COOLDOWN := 0.12
const AIRCRAFT_GUN_CAPACITY := 0  # Disabled - planes use missiles only
const AIRCRAFT_SHOT_WIDTH := 2.6
const AIRCRAFT_SHOT_LIFETIME := 0.16

## Aircraft missiles
const AIRCRAFT_MISSILE_CAPACITY := 2
const AIRCRAFT_MISSILE_DAMAGE := 32.0
const AIRCRAFT_MISSILE_SPEED := 1170.0  # Increased by 50% from 780.0 (original 520.0 * 2.25)
const AIRCRAFT_MISSILE_TURN_RATE := 7.0
const AIRCRAFT_MISSILE_RANGE := 12000.0
const AIRCRAFT_MISSILE_COOLDOWN := 2.4
const AIRCRAFT_MISSILE_LOCK_TIME := 2.0
const AIRCRAFT_MISSILE_FOCUS_LIMIT := 1
const AIRCRAFT_MISSILE_HIT_RADIUS := 16.0
const AIRCRAFT_MISSILE_SPLASH_RADIUS := 80.0
const AIRCRAFT_MISSILE_SPLASH_SCALE := 0.85
const AIRCRAFT_MISSILE_LIFETIME := 24.0

## Aircraft reload and loitering
const AIRCRAFT_RELOAD_TIME := 7.0
const AIRCRAFT_RELOAD_RADIUS := 18.0
const AIRCRAFT_LOITER_RADIUS := 90.0
const AIRCRAFT_LOITER_ORBIT_SPEED := 0.3
const AIRCRAFT_ORBIT_RADIUS_SCALE := 10.0
const AIRCRAFT_ORBIT_WOBBLE_RATIO := 0.08
const AIRCRAFT_ORBIT_WOBBLE_SPEED := 3.0
const AIRCRAFT_PERIMETER_PADDING := 60.0
const AIRCRAFT_PERIMETER_FORWARD_BIAS := 0.2
const AIRCRAFT_LOITER_RELOAD_DELAY := 5.0
const AIRCRAFT_CIRCULATE_SPEED_MULT := 1.5
const AIRCRAFT_ENGAGE_SPEED_MULT := 2.0

## Aircraft circulation and spacing
const AIRCRAFT_CIRCULATION_SPACING := 16.0
const AIRCRAFT_CIRCULATION_AVOID_RADIUS := 28.0
const AIRCRAFT_CIRCULATION_AVOID_STRENGTH := 0.8

## Aircraft landing
const AIRCRAFT_LANDING_RADIUS := 2.0
const AIRCRAFT_LANDING_PATH_LENGTH := 720.0
const AIRCRAFT_LANDING_PATH_ENTRY_RADIUS := 18.0
const AIRCRAFT_RUNWAY_OFFSET_RATIO := 0.0
const AIRCRAFT_LANDING_SLOT_SPACING := 32.0
const AIRCRAFT_LANDING_CAP := 2
const AIRCRAFT_QUEUE_RADIUS := 0.0

## UAV (Reconnaissance Drone)
const UAV_SPEED := 80.0  # Slower than fighter jets
const UAV_MAX_HP := 25.0  # Fragile
const UAV_BODY_RADIUS := 10.0
const UAV_VISION_RADIUS := 800.0  # Very large vision for reconnaissance
const UAV_TURN_RATE := 1.8
const UAV_UNIT_COST := 80  # Cheaper than fighter jets
const UAV_LOITER_RADIUS := 80.0  # Circle radius (tighter circles)
const UAV_LOITER_ORBIT_SPEED := 0.3  # Slower orbit

## Aircraft squad formation
const AIRCRAFT_SQUAD_SPACING := 80.0
const AIRCRAFT_SQUAD_LATERAL_RATIO := 0.6

# =============================================================================
# PROJECTILES
# =============================================================================

const MISSILE_FUEL_TIME := 5.0

# =============================================================================
# PRODUCTION RATES
# =============================================================================

const BARRACKS_INFANTRY_RATE := 0.6
const FACTORY_VEHICLE_RATE := 0.25
const AIRFIELD_AIRCRAFT_RATE := 0.2
const FACTORY_QUEUE_MAX := 6

# =============================================================================
# PRODUCTION POOLS
# =============================================================================

const MAX_INFANTRY_POOL := 5.0
const MAX_AIRCRAFT_POOL := 2.0

# =============================================================================
# BUILDING CAPACITY
# =============================================================================

const AIRFIELD_AIRCRAFT_CAP := 3
const AIRFIELD_LANDING_CAP := 2
const F35_AIRFIELD_CAP := 1

# =============================================================================
# COMBAT
# =============================================================================

## Damage multipliers (for future armor system)
const DAMAGE_VS_INFANTRY := 1.0
const DAMAGE_VS_VEHICLE := 1.0
const DAMAGE_VS_STRUCTURE := 1.0

## Combat spread
const COMBAT_SPREAD_RADIUS := 24.0
const COMBAT_SPREAD_MIN_INTERVAL := 0.6
const COMBAT_SPREAD_MAX_INTERVAL := 1.2

## Range multiplier (for balance tweaking)
const RANGE_MULTIPLIER := 1.0

# =============================================================================
# SPAWNING
# =============================================================================

const UNIT_SPAWN_LIMIT := 50
const UNIT_SPAWN_SPREAD := 22.0
const RALLY_DISTANCE_THRESHOLD := 5.0

# =============================================================================
# NAVIGATION
# =============================================================================

const NAVIGATION_LAYERS := 1
const NAVIGATION_REPATH_INTERVAL := 0.6
const NAVIGATION_REPATH_DISTANCE := 120.0
const NAVIGATION_POINT_REACH_DIST := 14.0
const GROUND_SLOPE_MAX_DEG := 28.0
const GROUND_SLOPE_SAMPLE_DISTANCE := 0.0

# =============================================================================
# STARTING UNITS
# =============================================================================

const STARTING_P1_BARRACKS := 0
const STARTING_P2_BARRACKS := 1
const STARTING_P1_FACTORY := 0
const STARTING_P2_FACTORY := 1
const STARTING_P1_AIRFIELD := 0
const STARTING_P2_AIRFIELD := 0

# =============================================================================
# BATTALIONS
# =============================================================================

## Battalion costs (8-man squads)
const ASSAULT_BATTALION_COST := 150
const DEFENSE_BATTALION_COST := 120
const CONTROL_BATTALION_COST := 100
const AIR_DEFENSE_BATTALION_COST := 180

## Battalion size
const BATTALION_ACTIVE_SIZE := 8
const BATTALION_RESERVE_SIZE := 8

## Battalion formation
const BATTALION_FORMATION_SPACING := 50.0  # Base spacing between units (modern dispersed warfare)
const BATTALION_ASSAULT_DEPTH := 3  # Rows in assault formation
const BATTALION_DEFENSE_WIDTH := 1.8  # Width multiplier for defense
const BATTALION_CONTROL_SPREAD := 400.0  # Radius for control patrol area

## Reinforcement
const BATTALION_REINFORCE_DELAY := 3.0  # Seconds between reserve spawns

## Withdraw
const BATTALION_WITHDRAW_SAFE_DISTANCE := 300.0  # Distance from enemies to stop retreating

## AI behavior
const AI_BATTALION_CHECK_INTERVAL := 5.0  # How often AI considers buying battalions
