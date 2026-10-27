class_name DecisionBookView
extends VBoxContainer
const Icon = preload("res://src/presentation/resource_icon.gd")
var copy: Label
var _key := ""

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy = Label.new()
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_override("font", UiTypography.body_font())
	copy.add_theme_font_size_override("font_size", 16)
	copy.add_theme_color_override("font_color", UiMaterial.INK)
	add_child(copy)

func show_book(book: Dictionary, latest_only: bool = false) -> void:
	var key := JSON.stringify(book, "", true) + str(latest_only)
	if key == _key: return
	_key = key
	if book.is_empty():
		copy.text = "抉擇簿：未有紀錄；舊機緣不補造實得。"
		return
	var lines: Array[String] = ["抉擇簿 · 自 %.1f 祀起記錄 · 略去 %d 件" % [float(book.started_at) / 60.0, int(book.omitted)]]
	var receipts: Array = book.get("receipts", [])
	if receipts.is_empty(): lines.append("此記錄區間尚無已記錄的抉擇。")
	var ordered := receipts.duplicate()
	ordered.reverse()
	if latest_only and ordered.size() > 1: ordered.resize(1)
	for r in ordered: lines.append(receipt_text(r))
	copy.text = "\n\n".join(lines)

static func amount(raw: String) -> String:
	var parsed := AmountCompat.try_parse(raw)
	return parsed.value.to_display_string() if parsed.ok else "未記錄"

static func receipt_text(r: Dictionary) -> String:
	var lines: Array[String] = ["第 %d 世 · %.1f 祀 · %s\n所選：%s\n%s" % [int(r.life_id), float(r.at) / 60.0, r.title, r.option, r.log]]
	for id in r.resources:
		var row: Dictionary = r.resources[id]
		lines.append("%s：已付 %s · 實得 %s · 未入庫 %s\n當次餘量 %s → %s（標稱 %s）" % [Icon.get_resource_name(id), amount(row.paid), amount(row.gained), amount(row.overflow), amount(row.before), amount(row.after), amount(row.nominal)])
	if float(r.training.get("nominal", r.training.gained)) > 0:
		lines.append("修煉：標稱 %s 秒 · 實增 %s 秒 · 捨棄 %s 秒\n當次 %s → %s 秒" % [str(r.training.get("nominal", r.training.gained)), str(r.training.gained), str(r.training.get("overflow", 0)), str(r.training.before), str(r.training.after)])
	for id in r.pills:
		var def: Dictionary = AlchemySystem.PILLS.get(id, {})
		var row: Dictionary = r.pills[id]
		lines.append("%s：實得 %d · 當次 %d → %d" % [str(def.get("name", id)), int(row.gained), int(row.before), int(row.after)])
	if not r.buff.is_empty():
		var def: Variant = BuffSystem.get_definition(r.buff.id)
		var name := str(def.get("name", r.buff.id)) if def is Dictionary else str(r.buff.id)
		lines.append("%s：已套用 · %s" % [name, "當世常駐" if r.buff.permanent else "剩餘 %s → %s 秒（刷新不疊加）" % [str(r.buff.before), str(r.buff.after)]])
	lines.append("資源依原機緣規則入庫；收據不代表目前庫存。")
	return "\n".join(lines)

static func preview_text(rewards: Dictionary) -> String:
	var lines: Array[String] = []
	for raw in rewards.get("resources", {}):
		var id := FortuneSystem.resource_key({"spirit_grass_low": {}, "lingli": {}}, str(raw))
		lines.append("%s +%s" % [Icon.get_resource_name(id), str(rewards.resources[raw])])
	if float(rewards.get("training_seconds", 0)) > 0: lines.append("修煉 +%s 秒" % str(rewards.training_seconds))
	for id in rewards.get("pills", {}): lines.append("%s +%s" % [str(AlchemySystem.PILLS.get(id, {}).get("name", id)), str(rewards.pills[id])])
	var buff := str(rewards.get("buff_id", ""))
	if not buff.is_empty():
		var def: Variant = BuffSystem.get_definition(buff)
		lines.append(str(def.get("name", buff)) if def is Dictionary else buff)
	return "固定效果：" + (" · ".join(lines) if not lines.is_empty() else "以選後結果為準")
