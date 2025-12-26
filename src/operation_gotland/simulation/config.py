"""Simulation tuning constants and aggregate settings."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class EconomySettings:
    base_credits: int = 120
    income_per_tick: float = 25.0
    supply_zone_bonus: int = 50
    unit_build_rate: float = 0.12
    air_unit_build_rate: float = 0.06
    build_queue_max: int = 9


@dataclass(frozen=True)
class FrontlineSettings:
    min_position: float = 0.0
    max_position: float = 100.0
    segment: float = 25.0
    pressure_threshold: float = 10.0
    pressure_decay: float = 0.5
    opposing_bleed: float = 0.35


@dataclass(frozen=True)
class CombatSettings:
    combat_scale: float = 0.04
    sortie_duration: int = 3


@dataclass(frozen=True)
class SimulationSettings:
    economy: EconomySettings = EconomySettings()
    frontline: FrontlineSettings = FrontlineSettings()
    combat: CombatSettings = CombatSettings()
