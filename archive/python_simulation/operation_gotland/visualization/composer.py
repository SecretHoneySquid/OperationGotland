from __future__ import annotations

from operation_gotland.representation.models import RepresentationFrame
from operation_gotland.visualization.scene import SceneState


class SceneComposer:
    def compose(self, frame: RepresentationFrame) -> SceneState:
        scene = SceneState()
        scene.metadata["frontline_ratio"] = frame.frontline.ratio
        scene.metadata["frontline_momentum"] = frame.frontline.momentum
        return scene
