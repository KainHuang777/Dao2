extends SceneTree
## Memory-only earned flow. Never writes a save or shared C/R2 fixture.
const Contract = preload("res://tests/fixtures/res1d1/contract.gd")
var checks := 0
var failures: Array[String] = []
var serial := 0
var fixture: Dictionary
var content: GameContent

func _init() -> void:
	call_deferred("_run")

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func send(s: GameSession, kind: String, p: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id": "d1-" + str(serial), "type": kind, "payload": p, "expected_revision": s.state.revision})

func snapshot(state: GameState) -> String:
	return JSON.stringify(state.to_snapshot_dict(), "", true)

func build(s: GameSession, id: String) -> bool:
	var costs: Dictionary = s.get_view().buildings[id].costs
	for resource in costs:
		for _attempt in range(3000):
			if s.state.resources[resource].value.to_float() >= float(costs[resource]):
				break
			if not send(s, "gather", {"resource_id": resource}).ok:
				return false
	return send(s, "upgrade_building", {"building_id": id}).ok

func craft(state: GameState, id: String, island: String = "home", count: int = 1, repeat_job: bool = false) -> Dictionary:
	return Contract.craft(content, state, {"recipe_id": id, "island_id": island, "count": count, "repeat": repeat_job}, fixture)

func reject(state: GameState, operation: Callable, error: String) -> void:
	var before := snapshot(state)
	var result: Dictionary = operation.call()
	expect(not result.ok and result.error == error, "reject " + error + ": " + str(result))
	expect(before == snapshot(state), "atomic rejection " + error)

func wait_recipe(s: GameSession, id: String, count: int = 1) -> bool:
	for _attempt in range(1500):
		var result := craft(s.state, id, "home", count)
		if result.ok:
			s.advance_time(IslandEconomy.DURATIONS[id] * count)
			return not s.state.economy.jobs.has("home")
		if not result.error in ["INSUFFICIENT_RESOURCE", "JOB_BUSY"]:
			return false
		s.advance_time(10)
	return false

func _run() -> void:
	content = ContentLoader.load_directory("res://content").content
	expect(content.era(3) == null, "release Era3 absent")
	var baseline_caps := Production.compute_caps(content, {"storage_lingli": 10}, 2, 1)
	expect(baseline_caps.lingli.to_float() == 1100, "audit: capped release storage blocks 2000 requirement")
	fixture = Contract.attach(content)
	expect(fixture.fixture_version == "res1-d1-1", "versioned isolated proposal")
	var cycle := content.processing_catalog.duplicate(true)
	cycle.recipes.formation_core.inputs = {"formation_core": "1"}
	expect(not ProcessingCatalog.validate(cycle).ok, "reject cyclic T3 dependency")
	var future := content.processing_catalog.duplicate(true)
	future.recipes.foundation_pill.inputs = {"stone_mid": "1"}
	expect(not ProcessingCatalog.validate(future).ok, "reject future-Era prerequisite")
	var s := GameSession.create_new_game(content)
	for id in ["hut", "hut", "wooden_house", "wooden_house", "forest_farm", "forest_farm", "forest_farm", "stone_mine", "stone_mine", "stone_mine", "herb_farm", "herb_farm", "herb_farm", "storage_wood", "storage_money", "storage_money", "storage_stone", "storage_herb"]:
		expect(build(s, id), "earned T1 building " + id)
	for _i in range(8):
		expect(build(s, "storage_lingli"), "earned proposed capacity expansion")
	for era in [1, 2]:
		for _attempt in range(500):
			if s.state.level == 10:
				break
			if s.get_view().can_level_up:
				expect(send(s, "level_up_cultivation").ok, "earned level Era" + str(era))
			else:
				s.advance_time(10)
		expect(s.state.level == 10, "earned max level Era" + str(era))
		if era == 2:
			var blocked_content: GameContent = ContentLoader.load_directory("res://content").content
			blocked_content.eras[3] = fixture.era
			var blocked := s.state.duplicate_state()
			reject(blocked, func(): return CommandProcessor.apply(blocked_content, blocked, {"type": "breakthrough_era", "payload": {}}), "INSUFFICIENT_CAPACITY")
			expect(send(s, "migrate_processing").ok, "B isolation migration from earned T1")
			reject(s.state, func(): return IslandEconomy.command(content, s.state, "open_island", {"island_id": "herb"}), "ERA_REQUIREMENT")
			for id in ["formation_core", "golden_core_pill", "spirit_grass_100y"]:
				expect(IslandEconomy.value(s.state, "home", id) == 0, "no future material before Era3 " + id)
		expect(send(s, "breakthrough_era").ok and s.state.era_id == era + 1, "earned breakthrough without future material")
	if s.state.era_id != 3:
		finish()
		return
	for island in ["wood", "ore", "herb"]:
		s.advance_time(30)
		var wood := IslandEconomy.value(s.state, "home", "wood")
		var stone := IslandEconomy.value(s.state, "home", "stone_low")
		expect(send(s, "open_island", {"island_id": island}).ok, "T1 opening " + island)
		expect(IslandEconomy.value(s.state, "home", "wood") == wood - 20 and IslandEconomy.value(s.state, "home", "stone_low") == stone - 10, "opening exact T1 payment")
	for route in IslandEconomy.ROUTES:
		expect(send(s, "configure_route", {"route_id": route}).ok, "route " + route)
	s.advance_time(31)
	expect(IslandEconomy.value(s.state, "home", "spirit_grass_100y") > 0, "Danxia raw delivered, no granted intermediate")
	for pair in [["spirit_timber", "wood"], ["bronze_essence", "ore"]]:
		expect(craft(s.state, pair[0], pair[1], 1, true).ok, "start T2 producer " + pair[0])
	s.advance_time(61)
	reject(s.state, func(): return craft(s.state, "formation_core", "herb"), "RECIPE_ISLAND_REQUIREMENT")
	var timber := IslandEconomy.value(s.state, "home", "spirit_timber")
	var bronze := IslandEconomy.value(s.state, "home", "bronze_essence")
	expect(craft(s.state, "formation_core").ok, "delivered T2 starts T3")
	expect(IslandEconomy.value(s.state, "home", "spirit_timber") == timber - 2 and IslandEconomy.value(s.state, "home", "bronze_essence") == bronze - 2, "exact T3 stoichiometry")
	expect(IslandEconomy.reserved(s.state, "home", "formation_core", content.processing_catalog) == 1, "T3 output reservation")
	s.advance_time(20)
	expect(IslandEconomy.value(s.state, "home", "formation_core") == 1, "timed T3 completion")
	expect(wait_recipe(s, "liquid"), "earned delivered grass to liquid")
	expect(wait_recipe(s, "stone_mid", 55), "earned T1 to mid stones")
	expect(wait_recipe(s, "foundation_pill", 3), "earned foundation pills")
	var before_gold := s.state.duplicate_state()
	expect(craft(s.state, "golden_core_pill").ok, "earned golden pill from crafted inputs")
	for id in content.processing_catalog.recipes.golden_core_pill.inputs:
		expect(IslandEconomy.value(s.state, "home", id) == IslandEconomy.value(before_gold, "home", id) - float(content.processing_catalog.recipes.golden_core_pill.inputs[id]), "golden pill exact start payment " + id)
	s.advance_time(30)
	expect(IslandEconomy.value(s.state, "home", "foundation_pill") == IslandEconomy.value(before_gold, "home", "foundation_pill") - 3, "golden pill consumes foundation pills")
	expect(IslandEconomy.value(s.state, "home", "stone_mid") == 50, "golden pill consumes 5 mid stones")
	expect(IslandEconomy.value(s.state, "home", "golden_core_pill") == 1, "golden pill is an item within Era3")
	# Wait only through the normal simulation; never assign training, era or stock.
	for _attempt in range(500):
		if s.get_view().can_level_up:
			break
		s.advance_time(10)
	var level_before := s.state.duplicate_state()
	expect(send(s, "level_up_cultivation").ok and s.state.level == 2, "actual Era3 cultivation command consumes T2/T3")
	for id in content.eras[3].level_up_requirements.resources:
		expect(IslandEconomy.value(s.state, "home", id) == IslandEconomy.value(level_before, "home", id) - float(content.eras[3].level_up_requirements.resources[id]), "cultivation exact cost " + id)
	for level in range(1, 10):
		var costs := Cultivation.level_up_cost(content.eras[3], level, 0)
		expect(costs.stone_mid.to_float() == 50 and costs.formation_core.to_float() == 1, "Lv" + str(level) + " costs")
		expect(costs.has("talisman") == (level == 9), "Lv9 talisman gate")
	_test_diagnostics(s)
	# Continue the earned flow across every Era3 level, including Lv9 talismans.
	for level in range(2, 10):
		expect(wait_recipe(s, "formation_core"), "earned T3 for Lv" + str(level))
		expect(wait_recipe(s, "liquid"), "earned liquid for Lv" + str(level))
		expect(wait_recipe(s, "stone_mid", 50), "earned mid stones for Lv" + str(level))
		if level == 9:
			expect(wait_recipe(s, "talisman", 10), "earned Lv9 talismans")
		for _attempt in range(500):
			if s.get_view().can_level_up:
				break
			s.advance_time(10)
		var before_level := s.state.duplicate_state()
		expect(send(s, "level_up_cultivation").ok and s.state.level == level + 1, "earned Era3 Lv" + str(level + 1))
		for id in Cultivation.level_up_cost(content.eras[3], level, 0):
			var amount: AmountCompat = Cultivation.level_up_cost(content.eras[3], level, 0)[id]
			expect(IslandEconomy.value(s.state, "home", id) == IslandEconomy.value(before_level, "home", id) - amount.to_float(), "earned level payment " + id)
	reject(s.state, func(): return CommandProcessor.apply(content, s.state, {"type": "level_up_cultivation", "payload": {}}), "MAX_LEVEL_REACHED")
	reject(s.state, func(): return CommandProcessor.apply(content, s.state, {"type": "breakthrough_era", "payload": {}}), "NO_NEXT_ERA")
	print("EARNED: Era", s.state.era_id, " Lv", s.state.level, " sim_seconds=", s.state.total_elapsed_seconds)
	finish()

func _test_diagnostics(s: GameSession) -> void:
	var shortage := s.state.duplicate_state() # cultivation just consumed the only T3
	reject(shortage, func(): return craft(shortage, "golden_core_pill"), "INSUFFICIENT_RESOURCE")
	reject(shortage, func(): return craft(shortage, "missing"), "UNKNOWN_RECIPE")
	var early := s.state.duplicate_state()
	early.training_seconds = 0 # adversarial rejection, not earned-flow evidence
	reject(early, func(): return CommandProcessor.apply(content, early, {"type": "level_up_cultivation", "payload": {}}), "INSUFFICIENT_TRAINING")
	var missing := s.state.duplicate_state()
	missing.training_seconds = 10000 # isolate material gate on a diagnostic clone
	for id in content.eras[3].level_up_requirements.resources:
		IslandEconomy._put(missing, "home", id, float(content.eras[3].level_up_requirements.resources[id]))
	IslandEconomy._put(missing, "home", "formation_core", 0)
	reject(missing, func(): return CommandProcessor.apply(content, missing, {"type": "level_up_cultivation", "payload": {}}), "INSUFFICIENT_RESOURCE")
	IslandEconomy._put(missing, "home", "formation_core", 1)
	missing.level = 9
	reject(missing, func(): return CommandProcessor.apply(content, missing, {"type": "level_up_cultivation", "payload": {}}), "INSUFFICIENT_RESOURCE")
	var full := s.state.duplicate_state()
	full.economy.jobs.erase("home")
	# Adversarial boundary only, excluded from earned reachability evidence.
	IslandEconomy._put(full, "home", "formation_core", 1000000)
	reject(full, func(): return craft(full, "formation_core"), "OUTPUT_FULL")
	var packed := s.state.duplicate_state()
	for route in packed.economy.routes:
		packed.economy.routes[route].enabled = false
	packed.economy.jobs.clear()
	packed.economy.trips.clear()
	IslandEconomy._put(packed, "herb", "spirit_grass_100y", 100)
	IslandEconomy.tick(packed, content.processing_catalog)
	expect(IslandEconomy.value(packed, "herb", "spirit_grass_100y") == 100, "full local raw warehouse stops production")
	IslandEconomy._put(packed, "home", "spirit_grass_100y", 999995)
	expect(IslandEconomy.command(content, packed, "configure_route", {"route_id": "herb_home", "target": "1000000"}).ok, "nearly full destination route")
	IslandEconomy.tick(packed, content.processing_catalog)
	expect(float(packed.economy.trips.herb_home.cargo) == 5, "departure respects remaining destination capacity")
	expect(IslandEconomy.free_space(packed, "home", "spirit_grass_100y", content.processing_catalog) == 0, "cargo reserves destination capacity")
	for _i in range(10):
		IslandEconomy.tick(packed, content.processing_catalog)
	expect(IslandEconomy.value(packed, "home", "spirit_grass_100y") == 1000000 and packed.economy.trips.is_empty(), "exactly full arrival no overflow or second shipment")
	var once := s.state.duplicate_state()
	var split := s.state.duplicate_state()
	TimeAdvancer.advance(once, content, 600)
	for seconds in [7, 23, 101, 169, 300]:
		TimeAdvancer.advance(split, content, seconds)
	expect(snapshot(once) == snapshot(split), "600 seconds full state once equals partitioned")
	# Same earned source; no inventory injection for bottleneck comparison.
	var low := s.state.duplicate_state()
	var high := low.duplicate_state()
	low.economy.routes.herb_home.target = "1000"
	high.economy.routes.herb_home.target = "1000"
	expect(IslandEconomy.command(content, high, "configure_route", {"route_id": "herb_home", "target": "1000", "level": 2}).ok, "T1 operational route upgrade")
	var low_start := IslandEconomy.value(low, "home", "spirit_grass_100y")
	var high_start := IslandEconomy.value(high, "home", "spirit_grass_100y")
	for _i in range(61):
		IslandEconomy.tick(low, content.processing_catalog)
		IslandEconomy.tick(high, content.processing_catalog)
	expect(IslandEconomy.value(high, "home", "spirit_grass_100y") - high_start > IslandEconomy.value(low, "home", "spirit_grass_100y") - low_start, "higher transport delivers more earned cargo")
	# Freeze production on a diagnostic clone; existing cargo must only move once.
	var transport := high.duplicate_state()
	transport.economy.jobs.clear()
	for island in ["wood", "ore", "herb"]:
		transport.economy.islands[island].opened = false
	var before := total(transport, "spirit_grass_100y")
	for _i in range(31):
		IslandEconomy.tick(transport, content.processing_catalog)
	expect(total(transport, "spirit_grass_100y") == before, "source plus transit plus destination conserved")
	expect(IslandEconomy.validate(s.state).is_empty(), "earned B contract validates")

func total(state: GameState, id: String) -> float:
	var result := 0.0
	for island in IslandEconomy.ISLANDS:
		result += IslandEconomy.value(state, island, id)
	for route in state.economy.trips:
		if IslandEconomy.ROUTES[route][2] == id:
			result += float(state.economy.trips[route].cargo)
	return result

func finish() -> void:
	if failures.is_empty():
		print("PASS: RES1-D1 %d checks; isolated earned Era3, Danxia, T2/T3 consumption, atomic refusal, transport, conservation, 600s partitions." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
