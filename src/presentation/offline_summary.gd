class_name OfflineSummary
extends Control

var _background: Panel
var _box: VBoxContainer
var _body_label: Label

func _ready() -> void:
	visible = false
	_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _background != null:
		_background.size = size
	if _box != null:
		_box.position = Vector2(16, 16)
		_box.size = Vector2(maxf(0.0, size.x - 32.0), maxf(0.0, size.y - 32.0))

func _build_ui() -> void:
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)
	_box = VBoxContainer.new()
	_box.name = "OfflineSummaryBox"
	_box.add_theme_constant_override("separation", 10)
	add_child(_box)
	var title := Label.new()
	title.name = "OfflineSummaryTitle"
	title.text = "離線收益摘要"
	_box.add_child(title)
	_body_label = Label.new()
	_body_label.name = "OfflineSummaryBody"
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(scroll)
	scroll.add_child(_body_label)
	var close_button := Button.new()
	close_button.name = "OfflineSummaryClose"
	close_button.text = "關閉"
	close_button.custom_minimum_size = Vector2(88, 44)
	close_button.pressed.connect(_on_close_pressed)
	_box.add_child(close_button)
	set_layout_bounds(Rect2(position, size))

func show_report(report: Dictionary) -> void:
	var away_seconds: float = float(report.get("away_ms", 0)) / 1000.0
	var effective_seconds: float = float(report.get("effective_ms", 0)) / 1000.0
	var age_seconds: float = float(report.get("age_seconds", 0.0))
	var stopped: Variant = report.get("stopped", null)
	var cap_applied: bool = bool(report.get("cap_applied", false))

	var away_sec_str: String = "%.1f 秒" % away_seconds if away_seconds > 0.0 and away_seconds < 1.0 else "%d 秒" % int(round(away_seconds))
	var eff_sec_str: String = "%.1f 秒" % effective_seconds if effective_seconds > 0.0 and effective_seconds < 1.0 else "%d 秒" % int(round(effective_seconds))

	var age_years: float = age_seconds / 60.0
	var age_year_str: String = "%d 年" % int(round(age_years)) if is_equal_approx(age_years, round(age_years)) else "%.1f 年" % age_years

	var stopped_text: String = _format_stopped_reason(stopped)
	var cap_text: String = "是" if cap_applied else "否"

	_body_label.text = (
		"實際離開時間：%s\n" % away_sec_str
		+ "有效收益時間：%s\n" % eff_sec_str
		+ "年歲變化：%s\n" % age_year_str
		+ "停止原因：%s\n" % stopped_text
		+ "是否套用上限：%s" % cap_text
	)
	visible = true

func _format_stopped_reason(stopped: Variant) -> String:
	if stopped == null:
		return "無（正常結算）"
	var stopped_str := str(stopped)
	match stopped_str:
		"lifespan_exhausted":
			return "壽元耗盡"
		"cap_reached", "cap_applied":
			return "達到離線收益上限"
		_:
			return stopped_str

func _on_close_pressed() -> void:
	visible = false
