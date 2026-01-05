extends Control

## Selection Box Overlay
## Draws the selection box in screen space (UI layer)

var dragging := false
var drag_start := Vector2.ZERO
var drag_end := Vector2.ZERO
var fill_color := Color(0.2, 0.8, 1.0, 0.15)
var outline_color := Color(0.2, 0.8, 1.0, 0.7)
var outline_width := 2.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func start_drag(screen_pos: Vector2) -> void:
	dragging = true
	drag_start = screen_pos
	drag_end = screen_pos
	queue_redraw()

func update_drag(screen_pos: Vector2) -> void:
	if not dragging:
		return
	drag_end = screen_pos
	queue_redraw()

func end_drag() -> void:
	dragging = false
	queue_redraw()

func _draw() -> void:
	if not dragging:
		return
	var rect := Rect2(drag_start, drag_end - drag_start).abs()
	draw_rect(rect, fill_color, true)
	draw_rect(rect, outline_color, false, outline_width)
