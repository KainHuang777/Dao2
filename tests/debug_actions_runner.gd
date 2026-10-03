extends SceneTree

## debug_actions_runner.gd
## Verifies DebugActions (era step, resources, time warp/chrono, fortune, sect, beast)
## against a real GameSession, plus panel -> signal wiring. No save files are touched.

var _failed := false

func _init() -> void:
	_run()

func _run() -> void:
	print("[DEBUG_ACTIONS_RUNNER] Starting DebugActions tests...")
	var content := (ContentLoader.load_directory("res://content")["content"] as GameContent)
	_test_era_step(content)
	_test_resources(content)
	_test_time_and_chrono(content)
	_test_fortune(content)
	_test_sect(content)
	_test_beast(content)
	await _test_unknown_and_panel(content)
	if _failed:
		printerr("[DEBUG_ACTIONS_RUNNER] FAILED (exit 1)")
		quit(1)
	else:
		print("[DEBUG_ACTIONS_RUNNER] ALL DEBUG ACTION TESTS PASSED (exit 0)")
		quit(0)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		printerr("  FAIL: ", msg)
		_failed = true

func _new_session(content: GameContent) -> GameSession:
	return GameSession.create_new_game(content)

func _test_era_step(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.level = 5
	var first_era := s.state.era_id
	var res := DebugActions.run("era_step", {"delta": -1}, s)
	_expect(not bool(res.ok), "era_step -1 at lowest era must fail")
	_expect(s.state.era_id == first_era and s.state.level == 5, "failed era_step must not mutate state")
	res = DebugActions.run("era_step", {"delta": 1}, s)
	if content.era_ids.size() > 1:
		_expect(bool(res.ok), "era_step +1 must succeed when a next era exists")
		_expect(s.state.era_id == int(content.era_ids[1]) and s.state.level == 1, "era advanced and level reset")
		_expect(s.state.highest_era >= s.state.era_id, "highest_era follows era")
		res = DebugActions.run("era_step", {"delta": -1}, s)
		_expect(bool(res.ok) and s.state.era_id == first_era, "era_step -1 returns to first era")
	var top := DebugActions.run("era_step", {"delta": 999}, s)
	_expect(not bool(top.ok) or s.state.era_id == int(content.era_ids[content.era_ids.size() - 1]), "huge delta clamps to last era")

func _test_resources(content: GameContent) -> void:
	var s := _new_session(content)
	var rid: String = String(content.resource_ids[0])
	var before := (s.state.resources[rid].value as AmountCompat).to_float()
	var res := DebugActions.run("res_add", {"amount": 100000.0}, s)
	_expect(bool(res.ok), "res_add ok")
	_expect(is_equal_approx((s.state.resources[rid].value as AmountCompat).to_float(), before + 100000.0), "res_add adds exact amount")
	_expect(bool(s.state.resources[rid].unlocked), "res_add unlocks resource")
	res = DebugActions.run("res_clear", {}, s)
	_expect(bool(res.ok), "res_clear ok")
	for r_id in s.state.resources:
		_expect((s.state.resources[r_id].value as AmountCompat).compare_to(AmountCompat.zero()) == 0, "res_clear zeroes %s" % r_id)
	var caps := Production.compute_caps(content, s.state.buildings, s.state.era_id, s.state.onboarding_version)
	DebugActions.run("res_fill", {}, s)
	for r_id in caps:
		if s.state.resources.has(r_id):
			_expect((s.state.resources[r_id].value as AmountCompat).compare_to(caps[r_id]) >= 0, "res_fill reaches cap for %s" % r_id)

func _test_time_and_chrono(content: GameContent) -> void:
	var s := _new_session(content)
	var t0 := s.state.total_elapsed_seconds
	var res := DebugActions.run("time_warp", {"seconds": 600.0}, s)
	_expect(bool(res.ok), "time_warp ok")
	_expect(s.state.total_elapsed_seconds >= t0 + 599.0, "time_warp advances total_elapsed_seconds via session")
	_expect(not bool(DebugActions.run("time_warp", {"seconds": -5.0}, s).ok), "negative warp rejected")
	_expect(not bool(DebugActions.run("time_warp", {"seconds": 99999999.0}, s).ok), "oversized warp rejected")
	DebugActions.run("chrono_unlock", {}, s)
	_expect(ChronoSystem.is_unlocked(s.state), "chrono_unlock unlocks")
	var shichen_before := int(s.state.chrono.get("shichen_index", 0))
	res = DebugActions.run("chrono_next_shichen", {}, s)
	_expect(bool(res.ok), "chrono_next_shichen ok")
	_expect(int(s.state.chrono.get("shichen_index", 0)) == (shichen_before + 1) % ChronoSystem.SHICHEN_COUNT, "shichen moved exactly one step")
	var weather_before := String(s.state.chrono.get("weather_id", ""))
	res = DebugActions.run("chrono_next_weather", {}, s)
	_expect(bool(res.ok) and String(s.state.chrono.get("weather_id", "")) != weather_before, "weather changed")

func _test_fortune(content: GameContent) -> void:
	var s := _new_session(content)
	var res := DebugActions.run("fortune_trigger", {}, s)
	_expect(bool(res.ok), "fortune_trigger ok at era 1")
	_expect(not (s.state.fortune.get("pending_encounter", {}) as Dictionary).is_empty(), "pending encounter set")
	var count := int(s.state.fortune.get("encounter_history_count", 0))
	res = DebugActions.run("fortune_trigger", {}, s)
	_expect(not bool(res.ok), "second trigger rejected while pending")
	_expect(int(s.state.fortune.get("encounter_history_count", 0)) == count, "rejected trigger does not count")
	var resolved := s.resolve_fortune(0)
	_expect(resolved is Dictionary, "pending encounter can flow into normal resolve path")

func _test_sect(content: GameContent) -> void:
	var s := _new_session(content)
	_expect(not bool(DebugActions.run("sect_refresh", {}, s).ok), "refresh before joining rejected")
	_expect(not bool(DebugActions.run("sect_contribution", {}, s).ok), "contribution before joining rejected")
	var res := DebugActions.run("sect_open", {}, s)
	_expect(bool(res.ok), "sect_open bypasses era gate")
	_expect(bool(s.state.sect.get("unlocked", false)), "sect unlocked")
	_expect((s.state.sect.get("available_tasks", []) as Array).size() == SectSystem.EXPEDITION_SLOTS, "tasks generated")
	_expect(not bool(DebugActions.run("sect_open", {}, s).ok), "double join rejected")
	_expect(not bool(DebugActions.run("sect_finish", {}, s).ok), "finish without expedition rejected")
	var task_id := String((s.state.sect.available_tasks as Array)[0].id)
	var start := SectSystem.start_expedition(s.state, task_id)
	_expect(bool(start.ok), "expedition starts")
	res = DebugActions.run("sect_finish", {}, s)
	_expect(bool(res.ok), "sect_finish ok")
	var claimed := SectSystem.claim_expedition_reward(s.state)
	_expect(bool(claimed.ok), "finished expedition is claimable through normal rules")
	var contrib_before: float = (AmountCompat.try_parse(String(s.state.sect.contribution)).value as AmountCompat).to_float()
	DebugActions.run("sect_contribution", {"amount": 1000.0}, s)
	var contrib_after: float = (AmountCompat.try_parse(String(s.state.sect.contribution)).value as AmountCompat).to_float()
	_expect(is_equal_approx(contrib_after, contrib_before + 1000.0), "contribution +1000")

func _test_beast(content: GameContent) -> void:
	var s := _new_session(content)
	_expect(not bool(DebugActions.run("beast_acquire", {"beast_id": "nope"}, s).ok), "unknown beast rejected")
	_expect(not bool(DebugActions.run("beast_mature", {}, s).ok), "mature without beast rejected")
	var res := DebugActions.run("beast_acquire", {"beast_id": "cloud_serpent"}, s)
	_expect(bool(res.ok), "acquire bypasses era gate")
	_expect(String(BeastSystem.get_active_beast(s.state).id) == "cloud_serpent", "active beast set")
	res = DebugActions.run("beast_acquire", {"beast_id": "jade_fox"}, s)
	_expect(String(BeastSystem.get_active_beast(s.state).id) == "jade_fox" and String(BeastSystem.get_active_beast(s.state).stage) == "egg", "acquire replaces active beast with egg")
	DebugActions.run("beast_mature", {}, s)
	_expect(String(BeastSystem.get_active_beast(s.state).stage) == "mature", "mature stage")
	DebugActions.run("beast_souls", {"amount": 10}, s)
	for b_id in BeastSystem.BEAST_CONFIGS:
		_expect(int(s.state.beast_souls.get(b_id, 0)) == 10, "souls +10 for %s" % b_id)
	s.state.beasts["cooldown_remaining"] = 300.0
	DebugActions.run("beast_cooldown", {}, s)
	_expect(float(s.state.beasts["cooldown_remaining"]) == 0.0, "cooldown cleared")

func _test_unknown_and_panel(content: GameContent) -> void:
	var s := _new_session(content)
	_expect(not bool(DebugActions.run("no_such_action", {}, s).ok), "unknown action rejected")
	_expect(not bool(DebugActions.run("res_add", {}, null).ok), "null session rejected")
	var panel := DebugPanel.new()
	root.add_child(panel)
	await process_frame
	var received: Array = []
	panel.debug_action_requested.connect(func(a: String, p: Dictionary): received.append([a, p]))
	var buttons := panel.find_children("Action_*", "Button", true, false)
	_expect(buttons.size() == 28, "panel exposes 28 extended action buttons (got %d)" % buttons.size())
	for b in buttons:
		(b as Button).pressed.emit()
	_expect(received.size() == buttons.size(), "every button emits debug_action_requested")
	var ids := {}
	for entry in received:
		ids[entry[0]] = true
	for expected in ["era_step", "res_add", "res_fill", "res_clear", "time_warp", "chrono_unlock", "chrono_next_shichen", "chrono_next_weather", "fortune_trigger", "sect_open", "sect_refresh", "sect_finish", "sect_contribution", "beast_acquire", "beast_mature", "beast_souls", "beast_cooldown", "inspect_health", "inspect_prod", "sim_offline", "sim_stress"]:
		_expect(ids.has(expected), "panel has button for %s" % expected)
	var s2 := _new_session(content)
	for entry in received:
		var r := DebugActions.run(String(entry[0]), entry[1], s2)
		_expect(r.has("ok") and r.has("msg"), "action %s returns ok/msg shape" % entry[0])
	panel.queue_free()
