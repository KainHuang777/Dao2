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
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(_body_label)
	var close_button := Button.new()
	close_button.name = "OfflineSummaryClose"
	close_button.text = "關閉"
	close_button.custom_minimum_size = Vector2(88, 44)
	close_button.pressed.connect(_on_close_pressed)
	_box.add_child(close_button)
	set_layout_bounds(Rect2(position, size))

func show_report(report: Dictionary) -> void:
	var left_at_ms: int = int(report.get("left_at_utc_ms", 0))
	var effective_ms: int = int(report.get("effective_ms", 0))
	var age_seconds: float = float(report.get("age_seconds", 0.0))
	var stopped: Variant = report.get("stopped", null)
	var cap_applied: bool = bool(report.get("cap_applied", false))
	var stopped_text: String = "無（正常結算）" if stopped == null else str(stopped)
	var cap_text: String = "是" if cap_applied else "否"
	_body_label.text = (
		"實際離開時間：%d ms（UTC 紀元）\n" % left_at_ms
		+ "有效收益時間：%d ms（%.1f 秒）\n" % [effective_ms, effective_ms / 1000.0]
		+ "年歲變化：%.1f 秒\n" % age_seconds
		+ "停止原因：%s\n" % stopped_text
		+ "是否套用上限：%s" % cap_text
	)
	visible = true

func _on_close_pressed() -> void:
	visible = false