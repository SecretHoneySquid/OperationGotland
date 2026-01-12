# HIMARS Launcher Animation Setup Guide

## Overview
This guide explains how to set up AnimationPlayer-based launcher elevation for the HIMARS model.

## Quick Start

### Step 1: Run the Setup Script
1. Open Godot Editor
2. Open the script: `godot/setup_himars_animation.gd`
3. Click **File → Run** (or press Ctrl+Shift+X)
4. The script will:
   - Analyze the GLB structure
   - Create a `LauncherPivot` node at the hinge point
   - Reparent the launcher mesh under the pivot
   - Create 4 animations in AnimationPlayer
   - Save the result to `res://scenes/units/himars_visual_animated.tscn`

### Step 2: Verify Output
Check the console output for:
```
✓ SUCCESS: Saved to res://scenes/units/himars_visual_animated.tscn
```

### Step 3: Use in Game
Update `unit.gd` to use the new scene:

```gdscript
# Change this line in unit.gd or your HIMARS definition
visual_scene_path = "res://scenes/units/himars_visual_animated.tscn"
```

---

## Created Animations

The setup script creates 4 animations:

### 1. `launcher_lowered`
- **Duration:** 0.1s (static pose)
- **Rotation:** 0° (travel position)
- **Use:** Set launcher to lowered state instantly

### 2. `launcher_raised`
- **Duration:** 0.1s (static pose)
- **Rotation:** -50° (fire position)
- **Use:** Set launcher to raised state instantly

### 3. `launcher_raise`
- **Duration:** 1.2s (smooth transition)
- **Rotation:** 0° → -50°
- **Use:** Animate deploying the launcher

### 4. `launcher_lower`
- **Duration:** 1.2s (smooth transition)
- **Rotation:** -50° → 0°
- **Use:** Animate stowing the launcher

---

## Usage in Code

### Basic Playback

```gdscript
# In unit.gd or HIMARS controller
var animation_player: AnimationPlayer = null

func _ready() -> void:
    # Find AnimationPlayer in the visual node
    animation_player = _find_animation_player(_visual_node)

func deploy_launcher() -> void:
    """Raise the launcher to fire position"""
    if animation_player != null:
        animation_player.play("launcher_raise")

func stow_launcher() -> void:
    """Lower the launcher to travel position"""
    if animation_player != null:
        animation_player.play("launcher_lower")
```

### Wait for Animation Completion

```gdscript
func deploy_and_fire() -> void:
    """Deploy launcher, wait, then fire"""
    animation_player.play("launcher_raise")
    await animation_player.animation_finished
    print("Launcher deployed!")
    # Fire missiles here
```

### Instant State Changes

```gdscript
func set_launcher_state(raised: bool) -> void:
    """Instantly set launcher position without animation"""
    if animation_player != null:
        if raised:
            animation_player.play("launcher_raised")
        else:
            animation_player.play("launcher_lowered")
```

### Adjust Animation Speed

```gdscript
# Play deployment at 2x speed
animation_player.speed_scale = 2.0
animation_player.play("launcher_raise")

# Play deployment at half speed (dramatic effect)
animation_player.speed_scale = 0.5
animation_player.play("launcher_raise")
```

---

## Scene Structure

After running the setup script, your HIMARS scene will have this structure:

```
himars_visual_animated.tscn
├── RootNode (Node3D)
│   ├── Chassis (Node3D/MeshInstance3D)
│   ├── Wheels (Node3D/MeshInstance3D)
│   ├── LauncherPivot (Node3D) ← NEW - Rotation hinge
│   │   └── LauncherMesh (MeshInstance3D) ← Reparented here
│   └── AnimationPlayer ← Contains all 4 animations
```

---

## Integration with Existing Code

### Replace Manual Rotation System

Your existing `unit.gd` has this manual rotation code:

```gdscript
# OLD SYSTEM (manual rotation)
func _update_himars_manual_rotation(delta: float) -> void:
    var target_angle = 45.0 if deployed else -15.0
    _himars_current_angle = move_toward(_himars_current_angle, target_angle, speed * delta)
    _himars_launcher_node.rotation_degrees.x = _himars_current_angle
```

Replace with:

```gdscript
# NEW SYSTEM (AnimationPlayer)
func _update_himars_deployment(deployed: bool) -> void:
    if _himars_animation_player == null:
        return

    var target_anim = "launcher_raise" if deployed else "launcher_lower"
    var current_anim = _himars_animation_player.current_animation

    # Only play if not already in this state
    if current_anim != target_anim:
        _himars_animation_player.play(target_anim)
```

### Full Integration Example

```gdscript
# In unit.gd
var _himars_animation_player: AnimationPlayer = null
var _himars_launcher_deployed := false

func _setup_himars_animations() -> void:
    """Find AnimationPlayer in the visual scene"""
    if _visual_node == null:
        return

    _himars_animation_player = _find_animation_player(_visual_node)

    if _himars_animation_player != null:
        print("[HIMARS] AnimationPlayer found with animations: %s" % [_himars_animation_player.get_animation_list()])
        # Start in lowered position
        _himars_animation_player.play("launcher_lowered")

func set_himars_deployed(deployed: bool) -> void:
    """Control launcher deployment state"""
    if _himars_launcher_deployed == deployed:
        return  # Already in this state

    _himars_launcher_deployed = deployed

    if _himars_animation_player != null:
        var anim = "launcher_raise" if deployed else "launcher_lower"
        _himars_animation_player.play(anim)
        print("[HIMARS] Playing animation: %s" % anim)

func _process(delta: float) -> void:
    # Update deployment based on bombardment state
    if is_himars:
        var should_deploy = _bombardment_area_active or _bombardment_area_target != Vector2.ZERO
        set_himars_deployed(should_deploy)
```

---

## Customization

### Adjust Elevation Angle

Edit `setup_himars_animation.gd`:

```gdscript
const LAUNCHER_ELEVATION_ANGLE = -50.0  # Change this value
# Negative = up (HIMARS orientation)
# Range: -30° to -70° for realistic HIMARS
```

Then re-run the script.

### Adjust Animation Speed

Edit `setup_himars_animation.gd`:

```gdscript
const ANIMATION_DURATION = 1.2  # Change this value (seconds)
```

### Adjust Pivot Point

If the launcher rotates from the wrong point, you need to adjust the pivot position manually in Godot Editor:

1. Open `himars_visual_animated.tscn`
2. Select `LauncherPivot` node
3. Move it to the correct hinge point (rear bottom of launcher)
4. Save the scene

---

## Troubleshooting

### Animation Not Playing

**Symptom:** `animation_player.play()` does nothing

**Solution:**
- Check that AnimationPlayer exists: `print(animation_player != null)`
- Check animations exist: `print(animation_player.get_animation_list())`
- Ensure node paths are correct in animation tracks

### Launcher Rotates from Wrong Point

**Symptom:** Launcher spins around wrong axis or point

**Solution:**
- Open `himars_visual_animated.tscn` in editor
- Adjust `LauncherPivot` position to the physical hinge point
- The pivot should be at the **rear bottom** of the launcher box

### Animation Doesn't Affect Launcher

**Symptom:** Animation plays but launcher doesn't move

**Solution:**
- Check animation tracks target the correct node path
- Verify LauncherPivot is the parent of the launcher mesh
- Re-run setup script if structure is wrong

### Launcher Already Has Rotation

**Symptom:** Launcher starts at wrong angle

**Solution:**
```gdscript
# Reset to lowered position on spawn
if _himars_animation_player != null:
    _himars_animation_player.play("launcher_lowered")
```

---

## Technical Details

### Animation Tracks

Each animation contains a single track:

```
Track Type: TYPE_ROTATION_3D
Track Path: NodePath to LauncherPivot
Interpolation: CUBIC (smooth ease in/out)
Keys: Start rotation → End rotation
```

### Rotation Axis

- **Axis:** Local X (pitch)
- **Direction:** Negative = Up (HIMARS coordinate system)
- **Range:** 0° (level) to -50° (elevated)

### Node Hierarchy

The launcher mesh **must** be a child of `LauncherPivot`:

```
LauncherPivot          ← Rotates
└── LauncherMesh       ← Follows rotation
```

This ensures rotation occurs around the pivot point, not the mesh center.

---

## Performance Notes

- AnimationPlayer is **highly optimized** in Godot
- No overhead compared to manual rotation
- Animations are **deterministic** (same result every time)
- Frame rate independent (uses delta time internally)
- Can be paused, reversed, speed-scaled without issues

---

## Next Steps

1. Run `setup_himars_animation.gd` to generate the animated scene
2. Update `unit.gd` to use the new scene path
3. Replace manual rotation code with AnimationPlayer calls
4. Test in-game deployment/stowing
5. Adjust angles/timing if needed and re-run setup script
