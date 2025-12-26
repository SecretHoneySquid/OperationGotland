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

    def total_output(self, logistics_factor: float) -> float:
        subtotal = self.vehicles + self.arms + self.aircraft + self.defense
        return round(subtotal * logistics_factor, 2)


@dataclass
class UnitPool:
    infantry: float = 0.0
    vehicles: float = 0.0
    tanks: float = 0.0
    aircraft: float = 0.0
    helicopters: float = 0.0
    missiles: float = 0.0
    def_arms: float = 0.0
    def_vehicle: float = 0.0
    def_air: float = 0.0


@dataclass
class QueuedStructure:
    blueprint_id: str
    remaining: int


@dataclass
class PlayerState:
    name: str
    logistics_health: float = 100.0
    logistics_penalty: float = 0.0
    production: ProductionProfile = field(default_factory=ProductionProfile)
    units: UnitPool = field(default_factory=UnitPool)
    credits: int = 120
    structures: Dict[str, int] = field(default_factory=dict)
    build_queue: List[QueuedStructure] = field(default_factory=list)
    missile_unlocked: bool = False
    helipads: int = 0

    def build_capacity(self) -> int:
        workshops = self.structures.get("workshop", 0)
        return max(1, min(9, 2 + workshops))

    def logistics_factor(self) -> float:
        effective_logi = max(1.0, self.logistics_health - max(0.0, self.logistics_penalty))
        return 0.6 + 0.4 * (effective_logi / 100.0)

    def income_per_tick(self, settings: SimulationSettings) -> int:
        earned = settings.economy.income_per_tick * (self.logistics_health / 100.0)
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
    history: List[str] = field(default_factory=list)
    tick: int = 0
    winner: Optional[str] = None

    def record(self, message: str) -> None:
        self.history.append(message)
        if len(self.history) > 100:
            self.history = self.history[-100:]
