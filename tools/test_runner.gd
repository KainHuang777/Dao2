extends SceneTree

const PROBE_SAVE_PATH := "user://web_probe_runner.json"
const UI_FONT_PATH := "res://assets/fonts/SourceHanSansTW-VF.ttf"

func _init() -> void:
	var output := FileAccess.open(PROBE_SAVE_PATH, FileAccess.WRITE)
	if output == null:
		push_error("Cannot create Web probe save fixture")
		quit(1)
		return
	output.store_string(JSON.stringify({"probe": "ok", "count": 1}))
	output.close()
	var input := FileAccess.open(PROBE_SAVE_PATH, FileAccess.READ)
	if input == null:
		push_error("Cannot read Web probe save fixture")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(input.get_as_text())
	if not (parsed is Dictionary and parsed.get("probe", "") == "ok" and int(parsed.get("count", 0)) == 1):
		push_error("Web probe save fixture mismatch")
		quit(1)
		return
	var ui_font := load(UI_FONT_PATH) as Font
	if ui_font == null or not ui_font.has_char(0x4FEE) or not ui_font.has_char(0x4ED9) or not ui_font.has_char(0x9053) or not ui_font.has_char(0x5468):
		push_error("Traditional Chinese UI font glyph fixture failed")
		quit(1)
		return
	print("PASS: project script, JSON serialization, user storage, and Traditional Chinese font glyphs are available.")
	quit(0)
