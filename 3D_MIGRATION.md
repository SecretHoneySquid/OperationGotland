# 3D Migration - Removing Legacy 2D Rendering

## Changes Made (2026-01-03)

The game had a **2D proof-of-concept layer** that was still rendering alongside the 3D visualization. This has been cleaned up.

## What Was Changed

### 1. Disabled 2D Rendering
**File**: [godot/scenes/game/main.tscn](godot/scenes/game/main.tscn)

Changed MapRoot rendering:
```gdscript
# Before:
render_2d = true  # Drew 2D map, build zones, etc.

# After:
render_2d = false  # Disabled legacy 2D rendering
```

### 2. Added 3D Build Zone Visualization
Added **VisualSync** node to render build zones in 3D:

```gdscript
[node name="VisualSync" type="Node3D" parent="World3D"]
script = ExtResource("11_vsync")
ground_path = NodePath("../../Terrain3D")
show_build_zone = true           # ← Enables 3D build zone rendering
show_build_zone_outline = true   # ← Shows green outlines
```

### 3. Added 3D Mouse Input Handling
Added **WorldInput** node for converting mouse clicks to 3D world coordinates:

```gdscript
[node name="WorldInput" type="Node" parent="."]
script = ExtResource("12_winput")
camera_path = NodePath("../World3D/CameraRig/Camera3D")
```

This enables building placement in 3D by raycasting from the camera to the ground plane.

### 4. Added 3D Environment
Added proper 3D rendering environment:
- **WorldEnvironment** - Sets background color and rendering settings
- **NavigationRegion3D** - For pathfinding (future use)

### 5. Updated Build Zone Coordinates
**File**: [godot/data/maps/test_map.json](godot/data/maps/test_map.json)

Moved build zones from negative/off-map coordinates to visible positive coordinates:

| Zone | Old Position | New Position | Size |
|------|-------------|--------------|------|
| P1 | x:-2524, y:-1650 | x:200, y:200 | 1800×1800 |
| P2 | x:-1404, y:-2717 | x:4200, y:4200 | 1800×1800 |

## Current Architecture

```
main.tscn (Main Scene)
├── 2D Logic Layer (invisible)
│   ├── GameController (spawns units, manages state)
│   ├── BuildController (handles building logic)
│   ├── SelectionController (handles selection)
│   └── Camera2D (legacy, not rendered)
│
└── 3D Visualization Layer
    ├── CameraRig (3D camera controller)
    │   └── Camera3D (active camera)
    ├── DirectionalLight3D (lighting)
    ├── Environment (rendering settings)
    ├── NavigationRegion3D (pathfinding)
    ├── Terrain3D (your map terrain)
    └── VisualSync (syncs 2D logic → 3D visuals)
        ├── Renders units as 3D models
        ├── Renders buildings as 3D models
        └── Renders build zones (green grid)
```

## Why This Architecture?

The game uses **2D logic with 3D visualization**:
- **2D logic** is simpler for RTS mechanics (pathfinding, collision, etc.)
- **3D visualization** provides better visuals
- **VisualSync** bridges the gap, converting 2D positions to 3D

This is actually a good architecture! It separates simulation from presentation.

## What You Should See Now

When running the game:
1. ✅ **3D terrain** visible
2. ✅ **Green build zone grid** in the top-left area (P1 zone)
3. ✅ **3D camera controls** (WASD to pan, scroll to zoom)
4. ✅ **Building placement** works with mouse in 3D
5. ❌ **No 2D overlays** (map outlines, 2D sprites, etc.)

## Build Zone Location

**Player 1 Build Zone**:
- Position: (200, 200)
- Size: 1800 × 1800
- Visible in top-left quadrant of map

**Camera starts** near (1000, 600), which is right in the build zone area.

## Testing

1. **Run the game** ([main.tscn](godot/scenes/game/main.tscn))
2. **Look for green grid** - that's your build zone
3. **Open build menu** (check BuildUI in game)
4. **Click inside green grid** - should allow building placement
5. **Use WASD** to pan camera if needed

## If Build Zones Still Don't Show

Check these settings in the editor:

1. **VisualSync node** → `show_build_zone = true`
2. **VisualSync node** → `show_build_zone_outline = true`
3. **MapRoot node** → `render_2d = false`

---

**Summary**: The 2D proof-of-concept rendering is now disabled. The game runs in full 3D with proper build zone visualization via VisualSync.
