class_name V2RulesNotice
extends Control

signal closed

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
	_box.name = "V2RulesNoticeBox"
	_box.add_theme_constant_override("separation", 10)
	add_child(_box)
	var title := Label.new()
	title.name = "V2RulesNoticeTitle"
	title.text = "規則更新存檔重置"
	_box.add_child(title)
	_body_label = Label.new()
	_body_label.name = "V2RulesNoticeBody"
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(scroll)
	scroll.add_child(_body_label)
	var close_button := Button.new()
	close_button.name = "V2RulesNoticeClose"
	close_button.text = "關閉"
	close_button.custom_minimum_size = Vector2(88, 44)
	close_button.pressed.connect(_on_close_pressed)
	_box.add_child(close_button)
	_body_label.text = "本次更新（early pacing v2）調整了修煉與建設規則，舊版存檔已自動備份並清除。將以全新洞府開始修行。"
	set_layout_bounds(Rect2(position, size))

func show_notice() -> void:
	visible = true

func _on_close_pressed() -> void:
	visible = false
	emit_signal("closed")