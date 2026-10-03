extends SceneTree
## Verifies:
## 1. Wall-clock catch-up on _process (background tab compensation)
## 2. NOTIFICATION_APPLICATION_FOCUS_IN immediate settlement
## 3. DEBUG auto-build triggers level_up_cultivation when can_level_up == true
## 4. DEBUG auto-build strictly avoids breakthrough_era (tribulation) when can_breakthrough == true

const LivingAbodeScene = preload("res://scenes/living_abode.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var LivingAbodeScript = preload("res://src/abode/living_abode.gd")
	LivingAbodeScript.save_dir_override = "user://debug_autobuild_test_saves"
	var test_adapter := FileStorageAdapter.new("user://debug_autobuild_test_saves")
	var test_slots := SaveSlots.new(test_adapter)
	test_slots.reset()

	var abode = LivingAbodeScene.instantiate()
	root.add_child(abode)
	await process_frame

	var session := GameSession.create_new_game(abode.content)
	abode.session = session
	abode.state = abode.AbodeStateCompat.new(session)
	abode._refresh_hud()

	print("=== CASE 1: Background Wall-Clock Catch-Up ===")
	var t0: float = session.state.total_elapsed_seconds
	# Simulate 10 seconds in background
	abode._last_process_ticks_msec = Time.get_ticks_msec() - 10000
	abode._process(0.016)
	var t1: float = session.state.total_elapsed_seconds
	var advanced: float = t1 - t0
	if advanced < 9.5 or advanced > 11.0:
		_fail("Background catch-up expected ~10s advanced, got: %f" % advanced)
		return
	print("  -> PASS: Background 10s catch-up advanced %f seconds." % advanced)

	print("=== CASE 2: Focus In Immediate Settlement ===")
	var t2: float = session.state.total_elapsed_seconds
	abode._last_process_ticks_msec = Time.get_ticks_msec() - 5000
	abode._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var t3: float = session.state.total_elapsed_seconds
	var focus_advanced: float = t3 - t2
	if focus_advanced < 4.5 or focus_advanced > 6.0:
		_fail("Focus in catch-up expected ~5s advanced, got: %f" % focus_advanced)
		return
	print("  -> PASS: Focus-in immediate settlement advanced %f seconds." % focus_advanced)

	print("=== CASE 3: DEBUG Auto-Build Level Up Cultivation ===")
	# Give sufficient resources and training seconds for level 1 -> 2
	session.state.resources["lingli"].value = AmountCompat.from_number(1000.0)
	session.state.training_seconds = 100.0
	var view_before: Dictionary = session.get_view()
	if not bool(view_before.get("can_level_up", false)):
		_fail("Expected can_level_up to be true for Level Up test")
		return
	var old_level: int = session.state.level
	abode._debug_perform_random_upgrade()
	if session.state.level != old_level + 1:
		_fail("Expected level to be %d, got %d" % [old_level + 1, session.state.level])
		return
	print("  -> PASS: DEBUG auto-build promoted cultivation from level %d to %d." % [old_level, session.state.level])

	print("=== CASE 4: DEBUG Auto-Build Strictly Skips Breakthrough Era (Tribulation) ===")
	# Boost to level 10 (era cap for Qi Refining)
	session.state.level = 10
	session.state.training_seconds = 0.0
	# Give high lingli cap via storage to satisfy breakthrough requirement
	session.state.buildings["storage_lingli"] = 10
	var view_bt: Dictionary = session.get_view()
	if not bool(view_bt.get("can_breakthrough", false)):
		_fail("Expected can_breakthrough to be true for Breakthrough test")
		return
	var era_before: int = session.state.era_id
	abode._debug_perform_random_upgrade()
	if session.state.era_id != era_before:
		_fail("DEBUG auto-build MUST NOT auto-breakthrough era! Era changed from %d to %d" % [era_before, session.state.era_id])
		return
	if session.state.level != 10:
		_fail("Level should remain 10, got %d" % session.state.level)
		return
	print("  -> PASS: DEBUG auto-build strictly preserved tribulation barrier (era=%d, level=10)." % session.state.era_id)

	print("==================================================")
	print("ALL DEBUG AUTO-BUILD AND BACKGROUND TIME TESTS PASSED (exit 0)")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[TEST FAILED] ", msg)
	quit(1)
