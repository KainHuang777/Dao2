extends PanelContainer
## Hosted by the existing shell tool overlay: shared shield, CloseSeal and Escape.
var image: TextureRect
var title_label: Label
var body_scroll: ScrollContainer
var body: Label
var choices: BoxContainer
var reset_button: InscriptionAction
var choice_buttons: Array = []
var _script: Dictionary = {}
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
	choices = BoxContainer.new()
	choices.vertical = true
	choices.add_theme_constant_override("separation", 4)
	choices.visible = false
	column.add_child(choices)
	reset_button = InscriptionAction.new()
	reset_button.text = "重新閱讀"
	reset_button.add_theme_font_size_override("font_size", 18)
	reset_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset_button.tooltip_text = "從這一章的開頭重新閱讀。"
	reset_button.visible = false
	reset_button.pressed.connect(reset_chapter)
	column.add_child(reset_button)

func present(texture: Texture2D, owner: String) -> void:
	_script = {}
	image.texture = texture
	image.visible = true
	body_scroll.size_flags_stretch_ratio = 0.45
	title_label.text = "%s · 完整立繪" % owner
	body_scroll.visible = false
	body.text = ""
	_clear_choices()
	reset_button.visible = false

func present_memory(texture: Texture2D, title: String, lines: Array) -> void:
	_script = {}
	image.texture = texture
	image.visible = true
	body_scroll.size_flags_stretch_ratio = 0.45
	title_label.text = title
	var parts := PackedStringArray()
	for line in lines:
		parts.append(String(line))
	body.text = "\n\n".join(parts)
	body_scroll.visible = true
	_clear_choices()
	reset_button.visible = false

func present_chapter(title: String, script: Dictionary) -> void:
	_script = script.duplicate(true)
	title_label.text = title
	image.texture = null
	image.visible = false
	body_scroll.size_flags_stretch_ratio = 1.0
	body_scroll.visible = true
	body.text = "\n\n".join(_lines(_script.get("lines", [])))
	_clear_choices()
	var labels: Variant = _script.get("choices", [])
	if labels is Array:
		for index in (labels as Array).size():
			var button := InscriptionAction.new()
			button.text = String((labels as Array)[index])
			button.add_theme_font_size_override("font_size", 18)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(choose.bind(index))
			choices.add_child(button)
			choice_buttons.append(button)
	choices.visible = not choice_buttons.is_empty()
	reset_button.visible = false

func choose(index: int) -> void:
	var branches: Variant = _script.get("branches", [])
	if not branches is Array: return
	if index < 0 or index >= (branches as Array).size(): return
	var parts := PackedStringArray()
	parts.append(body.text)
	parts.append("\n\n".join(_lines((branches as Array)[index])))
	var closing := String(_script.get("closing", ""))
	if not closing.is_empty(): parts.append(closing)
	body.text = "\n\n".join(parts)
	choices.visible = false
	reset_button.visible = true
	body_scroll.scroll_vertical = 0
	reset_button.grab_focus()

func reset_chapter() -> void:
	if _script.is_empty(): return
	present_chapter(title_label.text, _script)

func _lines(raw: Variant) -> PackedStringArray:
	var parts := PackedStringArray()
	if raw is Array:
		for line in raw:
			parts.append(String(line))
	return parts

func _clear_choices() -> void:
	choice_buttons.clear()
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	choices.visible = false

func set_layout_bounds(bounds: Rect2) -> void:
	position = Vector2((get_viewport_rect().size.x - bounds.size.x) * 0.5, bounds.position.y)
	size = bounds.size
