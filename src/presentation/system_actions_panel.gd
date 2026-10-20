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
var save_failed := false
var _scroll: ScrollContainer
var _surface: PanelContainer
var skill_view: Control
var decision_view: Control
var retry_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTypography.create_theme()
	theme.set_color("font_color", "Label", UiMaterial.INK)
	var surface := PanelContainer.new()
	_surface = surface
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", UiMaterial.scroll_shell())
	add_child(surface)
	box = VBoxContainer.new()
	surface.add_child(box)
	var feedback_row := HBoxContainer.new()
	box.add_child(feedback_row)
	status = Label.new()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.visible = false
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 16)
	feedback_row.add_child(status)
	retry_button = Button.new()
	retry_button.text = "重試保存"
	retry_button.custom_minimum_size = Vector2(0, 44)
	UiMaterial.apply_button(retry_button)
	retry_button.hide()
	retry_button.pressed.connect(func(): action_requested.emit("retry_save", ""))
	feedback_row.add_child(retry_button)
	retry_button.custom_minimum_size.x = 112
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	skill_view = preload("res://src/presentation/skill_study_view.gd").new()
	box.add_child(skill_view)
	skill_view.action_requested.connect(func(kind: String, id: String): action_requested.emit(kind, id))
	skill_view.hide()
	decision_view = preload("res://src/presentation/realm_decision_view.gd").new()
	box.add_child(decision_view)
	decision_view.action_requested.connect(func(kind: String, id: String): action_requested.emit(kind, id))
	decision_view.hide()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	_surface.add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell() if bounds.size.y < 350 else UiMaterial.scroll_shell())
	_sync_skill_feedback()

func _sync_skill_feedback() -> void:
	if skill_view == null or status == null: return
	var merged := mode == "skills" and size.y < 350 and not save_failed and not status.text.is_empty()
	skill_view.set_feedback(status.text if merged else "")
	status.visible = not status.text.is_empty() and not merged

func show_result(message: String) -> void:
	status.text = message
	status.visible = true
	_sync_skill_feedback()

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
		if not save_failed: status.text = ""
		status.visible = save_failed
		_last_mode = mode
	skill_view.visible = mode == "skills"
	decision_view.visible = mode == "decisions"
	_scroll.visible = mode not in ["skills", "decisions"]
	retry_button.visible = save_failed
	if mode == "decisions":
		decision_view.refresh(view)
		buttons = decision_view.buttons.duplicate()
		_signature = ""
		return
	if mode == "skills":
		_sync_skill_feedback()
		skill_view.refresh(view)
		buttons = skill_view.buttons.duplicate()
		_signature = ""
		return
	var data: Variant = view.get("beast", {}) if mode == "beasts" else view.get("realm_decisions", [])
	var signature_data: Variant = data
	var signature := mode + JSON.stringify(signature_data)
	if signature == _signature:
		return
	_signature = signature
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	buttons.clear()
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

func show_save_failure(message: String) -> void:
	save_failed = true
	retry_button.show()
	show_result(message)
func storage_recovered() -> void:
	if save_failed:
		save_failed = false
		retry_button.hide()
		show_result("已恢復保存，進度已寫入。")
