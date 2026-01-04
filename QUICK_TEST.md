# Quick Test - Force Build Mode with Keyboard

Since the ghost isn't appearing, let's test if the system works by forcing build mode with a keyboard shortcut.

## Add Test Code

1. Open `godot/scripts/core/build_controller.gd`

2. Find the `_process()` function (around line 173)

3. Add this code RIGHT AT THE START of `_process()`:

```gdscript
func _process(_delta: float) -> void:
	# TEST: Press B key to force build mode
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_B):
		if _active_build_id == "":
			start_placement("barracks")
			print("BUILD MODE ACTIVATED - Barracks")
	
	# TEST: Press ESC to cancel
	if Input.is_key_pressed(KEY_ESCAPE):
		if _active_build_id != "":
			cancel_placement()
			print("BUILD MODE CANCELLED")
	
	# Original code continues...
	if _active_build_id == "":
		return
	# ... rest of function
```

## Test Steps

1. Run the game
2. Press **B** key
3. Console should print "BUILD MODE ACTIVATED - Barracks"
4. Move mouse - ghost should appear
5. Press **ESC** to cancel

## What This Tests

- If ghost appears when you press B → BuildController works, UI doesn't
- If ghost still doesn't appear → VisualSync or WorldInput issue

## Expected Result

When you press B and move mouse:
- Green/red 3D box should appear
- Box follows mouse cursor
- Console prints debug message

---

Try this and let me know what happens!
