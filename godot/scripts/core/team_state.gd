class_name TeamState
extends RefCounted

## Team State
##
## Consolidates all team-specific state that was previously duplicated
## as _p1 and _p2 variable pairs in GameController.

var team_id: String = ""

# Production pools
var infantry_pool := 0.0
var aircraft_pool := 0.0
var vehicle_progress := 0.0

# Queues
var factory_queue: Array[Dictionary] = []

# Units
var collectors: Array[Collector] = []

# Economy
var income_accum := 0.0

# Positions
var start_pos := Vector2.ZERO
var rally_pos := Vector2.ZERO
var build_zone := Rect2()

# References
var hq: HQ = null
var selected_factory: Building = null

# Spawn indices for round-robin building selection
var barracks_spawn_index := 0
var airfield_spawn_index := 0
var supply_spawn_index := 0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(id: String = "") -> void:
	team_id = id

static func create(id: String) -> TeamState:
	var state := TeamState.new()
	state.team_id = id
	return state

# =============================================================================
# CREDITS MANAGEMENT
# =============================================================================

func get_credits() -> int:
	return GameState.p1_credits if team_id == "p1" else GameState.p2_credits

func has_credits(cost: int) -> bool:
	return get_credits() >= cost

func deduct_credits(cost: int) -> void:
	if team_id == "p1":
		GameState.p1_credits = maxi(0, GameState.p1_credits - cost)
	else:
		GameState.p2_credits = maxi(0, GameState.p2_credits - cost)

func add_credits(amount: int) -> void:
	if amount <= 0:
		return
	if team_id == "p1":
		GameState.p1_credits += amount
	else:
		GameState.p2_credits += amount

func add_income(amount: int) -> void:
	if amount <= 0:
		return
	add_credits(amount)
	income_accum += amount

# =============================================================================
# BUILDING COUNTS
# =============================================================================

func get_barracks_count() -> int:
	return GameState.p1_barracks if team_id == "p1" else GameState.p2_barracks

func get_factory_count() -> int:
	return GameState.p1_factory if team_id == "p1" else GameState.p2_factory

func get_airfield_count() -> int:
	return GameState.p1_airfield if team_id == "p1" else GameState.p2_airfield

func get_supply_count() -> int:
	return GameState.p1_supply if team_id == "p1" else GameState.p2_supply

# =============================================================================
# PRODUCTION RATES
# =============================================================================

func get_infantry_prod() -> float:
	return GameState.p1_infantry_prod if team_id == "p1" else GameState.p2_infantry_prod

func get_vehicle_prod() -> float:
	return GameState.p1_vehicle_prod if team_id == "p1" else GameState.p2_vehicle_prod

func get_aircraft_prod() -> float:
	return GameState.p1_aircraft_prod if team_id == "p1" else GameState.p2_aircraft_prod

# =============================================================================
# GAME STATE SYNC
# =============================================================================

func sync_to_game_state() -> void:
	if team_id == "p1":
		GameState.p1_infantry_pool = infantry_pool
		GameState.p1_aircraft_pool = aircraft_pool
		GameState.p1_factory_queue = factory_queue.size()
		GameState.p1_collectors = collectors.size()
	else:
		GameState.p2_infantry_pool = infantry_pool
		GameState.p2_aircraft_pool = aircraft_pool
		GameState.p2_factory_queue = factory_queue.size()
		GameState.p2_collectors = collectors.size()

# =============================================================================
# UTILITY
# =============================================================================

func is_hq_alive() -> bool:
	return hq != null and is_instance_valid(hq) and hq.hp > 0.0

func get_enemy_team_id() -> String:
	return "p2" if team_id == "p1" else "p1"

func get_unit_color() -> Color:
	if team_id == "p1":
		return Color(0.2, 0.5, 1.0, 1.0)
	return Color(1.0, 0.3, 0.3, 1.0)

func get_vehicle_color() -> Color:
	if team_id == "p1":
		return Color(0.25, 0.7, 1.0, 1.0)
	return Color(1.0, 0.45, 0.3, 1.0)

func get_aircraft_color() -> Color:
	if team_id == "p1":
		return Color(0.2, 0.65, 1.0, 1.0)
	return Color(1.0, 0.5, 0.3, 1.0)

func get_hq_color() -> Color:
	if team_id == "p1":
		return Color(0.2, 0.35, 0.7, 1.0)
	return Color(0.7, 0.2, 0.2, 1.0)

func get_collector_color() -> Color:
	if team_id == "p1":
		return Color(0.9, 0.85, 0.2, 1.0)
	return Color(0.9, 0.6, 0.2, 1.0)
