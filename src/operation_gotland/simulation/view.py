"""Helpers for presenting simulation state in text form."""

from __future__ import annotations

from .models import GameState


def render_status(state: GameState) -> str:
    front = state.frontline
    lines = [
        f"Front line: {front.ratio(state.settings):.1f}%",
        _render_player(state.player1, prefix="P1"),
        _render_player(state.player2, prefix="P2"),
    ]
    if state.winner:
        lines.append(f"🏁 {state.winner} controls the front line.")
    return "\n".join(lines)


def render_history(state: GameState, limit: int = 10) -> str:
    if not state.history:
        return "No history yet."
    return "\n".join(state.history[-limit:])


def _render_player(player, prefix: str) -> str:
    prod = player.production
    return (
        f"{prefix} {player.name}: credits {player.credits}, logi {player.logistics_health:.1f} "
        f"(factor {player.logistics_factor():.2f}) | prod -> veh {prod.vehicles:.1f}, "
        f"arms {prod.arms:.1f}, air {prod.aircraft:.1f}, def {prod.defense:.1f} | "
        f"structures {sum(player.structures.values())}"
    )
