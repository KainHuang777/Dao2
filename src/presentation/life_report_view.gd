class_name LifeReportView
extends VBoxContainer
## Only reads the explicit session report API; no archive copies in the HUD view.
var title: Label
var seal: Label
var closing: Label
var biography: Label
var coverage: Label
var traces: Label
var sources: Label
var echoes: Label
var records_button: Button
var _key := ""
var _heading: BoxContainer

func _label(font: Font, pixels: int) -> Label:
	var node := Label.new()
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", pixels)
	node.add_theme_color_override("font_color", UiMaterial.INK)
	add_child(node)
	return node

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	seal = _label(UiTypography.epilogue_seal_font(), 18)
	seal.add_theme_color_override("font_color", Color("9b3e30"))
	_heading = BoxContainer.new()
	_heading.vertical = true
	_heading.add_theme_constant_override("separation", 8)
	add_child(_heading)
	title = _label(UiTypography.epilogue_title_font(), 32)
	title.reparent(_heading)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	closing = _label(UiTypography.biography_font(), 22)
	closing.reparent(_heading)
	closing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	biography = _label(UiTypography.biography_font(), 18)
	biography.add_theme_constant_override("line_spacing", 8)
	echoes = _label(UiTypography.biography_font(), 18)
	echoes.add_theme_constant_override("line_spacing", 8)
	coverage = _label(UiTypography.body_font(), 16)
	coverage.add_theme_color_override("font_color", Color("756750"))
	records_button = InscriptionAction.new()
	records_button.text = "查記錄"
	records_button.custom_minimum_size.y = 44
	records_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(records_button)
	records_button.pressed.connect(func(): sources.visible = not sources.visible)
	sources = _label(UiTypography.body_font(), 16)
	sources.hide()
	traces = _label(UiTypography.body_font(), 16)

func set_compact(compact: bool) -> void:
	if title == null: return
	add_theme_constant_override("separation", 6 if compact else 12)
	seal.visible = not compact
	_heading.vertical = not compact
	title.add_theme_font_size_override("font_size", 24 if compact else 32)
	closing.add_theme_font_size_override("font_size", 18 if compact else 22)

func show_report(data: Dictionary, reason: String) -> void:
	if title == null: return
	var key := JSON.stringify(data, "", true) + reason
	if key == _key: return
	_key = key
	var life: Dictionary = data.get("life", {})
	var report: Dictionary = data.get("report", {})
	seal.text = "一世卷末" if reason == "lifespan_exhausted" else ("此世暫結預覽" if reason == "rebirth_lotus" else "此世行跡")
	title.text = report.get("title", "此世行跡")
	closing.text = report.get("closing", "行跡仍在續寫。")
	var start := float(life.get("started_at", 0))
	var until := float(life.get("until", 0))
	coverage.text = "本版里程碑覆蓋：%s · 記錄年歲 %.1f～%.1f · 略去 %d 件" % ["完整" if life.get("coverage") == "complete" else "部分", start / 60.0, until / 60.0, int(life.get("omitted_count", 0))]
	coverage.tooltip_text = "完整僅指本版支援的里程碑觀測；不代表完整人生或資源帳目。舊檔從導入年歲起記錄，缺紀錄不等於沒有發生。"
	if life.is_empty(): coverage.text = "缺紀錄：本世尚無可讀取的里程碑資料。"
	biography.text = ""
	sources.text = "題名依據與逐句來源（本世事件序號）\n"
	for sentence in report.get("sentences", []):
		biography.text += String(sentence.text)
		sources.text += String(sentence.text) + " → " + str(sentence.refs) + "\n"
	echoes.text = ""
	for echo in report.get("echoes", []):
		echoes.text += "回聲 · %s\n%s\n" % [echo.title, echo.text]
		sources.text += "回聲 · " + str(echo.title) + "（先後留痕，不推定收益因果）\n"
		for source in echo.sources:
			sources.text += "%.2f祀 · %s · 來源 %s\n" % [float(source.at) / 60.0, source.label, source.id]
	echoes.visible = not echoes.text.is_empty()
	var by_sequence := {}
	for event in life.get("events", []): by_sequence[int(event.seq)] = event
	traces.text = "此世留痕"
	for sequence in report.get("traces", []):
		if by_sequence.has(int(sequence)):
			var event: Dictionary = by_sequence[int(sequence)]
			traces.text += "\n#%d · %s %s" % [int(sequence), _event_name(String(event.kind)), _subject_name(String(event.subject))]
	if report.get("traces", []).is_empty(): traces.text += "\n尚無可列留痕，不補造事件。"
	for event in life.get("events", []):
		sources.text += "#%d · %.1f歲 · %s %s\n" % [int(event.seq), float(event.at) / 60.0, _event_name(String(event.kind)), _subject_name(String(event.subject))]
	sources.tooltip_text = "life_id=" + str(life.get("life_id", "missing")) + "；每個序號只在本世記錄內解讀。"

static func _event_name(kind: String) -> String:
	return {"building_built":"建築落成", "island_opened":"空島開拓", "cargo_arrived":"航船到貨", "era_breakthrough":"突破境界", "cultivation_leveled_up":"修行晉階", "tribulation_failed":"渡劫受挫", "tribulation_passed":"渡劫成功", "beast_acquired":"取得靈獸", "beast_matured":"靈獸成熟", "joined_sect":"加入宗門", "expedition_completed":"委託完成", "expedition_claimed":"委託領取", "lifespan_exhausted":"壽元已盡", "pill_refined":"丹藥煉成", "skill_learned":"研習技能"}.get(kind, kind)

static func _subject_name(subject: String) -> String:
	return {"hut":"茅屋", "herb_farm":"靈草圃", "wood":"青木島", "ore":"玄礦島", "2:3":"築基 → 金丹"}.get(subject, "")
