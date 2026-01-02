extends Node3D

@export var unit_height := 6.0
@export var vehicle_height := 10.0
@export var aircraft_height := 160.0
@export var aircraft_height_smooth := 4.0
@export var aircraft_model_path := "res://gripen.glb"
@export var aircraft_model_scale := 1.0
@export var aircraft_model_rotation := Vector3(0.0, 90.0, 0.0)
@export var aircraft_model_offset := Vector3.ZERO
@export var aircraft_model_path_f35 := "res://f-35_lightning_ii_-_fighter_jet_-_free.glb"
@export var aircraft_model_scale_f35 := 1.0
@export var aircraft_model_rotation_f35 := Vector3(0.0, 90.0, 0.0)
@export var aircraft_model_offset_f35 := Vector3.ZERO
@export var aircraft_bank_enabled := true
@export var aircraft_bank_max_deg := 32.0
@export var aircraft_bank_strength := 0.45
@export var aircraft_bank_smooth := 6.0
@export var aircraft_roll_enabled := true
@export var aircraft_roll_interval_min := 10.0
@export var aircraft_roll_interval_max := 20.0
@export var aircraft_roll_duration := 1.6
@export var aircraft_roll_min_altitude := 0.4
@export var aircraft_afterburner_smoke_enabled := true
@export var aircraft_afterburner_smoke_interval := 0.12
@export var aircraft_afterburner_smoke_color := Color(0.9, 0.9, 0.95, 0.5)
@export var aircraft_afterburner_smoke_size := 1.1
@export var aircraft_afterburner_smoke_duration := 0.6
@export var aircraft_afterburner_smoke_spread := 1.0
@export var aircraft_afterburner_smoke_offset := 8.0
@export var aircraft_afterburner_smoke_height_offset := -1.5
@export var collector_height := 7.0
@export var turret_height := 9.0
@export var building_height := 18.0
@export var hq_height := 26.0
@export var health_bar_height := 6.0
@export var health_bar_offset := 8.0
@export var health_bar_color := Color(0.2, 0.85, 0.25, 0.9)
@export var health_bar_back := Color(0.12, 0.12, 0.12, 0.8)
@export var barracks_model_path := "res://barracks.glb"
@export var barracks_model_scale := 1.0
@export var barracks_model_rotation := Vector3(0.0, -90.0, 0.0)
@export var barracks_compound_enabled := false
@export var barracks_compound_rows := 3
@export var barracks_compound_cols := 4
@export var barracks_compound_spacing := 2.0
@export var barracks_compound_models := PackedStringArray([
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/2Story_Sidehouse_Mat.fbx",
])
@export var factory_compound_enabled := false
@export var factory_compound_rows := 2
@export var factory_compound_cols := 2
@export var factory_compound_spacing := 4.0
@export var factory_compound_models := PackedStringArray([
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/2Story_Double_Mat.fbx",
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/2Story_Columns_Mat.fbx",
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/1Story_RoundRoof_Mat.fbx",
])
@export var factory_model_path := "res://factory.glb"
@export var factory_model_scale := 1.0
@export var airfield_model_path := "res://airfield.glb"
@export var airfield_model_scale := 1.0
@export var airfield_runway_color := Color(0.12, 0.12, 0.14, 1.0)
@export var airfield_marking_color := Color(0.9, 0.9, 0.9, 0.85)
@export var supply_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-r.glb"
@export var supply_model_scale := 1.0
@export var power_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-l.glb"
@export var power_model_scale := 1.0
@export var command_center_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-p.glb"
@export var command_center_model_scale := 1.0
@export var defense_gun_model_path := ""
@export var defense_gun_model_scale := 1.0
@export var defense_missile_model_path := ""
@export var defense_missile_model_scale := 1.0
@export var defense_laser_model_path := ""
@export var defense_laser_model_scale := 1.0
@export var hq_pentagon_enabled := true
@export var hq_pentagon_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-s.glb"
@export var hq_pentagon_model_scale := 1.0
@export var hq_pentagon_center_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-q.glb"
@export var hq_pentagon_center_model_scale := 1.0
@export var hq_pentagon_center_size_scale := 0.45
@export var hq_pentagon_radius_scale := 0.42
@export var hq_pentagon_wing_depth_scale := 0.22
@export var map_path := "res://data/maps/test_map.json"
@export var ground_path := NodePath("../Ground")
@export var terrain_follow_enabled := true
@export var terrain_height_bias := 0.0
@export var tracer_follow_terrain := true
@export var impact_follow_terrain := true
@export var logic_root_path := NodePath("../../Logic2D")
@export var hide_2d_world := true
@export var hide_nodes := PackedStringArray(["MapRoot", "GameController", "Fog"])
@export var disable_render_nodes := PackedStringArray(["BuildController", "SelectionController"])
@export var build_controller_path := NodePath("../../Logic2D/BuildController")
@export var show_build_ghost := true
@export var ghost_height := 2.0
@export var ghost_y_offset := 0.2
@export var ghost_valid_color := Color(0.2, 0.9, 0.2, 0.35)
@export var ghost_invalid_color := Color(0.95, 0.75, 0.2, 0.35)
@export var show_build_zone := true
@export var build_zone_team_id := "p1"
@export var build_zone_height := 0.4
@export var build_zone_y_offset := 0.05
@export var build_zone_color := Color(0.1, 0.6, 0.2, 0.2)
@export var show_fog_of_war := true
@export var fog_vision_group := "vision_p1"
@export var fog_y_offset := 0.25
@export var fog_height_follow_terrain := false
@export var fog_height_extra := 8.0
@export var fog_texture_size := Vector2i(256, 256)
@export var fog_update_interval := 0.2
@export var fog_softness := 0.25
@export var fog_color := Color(0.05, 0.06, 0.08, 0.75)
@export var tracer_height := 6.0
@export var tracer_width_scale := 0.4
@export var tracer_min_width := 0.5
@export var impact_enabled := true
@export var impact_height := 6.2
@export var impact_flash_size := 1.4
@export var impact_flash_duration := 0.16
@export var missile_height := 6.0
@export var missile_body_radius := 0.7
@export var missile_body_length := 4.6
@export var missile_nose_length := 1.6
@export var missile_fin_length := 1.2
@export var missile_fin_thickness := 0.25
@export var missile_small_scale := 1.0
@export var missile_medium_scale := 1.35
@export var missile_large_scale := 1.7
@export var missile_model_path := "res://scenes/props/missile_visual.tscn"
@export var missile_model_scale := 1.0
@export var missile_impact_flash_size := 3.2
@export var missile_impact_duration := 0.3
@export var aircraft_missile_impact_scale := 1.8
@export var aircraft_missile_impact_duration := 0.45
@export var aircraft_missile_shockwave_size := 2.6
@export var aircraft_missile_shockwave_duration := 0.4
@export var aircraft_missile_smoke_burst := 7
@export var aircraft_missile_smoke_color := Color(0.2, 0.2, 0.2, 0.6)
@export var aircraft_missile_smoke_size := 2.4
@export var aircraft_missile_smoke_duration := 0.9
@export var aircraft_missile_smoke_spread := 2.2
@export var missile_smoke_enabled := true
@export var missile_smoke_color := Color(0.9, 0.9, 0.9, 0.35)
@export var missile_smoke_size := 1.4
@export var missile_smoke_duration := 0.25
@export var missile_smoke_interval := 0.05
@export var missile_smoke_spread := 0.35
@export var missile_smoke_grow := 2.0
@export var missile_smoke_height_offset := 0.0
@export var missile_smoke_use_warhead_scale := true
@export var building_pad_enabled := true
@export var building_pad_margin := 0.08
@export var building_pad_height := 0.06
@export var building_pad_color := Color(0.08, 0.08, 0.08, 0.55)
@export var prop_detail_enabled := true
@export var prop_tank_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/detail-tank.glb"
@export var prop_chimney_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/chimney-medium.glb"
@export var prop_model_scale := 1.0
@export var show_unit_health := true
@export var unit_health_selected_only := false
@export var unit_health_height := 4.0
@export var unit_health_offset := 6.0
@export var unit_health_width_scale := 2.4
@export var selection_ring_color := Color(0.2, 0.9, 1.0, 0.75)
@export var selection_ring_height := 0.12
@export var selection_ring_thickness := 0.18
@export var selection_ring_vehicle_scale := 1.5
@export var selection_ring_infantry_scale := 1.1
@export var selection_ring_use_unit_color := true
@export var turret_range_enabled := true
@export var turret_range_color := Color(0.0, 0.0, 0.0, 0.65)
@export var turret_range_height := 0.12
@export var turret_range_thickness := 0.8
@export var turret_range_dash_count := 64
@export var turret_range_dash_ratio := 0.55
@export var show_build_zone_outline := true
@export var build_zone_outline_color := Color(0.1, 0.8, 0.3, 0.6)
@export var build_zone_outline_width := 4.0
@export var build_zone_outline_height := 0.6
@export var build_zone_outline_y_offset := 0.3

var _proxies: Dictionary[int, Node3D] = {}
var _live_ids: Dictionary[int, bool] = {}
var _shot_connected: Dictionary[int, bool] = {}
var _missile_connected: Dictionary[int, bool] = {}
var _missile_trails: Dictionary[int, Dictionary] = {}
var _aircraft_visual_state: Dictionary[int, Dictionary] = {}
var _hidden_2d := false
var _ghost_root: Node3D
var _ghost_mesh: MeshInstance3D
var _ghost_mat_valid: StandardMaterial3D
var _ghost_mat_invalid: StandardMaterial3D
var _tracers: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _smokes: Array[Dictionary] = []
var _map_loaded := false
var _map_size := Vector2.ZERO
var _build_zones: Dictionary = {}
var _build_zone_root: Node3D
var _build_zone_mesh: MeshInstance3D
var _build_zone_material: StandardMaterial3D
var _build_zone_outline_root: Node3D
var _build_zone_outline_edges: Array[MeshInstance3D] = []
var _fog_root: Node3D
var _fog_mesh: MeshInstance3D
var _fog_material: StandardMaterial3D
var _fog_image: Image
var _fog_texture: ImageTexture
var _fog_timer := 0.0
var _ground: Node
var _frame_delta := 0.0
var _smoke_rng := RandomNumberGenerator.new()
var _aircraft_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_smoke_rng.randomize()
	_aircraft_rng.randomize()

func _process(delta: float) -> void:
	_frame_delta = delta
	_hide_2d_world_nodes()
	_update_build_ghost()
	_update_build_zone()
	_update_fog_of_war(delta)
	_update_tracers(delta)
	_update_impacts(delta)
	_update_smokes(delta)
	_live_ids.clear()
	_disable_map_render()
	_sync_group("units")
	_sync_group("collectors")
	_sync_group("missiles")
	_sync_group("defense_turret")
	_sync_group("building")
	_sync_group("hq")
	_cleanup()

func _sync_group(group_name: String) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node == null or not is_instance_valid(node):
			continue
		var id := int(node.get_instance_id())
		_live_ids[id] = true
		_disable_2d_render(node)
		if group_name in ["units", "defense_turret"]:
			_ensure_shot_connection(node, id)
		elif group_name == "missiles":
			_ensure_missile_connection(node, id)
		var proxy: Node3D = _proxies.get(id) as Node3D
		if proxy == null:
			proxy = _create_proxy(node, group_name)
			_proxies[id] = proxy
		_update_proxy(node, proxy, group_name)

func _cleanup() -> void:
	var dead: Array[int] = []
	for id in _proxies.keys():
		if _live_ids.has(id):
			continue
		var proxy: Node3D = _proxies[id] as Node3D
		if proxy != null and is_instance_valid(proxy):
			proxy.queue_free()
		dead.append(id)
	for id in dead:
		_proxies.erase(id)
		if _shot_connected.has(id):
			_shot_connected.erase(id)
		if _missile_connected.has(id):
			_missile_connected.erase(id)
		if _missile_trails.has(id):
			_missile_trails.erase(id)
		if _aircraft_visual_state.has(id):
			_aircraft_visual_state.erase(id)

func _hide_2d_world_nodes() -> void:
	if not hide_2d_world or _hidden_2d:
		return
	var logic := get_node_or_null(logic_root_path)
	if logic == null:
		return
	for node_name in hide_nodes:
		var node := logic.get_node_or_null(node_name)
		if node == null:
			continue
		if node.has_method("set_render_2d"):
			node.set_render_2d(false)
		if node is CanvasItem:
			node.visible = false
	for node_name in disable_render_nodes:
		var node := logic.get_node_or_null(node_name)
		if node == null:
			continue
		if node.has_method("set_render_2d"):
			node.set_render_2d(false)
	_hidden_2d = true

func _create_proxy(node, group_name: String) -> Node3D:
	var proxy := Node3D.new()
	add_child(proxy)
	match group_name:
		"units":
			_build_unit_proxy(proxy, node)
		"collectors":
			_build_collector_proxy(proxy, node)
		"missiles":
			_build_missile_proxy(proxy, node)
		"defense_turret":
			_build_turret_proxy(proxy, node)
		"building":
			_build_building_proxy(proxy, node)
		"hq":
			_build_hq_proxy(proxy, node)
	return proxy

func _build_unit_proxy(proxy: Node3D, unit) -> void:
	var radius := maxf(3.0, _get_float(unit, "body_radius", 6.0))
	var unit_kind := str(_get_value(unit, "unit_kind", "infantry"))
	var base_color := _get_color(unit, "color", Color(0.7, 0.7, 0.7, 1.0))
	if unit_kind == "vehicle":
		var hull_height := vehicle_height * 0.45
		var hull_size := Vector3(radius * 2.1, hull_height, radius * 2.6)
		var hull := _make_box(hull_size, base_color.darkened(0.12))
		hull.position = Vector3(0, hull_height * 0.5, 0)
		proxy.add_child(hull)
		var cabin := _make_box(Vector3(radius * 1.3, hull_height * 0.6, radius * 1.2), base_color.lightened(0.12))
		cabin.position = Vector3(0, hull_height * 0.9, -radius * 0.2)
		proxy.add_child(cabin)
		var turret_section := vehicle_height * 0.25
		var turret := _make_cylinder(radius * 0.55, turret_section, base_color.lightened(0.2))
		turret.position = Vector3(0, hull_height + turret_section * 0.5, 0)
		proxy.add_child(turret)
		var barrel := _make_cylinder(radius * 0.12, radius * 1.4, base_color.lightened(0.35))
		barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		barrel.position = Vector3(0, hull_height + turret_section * 0.6, -radius * 1.1)
		proxy.add_child(barrel)
		var track_size := Vector3(radius * 0.55, hull_height * 0.7, radius * 2.8)
		var track_color := base_color.darkened(0.35)
		var track_left := _make_box(track_size, track_color)
		track_left.position = Vector3(-radius * 0.95, track_size.y * 0.5, 0)
		proxy.add_child(track_left)
		var track_right := _make_box(track_size, track_color)
		track_right.position = Vector3(radius * 0.95, track_size.y * 0.5, 0)
		proxy.add_child(track_right)
		if show_unit_health:
			var bar_width := maxf(12.0, radius * unit_health_width_scale)
			var bar_height := hull_height + turret_section + (radius * 0.6)
			_attach_health_bar(proxy, bar_width, bar_height, unit_health_height, unit_health_offset)
		_attach_selection_ring(proxy, radius * selection_ring_vehicle_scale, base_color)
	elif unit_kind == "aircraft":
		var airframe := Node3D.new()
		airframe.name = "Airframe"
		proxy.add_child(airframe)
		proxy.set_meta("airframe", airframe)
		var type_id := str(_get_value(unit, "unit_type", ""))
		var model_path := aircraft_model_path
		var model_scale := aircraft_model_scale
		var model_rotation := aircraft_model_rotation
		var model_offset := aircraft_model_offset
		if type_id == "f35" and aircraft_model_path_f35 != "":
			model_path = aircraft_model_path_f35
			model_scale = aircraft_model_scale_f35
			model_rotation = aircraft_model_rotation_f35
			model_offset = aircraft_model_offset_f35
		var body_length := radius * 3.4
		var body_height := maxf(1.4, radius * 0.7)
		var body_width := radius * 0.6
		var wing_span := radius * 3.6
		var wing_depth := radius * 1.5
		var model_height := 0.0
		if model_path != "" and ResourceLoader.exists(model_path):
			var target_size := Vector2(wing_span, body_length)
			model_height = _add_scene_model(
				airframe,
				model_path,
				target_size,
				0.0,
				model_scale,
				model_offset,
				model_rotation
			)
		if model_height <= 0.0:
			var fuselage := _make_box(Vector3(body_width, body_height, body_length), base_color)
			fuselage.position = Vector3(0, body_height * 0.5, 0)
			airframe.add_child(fuselage)
			var nose := _make_cone(body_width * 0.55, body_height * 1.3, base_color.lightened(0.2))
			nose.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			nose.position = Vector3(0, body_height * 0.5, -body_length * 0.5 - body_height * 0.65)
			airframe.add_child(nose)
			var wing := _make_box(Vector3(wing_span, body_height * 0.15, wing_depth), base_color.lightened(0.1))
			wing.position = Vector3(0, body_height * 0.35, -body_length * 0.05)
			airframe.add_child(wing)
			var tail_span := wing_span * 0.35
			var tail_depth := wing_depth * 0.55
			var tail := _make_box(Vector3(tail_span, body_height * 0.12, tail_depth), base_color.lightened(0.15))
			tail.position = Vector3(0, body_height * 0.55, body_length * 0.35)
			airframe.add_child(tail)
			var fin := _make_box(Vector3(body_width * 0.35, body_height * 0.9, body_width * 0.6), base_color.darkened(0.05))
			fin.position = Vector3(0, body_height * 0.5 + body_height * 0.45, body_length * 0.32)
			airframe.add_child(fin)
			var engine := _make_cylinder(body_width * 0.3, body_height * 0.6, base_color.darkened(0.2))
			engine.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			engine.position = Vector3(0, body_height * 0.45, body_length * 0.45)
			airframe.add_child(engine)
		if show_unit_health:
			var bar_width := maxf(14.0, radius * unit_health_width_scale * 1.1)
			var bar_height := model_height if model_height > 0.0 else body_height + body_height * 1.2
			_attach_health_bar(proxy, bar_width, bar_height, unit_health_height, unit_health_offset)
		_attach_selection_ring(proxy, radius * selection_ring_vehicle_scale * 1.2, base_color)
	else:
		var body_radius := radius * 0.35
		var body_height := maxf(2.0, unit_height * 0.6)
		var body := _make_capsule(body_radius, body_height, base_color.darkened(0.1))
		var total_height := body_height + (body_radius * 2.0)
		body.position = Vector3(0, total_height * 0.5, 0)
		proxy.add_child(body)
		var head_radius := body_radius * 0.7
		var head := _make_sphere(head_radius, base_color.lightened(0.25))
		head.position = Vector3(0, total_height + head_radius * 0.6, 0)
		proxy.add_child(head)
		var pack_size := Vector3(body_radius * 1.2, body_radius * 1.4, body_radius * 0.6)
		var pack := _make_box(pack_size, base_color.darkened(0.35))
		pack.position = Vector3(0, total_height * 0.6, body_radius * 0.7)
		proxy.add_child(pack)
		var unit_type := str(_get_value(unit, "unit_type", "rifle"))
		var weapon_len := radius * 1.1
		var weapon_thick := body_radius * 0.35
		if unit_type == "sniper":
			weapon_len = radius * 1.8
			weapon_thick = body_radius * 0.3
		elif unit_type == "rocket":
			weapon_len = radius * 1.4
			weapon_thick = body_radius * 0.55
		var weapon := _make_box(Vector3(weapon_thick, weapon_thick, weapon_len), base_color.lightened(0.3))
		weapon.position = Vector3(0, total_height * 0.6, -weapon_len * 0.5 - body_radius * 0.2)
		proxy.add_child(weapon)
		if show_unit_health:
			var bar_width := maxf(10.0, radius * unit_health_width_scale)
			var bar_height := total_height + head_radius * 0.8
			_attach_health_bar(proxy, bar_width, bar_height, unit_health_height, unit_health_offset)
		_attach_selection_ring(proxy, radius * selection_ring_infantry_scale, base_color)

func _build_collector_proxy(proxy: Node3D, collector) -> void:
	var radius := maxf(3.0, _get_float(collector, "body_radius", 6.0))
	var height := collector_height
	var base_color := _get_color(collector, "color", Color(0.7, 0.7, 0.7, 1.0))
	var base_height := height * 0.45
	var base := _make_box(Vector3(radius * 2.0, base_height, radius * 2.4), base_color.darkened(0.08))
	base.position = Vector3(0, base_height * 0.5, 0)
	proxy.add_child(base)
	var cab := _make_box(Vector3(radius * 1.0, base_height * 0.7, radius * 1.0), base_color.lightened(0.1))
	cab.position = Vector3(0, base_height * 0.9, -radius * 0.4)
	proxy.add_child(cab)
	var tank := _make_cylinder(radius * 0.5, height * 0.5, base_color.lightened(0.2))
	tank.position = Vector3(0, base_height + height * 0.25, radius * 0.4)
	proxy.add_child(tank)

func _build_missile_proxy(proxy: Node3D, missile) -> void:
	var base_color := _get_color(missile, "color", Color(0.9, 0.55, 0.2, 1.0))
	var scale := _get_missile_scale(missile)
	if _add_missile_model(proxy, base_color, scale):
		return
	var body_radius := missile_body_radius * scale
	var body_length := missile_body_length * scale
	var nose_length := missile_nose_length * scale
	var fin_length := missile_fin_length * scale
	var fin_thickness := missile_fin_thickness * scale
	var body := _make_cylinder(body_radius, body_length, base_color)
	body.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	proxy.add_child(body)
	var nose := _make_cone(body_radius, nose_length, base_color.lightened(0.2))
	nose.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	nose.position = Vector3(0.0, 0.0, -body_length * 0.5 - nose_length * 0.5)
	proxy.add_child(nose)
	var tail_offset := body_length * 0.5 - fin_length * 0.45
	var fin_color := base_color.darkened(0.2)
	var fin_a := _make_box(Vector3(body_radius * 2.4, fin_thickness, fin_length), fin_color)
	fin_a.position = Vector3(0.0, 0.0, tail_offset)
	proxy.add_child(fin_a)
	var fin_b := _make_box(Vector3(fin_thickness, body_radius * 2.4, fin_length), fin_color)
	fin_b.position = Vector3(0.0, 0.0, tail_offset)
	proxy.add_child(fin_b)
	var exhaust := _make_sphere(body_radius * 0.35, base_color.lightened(0.4))
	exhaust.position = Vector3(0.0, 0.0, body_length * 0.5 + body_radius * 0.2)
	proxy.add_child(exhaust)

func _build_turret_proxy(proxy: Node3D, turret) -> void:
	var base_radius := maxf(4.0, _get_float(turret, "base_radius", 8.0))
	var height := turret_height
	var base_color := _get_color(turret, "base_color", Color(0.7, 0.7, 0.7, 1.0))
	var base := _make_cylinder(base_radius, height * 0.45, base_color.darkened(0.08))
	base.position = Vector3(0, height * 0.225, 0)
	proxy.add_child(base)
	var head := _make_cylinder(base_radius * 0.55, height * 0.25, base_color.lightened(0.2))
	head.position = Vector3(0, height * 0.55, 0)
	proxy.add_child(head)
	var barrel := _make_cylinder(base_radius * 0.12, base_radius * 1.4, base_color.lightened(0.35))
	barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	barrel.position = Vector3(0, height * 0.55, -base_radius * 1.0)
	proxy.add_child(barrel)

func _build_building_proxy(proxy: Node3D, building) -> void:
	var size2d := _get_vec2(building, "size", Vector2(80, 80))
	var height := building_height
	var size := Vector3(size2d.x, height, size2d.y)
	var base_color := _get_color(building, "fill_color", Color(0.7, 0.7, 0.7, 1.0))
	var build_id := str(_get_value(building, "build_id", ""))
	_add_building_pad(proxy, size2d, base_color)
	if build_id == "barracks":
		var model_height := 0.0
		if barracks_compound_enabled and not barracks_compound_models.is_empty():
			model_height = _add_barracks_compound(proxy, size2d, height)
		elif barracks_model_path != "" and ResourceLoader.exists(barracks_model_path):
			model_height = _add_scene_model(
				proxy,
				barracks_model_path,
				size2d,
				0.0,
				barracks_model_scale,
				Vector3.ZERO,
				barracks_model_rotation
			)
		if model_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, model_height), base_color)
			_attach_health_bar(proxy, size2d.x, model_height, health_bar_height, health_bar_offset)
			return
	elif build_id == "factory":
		var factory_height := 0.0
		if factory_compound_enabled and not factory_compound_models.is_empty():
			factory_height = _add_factory_compound(proxy, size2d, height)
		elif factory_model_path != "" and ResourceLoader.exists(factory_model_path):
			factory_height = _add_scene_model(proxy, factory_model_path, size2d, 0.0, factory_model_scale)
		if factory_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, factory_height), base_color)
			_attach_health_bar(proxy, size2d.x, factory_height, health_bar_height, health_bar_offset)
			return
	elif build_id == "airfield":
		var airfield_height := 0.0
		if airfield_model_path != "" and ResourceLoader.exists(airfield_model_path):
			airfield_height = _add_scene_model(proxy, airfield_model_path, size2d, 0.0, airfield_model_scale)
		if airfield_height <= 0.0:
			airfield_height = _build_airfield_base(proxy, size2d, height, base_color)
		_add_building_props(proxy, build_id, size2d, maxf(height, airfield_height), base_color)
		_attach_health_bar(proxy, size2d.x, airfield_height, health_bar_height, health_bar_offset)
		return
	elif build_id == "supply":
		var supply_height := 0.0
		if supply_model_path != "" and ResourceLoader.exists(supply_model_path):
			supply_height = _add_scene_model(proxy, supply_model_path, size2d, 0.0, supply_model_scale)
		if supply_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, supply_height), base_color)
			_attach_health_bar(proxy, size2d.x, supply_height, health_bar_height, health_bar_offset)
			return
		var fallback_height := height * 0.8
		var main_height := fallback_height * 0.45
		var main := _make_box(Vector3(size2d.x * 0.78, main_height, size2d.y * 0.62), base_color)
		main.position = Vector3(0, main_height * 0.5, 0)
		proxy.add_child(main)
		var annex_height := fallback_height * 0.28
		var annex := _make_box(Vector3(size2d.x * 0.28, annex_height, size2d.y * 0.22), base_color.lightened(0.08))
		annex.position = Vector3(size2d.x * 0.28, annex_height * 0.5, -size2d.y * 0.12)
		proxy.add_child(annex)
		var roof_height := fallback_height * 0.08
		var roof := _make_box(Vector3(size2d.x * 0.84, roof_height, size2d.y * 0.68), base_color.lightened(0.18))
		roof.position = Vector3(0, main_height + roof_height * 0.5, 0)
		proxy.add_child(roof)
		var tank_height := fallback_height * 0.5
		for i in range(3):
			var x := (float(i) - 1.0) * (size2d.x * 0.18)
			var tank := _make_cylinder(size2d.x * 0.06, tank_height, base_color.lightened(0.25))
			tank.position = Vector3(x, tank_height * 0.5, size2d.y * 0.28)
			proxy.add_child(tank)
		var max_height := maxf(main_height + roof_height, tank_height)
		if annex_height > max_height:
			max_height = annex_height
		_add_building_props(proxy, build_id, size2d, maxf(height, max_height), base_color)
		_attach_health_bar(proxy, size2d.x, max_height, health_bar_height, health_bar_offset)
		return
	elif build_id == "power":
		var power_height := 0.0
		if power_model_path != "" and ResourceLoader.exists(power_model_path):
			power_height = _add_scene_model(proxy, power_model_path, size2d, 0.0, power_model_scale)
		if power_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, power_height), base_color)
			_attach_health_bar(proxy, size2d.x, power_height, health_bar_height, health_bar_offset)
			return
	elif build_id == "command_center":
		var command_height := 0.0
		if command_center_model_path != "" and ResourceLoader.exists(command_center_model_path):
			command_height = _add_scene_model(proxy, command_center_model_path, size2d, 0.0, command_center_model_scale)
		if command_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, command_height), base_color)
			_attach_health_bar(proxy, size2d.x, command_height, health_bar_height, health_bar_offset)
			return
	elif build_id.begins_with("defense"):
		var defense_path := ""
		var defense_scale := 1.0
		match build_id:
			"defense_gun":
				defense_path = defense_gun_model_path
				defense_scale = defense_gun_model_scale
			"defense_missile":
				defense_path = defense_missile_model_path
				defense_scale = defense_missile_model_scale
			"defense_laser":
				defense_path = defense_laser_model_path
				defense_scale = defense_laser_model_scale
		var defense_height := 0.0
		if defense_path != "" and ResourceLoader.exists(defense_path):
			defense_height = _add_scene_model(proxy, defense_path, size2d, 0.0, defense_scale)
		if defense_height <= 0.0:
			defense_height = _build_defense_base(proxy, build_id, size2d, height, base_color)
		_add_building_props(proxy, build_id, size2d, maxf(height, defense_height), base_color)
		_attach_health_bar(proxy, size2d.x, defense_height, health_bar_height, health_bar_offset)
		return
	var body := _make_box(size, base_color)
	body.position = Vector3(0, height * 0.5, 0)
	proxy.add_child(body)
	_add_building_details(proxy, build_id, size2d, height, base_color)
	_add_building_props(proxy, build_id, size2d, height, base_color)
	_attach_health_bar(proxy, size2d.x, height, health_bar_height, health_bar_offset)

func _build_hq_proxy(proxy: Node3D, hq) -> void:
	var size2d := _get_vec2(hq, "size", Vector2(140, 140))
	var height := hq_height
	var base_color := _get_color(hq, "fill_color", Color(0.7, 0.7, 0.7, 1.0))
	_add_building_pad(proxy, size2d, base_color)
	if hq_pentagon_enabled and hq_pentagon_model_path != "" and ResourceLoader.exists(hq_pentagon_model_path):
		var model_height := _add_hq_pentagon(proxy, size2d, height)
		if model_height > 0.0:
			_add_hq_props(proxy, size2d, maxf(height, model_height), base_color)
			_attach_health_bar(proxy, size2d.x, model_height, health_bar_height, health_bar_offset)
			return
	var radius := minf(size2d.x, size2d.y) * 0.45
	var base_height := height * 0.45
	var base := _make_pentagon_prism(radius, base_height, base_color)
	base.position = Vector3(0, base_height * 0.5, 0)
	proxy.add_child(base)
	var mid_height := height * 0.22
	var mid := _make_pentagon_prism(radius * 0.62, mid_height, base_color.lightened(0.12))
	mid.position = Vector3(0, base_height + mid_height * 0.5, 0)
	proxy.add_child(mid)
	var top_height := height * 0.12
	var top := _make_pentagon_prism(radius * 0.35, top_height, base_color.lightened(0.22))
	top.position = Vector3(0, base_height + mid_height + top_height * 0.5, 0)
	proxy.add_child(top)
	var mast_height := height * 0.18
	var mast := _make_cylinder(radius * 0.08, mast_height, base_color.lightened(0.35))
	mast.position = Vector3(0, base_height + mid_height + top_height + mast_height * 0.5, 0)
	proxy.add_child(mast)
	var max_height := base_height + mid_height + top_height + mast_height
	_add_hq_props(proxy, size2d, maxf(height, max_height), base_color)
	_attach_health_bar(proxy, size2d.x, max_height, health_bar_height, health_bar_offset)

func _update_proxy(node, proxy: Node3D, group_name: String) -> void:
	proxy.visible = node.visible
	var id := int(node.get_instance_id())
	if node is Node2D:
		var pos2: Vector2 = node.global_position
		var ground_y: float = _get_ground_height(pos2)
		var y_offset: float = terrain_height_bias
		var unit_kind := ""
		if group_name == "units":
			unit_kind = str(_get_value(node, "unit_kind", "infantry"))
			if unit_kind == "aircraft":
				var altitude: float = clampf(_get_float(node, "aircraft_altitude_factor", 1.0), 0.0, 1.0)
				y_offset += aircraft_height * altitude
		if group_name == "missiles":
			y_offset += missile_height * _get_missile_scale(node)
			var source_kind := str(_get_value(node, "source_kind", ""))
			if source_kind == "aircraft":
				var altitude := clampf(_get_float(node, "source_altitude", 1.0), 0.0, 1.0)
				y_offset += aircraft_height * altitude
		var target_y: float = ground_y + y_offset
		if group_name == "units" and unit_kind == "aircraft" and aircraft_height_smooth > 0.0:
			var altitude: float = clampf(_get_float(node, "aircraft_altitude_factor", 1.0), 0.0, 1.0)
			var state: Dictionary = _aircraft_visual_state.get(id, {})
			var smoothed_y: float = float(state.get("altitude_y", target_y))
			if altitude <= 0.01:
				smoothed_y = target_y
			else:
				var t: float = clampf(aircraft_height_smooth * _frame_delta, 0.0, 1.0)
				smoothed_y = lerpf(smoothed_y, target_y, t)
			state["altitude_y"] = smoothed_y
			_aircraft_visual_state[id] = state
			target_y = smoothed_y
		proxy.position = Vector3(pos2.x, target_y, pos2.y)
		if group_name in ["units", "collectors", "defense_turret", "missiles"]:
			var facing: Variant = node.get("_facing")
			if group_name == "missiles":
				var velocity: Variant = node.get("_velocity")
				if velocity is Vector2 and velocity.length() > 0.1:
					var target := proxy.global_position + Vector3(velocity.x, 0.0, velocity.y)
					proxy.look_at(target, Vector3.UP)
				_update_missile_trail(node, proxy, id)
			elif facing is Vector2 and facing.length() > 0.1:
				var target := proxy.global_position + Vector3(facing.x, 0.0, facing.y)
				proxy.look_at(target, Vector3.UP)
				if group_name == "units" and unit_kind == "aircraft":
					_apply_aircraft_bank_and_roll(node, proxy, id, facing)
					_update_aircraft_afterburner(node, proxy, id, facing)
		if group_name == "defense_turret":
			_update_turret_range(proxy, node)
		elif group_name in ["building", "hq"]:
			_update_health_bar(node, proxy, true)
		elif group_name == "units":
			var selected_value: Variant = node.get("is_selected")
			var is_selected := bool(selected_value)
			_update_selection_ring(proxy, is_selected and node.visible)
			if show_unit_health:
				var allow := true
				if unit_health_selected_only and not is_selected:
					allow = false
				_update_health_bar(node, proxy, allow)

func _get_airframe_node(proxy: Node3D) -> Node3D:
	if proxy == null:
		return null
	if proxy.has_meta("airframe"):
		var airframe: Node3D = proxy.get_meta("airframe") as Node3D
		if airframe != null and is_instance_valid(airframe):
			return airframe
	return proxy

func _apply_aircraft_bank_and_roll(node, proxy: Node3D, id: int, facing: Vector2) -> void:
	if not aircraft_bank_enabled and not aircraft_roll_enabled:
		return
	var airframe := _get_airframe_node(proxy)
	if airframe == null:
		return
	var state: Dictionary = _aircraft_visual_state.get(id, {})
	var prev_facing_value: Variant = state.get("facing", facing)
	var prev_facing: Vector2 = facing
	if prev_facing_value is Vector2:
		prev_facing = prev_facing_value
	var yaw := atan2(facing.x, facing.y)
	var prev_yaw := float(state.get("yaw", yaw))
	var delta_yaw := wrapf(yaw - prev_yaw, -PI, PI)
	var turn_sign: float = sign(prev_facing.cross(facing))
	var yaw_rate := delta_yaw / maxf(0.001, _frame_delta)
	var altitude := clampf(_get_float(node, "aircraft_altitude_factor", 1.0), 0.0, 1.0)
	var target_bank := 0.0
	if aircraft_bank_enabled:
		var bank_mag := clampf(rad_to_deg(absf(yaw_rate)) * aircraft_bank_strength, 0.0, aircraft_bank_max_deg)
		target_bank = bank_mag * turn_sign * altitude
	var current_bank := float(state.get("bank", 0.0))
	var bank_t := clampf(aircraft_bank_smooth * _frame_delta, 0.0, 1.0)
	current_bank = lerpf(current_bank, target_bank, bank_t)
	var roll_angle := 0.0
	var roll_active := bool(state.get("roll_active", false))
	var roll_progress := float(state.get("roll_progress", 0.0))
	var roll_dir := float(state.get("roll_dir", 1.0))
	var roll_timer := float(state.get("roll_timer", -1.0))
	if aircraft_roll_enabled:
		var min_interval := maxf(0.1, aircraft_roll_interval_min)
		var max_interval := maxf(min_interval, aircraft_roll_interval_max)
		if roll_timer < 0.0:
			roll_timer = _aircraft_rng.randf_range(min_interval, max_interval)
		var reloading := bool(_get_value(node, "_aircraft_reloading", false))
		var manual := bool(_get_value(node, "manual_active", false))
		var hold := bool(_get_value(node, "_hold_active", false))
		var circulating := bool(_get_value(node, "aircraft_circulating", false))
		if roll_active:
			roll_progress += _frame_delta / maxf(0.1, aircraft_roll_duration)
			if roll_progress >= 1.0:
				roll_active = false
				roll_progress = 0.0
				roll_timer = _aircraft_rng.randf_range(min_interval, max_interval)
			else:
				roll_angle = roll_dir * TAU * roll_progress
		else:
			var can_roll := circulating and not reloading and not manual and not hold and altitude >= aircraft_roll_min_altitude
			if can_roll:
				roll_timer -= _frame_delta
				if roll_timer <= 0.0:
					roll_active = true
					roll_progress = 0.0
					roll_dir = -1.0 if _aircraft_rng.randf() < 0.5 else 1.0
					roll_timer = _aircraft_rng.randf_range(min_interval, max_interval)
		if roll_active:
			roll_angle = roll_dir * TAU * roll_progress
	airframe.rotation = Vector3.ZERO
	var total_roll := deg_to_rad(current_bank) + roll_angle
	if absf(total_roll) > 0.0001:
		airframe.rotate_object_local(Vector3.FORWARD, total_roll)
	state["facing"] = facing
	state["yaw"] = yaw
	state["bank"] = current_bank
	state["roll_active"] = roll_active
	state["roll_progress"] = roll_progress
	state["roll_dir"] = roll_dir
	state["roll_timer"] = roll_timer
	_aircraft_visual_state[id] = state

func _update_aircraft_afterburner(node, proxy: Node3D, id: int, facing: Vector2) -> void:
	if not aircraft_afterburner_smoke_enabled:
		return
	var active := bool(_get_value(node, "aircraft_afterburner_active", false))
	if not active:
		var inactive_state: Dictionary = _aircraft_visual_state.get(id, {})
		inactive_state["afterburner_timer"] = 0.0
		_aircraft_visual_state[id] = inactive_state
		return
	var altitude := clampf(_get_float(node, "aircraft_altitude_factor", 1.0), 0.0, 1.0)
	if altitude <= 0.01:
		return
	var state: Dictionary = _aircraft_visual_state.get(id, {})
	var timer: float = float(state.get("afterburner_timer", 0.0)) - _frame_delta
	if timer > 0.0:
		state["afterburner_timer"] = timer
		_aircraft_visual_state[id] = state
		return
	timer = maxf(0.02, aircraft_afterburner_smoke_interval)
	state["afterburner_timer"] = timer
	_aircraft_visual_state[id] = state
	var back := -facing
	if back.length_squared() <= 0.01:
		back = Vector2(0.0, -1.0)
	var pos := proxy.global_position + Vector3(back.x, 0.0, back.y) * aircraft_afterburner_smoke_offset
	pos.y += aircraft_afterburner_smoke_height_offset
	if aircraft_afterburner_smoke_spread > 0.0:
		var jitter := Vector3(
			_smoke_rng.randf_range(-aircraft_afterburner_smoke_spread, aircraft_afterburner_smoke_spread),
			_smoke_rng.randf_range(-aircraft_afterburner_smoke_spread, aircraft_afterburner_smoke_spread) * 0.2,
			_smoke_rng.randf_range(-aircraft_afterburner_smoke_spread, aircraft_afterburner_smoke_spread)
		)
		pos += jitter
	_spawn_smoke(pos, aircraft_afterburner_smoke_color, aircraft_afterburner_smoke_size, aircraft_afterburner_smoke_duration)

func _get_ground_height(pos: Vector2) -> float:
	if not terrain_follow_enabled:
		return 0.0
	var ground := _get_ground_node()
	if ground == null:
		return 0.0
	if not ground.has_method("get_height_at"):
		return 0.0
	var height_value: Variant = ground.call("get_height_at", pos)
	if height_value is float or height_value is int:
		return float(height_value)
	return 0.0

func _get_ground_max_height() -> float:
	if not terrain_follow_enabled:
		return 0.0
	if not fog_height_follow_terrain:
		return 0.0
	var ground := _get_ground_node()
	if ground == null:
		return 0.0
	if not ground.has_method("get_max_height"):
		return 0.0
	var height_value: Variant = ground.call("get_max_height")
	if height_value is float or height_value is int:
		return float(height_value)
	return 0.0

func _get_ground_node() -> Node:
	if _ground != null and is_instance_valid(_ground):
		return _ground
	_ground = get_node_or_null(ground_path)
	return _ground

func _make_box(size: Vector3, color: Color) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = _make_material(color)
	return mesh

func _make_cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.material_override = _make_material(color)
	return mesh

func _make_cone(radius: float, height: float, color: Color) -> MeshInstance3D:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	var mesh := MeshInstance3D.new()
	mesh.mesh = cone
	mesh.material_override = _make_material(color)
	return mesh

func _make_pentagon_prism(radius: float, height: float, color: Color) -> MeshInstance3D:
	var prism := CylinderMesh.new()
	prism.top_radius = radius
	prism.bottom_radius = radius
	prism.height = height
	prism.radial_segments = 5
	prism.rings = 1
	var mesh := MeshInstance3D.new()
	mesh.mesh = prism
	mesh.material_override = _make_material(color)
	return mesh

func _make_capsule(radius: float, height: float, color: Color) -> MeshInstance3D:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	var mesh := MeshInstance3D.new()
	mesh.mesh = capsule
	mesh.material_override = _make_material(color)
	return mesh

func _make_sphere(radius: float, color: Color) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = _make_material(color)
	return mesh

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.metallic = 0.05
	return material

func _make_pad_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_ui_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_ghost_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_zone_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_fog_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_tracer_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_fx_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_ring_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _attach_selection_ring(proxy: Node3D, radius: float, base_color: Color) -> void:
	if proxy.has_meta("selection_ring"):
		return
	var ring_color := selection_ring_color
	if selection_ring_use_unit_color:
		ring_color = base_color.lightened(0.5)
		ring_color.a = selection_ring_color.a
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	var outer := maxf(0.5, radius)
	var inner := maxf(0.05, outer - selection_ring_thickness)
	torus.outer_radius = outer
	torus.inner_radius = inner
	torus.rings = 64
	torus.ring_segments = 12
	ring.mesh = torus
	ring.material_override = _make_ring_material(ring_color)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false
	ring.position = Vector3(0.0, selection_ring_height, 0.0)
	proxy.add_child(ring)
	proxy.set_meta("selection_ring", ring)

func _update_selection_ring(proxy: Node3D, visible: bool) -> void:
	if not proxy.has_meta("selection_ring"):
		return
	var ring: MeshInstance3D = proxy.get_meta("selection_ring") as MeshInstance3D
	if ring == null:
		return
	ring.visible = visible

func _attach_turret_range(proxy: Node3D, radius: float) -> void:
	if proxy.has_meta("turret_range_ring"):
		return
	var ring := _build_turret_range_ring(radius)
	proxy.add_child(ring)
	proxy.set_meta("turret_range_ring", ring)
	proxy.set_meta("turret_range_radius", radius)

func _update_turret_range(proxy: Node3D, turret) -> void:
	if not turret_range_enabled:
		if proxy.has_meta("turret_range_ring"):
			var ring_hidden: MultiMeshInstance3D = proxy.get_meta("turret_range_ring") as MultiMeshInstance3D
			if ring_hidden != null:
				ring_hidden.visible = false
		return
	var radius := _get_float(turret, "attack_range", 0.0)
	if radius <= 0.0:
		return
	if not proxy.has_meta("turret_range_ring"):
		_attach_turret_range(proxy, radius)
	var ring: MultiMeshInstance3D = proxy.get_meta("turret_range_ring") as MultiMeshInstance3D
	if ring == null:
		return
	ring.visible = true
	ring.position = Vector3(0.0, turret_range_height, 0.0)
	var last_radius: float = float(proxy.get_meta("turret_range_radius", -1.0))
	if absf(last_radius - radius) > 0.1:
		_set_turret_range_mesh(ring, radius)
		proxy.set_meta("turret_range_radius", radius)
	ring.material_override = _make_ring_material(turret_range_color)

func _build_turret_range_ring(radius: float) -> MultiMeshInstance3D:
	var ring := MultiMeshInstance3D.new()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = turret_range_enabled
	_set_turret_range_mesh(ring, radius)
	return ring

func _set_turret_range_mesh(ring: MultiMeshInstance3D, radius: float) -> void:
	var use_radius := maxf(0.5, radius)
	var dash_count := maxi(6, turret_range_dash_count)
	var dash_ratio := clampf(turret_range_dash_ratio, 0.1, 0.9)
	var circumference := TAU * use_radius
	var dash_length := maxf(0.3, (circumference / float(dash_count)) * dash_ratio)
	var thickness := maxf(0.1, turret_range_thickness)
	var height := maxf(0.02, thickness * 0.2)
	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(thickness, height, dash_length)
	var multi := MultiMesh.new()
	multi.mesh = dash_mesh
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = dash_count
	var step := TAU / float(dash_count)
	for i in range(dash_count):
		var angle := step * float(i)
		var pos := Vector3(cos(angle) * use_radius, 0.0, sin(angle) * use_radius)
		var forward := Vector3(-sin(angle), 0.0, cos(angle))
		var right := Vector3.UP.cross(forward).normalized()
		var basis := Basis(right, Vector3.UP, forward)
		var xform := Transform3D(basis, pos)
		multi.set_instance_transform(i, xform)
	ring.multimesh = multi

func _add_building_details(proxy: Node3D, build_id: String, size2d: Vector2, height: float, base_color: Color) -> void:
	var accent := base_color.lightened(0.2)
	var dark := base_color.darkened(0.25)
	var roof_color := base_color.lightened(0.12)
	var slab_height := height * 0.08
	_add_box_detail(proxy, Vector3(size2d.x * 1.06, slab_height, size2d.y * 1.06), base_color.darkened(0.35),
		Vector3(0, slab_height * 0.5, 0))
	match build_id:
		"barracks":
			_add_box_detail(proxy, Vector3(size2d.x * 0.86, height * 0.14, size2d.y * 0.78), roof_color,
				Vector3(0, height * 0.9, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.34, height * 0.3, size2d.y * 0.56), accent.darkened(0.06),
				Vector3(-size2d.x * 0.34, height * 0.28, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.28, height * 0.26, size2d.y * 0.46), accent.darkened(0.08),
				Vector3(size2d.x * 0.36, height * 0.24, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.32, height * 0.22, size2d.y * 0.22), accent,
				Vector3(0, height * 0.26, -size2d.y * 0.46))
			_add_box_detail(proxy, Vector3(size2d.x * 0.4, height * 0.05, size2d.y * 0.16), roof_color.lightened(0.1),
				Vector3(0, height * 0.34, -size2d.y * 0.56))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.07, size2d.y * 0.12), dark,
				Vector3(0, height * 0.2, -size2d.y * 0.64))
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.16, size2d.y * 0.5), accent.darkened(0.12),
				Vector3(size2d.x * 0.44, height * 0.2, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.16, size2d.y * 0.5), accent.darkened(0.12),
				Vector3(-size2d.x * 0.44, height * 0.2, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.22, size2d.y * 0.26), dark,
				Vector3(0, height * 0.18, size2d.y * 0.46))
			_add_box_detail(proxy, Vector3(size2d.x * 0.32, height * 0.06, size2d.y * 0.12), roof_color,
				Vector3(0, height * 0.26, size2d.y * 0.56))
			var tower := _add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.6, size2d.y * 0.2), accent,
				Vector3(-size2d.x * 0.3, height * 0.8, size2d.y * 0.24))
			tower.scale = Vector3(1.0, 1.1, 1.0)
			for i in range(4):
				var x := (float(i) - 1.5) * (size2d.x * 0.16)
				_add_box_detail(proxy, Vector3(size2d.x * 0.12, height * 0.08, size2d.y * 0.1), dark,
					Vector3(x, height * 0.92, size2d.y * 0.1))
			for i in range(3):
				var x := (float(i) - 1.0) * (size2d.x * 0.12)
				_add_box_detail(proxy, Vector3(size2d.x * 0.08, height * 0.06, size2d.y * 0.08), dark,
					Vector3(x, height * 0.82, -size2d.y * 0.22))
			for i in range(4):
				var x := (float(i) - 1.5) * (size2d.x * 0.16)
				_add_box_detail(proxy, Vector3(size2d.x * 0.08, height * 0.12, size2d.y * 0.04), accent.darkened(0.2),
					Vector3(x, height * 0.42, -size2d.y * 0.52))
			for i in range(3):
				var z := (float(i) - 1.0) * (size2d.y * 0.18)
				_add_box_detail(proxy, Vector3(size2d.x * 0.04, height * 0.1, size2d.y * 0.12), dark,
					Vector3(-size2d.x * 0.46, height * 0.36, z))
			_add_cylinder_detail(proxy, size2d.x * 0.02, height * 0.6, dark,
				Vector3(-size2d.x * 0.4, height * 1.04, size2d.y * 0.3))
			_add_cylinder_detail(proxy, size2d.x * 0.03, height * 0.42, accent,
				Vector3(size2d.x * 0.38, height * 0.86, -size2d.y * 0.32))
			_add_cylinder_detail(proxy, size2d.x * 0.035, height * 0.35, accent.lightened(0.12),
				Vector3(size2d.x * 0.18, height * 0.84, size2d.y * 0.32))
			_add_box_detail(proxy, Vector3(size2d.x * 0.1, height * 0.1, size2d.y * 0.1), roof_color,
				Vector3(-size2d.x * 0.06, height * 0.88, -size2d.y * 0.3))
		"factory":
			_add_box_detail(proxy, Vector3(size2d.x * 0.86, height * 0.18, size2d.y * 0.8), roof_color,
				Vector3(0, height * 0.9, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.62, height * 0.38, size2d.y * 0.08), dark,
				Vector3(0, height * 0.34, -size2d.y * 0.5))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.32, size2d.y * 0.28), accent,
				Vector3(-size2d.x * 0.38, height * 0.44, size2d.y * 0.2))
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.24, size2d.y * 0.2), accent,
				Vector3(size2d.x * 0.36, height * 0.38, size2d.y * 0.24))
			for i in range(4):
				var x := (float(i) - 1.5) * (size2d.x * 0.18)
				_add_box_detail(proxy, Vector3(size2d.x * 0.14, height * 0.12, size2d.y * 0.16), roof_color,
					Vector3(x, height * 0.96, size2d.y * 0.02))
			_add_cylinder_detail(proxy, size2d.x * 0.05, height * 0.6, dark,
				Vector3(size2d.x * 0.42, height * 0.85, size2d.y * 0.32))
			_add_cylinder_detail(proxy, size2d.x * 0.04, height * 0.5, dark,
				Vector3(size2d.x * 0.32, height * 0.78, -size2d.y * 0.18))
		"supply":
			_add_box_detail(proxy, Vector3(size2d.x * 0.7, height * 0.14, size2d.y * 0.68), roof_color,
				Vector3(0, height * 0.86, 0))
			_add_cylinder_detail(proxy, size2d.x * 0.13, height * 0.5, accent,
				Vector3(-size2d.x * 0.26, height * 0.56, size2d.y * 0.22))
			_add_cylinder_detail(proxy, size2d.x * 0.13, height * 0.5, accent,
				Vector3(size2d.x * 0.26, height * 0.56, size2d.y * 0.22))
			var tank_c := _add_cylinder_detail(proxy, size2d.x * 0.1, height * 0.42, accent.lightened(0.08),
				Vector3(0, height * 0.52, size2d.y * 0.28))
			tank_c.scale = Vector3(1.0, 0.9, 1.0)
			var pipe := _add_cylinder_detail(proxy, size2d.x * 0.03, size2d.x * 0.55, dark,
				Vector3(0, height * 0.5, size2d.y * 0.22))
			pipe.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			_add_box_detail(proxy, Vector3(size2d.x * 0.42, height * 0.08, size2d.y * 0.1), dark,
				Vector3(0, height * 0.3, -size2d.y * 0.38))
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.2, size2d.y * 0.14), dark,
				Vector3(size2d.x * 0.3, height * 0.42, -size2d.y * 0.18))
			_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.16, size2d.y * 0.16), roof_color,
				Vector3(-size2d.x * 0.34, height * 0.38, -size2d.y * 0.1))
		"power":
			_add_box_detail(proxy, Vector3(size2d.x * 0.66, height * 0.16, size2d.y * 0.62), roof_color,
				Vector3(0, height * 0.88, 0))
			_add_cylinder_detail(proxy, size2d.x * 0.16, height * 0.7, accent,
				Vector3(-size2d.x * 0.24, height * 0.82, size2d.y * 0.18))
			_add_cylinder_detail(proxy, size2d.x * 0.16, height * 0.7, accent,
				Vector3(size2d.x * 0.24, height * 0.82, size2d.y * 0.18))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.26, size2d.y * 0.2), dark,
				Vector3(0, height * 0.54, -size2d.y * 0.22))
			for i in range(3):
				var x := (float(i) - 1.0) * (size2d.x * 0.18)
				_add_box_detail(proxy, Vector3(size2d.x * 0.12, height * 0.14, size2d.y * 0.16), dark,
					Vector3(x, height * 0.34, -size2d.y * 0.38))
			_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.12, size2d.y * 0.12), dark,
				Vector3(-size2d.x * 0.32, height * 0.42, -size2d.y * 0.3))
		"command_center":
			_add_box_detail(proxy, Vector3(size2d.x * 0.72, height * 0.18, size2d.y * 0.72), roof_color,
				Vector3(0, height * 0.88, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.7, size2d.y * 0.24), accent,
				Vector3(-size2d.x * 0.2, height * 0.88, size2d.y * 0.1))
			var dish := _add_sphere_detail(proxy, size2d.x * 0.12, accent,
				Vector3(size2d.x * 0.26, height * 1.05, size2d.y * 0.02))
			dish.scale = Vector3(1.6, 0.4, 1.6)
			var radome := _add_sphere_detail(proxy, size2d.x * 0.1, roof_color,
				Vector3(-size2d.x * 0.34, height * 1.0, -size2d.y * 0.08))
			radome.scale = Vector3(1.2, 0.8, 1.2)
			_add_cylinder_detail(proxy, size2d.x * 0.03, height * 0.48, dark,
				Vector3(size2d.x * 0.32, height * 0.98, size2d.y * 0.2))
			var helipad := _add_cylinder_detail(proxy, size2d.x * 0.18, height * 0.04, dark,
				Vector3(size2d.x * 0.3, height * 0.24, -size2d.y * 0.22))
			helipad.scale = Vector3(1.4, 1.0, 1.4)
			_add_box_detail(proxy, Vector3(size2d.x * 0.22, height * 0.18, size2d.y * 0.12), dark,
				Vector3(0, height * 0.36, -size2d.y * 0.36))
		_:
			if build_id.begins_with("defense"):
				_add_box_detail(proxy, Vector3(size2d.x * 0.62, height * 0.14, size2d.y * 0.62), roof_color,
					Vector3(0, height * 0.74, 0))
				_add_box_detail(proxy, Vector3(size2d.x * 0.24, height * 0.26, size2d.y * 0.24), dark,
					Vector3(0, height * 0.44, 0))
				var radar := _add_sphere_detail(proxy, size2d.x * 0.1, accent,
					Vector3(size2d.x * 0.22, height * 0.86, -size2d.y * 0.12))
				radar.scale = Vector3(1.3, 0.5, 1.3)
				_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.12, size2d.y * 0.12), dark,
					Vector3(-size2d.x * 0.28, height * 0.36, size2d.y * 0.28))
			else:
				_add_box_detail(proxy, Vector3(size2d.x * 0.72, height * 0.18, size2d.y * 0.7), roof_color,
					Vector3(0, height * 0.88, 0))
				_add_box_detail(proxy, Vector3(size2d.x * 0.24, height * 0.2, size2d.y * 0.18), dark,
					Vector3(-size2d.x * 0.2, height * 0.45, -size2d.y * 0.3))
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.12, size2d.y * 0.1), accent,
				Vector3(size2d.x * 0.26, height * 0.36, size2d.y * 0.3))

func _add_building_pad(proxy: Node3D, size2d: Vector2, base_color: Color) -> void:
	if not building_pad_enabled:
		return
	var margin := maxf(0.0, building_pad_margin)
	var pad_height := maxf(0.01, building_pad_height)
	var pad_size := Vector3(size2d.x * (1.0 + margin), pad_height, size2d.y * (1.0 + margin))
	var pad_color := building_pad_color
	pad_color.a = clampf(pad_color.a, 0.1, 0.8)
	if pad_color.a <= 0.1:
		pad_color = base_color.darkened(0.55)
		pad_color.a = 0.55
	var pad := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = pad_size
	pad.mesh = mesh
	pad.material_override = _make_pad_material(pad_color)
	pad.position = Vector3(0.0, pad_height * 0.5, 0.0)
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	proxy.add_child(pad)

func _add_building_props(proxy: Node3D, build_id: String, size2d: Vector2, height: float, base_color: Color) -> void:
	if not prop_detail_enabled:
		return
	var accent := base_color.lightened(0.2)
	var dark := base_color.darkened(0.35)
	match build_id:
		"barracks":
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.12, size2d.y * 0.12), dark,
				Vector3(-size2d.x * 0.32, height * 0.06, size2d.y * 0.34))
			_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.1, size2d.y * 0.1), accent,
				Vector3(size2d.x * 0.34, height * 0.05, size2d.y * 0.32))
			_add_cylinder_detail(proxy, size2d.x * 0.035, height * 0.55, accent.lightened(0.2),
				Vector3(size2d.x * 0.2, height * 0.7, -size2d.y * 0.18))
		"factory":
			var chimney_height := height * 0.65
			if prop_chimney_model_path != "" and ResourceLoader.exists(prop_chimney_model_path):
				_add_scene_model(proxy, prop_chimney_model_path, Vector2(size2d.x * 0.16, size2d.y * 0.16), 0.0,
					prop_model_scale, Vector3(-size2d.x * 0.3, 0.0, -size2d.y * 0.32))
				_add_scene_model(proxy, prop_chimney_model_path, Vector2(size2d.x * 0.16, size2d.y * 0.16), 0.0,
					prop_model_scale, Vector3(size2d.x * 0.3, 0.0, -size2d.y * 0.32))
			else:
				_add_cylinder_detail(proxy, size2d.x * 0.05, chimney_height, dark,
					Vector3(-size2d.x * 0.3, chimney_height * 0.5, -size2d.y * 0.32))
				_add_cylinder_detail(proxy, size2d.x * 0.05, chimney_height * 0.85, dark,
					Vector3(size2d.x * 0.3, chimney_height * 0.42, -size2d.y * 0.32))
			_add_box_detail(proxy, Vector3(size2d.x * 0.24, height * 0.12, size2d.y * 0.16), accent,
				Vector3(size2d.x * 0.34, height * 0.06, size2d.y * 0.34))
		"supply":
			if prop_tank_model_path != "" and ResourceLoader.exists(prop_tank_model_path):
				_add_scene_model(proxy, prop_tank_model_path, Vector2(size2d.x * 0.28, size2d.y * 0.18), 0.0,
					prop_model_scale, Vector3(-size2d.x * 0.22, 0.0, size2d.y * 0.34))
				_add_scene_model(proxy, prop_tank_model_path, Vector2(size2d.x * 0.28, size2d.y * 0.18), 0.0,
					prop_model_scale, Vector3(size2d.x * 0.22, 0.0, size2d.y * 0.34))
			else:
				_add_cylinder_detail(proxy, size2d.x * 0.08, height * 0.32, accent,
					Vector3(-size2d.x * 0.26, height * 0.16, size2d.y * 0.32))
				_add_cylinder_detail(proxy, size2d.x * 0.08, height * 0.32, accent,
					Vector3(size2d.x * 0.26, height * 0.16, size2d.y * 0.32))
			_add_box_detail(proxy, Vector3(size2d.x * 0.22, height * 0.1, size2d.y * 0.14), dark,
				Vector3(0.0, height * 0.05, size2d.y * 0.34))
		"command_center":
			_add_cylinder_detail(proxy, size2d.x * 0.04, height * 0.5, accent,
				Vector3(size2d.x * 0.12, height * 0.7, 0.0))
			_add_sphere_detail(proxy, size2d.x * 0.06, accent.lightened(0.3),
				Vector3(-size2d.x * 0.16, height * 0.8, -size2d.y * 0.1))
		"power":
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.16, size2d.y * 0.18), dark,
				Vector3(size2d.x * 0.28, height * 0.08, -size2d.y * 0.22))
			_add_cylinder_detail(proxy, size2d.x * 0.03, height * 0.45, accent,
				Vector3(-size2d.x * 0.28, height * 0.65, size2d.y * 0.2))
		_:
			if build_id.begins_with("defense"):
				_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.12, size2d.y * 0.2), dark,
					Vector3(0.0, height * 0.06, size2d.y * 0.32))

func _add_missile_model(proxy: Node3D, base_color: Color, scale: float) -> bool:
	if missile_model_path == "" or not ResourceLoader.exists(missile_model_path):
		return false
	var target_size := Vector2(
		maxf(0.5, missile_body_radius * 2.6 * scale),
		maxf(0.5, (missile_body_length + missile_nose_length) * scale)
	)
	var model := _add_scene_model_instance(
		proxy,
		missile_model_path,
		target_size,
		0.0,
		missile_model_scale
	)
	if model == null:
		return false
	_tint_model(model, base_color)
	return true

func _tint_model(root: Node3D, base_color: Color) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is MeshInstance3D):
			continue
		var mesh_instance := node as MeshInstance3D
		var part := mesh_instance.name.to_lower()
		var part_color := base_color
		if part.find("nose") >= 0:
			part_color = base_color.lightened(0.2)
		elif part.find("fin") >= 0:
			part_color = base_color.darkened(0.2)
		elif part.find("exhaust") >= 0:
			part_color = base_color.lightened(0.4)
		mesh_instance.material_override = _make_material(part_color)

func _build_airfield_base(proxy: Node3D, size2d: Vector2, height: float, base_color: Color) -> float:
	var pad_height := maxf(0.2, height * 0.06)
	var pad := _make_box(Vector3(size2d.x * 0.98, pad_height, size2d.y * 0.62), base_color.darkened(0.2))
	pad.position = Vector3(0.0, pad_height * 0.5, size2d.y * 0.08)
	proxy.add_child(pad)
	var runway_height := maxf(0.15, height * 0.04)
	var runway := _make_box(Vector3(size2d.x * 0.9, runway_height, size2d.y * 0.28), airfield_runway_color)
	runway.position = Vector3(0.0, pad_height + runway_height * 0.5, size2d.y * 0.18)
	proxy.add_child(runway)
	var stripe_height := runway_height * 0.6
	var stripe_size := Vector3(size2d.x * 0.08, stripe_height, size2d.y * 0.03)
	var stripe_y := pad_height + runway_height * 0.5 + stripe_height * 0.5
	for i in range(4):
		var z := size2d.y * 0.18 + (float(i) - 1.5) * (size2d.y * 0.07)
		var stripe := _make_box(stripe_size, airfield_marking_color)
		stripe.position = Vector3(0.0, stripe_y, z)
		proxy.add_child(stripe)
	var hangar_height := height * 0.42
	var hangar_size := Vector3(size2d.x * 0.4, hangar_height, size2d.y * 0.32)
	var hangar := _make_box(hangar_size, base_color)
	hangar.position = Vector3(-size2d.x * 0.22, hangar_height * 0.5, -size2d.y * 0.18)
	proxy.add_child(hangar)
	var roof_height := hangar_height * 0.25
	var roof := _make_box(Vector3(hangar_size.x * 1.02, roof_height, hangar_size.z * 1.05), base_color.lightened(0.18))
	roof.position = Vector3(hangar.position.x, hangar_height + roof_height * 0.5, hangar.position.z)
	proxy.add_child(roof)
	var tower_height := height * 0.7
	var tower_size := Vector3(size2d.x * 0.12, tower_height, size2d.y * 0.12)
	var tower := _make_box(tower_size, base_color.lightened(0.12))
	tower.position = Vector3(size2d.x * 0.36, tower_height * 0.5, -size2d.y * 0.2)
	proxy.add_child(tower)
	var cabin_height := height * 0.18
	var cabin := _make_box(Vector3(tower_size.x * 1.6, cabin_height, tower_size.z * 1.6), base_color.lightened(0.22))
	cabin.position = Vector3(tower.position.x, tower_height + cabin_height * 0.5, tower.position.z)
	proxy.add_child(cabin)
	var radar := _make_cylinder(size2d.x * 0.05, height * 0.12, base_color.lightened(0.3))
	radar.position = Vector3(tower.position.x, tower_height + cabin_height + height * 0.08, tower.position.z)
	proxy.add_child(radar)
	var max_height := maxf(hangar_height + roof_height, tower_height + cabin_height + height * 0.12)
	return maxf(max_height, runway_height + pad_height)

func _build_defense_base(proxy: Node3D, build_id: String, size2d: Vector2, height: float, base_color: Color) -> float:
	var accent := base_color.lightened(0.2)
	var dark := base_color.darkened(0.35)
	var mid := base_color.darkened(0.18)
	var base_height := height * 0.2
	var base_size := Vector3(size2d.x * 0.86, base_height, size2d.y * 0.86)
	var base := _make_box(base_size, mid)
	base.position = Vector3(0.0, base_height * 0.5, 0.0)
	proxy.add_child(base)
	var ring_height := height * 0.12
	var ring_radius := minf(size2d.x, size2d.y) * 0.22
	var ring := _make_cylinder(ring_radius, ring_height, base_color.lightened(0.05))
	ring.position = Vector3(0.0, base_height + ring_height * 0.5, 0.0)
	proxy.add_child(ring)
	var deck_height := height * 0.05
	var deck := _make_box(Vector3(size2d.x * 0.58, deck_height, size2d.y * 0.58), dark)
	deck.position = Vector3(0.0, base_height + ring_height + deck_height * 0.5, 0.0)
	proxy.add_child(deck)
	var max_height := base_height + ring_height + deck_height
	match build_id:
		"defense_gun":
			var ammo_height := height * 0.14
			var ammo_size := Vector3(size2d.x * 0.16, ammo_height, size2d.y * 0.12)
			var ammo_a := _make_box(ammo_size, dark)
			ammo_a.position = Vector3(-size2d.x * 0.22, ammo_height * 0.5, size2d.y * 0.24)
			proxy.add_child(ammo_a)
			var ammo_b := _make_box(ammo_size, dark)
			ammo_b.position = Vector3(size2d.x * 0.22, ammo_height * 0.5, size2d.y * 0.24)
			proxy.add_child(ammo_b)
			var mast_height := height * 0.32
			var mast := _make_cylinder(size2d.x * 0.025, mast_height, accent)
			mast.position = Vector3(0.0, base_height + ring_height + deck_height + mast_height * 0.5, -size2d.y * 0.18)
			proxy.add_child(mast)
			var radar := _make_sphere(size2d.x * 0.06, accent.lightened(0.3))
			radar.position = Vector3(0.0, base_height + ring_height + deck_height + mast_height, -size2d.y * 0.18)
			radar.scale = Vector3(1.4, 0.5, 1.4)
			proxy.add_child(radar)
			max_height = maxf(max_height, base_height + ring_height + deck_height + mast_height)
		"defense_missile":
			var tube_height := height * 0.55
			var tube_radius := minf(size2d.x, size2d.y) * 0.06
			var tube_y := base_height + ring_height + deck_height + tube_height * 0.5
			for i in range(3):
				var x := (float(i) - 1.0) * (size2d.x * 0.18)
				var tube := _make_cylinder(tube_radius, tube_height, accent)
				tube.position = Vector3(x, tube_y, -size2d.y * 0.06)
				proxy.add_child(tube)
				var cap := _make_sphere(tube_radius * 0.7, accent.lightened(0.3))
				cap.position = Vector3(x, tube_y + tube_height * 0.5, -size2d.y * 0.06)
				proxy.add_child(cap)
			max_height = maxf(max_height, tube_y + tube_height * 0.5)
		"defense_laser":
			var emitter_height := height * 0.65
			var emitter_radius := minf(size2d.x, size2d.y) * 0.045
			var emitter_y := base_height + ring_height + deck_height + emitter_height * 0.5
			var emitter := _make_cylinder(emitter_radius, emitter_height, accent.lightened(0.1))
			emitter.position = Vector3(0.0, emitter_y, -size2d.y * 0.08)
			proxy.add_child(emitter)
			var lens := _make_sphere(emitter_radius * 1.2, Color(0.4, 0.9, 1.0, 1.0))
			lens.position = Vector3(0.0, emitter_y + emitter_height * 0.5, -size2d.y * 0.08)
			proxy.add_child(lens)
			var cell_height := height * 0.2
			var cell := _make_box(Vector3(size2d.x * 0.16, cell_height, size2d.y * 0.12), dark)
			cell.position = Vector3(-size2d.x * 0.22, cell_height * 0.5, size2d.y * 0.22)
			proxy.add_child(cell)
			var cell_b := _make_box(Vector3(size2d.x * 0.16, cell_height, size2d.y * 0.12), dark)
			cell_b.position = Vector3(size2d.x * 0.22, cell_height * 0.5, size2d.y * 0.22)
			proxy.add_child(cell_b)
			max_height = maxf(max_height, emitter_y + emitter_height * 0.5)
	return max_height

func _add_hq_props(proxy: Node3D, size2d: Vector2, height: float, base_color: Color) -> void:
	if not prop_detail_enabled:
		return
	var pad_radius := minf(size2d.x, size2d.y) * 0.22
	var helipad := _make_cylinder(pad_radius, height * 0.04, base_color.darkened(0.4))
	helipad.position = Vector3(0.0, height * 0.02, -size2d.y * 0.12)
	helipad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	proxy.add_child(helipad)
	_add_cylinder_detail(proxy, size2d.x * 0.035, height * 0.55, base_color.lightened(0.25),
		Vector3(size2d.x * 0.18, height * 0.7, size2d.y * 0.08))
	_add_sphere_detail(proxy, size2d.x * 0.05, base_color.lightened(0.4),
		Vector3(size2d.x * 0.18, height * 0.9, size2d.y * 0.08))

func _add_box_detail(proxy: Node3D, size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := _make_box(size, color)
	mesh.position = pos
	proxy.add_child(mesh)
	return mesh

func _add_cylinder_detail(proxy: Node3D, radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := _make_cylinder(radius, height, color)
	mesh.position = pos
	proxy.add_child(mesh)
	return mesh

func _add_sphere_detail(proxy: Node3D, radius: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := _make_sphere(radius, color)
	mesh.position = pos
	proxy.add_child(mesh)
	return mesh

func _add_scene_model(
	proxy: Node3D,
	scene_path: String,
	target_size: Vector2,
	target_height: float,
	scale_hint: float,
	offset := Vector3.ZERO,
	rotation_degrees := Vector3.ZERO
) -> float:
	var packed: Resource = load(scene_path)
	if packed == null or not (packed is PackedScene):
		return 0.0
	var instance := (packed as PackedScene).instantiate()
	if instance == null or not (instance is Node3D):
		return 0.0
	var model := instance as Node3D
	proxy.add_child(model)
	var bounds := _calc_model_aabb(model)
	if bounds.size == Vector3.ZERO:
		return 0.0
	var scale := scale_hint if scale_hint > 0.0 else 1.0
	if bounds.size.x > 0.0 and bounds.size.z > 0.0:
		scale *= minf(target_size.x / bounds.size.x, target_size.y / bounds.size.z)
	if target_height > 0.0 and bounds.size.y > 0.0:
		scale = minf(scale, target_height / bounds.size.y)
	model.scale = Vector3.ONE * scale
	var center := bounds.position + (bounds.size * 0.5)
	model.position = Vector3(-center.x * scale, -bounds.position.y * scale, -center.z * scale) + offset
	model.rotation_degrees = rotation_degrees
	return bounds.size.y * scale

func _add_scene_model_instance(
	proxy: Node3D,
	scene_path: String,
	target_size: Vector2,
	target_height: float,
	scale_hint: float,
	offset := Vector3.ZERO,
	rotation_degrees := Vector3.ZERO
) -> Node3D:
	var packed: Resource = load(scene_path)
	if packed == null or not (packed is PackedScene):
		return null
	var instance := (packed as PackedScene).instantiate()
	if instance == null or not (instance is Node3D):
		return null
	var model := instance as Node3D
	proxy.add_child(model)
	var bounds := _calc_model_aabb(model)
	if bounds.size == Vector3.ZERO:
		return model
	var scale := scale_hint if scale_hint > 0.0 else 1.0
	if bounds.size.x > 0.0 and bounds.size.z > 0.0:
		scale *= minf(target_size.x / bounds.size.x, target_size.y / bounds.size.z)
	if target_height > 0.0 and bounds.size.y > 0.0:
		scale = minf(scale, target_height / bounds.size.y)
	model.scale = Vector3.ONE * scale
	var center := bounds.position + (bounds.size * 0.5)
	model.position = Vector3(-center.x * scale, -bounds.position.y * scale, -center.z * scale) + offset
	model.rotation_degrees = rotation_degrees
	return model

func _add_barracks_compound(proxy: Node3D, target_size: Vector2, target_height: float) -> float:
	return _add_compound(
		proxy,
		target_size,
		target_height,
		barracks_compound_rows,
		barracks_compound_cols,
		barracks_compound_spacing,
		barracks_compound_models,
		barracks_model_scale
	)

func _add_factory_compound(proxy: Node3D, target_size: Vector2, target_height: float) -> float:
	return _add_compound(
		proxy,
		target_size,
		target_height,
		factory_compound_rows,
		factory_compound_cols,
		factory_compound_spacing,
		factory_compound_models,
		factory_model_scale
	)

func _add_hq_pentagon(proxy: Node3D, target_size: Vector2, target_height: float) -> float:
	var radius := minf(target_size.x, target_size.y) * hq_pentagon_radius_scale
	if radius <= 0.0:
		return 0.0
	var edge_len := 2.0 * radius * sin(PI / 5.0)
	var wing_depth := minf(target_size.x, target_size.y) * hq_pentagon_wing_depth_scale
	var wing_size := Vector2(maxf(10.0, edge_len), maxf(8.0, wing_depth))
	var max_height := 0.0
	for i in range(5):
		var angle := (TAU / 5.0) * float(i)
		var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var yaw := -rad_to_deg(angle) + 90.0
		var rotation := Vector3(0.0, yaw, 0.0)
		var model_height := _add_scene_model(proxy, hq_pentagon_model_path, wing_size, 0.0, hq_pentagon_model_scale, offset, rotation)
		if model_height > max_height:
			max_height = model_height
	if hq_pentagon_center_model_path != "" and ResourceLoader.exists(hq_pentagon_center_model_path):
		var center_size := Vector2(
			maxf(10.0, target_size.x * hq_pentagon_center_size_scale),
			maxf(10.0, target_size.y * hq_pentagon_center_size_scale)
		)
		var center_height := _add_scene_model(proxy, hq_pentagon_center_model_path, center_size, 0.0, hq_pentagon_center_model_scale)
		if center_height > max_height:
			max_height = center_height
	return max_height

func _add_compound(
	proxy: Node3D,
	target_size: Vector2,
	target_height: float,
	rows: int,
	cols: int,
	spacing: float,
	models: PackedStringArray,
	scale_hint: float
) -> float:
	var use_rows := maxi(1, rows)
	var use_cols := maxi(1, cols)
	var use_spacing := maxf(0.0, spacing)
	var total_spacing_x := use_spacing * float(use_cols - 1)
	var total_spacing_z := use_spacing * float(use_rows - 1)
	var cell_size := Vector2(
		maxf(6.0, (target_size.x - total_spacing_x) / float(use_cols)),
		maxf(6.0, (target_size.y - total_spacing_z) / float(use_rows))
	)
	var start := Vector2(
		-target_size.x * 0.5 + cell_size.x * 0.5,
		-target_size.y * 0.5 + cell_size.y * 0.5
	)
	var max_height := 0.0
	var idx := 0
	for row in range(use_rows):
		for col in range(use_cols):
			var path := models[idx % models.size()]
			idx += 1
			if path == "" or not ResourceLoader.exists(path):
				continue
			var offset := Vector3(
				start.x + float(col) * (cell_size.x + use_spacing),
				0.0,
				start.y + float(row) * (cell_size.y + use_spacing)
			)
			var model_height := _add_scene_model(proxy, path, cell_size, 0.0, scale_hint, offset)
			if model_height > max_height:
				max_height = model_height
	return max_height

func _calc_model_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO
	var root_inv := root.global_transform.affine_inverse()
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is MeshInstance3D):
			continue
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var local_aabb := mesh_instance.mesh.get_aabb()
		var xform := root_inv * mesh_instance.global_transform
		for corner in _get_aabb_corners(local_aabb):
			var p := xform * corner
			if first:
				min_v = p
				max_v = p
				first = false
			else:
				min_v = Vector3(minf(min_v.x, p.x), minf(min_v.y, p.y), minf(min_v.z, p.z))
				max_v = Vector3(maxf(max_v.x, p.x), maxf(max_v.y, p.y), maxf(max_v.z, p.z))
	if first:
		return AABB()
	combined.position = min_v
	combined.size = max_v - min_v
	return combined

func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	var pos := aabb.position
	var size := aabb.size
	return [
		pos,
		pos + Vector3(size.x, 0.0, 0.0),
		pos + Vector3(0.0, size.y, 0.0),
		pos + Vector3(0.0, 0.0, size.z),
		pos + Vector3(size.x, size.y, 0.0),
		pos + Vector3(size.x, 0.0, size.z),
		pos + Vector3(0.0, size.y, size.z),
		pos + size,
	]

func _attach_health_bar(proxy: Node3D, width: float, height: float, bar_height: float, y_offset: float) -> void:
	if proxy.has_meta("health_bar_root"):
		return
	var use_height := bar_height if bar_height > 0.0 else health_bar_height
	var use_offset := y_offset if y_offset >= 0.0 else health_bar_offset
	var bar := Node3D.new()
	bar.name = "HealthBar3D"
	bar.position = Vector3(0, height + use_offset, 0)
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(width, use_height)
	var bg := MeshInstance3D.new()
	bg.mesh = bg_mesh
	bg.material_override = _make_ui_material(health_bar_back)
	bg.sorting_offset = -0.5
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.add_child(bg)
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(width, use_height)
	var fill := MeshInstance3D.new()
	fill.mesh = fill_mesh
	fill.material_override = _make_ui_material(health_bar_color)
	fill.position = Vector3(0, 0.0, 0.01)
	fill.sorting_offset = 0.5
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.add_child(fill)
	proxy.add_child(bar)
	proxy.set_meta("health_bar_root", bar)
	proxy.set_meta("health_bar_bg", bg)
	proxy.set_meta("health_bar_fill", fill)
	proxy.set_meta("health_bar_width", width)
	proxy.set_meta("health_bar_height", use_height)

func _update_health_bar(node, proxy: Node3D, allow_visible: bool) -> void:
	if not proxy.has_meta("health_bar_root"):
		return
	var bar: Node3D = proxy.get_meta("health_bar_root") as Node3D
	if bar == null:
		return
	var fill: MeshInstance3D = proxy.get_meta("health_bar_fill") as MeshInstance3D
	if fill == null:
		return
	if not allow_visible:
		bar.visible = false
		return
	bar.visible = true
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var xform := bar.global_transform
		xform.basis = camera.global_transform.basis
		bar.global_transform = xform
	var max_hp := float(_get_float(node, "max_hp", 0.0))
	if max_hp <= 0.0:
		bar.visible = false
		return
	var hp := float(_get_float(node, "hp", max_hp))
	var pct := clampf(hp / max_hp, 0.0, 1.0)
	var width: float = float(proxy.get_meta("health_bar_width", 0.0))
	var bar_height: float = float(proxy.get_meta("health_bar_height", health_bar_height))
	if pct <= 0.0:
		bar.visible = false
		return
	fill.visible = true
	var fill_mesh: QuadMesh = fill.mesh as QuadMesh
	if fill_mesh == null:
		fill_mesh = QuadMesh.new()
		fill.mesh = fill_mesh
	fill_mesh.size = Vector2(width * pct, bar_height)
	fill.position = Vector3(-(width - fill_mesh.size.x) * 0.5, 0.0, 0.01)

func _ensure_shot_connection(node: Node, id: int) -> void:
	if _shot_connected.has(id):
		return
	if not node.has_signal("shot_fired"):
		return
	var callable := Callable(self, "_on_unit_shot")
	if node.is_connected("shot_fired", callable):
		_shot_connected[id] = true
		return
	node.connect("shot_fired", callable)
	_shot_connected[id] = true

func _ensure_missile_connection(node: Node, id: int) -> void:
	if _missile_connected.has(id):
		return
	if not node.has_signal("impact"):
		return
	var callable := Callable(self, "_on_missile_impact")
	if node.is_connected("impact", callable):
		_missile_connected[id] = true
		return
	node.connect("impact", callable)
	_missile_connected[id] = true

func _on_unit_shot(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, lifetime: float) -> void:
	_spawn_tracer(start_pos, end_pos, color, width, lifetime)
	_spawn_impact(end_pos, color, width)

func _on_missile_impact(pos: Vector2, color: Color, warhead_size: String, source_kind: String) -> void:
	_spawn_missile_impact(pos, color, warhead_size, source_kind)

func _spawn_tracer(start_pos: Vector2, end_pos: Vector2, color: Color, width: float, lifetime: float) -> void:
	var start_y := tracer_height
	var end_y := tracer_height
	if tracer_follow_terrain:
		start_y += _get_ground_height(start_pos)
		end_y += _get_ground_height(end_pos)
	var start3 := Vector3(start_pos.x, start_y, start_pos.y)
	var end3 := Vector3(end_pos.x, end_y, end_pos.y)
	var delta := end3 - start3
	var line_length := delta.length()
	if line_length <= 0.1:
		return
	var root := Node3D.new()
	add_child(root)
	root.global_position = (start3 + end3) * 0.5
	root.look_at(end3, Vector3.UP)
	var thickness := maxf(tracer_min_width, width * tracer_width_scale)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, thickness, line_length)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := _make_tracer_material(color)
	instance.material_override = material
	root.add_child(instance)
	var tracer: Dictionary = {
		"node": root,
		"material": material,
		"time": 0.0,
		"duration": maxf(0.05, lifetime),
		"alpha": color.a,
	}
	_tracers.append(tracer)

func _update_tracers(delta: float) -> void:
	if _tracers.is_empty():
		return
	var alive: Array[Dictionary] = []
	for tracer in _tracers:
		var node: Node3D = tracer.get("node") as Node3D
		var material: StandardMaterial3D = tracer.get("material") as StandardMaterial3D
		var duration: float = float(tracer.get("duration", 0.0))
		var time: float = float(tracer.get("time", 0.0)) + delta
		if node == null or not is_instance_valid(node) or duration <= 0.0 or time >= duration:
			if node != null and is_instance_valid(node):
				node.queue_free()
			continue
		var alpha: float = float(tracer.get("alpha", 1.0))
		var t := clampf(1.0 - (time / duration), 0.0, 1.0)
		if material != null:
			var col := material.albedo_color
			col.a = alpha * t
			material.albedo_color = col
		tracer["time"] = time
		alive.append(tracer)
	_tracers = alive

func _spawn_impact(end_pos: Vector2, color: Color, width: float) -> void:
	_spawn_impact_custom(end_pos, color, width, impact_flash_duration, impact_flash_size)

func _spawn_missile_impact(end_pos: Vector2, color: Color, warhead_size: String, source_kind: String) -> void:
	var scale: float = _warhead_scale(warhead_size)
	var flash_width: float = missile_impact_flash_size * scale * 6.0
	var flash_color: Color = color.lightened(0.35)
	flash_color.a = clampf(color.a, 0.5, 0.95)
	_spawn_impact_custom(end_pos, flash_color, flash_width, missile_impact_duration, missile_impact_flash_size * scale)
	if source_kind != "aircraft":
		return
	var boost_scale: float = maxf(0.1, aircraft_missile_impact_scale)
	var effect_scale: float = scale * boost_scale
	var hot_color: Color = color.lightened(0.55)
	hot_color.a = clampf(color.a, 0.55, 0.95)
	var hot_width: float = missile_impact_flash_size * effect_scale * 8.5
	_spawn_impact_custom(end_pos, hot_color, hot_width, aircraft_missile_impact_duration, missile_impact_flash_size * effect_scale)
	var shock_color: Color = color.lightened(0.2)
	shock_color.a = clampf(color.a * 0.75, 0.35, 0.85)
	var shock_width: float = aircraft_missile_shockwave_size * effect_scale * 7.5
	_spawn_impact_custom(end_pos, shock_color, shock_width, aircraft_missile_shockwave_duration, aircraft_missile_shockwave_size * effect_scale)
	var impact_y := impact_height
	if impact_follow_terrain:
		impact_y += _get_ground_height(end_pos)
	var smoke_pos := Vector3(end_pos.x, impact_y + 0.25, end_pos.y)
	var burst: int = maxi(0, aircraft_missile_smoke_burst)
	if burst > 0:
		var spread: float = aircraft_missile_smoke_spread * effect_scale
		_spawn_smoke_burst(smoke_pos, burst, aircraft_missile_smoke_color, aircraft_missile_smoke_size * effect_scale, aircraft_missile_smoke_duration, spread)
	_spawn_smoke(smoke_pos, aircraft_missile_smoke_color, aircraft_missile_smoke_size * effect_scale * 1.4, aircraft_missile_smoke_duration * 1.15)

func _spawn_impact_custom(
	end_pos: Vector2,
	color: Color,
	width: float,
	duration: float,
	base_size: float
) -> void:
	if not impact_enabled:
		return
	var root := Node3D.new()
	add_child(root)
	var impact_y := impact_height
	if impact_follow_terrain:
		impact_y += _get_ground_height(end_pos)
	root.global_position = Vector3(end_pos.x, impact_y, end_pos.y)
	var flash_radius := maxf(0.35, base_size + width * 0.15)
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	flash.mesh = sphere
	var flash_color := color.lightened(0.25)
	flash_color.a = clampf(color.a, 0.4, 0.95)
	var material := _make_fx_material(flash_color)
	flash.material_override = material
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(flash)
	root.scale = Vector3.ONE * flash_radius
	var impact: Dictionary = {
		"node": root,
		"material": material,
		"time": 0.0,
		"duration": maxf(0.06, duration),
		"alpha": flash_color.a,
		"start_scale": flash_radius,
	}
	_impacts.append(impact)

func _update_impacts(delta: float) -> void:
	if _impacts.is_empty():
		return
	var alive: Array[Dictionary] = []
	for impact in _impacts:
		var node: Node3D = impact.get("node") as Node3D
		var material: StandardMaterial3D = impact.get("material") as StandardMaterial3D
		var duration: float = float(impact.get("duration", 0.0))
		var time: float = float(impact.get("time", 0.0)) + delta
		if node == null or not is_instance_valid(node) or duration <= 0.0 or time >= duration:
			if node != null and is_instance_valid(node):
				node.queue_free()
			continue
		var alpha: float = float(impact.get("alpha", 1.0))
		var t := clampf(1.0 - (time / duration), 0.0, 1.0)
		if material != null:
			var col := material.albedo_color
			col.a = alpha * t
			material.albedo_color = col
		var start_scale := float(impact.get("start_scale", 1.0))
		var scale := start_scale * (0.7 + t * 0.3)
		node.scale = Vector3.ONE * scale
		impact["time"] = time
		alive.append(impact)
	_impacts = alive

func _spawn_smoke(pos: Vector3, color: Color, size: float, duration: float) -> void:
	if duration <= 0.0:
		return
	var root := Node3D.new()
	add_child(root)
	root.global_position = pos
	var puff := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	puff.mesh = sphere
	var smoke_color := color
	smoke_color.a = clampf(smoke_color.a, 0.1, 0.9)
	var material := _make_fx_material(smoke_color)
	puff.material_override = material
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(puff)
	root.scale = Vector3.ONE * maxf(0.1, size)
	var smoke: Dictionary = {
		"node": root,
		"material": material,
		"time": 0.0,
		"duration": duration,
		"alpha": smoke_color.a,
		"start_scale": maxf(0.1, size),
	}
	_smokes.append(smoke)

func _spawn_smoke_burst(pos: Vector3, count: int, color: Color, size: float, duration: float, spread: float) -> void:
	if count <= 0 or duration <= 0.0:
		return
	var spread_radius: float = maxf(0.0, spread)
	for i in range(count):
		var offset := Vector3.ZERO
		if spread_radius > 0.0:
			offset = Vector3(
				_smoke_rng.randf_range(-spread_radius, spread_radius),
				_smoke_rng.randf_range(-spread_radius, spread_radius) * 0.2,
				_smoke_rng.randf_range(-spread_radius, spread_radius)
			)
		_spawn_smoke(pos + offset, color, size, duration)

func _update_smokes(delta: float) -> void:
	if _smokes.is_empty():
		return
	var alive: Array[Dictionary] = []
	for smoke in _smokes:
		var node: Node3D = smoke.get("node") as Node3D
		var material: StandardMaterial3D = smoke.get("material") as StandardMaterial3D
		var duration: float = float(smoke.get("duration", 0.0))
		var time: float = float(smoke.get("time", 0.0)) + delta
		if node == null or not is_instance_valid(node) or duration <= 0.0 or time >= duration:
			if node != null and is_instance_valid(node):
				node.queue_free()
			continue
		var alpha: float = float(smoke.get("alpha", 1.0))
		var t := clampf(time / duration, 0.0, 1.0)
		if material != null:
			var col := material.albedo_color
			col.a = alpha * (1.0 - t)
			material.albedo_color = col
		var start_scale := float(smoke.get("start_scale", 1.0))
		var end_scale := start_scale * maxf(1.0, missile_smoke_grow)
		var scale := lerpf(start_scale, end_scale, t)
		node.scale = Vector3.ONE * scale
		smoke["time"] = time
		alive.append(smoke)
	_smokes = alive

func _update_missile_trail(missile, proxy: Node3D, id: int) -> void:
	if not missile_smoke_enabled:
		return
	var info: Dictionary = _missile_trails.get(id, {})
	var timer := float(info.get("timer", 0.0)) - _frame_delta
	if timer > 0.0:
		info["timer"] = timer
		_missile_trails[id] = info
		return
	info["timer"] = maxf(0.01, missile_smoke_interval)
	_missile_trails[id] = info
	var scale := _get_missile_scale(missile)
	if not missile_smoke_use_warhead_scale:
		scale = 1.0
	var pos := proxy.global_position
	var velocity: Variant = missile.get("_velocity")
	if velocity is Vector2 and velocity.length() > 0.1:
		var back := Vector3(-velocity.x, 0.0, -velocity.y).normalized()
		pos += back * (missile_body_length * 0.3 * scale)
	if missile_smoke_spread > 0.0:
		var jitter := Vector3(
			_smoke_rng.randf_range(-missile_smoke_spread, missile_smoke_spread),
			_smoke_rng.randf_range(-missile_smoke_spread, missile_smoke_spread) * 0.4,
			_smoke_rng.randf_range(-missile_smoke_spread, missile_smoke_spread)
		)
		pos += jitter
	pos.y += missile_smoke_height_offset
	_spawn_smoke(pos, missile_smoke_color, missile_smoke_size * scale, missile_smoke_duration)

func _update_build_ghost() -> void:
	if not show_build_ghost:
		_set_ghost_visible(false)
		return
	var controller := get_node_or_null(build_controller_path)
	if controller == null or not controller.has_method("get_ghost_state"):
		_set_ghost_visible(false)
		return
	var state: Dictionary = controller.get_ghost_state()
	if state.is_empty():
		_set_ghost_visible(false)
		return
	var size_value: Variant = state.get("size", Vector2.ZERO)
	if size_value is not Vector2 or size_value == Vector2.ZERO:
		_set_ghost_visible(false)
		return
	var pos_value: Variant = state.get("pos", Vector2.ZERO)
	if pos_value is not Vector2:
		_set_ghost_visible(false)
		return
	var size: Vector2 = size_value
	var pos: Vector2 = pos_value
	_ensure_ghost()
	_ghost_root.visible = true
	var base_y := _get_ground_height(pos)
	_ghost_root.position = Vector3(pos.x, base_y + (ghost_height * 0.5) + ghost_y_offset, pos.y)
	var box: BoxMesh = _ghost_mesh.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		_ghost_mesh.mesh = box
	box.size = Vector3(size.x, ghost_height, size.y)
	var valid := bool(state.get("valid", false))
	_ghost_mesh.material_override = _ghost_mat_valid if valid else _ghost_mat_invalid

func _ensure_ghost() -> void:
	if _ghost_root != null and is_instance_valid(_ghost_root):
		return
	_ghost_root = Node3D.new()
	_ghost_root.name = "BuildGhost3D"
	add_child(_ghost_root)
	_ghost_mesh = MeshInstance3D.new()
	_ghost_mesh.mesh = BoxMesh.new()
	_ghost_root.add_child(_ghost_mesh)
	_ghost_mat_valid = _make_ghost_material(ghost_valid_color)
	_ghost_mat_invalid = _make_ghost_material(ghost_invalid_color)

func _set_ghost_visible(value: bool) -> void:
	if _ghost_root != null and is_instance_valid(_ghost_root):
		_ghost_root.visible = value

func _update_build_zone() -> void:
	if not show_build_zone:
		_set_build_zone_visible(false)
		_set_build_zone_outline_visible(false)
		return
	_ensure_map_data()
	if _map_size == Vector2.ZERO:
		_set_build_zone_visible(false)
		_set_build_zone_outline_visible(false)
		return
	var rect_value: Variant = _build_zones.get(build_zone_team_id, null)
	if rect_value is not Rect2:
		_set_build_zone_visible(false)
		_set_build_zone_outline_visible(false)
		return
	var rect: Rect2 = rect_value
	_ensure_build_zone()
	_build_zone_root.visible = true
	var center := rect.position + rect.size * 0.5
	var base_y := _get_ground_height(center)
	_build_zone_root.position = Vector3(center.x, base_y + build_zone_y_offset + (build_zone_height * 0.5), center.y)
	var box: BoxMesh = _build_zone_mesh.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		_build_zone_mesh.mesh = box
	box.size = Vector3(rect.size.x, build_zone_height, rect.size.y)
	if _build_zone_material != null:
		_build_zone_mesh.material_override = _build_zone_material
	_update_build_zone_outline(rect)

func _ensure_build_zone() -> void:
	if _build_zone_root != null and is_instance_valid(_build_zone_root):
		return
	_build_zone_root = Node3D.new()
	_build_zone_root.name = "BuildZone3D"
	add_child(_build_zone_root)
	_build_zone_mesh = MeshInstance3D.new()
	_build_zone_mesh.mesh = BoxMesh.new()
	_build_zone_root.add_child(_build_zone_mesh)
	_build_zone_material = _make_zone_material(build_zone_color)

func _set_build_zone_visible(value: bool) -> void:
	if _build_zone_root != null and is_instance_valid(_build_zone_root):
		_build_zone_root.visible = value

func _update_build_zone_outline(rect: Rect2) -> void:
	if not show_build_zone_outline:
		_set_build_zone_outline_visible(false)
		return
	_ensure_build_zone_outline()
	if _build_zone_outline_root == null:
		return
	_build_zone_outline_root.visible = true
	var center := rect.position + rect.size * 0.5
	var base_y := _get_ground_height(center)
	var y := base_y + build_zone_outline_y_offset + (build_zone_outline_height * 0.5)
	var half_w := rect.size.x * 0.5
	var half_h := rect.size.y * 0.5
	var edge_w := build_zone_outline_width
	var edge_h := build_zone_outline_height
	var top_z := rect.position.y + (edge_w * 0.5)
	var bottom_z := rect.position.y + rect.size.y - (edge_w * 0.5)
	var left_x := rect.position.x + (edge_w * 0.5)
	var right_x := rect.position.x + rect.size.x - (edge_w * 0.5)
	_set_outline_edge(0, Vector3(center.x, y, top_z), Vector3(rect.size.x, edge_h, edge_w))
	_set_outline_edge(1, Vector3(center.x, y, bottom_z), Vector3(rect.size.x, edge_h, edge_w))
	_set_outline_edge(2, Vector3(left_x, y, center.y), Vector3(edge_w, edge_h, rect.size.y))
	_set_outline_edge(3, Vector3(right_x, y, center.y), Vector3(edge_w, edge_h, rect.size.y))

func _ensure_build_zone_outline() -> void:
	if _build_zone_outline_root != null and is_instance_valid(_build_zone_outline_root):
		return
	_build_zone_outline_root = Node3D.new()
	_build_zone_outline_root.name = "BuildZoneOutline3D"
	add_child(_build_zone_outline_root)
	_build_zone_outline_edges.clear()
	for _i in range(4):
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.material_override = _make_zone_material(build_zone_outline_color)
		_build_zone_outline_root.add_child(mesh_instance)
		_build_zone_outline_edges.append(mesh_instance)

func _set_outline_edge(index: int, pos: Vector3, size: Vector3) -> void:
	if index < 0 or index >= _build_zone_outline_edges.size():
		return
	var mesh_instance: MeshInstance3D = _build_zone_outline_edges[index]
	if mesh_instance == null:
		return
	mesh_instance.position = pos
	var box: BoxMesh = mesh_instance.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		mesh_instance.mesh = box
	box.size = size

func _set_build_zone_outline_visible(value: bool) -> void:
	if _build_zone_outline_root != null and is_instance_valid(_build_zone_outline_root):
		_build_zone_outline_root.visible = value

func _update_fog_of_war(delta: float) -> void:
	if not show_fog_of_war:
		_set_fog_visible(false)
		return
	_ensure_map_data()
	if _map_size == Vector2.ZERO:
		_set_fog_visible(false)
		return
	_ensure_fog_plane()
	_fog_root.visible = true
	if _fog_mesh != null and is_instance_valid(_fog_mesh):
		_fog_mesh.position = Vector3(_map_size.x * 0.5, _get_ground_max_height() + fog_y_offset + fog_height_extra, _map_size.y * 0.5)
	_fog_timer += delta
	if _fog_timer < fog_update_interval:
		return
	_fog_timer = 0.0
	_render_fog_texture()

func _ensure_fog_plane() -> void:
	if _fog_root != null and is_instance_valid(_fog_root):
		return
	_fog_root = Node3D.new()
	_fog_root.name = "FogOfWar3D"
	add_child(_fog_root)
	_fog_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = _map_size
	_fog_mesh.mesh = plane
	_fog_mesh.position = Vector3(_map_size.x * 0.5, _get_ground_max_height() + fog_y_offset + fog_height_extra, _map_size.y * 0.5)
	_fog_root.add_child(_fog_mesh)
	_fog_material = _make_fog_material(Color(1.0, 1.0, 1.0, 1.0))
	_fog_mesh.material_override = _fog_material
	_fog_image = Image.create(fog_texture_size.x, fog_texture_size.y, false, Image.FORMAT_RGBA8)
	_fog_image.fill(fog_color)
	_fog_texture = ImageTexture.create_from_image(_fog_image)
	_fog_material.albedo_texture = _fog_texture

func _set_fog_visible(value: bool) -> void:
	if _fog_root != null and is_instance_valid(_fog_root):
		_fog_root.visible = value

func _render_fog_texture() -> void:
	if _fog_image == null or _fog_texture == null:
		return
	_fog_image.fill(fog_color)
	var tex_w := fog_texture_size.x
	var tex_h := fog_texture_size.y
	if tex_w <= 1 or tex_h <= 1:
		return
	var map_w := maxf(1.0, _map_size.x)
	var map_h := maxf(1.0, _map_size.y)
	var base_r := fog_color.r
	var base_g := fog_color.g
	var base_b := fog_color.b
	var base_a := fog_color.a
	var edge := clampf(1.0 - fog_softness, 0.0, 1.0)
	for node in get_tree().get_nodes_in_group(fog_vision_group):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_vision_radius"):
			continue
		if node is not Node2D:
			continue
		var pos2d: Vector2 = node.global_position
		var radius := float(node.get_vision_radius())
		if radius <= 0.0:
			continue
		var cx := int(clampf((pos2d.x / map_w) * float(tex_w - 1), 0.0, float(tex_w - 1)))
		var cy := int(clampf((pos2d.y / map_h) * float(tex_h - 1), 0.0, float(tex_h - 1)))
		var rx := int(maxf(1.0, (radius / map_w) * float(tex_w)))
		var ry := int(maxf(1.0, (radius / map_h) * float(tex_h)))
		var y0 := maxi(0, cy - ry)
		var y1 := mini(tex_h - 1, cy + ry)
		var x0 := maxi(0, cx - rx)
		var x1 := mini(tex_w - 1, cx + rx)
		for y in range(y0, y1 + 1):
			var dy := float(y - cy) / float(ry)
			var dy2 := dy * dy
			for x in range(x0, x1 + 1):
				var dx := float(x - cx) / float(rx)
				var dist := sqrt(dx * dx + dy2)
				if dist > 1.0:
					continue
				var alpha := 0.0
				if dist > edge:
					var t := (dist - edge) / maxf(0.0001, (1.0 - edge))
					alpha = base_a * clampf(t, 0.0, 1.0)
				var current := _fog_image.get_pixel(x, y)
				if alpha < current.a:
					_fog_image.set_pixel(x, y, Color(base_r, base_g, base_b, alpha))
	_fog_texture.update(_fog_image)

func _ensure_map_data() -> void:
	if _map_loaded:
		return
	_map_loaded = true
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var size_data: Dictionary = data.get("size", {})
	_map_size = Vector2(float(size_data.get("width", 0.0)), float(size_data.get("height", 0.0)))
	_build_zones.clear()
	var zones: Array = data.get("build_zones", [])
	for zone in zones:
		if typeof(zone) != TYPE_DICTIONARY:
			continue
		var zone_id := str(zone.get("id", ""))
		var rect := Rect2(
			Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))),
			Vector2(float(zone.get("width", 0.0)), float(zone.get("height", 0.0)))
		)
		_build_zones[zone_id] = rect

func _get_color(node, property: String, fallback: Color) -> Color:
	var value: Variant = node.get(property)
	return value if value is Color else fallback

func _get_float(node, property: String, fallback: float) -> float:
	var value: Variant = node.get(property)
	return float(value) if value is float or value is int else fallback

func _get_vec2(node, property: String, fallback: Vector2) -> Vector2:
	var value: Variant = node.get(property)
	return value if value is Vector2 else fallback

func _get_value(node, property: String, fallback):
	var value: Variant = node.get(property)
	return value if value != null else fallback

func _get_missile_scale(missile) -> float:
	var size := str(_get_value(missile, "warhead_size", "medium")).to_lower()
	return _warhead_scale(size)

func _warhead_scale(size: String) -> float:
	match size:
		"small":
			return missile_small_scale
		"large":
			return missile_large_scale
	return missile_medium_scale

func _disable_2d_render(node) -> void:
	if node.has_method("set_render_2d"):
		node.set_render_2d(false)

func _disable_map_render() -> void:
	for node in get_tree().get_nodes_in_group("map_loader"):
		_disable_2d_render(node)
