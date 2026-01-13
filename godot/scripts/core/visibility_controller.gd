class_name VisibilityController
extends Node

## Visibility Controller
##
## Handles fog of war and unit visibility.
## Extracted from game_controller.gd for better organization.

@export var fog_enabled := true
@export var fog_hide_enemies := true
@export var base_vision_enabled := true
@export var base_vision_padding := 40.0
@export var base_vision_energy := 2.2

var _p1_build_zone := Rect2()
var _base_vision: BaseVision
var _teams: Dictionary  # team_id -> TeamState

func configure(teams: Dictionary) -> void:
	_teams = teams

func set_build_zone(team_id: String, zone: Rect2) -> void:
	if team_id == "p1":
		_p1_build_zone = zone

func setup_base_vision(parent: Node) -> void:
	if not base_vision_enabled:
		return
	if _p1_build_zone == Rect2():
		return

	var center := _p1_build_zone.position + (_p1_build_zone.size * 0.5)
	var radius := (_p1_build_zone.size.length() * 0.5) + base_vision_padding

	if _base_vision != null and is_instance_valid(_base_vision):
		_base_vision.queue_free()

	_base_vision = BaseVision.new()
	_base_vision.vision_radius = radius
	_base_vision.light_energy = base_vision_energy
	_base_vision.position = center
	parent.add_child(_base_vision)

# =============================================================================
# VISIBILITY UPDATE
# =============================================================================

func update() -> void:
	if not fog_enabled or not fog_hide_enemies:
		_set_enemy_visibility(true)
		return

	var sources := _get_vision_sources()
	_apply_visibility_to_group("units_p2", sources)
	_apply_visibility_to_group("collectors_p2", sources)
	_apply_visibility_to_group("defense_turret_p2", sources)
	_apply_visibility_to_buildings("p2", sources)
	_apply_visibility_to_hq("p2", sources)

func _get_vision_sources() -> Array:
	var sources: Array = []
	for node in get_tree().get_nodes_in_group("vision_p1"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_vision_radius"):
			continue
		var radius := float(node.get_vision_radius())
		if radius <= 0.0:
			continue
		sources.append({
			"pos": node.global_position,
			"radius_sq": radius * radius,
		})
	return sources

func _apply_visibility_to_group(group_name: String, sources: Array) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node == null or not is_instance_valid(node):
			continue
		node.visible = _is_in_vision(node.global_position, sources)

func _apply_visibility_to_buildings(team_id: String, sources: Array) -> void:
	for node in get_tree().get_nodes_in_group("building"):
		if not (node is Building):
			continue
		if node.team_id != team_id:
			continue
		node.visible = _is_in_vision(node.global_position, sources)

func _apply_visibility_to_hq(team_id: String, sources: Array) -> void:
	for node in get_tree().get_nodes_in_group("hq"):
		if not (node is HQ):
			continue
		if node.team_id != team_id:
			continue
		node.visible = _is_in_vision(node.global_position, sources)

func _is_in_vision(pos: Vector2, sources: Array) -> bool:
	# Always visible within player 1's build zone
	if _p1_build_zone != Rect2():
		var base_rect := _p1_build_zone.grow(base_vision_padding)
		if base_rect.has_point(pos):
			return true

	if sources.is_empty():
		return false

	for source in sources:
		var src_pos := source.get("pos", Vector2.ZERO) as Vector2
		var radius_sq := float(source.get("radius_sq", 0.0))
		if pos.distance_squared_to(src_pos) <= radius_sq:
			return true

	return false

func _set_enemy_visibility(is_visible: bool) -> void:
	for node in get_tree().get_nodes_in_group("units_p2"):
		if node != null and is_instance_valid(node):
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("collectors_p2"):
		if node != null and is_instance_valid(node):
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("defense_turret_p2"):
		if node != null and is_instance_valid(node):
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("building"):
		if node is Building and node.team_id == "p2":
			node.visible = is_visible
	for node in get_tree().get_nodes_in_group("hq"):
		if node is HQ and node.team_id == "p2":
			node.visible = is_visible
