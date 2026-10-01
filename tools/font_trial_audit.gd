extends SceneTree
## Offline font coverage and metric evidence; not a browser/performance benchmark.
var _chars: Dictionary = {}

func _init() -> void:
	var sans := load("res://assets/fonts/SourceHanSansTW-VF.ttf") as FontFile
	var serif := load("res://assets/fonts/NotoSerifTC-VF.ttf") as FontFile
	sans.allow_system_fallback = false
	serif.allow_system_fallback = false
	_scan("res://src")
	_scan("res://content")
	var missing_cjk: Array[String] = []
	var missing_symbols: Array[String] = []
	var cjk_count := 0
	for code: int in _chars:
		var cjk := (code >= 0x3400 and code <= 0x9fff) or (code >= 0x20000 and code <= 0x323af)
		if cjk:
			cjk_count += 1
		if not sans.has_char(code):
			var item := "%s U+%04X" % [String.chr(code), code]
			if cjk: missing_cjk.append(item)
			else: missing_symbols.append(item)
	missing_cjk.sort()
	missing_symbols.sort()
	var old := FontVariation.new()
	old.base_font = serif
	old.variation_opentype = {UiTypography.WEIGHT_AXIS: 600}
	var trial := FontVariation.new()
	trial.base_font = sans
	trial.variation_opentype = {UiTypography.WEIGHT_AXIS: 400}
	var metrics: Array = []
	for size in [15, 17, 20]:
		for sample in ["境界：練氣期 · 6/10 層", "修煉 32/121 秒 · 壽元 58/88 祀", "系統訊息 · 新手引導", "0123456789 +1.25/s"]:
			metrics.append({"size": size, "sample": sample, "serif_width": old.get_string_size(sample, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, "sans_width": trial.get_string_size(sample, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, "serif_height": old.get_height(size), "sans_height": trial.get_height(size)})
	var report := {"font": sans.get_font_name(), "axes": sans.get_supported_variation_list(), "serif_name": serif.get_font_name(), "serif_axes": serif.get_supported_variation_list(), "serif_metadata": serif.get_ot_name_strings(), "source_corpus_includes_comments": true, "cjk_unique_count": cjk_count, "missing_cjk": missing_cjk, "missing_non_cjk": missing_symbols, "metrics": metrics}
	var text_server := TextServerManager.get_primary_interface()
	report["resolved_body_axis"] = text_server.font_get_variation_coordinates(UiTypography.body_font().get_rids()[0])
	report["resolved_emphasis_axis"] = text_server.font_get_variation_coordinates(UiTypography.emphasis_font().get_rids()[0])
	report["resolved_chapter_axis"] = text_server.font_get_variation_coordinates(UiTypography.chapter_font().get_rids()[0])
	var dir := "res://docs/verification/artifacts/ui-mixed" if OS.get_cmdline_user_args().has("--mixed-font") else "res://docs/verification/artifacts/ui-sans"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var file := FileAccess.open(dir + "/font-audit.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	var weights_ok: bool = report.resolved_body_axis.get(UiTypography.WEIGHT_AXIS, 0) == 400 and report.resolved_emphasis_axis.get(UiTypography.WEIGHT_AXIS, 0) == 600 and report.resolved_chapter_axis.get(UiTypography.WEIGHT_AXIS, 0) == 800
	quit(0 if missing_cjk.is_empty() and weights_ok else 1)

func _scan(path: String) -> void:
	for dir in DirAccess.get_directories_at(path):
		_scan(path + "/" + dir)
	for file in DirAccess.get_files_at(path):
		if file.get_extension() not in ["gd", "json"]:
			continue
		var text := FileAccess.get_file_as_string(path + "/" + file)
		for i in text.length():
			var code := text.unicode_at(i)
			if code >= 0x80:
				_chars[code] = true
