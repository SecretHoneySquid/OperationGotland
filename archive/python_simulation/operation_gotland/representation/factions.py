from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List


@dataclass(frozen=True)
class FactionDefinition:
    faction_id: str
    display_name: str
    doctrine: str
    equipment: Dict[str, List[str]]


@dataclass
class FactionCatalog:
    factions: Dict[str, FactionDefinition]

    def get(self, faction_id: str) -> FactionDefinition:
        return self.factions[faction_id]


def load_factions(path: Path) -> FactionCatalog:
    data = json.loads(path.read_text(encoding="utf-8"))
    factions: Dict[str, FactionDefinition] = {}
    for entry in data.get("factions", []):
        faction = FactionDefinition(
            faction_id=entry["id"],
            display_name=entry["display_name"],
            doctrine=entry.get("doctrine", ""),
            equipment=entry.get("equipment", {}),
        )
        factions[faction.faction_id] = faction
    return FactionCatalog(factions=factions)
