from __future__ import annotations

from typing import Dict, Tuple

from operation_gotland.simulation.state import GameState, PlayerState, SimulationConfig


def clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))


def logistics_factor(player: PlayerState) -> float:
    effective_logi = max(1.0, player.logistics_health - max(0.0, player.logistics_penalty))
    return 0.6 + 0.4 * (effective_logi / 100.0)


def income_this_tick(player: PlayerState, config: SimulationConfig) -> int:
    earned = config.income_per_tick * (player.logistics_health / 100.0)
    return max(5, int(round(earned)))


def total_production(player: PlayerState) -> float:
    prod = player.production
    subtotal = prod.vehicles + prod.arms + prod.aircraft + prod.defense
    return round(subtotal * logistics_factor(player), 2)


def build_capacity(player: PlayerState) -> int:
    return int(clamp(2 + player.economy.workshops, 1, 9))


def missile_penalty_value(attacker: PlayerState, frontline_pos: float, config: SimulationConfig) -> float:
    if attacker.units.missiles <= 0:
        return 0.0
    base_penalty = min(attacker.units.missiles * config.missile_penalty_per, config.missile_penalty_cap)
    proximity = clamp(1.0 - abs((frontline_pos - 50.0) / 50.0), 0.0, 1.0)
    return base_penalty * proximity


def compute_frontline_pressure(
    attacker: PlayerState, defender: PlayerState
) -> Tuple[float, Dict[str, float]]:
    armor_strength = attacker.units.vehicles + attacker.units.tanks * 1.2
    armor_resistance = defender.units.vehicles + defender.units.tanks * 1.1 + defender.units.def_vehicle * 0.5
    armor_superiority = (armor_strength - armor_resistance) * 0.25

    infantry_push = attacker.units.arms + attacker.units.def_arms * 0.4
    infantry_wall = defender.units.arms + defender.units.def_arms * 0.6
    infantry_density = (infantry_push - infantry_wall) * 0.2

    air_push = attacker.units.aircraft * 1.05 + attacker.units.helicopters * 0.8
    air_denial = (
        defender.units.aircraft + defender.units.helicopters * 0.6 + defender.units.def_air * 1.0
    )
    air_support = (air_push - air_denial) * 0.25

    enemy_defenses = -(
        defender.units.def_vehicle * 0.04
        + defender.units.def_arms * 0.04
        + defender.units.def_air * 0.04
    )
    logistics_penalty = -max(0.0, (100.0 - attacker.logistics_health) / 14.0)

    components = {
        "armor_superiority": armor_superiority,
        "infantry_density": infantry_density,
        "air_support": air_support,
        "enemy_defenses": enemy_defenses,
        "logistics_penalty": logistics_penalty,
    }
    net = sum(components.values())
    return net, components


def update_pressure_progress(
    current: float,
    pushing_net: float,
    opposing_net: float,
    config: SimulationConfig,
) -> float:
    progress = max(0.0, current - config.pressure_decay)
    progress += pushing_net
    if opposing_net > 0:
        progress -= opposing_net * config.opposing_bleed
    return clamp(progress, 0.0, config.pressure_threshold * 1.5)


def apply_breakthrough_attrition(state: GameState) -> None:
    for player in (state.player1, state.player2):
        for attr in (
            "arms",
            "vehicles",
            "tanks",
            "aircraft",
            "helicopters",
            "def_arms",
            "def_vehicle",
            "def_air",
            "missiles",
        ):
            current = getattr(player.units, attr, 0.0)
            setattr(player.units, attr, round(current * 0.25, 2))


def casualties_from(
    attacker: PlayerState, defender: PlayerState, config: SimulationConfig
) -> Dict[str, float]:
    eff: Dict[str, Dict[str, float]] = {
        "arms": {"vehicles": 0.6, "aircraft": 0.1},
        "vehicles": {"arms": 0.7, "vehicles": 0.25},
        "tanks": {"vehicles": 0.8, "tanks": 0.5, "def_vehicle": 0.6, "def_arms": 0.4},
        "aircraft": {
            "tanks": 1.25,
            "vehicles": 2.4,
            "aircraft": 0.7,
            "def_air": 0.35,
            "def_vehicle": 0.38,
            "def_arms": 0.25,
            "arms": 0.25,
            "missiles": 0.7,
        },
        "helicopters": {
            "arms": 1.0,
            "vehicles": 1.4,
            "tanks": 0.9,
            "helicopters": 0.6,
            "aircraft": 0.2,
            "def_air": 0.55,
            "def_vehicle": 0.35,
            "missiles": 0.4,
        },
        "missiles": {
            "def_air": 0.45,
            "def_vehicle": 0.5,
            "def_arms": 0.35,
            "vehicles": 0.25,
            "arms": 0.2,
            "helicopters": 0.2,
        },
        "def_arms": {"arms": 0.9},
        "def_vehicle": {"vehicles": 0.95, "helicopters": 0.35},
        "def_air": {"aircraft": 1.2, "helicopters": 1.0, "missiles": 0.7},
    }

    units = attacker.units
    attacker_counts = {
        "arms": units.arms,
        "vehicles": units.vehicles,
        "tanks": units.tanks,
        "aircraft": units.aircraft,
        "def_arms": units.def_arms,
        "def_vehicle": units.def_vehicle,
        "def_air": units.def_air,
        "helicopters": units.helicopters,
        "missiles": units.missiles,
    }
    losses: Dict[str, float] = {k: 0.0 for k in attacker_counts.keys()}

    for atk_type, atk_count in attacker_counts.items():
        if atk_count <= 0:
            continue
        for def_type, coeff in eff.get(atk_type, {}).items():
            if hasattr(defender.units, def_type):
                losses[def_type] += atk_count * coeff * config.combat_scale

    return {k: v for k, v in losses.items() if v > 0}


def apply_losses(player: PlayerState, losses: Dict[str, float]) -> None:
    for key, dmg in losses.items():
        if not hasattr(player.units, key):
            continue
        current = getattr(player.units, key)
        setattr(player.units, key, max(0.0, current - dmg))
