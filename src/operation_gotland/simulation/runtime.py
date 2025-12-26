"""Headless simulation loop for the larger RTS version."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Iterable, Optional

from .config import SimulationSettings
from .models import FrontlineState, GameState, PlayerState, QueuedStructure
from .store import StructureBlueprint


@dataclass
class SimulationClock:
    tick_rate: float = 1.0  # ticks per second placeholder


class SimulationRuntime:
    """
    A minimal orchestrator that advances the state and exposes hooks that the
    rendering engine can subscribe to.
    """

    def __init__(
        self,
        settings: SimulationSettings,
        blueprints: Dict[str, StructureBlueprint],
        clock: Optional[SimulationClock] = None,
    ) -> None:
        self.settings = settings
        self.blueprints = blueprints
        self.clock = clock or SimulationClock()
        self.state = GameState(
            player1=PlayerState("Player 1", credits=settings.economy.base_credits),
            player2=PlayerState("Player 2", credits=settings.economy.base_credits),
            settings=settings,
            frontline=FrontlineState(position=settings.frontline.max_position / 2.0),
        )

    def queue_structure(self, player_key: str, blueprint_id: str, quantity: int = 1) -> None:
        if blueprint_id not in self.blueprints:
            raise ValueError(f"Unknown blueprint '{blueprint_id}'.")
        if quantity <= 0:
            raise ValueError("Quantity must be positive.")
        player = self._player(player_key)
        blueprint = self.blueprints[blueprint_id]
        total_cost = blueprint.cost * quantity
        if player.credits < total_cost:
            raise ValueError(f"{player.name} needs {total_cost} credits for {quantity}x {blueprint.name}.")
        for _ in range(quantity):
            if len(player.build_queue) >= self.settings.economy.build_queue_max:
                raise ValueError(f"{player.name} build queue full.")
            player.build_queue.append(QueuedStructure(blueprint_id=blueprint.key, remaining=blueprint.build_time))
        player.credits -= total_cost
        player.structures.setdefault(blueprint.key, 0)
        self.state.record(f"{player.name} queued {quantity}x {blueprint.name}.")

    def tick(self, count: int = 1) -> GameState:
        for _ in range(max(1, count)):
            self._step_once()
            if self.state.winner:
                break
        return self.state

    def _step_once(self) -> None:
        self.state.tick += 1
        self._apply_income()
        self._process_builds()
        self._update_frontline()
        self._check_victory()
        self.state.record(f"Tick {self.state.tick}: front {self.state.frontline.ratio(self.settings):.1f}%")

    def _apply_income(self) -> None:
        for player in (self.state.player1, self.state.player2):
            player.apply_income(self.settings)

    def _process_builds(self) -> None:
        for player in (self.state.player1, self.state.player2):
            if not player.build_queue:
                continue
            still_building: list[QueuedStructure] = []
            capacity = player.build_capacity()
            active = player.build_queue[:capacity]
            deferred = player.build_queue[capacity:]
            for order in active:
                order.remaining -= 1
                if order.remaining <= 0:
                    player.structures[order.blueprint_id] = player.structures.get(order.blueprint_id, 0) + 1
                    self.state.record(f"{player.name} completed {order.blueprint_id}.")
                else:
                    still_building.append(order)
            still_building.extend(deferred)
            player.build_queue = still_building

    def _update_frontline(self) -> None:
        """Placeholder for pressure calculations; this will later mirror the rich prototype logic."""
        front = self.state.frontline
        pressure = 0.1  # tiny nudge to prove the loop moves
        front.position = min(
            self.settings.frontline.max_position,
            max(self.settings.frontline.min_position, front.position + pressure),
        )

    def _check_victory(self) -> None:
        if self.state.winner:
            return
        if self.state.frontline.position <= self.settings.frontline.min_position:
            self.state.winner = self.state.player2.name
        elif self.state.frontline.position >= self.settings.frontline.max_position:
            self.state.winner = self.state.player1.name

    def _player(self, key: str) -> PlayerState:
        normalized = key.lower()
        if normalized in {"p1", "1", "player1"}:
            return self.state.player1
        return self.state.player2
