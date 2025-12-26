"""Dataclasses that represent the simulation state for the larger RTS version."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

from .config import SimulationSettings


@dataclass
class ProductionProfile:
    vehicles: float = 25.0
    arms: float = 25.0
    aircraft: float = 25.0
    defense: float = 25.0

    def total_weight(self) -> float:
        return max(0.0, self.vehicles + self.arms + self.aircraft + self.defense)

    def normalized(self) -> "ProductionProfile":
        total = self.total_weight()
        if total <= 0:
            return ProductionProfile(vehicles=25.0, arms=25.0, aircraft=25.0, defense=25.0)
        factor = 100.0 / total
        return ProductionProfile(
            vehicles=self.vehicles * factor,
            arms=self.arms * factor,
            aircraft=self.aircraft * factor,
            defense=self.defense * factor,
        )


@dataclass
class UnitPool:
    infantry: float = 0.0
    ifv: float = 0.0
    tank: float = 0.0
    aircraft: float = 0.0
    def_arms: float = 0.0
    def_vehicle: float = 0.0
    def_air: float = 0.0


@dataclass
class QueuedStructure:
    blueprint_id: str
    remaining: int


@dataclass
class ActiveOperation:
    operation_id: str
    target: str
    magnitude: float
    remaining_delay: int
    remaining_duration: int


@dataclass
class PlayerState:
    name: str
    logistics_health: float = 100.0
    industry_health: float = 100.0
    defense_health: float = 100.0
    production: ProductionProfile = field(default_factory=ProductionProfile)
    units: UnitPool = field(default_factory=UnitPool)
    credits: int = 120
    structures: Dict[str, int] = field(default_factory=dict)
    build_queue: List[QueuedStructure] = field(default_factory=list)
    operations: List[ActiveOperation] = field(default_factory=list)
    air_posture: str = "ISR"
    unit_tiers: Dict[str, int] = field(
        default_factory=lambda: {
            "infantry": 0,
            "ifv": 0,
            "tank": 0,
            "aircraft": 0,
            "def_arms": 0,
            "def_vehicle": 0,
            "def_air": 0,
        }
    )

    def build_capacity(self) -> int:
        factories = self.structures.get("factory", 0)
        return max(1, min(9, 2 + factories))

    def logistics_factor(self) -> float:
        effective_logi = max(1.0, self.logistics_health)
        return 0.6 + 0.4 * (effective_logi / 100.0)

    def income_per_tick(self, settings: SimulationSettings) -> int:
        income_structures = self.structures.get("income", 0)
        base_income = settings.economy.base_income_per_tick + income_structures * settings.economy.income_per_structure
        earned = base_income * (self.logistics_health / 100.0)
        return max(5, int(round(earned)))

    def apply_income(self, settings: SimulationSettings) -> None:
        self.credits += self.income_per_tick(settings)


@dataclass
class FrontlineState:
    position: float = 50.0
    pressure_toward_p2: float = 0.0
    pressure_toward_p1: float = 0.0

    def ratio(self, settings: SimulationSettings) -> float:
        span = settings.frontline.max_position - settings.frontline.min_position
        return round((self.position - settings.frontline.min_position) / span * 100.0, 2)


@dataclass
class GameState:
    player1: PlayerState
    player2: PlayerState
    settings: SimulationSettings
    frontline: FrontlineState = field(default_factory=FrontlineState)
    escalation: float = 0.0
    objectives: List["ObjectiveState"] = field(default_factory=list)
    history: List[str] = field(default_factory=list)
    tick: int = 0
    winner: Optional[str] = None
    victory_reason: Optional[str] = None

    def record(self, message: str) -> None:
        self.history.append(message)
        if len(self.history) > 100:
            self.history = self.history[-100:]


@dataclass
class ObjectiveState:
    name: str
    position: float
    owner: Optional[str] = None
