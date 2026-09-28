class_name SectPanel
extends Control

signal join_sect_requested(sect_name: String)
signal refresh_tasks_requested()
signal start_expedition_requested(task_id: String)
signal claim_expedition_requested()
signal learn_technique_requested(tech_id: String)
signal buy_market_item_requested(item_id: String)
signal close_requested()

enum TabMode { EXPEDITIONS, TECHNIQUES, MARKET }

var _background: Panel
var _header_container: VBoxContainer
var _title_row: HBoxContainer
var _title_label: Label
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
var _cached_is_eligible_to_join: bool = false

const SECT_FLAVORS := {
	"太虛天闕": "道門正宗 · 吐納浩然，周天靈氣生生不息",
	"天劍聖宗": "劍道至尊 · 凌厲殺伐，一心向道修為精進",
	"縹緲仙宮": "仙家勝境 · 造化靈秀，草木靈根產量豐沛",
	"萬佛靈宗": "佛光普照 · 金身不滅，壽元綿長道心無漏",
	"紫霄玄門": "九天雷動 · 天威正氣，天地資產周流不息",
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
	var pad := 14.0
	var avail_w := maxf(0.0, size.x - pad * 2.0)
	var header_h := 0.0
	if _header_container != null:
		_header_container.position = Vector2(pad, pad)
		_header_container.size = Vector2(avail_w, 0)
		header_h = _header_container.get_combined_minimum_size().y
		_header_container.size = Vector2(avail_w, header_h)
	if _scroll != null:
		var scroll_top := pad + header_h + 10.0
		var scroll_h := maxf(60.0, size.y - scroll_top - pad)
		_scroll.position = Vector2(pad, scroll_top)
		_scroll.size = Vector2(avail_w, scroll_h)
		_scroll.custom_minimum_size = Vector2(0, 0)
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func _build_ui() -> void:
	clip_contents = true
	_background = Panel.new()
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.08, 0.10, 0.14, 0.98)
	bg_box.border_color = Color(0.7, 0.55, 0.25, 0.8)
	bg_box.border_width_left = 1
	bg_box.border_width_top = 1
	bg_box.border_width_right = 1
	bg_box.border_width_bottom = 1
	bg_box.corner_radius_top_left = 8
	bg_box.corner_radius_top_right = 8
	bg_box.corner_radius_bottom_left = 8
	bg_box.corner_radius_bottom_right = 8
	_background.add_theme_stylebox_override("panel", bg_box)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	_header_container = VBoxContainer.new()
	_header_container.name = "SectHeaderContainer"
	_header_container.add_theme_constant_override("separation", 10)
	add_child(_header_container)

	# 1. 頂部標題列
	_title_row = HBoxContainer.new()
	_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_container.add_child(_title_row)

	_title_label = Label.new()
	_title_label.text = "【宗門外務】· 太虛天闕"
	_title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_row.add_child(_title_label)

	_contrib_label = Label.new()
	_contrib_label.text = "貢獻：0 點"
	_contrib_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_title_row.add_child(_contrib_label)

	var space := Control.new()
	space.custom_minimum_size = Vector2(10, 0)
	_title_row.add_child(space)

	_close_button = Button.new()
	_close_button.text = "關閉"
	_close_button.custom_minimum_size = Vector2(70, 32)
	_close_button.pressed.connect(func(): close_requested.emit())
	_title_row.add_child(_close_button)

	# 2. 狀態或概覽橫幅
	_banner_panel = PanelContainer.new()
	var b_box := StyleBoxFlat.new()
	b_box.bg_color = Color(0.12, 0.16, 0.22, 0.95)
	b_box.border_color = Color(0.35, 0.65, 0.85, 0.5)
	b_box.border_width_left = 1
	b_box.border_width_top = 1
	b_box.border_width_right = 1
	b_box.border_width_bottom = 1
	b_box.corner_radius_top_left = 6
	b_box.corner_radius_top_right = 6
	b_box.corner_radius_bottom_left = 6
	b_box.corner_radius_bottom_right = 6
	b_box.content_margin_left = 12
	b_box.content_margin_right = 12
	b_box.content_margin_top = 6
	b_box.content_margin_bottom = 6
	_banner_panel.add_theme_stylebox_override("panel", b_box)
	_header_container.add_child(_banner_panel)

	_banner_label = Label.new()
	_banner_label.text = "派遣門下弟子遊歷天下，獲取天地靈珍與宗門功勳，參悟護道真訣。"
	_banner_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_panel.add_child(_banner_label)

	# 3. 分頁標籤按鈕
	_tab_row = HBoxContainer.new()
	_tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_row.add_theme_constant_override("separation", 8)
	_header_container.add_child(_tab_row)

	_tab_expeditions_btn = Button.new()
	_tab_expeditions_btn.text = "歷練委託"
	_tab_expeditions_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_expeditions_btn.pressed.connect(func(): _switch_tab(TabMode.EXPEDITIONS))
	_tab_row.add_child(_tab_expeditions_btn)

	_tab_techniques_btn = Button.new()
	_tab_techniques_btn.text = "秘術傳承"
	_tab_techniques_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_techniques_btn.pressed.connect(func(): _switch_tab(TabMode.TECHNIQUES))
	_tab_row.add_child(_tab_techniques_btn)

	_tab_market_btn = Button.new()
	_tab_market_btn.text = "宗門坊市"
	_tab_market_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_market_btn.pressed.connect(func(): _switch_tab(TabMode.MARKET))
	_tab_row.add_child(_tab_market_btn)

	# 4. 滾動主區域（作為 SectPanel 同級子節點，獨立受控於 set_layout_bounds）
	_scroll = ScrollContainer.new()
	_scroll.name = "SectScroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)

	_tab_content_container = VBoxContainer.new()
	_tab_content_container.name = "TabContent"
	_tab_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_content_container.add_theme_constant_override("separation", 10)
	_scroll.add_child(_tab_content_container)

func _switch_tab(mode: TabMode) -> void:
	_current_tab = mode
	_render_current_tab()

func update_view(state: GameState) -> void:
	if _header_container == null:
		_build_ui()
	if state == null:
		return
	var sect: Dictionary = SectSystem.ensure_sect_state(state)
	_cached_sect_data = sect
	_cached_resources = state.resources
	_cached_is_eligible_to_join = SectSystem.is_unlocked(state)

	var is_unlocked := bool(sect.get("unlocked", false))
	var s_name := String(sect.get("sect_name", "太虛天闕"))
	var contrib_str := String(sect.get("contribution", "0"))
	var c_parsed := AmountCompat.try_parse(contrib_str)
	var contrib_display := int(c_parsed["value"].to_float()) if bool(c_parsed.get("ok", false)) else 0

	_title_label.text = "【宗門外務】· " + s_name if is_unlocked else "【尋仙訪道】· 拜入山門"
	_contrib_label.text = "宗門貢獻：%d 點" % contrib_display if is_unlocked else ""
	_tab_row.visible = is_unlocked
	if not is_unlocked:
		_banner_label.text = "派遣門下弟子遊歷天下，獲取天地靈珍與宗門功勳，參悟護道真訣。" if _cached_is_eligible_to_join else "仙途漫漫，唯仙基穩固（築基期或歷經轉世）方具立誓拜入仙門之資。"
	else:
		_banner_label.text = "派遣門下弟子遊歷天下，獲取天地靈珍與宗門功勳，參悟護道真訣。"

	_render_current_tab()
	set_layout_bounds(Rect2(position, size))

func _render_current_tab() -> void:
	# 清空容器
	for child in _tab_content_container.get_children():
		_tab_content_container.remove_child(child)
		child.queue_free()

	var is_unlocked := bool(_cached_sect_data.get("unlocked", false))
	if not is_unlocked:
		_render_join_panel()
		return

	# 高亮分頁按鈕樣式
	_tab_expeditions_btn.modulate = Color(1.2, 1.2, 1.2) if _current_tab == TabMode.EXPEDITIONS else Color(0.7, 0.7, 0.7)
	_tab_techniques_btn.modulate = Color(1.2, 1.2, 1.2) if _current_tab == TabMode.TECHNIQUES else Color(0.7, 0.7, 0.7)
	_tab_market_btn.modulate = Color(1.2, 1.2, 1.2) if _current_tab == TabMode.MARKET else Color(0.7, 0.7, 0.7)

	match _current_tab:
		TabMode.EXPEDITIONS:
			_render_expeditions_tab()
		TabMode.TECHNIQUES:
			_render_techniques_tab()
		TabMode.MARKET:
			_render_market_tab()

# ================= 拜入宗門介面 =================
func _render_join_panel() -> void:
	var is_eligible := _cached_is_eligible_to_join

	var intro_card := PanelContainer.new()
	var intro_box := StyleBoxFlat.new()
	intro_box.bg_color = Color(0.12, 0.15, 0.20, 0.95)
	intro_box.border_color = Color(0.8, 0.65, 0.2, 0.8) if is_eligible else Color(0.85, 0.4, 0.35, 0.8)
	intro_box.border_width_left = 1
	intro_box.border_width_top = 1
	intro_box.border_width_right = 1
	intro_box.border_width_bottom = 1
	intro_box.corner_radius_top_left = 8
	intro_box.corner_radius_top_right = 8
	intro_box.corner_radius_bottom_left = 8
	intro_box.corner_radius_bottom_right = 8
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
		h_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	else:
		h_lbl.text = "【未達門檻 · 需達築基期方可拜入】"
		h_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	h_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
	h_lbl.add_theme_font_size_override("font_size", 16)
	intro_vb.add_child(h_lbl)

	var desc_lbl := Label.new()
	if is_eligible:
		desc_lbl.text = "拜入宗門後，即可派遣分身弟子外出歷練，採集天地靈草玄鐵、換取專屬秘術傳承，並在宗門坊市兌換珍貴築基丹藥與靈晶。"
	else:
		desc_lbl.text = "各大宗門門規森嚴，需道友突破至第二重境界【築基期】或歷經轉世，方具拜入門戶之資。請先在洞府納靈營造，早日築基！"
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.88, 0.95))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_vb.add_child(desc_lbl)

	# 宗門清單標題
	var sects_lbl := Label.new()
	sects_lbl.text = "【名門正派 · 擇一立誓】" if is_eligible else "【五大名門 · 預覽傳承】"
	sects_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
	sects_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_tab_content_container.add_child(sects_lbl)

	# 垂直排列的各宗門卡片，完全自適應且永遠不會水平截斷
	for s_name in SectSystem.SECT_NAMES:
		var s_card := PanelContainer.new()
		var s_box := StyleBoxFlat.new()
		s_box.bg_color = Color(0.10, 0.13, 0.18, 0.9)
		s_box.border_color = Color(0.3, 0.45, 0.6, 0.5)
		s_box.border_width_left = 1
		s_box.border_width_top = 1
		s_box.border_width_right = 1
		s_box.border_width_bottom = 1
		s_box.corner_radius_top_left = 6
		s_box.corner_radius_top_right = 6
		s_box.corner_radius_bottom_left = 6
		s_box.corner_radius_bottom_right = 6
		s_box.content_margin_left = 12
		s_box.content_margin_right = 12
		s_box.content_margin_top = 8
		s_box.content_margin_bottom = 8
		s_card.add_theme_stylebox_override("panel", s_box)
		_tab_content_container.add_child(s_card)

		var s_row := HBoxContainer.new()
		s_row.add_theme_constant_override("separation", 10)
		s_card.add_child(s_row)

		var s_info := VBoxContainer.new()
		s_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s_row.add_child(s_info)

		var s_title := Label.new()
		s_title.text = "【%s】" % s_name
		s_title.add_theme_font_override("font", UiTypography.emphasis_font())
		s_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		s_info.add_child(s_title)

		var s_desc := Label.new()
		s_desc.text = SECT_FLAVORS.get(s_name, "玄門妙法，各顯神通。")
		s_desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.88))
		s_desc.add_theme_font_size_override("font_size", 12)
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
		j_btn.custom_minimum_size = Vector2(96, 36)
		s_row.add_child(j_btn)

func _on_join_pressed(s_name: String) -> void:
	join_sect_requested.emit(s_name)

# ================= 歷練委託分頁 =================
func _render_expeditions_tab() -> void:
	var active = _cached_sect_data.get("active_expedition")
	var is_active: bool = (active != null and active is Dictionary)

	# 1. 進行中歷練卡片
	var active_panel := PanelContainer.new()
	var act_box := StyleBoxFlat.new()
	act_box.bg_color = Color(0.15, 0.18, 0.24, 0.95) if is_active else Color(0.10, 0.12, 0.15, 0.8)
	act_box.border_color = Color(0.9, 0.7, 0.2, 0.8) if is_active else Color(0.3, 0.35, 0.4, 0.5)
	act_box.border_width_left = 1
	act_box.border_width_top = 1
	act_box.border_width_right = 1
	act_box.border_width_bottom = 1
	act_box.corner_radius_top_left = 6
	act_box.corner_radius_top_right = 6
	act_box.corner_radius_bottom_left = 6
	act_box.corner_radius_bottom_right = 6
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
		var a_title := Label.new()
		var rarity_name: String = String(active.get("rarity_name", "普通"))
		var t_name: String = String(active.get("name", "歷練"))
		a_title.text = "⏳【當前歷練中】[%s] %s" % [rarity_name, t_name]
		a_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		act_vb.add_child(a_title)

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
		status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if is_finished else Color(0.8, 0.9, 1.0))
		status_row.add_child(status_lbl)

		var claim_btn := Button.new()
		claim_btn.text = "🎁 領取歷練獎勵" if is_finished else "歷練中..."
		claim_btn.disabled = not is_finished
		claim_btn.custom_minimum_size = Vector2(120, 32)
		claim_btn.pressed.connect(_on_claim_expedition_pressed)
		status_row.add_child(claim_btn)
	else:
		var idle_lbl := Label.new()
		idle_lbl.text = "⛩️ 當前無進行中歷練，可從下方挑選委託派遣分身。"
		idle_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.85))
		act_vb.add_child(idle_lbl)

	# 2. 待接委託清單標題與手動刷新
	var list_header := HBoxContainer.new()
	_tab_content_container.add_child(list_header)

	var sub_title := Label.new()
	sub_title.text = "📜 宗門懸賞委託清單"
	sub_title.add_theme_font_override("font", UiTypography.emphasis_font())
	sub_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_header.add_child(sub_title)

	var refresh_cd := int(_cached_sect_data.get("next_refresh_seconds", 0))
	var refresh_btn := Button.new()
	refresh_btn.text = "🔄 刷新委託" if refresh_cd <= 0 else "冷卻中 (%ds)" % refresh_cd
	refresh_btn.disabled = refresh_cd > 0
	refresh_btn.pressed.connect(_on_refresh_tasks_pressed)
	list_header.add_child(refresh_btn)

	# 3. 委託清單項目
	var tasks: Array = _cached_sect_data.get("available_tasks", [])
	if tasks.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "暫無可接委託，請點擊上方刷新委託。"
		_tab_content_container.add_child(empty_lbl)
	else:
		for task in tasks:
			var t_card := _create_task_card(task, is_active)
			_tab_content_container.add_child(t_card)

func _create_task_card(task: Dictionary, is_active: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.12, 0.15, 0.20, 0.9)
	box.border_color = Color(0.3, 0.4, 0.5, 0.5)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_vb)

	var r_name: String = String(task.get("rarity_name", "普通"))
	var r_color := Color.from_string(String(task.get("rarity_color", "#cccccc")), Color.WHITE)
	var t_name: String = String(task.get("name", ""))
	var duration: int = int(task.get("duration", 60))

	var name_lbl := Label.new()
	name_lbl.text = "[%s] %s  (時長：%d 秒)" % [r_name, t_name, duration]
	name_lbl.add_theme_color_override("font_color", r_color)
	info_vb.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = String(task.get("desc", ""))
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	info_vb.add_child(desc_lbl)

	var rewards: Dictionary = task.get("rewards", {})
	var r_text := "預期獎勵：貢獻 +%d | 金錢 +%d" % [int(rewards.get("contribution", 0)), int(rewards.get("money", 0))]
	if rewards.has("stone_low"):
		r_text += " | 下品靈石 +%d" % int(rewards["stone_low"])
	if rewards.has("herb"):
		r_text += " | 靈草 +%d" % int(rewards["herb"])
	if rewards.has("special_buff"):
		r_text += " | 🌟【頓悟靈光】"
	var rew_lbl := Label.new()
	rew_lbl.text = r_text
	rew_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	rew_lbl.add_theme_font_size_override("font_size", 12)
	info_vb.add_child(rew_lbl)

	var start_btn := Button.new()
	start_btn.text = "派遣歷練"
	start_btn.disabled = is_active
	start_btn.custom_minimum_size = Vector2(90, 36)
	var t_id: String = String(task.get("id", ""))
	start_btn.pressed.connect(_on_start_expedition_pressed.bind(t_id))
	row.add_child(start_btn)

	return card

# ================= 秘術傳承分頁 =================
func _render_techniques_tab() -> void:
	var techs: Dictionary = _cached_sect_data.get("techniques", {})

	for tech_id in SectSystem.TECHNIQUES:
		var def: Dictionary = SectSystem.TECHNIQUES[tech_id]
		var cur_lvl := int(techs.get(tech_id, 0))
		var max_lvl := int(def.get("max_level", 10))

		var card := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.12, 0.15, 0.20, 0.9)
		box.border_color = Color(0.3, 0.45, 0.6, 0.6)
		box.border_width_left = 1
		box.border_width_top = 1
		box.border_width_right = 1
		box.border_width_bottom = 1
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", box)
		_tab_content_container.add_child(card)

		var row := HBoxContainer.new()
		card.add_child(row)

		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vb)

		var title_lbl := Label.new()
		title_lbl.text = "%s  (第 %d / %d 重)" % [String(def.name), cur_lvl, max_lvl]
		title_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
		title_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		info_vb.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = String(def.desc)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		info_vb.add_child(desc_lbl)

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
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		cost_lbl.add_theme_font_size_override("font_size", 12)
		info_vb.add_child(cost_lbl)

		var learn_btn := Button.new()
		learn_btn.text = "參悟提升" if not is_max else "已圓滿"
		learn_btn.disabled = is_max
		learn_btn.custom_minimum_size = Vector2(90, 36)
		learn_btn.pressed.connect(_on_learn_technique_pressed.bind(tech_id))
		row.add_child(learn_btn)

# ================= 宗門坊市分頁 =================
func _render_market_tab() -> void:
	var purchases: Dictionary = _cached_sect_data.get("market_purchases", {})

	for item_id in SectSystem.MARKET_ITEMS:
		var def: Dictionary = SectSystem.MARKET_ITEMS[item_id]
		var bought_count := int(purchases.get(item_id, 0))
		var limit := int(def.get("limit", 10))
		var is_sold_out := bought_count >= limit

		var card := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.12, 0.15, 0.20, 0.9)
		box.border_color = Color(0.6, 0.45, 0.3, 0.5)
		box.border_width_left = 1
		box.border_width_top = 1
		box.border_width_right = 1
		box.border_width_bottom = 1
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", box)
		_tab_content_container.add_child(card)

		var row := HBoxContainer.new()
		card.add_child(row)

		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vb)

		var name_lbl := Label.new()
		name_lbl.text = "%s  (限購：%d / %d)" % [String(def.name), bought_count, limit]
		name_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
		info_vb.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = String(def.desc)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		info_vb.add_child(desc_lbl)

		var cost_lbl := Label.new()
		cost_lbl.text = "兌換價格：宗門貢獻 %d 點" % int(def.cost)
		cost_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
		cost_lbl.add_theme_font_size_override("font_size", 12)
		info_vb.add_child(cost_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "售罄" if is_sold_out else "兌換物資"
		buy_btn.disabled = is_sold_out
		buy_btn.custom_minimum_size = Vector2(90, 36)
		buy_btn.pressed.connect(_on_buy_market_item_pressed.bind(item_id))
		row.add_child(buy_btn)

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
