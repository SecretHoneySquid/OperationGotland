#!/usr/bin/env python3
from __future__ import annotations

import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(ROOT, "src")
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from operation_gotland.simulation.bootstrap import create_default_engine
from operation_gotland.simulation.state import SimulationConfig
from operation_gotland.ui.tk_app import GameUI


def main() -> None:
    config = SimulationConfig()
    engine, factories = create_default_engine(config)
    ui = GameUI(engine, factories, config)
    ui.run()


if __name__ == "__main__":
    main()
