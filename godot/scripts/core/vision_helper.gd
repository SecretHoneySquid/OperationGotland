class_name VisionHelper
extends Node

static var _vision_texture: Texture2D

static func create_light(radius: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _get_texture()
	light.color = Color(1.0, 1.0, 1.0, 1.0)
	light.energy = 1.0
	light.shadow_enabled = false
	var texture_size := 128.0
	light.texture_scale = radius / (texture_size * 0.5)
	return light

static func _get_texture() -> Texture2D:
	if _vision_texture != null:
		return _vision_texture
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var max_dist := center.x
	for y in range(size):
		for x in range(size):
			var dx := (x + 0.5) - center.x
			var dy := (y + 0.5) - center.y
			var dist := sqrt(dx * dx + dy * dy)
			var t := clampf(1.0 - (dist / max_dist), 0.0, 1.0)
			var alpha := pow(t, 2.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_vision_texture = ImageTexture.create_from_image(img)
	return _vision_texture
