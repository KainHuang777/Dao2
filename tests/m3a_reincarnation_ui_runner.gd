extends SceneTree

const SCENE_PATH := "res://scenes/living_abode.tscn"
const TEST_SAVE_DIR := "user://m3a_reincarnation_ui_test_saves"
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

	print("--- Running M3-A Reincarnation UI Runner ---")

	# 1. 初始狀態與面板開關
	abode._layout_for_size(Vector2(1280, 720))
	_expect(not abode.more_menu.visible and abode.reincarnation_button.visible, "wide desktop toolbar must expose the cultivation section")
	_expect(not abode.reincarnation_panel.visible, "reincarnation panel must be closed initially")

	abode.feature_navigation.open("reincarnation")
	_expect(abode.reincarnation_panel.visible, "canonical cultivation tab must open reincarnation")
	_expect(abode.reincarnation_panel._reincarnate_action_button.disabled, "reincarnate button must be disabled for new game (Era 1, full lifespan)")
	_expect(abode.reincarnation_panel._eligibility_label.text.find("往生蓮臺") >= 0, "eligibility label must explain requirement")

	# 2. 分頁切換至道心天賦
	abode.reincarnation_panel._talents_button.pressed.emit()
	_expect(abode.reincarnation_panel._talents_box.visible and not abode.reincarnation_panel._reincarnate_box.visible, "switching tab must show talents box and hide reincarnate box")

	var row_inher: PanelContainer = abode.reincarnation_panel._talent_rows.get("resource_inheritance", null)
	_expect(row_inher != null, "resource_inheritance talent row must exist")
	var btn_learn: Button = row_inher.find_child("LearnButton", true, false)
	_expect(btn_learn != null and btn_learn.disabled, "learn button must be disabled when dao heart is 0")
	await process_frame
	await process_frame
	_expect(row_inher.size.y > 44 and abode.reincarnation_panel._talents_list.size.y > 100, "talent rows must receive a real height inside the outer scroll body")
	_expect(btn_learn.get_global_rect().intersects(abode.reincarnation_panel._body_scroll.get_global_rect()), "first talent purchase must be visible in the scroll viewport")

	# 3. 道心注入與天賦參悟
	abode.session.state.dao_heart = AmountCompat.from_number(50.0)
	abode._refresh_hud()
	_expect(not btn_learn.disabled, "learn button must be enabled when player has 50 dao heart (cost=5)")

	btn_learn.pressed.emit()
	_expect(int(abode.session.state.talents.get("resource_inheritance", 0)) == 1, "resource_inheritance level must become 1")
	_expect(abode.session.state.dao_heart.to_float() == 45.0, "dao heart must be deducted from 50 to 45")
	var name_label: Label = row_inher.find_child("TalentName", true, false)
	_expect(name_label.text.find("[1 / 10 階]") >= 0, "talent row label must reflect new level [1 / 10 階]")

	# 4. 達成轉世資格與轉世執行
	abode.reincarnation_panel._reincarnate_button.pressed.emit()
	_expect(abode.reincarnation_panel._reincarnate_box.visible, "switching back must show reincarnate box")

	# 模擬築基並建造部分建築（壽元未盡且無蓮臺：不可輪迴，橫幅不顯示）
	abode.session.state.era_id = 2
	abode.session.state.buildings["hut"] = 3
	abode.session.state.buildings["wooden_house"] = 2
	abode._refresh_hud()
	_expect(not abode.lifespan_banner.visible, "lifespan banner must be hidden when lifespan is not exhausted")
	_expect(abode.reincarnation_panel._reincarnate_action_button.disabled, "reincarnate button must be disabled when era >= 2 but no rebirth lotus")

	# 模擬修築往生蓮臺 (rebirth_lotus = 1)
	abode.session.state.buildings["rebirth_lotus"] = 1
	abode._refresh_hud()
	_expect(not abode.lifespan_banner.visible, "lifespan banner remains hidden for early lotus reincarnation")
	_expect(not abode.reincarnation_panel._reincarnate_action_button.disabled, "reincarnate button must be enabled when rebirth lotus is built")
	_expect(abode.reincarnation_panel._eligibility_label.text.find("往生蓮臺") >= 0, "eligibility label must display lotus qualification")

	# 模擬壽元耗盡情境，驗證 HUD 懸浮橫幅顯示與直達輪迴
	abode.session.state.buildings.erase("rebirth_lotus")
	abode.session.state.total_elapsed_seconds = 200000.0
	abode._refresh_hud()
	_expect(abode.lifespan_banner.visible, "lifespan banner must become visible when lifespan is exhausted")
	_expect(not abode.reincarnation_panel._reincarnate_action_button.disabled, "reincarnate button must be enabled when lifespan is exhausted")
	_expect(abode.reincarnation_panel._eligibility_label.text.find("壽元已盡") >= 0, "eligibility label must display lifespan exhausted qualification")

	# 測試點擊橫幅按鈕直達輪迴面板
	abode.reincarnation_panel.visible = false
	abode.lifespan_banner_button.pressed.emit()
	_expect(abode.reincarnation_panel.visible, "pressing lifespan banner button must directly open reincarnation panel")

	# 執行轉世
	abode.reincarnation_panel._reincarnate_action_button.pressed.emit()
	await process_frame

	_expect(abode.session.state.reincarnation_count == 1, "reincarnation count must be 1 after reincarnating")
	_expect(abode.session.state.era_id == 1, "era must reset to 1 (练气期)")
	_expect(abode.session.state.buildings.is_empty(), "island buildings must be reset to empty")
	# 45 (剩餘) + 15 (二階保底) = 60
	_expect(abode.session.state.dao_heart.to_float() == 60.0, "dao heart must be updated to 60 (45 remaining + 15 floor)")
	# 天賦 1 階提供 10%，取消自動補給。
	var lingli_val: float = abode.session.state.resources["lingli"].value.to_float()
	_expect(lingli_val == 10.0, "level1 talent grants 10% of cap100, with no automatic supply")
	_expect(not abode.reincarnation_panel.visible, "reincarnation panel must be automatically closed upon rebirth")
	_expect(not abode.lifespan_banner.visible, "lifespan banner must be hidden after reincarnation")

	# 5. 直式版型與 more_menu 整合
	abode._layout_for_size(Vector2(360, 640))
	_expect(not abode.more_menu.visible, "legacy More must remain hidden in portrait")
	_expect(abode.reincarnation_button.visible, "cultivation section remains discoverable beneath the rotation prompt")

	abode.feature_navigation.open("reincarnation")
	abode._layout_for_size(Vector2(360, 640))
	_expect(abode.reincarnation_panel.visible, "more_menu item 6 must toggle reincarnation panel in portrait layout")
	_expect(abode.reincarnation_panel.size.x <= 360.0, "reincarnation panel must fit within 360 CSS px bounds")
	_expect(abode.reincarnation_panel.position.x >= 0.0, "reincarnation panel position must be inside screen")


	# 關閉面板
	abode.reincarnation_panel._close_button.pressed.emit()
	_expect(not abode.reincarnation_panel.visible, "clicking close button must close the panel")

	# 6. 轉生特效表演（ReincarnationSequence）測試
	_expect(abode.reincarnation_seq != null, "reincarnation_seq node must exist")
	_expect(abode.reincarnation_seq.visible, "reincarnation_seq must be visible after reincarnation triggered")

	# 驗證階段 1 狀態
	abode.reincarnation_seq._process(0.5)
	_expect(is_equal_approx(abode.camera.zoom.x, 0.08), "camera zoom must be at cosmos (0.08) in stage 1")
	_expect(abode.reincarnation_seq._stage_badge.text.find("太虛出神") >= 0, "stage 1 badge must indicate cosmic view")

	# 驗證階段 2 縮放平滑放大
	abode.reincarnation_seq._process(1.2) # anim_time = 1.7
	_expect(abode.camera.zoom.x > 0.08 and abode.camera.zoom.x < 0.70, "camera zoom must interpolate between 0.08 and 0.70 in stage 2")
	_expect(abode.reincarnation_seq._couplet_label.text.find("神返靈山") >= 0, "stage 2 couplet must indicate return to holy mountain")

	# 驗證跳過功能（skip）
	abode.reincarnation_seq._skip_button.pressed.emit()
	_expect(is_equal_approx(abode.camera.target_zoom, 0.70), "skip must restore camera to home zoom (0.70)")
	_expect(abode.reincarnation_seq._result_card.visible, "skip must directly show result card")

	# 驗證完成按鈕關閉
	abode.reincarnation_seq._finish_button.pressed.emit()
	_expect(not abode.reincarnation_seq.visible, "finish button must hide reincarnation sequence")
	_expect(not abode.camera.input_locked, "camera input must be unlocked after sequence finishes")

	slots.reset()

	if _failed:
		print("FAIL: M3-A reincarnation UI tests failed.")
		quit(1)
	else:
		print("PASS: M3-A reincarnation UI, talent purchasing, responsive layouts, and state transitions.")
		quit(0)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAILED: " + msg)
		print("FAILED: ", msg)
		_failed = true
