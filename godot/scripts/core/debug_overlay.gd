extends Label

@export var refresh_interval := 0.25

var _accum := 0.0

func _process(delta: float) -> void:
	_accum += delta
	if _accum < refresh_interval:
		return
	_accum = 0.0
	var fps := Engine.get_frames_per_second()
	text = "FPS: %d\nP1 Credits: %d  P2 Credits: %d\nP1 Income/s: %.1f  P2 Income/s: %.1f\nUnits: %d\nP1 Buildings: %d  P2 Buildings: %d\nP1 Inf Prod: %.2f  P2 Inf Prod: %.2f\nP1 Veh Prod: %.2f  P2 Veh Prod: %.2f\nP1 Total Prod: %.2f  P2 Total Prod: %.2f\nP1 Queue: %d  P2 Queue: %d\nP1 Collectors: %d  P2 Collectors: %d\nSupply Remaining: %.0f\nHQ P1: %d  HQ P2: %d" % [
		fps,
		GameState.p1_credits,
		GameState.p2_credits,
		GameState.p1_income_rate,
		GameState.p2_income_rate,
		GameState.unit_count,
		GameState.p1_building_count,
		GameState.p2_building_count,
		GameState.p1_infantry_prod,
		GameState.p2_infantry_prod,
		GameState.p1_vehicle_prod,
		GameState.p2_vehicle_prod,
		GameState.p1_total_prod,
		GameState.p2_total_prod,
		GameState.p1_factory_queue,
		GameState.p2_factory_queue,
		GameState.p1_collectors,
		GameState.p2_collectors,
		GameState.total_supply_remaining,
		GameState.p1_hq_hp,
		GameState.p2_hq_hp,
	]
	if GameState.winner != "":
		text += "\nWinner: %s" % GameState.winner
