extends PanelContainer
## Bounded management view for buildings that do not have authored world footprints.

signal building_selected(building_id: String)
signal building_upgrade_requested(building_id: String)
signal gather_resource_requested(resource_id: String)
signal close_requested()
signal guidance_requested()

var rows: Dictionary = {}
var group_rows: Dictionary = {}
var progress_bars: Dictionary = {}
var resource_buttons: Dictionary = {}
var resource_value_labels: Dictionary = {}
var resource_gather_buttons: Dictionary = {}
var upgrade_buttons: Dictionary = {}
var row_info: Dictionary = {}
var expanded_row_id: String = ""
var resource_names: Dictionary = {}
var scroll: ScrollContainer
var close_button: Button
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
var short_mode: bool = false
var _last_resources: Dictionary = {}
var _last_buildings: Dictionary = {}
var _last_era_id: int = 1
var _list_scroll_position: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var surface := UiTypography.dialog_surface()
	surface.content_margin_left = 12
	surface.content_margin_right = 12
	surface.content_margin_top = 12
	surface.content_margin_bottom = 12
	add_theme_stylebox_override("panel", surface)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	box.add_child(title_row)
	var heading := Label.new()
	heading.text = "營造簿"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_override("font", UiTypography.emphasis_font())
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color("fff0c8"))
	title_row.add_child(heading)

	close_button = Button.new()
	close_button.text = "空島"
	close_button.custom_minimum_size = Vector2(64, 48)
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
	resource_names = names.duplicate()
	resource_summary = Label.new()
	for resource_id_value in resource_ids:
		var resource_id := String(resource_id_value)
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
		gather_btn.visible = false
		gather_btn.pressed.connect(func(): gather_resource_requested.emit(resource_id))
		row.add_child(gather_btn)
		resource_grid.add_child(card)
		resource_buttons[resource_id] = card
		resource_value_labels[resource_id] = value_label
		resource_gather_buttons[resource_id] = gather_btn

func set_context(status: String, objective: String) -> void:
	status_label.text = status
	objective_button.text = objective
	objective_button.tooltip_text = objective

func set_short_mode(short: bool) -> void:
	if short_mode == short:
		return
	short_mode = short
	status_label.visible = false
	objective_button.visible = not short and not detail_slot.visible
	filter_row.visible = not short and not detail_slot.visible
	_apply_resource_cards()

func show_detail(show: bool) -> void:
	if show and not detail_slot.visible:
		_list_scroll_position = scroll.scroll_vertical
	detail_slot.visible = show
	scroll.visible = not show
	objective_button.visible = not short_mode and not show
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
		group_box.add_child(group_title)
		for entry in group.get("entries", []):
			var id: String = String(entry.get("id", ""))
			var row_box := HBoxContainer.new()
			row_box.add_theme_constant_override("separation", 4)
			group_box.add_child(row_box)
			var button := Button.new()
			button.custom_minimum_size = Vector2(0, 48)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_override("font", UiTypography.body_font())
			button.add_theme_font_size_override("font_size", 16)
			button.add_theme_color_override("font_color", Color("f4e7be"))
			button.add_theme_stylebox_override("normal", _row_style(Color(0.02, 0.08, 0.10, 0.98), false))
			button.add_theme_stylebox_override("hover", _row_style(Color(0.08, 0.19, 0.19, 0.99), false))
			button.add_theme_stylebox_override("pressed", _row_style(Color(0.12, 0.27, 0.23, 0.99), false))
			button.pressed.connect(_select.bind(id))
			button.set_meta("title", String(entry.get("title", id)))
			button.set_meta("role", String(entry.get("role", "")))
			button.clip_children = Control.CLIP_CHILDREN_DISABLED

			# Dao1 進度條背景與填充
			var progress_bg := ColorRect.new()
			progress_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			progress_bg.color = Color(0.10, 0.13, 0.16, 0.75)
			progress_bg.visible = false
			button.add_child(progress_bg)

			var progress_fill := ColorRect.new()
			progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			progress_fill.color = Color(0.29, 0.72, 0.35, 0.85)
			progress_fill.visible = false
			button.add_child(progress_fill)

			# Dao1 側邊發亮提示
			var glow_bar := ColorRect.new()
			glow_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glow_bar.color = Color(0.35, 0.95, 0.45, 1.0)
			glow_bar.visible = false
			button.add_child(glow_bar)

			progress_bars[id] = {
				"bg": progress_bg,
				"fill": progress_fill,
				"glow": glow_bar,
				"progress": 0.0,
			}

			button.resized.connect(_update_row_overlays.bind(id))

			row_box.add_child(button)
			var upgrade := Button.new()
			upgrade.custom_minimum_size = Vector2(64, 48)
			upgrade.add_theme_font_override("font", UiTypography.emphasis_font())
			upgrade.add_theme_font_size_override("font_size", 16)
			upgrade.add_theme_stylebox_override("normal", _row_style(Color(0.08, 0.19, 0.18, 0.98), true))
			upgrade.add_theme_stylebox_override("hover", _row_style(Color(0.13, 0.29, 0.23, 0.99), true))
			upgrade.add_theme_stylebox_override("disabled", _row_style(Color(0.04, 0.08, 0.09, 0.95)))
			upgrade.add_theme_color_override("font_disabled_color", Color("a9b5aa"))
			upgrade.pressed.connect(func(): building_upgrade_requested.emit(id))
			row_box.add_child(upgrade)
			rows[id] = button
			upgrade_buttons[id] = upgrade
			var info_box := HBoxContainer.new()
			info_box.visible = false
			group_box.add_child(info_box)
			var info_label := Label.new()
			info_label.text = String(entry.get("role", ""))
			info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_label.add_theme_font_override("font", UiTypography.body_font())
			info_label.add_theme_font_size_override("font_size", 16)
			info_box.add_child(info_label)
			var detail_button := Button.new()
			detail_button.text = "詳情"
			detail_button.custom_minimum_size = Vector2(64, 48)
			detail_button.pressed.connect(func(): building_selected.emit(id))
			info_box.add_child(detail_button)
			row_info[id] = {"box": info_box, "label": info_label}
	_apply_density()

func _apply_density() -> void:
	var btn_height: float = 48.0
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
				child.add_theme_font_size_override("font_size", group_font_size)
	for id in rows:
		rows[id].custom_minimum_size.y = btn_height
		rows[id].add_theme_font_size_override("font_size", font_size)
		upgrade_buttons[id].custom_minimum_size.y = btn_height
		_update_row_overlays(id)

func refresh(buildings: Dictionary, resources: Dictionary = {}, era_id: int = 1) -> void:
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
	_last_era_id = era_id
	_update_resource_values()
	_apply_resource_cards()
	for id in rows:
		var button: Button = rows[id]
		var view: Dictionary = buildings.get(id, {})
		button.visible = bool(view.get("visible", false))
		button.get_parent().visible = button.visible
		if not button.visible:
			continue
		var level: int = int(view.get("level", 0))
		var level_cap: int = int(view.get("level_cap", 0))
		var affordable: bool = bool(view.get("affordable", false))
		var status := "待建" if level == 0 else "%d階" % level
		if level == 0 and affordable:
			status = "可建"
		elif level > 0 and affordable and level < level_cap:
			status = "%d階·可升" % level
		var role: String = button.get_meta("role")
		var costs: Dictionary = view.get("costs", {})
		var cost_parts: Array[String] = []
		for resource_id in costs:
			cost_parts.append("%s %s" % [String(costs[resource_id]), resource_names.get(resource_id, resource_id)])
		var cost_line: String = " · ".join(cost_parts) if not cost_parts.is_empty() else role
		button.text = "%s · %s" % [button.get_meta("title"), status]
		var upgrade: Button = upgrade_buttons[id]
		upgrade.visible = button.visible
		upgrade.text = "建造" if level == 0 else "升級"
		upgrade.disabled = not affordable or level >= level_cap
		upgrade.tooltip_text = "%s｜%s" % [role, cost_line]
		row_info[id].label.text = "%s｜需求：%s" % [role, cost_line]

		# 樣式與側邊發亮
		button.add_theme_stylebox_override("normal", _row_style(Color(0.02, 0.08, 0.10, 0.98), affordable))
		button.add_theme_stylebox_override("hover", _row_style(Color(0.08, 0.19, 0.19, 0.99), affordable))
		button.add_theme_stylebox_override("pressed", _row_style(Color(0.12, 0.27, 0.23, 0.99), affordable))

		# 計算需求條進度
		var bar_data: Dictionary = progress_bars.get(id, {})
		if not bar_data.is_empty():
			var glow: ColorRect = bar_data["glow"]
			var bg: ColorRect = bar_data["bg"]
			var fill: ColorRect = bar_data["fill"]
			glow.visible = affordable

			if level >= level_cap or costs.is_empty():
				bg.visible = false
				fill.visible = false
				bar_data["progress"] = 0.0
			else:
				bg.visible = true
				fill.visible = true
				if affordable:
					bar_data["progress"] = 1.0
				else:
					var min_ratio := 1.0
					for r_id in costs:
						var cost_val := _parse_amount_float(costs[r_id])
						var cur_val := 0.0
						if resources.has(r_id):
							cur_val = _parse_amount_float(resources[r_id].get("value", "0"))
						var ratio: float = clamp(cur_val / cost_val, 0.0, 1.0) if cost_val > 0.0 else 1.0
						min_ratio = min(min_ratio, ratio)
					bar_data["progress"] = min_ratio
			_update_row_overlays(id)

	for group_id in group_rows:
		var group_box: VBoxContainer = group_rows[group_id]
		var has_visible := false
		for child in group_box.get_children():
			if child is HBoxContainer and child.visible and child.get_child(0).visible:
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
		var second_line := "+%.2f/秒" % rate if rate > 0.0 else "待產出"
		value_label.text = "%s  %.2f" % [resource_names.get(resource_id, resource_id), current] if resource_display_mode == 1 else "%s  %.2f/%.0f\n%s" % [resource_names.get(resource_id, resource_id), current, capacity, second_line]
		value_label.add_theme_color_override("font_color", Color("f5bd71") if capacity > 0.0 and current >= capacity else Color("e4f0dc"))
		card.tooltip_text = "%s  %.2f/%.0f · %s" % [resource_names.get(resource_id, resource_id), current, capacity, second_line]
		if gather_btn != null:
			var can_gather: bool = (_last_era_id == 1 and bool(entry.get("unlocked", false)) and String(entry.get("type", "")) == "basic")
			gather_btn.visible = can_gather
			gather_btn.disabled = capacity > 0.0 and current >= capacity

func _set_filter(filter_id: String) -> void:
	active_filter = filter_id
	for id in filter_buttons:
		filter_buttons[id].button_pressed = id == active_filter
	refresh(_last_buildings, _last_resources, _last_era_id)


func _update_row_overlays(id: String) -> void:
	if not rows.has(id) or not progress_bars.has(id):
		return
	var button: Button = rows[id]
	var bar_data: Dictionary = progress_bars[id]
	var glow: ColorRect = bar_data["glow"]
	var bg: ColorRect = bar_data["bg"]
	var fill: ColorRect = bar_data["fill"]
	var progress: float = float(bar_data.get("progress", 0.0))
	var btn_size: Vector2 = button.size
	if btn_size.y <= 0:
		btn_size.y = button.custom_minimum_size.y
	if btn_size.x <= 0:
		btn_size.x = button.custom_minimum_size.x

	# 左側發亮條
	glow.position = Vector2(0, 0)
	glow.size = Vector2(3.5, btn_size.y)

	# 底部進度條背景與填充
	var bar_h := 3.0
	bg.position = Vector2(0, btn_size.y - bar_h)
	bg.size = Vector2(btn_size.x, bar_h)

	fill.position = Vector2(0, btn_size.y - bar_h)
	fill.size = Vector2(btn_size.x * progress, bar_h)

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size

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

func _row_style(background: Color, is_affordable: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	if is_affordable:
		style.border_color = Color(0.30, 0.78, 0.35, 0.95)
		style.set_border_width_all(1)
		style.shadow_color = Color(0.30, 0.78, 0.35, 0.25)
		style.shadow_size = 3
	else:
		style.border_color = Color(0.70, 0.63, 0.43, 0.78)
		style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
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
