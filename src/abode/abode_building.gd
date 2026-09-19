extends Node2D
## Independent map prop: world anchor, selection area and sprite are separate.
var building_id: String
var title: String
var level: int = 1
var selected: bool = false
var running: bool = true
var reduced_motion: bool = false
var sprite: Sprite2D
var caption: Label
var body_size: Vector2
var clock_time: float = 0.0
var upgrade_flash: float = 0.0
var base_scale: Vector2

func setup(id: String, display_name: String, art: Texture2D, width: float, font: Font) -> void:
	building_id = id
	title = display_name
	name = display_name
	body_size = Vector2(width, width)
	sprite = Sprite2D.new()
	sprite.texture = art
	sprite.scale = Vector2.ONE * width / float(art.get_width())
	base_scale = sprite.scale
	sprite.position = Vector2(0, -width * 0.42)
	add_child(sprite)
	caption = Label.new()
	caption.position = Vector2(-145, 14)
	caption.size = Vector2(290, 48)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font", font)
	caption.add_theme_font_size_override("font_size", 28)
	caption.add_theme_color_override("font_color", Color("f6e6b9"))
	caption.add_theme_color_override("font_outline_color", Color("07161c"))
	caption.add_theme_constant_override("outline_size", 2)
	var caption_style := StyleBoxFlat.new()
	caption_style.bg_color = Color(0.008, 0.045, 0.065, 0.86)
	caption_style.border_color = Color(0.80, 0.73, 0.50, 0.66)
	caption_style.set_border_width_all(1)
	caption_style.set_corner_radius_all(8)
	caption_style.content_margin_left = 8
	caption_style.content_margin_right = 8
	caption_style.content_margin_top = 3
	caption_style.content_margin_bottom = 3
	caption.add_theme_stylebox_override("normal", caption_style)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)

func contains_point(world_point: Vector2) -> bool:
	if not visible:
		return false
	return Rect2(Vector2(-body_size.x * 0.45, -body_size.y * 0.82), Vector2(body_size.x * 0.9, body_size.y * 0.86)).has_point(to_local(world_point))

func pulse_upgrade() -> void:
	upgrade_flash = 1.0

func _process(delta: float) -> void:
	clock_time += delta
	upgrade_flash = maxf(0, upgrade_flash - delta * 0.8)
	var status_text := ""
	if level == 0:
		status_text = "未建造"
	else:
		status_text = "%d階%s" % [level, "" if running else " · 停駐"]
	caption.text = "%s · %s" % [title, status_text]
	var pulse: float = 0.0 if reduced_motion else sin(clock_time * 1.6) * 0.018
	if (building_id == "garden" or building_id == "herb_farm") and running and level > 0:
		sprite.scale = base_scale * Vector2(1.0 + pulse * 0.3, 1.0 + pulse)
	var base_alpha: float = 1.0 if level > 0 else 0.72
	var flash_color: Color = Color(1.0 + upgrade_flash * 0.45, 1.0 + upgrade_flash * 0.3, 1.0 + upgrade_flash * 0.1, base_alpha)
	sprite.modulate = flash_color if running else Color(0.65, 0.72, 0.73, base_alpha)
	queue_redraw()

func _draw() -> void:
	var tint: Color = Color("bbf8d7") if running else Color("95a6a6")
	if selected or upgrade_flash > 0.0:
		draw_set_transform(Vector2(0, -12), 0, Vector2(1, 0.4))
		draw_arc(Vector2.ZERO, body_size.x * 0.5 + 9 + upgrade_flash * 30, 0, TAU, 80, Color(tint, 0.75), 3.0, true)
		draw_arc(Vector2.ZERO, body_size.x * 0.5 + 16, 0, TAU, 80, Color(tint, 0.2), 8.0, true)
		draw_set_transform(Vector2.ZERO)
	if building_id == "altar":
		var alpha: float = 0.4 if reduced_motion else 0.35 + sin(clock_time * 1.5) * 0.15
		draw_set_transform(Vector2(0, -body_size.y * 0.44), clock_time * 0.08 if not reduced_motion else 0, Vector2(1, 0.42))
		draw_arc(Vector2.ZERO, body_size.x * 0.28, 0, TAU, 80, Color("d9e9ba", alpha), 2.0 + level, true)
		draw_set_transform(Vector2.ZERO)
