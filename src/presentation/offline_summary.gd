class_name OfflineSummary
extends Control

var _body_label: Label

func _ready() -> void:
	visible = false
	_build_ui()

func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.name = "OfflineSummaryBox"
	box.position = Vector2(64, 48)
	box.custom_minimum_size = Vector2(420, 220)
	add_child(box)
	var title := Label.new()
	title.name = "OfflineSummaryTitle"
	title.text = "離線收益摘要"
	box.add_child(title)
	_body_label = Label.new()
	_body_label.name = "OfflineSummaryBody"
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body_label)
	var close_button := Button.new()
	close_button.name = "OfflineSummaryClose"
	close_button.text = "關閉"
	close_button.pressed.connect(_on_close_pressed)
	box.add_child(close_button)

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