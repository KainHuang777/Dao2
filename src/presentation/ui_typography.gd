class_name UiTypography
extends RefCounted
## Shared Godot font roles for readable Traditional Chinese UI.

const BASE_FONT: FontFile = preload("res://assets/fonts/NotoSerifTC-VF.ttf")

static var _body: FontVariation
static var _emphasis: FontVariation

static func body_font() -> Font:
	if _body == null:
		_body = _weighted_font(600)
	return _body

static func emphasis_font() -> Font:
	if _emphasis == null:
		_emphasis = _weighted_font(700)
	return _emphasis

static func create_theme() -> Theme:
	var result := Theme.new()
	result.default_font = body_font()
	result.default_font_size = 18
	return result

static func dialog_surface() -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = Color(0.008, 0.035, 0.05, 0.98)
	result.border_color = Color(0.82, 0.73, 0.49, 0.9)
	result.set_border_width_all(2)
	result.set_corner_radius_all(8)
	return result

static func _weighted_font(weight: int) -> FontVariation:
	var result := FontVariation.new()
	result.base_font = BASE_FONT
	result.variation_opentype = {"wght": weight}
	return result
