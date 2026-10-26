extends SceneTree
const P2_IDS := ["nascent_soul_incubation", "nascent_soul_mastery", "heavenly_craft", "deep_vein_resonance", "void_expansion", "spirit_transformation", "ancient_herb_attunement", "spirit_sea_breath", "void_mastery", "void_refinement", "void_essence_attunement", "frontier_storekeeping"]
const GC_IDS := ["nascent_soul_incubation", "nascent_soul_mastery", "spirit_transformation", "void_refinement"]
const LEGACY_SKILLS := {"basic_meditation": 1, "qi_condensation": 1, "foundation_building": 1, "qi_storage_1": 1, "body_strengthening_1": 1, "building_mastery_1": 1, "golden_core_formation": 1, "greenwood_nourishment": 1, "ore_breath_refinement": 1, "herbal_spirit_nurture": 1, "warehouse_preparation": 1, "alchemical_breath_control": 1}
const META := {"save_id": "sksp2-core", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
var checks := 0
var failures: Array[String] = []
var serial := 0
var plain_content: GameContent
var supply_content: GameContent
var plain_session: GameSession
var econ_session: GameSession

func _init() -> void:
	plain_content = ContentLoader.load_directory("res://content").content
	expect(IslandProgression.attach(plain_content).ok, "legacy attachment")
	supply_content = ContentLoader.load_directory("res://content").content
	expect(IslandProgression.attach_supply(supply_content).ok, "supply attachment")
	plain_session = GameSession.create_new_game(plain_content, 20261024)
	econ_session = GameSession.create_new_game(supply_content, 20261024)
	econ_session.state.era_id = 6
	expect(send(econ_session, "activate_islands").ok, "supply economy activation")
	expect(String(econ_session.state.economy.get("version", "")) == IslandProgression.SUPPLY_VERSION, "supply-attached new game expands economy")
	_test_constants()
	_test_attach_data()
	_test_learn_gating()
	_test_effect_math()
	_test_local_and_caps()
	_test_discounts()
	_test_craft_flow()
	_test_save_flow()
	_test_local_capacity_validate()
	_test_reincarnation()
	for failure in failures:
		push_error(failure)
	print("%s: SKS-P2 %d checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)

func send(session: GameSession, type: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return session.submit({"command_id": "sksp2-" + str(serial), "expected_revision": session.state.revision, "type": type, "payload": payload})

func stock(state: GameState, id: String, amount: float) -> void:
	state.resources[id] = {"value": AmountCompat.from_number(amount), "unlocked": true, "ever_obtained": true}

func skill_def(id: String) -> Dictionary:
	var def: Dictionary = plain_content.skill_defs.get(id, {})
	return def

func def_matches(id: String, want_era: int, want_cost: float, want_max: int, want_effect: String, want_amount: float) -> bool:
	var def := skill_def(id)
	return not def.is_empty() and int(def.get("era", 0)) == want_era and float(def.get("cost", 0.0)) == want_cost and int(def.get("max_level", 0)) == want_max and String(def.get("effect", "")) == want_effect and float(def.get("amount", 0.0)) == want_amount

func has_golden_requires(id: String) -> bool:
	var requires: Dictionary = skill_def(id).get("requires", {})
	return String(requires.get("skill_id", "")) == "golden_core_formation" and int(requires.get("level", 0)) == 1

func has_no_requires(id: String) -> bool:
	var requires: Dictionary = skill_def(id).get("requires", {})
	return requires.is_empty()

func skill_reason(content: GameContent, state: GameState, skill_id: String) -> String:
	var view_data: Dictionary = SkillSystem.view(content, state)
	for item in view_data["items"]:
		var entry: Dictionary = item
		if String(entry.get("id", "")) == skill_id:
			return String(entry.get("reason", ""))
	return ""

func _test_constants() -> void:
	var limits_ok := SksP2Rules.LIMITS.size() == 12 and int(SksP2Rules.LIMITS["nascent_soul_incubation"]) == 5
	for id in SksP2Rules.LIMITS:
		if String(id) != "nascent_soul_incubation":
			limits_ok = limits_ok and int(SksP2Rules.LIMITS[id]) == 3
	expect(limits_ok, "twelve limits incubation five others three")
	expect(SksP2Rules.HOME_CAPACITY_IDS.size() == 23 and SksP2Rules.HOME_CAPACITY_IDS.has("lingli") and SksP2Rules.HOME_CAPACITY_IDS.has("skill_point") and SksP2Rules.HOME_CAPACITY_IDS.has("mithril") and SksP2Rules.HOME_CAPACITY_IDS.has("void_essence") and not SksP2Rules.HOME_CAPACITY_IDS.has("lingqi") and not SksP2Rules.HOME_CAPACITY_IDS.has("spirit_crystal") and not SksP2Rules.HOME_CAPACITY_IDS.has("contribution"), "home capacity list twenty-three with contract membership")
	var subset_ok := SksP2Rules.ADVANCED_CAPACITY_IDS.size() == 7
	for id in SksP2Rules.ADVANCED_CAPACITY_IDS:
		subset_ok = subset_ok and SksP2Rules.HOME_CAPACITY_IDS.has(id)
	expect(subset_ok, "seven advanced ids subset of home list")
	expect(SksP2Rules.HOME_RATE_IDS == ["lingli", "money", "wood", "stone_low", "spirit_grass_low", "skill_point"], "home rate list exactly six documented ids")
	expect(SksP2Rules.DISCOUNT_RECIPE_IDS == ["stone_mid_bulk", "stone_high"] and SksP2Rules.LOCAL_CAPACITY_ISLANDS == ["deep", "ancient", "void"], "discount recipes and local islands exact")
	expect(SksP2Rules.INCUBATION_FACTOR == 1.15 and SksP2Rules.ADVANCED_CAPACITY_FACTOR == 1.1 and SksP2Rules.HOME_RATE_FACTOR == 1.1 and SksP2Rules.LOCAL_RATE_FACTOR == 1.1 and SksP2Rules.DISCOUNT_PER_LEVEL == 0.05 and SksP2Rules.LOCAL_CAPACITY_PER_LEVEL == 100.0, "rule factors match design")
	expect(SkillSystem.VERSION == 4 and String(SkillSystem.P2_CONTENT_TAG) == "+content-sks-p2" and SkillSystem.SUPPORTED_VERSIONS == [0, 1, 2, 3, 4], "skill system version tag and supported list")

func _test_attach_data() -> void:
	expect(plain_content.skill_defs.size() == 24, "twenty-four skill definitions after attach")
	var era_counts := {4: 0, 5: 0, 6: 0}
	var present := true
	for id in P2_IDS:
		present = present and plain_content.skill_defs.has(String(id))
		var era_value := int(skill_def(String(id)).get("era", 0))
		if era_counts.has(era_value):
			era_counts[era_value] = int(era_counts[era_value]) + 1
	expect(present and int(era_counts[4]) == 4 and int(era_counts[5]) == 4 and int(era_counts[6]) == 4, "all twelve p2 ids present four per era")
	expect(def_matches("nascent_soul_incubation", 4, 21250.0, 5, "p2_home_capacity_multiplier", 1.15) and def_matches("nascent_soul_mastery", 4, 21000.0, 3, "time_multiplier", 0.95) and def_matches("heavenly_craft", 4, 12000.0, 3, "p2_craft_lingli_discount", 0.05) and def_matches("deep_vein_resonance", 4, 9000.0, 3, "p2_deep_rate_multiplier", 1.1), "era four definitions frozen numbers")
	expect(def_matches("void_expansion", 5, 30000.0, 3, "p2_advanced_capacity_multiplier", 1.1) and def_matches("spirit_transformation", 5, 35000.0, 3, "time_multiplier", 0.93) and def_matches("ancient_herb_attunement", 5, 15000.0, 3, "p2_ancient_rate_multiplier", 1.1) and def_matches("spirit_sea_breath", 5, 18000.0, 3, "lingli_multiplier", 1.15), "era five definitions frozen numbers")
	expect(def_matches("void_mastery", 6, 45000.0, 3, "p2_home_rate_multiplier", 1.1) and def_matches("void_refinement", 6, 50000.0, 3, "time_multiplier", 0.9) and def_matches("void_essence_attunement", 6, 24000.0, 3, "p2_void_rate_multiplier", 1.1) and def_matches("frontier_storekeeping", 6, 20000.0, 3, "p2_local_capacity_flat", 100.0), "era six definitions frozen numbers")
	var requires_ok := true
	for id in P2_IDS:
		if GC_IDS.has(String(id)):
			requires_ok = requires_ok and has_golden_requires(String(id))
		else:
			requires_ok = requires_ok and has_no_requires(String(id))
	expect(requires_ok, "golden core requirement only on incubation mastery transformation refinement")
	var version_before: String = plain_content.content_version
	expect(IslandProgression.attach(plain_content).ok and plain_content.content_version == version_before and plain_content.skill_defs.size() == 24, "idempotent attach keeps version and twenty-four defs")
	expect(plain_content.content_version.contains(SkillSystem.P2_CONTENT_TAG), "content version carries sks p2 tag")

func _test_learn_gating() -> void:
	plain_session.state.era_id = 3
	plain_session.state.buildings["library"] = 1
	stock(plain_session.state, "skill_point", 1000000)
	var era_block: Dictionary = send(plain_session, "learn_skill", {"skill_id": "heavenly_craft"})
	expect(not bool(era_block.get("ok", false)) and String(era_block.get("error", "")) == "SKILL_ERA_LOCKED" and int(plain_session.state.skills.get("heavenly_craft", 0)) == 0 and skill_reason(plain_content, plain_session.state, "heavenly_craft") == "SKILL_ERA_LOCKED", "era three refuses era four skill")
	plain_session.state.buildings["library"] = 0
	var study_block: Dictionary = send(plain_session, "learn_skill", {"skill_id": "heavenly_craft"})
	expect(not bool(study_block.get("ok", false)) and String(study_block.get("error", "")) == "SKILL_STUDY_LOCKED" and skill_reason(plain_content, plain_session.state, "heavenly_craft") == "SKILL_STUDY_LOCKED", "library zero refuses study")
	plain_session.state.buildings["library"] = 1
	plain_session.state.era_id = 4
	var prereq_block: Dictionary = send(plain_session, "learn_skill", {"skill_id": "nascent_soul_mastery"})
	expect(not bool(prereq_block.get("ok", false)) and String(prereq_block.get("error", "")) == "SKILL_PREREQ_LOCKED" and skill_reason(plain_content, plain_session.state, "nascent_soul_mastery") == "SKILL_PREREQ_LOCKED", "mastery needs golden core")
	var craft_learn: Dictionary = send(plain_session, "learn_skill", {"skill_id": "heavenly_craft"})
	var points_after: float = plain_session.state.resources.skill_point.value.to_float()
	expect(bool(craft_learn.get("ok", false)) and int(plain_session.state.skills.get("heavenly_craft", 0)) == 1 and is_equal_approx(points_after, 988000.0), "heavenly craft one costs exactly twelve thousand")
	plain_session.state.skills["golden_core_formation"] = 1
	var mastery_learn: Dictionary = send(plain_session, "learn_skill", {"skill_id": "nascent_soul_mastery"})
	expect(bool(mastery_learn.get("ok", false)) and int(plain_session.state.skills.get("nascent_soul_mastery", 0)) == 1, "golden core one unlocks mastery")
	plain_session.state.skills["heavenly_craft"] = 3
	stock(plain_session.state, "skill_point", 1000000)
	var max_block: Dictionary = send(plain_session, "learn_skill", {"skill_id": "heavenly_craft"})
	expect(not bool(max_block.get("ok", false)) and String(max_block.get("error", "")) == "SKILL_MAX_LEVEL" and plain_session.state.resources.skill_point.value.to_float() == 1000000.0 and skill_reason(plain_content, plain_session.state, "heavenly_craft") == "SKILL_MAX_LEVEL", "level three refuses without deduction")
	plain_session.state.skills["heavenly_craft"] = 2
	stock(plain_session.state, "skill_point", 100)
	var poor_block: Dictionary = send(plain_session, "learn_skill", {"skill_id": "heavenly_craft"})
	expect(not bool(poor_block.get("ok", false)) and String(poor_block.get("error", "")) == "INSUFFICIENT_SKILL_POINT" and int(plain_session.state.skills.get("heavenly_craft", 0)) == 2 and plain_session.state.resources.skill_point.value.to_float() == 100.0, "one hundred points keeps level")

func _test_effect_math() -> void:
	var time_skills := {"golden_core_formation": 5, "nascent_soul_mastery": 3, "spirit_transformation": 3, "void_refinement": 3}
	var actual: float = SkillSystem.effect(plain_content, time_skills, "time_multiplier")
	var expected: float = pow(0.9, 5.0) * pow(0.95, 3.0) * pow(0.93, 3.0) * pow(0.9, 3.0)
	expect(absf(actual - expected) <= 1e-12, "time multiplier stack ninety five ninety-three ninety powers")
	expect(is_equal_approx(SkillSystem.effect(plain_content, {"spirit_sea_breath": 3}, "lingli_multiplier"), pow(1.15, 3.0)), "spirit sea breath lingli multiplier")
	expect(is_equal_approx(SkillSystem.effect(plain_content, {"heavenly_craft": 3}, "p2_craft_lingli_discount"), 0.15), "heavenly craft three discount sum")
	expect(SkillSystem.effect(plain_content, {"frontier_storekeeping": 3}, "p2_local_capacity_flat") == 300.0, "frontier three flat capacity three hundred")
	expect(is_equal_approx(SkillSystem.effect(plain_content, {"heavenly_craft": 9}, "p2_craft_lingli_discount"), 0.15), "effect clamps to max level")
	expect(absf(SksP2Rules.cap_multiplier("mithril", {"nascent_soul_incubation": 9}) - pow(1.15, 5.0)) <= 1e-12, "rule level clamp at five")

func _test_local_and_caps() -> void:
	var zero_caps: Dictionary = Production.compute_caps(supply_content, {}, 6, 1, {})
	var full := {"nascent_soul_incubation": 5, "void_expansion": 3}
	expect(zero_caps["mithril"].to_float() == 3000.0 and zero_caps["refined_iron"].to_float() == 3000.0 and zero_caps["stone_high"].to_float() == 10000.0 and zero_caps["trans_pill"].to_float() == 1000.0 and SksP2Rules.cap_multiplier("lingqi", full) == 1.0 and SksP2Rules.cap_multiplier("spirit_crystal", full) == 1.0 and SksP2Rules.cap_multiplier("contribution", full) == 1.0, "base caps 3000 3000 10000 1000 and non-whitelist untouched")
	var inc_caps: Dictionary = Production.compute_caps(supply_content, {}, 6, 1, {"nascent_soul_incubation": 5})
	expect(inc_caps["mithril"].to_float() == 6034.0 and inc_caps["refined_iron"].to_float() == 6034.0, "incubation five floors 3000 times 1.15 to fifth")
	var both_caps: Dictionary = Production.compute_caps(supply_content, {}, 6, 1, full)
	expect(both_caps["mithril"].to_float() == 8031.0 and both_caps["refined_iron"].to_float() == 8031.0, "incubation five plus void three reaches 8031")
	expect(inc_caps["stone_high"].to_float() == 20113.0 and both_caps["stone_high"].to_float() == 26771.0 and inc_caps["trans_pill"].to_float() == 2011.0 and both_caps["trans_pill"].to_float() == 2677.0, "stone_high and trans_pill ladder")
	econ_session.state.skills = full
	var cap_value: float = IslandEconomy.home_cap(econ_session.state, "mithril", supply_content.processing_catalog)
	var caps_ref: Dictionary = Production.compute_caps(supply_content, econ_session.state.buildings, econ_session.state.era_id, econ_session.state.onboarding_version, econ_session.state.skills)
	expect(cap_value == 8031.0 and cap_value == floorf(cap_value) and cap_value == caps_ref["mithril"].to_float(), "home cap matches compute_caps integer-valued")
	var point_cap: AmountCompat = Production.compute_caps(supply_content, {}, 6, 1, {"nascent_soul_incubation": 5})["skill_point"]
	var studied: AmountCompat = SkillSystem.study_cap(econ_session.state, point_cap)
	expect(point_cap.to_float() == 402.0 and studied.to_float() == 402.0 and studied.serialize() == point_cap.serialize(), "study cap does not double multiply skill point")
	econ_session.state.skills = {}
	var sd: Dictionary = IslandEconomy.supply_data()
	expect(float(sd.islands.deep.local_cap) == 300.0 and float(sd.islands.ancient.local_cap) == 300.0 and float(sd.islands.void.local_cap) == 300.0 and String(sd.dispatch.deep) == "mineral_focus" and String(sd.dispatch.ancient) == "ancient_focus" and String(sd.dispatch.void) == "void_focus", "supply islands local cap and dispatch buildings")
	expect(float(sd.islands.deep.rates.refined_iron) == 0.1 and float(sd.islands.deep.rates.mithril) == 0.05 and float(sd.islands.deep.rates.cold_iron) == 0.05 and float(sd.islands.ancient.rates.spirit_grass_1000y) == 0.04 and float(sd.islands.void.rates.void_essence) == 0.05, "supply base gathering rates")
	for island in ["deep", "ancient", "void"]:
		econ_session.state.economy.islands[island].opened = true
	econ_session.state.buildings["mineral_focus"] = 1
	econ_session.state.skills = {"deep_vein_resonance": 3}
	expect(is_equal_approx(IslandEconomy.rate(econ_session.state, "deep", "refined_iron"), 0.2662), "deep focus times resonance")
	econ_session.state.skills = {}
	expect(is_equal_approx(IslandEconomy.rate(econ_session.state, "deep", "refined_iron"), 0.2), "deep focus doubles at level zero")
	econ_session.state.buildings["mineral_focus"] = 0
	econ_session.state.skills = {"deep_vein_resonance": 3}
	expect(is_equal_approx(IslandEconomy.rate(econ_session.state, "deep", "refined_iron"), 0.1331), "resonance alone lifts deep base")
	econ_session.state.skills = {"ancient_herb_attunement": 3, "void_essence_attunement": 3}
	expect(is_equal_approx(IslandEconomy.rate(econ_session.state, "ancient", "spirit_grass_1000y"), 0.05324) and is_equal_approx(IslandEconomy.rate(econ_session.state, "void", "void_essence"), 0.06655), "ancient and void attunement rates")
	for island in ["deep", "ancient", "void"]:
		econ_session.state.economy.islands[island].opened = true
	for level in range(4):
		econ_session.state.skills = {"frontier_storekeeping": level}
		var want: float = 300.0 + float(level) * 100.0
		var level_ok := true
		for island in ["deep", "ancient", "void"]:
			level_ok = level_ok and IslandProgression.capacity(econ_session.state, String(island)) == want
		expect(level_ok, "frontier %d local capacity %d on three supply islands" % [level, int(want)])
	econ_session.state.skills = {"frontier_storekeeping": 3}
	econ_session.state.economy.islands.deep.opened = false
	expect(IslandProgression.capacity(econ_session.state, "deep") == 300.0, "closed supply island keeps base capacity")
	econ_session.state.economy.islands.deep.opened = true
	econ_session.state.skills = {"frontier_storekeeping": 3}
	expect(IslandProgression.capacity(econ_session.state, "wood") == 150.0, "non-supply island capacity untouched by frontier")

func _test_discounts() -> void:
	var bulk_vector: Array = ["1000", "950", "900", "850"]
	var bulk_ok := true
	for level in range(4):
		bulk_ok = bulk_ok and SksP2Rules.discounted_amount("stone_mid_bulk", "home", "lingli", "1000", {"heavenly_craft": level}) == String(bulk_vector[level])
	expect(bulk_ok, "bulk lingli thousand discount vector")
	var high_vector: Array = ["47.5", "45", "42.5"]
	var high_ok := true
	for level in range(1, 4):
		high_ok = high_ok and SksP2Rules.discounted_amount("stone_high", "home", "lingli", "50", {"heavenly_craft": level}) == String(high_vector[level - 1])
	expect(high_ok, "stone high lingli fifty vector")
	var skills_three := {"heavenly_craft": 3}
	expect(SksP2Rules.discounted_amount("stone_mid_bulk", "home", "stone_low", "500", skills_three) == "500" and SksP2Rules.discounted_amount("stone_mid_bulk", "deep", "lingli", "1000", skills_three) == "1000" and SksP2Rules.discounted_amount("stone_mid", "home", "lingli", "10", skills_three) == "10", "stone island and legacy recipe stay raw")
	expect(SksP2Rules.discounted_amount("stone_mid_bulk", "home", "lingli", "1000", {"heavenly_craft": 9}) == "850", "level nine clamps to fifteen percent")
	econ_session.state.skills = {"heavenly_craft": 3}
	var inputs: Dictionary = IslandEconomy.effective_inputs(econ_session.state, supply_content.processing_catalog, "home", "stone_mid_bulk")
	expect(inputs == {"stone_low": "500", "lingli": "850"}, "effective inputs expose discount")
	econ_session.state.skills = {}

func _test_craft_flow() -> void:
	var session := GameSession.create_new_game(supply_content, 20261024)
	session.state.era_id = 4
	session.state.buildings["stone_mine"] = 3
	for id in supply_content.processing_catalog.resources:
		stock(session.state, String(id), 0)
	expect(send(session, "activate_islands").ok, "craft economy activation")
	session.state.skills = {"heavenly_craft": 3}
	stock(session.state, "stone_low", 500)
	stock(session.state, "lingli", 1000)
	expect(send(session, "craft", {"recipe_id": "stone_mid_bulk"}).ok, "discounted bulk craft starts")
	expect(IslandEconomy.value(session.state, "home", "stone_low") == 0.0 and IslandEconomy.value(session.state, "home", "lingli") == 150.0, "bulk charges five hundred stone and eight hundred fifty lingli")
	expect(IslandEconomy.reserved(session.state, "home", "stone_mid", supply_content.processing_catalog) == 100.0 and IslandEconomy.validate(session.state) == "", "running bulk reserves one hundred and validates")
	for index in range(10):
		IslandEconomy.tick(session.state, supply_content.processing_catalog)
	expect(IslandEconomy.value(session.state, "home", "stone_mid") == 100.0, "bulk completes into one hundred mid stone")
	session.state.skills = {}
	stock(session.state, "stone_low", 500)
	stock(session.state, "lingli", 950)
	var short_refused: Dictionary = send(session, "craft", {"recipe_id": "stone_mid_bulk"})
	expect(not bool(short_refused.get("ok", false)) and String(short_refused.get("error", "")) == "INSUFFICIENT_RESOURCE", "level zero needs the full thousand lingli")
	stock(session.state, "lingli", 1000)
	expect(send(session, "craft", {"recipe_id": "stone_mid_bulk"}).ok and IslandEconomy.value(session.state, "home", "lingli") == 0.0, "old job scenario starts at level zero paying thousand")
	session.state.skills = {"heavenly_craft": 3}
	stock(session.state, "stone_low", 500)
	stock(session.state, "lingli", 850)
	var busy: Dictionary = send(session, "craft", {"recipe_id": "stone_mid_bulk"})
	expect(not bool(busy.get("ok", false)) and String(busy.get("error", "")) == "JOB_BUSY" and IslandEconomy.value(session.state, "home", "lingli") == 850.0, "simultaneous second craft rejected without spending")
	expect(send(session, "switch_processing", {"recipe_id": "stone_mid_bulk"}).ok, "queue second bulk at exactly eight hundred fifty")
	var running: Dictionary = session.state.economy.jobs["home"]
	expect(int(running.remaining) == 10 and running.reserves == {} and String(running.status) == "running", "running job keeps remaining and reserves")
	for index in range(10):
		IslandEconomy.tick(session.state, supply_content.processing_catalog)
	expect(IslandEconomy.value(session.state, "home", "lingli") == 0.0 and IslandEconomy.value(session.state, "home", "stone_low") == 0.0 and IslandEconomy.value(session.state, "home", "stone_mid") == 200.0, "queued batch pays exactly eight hundred fifty with no refund")
	var next_job: Dictionary = session.state.economy.jobs["home"]
	expect(int(next_job.remaining) == 10 and String(next_job.status) == "running" and IslandEconomy.validate(session.state) == "", "discounted handoff runs and validates")

func _test_save_flow() -> void:
	econ_session.state.skills = {"golden_core_formation": 5, "nascent_soul_incubation": 5, "nascent_soul_mastery": 3, "heavenly_craft": 3, "deep_vein_resonance": 3, "void_expansion": 3, "spirit_transformation": 3, "ancient_herb_attunement": 3, "spirit_sea_breath": 3, "void_mastery": 3, "void_refinement": 3, "void_essence_attunement": 3, "frontier_storekeeping": 3}
	var encoded: Dictionary = SaveCodec.encode(econ_session.state, supply_content.content_version, META)
	expect(bool(encoded.get("ok", false)), "expanded v4 save encodes")
	var decoded: Dictionary = SaveCodec.decode(String(encoded.get("json", "")))
	var envelope: Dictionary = decoded.get("envelope", {})
	expect(bool(decoded.get("ok", false)) and decoded.state.skills == econ_session.state.skills and int(decoded.state.skill_version) == 4, "p2 roundtrip preserves version four levels")
	expect(econ_session.state.sect_version == 2 and econ_session.state.pill_version == 2 and String(envelope.get("rules_version", "")) == SaveCodec.BEAST_RULES_VERSION and SaveCodec.SECT_RULES_VERSION == "core-flow-22-content-p2-sect" and SaveCodec.PILL_RULES_VERSION == "core-flow-21-content-p2-pills" and SaveCodec.SKS_RULES_VERSION == "core-flow-19-content-sks-p2", "expanded skill v4 uses current beast v1 rules identity")
	var plain_encoded: Dictionary = SaveCodec.encode(plain_session.state, plain_content.content_version, META)
	var plain_decoded: Dictionary = SaveCodec.decode(String(plain_encoded.get("json", "")))
	var plain_envelope: Dictionary = plain_decoded.get("envelope", {})
	expect(bool(plain_encoded.get("ok", false)) and bool(plain_decoded.get("ok", false)) and plain_session.state.sect_version == 2 and plain_session.state.pill_version == 2 and String(plain_envelope.get("rules_version", "")) == SaveCodec.BEAST_RULES_VERSION, "observed non-expanded skill v4 uses current beast v1 rules identity")
	expect(not SkillSystem.validate(3, {"nascent_soul_incubation": 1}).is_empty() and SkillSystem.validate(4, {"nascent_soul_incubation": 1}).is_empty(), "p2 ids rejected at three accepted at four")
	var rejects := not SkillSystem.validate(4, {"heavenly_craft": -1}).is_empty() and not SkillSystem.validate(4, {"heavenly_craft": 1.5}).is_empty() and not SkillSystem.validate(4, {"heavenly_craft": 4}).is_empty() and not SkillSystem.validate(4, {"nascent_soul_incubation": 6}).is_empty()
	expect(rejects, "negative fractional over max levels rejected")
	expect(SkillSystem.validate(4, {"nascent_soul_incubation": 5}).is_empty() and SkillSystem.skill_count_limit(3) == 12 and SkillSystem.skill_count_limit(4) == 24, "incubation five accepted and count limits twelve twenty-four")
	var thirteen: Dictionary = LEGACY_SKILLS.duplicate(true)
	thirteen["heavenly_craft"] = 1
	expect(SkillSystem.validate(3, LEGACY_SKILLS).is_empty() and not SkillSystem.validate(3, thirteen).is_empty() and SkillSystem.validate(4, thirteen).is_empty(), "legacy twelve validates thirteen breaks three fits four")
	econ_session.state.skills = {}

func _test_local_capacity_validate() -> void:
	var roomed: GameState = econ_session.state.duplicate_state()
	roomed.skills = {"frontier_storekeeping": 2}
	roomed.economy.islands.deep = {"opened": true, "inventory": {"refined_iron": "450"}}
	expect(IslandProgression.capacity(roomed, "deep") == 500.0 and IslandEconomy.validate(roomed) == "", "frontier two expands deep to five hundred")
	var tight: GameState = econ_session.state.duplicate_state()
	tight.skills = {}
	tight.economy.islands.deep = {"opened": true, "inventory": {"refined_iron": "450"}}
	expect(IslandProgression.capacity(tight, "deep") == 300.0 and IslandEconomy.validate(tight) == "ECONOMY_LOCAL_AMOUNT", "base three hundred rejects four hundred fifty")

func _test_reincarnation() -> void:
	var session := GameSession.create_new_game(plain_content, 20261024)
	session.state.era_id = 4
	session.state.skills = {"golden_core_formation": 2, "heavenly_craft": 1, "nascent_soul_incubation": 2}
	session.state.buildings["rebirth_lotus"] = 1
	stock(session.state, "skill_point", 5000)
	var result: Dictionary = send(session, "reincarnate", {"mode": "normal"})
	expect(bool(result.get("ok", false)), "reincarnation accepted with p2 skills")
	expect(session.state.skills.is_empty() and int(session.state.skill_version) == 4, "observed contract skills clear while skill_version stays four")
	expect(int(session.state.reincarnation_count) == 1 and session.state.era_id == 1, "new life count and era reset")
	expect(session.state.resources.skill_point.value.to_float() == 0.0 and not session.state.resources.skill_point.unlocked, "skill point returns locked and zero")
