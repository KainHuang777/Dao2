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
	_test_view_options_and_shortage()
	_test_recruit()
	_test_parallel_duties()
	_test_steward()
	_test_oversee()
	_test_restock()
	_test_reincarnation()
	_test_display()
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
		check(MaidRules.chapters(id).size() == 4, "four chapters " + String(id))
	check(int(MaidRules.DUTY_CADENCE_SECONDS.steward_stock) == 10 and int(MaidRules.DUTY_CADENCE_SECONDS.oversee_build) == 30 and int(MaidRules.DUTY_CADENCE_SECONDS.restock_pills) == 10, "cadence 10/30/10")
	check(MaidRules.FIRST_DUTY_BOND == 10 and MaidRules.MAX_UNITS_PER_ACTION == 5, "first duty bond and unit cap")
	check(MaidRules.MAX_ACTIONS_PER_CALL == 5 and MaidSystem.MAX_ACTIONS_PER_ADVANCE == 1000, "advance budget constants")
	check(MaidSaveContract.VERSION == 2 and MaidSaveContract.MAX_BYTES == 16384, "contract constants")
	check(String(MaidRules.bond_level(40).id) == "xiangzhi" and int(MaidRules.next_bond(40).at) == 100, "bond level lookup")
	var presets := MaidRules.duty_presets("steward_stock")
	check(presets.size() == 3, "steward presets frozen")
	if presets.size() == 3:
		check(String(presets[0].id) == "steady" and int(presets[0].target) == 5 and is_equal_approx(float(presets[0].reserve_ratio), 0.2), "steady preset 5/20%")
		check(String(presets[2].id) == "rush" and int(presets[2].target) == 20 and is_equal_approx(float(presets[2].reserve_ratio), 0.0), "rush preset 20/0%")
	check(MaidRules.duty_presets("restock_pills").size() == 3, "restock presets frozen")
	check(MaidRules.duty_presets("oversee_build").is_empty(), "overseer has no presets")
	check(MaidRules.duty_presets("bogus").is_empty(), "unknown duty has no presets")
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
	check(MaidSaveContract.validate({"version": 3, "maids": {}}) == "MAID_VERSION", "wrong version rejected")
	check(MaidSaveContract.validate({"version": 1.5, "maids": {}}) == "MAID_VERSION", "fractional version rejected")
	check(MaidSaveContract.validate({"version": 2, "maids": {}}) == "MAID_KEYS", "v2 without display rejected")
	check(MaidSaveContract.validate({"version": 1, "maids": {}}) == "", "legacy v1 accepted")
	var migrated := MaidSaveContract.normalize({"version": 1, "maids": {}})
	check(int(migrated.get("version", 0)) == 2 and migrated.get("display") == {"expanded": true, "maid_id": ""}, "legacy normalizes to v2 default display")
	var display_bad := fixture(qingheng_entry())
	display_bad.display["extra"] = true
	check(MaidSaveContract.validate(display_bad) == "MAID_DISPLAY", "display extra key rejected")
	display_bad = fixture(qingheng_entry())
	display_bad.display.expanded = 1
	check(MaidSaveContract.validate(display_bad) == "MAID_DISPLAY", "non bool expanded rejected")
	display_bad = fixture(qingheng_entry())
	display_bad.display.maid_id = 5
	check(MaidSaveContract.validate(display_bad) == "MAID_DISPLAY", "non string display maid rejected")
	display_bad = fixture(qingheng_entry())
	display_bad.display.maid_id = "bogus"
	check(MaidSaveContract.validate(display_bad) == "MAID_DISPLAY", "unknown display maid rejected")
	display_bad = fixture(qingheng_entry())
	display_bad.display = {"expanded": false, "maid_id": "nuomeizi"}
	check(MaidSaveContract.validate(display_bad) == "", "collapsed manual display valid")
	display_bad = fixture(qingheng_entry())
	display_bad.display.maid_id = ""
	check(MaidSaveContract.validate(display_bad) == "", "auto display valid")
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
	check(normalized.version is int and int(normalized.version) == 2, "normalize version int")
	check(normalized.get("display") == {"expanded": true, "maid_id": ""}, "normalize adds default display")
	check(MaidSaveContract.normalize(normalized) == normalized, "normalize stable")
	check((normalized.get("maids", {}) as Dictionary).size() == 1, "normalize adds no maid entries")
	check(MaidSaveContract.normalize({}) == {}, "normalize empty safe")
	var parsed: Variant = JSON.parse_string(JSON.stringify(jsonlike))
	var reparsed := MaidSaveContract.normalize(parsed)
	check(reparsed == normalized, "normalize survives json transport")
func fixture(entry_data: Variant) -> Dictionary:
	return {"version": 2, "maids": {"qingheng": entry_data}, "display": {"expanded": true, "maid_id": ""}}
func qingheng_entry() -> Dictionary:
	return {"recruited": true, "bond": 45, "chapters": {"qingheng_1": true}, "duty": {"kind": "steward_stock", "paused": false, "cooldown": 5, "status": "RUNNING", "recipe_id": "foundation_pill", "target": 2, "reserve": {"spirit_grass_low": "50", "black_copper": 20}}, "duty_actions": 12, "reunion_pending": false, "first_duty_done": true}
func _test_view() -> void:
	var state := fresh()
	var before := snap(state)
	var view: Dictionary = MaidSystem.get_view(state, content)
	check(snap(state) == before, "view is pure read")
	check(int(view.get("version", 0)) == 2, "view version two")
	check(view.get("display") == {"expanded": true, "maid_id": ""}, "view exposes default display")
	var maids_view: Variant = view.get("maids", {})
	check(maids_view is Dictionary and (maids_view as Dictionary).size() == 3, "view lists three maids")
	if maids_view is Dictionary:
		for id in MaidRules.MAID_IDS:
			var item: Variant = (maids_view as Dictionary).get(id, {})
			check(item is Dictionary and not bool((item as Dictionary).get("recruited", true)), "view unrecruited " + String(id))
func _test_view_options_and_shortage() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "options qingheng recruited")
	var before := snap(state)
	var view: Dictionary = MaidSystem.get_view(state, content)
	check(snap(state) == before, "view with options stays pure")
	var qing: Dictionary = view.get("maids", {}).get("qingheng", {})
	var options: Dictionary = qing.get("options", {})
	var recipe := {}
	for raw in options.get("recipes", []):
		if String(raw.get("id", "")) == "foundation_pill": recipe = raw
	check(not recipe.is_empty(), "recipe option exposed")
	check(is_equal_approx(float(recipe.get("output", 0.0)), 1.0) and is_equal_approx(float(recipe.get("stock", -1)), 0.0), "recipe option output and stock")
	var inputs: Array = recipe.get("inputs", [])
	check(inputs.size() == 3, "recipe option lists three inputs")
	var per_batch := {}
	for raw in inputs:
		var row: Dictionary = raw
		check(not String(row.get("name", "")).is_empty() and row.has("per_batch") and row.has("stock"), "input row metadata " + String(row.get("id", "")))
		per_batch[String(row.get("id", ""))] = float(row.get("per_batch", 0.0))
	check(is_equal_approx(per_batch.get("spirit_grass_low", 0.0), 50.0) and is_equal_approx(per_batch.get("black_copper", 0.0), 20.0) and is_equal_approx(per_batch.get("lingli", 0.0), 200.0), "recipe input amounts")
	var pill := {}
	for raw in options.get("pills", []):
		if String(raw.get("id", "")) == "foundation_pill": pill = raw
	check(not pill.is_empty() and is_equal_approx(float(pill.get("stock", -1)), 0.0), "pill option exposed")
	var cost: Array = pill.get("cost", [])
	check(cost.size() == 3, "pill option lists three costs")
	var per_unit := {}
	for raw in cost:
		var row: Dictionary = raw
		check(not String(row.get("name", "")).is_empty() and float(row.get("per_unit", 0.0)) > 0.0, "cost row metadata " + String(row.get("id", "")))
		per_unit[String(row.get("id", ""))] = float(row.get("per_unit", 0.0))
	check(is_equal_approx(per_unit.get("spirit_grass_low", 0.0), 50.0), "pill cost mirrors alchemy")
	stock(state, "spirit_grass_low", 60.0)
	stock(state, "black_copper", 0.0)
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(3, {})).get("ok", false)), "shortage duty assigned")
	var shortage: Dictionary = MaidSystem.get_view(state, content).get("maids", {}).get("qingheng", {}).get("duty", {}).get("shortage", {})
	check(String(shortage.get("code", "")) == "INSUFFICIENT_RESOURCE" and int(shortage.get("requested", 0)) == 3, "steward shortage code and batches")
	var rows: Array = shortage.get("inputs", [])
	check(rows.size() == 1 and String(rows[0].get("id", "")) == "black_copper" and String(rows[0].get("name", "")) == "玄銅", "steward shortage names the limiting input")
	if rows.size() == 1:
		check(is_equal_approx(float(rows[0].get("required", 0.0)), 60.0) and is_equal_approx(float(rows[0].get("missing", 0.0)), 60.0) and is_equal_approx(float(rows[0].get("stock", -1)), 0.0), "steward shortage amounts")
	var shortage_text := String(MaidSystem.get_view(state, content).get("maids", {}).get("qingheng", {}).get("duty", {}).get("shortage_text", ""))
	check(shortage_text.contains("玄銅不足") and shortage_text.contains("需") and not shortage_text.contains("保留"), "steward shortage text")
	var reserved := prepared()
	check(bool(MaidSystem.recruit(reserved, "qingheng").get("ok", false)), "reserve shortage recruited")
	stock(reserved, "spirit_grass_low", 60.0)
	check(bool(MaidSystem.assign_duty(reserved, content, "qingheng", steward(3, {"spirit_grass_low": 100})).get("ok", false)), "reserve shortage assigned")
	var reserved_view: Dictionary = MaidSystem.get_view(reserved, content).get("maids", {}).get("qingheng", {}).get("duty", {})
	var reserved_rows: Array = reserved_view.get("shortage", {}).get("inputs", [])
	check(reserved_rows.size() == 1 and String(reserved_rows[0].get("id", "")) == "spirit_grass_low" and is_equal_approx(float(reserved_rows[0].get("reserve", 0.0)), 100.0), "reserve shortage keeps the reserve")
	check(String(reserved_view.get("shortage_text", "")).contains("保留"), "reserve shortage text names the reserve")
	var restock_state := prepared()
	check(bool(MaidSystem.recruit(restock_state, "qingheng").get("ok", false)), "shortage restock qingheng")
	entry(restock_state, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(restock_state, "danxia").get("ok", false)), "shortage restock danxia")
	stock(restock_state, "spirit_grass_low", 100.0)
	check(bool(MaidSystem.assign_duty(restock_state, content, "danxia", restock(2, {"spirit_grass_low": 1000})).get("ok", false)), "restock reserve assigned")
	var restock_duty: Dictionary = MaidSystem.get_view(restock_state, content).get("maids", {}).get("danxia", {}).get("duty", {})
	var restock_rows: Array = restock_duty.get("shortage", {}).get("inputs", [])
	check(restock_rows.size() == 1 and String(restock_rows[0].get("id", "")) == "spirit_grass_low" and is_equal_approx(float(restock_rows[0].get("reserve", 0.0)), 1000.0), "restock shortage honours the reserve")
	check(String(restock_duty.get("shortage_text", "")).contains("低階靈草不足") and String(restock_duty.get("shortage_text", "")).contains("保留"), "restock shortage text")
	var oversee_state := prepared()
	check(bool(MaidSystem.recruit(oversee_state, "qingheng").get("ok", false)), "shortage oversee qingheng")
	entry(oversee_state, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(oversee_state, "nuomeizi").get("ok", false)), "shortage oversee nuomeizi")
	stock(oversee_state, "money", 0.0)
	stock(oversee_state, "lingli", 0.0)
	check(bool(MaidSystem.assign_duty(oversee_state, content, "nuomeizi", oversee("hut")).get("ok", false)), "oversee shortage assigned")
	var oversee_duty: Dictionary = MaidSystem.get_view(oversee_state, content).get("maids", {}).get("nuomeizi", {}).get("duty", {})
	var oversee_rows: Array = oversee_duty.get("shortage", {}).get("inputs", [])
	check(oversee_rows.size() == 1 and String(oversee_rows[0].get("id", "")) in ["money", "lingli"] and float(oversee_rows[0].get("missing", 0.0)) > 0.0, "oversee shortage reports the cost resource")
	check(String(oversee_duty.get("shortage_text", "")).contains("不足"), "oversee shortage text")
	check(MaidSaveContract.validate(oversee_state.maid) == "" and not overseer_shorts_persist(oversee_state), "shortage stays out of the save block")
func overseer_shorts_persist(state: GameState) -> bool:
	return JSON.stringify(state.maid).contains("shortage")
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
func _test_parallel_duties() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "parallel qingheng recruited")
	entry(state, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(state, "nuomeizi").get("ok", false)), "parallel nuomeizi recruited")
	check(bool(MaidSystem.recruit(state, "danxia").get("ok", false)), "parallel danxia recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(2, {})).get("ok", false)), "parallel steward assigned")
	var second: Dictionary = MaidSystem.assign_duty(state, content, "nuomeizi", oversee("hut"))
	check(bool(second.get("ok", false)), "parallel oversee assigned " + String(second.get("error", "")))
	var third: Dictionary = MaidSystem.assign_duty(state, content, "danxia", restock(2, {}))
	check(bool(third.get("ok", false)), "parallel restock assigned " + String(third.get("error", "")))
	var view: Dictionary = MaidSystem.get_view(state, content)
	var active: Array = view.get("active_duties", [])
	check(active.size() == 3 and active.has("qingheng") and active.has("nuomeizi") and active.has("danxia"), "view lists all active duties")
	check(not active.is_empty() and String(view.get("active_duty", "")) == String(active[0]), "view keeps a first active duty")
	check(bool(MaidSystem.set_duty_paused(state, "qingheng", true).get("ok", false)), "parallel pause one")
	check(MaidSystem.get_view(state, content).get("active_duties", []).size() == 2, "paused duty leaves the active list")
	var resumed: Dictionary = MaidSystem.set_duty_paused(state, "qingheng", false)
	check(bool(resumed.get("ok", false)), "parallel resume while others run " + String(resumed.get("error", "")))
	check(MaidSaveContract.validate(state.maid) == "", "parallel duties keep contract valid")
	var share := prepared()
	check(bool(MaidSystem.recruit(share, "qingheng").get("ok", false)), "share qingheng recruited")
	entry(share, "qingheng").bond = 40
	check(bool(MaidSystem.recruit(share, "nuomeizi").get("ok", false)), "share nuomeizi recruited")
	check(bool(MaidSystem.recruit(share, "danxia").get("ok", false)), "share danxia recruited")
	check(bool(MaidSystem.assign_duty(share, content, "qingheng", steward(200, {})).get("ok", false)), "share steward assigned")
	check(bool(MaidSystem.assign_duty(share, content, "nuomeizi", oversee("hut")).get("ok", false)), "share oversee assigned")
	check(bool(MaidSystem.assign_duty(share, content, "danxia", restock(5, {})).get("ok", false)), "share restock assigned")
	var advanced: Dictionary = MaidSystem.advance(content, share, 60, MaidRules.MAX_ACTIONS_PER_CALL)
	for maid_id in ["qingheng", "nuomeizi", "danxia"]:
		check(int(entry(share, maid_id).get("duty_actions", 0)) > 0, "shared budget serves " + String(maid_id))
	check(_executed(advanced.get("events", [])) >= 3, "shared budget reports every maid action")
	check(MaidSaveContract.validate(share.maid) == "", "shared budget keeps contract valid")
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
func _test_display() -> void:
	var state := prepared()
	check(MaidSystem.display(state) == {"expanded": true, "maid_id": ""}, "display defaults")
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "display recruited")
	var roster_before := JSON.stringify(state.maid.get("maids", {}))
	var set_result: Dictionary = MaidSystem.set_display(state, false, "qingheng")
	check(bool(set_result.get("ok", false)) and set_result.get("changed_ids", []).has("maid"), "display set reports maid")
	check(MaidSystem.display(state) == {"expanded": false, "maid_id": "qingheng"}, "display stored")
	check(JSON.stringify(state.maid.get("maids", {})) == roster_before, "display leaves roster untouched")
	check(MaidSaveContract.validate(state.maid) == "", "display block valid")
	var noop: Dictionary = MaidSystem.set_display(state, false, "qingheng")
	check(bool(noop.get("ok", false)) and noop.get("changed_ids", []).is_empty(), "display no-op")
	var unknown: Dictionary = MaidSystem.set_display(state, true, "bogus")
	check(not bool(unknown.get("ok", true)) and String(unknown.get("error", "")) == "UNKNOWN_MAID", "unknown display maid rejected")
	check(MaidSystem.display(state) == {"expanded": false, "maid_id": "qingheng"}, "failed display leaves state")
	var view: Dictionary = MaidSystem.get_view(state, content)
	check(view.get("display") == {"expanded": false, "maid_id": "qingheng"}, "view exposes display")
	MaidSystem.set_display(state, false, "")
	check(MaidSystem.display(state) == {"expanded": false, "maid_id": ""}, "auto display clears manual")
	MaidSystem.on_reincarnate(state)
	check(MaidSystem.display(state) == {"expanded": false, "maid_id": ""}, "display survives rebirth hook")
	state.buildings.rebirth_lotus = 1
	var reborn: Dictionary = ReincarnationRules.apply_reincarnation(state, content, "normal", "maid-display")
	check(bool(reborn.get("ok", false)), "full rebirth applies " + String(reborn.get("error", "")))
	check(MaidSystem.display(state) == {"expanded": false, "maid_id": ""}, "display survives full rebirth")
	check(MaidSaveContract.validate(state.maid) == "", "display block valid after rebirth")
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
	var display_set: Dictionary = session.set_maid_display(false, "qingheng")
	check(bool(display_set.get("ok", false)) and MaidSystem.display(state) == {"expanded": false, "maid_id": "qingheng"}, "session display command")
	var display_auto: Dictionary = session.set_maid_display(true)
	check(bool(display_auto.get("ok", false)) and MaidSystem.display(state) == {"expanded": true, "maid_id": ""}, "session display auto")
	var display_bad: Dictionary = session.submit({"command_id": "display_bad_shape", "type": "set_maid_display", "expected_revision": state.revision, "payload": {"expanded": "yes"}})
	check(not bool(display_bad.get("ok", true)), "session rejects display shape")
	var display_unknown: Dictionary = session.submit({"command_id": "display_unknown_maid", "type": "set_maid_display", "expected_revision": state.revision, "payload": {"expanded": true, "maid_id": "bogus"}})
	check(not bool(display_unknown.get("ok", true)), "session rejects unknown display maid")

func _test_save() -> void:
	var state := prepared()
	check(bool(MaidSystem.recruit(state, "qingheng").get("ok", false)), "save recruited")
	check(bool(MaidSystem.assign_duty(state, content, "qingheng", steward(2, {"lingli": 500.0})).get("ok", false)), "save duty assigned")
	MaidSystem.execute_duty(state, content, "qingheng")
	MaidSystem.set_display(state, false, "qingheng")
	var snapshot := state.to_snapshot_dict()
	var block: Variant = snapshot.get("maid", {})
	check(block is Dictionary and not (block as Dictionary).is_empty(), "maid enters snapshot")
	if not (block is Dictionary): return
	check((block as Dictionary).get("display") == {"expanded": false, "maid_id": "qingheng"}, "display enters snapshot")
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
