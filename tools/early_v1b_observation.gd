extends SceneTree
const OUT_DIR := "res://docs/verification/artifacts/early-v1-b"
const OUT_JSON := OUT_DIR + "/observation.json"
const OUT_MD := OUT_DIR + "/observation.md"
const TALENT_IDS := ["resource_inheritance", "lifespan_extension", "innate_dao_body"]
const FROZEN_NAMES := {"resource_inheritance": "資源傳承", "lifespan_extension": "長生久視", "innate_dao_body": "先天道體"}
const TEST_LEVELS := [0, 1, 2, 5, 10]
const FIXTURE_DAO_HEART := 20000.0
const FIXTURE_PREVIOUS_LINGLI := 777.0
const METHOD_NOTES := [
	"Real GameSession submit commands for learn_talent and reincarnate; no direct talent, era, resource, building or time mutation during measured steps.",
	"Fixture setup per isolated session is declared and is not earned play: era 3, level 10, buildings rebirth_lotus = 1, previous lingli stock 777, dao heart 20000, money and wood unlocked.",
	"rebirth_lotus has no live content entry in this build (no content/*.json reference); it is fixture setup only and is NOT claimed as reachable content.",
	"One isolated session per variant; three talents x levels 0/1/2/5/10; official learn_talent purchases; official reincarnate with mode normal.",
	"All recorded seconds are simulated seconds from state and rule values; this matrix is fixture-driven and is not a human or Web session.",
	"era1_lv1_next_required_seconds comes from the post-reincarnation view; era3_lv10_required_seconds comes from Cultivation.next_level_required_seconds(content.era(3), 10, 0, 1.0) because the era3 level10 view shows the breakthrough panel instead of a next level.",
	"Start amounts follow ReincarnationRules on the fresh era1 state: only onboarding-unlocked basic resources receive floor(cap x 10% x inheritance level); at a fresh era1 start with cleared buildings only lingli is unlocked.",
]
var checks := 0
var failures: Array[String] = []
var serial := 0
var content: GameContent

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func send(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return s.submit({"command_id": "early-v1b-obs-" + str(serial), "type": kind, "expected_revision": s.state.revision, "payload": payload})

func expected_start(resource_id: String, inheritance_bonus: float) -> float:
	var unlock: Dictionary = Onboarding.unlock_state(1, 1, {})
	var unlocked: bool = resource_id != "skill_point" and (not bool(unlock["active"]) or resource_id in (unlock["resources"] as Array))
	if not unlocked:
		return 0.0
	var caps: Dictionary = Production.compute_caps(content, {}, 1, 1)
	var cap_amount: AmountCompat = caps.get(resource_id, AmountCompat.from_number(100.0))
	return ReincarnationRules.compute_start_amount(cap_amount.to_float(), 1, inheritance_bonus)

func _run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	if not bool(loaded.ok):
		failures.append("content load failed")
		_emit_and_quit()
		return
	content = loaded.content
	var attached := IslandProgression.attach(content)
	check(bool(attached.ok), "island progression attach")
	var variants: Array = []
	if bool(attached.ok):
		for talent_id in TALENT_IDS:
			var tid := String(talent_id)
			var by_level: Dictionary = {}
			for level in TEST_LEVELS:
				var lvl := int(level)
				var variant := _run_variant(tid, lvl)
				by_level[lvl] = variant
				variants.append(variant)
			for level in TEST_LEVELS:
				var lvl2 := int(level)
				if lvl2 == 0:
					continue
				variants.append(_delta_row(tid, lvl2, by_level[0], by_level[lvl2]))
	_emit_and_quit_with_variants(variants)

func _run_variant(talent_id: String, level: int) -> Dictionary:
	var s := GameSession.create_new_game(content)
	s.state.era_id = 3
	s.state.level = 10
	s.state.buildings["rebirth_lotus"] = 1
	s.state.resources["lingli"].value = AmountCompat.from_number(FIXTURE_PREVIOUS_LINGLI)
	s.state.resources["money"].unlocked = true
	s.state.resources["wood"].unlocked = true
	s.state.dao_heart = AmountCompat.from_number(FIXTURE_DAO_HEART)
	var dh_before: float = s.state.dao_heart.to_float()
	var spent := 0.0
	for _i in range(level):
		var current_level := int(s.state.talents.get(talent_id, 0))
		var cost := TalentSystem.get_cost(talent_id, current_level).to_float()
		var result := send(s, "learn_talent", {"talent_id": talent_id})
		check(bool(result.ok), "variant " + talent_id + " L" + str(level) + " learn level " + str(current_level + 1))
		if bool(result.ok):
			spent += cost
	var dh_after_buy: float = s.state.dao_heart.to_float()
	check(is_equal_approx(dh_before - dh_after_buy, spent), "variant " + talent_id + " L" + str(level) + " cost spent matches dao heart drop")
	var reinc := send(s, "reincarnate", {"mode": "normal"})
	check(bool(reinc.ok), "variant " + talent_id + " L" + str(level) + " official reincarnate ok")
	check(int(s.state.reincarnation_count) == 1, "variant " + talent_id + " L" + str(level) + " reincarnation count 1")
	check(int(s.state.talents.get(talent_id, 0)) == level, "variant " + talent_id + " L" + str(level) + " talent persists")
	var view: Dictionary = s.get_view()
	var inheritance_bonus := 0.1 * float(level) if talent_id == "resource_inheritance" else 0.0
	var lingli_expected := expected_start("lingli", inheritance_bonus)
	var starts: Dictionary = {}
	for resource_id in content.resource_ids:
		var def: Dictionary = content.resources[resource_id]
		if String(def.get("type", "")) != "basic":
			continue
		var entry: Dictionary = s.state.resources[resource_id]
		starts[String(resource_id)] = {"value": entry.value.to_float(), "unlocked": bool(entry.unlocked)}
	check(is_equal_approx(float((starts["lingli"] as Dictionary)["value"]), lingli_expected), "variant " + talent_id + " L" + str(level) + " lingli start equals floor(cap*ratio)")
	var others_zero := true
	for resource_key in starts:
		if String(resource_key) == "lingli":
			continue
		var entry2: Dictionary = starts[resource_key]
		if float(entry2["value"]) != 0.0 or bool(entry2["unlocked"]):
			others_zero = false
	check(others_zero, "variant " + talent_id + " L" + str(level) + " other basic resources zero and locked at fresh era1")
	var era3_def: Dictionary = content.era(3)
	var era3_required := Cultivation.next_level_required_seconds(era3_def, 10, 0.0, 1.0)
	var mults: Dictionary = view["multipliers"]
	var dh_after: float = s.state.dao_heart.to_float()
	return {
		"kind": "variant",
		"talent": talent_id,
		"name": String(FROZEN_NAMES[talent_id]),
		"level": level,
		"cost_spent": spent,
		"dao_heart_before": dh_before,
		"dao_heart_after_purchase": dh_after_buy,
		"dao_heart_after_reincarnation": dh_after,
		"start_resources": starts,
		"other_basic_zero_locked": others_zero,
		"max_lifespan_seconds": float(view["max_lifespan_seconds"]),
		"cultivation_speed_bonus": float(mults["cultivation_speed_bonus"]),
		"era1_lv1_next_required_seconds": float(view["next_level_required_seconds"]),
		"era3_lv10_required_seconds": era3_required,
		"reincarnation_count": int(s.state.reincarnation_count),
		"talents_after": s.state.talents.duplicate(true),
	}

func lingli_start_of(variant: Dictionary) -> float:
	return float((variant["start_resources"]["lingli"] as Dictionary)["value"])

func _delta_row(talent_id: String, level: int, base: Dictionary, variant: Dictionary) -> Dictionary:
	return {
		"kind": "delta_vs_level0",
		"talent": talent_id,
		"level": level,
		"cost_spent": float(variant["cost_spent"]),
		"lingli_start_delta": lingli_start_of(variant) - lingli_start_of(base),
		"max_lifespan_delta": float(variant["max_lifespan_seconds"]) - float(base["max_lifespan_seconds"]),
		"cultivation_speed_bonus_delta": float(variant["cultivation_speed_bonus"]) - float(base["cultivation_speed_bonus"]),
		"era1_lv1_required_delta": float(variant["era1_lv1_next_required_seconds"]) - float(base["era1_lv1_next_required_seconds"]),
		"era3_lv10_required_delta": float(variant["era3_lv10_required_seconds"]) - float(base["era3_lv10_required_seconds"]),
	}

func _emit_and_quit() -> void:
	_emit_and_quit_with_variants([])

func _affordability(variants: Array) -> Dictionary:
	var income_first := float(ReincarnationRules.era_dao_heart_floor(3))
	var income_second := float(ReincarnationRules.era_dao_heart_floor(2))
	var total := income_first + income_second
	var rows: Array = []
	for item in variants:
		var row: Dictionary = item
		if String(row.get("kind", "")) != "delta_vs_level0":
			continue
		var cost := float(row.get("cost_spent", 0.0))
		rows.append({
			"talent": String(row.get("talent", "")),
			"level": int(row.get("level", 0)),
			"cumulative_cost": cost,
			"covered_by_first_rebirth": cost <= income_first,
			"covered_by_first_two_rebirths": cost <= total,
		})
	return {
		"income_first_rebirth": income_first,
		"income_second_rebirth": income_second,
		"first_two_rebirth_total": total,
		"basis": "era3 fixture building sum 1 -> max(floor(1/10), era3 floor 20); rebuilt era2 fixture -> max(floor(1/10), era2 floor 15); natural income only, fixture dao heart 20000 excluded",
		"rows": rows,
	}

func _emit_and_quit_with_variants(variants: Array) -> void:
	var report := {
		"engine": String(Engine.get_version_info().get("string", "")),
		"project_version": SaveCodec.GAME_VERSION,
		"rules_version": SaveCodec.RULES_VERSION,
		"save_schema_version": SaveCodec.SCHEMA_VERSION,
		"content_version": content.content_version if content != null else "",
		"method": METHOD_NOTES,
		"variants": variants,
		"affordability": _affordability(variants),
		"checks": checks,
		"failures": failures.duplicate(true),
	}
	var write_ok := _write_artifacts(report)
	if not write_ok:
		failures.append("artifact write failed")
	print("EARLY-V1-B observation: variants=%d checks=%d failures=%d" % [variants.size(), checks, failures.size()])
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _write_artifacts(report: Dictionary) -> bool:
	var artifacts_dir := DirAccess.open("res://docs/verification/artifacts")
	if artifacts_dir != null and not artifacts_dir.dir_exists("early-v1-b"):
		artifacts_dir.make_dir("early-v1-b")
	var json_file := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	if json_file == null:
		failures.append("cannot write " + OUT_JSON)
		return false
	json_file.store_string(JSON.stringify(report, "  ", true))
	json_file.close()
	var md_file := FileAccess.open(OUT_MD, FileAccess.WRITE)
	if md_file == null:
		failures.append("cannot write " + OUT_MD)
		return false
	md_file.store_string(_render_markdown(report))
	md_file.close()
	return true

func _render_markdown(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# EARLY-V1-B Reincarnation Talent Observation (fixture-driven)")
	lines.append("")
	lines.append("Engine: %s | Project: %s | Rules: %s | Save schema: %d" % [String(report["engine"]), String(report["project_version"]), String(report["rules_version"]), int(report["save_schema_version"])])
	lines.append("")
	lines.append("Content version: `%s`" % String(report["content_version"]))
	lines.append("")
	lines.append("Deterministic artifact: no wall-clock values; every recorded second is a simulated second from state and rule values.")
	lines.append("")
	lines.append("## Scope and method")
	lines.append("")
	for note in report["method"]:
		lines.append("- " + String(note))
	lines.append("")
	lines.append("## Variant matrix (one isolated session per row)")
	lines.append("")
	lines.append("| Talent | Lv | Cost spent | DH before | DH after buy | DH after rebirth | lingli start | Other basic zero+locked | Max lifespan s | Speed bonus | Era1 lv1 req s | Era3 lv10 req s |")
	lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: |")
	for item in report["variants"]:
		var v: Dictionary = item
		if String(v.get("kind", "")) != "variant":
			continue
		lines.append("| %s (%s) | %d | %.0f | %.0f | %.0f | %.0f | %.1f | %s | %.1f | %.2f | %.1f | %.1f |" % [
			String(v["talent"]), String(v["name"]), int(v["level"]), float(v["cost_spent"]),
			float(v["dao_heart_before"]), float(v["dao_heart_after_purchase"]), float(v["dao_heart_after_reincarnation"]),
			lingli_start_of(v), "yes" if bool(v["other_basic_zero_locked"]) else "NO",
			float(v["max_lifespan_seconds"]), float(v["cultivation_speed_bonus"]),
			float(v["era1_lv1_next_required_seconds"]), float(v["era3_lv10_required_seconds"]),
		])
	lines.append("")
	lines.append("## Delta versus level 0 (same talent)")
	lines.append("")
	lines.append("| Talent | Lv | Cumulative cost | lingli start delta | Lifespan delta s | Speed bonus delta | Era1 lv1 req delta | Era3 lv10 req delta |")
	lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
	for item in report["variants"]:
		var d: Dictionary = item
		if String(d.get("kind", "")) != "delta_vs_level0":
			continue
		lines.append("| %s | %d | %.0f | %.1f | %.1f | %.2f | %.1f | %.1f |" % [
			String(d["talent"]), int(d["level"]), float(d["cost_spent"]),
			float(d["lingli_start_delta"]), float(d["max_lifespan_delta"]),
			float(d["cultivation_speed_bonus_delta"]), float(d["era1_lv1_required_delta"]), float(d["era3_lv10_required_delta"]),
		])
	lines.append("")
	lines.append("## First two rebirths: dao heart income versus talent cost")
	lines.append("")
	var afford: Dictionary = report["affordability"]
	lines.append("- first rebirth income: **%.0f** dao heart; hypothetical second rebirth income: **%.0f**; first-two-rebirth total: **%.0f**." % [float(afford["income_first_rebirth"]), float(afford["income_second_rebirth"]), float(afford["first_two_rebirth_total"])])
	lines.append("- basis: %s; all values are rule-derived simulated-state numbers, not a human or Web session." % String(afford["basis"]))
	lines.append("")
	lines.append("| Talent | Lv | Cumulative cost | Covered by first rebirth | Covered by first two rebirths |")
	lines.append("| --- | ---: | ---: | --- | --- |")
	for item in afford["rows"]:
		var a: Dictionary = item
		lines.append("| %s | %d | %.0f | %s | %s |" % [
			String(a["talent"]), int(a["level"]), float(a["cumulative_cost"]),
			"yes" if bool(a["covered_by_first_rebirth"]) else "no",
			"yes" if bool(a["covered_by_first_two_rebirths"]) else "no",
		])
	lines.append("")
	lines.append("All seconds above are simulated seconds; the fixture (era 3, level 10, rebirth_lotus = 1, previous lingli stock 777, dao heart 20000) is declared setup, and rebirth_lotus has no live content entry in this build, so nothing here is a human or Web session claim.")
	lines.append("")
	lines.append("## Checks")
	lines.append("")
	lines.append("- Checks: %d" % int(report["checks"]))
	lines.append("- Failures: %s" % str(report["failures"]))
	lines.append("")
	return "\n".join(lines)
