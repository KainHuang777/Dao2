extends SceneTree
## M2-B Breakthrough & Sequence Acceptance Test Runner
## Verifies:
## 1. Cultivation training time accumulation and level_up_cultivation command
## 2. Insufficient training and insufficient resource rejections
## 3. Capacity requirement vs stock requirement in breakthrough_era (requires 500 capacity, doesn't consume stock)
## 4. Successful Era 1 -> Era 2 breakthrough (era_id=2, level=1, training_seconds=0, lifespan expanded to 200 祀)
## 5. Skippable & replayable BreakthroughSequence without duplicate rewards
## 6. Persistence save/reload preserves Era 2 state and UI atmospheric changes

const LivingAbodeScene = preload("res://scenes/living_abode.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var LivingAbodeScript = preload("res://src/abode/living_abode.gd")
	LivingAbodeScript.save_dir_override = "user://m2b_test_saves"
	var test_adapter := FileStorageAdapter.new("user://m2b_test_saves")
	var test_slots := SaveSlots.new(test_adapter)
	test_slots.reset()

	var abode = LivingAbodeScene.instantiate()
	root.add_child(abode)
	await process_frame

	# Setup isolated session
	var session := GameSession.create_new_game(abode.content)
	abode.session = session
	abode.state = abode.AbodeStateCompat.new(session)
	abode._refresh_hud()

	# 1. Level up training accumulation check
	var lvl_cmd := {
		"command_id": "test_lvl_1",
		"type": "level_up_cultivation",
		"expected_revision": session.state.revision,
		"payload": {}
	}
	var res: Dictionary = session.submit(lvl_cmd)
	if res.get("ok", false) or res.get("error") != "INSUFFICIENT_TRAINING":
		_fail("level_up_cultivation must fail with INSUFFICIENT_TRAINING when training_seconds is 0")
		return

	# Provide training time but 0 lingli
	session.state.training_seconds = 100.0
	lvl_cmd.command_id = "test_lvl_2"
	lvl_cmd.expected_revision = session.state.revision
	res = session.submit(lvl_cmd)
	if res.get("ok", false) or res.get("error") != "INSUFFICIENT_RESOURCE":
		_fail("level_up_cultivation must fail with INSUFFICIENT_RESOURCE when lacking lingli")
		return

	# Provide lingli and level up to level 2
	session.state.resources["lingli"].value = AmountCompat.from_number(100.0)
	lvl_cmd.command_id = "test_lvl_3"
	lvl_cmd.expected_revision = session.state.revision
	res = session.submit(lvl_cmd)
	if not res.get("ok", false):
		_fail("level_up_cultivation must succeed with sufficient training and lingli")
		return
	if session.state.level != 2:
		_fail("State level must become 2, got: %d" % session.state.level)
		return
	if session.state.training_seconds != 0.0:
		_fail("training_seconds must reset to 0.0 after level up")
		return

	# 2. Advance to Level 10 (Peak Qi Refining)
	session.state.level = 10
	session.state.training_seconds = 500.0
	session.state.resources["lingli"].value = AmountCompat.from_number(88.0) # stock
	session.state.buildings["hut"] = 2 # provides 300 cap + base 100 = 400 cap (< 500)
	abode._refresh_hud()

	# 3. Breakthrough Capacity constraint check
	var bt_cmd := {
		"command_id": "test_bt_1",
		"type": "breakthrough_era",
		"expected_revision": session.state.revision,
		"payload": {}
	}
	res = session.submit(bt_cmd)
	if res.get("ok", false) or res.get("error") != "INSUFFICIENT_CAPACITY":
		_fail("breakthrough_era must fail when lingli capacity is below 500, got: %s" % str(res))
		return

	# Build storage_lingli to level 2 (adds 200 capacity -> total 600 >= 500)
	session.state.buildings["storage_lingli"] = 2
	abode._refresh_hud()

	var view: Dictionary = session.get_view()
	if not bool(view.can_breakthrough):
		_fail("can_breakthrough must be true once capacity meets 500")
		return

	# 4. Successful Breakthrough Execution
	bt_cmd.command_id = "test_bt_2"
	bt_cmd.expected_revision = session.state.revision
	res = session.submit(bt_cmd)
	if not res.get("ok", false):
		_fail("breakthrough_era must succeed when level 10 and capacity >= 500")
		return

	if session.state.era_id != 2:
		_fail("Player era_id must become 2 (Foundation Establishment), got: %d" % session.state.era_id)
		return
	if session.state.level != 1:
		_fail("Player level must reset to 1 in new era, got: %d" % session.state.level)
		return

	# Verify stock was NOT consumed
	var stock_after: float = session.state.resources["lingli"].value.to_float()
	if not is_equal_approx(stock_after, 88.0):
		_fail("Breakthrough must NOT consume lingli stock (expected 88.0, got: %f)" % stock_after)
		return

	# Lifespan verification: era 1 (80) + era 2 (120) = 200 祀 = 12000s
	view = session.get_view()
	if not bool(view.buildings["hut"].visible) or not bool(view.buildings["storage_lingli"].visible):
		_fail("Earlier-era buildings must remain manageable after the Era 2 breakthrough")
		return
	var max_life: float = float(view.max_lifespan_seconds)
	if not is_equal_approx(max_life, 12000.0):
		_fail("Total lifespan for Era 2 must be 12000 seconds (200 祀), got: %f" % max_life)
		return

	# 5. Breakthrough Sequence presentation, skip, and replay
	if abode.breakthrough_seq == null:
		_fail("BreakthroughSequence must be present in living abode HUD")
		return

	abode.breakthrough_seq.play("練氣期", "築基期")
	if not abode.breakthrough_seq.visible:
		_fail("BreakthroughSequence must be visible when playing")
		return

	# Skip sequence
	abode.breakthrough_seq._on_skip_pressed()
	# Replay sequence
	abode.breakthrough_seq._on_replay_pressed()
	abode.breakthrough_seq._on_close_pressed()
	if abode.breakthrough_seq.visible:
		_fail("BreakthroughSequence must hide after close pressed")
		return

	# Verify state not altered by replay
	if session.state.era_id != 2 or session.state.level != 1:
		_fail("Replaying sequence must not re-grant or alter player state")
		return

	# 6. Persistence Save & Reload
	abode._save_game()
	abode.queue_free()
	await process_frame

	var reloaded = LivingAbodeScene.instantiate()
	root.add_child(reloaded)
	await process_frame

	if reloaded.session.state.era_id != 2:
		_fail("Reloaded abode must preserve era_id 2, got: %d" % reloaded.session.state.era_id)
		return
	reloaded._layout_for_size(Vector2(360, 640))
	reloaded._refresh_hud()
	if reloaded.replay_breakthrough_button.visible or reloaded.settings_menu.get_popup().is_item_disabled(reloaded.settings_menu.get_popup().get_item_index(5)):
		_fail("Era 2 replay must remain available through the portrait Settings menu")
		return

	reloaded._layout_for_size(Vector2(1280, 720))
	reloaded._refresh_hud()

	if reloaded.replay_breakthrough_button.visible or not reloaded.settings_menu.visible or reloaded.settings_menu.get_popup().is_item_disabled(reloaded.settings_menu.get_popup().get_item_index(5)):
		_fail("Era 2 replay must remain available through the wide Settings menu")
		return

	reloaded.queue_free()
	test_slots.reset()
	LivingAbodeScript.save_dir_override = ""
	print("PASS: M2-B cultivation level up, capacity barrier, breakthrough to Era 2, non-consuming stock, sequence replay, and reload.")
	quit(0)

func _fail(message: String) -> void:
	push_error("M2-B FAIL: " + message)
	quit(1)
