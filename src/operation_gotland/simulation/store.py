"""Structure and upgrade blueprints for the expanded simulation."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Tuple


@dataclass(frozen=True)
class StructureBlueprint:
    key: str
    name: str
    cost: int
    build_time: int = 2
    description: str = ""
    tags: Tuple[str, ...] = ()


def default_blueprints() -> Dict[str, StructureBlueprint]:
    """
    Baseline structures used by the headless simulation. Tags encode the
    systemic effects that runtime will interpret each tick.
    """
    blueprints: List[StructureBlueprint] = [
        StructureBlueprint(
            key="infantry_factory",
            name="Infantry Works",
            cost=70,
            description="Boosts infantry throughput and upgrades.",
            tags=("factory", "infantry"),
        ),
        StructureBlueprint(
            key="armor_factory",
            name="Armor Yard",
            cost=95,
            description="Boosts IFV/tank throughput and upgrades.",
            tags=("factory", "armor"),
        ),
        StructureBlueprint(
            key="air_factory",
            name="Airframe Plant",
            cost=120,
            description="Boosts aircraft throughput and upgrades.",
            tags=("factory", "air"),
        ),
        StructureBlueprint(
            key="heli_factory",
            name="Rotary Wing Depot",
            cost=105,
            description="Boosts helicopter throughput and upgrades.",
            tags=("factory", "heli"),
        ),
        StructureBlueprint(
            key="defense_factory",
            name="Defense Forge",
            cost=110,
            description="Boosts defense throughput and range upgrades.",
            tags=("factory", "defense"),
        ),
        StructureBlueprint(
            key="income",
            name="Revenue Facility",
            cost=75,
            description="Generates steady war funding each tick.",
            tags=("income",),
        ),
        StructureBlueprint(
            key="logistics_hub",
            name="Logistics Hub",
            cost=65,
            description="Raises logistics resilience and repair throughput.",
            tags=("logistics",),
        ),
        StructureBlueprint(
            key="def_arms",
            name="Anti-Infantry Grid",
            cost=55,
            build_time=2,
            description="Suppresses infantry pressure along the front.",
            tags=("defense", "def_arms"),
        ),
        StructureBlueprint(
            key="def_vehicle",
            name="Anti-Armor Emplacements",
            cost=70,
            build_time=2,
            description="Suppresses IFV and tank pressure.",
            tags=("defense", "def_vehicle"),
        ),
        StructureBlueprint(
            key="def_air",
            name="Air Defense Network",
            cost=80,
            build_time=3,
            description="Suppresses aircraft pressure and air posture effects.",
            tags=("defense", "def_air"),
        ),
    ]
    return {bp.key: bp for bp in blueprints}
