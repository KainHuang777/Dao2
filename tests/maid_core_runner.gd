extends SceneTree
const META := {"save_id": "maid-core-isolated", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
var content: GameContent
var checks := 0
var failures: Array[String] = []
func _init() -> void: run.call_deferred()
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
func prepared() -> GameState:
	var state := fresh()
	MaidSystem.ensure_state(state)
	state.era_id = 2
	state.buildings.hut = 1
	state.buildings.herb_farm = 3
	stock(state, "spirit_grass_low", 1000.0)
	stock(state, "black_copper", 1000.0)
	stock(state, "lingli", 100000.0)
	stock(state, "money", 100000.0)
	stock(state, "wood", 100000.0)
	stock(state, "stone_low", 100000.0)
	stock(state, "foundation_pill", 0.0)
	return state
func steward(target: int, reserve: Dictionary) -> Dictionary:
	return {"kind": "steward_stock", "recipe_id": "foundation_pill", "target": target, "reserve": reserve}
func oversee(building_id: String) -> Dictionary:
	return {"kind": "oversee_build", "building_id": building_id}
func restock(target: int, reserve: Dictionary) -> Dictionary:
	return {"kind": "restock_pills", "pill_id": "foundation_pill", "target": target, "reserve": reserve}
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "supply attached")
	_test_rules()
	_test_contract()
	_test_view()
	_test_recruit()
	_test_duty_busy()
	_test_steward()
	_test_oversee()
	_test_restock()
	_test_reincarnation()
	_test_chapters()
	_test_determinism()
	_test_budget()
	_test_session()
	_test_save()
	var report_path := RunnerResult.output_path("res://docs/verification/artifacts/maid-core/runner.json")
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	if report == null: check(false, "report write")
	else:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures}, "\t"))
		report.close()
	print("MAID-CORE checks=", checks, " failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
func _test_rules() -> void:
	check(MaidRules.MAID_IDS.size() == 3 and MaidRules.MAIDS.size() == 3, "three maids frozen")
	var thresholds := []
	for level in MaidRules.BOND_LEVELS:
		thresholds.append(int(level.at))
	check(thresholds == [0, 40, 100, 200], "bond thresholds 0/40/100/200")
	for id in MaidRules.MAID_IDS:
		check(MaidRules.chapters(id).size() == 3, "three chapters " + String(id))
	check(int(MaidRules.DUTY_CADENCE_SECONDS.steward_stock) == 10 and int(MaidRules.DUTY_CADENCE_SECONDS.oversee_build) == 30 and int(MaidRules.DUTY_CADENCE_SECONDS.restock_pills) == 10, "cadence 10/30/10")
	check(MaidRules.FIRST_DUTY_BOND == 10 and MaidRules.MAX_UNITS_PER_ACTION == 5, "first duty bond and unit cap")
	check(MaidRules.MAX_ACTIONS_PER_CALL == 5 and MaidSystem.MAX_ACTIONS_PER_ADVANCE == 1000, "advance budget constants")
	check(MaidSaveContract.VERSION == 1 and MaidSaveContract.MAX_BYTES == 16384, "contract constants")
	check(String(MaidRules.bond_level(40).id) == "xiangzhi" and int(MaidRules.next_bond(40).at) == 100, "bond level lookup")
func _test_contract() -> void:
	check(MaidSaveContract.validate({}) == "", "empty block valid")
	check(MaidSaveContract.validate("x") == "MAID_TYPE", "string rejected")
	check(MaidSaveContract.validate([]) == "MAID_TYPE", "array rejected")
	var good := fixture(qingheng_entry())
	check(MaidSaveContract.validate(good) == "", "valid fixture with steward duty")
	var bad := fixture(qingheng_entry())
	bad["extra"] = 1
	check(MaidSaveContract.validate(bad) == "MAID_KEYS", "extra top key rejected")
	bad = fixture(qingheng_entry())
	bad.erase("maids")
	check(MaidSaveContract.validate(bad) == "MAID_KEYS", "missing maids rejected")
	check(MaidSaveContract.validate({"version": 2, "maids": {}}) == "MAID_VERSION", "wrong version rejected")
	check(MaidSaveContract.validate({"version": 1.5, "maids": {}}) == "MAID_VERSION", "fractional version rejected")
	bad = fixture(qingheng_entry())
	bad.maids["bogus"] = {}
	check(MaidSaveContract.validate(bad) == "MAID_ID", "unknown maid id rejected")
	for value in [-1, 2.5, "40", true, NAN, INF]:
		bad = fixture(qingheng_entry())
		bad.maids.qingheng.bond = value
		check(MaidSaveContract.validate(bad) == "MAID_BOND", "bond rejected " + str(value))
	bad = fixture(qingheng_entry())
	bad.maids.qingheng.chapters = {"bogus_1": true}
	check(MaidSaveContract.validate(bad) == "MAID_CHAPTER", "unknown chapter id rejected")
	bad = fixture(qingheng_entry())
	bad.maids.qingheng.chapters = {"qingheng_1": false}
	check(MaidSaveContract.validate(bad) == "MAID_CHAPTER", "false chapter flag rejected")
	for duty in [{"kind": "bogus"}, {"kind": "oversee_build"}, {"kind": "steward_stock", "paused": false, "cooldown": 86401, "status": "RUNNING", "recipe_id": "foundation_pill", "target": 2, "reserve": {}}, {"kind": "restock_pills", "paused": false, "cooldown": 0, "status": "", "pill_id": "foundation_pill", "target": 2, "reserve": {}}, {"kind": "steward_stock", "paused": false, "cooldown": 0, "status": "RUNNING", "recipe_id": "", "target": 2, "reserve": {}}, {"kind": "steward_stock", "paused": false, "cooldown": 0, "status": "RUNNING", "recipe_id": "foundation_pill", "target": 0, "reserve": {}}, {"kind": "steward_stock", "paused": false, "cooldown": 0, "status": "RUNNING", "recipe_id": "foundation_pill", "target": 2, "reserve": {"wood": -3}}, "text"]:
		bad = fixture(qingheng_entry())
		bad.maids.qingheng.duty = duty
		check(MaidSaveContract.validate(bad) == "MAID_DUTY", "bad duty rejected " + str(duty))
	bad = fixture(qingheng_entry())
	bad.maids.qingheng.duty = {}
	check(MaidSaveContract.validate(bad) == "", "empty duty valid")
	bad = fixture(qingheng_entry())
	bad.maids.qingheng.duty = {"kind": "oversee_build", "paused": true, "cooldown": 0, "status": "PAUSED", "building_id": "hut"}
	check(MaidSaveContract.validate(bad) == "", "oversee duty valid")
	bad = fixture(qingheng_entry())
	bad.maids.qingheng.duty = {"kind": "restock_pills", "paused": false, "cooldown": 10, "status": "RUNNING", "pill_id": "foundation_pill", "target": 5, "reserve": {"spirit_grass_low": "50"}}
	check(MaidSaveContract.validate(bad) == "", "restock duty valid")
	bad = fixture("broken")
	check(MaidSaveContract.validate(bad) == "MAID_ENTRY", "non dictionary entry rejected")
	var short_entry := {"recruited": true}
	check(MaidSaveContract.validate(fixture(short_entry)) == "MAID_ENTRY", "missing entry keys rejected")
	var wide_entry := qingheng_entry()
	wide_entry["extra"] = 1
	check(MaidSaveContract.validate(fixture(wide_entry)) == "MAID_ENTRY", "extra entry keys rejected")
	var huge := fixture(qingheng_entry())
	var big_reserve: Dictionary = huge.maids.qingheng.duty.reserve
	for i in range(3000):
		big_reserve["reserve_%04d" % i] = i
	check(MaidSaveContract.validate(huge) == "MAID_SIZE", "oversized payload rejected")
	var jsonlike := {"version": 1.0, "maids": {"qingheng": {"recruited": true, "bond": 45.0, "chapters": {"qingheng_1": true}, "duty": {"kind": "steward_stock", "paused": false, "cooldown": 5.0, "status": "RUNNING", "recipe_id": "foundation_pill", "target": 2.0, "reserve": {"spirit_grass_low": 20.0, "black_copper": "20"}}, "duty_actions": 12.0, "reunion_pending": false, "first_duty_done": true}}}
	check(MaidSaveContract.validate(jsonlike) == "", "integral floats accepted")
	var normalized := MaidSaveContract.normalize(jsonlike)
	check(MaidSaveContract.validate(normalized) == "", "normalized still valid")
	var ne: Dictionary = normalized.get("maids", {}).get("qingheng", {})
	check(ne.bond is int and ne.duty.cooldown is int and ne.duty.target is int and ne.duty_actions is int and ne.duty.reserve.spirit_grass_low is int, "normalize turns floats into ints")
	check(normalized.version is int and int(normalized.version) == 1, "normalize version int")
	check(MaidSaveContract.normalize(normalized) == normalized, "normalize stable")
	check((normalized.get("maids", {}) as Dictionary).size() == 1, "normalize adds no maid entries")
	check(MaidSaveContract.normalize({}) == {}, "normalize empty safe")
	var parsed: Variant = JSON.parse_string(JSON.stringify(jsonlike))
	var reparsed := MaidSaveContract.normalize(parsed)
	check(reparsed == normalized, "normalize survives json transport")
func fixture(entry_data: Variant) -> Dictionary:
	return {"version": 1, "maids": {"qingheng": entry_data}}
func qingheng_entry() -> Dictionary:
	return {"recruited": true, "bond": 45, "chapters": {"qingheng_1": true}, "duty": {"kind": "steward_stock", "paused": false, "cooldown": 5, "status": "RUNNING", "recipe_id": "foundation_pill", "target": 2, "reserve": {"spirit_grass_low": "50", "black_copper": 20}}, "duty_actions": 12, "reunion_pending": false, "first_duty_done": true}
func _test_view() -> void:
	var state := fresh()
	var before := snap(state)
	var view: Dictionary = MaidSystem.get_view(state, content)
	check(snap(state) == before, "view is pure read")
	check(int(view.get("version", 0)) == 1, "view version one")
	var maids_view: Variant = view.get("maids", {})
	check(maids_view is Dictionary and (maids_view as Dictionary).size() == 3, "view lists three maids")
	if maids_view is Dictionary:
		for id in MaidRules.MAID_IDS:
			var item: Variant = (maids_view as Dictionary).get(id, {})
			check(item is Dictionary and not bool((item as Dictionary).get("recruited", true)), "view unrecruited " + String(id))
func _test_recruit() -> void:
	var state := fresh()
	MaidSystem.ensure_state(state)
	check(MaidSaveContract.validate(state.maid) == "", "ensured maid block valid")
	var before := snap(state)
	var failed: Dictionary = MaidSystem.recruit(state, "qingheng")
	check(not bool(failed.get("ok", true)) and String(failed.get("error", "")) == "MAID_REQUIREMENT" and snap(state) == before, "hut gates qingheng")
	state.buildings.hut = 1
	var done: Dictionary = MaidSystem.recruit(state, "qingheng")
	check(bool(done.get("ok", false)) and bool(entry(state, "qingheng").get("recruited", false)) and int(entry(state, "qingheng").bond) == 0, "qingheng recruited after hut")
	check(MaidSaveContract.validate(state.maid) == "", "maid block valid after recruit")
	var again: Dictionary = MaidSystem.recruit(state, "qingheng")
	before = snap(state)
	check(not bool(again.get("ok", false)) and String(again.get("error", "")).length() > 0 and snap(state) == before, "recruit happens once")
	before = snap(state)
	var nu_low: Dictionary = MaidSystem.recruit(state, "nuomeizi")
	check(not bool(nu_low.get("ok", true)) and String(nu_low.get("error", "")).length() > 0 and snap(state) == before, "nuomeizi needs bond")
	entry(state, "qingheng").bond = 40
	var nu_era: Dictionary = MaidSystem.recruit(state, "nuomeizi")
	check(not bool(nu_era.get("ok", true)), "nuomeizi needs era")
	var dan_era: Dictionary = MaidSystem.recruit(state, "danxia")
	check(not bool(dan_era.get("ok", true)) and String(dan_era.get("error", "")).length() > 0, "danxia locked at era 1")
	state.era_id = 2
	var nu_done: Dictionary = MaidSystem.recruit(state, "nuomeizi")
	check(bool(nu_done.get("ok", false)) and bool(entry(state, "nuomeizi").get("recruited", false)), "nuomeizi at bond 40 era 2")
	var lock_result: Dictionary = MaidSystem.recruit(state, "danxia")
	check(bool(lock_result.get("ok", false)) and bool(entry(state, "danxia").get("recruited", false)), "danxia recruited when alchemy unlocks at era 2")
	var dan_again: Dictionary = MaidSystem.recruit(state, "danxia")
	check(not bool(dan_again.get("ok", true)) and String(dan_again.get("error", "")) == "ALREADY_RECRUITED", "danxia recruit happens once")
func _test_duty_busy() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "busy qingheng recruited")
	entry(state, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(state, "nuomeizi").get("ok", false)), "busy nuomeizi recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(2, {})).get("ok", false)), "steward assigned")
	var busy: Dictionary = MaidSystem.assign_duty(state, content, "nuomeizi", oversee("hut"))
	check(not bool(busy.get("ok", true)) and String(busy.get("error", "")) == "DUTY_BUSY", "single active duty")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(3, {})).get("ok", false)), "replacement duty allowed")
	var view: Dictionary = MaidSystem.get_view(state, content)
	check(String(view.get("active_duty", "")) == "qingheng", "view tracks active duty")
	check(MaidSaveContract.validate(state.maid) == "", "duty block contract valid")
	var duty: Dictionary = entry(state, "qingheng").get("duty", {})
	check(String(duty.get("kind", "")) == "steward_stock" and int(duty.get("target", 0)) == 3 and String(duty.get("status", "")) in ["RUNNING", "PAUSED"], "duty stored")
func _test_steward() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "steward path recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(2, {})).get("ok", false)), "steward target two")
	var result: Dictionary = MaidSystem.execute_duty(state, content, "qingheng")
	check(bool(result.get("ok", false)), "steward execute " + String(result.get("error", "")))
	var data := entry(state, "qingheng")
	check(int(data.get("duty_actions", 0)) == 1, "one action per execute")
	check(int(data.get("bond", -1)) == MaidRules.FIRST_DUTY_BOND and bool(data.get("first_duty_done", false)), "first duty bond once")
	var count := fp_count(state)
	check(count >= 1.0 and count <= 2.0, "batches stay within target")
	for id in ["spirit_grass_low", "black_copper", "lingli"]:
		var amount: AmountCompat = state.resources[id].value
		check(amount.to_float() >= 0.0, "no negative " + id)
	MaidSystem.advance(content, state, 10, MaidRules.MAX_ACTIONS_PER_CALL)
	var data2 := entry(state, "qingheng")
	check(int(data2.get("duty_actions", 0)) == 1, "advance does not count idle checks")
	check(is_equal_approx(fp_count(state), 2.0), "stock capped at target")
	var duty2: Dictionary = data2.get("duty", {})
	check(String(duty2.get("status", "")) == "TARGET_REACHED", "target reached status")
	check(int(data2.get("bond", -1)) == MaidRules.FIRST_DUTY_BOND, "advance adds no bond")
	var blocked := prepared()
	check(bool(MaidSystem.recruit(blocked, "qingheng").get("ok", false)), "reserve state recruited")
	stock(blocked, "spirit_grass_low", 100.0)
	check(bool(MaidSystem.assign_duty(blocked, content, "qingheng", steward(5, {"spirit_grass_low": 100.0})).get("ok", false)), "reserve assigned")
	var blocked_result: Dictionary = MaidSystem.execute_duty(blocked, content, "qingheng")
	var blocked_duty: Dictionary = entry(blocked, "qingheng").get("duty", {})
	check((not bool(blocked_result.get("ok", true)) and String(blocked_result.get("error", "")) == "INSUFFICIENT_RESOURCE") or (bool(blocked_result.get("ok", false)) and String(blocked_duty.get("status", "")) == "INSUFFICIENT_RESOURCE"), "reserve cannot be crossed")
	check(is_equal_approx(fp_count(blocked), 0.0) and is_equal_approx(blocked.resources["spirit_grass_low"].value.to_float(), 100.0), "reserve blocks crafting")
func _test_oversee() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "oversee qingheng recruited")
	entry(state, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(state, "nuomeizi").get("ok", false)), "oversee nuomeizi recruited")
	state.buildings.hut = 1
	check(bool(MaidSystem.assign_duty(state, content, "nuomeizi", oversee("hut")).get("ok", false)), "oversee assigned")
	var money_before: float = state.resources["money"].value.to_float()
	var result: Dictionary = MaidSystem.execute_duty(state, content, "nuomeizi")
	check(bool(result.get("ok", false)), "oversee upgrade " + String(result.get("error", "")))
	check(int(state.buildings.get("hut", 0)) == 2, "one level per action")
	var money_after: float = state.resources["money"].value.to_float()
	check(money_after < money_before, "upgrade spends the building cost")
	var cap := CommandProcessor.level_cap(content.building("hut"), content, state)
	check(int(state.buildings.get("hut", 0)) == cap, "hut at cap")
	var capped: Dictionary = MaidSystem.execute_duty(state, content, "nuomeizi")
	var capped_duty: Dictionary = entry(state, "nuomeizi").get("duty", {})
	check((not bool(capped.get("ok", true)) and String(capped.get("error", "")) == "LEVEL_CAP") or (bool(capped.get("ok", false)) and String(capped_duty.get("status", "")) == "LEVEL_CAP"), "level cap reported")
	check(is_equal_approx(state.resources["money"].value.to_float(), money_after), "level cap spends nothing")
	check(MaidSaveContract.validate(state.maid) == "", "oversee block valid")
func _test_restock() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "restock qingheng recruited")
	entry(state, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(state, "danxia").get("ok", false)), "restock danxia recruited")
	check(bool(MaidSystem.assign_duty(state, content, "danxia", restock(2, {})).get("ok", false)), "restock assigned")
	var result: Dictionary = MaidSystem.execute_duty(state, content, "danxia")
	check(bool(result.get("ok", false)), "restock execute " + String(result.get("error", "")))
	var count := fp_count(state)
	check(count >= 1.0 and count <= 2.0, "restock bounded")
	MaidSystem.execute_duty(state, content, "danxia")
	check(is_equal_approx(fp_count(state), 2.0), "restock target reached")
	check(float(state.pills.get("foundation_pill", 0)) >= 1.0, "pill store increased")
	var data := entry(state, "danxia")
	check(int(data.get("bond", -1)) == MaidRules.FIRST_DUTY_BOND, "restock first duty bond")
	var blocked := prepared()
	check(bool(MaidSystem.recruit(blocked, "qingheng").get("ok", false)), "restock reserve qingheng")
	entry(blocked, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(blocked, "danxia").get("ok", false)), "restock reserve danxia")
	stock(blocked, "spirit_grass_low", 100.0)
	check(bool(MaidSystem.assign_duty(blocked, content, "danxia", restock(5, {"spirit_grass_low": 100.0})).get("ok", false)), "restock reserve assigned")
	var blocked_result: Dictionary = MaidSystem.execute_duty(blocked, content, "danxia")
	var blocked_duty: Dictionary = entry(blocked, "danxia").get("duty", {})
	check((not bool(blocked_result.get("ok", true)) and String(blocked_result.get("error", "")) == "INSUFFICIENT_RESOURCE") or (bool(blocked_result.get("ok", false)) and String(blocked_duty.get("status", "")) == "INSUFFICIENT_RESOURCE"), "restock reserve blocks")
	check(is_equal_approx(fp_count(blocked), 0.0), "reserve blocks refining")
func _test_reincarnation() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "reunion recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(2, {})).get("ok", false)), "reunion duty assigned")
	var data := entry(state, "qingheng")
	data.bond = 25
	data.chapters = {"qingheng_1": true}
	var bond_before := int(entry(state, "qingheng").bond)
	var chapters_before: Dictionary = entry(state, "qingheng").chapters
	MaidSystem.on_reincarnate(state)
	var after := entry(state, "qingheng")
	check(bool(after.get("recruited", false)), "recruitment survives rebirth")
	check(int(after.get("bond", -1)) == bond_before and after.get("chapters") == chapters_before, "bond and chapters unchanged")
	var duty: Dictionary = after.get("duty", {})
	check(bool(duty.get("paused", false)) and int(duty.get("cooldown", -1)) == 0, "duty pauses at rebirth")
	check(String(duty.get("recipe_id", "")) == "foundation_pill", "duty target survives")
	check(bool(after.get("reunion_pending", false)), "reunion pending")
	check(MaidSaveContract.validate(state.maid) == "", "maid block valid after rebirth")
	MaidSystem.reunion(state, "qingheng")
	var reunited := entry(state, "qingheng")
	check(not bool(reunited.get("reunion_pending", true)) and int(reunited.get("bond", -1)) == bond_before, "reunion clears flag without bond")
func _test_chapters() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "chapter qingheng recruited")
	var early: Dictionary = MaidSystem.claim_chapter(state, "qingheng", "qingheng_2")
	check(not bool(early.get("ok", true)) and String(early.get("error", "")).length() > 0, "chapters are sequential")
	entry(state, "qingheng").duty_actions = 9
	var short: Dictionary = MaidSystem.claim_chapter(state, "qingheng", "qingheng_1")
	check(not bool(short.get("ok", true)), "chapter one needs ten actions")
	entry(state, "qingheng").duty_actions = 10
	var claim1: Dictionary = MaidSystem.claim_chapter(state, "qingheng", "qingheng_1")
	check(bool(claim1.get("ok", false)), "qingheng chapter one " + String(claim1.get("error", "")))
	check(int(entry(state, "qingheng").bond) == 20 and entry(state, "qingheng").get("chapters", {}).get("qingheng_1") == true, "chapter grants bond and flag")
	var before := snap(state)
	var again: Dictionary = MaidSystem.claim_chapter(state, "qingheng", "qingheng_1")
	check(not bool(again.get("ok", true)) and String(again.get("error", "")).length() > 0 and snap(state) == before, "chapter claim is one time")
	var sect_gate: Dictionary = MaidSystem.claim_chapter(state, "qingheng", "qingheng_2")
	check(not bool(sect_gate.get("ok", true)), "sect gates chapter two")
	SectSystem.ensure_sect_state(state)
	state.sect.unlocked = true
	check(bool(MaidSystem.claim_chapter(state, "qingheng", "qingheng_2").get("ok", false)), "qingheng chapter two")
	check(int(entry(state, "qingheng").bond) == 50, "chapter two bond")
	var third_gate: Dictionary = MaidSystem.claim_chapter(state, "qingheng", "qingheng_3")
	check(not bool(third_gate.get("ok", true)), "rebirth gates chapter three")
	state.reincarnation_count = 1
	state.talents = {"resource_inheritance": 1}
	check(bool(MaidSystem.claim_chapter(state, "qingheng", "qingheng_3").get("ok", false)), "qingheng chapter three")
	check(int(entry(state, "qingheng").bond) == 100, "chapter three bond")
	check(bool(MaidSystem.recruit(state, "nuomeizi").get("ok", false)), "nuomeizi chapter recruit")
	entry(state, "nuomeizi").duty_actions = 2
	check(not bool(MaidSystem.claim_chapter(state, "nuomeizi", "nuomeizi_1").get("ok", true)), "nuomeizi needs three actions")
	entry(state, "nuomeizi").duty_actions = 3
	check(bool(MaidSystem.claim_chapter(state, "nuomeizi", "nuomeizi_1").get("ok", false)), "nuomeizi chapter one")
	check(int(entry(state, "nuomeizi").bond) == 20, "nuomeizi chapter one bond")
	state.skills = {"basic_meditation": 1}
	check(bool(MaidSystem.claim_chapter(state, "nuomeizi", "nuomeizi_2").get("ok", false)), "any skill gates nuomeizi two")
	check(bool(MaidSystem.claim_chapter(state, "nuomeizi", "nuomeizi_3").get("ok", false)), "nuomeizi chapter three")
	check(int(entry(state, "nuomeizi").bond) == 100, "nuomeizi chapter total")
	check(bool(MaidSystem.recruit(state, "danxia").get("ok", false)), "danxia chapter recruit")
	entry(state, "danxia").duty_actions = 4
	check(not bool(MaidSystem.claim_chapter(state, "danxia", "danxia_1").get("ok", true)), "danxia needs five actions")
	entry(state, "danxia").duty_actions = 5
	check(bool(MaidSystem.claim_chapter(state, "danxia", "danxia_1").get("ok", false)), "danxia chapter one")
	check(int(entry(state, "danxia").bond) == 20, "danxia chapter one bond")
	var beast_gate: Dictionary = MaidSystem.claim_chapter(state, "danxia", "danxia_2")
	check(not bool(beast_gate.get("ok", true)), "beast gates danxia two")
	state.beasts = {"active": {"id": "iron_turtle", "stage": "egg", "exp": 0}, "cooldown_remaining": 0.0}
	check(bool(MaidSystem.claim_chapter(state, "danxia", "danxia_2").get("ok", false)), "active beast unlocks danxia two")
	check(bool(MaidSystem.claim_chapter(state, "danxia", "danxia_3").get("ok", false)), "danxia chapter three")
	check(int(entry(state, "danxia").bond) == 100, "danxia chapter total")
	check(MaidSaveContract.validate(state.maid) == "", "chapter claims keep block valid")
func _test_determinism() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "twin recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(5, {"black_copper": 10.0})).get("ok", false)), "twin duty assigned")
	var twin := state.duplicate_state()
	check(snap(twin) == snap(state), "duplicate keeps maid progress")
	MaidSystem.advance(content, state, 30, MaidRules.MAX_ACTIONS_PER_CALL)
	MaidSystem.advance(content, twin, 30, MaidRules.MAX_ACTIONS_PER_CALL)
	check(snap(state) == snap(twin), "advance is deterministic")
func _test_budget() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "budget recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(100, {})).get("ok", false)), "budget duty assigned")
	var before := snap(state)
	var none: Dictionary = MaidSystem.advance(content, state, 43200, 0)
	check(none.get("events", []).is_empty() and snap(state) == before, "zero budget is a no-op")
	var capped: Dictionary = MaidSystem.advance(content, state, 43200, 2)
	check(_executed(capped.get("events", [])) == 2, "explicit budget caps actions")
	check(int(entry(state, "qingheng").get("duty_actions", 0)) == 2, "budget counts duty actions")
	stock(state, "spirit_grass_low", 100000.0)
	stock(state, "black_copper", 100000.0)
	stock(state, "lingli", 1000000.0)
	var more: Dictionary = MaidSystem.advance(content, state, 43200, 3)
	check(_executed(more.get("events", [])) == 3, "second explicit budget caps actions")

func _executed(events: Array) -> int:
	var count := 0
	for event in events:
		if event is Dictionary and String(event.get("kind", "")) == "maid_duty_executed":
			count += 1
	return count

func _test_session() -> void:
	var session := GameSession.create_new_game(content, 20261101)
	var state := session.state
	state.buildings.hut = 1
	var recruited: Dictionary = session.recruit_maid("qingheng")
	check(bool(recruited.get("ok", false)) and bool(entry(state, "qingheng").get("recruited", false)), "session recruit command")
	check(int(state.revision) == 1, "session command advances revision")
	state.era_id = 2
	state.buildings.herb_farm = 3
	stock(state, "spirit_grass_low", 1000.0)
	stock(state, "black_copper", 1000.0)
	stock(state, "lingli", 100000.0)
	stock(state, "foundation_pill", 0.0)
	var assigned: Dictionary = session.assign_maid_duty("qingheng", steward(1, {}))
	check(bool(assigned.get("ok", false)), "session assign command")
	var advanced: Dictionary = session.advance_time(10.0)
	check(bool(advanced.get("ok", false)) and int(advanced.get("ticks_advanced", 0)) == 10, "session time advances")
	check(advanced.get("changed_ids", []).has("maid"), "time advance reports maid")
	check(is_equal_approx(fp_count(state), 1.0), "online duty executes during time advance")
	var view := session.get_view()
	var maid_view: Dictionary = view.get("maid", {})
	var qingheng_view: Dictionary = maid_view.get("maids", {}).get("qingheng", {})
	check(bool(qingheng_view.get("recruited", false)) and int(qingheng_view.get("duty_actions", 0)) == 1, "session view exposes progress")

func _test_save() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "save recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(2, {"lingli": 500.0})).get("ok", false)), "save duty assigned")
	MaidSystem.execute_duty(state, content, "qingheng")
	var snapshot := state.to_snapshot_dict()
	var block: Variant = snapshot.get("maid", {})
	check(block is Dictionary and not (block as Dictionary).is_empty(), "maid enters snapshot")
	if not (block is Dictionary): return
	check(MaidSaveContract.validate(block) == "", "snapshot block valid")
	var normalized := MaidSaveContract.normalize(block)
	check(MaidSaveContract.validate(normalized) == "" and MaidSaveContract.normalize(normalized) == normalized, "normalize stable roundtrip")
	var encoded := SaveCodec.encode(state, content.content_version, META)
	check(bool(encoded.get("ok", false)), "encode maid save " + String(encoded.get("error", "")))
	if not bool(encoded.get("ok", false)): return
	var decoded: Dictionary = SaveCodec.decode(String(encoded.get("json", "")))
	check(bool(decoded.get("ok", false)), "decode maid save " + String(decoded.get("error", "")))
	if not bool(decoded.get("ok", false)): return
	var restored: GameState = decoded.get("state")
	check(restored != null and JSON.stringify(restored.to_snapshot_dict().get("maid", {})) == JSON.stringify(block), "maid survives save roundtrip")
	var corrupted := state.duplicate_state()
	corrupted.maid.maids.qingheng.bond = -1
	var bad_encode := SaveCodec.encode(corrupted, content.content_version, META)
	check(not bool(bad_encode.get("ok", true)) and String(bad_encode.get("error", "")).begins_with("MAID"), "corrupt maid blocks save")
