from __future__ import annotations

from dataclasses import dataclass, field
from typing import List


@dataclass
class PresenceScaling:
    infantry_per_platoon: float = 40.0
    vehicles_per_column: float = 20.0
    tanks_per_column: float = 12.0
    aircraft_per_sortie: float = 6.0
    helicopters_per_flight: float = 4.0
    missiles_per_battery: float = 1.0
    air_defense_per_site: float = 8.0
    logistics_per_convoy: float = 25.0
    industry_activity_divisor: float = 200.0


@dataclass
class TierThresholds:
    thresholds: List[float] = field(default_factory=list)

    def resolve(self, score: float) -> int:
        for idx, threshold in enumerate(self.thresholds):
            if score < threshold:
                return idx
        return len(self.thresholds)


@dataclass
class RepresentationConfig:
    presence: PresenceScaling = field(default_factory=PresenceScaling)
    armor_tiers: TierThresholds = field(default_factory=lambda: TierThresholds([40.0, 90.0, 160.0]))
    infantry_tiers: TierThresholds = field(default_factory=lambda: TierThresholds([40.0, 90.0, 160.0]))
    air_tiers: TierThresholds = field(default_factory=lambda: TierThresholds([15.0, 35.0, 60.0]))
    air_defense_tiers: TierThresholds = field(default_factory=lambda: TierThresholds([20.0, 50.0, 90.0]))
    logistics_tiers: TierThresholds = field(default_factory=lambda: TierThresholds([60.0, 90.0, 130.0]))
