class_name GraphicAction
extends Button
## Shared ink action / transparent artwork hit area. Never owns rewards or timers.
const JADE := Color("326b59")
const COOL := Color("416b82")
var artwork_hit := false:
	set(value):
		artwork_hit = value
		if value:
			for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				add_theme_stylebox_override(state, StyleBoxEmpty.new())
var attention := false
var reduced_motion := false
var _phase := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(44, 44)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UiMaterial.apply_scroll_button(self)
	add_theme_color_override("font_color", JADE)
	add_theme_color_override("icon_normal_color", Color.WHITE)
	add_theme_color_override("icon_disabled_color", Color("878b85"))
	add_theme_font_override("font", UiTypography.emphasis_font())
	add_theme_font_size_override("font_size", 18)
	add_theme_constant_override("h_separation", 10)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	visibility_changed.connect(_sync_process)
	set_process(false)

func present(ready: bool, reduced: bool = false) -> void:
	attention = ready
	reduced_motion = reduced
	_sync_process()
	queue_redraw()

func _sync_process() -> void:
	set_process(attention and not disabled and not reduced_motion and is_visible_in_tree())

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, TAU)
	queue_redraw()

func _draw() -> void:
	if disabled: return
	var hot := is_hovered() or has_focus()
	if artwork_hit:
		if not attention and not hot: return
		var radius := minf(size.x, size.y) * 0.46
		var pulse := 0.0 if reduced_motion else sin(_phase * 2.0) * 0.5 + 0.5
		for band in 4:
			draw_arc(size * 0.5, radius - float(band), 0, TAU, 64, Color(JADE, (0.12 + pulse * 0.10) / float(band + 1)), 2.0, true)
		if hot: draw_arc(size * 0.5, radius, 0, TAU, 64, Color(JADE, 0.65), 2.0, true)
	else:
		# A short ink stroke anchors the image + verb, without a rectangular plaque.
		var strength := 0.45 + sin(_phase * 2.0) * 0.15 if attention and not reduced_motion else 0.25
		draw_line(Vector2(12, size.y - 3), Vector2(size.x - 12, size.y - 3), Color(JADE, 0.7 if hot else strength), 2.0 if is_pressed() else 1.0, true)
