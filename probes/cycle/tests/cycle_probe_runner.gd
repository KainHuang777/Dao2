extends SceneTree

const SAVE_PATH := "user://m0a_cycle_probe_runner.json"

func _init() -> void:
	var output := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if output == null:
		_fail("Cannot create isolated cycle probe fixture")
		return
	output.store_string(JSON.stringify({"schema": 1, "visit_count": 4}))
	output.close()
	var input := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if input == null:
		_fail("Cannot read isolated cycle probe fixture")
		return
	var parsed: Variant = JSON.parse_string(input.get_as_text())
	if not (parsed is Dictionary and int(parsed.get("schema", 0)) == 1 and int(parsed.get("visit_count", 0)) == 4):
		_fail("Cycle probe fixture round-trip mismatch")
		return
	var font := load("res://assets/fonts/NotoSerifTC-VF.ttf") as Font
	if font == null or not font.has_char(0x5468) or not font.has_char(0x5929):
		_fail("Cycle probe Traditional Chinese glyph fixture failed")
		return
	print("PASS: isolated cycle probe storage fixture and Traditional Chinese font are available.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
