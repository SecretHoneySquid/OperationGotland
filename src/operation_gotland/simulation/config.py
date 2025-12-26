"""Simulation tuning constants and aggregate settings."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, Tuple


@dataclass(frozen=True)
class EconomySettings:
    base_credits: int = 120
    base_income_per_tick: float = 20.0
    income_per_structure: float = 15.0
    build_queue_max: int = 9


@dataclass(frozen=True)
class ProductionSettings:
    base_output: float = 30.0
    factory_output: float = 12.0
    armor_split: Tuple[float, float] = (0.6, 0.4)
    defense_split: Tuple[float, float, float] = (0.4, 0.4, 0.2)
    defense_build_rate: float = 0.08


@dataclass(frozen=True)
class FrontlineSettings:
    min_position: float = 0.0
    max_position: float = 100.0
    collapse_threshold: float = 80.0
    collapse_multiplier: float = 1.35


@dataclass(frozen=True)
class CombatSettings:
    pressure_scale: float = 0.04
    defense_soft_cap: float = 0.75


@dataclass(frozen=True)
class UnitDefinition:
    key: str
    cost: float
    pressure: float
    build_rate: float
    defense_key: str


@dataclass(frozen=True)
class DefenseDefinition:
    key: str
    strength: float


@dataclass(frozen=True)
class TierDefinition:
    name: str
    asset: str


@dataclass(frozen=True)
class AirPostureDefinition:
    key: str
    cost_per_tick: int
    pressure_bonus: float = 0.0
    defense_suppression: float = 0.0
    logistics_strike: float = 0.0
    industry_strike: float = 0.0


@dataclass(frozen=True)
class OperationDefinition:
    key: str
    name: str
    cost: int
    target: str
    magnitude: float
    delay: int
    duration: int


@dataclass(frozen=True)
class EscalationSettings:
    base_rate: float = 0.4
    intensity_factor: float = 0.15
    max_value: float = 100.0
    phase_thresholds: Tuple[float, float] = (33.0, 66.0)
    repair_rate_base: float = 2.5
    repair_rate_min: float = 0.4
    strike_multiplier_base: float = 1.0
    strike_multiplier_per_phase: float = 0.35
    pressure_multiplier_per_phase: float = 0.15


@dataclass(frozen=True)
class ObjectiveDefinition:
    name: str
    position: float


@dataclass(frozen=True)
class VictorySettings:
    system_collapse_threshold: float = 5.0


def _default_units() -> Dict[str, UnitDefinition]:
    return {
        "infantry": UnitDefinition("infantry", cost=1.0, pressure=0.7, build_rate=1.4, defense_key="def_arms"),
        "ifv": UnitDefinition("ifv", cost=2.5, pressure=1.4, build_rate=0.9, defense_key="def_vehicle"),
        "tank": UnitDefinition("tank", cost=4.0, pressure=2.2, build_rate=0.55, defense_key="def_vehicle"),
        "aircraft": UnitDefinition("aircraft", cost=6.0, pressure=2.8, build_rate=0.4, defense_key="def_air"),
    }


def _default_defenses() -> Dict[str, DefenseDefinition]:
    return {
        "def_arms": DefenseDefinition("def_arms", strength=1.2),
        "def_vehicle": DefenseDefinition("def_vehicle", strength=1.6),
        "def_air": DefenseDefinition("def_air", strength=1.9),
    }


def _default_unit_tiers() -> Dict[str, Tuple[TierDefinition, ...]]:
    return {
        "infantry": (
            TierDefinition("M4A1 Rifle Team", "assets/models/infantry/tier_1.bam"),
            TierDefinition("M4A1 SOPMOD Team", "assets/models/infantry/tier_2.bam"),
            TierDefinition("M27 IAR Squad", "assets/models/infantry/tier_3.bam"),
            TierDefinition("XM7 NGSW Squad", "assets/models/infantry/tier_4.bam"),
        ),
        "ifv": (
            TierDefinition("M2 Bradley", "assets/models/ifv/tier_1.bam"),
            TierDefinition("M2A3 Bradley", "assets/models/ifv/tier_2.bam"),
            TierDefinition("M1126 Stryker", "assets/models/ifv/tier_3.bam"),
            TierDefinition("AMPV", "assets/models/ifv/tier_4.bam"),
        ),
        "tank": (
            TierDefinition("M1A1 Abrams", "assets/models/tank/tier_1.bam"),
            TierDefinition("M1A2 SEP v2", "assets/models/tank/tier_2.bam"),
            TierDefinition("M1A2 SEP v3", "assets/models/tank/tier_3.bam"),
            TierDefinition("M1A2 SEP v4", "assets/models/tank/tier_4.bam"),
        ),
        "aircraft": (
            TierDefinition("F-14 Tomcat", "assets/models/aircraft/tier_1.bam"),
            TierDefinition("F-16 Fighting Falcon", "assets/models/aircraft/tier_2.bam"),
            TierDefinition("F-35 Lightning II", "assets/models/aircraft/tier_3.bam"),
            TierDefinition("F-22 Raptor", "assets/models/aircraft/tier_4.bam"),
        ),
    }


def _default_defense_tiers() -> Dict[str, Tuple[TierDefinition, ...]]:
    return {
        "def_arms": (
            TierDefinition("M240B Line", "assets/models/defense/arms_tier_1.bam"),
            TierDefinition("Mk 19 Grid", "assets/models/defense/arms_tier_2.bam"),
            TierDefinition("M2HB Emplacements", "assets/models/defense/arms_tier_3.bam"),
            TierDefinition("XM914 Arrays", "assets/models/defense/arms_tier_4.bam"),
        ),
        "def_vehicle": (
            TierDefinition("M220 TOW Line", "assets/models/defense/vehicle_tier_1.bam"),
            TierDefinition("Javelin Nests", "assets/models/defense/vehicle_tier_2.bam"),
            TierDefinition("M1134 ATGM Grid", "assets/models/defense/vehicle_tier_3.bam"),
            TierDefinition("M1299 Overwatch", "assets/models/defense/vehicle_tier_4.bam"),
        ),
        "def_air": (
            TierDefinition("Avenger SHORAD", "assets/models/defense/air_tier_1.bam"),
            TierDefinition("NASAMS Battery", "assets/models/defense/air_tier_2.bam"),
            TierDefinition("Patriot Battery", "assets/models/defense/air_tier_3.bam"),
            TierDefinition("THAAD Battery", "assets/models/defense/air_tier_4.bam"),
        ),
    }


def _default_air_postures() -> Dict[str, AirPostureDefinition]:
    return {
        "ISR": AirPostureDefinition("ISR", cost_per_tick=4),
        "SEAD": AirPostureDefinition("SEAD", cost_per_tick=8, defense_suppression=0.25),
        "INTERDICT": AirPostureDefinition("INTERDICT", cost_per_tick=9, logistics_strike=1.2),
        "DEEP_STRIKE": AirPostureDefinition("DEEP_STRIKE", cost_per_tick=12, industry_strike=1.4),
        "CAS": AirPostureDefinition("CAS", cost_per_tick=10, pressure_bonus=1.6),
    }


def _default_operations() -> Dict[str, OperationDefinition]:
    return {
        "strike_factories": OperationDefinition(
            key="strike_factories",
            name="Strike Factories",
            cost=80,
            target="industry",
            magnitude=2.4,
            delay=2,
            duration=4,
        ),
        "hit_logistics": OperationDefinition(
            key="hit_logistics",
            name="Hit Logistics",
            cost=65,
            target="logistics",
            magnitude=2.0,
            delay=1,
            duration=3,
        ),
        "suppress_defenses": OperationDefinition(
            key="suppress_defenses",
            name="Suppress Defenses",
            cost=55,
            target="defense",
            magnitude=1.8,
            delay=1,
            duration=3,
        ),
    }


def _default_objectives() -> Tuple[ObjectiveDefinition, ...]:
    return (
        ObjectiveDefinition("Industrial Port", 30.0),
        ObjectiveDefinition("Airbase Cluster", 50.0),
        ObjectiveDefinition("Supply Spine", 70.0),
    )


@dataclass(frozen=True)
class SimulationSettings:
    economy: EconomySettings = EconomySettings()
    production: ProductionSettings = ProductionSettings()
    frontline: FrontlineSettings = FrontlineSettings()
    combat: CombatSettings = CombatSettings()
    escalation: EscalationSettings = EscalationSettings()
    victory: VictorySettings = VictorySettings()
    units: Dict[str, UnitDefinition] = field(default_factory=_default_units)
    defenses: Dict[str, DefenseDefinition] = field(default_factory=_default_defenses)
    air_postures: Dict[str, AirPostureDefinition] = field(default_factory=_default_air_postures)
    operations: Dict[str, OperationDefinition] = field(default_factory=_default_operations)
    objectives: Tuple[ObjectiveDefinition, ...] = field(default_factory=_default_objectives)
    unit_tiers: Dict[str, Tuple[TierDefinition, ...]] = field(default_factory=_default_unit_tiers)
    defense_tiers: Dict[str, Tuple[TierDefinition, ...]] = field(default_factory=_default_defense_tiers)
