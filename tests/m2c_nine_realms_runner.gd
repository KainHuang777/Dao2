extends SceneTree

const SCENE_PATH := "res://scenes/living_abode.tscn"
const TEST_SAVE_DIR := "user://m2c_test_saves"

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
	var state = session.state

	# 1. Blank opening: hook not yet seen
	if state.tutorial_flags.get("seen_nine_realms_hook", false):
		_fail("seen_nine_realms_hook must be false initially")
		return
	if abode.nine_realms_preview == null:
		_fail("nine_realms_preview must be mounted")
		return
	if abode.nine_realms_preview.visible:
		_fail("nine_realms_preview must be hidden initially")
		return

	# 2. First Gather triggers hook
	abode._pick_world(abode.buildings["hut"].position)
	abode._gather_lingli()

	if not state.tutorial_flags.get("seen_nine_realms_hook", false):
		_fail("seen_nine_realms_hook must be true after first gather")
		return

	if not abode.nine_realms_preview.visible:
		_fail("nine_realms_preview must become visible on hook trigger")
		return

	if not abode.nine_realms_preview._is_cinematic_playing:
		_fail("Cinematic must be playing on hook trigger")
		return

	# 3. Skip cinematic
	abode.nine_realms_preview.skip_cinematic()
	if abode.nine_realms_preview._is_cinematic_playing:
		_fail("Cinematic must not be playing after skip")
		return

	if not abode.nine_realms_preview._overview_panel.visible:
		_fail("Overview panel must be visible after skip")
		return

	if not is_equal_approx(abode.camera.target_zoom, 0.08):
		_fail("Camera target_zoom must be 0.08 in cosmos view, got: %f" % abode.camera.target_zoom)
		return

	# 4. Check Nine Realms cards & Aspire bookmarking (zero side-effects)
	var cards = abode.nine_realms_preview._grid_container.get_children()
	if cards.size() != 9:
		_fail("Expected 9 realm cards, got: %d" % cards.size())
		return

	var qi_before = session.get_view().resources["lingli"].value
	abode.nine_realms_preview._on_aspire_pressed("realm_spirit")

	if state.tutorial_flags.get("aspired_realm", "") != "realm_spirit":
		_fail("aspired_realm must be 'realm_spirit' after aspiring")
		return

	var qi_after = session.get_view().resources["lingli"].value
	if qi_after != qi_before:
		_fail("Aspiring must not alter resource balances (zero side-effect contract)")
		return

	# 5. Return to abode
	abode.nine_realms_preview._on_close_pressed()
	if abode.nine_realms_preview.visible:
		_fail("nine_realms_preview must be hidden after close")
		return

	if not is_equal_approx(abode.camera.target_zoom, 0.70):
		_fail("Camera target_zoom must return to 0.70, got: %f" % abode.camera.target_zoom)
		return

	# 6. Save & Reload persistence test
	abode.queue_free()
	await process_frame

	var abode2 = packed.instantiate()
	root.add_child(abode2)
	await process_frame

	var state2 = abode2.session.state
	if not state2.tutorial_flags.get("seen_nine_realms_hook", false):
		_fail("seen_nine_realms_hook must remain true after reload")
		return

	if state2.tutorial_flags.get("aspired_realm", "") != "realm_spirit":
		_fail("aspired_realm must remain 'realm_spirit' after reload")
		return

	if abode2.nine_realms_preview.visible:
		_fail("nine_realms_preview must not auto-trigger after reload when seen=true")
		return

	# 7. Replay / Manual overview test
	abode2._open_nine_realms_overview()
	if not abode2.nine_realms_preview.visible or not abode2.nine_realms_preview._overview_panel.visible:
		_fail("Manual overview must open overview panel")
		return

	var qi_replay = abode2.session.get_view().resources["lingli"].value
	if qi_replay != qi_after:
		_fail("Opening overview must not grant any secondary rewards")
		return

	abode2.nine_realms_preview._on_close_pressed()
	if not is_equal_approx(abode2.camera.target_zoom, 0.70):
		_fail("Camera must return home after replay")
		return

	slots.reset()
	abode_script.save_dir_override = ""
	abode2.queue_free()

	print("PASS: M2-C first-minute hook, 6-8s skippable zoom-out, 9 realms preview, aspire bookmarking, zero side-effects, and persistence.")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	print("FAIL: %s" % message)
	quit(1)
