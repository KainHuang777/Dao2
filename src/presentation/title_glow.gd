extends Control
## Local glyph bloom; no screen capture, font-atlas sampling or full-HUD blur.
const SHADER := preload("res://assets/vfx/title_glow.gdshader")
const PADDING := 16
var source: Label
var stencil: Label
var viewport: SubViewport
var image: TextureRect
var _font_size := -1
var _size := Vector2.ZERO
var glow_enabled := true

func setup(label: Label, tint: Color) -> void:
	source = label
	name = "題字柔光"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.size = Vector2i(1, 1)
	add_child(viewport)
	stencil = Label.new()
	stencil.position = Vector2(PADDING, PADDING)
	stencil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stencil.add_theme_color_override("font_color", Color.WHITE)
	stencil.add_theme_constant_override("outline_size", 0)
	stencil.add_theme_constant_override("shadow_outline_size", 0)
	stencil.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	viewport.add_child(stencil)
	image = TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.position = Vector2(-PADDING, -PADDING)
	image.texture = viewport.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("tint", tint)
	image.material = material
	add_child(image)
	label.add_child(self)

func _process(_delta: float) -> void:
	var enabled := glow_enabled and source.is_visible_in_tree() and source.size.x > 0.0 and source.size.y > 0.0
	visible = enabled
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
	if not enabled:
		return
	if _size != source.size:
		_size = source.size
		viewport.size = Vector2i(_size.ceil()) + Vector2i.ONE * PADDING * 2
		image.size = Vector2(viewport.size)
		stencil.size = _size
	var font_size := source.get_theme_font_size("font_size")
	if font_size != _font_size:
		_font_size = font_size
		stencil.add_theme_font_override("font", source.get_theme_font("font"))
		stencil.add_theme_font_size_override("font_size", font_size)
	stencil.text = source.text
	stencil.visible_ratio = source.visible_ratio
	stencil.horizontal_alignment = source.horizontal_alignment
	stencil.vertical_alignment = source.vertical_alignment
	stencil.autowrap_mode = source.autowrap_mode
