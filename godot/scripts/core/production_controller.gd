class_name ProductionController
extends Node

## Production Controller
##
## Handles production pools, queues, and rates.
## Extracted from game_controller.gd for better organization.

signal infantry_ready(team: TeamState)
signal vehicle_ready(team: TeamState, entry: Dictionary)
signal aircraft_ready(team: TeamState)

@export var max_infantry_pool := 5.0
@export var max_aircraft_pool := 2.0
@export var factory_queue_max := 6
@export var barracks_infantry_rate := 0.6
@export var factory_vehicle_rate := 0.25
@export var airfield_aircraft_rate := 0.2

var _teams: Dictionary  # team_id -> TeamState
var _income_timer := 0.0

func configure(teams: Dictionary) -> void:
	_teams = teams

func get_team(team_id: String) -> TeamState:
	return _teams.get(team_id)

# =============================================================================
# UPDATE LOOP
# =============================================================================

func update(delta: float) -> void:
	if GameState.winner != "":
		return
	_update_production_rates()
	for team_id in _teams:
		var team: TeamState = _teams[team_id]
		_update_infantry_pool(team, delta)
		_update_factory_queue(team, delta)
		_update_aircraft_pool(team, delta)
	_update_income_rate(delta)
	_sync_game_state()

func _update_production_rates() -> void:
	GameState.p1_infantry_prod = GameState.p1_barracks * barracks_infantry_rate
	GameState.p2_infantry_prod = GameState.p2_barracks * barracks_infantry_rate
	GameState.p1_vehicle_prod = GameState.p1_factory * factory_vehicle_rate
	GameState.p2_vehicle_prod = GameState.p2_factory * factory_vehicle_rate
	GameState.p1_aircraft_prod = GameState.p1_airfield * airfield_aircraft_rate
	GameState.p2_aircraft_prod = GameState.p2_airfield * airfield_aircraft_rate
	GameState.p1_total_prod = GameState.p1_infantry_prod + GameState.p1_vehicle_prod + GameState.p1_aircraft_prod
	GameState.p2_total_prod = GameState.p2_infantry_prod + GameState.p2_vehicle_prod + GameState.p2_aircraft_prod

func _update_income_rate(delta: float) -> void:
	_income_timer += delta
	if _income_timer < 1.0:
		return
	var sample_time := _income_timer
	var p1 := get_team("p1")
	var p2 := get_team("p2")
	if p1 != null:
		GameState.p1_income_rate = p1.income_accum / sample_time
		p1.income_accum = 0.0
	if p2 != null:
		GameState.p2_income_rate = p2.income_accum / sample_time
		p2.income_accum = 0.0
	_income_timer = 0.0

func _sync_game_state() -> void:
	for team_id in _teams:
		var team: TeamState = _teams[team_id]
		team.sync_to_game_state()

# =============================================================================
# INFANTRY PRODUCTION
# =============================================================================

func _update_infantry_pool(team: TeamState, _delta: float) -> void:
	# Infantry auto-spawn disabled - battalions now handle infantry spawning
	# Keep the pool at 0 and ETA at -1 (disabled)
	team.infantry_pool = 0.0
	if team.team_id == "p1":
		GameState.p1_infantry_eta = -1.0
	else:
		GameState.p2_infantry_eta = -1.0

	# Old auto-spawn logic (disabled):
	# var prod_rate := team.get_infantry_prod()
	# team.infantry_pool = minf(team.infantry_pool + prod_rate * delta, max_infantry_pool)
	#
	# while team.infantry_pool >= 1.0:
	#     if not team.is_hq_alive():
	#         team.infantry_pool = 0.0
	#         break
	#     if not team.has_credits(GameBalance.INFANTRY_UNIT_COST):
	#         break
	#     infantry_ready.emit(team)
	#     team.deduct_credits(GameBalance.INFANTRY_UNIT_COST)
	#     team.infantry_pool -= 1.0

# =============================================================================
# FACTORY QUEUE PRODUCTION
# =============================================================================

func _update_factory_queue(team: TeamState, delta: float) -> void:
	if team.factory_queue.is_empty():
		team.vehicle_progress = 0.0
		return

	var prod_rate := team.get_vehicle_prod()
	team.vehicle_progress += prod_rate * delta

	while team.vehicle_progress >= 1.0 and not team.factory_queue.is_empty():
		if not team.is_hq_alive():
			team.vehicle_progress = 0.0
			break
		var entry: Dictionary = team.factory_queue[0]
		vehicle_ready.emit(team, entry)
		team.factory_queue.remove_at(0)
		team.vehicle_progress -= 1.0

# =============================================================================
# AIRCRAFT PRODUCTION
# =============================================================================

func _update_aircraft_pool(team: TeamState, delta: float) -> void:
	var prod_rate := team.get_aircraft_prod()
	team.aircraft_pool = minf(team.aircraft_pool + prod_rate * delta, max_aircraft_pool)

	while team.aircraft_pool >= 1.0:
		if not team.is_hq_alive():
			team.aircraft_pool = 0.0
			break
		if not team.has_credits(GameBalance.AIRCRAFT_UNIT_COST):
			break
		# Signal that aircraft is ready to spawn
		aircraft_ready.emit(team)
		team.deduct_credits(GameBalance.AIRCRAFT_UNIT_COST)
		team.aircraft_pool -= 1.0

	# Update ETA
	if team.team_id == "p1":
		GameState.p1_aircraft_eta = _pool_eta(prod_rate, team.aircraft_pool)
	else:
		GameState.p2_aircraft_eta = _pool_eta(prod_rate, team.aircraft_pool)

# =============================================================================
# QUEUE MANAGEMENT
# =============================================================================

func queue_vehicle(team_id: String, vehicle_type: String = "mixed", factory: Building = null) -> bool:
	var team := get_team(team_id)
	if team == null:
		return false
	if not team.has_credits(GameBalance.VEHICLE_UNIT_COST):
		return false
	if team.get_factory_count() <= 0:
		return false
	if team.factory_queue.size() >= factory_queue_max:
		return false

	var chosen_factory: Building = null
	if factory != null and is_instance_valid(factory):
		if factory.build_id == "factory" and factory.team_id == team_id:
			chosen_factory = factory

	var type_id := vehicle_type
	if type_id == "" and chosen_factory != null:
		type_id = chosen_factory.vehicle_production_type

	team.deduct_credits(GameBalance.VEHICLE_UNIT_COST)
	team.factory_queue.append({
		"type": type_id,
		"factory": chosen_factory,
	})
	return true

func queue_himars(team_id: String, factory: Building = null) -> bool:
	var team := get_team(team_id)
	if team == null:
		return false
	if not team.has_credits(GameBalance.HIMARS_UNIT_COST):
		return false
	if team.get_factory_count() <= 0:
		return false
	if team.factory_queue.size() >= factory_queue_max:
		return false

	var chosen_factory: Building = null
	if factory != null and is_instance_valid(factory):
		if factory.build_id == "factory" and factory.team_id == team_id:
			chosen_factory = factory

	team.deduct_credits(GameBalance.HIMARS_UNIT_COST)
	team.factory_queue.append({
		"type": "himars",
		"factory": chosen_factory,
	})
	return true

func get_factory_queue(team_id: String) -> Array[Dictionary]:
	var team := get_team(team_id)
	if team == null:
		return []
	return team.factory_queue

func get_factory_queue_size(team_id: String) -> int:
	var team := get_team(team_id)
	if team == null:
		return 0
	return team.factory_queue.size()

# =============================================================================
# UTILITY
# =============================================================================

func _pool_eta(rate: float, pool: float) -> float:
	if rate <= 0.0:
		return -1.0
	if pool >= 1.0:
		return 0.0
	return maxf(0.0, (1.0 - pool) / rate)
