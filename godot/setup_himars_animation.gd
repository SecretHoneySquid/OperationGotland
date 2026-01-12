extends EditorScript

## HIMARS Launcher Animation Setup Script
## This script sets up the proper pivot point and AnimationPlayer for the HIMARS launcher
## Run this once in Godot Editor: File > Run

const MODEL_PATH = "res://assets/models/HIMARS/m142_himars__free_model__animation.glb"
const OUTPUT_PATH = "res://scenes/units/himars_visual_animated.tscn"

const LAUNCHER_ELEVATION_ANGLE = -50.0  # Degrees (negative = up in HIMARS orientation)
const ANIMATION_DURATION = 1.2  # Seconds

func _run() -> void:
	print("\n=== HIMARS Animation Setup ===\n")

	# Load the original GLB
	var scene = load(MODEL_PATH) as PackedScene
	if scene == null:
		print("ERROR: Could not load model at %s" % MODEL_PATH)
		return

	var instance = scene.instantiate()
	print("✓ Loaded GLB model")

	# Analyze structure
	print("\n--- Current Structure ---")
	_print_tree(instance, 0)

	# Find the launcher mesh
	var launcher_mesh = _find_launcher_mesh(instance)
	if launcher_mesh == null:
		print("\nERROR: Could not find launcher mesh")
		instance.queue_free()
		return

	print("\n✓ Found launcher mesh: %s" % launcher_mesh.name)
	print("  Current parent: %s" % launcher_mesh.get_parent().name)
	print("  Position: %s" % launcher_mesh.position)
	print("  Rotation: %s" % launcher_mesh.rotation_degrees)

	# Create pivot node
	var pivot = Node3D.new()
	pivot.name = "LauncherPivot"

	# Calculate pivot position (rear bottom hinge of launcher)
	var launcher_parent = launcher_mesh.get_parent()
	launcher_parent.add_child(pivot)
	pivot.owner = instance

	# Position pivot at hinge point
	# HIMARS launcher hinges at the rear bottom
	pivot.position = launcher_mesh.position

	# Reparent launcher under pivot
	var original_transform = launcher_mesh.global_transform
	launcher_mesh.reparent(pivot)
	launcher_mesh.global_transform = original_transform
	launcher_mesh.position = Vector3.ZERO  # Reset to pivot center

	print("\n✓ Created LauncherPivot node")
	print("  Pivot position: %s" % pivot.position)

	# Find or create AnimationPlayer
	var anim_player = _find_animation_player(instance)
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		instance.add_child(anim_player)
		anim_player.owner = instance
		print("\n✓ Created new AnimationPlayer")
	else:
		print("\n✓ Found existing AnimationPlayer: %s" % anim_player.name)

	# Create animations
	_create_launcher_animations(anim_player, pivot)

	# Show final structure
	print("\n--- Final Structure ---")
	_print_tree(instance, 0)

	# Show created animations
	print("\n--- Created Animations ---")
	var anims = anim_player.get_animation_list()
	for anim_name in anims:
		var anim = anim_player.get_animation(anim_name)
		print("  • %s (%.2fs)" % [anim_name, anim.length])

	# Save as new scene
	var packed = PackedScene.new()
	packed.pack(instance)
	var err = ResourceSaver.save(packed, OUTPUT_PATH)

	if err == OK:
		print("\n✓ SUCCESS: Saved to %s" % OUTPUT_PATH)
		print("\nYou can now use this scene with:")
		print('  $AnimationPlayer.play("launcher_raise")')
		print('  $AnimationPlayer.play("launcher_lower")')
	else:
		print("\n✗ ERROR: Failed to save scene (error code: %d)" % err)

	instance.queue_free()
	print("\n=== Setup Complete ===\n")

func _create_launcher_animations(anim_player: AnimationPlayer, pivot: Node3D) -> void:
	"""Create all launcher animations"""

	# Get path to pivot relative to AnimationPlayer
	var pivot_path = anim_player.get_path_to(pivot)

	# Animation 1: launcher_lowered (0°)
	var anim_lowered = Animation.new()
	anim_lowered.length = 0.1
	var track_idx = anim_lowered.add_track(Animation.TYPE_ROTATION_3D)
	anim_lowered.track_set_path(track_idx, pivot_path)
	anim_lowered.track_insert_key(track_idx, 0.0, Quaternion.from_euler(Vector3.ZERO))
	anim_player.add_animation_library("", anim_player.get_animation_library(""))
	if anim_player.has_animation("launcher_lowered"):
		anim_player.remove_animation("launcher_lowered")
	anim_player.add_animation("launcher_lowered", anim_lowered)

	# Animation 2: launcher_raised (elevated)
	var anim_raised = Animation.new()
	anim_raised.length = 0.1
	track_idx = anim_raised.add_track(Animation.TYPE_ROTATION_3D)
	anim_raised.track_set_path(track_idx, pivot_path)
	var raised_rot = Vector3(deg_to_rad(LAUNCHER_ELEVATION_ANGLE), 0, 0)
	anim_raised.track_insert_key(track_idx, 0.0, Quaternion.from_euler(raised_rot))
	if anim_player.has_animation("launcher_raised"):
		anim_player.remove_animation("launcher_raised")
	anim_player.add_animation("launcher_raised", anim_raised)

	# Animation 3: launcher_raise (lowered → raised transition)
	var anim_raise = Animation.new()
	anim_raise.length = ANIMATION_DURATION
	track_idx = anim_raise.add_track(Animation.TYPE_ROTATION_3D)
	anim_raise.track_set_path(track_idx, pivot_path)
	anim_raise.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)
	anim_raise.track_insert_key(track_idx, 0.0, Quaternion.from_euler(Vector3.ZERO))
	anim_raise.track_insert_key(track_idx, ANIMATION_DURATION, Quaternion.from_euler(raised_rot))
	if anim_player.has_animation("launcher_raise"):
		anim_player.remove_animation("launcher_raise")
	anim_player.add_animation("launcher_raise", anim_raise)

	# Animation 4: launcher_lower (raised → lowered transition)
	var anim_lower = Animation.new()
	anim_lower.length = ANIMATION_DURATION
	track_idx = anim_lower.add_track(Animation.TYPE_ROTATION_3D)
	anim_lower.track_set_path(track_idx, pivot_path)
	anim_lower.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)
	anim_lower.track_insert_key(track_idx, 0.0, Quaternion.from_euler(raised_rot))
	anim_lower.track_insert_key(track_idx, ANIMATION_DURATION, Quaternion.from_euler(Vector3.ZERO))
	if anim_player.has_animation("launcher_lower"):
		anim_player.remove_animation("launcher_lower")
	anim_player.add_animation("launcher_lower", anim_lower)

	print("\n✓ Created 4 launcher animations:")
	print("  • launcher_lowered (static)")
	print("  • launcher_raised (static)")
	print("  • launcher_raise (%.1fs transition)" % ANIMATION_DURATION)
	print("  • launcher_lower (%.1fs transition)" % ANIMATION_DURATION)

func _find_launcher_mesh(node: Node) -> Node3D:
	"""Find the launcher mesh node"""
	var keywords = ["launcher", "pod", "rocket", "tube", "mount", "mlrs"]
	var name_lower = node.name.to_lower()

	# Check current node
	for keyword in keywords:
		if keyword in name_lower and (node is MeshInstance3D or node is Node3D):
			return node as Node3D

	# Check children
	for child in node.get_children():
		var found = _find_launcher_mesh(child)
		if found != null:
			return found

	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Find AnimationPlayer in scene tree"""
	if node is AnimationPlayer:
		return node as AnimationPlayer

	for child in node.get_children():
		var found = _find_animation_player(child)
		if found != null:
			return found

	return null

func _print_tree(node: Node, depth: int) -> void:
	"""Print node hierarchy"""
	var indent = "  ".repeat(depth)
	var info = "%s├─ %s (%s)" % [indent, node.name, node.get_class()]

	if node is Node3D:
		var n3d = node as Node3D
		info += " @ %s" % n3d.position

	if node is AnimationPlayer:
		info += " [ANIM]"
	elif node is MeshInstance3D:
		info += " [MESH]"

	print(info)

	for child in node.get_children():
		_print_tree(child, depth + 1)
