extends Control

## This isolated Web project proves only a click/reload persistence contract.
## It never reads the main game's future save path or the former web_probe state.
const SAVE_PATH := "user://m0a_cycle_probe_state.json"

@onready var status_label: Label = $Margin/Layout/Status
@onready var visit_count_label: Label = $Margin/Layout/VisitCount
@onready var increment_button: Button = $Margin/Layout/Increment

var visit_count := 0

func _ready() -> void:
	visit_count = _load_visit_count() + 1
	if not _save_visit_count():
		return
	_refresh_view("啟動已保存。點「運轉一次周天」，再重新整理。")
	increment_button.pressed.connect(_on_increment_pressed)
	print("CYCLE_PROBE_READY count=", visit_count)

func _on_increment_pressed() -> void:
	visit_count += 1
	if not _save_visit_count():
		return
	_refresh_view("周天運轉成功，已保存。重新整理後會再增加一次啟動記錄。")
	print("CYCLE_PROBE_INCREMENT count=", visit_count)

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
	if parsed is Dictionary and typeof(parsed.get("visit_count")) in [TYPE_INT, TYPE_FLOAT]:
		return max(0, int(parsed["visit_count"]))
	return 0

func _save_visit_count() -> bool:
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		status_label.text = "無法寫入此探針的本機儲存。"
		return false
	save_file.store_string(JSON.stringify({"schema": 1, "visit_count": visit_count}))
	save_file.close()
	return true
