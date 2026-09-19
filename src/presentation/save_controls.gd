class_name SaveControls
extends Control

var _share_text: TextEdit
var _legacy_text: TextEdit
var _status_label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var column := VBoxContainer.new()
	column.name = "SaveColumn"
	column.position = Vector2(16, 16)
	add_child(column)
	var buttons := HBoxContainer.new()
	buttons.name = "SaveButtons"
	column.add_child(buttons)
	var export_button := Button.new()
	export_button.name = "ExportButton"
	export_button.text = "匯出存檔"
	export_button.pressed.connect(_on_export_pressed)
	buttons.add_child(export_button)
	var import_button := Button.new()
	import_button.name = "ImportButton"
	import_button.text = "匯入存檔"
	import_button.pressed.connect(_on_import_pressed)
	buttons.add_child(import_button)
	_share_text = TextEdit.new()
	_share_text.name = "ShareText"
	_share_text.custom_minimum_size = Vector2(360, 120)
	column.add_child(_share_text)
	var legacy_button := Button.new()
	legacy_button.name = "LegacyImportButton"
	legacy_button.text = "舊檔匯入"
	legacy_button.pressed.connect(_on_legacy_import_pressed)
	column.add_child(legacy_button)
	_legacy_text = TextEdit.new()
	_legacy_text.name = "LegacyText"
	_legacy_text.custom_minimum_size = Vector2(360, 120)
	column.add_child(_legacy_text)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	column.add_child(_status_label)

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
