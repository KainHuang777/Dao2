class_name UiMaterial
extends RefCounted
## Original vector nine-patch skins. No state, input or animation ownership.

const JADE = preload("res://assets/ui/material/jade_panel.svg")
const PAPER = preload("res://assets/ui/material/silk_row.svg")
const PLAQUE = preload("res://assets/ui/material/paper_button.svg")
const JADE_SELECTED = preload("res://assets/ui/material/jade_selected.svg")
const CINNABAR = preload("res://assets/ui/material/cinnabar_button.svg")
const CARD = preload("res://assets/ui/material/jade_card.svg")
const SILK_PANEL = preload("res://assets/ui/material/silk_panel.svg")
static var _styles: Dictionary = {}
static var _focus: StyleBoxFlat
const INK = Color("343c3d")
const LIGHT_TEXT = Color("f5eedf")
const DISABLED_INK = Color("68665e")

static func surface(role: String, state: String = "normal") -> StyleBoxTexture:
	var key := role + ":" + state
	if _styles.has(key):
		return _styles[key]
	var style := StyleBoxTexture.new()
	style.texture = JADE if role == "panel" else (CARD if role == "card" else (PAPER if role == "paper" else PLAQUE))
	if role == "jade" or (role == "plaque" and state == "selected"):
		style.texture = JADE_SELECTED
	elif role == "primary":
		style.texture = CINNABAR
	var edge := 20.0 if role == "panel" else (12.0 if role == "card" else 14.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, edge)
	style.content_margin_left = 16 if role == "panel" else 12
	style.content_margin_right = style.content_margin_left
	style.content_margin_top = 10 if role == "panel" else (8 if role == "card" else 4)
	style.content_margin_bottom = style.content_margin_top
	match state:
		"hover": style.modulate_color = Color(1.03, 1.03, 1.01)
		"pressed": style.modulate_color = Color(0.91, 0.91, 0.88)
		"disabled": style.modulate_color = Color(0.89, 0.89, 0.86)
		"ready", "full": style.modulate_color = Color(1.0, 0.97, 0.87)
		"warning": style.modulate_color = Color(1.0, 0.93, 0.85)
	_styles[key] = style
	return style

static func card(state: String = "normal") -> StyleBoxTexture:
	return surface("card", state).duplicate()

static func hud_paper() -> StyleBoxTexture:
	var style: StyleBoxTexture = surface("panel").duplicate()
	style.texture = SILK_PANEL
	return style

static func hud_resource_row(full: bool = false) -> StyleBoxFlat:
	var key := "hud_resource:full" if full else "hud_resource:normal"
	if _styles.has(key):
		return _styles[key]
	var style := rounded(Color(0.52, 0.40, 0.19, 0.12) if full else Color(0.95, 0.91, 0.80, 0.12), 3)
	style.border_color = Color(0.43, 0.36, 0.24, 0.24)
	style.border_width_bottom = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_styles[key] = style
	return style

static func mark_paper_tab(button: Button, selected: bool) -> void:
	apply_button(button)
	if not _styles.has("paper_tab:idle"):
		var base := rounded(Color.TRANSPARENT, 3)
		base.content_margin_left = 12
		base.content_margin_right = 12
		base.content_margin_top = 4
		base.content_margin_bottom = 4
		_styles["paper_tab:idle"] = base
		var highlighted: StyleBoxFlat = base.duplicate()
		highlighted.bg_color = Color(0.36, 0.40, 0.30, 0.12)
		_styles["paper_tab:hover"] = highlighted
	var idle: StyleBoxFlat = _styles["paper_tab:idle"]
	var hover: StyleBoxFlat = _styles["paper_tab:hover"]
	button.add_theme_stylebox_override("normal", surface("jade") if selected else idle)
	button.add_theme_stylebox_override("hover", surface("jade", "hover") if selected else hover)
	button.add_theme_stylebox_override("pressed", surface("jade", "pressed") if selected else hover)
	button.add_theme_stylebox_override("hover_pressed", surface("jade", "pressed") if selected else hover)
	button.add_theme_stylebox_override("disabled", surface("jade") if selected else idle)
	_set_button_ink(button, LIGHT_TEXT if selected else INK, LIGHT_TEXT if selected else DISABLED_INK)

static func apply_world_text(label: Label, font: Font, font_size: int, color: Color = Color("f9eccb"), scenic: bool = false) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("19352e"))
	label.add_theme_constant_override("outline_size", 2 if scenic else 0)
	label.add_theme_color_override("font_shadow_color", Color(0.035, 0.07, 0.055, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2 if scenic else 1)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep world typography above the island's sword trails and mist layer.
	label.z_index = 5

static func apply_world_caption(label: Label, font: Font, font_size: int) -> void:
	apply_world_text(label, font, font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Solid ink keeps small world text legible over clouds and island details.
	var plaque := rounded(Color("253b36"), 5)
	label.add_theme_color_override("font_color", LIGHT_TEXT)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	plaque.content_margin_left = 10
	plaque.content_margin_right = 10
	plaque.content_margin_top = 4
	plaque.content_margin_bottom = 4
	label.add_theme_stylebox_override("normal", plaque)

static func keep_world_text_readable(label: Label, minimum_size: float) -> void:
	# Use the parent transform to avoid feeding our own compensation back into it.
	# The anchor remains on the world object; only the text resists camera shrink.
	var parent := label.get_parent() as CanvasItem
	if parent == null:
		return
	var transform := parent.get_global_transform_with_canvas()
	var factor := maxf(0.001, minf(transform.x.length(), transform.y.length()))
	var font_size := label.get_theme_font_size("font_size")
	label.pivot_offset = Vector2(label.size.x * 0.5, 0)
	label.scale = Vector2.ONE * maxf(1.0, minimum_size / (font_size * factor))

static func mark_selected(button: Button, selected: bool) -> void:
	button.modulate = Color.WHITE
	button.add_theme_stylebox_override("normal", surface("plaque", "selected" if selected else "normal"))
	button.add_theme_stylebox_override("hover", surface("plaque", "selected" if selected else "hover"))
	button.add_theme_stylebox_override("pressed", surface("plaque", "selected" if selected else "pressed"))
	button.add_theme_stylebox_override("hover_pressed", surface("plaque", "selected" if selected else "pressed"))
	button.add_theme_stylebox_override("disabled", surface("plaque", "selected" if selected else "disabled"))
	_set_button_ink(button, LIGHT_TEXT if selected else INK, LIGHT_TEXT if selected else DISABLED_INK)

static func rounded(color: Color, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 16
	style.anti_aliasing = true
	return style

static func requirement_fill(state: String) -> StyleBoxFlat:
	var key := "requirement:" + state
	if not _styles.has(key):
		var color := Color("477a68")
		if state == "ready": color = Color("b99348")
		if state == "warning": color = Color("b37843")
		_styles[key] = rounded(color, 3)
	return _styles[key]

static func populate_theme(theme: Theme) -> void:
	for type in ["Button", "MenuButton", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			theme.set_stylebox(state, type, surface("plaque", "pressed" if state == "hover_pressed" else state))
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			theme.set_color(color, type, INK)
		theme.set_color("font_disabled_color", type, DISABLED_INK)
	for type in ["Panel", "PanelContainer", "PopupMenu", "PopupPanel", "TooltipPanel"]:
		theme.set_stylebox("panel", type, surface("card"))
	theme.set_stylebox("hover", "PopupMenu", surface("jade", "hover"))
	theme.set_color("font_color", "PopupMenu", Color("f9eccb"))
	theme.set_color("font_hover_color", "PopupMenu", Color("fff5d7"))
	theme.set_color("font_disabled_color", "PopupMenu", Color("aebbb2"))
	theme.set_constant("v_separation", "PopupMenu", 12)
	for type in ["Label", "RichTextLabel"]:
		theme.set_color("font_color" if type == "Label" else "default_color", type, Color("efe7d1"))
	for type in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", type, surface("card", "pressed"))
		theme.set_stylebox("focus", type, surface("card", "hover"))
		theme.set_color("font_color", type, Color("f9eccb"))
		theme.set_color("caret_color", type, Color("f3d48c"))
		theme.set_color("selection_color", type, Color("426e64"))
	for type in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", type, rounded(Color("153331")))
		theme.set_stylebox("grabber", type, rounded(Color("857b50")))
		theme.set_stylebox("grabber_highlight", type, rounded(Color("c3b478")))
		theme.set_stylebox("grabber_pressed", type, rounded(Color("ac965c")))

static func apply_button(button: Button, role: String = "plaque", selected_when_disabled: bool = false) -> void:
	button.flat = false
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, surface(role, "selected" if state == "disabled" and selected_when_disabled else state))
	button.add_theme_stylebox_override("hover_pressed", surface(role, "pressed"))
	if _focus == null:
		_focus = StyleBoxFlat.new()
		_focus.bg_color = Color.TRANSPARENT
		_focus.border_color = Color("b58c42")
		_focus.set_border_width_all(2)
		_focus.set_corner_radius_all(7)
		_focus.corner_detail = 16
		_focus.anti_aliasing = true
	button.add_theme_stylebox_override("focus", _focus)
	var ink := LIGHT_TEXT if role in ["jade", "primary"] else INK
	_set_button_ink(button, ink, LIGHT_TEXT if selected_when_disabled else (Color("d0ccc1") if role in ["jade", "primary"] else DISABLED_INK))
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

static func _set_button_ink(button: Button, ink: Color, disabled_ink: Color) -> void:
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color, ink)
	button.add_theme_color_override("font_disabled_color", disabled_ink)
