# Battalion System Implementation Plan

**STATUS: IMPLEMENTED**

## Overview

Replace the current auto-spawning infantry system with a player-controlled battalion purchase system. Players buy battalions (30 units + 30 reserves) that behave autonomously based on their type.

---

## New Concepts

### Battalion Types

| Button | Type | Behavior |
|--------|------|----------|
| 1 | Assault | Advances toward target, engages enemies aggressively |
| 2 | Defense | Moves to position, digs in, holds ground |
| 3 | Control | Moves to area, spreads out, patrols |
| 4 | Air Defense | Moves to position, provides AA coverage |

### Battalion Entity

- **30 active units** - visible, fighting
- **30 reserve units** - spawn when active units die (trickle reinforcement)
- **Selectable as one entity** - click battalion, not individual units
- **Formation-based positioning** - units spread in soccer-style formation

### Single Order: Withdraw

- Select battalion → click Withdraw in bottom panel
- Battalion pulls back until out of combat (no nearby enemies)
- Stops when "safe"

---

## Implementation Steps

### Phase 1: Battalion Data Structure

**File: `scripts/core/battalion.gd` (NEW)**

```gdscript
class_name Battalion
extends Node2D

enum BattalionType { ASSAULT, DEFENSE, CONTROL, AIR_DEFENSE }
enum BattalionState { DEPLOYING, ACTIVE, WITHDRAWING, IDLE }

var battalion_type: BattalionType
var team_id: String
var target_position: Vector2

var active_units: Array[Unit] = []
var reserve_count: int = 30
var max_active: int = 30

var state: BattalionState = BattalionState.DEPLOYING

signal unit_died(unit: Unit)
signal battalion_destroyed
signal strength_changed(active: int, reserves: int)
```

**Key Methods:**
- `spawn_initial_units()` - Create first 30 units in formation
- `reinforce()` - Spawn reserve when active unit dies
- `get_formation_positions()` - Calculate spread positions based on type
- `withdraw()` - Set state to WITHDRAWING, units pull back
- `get_strength()` - Returns {active: int, reserves: int}

---

### Phase 2: Formation System

**File: `scripts/core/battalion_formation.gd` (NEW)**

Calculates unit positions within battalion based on type and facing.

```gdscript
class_name BattalionFormation

# Returns array of 30 offset positions relative to center
static func get_positions(type: Battalion.BattalionType, facing: Vector2) -> Array[Vector2]:
    match type:
        Battalion.BattalionType.ASSAULT:
            return _assault_formation(facing)
        Battalion.BattalionType.DEFENSE:
            return _defense_formation(facing)
        Battalion.BattalionType.CONTROL:
            return _control_formation(facing)
        Battalion.BattalionType.AIR_DEFENSE:
            return _air_defense_formation(facing)
```

**Formation Layouts:**

```
ASSAULT (narrow spearhead):
        x x x          <- support (snipers/AT) - 5 units
       x x x x x       <- core - 10 units
      x x x x x x x    <- front line - 15 units
      ─── toward enemy ───

DEFENSE (wide, layered):
    x   x   x   x   x      <- support - 5 units (spread)
      x  x  x  x  x  x     <- core - 10 units
    x x x x x x x x x x    <- front line - 15 units (wide)

CONTROL (very spread, patrol zones):
    x     x     x     x    <- 4 units per "zone"
       x     x     x       <- spread across large area
    x     x     x     x
       x     x     x
    ... (30 total, max spread)

AIR_DEFENSE (clustered around AA):
         x x x             <- perimeter guards
        x[AA]x[AA]x        <- AA assets in center
         x x x
        x  x  x  x         <- outer screen
```

**Dynamic Adjustment:**
- Formation rotates to face nearest enemy
- Spread increases/decreases based on threat (artillery = spread out)

---

### Phase 3: Unit Modifications

**File: `scripts/core/unit.gd` (MODIFY)**

Add battalion awareness to existing Unit class:

```gdscript
# New properties
var battalion: Battalion = null  # Reference to parent battalion
var formation_slot: int = -1     # Position in formation (0-29)
var formation_target: Vector2    # Where this unit should be in formation

# New behavior modes
enum UnitMode { LEGACY, BATTALION }
var unit_mode: UnitMode = UnitMode.LEGACY
```

**Modified Movement Logic:**

When `unit_mode == BATTALION`:
- Don't march to enemy HQ
- Instead: move toward `formation_target`
- Once at formation position, behavior depends on battalion type:
  - ASSAULT: advance formation toward battalion target
  - DEFENSE: hold position, engage enemies in range
  - CONTROL: patrol within zone radius
  - AIR_DEFENSE: hold position, prioritize air targets

**Death Handling:**
- Emit signal to battalion
- Battalion spawns reserve (if any) at rear of formation

---

### Phase 4: Battalion Controller

**File: `scripts/core/battalion_controller.gd` (NEW)**

Manages all battalions, handles spawning, selection.

```gdscript
class_name BattalionController
extends Node

var battalions: Dictionary = {
    "p1": [] as Array[Battalion],
    "p2": [] as Array[Battalion]
}

signal battalion_spawned(battalion: Battalion)
signal battalion_destroyed(battalion: Battalion)
signal battalion_selected(battalion: Battalion)
```

**Key Methods:**
- `spawn_battalion(team: String, type: BattalionType, target: Vector2)`
- `get_battalion_at(position: Vector2)` - For click selection
- `get_battalions_for_team(team: String)`
- `withdraw_battalion(battalion: Battalion)`

---

### Phase 5: Purchase UI

**File: `scripts/ui/build_ui.gd` (MODIFY)**

Add battalion purchase buttons (similar to HIMARS button pattern).

**New UI Section:**
```
┌─────────────────────────────────────────┐
│ BATTALIONS                              │
│ [1] [2] [3] [4]                         │
│                                         │
│ Hover tooltip: "Assault Battalion"      │
│ Cost: 500 credits (from GameBalance)    │
└─────────────────────────────────────────┘
```

**Button Behavior:**
1. Click button (if credits available)
2. Enter "placement mode" (cursor changes)
3. Click on map to set target position
4. Battalion spawns at HQ, moves to target
5. Deduct credits

**Code Pattern (following HIMARS):**
```gdscript
var _battalion_buttons: Array[Button] = []

func _create_battalion_buttons():
    var types = ["Assault", "Defense", "Control", "Air Defense"]
    for i in range(4):
        var btn = Button.new()
        btn.text = str(i + 1)
        btn.tooltip_text = types[i] + " Battalion\nCost: " + str(GameBalance.BATTALION_COST)
        btn.pressed.connect(_on_battalion_button_pressed.bind(i))
        _battalion_buttons.append(btn)
```

---

### Phase 6: Selection & Withdraw UI

**File: `scripts/core/selection_controller.gd` (MODIFY)**

Add battalion selection alongside unit selection:

```gdscript
var _selected_battalion: Battalion = null

func _pick_battalion(screen_pos: Vector2) -> Battalion:
    # Check if click is near any battalion center
    # Or if click is on any unit belonging to a battalion
    pass
```

**File: `scripts/ui/build_ui.gd` (MODIFY)**

Add battalion info panel:

```
┌─────────────────────────────────────────┐
│ 2nd Assault Battalion                   │
│ Strength: 24/30 (18 reserves)           │
│ Status: Active                          │
│                                         │
│ [WITHDRAW]                              │
└─────────────────────────────────────────┘
```

---

### Phase 7: Remove Auto-Spawn

**File: `scripts/core/production_controller.gd` (MODIFY)**

- Remove `infantry_pool` accumulation
- Remove `infantry_ready` signal emission
- Keep vehicle and aircraft production (unchanged)

**File: `scripts/core/game_controller.gd` (MODIFY)**

- Remove `_on_infantry_ready()` connection
- Add `BattalionController` as child
- Wire up battalion signals

**File: `scripts/ui/build_ui.gd` (MODIFY)**

- Remove barracks production type selector
- Remove "Wait At Base Edge" toggle
- Replace with battalion info when barracks selected (or remove barracks panel entirely)

---

### Phase 8: GameBalance Constants

**File: `scripts/constants/GameBalance.gd` (MODIFY)**

Add battalion constants:

```gdscript
# Battalion costs
const ASSAULT_BATTALION_COST := 500
const DEFENSE_BATTALION_COST := 400
const CONTROL_BATTALION_COST := 350
const AIR_DEFENSE_BATTALION_COST := 600

# Battalion formation
const BATTALION_ACTIVE_SIZE := 30
const BATTALION_RESERVE_SIZE := 30
const BATTALION_FORMATION_SPACING := 15.0
const BATTALION_CONTROL_SPREAD := 200.0

# Reinforcement
const BATTALION_REINFORCE_DELAY := 3.0  # Seconds between reserve spawns

# Withdraw
const BATTALION_WITHDRAW_SAFE_DISTANCE := 300.0  # Distance from enemies to stop
```

---

## File Summary

| File | Action | Description |
|------|--------|-------------|
| `battalion.gd` | CREATE | Battalion entity class |
| `battalion_formation.gd` | CREATE | Formation position calculations |
| `battalion_controller.gd` | CREATE | Battalion manager |
| `unit.gd` | MODIFY | Add battalion mode, formation targeting |
| `build_ui.gd` | MODIFY | Add purchase buttons, battalion panel, remove barracks controls |
| `selection_controller.gd` | MODIFY | Add battalion selection |
| `production_controller.gd` | MODIFY | Remove infantry auto-spawn |
| `game_controller.gd` | MODIFY | Wire up battalion controller |
| `GameBalance.gd` | MODIFY | Add battalion constants |

---

## Implementation Order

1. **GameBalance.gd** - Add constants first
2. **battalion.gd** - Core data structure
3. **battalion_formation.gd** - Formation math
4. **battalion_controller.gd** - Spawning logic
5. **unit.gd** - Add battalion mode
6. **build_ui.gd** - Purchase buttons (test spawning works)
7. **selection_controller.gd** - Battalion selection
8. **build_ui.gd** - Withdraw button
9. **production_controller.gd** - Remove auto-spawn (last, so we can test alongside)

---

## Design Decisions

1. **Reserve Spawn Location** - Spawn at barracks, then travel to their formation slot
2. **AI Battalions** - AI also uses battalion system (same rules as player)
3. **Placement Preview** - Ghost formation shown when placing (see formation shape before committing)
4. **Withdraw Destination** - Stop when safe (no enemies nearby), don't return to HQ
5. **Battalion Naming** - Simple: "Assault Battalion", "Defense Battalion", etc.

---

## AI Behavior

Simple logic for enemy AI:
- When AI has enough credits → buy a battalion (random type or weighted)
- Target position = middle of the map
- No strategic decision-making, just constant pressure
- Same battalion system as player (no cheating)

---

## Future Considerations (Not in Scope)

- Rally points for battalions
- Merging depleted battalions
- Veterancy/experience system
- Smarter AI (reactive, strategic)
- Different unit compositions per battalion type
- Battalion special abilities
