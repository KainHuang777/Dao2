class_name ResourceAccountsView
extends VBoxContainer
## Exact Amount text is authoritative; bars show relative order of magnitude only.
const Icon = preload("res://src/presentation/resource_icon.gd")
const NAMES := {"production":"生產", "gather":"採集", "building":"營造", "cultivation":"修行", "alchemy":"煉丹／服用", "fortune":"機緣", "decision":"法令", "sect":"宗門", "beast":"靈獸", "achievement":"成就", "scenery":"小景", "skill":"研習", "processing":"加工／設施", "transfer":"內部移轉", "realm":"靈界", "adjustment":"調整"}
const SCOPES := {"home":"祖島", "wood":"青木島", "ore":"玄礦島", "herb":"丹霞島", "deep":"寒銀島", "ancient":"古藥島", "void":"太虛島", "realm_spirit":"靈界", "transit":"在途"}
var selector: OptionButton
var copy: Label
var coverage: Label
var incoming: ProgressBar
var outgoing: ProgressBar
var _book := {}
var _key := ""

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coverage = _label()
	selector = OptionButton.new()
	selector.custom_minimum_size.y = 44
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_theme_font_override("font", UiTypography.body_font())
	selector.add_theme_font_size_override("font_size", 16)
	UiMaterial.apply_button(selector)
	selector.get_popup().add_theme_font_override("font", UiTypography.body_font())
	selector.get_popup().add_theme_font_size_override("font_size", 16)
	selector.get_popup().add_theme_constant_override("v_separation", 28)
	add_child(selector)
	selector.item_selected.connect(func(_index): _render())
	incoming = _bar("實際收入（相對量級）")
	outgoing = _bar("已付支出（相對量級）")
	copy = _label()

func _label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UiTypography.body_font())
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	add_child(label)
	return label

func _bar(caption: String) -> ProgressBar:
	_label().text = caption
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 12
	bar.max_value = 1
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	return bar

func show_book(book: Dictionary) -> void:
	var key := JSON.stringify(book, "", true)
	if key == _key: return
	_key = key
	var selected: Variant = selector.get_item_metadata(selector.selected) if selector.selected >= 0 else ""
	_book = book
	selector.clear()
	var ids := {}
	for row_key in book.get("rows", {}): ids[row_key.get_slice(":", 1)] = true
	for id in ids:
		selector.add_item("全域 · " + Icon.get_resource_name(id))
		selector.set_item_metadata(selector.item_count - 1, "all:" + id)
	for row_key in book.get("rows", {}):
		selector.add_item(str(SCOPES.get(row_key.get_slice(":", 0), "其他")) + " · " + Icon.get_resource_name(row_key.get_slice(":", 1)))
		selector.set_item_metadata(selector.item_count - 1, row_key)
	for index in selector.item_count:
		if selector.get_item_metadata(index) == selected: selector.select(index)
	_render()

static func total(values: Dictionary, include_transfers: bool = true) -> AmountCompat:
	var result := AmountCompat.zero()
	for category in values:
		if include_transfers or category != "transfer": result = result.add(ResourceLedger.amount(values[category]))
	return result

static func ratio(value: AmountCompat, maximum: AmountCompat) -> float:
	if value.sign <= 0 or maximum.sign <= 0: return 0
	if value.compare_to(maximum) >= 0: return 1
	if value.layer == 0 and maximum.layer == 0: return clampf(value.mag / maximum.mag, 0, 1)
	if value.layer == 1 and maximum.layer == 1: return clampf(pow(10, maxf(-6, value.mag - maximum.mag)), 0, 1)
	# Avoid converting huge Amounts to float. A hairline denotes a smaller scale.
	return 0.001

func _render() -> void:
	selector.visible = not _book.is_empty() and selector.item_count > 0
	incoming.visible = selector.visible
	outgoing.visible = selector.visible
	if _book.is_empty():
		coverage.text = "帳目：未有紀錄；舊收支不補造為零。"
		copy.text = "一般資源、各島庫存、在途與靈界資源按實際寫入記錄。丹藥（築基丹庫存鏡像除外）、道心、道證、宗門貢獻與獸魂不屬本資源帳；請閱原系統與抉擇收據。"
		return
	coverage.text = "資源帳目 · %s · 自 %.1f 祀起 · 略去 %d 筆" % ["完整覆蓋" if _book.coverage == "complete" else "部分覆蓋", float(_book.started_at) / 60, int(_book.omitted)]
	if selector.selected < 0:
		copy.text = "此區間未有可讀資源列。"
		return
	var key: String = selector.get_item_metadata(selector.selected)
	var global := key.begins_with("all:")
	var id := key.get_slice(":", 1)
	var merged := {"opening":"0", "closing":"0", "income":{}, "expense":{}, "adjustment":"0", "overflow":"0"}
	for row_key in _book.rows:
		if (global and row_key.get_slice(":", 1) == id) or row_key == key:
			var row: Dictionary = _book.rows[row_key]
			for field in ["opening", "closing", "adjustment", "overflow"]:
				merged[field] = ResourceLedger.encode(ResourceLedger.amount(merged[field]).add(ResourceLedger.amount(row[field])))
			for field in ["income", "expense"]:
				for category in row[field]:
					if global and category == "transfer": continue
					merged[field][category] = ResourceLedger.encode(ResourceLedger.amount(merged[field].get(category, "0")).add(ResourceLedger.amount(row[field][category])))
	var income := total(merged.income)
	var expense := total(merged.expense)
	var maximum := income if income.compare_to(expense) >= 0 else expense
	incoming.value = ratio(income, maximum)
	outgoing.value = ratio(expense, maximum)
	var expected := ResourceLedger.amount(merged.opening).add(income).subtract(expense).add(ResourceLedger.amount(merged.adjustment))
	copy.text = "期初 %s\n實際收入 %s\n已付支出 %s\n有號調整 %s\n期末 %s\n未入庫 %s（不再扣一次）\n對帳：%s" % [merged.opening, ResourceLedger.encode(income), ResourceLedger.encode(expense), merged.adjustment, merged.closing, merged.overflow, "相符（Amount 精度內）" if expected.compare_to(ResourceLedger.amount(merged.closing)) == 0 else "存在精度差異／缺漏"]
	for field in ["income", "expense"]:
		for category in merged[field]:
			copy.text += "\n%s · %s：%s" % ["收入" if field == "income" else "支出", NAMES.get(category, "其他"), merged[field][category]]
	copy.text += "\n本表僅加總已保留的記錄，缺漏不當作零。全域包含在途，移轉抵銷；各資源獨立計量。條僅供同資源量級比較，精確數值以本表為準。未入庫可能含容量或 Amount 精度，不能單憑此判斷瓶頸。"

