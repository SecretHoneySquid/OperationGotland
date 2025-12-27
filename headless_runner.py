#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import sys
from typing import Iterable, List

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(ROOT, "src")
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from operation_gotland.simulation.actions import launch_sortie, queue_factory_purchase
from operation_gotland.simulation.bootstrap import create_default_engine
from operation_gotland.simulation.engine import SimulationFrame
from operation_gotland.simulation.rules import logistics_factor, total_production
from operation_gotland.simulation.state import GameState, SimulationConfig


def frontline_ratio(state: GameState, config: SimulationConfig) -> float:
    span = config.frontline_max - config.frontline_min
    if span <= 0:
        return 0.0
    return round(((state.frontline.position - config.frontline_min) / span) * 100.0, 2)


def summarize_events(events: Iterable) -> str:
    counts = {}
    for event in events:
        kind = getattr(event.kind, "value", str(event.kind))
        if kind == "tick":
            continue
        counts[kind] = counts.get(kind, 0) + 1
    if not counts:
        return "Events: none"
    summary = ", ".join(f"{kind} x{count}" for kind, count in sorted(counts.items()))
    return f"Events: {summary}"


def format_player(player, config: SimulationConfig) -> str:
    prod = player.production
    units = player.units
    queue_len = len(player.economy.build_queue)
    return (
        f"{player.name}: credits {player.economy.credits} | logi {player.logistics_health:.1f} "
        f"(factor {logistics_factor(player):.2f})\n"
        f"  Prod: veh {prod.vehicles:.1f} arms {prod.arms:.1f} air {prod.aircraft:.1f} "
        f"def {prod.defense:.1f} total {total_production(player):.2f}\n"
        f"  Units: inf {units.arms:.1f} ifv {units.vehicles:.1f} tank {units.tanks:.1f} "
        f"air {units.aircraft:.1f} heli {units.helicopters:.1f} miss {units.missiles:.1f}\n"
        f"  Def: arms {units.def_arms:.1f} veh {units.def_vehicle:.1f} air {units.def_air:.1f}\n"
        f"  Queue: {queue_len}/{config.build_queue_max}"
    )


def render_state(state: GameState, config: SimulationConfig) -> str:
    ratio = frontline_ratio(state, config)
    lines = [
        f"Frontline: {ratio:.2f}% | Pressure P1->P2 {state.frontline.pressure_toward_p2:.1f} | "
        f"Pressure P2->P1 {state.frontline.pressure_toward_p1:.1f}",
        format_player(state.player1, config),
        format_player(state.player2, config),
    ]
    if state.winner:
        lines.append(f"Winner: {state.winner}")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Headless runner for Operation Gotland.")
    parser.add_argument("--ticks", type=int, default=5, help="Number of ticks to simulate.")
    parser.add_argument(
        "--buy",
        nargs=3,
        action="append",
        metavar=("PLAYER", "FACTORY", "QTY"),
        help="Queue a factory purchase before ticks. Example: --buy p1 3 2",
    )
    parser.add_argument(
        "--sortie",
        nargs=3,
        action="append",
        metavar=("PLAYER", "SIZE", "TARGET"),
        help="Launch a sortie before ticks. Example: --sortie p1 small vehicles",
    )
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Print state only (skip event summaries).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    config = SimulationConfig()
    engine, factories = create_default_engine(config)

    if args.buy:
        for player_key, factory_id, qty in args.buy:
            queue_factory_purchase(
                engine.state,
                player_key=player_key,
                factory_id=int(factory_id),
                quantity=int(qty),
                factories=factories,
                config=config,
                events=[],
            )

    if args.sortie:
        for player_key, size, target in args.sortie:
            launch_sortie(
                engine.state,
                player_key=player_key,
                size_key=size,
                target_key=target,
                config=config,
                events=[],
            )

    print(render_state(engine.state, config))
    print()

    for _ in range(max(1, args.ticks)):
        frame: SimulationFrame = engine.tick(1)
        print(f"Tick {frame.tick}")
        print(render_state(frame.state, config))
        if not args.summary_only:
            print(summarize_events(frame.events))
        print("-" * 60)
        if frame.state.winner:
            break


if __name__ == "__main__":
    main()
