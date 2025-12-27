from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional


@dataclass
class SimulationConfig:
    frontline_min: float = 0.0
    frontline_max: float = 100.0
    frontline_segment: float = 25.0
    pressure_threshold: float = 10.0
    pressure_decay: float = 0.5
    opposing_bleed: float = 0.35
    missile_penalty_per: float = 2.5
    missile_penalty_cap: float = 50.0
    base_credits: int = 120
    income_per_tick: float = 25.0
    supply_zone_bonus: int = 50
    unit_build_rate: float = 0.12
    air_unit_build_rate: float = 0.06
    build_queue_max: int = 9
    combat_scale: float = 0.04
    sortie_duration: int = 3
    build_times: Dict[int, int] = field(
        default_factory=lambda: {
            1: 2,
            2: 3,
            3: 2,
            4: 3,
            5: 2,
            6: 2,
            7: 1,
            8: 1,
            13: 3,
        }
    )


@dataclass(frozen=True)
class FactoryDefinition:
    factory_id: int
    name: str
    cost: int
    description: str
    build_time: int
    tags: List[str] = field(default_factory=list)


@dataclass
class BuildOrder:
    factory_id: int
    remaining: int


@dataclass
class ProductionState:
    vehicles: float = 25.0
    arms: float = 25.0
    aircraft: float = 25.0
    defense: float = 25.0
    tank_bonus: float = 0.0


@dataclass
class UnitPools:
    arms: float = 0.0
    vehicles: float = 0.0
    tanks: float = 0.0
    aircraft: float = 0.0
    helicopters: float = 0.0
    missiles: float = 0.0
    def_arms: float = 0.0
    def_vehicle: float = 0.0
    def_air: float = 0.0


@dataclass
class EconomyState:
    credits: int = 120
    supply_zones: int = 0
    workshops: int = 0
    build_queue: List[BuildOrder] = field(default_factory=list)


@dataclass
class CapabilityScores:
    armor: int = 0
    infantry: int = 0
    air: int = 0
    air_defense: int = 0
    logistics: int = 0
    missiles: int = 0


@dataclass
class PlayerState:
    name: str
    logistics_health: float = 100.0
    logistics_penalty: float = 0.0
    production: ProductionState = field(default_factory=ProductionState)
    economy: EconomyState = field(default_factory=EconomyState)
    units: UnitPools = field(default_factory=UnitPools)
    purchases: Dict[int, int] = field(default_factory=dict)
    helipads: int = 0
    missile_unlocked: bool = False
    armored_synergy_bonus: bool = False
    capability_scores: CapabilityScores = field(default_factory=CapabilityScores)

    def __post_init__(self) -> None:
        for factory_id in range(1, 14):
            self.purchases.setdefault(factory_id, 0)


@dataclass
class FrontlineState:
    position: float = 50.0
    pressure_toward_p1: float = 0.0
    pressure_toward_p2: float = 0.0


@dataclass
class SortieState:
    owner: str
    target: str
    committed: float
    remaining: int


@dataclass
class GameState:
    tick: int
    player1: PlayerState
    player2: PlayerState
    frontline: FrontlineState = field(default_factory=FrontlineState)
    sorties: List[SortieState] = field(default_factory=list)
    winner: Optional[str] = None
