class_name ArrowBookmarkTab
extends GameTab
## 直立式箭型書籤籤條；古風線裝書版式，頂部垂掛，底部呈箭尖 (▼)。

var bookmark_text: String = ""
var custom_font_size: int = 14

func _init() -> void:
	super._init()
	custom_minimum_size = Vector2(46, 58)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for event in [mouse_entered, mouse_exited, button_down, button_up, focus_entered, focus_exited, toggled]:
		event.connect(queue_redraw)

func _toggled(_button_pressed: bool) -> void:
	queue_redraw()

func _update_style() -> void:
	# 覆寫 GameTab 預設的滿版矩形按鈕樣式，轉由 _draw 繪製古籍箭型籤條
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, empty)
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	queue_redraw()

func _get_display_chars() -> Array[String]:
	var source := bookmark_text if not bookmark_text.is_empty() else text
	if source == "轉世輪迴": source = "轉世"
	elif source == "道心天賦": source = "天賦"
	elif source.length() > 2 and source.contains("·"):
		source = source.split("·")[0].strip_edges()
	var chars: Array[String] = []
	for i in range(source.length()):
		chars.append(source.substr(i, 1))
	return chars

func _draw() -> void:
	var w := size.x
	var selected := button_pressed
	var hot := is_hovered() or has_focus()
	var arrow_tip := 10.0

	# 尺寸狀態：直立垂直排列時，選中籤條向右微探 3px，長度微展，呈現古籍夾籤層次
	var shift_x := 3.0 if selected else (1.5 if hot and not disabled else 0.0)
	var x0 := shift_x
	var x1 := w + shift_x - 1.0

	var h: float
	if selected:
		h = clampf(size.y, 52.0, 60.0)
	elif hot and not disabled:
		h = clampf(size.y - 3.0, 48.0, 56.0)
	else:
		h = clampf(size.y - 6.0, 46.0, 52.0)

	var pts := PackedVector2Array([
		Vector2(x0, 0),
		Vector2(x1, 0),
		Vector2(x1, h - arrow_tip),
		Vector2(x0 + (x1 - x0) * 0.5, h),
		Vector2(x0, h - arrow_tip)
	])

	# 封閉外框頂點（用於繪製描邊）
	var outline := PackedVector2Array([
		Vector2(x0, 0),
		Vector2(x1, 0),
		Vector2(x1, h - arrow_tip),
		Vector2(x0 + (x1 - x0) * 0.5, h),
		Vector2(x0, h - arrow_tip),
		Vector2(x0, 0)
	])

	# 配色原則：選中為深青玉金線，未選中為古宣紙墨線
	var fill_color: Color
	var border_color: Color
	var text_color: Color
	var border_width := 1.0

	if disabled:
		fill_color = Color(0.85, 0.81, 0.72, 0.4)
		border_color = Color(0.55, 0.50, 0.40, 0.4)
		text_color = Color(0.50, 0.45, 0.38, 0.5)
	elif selected:
		fill_color = Color("285244") # 古雅青玉色
		border_color = Color("ad8d4f") # 古典金描邊
		text_color = Color("fbf6ea") # 金宣米白墨
		border_width = 1.4
	elif hot:
		fill_color = Color(0.93, 0.89, 0.80, 0.95) # 亮宣紙
		border_color = Color("416b82") # 青嵐墨線
		text_color = Color("1a1814")
		border_width = 1.2
	else:
		fill_color = Color(0.88, 0.83, 0.73, 0.88) # 古宣紙沉色
		border_color = Color(0.48, 0.42, 0.32, 0.75) # 淡墨褐
		text_color = Color("2c2a26") # 濃墨字

	# 繪製籤身多邊形與外框
	draw_colored_polygon(pts, fill_color)
	draw_polyline(outline, border_color, border_width, true)

	# 頂部裝飾：壓邊細線與古書掛籤銅環／孔眼
	var header_line_color := border_color
	draw_line(Vector2(x0, 0), Vector2(x1, 0), header_line_color, 2.0, true)
	var hole_center := Vector2(x0 + (x1 - x0) * 0.5, 6.0)
	draw_circle(hole_center, 1.8, Color(border_color, 0.6))

	# 垂直文字排版
	var chars := _get_display_chars()
	if chars.is_empty():
		return

	var font := UiTypography.emphasis_font() if selected else UiTypography.body_font()
	var font_size := custom_font_size
	var line_spacing := 2.0
	var char_height := float(font.get_height(font_size))
	var total_text_h := float(chars.size()) * char_height + float(chars.size() - 1) * line_spacing

	# 垂直置中於書籤主要長方形區域（扣除底部箭頭）
	var body_h := h - arrow_tip - 8.0 # 避開頂部孔眼與底部箭折
	var start_y := 9.0 + maxf(0.0, (body_h - total_text_h) * 0.5) + font.get_ascent(font_size)

	for i in range(chars.size()):
		var ch := chars[i]
		var char_w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var char_pos := Vector2(x0 + ((x1 - x0) - char_w) * 0.5, start_y + float(i) * (char_height + line_spacing))
		draw_string(font, char_pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
