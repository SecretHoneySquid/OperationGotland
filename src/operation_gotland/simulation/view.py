"""Helpers for presenting simulation state in text form."""

from __future__ import annotations

from .models import GameState


def render_status(state: GameState) -> str:
    front = state.frontline
    phase = _phase_label(state)
    lines = [
        f"Front line: {front.ratio(state.settings):.1f}%",
        f"Escalation: {state.escalation:.1f} ({phase})",
        _render_objectives(state),
        _render_player(state.player1, prefix="P1"),
        _render_player(state.player2, prefix="P2"),
    ]
    if state.winner:
        reason = f" ({state.victory_reason})" if state.victory_reason else ""
        lines.append(f"Winner: {state.winner}{reason}")
    return "\n".join(lines)


def render_history(state: GameState, limit: int = 10) -> str:
    if not state.history:
        return "No history yet."
    return "\n".join(state.history[-limit:])


def _render_player(player, prefix: str) -> str:
    prod = player.production
    units = player.units
    return (
        f"{prefix} {player.name}: credits {player.credits}, logi {player.logistics_health:.1f}, "
        f"industry {player.industry_health:.1f}, defense {player.defense_health:.1f} | "
        f"air {player.air_posture} | prod -> veh {prod.vehicles:.1f}, arms {prod.arms:.1f}, "
        f"air {prod.aircraft:.1f}, def {prod.defense:.1f} | "
        f"units inf {units.infantry:.1f}, ifv {units.ifv:.1f}, tank {units.tank:.1f}, "
        f"air {units.aircraft:.1f} | "
        f"def {units.def_arms:.1f}/{units.def_vehicle:.1f}/{units.def_air:.1f} | "
        f"structures {sum(player.structures.values())}"
    )


def _render_objectives(state: GameState) -> str:
    if not state.objectives:
        return "Objectives: none"
    parts = []
    for obj in state.objectives:
        owner = obj.owner or "Neutral"
        parts.append(f"{obj.name}({owner})")
    return "Objectives: " + ", ".join(parts)


def _phase_label(state: GameState) -> str:
    t1, t2 = state.settings.escalation.phase_thresholds
    if state.escalation >= t2:
        return "Phase III"
    if state.escalation >= t1:
        return "Phase II"
    return "Phase I"
