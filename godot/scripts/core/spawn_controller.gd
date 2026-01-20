class_name SpawnController
extends Node

## Spawn Controller
##
## Handles spawning of units and buildings.
## Extracted from game_controller.gd for better organization.

signal unit_spawned(unit: Unit, team_id: String, unit_kind: String)
signal building_spawned(building: Building, team_id: String, build_id: String)
signal collector_spawned(collector: Collector, team_id: String)

var _units_container: Node2D
var _structures_container: Node2D
var _rng := RandomNumberGenerator.new()

# References set by GameController
var _teams: Dictionary  # team_id -> TeamState

func _ready() -> void:
	_rng.randomize()

func configure(units_container: Node2D, structures_container: Node2D, teams: Dictionary) -> void:
	_units_container = units_container
	_structures_container = structures_container
	_teams = teams

func get_team(team_id: String) -> TeamState:
	return _teams.get(team_id)

# =============================================================================
# UNIT SPAWNING
# =============================================================================

func spawn_unit(team_id: String, unit_kind: String, source_building: Building = null, unit_type_id: String = "") -> Unit:
	var team := get_team(team_id)
	if team == null:
		return null

	var unit := Unit.new()
	unit.team_id = team_id
	unit.home_pos = team.start_pos

	match unit_kind:
		"vehicle":
			_configure_vehicle(unit, team, source_building, unit_type_id)
		"aircraft":
			_configure_aircraft(unit, team, source_building, unit_type_id)
		_:  # infantry
			_configure_infantry(unit, team, source_building, unit_type_id)

	# Set enemy HQ
	var enemy_team := get_team(team.get_enemy_team_id())
	if enemy_team != null:
		unit.enemy_hq = enemy_team.hq

	# Set rally target for infantry and aircraft (vehicles set it in _configure_vehicle)
	if unit_kind != "vehicle":
		unit.rally_target = team.rally_pos

	_units_container.add_child(unit)
	unit_spawned.emit(unit, team_id, unit_kind)
	return unit

func _configure_infantry(unit: Unit, team: TeamState, barracks: Building, type_id: String) -> void:
	var production_type := "mixed"
	var wait_mode := false
	var spawn_origin := team.start_pos

	if barracks != null and is_instance_valid(barracks):
		production_type = barracks.production_type
		wait_mode = barracks.wait_mode
		spawn_origin = barracks.global_position

	var resolved_type := UnitDefinitions.resolve_infantry_type(production_type if type_id == "" else type_id, _rng)
	var stats := UnitDefinitions.get_infantry_def(resolved_type)
	var range_role := str(stats.get("range_role", "short"))
	var range_mult := UnitDefinitions.get_range_multiplier(range_role, GameBalance.INFANTRY_LONG_MULTIPLIER, GameBalance.INFANTRY_MID_MULTIPLIER)
	var attack_range := GameBalance.INFANTRY_ATTACK_RANGE * range_mult

	unit.unit_kind = "infantry"
	unit.unit_type = resolved_type
	unit.range_role = range_role
	unit.range_multiplier = range_mult
	unit.prefers_vehicle = bool(stats.get("prefers_vehicle", false))
	unit.prefers_infantry = bool(stats.get("prefers_infantry", false))
	unit.damage_vs_infantry = float(stats.get("damage_vs_infantry", 1.0))
	unit.damage_vs_vehicle = float(stats.get("damage_vs_vehicle", 1.0))
	unit.damage_vs_structure = float(stats.get("damage_vs_structure", 1.0))
	unit.speed = float(stats.get("speed", GameBalance.INFANTRY_SPEED))
	unit.max_hp = float(stats.get("max_hp", GameBalance.INFANTRY_MAX_HP))
	unit.attack_damage = float(stats.get("damage", GameBalance.INFANTRY_DAMAGE))
	unit.attack_range = attack_range
	unit.attack_cooldown = float(stats.get("cooldown", GameBalance.INFANTRY_ATTACK_COOLDOWN))
	unit.body_radius = GameBalance.INFANTRY_BODY_RADIUS
	unit.color = team.get_unit_color()
	unit.aggro_range = maxf(220.0, attack_range * 1.05)
	unit.chase_leash = maxf(320.0, attack_range * 1.1)
	unit.structure_aggro_range = maxf(260.0, attack_range * 1.1)
	unit.shot_width = float(stats.get("shot_width", 2.0))
	unit.shot_lifetime = float(stats.get("shot_lifetime", 0.12))
	var shot_color = stats.get("shot_color", Color(1.0, 1.0, 1.0, 0.75))
	if shot_color is Color:
		unit.shot_color = shot_color

	unit.position = _spawn_at_barracks(team, barracks)

	if wait_mode:
		var wait_pos := _get_wait_point(team, spawn_origin)
		unit.assign_hold(wait_pos, GameBalance.INFANTRY_WAIT_DURATION)

	unit.visual_scene_path = VisualPaths.get_unit_visual_path("infantry")
	unit.visual_base_radius = 8.0

func _configure_vehicle(unit: Unit, team: TeamState, factory: Building, type_id: String) -> void:
	var production_type := type_id
	if production_type == "" and factory != null and is_instance_valid(factory):
		production_type = factory.vehicle_production_type

	var resolved_type := UnitDefinitions.resolve_vehicle_type(production_type, _rng)
	print("[SPAWN] Spawning vehicle: production_type='", production_type, "' resolved_type='", resolved_type, "'")
	var stats := UnitDefinitions.get_vehicle_def(resolved_type)
	var range_role := str(stats.get("range_role", "short"))
	var range_mult := UnitDefinitions.get_range_multiplier(range_role, GameBalance.VEHICLE_LONG_MULTIPLIER, GameBalance.VEHICLE_MID_MULTIPLIER)
	var attack_range := GameBalance.VEHICLE_ATTACK_RANGE * range_mult

	unit.unit_kind = "vehicle"
	unit.unit_type = resolved_type
	unit.range_role = range_role
	unit.range_multiplier = range_mult
	unit.prefers_vehicle = bool(stats.get("prefers_vehicle", false))
	unit.prefers_infantry = bool(stats.get("prefers_infantry", false))
	unit.damage_vs_infantry = float(stats.get("damage_vs_infantry", 1.0))
	unit.damage_vs_vehicle = float(stats.get("damage_vs_vehicle", 1.0))
	unit.damage_vs_structure = float(stats.get("damage_vs_structure", 1.0))
	unit.speed = float(stats.get("speed", GameBalance.VEHICLE_SPEED))
	unit.max_hp = float(stats.get("max_hp", GameBalance.VEHICLE_MAX_HP))
	unit.attack_damage = float(stats.get("damage", GameBalance.VEHICLE_DAMAGE))
	unit.attack_range = attack_range
	unit.attack_cooldown = float(stats.get("cooldown", GameBalance.VEHICLE_ATTACK_COOLDOWN))
	unit.body_radius = float(stats.get("body_radius", GameBalance.VEHICLE_BODY_RADIUS))
	unit.color = team.get_vehicle_color()
	unit.aggro_range = maxf(260.0, attack_range * 1.05)
	unit.chase_leash = maxf(360.0, attack_range * 1.1)
	unit.structure_aggro_range = maxf(320.0, attack_range * 1.1)
	unit.shot_width = float(stats.get("shot_width", 3.0))
	unit.shot_lifetime = float(stats.get("shot_lifetime", 0.14))
	var shot_color = stats.get("shot_color", Color(1.0, 0.8, 0.5, 0.8))
	if shot_color is Color:
		unit.shot_color = shot_color
	unit.vehicle_turn_rate = float(stats.get("turn_rate", 3.0))

	var spawn_pos := _spawn_at_factory(team, factory)
	unit.position = spawn_pos

	# Check if vehicle def has custom visual path (e.g., HIMARS)
	var custom_visual_path = stats.get("visual_scene_path", "")
	if custom_visual_path != "":
		unit.visual_scene_path = str(custom_visual_path)
		unit.visual_base_radius = float(stats.get("visual_base_radius", 14.0))
	else:
		unit.visual_scene_path = VisualPaths.get_unit_visual_path("vehicle")
		unit.visual_base_radius = 14.0

	# Set HIMARS-specific properties
	if bool(stats.get("is_himars", false)):
		unit.is_himars = true
		unit.vision_radius = float(stats.get("vision_radius", GameBalance.HIMARS_VISION_RADIUS))
		unit.bombardment_range = float(stats.get("bombardment_range", GameBalance.HIMARS_BOMBARDMENT_RANGE))
		unit.bombardment_missile_damage = float(stats.get("missile_damage", GameBalance.HIMARS_MISSILE_DAMAGE))
		unit.bombardment_missile_speed = float(stats.get("missile_speed", GameBalance.HIMARS_MISSILE_SPEED))
		unit.bombardment_missile_lifetime = float(stats.get("missile_lifetime", GameBalance.HIMARS_MISSILE_LIFETIME))
		unit.bombardment_missile_splash_radius = float(stats.get("missile_splash_radius", GameBalance.HIMARS_MISSILE_SPLASH_RADIUS))
		unit.bombardment_missiles_per_salvo = int(stats.get("missiles_per_salvo", GameBalance.HIMARS_MISSILES_PER_SALVO))
		unit.bombardment_salvo_interval = float(stats.get("salvo_interval", GameBalance.HIMARS_SALVO_INTERVAL))
		unit.bombardment_reload_time = float(stats.get("reload_time", GameBalance.HIMARS_RELOAD_TIME))

	# HIMARS always drives forward 200 units and stops, normal vehicles use rally
	var forward_dir := Vector2(1.0, 0.0) if team.team_id == "p1" else Vector2(-1.0, 0.0)
	unit.rally_target = spawn_pos + forward_dir * 200.0

func _configure_aircraft(unit: Unit, team: TeamState, airfield: Building, type_id: String) -> void:
	var resolved_type := UnitDefinitions.resolve_aircraft_type(type_id)
	var stats := UnitDefinitions.get_aircraft_def(resolved_type)
	var range_role := str(stats.get("range_role", "long"))
	var range_mult := float(stats.get("range_multiplier", 1.0))
	var attack_range := float(stats.get("attack_range", GameBalance.AIRCRAFT_GUN_ATTACK_RANGE)) * range_mult

	unit.unit_kind = "aircraft"
	unit.unit_type = resolved_type
	unit.range_role = range_role
	unit.range_multiplier = range_mult
	unit.prefers_vehicle = bool(stats.get("prefers_vehicle", true))
	unit.prefers_infantry = bool(stats.get("prefers_infantry", false))
	unit.damage_vs_infantry = float(stats.get("damage_vs_infantry", 0.6))
	unit.damage_vs_vehicle = float(stats.get("damage_vs_vehicle", 1.6))
	unit.damage_vs_structure = float(stats.get("damage_vs_structure", 1.0))
	unit.speed = float(stats.get("speed", GameBalance.AIRCRAFT_SPEED))
	unit.max_hp = float(stats.get("max_hp", GameBalance.AIRCRAFT_MAX_HP))
	unit.attack_damage = float(stats.get("damage", GameBalance.AIRCRAFT_GUN_DAMAGE))
	unit.attack_range = attack_range
	unit.attack_cooldown = float(stats.get("cooldown", GameBalance.AIRCRAFT_GUN_ATTACK_COOLDOWN))
	unit.body_radius = float(stats.get("body_radius", GameBalance.AIRCRAFT_BODY_RADIUS))
	unit.vision_radius = float(stats.get("vision_radius", GameBalance.AIRCRAFT_VISION_RADIUS))
	unit.color = team.get_aircraft_color()
	unit.aggro_range = maxf(320.0, attack_range * 1.1)
	unit.chase_leash = maxf(420.0, attack_range * 1.2)
	unit.structure_aggro_range = maxf(360.0, attack_range * 1.15)
	unit.shot_width = float(stats.get("shot_width", GameBalance.AIRCRAFT_SHOT_WIDTH))
	unit.shot_lifetime = float(stats.get("shot_lifetime", GameBalance.AIRCRAFT_SHOT_LIFETIME))
	var shot_color = stats.get("shot_color", Color(1.0, 0.9, 0.8, 0.8))
	if shot_color is Color:
		unit.shot_color = shot_color

	# Aircraft ammo and missiles
	unit.aircraft_gun_capacity = int(stats.get("gun_ammo", GameBalance.AIRCRAFT_GUN_CAPACITY))
	unit.aircraft_gun_ammo = unit.aircraft_gun_capacity
	unit.aircraft_missile_capacity = int(stats.get("missile_ammo", GameBalance.AIRCRAFT_MISSILE_CAPACITY))
	unit.aircraft_missile_ammo = unit.aircraft_missile_capacity
	unit.aircraft_reload_time = float(stats.get("reload_time", GameBalance.AIRCRAFT_RELOAD_TIME))
	unit.aircraft_missile_damage = float(stats.get("missile_damage", GameBalance.AIRCRAFT_MISSILE_DAMAGE))
	unit.aircraft_missile_speed = float(stats.get("missile_speed", GameBalance.AIRCRAFT_MISSILE_SPEED))
	unit.aircraft_missile_turn_rate = float(stats.get("missile_turn_rate", GameBalance.AIRCRAFT_MISSILE_TURN_RATE))
	unit.aircraft_missile_range = float(stats.get("missile_range", GameBalance.AIRCRAFT_MISSILE_RANGE))
	unit.aircraft_missile_cooldown = float(stats.get("missile_cooldown", GameBalance.AIRCRAFT_MISSILE_COOLDOWN))
	unit.aircraft_missile_hit_radius = float(stats.get("missile_hit_radius", GameBalance.AIRCRAFT_MISSILE_HIT_RADIUS))
	unit.aircraft_missile_warhead_size = str(stats.get("missile_warhead_size", "large"))
	unit.aircraft_missile_splash_radius = float(stats.get("missile_splash_radius", GameBalance.AIRCRAFT_MISSILE_SPLASH_RADIUS))
	unit.aircraft_missile_splash_scale = float(stats.get("missile_splash_scale", GameBalance.AIRCRAFT_MISSILE_SPLASH_SCALE))
	unit.aircraft_missile_lifetime = float(stats.get("missile_lifetime", GameBalance.AIRCRAFT_MISSILE_LIFETIME))
	unit.aircraft_landing_cap = GameBalance.AIRCRAFT_LANDING_CAP
	var missile_color = stats.get("missile_color", Color(1.0, 0.55, 0.25, 1.0))
	if missile_color is Color:
		unit.aircraft_missile_color = missile_color

	# Set airfield home
	if airfield != null and is_instance_valid(airfield):
		unit.aircraft_home = airfield
		unit.aircraft_home_pos = airfield.global_position
		if airfield.has_meta("_spawn_slot_reserved"):
			var slot_id := int(airfield.get_meta("_spawn_slot_temp", -1))
			print("[Spawn] Airfield has reserved slot: ", slot_id)
			if slot_id >= 0:
				unit._aircraft_landing_slot = slot_id
				unit._aircraft_landing_reserved = true
				print("[Spawn] Assigned slot ", slot_id, " to aircraft BEFORE _ready")
	else:
		unit.aircraft_home = null
		unit.aircraft_home_pos = team.start_pos

	unit.position = _spawn_at_airfield(team, airfield)
	unit.visual_scene_path = VisualPaths.get_unit_visual_path("aircraft", resolved_type)
	unit.visual_base_radius = 20.0
	unit.missile_visual_path = VisualPaths.get_missile_visual_path(resolved_type, "ground")

	# Set UAV flag if this is a UAV
	if stats.get("is_uav", false):
		unit.is_uav = true
		unit.aircraft_loiter_radius = float(stats.get("loiter_radius", GameBalance.UAV_LOITER_RADIUS))
		unit.aircraft_loiter_orbit_speed = float(stats.get("loiter_orbit_speed", GameBalance.UAV_LOITER_ORBIT_SPEED))
		print("[UAV] Spawned UAV with vision_radius: ", unit.vision_radius, " loiter_radius: ", unit.aircraft_loiter_radius)

# =============================================================================
# SPAWN POSITION HELPERS
# =============================================================================

func _spawn_at_barracks(team: TeamState, barracks: Building = null) -> Vector2:
	if barracks != null and is_instance_valid(barracks):
		return _offset_spawn(barracks.global_position)
	return _spawn_at_building(team, "barracks", team.start_pos)

func _spawn_at_factory(team: TeamState, factory: Building = null) -> Vector2:
	if factory != null and is_instance_valid(factory):
		return _offset_spawn(factory.global_position)
	return _spawn_at_building(team, "factory", team.start_pos)

func _spawn_at_airfield(team: TeamState, airfield: Building = null) -> Vector2:
	if airfield != null and is_instance_valid(airfield):
		var runway_dir := Vector2(1.0, 0.0) if team.team_id == "p1" else Vector2(-1.0, 0.0)
		var size_value: Variant = airfield.get("size")
		var size2d: Vector2 = size_value if size_value is Vector2 else Vector2.ZERO

		var offset_ratio := 0.0
		var lateral := Vector2(-runway_dir.y, runway_dir.x).normalized()
		var runway_offset: Vector2 = lateral * (size2d.y * offset_ratio) if size2d != Vector2.ZERO else Vector2.ZERO
		var runway_start: Vector2 = airfield.global_position + runway_offset
		if size2d != Vector2.ZERO:
			runway_start = airfield.global_position - (runway_dir * (size2d.x * 0.5)) + runway_offset

		var slot_index := int(airfield.get_meta("_spawn_slot_temp", 0))
		var spacing := 32.0
		var center_index := 1.5
		var offset_amount := (float(slot_index) - center_index) * spacing
		var lateral_offset := lateral * offset_amount

		return runway_start + lateral_offset
	return _spawn_at_building(team, "airfield", team.start_pos)

func _spawn_at_building(team: TeamState, build_id: String, fallback: Vector2) -> Vector2:
	var group_name := "building_%s_%s" % [build_id, team.team_id]
	var buildings := get_tree().get_nodes_in_group(group_name)
	if buildings.is_empty():
		return _offset_spawn(fallback)
	var index := _rng.randi_range(0, buildings.size() - 1)
	var building := buildings[index] as Node2D
	if building == null:
		return _offset_spawn(fallback)
	return _offset_spawn(building.global_position)

func _offset_spawn(pos: Vector2) -> Vector2:
	return pos + Vector2(
		_rng.randf_range(-GameBalance.UNIT_SPAWN_SPREAD, GameBalance.UNIT_SPAWN_SPREAD),
		_rng.randf_range(-GameBalance.UNIT_SPAWN_SPREAD, GameBalance.UNIT_SPAWN_SPREAD)
	)

func _get_wait_point(team: TeamState, origin: Vector2) -> Vector2:
	var zone := team.build_zone
	var enemy_team := get_team(team.get_enemy_team_id())
	var enemy_pos := enemy_team.start_pos if enemy_team != null else Vector2.ZERO

	if zone == Rect2():
		var dir := (enemy_pos - origin).normalized()
		return origin + dir * 120.0

	var edge_x := zone.position.x + zone.size.x if enemy_pos.x >= origin.x else zone.position.x
	var pad := maxf(0.0, 12.0)  # wait_edge_padding
	var inside_x := edge_x - pad if enemy_pos.x >= origin.x else edge_x + pad
	var min_y := zone.position.y + pad
	var max_y := zone.position.y + zone.size.y - pad
	var clamped_y := clampf(origin.y, min_y, max_y)
	return Vector2(inside_x, clamped_y)

# =============================================================================
# BUILDING SPAWNING
# =============================================================================

func spawn_building(team_id: String, build_id: String, pos: Vector2) -> Building:
	var team := get_team(team_id)
	if team == null:
		return null

	var building := Building.new()
	building.team_id = team_id
	building.build_id = build_id
	building.visual_scene_path = VisualPaths.get_building_visual_path(build_id)
	building.visual_base_size = BuildingDefinitions.get_building_visual_base_size(build_id)
	building.size = BuildingDefinitions.get_building_size(build_id)
	building.fill_color = BuildingDefinitions.get_building_color(build_id, team.get_hq_color())
	building.max_hp = BuildingDefinitions.get_building_hp(build_id)

	# Type-specific configuration
	match build_id:
		"barracks":
			building.production_type = "mixed"
			building.wait_mode = false
		"factory":
			building.vehicle_production_type = "mixed"
		"airfield":
			building.set_meta("aircraft_tier", "f16")
			building.set_meta("aircraft_active", 0)
			building.set_meta("aircraft_landing", 0)
			building.aircraft_production_type = "fighter"

	building.position = pos
	_structures_container.add_child(building)
	_increment_building_count(team_id, build_id)
	building_spawned.emit(building, team_id, build_id)
	return building

func spawn_hq(team: TeamState) -> HQ:
	var hq := HQ.new()
	hq.team_id = team.team_id
	hq.visual_scene_path = VisualPaths.get_hq_visual_path()
	hq.visual_base_size = BuildingDefinitions.get_hq_visual_base_size()
	hq.position = team.start_pos
	hq.size = BuildingDefinitions.get_hq_size()
	hq.max_hp = BuildingDefinitions.get_hq_hp()
	hq.fill_color = team.get_hq_color()
	_structures_container.add_child(hq)
	team.hq = hq
	return hq

func spawn_defense_turret(team_id: String, pos: Vector2, build_id: String = "defense") -> DefenseTurret:
	var team := get_team(team_id)
	if team == null:
		return null

	var turret := DefenseTurret.new()
	turret.team_id = team_id
	var profile := BuildingDefinitions.get_defense_profile(build_id)

	var base_range := float(profile.get("range", 260.0)) * 1.5  # defense_range_multiplier
	turret.attack_range = _compute_defense_range(team, pos, base_range)
	turret.damage = float(profile.get("damage", 10.0))
	turret.fire_rate = float(profile.get("fire_rate", 0.8)) * 0.75  # defense_fire_rate_multiplier
	turret.missile_speed = float(profile.get("missile_speed", 260.0))
	turret.missile_turn_rate = float(profile.get("missile_turn_rate", 10.0))
	var missile_color = profile.get("missile_color")
	if missile_color is Color:
		turret.missile_color = missile_color
	turret.missile_warhead_size = str(profile.get("warhead_size", "medium"))
	turret.prefers_infantry = bool(profile.get("prefers_infantry", false))
	turret.prefers_vehicle = bool(profile.get("prefers_vehicle", false))
	turret.damage_vs_infantry = float(profile.get("damage_vs_infantry", 1.0))
	turret.damage_vs_vehicle = float(profile.get("damage_vs_vehicle", 1.0))
	turret.hitscan_enabled = bool(profile.get("hitscan", false))
	var shot_color = profile.get("shot_color")
	if shot_color is Color:
		turret.shot_color = shot_color
	turret.shot_width = float(profile.get("shot_width", turret.shot_width))
	turret.shot_lifetime = float(profile.get("shot_lifetime", turret.shot_lifetime))
	turret.visual_scene_path = VisualPaths.get_turret_visual_path(build_id)
	turret.visual_base_radius = 16.0
	turret.position = pos
	_structures_container.add_child(turret)
	return turret

func _compute_defense_range(team: TeamState, pos: Vector2, base_range: float) -> float:
	var zone := team.build_zone
	if zone == Rect2():
		return base_range
	var left := pos.x - zone.position.x
	var right := (zone.position.x + zone.size.x) - pos.x
	var top := pos.y - zone.position.y
	var bottom := (zone.position.y + zone.size.y) - pos.y
	var min_edge := minf(minf(left, right), minf(top, bottom))
	var capped := maxf(0.0, min_edge * 0.9)
	return minf(base_range, capped)

func _increment_building_count(team_id: String, build_id: String) -> void:
	if team_id == "p1":
		GameState.p1_building_count += 1
		match build_id:
			"barracks":
				GameState.p1_barracks += 1
			"factory":
				GameState.p1_factory += 1
			"airfield":
				GameState.p1_airfield += 1
			"supply":
				GameState.p1_supply += 1
			"power":
				GameState.p1_power += 1
			"command_center":
				GameState.p1_command_center += 1
			_:
				if build_id.begins_with("defense"):
					GameState.p1_defense += 1
	else:
		GameState.p2_building_count += 1
		match build_id:
			"barracks":
				GameState.p2_barracks += 1
			"factory":
				GameState.p2_factory += 1
			"airfield":
				GameState.p2_airfield += 1
			"supply":
				GameState.p2_supply += 1
			"power":
				GameState.p2_power += 1
			"command_center":
				GameState.p2_command_center += 1
			_:
				if build_id.begins_with("defense"):
					GameState.p2_defense += 1

# =============================================================================
# COLLECTOR SPAWNING
# =============================================================================

# =============================================================================
# BATTALION UNIT SPAWNING
# =============================================================================

func spawn_battalion_unit(team_id: String, unit_type: String, spawn_pos: Vector2) -> Unit:
	var team := get_team(team_id)
	if team == null:
		return null

	var unit := Unit.new()
	unit.team_id = team_id
	unit.home_pos = team.start_pos

	# Configure as infantry with specific type
	var stats := UnitDefinitions.get_infantry_def(unit_type)
	var range_role := str(stats.get("range_role", "short"))
	var range_mult := UnitDefinitions.get_range_multiplier(range_role, GameBalance.INFANTRY_LONG_MULTIPLIER, GameBalance.INFANTRY_MID_MULTIPLIER)
	var attack_range := GameBalance.INFANTRY_ATTACK_RANGE * range_mult

	unit.unit_kind = "infantry"
	unit.unit_type = unit_type
	unit.range_role = range_role
	unit.range_multiplier = range_mult
	unit.prefers_vehicle = bool(stats.get("prefers_vehicle", false))
	unit.prefers_infantry = bool(stats.get("prefers_infantry", false))
	unit.damage_vs_infantry = float(stats.get("damage_vs_infantry", 1.0))
	unit.damage_vs_vehicle = float(stats.get("damage_vs_vehicle", 1.0))
	unit.damage_vs_structure = float(stats.get("damage_vs_structure", 1.0))
	unit.speed = float(stats.get("speed", GameBalance.INFANTRY_SPEED))
	unit.max_hp = float(stats.get("max_hp", GameBalance.INFANTRY_MAX_HP))
	unit.attack_damage = float(stats.get("damage", GameBalance.INFANTRY_DAMAGE))
	unit.attack_range = attack_range
	unit.attack_cooldown = float(stats.get("cooldown", GameBalance.INFANTRY_ATTACK_COOLDOWN))
	unit.body_radius = GameBalance.INFANTRY_BODY_RADIUS
	unit.color = team.get_unit_color()
	unit.aggro_range = maxf(220.0, attack_range * 1.05)
	unit.chase_leash = maxf(320.0, attack_range * 1.1)
	unit.structure_aggro_range = maxf(260.0, attack_range * 1.1)
	unit.shot_width = float(stats.get("shot_width", 2.0))
	unit.shot_lifetime = float(stats.get("shot_lifetime", 0.12))
	var shot_color = stats.get("shot_color", Color(1.0, 1.0, 1.0, 0.75))
	if shot_color is Color:
		unit.shot_color = shot_color

	unit.position = _offset_spawn(spawn_pos)
	unit.visual_scene_path = VisualPaths.get_unit_visual_path("infantry")
	unit.visual_base_radius = 8.0

	# Set enemy HQ
	var enemy_team := get_team(team.get_enemy_team_id())
	if enemy_team != null:
		unit.enemy_hq = enemy_team.hq

	# Battalion units don't use rally - they go to formation position
	unit.rally_target = unit.position  # Stay put until battalion tells them where to go

	_units_container.add_child(unit)
	unit_spawned.emit(unit, team_id, "infantry")
	return unit


# =============================================================================
# COLLECTOR SPAWNING
# =============================================================================

func spawn_collector(team: TeamState, base_pos: Vector2) -> Collector:
	var collector := Collector.new()
	collector.team_id = team.team_id
	collector.speed = 80.0  # collector_speed
	collector.carry_capacity = 100.0  # collector_capacity
	collector.harvest_time = 1.0  # collector_harvest_time
	collector.color = team.get_collector_color()
	collector.visual_scene_path = VisualPaths.get_unit_visual_path("collector")
	collector.visual_base_radius = 10.0
	collector.global_position = _offset_spawn(base_pos)
	_units_container.add_child(collector)
	team.collectors.append(collector)
	collector_spawned.emit(collector, team.team_id)
	return collector
