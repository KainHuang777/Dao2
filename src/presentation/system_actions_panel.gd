extends Control
## Native scrollable command views for existing beasts and realm decisions.
signal action_requested(kind: String, id: String)
var mode := "beasts"
var box: VBoxContainer
var content: VBoxContainer
var status: Label
var _signature := ""
var _last_mode := ""
var buttons: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var surface := PanelContainer.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	add_child(surface)
	box = VBoxContainer.new()
	surface.add_child(box)
	status = Label.new()
	status.visible = false
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 16)
	box.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size

func show_result(message: String) -> void:
	status.text = message
	status.visible = true

func _text(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	content.add_child(label)

func _action(text: String, kind: String, id: String, enabled: bool) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.disabled = not enabled
	UiMaterial.apply_button(button)
	button.pressed.connect(func(): action_requested.emit(kind, id))
	content.add_child(button)
	buttons[kind + ":" + id] = button

func refresh(view: Dictionary) -> void:
	if _last_mode != mode:
		status.visible = false
		_last_mode = mode
	var data: Variant = view.get("beast", {}) if mode == "beasts" else view.get("realm_decisions", [])
	var signature := mode + JSON.stringify(data)
	if signature == _signature:
		return
	_signature = signature
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	buttons.clear()
	if mode == "decisions":
		_text("天道決策 · 當前界域\n只施行目前所在界域的法則取捨，其他界域不會因預覽而解鎖。")
		for item in data:
			_text("%s\n%s\n代價：%s\n冷卻：%.0f 秒" % [item.get("name", item.id), item.get("description", ""), _costs(item.get("costs", {})), item.get("cooldown_remaining", 0.0)])
			var reason := "境界不足" if not bool(item.get("era_met", false)) else ("資糧不足" if not bool(item.get("costs_met", false)) else "等待冷卻")
			_action("施行" if bool(item.get("is_ready", false)) else reason, "decision", item.id, bool(item.get("is_ready", false)))
		return
	_text("靈獸培育 · 成熟獸魂與天賦可跨世繼承")
	var active: Dictionary = data.get("active", {})
	if not active.is_empty():
		_text("%s · %s · 成長 %d\n餵食：%s · 冷卻 %.0f秒" % [BeastSystem.BEAST_CONFIGS.get(active.id, {}).get("name", active.id), BeastSystem.STAGE_CONFIGS.get(active.stage, {}).get("name", active.stage), active.get("exp", 0), _costs(data.get("feed_costs", {})), data.get("cooldown_remaining", 0.0)])
		_action("餵養靈獸" if bool(data.get("can_feed", false)) else String(data.get("feed_reason", "目前不可餵食")), "feed", "", bool(data.get("can_feed", false)))
	for id in BeastSystem.BEAST_CONFIGS:
		var config: Dictionary = BeastSystem.BEAST_CONFIGS[id]
		_text("%s · 第 %d 境解鎖\n%s · 獸魂 %d" % [config.name, config.unlock_era, config.desc, data.get("souls", {}).get(id, 0)])
		_action("結契 %s" % config.name, "acquire", id, active.is_empty() and int(view.get("era_id", 1)) >= int(config.unlock_era))
		for talent in data.get("talents_view", []):
			if talent.beast_id != id:
				continue
			_text("%s · %s" % [talent.name, talent.desc])
			_action("已領悟" if bool(talent.owned) else "領悟 · %d獸魂" % int(talent.cost), "talent", talent.id, bool(talent.can_unlock))

func _costs(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for id in costs:
		var name: String = {"lifespan_seconds": "壽元（秒）", "money": "金錢", "wood": "靈木", "herb": "靈草", "mineral": "礦材", "lingqi": "靈氣", "spirit_crystal": "極品靈晶", "azure_nectar": "天青靈液", "stone_low": "下品靈石", "spirit_grass_low": "靈草", "lingli": "靈氣", "refined_iron": "精鐵", "void_essence": "虛空精華", "star_metal": "星金", "spirit_grass_1000y": "千年靈草"}.get(id, id)
		parts.append("%s %s" % [name, costs[id]])
	return "、".join(parts) if not parts.is_empty() else "無"
