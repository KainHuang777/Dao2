class_name BuffHudBar
extends HFlowContainer

var _cached_buffs: Array = []

func _init() -> void:
	name = "BuffHudBar"
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 4)
	visible = false

func update_buffs(active_buffs: Array) -> void:
	if active_buffs.is_empty():
		visible = false
		_clear_children()
		_cached_buffs.clear()
		return

	visible = true
	_cached_buffs = active_buffs

	# Rebuild badges to guarantee sync
	_clear_children()
	for buff in active_buffs:
		var badge := _create_buff_badge(buff)
		add_child(badge)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _create_buff_badge(buff: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var theme_color := Color(String(buff.get("color", "#4fe3c1")))

	var style := UiMaterial.card()
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	var icon_label := Label.new()
	icon_label.text = String(buff.get("icon_text", "符"))
	icon_label.add_theme_font_override("font", UiTypography.emphasis_font())
	icon_label.add_theme_font_size_override("font_size", 13)
	icon_label.add_theme_color_override("font_color", theme_color)
	hbox.add_child(icon_label)

	var text_label := Label.new()
	var name_str := String(buff.get("name", buff.get("id", "")))
	var rem_str := String(buff.get("formatted_remaining", ""))
	text_label.text = "%s %s" % [name_str, rem_str]
	text_label.add_theme_font_override("font", UiTypography.body_font())
	text_label.add_theme_font_size_override("font_size", 13)
	text_label.add_theme_color_override("font_color", Color("f0ebd8"))
	hbox.add_child(text_label)

	var desc_str := String(buff.get("description", ""))
	panel.tooltip_text = "【%s】\n%s\n持續狀態：%s" % [name_str, desc_str, rem_str]

	return panel
