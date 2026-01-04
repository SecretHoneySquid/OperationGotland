from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Any, Dict


class EventKind(str, Enum):
    TICK = "tick"
    FACTORY_QUEUED = "factory_queued"
    FACTORY_COMPLETED = "factory_completed"
    SORTIE_LAUNCHED = "sortie_launched"
    SORTIE_RESOLVED = "sortie_resolved"
    FRONTLINE_MOVED = "frontline_moved"
    COMBAT_RESOLVED = "combat_resolved"
    SUPPLY_BONUS = "supply_bonus"
    MISSILE_PRESSURE = "missile_pressure"
    VICTORY = "victory"


@dataclass(frozen=True)
class SimEvent:
    tick: int
    kind: EventKind
    payload: Dict[str, Any]
