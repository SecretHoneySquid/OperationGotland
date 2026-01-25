class_name HQ
extends Node2D

@export var team_id := "p1"
@export var build_id := "hq"
@export var size := Vector2(140, 140):
	set(value):
		size = value
		_update_visual_transform()
		queue_redraw()

@export var fill_color := Color(0.25, 0.25, 0.25, 1.0):
	set(value):
		fill_color = value
		_update_visual_color()
		queue_redraw()

@export var outline_color := Color(0.95, 0.95, 0.95, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

@export var outline_width := 2.0:
	set(value):
		outline_width = value
		queue_redraw()

@export var max_hp := 500.0
@export var show_health := true
@export var health_bar_height := 8.0
@export var health_bar_offset := 12.0
@export var vision_radius := 280.0
@export var visual_scene_path := ""
@export var visual_base_size := Vector2.ZERO
@export var visual_offset := Vector2.ZERO

var hp := 0.0
var _visual_node: Node2D

# Spy satellite cooldown
var _spy_satellite_cooldown := 0.0
var _spy_satellite_ready := true

func _ready() -> void:
	hp = max_hp
	add_to_group("hq")
	add_to_group("hq_%s" % team_id)
	add_to_group("building")  # Make HQ selectable like other buildings
	if team_id == "p1" and vision_radius > 0.0:
		add_to_group("vision_p1")
		var light := VisionHelper.create_light(vision_radius)
		add_child(light)
	_setup_visual()

func _process(delta: float) -> void:
	if not _spy_satellite_ready:
		_spy_satellite_cooldown -= delta
		if _spy_satellite_cooldown <= 0.0:
			_spy_satellite_cooldown = 0.0
			_spy_satellite_ready = true

func take_damage(amount: float, attacker_type: String = "") -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	queue_redraw()
	if hp <= 0.0:
		queue_free()

func get_vision_radius() -> float:
	return vision_radius

func _setup_visual() -> void:
	if visual_scene_path == "":
		return
	var packed := load(visual_scene_path)
	if packed == null:
		push_warning("HQ: missing visual scene at %s" % visual_scene_path)
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
		push_warning("HQ: visual scene is not a PackedScene at %s" % visual_scene_path)

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

# Spy Satellite ability
func is_spy_satellite_ready() -> bool:
	return _spy_satellite_ready

func start_spy_satellite_cooldown() -> void:
	_spy_satellite_ready = false
	_spy_satellite_cooldown = GameBalance.SPY_SATELLITE_COOLDOWN

func get_cooldown_remaining() -> float:
	return _spy_satellite_cooldown
