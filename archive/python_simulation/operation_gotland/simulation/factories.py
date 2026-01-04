from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional

from operation_gotland.simulation.rules import clamp
from operation_gotland.simulation.state import FactoryDefinition, PlayerState, SimulationConfig


@dataclass
class FactoryCatalog:
    factories: Dict[int, FactoryDefinition]

    def get(self, factory_id: int) -> FactoryDefinition:
        return self.factories[factory_id]


def default_factory_catalog(config: SimulationConfig) -> FactoryCatalog:
    build_times = config.build_times
    factories = {
        1: FactoryDefinition(
            factory_id=1,
            name="IFV Factory",
            cost=55,
            description="Boosts IFV vehicle production by +15.",
            build_time=build_times.get(1, 2),
            tags=["armor"],
        ),
        2: FactoryDefinition(
            factory_id=2,
            name="Logistics Hub",
            cost=70,
            description="Improves logistics health by +20% (helps every production type).",
            build_time=build_times.get(2, 3),
            tags=["logistics"],
        ),
        3: FactoryDefinition(
            factory_id=3,
            name="Arms Plant",
            cost=65,
            description="Raises arms production by +12.",
            build_time=build_times.get(3, 2),
            tags=["infantry"],
        ),
        4: FactoryDefinition(
            factory_id=4,
            name="Aircraft Works",
            cost=80,
            description="Raises aircraft production by +10.",
            build_time=build_times.get(4, 3),
            tags=["air"],
        ),
        5: FactoryDefinition(
            factory_id=5,
            name="Defense Complex",
            cost=75,
            description="Raises air defense production by +10.",
            build_time=build_times.get(5, 2),
            tags=["defense"],
        ),
        6: FactoryDefinition(
            factory_id=6,
            name="Supply Zone",
            cost=60,
            description="Generates bonus credits every 5th tick.",
            build_time=build_times.get(6, 2),
            tags=["economy"],
        ),
        7: FactoryDefinition(
            factory_id=7,
            name="Infantry Defense Network",
            cost=70,
            description="Deploys infantry defenses (immediate +30 def_arms units).",
            build_time=build_times.get(7, 1),
            tags=["defense"],
        ),
        8: FactoryDefinition(
            factory_id=8,
            name="Vehicle Defense Network",
            cost=80,
            description="Deploys vehicle defenses (immediate +30 def_vehicle units).",
            build_time=build_times.get(8, 1),
            tags=["defense"],
        ),
        9: FactoryDefinition(
            factory_id=9,
            name="Tank Foundry",
            cost=70,
            description="Adds heavy tank focus (+6 tank bonus, +6 vehicle prod).",
            build_time=build_times.get(9, 2),
            tags=["armor"],
        ),
        10: FactoryDefinition(
            factory_id=10,
            name="Missile Corps Authorization",
            cost=500,
            description="Unlocks missile launchers (requires armor plants or Aircraft Works + 3 Helipads).",
            build_time=build_times.get(10, 2),
            tags=["missiles"],
        ),
        11: FactoryDefinition(
            factory_id=11,
            name="Missile Launcher Battery",
            cost=100,
            description="Adds one missile launcher (logistics harass near the front).",
            build_time=build_times.get(11, 2),
            tags=["missiles"],
        ),
        12: FactoryDefinition(
            factory_id=12,
            name="Helipad",
            cost=30,
            description="Requires Aircraft Works. Adds 5 helicopters and +5% arms production.",
            build_time=build_times.get(12, 2),
            tags=["air"],
        ),
        13: FactoryDefinition(
            factory_id=13,
            name="Workshop",
            cost=50,
            description="Increases parallel build capacity by +1 (base 2).",
            build_time=build_times.get(13, 3),
            tags=["economy"],
        ),
    }
    return FactoryCatalog(factories=factories)


def missile_authorization_allowed(player: PlayerState) -> bool:
    armor_path = player.purchases.get(1, 0) > 0 and player.purchases.get(9, 0) > 0
    air_path = player.purchases.get(4, 0) > 0 and player.helipads >= 3
    return armor_path or air_path


def maybe_update_missile_prereq(player: PlayerState) -> None:
    if player.missile_unlocked:
        return
    if missile_authorization_allowed(player):
        player.missile_unlocked = True


def maybe_apply_armor_synergy(player: PlayerState, projected_purchases: Optional[Dict[int, int]] = None) -> None:
    if player.armored_synergy_bonus:
        return
    purchases = projected_purchases or player.purchases
    if purchases.get(1, 0) > 0 and purchases.get(9, 0) > 0:
        player.armored_synergy_bonus = True
        player.logistics_health = clamp(player.logistics_health + 5, 10.0, 250.0)
        player.production.defense += 3
        maybe_update_missile_prereq(player)


def apply_armored_factory(player: PlayerState, vehicle_boost: float, tank_boost: float, key: int) -> None:
    player.production.vehicles += vehicle_boost
    player.production.tank_bonus += tank_boost
    projected = dict(player.purchases)
    projected[key] = projected.get(key, 0) + 1
    maybe_apply_armor_synergy(player, projected)
    maybe_update_missile_prereq(player)


def unlock_missiles(player: PlayerState) -> None:
    if player.missile_unlocked:
        return
    if not missile_authorization_allowed(player):
        raise ValueError("Missile unlock requires armor plants or Aircraft Works + 3 Helipads.")
    player.missile_unlocked = True


def add_helipad(player: PlayerState) -> None:
    if player.purchases.get(4, 0) <= 0:
        raise ValueError("Helipads require owning an Aircraft Works.")
    player.helipads += 1
    player.units.helicopters += 5
    player.production.arms = round(player.production.arms * 1.05, 2)
    maybe_update_missile_prereq(player)


def apply_factory_effect(
    player: PlayerState,
    factory_id: int,
    config: SimulationConfig,
) -> None:
    if factory_id == 1:
        apply_armored_factory(player, vehicle_boost=15, tank_boost=0, key=1)
    elif factory_id == 2:
        player.logistics_health = clamp(player.logistics_health * 1.2, 10.0, 250.0)
    elif factory_id == 3:
        player.production.arms += 12
    elif factory_id == 4:
        player.production.aircraft += 10
    elif factory_id == 5:
        player.production.defense += 10
    elif factory_id == 6:
        player.economy.supply_zones += 1
    elif factory_id == 7:
        player.units.def_arms += 30
    elif factory_id == 8:
        player.units.def_vehicle += 30
    elif factory_id == 9:
        apply_armored_factory(player, vehicle_boost=6, tank_boost=6, key=9)
    elif factory_id == 10:
        unlock_missiles(player)
    elif factory_id == 11:
        player.units.missiles += 1
    elif factory_id == 12:
        add_helipad(player)
    elif factory_id == 13:
        player.economy.workshops += 1
    else:
        raise ValueError(f"Unknown factory id {factory_id}.")
