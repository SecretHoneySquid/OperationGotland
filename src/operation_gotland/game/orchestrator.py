from __future__ import annotations

from dataclasses import dataclass

from operation_gotland.representation.mapper import RepresentationMapper
from operation_gotland.simulation.engine import SimulationEngine
from operation_gotland.visualization.composer import SceneComposer
from operation_gotland.visualization.renderer import Renderer


@dataclass
class GameOrchestrator:
    simulation: SimulationEngine
    representation: RepresentationMapper
    composer: SceneComposer
    renderer: Renderer

    def tick(self, steps: int = 1) -> None:
        sim_frame = self.simulation.tick(steps)
        rep_frame = self.representation.map_frame(sim_frame)
        scene = self.composer.compose(rep_frame)
        self.renderer.render(scene)
