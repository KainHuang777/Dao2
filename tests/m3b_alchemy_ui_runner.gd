extends SceneTree

const SCENE_PATH := "res://scenes/living_abode.tscn"
const TEST_SAVE_DIR := "user://m3b_alchemy_ui_test_saves"
var _failed: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	var abode_script = load("res://src/abode/living_abode.gd")
	abode_script.save_dir_override = TEST_SAVE_DIR
	var slots := SaveSlots.new(FileStorageAdapter.new(TEST_SAVE_DIR))
	slots.reset()

	var abode = load(SCENE_PATH).instantiate()
	root.add_child(abode)
	await process_frame
	abode.offline_summary.hide()

	print("--- Running M3-B Alchemy UI Runner ---")

	# 1. 初始面板狀態與開關
	abode._layout_for_size(Vector2(1280, 720))
	_expect(abode.alchemy_panel != null, "alchemy_panel must be instantiated")
	_expect(not abode.alchemy_panel.visible, "alchemy_panel must be hidden initially")

	# 透過更多功能打開煉丹房 (ID 7)
	abode.feature_navigation.open("alchemy")
	_expect(abode.alchemy_panel.visible, "cultivation alchemy tab must open alchemy_panel")

	# 初始未解鎖檢查（herb_farm = 0）
	var cult_row: PanelContainer = abode.alchemy_panel._pill_rows.get("cultivation_pill", null)
	_expect(cult_row != null, "cultivation_pill row must exist")
	var refine_btn: Button = cult_row.find_child("RefineButton", true, false)
	var consume_btn: Button = cult_row.find_child("ConsumeButton", true, false)
	_expect(refine_btn != null and refine_btn.disabled, "refine button must be disabled when locked/no materials")
	_expect(consume_btn != null and consume_btn.disabled, "consume button must be disabled when count is 0")

	# 2. 解鎖並給予材料
	abode.session.state.buildings["herb_farm"] = 3
	abode.session.state.resources["spirit_grass_low"].value = AmountCompat.from_number(100.0)
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(200.0)
	abode._refresh_hud()

	_expect(not refine_btn.disabled, "refine button must be enabled when unlocked and materials sufficient")

	# 3. 點擊煉製聚靈丹
	refine_btn.pressed.emit()
	_expect(int(abode.session.state.pills.get("cultivation_pill", 0)) == 1, "cultivation_pill count must become 1")
	var count_lbl: Label = cult_row.find_child("CountLabel", true, false)
	_expect(count_lbl.text.find("1") >= 0, "count label must display 1")
	_expect(not consume_btn.disabled, "consume button must be enabled after refining")

	# 4. 點擊服用聚靈丹
	var prev_train: float = float(abode.session.state.training_seconds)
	consume_btn.pressed.emit()
	_expect(int(abode.session.state.pills.get("cultivation_pill", 0)) == 0, "cultivation_pill count must return to 0")
	_expect(abode.session.state.training_seconds == prev_train + 60.0, "training seconds must increase by 60s")
	_expect(consume_btn.disabled, "consume button must be disabled again when count returns to 0")
	_expect(abode.alchemy_panel._feedback.visible, "refine and consume feedback stays on the alchemy page")
	abode.session.state.pills["lifespan_pill"] = 1
	abode.session.state.pills["foundation_pill"] = 1
	abode.session.state.revision += 1
	abode._refresh_hud()
	abode.alchemy_panel._widgets.lifespan_pill.consume.pressed.emit()
	abode.alchemy_panel._widgets.foundation_pill.consume.pressed.emit()
	_expect(abode.buff_hud_bar.badges.has("pill:lifespan") and abode.buff_hud_bar.badges.has("pill:production"), "consuming persistent-effect pills immediately adds HUD status badges")
	for vp in ([Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]):
		abode._layout_for_size(vp)
		await process_frame
		_expect(abode.feature_navigation.shell.compact_hud.visible and not abode.header.visible and abode.buff_hud_bar.is_visible_in_tree(), "alchemy uses shared compact HUD and buffs %s" % vp)
		_expect(abode.resource_ribbon.visible == (vp.y >= 500), "alchemy rail only in wide layout %s" % vp)
		_expect(abode.feature_navigation.shell.compact_hud.get_global_rect().end.y <= abode.feature_navigation.bar.position.y, "alchemy clears compact HUD %s" % vp)
		_expect(abode.alchemy_panel._scroll.get_global_rect().end.y <= abode.alchemy_panel.get_global_rect().end.y + 1, "alchemy scroll stays in panel")
		var close: Button = abode.alchemy_panel._close_button if abode.alchemy_panel._title_row.visible else abode.feature_navigation.back_button
		_expect(close.get_global_rect().end.y <= abode.alchemy_panel._scroll.get_global_rect().position.y, "close remains above scrolling recipes")
		_expect(abode.feature_navigation.shell.resource_button.visible, "resource drawer entry remains available")
	var tile = abode.alchemy_panel._widgets.cultivation_pill.tiles.spirit_grass_low
	_expect(tile.quantity.text.contains("/10"), "material tile shows current stock and required amount")
	_expect(abode.alchemy_panel._widgets.cultivation_pill.output.tooltip_text.contains("60 秒"), "pill effect remains available as TIP")
	_expect(abode.alchemy_panel._widgets.cultivation_pill.title.get_theme_color("font_color") == UiMaterial.INK, "paper pill titles use readable dark ink")

	# 5. 響應式佈局驗證（360x640 手機直式）
	abode._layout_for_size(Vector2(360, 640))
	_expect(abode.alchemy_panel.size.x <= 360, "alchemy panel width within mobile width")
	_expect(abode.alchemy_panel.size.y <= 640, "alchemy panel height within mobile height")

	# 關閉面板
	abode.alchemy_panel._close_button.pressed.emit()
	_expect(not abode.alchemy_panel.visible, "close button must hide alchemy_panel")

	_finish()

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		push_error("Assertion failed: %s" % msg)
		_failed = true

func _finish() -> void:
	if _failed:
		print("FAIL: M3-B alchemy UI runner encountered errors.")
		RunnerResult.finish(self, 1)
	else:
		print("PASS: M3-B alchemy UI, refining, consuming, responsiveness, and state updates.")
		RunnerResult.finish(self, 0)
