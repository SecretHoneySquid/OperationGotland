# Troubleshooting Guide - Building Placement

## Current Setup

Your game should now have:
- ✅ 3D terrain visible
- ✅ Green build zone grid visible
- ✅ Build menu on left side of screen
- ✅ 3D camera controls (WASD)

## If Ghost Doesn't Appear

### Check 1: Is Build Mode Active?

**What to Look For:**
- Build menu should be visible on the **left side** of the screen
- Menu shows: "Build Menu", Credits, Income, Production stats
- Multiple building buttons (Barracks $150, Factory $300, etc.)

**How to Activate Build Mode:**
1. Click one of the building buttons (e.g., "Barracks ($150)")
2. The button should trigger build mode
3. A green/red ghost box should appear

### Check 2: Console Output

Open Godot console and look for errors:
```
[WorldInput] ERROR: Camera not found at path: ...
```

If you see this, the camera path is wrong.

### Check 3: Verify Node Paths

In Godot Editor, open `main.tscn` and check:

**WorldInput node:**
- `camera_path` = `World3D/CameraRig/Camera3D` ✅
- `terrain_path` = `Terrain3D` ✅
- `use_terrain_raycast` = `false` ✅
- Should be in group "world_input" ✅

**VisualSync node:**
- `show_build_ghost` = `true` ✅
- `build_controller_path` = `../../BuildController` ✅
- Parent should be `World3D` ✅

**BuildController node:**
- `render_2d` = `false` ✅
- Parent should be `Main` (root) ✅

### Check 4: Camera Setup

**Camera3D:**
- Should be active (`current = true`)
- Located at `World3D/CameraRig/Camera3D`

**Camera2D:**
- Should be disabled (`enabled = false`)

## Manual Test Steps

1. **Launch the game** (press F5 or click Play in Godot)

2. **Look for build menu** on left side:
   ```
   Build Menu
   Credits: 500
   Income/s: ...
   Inf Prod: ...

   [Barracks ($150)]
   [Factory ($300)]
   ...
   ```

3. **Click "Barracks ($150)"** button

4. **Move mouse over green build zone** → Ghost should appear

5. **Ghost behavior:**
   - ✅ Green box when over build zone
   - ❌ Red/orange box when outside or overlapping
   - Should follow mouse cursor

## Common Issues

### Issue: No Build Menu Visible

**Solution:**
- Check if `BuildUI` node exists in scene tree
- Check if `build_controller_path` in BuildUI is correct
- Look for error in console about BuildController not found

### Issue: Ghost Appears in Wrong Location

**Solution:**
- Set `use_terrain_raycast = false` in WorldInput (already done)
- This uses flat ground plane at y=0

### Issue: Can't Click Buildings

**Solution:**
- Make sure you have enough credits (starting is 500)
- Ghost must be GREEN (valid placement)
- Click LEFT MOUSE BUTTON to place

### Issue: Ghost is 2D (flat square on screen)

**Solution:**
- Check `BuildController.render_2d` should be `false`
- Check `VisualSync.show_build_ghost` should be `true`

## Debug Commands

Add these to BuildController's `_process()` function temporarily for debugging:

```gdscript
func _process(_delta: float) -> void:
	if _active_build_id != "":
		print("Build Mode Active: ", _active_build_id)
		print("Ghost Pos: ", _ghost_pos)
		print("Ghost Valid: ", _ghost_valid)
	# ... rest of function
```

Add to WorldInput's `screen_to_world()`:

```gdscript
func screen_to_world(screen_pos: Vector2) -> Vector2:
	var camera := get_node_or_null(camera_path) as Camera3D
	if camera == null:
		print("[WorldInput] ERROR: Camera not found at path: ", camera_path)
		return _last_valid

	# ... rest of function

	print("[WorldInput] Mouse at: ", screen_pos, " → World: ", pos)
	return pos
```

## Quick Fix Commands

If ghost still doesn't appear, try these in Godot's console while game is running:

```gdscript
# Check if WorldInput exists
get_tree().get_nodes_in_group("world_input")

# Check if BuildController is in placement mode
$BuildController.is_placing()

# Force placement mode
$BuildController.start_placement("barracks")
```

## File Checklist

Verify these files are correctly set up:

- [ ] `godot/scenes/game/main.tscn` - All nodes configured
- [ ] `godot/scripts/visuals/world_input_3d.gd` - Updated with terrain support
- [ ] `godot/scripts/core/build_controller.gd` - render_2d disabled
- [ ] `godot/data/maps/test_map.json` - Build zones in positive coordinates

---

If none of this works, share what you see on screen and any console errors!
