extends Node
class_name UnitDefinitions

## Unit Definitions
##
## Centralized location for all unit type definitions.
## Extracted from game_controller.gd for better organization.

# =============================================================================
# TYPE RESOLUTION
# =============================================================================

static func resolve_infantry_type(requested: String, rng: RandomNumberGenerator) -> String:
	if requested == "mixed":
		var long_ratio := clampf(GameBalance.INFANTRY_LONG_RATIO, 0.0, 1.0)
		var mid_ratio := clampf(GameBalance.INFANTRY_MID_RATIO, 0.0, 1.0 - long_ratio)
		var roll := rng.randf()
		if roll < long_ratio:
			return "sniper"
		if roll < long_ratio + mid_ratio:
			return "rocket"
		return "rifle"
	if requested in ["rifle", "sniper", "rocket"]:
		return requested
	return "rifle"

static func resolve_vehicle_type(requested: String, rng: RandomNumberGenerator) -> String:
	if requested == "mixed" or requested == "":
		var long_ratio := clampf(GameBalance.VEHICLE_LONG_RATIO, 0.0, 1.0)
		var mid_ratio := clampf(GameBalance.VEHICLE_MID_RATIO, 0.0, 1.0 - long_ratio)
		var roll := rng.randf()
		if roll < long_ratio:
			return "artillery"
		if roll < long_ratio + mid_ratio:
			return "ifv"
		return "tank"
	if requested == "apc":
		return "ifv"
	if requested in ["tank", "artillery", "ifv", "himars"]:
		return requested
	return "tank"

static func resolve_aircraft_type(requested: String) -> String:
	if requested == "" or requested == "mixed":
		return "f16"
	if requested in ["f16", "gripen", "f22", "f35", "uav"]:
		return requested
	return "f16"

# =============================================================================
# RANGE HELPERS
# =============================================================================

static func get_range_multiplier(role: String, long_mult: float, mid_mult: float) -> float:
	if role == "long":
		return long_mult
	if role == "mid":
		return mid_mult
	return 1.0

# =============================================================================
# INFANTRY DEFINITIONS
# =============================================================================

static func get_infantry_def(type_id: String) -> Dictionary:
	match type_id:
		"sniper":
			return {
				"range_role": "long",
				"max_hp": GameBalance.INFANTRY_MAX_HP * 0.8,
				"damage": GameBalance.INFANTRY_DAMAGE * 2.2,
				"cooldown": GameBalance.INFANTRY_ATTACK_COOLDOWN * 1.8,
				"speed": GameBalance.INFANTRY_SPEED * 0.85,
				"shot_color": Color(1.0, 0.95, 0.6, 0.85),
				"shot_width": 2.5,
				"shot_lifetime": 0.2,
				"prefers_infantry": true,
				"prefers_vehicle": false,
				"damage_vs_infantry": 1.1,
				"damage_vs_vehicle": 0.5,
				"damage_vs_structure": 0.6,
			}
		"rocket":
			return {
				"range_role": "mid",
				"max_hp": GameBalance.INFANTRY_MAX_HP * 1.15,
				"damage": GameBalance.INFANTRY_DAMAGE * 2.4,
				"cooldown": GameBalance.INFANTRY_ATTACK_COOLDOWN * 1.4,
				"speed": GameBalance.INFANTRY_SPEED * 0.8,
				"shot_color": Color(1.0, 0.7, 0.3, 0.85),
				"shot_width": 3.0,
				"shot_lifetime": 0.18,
				"prefers_infantry": false,
				"prefers_vehicle": true,
				"damage_vs_infantry": 0.7,
				"damage_vs_vehicle": 1.8,
				"damage_vs_structure": 1.2,
			}
		_:  # rifle (default)
			return {
				"range_role": "short",
				"max_hp": GameBalance.INFANTRY_MAX_HP,
				"damage": GameBalance.INFANTRY_DAMAGE * 0.6,
				"cooldown": GameBalance.INFANTRY_ATTACK_COOLDOWN * 0.45,
				"speed": GameBalance.INFANTRY_SPEED,
				"shot_color": Color(1.0, 1.0, 1.0, 0.7),
				"shot_width": 1.6,
				"shot_lifetime": 0.08,
				"prefers_infantry": true,
				"prefers_vehicle": false,
				"damage_vs_infantry": 1.3,
				"damage_vs_vehicle": 0.6,
				"damage_vs_structure": 0.8,
			}

static func get_infantry_type_options() -> Array:
	return [
		{"id": "mixed", "name": "Mixed"},
		{"id": "rifle", "name": "Rifle"},
		{"id": "sniper", "name": "Sniper"},
		{"id": "rocket", "name": "Rocket"},
	]

# =============================================================================
# VEHICLE DEFINITIONS
# =============================================================================

static func get_vehicle_def(type_id: String) -> Dictionary:
	match type_id:
		"himars":
			return {
				"range_role": "short",
				"max_hp": GameBalance.HIMARS_MAX_HP,
				"damage": 0.0,  # HIMARS doesn't use direct fire
				"cooldown": 999.0,  # No direct fire
				"speed": GameBalance.HIMARS_SPEED,
				"shot_color": Color(1.0, 0.5, 0.0, 0.0),
				"shot_width": 0.0,
				"shot_lifetime": 0.0,
				"body_radius": GameBalance.HIMARS_BODY_RADIUS,
				"turn_rate": 3.0,
				"prefers_infantry": false,
				"prefers_vehicle": false,
				"damage_vs_infantry": 1.0,
				"damage_vs_vehicle": 1.0,
				"damage_vs_structure": 1.0,
				"is_himars": true,
				"vision_radius": GameBalance.HIMARS_VISION_RADIUS,
				"bombardment_range": GameBalance.HIMARS_BOMBARDMENT_RANGE,
				"missile_damage": GameBalance.HIMARS_MISSILE_DAMAGE,
				"missile_speed": GameBalance.HIMARS_MISSILE_SPEED,
				"missile_lifetime": GameBalance.HIMARS_MISSILE_LIFETIME,
				"missile_splash_radius": GameBalance.HIMARS_MISSILE_SPLASH_RADIUS,
				"missiles_per_salvo": GameBalance.HIMARS_MISSILES_PER_SALVO,
				"salvo_interval": GameBalance.HIMARS_SALVO_INTERVAL,
				"reload_time": GameBalance.HIMARS_RELOAD_TIME,
				"visual_scene_path": "res://scenes/units/himars_visual_animated.tscn",
				"visual_base_radius": 16.0,
			}
		"artillery":
			return {
				"range_role": "long",
				"max_hp": GameBalance.VEHICLE_MAX_HP * 0.85,
				"damage": GameBalance.VEHICLE_DAMAGE * 2.4,
				"cooldown": GameBalance.VEHICLE_ATTACK_COOLDOWN * 1.8,
				"speed": GameBalance.VEHICLE_SPEED * 0.75,
				"shot_color": Color(1.0, 0.6, 0.35, 0.9),
				"shot_width": 4.0,
				"shot_lifetime": 0.22,
				"body_radius": GameBalance.VEHICLE_BODY_RADIUS,
				"turn_rate": 3.0,
				"prefers_infantry": false,
				"prefers_vehicle": false,
				"damage_vs_infantry": 1.1,
				"damage_vs_vehicle": 1.3,
				"damage_vs_structure": 1.8,
			}
		"ifv":
			return {
				"range_role": "mid",
				"max_hp": GameBalance.VEHICLE_MAX_HP * 1.1,
				"damage": GameBalance.VEHICLE_DAMAGE * 1.2,
				"cooldown": GameBalance.VEHICLE_ATTACK_COOLDOWN * 1.1,
				"speed": GameBalance.VEHICLE_SPEED * 1.1,
				"shot_color": Color(1.0, 0.8, 0.5, 0.85),
				"shot_width": 3.0,
				"shot_lifetime": 0.16,
				"body_radius": GameBalance.VEHICLE_BODY_RADIUS,
				"turn_rate": 3.0,
				"prefers_infantry": true,
				"prefers_vehicle": false,
				"damage_vs_infantry": 1.6,
				"damage_vs_vehicle": 0.7,
				"damage_vs_structure": 0.8,
			}
		_:  # tank (default)
			return {
				"range_role": "short",
				"max_hp": GameBalance.VEHICLE_MAX_HP,
				"damage": GameBalance.VEHICLE_DAMAGE,
				"cooldown": GameBalance.VEHICLE_ATTACK_COOLDOWN,
				"speed": GameBalance.VEHICLE_SPEED,
				"shot_color": Color(1.0, 0.85, 0.6, 0.8),
				"shot_width": 3.0,
				"shot_lifetime": 0.14,
				"body_radius": GameBalance.VEHICLE_BODY_RADIUS,
				"turn_rate": 3.0,
				"prefers_infantry": false,
				"prefers_vehicle": true,
				"damage_vs_infantry": 0.9,
				"damage_vs_vehicle": 1.2,
				"damage_vs_structure": 1.1,
			}

static func get_vehicle_type_options() -> Array:
	return [
		{"id": "mixed", "name": "Mixed"},
		{"id": "tank", "name": "Tank"},
		{"id": "artillery", "name": "Artillery"},
		{"id": "ifv", "name": "IFV"},
	]

# =============================================================================
# AIRCRAFT DEFINITIONS
# =============================================================================

static func get_aircraft_def(type_id: String) -> Dictionary:
	match type_id:
		"gripen":
			var base := _base_fighter_def()
			base["max_hp"] = base["max_hp"] * 1.1
			base["damage"] = base["damage"] * 1.15
			base["cooldown"] = base["cooldown"] * 0.95
			base["speed"] = base["speed"] * 1.05
			base["gun_ammo"] = base["gun_ammo"] + 5
			base["missile_damage"] = base["missile_damage"] * 1.1
			base["reload_time"] = base["reload_time"] * 0.9
			base["damage_vs_structure"] = 1.1
			return base
		"f22":
			var base := _base_fighter_def()
			base["max_hp"] = base["max_hp"] * 1.25
			base["damage"] = base["damage"] * 1.3
			base["cooldown"] = base["cooldown"] * 0.9
			base["speed"] = base["speed"] * 1.1
			base["gun_ammo"] = base["gun_ammo"] + 10
			base["missile_ammo"] = base["missile_ammo"] + 1
			base["missile_damage"] = base["missile_damage"] * 1.2
			base["missile_speed"] = base["missile_speed"] * 1.05
			base["missile_cooldown"] = base["missile_cooldown"] * 0.95
			base["reload_time"] = base["reload_time"] * 0.85
			base["damage_vs_structure"] = 1.1
			return base
		"f35":
			var base := _base_fighter_def()
			base["damage_vs_structure"] = 1.1
			return base
		"uav":
			return {
				"range_role": "long",
				"range_multiplier": 1.0,
				"max_hp": GameBalance.UAV_MAX_HP,
				"damage": 0.0,  # No weapons
				"cooldown": 999.0,
				"speed": GameBalance.UAV_SPEED,
				"attack_range": 0.0,  # No combat
				"body_radius": GameBalance.UAV_BODY_RADIUS,
				"vision_radius": GameBalance.UAV_VISION_RADIUS,
				"turn_rate": GameBalance.UAV_TURN_RATE,
				"loiter_radius": GameBalance.UAV_LOITER_RADIUS,
				"loiter_orbit_speed": GameBalance.UAV_LOITER_ORBIT_SPEED,
				"shot_color": Color(0.0, 0.0, 0.0, 0.0),
				"shot_width": 0.0,
				"shot_lifetime": 0.0,
				"gun_ammo": 0,
				"missile_ammo": 0,
				"missile_damage": 0.0,
				"missile_speed": 0.0,
				"missile_turn_rate": 0.0,
				"missile_range": 0.0,
				"missile_cooldown": 999.0,
				"missile_hit_radius": 0.0,
				"missile_warhead_size": "small",
				"missile_splash_radius": 0.0,
				"missile_splash_scale": 0.0,
				"missile_lifetime": 0.0,
				"reload_time": 999.0,
				"missile_color": Color(0.0, 0.0, 0.0, 0.0),
				"prefers_vehicle": false,
				"prefers_infantry": false,
				"damage_vs_infantry": 0.0,
				"damage_vs_vehicle": 0.0,
				"damage_vs_structure": 0.0,
				"is_uav": true,
			}
		_:  # f16 (default)
			return _base_fighter_def()

static func _base_fighter_def() -> Dictionary:
	return {
		"range_role": "long",
		"range_multiplier": 1.0,
		"max_hp": GameBalance.AIRCRAFT_MAX_HP,
		"damage": GameBalance.AIRCRAFT_GUN_DAMAGE,
		"cooldown": GameBalance.AIRCRAFT_GUN_ATTACK_COOLDOWN,
		"speed": GameBalance.AIRCRAFT_SPEED,
		"attack_range": GameBalance.AIRCRAFT_GUN_ATTACK_RANGE,
		"body_radius": GameBalance.AIRCRAFT_BODY_RADIUS,
		"vision_radius": GameBalance.AIRCRAFT_VISION_RADIUS,
		"shot_color": Color(1.0, 0.9, 0.75, 0.85),
		"shot_width": GameBalance.AIRCRAFT_SHOT_WIDTH,
		"shot_lifetime": GameBalance.AIRCRAFT_SHOT_LIFETIME,
		"gun_ammo": GameBalance.AIRCRAFT_GUN_CAPACITY,
		"missile_ammo": GameBalance.AIRCRAFT_MISSILE_CAPACITY,
		"missile_damage": GameBalance.AIRCRAFT_MISSILE_DAMAGE,
		"missile_speed": GameBalance.AIRCRAFT_MISSILE_SPEED,
		"missile_turn_rate": GameBalance.AIRCRAFT_MISSILE_TURN_RATE,
		"missile_range": GameBalance.AIRCRAFT_MISSILE_RANGE,
		"missile_cooldown": GameBalance.AIRCRAFT_MISSILE_COOLDOWN,
		"missile_hit_radius": GameBalance.AIRCRAFT_MISSILE_HIT_RADIUS,
		"missile_warhead_size": "large",
		"missile_splash_radius": GameBalance.AIRCRAFT_MISSILE_SPLASH_RADIUS,
		"missile_splash_scale": GameBalance.AIRCRAFT_MISSILE_SPLASH_SCALE,
		"missile_lifetime": GameBalance.AIRCRAFT_MISSILE_LIFETIME,
		"reload_time": GameBalance.AIRCRAFT_RELOAD_TIME,
		"missile_color": Color(1.0, 0.55, 0.25, 1.0),
		"prefers_vehicle": true,
		"prefers_infantry": false,
		"damage_vs_infantry": 0.6,
		"damage_vs_vehicle": 1.6,
		"damage_vs_structure": 1.0,
	}
