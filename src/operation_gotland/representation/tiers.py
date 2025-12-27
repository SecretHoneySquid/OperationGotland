from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List

from operation_gotland.representation.config import TierThresholds


@dataclass(frozen=True)
class TierDefinition:
    tier: int
    label: str
    description: str


@dataclass
class TierCatalog:
    domains: Dict[str, List[TierDefinition]]


class TierResolver:
    def resolve(self, score: float, thresholds: TierThresholds) -> int:
        return thresholds.resolve(score)


def load_tiers(path: Path) -> TierCatalog:
    data = json.loads(path.read_text(encoding="utf-8"))
    domains: Dict[str, List[TierDefinition]] = {}
    for domain, tiers in data.get("domains", {}).items():
        domains[domain] = [
            TierDefinition(
                tier=entry["tier"],
                label=entry.get("label", ""),
                description=entry.get("description", ""),
            )
            for entry in tiers
        ]
    return TierCatalog(domains=domains)
