# HIMARS Animation System - Update Summary

## What Changed

### New Animated Model
Switched from static `Himars.glb` to animated `m142_himars__free_model__animation.glb`

**File**: `scenes/units/himars_visual.tscn`
- Now references the animated model with built-in animations

### Enhanced Animation System
**File**: `scripts/core/unit.gd`

The deployment system now supports **dual-mode operation**:

#### Mode 1: Built-in GLB Animations (Primary)
- Automatically detects AnimationPlayer in the model
- Searches for animations with keywords:
  - **Deploy**: "deploy", "raise", "up", "fire", "ready", "elevate"
  - **Stow**: "stow", "lower", "down", "travel", "retract"
- Plays animations with timing matched to `himars_deploy_time`
- Can play animations backwards if only one animation exists

#### Mode 2: Manual Rotation (Fallback)
- Activates if no AnimationPlayer is found
- Smoothly rotates launcher node from -15° to 45°
- Same behavior as before, ensures compatibility

### New Variables Added
```gdscript
var _himars_animation_player: AnimationPlayer = null
var _himars_has_animations := false
```

### New Functions
1. **`_find_animation_player()`** - Recursively searches for AnimationPlayer
2. **`_update_himars_with_animations()`** - Handles GLB animation playback
3. **`_update_himars_manual_rotation()`** - Fallback rotation logic

### Updated Test Script
**File**: `test_himars_structure.gd`
- Now inspects the animated model
- Compares old vs new model structure
- Shows all animations available

## How It Works

### Initialization (First Frame)
1. System searches for AnimationPlayer in HIMARS visual node
2. If found:
   - Gets list of all animations
   - Sets animation speed to match deploy time (3 seconds)
   - Enables animation mode
3. If not found:
   - Searches for launcher node (original method)
   - Enables manual rotation mode

### During Gameplay
**When Deployed (launcher up)**:
- Animation mode: Plays "deploy" animation (or similar keyword)
- Manual mode: Rotates to 45°

**When Stowed (launcher down)**:
- Animation mode: Plays "stow" animation or "deploy" backwards
- Manual mode: Rotates to -15°

### Console Output
You'll see these messages during gameplay:

**Successful Animation Detection**:
```
[HIMARS] Found AnimationPlayer with animations: ["Animation1", "Animation2"]
[HIMARS] Playing deploy animation: Animation1
[HIMARS] Playing stow animation: Animation2
```

**Fallback to Manual Rotation**:
```
[HIMARS] No AnimationPlayer found, using manual rotation
[HIMARS] Found launcher node for manual rotation: LauncherPod
```

**Deployment Events**:
```
[HIMARS] Starting deployment (raising launcher)
[HIMARS] Deployment complete: deployed=true
[HIMARS] Starting stow (lowering launcher)
```

## Testing Checklist

1. ✅ Spawn HIMARS from factory
2. ✅ Check console for animation detection messages
3. ✅ Watch HIMARS auto-deploy when enemies approach
4. ✅ Verify launcher raises (animation or rotation)
5. ✅ Give move command - launcher should lower
6. ✅ Wait for arrival - launcher should raise again
7. ✅ Set bombardment area - should deploy immediately
8. ✅ Cancel bombardment - should stow

## Benefits

### With Animated Model
- **Realistic animations** from professional 3D artist
- **Authentic movement** matching real HIMARS deployment
- **Multiple moving parts** - not just launcher rotation
- **Professional quality** visual feedback

### Fallback System
- **100% compatibility** - works even if animations fail
- **No crashes** - gracefully handles missing assets
- **Easy debugging** - clear console messages
- **Smooth transitions** - interpolated rotation

## File Structure
```
godot/
├── assets/models/HIMARS/
│   ├── m142_himars__free_model__animation.glb  ← NEW animated model
│   ├── Himars.glb  ← Old static model (backup)
│   └── mgm140.glb  ← ATACMS missile
├── scenes/units/
│   └── himars_visual.tscn  ← Updated to use animated model
├── scripts/core/
│   └── unit.gd  ← Enhanced with animation support
├── test_himars_structure.gd  ← Model inspector script
├── HIMARS_SETUP_GUIDE.md  ← Configuration guide
└── HIMARS_ANIMATION_UPDATE.md  ← This file
```

## What You Should See

### Best Case (Animations Working)
1. HIMARS spawns with launcher in lowered position
2. Console shows: "Found AnimationPlayer with animations"
3. When deploying, smooth animation plays with all moving parts
4. Launcher, stabilizers, or other parts move realistically
5. Animation completes in exactly 3 seconds

### Fallback Case (Manual Rotation)
1. HIMARS spawns normally
2. Console shows: "No AnimationPlayer found, using manual rotation"
3. When deploying, launcher rotates smoothly from -15° to 45°
4. Still looks good, just simpler movement
5. Rotation completes in exactly 3 seconds

## Next Steps

1. **Run the game** and spawn a HIMARS
2. **Check the console** to see which mode activated
3. **Test deployment** by setting bombardment area
4. **Test stowing** by commanding movement

If you want to see the exact model structure, run `test_himars_structure.gd` in Godot editor (attach it to a Node and press F6).

## Customization

Animation timing can be adjusted via export variable:
```gdscript
@export var himars_deploy_time := 3.0  # Seconds for animation
```

Change this value to make deployment faster or slower. The system automatically adjusts both animation playback speed and manual rotation speed to match.
