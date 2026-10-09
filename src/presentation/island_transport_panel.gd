extends "res://src/presentation/island_management_panel.gd"
## Reusable route rows and presentation-only drafts; all writes are commands.
const MaterialTile = preload("res://src/presentation/recipe_material_tile.gd")
var route_widgets := {}
var grid: GridContainer
var route_summary: Label
var short_layout := false
var detail_visual: Dictionary
var detail_progress: ProgressBar
var detail_toggle: Button
var policy_fields: GridContainer
var filter_picker: OptionButton
var selected_route := ""
var drafts := {}
var list_box: VBoxContainer
var detail_box: VBoxContainer
var draft_notice: Label
var detail_title: Label
var detail_stock: Label
var detail_status: Label
var draft_status: Label
var reserve: LineEdit
var target: LineEdit
var save_button: Button
var upgrade_button: Button
var supply_button: Button
var back_button: Button
var list_scroll := 0
var _loading_fields := false
signal manufacturing_requested(island_id: String, recipe_id: String)

func _ready() -> void:
	super._ready()
	filter_picker = OptionButton.new()
	filter_picker.custom_minimum_size = Vector2(112, 44)
	for text in ["全部航線", "青木島", "玄礦島", "丹霞島"]:
		filter_picker.add_item(text)
	filter_picker.item_selected.connect(func(index: int): select_island(["home", "wood", "ore", "herb"][index]))
	heading_label.get_parent().add_child(filter_picker)
	heading_label.get_parent().move_child(filter_picker, 1)
	back_button = _add_button(heading_label.get_parent(), "返回航線", back_to_list)
	back_button.visible = false

func _rebuild() -> void:
	if body == null:
		return
	_clear_body()
	route_widgets.clear()
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	body.add_child(list_box)
	draft_notice = _label("")
	list_box.add_child(draft_notice)
	route_summary = _label("")
	list_box.add_child(route_summary)
	grid = GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	list_box.add_child(grid)
	for id in IslandEconomy.ROUTES:
		var row := PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
		grid.add_child(row)
		var content := BoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		row.add_child(content)
		var visual := _create_visual(content)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.custom_minimum_size.x = 156
		content.add_child(text)
		var title := _label(_resource_name(IslandEconomy.ROUTES[id][2]))
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_font_override("font", UiTypography.emphasis_font())
		text.add_child(title)
		var status := _label("")
		text.add_child(status)
		var progress := _progress(text)
		var policy := _label("")
		policy.visible = false
		text.add_child(policy)
		var actions := HBoxContainer.new()
		text.add_child(actions)
		var toggle := _add_button(actions, "啟航", func(): _toggle(id))
		toggle.custom_minimum_size.x = 64
		var settings := _add_button(actions, "設定", func(): select_route(id))
		settings.custom_minimum_size.x = 64
		route_widgets[id] = {"root": row, "title": title, "status": status, "policy": policy, "toggle": toggle, "settings": settings, "visual": visual, "progress": progress}
	detail_box = VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 10)
	detail_box.visible = false
	body.add_child(detail_box)
	detail_title = _label("")
	detail_box.add_child(detail_title)
	detail_visual = _create_visual(detail_box)
	detail_status = _label("")
	detail_box.add_child(detail_status)
	detail_progress = _progress(detail_box)
	detail_toggle = _add_button(detail_box, "啟航", func(): _toggle(selected_route))
	detail_stock = _label("")
	detail_box.add_child(detail_stock)
	policy_fields = GridContainer.new()
	policy_fields.add_theme_constant_override("h_separation", 12)
	policy_fields.add_theme_constant_override("v_separation", 8)
	detail_box.add_child(policy_fields)
	var reserve_box := VBoxContainer.new()
	reserve_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	policy_fields.add_child(reserve_box)
	reserve_box.add_child(_label("來源保留量"))
	reserve = _field()
	reserve.tooltip_text = "留在來源島的可用庫存"
	reserve_box.add_child(reserve)
	var target_box := VBoxContainer.new()
	target_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	policy_fields.add_child(target_box)
	target_box.add_child(_label("目的目標庫存"))
	target = _field()
	target.tooltip_text = "目的島可用庫存＋容量預留（在途貨物與加工產物）"
	target_box.add_child(target)
	for field in [reserve, target]:
		field.text_changed.connect(func(_text: String): _edit_draft())
	draft_status = _label("")
	detail_box.add_child(draft_status)
	save_button = _add_button(detail_box, "保存設定・保留啟停狀態", _save_settings)
	upgrade_button = _add_button(detail_box, "", _upgrade)
	supply_button = _add_button(detail_box, "", _open_supply)
	var endpoints := HFlowContainer.new()
	detail_box.add_child(endpoints)
	_add_button(endpoints, "來源島", func(): page_requested.emit("outposts", IslandEconomy.ROUTES[selected_route][0]))
	_add_button(endpoints, "目的島", func(): page_requested.emit("outposts", IslandEconomy.ROUTES[selected_route][1]))

func _create_visual(parent: Node) -> Dictionary:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var source := MaterialTile.new()
	row.add_child(source)
	var arrow := _label("→")
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 24)
	row.add_child(arrow)
	var destination := MaterialTile.new()
	row.add_child(destination)
	return {"root": row, "source": source, "destination": destination, "arrow": arrow}

func _progress(parent: Node) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 8
	parent.add_child(progress)
	return progress

func _quantity(value: float) -> String:
	if value >= 1000000:
		return "%.1e" % value
	if value >= 10000:
		return "%.1f萬" % (value / 10000.0)
	return str(int(value)) if value == floorf(value) else "%.1f" % value

func _refresh_visual(visual: Dictionary, id: String) -> void:
	var def: Array = IslandEconomy.ROUTES[id]
	var info := _info(id)
	var stock: Dictionary = info.get("stock", {})
	var settings := _settings(id)
	var resource: String = def[2]
	var name_text := _resource_name(resource)
	var source_name: String = IslandProgression.NAMES[def[0]]
	var destination_name: String = IslandProgression.NAMES[def[1]]
	var source := float(stock.get("source", 0))
	var destination := float(stock.get("destination", 0))
	visual.source.refresh(resource, name_text, source, source, source_name)
	visual.destination.refresh(resource, name_text, destination, destination, destination_name, true)
	visual.destination.caption.text = destination_name
	visual.source.quantity.text = "—" if stock.is_empty() else _quantity(source)
	visual.destination.quantity.text = "—" if stock.is_empty() else _quantity(destination)
	var missing: bool = info.get("reason") == "NO_SURPLUS"
	if missing:
		visual.source.shortage = true
		visual.source.style.bg_color = Color("f0ddd0")
		visual.source.style.border_color = Color("ad6552")
		visual.source.quantity.add_theme_color_override("font_color", MaterialTile.SHORTAGE)
		visual.source.caption.add_theme_color_override("font_color", MaterialTile.SHORTAGE)
	visual.source.tooltip_text = "%s・%s\n可用 %s・保留 %s\n保留後餘貨 %s" % [source_name, name_text, str(source), settings.reserve, str(stock.get("surplus", 0))] if not stock.is_empty() else source_name + "・" + name_text + "\n端點未開拓或空島未啟用"
	visual.destination.tooltip_text = "%s・%s\n可用 %s・目標 %s\n容量預留 %s・剩餘空間 %s" % [destination_name, name_text, str(destination), settings.target, str(stock.get("reserved", 0)), str(stock.get("space", 0))] if not stock.is_empty() else destination_name + "・" + name_text + "\n端點未開拓或空島未啟用"

func _refresh_progress(progress: ProgressBar, info: Dictionary) -> void:
	var trip: Dictionary = info.get("trip", {})
	progress.visible = not trip.is_empty()
	progress.value = (10.0 - float(trip.get("remaining", 10))) * 10.0
	progress.tooltip_text = "當趟運送・%d秒後到達" % int(trip.get("remaining", 0))

func _field() -> LineEdit:
	var field := LineEdit.new()
	field.custom_minimum_size.y = 44
	field.placeholder_text = "非負數，可輸入小數"
	field.add_theme_font_size_override("font_size", 18)
	return field

func _route_title(id: String) -> String:
	var def: Array = IslandEconomy.ROUTES[id]
	return "%s・%s→%s" % [_resource_name(def[2]), IslandProgression.NAMES[def[0]], IslandProgression.NAMES[def[1]]]

func _info(id: String) -> Dictionary:
	return _view.get("transport", {}).get(id, {})

func _settings(id: String) -> Dictionary:
	return _info(id).get("settings", {"enabled": false, "reserve": "0", "target": "100", "level": 1})

func _draft(id: String) -> Dictionary:
	var settings := _settings(id)
	if not drafts.has(id) or not bool(drafts[id].dirty):
		drafts[id] = {"reserve": String(settings.reserve), "target": String(settings.target), "dirty": false}
	elif String(drafts[id].reserve) == String(settings.reserve) and String(drafts[id].target) == String(settings.target):
		drafts[id].dirty = false
	return drafts[id]

func _edit_draft() -> void:
	if _loading_fields or selected_route.is_empty():
		return
	var settings := _settings(selected_route)
	drafts[selected_route] = {"reserve": reserve.text, "target": target.text, "dirty": reserve.text != String(settings.reserve) or target.text != String(settings.target)}
	_refresh_detail()

func _command(id: String, enabled: bool, level: int, policy: Dictionary) -> void:
	action_requested.emit("configure_route", {"route_id": id, "enabled": enabled, "reserve": String(policy.reserve), "target": String(policy.target), "level": level})

func _toggle(id: String) -> void:
	var settings := _settings(id)
	# Toggle/upgrade always use committed policy, never silently submit a draft.
	_command(id, not bool(settings.enabled), int(settings.level), settings)

func _upgrade() -> void:
	var settings := _settings(selected_route)
	_command(selected_route, bool(settings.enabled), 2, settings)

func _save_settings() -> void:
	_edit_draft()
	var settings := _settings(selected_route)
	_command(selected_route, bool(settings.enabled), int(settings.level), _draft(selected_route))

func select_route(id: String) -> void:
	if not route_widgets.has(id):
		return
	if selected_route.is_empty():
		list_scroll = body.get_parent().scroll_vertical
	selected_route = id
	var draft := _draft(id)
	_loading_fields = true
	reserve.text = String(draft.reserve)
	target.text = String(draft.target)
	_loading_fields = false
	list_box.visible = false
	detail_box.visible = true
	back_button.visible = true
	filter_picker.visible = false
	body.get_parent().scroll_vertical = 0
	_refresh_detail()

func back_to_list() -> void:
	selected_route = ""
	detail_box.visible = false
	list_box.visible = true
	if back_button != null:
		back_button.visible = false
	if filter_picker != null:
		filter_picker.visible = true
	body.get_parent().set_deferred("scroll_vertical", list_scroll)
	_refresh_rows()

func select_island(id: String) -> void:
	if not IslandProgression.NAMES.has(id):
		return
	island = id
	if not selected_route.is_empty():
		back_to_list()
	_refresh_rows()

func reset_context() -> void:
	select_island("home")

func refresh(view: Dictionary, catalog: Dictionary) -> void:
	_view = view
	_catalog = catalog
	if body == null:
		return
	heading_label.text = "島間運輸"
	_layout_feedback()
	_refresh_rows()
	if not selected_route.is_empty():
		var draft := _draft(selected_route)
		if not bool(draft.dirty):
			_loading_fields = true
			reserve.text = String(draft.reserve)
			target.text = String(draft.target)
			_loading_fields = false
		_refresh_detail()

func _status_text(info: Dictionary) -> String:
	var settings: Dictionary = info.get("settings", {})
	var text: String = {"ECONOMY_NOT_MIGRATED": "先啟用空島", "ISLAND_NOT_OPEN": "端點未開拓", "STOPPED": "停航", "DESTINATION_FULL": "目的倉滿", "TARGET_REACHED": "已達目標庫存", "NO_SURPLUS": "來源無餘貨", "READY": "等待下次出航", "IN_TRANSIT": "運送中"}.get(info.get("reason", ""), "等待資料")
	var trip: Dictionary = info.get("trip", {})
	if not trip.is_empty():
		text = "載貨%s・%d秒後到達" % [trip.cargo, int(trip.remaining)]
		if not bool(settings.get("enabled", false)):
			text += "・停止新出航；當趟仍會到貨"
	if bool(info.get("loaded_backlog", false)):
		text += "・本趟滿載，來源仍有餘貨"
	return text

func _refresh_rows() -> void:
	if list_box == null:
		return
	var dirty_count := 0
	var enabled_count := 0
	var trip_count := 0
	for id in route_widgets:
		var widget: Dictionary = route_widgets[id]
		var def: Array = IslandEconomy.ROUTES[id]
		widget.root.visible = island == "home" or island in [def[0], def[1]]
		widget.title.text = _resource_name(def[2])
		var info := _info(id)
		var settings := _settings(id)
		_refresh_visual(widget.visual, id)
		_refresh_progress(widget.progress, info)
		if bool(settings.enabled):
			enabled_count += 1
		if not info.get("trip", {}).is_empty():
			trip_count += 1
		widget.status.text = _status_text(info)
		widget.status.add_theme_color_override("font_color", MaterialTile.SHORTAGE if info.get("reason") in ["NO_SURPLUS", "DESTINATION_FULL"] else UiMaterial.INK)
		widget.policy.text = "運力%d／10秒・保留%s／目標%s" % [10 * int(settings.level), settings.reserve, settings.target]
		if bool(_draft(id).dirty):
			dirty_count += 1
			widget.policy.text += "・未保存草稿"
			widget.title.text += "・草稿"
		widget.toggle.text = "停航" if bool(settings.enabled) else "啟航"
		widget.toggle.tooltip_text = "停止新出航；當趟仍會到貨" if bool(settings.enabled) else "沿用已保存設定啟航"
		widget.toggle.disabled = not bool(info.get("ready", false))
		UiMaterial.mark_selected(widget.toggle, bool(settings.enabled))
		widget.settings.tooltip_text = _route_title(id) + "\n" + widget.policy.text
		# Closed endpoints remain inspectable and have an opening shortcut.
		widget.settings.disabled = false
	draft_notice.text = "%d條未保存草稿已保留；返回設定後保存才會生效。" % dirty_count
	draft_notice.visible = dirty_count > 0 and not short_layout
	route_summary.text = "啟航%d／7・在途%d・物品格為兩端可用庫存" % [enabled_count, trip_count]
	if filter_picker != null:
		filter_picker.select(["home", "wood", "ore", "herb"].find(island))
		filter_picker.tooltip_text = draft_notice.text if dirty_count > 0 else "依來源或目的空島篩選航線"

func _refresh_detail() -> void:
	var info := _info(selected_route)
	var settings := _settings(selected_route)
	detail_title.text = _route_title(selected_route)
	_refresh_visual(detail_visual, selected_route)
	_refresh_progress(detail_progress, info)
	detail_status.text = _status_text(info)
	detail_toggle.text = "停航" if bool(settings.enabled) else "啟航"
	detail_toggle.tooltip_text = "停止新出航；當趟仍會到貨" if bool(settings.enabled) else "沿用已保存設定啟航"
	detail_toggle.disabled = not bool(info.get("ready", false))
	UiMaterial.mark_selected(detail_toggle, bool(settings.enabled))
	var stock: Dictionary = info.get("stock", {})
	detail_stock.text = ""
	if not stock.is_empty():
		detail_stock.text = "餘貨 %s・目的容量預留 %s／空間 %s\n運力%d／10秒・已保存保留%s／目標%s" % [str(stock.surplus), str(stock.reserved), str(stock.space), 10 * int(settings.level), settings.reserve, settings.target]
	var draft := _draft(selected_route)
	draft_status.text = "未保存草稿；返回或切頁會保留，本次遊戲關閉後不保留。" if bool(draft.dirty) else "已保存設定；啟停與升階沿用此設定。" if _view.get("economy", {}).get("routes", {}).has(selected_route) else "尚未配置；預設保留0、目標100。保存設定後仍維持停航。"
	save_button.disabled = not bool(info.get("ready", false))
	var level := int(settings.level)
	var cost := "祖島支付：靈材2＋銅精2" if _view.get("economy", {}).get("version") == IslandProgression.VERSION else "祖島支付：靈木20"
	upgrade_button.text = ("運力20／10秒・已達上限" if level >= 2 else "運力10→20／10秒・" + cost) + "\n升階保留啟停與已保存設定"
	upgrade_button.disabled = not bool(info.get("ready", false)) or level >= 2
	var reason: String = info.get("reason", "")
	var def: Array = IslandEconomy.ROUTES[selected_route]
	supply_button.visible = reason in ["ECONOMY_NOT_MIGRATED", "ISLAND_NOT_OPEN", "DESTINATION_FULL", "NO_SURPLUS"]
	var endpoint: String = def[0] if reason == "NO_SURPLUS" else def[1]
	if reason == "ISLAND_NOT_OPEN":
		endpoint = info.closed[0]
	supply_button.text = "先啟用空島" if reason == "ECONOMY_NOT_MIGRATED" else "開拓・" + IslandProgression.NAMES[endpoint] if reason == "ISLAND_NOT_OPEN" else "目的倉儲・" + IslandProgression.NAMES[endpoint] if reason == "DESTINATION_FULL" else "來源供給・" + IslandProgression.NAMES[endpoint]

func _open_supply() -> void:
	var info := _info(selected_route)
	var def: Array = IslandEconomy.ROUTES[selected_route]
	if info.reason == "NO_SURPLUS" and IslandEconomy.DURATIONS.has(def[2]):
		manufacturing_requested.emit(def[0], def[2])
		return
	var endpoint: String = def[1] if info.reason == "DESTINATION_FULL" else def[0]
	if info.reason == "ISLAND_NOT_OPEN":
		endpoint = info.closed[0]
	page_requested.emit("buildings" if info.reason == "DESTINATION_FULL" and endpoint == "home" else "outposts", endpoint)

func set_layout_bounds(bounds: Rect2) -> void:
	super.set_layout_bounds(bounds)
	short_layout = bounds.size.y < 400
	if grid != null:
		var columns := 2 if bounds.size.x >= 800 and bounds.size.y >= 400 else 1
		if grid.columns != columns:
			grid.columns = columns
		# Tile pairs and controls share a row on short landscapes; narrow rows wrap.
		for widget in route_widgets.values():
			var content: BoxContainer = widget.visual.root.get_parent()
			content.vertical = bounds.size.x < 430
	if policy_fields != null:
		policy_fields.columns = 2 if bounds.size.x >= 620 else 1
	if route_summary != null:
		route_summary.visible = bounds.size.y >= 400
	_refresh_rows()
	_layout_feedback()

func show_success(text: String) -> void:
	super.show_success(text)
	_layout_feedback()

func show_result(text: String) -> void:
	super.show_result(text)
	_layout_feedback()

func _layout_feedback() -> void:
	if heading_label == null or message == null:
		return
	# Compact receipts occupy the existing heading, preserving the first card.
	var compact_receipt := short_layout and _success_until > 0 and not retry_button.visible
	message.visible = not message.text.is_empty() and not compact_receipt
	heading_label.text = "島間運輸・已保存" if compact_receipt else "島間運輸"
	heading_label.tooltip_text = message.text if compact_receipt else ""
