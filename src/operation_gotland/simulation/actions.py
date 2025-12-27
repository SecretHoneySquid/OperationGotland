from __future__ import annotations

from typing import List, Optional

from operation_gotland.simulation.events import EventKind, SimEvent
from operation_gotland.simulation.factories import FactoryCatalog, missile_authorization_allowed
from operation_gotland.simulation.state import BuildOrder, GameState, SortieState, SimulationConfig


def resolve_player(state: GameState, player_key: str):
    return state.player1 if player_key.lower() in ("1", "p1", "player1") else state.player2


def queue_factory_purchase(
    state: GameState,
    player_key: str,
    factory_id: int,
    quantity: int,
    factories: FactoryCatalog,
    config: SimulationConfig,
    events: Optional[List[SimEvent]] = None,
) -> None:
    if factory_id not in factories.factories:
        raise ValueError(f"Factory {factory_id} is not in the store.")
    if quantity <= 0:
        raise ValueError("Quantity must be at least 1.")

    player = resolve_player(state, player_key)
    factory = factories.get(factory_id)
    if factory.factory_id == 10 and not missile_authorization_allowed(player):
        raise ValueError("Missile Corps Authorization requires armor plants or Aircraft Works + 3 Helipads.")
    if factory.factory_id == 11 and not player.missile_unlocked:
        raise ValueError("Buy Missile Corps Authorization before purchasing launchers.")
    if factory.factory_id == 12 and player.purchases.get(4, 0) <= 0:
        raise ValueError("Helipads require Aircraft Works.")

    total_cost = factory.cost * quantity
    if player.economy.credits < total_cost:
        raise ValueError(
            f"{player.name} lacks credits ({player.economy.credits}) for {quantity}x {factory.name} (cost {total_cost})."
        )

    for _ in range(quantity):
        if len(player.economy.build_queue) >= config.build_queue_max:
            raise ValueError(f"{player.name} purchase queue full (max {config.build_queue_max}).")
        player.economy.build_queue.append(BuildOrder(factory_id=factory.factory_id, remaining=factory.build_time))
    player.economy.credits -= total_cost

    if events is not None:
        events.append(
            SimEvent(
                tick=state.tick,
                kind=EventKind.FACTORY_QUEUED,
                payload={
                    "player": player.name,
                    "factory_id": factory.factory_id,
                    "quantity": quantity,
                    "total_cost": total_cost,
                },
            )
        )


def launch_sortie(
    state: GameState,
    player_key: str,
    size_key: str,
    target_key: str,
    config: SimulationConfig,
    events: Optional[List[SimEvent]] = None,
) -> None:
    if state.winner:
        raise ValueError("Game is over.")

    player = resolve_player(state, player_key)
    size_map = {"small": 0.1, "sm": 0.1, "med": 0.25, "medium": 0.25, "large": 0.5, "lg": 0.5}
    target_map = {
        "vehicles": "vehicles",
        "arms": "arms",
        "air": "aircraft",
        "def": "defense",
        "logi": "logistics",
        "logistics": "logistics",
    }

    if size_key.lower() not in size_map:
        raise ValueError("Size must be small/med/large.")
    if target_key.lower() not in target_map:
        raise ValueError("Target must be one of: vehicles, arms, air, def, logi.")
    if player.units.aircraft < 1.0:
        raise ValueError(f"{player.name} has no aircraft to launch.")

    frac = size_map[size_key.lower()]
    committed = max(1.0, round(player.units.aircraft * frac, 1))
    committed = min(committed, player.units.aircraft)
    player.units.aircraft -= committed

    target_attr = target_map[target_key.lower()]
    state.sorties.append(
        SortieState(
            owner=player.name,
            target=target_attr,
            committed=committed,
            remaining=config.sortie_duration,
        )
    )

    if events is not None:
        events.append(
            SimEvent(
                tick=state.tick,
                kind=EventKind.SORTIE_LAUNCHED,
                payload={
                    "player": player.name,
                    "target": target_attr,
                    "committed": committed,
                },
            )
        )
