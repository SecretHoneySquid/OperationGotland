# Operation Gotland - RTS Architecture (Godot Prototype)

This document defines the baseline architecture for a unit-level RTS built in
Godot 4. It replaces the previous metric-only simulation and commits to
auto-pushing units with optional manual control later.

## Intent and Scope
- Unit-level RTS (C&C Generals inspired) in Godot 4.
- Windows-only target for the prototype.
- Default unit behavior: auto-push toward enemy base, attack on sight.
- Manual control is planned later (selection + orders) for finer operations.
- Must-have pillars (initial): base building and level structure.

## Explicit Non-Goals (for now)
- Multiplayer / deterministic lockstep.
- Superweapons or hero units.
- Multiple factions or tech trees beyond a minimal baseline.
- Full fog-of-war or stealth systems.

## Core Gameplay Loop
1. Build and place structures in a buildable zone.
2. Collect supply to generate credits.
3. Queue unit production at buildings.
4. Units spawn, then auto-push toward the enemy base and engage on sight.
5. Win by destroying the enemy HQ (or controlling key objectives).

## Layered Architecture
1) Game Simulation (authoritative)
   - Units, buildings, economy, production, combat, pathfinding.

2) Presentation (visuals)
   - Godot scenes, animation, VFX, SFX, camera.

3) UI/UX
   - Build menus, selection tools, minimap, debug overlays.

## Systems (Initial)
- Entity model: Unit, Building, Projectile, Resource Node.
- Economy: supply nodes + collectors, credit income tick.
- Production: build queues, spawn points, rally points.
- Orders:
  - Default: attack-move to enemy base.
  - Later: manual move, attack, stop, hold.
- Pathfinding: Godot NavigationRegion, dynamic obstacles for buildings.
- Combat: target acquisition, range, DPS, basic armor tags.
- Level: map boundaries, build zones, resource placement, start positions.
- AI: simple enemy base that also auto-pushes.

## Level Structure and Map Pipeline
- Store map data as Godot Resources (.tres) or JSON (layout, build zones, resources).
- Use NavigationRegion2D/3D for walkable space.
- Optional: import C&C Generals maps later (requires extraction from maps.big).

## Godot Project Layout (Proposed)
- godot/
  - scenes/
    - game/
    - units/
    - buildings/
    - ui/
    - maps/
  - scripts/
    - core/
    - units/
    - buildings/
    - ai/
    - ui/
  - data/
    - units/
    - buildings/
    - maps/
  - art/
  - audio/

## Data-Driven Content
- Units and buildings defined as Resources or JSON for fast iteration.
- Keep stats and costs editable without code changes.
- Allow quick swaps to test balance and pacing.

## Input Model (Phase 1)
- No manual orders required to function.
- Click-to-build placement + production queue controls.
- Manual unit control added later without redesigning core systems.

## Debug and Testing
- In-game debug overlay for FPS, unit counts, income, and queue status.
- A small test map for rapid iteration.

## Migration Notes
- `LF_prototype` remains as a design reference, not an authoritative sim.
- The Godot prototype is now the primary gameplay system.
