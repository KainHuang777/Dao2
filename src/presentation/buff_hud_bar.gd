class_name BuffHudBar
extends HBoxContainer
## Read-only reminders and active effects; clicks only open canonical pages.
signal route_requested(route: String)
signal page_changed
var badges: Dictionary = {}
var _keys: Array[String] = []
var _capacity := 1
var _page := 0

func fit_width(available: float) -> void:
	var capacity := maxi(1, int((available + 6.0) / 50.0))
	if capacity != _capacity:
		_capacity = capacity
		_page = 0
		_apply_page()

func next_page() -> void:
	_page = (_page + 1) % maxi(1, ceili(float(_keys.size()) / _capacity))
	_apply_page()

func hidden_count() -> int:
	return maxi(0, _keys.size() - mini(_capacity, _keys.size() - _page * _capacity))

func _apply_page() -> void:
	_page = mini(_page, maxi(0, ceili(float(_keys.size()) / _capacity) - 1))
	for i in _keys.size():
		badges[_keys[i]].visible = i >= _page * _capacity and i < (_page + 1) * _capacity
	page_changed.emit()

func _init() -> void:
	name = "BuffHudBar"
	add_theme_constant_override("separation", 6)
	visible = false

static func status_items(view: Dictionary, sect: Dictionary = {}) -> Array:
	var items: Array = []
	var expedition = sect.get("active_expedition")
	if bool(sect.get("unlocked", false)) and expedition is Dictionary and int(expedition.get("duration", 0)) > 0 and int(expedition.get("elapsed", 0)) >= int(expedition.duration):
		items.append({"id": "sect_ready", "seal": "宗", "text": "任務完成", "route": "sect", "tip": "宗門任務已完成，前往宗門領取獎勵。"})
	var beast: Dictionary = view.get("beast", {})
	if bool(beast.get("can_feed", false)):
		items.append({"id": "beast_feed", "seal": "獸", "text": "可以餵養", "route": "beasts", "tip": "靈獸餵食冷卻結束，且餵料足夠。前往靈獸查看成本與成長。"})
	if bool(view.get("fortune", {}).get("has_pending", false)):
		items.append({"id": "fortune_pending", "seal": "緣", "text": "機緣待決", "route": "fortune", "tip": "有待決機緣，前往機緣選擇。"})
	for buff in view.get("buffs", []):
		var title := String(buff.get("name", buff.get("id", "增益")))
		var remaining := String(buff.get("formatted_remaining", ""))
		var desc := String(buff.get("description", "")).strip_edges()
		var tip_lines: Array[String] = [title]
		if not desc.is_empty():
			tip_lines.append(desc)
		if not remaining.is_empty():
			tip_lines.append("持續：%s" % remaining)
		var tip_text := "\n".join(tip_lines)
		items.append({"id": "buff:" + String(buff.get("id", title)), "seal": String(buff.get("icon_text", "符")), "text": title + " " + remaining, "route": "", "tip": tip_text})
	return items

func update_status(view: Dictionary, sect: Dictionary = {}) -> void:
	_update_items(status_items(view, sect))

func update_buffs(active_buffs: Array) -> void:
	update_status({"buffs": active_buffs})

func _update_items(items: Array) -> void:
	var next_keys: Array[String] = []
	for item in items:
		next_keys.append(String(item.id))
	if next_keys != _keys:
		_clear_children()
		_keys = next_keys
		for item in items:
			var button := _create_badge(item)
			badges[item.id] = button
			add_child(button)
	for item in items:
		var button: Button = badges[item.id]
		button.tooltip_text = String(item.tip)
	visible = not items.is_empty()
	_apply_page()

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	badges.clear()
	_keys.clear()

func _create_badge(item: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(44, 44)
	UiMaterial.apply_button(button)
	var seal := Label.new()
	seal.text = String(item.seal).left(1)
	seal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seal.add_theme_font_override("font", UiTypography.chapter_font())
	seal.add_theme_font_size_override("font_size", 18)
	seal.add_theme_color_override("font_color", Color("74613d"))
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(seal)
	var route := String(item.route)
	if not route.is_empty():
		button.pressed.connect(func(): route_requested.emit(route))
	else:
		var popup := PopupPanel.new()
		button.add_child(popup)
		var detail := Label.new()
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_override("font", UiTypography.body_font())
		detail.add_theme_font_size_override("font_size", 16)
		popup.add_child(detail)
		button.pressed.connect(func():
			detail.text = button.tooltip_text
			popup.popup_centered(Vector2i(mini(320, int(get_viewport_rect().size.x) - 32), 140))
		)
	return button
