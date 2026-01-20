# Air Dominance & Territory Control System - Implementation Plan

## Overview

This document outlines the implementation of a comprehensive air warfare and territory control system for Operation Gotland. The system introduces:

1. **Region Grid System** - Map divided into controllable sectors with income generation
2. **Air Dominance Layer** - Aircraft patrol routes project control over regions
3. **Airforce Command UI** - New interface for managing aircraft patrol modes
4. **Expanded Building System** - Build defensive structures anywhere with vision
5. **Combat Modifiers** - Zone-based effectiveness penalties/bonuses

---

## Core Concepts

### The Three Zone Types

```
YOUR TERRITORY              CONTESTED                 ENEMY TERRITORY
(Safe Zone)                 (Risk/Reward)             (Danger Zone)

┌──────────────┐           ┌──────────────┐           ┌──────────────┐
│ • Full       │           │ • Dogfights  │           │ • High risk  │
│   aircraft   │           │ • CAS runs   │           │ • Deep       │
│   freedom    │           │ • Strike     │           │   strikes    │
│ • Rearming   │           │   missions   │           │ • Expect     │
│ • Safe       │           │ • Risk/reward│           │   losses     │
│   patrol     │           │   balance    │           │ • SEAD       │
│              │           │              │           │   required   │
└──────────────┘           └──────────────┘           └──────────────┘

LOW RISK ◄─────────────────────────────────────────────► HIGH RISK
LOW REWARD                                              HIGH REWARD
```

### Control Formula

```
REGION CONTROL = Air Dominance + Ground Presence

Normal Regions:
  - Air dominance OR ground presence (fog of war) = Control

Resource Regions:
  - Air dominance AND stationed units = Full Control
  - Only one = Contested
```

---

## Phase 1: Region Grid Foundation

### 1.1 Region Grid System

**New Files:**
- `godot/scripts/core/region.gd` - Single region data class
- `godot/scripts/core/region_controller.gd` - Manages all regions

**Region Grid Layout (7x7):**

```
     1     2     3     4     5     6     7
   ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐
 A │ P1  │     │     │ OIL │     │     │ P2  │
   │BASE │     │     │  ★  │     │     │BASE │
   ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
 B │     │MINE │     │     │     │MINE │     │
   │     │  ★  │     │     │     │  ★  │     │
   ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
 C │     │     │     │     │     │     │     │
   │     │     │     │     │     │     │     │
   ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
 D │     │     │     │ OIL │     │     │     │
   │     │     │     │  ★  │     │     │     │
   ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
 E │     │     │     │     │     │     │     │
   │     │     │     │     │     │     │     │
   ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
 F │     │MINE │     │     │     │MINE │     │
   │     │  ★  │     │     │     │  ★  │     │
   ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
 G │ P1  │     │     │ OIL │     │     │ P2  │
   │REAR │     │     │  ★  │     │     │REAR │
   └─────┴─────┴─────┴─────┴─────┴─────┴─────┘

Map size: 6144x6144 → Each region: ~878x878 pixels

★ = Resource region (higher income, requires stationed units)
```

**Starting Control:**
- P1 controls: A1, G1 (base regions)
- P2 controls: A7, G7 (base regions)
- All other regions: Neutral

### 1.2 Region Data Structure

```gdscript
# region.gd
class_name Region
extends RefCounted

enum State { NEUTRAL, CONTROLLED_P1, CONTROLLED_P2, CONTESTED }
enum Type { NORMAL, RESOURCE_MINE, RESOURCE_OIL, BASE }

var id: String                    # e.g., "A1", "D4"
var grid_pos: Vector2i            # e.g., (0, 0), (3, 3)
var world_rect: Rect2             # World coordinates
var type: Type = Type.NORMAL
var state: State = State.NEUTRAL
var controller: String = ""       # "", "p1", or "p2"

# Control factors
var p1_air_dominance: float = 0.0
var p2_air_dominance: float = 0.0
var p1_ground_presence: float = 0.0
var p2_ground_presence: float = 0.0

# State transition
var contest_timer: float = 0.0    # Time until state changes
var previous_controller: String = ""

# Income
var base_income: float = 1.0      # Credits per second when controlled
```

### 1.3 Region Controller

```gdscript
# region_controller.gd
class_name RegionController
extends Node

const GRID_SIZE := Vector2i(7, 7)
const CONTEST_DECAY_TIME := 5.0   # Seconds to transition contested → neutral
const CAPTURE_TIME := 5.0          # Seconds to transition neutral → controlled

var regions: Dictionary = {}       # "A1" -> Region
var region_grid: Array[Array] = [] # [row][col] -> Region

# Income rates
const INCOME_NORMAL := 1.0
const INCOME_MINE := 3.0
const INCOME_OIL := 5.0
const INCOME_CONTESTED_MULTIPLIER := 0.0  # No income when contested

signal region_state_changed(region_id: String, new_state: Region.State)
signal region_controller_changed(region_id: String, new_controller: String)
```

### 1.4 Visual Display

**Region Grid Overlay:**
- Render grid lines on the map (subtle, always visible)
- Color-code regions by controller:
  - Blue: P1 controlled
  - Red: P2 controlled
  - Grey: Neutral
  - Striped/flashing: Contested
- Resource regions have special icon/marker

**Implementation:**
- New `RegionGridVisual` node under the 3D world
- Uses `MeshInstance3D` or `ImmediateMesh` for grid lines
- Colored overlays as semi-transparent quads

### 1.5 Ground Presence Calculation

```gdscript
func calculate_ground_presence(region: Region) -> void:
    var rect := region.world_rect

    if region.type == Region.Type.RESOURCE_MINE or region.type == Region.Type.RESOURCE_OIL:
        # Resource regions require stationed units
        region.p1_ground_presence = _count_stationed_units(rect, "p1")
        region.p2_ground_presence = _count_stationed_units(rect, "p2")
    else:
        # Normal regions: fog of war visibility is enough
        region.p1_ground_presence = _get_vision_coverage(rect, "p1")
        region.p2_ground_presence = _get_vision_coverage(rect, "p2")

    # Buildings always count
    region.p1_ground_presence += _count_buildings(rect, "p1") * 2.0
    region.p2_ground_presence += _count_buildings(rect, "p2") * 2.0
```

### 1.6 Income System Integration

```gdscript
func _process(delta: float) -> void:
    var p1_income := 0.0
    var p2_income := 0.0

    for region in regions.values():
        if region.type == Region.Type.BASE:
            continue  # Base regions don't generate map income

        var income := _get_region_income(region)

        match region.state:
            Region.State.CONTROLLED_P1:
                p1_income += income
            Region.State.CONTROLLED_P2:
                p2_income += income
            Region.State.CONTESTED:
                # Reduced or no income
                pass

    # Add to team credits
    GameState.credits_p1 += p1_income * delta
    GameState.credits_p2 += p2_income * delta
```

---

## Phase 2: Air Dominance Layer

### 2.1 Aircraft Fuel System

**Modifications to existing aircraft units:**

```gdscript
# In unit.gd or new aircraft_component.gd

var max_fuel: float = 120.0
var current_fuel: float = 120.0
var fuel_consumption_idle: float = 0.0
var fuel_consumption_patrol: float = 1.0
var fuel_consumption_aggressive: float = 2.0
var fuel_consumption_combat: float = 3.0

var rtb_threshold: float = 0.2    # 20% fuel triggers RTB
var critical_threshold: float = 0.1  # 10% fuel forces RTB

var assigned_airfield: Node = null
var patrol_mode: PatrolMode = PatrolMode.DEFEND_BASE
var is_returning_to_base: bool = false

enum PatrolMode { DEFEND_BASE, AIR_SUPERIORITY }
```

**Fuel consumption per mode:**

| Mode | Fuel/sec | Coverage | Risk |
|------|----------|----------|------|
| Idle at airfield | 0 | None | None |
| Defend Base | 1 | Own territory | Minimal |
| Air Superiority | 2 | Push into contested | Medium |
| Combat | 3 | N/A | Variable |

### 2.2 Return-to-Base Mechanics

```gdscript
func _process_fuel(delta: float) -> void:
    if is_on_ground():
        _refuel(delta)
        return

    # Consume fuel based on current activity
    var consumption := fuel_consumption_patrol
    if patrol_mode == PatrolMode.AIR_SUPERIORITY:
        consumption = fuel_consumption_aggressive
    if is_in_combat:
        consumption = fuel_consumption_combat

    current_fuel -= consumption * delta

    # Check RTB thresholds
    var fuel_percent := current_fuel / max_fuel
    if fuel_percent <= critical_threshold:
        _force_rtb()
    elif fuel_percent <= rtb_threshold and not is_returning_to_base:
        _request_rtb()

func _refuel(delta: float) -> void:
    current_fuel = min(current_fuel + 10.0 * delta, max_fuel)
```

### 2.3 Patrol Route Generation

```gdscript
func generate_patrol_route(airfield_pos: Vector2, mode: PatrolMode) -> Array[Vector2]:
    var waypoints: Array[Vector2] = []

    match mode:
        PatrolMode.DEFEND_BASE:
            # Circular patrol around airfield, staying in friendly territory
            var radius := 800.0
            for i in range(4):
                var angle := i * TAU / 4.0
                waypoints.append(airfield_pos + Vector2(cos(angle), sin(angle)) * radius)

        PatrolMode.AIR_SUPERIORITY:
            # Pushed forward patrol, into contested territory
            var forward_dir := _get_enemy_direction(airfield_pos)
            var base_offset := forward_dir * 1500.0
            var lateral := forward_dir.rotated(PI / 2) * 600.0

            waypoints.append(airfield_pos + base_offset + lateral)
            waypoints.append(airfield_pos + base_offset * 1.5)
            waypoints.append(airfield_pos + base_offset - lateral)
            waypoints.append(airfield_pos + base_offset * 0.5)

    return waypoints
```

### 2.4 Air Dominance Calculation

```gdscript
func calculate_air_dominance(region: Region) -> void:
    region.p1_air_dominance = 0.0
    region.p2_air_dominance = 0.0

    # Check all aircraft
    for aircraft in get_tree().get_nodes_in_group("aircraft"):
        if not aircraft.is_airborne():
            continue

        var influence := _get_aircraft_influence(aircraft, region)
        if aircraft.team_id == "p1":
            region.p1_air_dominance += influence
        else:
            region.p2_air_dominance += influence

func _get_aircraft_influence(aircraft: Node, region: Region) -> float:
    var aircraft_pos := Vector2(aircraft.global_position.x, aircraft.global_position.z)
    var region_center := region.world_rect.get_center()
    var distance := aircraft_pos.distance_to(region_center)

    # Aircraft project influence in a radius
    var influence_radius := 1000.0  # Adjustable per aircraft type
    if distance > influence_radius:
        return 0.0

    # Influence decreases with distance
    var base_influence := aircraft.air_power  # e.g., F-22 = 3.0, F-16 = 2.0
    return base_influence * (1.0 - distance / influence_radius)
```

### 2.5 Combined Control Determination

```gdscript
func update_region_control(region: Region, delta: float) -> void:
    var p1_total := region.p1_air_dominance + region.p1_ground_presence
    var p2_total := region.p2_air_dominance + region.p2_ground_presence

    var dominance_threshold := 1.5  # Need 50% advantage for control

    var new_controller := ""
    if p1_total > p2_total * dominance_threshold and p1_total > 0.5:
        new_controller = "p1"
    elif p2_total > p1_total * dominance_threshold and p2_total > 0.5:
        new_controller = "p2"

    # Handle state transitions
    match region.state:
        Region.State.NEUTRAL:
            if new_controller != "":
                region.contest_timer += delta
                if region.contest_timer >= CAPTURE_TIME:
                    _set_region_controller(region, new_controller)
            else:
                region.contest_timer = 0.0

        Region.State.CONTROLLED_P1, Region.State.CONTROLLED_P2:
            var current := "p1" if region.state == Region.State.CONTROLLED_P1 else "p2"
            var enemy := "p2" if current == "p1" else "p1"
            var enemy_presence := p2_total if current == "p1" else p1_total

            if enemy_presence > 0.5:
                # Enemy contesting
                region.state = Region.State.CONTESTED
                region.contest_timer = 0.0

        Region.State.CONTESTED:
            if new_controller == region.previous_controller:
                # Original controller pushing back
                region.contest_timer += delta
                if region.contest_timer >= CONTEST_DECAY_TIME:
                    _set_region_controller(region, new_controller)
            elif new_controller != "" and new_controller != region.previous_controller:
                # New controller taking over
                region.contest_timer += delta
                if region.contest_timer >= CAPTURE_TIME:
                    _set_region_controller(region, new_controller)
            else:
                # No clear controller, decay to neutral
                region.contest_timer += delta
                if region.contest_timer >= CONTEST_DECAY_TIME * 2:
                    _set_region_neutral(region)
```

---

## Phase 3: Airforce Command UI

### 3.1 UI Flow

```
AIRFIELD SELECTED
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│  Bottom Menu (existing build_ui.gd)                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ Build   │ │ Rally   │ │AIRFORCE │ │  ...    │           │
│  │ Aircraft│ │ Point   │ │ COMMAND │ │         │           │
│  └─────────┘ └─────────┘ └────┬────┘ └─────────┘           │
└───────────────────────────────┼─────────────────────────────┘
                                │ (click)
                                ▼
┌─────────────────────────────────────────────────────────────┐
│  Airforce Command Menu (secondary page)                     │
│                                                             │
│  Aircraft: 4x F-16, 2x F-22        [◄ BACK]                │
│  Status: 2 Patrolling | 2 Refueling | 2 Ready              │
│                                                             │
│  PATROL MODE:                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │✓ DEFEND     │  │  AIR        │  │  (LOCKED)   │         │
│  │   BASE      │  │  SUPERIORITY│  │             │         │
│  │             │  │             │  │  Future     │         │
│  │ Safe patrol │  │ Aggressive  │  │  modes      │         │
│  │ Low fuel    │  │ High fuel   │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Implementation

**Modifications to `build_ui.gd`:**

```gdscript
# Add airforce command button when airfield selected
func _on_selection_changed(selected: Array) -> void:
    # ... existing code ...

    if _is_airfield_selected(selected):
        _show_airforce_command_button()

func _show_airforce_command_button() -> void:
    var airforce_btn := _create_menu_button("AIRFORCE", _on_airforce_pressed)
    _add_to_menu(airforce_btn)

func _on_airforce_pressed() -> void:
    _switch_to_airforce_menu()
```

**New `airforce_menu.gd`:**

```gdscript
extends Control

var selected_airfield: Node = null

@onready var aircraft_label: Label = $AircraftLabel
@onready var status_label: Label = $StatusLabel
@onready var defend_btn: Button = $DefendButton
@onready var superiority_btn: Button = $SuperiorityButton
@onready var back_btn: Button = $BackButton

func show_for_airfield(airfield: Node) -> void:
    selected_airfield = airfield
    _update_display()
    visible = true

func _update_display() -> void:
    var aircraft := selected_airfield.get_stationed_aircraft()
    aircraft_label.text = _format_aircraft_list(aircraft)
    status_label.text = _format_status(aircraft)

    var current_mode := selected_airfield.patrol_mode
    defend_btn.button_pressed = (current_mode == PatrolMode.DEFEND_BASE)
    superiority_btn.button_pressed = (current_mode == PatrolMode.AIR_SUPERIORITY)

func _on_defend_pressed() -> void:
    selected_airfield.set_patrol_mode(PatrolMode.DEFEND_BASE)
    _update_display()

func _on_superiority_pressed() -> void:
    selected_airfield.set_patrol_mode(PatrolMode.AIR_SUPERIORITY)
    _update_display()

func _on_back_pressed() -> void:
    visible = false
    # Return to main build menu
    get_parent().show_main_menu()
```

---

## Phase 4: Combat Modifiers

### 4.1 Zone-Based Damage Modifiers

```gdscript
# In unit.gd or combat system

func calculate_damage_taken(base_damage: float, attacker: Node) -> float:
    if not is_aircraft():
        return base_damage

    var my_region := RegionController.get_region_at(global_position)
    var zone_type := _get_zone_type_for_team(my_region, team_id)

    var modifier := 1.0
    match zone_type:
        ZoneType.SAFE:
            modifier = 1.0      # Normal damage
        ZoneType.CONTESTED:
            modifier = 1.5      # +50% damage taken
        ZoneType.DANGER:
            modifier = 2.0      # +100% damage taken

    return base_damage * modifier

enum ZoneType { SAFE, CONTESTED, DANGER }

func _get_zone_type_for_team(region: Region, team: String) -> ZoneType:
    if region.controller == team:
        return ZoneType.SAFE
    elif region.state == Region.State.CONTESTED or region.controller == "":
        return ZoneType.CONTESTED
    else:
        return ZoneType.DANGER
```

### 4.2 Loiter/Exposure System

```gdscript
# Aircraft accumulate exposure when in contested/enemy zones

var exposure: float = 0.0
const EXPOSURE_SAFE_THRESHOLD := 10.0   # Seconds before penalties start
const EXPOSURE_MAX := 30.0               # Maximum exposure

func _process_exposure(delta: float) -> void:
    var zone_type := _get_current_zone_type()

    match zone_type:
        ZoneType.SAFE:
            # Exposure decays in safe zones
            exposure = max(0.0, exposure - delta * 2.0)
        ZoneType.CONTESTED:
            exposure += delta
        ZoneType.DANGER:
            exposure += delta * 2.0

    exposure = min(exposure, EXPOSURE_MAX)

func get_exposure_damage_modifier() -> float:
    if exposure < EXPOSURE_SAFE_THRESHOLD:
        return 1.0

    var excess := exposure - EXPOSURE_SAFE_THRESHOLD
    var max_excess := EXPOSURE_MAX - EXPOSURE_SAFE_THRESHOLD

    # Scales from 1.0 to 2.0 based on exposure
    return 1.0 + (excess / max_excess)
```

### 4.3 Aircraft Effectiveness by Zone

| Zone Type | Damage Dealt | Damage Taken | Notes |
|-----------|--------------|--------------|-------|
| Safe | 100% | 100% | Normal operation |
| Contested | 75% | 150% | Combat penalties |
| Danger | 50% | 200% | Deep strike only |

---

## Phase 5: Expanded Building System

### 5.1 Build Anywhere With Vision

**Modifications to `build_controller.gd`:**

```gdscript
func can_build_at(position: Vector2, building_type: String, team: String) -> Dictionary:
    var result := {
        "can_build": false,
        "instant": false,
        "build_time": 0.0,
        "reason": ""
    }

    # Check if position has vision (no fog of war)
    if not VisibilityController.has_vision_at(position, team):
        result.reason = "No vision at location"
        return result

    # Check if in build zone
    var in_build_zone := _is_in_build_zone(position, team)

    # Check building type restrictions
    var building_data := BuildingData.get(building_type)
    if building_data.requires_build_zone and not in_build_zone:
        result.reason = "Must be built in base"
        return result

    result.can_build = true
    result.instant = in_build_zone
    result.build_time = 0.0 if in_build_zone else building_data.field_build_time

    return result
```

### 5.2 Build Timer System

```gdscript
# construction_site.gd - Represents building under construction

class_name ConstructionSite
extends Node3D

var building_type: String
var team_id: String
var build_time_total: float
var build_time_remaining: float
var is_paused: bool = false

signal construction_complete(building_type: String, position: Vector3)
signal construction_cancelled()

func _process(delta: float) -> void:
    # Check if we still have vision
    var pos_2d := Vector2(global_position.x, global_position.z)
    if not VisibilityController.has_vision_at(pos_2d, team_id):
        is_paused = true
        return

    is_paused = false
    build_time_remaining -= delta

    if build_time_remaining <= 0:
        emit_signal("construction_complete", building_type, global_position)
        queue_free()

func get_progress() -> float:
    return 1.0 - (build_time_remaining / build_time_total)
```

### 5.3 New Defensive Buildings

**Defense Turret:**
```gdscript
# Building data
{
    "id": "defense_turret",
    "name": "Defense Turret",
    "cost": 100,
    "hp": 500,
    "requires_build_zone": false,
    "field_build_time": 15.0,
    "attack_damage": 25,
    "attack_range": 400,
    "attack_speed": 1.0,
    "vision_range": 350,
    "targets": ["ground", "infantry"]
}
```

**SAM Site:**
```gdscript
{
    "id": "sam_site",
    "name": "SAM Site",
    "cost": 250,
    "hp": 400,
    "requires_build_zone": false,
    "field_build_time": 30.0,
    "attack_damage": 150,
    "attack_range": 1200,
    "attack_speed": 0.3,
    "vision_range": 800,
    "targets": ["aircraft"],
    "creates_air_denial": true,
    "air_denial_radius": 1000
}
```

### 5.4 Build UI Updates

```gdscript
# Visual feedback during build placement

func _update_build_preview(position: Vector2) -> void:
    var can_build := BuildController.can_build_at(position, selected_building, team_id)

    if not can_build.can_build:
        _show_invalid_placement(can_build.reason)
        preview_mesh.material = invalid_material  # Red
    elif can_build.instant:
        _show_valid_placement("Instant build")
        preview_mesh.material = valid_instant_material  # Green
    else:
        _show_valid_placement("Build time: %ds" % can_build.build_time)
        preview_mesh.material = valid_timer_material  # Yellow
```

---

## Phase 6: Resource Regions

### 6.1 Map Data Extension

```json
{
    "regions": {
        "resource_regions": [
            {"id": "A4", "type": "oil", "income": 5.0},
            {"id": "D4", "type": "oil", "income": 5.0},
            {"id": "G4", "type": "oil", "income": 5.0},
            {"id": "B2", "type": "mine", "income": 3.0},
            {"id": "B6", "type": "mine", "income": 3.0},
            {"id": "F2", "type": "mine", "income": 3.0},
            {"id": "F6", "type": "mine", "income": 3.0}
        ],
        "base_regions": [
            {"id": "A1", "owner": "p1"},
            {"id": "G1", "owner": "p1"},
            {"id": "A7", "owner": "p2"},
            {"id": "G7", "owner": "p2"}
        ]
    }
}
```

### 6.2 Visual Markers

- Resource regions have distinct visual markers on the map
- Mine regions: Pickaxe icon or mountain symbol
- Oil regions: Oil derrick icon or droplet symbol
- Different border styling for resource vs normal regions

---

## File Structure

```
godot/scripts/
├── core/
│   ├── region.gd                    # NEW - Region data class
│   ├── region_controller.gd         # NEW - Region management
│   ├── aircraft_controller.gd       # NEW - Aircraft patrol/fuel management
│   ├── construction_site.gd         # NEW - Building under construction
│   └── ... (existing files)
├── ui/
│   ├── airforce_menu.gd            # NEW - Airforce command UI
│   ├── region_grid_visual.gd       # NEW - Region overlay rendering
│   ├── build_ui.gd                 # MODIFY - Add airforce button
│   └── ... (existing files)
├── data/
│   ├── building_definitions.gd     # MODIFY - Add turret, SAM
│   └── ... (existing files)
└── visuals/
    └── region_overlay_3d.gd        # NEW - 3D region visualization
```

---

## Implementation Order

### Sprint 1: Region Foundation
1. Create `Region` class
2. Create `RegionController` with 7x7 grid
3. Implement ground presence calculation (fog of war based)
4. Add region visual overlay (grid lines, color coding)
5. Basic income generation from controlled regions

### Sprint 2: Air Dominance
1. Add fuel system to aircraft
2. Implement RTB mechanics
3. Create patrol route generation
4. Calculate air dominance per region
5. Combine air + ground for control determination

### Sprint 3: Airforce UI
1. Add "Airforce Command" button to build UI
2. Create secondary menu panel
3. Implement Defend Base mode toggle
4. Display aircraft status (patrolling/refueling/ready)

### Sprint 4: Combat Modifiers
1. Implement zone-based damage modifiers
2. Add exposure/loiter system
3. Apply effectiveness penalties by zone

### Sprint 5: Air Superiority Mode
1. Implement aggressive patrol routes
2. Higher fuel consumption
3. UI toggle for mode selection

### Sprint 6: Expanded Building
1. Modify build placement to allow anywhere with vision
2. Implement construction timer system
3. Add Defense Turret building
4. Add SAM Site building
5. Update build UI with timer feedback

### Sprint 7: Resource Regions
1. Mark resource regions in map data
2. Implement stationed unit requirement
3. Add visual markers for resource regions
4. Higher income rates for resource control

---

## Balance Considerations

### Income Rates (per second)
- Normal region (controlled): 1 credit
- Mine region (controlled): 3 credits
- Oil region (controlled): 5 credits
- Contested: 0 credits
- Base income (fixed): 10 credits/sec (existing system)

### Aircraft Fuel
- F-16: 120 fuel (2 min defend, 1 min aggressive)
- F-22: 180 fuel (3 min defend, 1.5 min aggressive)
- Gripen: 100 fuel (budget fighter, faster refuel)

### Zone Combat Modifiers
- Safe zone: 100% effectiveness
- Contested: 75% damage dealt, 150% damage taken
- Danger zone: 50% damage dealt, 200% damage taken

### Building Costs & Times
- Defense Turret: 100 credits, 15s build time
- SAM Site: 250 credits, 30s build time

---

## Future Expansions

After this system is complete, the following can be added:

1. **Helicopters** - Require air dominance to operate
2. **Drones/UAVs** - Recon + strike in safe zones
3. **Cruise/Ballistic Missiles** - Long range strikes
4. **Additional Patrol Modes** - Escort, Intercept, Ground Attack
5. **Forward Bases** - Outpost (extends build zone), Forward Airfield
6. **SEAD Missions** - Suppress Enemy Air Defense
7. **Radar Systems** - Extended detection range
8. **Electronic Warfare** - Jamming, stealth mechanics
