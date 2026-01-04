from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional


@dataclass
class TierSelection:
    armor: int
    infantry: int
    air: int
    air_defense: int
    logistics: int


@dataclass
class SidePresence:
    infantry_platoons: int
    vehicle_columns: int
    tank_columns: int
    aircraft_sorties: int
    helicopter_flights: int
    missile_batteries: int
    air_defense_sites: int
    logistics_convoys: int
    industry_activity: float
    infrastructure_damage: float


@dataclass
class FrontlineVisual:
    ratio: float
    momentum: float
    last_breakthrough: bool


@dataclass
class SideRepresentation:
    faction_id: str
    tiers: TierSelection
    presence: SidePresence


@dataclass
class VisualEvent:
    kind: str
    side: Optional[str]
    intensity: float
    payload: Dict[str, float] = field(default_factory=dict)


@dataclass
class RepresentationFrame:
    tick: int
    frontline: FrontlineVisual
    sides: Dict[str, SideRepresentation]
    events: List[VisualEvent] = field(default_factory=list)
