class_name RadarStation
extends DefenseTurret

## Radar Station
##
## Provides directional detection for aircraft and missiles without firing.

@export var protection_arc_half_angle := deg_to_rad(30.0)  # 60 degree arc total
@export var detection_hold_time := 5.0
@export var support_radius := 600.0

var protection_configured := false
var protection_direction := Vector2.RIGHT

func _ready() -> void:
	super._ready()
	add_to_group("radar_station")
	add_to_group("radar_station_%s" % team_id)

func update_targeting(_delta: float) -> void:
	# Radar does not attack; keep orientation aligned with detection arc.
	if protection_configured:
		_facing = protection_direction
		_sync_visual_rotation()
		_detect_targets()
	queue_redraw()

func _detect_targets() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for node in tree.get_nodes_in_group("units"):
		if node is not Unit:
			continue
		var unit := node as Unit
		if unit.team_id == team_id:
			continue
		if unit.unit_kind != "aircraft":
			continue
		if not is_in_protection_area(unit.global_position):
			continue
		unit.radar_detected_timer = maxf(unit.radar_detected_timer, detection_hold_time)

	for node in tree.get_nodes_in_group("missiles"):
		if node is not Missile:
			continue
		var missile := node as Missile
		if missile.team_id == team_id:
			continue
		if not is_in_protection_area(missile.global_position):
			continue
		missile.radar_detected_timer = maxf(missile.radar_detected_timer, detection_hold_time)

func set_protection_area(direction_angle: float, arc_half_angle: float) -> void:
	protection_direction = Vector2.from_angle(direction_angle)
	protection_arc_half_angle = arc_half_angle
	protection_configured = true
	_facing = protection_direction
	_sync_visual_rotation()
	print("[RADAR] Detection area configured: direction=", protection_direction,
		" arc=", rad_to_deg(arc_half_angle * 2), " degrees")

func is_in_protection_area(pos: Vector2) -> bool:
	if not protection_configured:
		return false

	var to_pos := pos - global_position
	var dist := to_pos.length()
	if dist > attack_range:
		return false
	if dist <= 0.01:
		return true

	var pos_angle := to_pos.angle()
	var dir_angle := protection_direction.angle()
	var angle_diff := absf(angle_difference(dir_angle, pos_angle))
	return angle_diff <= protection_arc_half_angle

func detects_node(node: Node2D) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	return is_in_protection_area(node.global_position)
