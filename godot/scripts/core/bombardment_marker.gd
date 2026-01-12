class_name BombardmentMarker
extends Node2D

## Visual marker showing where HIMARS is targeting

@export var marker_color := Color(1.0, 0.3, 0.1, 0.7)
@export var marker_outline := Color(1.0, 0.5, 0.2, 1.0)
@export var marker_radius := 25.0
@export var pulse_speed := 2.0
@export var pulse_min_scale := 0.9
@export var pulse_max_scale := 1.1
@export var render_2d := true

var _pulse_timer := 0.0
var target_unit: Unit = null  # The HIMARS that owns this marker

func _ready() -> void:
	add_to_group("bombardment_markers")
	z_index = -1  # Draw under units

func _process(delta: float) -> void:
	# Remove marker if the owning HIMARS is destroyed or stops targeting
	if target_unit == null or not is_instance_valid(target_unit):
		queue_free()
		return

	if not target_unit.is_area_bombardment_active():
		queue_free()
		return

	# Pulse animation
	_pulse_timer += delta * pulse_speed
	queue_redraw()

func _draw() -> void:
	if not render_2d:
		return

	# Calculate pulse scale
	var pulse := sin(_pulse_timer * TAU)
	var scale := lerpf(pulse_min_scale, pulse_max_scale, (pulse + 1.0) * 0.5)
	var radius := marker_radius * scale

	# Draw outer ring (pulsing)
	var outer_alpha := marker_color.a * (0.5 + pulse * 0.2)
	var outer_color := Color(marker_color.r, marker_color.g, marker_color.b, outer_alpha)
	draw_circle(Vector2.ZERO, radius, outer_color, true)

	# Draw inner circle (solid)
	var inner_radius := radius * 0.7
	draw_circle(Vector2.ZERO, inner_radius, marker_color, true)

	# Draw outline
	draw_circle(Vector2.ZERO, radius, marker_outline, false, 3.0)

	# Draw crosshair
	var cross_size := radius * 0.8
	var cross_width := 3.0
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), marker_outline, cross_width)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), marker_outline, cross_width)

	# Draw corner brackets
	var bracket_size := radius * 0.4
	var bracket_offset := radius * 0.85
	for angle in [0, PI/2, PI, PI * 3/2]:
		var dir := Vector2.from_angle(angle)
		var corner := dir * bracket_offset
		var h_start := corner - Vector2(bracket_size if abs(dir.x) < 0.5 else 0, 0)
		var h_end := corner + Vector2(bracket_size if abs(dir.x) < 0.5 else 0, 0)
		var v_start := corner - Vector2(0, bracket_size if abs(dir.y) < 0.5 else 0)
		var v_end := corner + Vector2(0, bracket_size if abs(dir.y) < 0.5 else 0)
		draw_line(h_start, h_end, marker_outline, 2.5)
		draw_line(v_start, v_end, marker_outline, 2.5)

func set_render_2d(value: bool) -> void:
	render_2d = value
	queue_redraw()
