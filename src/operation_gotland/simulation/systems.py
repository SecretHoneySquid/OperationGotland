from __future__ import annotations

from typing import List, Protocol

from operation_gotland.simulation.events import EventKind, SimEvent
from operation_gotland.simulation.factories import FactoryCatalog, apply_factory_effect
from operation_gotland.simulation.rules import (
    apply_breakthrough_attrition,
    apply_losses,
    build_capacity,
    casualties_from,
    clamp,
    compute_frontline_pressure,
    income_this_tick,
    logistics_factor,
    missile_penalty_value,
    update_pressure_progress,
)
from operation_gotland.simulation.state import GameState, SimulationConfig


class SimulationSystem(Protocol):
    name: str

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        ...


DEFAULT_SYSTEM_SEQUENCE = (
    "economy",
    "build_queue",
    "sorties",
    "production",
    "combat",
    "supply",
    "frontline",
    "victory",
)


class EconomySystem:
    name = "economy"

    def __init__(self, config: SimulationConfig) -> None:
        self.config = config

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner:
            return
        for player, opponent in (
            (state.player1, state.player2),
            (state.player2, state.player1),
        ):
            penalty = missile_penalty_value(opponent, state.frontline.position, self.config)
            player.logistics_penalty = penalty
            if penalty > 0:
                events.append(
                    SimEvent(
                        tick=state.tick,
                        kind=EventKind.MISSILE_PRESSURE,
                        payload={"player": player.name, "penalty": penalty},
                    )
                )
            player.economy.credits += income_this_tick(player, self.config)


class BuildQueueSystem:
    name = "build_queue"

    def __init__(self, config: SimulationConfig, factories: FactoryCatalog) -> None:
        self.config = config
        self.factories = factories

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner:
            return
        for player in (state.player1, state.player2):
            if not player.economy.build_queue:
                continue
            still_building = []
            parallel_slots = build_capacity(player)
            to_process = player.economy.build_queue[:parallel_slots]
            deferred = player.economy.build_queue[parallel_slots:]
            for order in to_process:
                order.remaining -= 1
                if order.remaining <= 0:
                    apply_factory_effect(player, order.factory_id, self.config)
                    player.purchases[order.factory_id] = player.purchases.get(order.factory_id, 0) + 1
                    events.append(
                        SimEvent(
                            tick=state.tick,
                            kind=EventKind.FACTORY_COMPLETED,
                            payload={"player": player.name, "factory_id": order.factory_id},
                        )
                    )
                else:
                    still_building.append(order)
            player.economy.build_queue = still_building + deferred


class SortieSystem:
    name = "sorties"

    def __init__(self, config: SimulationConfig) -> None:
        self.config = config

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner or not state.sorties:
            return
        remaining = []
        for sortie in state.sorties:
            sortie.remaining -= 1
            if sortie.remaining > 0:
                remaining.append(sortie)
                continue

            attacker = state.player1 if sortie.owner == state.player1.name else state.player2
            defender = state.player2 if attacker is state.player1 else state.player1

            attack_strength = sortie.committed
            defense_strength = defender.units.def_air * 0.8 + defender.units.aircraft * 0.6 + 5.0
            success = attack_strength / (attack_strength + defense_strength + 1.0)
            damage = success * 12.0

            if sortie.target == "logistics":
                defender.logistics_health = clamp(defender.logistics_health - damage * 0.7, 1.0, 250.0)
            elif sortie.target == "vehicles":
                defender.production.vehicles = max(0.0, defender.production.vehicles - damage)
            elif sortie.target == "arms":
                defender.production.arms = max(0.0, defender.production.arms - damage)
            elif sortie.target == "aircraft":
                defender.production.aircraft = max(0.0, defender.production.aircraft - damage)
            elif sortie.target == "defense":
                defender.production.defense = max(0.0, defender.production.defense - damage)

            loss_rate = (1.0 - success) * 0.6 + defender.units.def_air * 0.005
            losses = min(sortie.committed, sortie.committed * loss_rate)
            survivors = max(0.0, sortie.committed - losses)
            attacker.units.aircraft += survivors

            events.append(
                SimEvent(
                    tick=state.tick,
                    kind=EventKind.SORTIE_RESOLVED,
                    payload={
                        "attacker": attacker.name,
                        "defender": defender.name,
                        "target": sortie.target,
                        "damage": damage,
                        "losses": losses,
                        "survivors": survivors,
                    },
                )
            )
        state.sorties = remaining


class ProductionSystem:
    name = "production"

    def __init__(self, config: SimulationConfig) -> None:
        self.config = config

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner:
            return
        if state.tick % 5 == 0:
            for player in (state.player1, state.player2):
                if player.helipads > 0:
                    player.units.helicopters += player.helipads * 1

        for player in (state.player1, state.player2):
            factor = logistics_factor(player)
            prod = player.production
            units = player.units
            units.vehicles += prod.vehicles * self.config.unit_build_rate * factor
            units.arms += prod.arms * self.config.unit_build_rate * factor
            units.aircraft += prod.aircraft * self.config.air_unit_build_rate * factor
            units.def_air += prod.defense * self.config.unit_build_rate * factor * 0.4
            units.def_vehicle += prod.defense * self.config.unit_build_rate * factor * 0.35
            units.def_arms += prod.defense * self.config.unit_build_rate * factor * 0.25
            tank_input = ((prod.vehicles + prod.arms) / 2.0) + prod.tank_bonus
            units.tanks += tank_input * self.config.unit_build_rate * factor * 0.35


class CombatSystem:
    name = "combat"

    def __init__(self, config: SimulationConfig) -> None:
        self.config = config

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner:
            return
        p1_losses = casualties_from(state.player2, state.player1, self.config)
        p2_losses = casualties_from(state.player1, state.player2, self.config)

        if any(val > 0 for val in p1_losses.values()):
            apply_losses(state.player1, p1_losses)
        if any(val > 0 for val in p2_losses.values()):
            apply_losses(state.player2, p2_losses)

        if any(val > 0 for val in p1_losses.values()) or any(val > 0 for val in p2_losses.values()):
            events.append(
                SimEvent(
                    tick=state.tick,
                    kind=EventKind.COMBAT_RESOLVED,
                    payload={"p1_losses": p1_losses, "p2_losses": p2_losses},
                )
            )


class SupplySystem:
    name = "supply"

    def __init__(self, config: SimulationConfig) -> None:
        self.config = config

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner or state.tick % 5 != 0:
            return
        for player in (state.player1, state.player2):
            if player.economy.supply_zones > 0:
                bonus = player.economy.supply_zones * self.config.supply_zone_bonus
                player.economy.credits += bonus
                events.append(
                    SimEvent(
                        tick=state.tick,
                        kind=EventKind.SUPPLY_BONUS,
                        payload={"player": player.name, "bonus": bonus},
                    )
                )


class FrontlineSystem:
    name = "frontline"

    def __init__(self, config: SimulationConfig) -> None:
        self.config = config

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner:
            return
        p1_net, p1_components = compute_frontline_pressure(state.player1, state.player2)
        p2_net, p2_components = compute_frontline_pressure(state.player2, state.player1)
        state.frontline.pressure_toward_p2 = update_pressure_progress(
            state.frontline.pressure_toward_p2, p1_net, p2_net, self.config
        )
        state.frontline.pressure_toward_p1 = update_pressure_progress(
            state.frontline.pressure_toward_p1, p2_net, p1_net, self.config
        )

        moves = []
        if state.frontline.pressure_toward_p2 >= self.config.pressure_threshold:
            moves.append(("p1", p1_net))
        if state.frontline.pressure_toward_p1 >= self.config.pressure_threshold:
            moves.append(("p2", p2_net))

        if not moves:
            return

        mover, mover_net = max(moves, key=lambda item: item[1])
        if mover == "p1":
            state.frontline.position = clamp(
                state.frontline.position + self.config.frontline_segment,
                self.config.frontline_min,
                self.config.frontline_max,
            )
        else:
            state.frontline.position = clamp(
                state.frontline.position - self.config.frontline_segment,
                self.config.frontline_min,
                self.config.frontline_max,
            )

        apply_breakthrough_attrition(state)
        events.append(
            SimEvent(
                tick=state.tick,
                kind=EventKind.FRONTLINE_MOVED,
                payload={
                    "mover": mover,
                    "net": mover_net,
                    "frontline": state.frontline.position,
                    "p1_components": p1_components,
                    "p2_components": p2_components,
                },
            )
        )

        if state.frontline.position <= self.config.frontline_min:
            state.winner = state.player2.name
            state.frontline.position = self.config.frontline_min
        elif state.frontline.position >= self.config.frontline_max:
            state.winner = state.player1.name
            state.frontline.position = self.config.frontline_max

        if state.winner:
            events.append(
                SimEvent(
                    tick=state.tick,
                    kind=EventKind.VICTORY,
                    payload={"winner": state.winner},
                )
            )
        else:
            state.frontline.pressure_toward_p2 = 0.0
            state.frontline.pressure_toward_p1 = 0.0


class VictorySystem:
    name = "victory"

    def __init__(self, config: SimulationConfig) -> None:
        self.config = config

    def update(self, state: GameState, events: List[SimEvent]) -> None:
        if state.winner:
            return
        if state.frontline.position <= self.config.frontline_min:
            state.winner = state.player2.name
            state.frontline.position = self.config.frontline_min
        elif state.frontline.position >= self.config.frontline_max:
            state.winner = state.player1.name
            state.frontline.position = self.config.frontline_max
        if state.winner:
            events.append(
                SimEvent(
                    tick=state.tick,
                    kind=EventKind.VICTORY,
                    payload={"winner": state.winner},
                )
            )
