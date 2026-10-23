class_name LifeHistoryView
extends VBoxContainer
## Explicit, read-only history page. Selectors never issue game commands.
var life_selector: OptionButton
var resource_selector: OptionButton
var interval_selector: OptionButton
var comparison: Label
var coverage: Label
var scale_label: Label
var table: Label
var event_table: Label
var plot: LifeHistoryPlot
var report: LifeReportView
var accounts: ResourceAccountsView
var decisions: DecisionBookView
var _record := {}
var _life := {}
var _key := ""

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison = _label()
	life_selector = _selector()
	life_selector.item_selected.connect(func(_i): _select_life())
	coverage = _label()
	resource_selector = _selector()
	resource_selector.item_selected.connect(func(_i): _render())
	interval_selector = _selector()
	interval_selector.item_selected.connect(func(_i): _render())
	scale_label = _label()
	plot = LifeHistoryPlot.new()
	add_child(plot)
	table = _label()
	event_table = _label()
	report = LifeReportView.new()
	add_child(report)
	var detail := GameTab.new()
	detail.text = "封存帳目／抉擇"
	add_child(detail)
	accounts = ResourceAccountsView.new()
	add_child(accounts)
	decisions = DecisionBookView.new()
	add_child(decisions)
	accounts.hide()
	decisions.hide()
	detail.pressed.connect(func():
		accounts.visible = detail.button_pressed
		decisions.visible = detail.button_pressed)

func _label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UiTypography.body_font())
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	add_child(label)
	return label

func _selector() -> OptionButton:
	var control := OptionButton.new()
	control.custom_minimum_size.y = 44
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.fit_to_longest_item = false
	control.add_theme_font_override("font", UiTypography.body_font())
	control.add_theme_font_size_override("font_size", 16)
	control.get_popup().add_theme_font_override("font", UiTypography.body_font())
	control.get_popup().add_theme_font_size_override("font_size", 16)
	control.get_popup().add_theme_constant_override("v_separation", 28)
	UiMaterial.apply_button(control)
	add_child(control)
	return control

func show_record(record: Dictionary) -> void:
	# World time continues while reading. Never rebuild an open mouse menu.
	for control in [life_selector, resource_selector, interval_selector, accounts.selector]:
		if control.get_popup().visible: return
	var key := JSON.stringify(record, "", true)
	if _key == key: return
	_key = key
	_record = record
	var selected := int(life_selector.get_item_metadata(life_selector.selected)) if life_selector.selected >= 0 else 0
	life_selector.clear()
	comparison.text = "歷世比較 · 年歲（祀）／終點（境界、層）／已得道心／已得道證\n"
	var lives: Array = record.get("archive", []).duplicate()
	if record.has("current"): lives.append(record.current)
	for life in lives:
		var sealed: bool = not life.end_state.is_empty()
		life_selector.add_item("第 %d 世 · %s" % [int(life.life_id), "封存" if sealed else "當世"])
		life_selector.set_item_metadata(life_selector.item_count - 1, int(life.life_id))
		if int(life.life_id) == selected: life_selector.select(life_selector.item_count - 1)
		var reward: Dictionary = life.get("settlement", {})
		var ending: Dictionary = life.end_state
		comparison.text += "第%d世 · %.2f祀 · %s · %s道心 · %s道證 · %s\n" % [int(life.life_id), float(life.until) / 60, ("境%d／%d層" % [int(ending.era_id), int(ending.level)]) if sealed else "在世，未結算", str(reward.get("dao_heart", "未有紀錄")), str(reward.get("dao_proof", "未有紀錄")), "完整事實覆蓋" if life.coverage == "complete" else "部分事實覆蓋"]
	comparison.text += "各欄獨立計量；只列保留的九世與當世，不將跨世總持有當本世所得。"
	life_selector.visible = life_selector.item_count > 0
	if life_selector.item_count == 0:
		_life = {}
		resource_selector.clear()
		resource_selector.hide()
		interval_selector.clear()
		interval_selector.hide()
		coverage.text = "未有紀錄；缺資料不當作零。"
		plot.show_interval({"samples":[], "events":[]}, "", 0, 0)
		plot.hide()
		scale_label.text = "未有紀錄"
		table.text = "未有紀錄"
		event_table.text = "未有紀錄"
		report.show_report({}, "living")
		accounts.show_book({})
		decisions.show_book({})
		return
	if selected == 0: life_selector.select(life_selector.item_count - 1)
	_select_life()

func _select_life() -> void:
	var old_resource: Variant = resource_selector.get_item_metadata(resource_selector.selected) if resource_selector.selected >= 0 else ""
	var old_interval := maxi(0, interval_selector.selected)
	var id := int(life_selector.get_item_metadata(life_selector.selected))
	_life = _record.get("current", {})
	for life in _record.get("archive", []):
		if int(life.life_id) == id: _life = life
	resource_selector.clear()
	var keys := {}
	for sample in _life.get("history", {}).get("samples", []):
		for key in sample.rows: keys[key] = true
	for key in keys:
		resource_selector.add_item(str(ResourceAccountsView.SCOPES.get(key.get_slice(":", 0), "其他")) + " · " + ResourceAccountsView.Icon.get_resource_name(key.get_slice(":", 1)))
		resource_selector.set_item_metadata(resource_selector.item_count - 1, key)
		if key == old_resource: resource_selector.select(resource_selector.item_count - 1)
	resource_selector.visible = resource_selector.item_count > 0
	interval_selector.show()
	interval_selector.clear()
	interval_selector.add_item("全世年齡區間")
	interval_selector.set_item_metadata(0, [0.0, float(_life.until)])
	for i in 4:
		interval_selector.add_item("區間%d · %.2f–%.2f祀" % [i + 1, float(_life.until) * i / 240, float(_life.until) * (i + 1) / 240])
		interval_selector.set_item_metadata(i + 1, [float(_life.until) * i / 4, float(_life.until) * (i + 1) / 4])
	var samples: Array = _life.get("history", {}).get("samples", [])
	for i in range(1, samples.size()):
		var a := float(samples[i - 1].at)
		var b := float(samples[i].at)
		interval_selector.add_item("觀測區間%d · %.4f–%.4f祀" % [i, a / 60, b / 60])
		interval_selector.set_item_metadata(interval_selector.item_count - 1, [a, b])
	interval_selector.select(mini(old_interval, interval_selector.item_count - 1))
	var reason := str(_life.end_state.get("reason", "living"))
	report.show_report({"life": _life, "report": LifeReport.read(_life, reason)}, reason)
	accounts.show_book(_life.get("accounts", {}))
	decisions.show_book(_life.get("decisions", {}))
	_render()

func _render() -> void:
	var h: Dictionary = _life.get("history", {})
	coverage.text = "庫存／容量：未有紀錄；舊世不補造曲線。" if h.is_empty() else "庫存／容量觀測 · 自%.2f祀 · 保留%d點／略去%d項" % [float(h.started_at) / 60, h.samples.size(), int(h.omitted)]
	coverage.text += "\n原生時間邊界每60秒採樣、成功命令與轉世補終點；跨越邊界只留實際端點。同齡多次變更留最後值；最多12種島別資源。空隙未知，不代表期間不變。"
	var start := 0.0
	var finish := float(_life.until)
	if interval_selector.selected >= 0:
		var bounds: Array = interval_selector.get_item_metadata(interval_selector.selected)
		start = float(bounds[0])
		finish = float(bounds[1])
	var data := LifeHistory.interval(_life, start, finish)
	var key := str(resource_selector.get_item_metadata(resource_selector.selected)) if resource_selector.selected >= 0 else ""
	plot.show_interval(data, key, start, finish)
	scale_label.text = "同齡軸 %.2f–%.2f祀 · Y 0–%s（同資源數量）\n圓點庫存／方框容量／下方刻線事件。線性相對尺度；跨量級極小值以底線標示，精確值讀下表。無連線，不推定滿倉區間或事件因果。" % [start / 60, finish / 60, ResourceLedger.encode(plot.maximum)]
	table.text = "觀測數值表 · 年齡（祀）／庫存／當時總容量\n"
	var found := false
	for sample in data.samples:
		if not sample.rows.has(key): continue
		found = true
		var row: Array = sample.rows[key]
		table.text += "%.4f · %s · %s\n" % [float(sample.at) / 60, row[0], str(row[1]) if row[1] != null else "未有紀錄"]
	plot.visible = found
	if not found:
		scale_label.text = "此區間未有此資源觀測，數量尺度未建立。"
		table.text += "此區間未有此資源觀測；不補零、不借鄰點。\n"
	table.text += "總容量非扣除預留後可用量；島間不合併。此表不是收入／產率，收支見封存帳目。"
	event_table.text = "同齡事件精查（閉區間；邊界事件可能在相鄰兩區可讀）\n"
	for event in data.events:
		event_table.text += "%.4f祀 · #%d · %s · 境%d／%d層 · %s\n" % [float(event.at) / 60, int(event.seq), LifeReportView._event_name(event.kind), int(event.era_id), int(event.level), LifeReportView._subject_name(event.subject)]
	for receipt in data.decisions:
		event_table.text += "%.4f祀 · 機緣收據 · %s\n" % [float(receipt.at) / 60, receipt.get("title", "")]
	if data.events.is_empty() and data.decisions.is_empty(): event_table.text += "此區間未有保留事件，不推論從未發生。"

func set_compact(compact: bool) -> void:
	if plot != null: plot.custom_minimum_size.y = 72 if compact else 144
