extends SceneTree

const SCENE_PATH := "res://scenes/living_abode.tscn"
const TEST_SAVE_DIR := "user://m2d_slice_test_saves"

func _init() -> void:
	_run()

func _run() -> void:
	var abode_script = load("res://src/abode/living_abode.gd")
	abode_script.save_dir_override = TEST_SAVE_DIR
	var slots := SaveSlots.new(FileStorageAdapter.new(TEST_SAVE_DIR))
	slots.reset()

	var packed: PackedScene = load(SCENE_PATH)
	if packed == null:
		_fail("Could not load scene: %s" % SCENE_PATH)
		return

	var abode = packed.instantiate()
	root.add_child(abode)
	await process_frame

	var session = abode.session

	# =========================================================
	# Step 1: Blank Opening & Manual Qi Gathering
	# =========================================================
	var view = session.get_view()
	var qi_amount: float = AmountCompat.try_parse(view.resources["lingli"].value).value.to_float()
	if qi_amount != 0.0:
		_fail("Initial lingli must be 0, got: %f" % qi_amount)
		return

	# First Gather does NOT trigger hook (UX change: hook moved to first reincarnation)
	abode._gather_lingli()
	if session.state.tutorial_flags.get("seen_nine_realms_hook", false):
		_fail("seen_nine_realms_hook must remain false after first gather")
		return

	# Can open Nine Realms Overview via menu to verify aspire functionality
	abode._open_nine_realms_overview()
	if not abode.nine_realms_preview._overview_panel.visible:
		_fail("Overview panel must be open after opening overview")
		return

	# Aspire to spirit realm (zero side-effect verification)
	var qi_before_aspire: float = AmountCompat.try_parse(session.get_view().resources["lingli"].value).value.to_float()
	abode.nine_realms_preview._on_aspire_pressed("realm_spirit")
	var qi_after_aspire: float = AmountCompat.try_parse(session.get_view().resources["lingli"].value).value.to_float()
	if qi_after_aspire != qi_before_aspire:
		_fail("Aspiring realm must have zero side-effects on balances")
		return

	# Return to abode
	abode.nine_realms_preview._on_close_pressed()
	if not is_equal_approx(abode.camera.target_zoom, 0.70):
		_fail("Camera must return home (zoom=0.70)")
		return

	# =========================================================
	# Step 2: Build Hut & Automatic Production & Chained Unlocks
	# =========================================================
	# Gather remaining 19 times to reach 20 lingli for hut level 1
	for i in 19:
		abode._gather_lingli()

	abode.selected_id = "hut"
	abode._upgrade_selected() # Hut -> level 1
	if session.state.buildings.get("hut", 0) != 1:
		_fail("Hut must be level 1")
		return

	# Advance 120 seconds -> generates 36 lingli
	abode.session.advance_time(120.0)
	await process_frame

	# Hut -> level 2 (requires 25 lingli)
	abode.selected_id = "hut"
	abode._upgrade_selected()
	if session.state.buildings.get("hut", 0) != 2:
		_fail("Hut must be level 2")
		return

	# Unlocks wooden_house and storage_lingli
	if not abode.building_catalog.rows["wooden_house"].visible or abode.buildings["wooden_house"].visible:
		_fail("wooden_house must unlock in the catalogue without an unplanned island prop")
		return

	if not abode.building_catalog.rows["storage_lingli"].visible or abode.buildings["storage_lingli"].visible:
		_fail("storage_lingli must unlock in the catalogue without an unplanned island prop")
		return

	# =========================================================
	# Step 3: Minor Cultivation Level Up & Capacity Preparation
	# =========================================================
	session.state.level = 10
	session.state.training_seconds = 500.0
	abode._refresh_hud()

	# Attempt breakthrough before capacity 500 reached -> MUST FAIL
	var pre_bt_era = session.state.era_id
	abode._breakthrough_era()
	if session.state.era_id != pre_bt_era:
		_fail("Breakthrough must fail when capacity < 500")
		return

	# Upgrade storage_lingli to provide 500 capacity (total 600 >= 500)
	session.state.buildings["storage_lingli"] = 2
	abode._refresh_hud()
	var view_bt = session.get_view()
	if not bool(view_bt.can_breakthrough):
		_fail("can_breakthrough must be true once capacity meets 500")
		return

	# Ensure some inventory to verify NON-CONSUMING stock contract
	session.state.resources["lingli"].value = AmountCompat.from_number(320.0)
	var stock_before_bt: float = session.state.resources["lingli"].value.to_float()

	# Execute Breakthrough to Era 2 (Foundation Establishment)
	abode._breakthrough_era()
	if session.state.era_id != 2:
		_fail("Breakthrough must succeed to Era 2")
		return

	var stock_after_bt: float = session.state.resources["lingli"].value.to_float()
	if stock_after_bt != stock_before_bt:
		_fail("Breakthrough must strictly NOT deduct lingli stock")
		return

	# Verify breakthrough presentation
	if abode.breakthrough_seq != null and abode.breakthrough_seq.visible:
		abode.breakthrough_seq._on_skip_pressed()

	# Replay breakthrough (zero reward re-grant check)
	abode._replay_breakthrough()
	if abode.breakthrough_seq != null:
		abode.breakthrough_seq._on_skip_pressed()
	var stock_after_replay: float = session.state.resources["lingli"].value.to_float()
	if stock_after_replay != stock_before_bt:
		_fail("Replaying breakthrough sequence must not alter stock")
		return

	# =========================================================
	# Step 4: 50x Rapid View Switching Memory Leak Check
	# =========================================================
	var initial_mem: int = OS.get_static_memory_usage()
	for cycle in 50:
		abode.camera.focus_region()
		abode._open_nine_realms_overview()
		abode.nine_realms_preview._on_close_pressed()
		abode.camera.focus_home()
		if cycle % 10 == 0:
			await process_frame

	var final_mem: int = OS.get_static_memory_usage()
	var mem_growth_kb: float = float(final_mem - initial_mem) / 1024.0
	# Memory growth should not exhibit persistent linear growth (allow < 1500 KB for dynamic cache and text buffer)
	if mem_growth_kb > 1500.0:
		_fail("Excessive memory growth across 50 switches: %.2f KB" % mem_growth_kb)
		return

	# First reincarnation triggers hook
	abode._on_reincarnate_requested("normal")
	if not session.state.tutorial_flags.get("seen_nine_realms_hook", false):
		_fail("seen_nine_realms_hook must be true after first reincarnation")
		return
	if abode.nine_realms_preview != null and abode.nine_realms_preview.visible:
		abode.nine_realms_preview.skip_cinematic()
		abode.nine_realms_preview._on_close_pressed()
	session.state.era_id = 2

	# =========================================================
	# Step 5: Save & Reopen Consistency
	# =========================================================
	abode._save_game()
	abode.queue_free()
	await process_frame

	var abode2 = packed.instantiate()
	root.add_child(abode2)
	await process_frame

	var state2 = abode2.session.state
	if state2.era_id != 2:
		_fail("Reopened state must retain Era 2")
		return
	if state2.tutorial_flags.get("aspired_realm", "") != "realm_spirit":
		_fail("Reopened state must retain aspired realm")
		return
	if not state2.tutorial_flags.get("seen_nine_realms_hook", false):
		_fail("Reopened state must retain seen_nine_realms_hook")
		return

	slots.reset()
	abode_script.save_dir_override = ""
	abode2.queue_free()

	print("PASS: M2-D full slice release, end-to-end progression, 50x view switching memory stability (%.2f KB), and save integrity." % mem_growth_kb)
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	print("FAIL: %s" % message)
	quit(1)
