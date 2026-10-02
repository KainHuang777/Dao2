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
		quit(1)
	else:
		print("PASS: M3-B alchemy UI, refining, consuming, responsiveness, and state updates.")
		quit(0)
