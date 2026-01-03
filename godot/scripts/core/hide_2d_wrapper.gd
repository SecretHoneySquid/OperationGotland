extends Node3D

func _ready() -> void:
	var parent = get_parent()
	if parent == null:
		parent = get_tree().get_root()
	var logic: Node = null
	if parent.has_node("Logic2D"):
		logic = parent.get_node("Logic2D")
	if logic == null:
		# try alternative lookup
		logic = get_node_or_null("../Logic2D")
	if logic == null:
		return
	var maproot: Node = null
	if logic.has_node("MapRoot"):
		maproot = logic.get_node("MapRoot")
	if maproot == null:
		return
	# Fully disable the 2D map root to avoid any drawing or processing from it
	maproot.visible = false
	maproot.set_process(false)
	maproot.set_physics_process(false)
	maproot.set_process_unhandled_input(false)
	maproot.set_process_input(false)
	# If MapLoader API is present, ask it to disable 2D rendering too
	if maproot.has_method("set_render_2d"):
		maproot.set_render_2d(false)
	# Also try to find the MapLoader child/script and disable on it directly
	for child in maproot.get_children():
		if child == null:
			continue
		if child.has_method("set_render_2d"):
			child.set_render_2d(false)
