class_name CultivationLevelUpButton
extends Button

const ResourceIconScript = preload("res://src/presentation/resource_icon.gd")

var costs_data: Dictionary = {}
var missing_data: Dictionary = {}
var can_level_up: bool = false
var is_lifespan_exhausted: bool = false
var custom_title: String = ""

func update_tooltip_data(p_costs: Dictionary, p_missing: Dictionary, p_can_lvl: bool, p_lifespan_exhausted: bool, p_title: String = "") -> void:
	costs_data = p_costs.duplicate(true)
	missing_data = p_missing.duplicate(true)
	can_level_up = p_can_lvl
	is_lifespan_exhausted = p_lifespan_exhausted
	custom_title = p_title

func _make_custom_tooltip(_for_text: String) -> Object:
	if costs_data.is_empty() and missing_data.is_empty():
		return null

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.14, 0.96)
	style.border_color = Color(0.52, 0.44, 0.30, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# 標題列
	var header := Label.new()
	header.add_theme_font_override("font", UiTypography.emphasis_font())
	header.add_theme_font_size_override("font_size", 15)

	if is_lifespan_exhausted:
		header.text = "壽元已盡 · 無法晉階"
		header.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
	elif not missing_data.is_empty():
		header.text = "修為晉階 · 缺少材料"
		header.add_theme_color_override("font_color", Color("e07b62"))
	elif can_level_up:
		header.text = "修為晉階 · 材料充足"
		header.add_theme_color_override("font_color", Color("7bc47f"))
	else:
		header.text = "修為晉階消耗"
		header.add_theme_color_override("font_color", Color("f4e7be"))
	vbox.add_child(header)

	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.25)
	vbox.add_child(sep)

	# 材料清單列表
	for r_id in costs_data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN

		# 圖示：使用現有資源手繪 icon
		var tex: Texture2D = ResourceIconScript.get_resource_texture(r_id)
		if tex != null:
			var icon_rect := TextureRect.new()
			icon_rect.texture = tex
			icon_rect.custom_minimum_size = Vector2(22, 22)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon_rect)
		else:
			var seal := Label.new()
			seal.text = ResourceIconScript.get_resource_name(r_id).left(1)
			seal.custom_minimum_size = Vector2(22, 22)
			seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			seal.add_theme_font_size_override("font_size", 14)
			seal.add_theme_color_override("font_color", Color("d4af37"))
			row.add_child(seal)

		# 資源中文名稱
		var r_name: String = ResourceIconScript.get_resource_name(r_id)
		var name_lbl := Label.new()
		name_lbl.text = r_name
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color("f4e7be"))
		name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_lbl)

		# 數量對比
		var cost_val = costs_data[r_id]
		var req_str: String = ResourceIconScript.format_amount(cost_val)
		var qty_lbl := Label.new()
		qty_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		qty_lbl.add_theme_font_size_override("font_size", 13)

		if missing_data.has(r_id):
			var entry: Dictionary = missing_data[r_id]
			var avail_str: String = ResourceIconScript.format_amount(entry.get("available", 0))
			qty_lbl.text = "持有 %s ／ 需要 %s" % [avail_str, req_str]
			qty_lbl.add_theme_color_override("font_color", Color("e58e73"))
		else:
			qty_lbl.text = "需要 %s · 充足" % [req_str]
			qty_lbl.add_theme_color_override("font_color", Color("9ecb98"))

		row.add_child(qty_lbl)
		vbox.add_child(row)

	return panel
