class_name SaveControls
extends Control

var _background: Panel
var _column: VBoxContainer
var _share_text: TextEdit
var _legacy_text: TextEdit
var _status_label: Label

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
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)
	_column = VBoxContainer.new()
	_column.name = "SaveColumn"
	_column.add_theme_constant_override("separation", 10)
	add_child(_column)
	var buttons := HFlowContainer.new()
	buttons.name = "SaveButtons"
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 8)
	_column.add_child(buttons)
	var export_button := Button.new()
	export_button.name = "ExportButton"
	export_button.text = "匯出存檔"
	export_button.custom_minimum_size = Vector2(112, 44)
	export_button.pressed.connect(_on_export_pressed)
	buttons.add_child(export_button)
	var import_button := Button.new()
	import_button.name = "ImportButton"
	import_button.text = "匯入存檔"
	import_button.custom_minimum_size = Vector2(112, 44)
	import_button.pressed.connect(_on_import_pressed)
	buttons.add_child(import_button)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "關閉"
	close_button.custom_minimum_size = Vector2(88, 44)
	close_button.pressed.connect(func(): visible = false)
	buttons.add_child(close_button)
	_share_text = TextEdit.new()
	_share_text.name = "ShareText"
	_share_text.custom_minimum_size = Vector2(0, 120)
	_share_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_child(_share_text)
	var legacy_button := Button.new()
	legacy_button.name = "LegacyImportButton"
	legacy_button.text = "舊檔匯入"
	legacy_button.custom_minimum_size = Vector2(112, 44)
	legacy_button.pressed.connect(_on_legacy_import_pressed)
	_column.add_child(legacy_button)
	_legacy_text = TextEdit.new()
	_legacy_text.name = "LegacyText"
	_legacy_text.custom_minimum_size = Vector2(0, 120)
	_legacy_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_child(_legacy_text)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(_status_label)
	set_layout_bounds(Rect2(position, size))

func _on_export_pressed() -> void:
	var encoded := SaveManager.export_share_string()
	if encoded.is_empty():
		_set_status("匯出失敗：無法編碼存檔")
		return
	_share_text.text = encoded
	_set_status("已匯出存檔，請複製分享字串")

func _on_import_pressed() -> void:
	var share := _share_text.text.strip_edges()
	if share.is_empty():
		_set_status("匯入失敗：分享字串為空")
		return
	var result: Dictionary = SaveManager.import_share_string(share)
	if not bool(result.get("ok", false)):
		_set_status("匯入失敗：%s" % str(result.get("error", "unknown")))
		return
	_set_status("已驗證匯入檔（未套用進度）")

func _on_legacy_import_pressed() -> void:
	var legacy := _legacy_text.text.strip_edges()
	if legacy.is_empty():
		_set_status("舊檔匯入失敗：內容為空")
		return
	var result: Dictionary = SaveManager.import_legacy_text(legacy)
	if not bool(result.get("ok", false)):
		_set_status("舊檔匯入失敗：%s" % str(result.get("error", "unknown")))
		return
	var report: Dictionary = result.get("report", {})
	var unknown_resources: Array = report.get("unknown_resource_ids", [])
	var unknown_buildings: Array = report.get("unknown_building_ids", [])
	var amount_issues: Array = report.get("amount_issues", [])
	var high_layers: Array = report.get("high_layer_amounts", [])
	_set_status("舊檔匯入成功（%s）：未知資源 %d、未知建築 %d、數值問題 %d、高階數 %d" % [
		str(report.get("source_format", "?")),
		unknown_resources.size(),
		unknown_buildings.size(),
		amount_issues.size(),
		high_layers.size(),
	])

func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message