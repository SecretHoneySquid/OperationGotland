# Operation Gotland - Architecture Skeleton

This document captures the structural base for a system-driven operational war game.
It is derived from the low-fidelity prototype in `LF_prototype` and preserves its
deterministic, metric-based mechanics. No gameplay logic is redesigned here.

## Intent and Constraints
- System-driven, not unit-driven. Units are visual proxies for metrics.
- Deterministic, tick-based simulation. No per-unit orders or micro-control.
- Representation and graphics are non-authoritative and read-only.
- Visual progression is tiered and faction-specific but not a new ruleset.

## Three-Layer Architecture

### 1) Simulation Layer (authoritative)
Owns all mechanics and produces deterministic state and events per tick.

Responsibilities:
- Economy (credits, income, supply zones)
- Production (vehicle, arms, aircraft, defense, tank bonus)
- Logistics (health and penalties)
- Build queues and factories
- Sorties and combat resolution
- Frontline pressure and objectives

Outputs:
- `SimulationFrame` (state snapshot + event list)

### 2) Representation Layer (translation)
Converts metrics into visual intent: densities, counts, animation rates, and
capability tier selection. No gameplay authority.

Responsibilities:
- Map inventories to visual presence (columns, platoons, sorties)
- Resolve faction equipment from capability tiers
- Smooth transitions between ticks for visuals
- Emit visual events (breakthrough, large losses, supply surge)

Outputs:
- `RepresentationFrame` (per-side presence, tier choices, visual cues)

### 3) Visualization Layer (rendering)
High-fidelity graphics. Reads only representation data.

Responsibilities:
- Spawn and animate units, aircraft, defenses, infrastructure
- Render frontline movement and engagements
- Show damage, repair, and escalation cues

Outputs:
- Frame rendering only

## Data Flow and Timing

Simulation is fixed-step; rendering is continuous.

```
Input (orders) -> Simulation tick -> SimulationFrame
SimulationFrame -> Representation mapping -> RepresentationFrame
RepresentationFrame -> Scene composition -> Renderer
```

## Module Map (Initial Skeleton)

Simulation:
- `src/operation_gotland/simulation/state.py`
  - Core state models (players, production, units, frontline).
- `src/operation_gotland/simulation/events.py`
  - Simulation events for representation triggers.
- `src/operation_gotland/simulation/engine.py`
  - Tick orchestration and system ordering.
- `src/operation_gotland/simulation/systems.py`
  - System interfaces and placeholders.

Representation:
- `src/operation_gotland/representation/models.py`
  - Visual presence and tier selections.
- `src/operation_gotland/representation/config.py`
  - Scaling constants for presence mapping.
- `src/operation_gotland/representation/tiers.py`
  - Tier resolver for capability levels.
- `src/operation_gotland/representation/factions.py`
  - Data-driven faction loading.
- `src/operation_gotland/representation/mapper.py`
  - Simulation to representation mapping.

Visualization:
- `src/operation_gotland/visualization/scene.py`
  - Scene graph data structures.
- `src/operation_gotland/visualization/composer.py`
  - Representation to scene mapping.
- `src/operation_gotland/visualization/renderer.py`
  - Renderer interface (engine-specific adapters later).

Content:
- `src/operation_gotland/content/factions.json`
  - Faction definitions and equipment naming.
- `src/operation_gotland/content/visual_tiers.json`
  - Tier metadata and labels.

Orchestration:
- `src/operation_gotland/game/orchestrator.py`
  - High-level flow across layers.

## Core Simulation Model (From LF_prototype)

Key state and systems preserved:
- Economy: `credits`, `income_per_tick`, `supply_zones`
- Logistics: `logistics_health`, `logistics_penalty`, `logistics_factor`
- Production: `vehicle_prod`, `arms_prod`, `aircraft_prod`, `defense_prod`
- Unit pools: `arms`, `vehicles`, `tanks`, `aircraft`, `helicopters`, `missiles`,
  `def_arms`, `def_vehicle`, `def_air`
- Build queue: factory orders, build times, parallel slots (workshops)
- Sorties: air strikes with return cycles and attrition
- Frontline pressure: net pressure meters and threshold-based jumps
- Victory: frontline reaching bounds

The simulation layer exposes these metrics; representation translates them to
visual density and activity.

## Representation Model (How Metrics Drive Visuals)

Representation is a mapping layer, not a new ruleset. Example mappings:
- Higher `vehicles + tanks` -> more armor columns and heavier ground trails
- Higher `arms` -> denser infantry presence and trench density
- Higher `aircraft` -> more frequent sorties and patrols from airbases
- Higher `def_air` -> more visible SAM sites and flak bursts
- Higher `logistics_health` -> more active convoys and supply effects
- `frontline_ratio` and pressure -> visible pushback and breakthrough effects

Use scaling constants (in `representation/config.py`) to keep visuals readable
at high counts without spawning one-to-one units.

## Visual Progression and Capability Tiers

The simulation tracks capability levels, not specific models. The representation
layer resolves tiers to faction equipment for visuals.

Example (aircraft tiers):
- Tier 0: F-14
- Tier 1: F-16
- Tier 2: F-35
- Tier 3: F-22

Example (armor tiers):
- Tier 0: Cold War MBT
- Tier 1: Modern MBT
- Tier 2: Advanced MBT

These tiers are resolved by capability levels (not new mechanics), and each
faction supplies its own equipment set in `content/factions.json`.

## Examples: Inventory to Battlefield Presence

1) Armor concentration
- Inventory: vehicles=120, tanks=40
- Presence: 6 IFV columns, 3 tank columns
- Visuals: multiple armored convoys, heavier dust and impact effects

2) Air dominance
- Inventory: aircraft=30
- Presence: 4 concurrent sorties, visible patrol arcs
- Visuals: frequent takeoffs, high-altitude contrails, enemy flak responses

3) Defensive posture
- Inventory: def_air=80, def_vehicle=60
- Presence: 8 SAM sites, 5 anti-armor batteries
- Visuals: SAM launches, tracer fire, static emplacements near bases

4) Logistics strain
- Logistics health: 55 with missile penalty active
- Presence: reduced convoy flow and slower reinforcement visuals
- Visuals: fewer supply trucks, damaged depots, intermittent repairs

## Factions (Data-Driven)

Factions define:
- Visual models by capability tier
- Naming conventions
- Doctrine flavor (visual emphasis only)

All factions share the same simulation rules.

## Scalability and Growth

Designed to support:
- Additional factions by adding data files
- New visual tiers without touching simulation
- Additional map themes with new scene compositions
- Higher fidelity visuals via renderer adapters
- Multiplayer later (simulation remains deterministic)

## Explicit Non-Goals

Do not add:
- RTS-style unit control or per-unit orders
- Per-unit stats that drive gameplay
- Manual targeting or hero units
- Tactical micromanagement

## Implementation Reminder

All gameplay outcomes come from the simulation layer. Representation and visuals
are strictly derived from metrics and events.
