class_name ReincarnationSequence
extends Control

signal sequence_started
signal sequence_finished

const STAGE_1_END: float = 0.8
const STAGE_2_END: float = 2.4
const TOTAL_DURATION: float = 3.4
const REDUCED_DURATION: float = 0.8

var _camera: Camera2D = null
var _is_playing: bool = false
var _anim_time: float = 0.0
var _reduced_motion: bool = false
var _cycle: int = 1
var _dao_heart_gain: int = 0
var _on_finished_callback: Callable

var _bg_overlay: ColorRect
var _fx_layer: Control
var _ui_layer: MarginContainer
var _center_box: VBoxContainer
var _title_label: Label
var _couplet_label: Label
var _stage_badge: Label
var _result_card: PanelContainer
var _result_summary: Label
var _skip_button: Button
var _finish_button: Button

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTypography.create_theme()
	_build_ui()
	resized.connect(_on_viewport_resized)

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _bg_overlay != null:
		_bg_overlay.size = size
	if _fx_layer != null:
		_fx_layer.size = size
	if _ui_layer != null:
		_ui_layer.size = size
	_on_viewport_resized()

func _build_ui() -> void:
	# 柔光背景遮罩
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0.96, 0.94, 0.86, 0.0)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_overlay)

	# 穿梭粒子與靈光繪製層
	_fx_layer = Control.new()
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.draw.connect(_on_fx_draw)
	add_child(_fx_layer)

	# UI 浮層容器
	_ui_layer = MarginContainer.new()
	_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "right", "top", "bottom"]:
		_ui_layer.add_theme_constant_override("margin_" + edge, 24)
	add_child(_ui_layer)

	# 右上角跳過按鈕
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(top_row)

	_skip_button = Button.new()
	_skip_button.name = "ReincarnationSkipButton"
	_skip_button.text = "跳過演出"
	_skip_button.custom_minimum_size = Vector2(96, 36)
	_skip_button.pressed.connect(skip)
	top_row.add_child(_skip_button)

	# 中央文字與結算卡片
	_center_box = VBoxContainer.new()
	_center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_center_box.add_theme_constant_override("separation", 14)
	_center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_center_box)

	_stage_badge = Label.new()
	_stage_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_badge.text = "【太虛出神】"
	_stage_badge.add_theme_color_override("font_color", Color("ffd580"))
	_stage_badge.add_theme_font_size_override("font_size", 16)
	_center_box.add_child(_stage_badge)

	_title_label = Label.new()
	_title_label.name = "ReincarnationTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.text = "【大道輪迴 · 返璞歸真】"
	_title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_title_label.add_theme_color_override("font_color", Color("fff4d0"))
	_title_label.add_theme_font_size_override("font_size", 28)
	_center_box.add_child(_title_label)

	_couplet_label = Label.new()
	_couplet_label.name = "ReincarnationCouplet"
	_couplet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_couplet_label.text = "肉身有盡，道心無窮。"
	_couplet_label.add_theme_color_override("font_color", Color("d0e4d6"))
	_couplet_label.add_theme_font_size_override("font_size", 20)
	_center_box.add_child(_couplet_label)

	# 結算卡片
	_result_card = PanelContainer.new()
	_result_card.name = "ReincarnationResultCard"
	_result_card.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_result_card.visible = false
	_center_box.add_child(_result_card)

	var card_margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + edge, 16)
	_result_card.add_child(card_margin)

	var card_col := VBoxContainer.new()
	card_col.add_theme_constant_override("separation", 10)
	card_margin.add_child(card_col)

	_result_summary = Label.new()
	_result_summary.name = "ReincarnationSummary"
	_result_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_summary.text = "第 2 世 · 練氣期一層（新生命開展）\n道心收穫：+15"
	_result_summary.add_theme_font_size_override("font_size", 16)
	_result_summary.add_theme_color_override("font_color", Color("eaf2ea"))
	card_col.add_child(_result_summary)

	_finish_button = Button.new()
	_finish_button.name = "ReincarnationFinishButton"
	_finish_button.text = "重聚仙靈 · 入世修行"
	_finish_button.custom_minimum_size = Vector2(160, 44)
	_finish_button.pressed.connect(_on_finish_pressed)
	card_col.add_child(_finish_button)

func _on_viewport_resized() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var portrait := size.x < 640.0 or size.x / size.y < 1.25
	_title_label.add_theme_font_size_override("font_size", 22 if portrait else 28)
	_couplet_label.add_theme_font_size_override("font_size", 16 if portrait else 20)
	if _fx_layer != null:
		_fx_layer.queue_redraw()

func play(camera: Camera2D, cycle: int, dao_heart_gain: int, on_finished: Callable, reduced_motion: bool = false) -> void:
	_camera = camera
	_cycle = cycle
	_dao_heart_gain = dao_heart_gain
	_on_finished_callback = on_finished
	_reduced_motion = reduced_motion
	_anim_time = 0.0
	_is_playing = true

	_result_card.visible = false
	_skip_button.visible = true
	_stage_badge.text = "【太虛出神】"
	_couplet_label.text = "肉身有盡，道心無窮。"
	_result_summary.text = "第 %d 世 · 練氣初境（肉身重塑）\n本次轉世凝聚道心：+%d 點" % [_cycle, _dao_heart_gain]

	if _camera != null:
		_camera.input_locked = true
		_camera.position = Vector2(0, -100)
		_camera.zoom = Vector2(0.08, 0.08)
		_camera.target_position = Vector2(0, -100)
		_camera.target_zoom = 0.08

	visible = true
	sequence_started.emit()
	print("ABODE_REINCARNATION_SEQUENCE_STARTED: cycle=", _cycle)
	_fx_layer.queue_redraw()

func _process(delta: float) -> void:
	if not _is_playing:
		return
	_anim_time += delta
	var max_dur := REDUCED_DURATION if _reduced_motion else TOTAL_DURATION

	if _reduced_motion:
		# 無障礙模式：純淡入淡出並落定
		var t := clampf(_anim_time / REDUCED_DURATION, 0.0, 1.0)
		_bg_overlay.color.a = sin(t * PI) * 0.45
		if _camera != null:
			_camera.position = Vector2(0, -40)
			_camera.zoom = Vector2(0.70, 0.70)
			_camera.target_position = Vector2(0, -40)
			_camera.target_zoom = 0.70
		if _anim_time >= REDUCED_DURATION:
			_show_result_card()
		return

	# 正常三階段運鏡與特效
	if _anim_time <= STAGE_1_END:
		# 階段一：太虛出神（Cosmos 視野 0.08，白金微光淡入）
		var t1 := clampf(_anim_time / STAGE_1_END, 0.0, 1.0)
		_bg_overlay.color.a = lerpf(0.0, 0.40, t1)
		_stage_badge.text = "【太虛出神 · 俯瞰九界】"
		_couplet_label.text = "肉身有盡，道心無窮。"
		if _camera != null:
			_camera.position = Vector2(0, -100)
			_camera.zoom = Vector2(0.08, 0.08)
			_camera.target_position = Vector2(0, -100)
			_camera.target_zoom = 0.08

	elif _anim_time <= STAGE_2_END:
		# 階段二：穿越輪迴（0.08 平滑放大至 0.70，穿梭光絲）
		var t2 := (_anim_time - STAGE_1_END) / (STAGE_2_END - STAGE_1_END)
		var curve := t2 * t2 # 加速下沉感
		_bg_overlay.color.a = lerpf(0.40, 0.12, t2)
		_stage_badge.text = "【神遊太虛 · 歷劫歸真】"
		_couplet_label.text = "歷經千劫，神返靈山。"
		if _camera != null:
			var current_pos := Vector2(0, -100).lerp(Vector2(0, -40), curve)
			var current_zoom := lerpf(0.08, 0.70, curve)
			_camera.position = current_pos
			_camera.zoom = Vector2(current_zoom, current_zoom)
			_camera.target_position = current_pos
			_camera.target_zoom = current_zoom

	else:
		# 階段三：仙身聚頂（落地 Home 視野 0.70，靈環爆發）
		var t3 := clampf((_anim_time - STAGE_2_END) / (TOTAL_DURATION - STAGE_2_END), 0.0, 1.0)
		_stage_badge.text = "【重塑仙身 · 再問長生】"
		_couplet_label.text = "重聚仙靈，再問長生！"
		if _camera != null:
			_camera.position = Vector2(0, -40)
			_camera.zoom = Vector2(0.70, 0.70)
			_camera.target_position = Vector2(0, -40)
			_camera.target_zoom = 0.70
		if _anim_time >= TOTAL_DURATION:
			if not _result_card.visible:
				_show_result_card()
		else:
			_bg_overlay.color.a = lerpf(0.12, 0.0, t3)

	_fx_layer.queue_redraw()

func _on_fx_draw() -> void:
	if not _is_playing or _reduced_motion:
		return
	var center := size * 0.5

	# 預先定義 22 道不規則爆發光柱參數：角度非對稱、粗細相間、發射時差錯落
	const RAYS_DEF: Array = [
		{"angle_deg": 12.0,  "w_base": 38.0, "w_tip": 12.0, "max_len": 780.0, "delay": 0.05, "dur": 0.65},
		{"angle_deg": 28.0,  "w_base": 16.0, "w_tip": 4.0,  "max_len": 540.0, "delay": 0.22, "dur": 0.50},
		{"angle_deg": 46.0,  "w_base": 48.0, "w_tip": 16.0, "max_len": 880.0, "delay": 0.00, "dur": 0.70},
		{"angle_deg": 68.0,  "w_base": 22.0, "w_tip": 6.0,  "max_len": 620.0, "delay": 0.15, "dur": 0.55},
		{"angle_deg": 95.0,  "w_base": 42.0, "w_tip": 14.0, "max_len": 820.0, "delay": 0.08, "dur": 0.68},
		{"angle_deg": 118.0, "w_base": 18.0, "w_tip": 5.0,  "max_len": 560.0, "delay": 0.28, "dur": 0.48},
		{"angle_deg": 136.0, "w_base": 52.0, "w_tip": 18.0, "max_len": 920.0, "delay": 0.02, "dur": 0.72},
		{"angle_deg": 154.0, "w_base": 24.0, "w_tip": 7.0,  "max_len": 640.0, "delay": 0.18, "dur": 0.52},
		{"angle_deg": 172.0, "w_base": 36.0, "w_tip": 11.0, "max_len": 750.0, "delay": 0.10, "dur": 0.60},
		{"angle_deg": 195.0, "w_base": 20.0, "w_tip": 6.0,  "max_len": 580.0, "delay": 0.25, "dur": 0.50},
		{"angle_deg": 214.0, "w_base": 46.0, "w_tip": 15.0, "max_len": 860.0, "delay": 0.04, "dur": 0.68},
		{"angle_deg": 232.0, "w_base": 14.0, "w_tip": 4.0,  "max_len": 510.0, "delay": 0.32, "dur": 0.45},
		{"angle_deg": 248.0, "w_base": 40.0, "w_tip": 13.0, "max_len": 790.0, "delay": 0.12, "dur": 0.62},
		{"angle_deg": 272.0, "w_base": 56.0, "w_tip": 20.0, "max_len": 950.0, "delay": 0.00, "dur": 0.75},
		{"angle_deg": 296.0, "w_base": 22.0, "w_tip": 6.0,  "max_len": 610.0, "delay": 0.20, "dur": 0.54},
		{"angle_deg": 312.0, "w_base": 34.0, "w_tip": 10.0, "max_len": 730.0, "delay": 0.14, "dur": 0.58},
		{"angle_deg": 330.0, "w_base": 18.0, "w_tip": 5.0,  "max_len": 570.0, "delay": 0.30, "dur": 0.46},
		{"angle_deg": 348.0, "w_base": 44.0, "w_tip": 14.0, "max_len": 840.0, "delay": 0.06, "dur": 0.66},
		# 額外補強的幾道先導極光束
		{"angle_deg": 38.0,  "w_base": 12.0, "w_tip": 3.0,  "max_len": 690.0, "delay": 0.02, "dur": 0.40},
		{"angle_deg": 142.0, "w_base": 10.0, "w_tip": 3.0,  "max_len": 670.0, "delay": 0.04, "dur": 0.42},
		{"angle_deg": 220.0, "w_base": 12.0, "w_tip": 3.0,  "max_len": 710.0, "delay": 0.03, "dur": 0.38},
		{"angle_deg": 285.0, "w_base": 14.0, "w_tip": 4.0,  "max_len": 740.0, "delay": 0.01, "dur": 0.44},
	]

	# 階段二：穿越虛空與神聖光芒爆發（附圖效果）
	if _anim_time > STAGE_1_END and _anim_time <= STAGE_2_END:
		var stage2_progress := (_anim_time - STAGE_1_END) / (STAGE_2_END - STAGE_1_END) # 0.0 ~ 1.0 (時長 1.6s)

		# 1. 繪製非同步、不規則角度與粗細的光芒光柱
		for ray in RAYS_DEF:
			var delay: float = ray["delay"]
			var dur: float = ray["dur"]
			if stage2_progress < delay:
				continue
			var local_t := clampf((stage2_progress - delay) / dur, 0.0, 1.0)
			if local_t <= 0.0 or local_t >= 1.0:
				continue

			# 生長曲線：前 28% 極速刺出衝至最大長度，中段維持極盛，後段平滑消散
			var len_factor: float
			var alpha_factor: float
			if local_t < 0.28:
				var grow_p := local_t / 0.28
				len_factor = sin(grow_p * PI * 0.5) # 快速衝刺
				alpha_factor = grow_p
			elif local_t < 0.65:
				len_factor = 1.0
				alpha_factor = 1.0
			else:
				var fade_p := (local_t - 0.65) / 0.35
				len_factor = 1.0 + fade_p * 0.15 # 微微繼續延伸擴散
				alpha_factor = 1.0 - (fade_p * fade_p)

			var rad: float = deg_to_rad(ray["angle_deg"])
			var dir := Vector2(cos(rad), sin(rad))
			var norm := Vector2(-dir.y, dir.x)

			var core_r: float = 24.0 + stage2_progress * 45.0
			var cur_len: float = float(ray["max_len"]) * len_factor
			var w_base: float = float(ray["w_base"]) * (0.6 + 0.4 * alpha_factor)
			var w_tip: float = float(ray["w_tip"]) * (0.8 + 0.2 * len_factor)

			var p_base := center + dir * core_r
			var p_tip := center + dir * (core_r + cur_len)

			var v1 := p_base - norm * (w_base * 0.5)
			var v2 := p_base + norm * (w_base * 0.5)
			var v3 := p_tip + norm * (w_tip * 0.5)
			var v4 := p_tip - norm * (w_tip * 0.5)

			# 外層光暈錐（金色天輝）
			var halo_poly := PackedVector2Array([
				p_base - norm * (w_base * 0.8),
				p_base + norm * (w_base * 0.8),
				p_tip + norm * (w_tip * 1.5),
				p_tip - norm * (w_tip * 1.5)
			])
			var halo_col := Color(1.0, 0.90, 0.65, alpha_factor * 0.35)
			_fx_layer.draw_colored_polygon(halo_poly, halo_col)

			# 內層熾熱純白核心柱（附圖核心強烈白光）
			var core_poly := PackedVector2Array([v1, v2, v3, v4])
			var core_col := Color(1.0, 1.0, 0.96, alpha_factor * 0.92)
			_fx_layer.draw_colored_polygon(core_poly, core_col)

		# 2. 繪製中心熾熱能量爆發球體（附圖中央巨大純白能量球）
		var core_grow := sin(clampf(stage2_progress * 1.25, 0.0, 1.0) * PI * 0.5)
		var core_radius := lerpf(18.0, 85.0, core_grow)
		var core_alpha := clampf(sin(stage2_progress * PI), 0.0, 1.0)

		# 外圍光暈
		_fx_layer.draw_circle(center, core_radius * 1.35, Color(1.0, 0.92, 0.70, core_alpha * 0.45))
		# 中央純白高亮爆發核
		_fx_layer.draw_circle(center, core_radius, Color(1.0, 1.0, 1.0, core_alpha * 0.95))

	# 階段三：落地靈氣爆發環（仙身凝定）
	elif _anim_time > STAGE_2_END:
		var t3 := clampf((_anim_time - STAGE_2_END) / (TOTAL_DURATION - STAGE_2_END), 0.0, 1.0)
		var radius: float = lerpf(10.0, minf(size.x, size.y) * 0.45, t3)
		var ring_alpha: float = (1.0 - t3) * 0.75
		var ring_col := Color(0.45, 0.85, 1.0, ring_alpha)
		_fx_layer.draw_arc(center, radius, 0.0, TAU, 48, ring_col, 4.0)

		# 中心殘留凝結微光
		if t3 < 0.4:
			var residual_p := 1.0 - (t3 / 0.4)
			_fx_layer.draw_circle(center, 30.0 * residual_p, Color(1.0, 1.0, 1.0, residual_p * 0.8))

func _show_result_card() -> void:
	_result_card.visible = true
	_skip_button.visible = false
	_bg_overlay.color = Color(0.04, 0.06, 0.09, 0.85)

func skip() -> void:
	if not _is_playing:
		return
	_anim_time = TOTAL_DURATION
	if _camera != null:
		_camera.focus_home()
	_fx_layer.queue_redraw()
	_show_result_card()

func _on_finish_pressed() -> void:
	_is_playing = false
	visible = false
	_bg_overlay.color = Color(0.96, 0.94, 0.86, 0.0)
	if _camera != null:
		_camera.input_locked = false
		_camera.focus_home()
	print("ABODE_REINCARNATION_SEQUENCE_FINISHED: cycle=", _cycle)
	sequence_finished.emit()
	if _on_finished_callback.is_valid():
		_on_finished_callback.call()

func _gui_input(event: InputEvent) -> void:
	# 點擊畫面任意處可在播放中跳過，或在結算顯示時快速關閉
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_playing and not _result_card.visible:
			skip()
