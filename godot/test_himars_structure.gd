extends Node

# Temporary script to inspect HIMARS model structure
# Run this in Godot editor to see the node hierarchy

func _ready() -> void:
	# Test the new animated model
	var scene = load("res://assets/models/HIMARS/m142_himars__free_model__animation.glb")
	if scene is PackedScene:
		var instance = scene.instantiate()
		add_child(instance)
		print("\n=== ANIMATED HIMARS Model Structure ===")
		_print_tree(instance, 0)
		print("\n=== Checking for AnimationPlayer ===")
		_find_animation_players(instance)
		print("\n=== Looking for movable parts ===")
		_find_potential_launcher_nodes(instance)
		instance.queue_free()

	# Also check the old model for comparison
	print("\n\n========================================")
	print("=== OLD HIMARS Model (for comparison) ===")
	var old_scene = load("res://assets/models/HIMARS/Himars.glb")
	if old_scene is PackedScene:
		var old_instance = old_scene.instantiate()
		add_child(old_instance)
		print("\n=== Old Model Structure ===")
		_print_tree(old_instance, 0)
		old_instance.queue_free()

func _print_tree(node: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth):
		indent += "  "
	var node_info = "%s%s (%s)" % [indent, node.name, node.get_class()]

	# Add extra info for specific node types
	if node is Node3D:
		var node3d = node as Node3D
		node_info += " | Pos: %s | Rot: %s" % [node3d.position, node3d.rotation_degrees]
	if node is MeshInstance3D:
		node_info += " | [MESH]"
	if node is Skeleton3D:
		node_info += " | [SKELETON]"

	print(node_info)

	for child in node.get_children():
		_print_tree(child, depth + 1)

func _find_animation_players(node: Node) -> void:
	if node is AnimationPlayer:
		var anim_player = node as AnimationPlayer
		print("Found AnimationPlayer: %s" % node.name)
		var anim_list = anim_player.get_animation_list()
		for anim_name in anim_list:
			print("  - Animation: %s" % anim_name)

	for child in node.get_children():
		_find_animation_players(child)

func _find_potential_launcher_nodes(node: Node) -> void:
	var name_lower = node.name.to_lower()
	var keywords = ["launcher", "pod", "rocket", "missile", "tube", "arm", "turret", "mount"]

	for keyword in keywords:
		if keyword in name_lower:
			print("Potential launcher part found: %s (%s)" % [node.name, node.get_class()])
			if node is Node3D:
				var node3d = node as Node3D
				print("  Position: %s | Rotation: %s" % [node3d.position, node3d.rotation_degrees])
			break

	for child in node.get_children():
		_find_potential_launcher_nodes(child)
