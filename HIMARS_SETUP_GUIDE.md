# HIMARS Launcher Animation Setup Guide

## Overview
The HIMARS now has an automated deployment system where the launcher raises before firing and lowers for travel. The system uses the **animated M142 HIMARS model** (`m142_himars__free_model__animation.glb`) which includes built-in animations from Sketchfab.

## Current Setup
The game now uses the **animated model** with native GLB animations. The system automatically:
1. Detects the AnimationPlayer in the model
2. Finds and plays the appropriate deploy/stow animations
3. Falls back to manual rotation if no animations are found

## How It Works

### Automatic Behavior
1. **When Traveling**: Launcher is at `-15°` (lowered position)
2. **When Deploying**: Launcher smoothly raises to `45°` over 3 seconds
3. **When Firing**: Launcher stays elevated at `45°`
4. **When Stowing**: Launcher lowers back to `-15°` over 3 seconds

### Deployment Triggers
The HIMARS automatically deploys when:
- It has a bombardment area target set
- It has enemies in range and is not manually moving
- It's stationary and ready to fire

The HIMARS automatically stows when:
- It receives a manual move command
- It has no targets to engage

### Code Implementation
The system searches the 3D model for a node representing the launcher by looking for common keywords:
- "launcher"
- "pod"
- "rocket"
- "missile"
- "tube"
- "mount"
- "turret"
- "arm"
- "elevat"

## Finding the Launcher Node Name

### Method 1: Run the Test Script
1. Open Godot
2. Create a new scene with a Node as root
3. Attach the script `test_himars_structure.gd` to it
4. Run the scene (F6)
5. Check the Output console for the model structure

### Method 2: Import and Inspect
1. In Godot, open `res://assets/models/HIMARS/Himars.glb`
2. Look at the Scene tree in the inspector
3. Find the node that represents the rocket pod/launcher
4. Note its exact name

### Method 3: Check Sketchfab Naming
If the model came from Sketchfab, the launcher might be named based on the original model's naming convention. Common names include:
- `M142_Pod`
- `RocketLauncher`
- `LauncherPod`
- `MissilePod`
- `TubeLauncher`

## Manual Configuration (If Auto-Detection Fails)

If the automatic detection doesn't find the launcher node, you can manually specify it:

### Option 1: Rename the Node in the GLB
1. In Godot, right-click `Himars.glb` > "New Inherited"
2. Find the launcher mesh node
3. Rename it to include one of the keywords (e.g., "launcher")
4. Save as a new scene

### Option 2: Hardcode the Node Path
Edit `unit.gd` and modify `_find_himars_launcher_node`:

```gdscript
func _find_himars_launcher_node(node: Node) -> Node3D:
	# Manual override - replace "YourNodeName" with actual node name
	if node.name == "YourNodeName":
		return node as Node3D

	# Keep the automatic search as fallback
	var name_lower := node.name.to_lower()
	# ... rest of function
```

### Option 3: Use Node Path from Root
If you know the exact path, you can modify `_update_himars_launcher_angle`:

```gdscript
func _update_himars_launcher_angle(delta: float) -> void:
	if _himars_launcher_node == null and _visual_node != null:
		# Manual path - adjust to your model's structure
		_himars_launcher_node = _visual_node.get_node_or_null("HimarsModel/YourLauncherNodeName")
		if _himars_launcher_node != null:
			print("[HIMARS] Found launcher node: ", _himars_launcher_node.name)
			_himars_current_angle = himars_launcher_travel_angle
			_apply_launcher_rotation()
	# ... rest of function
```

## Adjusting Angles and Timing

All deployment parameters are exposed as exports in `unit.gd`:

```gdscript
@export var himars_deploy_time := 3.0  # Seconds to raise/lower
@export var himars_launcher_travel_angle := -15.0  # Degrees when traveling
@export var himars_launcher_fire_angle := 45.0  # Degrees when firing
```

You can adjust these values:
- In the Godot Inspector when selecting a HIMARS unit
- In `GameBalance.gd` as constants
- In the unit spawn code in `game_controller.gd`

## Troubleshooting

### Launcher Not Moving
**Check Console Output**: Look for these messages:
- `[HIMARS] Found launcher node: [name]` - Detection succeeded
- `[HIMARS] Starting deployment` - Animation starting
- `[HIMARS] Deployment complete` - Animation finished

**If No Messages Appear**:
1. The launcher node wasn't found
2. Run `test_himars_structure.gd` to see the model structure
3. Use manual configuration methods above

### Launcher Rotating Wrong Axis
The code rotates on the X axis (pitch). If your model needs a different axis:

Edit `_apply_launcher_rotation()`:
```gdscript
func _apply_launcher_rotation() -> void:
	if _himars_launcher_node == null:
		return
	# Change .x to .y (yaw) or .z (roll) as needed
	_himars_launcher_node.rotation_degrees.y = _himars_current_angle  # For yaw
```

### Launcher Angle Backwards
If the launcher goes down when it should go up:
- Reverse the angles in the export variables
- Or multiply `_himars_current_angle` by -1 in `_apply_launcher_rotation()`

## Testing the System

1. **Spawn a HIMARS**: Queue one from a factory
2. **Watch It Deploy**: It should auto-deploy when it has enemies in range
3. **Command Movement**: Right-click to move - launcher should lower
4. **Check Console**: Look for deployment messages
5. **Set Bombardment Area**: Use the bombardment button - launcher should raise

## Animation Detection (Already Implemented!)

**Good News**: The animated model support is already implemented! The system now:

1. **Automatically detects AnimationPlayer** in your HIMARS model
2. **Searches for animations** with keywords like "deploy", "raise", "up", "fire", "stow", "lower", "down"
3. **Plays animations** when deploying/stowing
4. **Falls back to manual rotation** if no AnimationPlayer is found

The code will print to console:
```
[HIMARS] Found AnimationPlayer with animations: [list of animation names]
[HIMARS] Playing deploy animation: AnimationName
```

If you see these messages, the animations are working! If you see:
```
[HIMARS] No AnimationPlayer found, using manual rotation
```

Then the system will use the manual rotation fallback (still works fine, just won't use the model's animations).

## Summary

The system is designed to work automatically if your model has a clearly-named launcher node. If it doesn't work out of the box, use the test script to inspect the model structure and apply one of the manual configuration methods above.
