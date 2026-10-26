extends SceneTree
const BUILD_ORDER := [
	"hut", "hut", "wooden_house", "wooden_house",
	"forest_farm", "forest_farm", "forest_farm",
	"stone_mine", "stone_mine", "stone_mine",
	"herb_farm", "herb_farm", "herb_farm",
	"storage_wood", "storage_money", "storage_money",
	"storage_stone", "storage_herb", "storage_lingli", "storage_lingli",
]
const ERA2_SKILLS := ["basic_meditation", "qi_condensation", "foundation_building", "qi_storage_1", "body_strengthening_1", "building_mastery_1"]
const FROZEN_SKILL_DEFS := {
	"basic_meditation": {"era": 2, "cost": 90.0, "max_level": 5, "effect": "lingli_multiplier", "amount": 1.1},
	"qi_condensation": {"era": 2, "cost": 1800.0, "max_level": 5, "effect": "lingli_rate", "amount": 2.0},
	"foundation_building": {"era": 2, "cost": 3600.0, "max_level": 5, "effect": "money_multiplier", "amount": 1.2},
	"qi_storage_1": {"era": 2, "cost": 120.0, "max_level": 1, "effect": "lingli_max", "amount": 200.0},
	"body_strengthening_1": {"era": 2, "cost": 1000.0, "max_level": 1, "effect": "money_max", "amount": 2000.0},
	"building_mastery_1": {"era": 2, "cost": 200.0, "max_level": 1, "effect": "building_level_cap", "amount": 10.0},
	"golden_core_formation": {"era": 3, "cost": 7650.0, "max_level": 5, "effect": "time_multiplier", "amount": 0.9},
}
const SAVE_META := {"save_id": "early-v1c", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
const OUT_JSON := "res://docs/verification/artifacts/early-v1-c/runner-measurement.json"
var content: GameContent
var helper = preload("res://src/verification/res1d2_contract.gd").new()
var failures: Array[String] = []
var checks := 0
var serial := 0
var last_cid := ""
var era2_fresh: GameState
var era3_state: GameState
var golden_saved_state: GameState
var table: Array = []
var golden_report: Dictionary = {}
var notes: Array[String] = []

class Memory extends StorageAdapter:
	var data := {}
	var refuse := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if refuse:
			return {"ok": false, "error": "injected"}
		data[key] = value
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func send(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	last_cid = "early-v1c-" + str(serial)
	return s.submit({"command_id": last_cid, "type": kind, "expected_revision": s.state.revision, "payload": payload})

func points(s: GameSession) -> float:
	return float((s.state.resources["skill_point"]["value"] as AmountCompat).to_float())

func view_number(s: GameSession, resource_id: String, field: String) -> float:
	var view := s.get_view()
	var res: Dictionary = view["resources"]
	var entry: Dictionary = res[resource_id]
	var parsed: Dictionary = AmountCompat.try_parse(String(entry[field]))
	if not bool(parsed.get("ok", false)):
		return -1.0
	return float((parsed["value"] as AmountCompat).to_float())

func skill_item(s: GameSession, id: String) -> Dictionary:
	var view := s.get_view()
	var skills_view: Dictionary = view["skills"]
	var items: Array = skills_view["items"]
	for item in items:
		var entry: Dictionary = item
		if String(entry.get("id", "")) == String(id):
			return entry
	return {}

func branch(state: GameState) -> GameSession:
	var s := GameSession.new()
	s.content = content
	s.clock = GameClock.create(float(state.total_elapsed_seconds))
	s.state = state.duplicate_state()
	return s

func modifiers_clean(s: GameSession) -> bool:
	var buffs: Dictionary = BuffSystem.compute_multipliers(s.state)
	if float(buffs.get("global_production_multiplier", 0.0)) != 0.0:
		return false
	if float(s.state.pill_effects.get("production_multiplier", 0.0)) != 0.0:
		return false
	var chrono: Dictionary = ChronoSystem.compute_multipliers(s.state)
	if float(chrono.get("global_production_multiplier", 0.0)) != 0.0 or float(chrono.get("storage_bonus", 0.0)) != 0.0:
		return false
	var beast: Dictionary = BeastSystem.compute_multipliers(s.state)
	if float(beast.get("global_production_multiplier", 0.0)) != 0.0 or float(beast.get("all_capacity_mult", 0.0)) != 0.0:
		return false
	return s.state.dao_heart.to_float() <= 0.0

func wait_clean(s: GameSession) -> void:
	var guard := 0
	while not modifiers_clean(s) and guard < 30:
		guard += 1
		s.advance_time(10.0)
	check(modifiers_clean(s), "modifiers clean after settle")

func accumulate_to(s: GameSession, target: float, chunk: float) -> float:
	var start := float(s.state.total_elapsed_seconds)
	var guard := 0
	while points(s) < target and guard < 1600:
		guard += 1
		s.advance_time(chunk)
	return float(s.state.total_elapsed_seconds) - start

func reject_learn(s: GameSession, id: String, error: String) -> void:
	var before: Dictionary = s.state.to_snapshot_dict()
	var result: Dictionary = send(s, "learn_skill", {"skill_id": id})
	check(not bool(result.get("ok", false)) and String(result.get("error", "")) == error, "reject " + id + " expects " + error + " got " + str(result.get("error", "")))
	check(before == s.state.to_snapshot_dict(), "atomic rejection " + id + " " + error)

func level_to(s: GameSession, target: int) -> bool:
	var guard_total := 0
	while s.state.level < target and guard_total < 20000:
		guard_total += 1
		var guard := 0
		while not bool(s.get_view().can_level_up) and guard < 5000:
			guard += 1
			var view := s.get_view()
			if bool(view.training_complete):
				s.advance_time(10.0)
			else:
				var need := maxf(1.0, ceilf(float(view.next_level_required_seconds) - float(view.training_seconds)))
				s.advance_time(need)
		var result := send(s, "level_up_cultivation", {})
		if not bool(result.get("ok", false)):
			return false
	return s.state.level == target

func _run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	content = loaded.content
	helper.content = content
	var attach := IslandProgression.attach(content)
	check(bool(attach.get("ok", false)), "official content attach")
	check(content.skill_defs.size() == 24, "twenty-four skill definitions")
	var version_before := content.content_version
	var attach_again := IslandProgression.attach(content)
	check(bool(attach_again.get("ok", false)) and content.content_version == version_before, "attach idempotent")
	for id in FROZEN_SKILL_DEFS:
		var frozen: Dictionary = FROZEN_SKILL_DEFS[id]
		var def: Dictionary = content.skill_defs.get(id, {})
		check(not def.is_empty()
			and int(def.get("era", 2)) == int(frozen.era)
			and is_equal_approx(float(def.get("cost", 0.0)), float(frozen.cost))
			and int(def.get("max_level", 0)) == int(frozen.max_level)
			and String(def.get("effect", "")) == String(frozen.effect)
			and is_equal_approx(float(def.get("amount", 0.0)), float(frozen.amount)),
			"frozen numbers " + String(id))
	var sp_def: Dictionary = content.resources.get("skill_point", {})
	check(is_equal_approx(float(sp_def.get("max", 0.0)), 200.0) and not bool(sp_def.get("unlocked", true)), "skill_point base cap 200 and locked by default")
	var golden_def: Dictionary = content.skill_defs.get("golden_core_formation", {})
	var requires: Dictionary = golden_def.get("requires", {})
	check(String(requires.get("skill_id", "")) == "foundation_building" and int(requires.get("level", 0)) == 1, "golden prereq frozen")
	if not play_prefix():
		notes.append("prefix failed; later sessions skipped")
	else:
		run_era2_sessions()
		run_golden_session()
		run_reincarnation_session()
		if not golden_report.is_empty():
			run_persistence_session()
	print_table()
	write_artifact()
	if failures.is_empty():
		print("PASS: EARLY-V1-C %d checks" % checks)
		RunnerResult.finish(self, 0)
		return
	for failure in failures:
		print("FAIL: " + failure)
	print("EARLY-V1-C %d checks with %d failures" % [checks, failures.size()])
	RunnerResult.finish(self, 1)

func play_prefix() -> bool:
	var s := GameSession.create_new_game(content, 20261018)
	check(s.state.era_id == 1 and s.state.skill_version == 4, "blank save skill state v4")
	check(s.get_view().skills.items.size() == 24, "twenty-four skill view items")
	check(not bool(s.state.resources.skill_point.unlocked) and points(s) == 0.0, "skill_point locked and zero on blank save")
	var blank_opened := bool((s.get_view().skills as Dictionary).opened)
	check(not blank_opened, "study panel closed on blank save")
	for item_variant in (s.get_view().skills as Dictionary).items:
		var item: Dictionary = item_variant
		check(String(item.get("reason", "")) == "SKILL_STUDY_LOCKED" and not bool(item.get("can_learn", true)), "study-locked view " + String(item.get("id", "")))
	reject_learn(s, "rogue_skill", "UNKNOWN_SKILL")
	reject_learn(s, "basic_meditation", "SKILL_STUDY_LOCKED")
	var before_upgrade: Dictionary = s.state.to_snapshot_dict()
	var locked_build := send(s, "upgrade_building", {"building_id": "library"})
	check(not bool(locked_build.get("ok", false)) and String(locked_build.get("error", "")) == "ERA_REQUIREMENT" and before_upgrade == s.state.to_snapshot_dict(), "library era-gated on Era1 atomically")
	for id in BUILD_ORDER:
		if not helper.build(s, id):
			check(false, "earned build " + String(id))
			return false
	if not level_to(s, 10):
		check(false, "earned Era1 Lv10")
		return false
	var first := send(s, "breakthrough_era", {})
	check(bool(first.get("ok", false)) and s.state.era_id == 2, "earned Era2 breakthrough")
	reject_learn(s, "basic_meditation", "SKILL_STUDY_LOCKED")
	if not bool(send(s, "activate_islands", {}).get("ok", false)):
		check(false, "earned activate_islands")
		return false
	for island in ["wood", "ore"]:
		if not bool(send(s, "open_island", {"island_id": island}).get("ok", false)):
			check(false, "earned open " + island)
			return false
	for route in IslandEconomy.ROUTES:
		if String(IslandEconomy.ROUTES[route][0]) != "herb":
			if not bool(send(s, "configure_route", {"route_id": route}).get("ok", false)):
				check(false, "earned route " + String(route))
				return false
	for pair in [["spirit_timber", "wood"], ["bronze_essence", "ore"]]:
		if not helper.wait_craft(s, String(pair[0]), String(pair[1])):
			check(false, "earned producer " + String(pair[0]))
			return false
	for _batch in range(30):
		if not helper.wait_recipe(s, "liquid"):
			check(false, "earned liquid batch")
			return false
	if not helper.build(s, "library"):
		check(false, "earned library")
		return false
	check(bool(s.state.resources.skill_point.unlocked), "library unlocks skill_point")
	wait_clean(s)
	check(modifiers_clean(s), "no production modifiers at rate window")
	check(is_equal_approx(view_rate(s), 2.0), "library Lv1 view rate 2.0")
	check(absf(view_cap(s, "skill_point") - 200.0) < 0.0001, "view cap 200 before scripture")
	var before_rate := points(s)
	s.advance_time(40.0)
	check(absf(points(s) - before_rate - 80.0) < 0.01, "rate delta matches 2.0/s over 40s")
	var seconds_to_cap := accumulate_to(s, 200.0, 10.0)
	check(points(s) == 200.0 and absf(view_cap(s, "skill_point") - 200.0) < 0.0001, "capped at base 200")
	s.advance_time(600.0)
	check(points(s) == 200.0, "stuck at base cap")
	notes.append("library Lv1 measured rate 2.0/s (content rate 1 x Era2 multiplier 2); cap 200 reached in %.0f simulated seconds" % (seconds_to_cap + 40.0))
	if not helper.build(s, "storage_wood"):
		check(false, "earned storage_wood Lv2")
		return false
	if not helper.build(s, "scripture_hall"):
		check(false, "earned scripture_hall")
		return false
	check(absf(view_cap(s, "skill_point") - 6200.0) < 0.0001, "scripture_hall raises cap to 6200")
	var caps := Production.compute_caps(content, s.state.buildings, 2, 1, {})
	check(float((caps["skill_point"] as AmountCompat).to_float()) == 6200.0, "scripture formula 200+6000=6200")
	reject_learn(s, "golden_core_formation", "SKILL_ERA_LOCKED")
	check(String(skill_item(s, "golden_core_formation").get("reason", "")) == "SKILL_ERA_LOCKED", "era-locked view reason at Era2")
	era2_fresh = s.state.duplicate_state()
	if not level_to(s, 10):
		check(false, "earned Era2 Lv10")
		return false
	var bank_wait := accumulate_to(s, 6200.0, 10.0)
	check(points(s) == 6200.0, "natural accumulation fills scripture cap 6200")
	s.advance_time(600.0)
	check(points(s) == 6200.0, "stuck at scripture cap 6200")
	notes.append("era2 points bank 6200 filled in %.0f simulated seconds at library Lv1" % bank_wait)
	if not helper.build(s, "foundation_reservoir") or not helper.build(s, "foundation_reservoir"):
		check(false, "earned foundation_reservoir x2")
		return false
	var second := send(s, "breakthrough_era", {})
	check(bool(second.get("ok", false)) and s.state.era_id == 3, "earned Era3 breakthrough")
	era3_state = s.state.duplicate_state()
	return true

func view_rate(s: GameSession) -> float:
	return view_number(s, "skill_point", "rate")

func view_cap(s: GameSession, resource_id: String) -> float:
	return view_number(s, resource_id, "cap")

func run_era2_sessions() -> void:
	for id in ERA2_SKILLS:
		run_era2_session(String(id))

func run_era2_session(id: String) -> void:
	var s := branch(era2_fresh)
	var def: Dictionary = content.skill_defs[id]
	var cost := float(def.cost)
	wait_clean(s)
	check(is_equal_approx(view_rate(s), 2.0), "session rate 2.0 " + id)
	if cost > points(s):
		check(String(skill_item(s, id).get("reason", "")) == "INSUFFICIENT_SKILL_POINT", "point-shortage view reason " + id)
	var wait_seconds := accumulate_to(s, cost, 10.0)
	var before := points(s)
	var learn := send(s, "learn_skill", {"skill_id": id})
	check(bool(learn.get("ok", false)) and int(s.state.skills.get(id, 0)) == 1, "earned learn Lv1 " + id)
	check(absf(before - points(s) - cost) < 0.001, "exact deduction " + id)
	var after_learn := points(s)
	var replay := s.submit({"command_id": last_cid, "type": "learn_skill", "expected_revision": s.state.revision, "payload": {"skill_id": id}})
	check(bool(replay.get("ok", false)) and bool(replay.get("duplicate", false)) and int(s.state.skills.get(id, 0)) == 1 and points(s) == after_learn, "receipt replay no double charge " + id)
	if int(def.max_level) == 1:
		reject_learn(s, id, "SKILL_MAX_LEVEL")
		check(String(skill_item(s, id).get("reason", "")) == "SKILL_MAX_LEVEL", "max-level view reason " + id)
	var second_level_seconds := 0.0
	if id == "foundation_building":
		second_level_seconds = accumulate_to(s, cost, 10.0)
		var before_two := points(s)
		check(bool(send(s, "learn_skill", {"skill_id": id}).get("ok", false)) and int(s.state.skills[id]) == 2, "foundation Lv2 learn")
		check(absf(before_two - points(s) - cost) < 0.001, "foundation Lv2 exact deduction")
		check(is_equal_approx(SkillSystem.effect(content, s.state.skills, "money_multiplier"), pow(1.2, 2)), "foundation Lv2 pow 1.44")
	effect_check(id, s)
	table.append({
		"skill": id,
		"era": int(def.get("era", 2)),
		"cost": cost,
		"max_level": int(def.max_level),
		"point_rate_per_s": 2.0,
		"cap_context": "200 base / 6200 with scripture_hall",
		"acquisition_seconds_derived": cost / 2.0,
		"session_wait_seconds_simulated": wait_seconds,
		"prerequisite": "none",
		"effect_at_Lv1": String(def.effect) + " " + str(float(def.amount)),
		"second_level_wait": second_level_seconds,
		"mode": "official commands, cloned fully earned Era2 prefix, natural accumulation",
	})

func effect_check(id: String, s: GameSession) -> void:
	match id:
		"basic_meditation":
			var plain: Dictionary = Production.compute_rates(content, s.state.buildings, 2.0, {})
			var boosted: Dictionary = Production.compute_rates(content, s.state.buildings, 2.0, s.state.skills)
			check(is_equal_approx(float((boosted["lingli"] as AmountCompat).to_float()), float((plain["lingli"] as AmountCompat).to_float()) * 1.1), "basic_meditation lingli multiplier pow")
			check(is_equal_approx(SkillSystem.effect(content, s.state.skills, "lingli_multiplier"), 1.1), "basic_meditation effect value")
		"qi_condensation":
			var plain2: Dictionary = Production.compute_rates(content, s.state.buildings, 2.0, {})
			var boosted2: Dictionary = Production.compute_rates(content, s.state.buildings, 2.0, s.state.skills)
			check(absf(float((boosted2["lingli"] as AmountCompat).to_float()) - float((plain2["lingli"] as AmountCompat).to_float()) - 4.0) < 0.001, "qi_condensation additive 2 scaled by era x2")
			check(is_equal_approx(SkillSystem.effect(content, s.state.skills, "lingli_rate"), 2.0), "qi_condensation effect value")
		"foundation_building":
			var plain3: Dictionary = Production.compute_rates(content, s.state.buildings, 2.0, {})
			var boosted3: Dictionary = Production.compute_rates(content, s.state.buildings, 2.0, s.state.skills)
			check(is_equal_approx(float((boosted3["money"] as AmountCompat).to_float()), float((plain3["money"] as AmountCompat).to_float()) * pow(1.2, float(int(s.state.skills.get("foundation_building", 0))))), "foundation_building money multiplier pow")
		"qi_storage_1":
			var caps_plain: Dictionary = Production.compute_caps(content, s.state.buildings, 2, 1, {})
			var caps_skill: Dictionary = Production.compute_caps(content, s.state.buildings, 2, 1, s.state.skills)
			check(absf(float((caps_skill["lingli"] as AmountCompat).to_float()) - float((caps_plain["lingli"] as AmountCompat).to_float()) - 200.0) < 0.001, "qi_storage_1 lingli cap +200")
		"body_strengthening_1":
			var caps_plain2: Dictionary = Production.compute_caps(content, s.state.buildings, 2, 1, {})
			var caps_skill2: Dictionary = Production.compute_caps(content, s.state.buildings, 2, 1, s.state.skills)
			check(absf(float((caps_skill2["money"] as AmountCompat).to_float()) - float((caps_plain2["money"] as AmountCompat).to_float()) - 2000.0) < 0.001, "body_strengthening_1 money cap +2000")
		"building_mastery_1":
			check(CommandProcessor.level_cap(content.buildings["wooden_house"], content, s.state) == 20, "mastery wooden_house cap 20")
			check(CommandProcessor.level_cap(content.buildings["forest_farm"], content, s.state) == 20, "mastery forest_farm cap 20")
			check(CommandProcessor.level_cap(content.buildings["stone_mine"], content, s.state) == 20, "mastery stone_mine cap 20")
			check(CommandProcessor.level_cap(content.buildings["herb_farm"], content, s.state) == 20, "mastery herb_farm cap 20")
			check(CommandProcessor.level_cap(content.buildings["storage_lingli"], content, s.state) == 10, "mastery excludes storage_lingli")
			check(CommandProcessor.level_cap(content.buildings["foundation_reservoir"], content, s.state) == 3, "mastery excludes foundation_reservoir")
			check(CommandProcessor.level_cap(content.buildings["hut"], content, s.state) == 2, "mastery excludes hut")

func run_golden_session() -> void:
	var s := branch(era3_state)
	wait_clean(s)
	check(s.state.era_id == 3, "golden session starts Era3 earned")
	var cap_no_bonus := view_cap(s, "skill_point")
	check(absf(cap_no_bonus - 6200.0) < 0.01, "reachable cap without storage bonus 6200")
	check(String(skill_item(s, "golden_core_formation").get("reason", "")) == "SKILL_PREREQ_LOCKED", "prereq-locked view reason at Era3")
	reject_learn(s, "golden_core_formation", "SKILL_PREREQ_LOCKED")
	var before_foundation := points(s)
	check(bool(send(s, "learn_skill", {"skill_id": "foundation_building"}).get("ok", false)) and int(s.state.skills.get("foundation_building", 0)) == 1, "earned foundation_building Lv1 prerequisite")
	check(absf(before_foundation - points(s) - 3600.0) < 0.001, "foundation Lv1 exact deduction 3600")
	check(String(skill_item(s, "golden_core_formation").get("reason", "")) == "INSUFFICIENT_SKILL_POINT", "golden point-shortage reason")
	var stuck_wait := accumulate_to(s, 7650.0, 10.0)
	check(points(s) == 6200.0 and absf(view_cap(s, "skill_point") - 6200.0) < 0.01, "points stuck at 6200 without storage bonus")
	reject_learn(s, "golden_core_formation", "INSUFFICIENT_SKILL_POINT")
	var gap := 7650.0 - cap_no_bonus
	golden_report = {
		"cap_without_storage_bonus": cap_no_bonus,
		"gap_7650_over_6200": gap,
		"stuck_wait_seconds": stuck_wait,
		"official_reachable": false,
	}
	notes.append("finding: golden cost 7650 exceeds base scripture cap 6200 by %.0f; natural accumulation stuck at 6200 after %.0f simulated seconds" % [gap, stuck_wait])
	var joined := send(s, "join_sect", {})
	check(bool(joined.get("ok", false)) and bool(s.state.sect.get("unlocked", false)), "official join_sect at Era3")
	s.state.sect["contribution"] = "1000"
	var wood_entry: Dictionary = s.state.resources["wood"]
	wood_entry["value"] = AmountCompat.from_number(950.0)
	wood_entry["unlocked"] = true
	notes.append("fixture-driven: sect contribution 1000 and wood 950 (exact talisman Lv1-3 cost) injected after official join_sect; expedition task RNG is not deterministic, technique purchases use official learn_sect_technique")
	for level in range(1, 4):
		var tech := send(s, "learn_sect_technique", {"technique_id": "storage_talisman"})
		check(bool(tech.get("ok", false)) and int((s.state.sect["techniques"] as Dictionary).get("storage_talisman", 0)) == level, "official storage_talisman Lv%d" % level)
	var sect_bonus := float(SectSystem.compute_multipliers(s.state).storage_bonus)
	check(is_equal_approx(sect_bonus, 0.3), "sect storage bonus 0.3 at talisman Lv3")
	var cap_with_bonus := view_cap(s, "skill_point")
	check(absf(cap_with_bonus - 8060.0) < 0.01, "measured reachable cap 6200 x 1.3 equals 8060")
	var wait_to_golden := accumulate_to(s, 7650.0, 10.0)
	check(points(s) >= 7650.0, "natural accumulation clears 7650 with raised cap")
	var before_golden := points(s)
	var req_before := float(s.get_view().next_level_required_seconds)
	var learn_golden := send(s, "learn_skill", {"skill_id": "golden_core_formation"})
	check(bool(learn_golden.get("ok", false)) and int(s.state.skills.get("golden_core_formation", 0)) == 1, "officially learned golden_core_formation Lv1")
	check(absf(before_golden - points(s) - 7650.0) < 0.01, "golden Lv1 exact deduction 7650")
	check(is_equal_approx(SkillSystem.effect(content, s.state.skills, "time_multiplier"), 0.9), "golden Lv1 time multiplier pow 0.9")
	var req_after := float(s.get_view().next_level_required_seconds)
	check(is_equal_approx(req_after, req_before * 0.9), "view training requirement scales by 0.9")
	golden_report["official_reachable"] = true
	golden_report["cap_with_talisman3"] = cap_with_bonus
	golden_report["acquisition_wait_seconds_after_bonus"] = wait_to_golden
	golden_report["prerequisite"] = "foundation_building >= 1, Era3"
	var def: Dictionary = content.skill_defs["golden_core_formation"]
	table.append({
		"skill": "golden_core_formation",
		"era": 3,
		"cost": float(def.cost),
		"max_level": int(def.max_level),
		"point_rate_per_s": 2.0,
		"cap_context": "6200 without bonus (insufficient) / 8060 with sect storage_talisman Lv3",
		"acquisition_seconds_derived": 7650.0 / 2.0,
		"session_wait_seconds_simulated": wait_to_golden,
		"prerequisite": "foundation_building:1",
		"effect_at_Lv1": "time_multiplier 0.9",
		"mode": "official learn with fixture sect contribution/wood setup only",
	})
	var era3_def: Dictionary = content.era(3)
	var base_req := Cultivation.next_level_required_seconds(era3_def, 10, 0.0, 1.0)
	var reduction_rows: Array = []
	var cumulative := 0.0
	for level in range(1, 6):
		var saved := base_req * (1.0 - pow(0.9, float(level)))
		cumulative += saved
		reduction_rows.append({"level": level, "required_seconds": base_req * pow(0.9, float(level)), "saved_seconds": saved})
	golden_report["era3_lv10_base_seconds"] = base_req
	golden_report["era3_lv10_reductions"] = reduction_rows
	golden_report["era3_lv10_total_saved_Lv1_to_Lv5"] = cumulative
	notes.append("derived formula: Era3 Lv10 base training %.3f s = 240 x 1.22^9; golden LvN multiplies by pow(0.9,N); cumulative saved over N=1..5 is %.3f simulated seconds" % [base_req, cumulative])
	golden_saved_state = s.state.duplicate_state()

func run_persistence_session() -> void:
	var s := branch(golden_saved_state)
	var encoded := SaveCodec.encode(s.state, content.content_version, SAVE_META)
	check(bool(encoded.get("ok", false)), "golden state encodes")
	if not bool(encoded.get("ok", false)):
		return
	var decoded := SaveCodec.decode(String(encoded.json))
	check(bool(decoded.get("ok", false)), "golden save decodes")
	if not bool(decoded.get("ok", false)):
		return
	var restored: GameState = decoded.state
	check(restored.skill_version == 4 and restored.skills == s.state.skills, "roundtrip preserves skills and version")
	check(int(restored.skills.get("golden_core_formation", 0)) == 1 and int(restored.skills.get("foundation_building", 0)) == 1, "roundtrip golden and foundation levels")
	check(restored.resources["skill_point"]["value"].serialize() == s.state.resources["skill_point"]["value"].serialize(), "roundtrip skill_point")
	check(int(restored.buildings.get("library", 0)) == 1 and int(restored.buildings.get("scripture_hall", 0)) == 1, "roundtrip study buildings")
	var tamper := branch(golden_saved_state)
	tamper.state.skills["rogue_skill"] = 1
	check(not bool(SaveCodec.encode(tamper.state, content.content_version, SAVE_META).get("ok", false)), "encode rejects unknown skill")
	var raw: Dictionary = JSON.parse_string(String(encoded.json))
	raw["state"]["skills"]["mystery_skill"] = 1
	raw.erase("checksum")
	raw["checksum"] = SaveCodec.compute_checksum(raw)
	var rejected := SaveCodec.decode(JSON.stringify(raw))
	check(not bool(rejected.get("ok", false)) and rejected.state == null, "decode rejects unknown skill id")
	var memory := Memory.new()
	SaveManager.configure(content, memory)
	check(bool(SaveManager.save(s.state, SAVE_META).get("ok", false)), "manager save baseline")
	memory.refuse = true
	check(not bool(SaveManager.save(s.state, SAVE_META).get("ok", false)), "manager write refusal surfaced")
	memory.refuse = false
	check(bool(SaveManager.save(s.state, SAVE_META).get("ok", false)), "manager retry succeeds")
	SaveManager.configure(content, memory)
	var loaded_state: GameState = SaveManager.current_state()
	check(loaded_state != null and loaded_state.skills.has("golden_core_formation") and int(loaded_state.skills.get("golden_core_formation", 0)) == 1, "isolated reload preserves golden level")
	check(loaded_state != null and loaded_state.resources.has("skill_point") and loaded_state.resources["skill_point"]["value"].serialize() == s.state.resources["skill_point"]["value"].serialize(), "isolated reload preserves skill_point")
	SaveManager.reset_for_tests()

func run_reincarnation_session() -> void:
	var s := branch(era2_fresh)
	wait_clean(s)
	var learn := send(s, "learn_skill", {"skill_id": "basic_meditation"})
	check(bool(learn.get("ok", false)) and int(s.state.skills.get("basic_meditation", 0)) == 1, "rebirth session earns basic_meditation Lv1 from bank 200")
	check(points(s) == 110.0, "rebirth session holds 110 skill points")
	s.state.buildings["rebirth_lotus"] = 1
	notes.append("fixture-driven: rebirth_lotus eligibility flag (no live content entry); reincarnate itself is the official command, matching SKS-P1 precedent")
	var rr := send(s, "reincarnate", {"mode": "normal"})
	check(bool(rr.get("ok", false)), "official reincarnate accepted")
	if not bool(rr.get("ok", false)):
		return
	check(s.state.skills.is_empty(), "reincarnation clears skills")
	check(points(s) == 0.0, "reincarnation zeroes skill points")
	check(not bool(s.state.resources.skill_point.unlocked), "skill_point relocked")
	check(not bool(s.state.resources.skill_point.ever_obtained), "skill_point ever_obtained reset")
	check(int(s.state.buildings.get("library", 0)) == 0 and int(s.state.buildings.get("scripture_hall", 0)) == 0, "study buildings cleared")
	check(s.state.era_id == 1 and s.state.level == 1 and s.state.reincarnation_count == 1, "new life starts Era1 Lv1 counted")
	var events: Array = rr.events
	var event: Dictionary = events[0] if not events.is_empty() else {}
	check(String(event.get("gained_dao_heart", "")) == "15", "Era2 dao heart floor 15")
	var talent := send(s, "learn_talent", {"talent_id": "innate_dao_body"})
	check(bool(talent.get("ok", false)) and int(s.state.talents.get("innate_dao_body", 0)) == 1, "talent learned after rebirth")
	check(points(s) == 0.0 and not bool(s.state.resources.skill_point.unlocked) and s.state.skills.is_empty(), "talent grants no skill points")
	s.advance_time(600.0)
	check(points(s) == 0.0, "no point production without library in new life")
	s.state.buildings["rebirth_lotus"] = 1
	var second := send(s, "reincarnate", {"mode": "normal"})
	check(bool(second.get("ok", false)) and int(s.state.talents.get("innate_dao_body", 0)) == 1, "talents persist across second reincarnation")
	check(s.state.skills.is_empty() and points(s) == 0.0 and not bool(s.state.resources.skill_point.unlocked), "skills and points stay cleared")
	var roundtrip := SaveCodec.decode(SaveCodec.encode(s.state, content.content_version, SAVE_META).json)
	var roundtrip_talents_match: bool = bool(roundtrip.get("ok", false)) and roundtrip.state != null and roundtrip.state.talents.size() == s.state.talents.size()
	if roundtrip_talents_match:
		for talent_key in s.state.talents:
			roundtrip_talents_match = roundtrip_talents_match and int(roundtrip.state.talents.get(talent_key, -1)) == int(s.state.talents[talent_key])
	check(roundtrip_talents_match and roundtrip.state.skills.is_empty(), "reborn save roundtrip keeps talents and empty skills")

func run_measurement_formula_rows() -> void:
	for level in range(1, 4):
		var rates: Dictionary = Production.compute_rates(content, {"library": level}, 2.0, {})
		print("MEASURE | library Lv%d point rate %.6f/s at Era2 multiplier (formula 1 x pow(L,1.5) x 2)" % [level, float((rates["skill_point"] as AmountCompat).to_float())])

func print_table() -> void:
	run_measurement_formula_rows()
	print("EARLY-V1-C measurement table (simulated seconds only; official commands unless labelled fixture-driven or derived):")
	for row_variant in table:
		var row: Dictionary = row_variant
		print("MEASURE | %s | era=%d cost=%.0f max=%d rate=2.0/s cap_ctx=%s acq_derived=%.1fs session_wait=%.1fs prereq=%s effect1=%s | %s" % [
			String(row.get("skill", "")), int(row.get("era", 0)), float(row.get("cost", 0.0)), int(row.get("max_level", 0)),
			String(row.get("cap_context", "")), float(row.get("acquisition_seconds_derived", 0.0)), float(row.get("session_wait_seconds_simulated", 0.0)),
			String(row.get("prerequisite", "")), String(row.get("effect_at_Lv1", "")), String(row.get("mode", "")),
		])
	if not golden_report.is_empty():
		print("GOLDEN | reachable=%s cap_no_bonus=%.3f cap_talisman3=%.3f gap_7650_minus_6200=%.3f era3_lv10_total_saved_Lv1_to_Lv5=%.3f s (derived)" % [
			str(bool(golden_report.get("official_reachable", false))),
			float(golden_report.get("cap_without_storage_bonus", 0.0)),
			float(golden_report.get("cap_with_talisman3", 0.0)),
			float(golden_report.get("gap_7650_over_6200", 0.0)),
			float(golden_report.get("era3_lv10_total_saved_Lv1_to_Lv5", 0.0)),
		])
	for note in notes:
		print("NOTE | " + note)

func write_artifact() -> void:
	if OS.has_feature("web"):
		return
	var dir := DirAccess.open("res://docs/verification/artifacts")
	if dir != null and not dir.dir_exists("early-v1-c"):
		dir.make_dir("early-v1-c")
	var file := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	if file == null:
		print("WARN | cannot write " + OUT_JSON)
		return
	var report := {
		"task": "early-v1-c",
		"engine": Engine.get_version_info(),
		"rules_version": SaveCodec.RULES_VERSION,
		"content_version": content.content_version,
		"time_basis": "simulated seconds only",
		"checks": checks,
		"failures": failures,
		"measurement_rows": table,
		"golden_reachability": golden_report,
		"notes": notes,
	}
	file.store_string(JSON.stringify(report, "  ", true))
	file.close()
