class_name SectPanel
extends Control

const ResourceIconScript = preload("res://src/presentation/resource_icon.gd")
const CONTRIBUTION_ICON = preload("res://assets/ui/icons/sect-contribution.svg")
const DISPATCH_ICON = preload("res://assets/ui/icons/sect-dispatch.svg")
const RARITY_ICON = preload("res://assets/ui/icons/sect-rarity.svg")
const RARITY_COLORS := {"common":Color("ffffff"), "uncommon":Color("65b765"), "rare":Color("539ee8"), "epic":Color("b476d6"), "legendary":Color("edc052")}
const UiIconScript = preload("res://src/presentation/ui_icon.gd")

signal join_sect_requested(sect_name: String)
signal refresh_tasks_requested()
signal start_expedition_requested(task_id: String)
signal claim_expedition_requested()
signal learn_technique_requested(tech_id: String)
signal buy_market_item_requested(item_id: String)
signal close_requested()
signal retry_save_requested()

enum TabMode { EXPEDITIONS, TECHNIQUES, MARKET }

var _background: Panel
var _header_container: VBoxContainer
var _title_row: HBoxContainer
var _title_label: Label
var _contrib_row: HBoxContainer
var _contrib_label: Label
var _close_button: Button

# 狀態橫幅或未解鎖/未加入提示
var _banner_panel: PanelContainer
var _banner_label: Label

# 分頁切換器
var _tab_row: HBoxContainer
var _tab_expeditions_btn: Button
var _tab_techniques_btn: Button
var _tab_market_btn: Button
var _current_tab: TabMode = TabMode.EXPEDITIONS

# 內容主捲軸
var _scroll: ScrollContainer
var _tab_content_container: VBoxContainer

# 快取當前 view
var _cached_sect_data: Dictionary = {}
var _cached_resources: Dictionary = {}
var _cached_state: GameState
var _cached_is_eligible_to_join: bool = false
var _header_reflow_pending := false
var _compact := false
var _art_nodes: Array[TextureRect] = []
var _p2_card_layouts: Array[Dictionary] = []
var _p2_market_layouts: Array[Dictionary] = []
var _dynamic: Array[Callable] = []
var _feedback: Label
var _retry: Button
var _feedback_row: HBoxContainer
var _pending_save := false
var _margin: MarginContainer
var _root_box: VBoxContainer
var _grids: Array[GridContainer] = []
var _join_intro: PanelContainer
const ART_DIR := "res://assets/ui/sects-painted/"
const SECT_ART := {"太虛天闕":"taixu", "天劍聖宗":"tianjian", "縹緲仙宮":"piaomiao", "萬佛靈宗":"wanfo", "紫霄玄門":"zixiao"}

const SECT_FLAVORS := {
	"太虛天闕": "雲闕道門 · 太虛清修",
	"天劍聖宗": "劍道山門 · 以劍問道",
	"縹緲仙宮": "縹緲仙境 · 月下蘭庭",
	"萬佛靈宗": "金蓮佛門 · 明心見性",
	"紫霄玄門": "紫霄玄門 · 雷法清修",
}

func _ready() -> void:
	if _header_container == null:
		_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	clip_contents = true
	if _background != null:
		_background.size = size
	_compact = size.y < 350
	_background.add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell() if _compact else UiMaterial.scroll_shell())
	UiMaterial.apply_scroll_content_margins(_margin, _compact)
	_banner_panel.visible = not _compact and not bool(_cached_sect_data.get("unlocked", false))
	_header_container.add_theme_constant_override("separation", 4 if _compact else 8)
	_root_box.add_theme_constant_override("separation", 2 if _compact else 6)
	var joined := bool(_cached_sect_data.get("unlocked",false))
	if is_instance_valid(_join_intro): _join_intro.visible = not _compact
	if not joined:
		_title_label.text = ("擇一拜入山門" if _cached_is_eligible_to_join else "需達築基或歷經轉世") if _compact else "【尋仙訪道】· 拜入山門"
	_title_row.visible = not (_compact and joined)
	_close_button.visible = not _compact
	var contribution_parent: Node = _tab_row if _compact and joined else _title_row
	if _contrib_row.get_parent() != contribution_parent:
		_contrib_row.reparent(contribution_parent)
	# Short workspaces share the fixed tab/title row with operation feedback.
	# Keep the original result and retry controls, without a second header row.
	var feedback_parent: Node = (_tab_row if joined else _title_row) if _compact else _feedback_row
	for control in [_feedback, _retry]:
		if control.get_parent() != feedback_parent: control.reparent(feedback_parent)
	_feedback_row.visible = not _compact and (_pending_save or not _feedback.text.is_empty())
	_feedback.clip_text = _compact
	_feedback.autowrap_mode = TextServer.AUTOWRAP_OFF if _compact else TextServer.AUTOWRAP_WORD_SMART
	if _pending_save:
		_feedback.text = "保存失敗；請重試保存。" if _compact else _feedback.tooltip_text
	for art in _art_nodes:
		if is_instance_valid(art): art.custom_minimum_size = Vector2.ONE * (64 if size.y < 220 else (80 if _compact else 112))
	for node in _tab_content_container.find_children("*", "Label", true, false):
		if node.has_meta("p1_description"): node.visible = not _compact
		if node.has_meta("p1_market_cost"):
			var item: Dictionary = SectSystem.MARKET_ITEMS[node.get_meta("p1_market_cost")]
			node.text = "%d貢獻 → %s · 需築基" % [int(item.cost), "靈木100" if item.has("grant_resource") else "育草丹1"]
	for layout in _p2_card_layouts:
		var short_card := size.y < 220
		layout.effect.visible = not short_card
		layout.short_effect.visible = short_card
		layout.title.text = layout.short_title if short_card else layout.full_title
		layout.title.add_theme_font_size_override("font_size", 18 if short_card else 20)
		layout.cost.text = layout.short_cost if short_card else layout.full_cost
		layout.title.autowrap_mode = TextServer.AUTOWRAP_OFF if short_card else TextServer.AUTOWRAP_WORD_SMART
		layout.cost.autowrap_mode = TextServer.AUTOWRAP_OFF if short_card else TextServer.AUTOWRAP_WORD_SMART
		layout.short_effect.autowrap_mode = TextServer.AUTOWRAP_OFF
		layout.info.add_theme_constant_override("separation", 0 if short_card else 4)
		layout.art.custom_minimum_size = Vector2.ONE * (44 if short_card else (80 if _compact else 112))
		layout.box.content_margin_top = 4 if short_card else 8
		layout.box.content_margin_bottom = 4 if short_card else 8
	for layout in _p2_market_layouts:
		var short_card := size.y < 220
		layout.title.add_theme_font_size_override("font_size", 18 if short_card else 20)
		layout.cost.text = layout.short_cost if short_card else layout.full_cost
		layout.info.add_theme_constant_override("separation", 0 if short_card else 4)
		layout.art.custom_minimum_size = Vector2.ONE * (44 if short_card else 80)
		layout.box.content_margin_top = 4 if short_card else 8
		layout.box.content_margin_bottom = 4 if short_card else 8
	for grid in _grids:
		if is_instance_valid(grid): grid.columns = 2 if size.x >= 1040 else 1
	_margin.size = size
	_scroll.custom_minimum_size = Vector2.ZERO

func _build_ui() -> void:
	clip_contents = true
	theme = UiTypography.create_theme()
	_margin = MarginContainer.new()
	_background = Panel.new()
	var bg_box := UiMaterial.scroll_shell()
	_background.add_theme_stylebox_override("panel", bg_box)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)
	add_child(_margin)
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_box = VBoxContainer.new()
	_root_box.add_theme_constant_override("separation",6)
	_margin.add_child(_root_box)

	_header_container = VBoxContainer.new()
	_header_container.name = "SectHeaderContainer"
	_header_container.add_theme_constant_override("separation", 10)
	_header_container.minimum_size_changed.connect(_queue_header_reflow)
	_root_box.add_child(_header_container)

	# 1. 頂部標題列
	_title_row = HBoxContainer.new()
	_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_container.add_child(_title_row)

	_title_label = Label.new()
	_title_label.text = "宗門外務"
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_override("font", UiTypography.chapter_font())
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UiMaterial.INK)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_row.add_child(_title_label)

	_contrib_row = HBoxContainer.new()
	_title_row.add_child(_contrib_row)
	_add_small_icon(_contrib_row, CONTRIBUTION_ICON, "宗門貢獻")
	_contrib_label = Label.new()
	_contrib_label.text = "貢獻：0 點"
	_contrib_label.add_theme_color_override("font_color", UiMaterial.INK)
	_contrib_row.add_child(_contrib_label)

	var space := Control.new()
	space.custom_minimum_size = Vector2(10, 0)
	_title_row.add_child(space)

	_close_button = CloseSeal.new()

	_close_button.custom_minimum_size = Vector2(44, 44)
	_close_button.pressed.connect(func(): close_requested.emit())
	_title_row.add_child(_close_button)

	# 2. 狀態或概覽橫幅
	_banner_panel = PanelContainer.new()
	var b_box := UiMaterial.hud_paper()
	b_box.content_margin_left = 12
	b_box.content_margin_right = 12
	b_box.content_margin_top = 6
	b_box.content_margin_bottom = 6
	_banner_panel.add_theme_stylebox_override("panel", b_box)
	_header_container.add_child(_banner_panel)

	_banner_label = Label.new()
	_banner_label.text = "歷練獲取貢獻，用於參悟功法與坊市兌換。"
	_banner_label.add_theme_color_override("font_color", UiMaterial.INK)
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_panel.add_child(_banner_label)

	# 3. 分頁標籤按鈕
	_tab_row = HBoxContainer.new()
	_tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_row.add_theme_constant_override("separation", 8)
	_header_container.add_child(_tab_row)

	_tab_expeditions_btn = GameTab.new()
	_tab_expeditions_btn.text = "歷練委託"
	_tab_expeditions_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_expeditions_btn.pressed.connect(func(): _switch_tab(TabMode.EXPEDITIONS))
	_tab_row.add_child(_tab_expeditions_btn)

	_tab_techniques_btn = GameTab.new()
	_tab_techniques_btn.text = "秘術傳承"
	_tab_techniques_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_techniques_btn.pressed.connect(func(): _switch_tab(TabMode.TECHNIQUES))
	_tab_row.add_child(_tab_techniques_btn)

	_tab_market_btn = GameTab.new()
	_tab_market_btn.text = "宗門坊市"
	_tab_market_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_market_btn.pressed.connect(func(): _switch_tab(TabMode.MARKET))
	_tab_row.add_child(_tab_market_btn)

	_feedback_row = HBoxContainer.new()
	_header_container.add_child(_feedback_row)
	_feedback = Label.new()
	_feedback.add_theme_color_override("font_color", UiMaterial.INK)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feedback.add_theme_font_size_override("font_size", 16)
	_feedback_row.add_child(_feedback)
	_retry = Button.new()
	_retry.text = "重試保存"
	_retry.custom_minimum_size = Vector2(96,44)
	_retry.hide()
	_retry.pressed.connect(func(): retry_save_requested.emit())
	_feedback_row.add_child(_retry)
	_feedback_row.hide()

	# 4. 滾動主區域（作為 SectPanel 同級子節點，獨立受控於 set_layout_bounds）
	_scroll = ScrollContainer.new()
	_scroll.name = "SectScroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_root_box.add_child(_scroll)

	_tab_content_container = VBoxContainer.new()
	_tab_content_container.name = "TabContent"
	_tab_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_content_container.add_theme_constant_override("separation", 10)
	_scroll.add_child(_tab_content_container)

func _switch_tab(mode: TabMode) -> void:
	_current_tab = mode
	_render_current_tab()
	set_layout_bounds(Rect2(position, size))
	_queue_header_reflow()

func update_view(state: GameState) -> void:
	if _header_container == null:
		_build_ui()
	if state == null:
		return
	var sect: Dictionary = state.sect
	_cached_sect_data = sect.duplicate(true)
	_cached_resources = state.resources
	_cached_state = state
	_cached_is_eligible_to_join = SectSystem.is_unlocked(state)

	var is_unlocked := bool(sect.get("unlocked", false))
	var s_name := String(sect.get("sect_name", "太虛天闕"))
	var contrib_str := String(sect.get("contribution", "0"))
	var c_parsed := AmountCompat.try_parse(contrib_str)
	var contrib_display: String = c_parsed["value"].to_display_string() if bool(c_parsed.get("ok", false)) else "0"

	_title_label.text = "【宗門外務】· " + s_name if is_unlocked else "【尋仙訪道】· 拜入山門"
	_contrib_label.text = contrib_display
	_contrib_row.visible = is_unlocked
	_contrib_label.tooltip_text = "宗門貢獻：" + contrib_str
	_tab_row.visible = is_unlocked
	if not is_unlocked:
		_banner_label.text = "歷練獲取貢獻，用於參悟功法與坊市兌換。" if _cached_is_eligible_to_join else "仙途漫漫，唯仙基穩固（築基期或歷經轉世）方具立誓拜入仙門之資。"
	else:
		_banner_label.text = "歷練獲取貢獻，用於參悟功法與坊市兌換。"

	var structural := sect.duplicate(true)
	structural.erase("next_refresh_seconds")
	var active = structural.get("active_expedition")
	if active is Dictionary:
		active.erase("elapsed")
	var signature := JSON.stringify([structural, _cached_is_eligible_to_join, state.era_id, state.beast_talents, state.sect_version, state.economy.get("version"), _p2_effect_signature(state)])
	if signature != _render_signature and not _has_pressed_button(_tab_content_container):
		_render_signature = signature
		_render_current_tab()
	for refresh in _dynamic: refresh.call()
	set_layout_bounds(Rect2(position, size))

var _render_signature := ""

func _has_pressed_button(node: Node) -> bool:
	if node is Button and node.is_pressed():
		return true
	for child in node.get_children():
		if _has_pressed_button(child):
			return true
	return false

func _render_current_tab() -> void:
	_dynamic.clear()
	_art_nodes.clear()
	_p2_card_layouts.clear()
	_p2_market_layouts.clear()
	_grids.clear()
	_join_intro = null
	# 清空容器
	for child in _tab_content_container.get_children():
		_tab_content_container.remove_child(child)
		child.queue_free()

	var is_unlocked := bool(_cached_sect_data.get("unlocked", false))
	if not is_unlocked:
		_render_join_panel()
		_wrap_card_labels(_tab_content_container)
		return

	# 高亮分頁按鈕樣式
	_tab_expeditions_btn.set_pressed_no_signal(_current_tab == TabMode.EXPEDITIONS)
	_tab_techniques_btn.set_pressed_no_signal(_current_tab == TabMode.TECHNIQUES)
	_tab_market_btn.set_pressed_no_signal(_current_tab == TabMode.MARKET)
	for tab in [_tab_expeditions_btn, _tab_techniques_btn, _tab_market_btn]: tab._update_style()

	match _current_tab:
		TabMode.EXPEDITIONS:
			_render_expeditions_tab()
		TabMode.TECHNIQUES:
			_render_techniques_tab()
		TabMode.MARKET:
			_render_market_tab()

	_wrap_card_labels(_tab_content_container)
	for refresh in _dynamic: refresh.call()

# ================= 拜入宗門介面 =================
func _render_join_panel() -> void:
	var is_eligible := _cached_is_eligible_to_join

	var intro_card := PanelContainer.new()
	_join_intro = intro_card
	intro_card.visible = not _compact
	var intro_box := UiMaterial.hud_paper()
	intro_box.content_margin_left = 14
	intro_box.content_margin_right = 14
	intro_box.content_margin_top = 12
	intro_box.content_margin_bottom = 12
	intro_card.add_theme_stylebox_override("panel", intro_box)
	_tab_content_container.add_child(intro_card)

	var intro_vb := VBoxContainer.new()
	intro_vb.add_theme_constant_override("separation", 8)
	intro_card.add_child(intro_vb)

	var h_lbl := Label.new()
	if is_eligible:
		h_lbl.text = "道友仙基初立，可立誓拜入仙門！"
		h_lbl.add_theme_color_override("font_color", UiMaterial.INK)
	else:
		h_lbl.text = "【未達門檻 · 需達築基期方可拜入】"
		h_lbl.add_theme_color_override("font_color", UiMaterial.INK)
	h_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
	h_lbl.add_theme_font_size_override("font_size", 16)
	intro_vb.add_child(h_lbl)

	var desc_lbl := Label.new()
	if is_eligible:
		desc_lbl.text = "入宗後開放歷練委託、秘術傳承與宗門坊市。"
	else:
		desc_lbl.text = "各大宗門門規森嚴，需道友突破至第二重境界【築基期】或歷經轉世，方具拜入門戶之資。請先在洞府納靈營造，早日築基！"
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", UiMaterial.INK)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_vb.add_child(desc_lbl)

	# 宗門清單標題
	var sects_lbl := Label.new()
	sects_lbl.text = "【名門正派 · 擇一立誓】" if is_eligible else "【五大名門 · 預覽傳承】"
	sects_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
	sects_lbl.add_theme_color_override("font_color", UiMaterial.INK)
	_tab_content_container.add_child(sects_lbl)
	var grid := _new_grid()

	# 垂直排列的各宗門卡片，完全自適應且永遠不會水平截斷
	for s_name in SectSystem.SECT_NAMES:
		var s_card := PanelContainer.new()
		var s_box := UiMaterial.hud_paper()
		s_box.content_margin_left = 12
		s_box.content_margin_right = 12
		s_box.content_margin_top = 8
		s_box.content_margin_bottom = 8
		s_card.add_theme_stylebox_override("panel", s_box)
		grid.add_child(s_card)

		var s_row := HBoxContainer.new()
		s_row.add_theme_constant_override("separation", 10)
		s_card.add_child(s_row)
		_add_art(s_row, SECT_ART[s_name])

		var s_info := VBoxContainer.new()
		s_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s_row.add_child(s_info)

		var s_title := Label.new()
		s_title.text = "【%s】" % s_name
		s_title.add_theme_font_override("font", UiTypography.emphasis_font())
		s_title.add_theme_color_override("font_color", UiMaterial.INK)
		s_info.add_child(s_title)

		var s_desc := Label.new()
		s_desc.text = SECT_FLAVORS.get(s_name, "玄門妙法，各顯神通。")
		s_desc.add_theme_color_override("font_color", UiMaterial.INK)
		s_desc.add_theme_font_size_override("font_size", 16)
		s_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s_info.add_child(s_desc)

		var j_btn := Button.new()
		if is_eligible:
			j_btn.text = "立誓拜入"
			j_btn.disabled = false
			j_btn.pressed.connect(_on_join_pressed.bind(s_name))
		else:
			j_btn.text = "需達築基期"
			j_btn.disabled = true
		j_btn.custom_minimum_size = Vector2(96, 44)
		j_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s_row.add_child(j_btn)

func _queue_header_reflow() -> void:
	if not _header_reflow_pending:
		_header_reflow_pending = true
		_reflow_header.call_deferred()

func _reflow_header() -> void:
	_header_reflow_pending = false
	set_layout_bounds(Rect2(position, size))

func _on_join_pressed(s_name: String) -> void:
	join_sect_requested.emit(s_name)

# ================= 歷練委託分頁 =================
func _render_expeditions_tab() -> void:
	var active = _cached_sect_data.get("active_expedition")
	var is_active: bool = (active != null and active is Dictionary)

	# 1. 進行中歷練卡片
	var active_panel := PanelContainer.new()
	var act_box := UiMaterial.hud_paper()
	act_box.content_margin_left = 12
	act_box.content_margin_right = 12
	act_box.content_margin_top = 10
	act_box.content_margin_bottom = 10
	active_panel.add_theme_stylebox_override("panel", act_box)
	_tab_content_container.add_child(active_panel)

	var act_vb := VBoxContainer.new()
	act_vb.add_theme_constant_override("separation", 6)
	active_panel.add_child(act_vb)

	if is_active:
		var active_title_row := HBoxContainer.new()
		active_title_row.add_theme_constant_override("separation", 6)
		act_vb.add_child(active_title_row)
		var active_icon: Control = UiIconScript.new()
		active_icon.set("kind", UiIconScript.Kind.HOURGLASS)
		active_icon.tint = Color(1.0, 0.85, 0.3)
		active_title_row.add_child(active_icon)
		_add_rarity(active_title_row, active)
		var a_title := Label.new()
		var t_name: String = String(active.get("name", "歷練"))
		a_title.text = "%s  %ds" % [t_name, int(active.get("duration", 0))]
		a_title.add_theme_color_override("font_color", UiMaterial.INK)
		a_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		active_title_row.add_child(a_title)

		_add_rewards(act_vb, active.get("rewards", {}))
		var duration := int(active.get("duration", 0))
		var elapsed := int(active.get("elapsed", 0))
		var is_finished := elapsed >= duration
		var remain := maxi(0, duration - elapsed)

		var prog_bar := ProgressBar.new()
		prog_bar.min_value = 0
		prog_bar.max_value = max(1, duration)
		prog_bar.value = elapsed
		prog_bar.show_percentage = true
		prog_bar.custom_minimum_size = Vector2(0, 18)
		act_vb.add_child(prog_bar)

		var status_row := HBoxContainer.new()
		act_vb.add_child(status_row)

		var status_lbl := Label.new()
		status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status_lbl.text = "歷練已圓滿完成！請速結算成果。" if is_finished else "歷練剩餘時間：%d 秒" % remain
		status_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		status_row.add_child(status_lbl)

		var claim_btn := Button.new()
		claim_btn.text = "領取歷練獎勵" if is_finished else "歷練中..."
		if is_finished:
			claim_btn.icon = load("res://assets/ui/icons/gift.svg")
		claim_btn.disabled = not is_finished
		claim_btn.custom_minimum_size = Vector2(120, 44)
		claim_btn.pressed.connect(_on_claim_expedition_pressed)
		status_row.add_child(claim_btn)
		_dynamic.append(func():
			var live: Dictionary = _cached_sect_data.get("active_expedition", {})
			var left := maxi(0, int(live.get("duration",0)) - int(live.get("elapsed",0)))
			a_title.text = "%s  %ds" % [String(live.get("name","歷練")), int(live.get("duration",0))]
			prog_bar.value = int(live.get("elapsed",0))
			status_lbl.text = "完成待領" if left == 0 else "派遣中 · %ds" % left
			claim_btn.disabled = left > 0
			claim_btn.text = "領取獎勵" if left == 0 else "歷練中"
		)
	else:
		active_panel.hide()

	# 2. 待接委託清單標題與手動刷新
	var list_header := HBoxContainer.new()
	_tab_content_container.add_child(list_header)

	var list_title_row := HBoxContainer.new()
	list_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_title_row.add_theme_constant_override("separation", 6)
	list_header.add_child(list_title_row)
	var list_icon: Control = UiIconScript.new()
	list_icon.set("kind", UiIconScript.Kind.SCROLL)
	list_icon.set("tint", Color("e8cf83"))
	list_title_row.add_child(list_icon)
	var sub_title := Label.new()
	sub_title.text = "宗門懸賞委託清單"
	sub_title.add_theme_font_override("font", UiTypography.emphasis_font())
	sub_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_title_row.add_child(sub_title)

	var refresh_cd := int(_cached_sect_data.get("next_refresh_seconds", 0))
	var refresh_btn := Button.new()
	refresh_btn.text = "刷新委託" if refresh_cd <= 0 else "冷卻中 (%ds)" % refresh_cd
	if refresh_cd <= 0:
		refresh_btn.icon = load("res://assets/ui/icons/refresh.svg")
	refresh_btn.disabled = refresh_cd > 0
	refresh_btn.custom_minimum_size = Vector2(140,44)
	refresh_btn.pressed.connect(_on_refresh_tasks_pressed)
	_dynamic.append(func():
		var cd := int(_cached_sect_data.get("next_refresh_seconds",0))
		refresh_btn.text = "刷新委託" if cd <= 0 else "冷卻 %d秒" % cd
		refresh_btn.disabled = cd > 0
	)
	list_header.add_child(refresh_btn)

	# 3. 委託清單項目
	var tasks: Array = _cached_sect_data.get("available_tasks", [])
	if tasks.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "暫無可接委託，請點擊上方刷新委託。"
		_tab_content_container.add_child(empty_lbl)
	else:
		var grid := _new_grid()
		for task in tasks:
			var t_card := _create_task_card(task, is_active)
			grid.add_child(t_card)

func _create_task_card(task: Dictionary, is_active: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var box := UiMaterial.hud_paper()
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	_add_art(row, _task_art(String(task.get("name",""))))

	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_vb)

	var title_row := HBoxContainer.new()
	info_vb.add_child(title_row)
	_add_rarity(title_row, task)
	var name_lbl := Label.new()
	name_lbl.text = "%s  %ds" % [String(task.get("name", "")), int(task.get("duration", 60))]
	name_lbl.tooltip_text = String(task.get("desc", ""))
	title_row.add_child(name_lbl)
	_add_rewards(info_vb, task.get("rewards", {}))

	var start_btn := Button.new()
	start_btn.name = "Dispatch"
	start_btn.icon = DISPATCH_ICON
	start_btn.expand_icon = true
	start_btn.add_theme_constant_override("icon_max_width", 48)
	start_btn.tooltip_text = "派遣歷練" if not is_active else "歷練中，完成並領取後可再派遣"
	for style in ["normal", "hover", "pressed", "disabled"]:
		start_btn.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	start_btn.add_theme_color_override("icon_hover_color", Color(1.2, 1.2, 1.1))
	start_btn.add_theme_color_override("icon_pressed_color", Color(0.7, 0.85, 0.75))
	start_btn.add_theme_color_override("icon_disabled_color", Color(0.45, 0.45, 0.45, 0.6))
	start_btn.disabled = is_active
	start_btn.custom_minimum_size = Vector2(56, 56)
	var t_id: String = String(task.get("id", ""))
	start_btn.pressed.connect(_on_start_expedition_pressed.bind(t_id))
	row.add_child(start_btn)

	return card

# ================= 秘術傳承分頁 =================
func _render_techniques_tab() -> void:
	var techs: Dictionary = _cached_sect_data.get("techniques", {})
	var grid := _new_grid()

	for tech_id in SectSystem.TECHNIQUES:
		var def: Dictionary = SectSystem.TECHNIQUES[tech_id]
		var cur_lvl := int(techs.get(tech_id, 0))
		var max_lvl := int(def.get("max_level", 10))

		var card := PanelContainer.new()
		card.set_meta("content_id", tech_id)
		var box := UiMaterial.hud_paper()
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", box)
		grid.add_child(card)

		var row := HBoxContainer.new()
		card.add_child(row)
		_add_art(row, tech_id)

		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vb)

		var title_lbl := Label.new()
		title_lbl.text = "%s  (第 %d / %d 重)" % [String(def.name), cur_lvl, max_lvl]
		title_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
		title_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		info_vb.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = String(def.desc)
		if tech_id in SectSystem.P1_TECHNIQUES:
			desc_lbl.set_meta("p1_description", true)
			title_lbl.text += " · " + ("築基" if int(def.min_era) == 2 else "金丹")
			title_lbl.tooltip_text = String(def.desc)
		desc_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		desc_lbl.add_theme_font_size_override("font_size", 16)
		info_vb.add_child(desc_lbl)
		if tech_id in SectSystem.P2_TECHNIQUES:
			desc_lbl.set_meta("p1_description", true)
			title_lbl.text += " · 元嬰"
			var effect := Label.new()
			effect.name = "EffectPreview"
			effect.tooltip_text = _p2_pill_names() if tech_id == "p2_pill_qi_conservation" else "玄龜當世元嬰、火鳳當世煉虛才生效；含現有獸魂折扣並最後取整，不加經驗、不縮冷卻；部分階實費相同。"
			effect.add_theme_font_size_override("font_size", 16)
			info_vb.add_child(effect)
			effect.text = _p2_technique_preview(tech_id)

		var is_max := cur_lvl >= max_lvl
		var cost_text := "已達圓滿"
		if not is_max:
			var scale := pow(float(def.get("cost_scale", 1.5)), float(cur_lvl))
			var req_contrib := int(ceil(float(def.get("base_contrib", 50)) * scale))
			cost_text = "參悟所需：貢獻 %d" % req_contrib
			if def.has("base_wood"):
				cost_text += " | 靈木 %d" % int(ceil(float(def.base_wood) * scale))
			if def.has("base_stone_low"):
				cost_text += " | 下品靈石 %d" % int(ceil(float(def.base_stone_low) * scale))

		var cost_lbl := Label.new()
		cost_lbl.text = cost_text
		if tech_id == "alchemy_herb_conservation":
			cost_lbl.tooltip_text = "僅聚靈／養木／聚財／納靈四丹下品草；現行每顆%s草，下一階%s草；批量不取整。退宗或當世境界不足時停用。" % [str(10.0 * (100 - 2 * SectSystem.active_level(_cached_state, tech_id)) / 100), str(10.0 * (100 - 2 * mini(cur_lvl + 1, 5)) / 100)]
		elif tech_id == "fox_feed_conservation":
			var preview := _cached_state.duplicate_state()
			preview.sect.techniques[tech_id] = mini(cur_lvl + 1, 5)
			cost_lbl.tooltip_text = "靈狐現行每餵%s草；下一階實際%s草。最後取整，部分階不減少。退宗或當世境界不足時停用。" % [str(BeastSystem.feed_costs(_cached_state, "jade_fox").spirit_grass_low), str(BeastSystem.feed_costs(preview, "jade_fox").spirit_grass_low)]

		cost_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		cost_lbl.add_theme_font_size_override("font_size", 16)
		info_vb.add_child(cost_lbl)
		if tech_id in SectSystem.P2_TECHNIQUES:
			var short_effect := Label.new()
			short_effect.add_theme_font_size_override("font_size", 16)
			short_effect.add_theme_color_override("font_color", UiMaterial.INK)
			short_effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			short_effect.text = _p2_short_technique_preview(tech_id)
			short_effect.tooltip_text = String(def.desc) + "\n" + _p2_technique_preview(tech_id) + "\n" + _p2_pill_names() if tech_id == "p2_pill_qi_conservation" else String(def.desc) + "\n" + _p2_technique_preview(tech_id)
			short_effect.visible = false
			row.add_child(short_effect)
			_p2_card_layouts.append({"title":title_lbl,"cost":cost_lbl,"info":info_vb,"art":row.get_child(0),"box":box,"effect":info_vb.get_node("EffectPreview"),"short_effect":short_effect,"full_title":title_lbl.text,"short_title":"%s %d/%d · 元嬰" % [String(def.name),cur_lvl,max_lvl],"full_cost":cost_text,"short_cost":cost_text.replace("參悟所需：", "").replace(" | ", "／").replace("下品靈石", "石").replace("靈木", "木")})

		var learn_btn := Button.new()
		learn_btn.text = "參悟提升" if not is_max else "已圓滿"
		learn_btn.disabled = is_max
		learn_btn.custom_minimum_size = Vector2(90, 44)
		learn_btn.pressed.connect(_on_learn_technique_pressed.bind(tech_id))
		row.add_child(learn_btn)
		_dynamic.append(func():
			var scale_now := pow(float(def.get("cost_scale",1.5)),float(cur_lvl))
			var enough := _has_contribution(ceil(float(def.get("base_contrib",50)) * scale_now))
			for key in ["wood", "stone_low"]:
				if def.has("base_"+key):
					var held: AmountCompat = _cached_resources.get(key,{}).get("value",AmountCompat.zero())
					enough = enough and held.compare_to(AmountCompat.from_number(ceil(float(def["base_"+key])*scale_now))) >= 0
			var locked := _cached_state.era_id < int(def.get("min_era", 1))
			if tech_id in SectSystem.P2_TECHNIQUES:
				var result := SectSystem.technique_requirements(_cached_state, tech_id)
				learn_btn.disabled = not result.ok
				learn_btn.text = _technique_status(String(result.get("error", "")))
				learn_btn.tooltip_text = "需入宗、當世元嬰及已開放供給；跨世保留，退宗或當世境界不足停用。"
				return
			learn_btn.disabled = is_max or not enough or locked
			learn_btn.text = "已圓滿" if is_max else ("境界未達" if locked else ("參悟提升" if enough else "資源不足"))
		)

# ================= 宗門坊市分頁 =================
func _render_market_tab() -> void:
	var purchases: Dictionary = _cached_sect_data.get("market_purchases", {})
	var grid := _new_grid()

	for item_id in SectSystem.MARKET_ITEMS:
		var def: Dictionary = SectSystem.MARKET_ITEMS[item_id]
		var bought_count := int(purchases.get(item_id, 0))
		var limit := int(def.get("limit", 10))
		var is_sold_out := bought_count >= limit

		var card := PanelContainer.new()
		var box := UiMaterial.hud_paper()
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", box)
		grid.add_child(card)

		var row := HBoxContainer.new()
		card.add_child(row)
		_add_market_art(row, item_id)

		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vb)

		var name_lbl := Label.new()
		name_lbl.text = "%s  (%s：%d / %d)" % [String(def.name), "終身限購" if def.has("min_era") else "限購", bought_count, limit]
		name_lbl.tooltip_text = String(def.desc)
		name_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
		name_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		info_vb.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = String(def.desc)
		if def.has("min_era"): desc_lbl.set_meta("p1_description", true)
		desc_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		desc_lbl.add_theme_font_size_override("font_size", 16)
		info_vb.add_child(desc_lbl)

		var cost_lbl := Label.new()
		cost_lbl.text = "兌換價格：宗門貢獻 %d 點" % int(def.cost)
		if def.has("min_era") and item_id not in SectSystem.P2_MARKET: cost_lbl.set_meta("p1_market_cost", item_id)
		if item_id in SectSystem.P2_MARKET:
			card.set_meta("content_id", item_id)
			cost_lbl.text = "%d貢獻 → %s%d · 需當世%s／%s · 餘%d次" % [int(def.cost), "精鐵" if item_id == "refined_iron_reserve" else "千年草", int(def.grant_amount), "元嬰" if int(def.min_era) == 4 else "化神", "寒銀已開" if def.requires_open_island == "deep" else "古藥已開", maxi(0, limit-bought_count)]
			_p2_market_layouts.append({"title":name_lbl,"cost":cost_lbl,"info":info_vb,"art":row.get_child(0),"box":box,"full_cost":cost_lbl.text,"short_cost":cost_lbl.text.get_slice(" · 餘",0).replace("需當世", "當世").replace("千年草", "千草")})
		cost_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		cost_lbl.add_theme_font_size_override("font_size", 16)
		info_vb.add_child(cost_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "售罄" if is_sold_out else "兌換物資"
		buy_btn.disabled = is_sold_out
		buy_btn.custom_minimum_size = Vector2(90, 44)
		buy_btn.pressed.connect(_on_buy_market_item_pressed.bind(item_id))
		row.add_child(buy_btn)
		_dynamic.append(func():
			var enough := _has_contribution(float(def.cost))
			var destination := SectSystem.market_destination_error(_cached_state, item_id, SaveManager.content())
			buy_btn.disabled = is_sold_out or not enough or not destination.is_empty()
			buy_btn.text = "售罄" if is_sold_out else (_market_status(destination) if not destination.is_empty() else ("兌換物資" if enough else "貢獻不足"))
			buy_btn.tooltip_text = cost_lbl.text + "；含在途預留的祖島有效容量足夠才整包交付，不扣款或占次數於拒絕時。" if item_id in SectSystem.P2_MARKET else ("需當世築基；全額交付，空間不足不扣貢獻也不占次數。" if def.has("min_era") else "")
		)

func _on_claim_expedition_pressed() -> void:
	claim_expedition_requested.emit()

func _on_refresh_tasks_pressed() -> void:
	refresh_tasks_requested.emit()

func _on_start_expedition_pressed(task_id: String) -> void:
	start_expedition_requested.emit(task_id)

func _on_learn_technique_pressed(tech_id: String) -> void:
	learn_technique_requested.emit(tech_id)

func _on_buy_market_item_pressed(item_id: String) -> void:
	buy_market_item_requested.emit(item_id)

func _add_small_icon(parent: Node, texture: Texture2D, tip: String) -> TextureRect:
	var icon := UiIllustration.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(28, 28)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.tooltip_text = tip
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(icon)
	return icon

func _add_rarity(parent: Node, task: Dictionary) -> void:
	var icon := _add_small_icon(parent, RARITY_ICON, String(task.get("rarity_name", "普通")))
	icon.name = "Rarity"
	icon.custom_minimum_size = Vector2(22, 22)
	icon.self_modulate = RARITY_COLORS.get(String(task.get("rarity", "common")), Color.WHITE)

func _add_rewards(parent: Node, rewards: Dictionary) -> void:
	var flow := HFlowContainer.new()
	flow.name = "Rewards"
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 2)
	parent.add_child(flow)
	var names := {"contribution":"宗門貢獻", "money":"金錢", "stone_low":"下品靈石", "spirit_grass_low":"靈草", "herb":"靈草", "black_copper":"玄銅", "special_buff":"頓悟靈光"}
	for key in rewards:
		var reward := HBoxContainer.new()
		reward.add_theme_constant_override("separation", 3)
		reward.tooltip_text = String(names.get(key, ResourceIconScript.get_resource_name(String(key))))
		flow.add_child(reward)
		var id: String = "spirit_grass_low" if key == "herb" else String(key)
		var texture: Texture2D = CONTRIBUTION_ICON if key == "contribution" else ResourceIconScript.TEXTURES.get(id)
		if texture != null: _add_small_icon(reward, texture, reward.tooltip_text)
		var value := Label.new()
		value.set_meta("reward_value", true)
		value.text = "+%s" % str(rewards[key]) if texture != null else ("頓悟靈光" if key == "special_buff" else "%s +%s" % [reward.tooltip_text, str(rewards[key])])
		value.add_theme_font_size_override("font_size", 16)
		reward.add_child(value)

func _add_art(row: HBoxContainer, id: String) -> void:
	var art := UiIllustration.new()
	art.texture = load(ART_DIR + id + ".png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2.ONE * (80 if _compact else 112)
	_art_nodes.append(art)
	row.add_child(art)

func _new_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2 if size.x >= 1040 else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_tab_content_container.add_child(grid)
	_grids.append(grid)
	return grid

func _add_market_art(row: HBoxContainer, id: String) -> void:
	if id == "herb_nurture_supply":
		var art := UiIllustration.new()
		art.texture = load("res://assets/ui/pills-painted/herb_nurture_pill.png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.custom_minimum_size = Vector2.ONE * (80 if _compact else 112)
		_art_nodes.append(art)
		row.add_child(art)
		return
	var files := {"greenwood_bundle":"wood", "herb_bundle":"spirit_grass_low", "stone_bundle":"stone_low", "foundation_pill":"foundation_pill"}
	if files.has(id):
		var art := UiIllustration.new()
		art.texture = load("res://assets/ui/resources-painted/" + files[id] + ".png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2.ONE * (80 if _compact else 112)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_art_nodes.append(art)
		row.add_child(art)
	else:
		var seal := Label.new()
		seal.text = {"refined_iron_reserve":"精鐵", "ancient_herb_reserve":"千草"}.get(id, "晶")
		seal.custom_minimum_size = Vector2(80,80)
		seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seal.tooltip_text = {"refined_iron_reserve":"精鐵 · 尚無專圖，以具名字印表示", "ancient_herb_reserve":"千年靈草 · 尚無專圖，以具名字印表示"}.get(id, "靈晶 · 尚無專用圖像，以字印表示")
		row.add_child(seal)

static func _task_art(task_name: String) -> String:
	if "採" in task_name or "靈田" in task_name: return "gathering"
	if "護送" in task_name: return "escort"
	if "探" in task_name: return "exploration"
	return "warding"

func _wrap_card_labels(node: Node) -> void:
	if node is Button: node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if node is PanelContainer: node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if node is Label:
		node.add_theme_color_override("font_color", UiMaterial.INK)
		if node.has_meta("reward_value"):
			return
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if node.tooltip_text.is_empty(): node.tooltip_text = node.text
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in node.get_children(): _wrap_card_labels(child)

func _has_contribution(cost: float) -> bool:
	var parsed := AmountCompat.try_parse(String(_cached_sect_data.get("contribution","0")))
	return bool(parsed.get("ok",false)) and parsed.value.compare_to(AmountCompat.from_number(cost)) >= 0

func set_command_result(result: Dictionary, saved: Dictionary = {}) -> void:
	_feedback_row.show()
	if not bool(result.get("ok",false)):
		_feedback.text = "操作未完成：" + str(result.get("error","未知"))
		_retry.visible = _pending_save
	elif not bool(saved.get("ok",false)):
		_pending_save = true
		_feedback.text = "操作已生效，保存失敗：" + str(saved.get("error","未知")) + "；請重試保存。"
		_retry.show()
	else:
		_pending_save = false
		_feedback.text = "操作已完成並保存。"
		_retry.hide()
	_feedback.tooltip_text = _feedback.text
	_queue_header_reflow()

func set_save_result(result: Dictionary) -> void:
	if bool(result.get("ok",false)): storage_recovered()
	else: set_command_result({"ok":true},result)

func storage_recovered() -> void:
	if _pending_save:
		_pending_save = false
		_feedback.text = "保存已恢復，操作結果已保存。"
		_retry.hide()
		_queue_header_reflow()

func _p2_effect_signature(state: GameState) -> Array:
	return [BeastSystem.feed_costs(state, "iron_turtle"), BeastSystem.feed_costs(state, "fire_phoenix")]

func _p2_technique_preview(id: String) -> String:
	var level := int(_cached_sect_data.get("techniques", {}).get(id, 0))
	var preview := _cached_state.duplicate_state()
	preview.sect.techniques[id] = mini(5, level+1)
	var next_label := "圓滿" if level >= 5 else "下階"
	if id == "p2_pill_qi_conservation":
		var current: AmountCompat = AlchemySystem.refinement_cost(_cached_state, "nascent_breath_pill", 1).lingli
		var following: AmountCompat = AlchemySystem.refinement_cost(preview, "nascent_breath_pill", 1).lingli
		return "八丹僅直接靈力 · 凝嬰每顆 %s → %s %s\n其他丹材不折，批量同率；八丹名單見提示。" % [current.to_display_string(), next_label, following.to_display_string()]
	var turtle := BeastSystem.feed_costs(_cached_state, "iron_turtle")
	var next_turtle := BeastSystem.feed_costs(preview, "iron_turtle")
	var phoenix := BeastSystem.feed_costs(_cached_state, "fire_phoenix")
	var next_phoenix := BeastSystem.feed_costs(preview, "fire_phoenix")
	return "玄龜 鐵%d／石%d → %s 鐵%d／石%d\n火鳳（煉虛）草%d → %d；第2–5階草費不再降。" % [turtle.refined_iron, turtle.stone_low, next_label, next_turtle.refined_iron, next_turtle.stone_low, phoenix.spirit_grass_1000y, next_phoenix.spirit_grass_1000y]

func _p2_short_technique_preview(id: String) -> String:
	var level := int(_cached_sect_data.get("techniques", {}).get(id, 0))
	var preview := _cached_state.duplicate_state()
	preview.sect.techniques[id] = mini(5, level+1)
	if id == "p2_pill_qi_conservation":
		return "凝嬰靈力 %s→%s\n八丹直接靈力；其他不折" % [AlchemySystem.refinement_cost(_cached_state,"nascent_breath_pill",1).lingli.to_display_string(),AlchemySystem.refinement_cost(preview,"nascent_breath_pill",1).lingli.to_display_string()]
	var turtle := BeastSystem.feed_costs(_cached_state,"iron_turtle")
	var next_turtle := BeastSystem.feed_costs(preview,"iron_turtle")
	var phoenix := BeastSystem.feed_costs(_cached_state,"fire_phoenix")
	var next_phoenix := BeastSystem.feed_costs(preview,"fire_phoenix")
	return "龜鐵%d石%d→%d／%d\n鳳(煉虛)草%d→%d；2–5階同費" % [turtle.refined_iron,turtle.stone_low,next_turtle.refined_iron,next_turtle.stone_low,phoenix.spirit_grass_1000y,next_phoenix.spirit_grass_1000y]

func _technique_status(error: String) -> String:
	return {"":"參悟提升", "TECHNIQUE_MAX_LEVEL":"已圓滿", "TECHNIQUE_ERA_LOCKED":"境界未達", "TECHNIQUE_SUPPLY_REQUIRED":"供給未開", "LIFESPAN_EXHAUSTED":"壽元已盡", "SECT_LOCKED":"需先入宗"}.get(error, "資源不足")

func _market_status(error: String) -> String:
	return {"MARKET_ERA_LOCKED":"境界未達", "MARKET_ISLAND_LOCKED":"來源島未開", "MARKET_SUPPLY_REQUIRED":"供給未開", "LIFESPAN_EXHAUSTED":"壽元已盡", "SECT_LOCKED":"需先入宗", "MARKET_DESTINATION_FULL":"庫存已滿", "PILL_INVENTORY_CAP":"庫存已滿"}.get(error, "容量未就緒")

func _p2_pill_names() -> String:
	var names := PackedStringArray()
	for id in SectSystem.P2_PILL_IDS: names.append(String(AlchemySystem.PILLS[id].name))
	return "、".join(names) + "；僅直接靈力費，不改服用效果。"
