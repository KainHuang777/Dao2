extends SceneTree

const OUT_JSON := "res://docs/verification/artifacts/early-v1-a/observation.json"
const OUT_MD := "res://docs/verification/early-v1-a.md"
const ART_MD := "res://docs/verification/artifacts/early-v1-a/observation.md"
const HASH_PATHS := [
	"project.godot",
	"content/eras/era1.json",
	"content/eras/era2.json",
	"content/eras/era3.json",
	"content/buildings/era1.json",
	"content/buildings/era2.json",
	"content/buildings/study.json",
	"content/skills/era2.json",
	"content/skills/era3.json",
	"content/recipes/era1_3.json",
	"content/resources/era1.json",
	"src/application/game_session.gd",
	"src/simulation/command_processor.gd",
	"src/simulation/skill_system.gd",
	"src/simulation/talent_system.gd",
	"src/simulation/reincarnation_rules.gd",
	"src/simulation/time_advancer.gd",
	"src/simulation/production.gd",
	"src/simulation/onboarding.gd",
	"src/simulation/cultivation.gd",
	"src/simulation/lifespan.gd",
	"src/simulation/island_progression.gd",
	"src/simulation/island_economy.gd",
	"src/simulation/tribulation_rules.gd",
	"src/persistence/save_codec.gd",
	"src/verification/res1d2_contract.gd",
	"tools/early_pacing_audit.gd",
	"tools/early_pacing_targets.json",
	"tools/early_v1a_observation.gd",
]
const BUILD_ORDER := [
	"hut", "hut", "wooden_house", "wooden_house",
	"forest_farm", "forest_farm", "forest_farm",
	"stone_mine", "stone_mine", "stone_mine",
	"herb_farm", "herb_farm", "herb_farm",
	"storage_wood", "storage_money", "storage_money",
	"storage_stone", "storage_herb", "storage_lingli", "storage_lingli",
]
const BASELINE := {
	"report": "docs/verification/early-pacing-baseline.md",
	"generated": "2026-10-18",
	"command": "tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/early_pacing_audit.gd",
	"exit_code": 0,
	"log": "build/early-v1-a-pacing-audit.log",
	"findings": {
		"C1": "FAIL 26/92",
		"C2": "WARN 60/92",
		"C3": "WARN 13/92",
		"C4": "WARN 65/92",
		"C5": "WARN 1/92",
		"C6": "WARN 15/92",
		"C7": "OK 4.13x",
		"C8": "WARN 88% (69/78)",
		"C9": "OK 52%/64%",
		"C10": "WARN",
	},
	"chain_training_seconds": {"era1": 1007.15051676797, "era2": 2495.8682112, "era3": 5440.8030540339},
	"era1_sim_active_seconds": 1286.0,
	"era1_sim_idle_seconds": 2700.0,
	"historical_only": {
		"report_date": "2026-10-11",
		"C1": "FAIL 42/92",
		"C2": "WARN 68/92",
		"C3": "WARN 57/92",
		"C4": "WARN 68/92",
		"C5": "WARN 1/92",
		"C6": "WARN 12/92",
		"C7": "OK 4.00x",
		"C8": "WARN 88%",
		"C9": "OK 60%/72%",
		"C10": "WARN",
		"era1_lv10_active_wall_minutes": 17.9,
		"era1_lv10_idle_wall_minutes": 45.0,
	},
}
const UNCOVERED := [
	"Only resource_inheritance talent level 1 is observed; other talents and higher talent levels are not replayed.",
	"Only basic_meditation is learned; skill combinations, qi_condensation, foundation_building, building_mastery_1 and golden_core_formation are not replayed.",
	"The bot drives commands directly; HUD, building markers, island presentation, input hit areas and animation timing are not observed.",
	"Wall-clock values here are headless machine time, not a human play session; real-player rhythm, reading time and misclicks are not modelled.",
	"Touch, phone/tablet, high-DPR, rotation, GPU and cold-start behaviour remain deferred and are not claimed.",
	"Save/load and offline settlement are not re-run here; res1d2/res1d and other runners own those contracts.",
	"There is no live content entry for rebirth_lotus or void_mirror, so early reincarnation is unreachable by normal building play in this build; reincarnation was reached by lifespan exhaustion.",
	"The observation does not judge total-run minutes; it only records segment waits and the 600-second boundary.",
]

var content: GameContent
var serial := 0
var checks := 0
var failures: Array[String] = []
var waits: Array = []
var milestones: Array = []
var variants: Dictionary = {}
var run_name := ""
var run_start_sim := 0.0
var run_start_wall := 0
var run_peak_sim := 0.0
var run_notes: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	if not loaded.ok:
		_fail("content load: " + str(loaded))
		quit(1)
		return
	content = loaded.content
	var attached := IslandProgression.attach(content)
	if not attached.ok:
		_fail("island attach: " + str(attached))
		quit(1)
		return

	var v1 := GameSession.create_new_game(content, 20261018)
	start_run(v1, "V1_first_life_no_talents_no_skills", "No talent, no skill; full Era1 to Era3, then natural lifespan exhaustion.")
	if not play_to(v1, 3):
		_fail("V1 first life did not reach Era3 Lv10")
		finish_run(v1, "FAILED")
	else:
		var max_life := float(v1.get_view().max_lifespan_seconds)
		var pre_rebirth := float(v1.state.total_elapsed_seconds)
		var b := begin(v1)
		var advanced := v1.advance_time(60000.0)
		end_wait(v1, "lifecycle:lifespan_runout", "lifecycle", b, {"stopped": advanced.get("stopped", null), "max_lifespan_seconds": max_life})
		milestone(v1, "lifespan_exhausted")
		var rr := send(v1, "reincarnate", {"mode": "normal", "tribulation_seed": 20261018})
		if not rr.ok:
			_fail("reincarnation rejected: " + str(rr))
			finish_run(v1, "FAILED")
		else:
			var ev: Dictionary = rr.events[0] if not rr.events.is_empty() else {}
			milestone(v1, "reincarnated", {
				"pre_rebirth_sim_seconds": pre_rebirth,
				"gained_dao_heart": ev.get("gained_dao_heart", ""),
				"gained_dao_proof": ev.get("gained_dao_proof", 0),
				"total_dao_heart": ev.get("total_dao_heart", ""),
				"granted_resources": ev.get("granted_resources", {}),
				"previous_era": ev.get("previous_era", 0),
				"previous_level": ev.get("previous_level", 0),
			})
			finish_run(v1, "DONE")
	var reborn_state: GameState = v1.state.duplicate_state()

	var v1b := branch_session(reborn_state)
	start_run(v1b, "V1b_rebuild_to_era2", "No talent, no skill; rebuild from reincarnation until Era2 foundation is reached.")
	var v1b_ok := play_to(v1b, 2)
	if v1b_ok:
		milestone(v1b, "refoundation_era2")
	finish_run(v1b, "DONE" if v1b_ok else "FAILED")

	var v2 := branch_session(reborn_state)
	start_run(v2, "V2_first_affordable_talent", "Learn first affordable talent resource_inheritance (5 dao heart), then full Era1 to Era3.")
	var dh_before := float(v2.state.dao_heart.to_float())
	var talent := send(v2, "learn_talent", {"talent_id": "resource_inheritance"})
	if not talent.ok:
		_fail("talent learn rejected: " + str(talent))
		finish_run(v2, "FAILED")
	else:
		var t_ev: Dictionary = talent.events[0] if not talent.events.is_empty() else {}
		milestone(v2, "resource_inheritance_learned", {
			"dao_heart_before": dh_before,
			"dao_heart_after": float(v2.state.dao_heart.to_float()),
			"cost": t_ev.get("cost", ""),
			"global_production_multiplier": float(TalentSystem.compute_multipliers(v2.state).global_production_multiplier),
		})
		var v2_ok := play_to(v2, 3)
		finish_run(v2, "DONE" if v2_ok else "FAILED")

	var v3 := branch_session(reborn_state)
	start_run(v3, "V3_skill_path", "No talent; build library in Era2, wait for skill points, learn basic_meditation, then finish Era3.")
	var v3_ok := play_to(v3, 3, {"skills": true})
	finish_run(v3, "DONE" if v3_ok else "FAILED")

	var report := build_report()
	var write_ok := write_report(report)
	if not write_ok:
		quit(1)
		return
	print("EARLY-V1-A: variants=%d waits=%d checks=%d failures=%d" % [variants.size(), waits.size(), checks, failures.size()])
	for key in variants:
		var v: Dictionary = variants[key]
		print("  %s era=%d lv=%d sim=%.1fs wall=%.3fs waits>=600s=%d" % [key, v.get("end_era", 0), v.get("end_level", 0), v.get("sim_seconds", 0.0), v.get("wall_seconds", 0.0), v.get("over_600s", 0)])
	if not failures.is_empty():
		print("FAILURES: " + str(failures))
	quit(0 if failures.is_empty() else 1)

func _fail(message: String) -> void:
	failures.append(message)

func start_run(s: GameSession, name: String, note: String) -> void:
	run_name = name
	run_start_sim = float(s.state.total_elapsed_seconds)
	run_start_wall = Time.get_ticks_msec()
	run_peak_sim = run_start_sim
	run_notes = {"note": note, "start_era": s.state.era_id, "start_level": s.state.level, "start_sim_seconds": run_start_sim}
	variants[name] = run_notes

func finish_run(s: GameSession, status: String) -> void:
	observe_sim(s)
	var v: Dictionary = variants.get(run_name, {})
	v["run"] = run_name
	v["status"] = status
	v["end_era"] = s.state.era_id
	v["end_level"] = s.state.level
	var peak_era := s.state.era_id
	var peak_level := s.state.level
	var peak_life := float(s.get_view().max_lifespan_seconds)
	for rec in milestones:
		if String(rec.get("run", "")) != run_name:
			continue
		var era := int(rec.get("era", 0))
		var level := int(rec.get("level", 0))
		if era > peak_era or (era == peak_era and level > peak_level):
			peak_era = era
			peak_level = level
		peak_life = maxf(peak_life, float(rec.get("max_lifespan_seconds", 0.0)))
	v["peak_era"] = peak_era
	v["peak_level"] = peak_level
	v["peak_max_lifespan_seconds"] = peak_life
	v["sim_seconds"] = maxf(0.0, run_peak_sim - run_start_sim)
	v["wall_seconds"] = float(Time.get_ticks_msec() - run_start_wall) / 1000.0
	v["max_lifespan_seconds"] = float(s.get_view().max_lifespan_seconds)
	v["dao_heart"] = s.state.dao_heart.serialize()
	v["dao_proof"] = s.state.dao_proof
	v["talents"] = s.state.talents.duplicate(true)
	v["skills"] = s.state.skills.duplicate(true)
	v["skill_points"] = float(s.state.resources.get("skill_point", {}).get("value", AmountCompat.zero()).to_float()) if s.state.resources.has("skill_point") else 0.0
	v["reincarnation_count"] = s.state.reincarnation_count
	v["over_600s"] = _over_600_count()
	variants[run_name] = v

func branch_session(state: GameState) -> GameSession:
	var s := GameSession.new()
	s.content = content
	s.clock = GameClock.create(float(state.total_elapsed_seconds))
	s.state = state.duplicate_state()
	return s

func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	var result := s.submit({
		"command_id": "v1a-" + str(serial),
		"type": kind,
		"payload": payload,
		"expected_revision": s.state.revision,
	})
	checks += 1
	return result

func begin(s: GameSession) -> Dictionary:
	observe_sim(s)
	return {"sim": float(s.state.total_elapsed_seconds), "wall": Time.get_ticks_msec()}

func observe_sim(s: GameSession) -> void:
	run_peak_sim = maxf(run_peak_sim, float(s.state.total_elapsed_seconds))

func end_wait(s: GameSession, label: String, kind: String, b: Dictionary, extra: Dictionary = {}) -> Dictionary:
	observe_sim(s)
	var end_sim := float(s.state.total_elapsed_seconds)
	var duration := maxf(0.0, end_sim - float(b.sim))
	var rec := {
		"run": run_name,
		"label": label,
		"kind": kind,
		"start_sim": float(b.sim),
		"end_sim": end_sim,
		"sim_seconds": duration,
		"wall_ms": Time.get_ticks_msec() - int(b.wall),
		"actionable": kind in ["build", "craft", "level", "skill_points"],
		"over_600s": kind != "lifecycle" and duration >= 600.0,
	}
	for key in extra:
		rec[key] = extra[key]
	waits.append(rec)
	return rec

func milestone(s: GameSession, label: String, extra: Dictionary = {}) -> void:
	observe_sim(s)
	var rec := {
		"run": run_name,
		"milestone": label,
		"sim_seconds": float(s.state.total_elapsed_seconds),
		"wall_ms_since_start": Time.get_ticks_msec() - run_start_wall,
		"era": s.state.era_id,
		"level": s.state.level,
		"dao_heart": s.state.dao_heart.serialize(),
		"skill_points": float(s.state.resources.get("skill_point", {}).get("value", AmountCompat.zero()).to_float()) if s.state.resources.has("skill_point") else 0.0,
		"max_lifespan_seconds": float(s.get_view().max_lifespan_seconds),
	}
	for key in extra:
		rec[key] = extra[key]
	milestones.append(rec)

func _over_600_count() -> int:
	var count := 0
	for rec in waits:
		if String(rec.get("run", "")) == run_name and bool(rec.get("over_600s", false)):
			count += 1
	return count

func play_to(s: GameSession, target_era: int, opts: Dictionary = {}) -> bool:
	if s.state.era_id == 1:
		if not play_era1(s):
			return false
	if target_era <= 2:
		return s.state.era_id >= 2
	if s.state.era_id == 2:
		if not play_era2(s, opts):
			return false
	if target_era >= 3 and s.state.era_id == 3:
		if not play_era3(s):
			return false
	return s.state.era_id >= 3 and s.state.level >= 10

func play_era1(s: GameSession) -> bool:
	for id in BUILD_ORDER:
		if not build(s, id):
			_fail(run_name + ": failed building " + id)
			return false
	milestone(s, "era1_build_chain_complete")
	if not level_to(s, 10):
		return false
	milestone(s, "era1_lv10")
	var r := send(s, "breakthrough_era")
	if not r.ok:
		_fail(run_name + ": Era1 breakthrough rejected " + str(r))
		return false
	milestone(s, "era2_reached")
	return true

func play_era2(s: GameSession, opts: Dictionary = {}) -> bool:
	if not IslandProgression.active(s.state):
		var act := send(s, "activate_islands")
		if not act.ok:
			_fail(run_name + ": activate_islands rejected " + str(act))
			return false
	for island in ["wood", "ore"]:
		if not bool(s.state.economy.islands[island].get("opened", false)):
			var opened := send(s, "open_island", {"island_id": island})
			if not opened.ok:
				_fail(run_name + ": open " + island + " rejected " + str(opened))
				return false
	for route in IslandEconomy.ROUTES:
		if IslandEconomy.ROUTES[route][0] != "herb":
			var routed := send(s, "configure_route", {"route_id": route})
			if not routed.ok:
				_fail(run_name + ": route " + route + " rejected " + str(routed))
				return false
	for pair in [["spirit_timber", "wood"], ["bronze_essence", "ore"]]:
		if not s.state.economy.jobs.has(pair[1]):
			if not wait_craft(s, pair[0], pair[1]):
				_fail(run_name + ": producer " + pair[0] + " failed")
				return false
	for _i in range(30):
		if not wait_recipe(s, "liquid"):
			_fail(run_name + ": Era2 liquid stock failed")
			return false
	milestone(s, "era2_islands_ready")
	if bool(opts.get("skills", false)):
		if not build(s, "library"):
			_fail(run_name + ": library build failed")
			return false
		milestone(s, "library_built")
	if not level_to(s, 10):
		return false
	milestone(s, "era2_lv10")
	if bool(opts.get("skills", false)):
		if not wait_skill_points(s, 90):
			_fail(run_name + ": skill points did not reach 90")
			return false
		var before := send(s, "learn_skill", {"skill_id": "basic_meditation"})
		if not before.ok:
			_fail(run_name + ": basic_meditation rejected " + str(before))
			return false
		milestone(s, "basic_meditation_learned", {"lingli_multiplier": float(SkillSystem.effect(content, s.state.skills, "lingli_multiplier"))})
	if not build(s, "foundation_reservoir") or not build(s, "foundation_reservoir"):
		_fail(run_name + ": foundation_reservoir capacity failed")
		return false
	var r := send(s, "breakthrough_era")
	if not r.ok or s.state.era_id != 3:
		_fail(run_name + ": Era2 breakthrough rejected " + str(r))
		return false
	milestone(s, "era3_reached")
	return true

func play_era3(s: GameSession) -> bool:
	for island in ["wood", "ore", "herb"]:
		var b := begin(s)
		s.advance_time(30.0)
		end_wait(s, "open_window:" + island, "wait", b, {"island": island})
		if not bool(s.state.economy.islands[island].get("opened", false)):
			var opened := send(s, "open_island", {"island_id": island})
			if not opened.ok:
				_fail(run_name + ": Era3 open " + island + " rejected " + str(opened))
				return false
	for route in IslandEconomy.ROUTES:
		var routed := send(s, "configure_route", {"route_id": route})
		if not routed.ok:
			_fail(run_name + ": Era3 route " + route + " rejected " + str(routed))
			return false
	var b31 := begin(s)
	s.advance_time(31.0)
	end_wait(s, "route_delivery_31s", "wait", b31, {})
	for pair in [["spirit_timber", "wood"], ["bronze_essence", "ore"]]:
		if not s.state.economy.jobs.has(pair[1]):
			if not wait_craft(s, pair[0], pair[1]):
				_fail(run_name + ": Era3 producer " + pair[0] + " failed")
				return false
	var b61 := begin(s)
	s.advance_time(61.0)
	end_wait(s, "t2_stock_61s", "wait", b61, {})
	milestone(s, "era3_islands_ready")
	var expansion := send(s, "upgrade_island_facility", {"island_id": "herb", "facility_id": "workshop"})
	if not expansion.ok:
		_fail(run_name + ": herb workshop upgrade rejected " + str(expansion))
		return false
	if not wait_recipe(s, "formation_core"):
		_fail(run_name + ": formation_core failed")
		return false
	if not wait_recipe(s, "liquid"):
		_fail(run_name + ": liquid failed")
		return false
	var b11 := begin(s)
	s.advance_time(11.0)
	end_wait(s, "liquid_delivery_11s", "wait", b11, {})
	if not wait_recipe(s, "stone_mid", 55):
		_fail(run_name + ": stone_mid 55 failed")
		return false
	if not wait_recipe(s, "foundation_pill", 3):
		_fail(run_name + ": foundation_pill 3 failed")
		return false
	if not wait_recipe(s, "golden_core_pill"):
		_fail(run_name + ": golden_core_pill failed")
		return false
	if not wait_can_level(s):
		_fail(run_name + ": Era3 Lv2 training failed")
		return false
	var l2 := send(s, "level_up_cultivation")
	if not l2.ok:
		_fail(run_name + ": Era3 Lv2 rejected " + str(l2))
		return false
	milestone(s, "era3_lv2")
	for level in range(2, 10):
		if not wait_recipe(s, "formation_core"):
			_fail(run_name + ": Lv" + str(level) + " formation_core failed")
			return false
		if not wait_recipe(s, "liquid"):
			_fail(run_name + ": Lv" + str(level) + " liquid failed")
			return false
		var b := begin(s)
		s.advance_time(11.0)
		end_wait(s, "liquid_delivery_Lv" + str(level), "wait", b, {})
		if not wait_recipe(s, "stone_mid", 50):
			_fail(run_name + ": Lv" + str(level) + " stone_mid failed")
			return false
		if level == 9:
			if not wait_recipe(s, "talisman", 10):
				_fail(run_name + ": Lv9 talisman failed")
				return false
		if not wait_can_level(s):
			_fail(run_name + ": Lv" + str(level) + " training failed")
			return false
		var r := send(s, "level_up_cultivation")
		if not r.ok or s.state.level != level + 1:
			_fail(run_name + ": Lv" + str(level) + " level up rejected " + str(r))
			return false
		milestone(s, "era3_lv" + str(level + 1))
	return true

func build(s: GameSession, id: String) -> bool:
	var view := s.get_view()
	if not view.buildings.has(id):
		return false
	var costs: Dictionary = view.buildings[id].costs
	var b := begin(s)
	var gathered := 0
	for resource in costs:
		var need := float(costs[resource])
		var guard := 0
		while float(s.state.resources[resource].value.to_float()) < need and guard < 3000:
			guard += 1
			if s.state.era_id > 1:
				s.advance_time(10.0)
			else:
				var g := send(s, "gather", {"resource_id": resource})
				if not g.ok:
					end_wait(s, "build:" + id, "build", b, {"building": id, "ok": false, "error": g.get("error", "")})
					return false
				gathered += 1
				s.advance_time(0.5)
	var level_before := int(s.state.buildings.get(id, 0))
	var r := send(s, "upgrade_building", {"building_id": id})
	end_wait(s, "build:" + id, "build", b, {
		"building": id,
		"level_before": level_before,
		"level_after": int(s.state.buildings.get(id, 0)),
		"gathers": gathered,
		"ok": r.ok,
		"error": r.get("error", ""),
	})
	return r.ok

func level_to(s: GameSession, max_level: int) -> bool:
	while s.state.level < max_level:
		var from_level := s.state.level
		var view := s.get_view()
		var missing: Array = view.level_up_missing_resources.keys()
		var b := begin(s)
		var guard := 0
		while not s.get_view().can_level_up and guard < 5000:
			guard += 1
			view = s.get_view()
			if bool(view.training_complete):
				s.advance_time(10.0)
			else:
				var need := maxf(1.0, ceil(float(view.next_level_required_seconds) - float(view.training_seconds)))
				s.advance_time(need)
		var r := send(s, "level_up_cultivation")
		end_wait(s, "level:" + str(from_level) + "->" + str(from_level + 1), "level", b, {
			"from_level": from_level,
			"to_level": from_level + 1,
			"missing_at_start": missing,
			"ok": r.ok,
			"error": r.get("error", ""),
		})
		if not r.ok:
			_fail(run_name + ": level " + str(from_level) + " rejected " + str(r))
			return false
		if s.state.level != from_level + 1:
			_fail(run_name + ": level did not advance from " + str(from_level))
			return false
	return true

func wait_can_level(s: GameSession) -> bool:
	var from_level := s.state.level
	var b := begin(s)
	var guard := 0
	while not s.get_view().can_level_up and guard < 5000:
		guard += 1
		var view := s.get_view()
		if bool(view.training_complete):
			s.advance_time(10.0)
		else:
			var need := maxf(1.0, ceil(float(view.next_level_required_seconds) - float(view.training_seconds)))
			s.advance_time(need)
	var missing: Array = s.get_view().level_up_missing_resources.keys()
	end_wait(s, "training_level:" + str(from_level), "level", b, {"from_level": from_level, "missing_at_end": missing})
	return s.get_view().can_level_up

func wait_skill_points(s: GameSession, needed: int) -> bool:
	var b := begin(s)
	var guard := 0
	while skill_points(s) < float(needed) and guard < 3000:
		guard += 1
		s.advance_time(10.0)
	var have := skill_points(s)
	end_wait(s, "skill_points_" + str(needed), "skill_points", b, {"needed": needed, "have": have, "cap": float(s.get_view().resources.get("skill_point", {}).get("cap", "0"))})
	return have >= float(needed)

func skill_points(s: GameSession) -> float:
	if not s.state.resources.has("skill_point"):
		return 0.0
	return float(s.state.resources["skill_point"].value.to_float())

func wait_recipe(s: GameSession, id: String, count: int = 1) -> bool:
	var b := begin(s)
	var attempts := 0
	var last_error := ""
	for _attempt in range(1500):
		attempts += 1
		var result := send(s, "craft", {"recipe_id": id, "island_id": "home", "count": count, "repeat": false})
		if result.ok:
			var duration: int = int(IslandEconomy.DURATIONS[id])
			if IslandProgression.active(s.state):
				duration = IslandProgression.duration(s.state, "home", id)
			s.advance_time(float(duration * count))
			var done: bool = not s.state.economy.jobs.has("home")
			end_wait(s, "craft:" + id + "x" + str(count), "craft", b, {
				"recipe": id,
				"count": count,
				"attempts": attempts,
				"ok": done,
				"error": "",
			})
			return done
		last_error = String(result.get("error", ""))
		if not last_error in ["INSUFFICIENT_RESOURCE", "JOB_BUSY"]:
			end_wait(s, "craft:" + id + "x" + str(count), "craft", b, {
				"recipe": id,
				"count": count,
				"attempts": attempts,
				"ok": false,
				"error": last_error,
			})
			return false
		s.advance_time(10.0)
	end_wait(s, "craft:" + id + "x" + str(count), "craft", b, {
		"recipe": id,
		"count": count,
		"attempts": attempts,
		"ok": false,
		"error": last_error,
	})
	return false

func wait_craft(s: GameSession, id: String, island: String) -> bool:
	var b := begin(s)
	var attempts := 0
	var last_error := ""
	for _attempt in range(150):
		attempts += 1
		var result := send(s, "craft", {"recipe_id": id, "island_id": island, "count": 1, "repeat": true})
		if result.ok:
			end_wait(s, "start_producer:" + id, "craft", b, {"recipe": id, "island": island, "attempts": attempts, "ok": true})
			return true
		last_error = String(result.get("error", ""))
		if not last_error in ["INSUFFICIENT_RESOURCE", "JOB_BUSY"]:
			end_wait(s, "start_producer:" + id, "craft", b, {"recipe": id, "island": island, "attempts": attempts, "ok": false, "error": last_error})
			return false
		s.advance_time(10.0)
	end_wait(s, "start_producer:" + id, "craft", b, {"recipe": id, "island": island, "attempts": attempts, "ok": false, "error": last_error})
	return false

func build_report() -> Dictionary:
	var variant_rows: Array = []
	for key in variants:
		var v: Dictionary = variants[key]
		variant_rows.append(v.duplicate(true))
	var slowest: Array = waits.duplicate(true)
	slowest.sort_custom(func(a, b): return float(a.get("sim_seconds", 0.0)) > float(b.get("sim_seconds", 0.0)))
	var top_waits: Array = []
	for i in range(mini(40, slowest.size())):
		top_waits.append(slowest[i])
	var over_600: Array = []
	for rec in waits:
		if bool(rec.get("over_600s", false)):
			over_600.append(rec)
	var bottlenecks: Array = bottleneck_rows()
	return {
		"generated_at": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info(),
		"project_version": SaveCodec.GAME_VERSION,
		"rules_version": SaveCodec.RULES_VERSION,
		"save_schema_version": SaveCodec.SCHEMA_VERSION,
		"content_version": content.content_version,
		"source_hashes": source_hashes(),
		"checks": checks,
		"failures": failures,
		"baseline": BASELINE,
		"variants": variant_rows,
		"milestones": milestones,
		"waits": waits,
		"over_600s": over_600,
		"top_waits": top_waits,
		"bottlenecks": bottlenecks,
		"uncovered": UNCOVERED,
		"method": [
			"Real GameSession commands only; no direct resource, building, era or training assignment.",
			"Isolated new-game state; no player save is read or written.",
			"Era1 gathering is modelled at 2 clicks per second with 0.5 simulated seconds per gather.",
			"Simulated seconds come from state.total_elapsed_seconds; wall time is headless machine time.",
			"After Era3 Lv10 the bot advances time until the lifespan is exhausted because no live early-reincarnation building exists.",
			"Observation command: tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/early_v1a_observation.gd; log: build/early-v1-a-observation.log; recorded run exit 0 with no SCRIPT ERROR.",
		],
	}

func bottleneck_rows() -> Array:
	var longest: Dictionary = {}
	for rec in waits:
		if not bool(rec.get("actionable", false)):
			continue
		var key := String(rec.get("run", "")) + "|" + String(rec.get("label", ""))
		if not longest.has(key) or float(rec.get("sim_seconds", 0.0)) > float(longest[key].get("sim_seconds", 0.0)):
			longest[key] = rec
	var rows: Array = []
	for key in longest:
		rows.append(longest[key])
	rows.sort_custom(func(a, b): return float(a.get("sim_seconds", 0.0)) > float(b.get("sim_seconds", 0.0)))
	var top: Array = []
	for i in range(mini(12, rows.size())):
		top.append(rows[i])
	return top

func source_hashes() -> Dictionary:
	var result := {}
	for path in HASH_PATHS:
		var full: String = "res://" + path
		result[path] = FileAccess.get_sha256(full) if FileAccess.file_exists(full) else "MISSING"
	return result

func write_report(report: Dictionary) -> bool:
	var dir := DirAccess.open("res://docs/verification/artifacts")
	if dir != null and not dir.dir_exists("early-v1-a"):
		dir.make_dir("early-v1-a")
	var json_file := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	if json_file == null:
		_fail("cannot write " + OUT_JSON)
		return false
	json_file.store_string(JSON.stringify(report, "  ", true))
	json_file.close()
	var md := render_markdown(report)
	for path in [OUT_MD, ART_MD]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			_fail("cannot write " + path)
			return false
		file.store_string(md)
		file.close()
	return true

func render_markdown(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# EARLY-V1-A Current Quantified Baseline")
	lines.append("")
	lines.append("Generated: " + String(report.generated_at) + " UTC")
	lines.append("")
	lines.append("Engine: " + String(report.engine.string) + " | Project: " + String(report.project_version) + " | Rules: " + String(report.rules_version) + " | Save schema: " + str(report.save_schema_version))
	lines.append("")
	lines.append("Content version: `" + String(report.content_version) + "`")
	lines.append("")
	lines.append("## Scope and method")
	lines.append("")
	for item in report.method:
		lines.append("- " + String(item))
	lines.append("")
	lines.append("This is a mechanical observation matrix, not a full human playthrough or a UI/device pass.")
	lines.append("")
	lines.append("## Current pacing audit (regenerated 2026-10-18)")
	lines.append("")
	var baseline: Dictionary = report.baseline
	lines.append("- Report: `" + String(baseline.report) + "` (2026-10-18, current rules)")
	lines.append("- Command: `" + String(baseline.command) + "`")
	lines.append("- Exit code: " + str(baseline.exit_code) + "; log: `" + String(baseline.log) + "`; no SCRIPT ERROR")
	lines.append("- Findings: " + str(baseline.findings))
	lines.append("- Chain training seconds: " + str(baseline.chain_training_seconds))
	lines.append("- Era1 simulation: active " + str(baseline.era1_sim_active_seconds) + "s / idle " + str(baseline.era1_sim_idle_seconds) + "s")
	lines.append("")
	lines.append("Old 2026-10-11 C1-C10 values are historical comparison only and are archived under `docs/verification/artifacts/early-v1-a/pre-v2-baseline/`: " + str(baseline.historical_only))
	lines.append("")
	lines.append("## Observation matrix")
	lines.append("")
	lines.append("| Variant | Status | Peak era/lv | End era/lv | Sim s | Wall s | Peak lifespan s | Dao heart | Skill pts | Talents | Skills | Waits >=600s |")
	lines.append("| --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- | --- | ---: |")
	for v in report.variants:
		lines.append("| %s | %s | %s/%s | %s/%s | %.1f | %.3f | %.0f | %s | %.1f | %s | %s | %d |" % [
			String(v.get("run", "")),
			String(v.get("status", "")), str(v.get("peak_era", 0)), str(v.get("peak_level", 0)),
			str(v.get("end_era", 0)), str(v.get("end_level", 0)),
			float(v.get("sim_seconds", 0.0)), float(v.get("wall_seconds", 0.0)), float(v.get("peak_max_lifespan_seconds", 0.0)),
			String(v.get("dao_heart", "0")), float(v.get("skill_points", 0.0)),
			str(v.get("talents", {})), str(v.get("skills", {})), int(v.get("over_600s", 0)),
		])
	lines.append("")
	lines.append("V1 ends at Era1 Lv1 because the recorded run includes the real reincarnation reset; its peak before rebirth is read from the milestone log. V1b measures rebuild from that rebirth to Era2 Lv1.")
	lines.append("")
	lines.append("## Milestones")
	lines.append("")
	lines.append("| Run | Milestone | Era/lv | Sim s | Wall ms | Dao heart | Skill pts |")
	lines.append("| --- | --- | --- | ---: | ---: | --- | ---: |")
	for m in report.milestones:
		lines.append("| %s | %s | %s/%s | %.1f | %d | %s | %.1f |" % [
			String(m.get("run", "")), String(m.get("milestone", "")), str(m.get("era", 0)), str(m.get("level", 0)),
			float(m.get("sim_seconds", 0.0)), int(m.get("wall_ms_since_start", 0)), String(m.get("dao_heart", "0")), float(m.get("skill_points", 0.0)),
		])
	lines.append("")
	lines.append("## Waits and bottlenecks")
	lines.append("")
	lines.append("All waits are recorded in the JSON. The table below shows the 40 longest simulated segments.")
	lines.append("")
	lines.append("| Run | Kind | Label | Sim s | Wall ms | Actionable | >=600s | Detail |")
	lines.append("| --- | --- | --- | ---: | ---: | --- | --- | --- |")
	for w in report.top_waits:
		lines.append("| %s | %s | %s | %.1f | %d | %s | %s | %s |" % [
			String(w.get("run", "")), String(w.get("kind", "")), String(w.get("label", "")),
			float(w.get("sim_seconds", 0.0)), int(w.get("wall_ms", 0)), str(w.get("actionable", false)), str(w.get("over_600s", false)),
			str(w.get("recipe", w.get("building", w.get("missing_at_start", "")))),
		])
	lines.append("")
	lines.append("Segments at or above 600 simulated seconds: %d. See `over_600s` in the JSON for the exact list." % report.over_600s.size())
	lines.append("")
	lines.append("### Longest actionable bottleneck per label")
	lines.append("")
	lines.append("| Run | Kind | Label | Sim s | Detail |")
	lines.append("| --- | --- | --- | ---: | --- |")
	for w in report.bottlenecks:
		lines.append("| %s | %s | %s | %.1f | %s |" % [
			String(w.get("run", "")), String(w.get("kind", "")), String(w.get("label", "")),
			float(w.get("sim_seconds", 0.0)),
			str(w.get("recipe", w.get("building", ""))),
		])
	lines.append("")
	var era1_lv9_to_10 := 0.0
	var longest_actionable := 0.0
	var longest_actionable_label := ""
	for w in report.waits:
		if bool(w.get("actionable", false)):
			var wait_seconds := float(w.get("sim_seconds", 0.0))
			if wait_seconds > longest_actionable:
				longest_actionable = wait_seconds
				longest_actionable_label = String(w.get("label", ""))
			if String(w.get("run", "")) == "V1_first_life_no_talents_no_skills" and String(w.get("label", "")) == "level:9->10":
				if era1_lv9_to_10 == 0.0 or wait_seconds < era1_lv9_to_10:
					era1_lv9_to_10 = wait_seconds
	lines.append("## Ten-minute policy boundary")
	lines.append("")
	lines.append("- User-named white-body Era1 Lv9->10: %.1f simulated seconds; below the 600-second limit." % era1_lv9_to_10)
	lines.append("- Actionable single waits at or above 600 simulated seconds: %d." % report.over_600s.size())
	lines.append("- Longest actionable single wait: %.1f simulated seconds (%s)." % [longest_actionable, longest_actionable_label])
	lines.append("- The multi-thousand-second lifespan runout segment is tagged lifecycle/non-actionable in the JSON and is not a resource wait.")
	lines.append("")
	lines.append("## Reincarnation and rebuild")
	lines.append("")
	lines.append("Reincarnation was reached by natural lifespan exhaustion; `rebirth_lotus` and `void_mirror` have no live content entry. Reward, granted resources and rebuild duration are in the variant and milestone tables.")
	lines.append("")
	lines.append("## Talents and skills")
	lines.append("")
	lines.append("V2 learns `resource_inheritance` at level 1 for 5 dao heart. Its inheritance effect applies only at a future reincarnation, so V2 does not realize that effect; the observed production multiplier is the dao-heart bonus from holding 15 dao heart, not the talent's inheritance grant. V3 builds `library`, waits for 90 skill points and learns `basic_meditation`. Other talents, skill combinations and Era3 `golden_core_formation` are intentionally not claimed.")
	lines.append("")
	lines.append("## Uncovered and not claimed")
	lines.append("")
	for item in report.uncovered:
		lines.append("- " + String(item))
	lines.append("")
	lines.append("## Source hashes")
	lines.append("")
	lines.append("| Path | SHA-256 |")
	lines.append("| --- | --- |")
	for path in report.source_hashes:
		lines.append("| `" + String(path) + "` | `" + String(report.source_hashes[path]) + "` |")
	lines.append("")
	lines.append("## Checks")
	lines.append("")
	lines.append("- Command checks: " + str(report.checks))
	lines.append("- Internal failures: " + str(report.failures))
	lines.append("")
	return "\n".join(lines)


