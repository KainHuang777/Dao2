class_name DebugPanel
extends Control
## Debug tool panel offering automated building upgrade loops and era progression testing.

signal auto_build_toggled(enabled: bool)
signal manual_upgrade_requested()
signal boost_era_level_requested()
signal add_resources_requested()
signal apply_buff_requested(buff_id: String)
signal reset_achievements_requested()
signal close_requested()

var _background: Panel
var _column: VBoxContainer
var _status_label: Label
var _auto_build_button: Button
var _manual_upgrade_button: Button
var _boost_era_button: Button
var _add_res_button: Button
var _close_button: Button

var auto_build_enabled: bool = false
var auto_build_timer: float = 30.0

func _ready() -> void:
	_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _background != null:
		_background.size = size
	if _column != null:
		_column.position = Vector2(16, 16)
		_column.size = Vector2(maxf(0.0, size.x - 32.0), maxf(0.0, size.y - 32.0))

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	_column = VBoxContainer.new()
	_column.name = "DebugColumn"
	_column.add_theme_constant_override("separation", 12)
	add_child(_column)

	# 標題列
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	_column.add_child(header_row)

	var title := Label.new()
	title.text = "調試工具 (DEBUG)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", UiTypography.emphasis_font())
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("fff0c8"))
	header_row.add_child(title)

	_close_button = Button.new()
	_close_button.text = "關閉"
	_close_button.custom_minimum_size = Vector2(72, 36)
	_close_button.add_theme_font_size_override("font_size", 16)
	_close_button.pressed.connect(func():
		visible = false
		close_requested.emit()
	)
	header_row.add_child(_close_button)

	# 提示與狀態說明
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "點擊選項以執行調試功能。"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color("b8d7ca"))
	_column.add_child(_status_label)

	# 分隔線 1
	var sep1 := HSeparator.new()
	_column.add_child(sep1)

	# 區塊 1: 建築升級
	var bld_section_label := Label.new()
	bld_section_label.text = "【建築建造與升級】"
	bld_section_label.add_theme_font_override("font", UiTypography.emphasis_font())
	bld_section_label.add_theme_font_size_override("font_size", 16)
	bld_section_label.add_theme_color_override("font_color", Color("ffd599"))
	_column.add_child(bld_section_label)

	var bld_buttons := HFlowContainer.new()
	bld_buttons.add_theme_constant_override("h_separation", 8)
	bld_buttons.add_theme_constant_override("v_separation", 8)
	_column.add_child(bld_buttons)

	_auto_build_button = Button.new()
	_auto_build_button.name = "AutoBuildButton"
	_auto_build_button.text = "每 30 秒自動隨機建造：關閉"
	_auto_build_button.custom_minimum_size = Vector2(240, 44)
	_auto_build_button.add_theme_font_size_override("font_size", 15)
	_auto_build_button.pressed.connect(_on_toggle_auto_build)
	bld_buttons.add_child(_auto_build_button)

	_manual_upgrade_button = Button.new()
	_manual_upgrade_button.name = "ManualUpgradeButton"
	_manual_upgrade_button.text = "立即隨機升級 1 棟滿足條件建築"
	_manual_upgrade_button.custom_minimum_size = Vector2(240, 44)
	_manual_upgrade_button.add_theme_font_size_override("font_size", 15)
	_manual_upgrade_button.pressed.connect(func(): manual_upgrade_requested.emit())
	bld_buttons.add_child(_manual_upgrade_button)

	# 分隔線 2
	var sep2 := HSeparator.new()
	_column.add_child(sep2)

	# 區塊 2: 境界與修為
	var era_section_label := Label.new()
	era_section_label.text = "【境界修行躍遷】"
	era_section_label.add_theme_font_override("font", UiTypography.emphasis_font())
	era_section_label.add_theme_font_size_override("font_size", 16)
	era_section_label.add_theme_color_override("font_color", Color("ffd599"))
	_column.add_child(era_section_label)

	var era_buttons := HFlowContainer.new()
	era_buttons.add_theme_constant_override("h_separation", 8)
	era_buttons.add_theme_constant_override("v_separation", 8)
	_column.add_child(era_buttons)

	_boost_era_button = Button.new()
	_boost_era_button.name = "BoostEraButton"
	_boost_era_button.text = "修為直升該 ERA LV10 (大圓滿)"
	_boost_era_button.custom_minimum_size = Vector2(240, 44)
	_boost_era_button.add_theme_font_size_override("font_size", 15)
	_boost_era_button.pressed.connect(func(): boost_era_level_requested.emit())
	era_buttons.add_child(_boost_era_button)

	# 分隔線 3
	var sep3 := HSeparator.new()
	_column.add_child(sep3)

	# 區塊 3: 資源支援
	var res_section_label := Label.new()
	res_section_label.text = "【資源調試支援】"
	res_section_label.add_theme_font_override("font", UiTypography.emphasis_font())
	res_section_label.add_theme_font_size_override("font_size", 16)
	res_section_label.add_theme_color_override("font_color", Color("ffd599"))
	_column.add_child(res_section_label)

	var res_buttons := HFlowContainer.new()
	res_buttons.add_theme_constant_override("h_separation", 8)
	res_buttons.add_theme_constant_override("v_separation", 8)
	_column.add_child(res_buttons)

	_add_res_button = Button.new()
	_add_res_button.name = "AddResourcesButton"
	_add_res_button.text = "獲得全基礎資源 (+1,000)"
	_add_res_button.custom_minimum_size = Vector2(200, 44)
	_add_res_button.add_theme_font_size_override("font_size", 15)
	_add_res_button.pressed.connect(func(): add_resources_requested.emit())
	res_buttons.add_child(_add_res_button)

	# 分隔線 4
	var sep4 := HSeparator.new()
	_column.add_child(sep4)

	# 區塊 4: BUFF 狀態增益
	var buff_section_label := Label.new()
	buff_section_label.text = "【狀態時效增益 (BUFF)】"
	buff_section_label.add_theme_font_override("font", UiTypography.emphasis_font())
	buff_section_label.add_theme_font_size_override("font_size", 16)
	buff_section_label.add_theme_color_override("font_color", Color("ffd599"))
	_column.add_child(buff_section_label)

	var buff_buttons := HFlowContainer.new()
	buff_buttons.add_theme_constant_override("h_separation", 8)
	buff_buttons.add_theme_constant_override("v_separation", 8)
	_column.add_child(buff_buttons)

	var surge_btn := Button.new()
	surge_btn.name = "SpiritSurgeButton"
	surge_btn.text = "施加「天靈氣湧」(+30%全產/50%靈氣)"
	surge_btn.custom_minimum_size = Vector2(240, 44)
	surge_btn.add_theme_font_size_override("font_size", 14)
	surge_btn.pressed.connect(func(): apply_buff_requested.emit("spirit_surge"))
	buff_buttons.add_child(surge_btn)

	var epi_btn := Button.new()
	epi_btn.name = "EpiphanyButton"
	epi_btn.text = "施加「頓悟靈光」(+100%修煉速度)"
	epi_btn.custom_minimum_size = Vector2(240, 44)
	epi_btn.add_theme_font_size_override("font_size", 14)
	epi_btn.pressed.connect(func(): apply_buff_requested.emit("epiphany"))
	buff_buttons.add_child(epi_btn)

	# 分隔線 5
	var sep5 := HSeparator.new()
	_column.add_child(sep5)

	# 區塊 5: 成就調試
	var ach_section_label := Label.new()
	ach_section_label.text = "【仙道成就調試】"
	ach_section_label.add_theme_font_override("font", UiTypography.emphasis_font())
	ach_section_label.add_theme_font_size_override("font_size", 16)
	ach_section_label.add_theme_color_override("font_color", Color("ffd599"))
	_column.add_child(ach_section_label)

	var ach_buttons := HFlowContainer.new()
	ach_buttons.add_theme_constant_override("h_separation", 8)
	ach_buttons.add_theme_constant_override("v_separation", 8)
	_column.add_child(ach_buttons)

	var reset_ach_btn := Button.new()
	reset_ach_btn.name = "ResetAchievementsButton"
	reset_ach_btn.text = "重置全部成就進度 (解鎖/領取/統計)"
	reset_ach_btn.custom_minimum_size = Vector2(260, 44)
	reset_ach_btn.add_theme_font_size_override("font_size", 14)
	reset_ach_btn.pressed.connect(func(): reset_achievements_requested.emit())
	ach_buttons.add_child(reset_ach_btn)

	set_layout_bounds(Rect2(position, size))

func _on_toggle_auto_build() -> void:
	auto_build_enabled = not auto_build_enabled
	auto_build_toggled.emit(auto_build_enabled)
	update_auto_build_ui(auto_build_timer)

func update_auto_build_ui(time_left: float) -> void:
	if _auto_build_button == null:
		return
	if auto_build_enabled:
		_auto_build_button.text = "每 30 秒自動建造：進行中 (%.0fs)" % maxf(0.0, time_left)
		_auto_build_button.add_theme_color_override("font_color", Color("77f29b"))
	else:
		_auto_build_button.text = "每 30 秒自動隨機建造：關閉"
		_auto_build_button.remove_theme_color_override("font_color")

func set_status_message(msg: String) -> void:
	if _status_label != null:
		_status_label.text = msg
