extends Label

@export var refresh_interval := 0.25
@export var allow_hotkeys := true
@export var show_help := true
@export var visible_by_default := true
@export var credit_delta := 250
@export var spawn_batch := 3
@export var time_scales := PackedFloat32Array([0.5, 1.0, 2.0, 4.0])
@export var game_controller_path := NodePath("../../GameController")
@export var map_loader_path := NodePath("../../MapRoot")
@export var camera_path := NodePath("../../Camera2D")

var _accum := 0.0
var _time_scale_index := -1

func _ready() -> void:
	visible = visible_by_default
	set_process_unhandled_input(true)
	_sync_time_scale_index()

func _process(delta: float) -> void:
	_accum += delta
	if _accum < refresh_interval:
		return
	_accum = 0.0
	var fps := Engine.get_frames_per_second()
	var controller := _get_game_controller()
	var map_label := ""
	if controller != null:
		var map_path := str(controller.map_path)
		map_label = map_path.get_file() if map_path != "" else ""
	var fog_label := ""
	if controller != null:
		fog_label = "on" if controller.fog_enabled else "off"
	var camera_label := ""
	var camera := _get_camera()
	if camera != null:
		camera_label = "Camera: (%.0f, %.0f) zoom %.2f" % [camera.position.x, camera.position.y, camera.zoom.x]
	var p1_units := _count_group("units_p1")
	var p2_units := _count_group("units_p2")
	var lines := PackedStringArray()
	lines.append("FPS: %d  Time: %.2fx" % [fps, Engine.time_scale])
	if map_label != "":
		lines.append("Map: %s  Fog: %s" % [map_label, fog_label])
	elif fog_label != "":
		lines.append("Fog: %s" % fog_label)
	if camera_label != "":
		lines.append(camera_label)
	lines.append("Credits: P1 %d  P2 %d" % [GameState.p1_credits, GameState.p2_credits])
	lines.append("Income/s: P1 %.1f  P2 %.1f" % [GameState.p1_income_rate, GameState.p2_income_rate])
	lines.append("Units: %d  (P1 %d / P2 %d)" % [GameState.unit_count, p1_units, p2_units])
	lines.append("Buildings: P1 %d  P2 %d" % [GameState.p1_building_count, GameState.p2_building_count])
	lines.append("Prod Inf: %.2f/%.2f  Veh: %.2f/%.2f  Air: %.2f/%.2f" % [
		GameState.p1_infantry_prod,
		GameState.p2_infantry_prod,
		GameState.p1_vehicle_prod,
		GameState.p2_vehicle_prod,
		GameState.p1_aircraft_prod,
		GameState.p2_aircraft_prod,
	])
	lines.append("Total Prod: P1 %.2f  P2 %.2f" % [GameState.p1_total_prod, GameState.p2_total_prod])
	lines.append("Queue: P1 %d  P2 %d  Collectors: P1 %d  P2 %d" % [
		GameState.p1_factory_queue,
		GameState.p2_factory_queue,
		GameState.p1_collectors,
		GameState.p2_collectors,
	])
	lines.append("Supply Remaining: %.0f  HQ P1: %d  HQ P2: %d" % [
		GameState.total_supply_remaining,
		GameState.p1_hq_hp,
		GameState.p2_hq_hp,
	])
	if GameState.winner != "":
		lines.append("Winner: %s" % GameState.winner)
	if show_help:
		lines.append("")
		lines.append("Debug: F1 HUD  F2 Help  F3 Time  F4 Fog  M Map")
		lines.append("Spawn: 1/2/3 P1 inf/veh/air  Shift+1/2/3 P2  C credits  X clear units")
	text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if not allow_hotkeys:
		return
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if not key_event.pressed or key_event.echo:
		return
	var shift: bool = key_event.shift_pressed
	match key_event.keycode:
		KEY_F1:
			visible = not visible
		KEY_F2:
			show_help = not show_help
		KEY_F3, KEY_BRACKETRIGHT:
			_cycle_time_scale(1)
		KEY_BRACKETLEFT:
			_cycle_time_scale(-1)
		KEY_F4:
			_toggle_fog()
		KEY_M:
			_toggle_map_render()
		KEY_C:
			_adjust_credits(shift)
		KEY_X:
			_clear_units()
		KEY_1:
			_spawn_unit(shift, "infantry")
		KEY_2:
			_spawn_unit(shift, "vehicle")
		KEY_3:
			_spawn_unit(shift, "aircraft")

func _sync_time_scale_index() -> void:
	if time_scales.is_empty():
		_time_scale_index = -1
		return
	_time_scale_index = time_scales.find(Engine.time_scale)
	if _time_scale_index < 0:
		_time_scale_index = 0

func _cycle_time_scale(step: int) -> void:
	if time_scales.is_empty():
		return
	if _time_scale_index < 0:
		_time_scale_index = 0
	else:
		var size := time_scales.size()
		_time_scale_index = (_time_scale_index + step + size) % size
	Engine.time_scale = time_scales[_time_scale_index]

func _adjust_credits(use_p2: bool) -> void:
	var controller := _get_game_controller()
	if controller == null:
		return
	var team_id := "p2" if use_p2 else "p1"
	controller.debug_add_credits(team_id, credit_delta)

func _spawn_unit(use_p2: bool, kind: String) -> void:
	var controller := _get_game_controller()
	if controller == null:
		return
	var team_id := "p2" if use_p2 else "p1"
	controller.debug_spawn_unit(team_id, kind, spawn_batch)

func _clear_units() -> void:
	var controller := _get_game_controller()
	if controller == null:
		return
	controller.debug_clear_units()

func _toggle_fog() -> void:
	var controller := _get_game_controller()
	if controller == null:
		return
	controller.fog_enabled = not controller.fog_enabled
	controller.fog_hide_enemies = controller.fog_enabled

func _toggle_map_render() -> void:
	var map_loader := get_node_or_null(map_loader_path)
	if map_loader == null:
		return
	if map_loader.has_method("set_render_2d"):
		var current := bool(map_loader.get("render_2d"))
		map_loader.set_render_2d(not current)

func _get_game_controller() -> GameController:
	var node := get_node_or_null(game_controller_path)
	return node as GameController

func _get_camera() -> Camera2D:
	var node := get_node_or_null(camera_path)
	return node as Camera2D

func _count_group(group_name: String) -> int:
	return get_tree().get_nodes_in_group(group_name).size()
