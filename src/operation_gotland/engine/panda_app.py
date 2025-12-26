"""Panda3D bootstrapper for the Command & Conquer-style presentation."""

from __future__ import annotations

from typing import Optional

from operation_gotland.simulation.runtime import SimulationRuntime


class CncPandaApplication:
    """
    Thin wrapper around Panda3D that owns the render loop and bridges it to the
    simulation runtime. Importing Panda3D is deferred to runtime so the
    headless flow keeps working without the dependency installed.
    """

    def __init__(self, runtime: SimulationRuntime) -> None:
        self.runtime = runtime
        self._engine: Optional["ShowBase"] = None

    def boot(self) -> None:
        from direct.showbase.ShowBase import ShowBase  # type: ignore
        from panda3d.core import WindowProperties, load_prc_file_data  # type: ignore

        load_prc_file_data("", "window-title Operation Gotland - Massive Front")
        self._engine = ShowBase()
        props = WindowProperties()
        props.setSize(1600, 900)
        self._engine.win.request_properties(props)
        self._engine.task_mgr.add(self._advance_simulation, "advance-simulation")
        self._build_scene()
        self._engine.run()

    def _build_scene(self) -> None:
        assert self._engine is not None
        render = self._engine.render
        render.setShaderAuto()  # type: ignore[attr-defined]
        # Placeholder: lighting, terrain, and unit placement will be filled in later.

    def _advance_simulation(self, task: "Task") -> int:
        """Advance the simulation and allow Panda3D to continue its task chain."""
        self.runtime.tick()
        return task.cont
