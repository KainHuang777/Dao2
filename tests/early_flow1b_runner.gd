extends SceneTree
## Earned Q1/Q3 path; optional alchemy, reloads and fault retry share that state.
var failures: Array[String] = []
var checks := 0
var helper = preload("res://src/verification/res1d2_contract.gd").new()

class FaultAdapter extends StorageAdapter:
	var data := {}
	var refuse := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if refuse:
			return {"ok": false, "error": "QuotaExceededError"}
		data[key] = value
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(content).ok, "normal content attached")
	var s := GameSession.create_new_game(content)
	check(s.get_view().next_objective.id == "hut", "Q1 starts from blank hut")
	for milestone in Onboarding.MILESTONES:
		while int(s.state.buildings.get(milestone.building, 0)) < int(milestone.level):
			if not helper.build(s, milestone.building):
				check(false, "earned build " + milestone.building)
				quit(1)
				return
	check(s.get_view().early_guidance.optional_alchemy, "Q2 unlocked after herb3")
	check(s.get_view().early_guidance.text.contains("無須煉丹"), "Q2 explicitly optional")
	check(s.get_view().early_guidance.route == "storage_lingli", "Q3 insufficient capacity directs to altar")
	var encoded := SaveCodec.encode(s.state, content.content_version, meta())
	var decoded := SaveCodec.decode(encoded.json)
	check(decoded.ok, "earned chain reload")
	var restored := GameSession.new()
	restored.content = content
	restored.state = decoded.state
	restored.clock = GameClock.create(0)
	check(restored.get_view().early_guidance == s.get_view().early_guidance, "reload derives same goals without preferences")
	await check_ui(restored)
	# Optional branch on a clone: no injected inventory or time.
	var optional := GameSession.new()
	optional.content = content
	optional.state = s.state.duplicate_state()
	optional.clock = GameClock.create(0)
	for id in ["spirit_grass_low", "lingli"]:
		var cost: float = float(AlchemySystem.PILLS.cultivation_pill.cost[id])
		while optional.state.resources[id].value.to_float() < cost:
			check(helper.send(optional, "gather", {"resource_id": id}).ok, "earned optional ingredient")
	check(helper.send(optional, "refine_pill", {"pill_id": "cultivation_pill", "count": 1}).ok, "optional refine succeeds")
	var before := optional.state.training_seconds
	check(helper.send(optional, "consume_pill", {"pill_id": "cultivation_pill", "count": 1}).ok, "optional consume succeeds")
	check(optional.state.training_seconds == before + 60 and optional.state.pills.cultivation_pill == 0, "actual consumed pill applies once")
	check(not optional.get_view().early_guidance.is_empty(), "consumption does not hide main Q3")
	check(helper.build(s, "storage_lingli"), "earned altar construction")
	var waits := 0
	while s.state.level < 10 and waits < 4800:
		if s.get_view().can_level_up:
			check(helper.send(s, "level_up_cultivation").ok, "earned level command")
		else:
			s.advance_time(1)
			waits += 1
	check(s.state.level == 10, "natural-rate one-second simulation reaches Q3")
	check(s.get_view().can_breakthrough, "actual capacity suffices")
	check(s.get_view().early_guidance.title.contains("突破"), "ready goal")
	var a := FaultAdapter.new()
	SaveManager.configure(content, a)
	check(SaveManager.save(s.state, meta()).ok, "pre-breakthrough snapshot")
	var result := helper.send(s, "breakthrough_era")
	check(result.ok and s.state.era_id == 2, "no pill main path reaches first foundation")
	a.refuse = true
	check(not SaveManager.save(s.state, meta()).ok, "failed save surfaced")
	check(s.get_view().early_guidance.route == "outposts", "failed write retains live foundation handoff")
	a.refuse = false
	check(SaveManager.save(s.state, meta()).ok, "retry only persists")
	SaveManager.configure(content, a)
	check(SaveManager.current_state().era_id == 2, "retry reload foundation")
	var replay := s.submit({"command_id": "d2-" + str(helper.serial), "type": "breakthrough_era", "payload": {}, "expected_revision": s.state.revision})
	check(replay.duplicate and s.state.era_id == 2, "same command replay cannot double advance")
	await check_handoff_ui(s)
	s.advance_time(float(s.get_view().max_lifespan_seconds))
	check(helper.send(s, "reincarnate", {"mode": "normal"}).ok, "normal reincarnation")
	var new_goal: Variant = s.get_view().next_objective
	check(new_goal is Dictionary and new_goal.id == "hut" and s.get_view().early_guidance.is_empty(), "new life starts current-life chain")
	print("EARLY-FLOW1-B: %d checks; simulated natural-rate wait %ds (not wall-clock/browser evidence)." % [checks, waits])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func meta() -> Dictionary:
	return {"save_id": "early-flow1b", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}

func check_ui(earned: GameSession) -> void:
	var facade = preload("res://src/abode/living_abode.gd")
	facade.save_dir_override = "user://early_flow1b_ui"
	var slots := SaveSlots.new(FileStorageAdapter.new(facade.save_dir_override))
	slots.reset()
	var abode = preload("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.offline_summary.hide() # Complete the report before testing feature input.
	abode.set_process(false)
	abode.session = earned
	abode.state = abode.AbodeStateCompat.new(earned)
	abode._refresh_hud()
	abode._hud_controller._goal_action.pressed.emit()
	await process_frame
	check(abode.feature_navigation.page == "buildings" and abode.selected_id == "storage_lingli", "goal routes to capacity detail without spending")
	abode.feature_navigation.home()
	abode._hud_controller._alchemy_action.pressed.emit()
	await process_frame
	check(abode.feature_navigation.page == "alchemy" and abode.alchemy_panel.visible, "optional button routes to existing alchemy")
	abode.feature_navigation.home()
	for size in ([Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]):
		abode._layout_for_size(size)
		abode._hud_controller.show_messages()
		await process_frame
		var action: Rect2 = abode._hud_controller._goal_action.get_global_rect()
		var optional: Rect2 = abode._hud_controller._alchemy_action.get_global_rect()
		check(Rect2(Vector2.ZERO, size).encloses(action) and Rect2(Vector2.ZERO, size).encloses(optional), "goal actions bounded " + str(size))
		check(action.size.y >= 44 and optional.size.y >= 44, "action target height " + str(size))
		check(not action.intersects(optional), "separate goals " + str(size))
	abode._layout_for_size(Vector2(360, 640))
	check(abode.orientation_prompt.visible, "portrait rotation prompt")
	abode._layout_for_size(Vector2(844, 390))
	check(not abode.orientation_prompt.visible, "rotation return restores UI")
	abode._toggle_guidance()
	abode._refresh_hud()
	check(not abode.hint_panel.visible, "closed messages stay closed on refresh")
	abode._toggle_guidance()
	check(abode.hint.text.contains("無須煉丹"), "reopen reconstructs optional/main goals")
	abode.queue_free()
	await process_frame
	slots.reset()
	facade.save_dir_override = ""

func check_handoff_ui(earned: GameSession) -> void:
	var facade = preload("res://src/abode/living_abode.gd")
	facade.save_dir_override = "user://early_flow1b_handoff"
	var slots := SaveSlots.new(FileStorageAdapter.new(facade.save_dir_override))
	slots.reset()
	var abode = preload("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.offline_summary.hide() # Complete the report before testing feature input.
	abode.set_process(false)
	abode.session = earned
	abode.state = abode.AbodeStateCompat.new(earned)
	abode._refresh_hud()
	check(abode.objective_button.text == earned.get_view().early_guidance.title and abode.objective_button.text.contains("開拓青木島"), "foundation handoff survives hidden message rail with current first-island objective")
	abode.objective_button.pressed.emit()
	check(abode.feature_navigation.page == "outposts", "foundation header goal directly opens island page")
	abode.queue_free()
	await process_frame
	slots.reset()
	facade.save_dir_override = ""
