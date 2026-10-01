extends SceneTree

const SCENE_PATH := "res://scenes/living_abode.tscn"
const TEST_SAVE_DIR := "user://debug_features_test_saves"
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

	print("--- Running Debug Features Runner ---")

	# 1. 初始面板狀態與子選單項目檢查
	abode._layout_for_size(Vector2(1280, 720))
	_expect(abode.debug_panel != null, "debug_panel must be instantiated")
	_expect(not abode.debug_panel.visible, "debug_panel must be hidden initially")

	var popup = abode.settings_menu.get_popup()
	var debug_item_idx: int = popup.get_item_index(8)
	_expect(debug_item_idx >= 0, "settings_menu must have debug tool item with ID 8")

	# 2. 透過系統設定打開調試工具 (ID 8)
	abode._on_settings_menu_pressed(8)
	_expect(abode.debug_panel.visible, "settings_menu item 8 must open debug_panel")

	# 3. 測試資源調試 (+1000)
	var prev_money: float = abode.session.state.resources["money"].value.to_float()
	abode._on_debug_add_resources_requested()
	var new_money: float = abode.session.state.resources["money"].value.to_float()
	_expect(new_money >= prev_money + 1000.0, "debug add resources must grant at least 1000 money")

	# 4. 測試境界修為躍遷至 Era LV10
	abode._on_debug_boost_era_level_requested()
	_expect(abode.session.state.level == 10, "state level must be boosted to 10")
	_expect(abode.session.state.training_seconds == 0.0, "training seconds should be reset cleanly")

	# 5. 測試 30 秒自動建造循環
	abode._on_debug_auto_build_toggled(true)
	_expect(abode.debug_auto_build_active == true, "debug_auto_build_active must be true")
	_expect(abode.debug_auto_build_timer == 30.0, "debug_auto_build_timer must start at 30s")

	# 推進 10 秒
	abode._process(10.0)
	_expect(is_equal_approx(abode.debug_auto_build_timer, 20.0), "timer should decrement to 20s")

	# 再推進 21 秒，跨越 30 秒週期，觸發自動建造
	var buildings_sum_before: int = 0
	for b_id in abode.session.state.buildings:
		buildings_sum_before += int(abode.session.state.buildings[b_id])

	abode._process(21.0)
	_expect(is_equal_approx(abode.debug_auto_build_timer, 30.0), "timer should reset to 30s after triggering")

	var buildings_sum_after: int = 0
	for b_id in abode.session.state.buildings:
		buildings_sum_after += int(abode.session.state.buildings[b_id])

	_expect(buildings_sum_after > buildings_sum_before, "at least one building must have upgraded automatically")

	# 6. 測試手動觸發單次隨機升級
	abode._on_debug_manual_upgrade_requested()
	var buildings_sum_manual: int = 0
	for b_id in abode.session.state.buildings:
		buildings_sum_manual += int(abode.session.state.buildings[b_id])
	_expect(buildings_sum_manual > buildings_sum_after, "manual upgrade request must upgrade an eligible building")

	# 7. 測試關閉自動建造與關閉面板
	abode._on_debug_auto_build_toggled(false)
	_expect(abode.debug_auto_build_active == false, "auto build must be stopped")

	abode._on_debug_closed()
	_expect(not abode.debug_panel.visible, "debug_panel must become invisible upon closing")

	slots.reset()
	abode.queue_free()

	if _failed:
		print("[FAIL] Debug Features Runner encountered errors!")
		quit(1)
	else:
		print("[PASS] Debug Features Runner completed successfully.")
		quit(0)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		printerr("ASSERTION FAILED: ", msg)
		_failed = true
