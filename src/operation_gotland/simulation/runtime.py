"""Headless simulation loop for the larger RTS version."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional, Tuple

from .config import AirPostureDefinition, SimulationSettings
from .models import ActiveOperation, FrontlineState, GameState, ObjectiveState, PlayerState, QueuedStructure
from .store import StructureBlueprint


@dataclass
class SimulationClock:
    tick_rate: float = 1.0  # ticks per second placeholder


class SimulationRuntime:
    """
    A minimal orchestrator that advances the state and exposes hooks that the
    rendering engine can subscribe to.
    """

    def __init__(
        self,
        settings: SimulationSettings,
        blueprints: Dict[str, StructureBlueprint],
        clock: Optional[SimulationClock] = None,
    ) -> None:
        self.settings = settings
        self.blueprints = blueprints
        self.clock = clock or SimulationClock()
        objectives = [ObjectiveState(obj.name, obj.position) for obj in settings.objectives]
        self.state = GameState(
            player1=PlayerState("Player 1", credits=settings.economy.base_credits),
            player2=PlayerState("Player 2", credits=settings.economy.base_credits),
            settings=settings,
            frontline=FrontlineState(position=settings.frontline.max_position / 2.0),
            objectives=objectives,
        )

    def queue_structure(self, player_key: str, blueprint_id: str, quantity: int = 1) -> None:
        if blueprint_id not in self.blueprints:
            raise ValueError(f"Unknown blueprint '{blueprint_id}'.")
        if quantity <= 0:
            raise ValueError("Quantity must be positive.")
        player = self._player(player_key)
        blueprint = self.blueprints[blueprint_id]
        total_cost = blueprint.cost * quantity
        if player.credits < total_cost:
            raise ValueError(f"{player.name} needs {total_cost} credits for {quantity}x {blueprint.name}.")
        for _ in range(quantity):
            if len(player.build_queue) >= self.settings.economy.build_queue_max:
                raise ValueError(f"{player.name} build queue full.")
            player.build_queue.append(QueuedStructure(blueprint_id=blueprint.key, remaining=blueprint.build_time))
        player.credits -= total_cost
        player.structures.setdefault(blueprint.key, 0)
        self.state.record(f"{player.name} queued {quantity}x {blueprint.name}.")

    def set_production(self, player_key: str, profile) -> None:
        player = self._player(player_key)
        player.production = profile.normalized()
        self.state.record(f"{player.name} updated production priorities.")

    def set_air_posture(self, player_key: str, posture_id: str) -> None:
        if posture_id not in self.settings.air_postures:
            raise ValueError(f"Unknown air posture '{posture_id}'.")
        player = self._player(player_key)
        player.air_posture = posture_id
        self.state.record(f"{player.name} switched air posture to {posture_id}.")

    def launch_operation(self, player_key: str, operation_id: str) -> None:
        if operation_id not in self.settings.operations:
            raise ValueError(f"Unknown operation '{operation_id}'.")
        player = self._player(player_key)
        operation = self.settings.operations[operation_id]
        if player.credits < operation.cost:
            raise ValueError(f"{player.name} needs {operation.cost} credits for {operation.name}.")
        player.credits -= operation.cost
        player.operations.append(
            ActiveOperation(
                operation_id=operation.key,
                target=operation.target,
                magnitude=operation.magnitude,
                remaining_delay=operation.delay,
                remaining_duration=operation.duration,
            )
        )
        self.state.record(f"{player.name} launched {operation.name}.")

    def tick(self, count: int = 1) -> GameState:
        for _ in range(max(1, count)):
            self._step_once()
            if self.state.winner:
                break
        return self.state

    def _step_once(self) -> None:
        self.state.tick += 1
        self._apply_income()
        self._process_builds()
        self._apply_production()
        air_mods = self._apply_air_postures()
        self._process_operations()
        net_pressure = self._update_frontline(air_mods)
        self._update_escalation(net_pressure, air_mods)
        self._apply_repair()
        self._check_victory()
        self.state.record(f"Tick {self.state.tick}: front {self.state.frontline.ratio(self.settings):.1f}%")

    def _apply_income(self) -> None:
        for player in (self.state.player1, self.state.player2):
            player.apply_income(self.settings)

    def _process_builds(self) -> None:
        for player in (self.state.player1, self.state.player2):
            if not player.build_queue:
                continue
            still_building: list[QueuedStructure] = []
            capacity = player.build_capacity()
            active = player.build_queue[:capacity]
            deferred = player.build_queue[capacity:]
            for order in active:
                order.remaining -= 1
                if order.remaining <= 0:
                    player.structures[order.blueprint_id] = player.structures.get(order.blueprint_id, 0) + 1
                    self.state.record(f"{player.name} completed {order.blueprint_id}.")
                else:
                    still_building.append(order)
            still_building.extend(deferred)
            player.build_queue = still_building

    def _apply_production(self) -> None:
        settings = self.settings
        for player in (self.state.player1, self.state.player2):
            profile = player.production.normalized()
            factories = player.structures.get("factory", 0)
            total_output = settings.production.base_output + factories * settings.production.factory_output
            total_output *= player.logistics_factor() * (player.industry_health / 100.0)
            arms_output = total_output * (profile.arms / 100.0)
            vehicles_output = total_output * (profile.vehicles / 100.0)
            air_output = total_output * (profile.aircraft / 100.0)
            defense_output = total_output * (profile.defense / 100.0)

            infantry_def = settings.units["infantry"]
            player.units.infantry += (arms_output * infantry_def.build_rate) / infantry_def.cost

            ifv_share, tank_share = settings.production.armor_split
            ifv_def = settings.units["ifv"]
            tank_def = settings.units["tank"]
            player.units.ifv += (vehicles_output * ifv_share * ifv_def.build_rate) / ifv_def.cost
            player.units.tank += (vehicles_output * tank_share * tank_def.build_rate) / tank_def.cost

            aircraft_def = settings.units["aircraft"]
            player.units.aircraft += (air_output * aircraft_def.build_rate) / aircraft_def.cost

            def_arms, def_vehicle, def_air = settings.production.defense_split
            defense_rate = settings.production.defense_build_rate
            player.units.def_arms += defense_output * def_arms * defense_rate
            player.units.def_vehicle += defense_output * def_vehicle * defense_rate
            player.units.def_air += defense_output * def_air * defense_rate

    def _apply_air_postures(self) -> Dict[str, AirPostureDefinition]:
        modifiers: Dict[str, AirPostureDefinition] = {}
        p1, p2 = self.state.player1, self.state.player2
        for player, enemy, key in ((p1, p2, "p1"), (p2, p1, "p2")):
            posture = self.settings.air_postures.get(player.air_posture, self.settings.air_postures["ISR"])
            if player.credits < posture.cost_per_tick:
                posture = self.settings.air_postures["ISR"]
            else:
                player.credits -= posture.cost_per_tick
            strike_multiplier = self._strike_multiplier()
            if posture.logistics_strike:
                enemy.logistics_health = max(0.0, enemy.logistics_health - posture.logistics_strike * strike_multiplier)
            if posture.industry_strike:
                enemy.industry_health = max(0.0, enemy.industry_health - posture.industry_strike * strike_multiplier)
            modifiers[key] = posture
        return modifiers

    def _process_operations(self) -> None:
        for player, enemy in ((self.state.player1, self.state.player2), (self.state.player2, self.state.player1)):
            if not player.operations:
                continue
            updated: list[ActiveOperation] = []
            for op in player.operations:
                if op.remaining_delay > 0:
                    op.remaining_delay -= 1
                    updated.append(op)
                    continue
                if op.remaining_duration <= 0:
                    continue
                strike_multiplier = self._strike_multiplier()
                self._apply_operation_effect(enemy, op, strike_multiplier)
                op.remaining_duration -= 1
                if op.remaining_duration > 0:
                    updated.append(op)
            player.operations = updated

    def _apply_operation_effect(self, enemy: PlayerState, op: ActiveOperation, multiplier: float) -> None:
        damage = op.magnitude * multiplier
        if op.target == "logistics":
            enemy.logistics_health = max(0.0, enemy.logistics_health - damage)
        elif op.target == "industry":
            enemy.industry_health = max(0.0, enemy.industry_health - damage)
        elif op.target == "defense":
            enemy.defense_health = max(0.0, enemy.defense_health - damage)

    def _update_frontline(self, air_mods: Dict[str, AirPostureDefinition]) -> float:
        front = self.state.frontline
        p1_mod = air_mods.get("p1", self.settings.air_postures["ISR"])
        p2_mod = air_mods.get("p2", self.settings.air_postures["ISR"])
        pressure_p1 = self._pressure_for(self.state.player1, self.state.player2, p1_mod)
        pressure_p2 = self._pressure_for(self.state.player2, self.state.player1, p2_mod)
        net = pressure_p1 - pressure_p2
        phase = self._current_phase()
        net *= 1.0 + (phase * self.settings.escalation.pressure_multiplier_per_phase)

        if front.position >= self.settings.frontline.collapse_threshold:
            net *= self.settings.frontline.collapse_multiplier
        elif front.position <= self.settings.frontline.max_position - self.settings.frontline.collapse_threshold:
            net *= self.settings.frontline.collapse_multiplier

        front.position = min(
            self.settings.frontline.max_position,
            max(self.settings.frontline.min_position, front.position + net * self.settings.combat.pressure_scale),
        )
        front.pressure_toward_p1 = max(0.0, pressure_p1)
        front.pressure_toward_p2 = max(0.0, pressure_p2)
        self._update_objectives()
        return net

    def _pressure_for(
        self,
        attacker: PlayerState,
        defender: PlayerState,
        posture: AirPostureDefinition,
    ) -> float:
        defenses = self._defense_power(defender, posture.defense_suppression)
        total = 0.0
        for unit_def in self.settings.units.values():
            count = getattr(attacker.units, unit_def.key)
            raw = count * unit_def.pressure * attacker.logistics_factor()
            if raw <= 0:
                continue
            defense_power = defenses.get(unit_def.defense_key, 0.0)
            reduction = defense_power / (defense_power + raw + 1.0)
            reduction = min(self.settings.combat.defense_soft_cap, reduction)
            total += raw * (1.0 - reduction)
        total += posture.pressure_bonus
        return total

    def _defense_power(self, defender: PlayerState, suppression: float) -> Dict[str, float]:
        defenses: Dict[str, float] = {}
        health_factor = defender.defense_health / 100.0
        for key, definition in self.settings.defenses.items():
            structural = defender.structures.get(key, 0)
            field = getattr(defender.units, key, 0.0)
            raw = (structural + field) * definition.strength * health_factor
            raw *= max(0.0, 1.0 - suppression)
            defenses[key] = raw
        return defenses

    def _update_escalation(self, net_pressure: float, air_mods: Dict[str, AirPostureDefinition]) -> None:
        air_intensity = 0.0
        if air_mods.get("p1", self.settings.air_postures["ISR"]).key != "ISR":
            air_intensity += 1.0
        if air_mods.get("p2", self.settings.air_postures["ISR"]).key != "ISR":
            air_intensity += 1.0
        active_ops = len(self.state.player1.operations) + len(self.state.player2.operations)
        intensity = abs(net_pressure) + active_ops * 1.5 + air_intensity
        delta = self.settings.escalation.base_rate + self.settings.escalation.intensity_factor * intensity
        self.state.escalation = min(self.settings.escalation.max_value, self.state.escalation + delta)

    def _apply_repair(self) -> None:
        phase = self._current_phase()
        base = self.settings.escalation.repair_rate_base
        minimum = self.settings.escalation.repair_rate_min
        if base <= minimum:
            repair_rate = minimum
        else:
            step = (base - minimum) / 2.0
            repair_rate = max(minimum, base - phase * step)
        for player in (self.state.player1, self.state.player2):
            bonus = player.structures.get("logistics_hub", 0) * 0.3
            total = repair_rate + bonus
            player.logistics_health = min(100.0, player.logistics_health + total)
            player.industry_health = min(100.0, player.industry_health + total)
            player.defense_health = min(100.0, player.defense_health + total)

    def _update_objectives(self) -> None:
        front_position = self.state.frontline.position
        for obj in self.state.objectives:
            if front_position >= obj.position:
                obj.owner = self.state.player1.name
            else:
                obj.owner = self.state.player2.name

    def _check_victory(self) -> None:
        if self.state.winner:
            return
        if self.state.frontline.position <= self.settings.frontline.min_position:
            self.state.winner = self.state.player2.name
            self.state.victory_reason = "Frontline collapse"
            return
        if self.state.frontline.position >= self.settings.frontline.max_position:
            self.state.winner = self.state.player1.name
            self.state.victory_reason = "Frontline collapse"
            return
        owners = {obj.owner for obj in self.state.objectives if obj.owner}
        if len(owners) == 1 and len(self.state.objectives) > 0:
            self.state.winner = owners.pop()
            self.state.victory_reason = "Objective control"
            return
        threshold = self.settings.victory.system_collapse_threshold
        for player, enemy in ((self.state.player1, self.state.player2), (self.state.player2, self.state.player1)):
            if enemy.logistics_health <= threshold or enemy.industry_health <= threshold:
                self.state.winner = player.name
                self.state.victory_reason = "Systemic collapse"
                return

    def _player(self, key: str) -> PlayerState:
        normalized = key.lower()
        if normalized in {"p1", "1", "player1"}:
            return self.state.player1
        return self.state.player2

    def _current_phase(self) -> int:
        t1, t2 = self.settings.escalation.phase_thresholds
        if self.state.escalation >= t2:
            return 2
        if self.state.escalation >= t1:
            return 1
        return 0

    def _strike_multiplier(self) -> float:
        phase = self._current_phase()
        return self.settings.escalation.strike_multiplier_base + phase * self.settings.escalation.strike_multiplier_per_phase
