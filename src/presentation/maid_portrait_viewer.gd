extends PanelContainer
## Hosted by the existing shell tool overlay: shared shield, CloseSeal and Escape.
var image: TextureRect
var title_label: Label
var body_scroll: ScrollContainer
var body: Label
func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	var column := VBoxContainer.new()
	add_child(column)
	title_label = Label.new()
	title_label.text = "完整立繪"
	title_label.add_theme_color_override("font_color", UiMaterial.INK)
	column.add_child(title_label)
	image = TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(image)
	body_scroll = ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_stretch_ratio = 0.45
	body_scroll.follow_focus = true
	body_scroll.visible = false
	column.add_child(body_scroll)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_override("font", UiTypography.body_font())
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", UiMaterial.INK)
	body_scroll.add_child(body)

func present(texture: Texture2D, owner: String) -> void:
	image.texture = texture
	title_label.text = "%s · 完整立繪" % owner
	body_scroll.visible = false
	body.text = ""

func present_memory(texture: Texture2D, title: String, lines: Array) -> void:
	image.texture = texture
	title_label.text = title
	var parts := PackedStringArray()
	for line in lines:
		parts.append(String(line))
	body.text = "\n\n".join(parts)
	body_scroll.visible = true

func set_layout_bounds(bounds: Rect2) -> void:
	position = Vector2((get_viewport_rect().size.x - bounds.size.x) * 0.5, bounds.position.y)
	size = bounds.size
