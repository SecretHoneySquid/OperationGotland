"""Headless simulation loop for the larger RTS version."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional, Tuple

from .config import AirPostureDefinition, SimulationSettings
from .models import ActiveOperation, FrontlineState, GameState, ObjectiveState, PlayerState, ProductionOutput, QueuedStructure
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
        self._sync_tech_tiers(self.state.player1)
        self._sync_tech_tiers(self.state.player2)

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

    def upgrade_factory(self, player_key: str, factory_key: str) -> None:
        player = self._player(player_key)
        if factory_key not in player.tech_levels:
            raise ValueError(f"Unknown tech '{factory_key}'.")
        if factory_key != "stealth" and player.structures.get(f"{factory_key}_factory", 0) <= 0:
            raise ValueError(f"{player.name} has no {factory_key} factory.")
        tier = player.tech_levels[factory_key]
        costs = self.settings.upgrades.factory_upgrade_costs
        if tier >= len(costs):
            raise ValueError("Factory already at max tier.")
        cost = costs[tier]
        if player.credits < cost:
            raise ValueError(f"{player.name} needs {cost} credits for upgrade.")
        player.credits -= cost
        player.tech_levels[factory_key] += 1
        self._sync_tech_tiers(player)
        self.state.record(f"{player.name} upgraded {factory_key} factory to tier {tier + 2}.")

    def upgrade_stealth(self, player_key: str) -> None:
        player = self._player(player_key)
        if player.structures.get("air_factory", 0) <= 0:
            raise ValueError(f"{player.name} has no air factory.")
        tier = player.tech_levels["stealth"]
        costs = self.settings.upgrades.stealth_upgrade_costs
        if tier >= len(costs):
            raise ValueError("Stealth already maxed.")
        cost = costs[tier]
        if player.credits < cost:
            raise ValueError(f"{player.name} needs {cost} credits for stealth.")
        player.credits -= cost
        player.tech_levels["stealth"] += 1
        self._sync_tech_tiers(player)
        self.state.record(f"{player.name} upgraded aircraft stealth to tier {player.air_stealth_level + 1}.")

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
        self._resolve_combat()
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
            infantry_factories = player.structures.get("infantry_factory", 0)
            armor_factories = player.structures.get("armor_factory", 0)
            air_factories = player.structures.get("air_factory", 0)
            heli_factories = player.structures.get("heli_factory", 0)
            defense_factories = player.structures.get("defense_factory", 0)
            total_output = settings.production.base_output
            total_output *= player.logistics_factor() * (player.industry_health / 100.0)
            arms_output = total_output * (profile.arms / 100.0) + infantry_factories * settings.production.factory_output
            vehicles_output = total_output * (profile.vehicles / 100.0) + armor_factories * settings.production.factory_output
            air_output = total_output * (profile.aircraft / 100.0) + air_factories * settings.production.factory_output
            rotary_output = total_output * (profile.rotary / 100.0) + heli_factories * settings.production.factory_output
            defense_output = total_output * (profile.defense / 100.0) + defense_factories * settings.production.factory_output

            player.last_output = ProductionOutput(
                arms=arms_output,
                vehicles=vehicles_output,
                aircraft=air_output,
                rotary=rotary_output,
                defense=defense_output,
                total=total_output,
            )

            infantry_def = settings.units["infantry"]
            infantry_added = (arms_output * infantry_def.build_rate) / infantry_def.cost
            self._add_units(player, "infantry", infantry_added)

            ifv_share, tank_share = settings.production.armor_split
            ifv_def = settings.units["ifv"]
            tank_def = settings.units["tank"]
            ifv_added = (vehicles_output * ifv_share * ifv_def.build_rate) / ifv_def.cost
            tank_added = (vehicles_output * tank_share * tank_def.build_rate) / tank_def.cost
            self._add_units(player, "ifv", ifv_added)
            self._add_units(player, "tank", tank_added)

            aircraft_def = settings.units["aircraft"]
            air_added = (air_output * aircraft_def.build_rate) / aircraft_def.cost
            self._add_units(player, "aircraft", air_added)

            heli_def = settings.units["helicopter"]
            heli_added = (rotary_output * heli_def.build_rate) / heli_def.cost
            self._add_units(player, "helicopter", heli_added)

            def_arms, def_vehicle, def_air = settings.production.defense_split
            defense_rate = settings.production.defense_build_rate
            self._add_units(
                player, "def_arms", defense_output * def_arms * defense_rate, hp_override=self._defense_hp("def_arms")
            )
            self._add_units(
                player,
                "def_vehicle",
                defense_output * def_vehicle * defense_rate,
                hp_override=self._defense_hp("def_vehicle"),
            )
            self._add_units(
                player, "def_air", defense_output * def_air * defense_rate, hp_override=self._defense_hp("def_air")
            )

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

    def _resolve_combat(self) -> None:
        total_damage = 0.0
        for attacker, defender in ((self.state.player1, self.state.player2), (self.state.player2, self.state.player1)):
            total_damage += self._apply_unit_damage(attacker, defender)
            total_damage += self._apply_air_defense(attacker, defender)
        for player in (self.state.player1, self.state.player2):
            self._recalculate_counts(player)
        self.state.combat_intensity = total_damage

    def _apply_unit_damage(self, attacker: PlayerState, defender: PlayerState) -> float:
        base = self.settings.combat.base_damage_scale
        total_damage = 0.0
        for unit_key in ("infantry", "ifv", "tank", "helicopter", "aircraft"):
            unit_def = self.settings.units[unit_key]
            count = getattr(attacker.units, unit_key)
            if count <= 0:
                continue
            raw_damage = count * unit_def.damage * base * attacker.logistics_factor()
            targets = self._target_weights(unit_key)
            for target_key, weight in targets.items():
                total_damage += self._deal_damage(attacker, defender, unit_def, target_key, raw_damage * weight)

            if unit_key == "aircraft":
                air_targets = {"aircraft": 0.6, "helicopter": 0.4}
                for target_key, weight in air_targets.items():
                    total_damage += self._deal_damage(attacker, defender, unit_def, target_key, raw_damage * 0.5 * weight)
        return total_damage

    def _apply_air_defense(self, attacker: PlayerState, defender: PlayerState) -> float:
        defense_units = defender.units.def_air + defender.structures.get("def_air", 0)
        if defense_units <= 0:
            return 0.0
        range_band = 1 + defender.defense_range_tier
        base = self.settings.combat.base_damage_scale
        strength = self.settings.defenses["def_air"].strength
        raw_damage = defense_units * strength * base
        total_damage = 0.0
        for target_key in ("aircraft", "helicopter"):
            target_def = self.settings.units[target_key]
            multiplier = 1.0 if range_band >= target_def.range_band else self.settings.combat.underrange_penalty
            if target_key == "aircraft":
                multiplier *= self._stealth_evasion(attacker)
            total_damage += self._apply_damage(defender=attacker, target_key=target_key, damage=raw_damage * multiplier)
        return total_damage

    def _deal_damage(
        self,
        attacker: PlayerState,
        defender: PlayerState,
        attacker_def,
        target_key: str,
        damage: float,
    ) -> float:
        target_def = self.settings.units.get(target_key)
        if not target_def:
            return 0.0
        multiplier = self._range_multiplier(attacker_def.range_band, target_def.range_band)
        if target_key == "aircraft":
            multiplier *= self._stealth_evasion(defender)
        return self._apply_damage(defender=defender, target_key=target_key, damage=damage * multiplier)

    def _apply_damage(self, defender: PlayerState, target_key: str, damage: float) -> float:
        if damage <= 0:
            return 0.0
        before = defender.unit_hp.get(target_key, 0.0)
        after = max(0.0, before - damage)
        defender.unit_hp[target_key] = after
        return before - after

    def _add_units(self, player: PlayerState, unit_key: str, amount: float, hp_override: Optional[float] = None) -> None:
        if amount <= 0:
            return
        hp = hp_override
        if hp is None:
            hp = self.settings.units[unit_key].hp
        player.unit_hp[unit_key] = player.unit_hp.get(unit_key, 0.0) + amount * hp
        self._sync_count(player, unit_key, hp)

    def _sync_count(self, player: PlayerState, unit_key: str, hp_per_unit: float) -> None:
        if not hasattr(player.units, unit_key):
            return
        setattr(player.units, unit_key, player.unit_hp.get(unit_key, 0.0) / max(1.0, hp_per_unit))

    def _recalculate_counts(self, player: PlayerState) -> None:
        for unit_key, unit_def in self.settings.units.items():
            self._sync_count(player, unit_key, unit_def.hp)
        for unit_key in ("def_arms", "def_vehicle", "def_air"):
            hp_per_unit = self._defense_hp(unit_key)
            self._sync_count(player, unit_key, hp_per_unit)

    def _defense_hp(self, unit_key: str) -> float:
        if unit_key == "def_arms":
            return 8.0
        if unit_key == "def_vehicle":
            return 10.0
        return 12.0

    def _target_weights(self, unit_key: str) -> Dict[str, float]:
        if unit_key == "infantry":
            return {"infantry": 0.6, "ifv": 0.4}
        if unit_key == "ifv":
            return {"infantry": 0.3, "ifv": 0.3, "tank": 0.4}
        if unit_key == "tank":
            return {"ifv": 0.4, "tank": 0.6}
        if unit_key == "helicopter":
            return {"ifv": 0.4, "tank": 0.6}
        if unit_key == "aircraft":
            return {"infantry": 0.3, "ifv": 0.35, "tank": 0.35}
        return {}

    def _range_multiplier(self, attacker_range: int, target_range: int) -> float:
        if attacker_range > target_range:
            return self.settings.combat.outrange_bonus
        if attacker_range < target_range:
            return self.settings.combat.underrange_penalty
        return 1.0

    def _stealth_evasion(self, defender: PlayerState) -> float:
        evasion = defender.air_stealth_level * self.settings.combat.stealth_evasion_per_tier
        evasion = min(self.settings.combat.max_stealth_evasion, evasion)
        return max(0.2, 1.0 - evasion)

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

    def _factory_unit_keys(self, factory_key: str) -> Tuple[str, ...]:
        mapping = {
            "infantry": ("infantry",),
            "armor": ("ifv", "tank"),
            "air": ("aircraft",),
            "heli": ("helicopter",),
            "defense": ("def_arms", "def_vehicle", "def_air"),
        }
        return mapping.get(factory_key, tuple())

    def _sync_tech_tiers(self, player: PlayerState) -> None:
        for key in ("infantry", "armor", "air", "heli", "defense"):
            tier = min(player.tech_levels.get(key, 0), 3)
            for unit_key in self._factory_unit_keys(key):
                player.unit_tiers[unit_key] = tier
        player.air_stealth_level = min(player.tech_levels.get("stealth", 0), 3)
        player.defense_range_tier = min(player.tech_levels.get("defense", 0), 2)

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
