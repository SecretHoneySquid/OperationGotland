from __future__ import annotations

from typing import Protocol

from operation_gotland.visualization.scene import SceneState


class Renderer(Protocol):
    def render(self, scene: SceneState) -> None:
        ...
