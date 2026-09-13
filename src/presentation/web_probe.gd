extends Control

const SAVE_PATH := "user://web_probe_state.json"

@onready var status_label: Label = $Margin/Layout/Status
@onready var visit_count_label: Label = $Margin/Layout/VisitCount
@onready var increment_button: Button = $Margin/Layout/Increment

var visit_count := 0

func _ready() -> void:
	visit_count = _load_visit_count()
	visit_count += 1
	_save_visit_count()
	_refresh_view("本機儲存已寫入；重新整理後應保留次數。")
	increment_button.pressed.connect(_on_increment_pressed)
	print("PASS: Web probe main scene completed a headless runtime start.")

func _on_increment_pressed() -> void:
	visit_count += 1
	_save_visit_count()
	_refresh_view("周天運轉成功，已寫入本機儲存。")

func _refresh_view(message: String) -> void:
	status_label.text = message
	visit_count_label.text = "啟動與運轉次數：%d" % visit_count

func _load_visit_count() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return 0
	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if parsed is Dictionary and parsed.has("visit_count"):
		return int(parsed["visit_count"])
	return 0

func _save_visit_count() -> void:
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		status_label.text = "無法寫入本機儲存。"
		return
	save_file.store_string(JSON.stringify({"visit_count": visit_count}))
