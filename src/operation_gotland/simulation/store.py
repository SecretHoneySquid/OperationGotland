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
    A minimal set of placeholder blueprints. The numbers are intentionally
    conservative; the real tuning will happen once we plug in the richer
    content set.
    """
    blueprints: List[StructureBlueprint] = [
        StructureBlueprint(
            key="ifv_factory",
            name="IFV Factory",
            cost=55,
            description="Boosts IFV vehicle throughput and tank pipeline.",
            tags=("production", "armor"),
        ),
        StructureBlueprint(
            key="logistics_hub",
            name="Logistics Hub",
            cost=70,
            description="Improves overall logistics health.",
            tags=("logistics",),
        ),
        StructureBlueprint(
            key="aircraft_works",
            name="Aircraft Works",
            cost=80,
            description="Opens the air production track.",
            tags=("production", "air"),
        ),
        StructureBlueprint(
            key="helipad",
            name="Helipad",
            cost=30,
            description="Adds helicopter capacity; supports missile unlock path.",
            build_time=1,
            tags=("air", "unlock"),
        ),
        StructureBlueprint(
            key="missile_authorization",
            name="Missile Corps Authorization",
            cost=500,
            description="Unlocks missile launchers once the right pre-reqs are met.",
            build_time=3,
            tags=("unlock",),
        ),
    ]
    return {bp.key: bp for bp in blueprints}
