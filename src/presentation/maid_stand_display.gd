extends Control

const ART := {
	"qingheng": "res://assets/characters/qingheng/portrait.png",
	"nuomeizi": "res://assets/characters/nuomeizi/portrait-r2.png",
	"danxia": "res://assets/characters/danxia/portrait-r2.png",
}
const ORDER := ["qingheng", "nuomeizi", "danxia"]
const NAMES := {"qingheng": "青蘅", "nuomeizi": "糯美子", "danxia": "丹霞"}
const ROLES := {"qingheng": "侍女", "nuomeizi": "劍侍", "danxia": "丹師"}
const CROP := Rect2(242.0, 0.0, 540.0, 780.0)
const PORTRAIT_RATIO := 780.0 / 540.0
const CHROME_HEIGHT := 192.0
const MIN_WIDTH := 200.0
const MAX_WIDTH := 252.0
const TOP_MIN := 84.0
const TAB_SIZE := Vector2(112.0, 64.0)

var _abode: Node
var _expanded := true
var _manual := false
var _selected := "qingheng"
var _active_duty := ""
var _maids: Dictionary = {}
var _texture_id := ""
var _room := Rect2()

var panel: PanelContainer
var portrait: TextureRect
var title_label: Label
var name_label: Label
var status_label: Label
var prev_button: Button
var next_button: Button
var open_button: Button
var collapse_button: Button
var tab: PanelContainer
var tab_button: Button
var guidance
var _column: VBoxContainer
var _header: HBoxContainer

func _init(abode_ref: Node) -> void:
	_abode = abode_ref
	name = "MaidStand"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	visible = false
	_build()

func _build() -> void:
	panel = PanelContainer.new()
	panel.name = "MaidStandPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	panel.tooltip_text = "洞府侍立展示；換人只改變呈現，不影響職掌。"
	add_child(panel)
	var column := VBoxContainer.new()
	_column = column
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)

	var header := HBoxContainer.new()
	_header = header
	header.add_theme_constant_override("separation", 4)
	column.add_child(header)
	title_label = _label("仙侍相伴", UiTypography.emphasis_font(), 18, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(title_label)
	collapse_button = CloseSeal.new()
	collapse_button.tooltip_text = "收起洞府侍立"
	collapse_button.accessibility_name = "收起洞府侍立"
	collapse_button.pressed.connect(func(): set_expanded(false))
	header.add_child(collapse_button)

	portrait = TextureRect.new()
	portrait.name = "MaidStandPortrait"
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(0, 64)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(portrait)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 2)
	column.add_child(name_row)
	prev_button = _action("前", "展示上一位仙侍", Control.SIZE_SHRINK_CENTER)
	prev_button.pressed.connect(func(): cycle(-1))
	name_row.add_child(prev_button)
	name_label = _label("", UiTypography.emphasis_font(), 18, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_row.add_child(name_label)
	next_button = _action("後", "展示下一位仙侍", Control.SIZE_SHRINK_CENTER)
	next_button.pressed.connect(func(): cycle(1))
	name_row.add_child(next_button)

	status_label = _label("", UiTypography.body_font(), 16, HORIZONTAL_ALIGNMENT_CENTER)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(status_label)

	open_button = _action("人物頁 · 初遇", "開啟人物、初遇、職掌與羈絆", Control.SIZE_EXPAND_FILL)
	open_button.pressed.connect(open_characters)
	column.add_child(open_button)

	tab = PanelContainer.new()
	tab.name = "MaidStandTab"
	tab.mouse_filter = Control.MOUSE_FILTER_STOP
	var tab_style := UiMaterial.hud_paper()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: tab_style.set_content_margin(side, 4)
	tab.add_theme_stylebox_override("panel", tab_style)
	tab.visible = false
	add_child(tab)
	tab_button = GameTab.new()
	tab_button.toggle_mode = false
	tab_button.text = "侍"
	tab_button.tooltip_text = "展開洞府侍立"
	tab_button.accessibility_name = "展開洞府侍立"
	tab_button.custom_minimum_size = Vector2(44, 44)
	tab_button.pressed.connect(func():
		if workspace_reserve(_abode.hud.size) > 0.0 or (not _expanded and _available_rect(_abode.hud.size, 28.0).size.x >= MIN_WIDTH):
			set_expanded(true)
		else: open_characters())
	tab.add_child(tab_button)
	guidance = preload("res://src/presentation/maid_guidance_dock.gd").new(_abode)
	add_child(guidance)
	guidance.guide_button.reparent(header, false)
	header.move_child(guidance.guide_button, 1)

	_apply_selection()

func _label(value: String, font: Font, font_size: int, align: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _action(value: String, tip: String, horizontal: int) -> Button:
	var button := InscriptionAction.new()
	button.text = value
	button.tooltip_text = tip
	button.accessibility_name = tip
	button.custom_minimum_size = Vector2(44, 44)
	button.size_flags_horizontal = horizontal
	return button

func refresh(view: Dictionary) -> void:
	var maid: Dictionary = view.get("maid", {}) if not view.is_empty() else {}
	var entries: Variant = maid.get("maids", {})
	_maids = entries if entries is Dictionary else {}
	_active_duty = String(maid.get("active_duty", ""))
	var saved: Variant = maid.get("display")
	if saved is Dictionary:
		_expanded = bool(saved.get("expanded", true))
		var saved_id := String(saved.get("maid_id", ""))
		if ORDER.has(saved_id):
			_selected = saved_id
			_manual = true
		else:
			_manual = false
			if ORDER.has(_active_duty):
				_selected = _active_duty
	elif not _manual and ORDER.has(_active_duty):
		_selected = _active_duty
	_apply_selection()
	guidance.refresh(view, _selected)
	if _abode != null and _abode.hud != null and _abode.hud.size.x > 0.0:
		update_layout(_abode.hud.size)

func cycle(step: int) -> void:
	var index: int = ORDER.find(_selected)
	if index < 0:
		index = 0
	_selected = ORDER[(index + step + ORDER.size()) % ORDER.size()]
	_manual = true
	_apply_selection()
	_persist_display()

func set_expanded(value: bool) -> void:
	if _expanded == value:
		return
	_expanded = value
	if _abode != null and _abode.hud != null and _abode.hud.size.x > 0.0:
		_abode._layout_for_size(_abode.hud.size)
	_persist_display()

func _persist_display() -> void:
	if _abode == null or _abode.session == null or _abode.session.state == null:
		return
	var result: Dictionary = _abode.session.submit({
		"command_id": "maid-display-" + str(Time.get_ticks_usec()),
		"type": "set_maid_display",
		"expected_revision": _abode.session.state.revision,
		"payload": {"expanded": _expanded, "maid_id": _selected if _manual else ""},
	})
	if bool(result.get("ok", false)):
		_abode._save_game()
	_abode._refresh_hud()

func is_expanded() -> bool:
	return _expanded

func selected_id() -> String:
	return _selected

func open_characters() -> void:
	if _abode == null or _abode.feature_navigation == null:
		return
	_abode.feature_navigation.open("characters")

func _apply_selection() -> void:
	if panel == null:
		return
	var entry: Dictionary = _maids.get(_selected, {}) if _maids.get(_selected, {}) is Dictionary else {}
	var display_name := String(entry.get("name", NAMES.get(_selected, _selected)))
	name_label.text = display_name
	name_label.tooltip_text = "%s · %s" % [display_name, String(entry.get("role", ROLES.get(_selected, "")))]
	var status := _status_text(entry)
	status_label.text = status
	status_label.tooltip_text = status
	var role := String(entry.get("role", ROLES.get(_selected, "")))
	open_button.tooltip_text = "開啟%s的人物、初遇、職掌與羈絆" % display_name
	open_button.accessibility_name = open_button.tooltip_text
	collapse_button.tooltip_text = "收起洞府侍立"
	tab_button.tooltip_text = "展開洞府侍立 · %s" % display_name
	tab_button.accessibility_name = tab_button.tooltip_text
	panel.tooltip_text = ""
	_load_texture()

func _status_text(entry: Dictionary) -> String:
	var role := String(entry.get("role", ROLES.get(_selected, "")))
	var prefix := role + " · " if not role.is_empty() else ""
	if entry.is_empty():
		return prefix + "立繪展示"
	var duty: Variant = entry.get("duty", {})
	if duty is Dictionary and not duty.is_empty():
		var text := String(duty.get("status_text", ""))
		return prefix + (text if not text.is_empty() else "職掌進行中")
	if not bool(entry.get("recruited", false)):
		return prefix + "未招募"
	return prefix + "未任職 · 純展示"

func _load_texture() -> void:
	if _texture_id == _selected:
		return
	_texture_id = _selected
	var path := String(ART.get(_selected, ""))
	if path.is_empty():
		portrait.texture = null
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = CROP
	portrait.texture = atlas
	portrait.visible = atlas.atlas != null
	tab_button.icon = atlas
	tab_button.expand_icon = true
	tab_button.text = ""
	tab_button.add_theme_constant_override("icon_max_width", 40)

func _is_home() -> bool:
	if _abode == null or _abode.feature_navigation == null:
		return false
	if _abode.feature_navigation.group not in ["home", "management"]:
		return false
	if _abode.offline_summary != null and _abode.offline_summary.visible:
		return false
	if _abode.v2_rules_notice != null and _abode.v2_rules_notice.visible:
		return false
	if _abode.feature_navigation.shell == null:
		return true
	return String(_abode.feature_navigation.shell.state.snapshot().overlay).is_empty()

func workspace_reserve(vp: Vector2) -> float:
	# Keep a useful management workspace; smaller views use the shared entry dock.
	if _abode.feature_navigation.group == "management" and _expanded and vp.x >= 1240.0 and vp.y >= 600.0:
		return 252.0 + (312.0 if vp.x >= 1600.0 else 0.0)
	return 0.0

func bubble_bounds(vp: Vector2) -> Rect2:
	# A speech bubble owns its own space; never borrow the portrait allocation.
	if not visible or not panel.visible: return Rect2()
	var height: float = maxf(236.0, guidance.bubble.get_combined_minimum_size().y)
	var candidate := Rect2(_room.position.x - 312.0, _room.position.y, 300.0, height)
	if candidate.position.x < 16.0 or candidate.end.y > _abode.toolbar.position.y - 8.0: return Rect2()
	var nav = _abode.feature_navigation
	var avoid: Array = [_abode.header, _abode.hint_panel, _abode.resource_ribbon, _abode.info_panel, _abode.toolbar, _abode.settings_menu, nav.shell.entry]
	if nav.group == "management": avoid.append(nav.shell.workbench.panel)
	for control in avoid:
		if control.is_visible_in_tree() and candidate.intersects(control.get_global_rect()): return Rect2()
	return candidate

func _selector_open() -> bool:
	if _abode == null or _abode.island_world == null:
		return false
	var selector: Variant = _abode.island_world.get("selector")
	return selector is Control and selector.visible

func _available_rect(vp: Vector2, margin: float) -> Rect2:
	if _abode.layout_mode != _abode.HudLayout.WIDE or _selector_open():
		return Rect2()
	var bottom: float = _abode.toolbar.position.y - 8.0
	var right: float = vp.x - margin
	var left_limit: float = margin
	var hint: Control = _abode.hint_panel
	if hint != null and hint.visible:
		left_limit = maxf(left_limit, hint.get_rect().end.x + 8.0)
	var max_width: float = minf(MAX_WIDTH, right - left_limit)
	if max_width < MIN_WIDTH:
		return Rect2()
	var width: float = clampf(vp.x * 0.20, MIN_WIDTH, max_width)
	var height: float = width * PORTRAIT_RATIO + CHROME_HEIGHT
	var max_height: float = bottom - TOP_MIN
	if height > max_height:
		height = max_height
		width = (height - CHROME_HEIGHT) / PORTRAIT_RATIO
		if width < MIN_WIDTH:
			return Rect2()
	return Rect2(right - width, bottom - height, width, height)

func update_layout(vp: Vector2) -> void:
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	size = vp
	if not _is_home():
		visible = false
		tab.hide()
		guidance.hide()
		_room = Rect2()
		return
	var margin: float = 28.0 if _abode.layout_mode == _abode.HudLayout.WIDE else 16.0
	var management: bool = _abode.feature_navigation.group == "management"
	var reserve := workspace_reserve(vp)
	_room = _available_rect(vp, margin) if not management else Rect2()
	if reserve > 0.0:
		var work: Rect2 = _abode.feature_navigation.shell.workbench.panel.get_global_rect()
		var top: float = maxf(76.0, work.position.y)
		_room = Rect2(work.end.x + reserve - 240.0, top, 240.0, work.end.y - top)
	visible = vp.x >= vp.y
	var expanded: bool = _expanded and _room.size.x >= MIN_WIDTH
	panel.visible = expanded
	tab.visible = not expanded
	guidance.show()
	if expanded:
		if guidance.guide_button.get_parent() != _header:
			guidance.guide_button.reparent(_header, false)
			_header.move_child(guidance.guide_button, 1)
		status_label.show()
		open_button.show()
		panel.position = _room.position
		panel.size = _room.size
		guidance.layout_bubble(bubble_bounds(vp))
		return
	# Compact/collapsed mode participates in the shell's entry container, so it
	# cannot cover resource/messages buttons or the bottom navigation.
	var entry: BoxContainer = _abode.feature_navigation.shell.entry
	_abode.feature_navigation.shell.message_button.hide()
	if tab.get_parent() != entry:
		tab.reparent(entry, false)
		entry.move_child(tab, 0)
	if tab.get_child(0) == tab_button:
		tab.remove_child(tab_button)
		var row := HBoxContainer.new()
		tab.add_child(row)
		row.add_child(tab_button)
	if guidance.guide_button.get_parent() != tab.get_child(0):
		guidance.guide_button.reparent(tab.get_child(0), false)
	_abode.feature_navigation.shell.layout_entries(vp)
	guidance.layout_bubble(Rect2())

func _exit_tree() -> void:
	# Compact controls temporarily belong to the shell's container.
	if is_instance_valid(tab) and tab.get_parent() != self: tab.queue_free()
