class_name SpySatelliteVision
extends Node2D

## Spy Satellite Vision Source
## Temporary vision source that auto-destroys after duration expires
## Features expanding deployment animation and blue intelligence edge effect

@export var vision_radius := 400.0
@export var duration := 30.0
@export var light_energy := 1.5
@export var light_color := Color(0.6, 0.8, 1.0, 1.0)  # Slightly blue tint for satellite

# Expansion animation
@export var expand_duration := 0.5  # Time to expand from center
@export var edge_color := Color(0.3, 0.6, 1.0, 0.8)  # Blue intelligence edge
@export var edge_width := 8.0
@export var edge_glow_color := Color(0.2, 0.5, 1.0, 0.4)  # Outer glow
@export var edge_glow_width := 16.0
@export var render_2d := true

var _light: PointLight2D
var _time_remaining := 0.0
var _initial_energy := 1.5
var _expand_progress := 0.0  # 0 to 1
var _current_visual_radius := 0.0
var _is_expanding := true

func _ready() -> void:
	_time_remaining = duration
	_initial_energy = light_energy
	_expand_progress = 0.0
	_current_visual_radius = 0.0
	_is_expanding = true
	z_index = 10  # Draw above terrain
	if vision_radius <= 0.0:
		queue_free()
		return
	add_to_group("vision_p1")
	add_to_group("spy_satellite_vision")  # For 3D visual sync
	# Create light but start with 0 scale - we'll animate it
	_light = VisionHelper.create_light(vision_radius)
	_light.energy = light_energy
	_light.color = light_color
	_light.scale = Vector2.ZERO
	add_child(_light)

func _process(delta: float) -> void:
	# Handle expansion animation
	if _is_expanding:
		_expand_progress += delta / expand_duration
		if _expand_progress >= 1.0:
			_expand_progress = 1.0
			_is_expanding = false
			_current_visual_radius = vision_radius
		else:
			# Ease out for smooth deceleration
			var eased := _ease_out_cubic(_expand_progress)
			_current_visual_radius = vision_radius * eased
		if _light != null:
			_light.scale = Vector2.ONE * (_current_visual_radius / vision_radius)
		queue_redraw()
		return

	_time_remaining -= delta
	if _time_remaining <= 0.0:
		queue_free()
		return

	# Fade out light energy in last 5 seconds
	var fade_start := 5.0
	if _time_remaining < fade_start:
		var fade_factor := _time_remaining / fade_start
		if _light != null:
			_light.energy = _initial_energy * fade_factor

	# Always redraw to keep edge effects visible
	queue_redraw()

func _draw() -> void:
	if not render_2d:
		return
	if _current_visual_radius <= 0.0:
		return

	# Calculate fade factor for last 5 seconds
	var fade_factor := 1.0
	if not _is_expanding and _time_remaining < 5.0:
		fade_factor = _time_remaining / 5.0

	# Draw outer glow ring (wider, more transparent)
	var glow_alpha := edge_glow_color.a * fade_factor
	var glow_col := Color(edge_glow_color.r, edge_glow_color.g, edge_glow_color.b, glow_alpha)
	draw_arc(Vector2.ZERO, _current_visual_radius + edge_glow_width * 0.5, 0, TAU, 64, glow_col, edge_glow_width, true)

	# Draw main edge ring
	var edge_alpha := edge_color.a * fade_factor
	var edge_col := Color(edge_color.r, edge_color.g, edge_color.b, edge_alpha)
	draw_arc(Vector2.ZERO, _current_visual_radius, 0, TAU, 64, edge_col, edge_width, true)

	# Draw inner subtle fill for intelligence look
	var fill_alpha := 0.08 * fade_factor
	if _is_expanding:
		fill_alpha = 0.15 * (1.0 - _expand_progress)  # Brighter during expansion
	var fill_col := Color(0.3, 0.6, 1.0, fill_alpha)
	draw_circle(Vector2.ZERO, _current_visual_radius, fill_col)

func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func get_vision_radius() -> float:
	return vision_radius

func get_time_remaining() -> float:
	return _time_remaining

static func create(pos: Vector2, radius: float = 400.0, dur: float = 30.0) -> SpySatelliteVision:
	var vision := SpySatelliteVision.new()
	vision.vision_radius = radius
	vision.duration = dur
	vision.position = pos
	return vision
