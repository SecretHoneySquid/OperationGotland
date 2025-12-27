from __future__ import annotations

from dataclasses import dataclass
from typing import List, Sequence

from operation_gotland.simulation.events import EventKind, SimEvent
from operation_gotland.simulation.state import GameState
from operation_gotland.simulation.systems import SimulationSystem


@dataclass
class SimulationFrame:
    tick: int
    state: GameState
    events: List[SimEvent]


class SimulationEngine:
    def __init__(self, state: GameState, systems: Sequence[SimulationSystem]) -> None:
        self.state = state
        self.systems = list(systems)

    def tick(self, steps: int = 1) -> SimulationFrame:
        events: List[SimEvent] = []
        for _ in range(max(1, steps)):
            if self.state.winner:
                break
            self.state.tick += 1
            events.append(SimEvent(tick=self.state.tick, kind=EventKind.TICK, payload={}))
            for system in self.systems:
                system.update(self.state, events)
        return SimulationFrame(tick=self.state.tick, state=self.state, events=events)
