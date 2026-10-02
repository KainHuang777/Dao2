extends SceneTree

const FIXTURE_PATH := "res://tests/fixtures/legacy/m0-b-v1.json"
const CONTENT_DIR := "res://content"

var failures: Array[String] = []
var _content: GameContent

func _init() -> void:
	_test_content_load()
	_test_content_validation()
	_test_cost_parity()
	_test_onboarding_parity()
	_test_new_game_blank_state()
	_test_gather()
	_test_upgrade()
	_test_level_caps()
	_test_idempotency()
	_test_stale_revision()
	_test_invalid_commands()
	_test_determinism()
	_test_rates_and_caps()
	if failures.is_empty():
		print("PASS: M1-A core contract, content validation, cost/onboarding parity, commands, idempotency, determinism.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_content_load() -> void:
	var loaded := ContentLoader.load_directory(CONTENT_DIR)
	_expect(bool(loaded.ok), "content loads from directory")
	if not bool(loaded.ok):
		_report_errors(loaded.errors, "content load")
		return
	_content = loaded.content
	_expect(_content.content_version.length() == 64, "content version is sha256 hex")
	var again := ContentLoader.load_directory(CONTENT_DIR)
	_expect(bool(again.ok) and String(again.content.content_version) == _content.content_version, "content version is stable across loads")
	_expect_equal(_content.resource_ids, ["lingli", "money", "wood", "stone_low", "black_copper", "spirit_grass_low", "foundation_pill", "skill_point", "spirit_rice", "refined_iron", "beast_hide_low", "beast_bone_low", "beast_crystal_low", "bronze_essence", "monster_core_low", "liquid"], "resource ids in declaration order")
	_expect_equal(_content.building_ids, ["hut", "wooden_house", "storage_lingli", "storage_money", "forest_farm", "stone_mine", "storage_stone", "herb_farm", "storage_wood", "storage_herb", "iron_mine", "hunter_camp", "rice_field", "library", "scripture_hall", "stone_mine_mid", "storage_lingli_mid", "storage_stone_mid", "storage_money_mid", "storage_wood_mid", "storage_herb_mid"], "building ids in declaration order")
	_expect_equal(_content.buildings.hut.cost_factor, 1.5, "hut cost factor")
	_expect_equal(_content.buildings.hut.base_cost, {"lingli": 20.0}, "hut base cost")
	_expect_equal(_content.resources.foundation_pill.type, "crafted", "foundation_pill type")

func _test_content_validation() -> void:
	var resources := _valid_resources()
	var hut := {
		"id": "hut", "era": 1, "max_level": 2, "cost_factor": 1.5, "prereq": null,
		"base_cost": {"lingli": 20}, "effect_weight": 1, "effects": {"lingli": 0.3},
	}
	_expect_rejection(_build_with(resources, [_with_cost(hut, {"void_res": 10})]), "void_res", "unknown cost resource is located")
	_expect_rejection(_build_with(resources, [_with_prereq(hut, "ghost_tower", 2)]), "ghost_tower", "unknown prereq target is located")
	_expect_rejection(_build_with(resources, [_with_effects(hut, {"void_effect": 1})]), "void_effect", "unknown effect key is located")
	var no_weight := {
		"id": "hut", "era": 1, "max_level": 2, "cost_factor": 1.5, "prereq": null,
		"base_cost": {"lingli": 20}, "effect_weight": null, "effects": {"lingli": 0.3},
	}
	_expect_rejection(_build_with(resources, [no_weight]), "effect_weight is required", "rate effect without weight is rejected")
	_expect_rejection(_build_with(resources, [hut, hut.duplicate(true)]), "duplicate building id", "duplicate building id is rejected")
	var tower_a := _with_prereq(hut.duplicate(true), "tower_b", 1)
	tower_a.id = "tower_a"
	var tower_b := _with_prereq(hut.duplicate(true), "tower_a", 1)
	tower_b.id = "tower_b"
	_expect_rejection(_build_with(resources, [tower_a, tower_b]), "prereq cycle detected: tower_a -> tower_b -> tower_a", "prereq cycle is located")

func _test_cost_parity() -> void:
	var fixture: Dictionary = _fixture()
	var inputs: Dictionary = fixture.inputs.building_cost
	var expected: Dictionary = fixture.expected.building_cost
	var base_cost: Dictionary = inputs.base_cost
	for level in inputs.levels:
		var costs := BuildingCosts.compute_cost(base_cost, int(level), 1.15)
		var expected_costs: Dictionary = expected["level_%d" % int(level)]
		for resource_id in expected_costs:
			_expect_equal(costs[resource_id].serialize(), String(expected_costs[resource_id]), "cost parity level %d %s" % [int(level), resource_id])
	var discounted: Dictionary = inputs.discounted
	var discounted_costs := BuildingCosts.compute_cost(base_cost, int(discounted.level), float(discounted.cost_factor), float(discounted.cost_reduction), int(discounted.intuition_level))
	var expected_discounted: Dictionary = expected.level_51_discounted
	for resource_id in expected_discounted:
		_expect_equal(discounted_costs[resource_id].serialize(), String(expected_discounted[resource_id]), "cost parity level 51 discounted %s" % resource_id)

func _test_onboarding_parity() -> void:
	var expected: Dictionary = _fixture().expected.onboarding
	var cases := {
		"new_game": {},
		"hut_2": {"hut": 2},
		"early_chain": {"hut": 2, "wooden_house": 2, "forest_farm": 3, "stone_mine": 3, "herb_farm": 3},
	}
	for case_name in cases:
		var state := Onboarding.unlock_state(1, 1, cases[case_name])
		var expected_state: Dictionary = expected[case_name]
		_expect_equal(state.active, bool(expected_state.isOnboardingActive), "onboarding active %s" % case_name)
		var expected_resources: Array = expected_state.resourceIds.duplicate()
		if case_name == "early_chain":
			expected_resources.insert(expected_resources.find("stone_low") + 1, "black_copper")
		_expect_equal(state.resources, expected_resources, "onboarding resources %s" % case_name)
		_expect_equal(state.buildings, expected_state.visibleBuildingIds, "onboarding buildings %s" % case_name)
		_expect_equal(state.next_objective, expected_state.nextObjective, "onboarding objective %s" % case_name)
	var inactive_era := Onboarding.unlock_state(2, 1, {})
	_expect(not inactive_era.active and inactive_era.resources.is_empty() and inactive_era.buildings.is_empty(), "onboarding inactive above era 1")
	var inactive_version := Onboarding.unlock_state(1, 0, {})
	_expect(not inactive_version.active, "onboarding inactive below schema version")

func _test_new_game_blank_state() -> void:
	var session := _new_session()
	var view := session.get_view()
	_expect_equal(session.state.revision, 0, "new game revision is zero")
	_expect_equal(session.state.era_id, 1, "new game era")
	_expect_equal(session.state.onboarding_version, 1, "new game onboarding version")
	for resource_id in view.resources:
		_expect_equal(view.resources[resource_id].value, "0", "new game %s starts at zero" % resource_id)
		_expect_equal(view.resources[resource_id].rate, "0", "new game %s has no rate" % resource_id)
	_expect_equal(view.resources.lingli.cap, "100", "new game lingli cap")
	_expect_equal(view.resources.money.cap, "200", "new game money cap")
	_expect_equal(bool(view.resources.lingli.unlocked), true, "new game lingli unlocked")
	for resource_id in ["money", "wood", "stone_low", "black_copper", "spirit_grass_low", "foundation_pill"]:
		_expect_equal(bool(view.resources[resource_id].unlocked), false, "new game %s locked" % resource_id)
	for building_id in view.buildings:
		_expect_equal(view.buildings[building_id].level, 0, "new game %s level zero" % building_id)
	_expect_equal(bool(view.buildings.hut.visible), true, "new game hut visible")
	for building_id in ["wooden_house", "storage_lingli", "storage_money", "forest_farm", "stone_mine", "storage_stone", "herb_farm", "storage_wood", "storage_herb"]:
		_expect_equal(bool(view.buildings[building_id].visible), false, "new game %s hidden" % building_id)
	_expect_equal(view.buildings.hut.costs, {"lingli": "20"}, "new game hut costs come from the core")
	_expect_equal(bool(view.buildings.hut.affordable), false, "new game hut not affordable")
	_expect_equal(view.next_objective, {"kind": "building", "id": "hut"}, "new game objective")

func _test_gather() -> void:
	var session := _new_session()
	var first := session.submit(_gather("g1", "lingli", 0))
	_expect(bool(first.ok), "gather lingli succeeds")
	_expect_equal(int(first.new_revision), 1, "gather bumps revision")
	_expect_equal(session.state.resources.lingli.value.serialize(), "1", "gather adds one")
	_expect_equal(bool(session.state.resources.lingli.ever_obtained), true, "gather marks ever obtained")
	var locked := session.submit(_gather("g2", "money", 1))
	_expect_equal(locked.error, "RESOURCE_LOCKED", "gather locked resource rejected")
	_expect_equal(int(locked.new_revision), 1, "failed gather keeps revision")
	var unknown := session.submit(_gather("g3", "void", 1))
	_expect_equal(unknown.error, "UNKNOWN_RESOURCE", "gather unknown resource rejected")
	var crafted_pill := session.submit(_gather("g6", "foundation_pill", 1))
	_expect_equal(crafted_pill.error, "NOT_BASIC_RESOURCE", "gather crafted resource rejected")
	var crafted_session := GameSession.create_new_game(_crafted_content())
	var not_basic := crafted_session.submit(_gather("cp1", "pill", 0))
	_expect_equal(not_basic.error, "NOT_BASIC_RESOURCE", "gather unlocked crafted resource rejected")
	_set_resource(session, "lingli", 99.0)
	var clamped := session.submit(_gather("g4", "lingli", 1))
	_expect(bool(clamped.ok), "gather near cap succeeds")
	_expect_equal(session.state.resources.lingli.value.serialize(), "100", "gather clamps to cap")
	var at_cap := session.submit(_gather("g5", "lingli", 2))
	_expect(bool(at_cap.ok), "gather at cap still succeeds")
	_expect_equal(session.state.resources.lingli.value.serialize(), "100", "gather at cap stays at cap")

func _test_upgrade() -> void:
	var session := _new_session()
	var locked_visibility := session.submit(_upgrade("u0", "wooden_house", 0))
	_expect_equal(locked_visibility.error, "BUILDING_LOCKED", "upgrade hidden building rejected")
	var locked_storage := session.submit(_upgrade("u0b", "storage_money", 0))
	_expect_equal(locked_storage.error, "BUILDING_LOCKED", "upgrade prereq-free hidden building rejected")
	var unknown := session.submit(_upgrade("u0c", "castle", 0))
	_expect_equal(unknown.error, "UNKNOWN_BUILDING", "upgrade unknown building rejected")
	var era_session := GameSession.create_new_game(_crafted_content())
	var era_result := era_session.submit(_upgrade("e1", "observatory", 0))
	_expect_equal(era_result.error, "ERA_REQUIREMENT", "upgrade future-era building rejected")
	_set_resource(session, "lingli", 20.0)
	var first := session.submit(_upgrade("u1", "hut", 0))
	_expect(bool(first.ok), "hut upgrade 0 to 1 succeeds")
	_expect_equal(int(session.state.buildings.hut), 1, "hut level 1")
	_expect_equal(session.state.resources.lingli.value.serialize(), "0", "hut upgrade pays 20 lingli")
	_expect_equal(bool(session.state.resources.money.unlocked), true, "hut 1 unlocks money")
	_expect_equal(bool(session.state.resources.wood.unlocked), true, "hut 1 unlocks wood")
	_expect_equal(first.changed_ids, ["hut", "money", "wood"], "hut 1 changed ids")
	_expect_equal(session.get_view().resources.lingli.cap, "250", "hut 1 lingli cap")
	var wh_locked := session.submit(_upgrade("u2", "wooden_house", 1))
	_expect_equal(wh_locked.error, "BUILDING_LOCKED", "wooden_house hidden below hut 2")
	_set_resource(session, "lingli", 31.0)
	var second := session.submit(_upgrade("u3", "hut", 1))
	_expect(bool(second.ok), "hut upgrade 1 to 2 succeeds")
	_expect_equal(int(session.state.buildings.hut), 2, "hut level 2")
	_expect_equal(session.state.resources.lingli.value.serialize(), "0", "hut upgrade 1 to 2 pays 31 lingli")
	_expect_equal(second.changed_ids, ["hut", "wooden_house", "storage_lingli", "storage_money"], "hut 2 changed ids")
	_expect_equal(session.get_view().next_objective, {"kind": "building", "id": "wooden_house"}, "objective after hut 2")
	var capped := session.submit(_upgrade("u4", "hut", 2))
	_expect_equal(capped.error, "LEVEL_CAP", "hut upgrade beyond max level rejected")
	var prereq := session.submit(_upgrade("u5", "storage_lingli", 2))
	_expect_equal(prereq.error, "PREREQ_UNSATISFIED", "storage_lingli prereq unsatisfied")
	_expect(prereq.detail.prereq_building == "herb_farm" and int(prereq.detail.prereq_level) == 3, "prereq failure is located")
	var insufficient := session.submit(_upgrade("u6", "wooden_house", 2))
	_expect_equal(insufficient.error, "INSUFFICIENT_RESOURCE", "wooden_house unaffordable rejected")
	_expect_equal(int(insufficient.new_revision), 2, "failed upgrade keeps revision")
	_set_resource(session, "money", 20.0)
	_set_resource(session, "lingli", 30.0)
	var built := session.submit(_upgrade("u7", "wooden_house", 2))
	_expect(bool(built.ok), "wooden_house upgrade succeeds when paid")
	_expect_equal(int(session.state.buildings.wooden_house), 1, "wooden_house level 1")
	_expect_equal(session.state.resources.money.value.serialize(), "0", "wooden_house pays 20 money")
	_expect_equal(session.state.resources.lingli.value.serialize(), "0", "wooden_house pays 30 lingli")
	_expect_equal(session.get_view().next_objective, {"kind": "building", "id": "wooden_house"}, "objective still wooden_house at level 1")

func _test_level_caps() -> void:
	var session := _new_session()
	var view := session.get_view()
	_expect_equal(int(view.buildings.hut.level_cap), 2, "hut level cap is max_level 2")
	_expect_equal(int(view.buildings.wooden_house.level_cap), 10, "wooden_house level cap is global 10")
	_expect_equal(int(view.buildings.forest_farm.level_cap), 10, "forest_farm level cap is global 10")
	_expect_equal(int(view.buildings.storage_money.level_cap), 10, "storage_money level cap is global 10")
	session.state.buildings.wooden_house = 10
	var capped := session.submit(_upgrade("cap1", "wooden_house", 0))
	_expect_equal(capped.error, "LEVEL_CAP", "upgrade at global level cap rejected")
	var capped_view := session.get_view()
	_expect_equal(capped_view.buildings.wooden_house.costs, {}, "no costs shown at level cap")
	_expect_equal(bool(capped_view.buildings.wooden_house.affordable), false, "not affordable at level cap")

func _test_idempotency() -> void:
	var session := _new_session()
	var first := session.submit(_gather("dup1", "lingli", 0))
	_expect(bool(first.ok), "original gather succeeds")
	var retry := session.submit(_gather("dup1", "lingli", 0))
	_expect(bool(retry.ok) and bool(retry.duplicate), "duplicate gather reports duplicate")
	_expect_equal(int(retry.new_revision), 1, "duplicate keeps revision")
	_expect_equal(session.state.resources.lingli.value.serialize(), "1", "duplicate does not gather again")
	var second := session.submit(_gather("dup2", "lingli", 1))
	_expect(bool(second.ok), "next gather succeeds")
	_expect_equal(session.state.resources.lingli.value.serialize(), "2", "next gather adds one")
	var stale_retry := session.submit(_gather("dup1", "lingli", 0))
	_expect(bool(stale_retry.ok) and bool(stale_retry.duplicate), "stale duplicate is duplicate not stale")
	_expect_equal(session.state.resources.lingli.value.serialize(), "2", "stale duplicate does not gather again")
	_set_resource(session, "lingli", 20.0)
	var upgrade := session.submit(_upgrade("dup3", "hut", 2))
	_expect(bool(upgrade.ok), "upgrade succeeds before duplicate retry")
	var upgrade_retry := session.submit(_upgrade("dup3", "hut", 2))
	_expect(bool(upgrade_retry.ok) and bool(upgrade_retry.duplicate), "duplicate upgrade reports duplicate")
	_expect_equal(int(session.state.buildings.hut), 1, "duplicate upgrade does not level twice")
	_expect_equal(session.state.resources.lingli.value.serialize(), "0", "duplicate upgrade does not charge twice")

func _test_stale_revision() -> void:
	var session := _new_session()
	session.submit(_gather("s0", "lingli", 0))
	var stale := session.submit(_gather("s1", "lingli", 99))
	_expect_equal(stale.error, "STALE_REVISION", "stale revision rejected")
	_expect_equal(int(stale.new_revision), 1, "stale revision keeps revision")
	_expect_equal(session.state.resources.lingli.value.serialize(), "1", "stale revision does not gather")

func _test_invalid_commands() -> void:
	var session := _new_session()
	_expect_equal(session.submit({}).error, "INVALID_COMMAND", "empty command rejected")
	_expect_equal(session.submit({"command_id": "", "type": "gather", "payload": {"resource_id": "lingli"}, "expected_revision": 0}).error, "INVALID_COMMAND", "empty command id rejected")
	_expect_equal(session.submit({"command_id": "x1", "type": "dance", "payload": {}, "expected_revision": 0}).error, "UNKNOWN_COMMAND", "unknown type rejected")
	_expect_equal(session.submit({"command_id": "x2", "type": "gather", "payload": {}, "expected_revision": 0}).error, "INVALID_COMMAND", "gather without resource id rejected")
	_expect_equal(session.submit({"command_id": "x3", "type": "gather", "payload": {"resource_id": "lingli"}, "expected_revision": "zero"}).error, "INVALID_COMMAND", "non-numeric revision rejected")
	_expect_equal(int(session.state.revision), 0, "invalid commands keep revision")

func _test_determinism() -> void:
	var first := _new_session()
	var second := _new_session()
	for session in [first, second]:
		for index in range(20):
			session.submit(_gather("d%d" % index, "lingli", index))
		session.submit(_upgrade("d20", "hut", 20))
		session.submit(_upgrade("d20", "hut", 20))
		for index in range(31):
			session.submit(_gather("e%d" % index, "lingli", 21 + index))
		session.submit(_upgrade("e31", "hut", 52))
		session.submit(_upgrade("e32", "wooden_house", 53))
		session.submit(_gather("e33", "lingli", 99))
	_expect_equal(first.state.to_snapshot_dict(), second.state.to_snapshot_dict(), "same commands produce same snapshot")
	_expect_equal(first.get_view(), second.get_view(), "same commands produce same view")

func _test_rates_and_caps() -> void:
	var session := _new_session()
	_set_resource(session, "lingli", 20.0)
	session.submit(_upgrade("r1", "hut", 0))
	var view := session.get_view()
	var lingli_rate: AmountCompat = AmountCompat.try_parse(view.resources.lingli.rate).value
	_expect(lingli_rate.compare_to(AmountCompat.from_number(0.84)) > 0, "hut 1 lingli rate above 0.84")
	_expect(lingli_rate.compare_to(AmountCompat.from_number(0.85)) < 0, "hut 1 lingli rate below 0.85")
	_expect_equal(view.resources.lingli.cap, "250", "hut 1 lingli cap")
	_expect_equal(view.resources.money.rate, "0", "unbuilt money rate is zero")
	var built := _new_session()
	built.state.buildings.hut = 2
	built.state.buildings.wooden_house = 1
	var built_view := built.get_view()
	var money_rate: AmountCompat = AmountCompat.try_parse(built_view.resources.money.rate).value
	_expect(money_rate.compare_to(AmountCompat.from_number(1.03)) > 0, "wooden_house 1 money rate above 1.03")
	_expect(money_rate.compare_to(AmountCompat.from_number(1.04)) < 0, "wooden_house 1 money rate below 1.04")
	_expect_equal(built_view.resources.money.cap, "250", "wooden_house 1 money cap")
	_expect_equal(built_view.resources.lingli.cap, "400", "hut 2 lingli cap")
	var rates := Production.compute_rates(built.content, built.state.buildings)
	var direct_rate: AmountCompat = AmountCompat.try_parse(rates.lingli.serialize()).value
	_expect(direct_rate.compare_to(AmountCompat.from_number(1.5588)) > 0, "hut 2 rate formula lower bound")
	_expect(direct_rate.compare_to(AmountCompat.from_number(1.5589)) < 0, "hut 2 rate formula upper bound")
	var caps := Production.compute_caps(built.content, built.state.buildings, built.state.era_id, built.state.onboarding_version)
	_expect_equal(caps.lingli.serialize(), "400", "caps API hut 2")

func _valid_resources() -> Array:
	return [
		{"id": "lingli", "type": "basic", "max": 100, "rate": 0, "unlocked": true},
		{"id": "money", "type": "basic", "max": 200, "rate": 0, "unlocked": true},
		{"id": "wood", "type": "basic", "max": 100, "rate": 0, "unlocked": true},
		{"id": "stone_low", "type": "basic", "max": 100, "rate": 0, "unlocked": true},
	]

func _crafted_content() -> GameContent:
	var resources := _valid_resources()
	resources.append({"id": "pill", "type": "crafted", "max": 200, "rate": 0, "unlocked": true})
	var buildings := [
		{"id": "hut", "era": 1, "max_level": 2, "cost_factor": 1.5, "prereq": null, "base_cost": {"lingli": 20}, "effect_weight": 1, "effects": {"lingli": 0.3}},
		{"id": "observatory", "era": 2, "max_level": 10, "cost_factor": 1.5, "prereq": null, "base_cost": {"money": 10}, "effect_weight": 1, "effects": {"money": 0.1}},
	]
	var built := ContentLoader.build_content(resources, buildings)
	_expect(bool(built.ok), "crafted content builds")
	return built.content

func _build_with(resources: Array, buildings: Array) -> Dictionary:
	return ContentLoader.build_content(resources, buildings)

func _with_cost(base: Dictionary, cost: Dictionary) -> Dictionary:
	var copy := base.duplicate(true)
	copy.base_cost = cost
	return copy

func _with_prereq(base: Dictionary, building_id: String, level: int) -> Dictionary:
	var copy := base.duplicate(true)
	copy.prereq = {"building": building_id, "level": level}
	return copy

func _with_effects(base: Dictionary, effects: Dictionary) -> Dictionary:
	var copy := base.duplicate(true)
	copy.effects = effects
	return copy

func _expect_rejection(result: Dictionary, token: String, label: String) -> void:
	_expect(not bool(result.ok), "%s rejects" % label)
	var found := false
	if result.has("errors"):
		for error in result.errors:
			if String(error).contains(token):
				found = true
	_expect(found, "%s names the problem (%s)" % [label, token])

func _report_errors(errors: Array, label: String) -> void:
	for error in errors:
		failures.append("%s error: %s" % [label, String(error)])

func _new_session() -> GameSession:
	return GameSession.create_new_game(_main_content())

func _main_content() -> GameContent:
	if _content == null:
		var loaded := ContentLoader.load_directory(CONTENT_DIR)
		if bool(loaded.ok):
			_content = loaded.content
		else:
			failures.append("content failed to load before session tests")
			_report_errors(loaded.errors, "content load")
			_content = _fallback_content()
	return _content

func _fallback_content() -> GameContent:
	var built := ContentLoader.build_content(_valid_resources(), [])
	return built.content

func _set_resource(session: GameSession, resource_id: String, value: float) -> void:
	session.state.resources[resource_id].value = AmountCompat.from_number(value)

func _gather(command_id: String, resource_id: String, revision: int) -> Dictionary:
	return {"command_id": command_id, "type": "gather", "payload": {"resource_id": resource_id}, "expected_revision": revision}

func _upgrade(command_id: String, building_id: String, revision: int) -> Dictionary:
	return {"command_id": command_id, "type": "upgrade_building", "payload": {"building_id": building_id}, "expected_revision": revision}

func _fixture() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s; expected=%s actual=%s" % [label, str(expected), str(actual)])
