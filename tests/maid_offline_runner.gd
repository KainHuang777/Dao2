extends SceneTree
const META := {"save_id": "maid-offline-isolated", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
const LAST_MS := 1000
const TWELVE_HOURS_MS := 43200000
const TWO_DAYS_MS := 172800000
var content: GameContent
var checks := 0
var failures: Array[String] = []

func _init() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)

func snap(state: GameState) -> String:
	return JSON.stringify(state.to_snapshot_dict())

func fresh() -> GameState:
	return GameSession.create_new_game(content, 20261101).state

func stock(state: GameState, id: String, amount: float) -> void:
	state.resources[id] = {"value": AmountCompat.from_number(amount), "unlocked": true, "ever_obtained": true}

func entry(state: GameState, maid_id: String) -> Dictionary:
	return state.maid.get("maids", {}).get(maid_id, {})

func fp_count(state: GameState) -> float:
	var via_resources := 0.0
	if state.resources.has("foundation_pill"):
		via_resources = float(state.resources["foundation_pill"].value.to_float())
	return maxf(via_resources, float(state.pills.get("foundation_pill", 0)))

func prepared(era := 8) -> GameState:
	var state := fresh()
	MaidSystem.ensure_state(state)
	state.era_id = era
	state.buildings.hut = 1
	state.buildings.herb_farm = 3
	for id in ["spirit_grass_low", "black_copper", "lingli", "money", "wood", "stone_low"]:
		stock(state, id, 100000.0)
	stock(state, "foundation_pill", 0.0)
	return state

func steward(target: int) -> Dictionary:
	return {"kind": "steward_stock", "recipe_id": "foundation_pill", "target": target, "reserve": {}}

func recruit_steward(state: GameState) -> void:
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "qingheng recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(100)).get("ok", false)), "steward duty assigned")

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "supply attached")
	_test_twelve_hours()
	_test_paused()
	_test_missing_block()
	_test_stopped()
	_test_reincarnation()
	_test_cap_24h()
	_test_economy_busy()
	await _test_sync_async()
	_test_save_roundtrip()
	_test_determinism()
	_test_ui_text()
	var report_path := RunnerResult.output_path("res://docs/verification/artifacts/maid-offline/runner.json")
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	if report == null:
		check(false, "report write")
	else:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures}, "\t"))
		report.close()
	print("MAID-OFFLINE checks=", checks, " failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func _test_twelve_hours() -> void:
	var state := prepared()
	recruit_steward(state)
	var settled := OfflineSettlement.settle(state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var report: Dictionary = settled["report"]
	check(report.get("stopped", null) == null, "12h settles without a stop")
	var maid: Dictionary = report.get("maid", {})
	check(int(maid.get("actions", 0)) == MaidRules.MAX_ACTIONS_PER_CALL, "12h runs exactly MAX_ACTIONS_PER_CALL actions")
	check(int(maid.get("kinds", {}).get("steward_stock", 0)) == MaidRules.MAX_ACTIONS_PER_CALL, "12h counts steward actions by kind")
	check(int(maid.get("first_duty", 0)) == 1, "12h grants the one-time first duty bond")
	check(int(maid.get("units", 0)) >= MaidRules.MAX_ACTIONS_PER_CALL, "12h reports produced units")
	check(int(entry(state, "qingheng").get("duty_actions", 0)) == MaidRules.MAX_ACTIONS_PER_CALL, "12h persists duty action count")
	check(fp_count(state) >= float(MaidRules.MAX_ACTIONS_PER_CALL), "12h produced stock")
	check(MaidSaveContract.validate(state.maid) == "", "12h keeps maid block valid")

func _test_paused() -> void:
	var state := prepared()
	recruit_steward(state)
	check(bool(MaidSystem.set_duty_paused(state, "qingheng", true).get("ok", false)), "paused duty accepted")
	var actions_before := int(entry(state, "qingheng").get("duty_actions", 0))
	var settled := OfflineSettlement.settle(state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var report: Dictionary = settled["report"]
	check(not report.has("maid"), "paused duty omits the maid report")
	check(int(entry(state, "qingheng").get("duty_actions", 0)) == actions_before, "paused duty keeps action count")
	check(bool(entry(state, "qingheng").get("duty", {}).get("paused", false)), "paused duty stays paused")

func _test_missing_block() -> void:
	var state := fresh()
	state.era_id = 8
	var settled := OfflineSettlement.settle(state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var report: Dictionary = settled["report"]
	check(state.maid.is_empty(), "missing maid block is never initialized offline")
	check(not report.has("maid"), "missing maid block omits the maid report")
	check(state.to_snapshot_dict().get("maid", {}) == {}, "missing maid block stays absent in the snapshot")

func _test_stopped() -> void:
	var state := prepared(1)
	recruit_steward(state)
	var settled := OfflineSettlement.settle(state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var report: Dictionary = settled["report"]
	check(String(report.get("stopped", "")) == "lifespan_exhausted", "lifespan stop is reported")
	check(not report.has("maid"), "lifespan stop skips maid work")
	check(int(entry(state, "qingheng").get("duty_actions", 0)) == 0, "lifespan stop leaves action count untouched")

func _test_reincarnation() -> void:
	var state := prepared()
	recruit_steward(state)
	MaidSystem.on_reincarnate(state)
	var settled := OfflineSettlement.settle(state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var report: Dictionary = settled["report"]
	var data := entry(state, "qingheng")
	check(not report.has("maid"), "rebirth pause omits the maid report")
	check(int(data.get("duty_actions", 0)) == 0, "rebirth pause runs no actions")
	check(bool(data.get("duty", {}).get("paused", false)) and int(data.get("duty", {}).get("cooldown", -1)) == 0, "rebirth pause keeps the paused duty")
	check(bool(data.get("reunion_pending", false)), "rebirth pause keeps reunion pending")

func _test_cap_24h() -> void:
	var state := prepared()
	recruit_steward(state)
	var settled := OfflineSettlement.settle(state, content, LAST_MS + TWO_DAYS_MS, LAST_MS)
	var report: Dictionary = settled["report"]
	check(bool(report.get("cap_applied", false)), "24h cap is applied")
	check(int(report.get("effective_ticks", 0)) == 86400, "24h cap keeps one day of reward ticks")
	var maid: Dictionary = report.get("maid", {})
	check(int(maid.get("actions", 0)) == MaidRules.MAX_ACTIONS_PER_CALL, "24h cap still runs only MAX_ACTIONS_PER_CALL actions")

func _test_economy_busy() -> void:
	var state := prepared()
	state.economy = IslandEconomy.initial()
	recruit_steward(state)
	var settled := OfflineSettlement.settle(state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var report: Dictionary = settled["report"]
	var maid: Dictionary = report.get("maid", {})
	check(int(maid.get("actions", 0)) == 1, "economy steward starts one job then blocks")
	check(String(entry(state, "qingheng").get("duty", {}).get("status", "")) == "BLOCKED", "economy steward reports BLOCKED")
	check(state.economy.jobs.has("home"), "economy steward leaves the timed job running")
	check(is_equal_approx(fp_count(state), 0.0), "economy steward records no finished product offline")

func _test_sync_async() -> void:
	var sync_state := prepared()
	recruit_steward(sync_state)
	var async_state := sync_state.duplicate_state()
	var sync_settle := OfflineSettlement.settle(sync_state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var async_settle: Dictionary = await OfflineCoordinator.compute_async(async_state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS, self)
	check(JSON.stringify(sync_settle.get("report", {})) == JSON.stringify(async_settle.get("report", {})), "sync and async reports match")
	check(JSON.stringify(sync_state.maid) == JSON.stringify(async_state.maid), "sync and async maid state match")

func _test_save_roundtrip() -> void:
	var state := prepared()
	recruit_steward(state)
	OfflineSettlement.settle(state, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	check(MaidSaveContract.validate(state.maid) == "", "offline maid block validates")
	var encoded := SaveCodec.encode(state, content.content_version, META)
	check(bool(encoded.get("ok", false)), "offline maid save encodes " + String(encoded.get("error", "")))
	if not bool(encoded.get("ok", false)):
		return
	var decoded := SaveCodec.decode(String(encoded.get("json", "")))
	check(bool(decoded.get("ok", false)), "offline maid save decodes " + String(decoded.get("error", "")))
	if not bool(decoded.get("ok", false)):
		return
	var restored: GameState = decoded.get("state")
	var original := entry(state, "qingheng")
	var loaded := entry(restored, "qingheng")
	check(int(loaded.get("duty_actions", 0)) == int(original.get("duty_actions", 0)), "offline action count survives save roundtrip")
	check(bool(loaded.get("first_duty_done", false)) == bool(original.get("first_duty_done", false)), "first duty flag survives save roundtrip")

func _test_determinism() -> void:
	var first := prepared()
	recruit_steward(first)
	var second := prepared()
	recruit_steward(second)
	var settled_first := OfflineSettlement.settle(first, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	var settled_second := OfflineSettlement.settle(second, content, LAST_MS + TWELVE_HOURS_MS, LAST_MS)
	check(snap(first) == snap(second), "offline maid state is deterministic")
	check(JSON.stringify(settled_first.get("report", {})) == JSON.stringify(settled_second.get("report", {})), "offline maid report is deterministic")

func _test_ui_text() -> void:
	var summary := OfflineSummary.new()
	summary._ready()
	var base_report := {"away_ms": 3600000, "effective_ms": 3600000, "age_seconds": 4800.0, "stopped": null, "cap_applied": false}
	summary.show_report(base_report)
	var plain: String = summary._body_label.text
	var zero_report := base_report.duplicate(true)
	zero_report["maid"] = {"actions": 0, "units": 0, "kinds": {}, "first_duty": 0}
	summary.show_report(zero_report)
	check(summary._body_label.text == plain, "zero maid actions keeps the summary text unchanged")
	var maid_report := base_report.duplicate(true)
	maid_report["maid"] = {"actions": 3, "units": 6, "kinds": {"steward_stock": 3}, "first_duty": 1}
	summary.show_report(maid_report)
	var text: String = summary._body_label.text
	check(text.contains("仙侍職掌：離線完成 3 次"), "summary shows the maid action line")
	var age_index := text.find("目前年歲")
	var maid_index := text.find("仙侍職掌")
	var stop_index := text.find("停止原因")
	check(age_index >= 0 and maid_index > age_index and stop_index > maid_index, "maid line sits between age and stop reason")
	summary.free()
