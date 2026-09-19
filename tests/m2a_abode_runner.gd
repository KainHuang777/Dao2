extends SceneTree
## M2-A Formal Abode Integration Test Runner
## Verifies:
## 1. Blank opening (0 resources, hut level 0, onboarding unlocks)
## 2. Manual start via gather until 20 lingli
## 3. First build to hut level 1, starting automatic lingli generation
## 4. Chained unlock after hut level 2 (wooden_house, storages appear)
## 5. Persistence save & reload preserves state
## 6. Motion toggle does not affect production determinism

const LivingAbodeScene = preload("res://scenes/living_abode.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var LivingAbodeScript = preload("res://src/abode/living_abode.gd")
	LivingAbodeScript.save_dir_override = "user://m2a_test_saves"
	var test_adapter := FileStorageAdapter.new("user://m2a_test_saves")
	var test_slots := SaveSlots.new(test_adapter)
	test_slots.reset()

	# 1. Blank Opening
	var abode = LivingAbodeScene.instantiate()
	root.add_child(abode)
	await process_frame

	# Ensure fresh test state for isolated runner
	var fresh_session := GameSession.create_new_game(abode.content)
	abode.session = fresh_session
	abode.state = abode.AbodeStateCompat.new(fresh_session)
	abode._refresh_hud()

	var view: Dictionary = abode.session.get_view()
	var qi_amount: float = AmountCompat.try_parse(view.resources["lingli"].value).value.to_float()
	if qi_amount != 0.0:
		_fail("Blank opening must start with 0 lingli, got: %f" % qi_amount)
		return

	if not abode.buildings.has("hut") or not abode.buildings["hut"].visible:
		_fail("Hut must be visible at start")
		return

	if abode.buildings.has("wooden_house") and abode.buildings["wooden_house"].visible:
		_fail("Wooden house must not be visible before hut level 2")
		return

	if view.next_objective == null or view.next_objective.id != "hut":
		_fail("Initial objective must be hut")
		return

	# 2. Manual Start (Gather)
	abode._pick_world(abode.buildings["hut"].position)
	if abode.selected_id != "hut" or not abode.info_panel.visible:
		_fail("Picking hut must open info panel")
		return

	if not abode.upgrade_button.disabled:
		_fail("Upgrade button must be disabled when lacking lingli")
		return

	for i in 20:
		abode._gather_lingli()

	view = abode.session.get_view()
	qi_amount = AmountCompat.try_parse(view.resources["lingli"].value).value.to_float()
	if qi_amount < 20.0:
		_fail("Gathering 20 times must accumulate at least 20 lingli, got: %f" % qi_amount)
		return

	if abode.upgrade_button.disabled:
		_fail("Upgrade button must be enabled once 20 lingli is reached")
		return

	# 3. First Build & Automatic Production
	abode._upgrade_selected()
	if abode.session.state.buildings.get("hut", 0) != 1:
		_fail("Hut level must become 1 after first build")
		return

	# Advance 60 seconds (1 tick)
	abode.session.advance_time(60.0)
	view = abode.session.get_view()
	var qi_rate: float = AmountCompat.try_parse(view.resources["lingli"].rate).value.to_float()
	if qi_rate <= 0.0:
		_fail("Hut level 1 must provide positive lingli rate, got: %f" % qi_rate)
		return

	var qi_after: float = AmountCompat.try_parse(view.resources["lingli"].value).value.to_float()
	if qi_after <= 0.0:
		_fail("Lingli must automatically increase after 60s of production, got: %f" % qi_after)
		return

	# 4. Chained Unlock after Hut Level 2
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(100.0)
	abode._refresh_hud()
	abode._upgrade_selected()
	if abode.session.state.buildings.get("hut", 0) != 2:
		_fail("Hut must reach level 2")
		return

	abode._process(0.1) # trigger building visibility update
	view = abode.session.get_view()
	if not bool(view.buildings["wooden_house"].visible):
		_fail("Wooden house must unlock after hut level 2")
		return
	if not bool(view.buildings["storage_lingli"].visible):
		_fail("Storage lingli must unlock after hut level 2")
		return
	if not bool(view.buildings["storage_money"].visible):
		_fail("Storage money must unlock after hut level 2")
		return

	if view.next_objective == null or view.next_objective.id != "wooden_house":
		_fail("Next objective must update to wooden_house, got: %s" % str(view.next_objective))
		return

	# 5. Persistence Save & Reload
	abode._save_game()
	abode.queue_free()
	await process_frame

	var reloaded = LivingAbodeScene.instantiate()
	root.add_child(reloaded)
	await process_frame

	if reloaded.session.state.buildings.get("hut", 0) != 2:
		_fail("Reloaded abode must preserve hut level 2, got: %d" % reloaded.session.state.buildings.get("hut", 0))
		return
	if not reloaded.buildings["wooden_house"].visible:
		_fail("Reloaded abode must preserve unlocked wooden house visibility")
		return

	# 6. Motion Toggle Production Determinism
	var base_tick: float = reloaded.session.state.total_elapsed_seconds
	reloaded._toggle_motion()
	reloaded.session.advance_time(60.0)
	var tick_after: float = reloaded.session.state.total_elapsed_seconds
	if not is_equal_approx(tick_after - base_tick, 60.0):
		_fail("Advance time under reduced motion must remain exactly 60 seconds")
		return

	reloaded.queue_free()
	test_slots.reset()
	LivingAbodeScript.save_dir_override = ""
	print("PASS: M2-A abode blank opening, manual start, auto production, chained unlocks, save/reload, and determinism.")
	quit(0)

func _fail(message: String) -> void:
	push_error("M2-A FAIL: " + message)
	quit(1)
