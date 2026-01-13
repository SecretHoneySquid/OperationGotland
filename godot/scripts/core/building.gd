class_name Building
extends Node2D

@export var size := Vector2(80, 80):
	set(value):
		size = value
		_update_visual_transform()

@export var fill_color := Color(0.25, 0.25, 0.25, 1.0):
	set(value):
		fill_color = value
		_update_visual_color()

@export var vision_radius := 160.0
@export var max_hp := 200.0
@export var show_health := true
@export var health_bar_height := 6.0
@export var health_bar_offset := 10.0
@export var production_type := "mixed"
@export var wait_mode := false
@export var vehicle_production_type := "mixed"
@export var aircraft_production_type := "fighter"  # "fighter" or "uav"
@export var build_id := "unknown"
@export var team_id := "p1"
@export var visual_scene_path := ""
@export var visual_base_size := Vector2.ZERO
@export var visual_offset := Vector2.ZERO

var hp := 0.0
var _visual_node: Node2D
var _is_selected := false
var _game_controller: Node

func _ready() -> void:
	hp = max_hp
	add_to_group("building")
	add_to_group("building_%s" % build_id)
	add_to_group("building_%s_%s" % [build_id, team_id])
	if team_id == "p1" and vision_radius > 0.0:
		add_to_group("vision_p1")
		var light := VisionHelper.create_light(vision_radius)
		add_child(light)
	_setup_visual()

func _exit_tree() -> void:
	if build_id == "" or build_id == "unknown":
		return
	if team_id == "p1":
		GameState.p1_building_count = maxi(0, GameState.p1_building_count - 1)
		match build_id:
			"barracks":
				GameState.p1_barracks = maxi(0, GameState.p1_barracks - 1)
			"factory":
				GameState.p1_factory = maxi(0, GameState.p1_factory - 1)
			"airfield":
				GameState.p1_airfield = maxi(0, GameState.p1_airfield - 1)
			"supply":
				GameState.p1_supply = maxi(0, GameState.p1_supply - 1)
			"power":
				GameState.p1_power = maxi(0, GameState.p1_power - 1)
			"command_center":
				GameState.p1_command_center = maxi(0, GameState.p1_command_center - 1)
			_:
				if build_id.begins_with("defense"):
					GameState.p1_defense = maxi(0, GameState.p1_defense - 1)
	else:
		GameState.p2_building_count = maxi(0, GameState.p2_building_count - 1)
		match build_id:
			"barracks":
				GameState.p2_barracks = maxi(0, GameState.p2_barracks - 1)
			"factory":
				GameState.p2_factory = maxi(0, GameState.p2_factory - 1)
			"airfield":
				GameState.p2_airfield = maxi(0, GameState.p2_airfield - 1)
			"supply":
				GameState.p2_supply = maxi(0, GameState.p2_supply - 1)
			"power":
				GameState.p2_power = maxi(0, GameState.p2_power - 1)
			"command_center":
				GameState.p2_command_center = maxi(0, GameState.p2_command_center - 1)
			_:
				if build_id.begins_with("defense"):
					GameState.p2_defense = maxi(0, GameState.p2_defense - 1)
	if has_meta("linked_turret"):
		var turret = get_meta("linked_turret")
		if turret is Node and is_instance_valid(turret):
			turret.queue_free()

func take_damage(amount: float, attacker_type: String = "") -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		queue_free()

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("Building: missing visual scene at %s" % visual_scene_path)
		return
	if packed is PackedScene:
		var instance = packed.instantiate()
		if instance is Node2D:
			_visual_node = instance
			add_child(_visual_node)
			_visual_node.visible = false  # 2D visuals are hidden - 3D used instead
			_update_visual_transform()
			_update_visual_color()
	else:
		push_warning("Building: visual scene is not a PackedScene at %s" % visual_scene_path)

func _update_visual_transform() -> void:
	if _visual_node == null:
		return
	_visual_node.position = visual_offset
	if visual_base_size != Vector2.ZERO:
		var scale_x := size.x / visual_base_size.x
		var scale_y := size.y / visual_base_size.y
		_visual_node.scale = Vector2(scale_x, scale_y)

func _update_visual_color() -> void:
	if _visual_node == null:
		return
	_visual_node.modulate = fill_color

func get_vision_radius() -> float:
	return vision_radius

func set_selected(value: bool) -> void:
	_is_selected = value
