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
	_skip_button.text = "跳過演出 ⏩"
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
		_bg_overlay.color.a = lerpf(0.12, 0.0, t3)
		_stage_badge.text = "【重塑仙身 · 再問長生】"
		_couplet_label.text = "重聚仙靈，再問長生！"
		if _camera != null:
			_camera.position = Vector2(0, -40)
			_camera.zoom = Vector2(0.70, 0.70)
			_camera.target_position = Vector2(0, -40)
			_camera.target_zoom = 0.70
		if not _result_card.visible:
			_show_result_card()

	_fx_layer.queue_redraw()

func _on_fx_draw() -> void:
	if not _is_playing or _reduced_motion:
		return
	var center := size * 0.5

	# 階段二：穿梭虛空光線
	if _anim_time > STAGE_1_END and _anim_time <= STAGE_2_END:
		var t2 := (_anim_time - STAGE_1_END) / (STAGE_2_END - STAGE_1_END)
		var streak_alpha: float = sin(t2 * PI) * 0.6
		var count := 16
		for i in range(count):
			var angle := float(i) / float(count) * TAU + _anim_time * 0.5
			var dir := Vector2(cos(angle), sin(angle))
			var start_dist: float = 60.0 + t2 * 80.0
			var end_dist: float = start_dist + 120.0 + t2 * 200.0
			var start_pt := center + dir * start_dist
			var end_pt := center + dir * end_dist
			var col := Color(0.96, 0.88, 0.60, streak_alpha)
			_fx_layer.draw_line(start_pt, end_pt, col, 2.0)

	# 階段三：落地靈氣爆發環
	elif _anim_time > STAGE_2_END:
		var t3 := clampf((_anim_time - STAGE_2_END) / (TOTAL_DURATION - STAGE_2_END), 0.0, 1.0)
		var radius: float = lerpf(10.0, minf(size.x, size.y) * 0.45, t3)
		var ring_alpha: float = (1.0 - t3) * 0.75
		var ring_col := Color(0.45, 0.85, 1.0, ring_alpha)
		_fx_layer.draw_arc(center, radius, 0.0, TAU, 48, ring_col, 3.5)

func _show_result_card() -> void:
	_result_card.visible = true
	_skip_button.visible = false

func skip() -> void:
	if not _is_playing:
		return
	_anim_time = TOTAL_DURATION
	if _camera != null:
		_camera.focus_home()
	_bg_overlay.color.a = 0.0
	_fx_layer.queue_redraw()
	_show_result_card()

func _on_finish_pressed() -> void:
	_is_playing = false
	visible = false
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
