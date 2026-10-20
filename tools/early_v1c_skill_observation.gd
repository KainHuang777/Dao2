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
const OUT_JSON := "res://docs/verification/artifacts/early-v1-c/observation.json"
const OUT_MD := "res://docs/verification/artifacts/early-v1-c/observation.md"
const SAVE_META := {"save_id": "early-v1c", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
const HASH_PATHS := [
	"content/skills/era2.json",
	"content/skills/era3.json",
	"content/buildings/study.json",
	"src/simulation/skill_system.gd",
	"src/simulation/production.gd",
	"src/simulation/sect_system.gd",
	"src/simulation/time_advancer.gd",
	"src/persistence/save_codec.gd",
	"src/application/game_session.gd",
	"tests/early_v1c_skills_runner.gd",
	"tools/early_v1c_skill_observation.gd",
]
var content: GameContent
var helper = preload("res://src/verification/res1d2_contract.gd").new()
var failures: Array[String] = []
var checks := 0
var serial := 0
var era2_fresh: GameState
var era3_state: GameState
var record: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func send(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return s.submit({"command_id": "early-v1c-obs-" + str(serial), "type": kind, "expected_revision": s.state.revision, "payload": payload})

func branch(state: GameState) -> GameSession:
	var s := GameSession.new()
	s.content = content
	s.clock = GameClock.create(float(state.total_elapsed_seconds))
	s.state = state.duplicate_state()
	return s

func points(s: GameSession) -> float:
	return float((s.state.resources["skill_point"]["value"] as AmountCompat).to_float())

func view_cap(s: GameSession) -> float:
	var view := s.get_view()
	var res: Dictionary = view["resources"]
	var entry: Dictionary = res["skill_point"]
	var parsed: Dictionary = AmountCompat.try_parse(String(entry["cap"]))
	if not bool(parsed.get("ok", false)):
		return -1.0
	return float((parsed["value"] as AmountCompat).to_float())

func view_rate(s: GameSession) -> float:
	var view := s.get_view()
	var res: Dictionary = view["resources"]
	var entry: Dictionary = res["skill_point"]
	var parsed: Dictionary = AmountCompat.try_parse(String(entry["rate"]))
	if not bool(parsed.get("ok", false)):
		return -1.0
	return float((parsed["value"] as AmountCompat).to_float())

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

func accumulate_to(s: GameSession, target: float, chunk: float) -> float:
	var start := float(s.state.total_elapsed_seconds)
	var guard := 0
	while points(s) < target and guard < 1600:
		guard += 1
		s.advance_time(chunk)
	return float(s.state.total_elapsed_seconds) - start

func level_to(s: GameSession, target: int) -> bool:
	var outer := 0
	while s.state.level < target and outer < 20000:
		outer += 1
		var guard := 0
		while not bool(s.get_view().can_level_up) and guard < 5000:
			guard += 1
			var view := s.get_view()
			if bool(view.training_complete):
				s.advance_time(10.0)
			else:
				var need := maxf(1.0, ceilf(float(view.next_level_required_seconds) - float(view.training_seconds)))
				s.advance_time(need)
		if not bool(send(s, "level_up_cultivation", {}).get("ok", false)):
			return false
	return s.state.level == target

func _run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	content = loaded.content
	helper.content = content
	var attach := IslandProgression.attach(content)
	if not bool(attach.get("ok", false)):
		failures.append("attach failed " + str(attach))
		record["prefix_reached_era3"] = false
		finalize()
		return
	record = {
		"task": "early-v1c skill observation",
		"engine": Engine.get_version_info(),
		"rules_version": SaveCodec.RULES_VERSION,
		"content_version": content.content_version,
		"time_basis": "simulated seconds only; no wall-clock assertions",
		"method": [
			"Official GameSession commands; no direct resource, era, level or training injection on the earned path.",
			"fixture-driven items are labelled: sect contribution/wood setup after official join_sect, rebirth_lotus eligibility flag (no live content entry, SKS-P1 precedent).",
			"library rates are the Production formula 1 x pow(level,1.5) multiplied by the Era2 resource multiplier 2; caps are the Production/SkillSystem formulas measured through get_view.",
		],
	}
	record["library_rates_caps"] = library_rows()
	record["scripture_hall"] = scripture_row()
	record["era2_skills"] = era2_skill_rows()
	record["golden_definition"] = golden_definition_row()
	var prefix_ok := play_prefix()
	record["prefix_reached_era3"] = prefix_ok
	if prefix_ok:
		run_golden_observation()
		run_save_observation()
	else:
		record["golden_reachability"] = {"official_reached": false, "reason": "era3 prefix failed", "base_scripture_cap": 6200.0, "gap_7650_over_6200": 1450.0, "measured_cap_with_talisman_Lv3": 0.0}
	run_reincarnation_observation()
	record["checks"] = checks
	record["failures"] = failures
	finalize()

func library_rows() -> Array:
	var rows: Array = []
	for level in range(1, 4):
		var rates: Dictionary = Production.compute_rates(content, {"library": level}, 2.0, {})
		var caps: Dictionary = Production.compute_caps(content, {"library": level}, 2, 1, {})
		rows.append({
			"library_level": level,
			"point_rate_per_s_era2": float((rates["skill_point"] as AmountCompat).to_float()),
			"skill_point_cap": float((caps["skill_point"] as AmountCompat).to_float()),
			"formula": "rate 1 x pow(level, 1.5) x era multiplier 2; cap base 200",
		})
	return rows

func scripture_row() -> Dictionary:
	var caps: Dictionary = Production.compute_caps(content, {"library": 1, "scripture_hall": 1}, 2, 1, {})
	return {
		"effect": "skill_point_max 6000 flat per level, max_level 1",
		"cap_with_scripture_hall": float((caps["skill_point"] as AmountCompat).to_float()),
		"formula": "base 200 + 6000 = 6200 (no storage bonus)",
	}

func era2_skill_rows() -> Array:
	var rows: Array = []
	var rates3: Dictionary = Production.compute_rates(content, {"library": 3}, 2.0, {})
	var rate3 := float((rates3["skill_point"] as AmountCompat).to_float())
	for id in ERA2_SKILLS:
		var def: Dictionary = content.skill_defs[id]
		var cost := float(def.cost)
		rows.append({
			"skill": id,
			"era": int(def.get("era", 2)),
			"cost": cost,
			"max_level": int(def.max_level),
			"effect": String(def.effect),
			"amount": float(def.amount),
			"acquisition_seconds_at_library_Lv1": cost / 2.0,
			"acquisition_seconds_at_library_Lv3": cost / rate3,
			"cap_context": "6200 with scripture_hall covers every Era2 cost",
		})
	return rows

func golden_definition_row() -> Dictionary:
	var def: Dictionary = content.skill_defs["golden_core_formation"]
	var requires: Dictionary = def.get("requires", {})
	var era3_def: Dictionary = content.era(3)
	var base_req := Cultivation.next_level_required_seconds(era3_def, 10, 0.0, 1.0)
	var reductions: Array = []
	var cumulative := 0.0
	for level in range(1, 6):
		var saved := base_req * (1.0 - pow(0.9, float(level)))
		cumulative += saved
		reductions.append({"level": level, "required_seconds": base_req * pow(0.9, float(level)), "cumulative_saved_seconds": cumulative})
	return {
		"skill": "golden_core_formation",
		"era": int(def.get("era", 3)),
		"cost": float(def.cost),
		"max_level": int(def.max_level),
		"effect": String(def.effect),
		"amount": float(def.amount),
		"prerequisite": String(requires.get("skill_id", "")) + " >= " + str(int(requires.get("level", 1))),
		"acquisition_seconds_at_library_Lv1": float(def.cost) / 2.0,
		"era3_lv10_base_seconds": base_req,
		"era3_lv10_reductions": reductions,
		"note": "reductions are derived from the frozen formula 240 x 1.22^9 x pow(0.9,N); simulated seconds, not wall clock",
	}

func play_prefix() -> bool:
	var s := GameSession.create_new_game(content, 20261018)
	for id in BUILD_ORDER:
		if not helper.build(s, id):
			return false
	if not level_to(s, 10):
		return false
	if not bool(send(s, "breakthrough_era", {}).get("ok", false)):
		return false
	if not bool(send(s, "activate_islands", {}).get("ok", false)):
		return false
	for island in ["wood", "ore"]:
		if not bool(send(s, "open_island", {"island_id": island}).get("ok", false)):
			return false
	for route in IslandEconomy.ROUTES:
		if String(IslandEconomy.ROUTES[route][0]) != "herb":
			if not bool(send(s, "configure_route", {"route_id": route}).get("ok", false)):
				return false
	for pair in [["spirit_timber", "wood"], ["bronze_essence", "ore"]]:
		if not helper.wait_craft(s, String(pair[0]), String(pair[1])):
			return false
	for _batch in range(30):
		if not helper.wait_recipe(s, "liquid"):
			return false
	if not helper.build(s, "library"):
		return false
	wait_clean(s)
	var measured := {
		"view_rate_library_Lv1": view_rate(s),
		"view_cap_library_only": view_cap(s),
	}
	accumulate_to(s, 200.0, 10.0)
	measured["stuck_value_library_only"] = points(s)
	if not helper.build(s, "storage_wood"):
		return false
	if not helper.build(s, "scripture_hall"):
		return false
	measured["view_cap_with_scripture"] = view_cap(s)
	era2_fresh = s.state.duplicate_state()
	if not level_to(s, 10):
		return false
	var bank_wait := accumulate_to(s, 6200.0, 10.0)
	measured["bank_fill_seconds_simulated"] = bank_wait
	measured["bank_value"] = points(s)
	record["measured_era2_points"] = measured
	if not helper.build(s, "foundation_reservoir") or not helper.build(s, "foundation_reservoir"):
		return false
	if not bool(send(s, "breakthrough_era", {}).get("ok", false)):
		return false
	era3_state = s.state.duplicate_state()
	return true

func run_golden_observation() -> void:
	var s := branch(era3_state)
	wait_clean(s)
	var cap_no_bonus := view_cap(s)
	check(absf(cap_no_bonus - 6200.0) < 0.01, "cap without bonus 6200")
	reject_and_record(s, "golden_core_formation")
	var foundation_learn := send(s, "learn_skill", {"skill_id": "foundation_building"})
	check(bool(foundation_learn.get("ok", false)) and int(s.state.skills.get("foundation_building", 0)) == 1, "official foundation_building Lv1")
	var pre_bonus_wait := accumulate_to(s, 7650.0, 10.0)
	check(points(s) == 6200.0, "points stuck at 6200 before storage bonus")
	reject_and_record(s, "golden_core_formation")
	var joined := send(s, "join_sect", {})
	check(bool(joined.get("ok", false)), "official join_sect")
	s.state.sect["contribution"] = "1000"
	var wood_entry: Dictionary = s.state.resources["wood"]
	wood_entry["value"] = AmountCompat.from_number(950.0)
	wood_entry["unlocked"] = true
	var talisman_levels := 0
	for _level in range(3):
		if bool(send(s, "learn_sect_technique", {"technique_id": "storage_talisman"}).get("ok", false)):
			talisman_levels += 1
	var cap_with_bonus := view_cap(s)
	var wait_after := accumulate_to(s, 7650.0, 10.0)
	var reached := false
	var before := points(s)
	var learn := send(s, "learn_skill", {"skill_id": "golden_core_formation"})
	if bool(learn.get("ok", false)) and int(s.state.skills.get("golden_core_formation", 0)) == 1:
		reached = true
	var bonus_needed := 7650.0 / 6200.0 - 1.0
	var min_talisman := ceilf(bonus_needed / 0.1)
	record["golden_reachability"] = {
		"cost": 7650.0,
		"base_scripture_cap": cap_no_bonus,
		"gap_7650_over_6200": 7650.0 - cap_no_bonus,
		"stuck_before_bonus_seconds": pre_bonus_wait,
		"official_reached": reached,
		"talisman_levels_ok": talisman_levels,
		"measured_cap_with_talisman_Lv3": cap_with_bonus,
		"derived_cap_with_talisman_Lv10": 6200.0 * 2.0,
		"derived_min_talisman_level": int(min_talisman),
		"accumulation_wait_after_bonus_seconds": wait_after,
		"points_before_learn": before,
		"points_after_learn": points(s),
		"fixture_labels": [
			"sect contribution and wood injected after official join_sect (expedition task RNG is not deterministic)",
			"storage_talisman purchased through official learn_sect_technique",
		],
	}
	check(reached, "golden officially reachable via storage_talisman path")

func reject_and_record(s: GameSession, id: String) -> void:
	var before: Dictionary = s.state.to_snapshot_dict()
	var result: Dictionary = send(s, "learn_skill", {"skill_id": id})
	check(not bool(result.get("ok", false)) and before == s.state.to_snapshot_dict(), "atomic rejection " + id + " " + String(result.get("error", "")))

func run_save_observation() -> void:
	var s := branch(era3_state)
	wait_clean(s)
	check(bool(send(s, "learn_skill", {"skill_id": "foundation_building"}).get("ok", false)), "save fixture foundation learn")
	var encoded := SaveCodec.encode(s.state, content.content_version, SAVE_META)
	var roundtrip_ok := false
	if bool(encoded.get("ok", false)):
		var decoded := SaveCodec.decode(String(encoded.json))
		roundtrip_ok = bool(decoded.get("ok", false)) and decoded.state != null and decoded.state.skills == s.state.skills and decoded.state.skill_version == 2
	check(roundtrip_ok, "save roundtrip preserves skills")
	var tamper := branch(era3_state)
	tamper.state.skills["rogue_skill"] = 1
	var unknown_rejected := not bool(SaveCodec.encode(tamper.state, content.content_version, SAVE_META).get("ok", false))
	check(unknown_rejected, "unknown skill rejected by codec")
	record["save_reload"] = {"roundtrip_preserves_skills": roundtrip_ok, "unknown_skill_rejected": unknown_rejected}

func run_reincarnation_observation() -> void:
	if era2_fresh == null:
		record["reincarnation_clear"] = {"ok": false, "reason": "no era2 fixture state"}
		return
	var s := branch(era2_fresh)
	wait_clean(s)
	check(bool(send(s, "learn_skill", {"skill_id": "basic_meditation"}).get("ok", false)), "reincarnation fixture learn")
	s.state.buildings["rebirth_lotus"] = 1
	var applied := ReincarnationRules.apply_reincarnation(s.state, content, "normal")
	var cleared := bool(applied.get("ok", false)) and s.state.skills.is_empty() and points(s) == 0.0 and not bool(s.state.resources.skill_point.unlocked) and int(s.state.buildings.get("library", 0)) == 0 and int(s.state.buildings.get("scripture_hall", 0)) == 0
	check(cleared, "reincarnation clears skills points and study buildings")
	record["reincarnation_clear"] = {
		"ok": cleared,
		"skills_cleared": s.state.skills.is_empty(),
		"skill_point_value": points(s),
		"skill_point_unlocked": bool(s.state.resources.skill_point.unlocked),
		"library_level": int(s.state.buildings.get("library", 0)),
		"scripture_hall_level": int(s.state.buildings.get("scripture_hall", 0)),
		"talents_after": s.state.talents.duplicate(true),
		"dao_heart_after": s.state.dao_heart.serialize(),
		"fixture_labels": ["rebirth_lotus eligibility flag has no live content entry (SKS-P1 precedent); apply_reincarnation is the official rule path"],
	}

func finalize() -> void:
	if record.is_empty():
		record = {"task": "early-v1c skill observation", "failures": failures}
	var hashes := {}
	for path in HASH_PATHS:
		var full: String = "res://" + String(path)
		hashes[path] = FileAccess.get_sha256(full) if FileAccess.file_exists(full) else "MISSING"
	record["source_hashes"] = hashes
	record["checks"] = checks
	record["failures"] = failures
	write_artifacts()
	print("EARLY-V1-C OBSERVATION | checks=%d failures=%d golden_reached=%s gap_7650_6200=%.1f" % [checks, failures.size(), str(bool((record.get("golden_reachability", {}) as Dictionary).get("official_reached", false))), float((record.get("golden_reachability", {}) as Dictionary).get("gap_7650_over_6200", 0.0))])
	for failure in failures:
		print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func write_artifacts() -> void:
	var dir := DirAccess.open("res://docs/verification/artifacts")
	if dir != null and not dir.dir_exists("early-v1-c"):
		dir.make_dir("early-v1-c")
	var json_file := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(record, "  ", true))
		json_file.close()
	else:
		failures.append("cannot write " + OUT_JSON)
	var md := render_markdown()
	var md_file := FileAccess.open(OUT_MD, FileAccess.WRITE)
	if md_file != null:
		md_file.store_string(md)
		md_file.close()
	else:
		failures.append("cannot write " + OUT_MD)

func render_markdown() -> String:
	var lines: Array[String] = []
	lines.append("# EARLY-V1-C Skill Observation")
	lines.append("")
	lines.append("Rules: `" + String(record.get("rules_version", "")) + "` | Content: `" + String(record.get("content_version", "")) + "` | Time basis: simulated seconds only")
	lines.append("")
	lines.append("## Method")
	lines.append("")
	for item in record.get("method", []):
		lines.append("- " + String(item))
	lines.append("")
	lines.append("## Library point rates and caps")
	lines.append("")
	lines.append("| library level | rate per s (Era2) | skill_point cap |")
	lines.append("| --- | ---: | ---: |")
	for row in record.get("library_rates_caps", []):
		var r: Dictionary = row
		lines.append("| %d | %.6f | %.0f |" % [int(r.get("library_level", 0)), float(r.get("point_rate_per_s_era2", 0.0)), float(r.get("skill_point_cap", 0.0))])
	var scripture: Dictionary = record.get("scripture_hall", {})
	lines.append("")
	lines.append("Scripture hall cap: **%.0f** (%s)" % [float(scripture.get("cap_with_scripture_hall", 0.0)), String(scripture.get("formula", ""))])
	var measured: Dictionary = record.get("measured_era2_points", {})
	if not measured.is_empty():
		lines.append("")
		lines.append("Measured in the earned Era2 session: view rate %.3f/s, library-only cap %.0f (stuck at %.0f), scripture cap %.0f, bank filled to %.0f in %.0f simulated seconds." % [
			float(measured.get("view_rate_library_Lv1", 0.0)), float(measured.get("view_cap_library_only", 0.0)), float(measured.get("stuck_value_library_only", 0.0)),
			float(measured.get("view_cap_with_scripture", 0.0)), float(measured.get("bank_value", 0.0)), float(measured.get("bank_fill_seconds_simulated", 0.0)),
		])
	lines.append("")
	lines.append("## Era2 skills")
	lines.append("")
	lines.append("| skill | era | cost | max | effect | amount | acq s @Lv1 rate | acq s @Lv3 rate |")
	lines.append("| --- | --- | ---: | --- | --- | ---: | ---: | ---: |")
	for row in record.get("era2_skills", []):
		var r: Dictionary = row
		lines.append("| %s | %d | %.0f | %d | %s | %s | %.1f | %.1f |" % [
			String(r.get("skill", "")), int(r.get("era", 2)), float(r.get("cost", 0.0)), int(r.get("max_level", 0)),
			String(r.get("effect", "")), str(float(r.get("amount", 0.0))), float(r.get("acquisition_seconds_at_library_Lv1", 0.0)), float(r.get("acquisition_seconds_at_library_Lv3", 0.0)),
		])
	lines.append("")
	lines.append("## golden_core_formation")
	lines.append("")
	var golden: Dictionary = record.get("golden_definition", {})
	lines.append("- era %d, cost %.0f, max %d, effect `%s` amount %s, prerequisite %s" % [
		int(golden.get("era", 3)), float(golden.get("cost", 0.0)), int(golden.get("max_level", 0)),
		String(golden.get("effect", "")), str(float(golden.get("amount", 0.0))), String(golden.get("prerequisite", "")),
	])
	lines.append("- acquisition at library Lv1 rate: %.1f simulated seconds" % float(golden.get("acquisition_seconds_at_library_Lv1", 0.0)))
	lines.append("")
	lines.append("### Era3 Lv10 training reductions (derived formula, simulated seconds)")
	lines.append("")
	lines.append("| golden level | required s | cumulative saved s |")
	lines.append("| --- | ---: | ---: |")
	for row in golden.get("era3_lv10_reductions", []):
		var r: Dictionary = row
		lines.append("| %d | %.3f | %.3f |" % [int(r.get("level", 0)), float(r.get("required_seconds", 0.0)), float(r.get("cumulative_saved_seconds", 0.0))])
	lines.append("")
	lines.append("## Golden reachability and the 7650 vs 6200 gap")
	lines.append("")
	var reach: Dictionary = record.get("golden_reachability", {})
	lines.append("- cost 7650 exceeds the base library+scripture cap 6200 by **%.0f points**; without a storage bonus accumulation is provably stuck at %.0f, so golden cannot be learned from the base cap." % [float(reach.get("gap_7650_over_6200", 1450.0)), float(reach.get("base_scripture_cap", 6200.0))])
	lines.append("- official storage path: sect `storage_talisman` adds +10%% of every storage cap per level (max 10); at Lv3 the measured skill_point cap is %.3f (6200 x 1.3), enough for 7650." % float(reach.get("measured_cap_with_talisman_Lv3", 0.0)))
	lines.append("- derived minimum talisman level to fit 7650: %d; derived cap at talisman Lv10: %.0f." % [int(reach.get("derived_min_talisman_level", 3)), float(reach.get("derived_cap_with_talisman_Lv10", 12400.0))])
	lines.append("- official path reached golden: **%s** (fixture-driven setup limited to sect contribution/wood after the official join_sect; purchases and learns are official commands)." % str(bool(reach.get("official_reached", false))))
	lines.append("")
	lines.append("## Save and reload")
	lines.append("")
	var save_res: Dictionary = record.get("save_reload", {})
	lines.append("- roundtrip preserves skills: %s | unknown skill rejected: %s" % [str(bool(save_res.get("roundtrip_preserves_skills", false))), str(bool(save_res.get("unknown_skill_rejected", false)))])
	lines.append("")
	lines.append("## Reincarnation clear")
	lines.append("")
	var reborn: Dictionary = record.get("reincarnation_clear", {})
	lines.append("- cleared: %s | skills empty: %s | skill_point %.1f unlocked=%s | library %d scripture_hall %d | talents after: %s | dao_heart after: %s" % [
		str(bool(reborn.get("ok", false))), str(bool(reborn.get("skills_cleared", false))),
		float(reborn.get("skill_point_value", -1.0)), str(bool(reborn.get("skill_point_unlocked", true))),
		int(reborn.get("library_level", -1)), int(reborn.get("scripture_hall_level", -1)),
		str(reborn.get("talents_after", {})), String(reborn.get("dao_heart_after", "")),
	])
	lines.append("")
	lines.append("## Checks")
	lines.append("")
	lines.append("- checks: %d" % checks)
	lines.append("- failures: %s" % str(failures))
	lines.append("")
	lines.append("## Source hashes")
	lines.append("")
	lines.append("| Path | SHA-256 |")
	lines.append("| --- | --- |")
	for path in record.get("source_hashes", {}):
		lines.append("| `" + String(path) + "` | `" + String((record.get("source_hashes", {}) as Dictionary)[path]) + "` |")
	lines.append("")
	return "\n".join(lines)
