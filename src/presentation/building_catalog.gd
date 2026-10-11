extends PanelContainer
## Bounded management view for buildings that do not have authored world footprints.

signal building_selected(building_id: String)
signal building_upgrade_requested(building_id: String)
signal gather_resource_requested(resource_id: String)
signal close_requested()
signal guidance_requested()

var rows: Dictionary = {}
var cards: Dictionary = {}
var card_labels: Dictionary = {}
var cost_rows: Dictionary = {}
var cost_cells: Dictionary = {}
var group_grids: Dictionary = {}
const CardButton = preload("res://src/presentation/building_card_button.gd")
const ResourceArt = preload("res://src/presentation/resource_icon.gd")
var group_rows: Dictionary = {}
var resource_buttons: Dictionary = {}
var resource_value_labels: Dictionary = {}
var resource_gather_buttons: Dictionary = {}
var _gather_tweens: Dictionary = {}
var _highlighted_resources: Array[String] = []
var upgrade_buttons: Dictionary = {}
var row_info: Dictionary = {}
var expanded_row_id: String = ""
var resource_names: Dictionary = {}
const BUILDING_NAMES := {
	"library": "藏經閣", "scripture_hall": "經書殿",
	"hut": "茅屋",
	"wooden_house": "木屋",
	"forest_farm": "林場",
	"stone_mine": "採石場",
	"herb_farm": "靈植場",
	"storage_lingli": "聚靈壇",
	"storage_money": "錢莊",
	"storage_wood": "木料庫",
	"storage_stone": "靈石庫",
	"storage_herb": "靈草庫",
}
var scroll: ScrollContainer
var close_button: Button
var cultivation_actions: HBoxContainer
var _content: VBoxContainer
var resource_summary: Label
var status_label: Label
var objective_button: Button
var resource_heading: Label
var resource_grid: GridContainer
var filter_row: HBoxContainer
var filter_buttons: Dictionary = {}
var active_filter: String = "all"
var detail_slot: Control
var resource_order: Array[String] = []
var resource_display_mode: int = 1
var _shared_resources: Dictionary = {}
var hud_paper_resources: bool = false
var short_mode: bool = false
var _last_resources: Dictionary = {}
var _last_buildings: Dictionary = {}
var _last_era_id: int = 1
var _list_scroll_position: int = 0
var _has_objective: bool = true
var _resource_rendered: Dictionary = {}
var _resource_visual_states: Dictionary = {}
var _row_material_states: Dictionary = {}
var _row_rendered: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var surface := UiMaterial.compact_scroll_shell()
	surface.content_margin_left = 12
	surface.content_margin_right = 12
	surface.content_margin_top = 6
	surface.content_margin_bottom = 6
	add_theme_stylebox_override("panel", surface)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	box.add_child(title_row)
	var heading := Label.new()
	heading.text = "營造簿"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_override("font", UiTypography.chapter_font())
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", UiMaterial.INK)
	title_row.add_child(heading)
	cultivation_actions = HBoxContainer.new()
	cultivation_actions.add_theme_constant_override("separation", 4)
	title_row.add_child(cultivation_actions)

	close_button = Button.new()
	close_button.text = "關閉"
	close_button.custom_minimum_size = Vector2(64, 44)
	close_button.add_theme_font_override("font", UiTypography.emphasis_font())
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.pressed.connect(func(): close_requested.emit())
	title_row.add_child(close_button)
	status_label = Label.new()
	status_label.add_theme_font_override("font", UiTypography.body_font())
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("f1d58d"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.visible = false
	box.add_child(status_label)
	objective_button = Button.new()
	objective_button.custom_minimum_size.y = 48
	objective_button.add_theme_font_override("font", UiTypography.body_font())
	objective_button.add_theme_font_size_override("font_size", 16)
	objective_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	objective_button.pressed.connect(func(): guidance_requested.emit())
	box.add_child(objective_button)
	filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	box.add_child(filter_row)
	for filter in [{"id": "all", "name": "全部"}, {"id": "production", "name": "生產"}, {"id": "storage", "name": "倉儲"}]:
		var filter_button := Button.new()
		filter_button.text = filter.name
		filter_button.custom_minimum_size.y = 48
		filter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_button.add_theme_font_size_override("font_size", 16)
		filter_button.toggle_mode = true
		filter_button.button_pressed = String(filter.id) == active_filter
		filter_button.pressed.connect(_set_filter.bind(String(filter.id)))
		filter_row.add_child(filter_button)
		filter_buttons[String(filter.id)] = filter_button
		UiMaterial.mark_paper_tab(filter_button, String(filter.id) == active_filter)
	resource_heading = Label.new()
	resource_heading.text = "資源"
	resource_heading.visible = false
	resource_heading.add_theme_font_override("font", UiTypography.emphasis_font())
	resource_heading.add_theme_font_size_override("font_size", 18)
	resource_heading.add_theme_color_override("font_color", Color("d9c58b"))
	box.add_child(resource_heading)
	resource_grid = GridContainer.new()
	resource_grid.columns = 2
	resource_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_grid.add_theme_constant_override("h_separation", 6)
	resource_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(resource_grid)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)
	detail_slot = Control.new()
	detail_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_slot.visible = false
	box.add_child(detail_slot)

func configure_resources(names: Dictionary, resource_ids: Array) -> void:
	resource_names.merge(names, true)
	if resource_summary == null:
		resource_summary = Label.new()
	for resource_id_value in resource_ids:
		var resource_id := String(resource_id_value)
		if resource_buttons.has(resource_id):
			continue
		resource_order.append(resource_id)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 38)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_theme_stylebox_override("panel", _row_style(Color(0.02, 0.08, 0.10, 0.72)))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		card.add_child(row)
		# Use the same authored item art as recipe/building costs in both list modes.
		var texture: Texture2D = ResourceArt.TEXTURES.get(resource_id)
		var icon: Control
		if texture != null:
			var picture := TextureRect.new()
			picture.texture = texture
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon = picture
		else:
			# Shared currencies/souls have no authored item art yet; keep a named seal.
			var seal := Label.new()
			seal.text = String(resource_names.get(resource_id, resource_id)).left(1)
			seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			seal.add_theme_font_override("font", UiTypography.emphasis_font())
			seal.add_theme_font_size_override("font_size", 18)
			seal.add_theme_color_override("font_color", Color("74613d"))
			icon = seal
		icon.name = "ResourceIcon"
		icon.custom_minimum_size = Vector2(24, 24)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		value_label.clip_text = true
		value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.add_theme_font_override("font", UiTypography.body_font())
		value_label.add_theme_font_size_override("font_size", 16)
		value_label.add_theme_color_override("font_color", Color("e4f0dc"))
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(value_label)
		var gather_btn := Button.new()
		gather_btn.text = "採集"
		gather_btn.custom_minimum_size = Vector2(56, 30)
		gather_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gather_btn.add_theme_font_override("font", UiTypography.emphasis_font())
		gather_btn.add_theme_font_size_override("font_size", 15)
		gather_btn.add_theme_stylebox_override("normal", _row_style(Color(0.08, 0.19, 0.18, 0.98), true))
		gather_btn.add_theme_stylebox_override("hover", _row_style(Color(0.13, 0.29, 0.23, 0.99), true))
		gather_btn.add_theme_stylebox_override("disabled", _row_style(Color(0.04, 0.08, 0.09, 0.95)))
		gather_btn.add_theme_color_override("font_color", Color("f4e7be"))
		gather_btn.add_theme_color_override("font_disabled_color", Color("a9b5aa"))
		UiMaterial.apply_button(gather_btn)
		gather_btn.visible = false
		gather_btn.pressed.connect(func(): gather_resource_requested.emit(resource_id))
		row.add_child(gather_btn)
		resource_grid.add_child(card)
		resource_buttons[resource_id] = card
		resource_value_labels[resource_id] = value_label
		resource_gather_buttons[resource_id] = gather_btn

func refresh_shared_resources(entries: Dictionary, names: Dictionary) -> void:
	configure_resources(names, entries.keys())
	for id in _shared_resources:
		_last_resources.erase(id)
	_shared_resources = entries.duplicate(true)
	_last_resources.merge(_shared_resources, true)
	_update_resource_values()
	_apply_resource_cards()

func set_context(status: String, objective: String) -> void:
	status_label.text = status
	objective_button.text = objective
	objective_button.tooltip_text = objective
	_has_objective = not objective.is_empty()
	objective_button.visible = _has_objective and not short_mode and not detail_slot.visible

func set_short_mode(short: bool) -> void:
	if short_mode == short:
		return
	short_mode = short
	status_label.visible = false
	objective_button.visible = _has_objective and not short and not detail_slot.visible
	filter_row.visible = not short and not detail_slot.visible
	_apply_density()
	_apply_resource_cards()

func show_detail(show: bool) -> void:
	if show and not detail_slot.visible:
		_list_scroll_position = scroll.scroll_vertical
	detail_slot.visible = show
	scroll.visible = not show
	objective_button.visible = _has_objective and not short_mode and not show
	filter_row.visible = not short_mode and not show
	_apply_resource_cards()
	if not show:
		scroll.set_deferred("scroll_vertical", _list_scroll_position)

func _apply_resource_cards() -> void:
	resource_heading.visible = false
	resource_grid.visible = resource_display_mode != 0
	for resource_id in resource_order:
		var card: PanelContainer = resource_buttons[resource_id]
		card.visible = bool(_last_resources.get(resource_id, {}).get("visible", false))
		card.custom_minimum_size.y = 38 if resource_display_mode == 1 else 56

func set_resource_display_mode(mode: int) -> void:
	resource_display_mode = clampi(mode, 0, 2)
	_update_resource_values()
	_apply_resource_cards()

func configure(groups: Array) -> void:
	for group in groups:
		var group_id: String = String(group.get("id", ""))
		var group_box := VBoxContainer.new()
		group_box.add_theme_constant_override("separation", 6)
		_content.add_child(group_box)
		group_rows[group_id] = group_box
		var group_title := Label.new()
		group_title.text = String(group.get("title", ""))
		group_title.add_theme_font_override("font", UiTypography.emphasis_font())
		group_title.add_theme_font_size_override("font_size", 20)
		group_title.add_theme_color_override("font_color", Color("d9c58b"))
		group_title.add_theme_color_override("font_color", UiMaterial.INK)
		group_box.add_child(group_title)
		var grid := GridContainer.new()
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		group_box.add_child(grid)
		group_grids[group_id] = grid
		for entry in group.get("entries", []):
			var id: String = String(entry.get("id", ""))
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("panel", UiMaterial.surface("paper"))
			grid.add_child(card)
			cards[id] = card
			var card_content := VBoxContainer.new()
			card_content.add_theme_constant_override("separation", 2)
			card.add_child(card_content)
			var row_box := HBoxContainer.new()
			row_box.add_theme_constant_override("separation", 8)
			card_content.add_child(row_box)
			var button := CardButton.new()
			button.custom_minimum_size = Vector2(104, 108)
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.add_theme_font_override("font", UiTypography.body_font())
			button.add_theme_font_size_override("font_size", 16)
			button.add_theme_color_override("font_color", Color("f4e7be"))
			button.pressed.connect(_select.bind(id))
			button.set_meta("title", String(entry.get("title", id)))
			button.set_meta("role", String(entry.get("role", "")))
			button.clip_children = Control.CLIP_CHILDREN_DISABLED
			button.expand_icon = true
			button.clip_text = true
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.add_theme_constant_override("icon_max_width", 88)
			button.add_theme_constant_override("h_separation", 10)

			UiMaterial.apply_scroll_button(button)
			for state in ["normal", "hover", "pressed", "disabled"]:
				var portrait_style: StyleBox = button.get_theme_stylebox(state).duplicate()
				portrait_style.content_margin_left = 8
				portrait_style.content_margin_right = 8
				button.add_theme_stylebox_override(state, portrait_style)

			row_box.add_child(button)
			var information := VBoxContainer.new()
			information.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			information.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			information.add_theme_constant_override("separation", 6)
			row_box.add_child(information)
			var materials_row := HBoxContainer.new()
			materials_row.add_theme_constant_override("separation", 4)
			information.add_child(materials_row)
			var title_label := Label.new()
			title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			title_label.add_theme_font_override("font", UiTypography.emphasis_font())
			title_label.add_theme_font_size_override("font_size", 16)
			title_label.add_theme_color_override("font_color", UiMaterial.INK)
			materials_row.add_child(title_label)
			card_labels[id] = title_label
			var costs := HFlowContainer.new()
			costs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			costs.add_theme_constant_override("h_separation", 6)
			costs.add_theme_constant_override("v_separation", 2)
			information.add_child(costs)
			var upgrade := Button.new()
			upgrade.custom_minimum_size = Vector2(64, 44)
			upgrade.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			upgrade.add_theme_font_override("font", UiTypography.emphasis_font())
			upgrade.add_theme_font_size_override("font_size", 16)
			upgrade.add_theme_stylebox_override("normal", _row_style(Color(0.08, 0.19, 0.18, 0.98), true))
			upgrade.add_theme_stylebox_override("hover", _row_style(Color(0.13, 0.29, 0.23, 0.99), true))
			upgrade.add_theme_stylebox_override("disabled", _row_style(Color(0.04, 0.08, 0.09, 0.95)))
			upgrade.add_theme_color_override("font_disabled_color", Color("a9b5aa"))
			UiMaterial.apply_button(upgrade)
			upgrade.add_theme_stylebox_override("disabled", _disabled_action_style())
			upgrade.add_theme_color_override("font_disabled_color", Color("53534d"))
			upgrade.pressed.connect(func(): building_upgrade_requested.emit(id))
			materials_row.add_child(upgrade)
			button.add_theme_font_override("font", UiTypography.emphasis_font())
			rows[id] = button
			upgrade_buttons[id] = upgrade
			cost_rows[id] = costs
			cost_cells[id] = {}
			var info_box := HBoxContainer.new()
			info_box.visible = false
			card_content.add_child(info_box)
			var info_label := Label.new()
			info_label.text = String(entry.get("role", ""))
			info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_label.add_theme_font_override("font", UiTypography.body_font())
			info_label.add_theme_font_size_override("font_size", 16)
			info_label.add_theme_color_override("font_color", UiMaterial.INK)
			info_box.add_child(info_label)
			var detail_button := Button.new()
			detail_button.text = "詳情"
			detail_button.custom_minimum_size = Vector2(64, 48)
			detail_button.pressed.connect(func(): building_selected.emit(id))
			info_box.add_child(detail_button)
			row_info[id] = {"box": info_box, "label": info_label}
	_apply_density()

func _apply_density() -> void:
	var btn_height: float = 108.0
	var font_size: int = 16
	var group_font_size: int = 16
	var v_sep: int = 4
	var group_sep: int = 3

	if _content != null:
		_content.add_theme_constant_override("separation", v_sep)

	for group_id in group_rows:
		var group_box: VBoxContainer = group_rows[group_id]
		group_box.add_theme_constant_override("separation", group_sep)
		for child in group_box.get_children():
			if child is Label:
				child.visible = not short_mode
				child.add_theme_font_size_override("font_size", group_font_size)
	for id in rows:
		rows[id].custom_minimum_size.y = btn_height
		rows[id].add_theme_font_size_override("font_size", font_size)
		upgrade_buttons[id].custom_minimum_size.y = 44.0

func refresh(buildings: Dictionary, resources: Dictionary = {}, era_id: int = 1, defer_resource_cards: bool = false) -> void:
	_last_buildings = buildings.duplicate(true)
	var resource_lines: Array[String] = []
	for resource_id in resources:
		var entry: Dictionary = resources[resource_id]
		if not bool(entry.get("visible", false)):
			continue
		var current := _parse_amount_float(entry.get("value", "0"))
		var capacity := _parse_amount_float(entry.get("cap", "0"))
		var rate := _parse_amount_float(entry.get("rate", "0"))
		var rate_text := " · +%.2f/秒" % rate if rate > 0.0 else ""
		resource_lines.append("%s %.2f/%.0f%s" % [resource_names.get(resource_id, resource_id), current, capacity, rate_text])
	resource_summary.text = "\n".join(resource_lines) if not resource_lines.is_empty() else "尚無已解鎖資源"
	_last_resources = resources.duplicate(true)
	_last_resources.merge(_shared_resources, true)
	_last_era_id = era_id
	if not defer_resource_cards:
		_update_resource_values()
		_apply_resource_cards()
	for id in rows:
		var button: Button = rows[id]
		var view: Dictionary = buildings.get(id, {})
		button.visible = bool(view.get("visible", false))
		button.get_parent().visible = button.visible
		cards[id].visible = button.visible
		if not button.visible:
			continue
		var level: int = int(view.get("level", 0))
		var level_cap: int = int(view.get("level_cap", 0))
		var affordable: bool = bool(view.get("affordable", false))
		var role: String = button.get_meta("role")
		var costs: Dictionary = view.get("costs", {})
		var cost_parts: Array[String] = []
		for resource_id in costs:
			cost_parts.append("%s %s" % [String(costs[resource_id]), resource_names.get(resource_id, resource_id)])
		var cost_line: String = " · ".join(cost_parts) if not cost_parts.is_empty() else role

		# 檢查材料是否均已湊齊
		var resources_sufficient: bool = not costs.is_empty()
		var min_ratio: float = 1.0
		for r_id in costs:
			var cost_val := _parse_amount_float(costs[r_id])
			var cur_val := 0.0
			if resources.has(r_id):
				cur_val = _parse_amount_float(resources[r_id].get("value", "0"))
			if cost_val > 0.0:
				var ratio: float = clamp(cur_val / cost_val, 0.0, 1.0)
				min_ratio = min(min_ratio, ratio)
				if cur_val < cost_val:
					resources_sufficient = false

		var prereq = view.get("prereq", null)
		var is_prereq_blocked: bool = (not affordable) and resources_sufficient and (level < level_cap)

		var status := "待建" if level == 0 else "%d階" % level
		var upgrade: Button = upgrade_buttons[id]
		upgrade.visible = button.visible

		if level >= level_cap:
			status = "%d階·已滿" % level
			upgrade.text = "滿階"
			upgrade.disabled = true
			upgrade.tooltip_text = "%s｜已達等階上限（%d階）" % [role, level_cap]
			row_info[id].label.text = "%s｜已達上限（%d階）" % [role, level_cap]
		elif affordable:
			status = "可建" if level == 0 else "%d階·可升" % level
			upgrade.text = "建造" if level == 0 else "升級"
			upgrade.disabled = false
			upgrade.tooltip_text = "%s｜%s" % [role, cost_line]
			row_info[id].label.text = "%s｜需求：%s" % [role, cost_line]
		elif is_prereq_blocked:
			var prereq_text := "需前置條件"
			if prereq != null:
				var p_bld: String = String(prereq.get("building", ""))
				var p_lvl: int = int(prereq.get("level", 1))
				var p_name: String = BUILDING_NAMES.get(p_bld, p_bld)
				prereq_text = "需 %s 達到 %d 階" % [p_name, p_lvl]
			status = "前置不足" if level == 0 else "%d階·前置不足" % level
			upgrade.text = "前置\n不足"
			upgrade.disabled = true
			upgrade.tooltip_text = "%s｜材料已齊，但%s" % [role, prereq_text]
			row_info[id].label.text = "%s｜【前置不足】%s｜需求：%s" % [role, prereq_text, cost_line]
		else:
			status = "待建" if level == 0 else "%d階" % level
			upgrade.text = "材料\n不足"
			upgrade.disabled = true
			upgrade.tooltip_text = "%s｜材料不足｜%s" % [role, cost_line]
			row_info[id].label.text = "%s｜需求：%s" % [role, cost_line]

		card_labels[id].text = "%s\n%s" % [button.get_meta("title"), status]
		_update_cost_cells(id, costs, resources, level >= level_cap)

		var material_state := "ready" if affordable else ("warning" if is_prereq_blocked else "normal")
		var row_style_state := [material_state, affordable]
		if _row_material_states.get(id) != row_style_state:
			cards[id].add_theme_stylebox_override("panel", UiMaterial.surface("paper", material_state))
			upgrade.add_theme_stylebox_override("normal", UiMaterial.surface("plaque", "ready" if affordable else "normal"))
		_row_material_states[id] = row_style_state
		var meter_vis: bool = level < level_cap and not costs.is_empty()
		button.refresh_portrait(id, era_id, level, level_cap, min_ratio, meter_vis)
		button.tooltip_text = "%s｜%s\n材料需求 %.0f%%（以最不足材料計）" % [role, cost_line, min_ratio * 100.0]
		if is_prereq_blocked:
			button.tooltip_text += "\n材料已齊，仍需滿足前置條件"
	for group_id in group_rows:
		var group_box: VBoxContainer = group_rows[group_id]
		var has_visible := false
		for child in group_box.get_children():
			if child is GridContainer and child.get_children().any(func(card): return card.visible):
				has_visible = true
				break
		group_box.visible = has_visible and (active_filter == "all" or active_filter == group_id or (active_filter == "production" and group_id == "core"))

func _update_resource_values() -> void:
	for resource_id in resource_buttons:
		var card: PanelContainer = resource_buttons[resource_id]
		var value_label: Label = resource_value_labels[resource_id]
		var gather_btn: Button = resource_gather_buttons.get(resource_id, null)
		var entry: Dictionary = _last_resources.get(resource_id, {})
		var current := _parse_amount_float(entry.get("value", "0"))
		var capacity := _parse_amount_float(entry.get("cap", "0"))
		var rate := _parse_amount_float(entry.get("rate", "0"))
		var second_line: String = entry.get("status_text", "+%.2f/秒" % rate if rate > 0.0 else "待產出")
		var is_full := (capacity > 0.0 and current >= capacity)
		var r_name: String = resource_names.get(resource_id, resource_id)
		# Own a copy: callers may mutate/reuse dictionaries between commands.
		# Names, Era, density and paper palette affect rendering even at equal stock.
		var signature := [entry, r_name, _last_era_id, resource_display_mode, hud_paper_resources]
		if _resource_rendered.get(resource_id) == signature:
			continue
		_resource_rendered[resource_id] = signature.duplicate(true)
		var visual_state := [bool(entry.get("uncapped", false)), is_full, hud_paper_resources]
		if _resource_visual_states.get(resource_id) != visual_state:
			var full_style := is_full and not bool(entry.get("uncapped", false))
			card.add_theme_stylebox_override("panel", UiMaterial.hud_resource_row(full_style) if hud_paper_resources else (_resource_full_style() if full_style else _row_style(Color(0.02, 0.08, 0.10, 0.72))))
		_resource_visual_states[resource_id] = visual_state

		if bool(entry.get("uncapped", false)):
			value_label.text = "%s  %.0f" % [r_name, current]
			if resource_display_mode == 2:
				value_label.text += "\n" + second_line
			value_label.add_theme_color_override("font_color", UiMaterial.INK)
			card.tooltip_text = "%s · %s" % [r_name, second_line]
		elif is_full:
			if resource_display_mode == 1:
				value_label.text = "%s  %.2f [滿]" % [r_name, current]
			else:
				value_label.text = "%s  %.2f/%.0f [滿倉]\n%s" % [r_name, current, capacity, second_line]
			value_label.add_theme_color_override("font_color", Color("78511e") if hud_paper_resources else Color("f5bd71"))
			card.tooltip_text = "%s  %.2f/%.0f 【已達上限】· %s" % [r_name, current, capacity, second_line]
		else:
			if resource_display_mode == 1:
				value_label.text = "%s  %.2f" % [r_name, current]
			else:
				value_label.text = "%s  %.2f/%.0f\n%s" % [r_name, current, capacity, second_line]
			value_label.add_theme_color_override("font_color", Color("414438") if hud_paper_resources else Color("e4f0dc"))
			card.tooltip_text = "%s  %.2f/%.0f · %s" % [r_name, current, capacity, second_line]

		if gather_btn != null:
			var can_gather: bool = (_last_era_id == 1 and bool(entry.get("unlocked", false)) and String(entry.get("type", "")) == "basic")
			gather_btn.visible = can_gather
			gather_btn.disabled = is_full
			gather_btn.text = "已滿" if is_full else "採集"
			gather_btn.tooltip_text = "已達上限，請升級對應倉儲設施" if is_full else "手動採集 1 點資源"
	_apply_gather_highlights()

func _set_filter(filter_id: String) -> void:
	active_filter = filter_id
	for id in filter_buttons:
		filter_buttons[id].button_pressed = id == active_filter
		UiMaterial.mark_paper_tab(filter_buttons[id], id == active_filter)
	refresh(_last_buildings, _last_resources, _last_era_id)


func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	for grid in group_grids.values():
		grid.columns = 2 if bounds.size.x >= 520.0 else 1

func _update_cost_cells(id: String, costs: Dictionary, resources: Dictionary, maxed: bool) -> void:
	cost_rows[id].visible = not maxed and not costs.is_empty()
	for resource_id in cost_cells[id]:
		cost_cells[id][resource_id].box.visible = costs.has(resource_id)
	for resource_id in costs:
		if not cost_cells[id].has(resource_id):
			var box := HBoxContainer.new()
			box.mouse_filter = Control.MOUSE_FILTER_PASS
			box.add_theme_constant_override("separation", 2)
			var icon := TextureRect.new()
			icon.texture = ResourceArt.TEXTURES.get(resource_id)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(icon)
			icon.custom_minimum_size = Vector2(24, 24)
			var label := Label.new()
			label.add_theme_font_override("font", UiTypography.body_font())
			label.add_theme_font_size_override("font_size", 16)
			box.add_child(label)
			cost_rows[id].add_child(box)
			cost_cells[id][resource_id] = {"box": box, "label": label}
		var cell: Dictionary = cost_cells[id][resource_id]
		var signature := [str(resources.get(resource_id, {}).get("value", "0")), str(costs[resource_id]), resource_names.get(resource_id, resource_id)]
		if cell.get("rendered") == signature:
			continue
		cell.rendered = signature
		var have := AmountCompat.try_parse(str(resources.get(resource_id, {}).get("value", "0")))
		var need := AmountCompat.try_parse(str(costs[resource_id]))
		if not have.get("ok", false) or not need.get("ok", false):
			continue
		var available: AmountCompat = have.value
		var required: AmountCompat = need.value
		cell.label.text = "%s/%s" % [_cost_display(available), _cost_display(required)]
		cell.label.add_theme_color_override("font_color", Color("35705b") if available.compare_to(required) >= 0 else Color("a34434"))
		cell.box.tooltip_text = "%s｜庫存 %s／需求 %s" % [resource_names.get(resource_id, resource_id), _cost_display(available), _cost_display(required)]

static func _cost_display(amount: AmountCompat) -> String:
	if amount.layer == 0 and absf(amount.to_float()) < 1000000.0:
		return ("%.2f" % amount.to_float()).rstrip("0").trim_suffix(".")
	return amount.to_display_string()

func preferred_height() -> float:
	# The management rail fills the available height; only the building section
	# scrolls, so resources and buildings remain simultaneously visible.
	return 600.0

func _select(id: String) -> void:
	var should_open: bool = expanded_row_id != id
	for row_id in row_info:
		row_info[row_id].box.visible = false
	expanded_row_id = id if should_open else ""
	if should_open and row_info.has(id):
		row_info[id].box.visible = true

func _row_style(_background: Color, is_affordable: bool = false) -> StyleBoxTexture:
	var style := UiMaterial.card("ready" if is_affordable else "normal")
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _resource_full_style() -> StyleBoxTexture:
	return _row_style(Color.WHITE, true)

func _disabled_action_style() -> StyleBoxTexture:
	var style: StyleBoxTexture = UiMaterial.surface("plaque", "disabled").duplicate()
	style.modulate_color = Color(0.68, 0.68, 0.64)
	style.content_margin_left = 6
	style.content_margin_right = 6
	return style
static func _parse_amount_float(raw_val: Variant) -> float:
	if raw_val is float or raw_val is int:
		return float(raw_val)
	var text := String(raw_val)
	var parse_result := AmountCompat.try_parse(text)
	if parse_result.get("ok", false):
		var amount: AmountCompat = parse_result["value"]
		return amount.to_float()
	if text.is_valid_float():
		return text.to_float()
	return 0.0

func highlight_gather_buttons(res_ids: Array) -> void:
	var clean_ids: Array[String] = []
	for item in res_ids:
		clean_ids.append(String(item))
	clean_ids.sort()
	if clean_ids == _highlighted_resources:
		return
	_highlighted_resources = clean_ids
	_apply_gather_highlights()

func _apply_gather_highlights() -> void:
	# 先清除不再高亮的按鈕與動畫
	for res_id in _gather_tweens.keys():
		if not (res_id in _highlighted_resources):
			var tw: Tween = _gather_tweens[res_id]
			if tw != null and tw.is_valid():
				tw.kill()
			_gather_tweens.erase(res_id)
			var btn: Button = resource_gather_buttons.get(res_id, null)
			if btn != null and is_instance_valid(btn):
				btn.modulate = Color.WHITE

	# 為需要高亮的按鈕建立呼吸閃爍
	for res_id in _highlighted_resources:
		var btn: Button = resource_gather_buttons.get(res_id, null)
		if btn == null or not is_instance_valid(btn) or not btn.visible or btn.disabled:
			if _gather_tweens.has(res_id):
				var tw: Tween = _gather_tweens[res_id]
				if tw != null and tw.is_valid():
					tw.kill()
				_gather_tweens.erase(res_id)
				if btn != null and is_instance_valid(btn):
					btn.modulate = Color.WHITE
			continue
		if _gather_tweens.has(res_id) and _gather_tweens[res_id] != null and _gather_tweens[res_id].is_valid():
			continue

		btn.modulate = Color.WHITE
		var tw := create_tween().set_loops()
		tw.tween_property(btn, "modulate", Color(1.85, 1.45, 0.45, 1.0), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_gather_tweens[res_id] = tw

func clear_gather_highlights() -> void:
	_highlighted_resources.clear()
	for res_id in _gather_tweens.keys():
		var tw: Tween = _gather_tweens[res_id]
		if tw != null and tw.is_valid():
			tw.kill()
		var btn: Button = resource_gather_buttons.get(res_id, null)
		if btn != null and is_instance_valid(btn):
			btn.modulate = Color.WHITE
	_gather_tweens.clear()

func _exit_tree() -> void:
	clear_gather_highlights()

