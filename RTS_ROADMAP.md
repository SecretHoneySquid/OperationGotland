# Operation Gotland - RTS Prototype Roadmap (Godot)

This roadmap targets a fast Windows-only prototype with base building, level
structure, and auto-pushing units.

## Phase 0 - Project Bootstrap (1-2 days)
- Create Godot 4 project in `godot/`.
- Set up folder structure, autoloads, and a basic test scene.
- Add a debug overlay (FPS, credits, unit counts).

## Phase 1 - Core Loop (auto-push) (1-2 weeks)
- Units: spawn, move toward enemy base, attack on sight.
- Buildings: placeable structures with simple build rules.
- Economy: supply nodes + collectors -> credits.
- Production: queues in buildings, rally points.
- Win condition: enemy HQ destroyed.

Exit criteria:
- Player can build, produce units, and see auto-push combat resolve to a win.

## Phase 2 - Level Structure (1 week)
- Map data format (.tres or JSON) for layout and build zones.
- Navigation baked per map.
- Resource nodes and start positions loaded from map data.

Exit criteria:
- Map loads from data, units path correctly, build zones enforced.

## Phase 3 - Manual Control (optional, later)
- Selection box, move/attack orders.
- Rally point overrides and hold/stop.

Exit criteria:
- Manual orders coexist with the default auto-push behavior.

## Phase 4 - Polish (as needed)
- Basic VFX, sound cues, UI improvements.
- Balance pass on build costs and unit stats.

## Optional - Map Import (later)
- Extract and inspect content from `maps.big`.
- Build a conversion script to the project map format.
