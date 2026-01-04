from __future__ import annotations

from typing import List, Tuple

from operation_gotland.simulation.engine import SimulationEngine
from operation_gotland.simulation.factories import FactoryCatalog, default_factory_catalog
from operation_gotland.simulation.state import FrontlineState, GameState, PlayerState, SimulationConfig
from operation_gotland.simulation.systems import (
    BuildQueueSystem,
    CombatSystem,
    EconomySystem,
    FrontlineSystem,
    ProductionSystem,
    SimulationSystem,
    SortieSystem,
    SupplySystem,
    VictorySystem,
)


def create_default_state(
    config: SimulationConfig, player1_name: str = "Player 1", player2_name: str = "Player 2"
) -> GameState:
    player1 = PlayerState(name=player1_name)
    player2 = PlayerState(name=player2_name)
    player1.economy.credits = config.base_credits
    player2.economy.credits = config.base_credits
    midpoint = config.frontline_min + (config.frontline_max - config.frontline_min) * 0.5
    frontline = FrontlineState(position=midpoint)
    return GameState(tick=0, player1=player1, player2=player2, frontline=frontline)


def create_default_systems(
    config: SimulationConfig, factories: FactoryCatalog
) -> List[SimulationSystem]:
    return [
        EconomySystem(config),
        BuildQueueSystem(config, factories),
        SortieSystem(config),
        ProductionSystem(config),
        CombatSystem(config),
        SupplySystem(config),
        FrontlineSystem(config),
        VictorySystem(config),
    ]


def create_default_engine(
    config: SimulationConfig | None = None,
) -> Tuple[SimulationEngine, FactoryCatalog]:
    sim_config = config or SimulationConfig()
    factories = default_factory_catalog(sim_config)
    state = create_default_state(sim_config)
    systems = create_default_systems(sim_config, factories)
    return SimulationEngine(state=state, systems=systems), factories
