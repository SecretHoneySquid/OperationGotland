"""Entrypoint wiring for the next-gen Operation Gotland experience."""

from __future__ import annotations

import argparse
import sys
from typing import Callable

from operation_gotland.engine.panda_app import CncPandaApplication
from operation_gotland.simulation.config import SimulationSettings
from operation_gotland.simulation.runtime import SimulationRuntime
from operation_gotland.simulation.store import default_blueprints
from operation_gotland.simulation.view import render_history, render_status


def build_runtime() -> SimulationRuntime:
    settings = SimulationSettings()
    blueprints = default_blueprints()
    return SimulationRuntime(settings=settings, blueprints=blueprints)


def run_headless(runtime: SimulationRuntime, ticks: int) -> None:
    runtime.tick(ticks)
    state = runtime.state
    print(render_status(state))
    print()
    print(render_history(state))


def run_panda(runtime: SimulationRuntime) -> None:
    app = CncPandaApplication(runtime)
    app.boot()


def main(argv: list[str] | None = None, *, runner: Callable[[SimulationRuntime], None] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Operation Gotland - Massive Front skeleton.")
    parser.add_argument("--ticks", type=int, default=5, help="Headless ticks to advance when running without the engine.")
    parser.add_argument(
        "--engine",
        choices=("headless", "panda"),
        default="headless",
        help="Select the presentation layer. Panda3D is optional and only imported when requested.",
    )
    args = parser.parse_args(argv)

    runtime = build_runtime()

    if runner:
        runner(runtime)
        return

    if args.engine == "panda":
        run_panda(runtime)
    else:
        run_headless(runtime, args.ticks)


if __name__ == "__main__":
    main(sys.argv[1:])
