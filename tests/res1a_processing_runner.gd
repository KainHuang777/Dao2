extends SceneTree

var failures: Array[String] = []
var checks := 0
var catalog: Dictionary

func _init() -> void:
	var loaded := ProcessingCatalog.load_file()
	_expect(loaded.ok, "catalog loads")
	if not loaded.ok:
		print(loaded.errors)
		quit(1)
		return
	catalog = loaded.catalog
	_test_sources()
	_test_content_rejection()
	_test_recipes()
	_test_rejections()
	_test_chains()
	_test_session()
	if failures.is_empty():
		print("PASS: RES1-A %d checks; sources, closure, atomic Craft, canonical inventory, Amount, Session replay." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _session() -> GameSession:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	content.processing_catalog = catalog.duplicate(true)
	var session := GameSession.create_new_game(content)
	session.state.era_id = 3
	session.state.buildings = {"hut": 2, "herb_farm": 3, "stone_mine": 3}
	for id in catalog.resources:
		session.state.resources[id] = {"value": AmountCompat.zero(), "unlocked": true, "ever_obtained": false}
	return session

func _put(state: GameState, id: String, raw: String) -> void:
	ProcessingInventory.write(state, id, AmountCompat.try_parse(raw).value)

func _value(state: GameState, id: String) -> String:
	return state.resources[id].value.serialize()

func _command(session: GameSession, id: String, count: Variant = 1, command_id: String = "test") -> Dictionary:
	return session.submit({"command_id": command_id, "expected_revision": session.state.revision, "type": "craft", "payload": {"recipe_id": id, "count": count, "recipe_version": 1}})

func _test_sources() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/legacy/res1-a-source.json"))
	for row in fixture.resources:
		if not row.recipe.is_empty() and row.id != "foundation_pill":
			for input in row.recipe:
				_expect(catalog.recipes[row.id].inputs[input] == str(int(row.recipe[input])), "CSV ratio %s %s" % [row.id, input])
	_expect(catalog.recipes.foundation_pill.inputs.spirit_grass_low == "50", "foundation preserves current v2 cost")
	_expect(catalog.resources.spirit_grass_100y.legacy_skill == "golden_core_formation", "legacy herb skill retained in evidence")
	_expect(fixture.era_requirements[2].lv9_item_type == "talisman", "Era3 Lv9 sink grounded")
	_expect(catalog.recipes.size() == 8, "six sourced + two v2 recipes")

func _test_content_rejection() -> void:
	for bad in [null, [], {"resources": [], "recipes": {}}]:
		_expect(not ProcessingCatalog.validate(bad).ok, "malformed catalog rejects")
	var bad := catalog.duplicate(true)
	bad.recipes.liquid.inputs.ghost = "1"
	_expect(not ProcessingCatalog.validate(bad).ok, "missing reference rejects")
	bad = catalog.duplicate(true)
	bad.recipes.spirit_timber.inputs = {"formation_core": "1"}
	_expect(not ProcessingCatalog.validate(bad).ok, "cycle/future Era rejects")
	bad = catalog.duplicate(true)
	bad.recipes.liquid.inputs = {"stone_mid": "1"}
	_expect(not ProcessingCatalog.validate(bad).ok, "acyclic future dependency rejects")
	bad = catalog.duplicate(true)
	bad.recipes.liquid.facility = {"ghost": 1}
	_expect(not ProcessingCatalog.validate(bad).ok, "unknown facility rejects")
	bad = catalog.duplicate(true)
	bad.recipes.liquid.skills = {"unknown_skill": 1}
	_expect(not ProcessingCatalog.validate(bad).ok, "unsupported skill rejects")
	bad = catalog.duplicate(true)
	bad.recipes.liquid.facility = {}
	_expect(not ProcessingCatalog.validate(bad).ok, "missing facility rejects")
	for raw in ["NaN", "Infinity", "0", "-1", "ee20", "1e13", 1]:
		bad = catalog.duplicate(true)
		bad.recipes.liquid.inputs.lingli = raw
		_expect(not ProcessingCatalog.validate(bad).ok, "invalid content Amount %s" % str(raw))

func _fund_recipe(session: GameSession, id: String, count: int = 1) -> void:
	for input in catalog.recipes[id].inputs:
		var amount: AmountCompat = AmountCompat.try_parse(catalog.recipes[id].inputs[input]).value.multiply(AmountCompat.from_number(float(count)))
		_put(session.state, input, amount.serialize())

func _test_recipes() -> void:
	for id in catalog.recipes:
		var session := _session()
		_fund_recipe(session, id, 2)
		var result := _command(session, id, 2)
		_expect(result.ok, "recipe succeeds " + id)
		_expect(_value(session.state, id) == "2", "exact output " + id)
		for input in catalog.recipes[id].inputs:
			_expect(_value(session.state, input) == "0", "exact input deducted %s %s" % [id, input])
		_expect(session.state.revision == 1, "revision " + id)
		if id == "foundation_pill" or id == "golden_core_pill":
			_expect(int(session.state.pills.get("foundation_pill", 0)) == (2 if id == "foundation_pill" else 0), "foundation mirror synchronizes " + id)

func _reject_unchanged(session: GameSession, id: String, error: String, count: Variant = 1) -> void:
	var before := JSON.stringify(session.state.to_snapshot_dict())
	var result := _command(session, id, count)
	_expect(not result.ok and result.error == error, "%s rejection, got %s" % [error, str(result)])
	_expect(JSON.stringify(session.state.to_snapshot_dict()) == before, error + " leaves all state unchanged")

func _test_rejections() -> void:
	var session := _session()
	_reject_unchanged(session, "ghost", "UNKNOWN_RECIPE")
	for count in [0, -1, 1.5, "2", true, INF, NAN, 1000001, {}]:
		_reject_unchanged(session, "liquid", "INVALID_COUNT", count)
	_reject_unchanged(session, "liquid", "INSUFFICIENT_RESOURCE")
	_fund_recipe(session, "liquid")
	session.state.era_id = 1
	_reject_unchanged(session, "liquid", "ERA_REQUIREMENT")
	session.state.era_id = 3
	session.state.buildings.herb_farm = 2
	_reject_unchanged(session, "liquid", "FACILITY_REQUIREMENT")
	session.state.buildings.herb_farm = 3
	session.state.resources.lingli.unlocked = false
	_reject_unchanged(session, "liquid", "RESOURCE_LOCKED")
	session.state.resources.lingli.unlocked = true
	_put(session.state, "liquid", "1000000")
	_reject_unchanged(session, "liquid", "OUTPUT_FULL")
	_put(session.state, "liquid", "999999")
	_expect(_command(session, "liquid").ok, "exact cap succeeds")
	session = _session()
	_fund_recipe(session, "golden_core_pill")
	session.state.pills.foundation_pill = 6
	_reject_unchanged(session, "golden_core_pill", "INVENTORY_CONFLICT")
	_expect(not ProcessingInventory.read(session.state, "foundation_pill").ok, "conflict is not summed")
	session.state.pills.foundation_pill = 3
	_put(session.state, "lingli", "ee20")
	_reject_unchanged(session, "stone_mid", "UNSUPPORTED_AMOUNT")
	_put(session.state, "lingli", "1e6")
	_put(session.state, "stone_low", "5")
	_expect(_command(session, "stone_mid").ok, "supported scientific Amount succeeds")
	session = _session()
	_fund_recipe(session, "liquid")
	_put(session.state, "lingli", "49.999")
	_reject_unchanged(session, "liquid", "INSUFFICIENT_RESOURCE")
	_fund_recipe(session, "liquid", 10000)
	_put(session.state, "lingli", "499999.9")
	_reject_unchanged(session, "liquid", "INSUFFICIENT_RESOURCE", 10000)
	session.content.processing_catalog = {}
	_reject_unchanged(session, "liquid", "PROCESSING_NOT_ENABLED")

func _test_chains() -> void:
	var session := _session()
	# Reachability starts from declared T1 sources; never preloads crafted intermediates.
	for id in ["wood", "stone_low", "black_copper", "spirit_grass_low", "lingli", "spirit_grass_100y"]:
		_put(session.state, id, "10000")
	session.state.era_id = 1
	_expect(_command(session, "foundation_pill", 3, "foundation").ok, "Era1 foundation bootstraps")
	session.state.era_id = 2
	_expect(_command(session, "bronze_essence", 2, "bronze").ok, "Era2 bronze bootstraps")
	_expect(_command(session, "spirit_timber", 2, "timber").ok, "Era2 timber bootstraps")
	_expect(_command(session, "liquid", 1, "liquid").ok, "Era2 liquid bootstraps")
	_reject_unchanged(session, "formation_core", "ERA_REQUIREMENT")
	session.state.era_id = 3
	_expect(_command(session, "formation_core", 1, "core").ok, "T2 to T3 chain")
	_expect(_value(session.state, "spirit_timber") == "0" and _value(session.state, "bronze_essence") == "0", "T2 has actual recipe sink")
	_expect(_command(session, "stone_mid", 5, "mid").ok, "Era3 mid chain")
	_expect(_command(session, "golden_core_pill", 1, "golden").ok, "foundation to golden chain")
	_expect(_value(session.state, "foundation_pill") == "0" and _value(session.state, "stone_mid") == "0", "crafted inputs consumed once")
	_expect(_command(session, "talisman", 1, "talisman").ok, "Era3 special material chain")

func _test_session() -> void:
	var session := _session()
	_fund_recipe(session, "liquid")
	_expect(_command(session, "liquid", 1, "same").ok, "Session success")
	var before := JSON.stringify(session.state.to_snapshot_dict())
	var replay := _command(session, "liquid", 1, "same")
	_expect(replay.ok and replay.duplicate, "same command replay")
	_expect(JSON.stringify(session.state.to_snapshot_dict()) == before, "replay no deduction")
	var stale := session.submit({"command_id": "stale", "type": "craft", "expected_revision": 0, "payload": {"recipe_id": "liquid"}})
	_expect(not stale.ok and stale.error == "STALE_REVISION", "stale revision rejects")
	_expect(JSON.stringify(session.state.to_snapshot_dict()) == before, "stale unchanged")
	var result := session.submit({"command_id": "version", "type": "craft", "expected_revision": session.state.revision, "payload": {"recipe_id": "liquid", "recipe_version": 99}})
	_expect(not result.ok and result.error == "RECIPE_VERSION_MISMATCH", "unknown version rejects")
	_expect(JSON.stringify(session.state.to_snapshot_dict()) == before, "version unchanged")
	var clone := session.state.duplicate_state()
	clone.resources.liquid.value = AmountCompat.zero()
	_expect(_value(session.state, "liquid") == "1", "Amount copy does not alias")
	var second := _session()
	_fund_recipe(second, "liquid")
	var first := _session()
	_fund_recipe(first, "liquid")
	_expect(_command(first, "liquid").ok and _command(second, "liquid").ok, "deterministic pair succeeds")
	_expect(JSON.stringify(first.state.to_snapshot_dict()) == JSON.stringify(second.state.to_snapshot_dict()), "same state and command produce same snapshot")
	var released := GameSession.create_new_game(ContentLoader.load_directory("res://content").content)
	_reject_unchanged(released, "liquid", "PROCESSING_NOT_ENABLED")

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
