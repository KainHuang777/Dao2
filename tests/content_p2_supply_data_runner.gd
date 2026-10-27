extends SceneTree
## R46 first implementation stage: isolated data contract, no release activation.
const Supply = preload("res://src/content/supply_content.gd")
var checks := 0
var failures: Array[String] = []

func _init() -> void:
	var base: GameContent = ContentLoader.load_directory("res://content").content
	var attached := IslandProgression.attach(base)
	_expect(attached.ok, "existing release attach")
	var before := _snapshot(base)
	var prepared: Dictionary = Supply.prepare(base)
	_expect(prepared.ok, "candidate content builds: " + str(prepared.get("errors", [])))
	if prepared.ok:
		_test_content(base, prepared.content, prepared.data)
		_test_rejections(prepared.content.processing_catalog)
	_expect(_snapshot(base) == before, "candidate preparation never mutates release content")
	_expect(base.era(4) == null, "no premature Era4 release before economy migration")
	var report := {"level": "L1", "stage": "SUPPLY-1 data contract", "checks": checks, "failures": failures}
	var dir := RunnerResult.output_path("res://docs/verification/artifacts/content-p2-supply")
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir + "/data-contract.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t"))
	for failure in failures: push_error(failure)
	print("%s: CONTENT-P2-SUPPLY data %d checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func _snapshot(content: GameContent) -> String:
	return JSON.stringify([content.resources, content.buildings, content.eras, content.processing_catalog, content.skill_defs, content.content_version])

func _test_content(base: GameContent, candidate: GameContent, data: Dictionary) -> void:
	var catalog := candidate.processing_catalog
	_expect(catalog.resources.size() == 22 and catalog.recipes.size() == 11, "22 resources / 11 recipes; no phantom bulk inventory")
	_expect(not catalog.resources.has("stone_mid_bulk"), "bulk recipe is not another stock")
	_expect(ProcessingCatalog.product_id(catalog, "stone_mid_bulk") == "stone_mid", "bulk product aliases canonical mid-stone")
	for id in base.processing_catalog.recipes:
		_expect(catalog.recipes[id] == base.processing_catalog.recipes[id], "old recipe unchanged " + id)
	for id in base.resources:
		_expect(candidate.resources[id] == base.resources[id], "existing resource unchanged " + id)
	for id in base.buildings:
		_expect(candidate.buildings[id] == base.buildings[id], "existing building unchanged " + id)
	for id in base.eras:
		_expect(candidate.eras[id] == base.eras[id], "existing era unchanged " + str(id))
	_expect(candidate.skill_defs == base.skill_defs, "P1 skills unchanged; no unapproved P2 skill")
	_expect(candidate.era(7) == null, "Era7 unavailable")
	var proposal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/design-data/res1-e-46-proposal.json"))
	for r in proposal.resources:
		_expect(candidate.resources[r.id].max == r.home_cap, "home capacity " + r.id)
		_expect(candidate.resources[r.id].rate == 0, "no free ancestral production " + r.id)
	for e in proposal.eras:
		var definition: Dictionary = candidate.era(int(e.id))
		_expect(definition.level_up_requirements.base_time == e.base_time and definition.level_up_requirements.time_multiplier == e.time_multiplier, "approved raw cultivation " + str(e.id))
		_expect(definition.lifespan == e.lifespan and definition.resource_multiplier == e.resource_multiplier, "approved lifespan / multiplier " + str(e.id))
		for level in range(1, 10):
			var costs := Cultivation.level_up_cost(definition, level, 0)
			for id in e.cost:
				_expect(costs[id].to_float() == e.cost[id], "approved level cost %s/%d/%s" % [e.id, level, id])
			_expect(costs.has(e.lv9.id) == (level == 9), "lv9-only item %s/%d" % [e.id, level])
	var buildings := {}
	for facility in proposal.facilities:
		buildings[facility.id] = 1
		var definition: Dictionary = candidate.buildings[facility.id]
		_expect(definition.base_cost == facility.cost and definition.max_level == 1 and definition.cost_factor == 1, "approved engineering cost " + facility.id)
		if not facility.requires.is_empty():
			_expect(definition.prereq.building == facility.requires.keys()[0] and definition.prereq.level == facility.requires.values()[0], "approved preceding facility " + facility.id)
	var rates := Production.compute_rates(candidate, buildings)
	var empty_rates := Production.compute_rates(candidate, {})
	for pair in [["lingli", 600.0], ["money", 170.0], ["stone_low", 20.0]]:
		_expect(is_equal_approx(rates[pair[0]].to_float() - empty_rates[pair[0]].to_float(), pair[1]), "flat additive base production " + pair[0])
	var artisan_rates := Production.compute_rates(candidate, buildings, 1, {}, {"artisan_past_wisdom": 5})
	for id in rates:
		_expect(is_equal_approx(artisan_rates[id].to_float(), rates[id].to_float()), "new producers excluded from artisan whitelist " + id)
	var caps := Production.compute_caps(candidate, buildings, 5, 1)
	var empty_caps := Production.compute_caps(candidate, {}, 5, 1)
	for pair in [["lingli", 260000], ["stone_low", 125000], ["money", 130000], ["skill_point", 80000]]:
		_expect(caps[pair[0]].to_float() - empty_caps[pair[0]].to_float() == pair[1], "additive capacities " + pair[0])
	for era in [3, 4, 5]:
		var built := {}
		for id in candidate.buildings:
			if id.begins_with("core_storehouse_") and candidate.buildings[id].era <= era: built[id] = 1
		var available := Production.compute_caps(candidate, built, era, 1)
		for id in candidate.era(era).upgrade_requirements.capacity:
			_expect(available[id].to_float() >= candidate.era(era).upgrade_requirements.capacity[id], "preceding-era capacity bootstrap %d/%s" % [era, id])
	_expect(data.islands.size() == 3 and data.routes.size() == 5, "three islands / five routes")
	for island in proposal.islands:
		_expect(data.islands[island.id].rates == island.rates and data.islands[island.id].cost == island.cost and data.islands[island.id].local_cap == 300, "approved local economy " + island.id)
	for id in data.routes:
		_expect(data.routes[id][1] == "home" and catalog.resources.has(data.routes[id][2]), "single return route " + id)
	_expect(data.route_policy.seconds == 10 and data.route_policy.cargo_per_level == 10 and data.route_policy.max_level == 3 and data.route_policy.enabled == false and data.route_policy.target == "100", "route policy has no automatic free opening")
	_expect(Supply.prepare(base).content.content_version == candidate.content_version, "deterministic complete content identity")
	_expect(not Supply.prepare(candidate).ok, "reject duplicate attach instead of silently changing definitions")

func _test_rejections(catalog: Dictionary) -> void:
	for field in ["ghost", null, 42]:
		var bad := catalog.duplicate(true)
		bad.recipes.stone_mid_bulk.product = field
		_expect(not ProcessingCatalog.validate(bad).ok, "invalid product rejects " + str(field))
	var future := catalog.duplicate(true)
	future.recipes.stone_mid_bulk.inputs = {"void_essence": "1"}
	_expect(not ProcessingCatalog.validate(future).ok, "bulk recipe cannot borrow future-era supply")
	var cycle := catalog.duplicate(true)
	cycle.recipes.stone_mid.inputs = {"stone_high": "1"}
	cycle.recipes.stone_mid_bulk.inputs = {"stone_high": "1"}
	_expect(not ProcessingCatalog.validate(cycle).ok, "product aliases cannot conceal dependency cycles")
	var blocked := catalog.duplicate(true)
	blocked.recipes.stone_mid_bulk.inputs = {"trans_pill": "1"}
	_expect(not ProcessingCatalog.validate(blocked).ok, "reachable product does not bypass an unreachable alternate recipe")
	var version := catalog.duplicate(true)
	version.version = "future"
	_expect(not ProcessingCatalog.validate(version).ok, "unknown profile rejects")
	var multi := {"id": "invalid_flat", "era": 4, "max_level": 2, "base_cost": {}, "prereq": null, "effects": {"lingli": 100}, "effect_weight": null}
	var resource := [{"id": "lingli", "type": "basic", "rate": 0, "max": 1, "unlocked": true}]
	_expect(not ContentLoader.build_content(resource, [multi]).ok, "null-weight flat producer remains single-level only")
	multi.max_level = 1.5
	_expect(not ContentLoader.build_content(resource, [multi]).ok, "fractional cap cannot masquerade as a flat singleton")

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)
