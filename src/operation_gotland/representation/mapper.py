from __future__ import annotations

from typing import Dict

from operation_gotland.representation.config import RepresentationConfig
from operation_gotland.representation.models import (
    FrontlineVisual,
    RepresentationFrame,
    SidePresence,
    SideRepresentation,
    TierSelection,
    VisualEvent,
)
from operation_gotland.representation.tiers import TierResolver
from operation_gotland.simulation.engine import SimulationFrame
from operation_gotland.simulation.events import EventKind
from operation_gotland.simulation.state import PlayerState


class RepresentationMapper:
    def __init__(
        self,
        config: RepresentationConfig,
        tier_resolver: TierResolver,
        side_factions: Dict[str, str],
    ) -> None:
        self.config = config
        self.tier_resolver = tier_resolver
        self.side_factions = side_factions

    def map_frame(self, sim_frame: SimulationFrame) -> RepresentationFrame:
        p1 = sim_frame.state.player1
        p2 = sim_frame.state.player2
        sides = {
            "p1": self._build_side("p1", p1),
            "p2": self._build_side("p2", p2),
        }
        last_breakthrough = any(event.kind == EventKind.FRONTLINE_MOVED for event in sim_frame.events)
        frontline = FrontlineVisual(
            ratio=sim_frame.state.frontline.position,
            momentum=sim_frame.state.frontline.pressure_toward_p2 - sim_frame.state.frontline.pressure_toward_p1,
            last_breakthrough=last_breakthrough,
        )
        events = [
            VisualEvent(kind=event.kind.value, side=None, intensity=1.0, payload={})
            for event in sim_frame.events
        ]
        return RepresentationFrame(tick=sim_frame.tick, frontline=frontline, sides=sides, events=events)

    def _build_side(self, side_key: str, player: PlayerState) -> SideRepresentation:
        tiers = self._tiers_from_capabilities(player)
        presence = self._presence_from_units(player)
        faction_id = self.side_factions.get(side_key, "unknown")
        return SideRepresentation(faction_id=faction_id, tiers=tiers, presence=presence)

    def _tiers_from_capabilities(self, player: PlayerState) -> TierSelection:
        capabilities = player.capability_scores
        return TierSelection(
            armor=self.tier_resolver.resolve(capabilities.armor, self.config.armor_tiers),
            infantry=self.tier_resolver.resolve(capabilities.infantry, self.config.infantry_tiers),
            air=self.tier_resolver.resolve(capabilities.air, self.config.air_tiers),
            air_defense=self.tier_resolver.resolve(capabilities.air_defense, self.config.air_defense_tiers),
            logistics=self.tier_resolver.resolve(capabilities.logistics, self.config.logistics_tiers),
        )

    def _presence_from_units(self, player: PlayerState) -> SidePresence:
        units = player.units
        scaling = self.config.presence
        infantry_platoons = int(units.arms / scaling.infantry_per_platoon)
        vehicle_columns = int(units.vehicles / scaling.vehicles_per_column)
        tank_columns = int(units.tanks / scaling.tanks_per_column)
        aircraft_sorties = int(units.aircraft / scaling.aircraft_per_sortie)
        helicopter_flights = int(units.helicopters / scaling.helicopters_per_flight)
        missile_batteries = int(units.missiles / scaling.missiles_per_battery)
        air_defense_sites = int(units.def_air / scaling.air_defense_per_site)
        logistics_convoys = int(player.logistics_health / scaling.logistics_per_convoy)
        industry_activity = (
            player.production.vehicles
            + player.production.arms
            + player.production.aircraft
            + player.production.defense
        ) / scaling.industry_activity_divisor
        infrastructure_damage = max(0.0, 1.0 - (player.logistics_health / 100.0))
        return SidePresence(
            infantry_platoons=max(1, infantry_platoons),
            vehicle_columns=max(1, vehicle_columns),
            tank_columns=max(0, tank_columns),
            aircraft_sorties=max(0, aircraft_sorties),
            helicopter_flights=max(0, helicopter_flights),
            missile_batteries=max(0, missile_batteries),
            air_defense_sites=max(0, air_defense_sites),
            logistics_convoys=max(1, logistics_convoys),
            industry_activity=industry_activity,
            infrastructure_damage=infrastructure_damage,
        )
