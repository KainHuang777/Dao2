extends RefCounted
## Normal attached content, earned progression and isolated persistence contracts.
var checks := 0
var failures: Array[String] = []
var serial := 0
var content: GameContent
var earned_state: GameState
var active_fixture_json := ""

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func send(s: GameSession, kind: String, p: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id": "d2-" + str(serial), "type": kind, "payload": p, "expected_revision": s.state.revision})

func snapshot(state: GameState) -> String:
	return JSON.stringify(state.to_snapshot_dict(), "", true)

func build(s: GameSession, id: String) -> bool:
	var costs: Dictionary = s.get_view().buildings[id].costs
	for resource in costs:
		for _attempt in range(3000):
			if s.state.resources[resource].value.to_float() >= float(costs[resource]):
				break
			if s.state.era_id > 1:
				s.advance_time(10)
				continue
			if not send(s, "gather", {"resource_id": resource}).ok:
				return false
	return send(s, "upgrade_building", {"building_id": id}).ok

func craft(state: GameState, id: String, island: String = "home", count: int = 1, repeat_job: bool = false) -> Dictionary:
	return send_session(state, "craft", {"recipe_id": id, "island_id": island, "count": count, "repeat": repeat_job})

func reject(state: GameState, operation: Callable, error: String) -> void:
	var before := snapshot(state)
	var result: Dictionary = operation.call()
	expect(not result.ok and result.error == error, "reject " + error + ": " + str(result))
	expect(before == snapshot(state), "atomic rejection " + error)

func wait_recipe(s: GameSession, id: String, count: int = 1) -> bool:
	for _attempt in range(1500):
		var result := craft(s.state, id, "herb" if id == "liquid" else "home", count)
		if result.ok:
			s.advance_time(IslandEconomy.DURATIONS[id] * count)
			return not s.state.economy.jobs.has("herb" if id == "liquid" else "home")
		if not result.error in ["INSUFFICIENT_RESOURCE", "JOB_BUSY"]:
			return false
		s.advance_time(10)
	return false

func run() -> Dictionary:
	content = ContentLoader.load_directory("res://content").content
	expect(content.era(3) == null, "release Era3 absent")
	var baseline_caps := Production.compute_caps(content, {"storage_lingli": 10}, 2, 1)
	expect(baseline_caps.lingli.to_float() == 1100, "audit: capped release storage blocks 2000 requirement")
	expect(IslandProgression.attach(content).ok, "normal D2 attachment")
	expect(content.era(3) != null, "normal Era3 present")
	var cycle := content.processing_catalog.duplicate(true)
	cycle.recipes.formation_core.inputs = {"formation_core": "1"}
	expect(not ProcessingCatalog.validate(cycle).ok, "reject cyclic T3 dependency")
	var future := content.processing_catalog.duplicate(true)
	future.recipes.foundation_pill.inputs = {"stone_mid": "1"}
	expect(not ProcessingCatalog.validate(future).ok, "reject future-Era prerequisite")
	var s := GameSession.create_new_game(content)
	for id in ["hut", "hut", "wooden_house", "wooden_house", "forest_farm", "forest_farm", "forest_farm", "stone_mine", "stone_mine", "stone_mine", "herb_farm", "herb_farm", "herb_farm", "storage_wood", "storage_money", "storage_money", "storage_stone", "storage_herb"]:
		expect(build(s, id), "earned T1 building " + id)
	for _i in range(2):
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
			expect(build(s, "foundation_reservoir") and build(s, "foundation_reservoir"), "earned Era2 T1 capacity facility")
			var blocked_content: GameContent = ContentLoader.load_directory("res://content").content
			blocked_content.eras[3] = content.eras[3]
			var blocked := s.state.duplicate_state()
			reject(blocked, func(): return CommandProcessor.apply(blocked_content, blocked, {"type": "breakthrough_era", "payload": {}}), "INSUFFICIENT_CAPACITY")
			expect(send(s, "activate_islands").ok, "normal D2 activation from earned T1")
			reject(s.state, func(): return IslandEconomy.command(content, s.state, "open_island", {"island_id": "herb"}), "ERA_REQUIREMENT")
			for id in ["formation_core", "golden_core_pill", "spirit_grass_100y"]:
				expect(IslandEconomy.value(s.state, "home", id) == 0, "no future material before Era3 " + id)
		expect(send(s, "breakthrough_era").ok and s.state.era_id == era + 1, "earned breakthrough without future material")
	if s.state.era_id != 3:
		return finish()
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
	var expansion_timber := IslandEconomy.value(s.state, "home", "spirit_timber")
	var expansion_bronze := IslandEconomy.value(s.state, "home", "bronze_essence")
	expect(send(s, "upgrade_island_facility", {"island_id": "herb", "facility_id": "workshop"}).ok, "earned T2 spent on Danxia expansion before cultivation")
	expect(IslandEconomy.value(s.state, "home", "spirit_timber") == expansion_timber - 2 and IslandEconomy.value(s.state, "home", "bronze_essence") == expansion_bronze - 2, "expansion competes with T3 inputs")
	reject(s.state, func(): return craft(s.state, "formation_core", "herb"), "RECIPE_ISLAND_REQUIREMENT")
	var timber := IslandEconomy.value(s.state, "home", "spirit_timber")
	var bronze := IslandEconomy.value(s.state, "home", "bronze_essence")
	expect(craft(s.state, "formation_core").ok, "delivered T2 starts T3")
	expect(IslandEconomy.value(s.state, "home", "spirit_timber") == timber - 2 and IslandEconomy.value(s.state, "home", "bronze_essence") == bronze - 2, "exact T3 stoichiometry")
	expect(IslandEconomy.reserved(s.state, "home", "formation_core", content.processing_catalog) == 1, "T3 output reservation")
	s.advance_time(20)
	expect(IslandEconomy.value(s.state, "home", "formation_core") == 1, "timed T3 completion")
	expect(wait_recipe(s, "liquid"), "earned Danxia liquid")
	s.advance_time(11)
	expect(IslandEconomy.value(s.state, "home", "liquid") > 0, "Danxia product delivered")
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
	var fixture_meta := {"save_id": "local", "saved_at_utc_ms": str(int(Time.get_unix_time_from_system() * 1000)), "settled_until_utc_ms": str(int(Time.get_unix_time_from_system() * 1000)), "sim_tick": str(int(s.state.total_elapsed_seconds))}
	var fixture_save := SaveCodec.encode(s.state, content.content_version, fixture_meta)
	expect(fixture_save.ok, "earned D2 review fixture validates")
	if fixture_save.ok and not OS.has_feature("web"):
		var fixture_file := FileAccess.open("res://docs/verification/artifacts/res1-d2-earned-era3.json", FileAccess.WRITE)
		fixture_file.store_string(fixture_save.json)
		fixture_file.close()
	_test_persistence(s)
	# Continue the earned flow across every Era3 level, including Lv9 talismans.
	for level in range(2, 10):
		expect(wait_recipe(s, "formation_core"), "earned T3 for Lv" + str(level))
		expect(wait_recipe(s, "liquid"), "earned liquid for Lv" + str(level))
		s.advance_time(11)
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
	earned_state = s.state.duplicate_state()
	return finish()

func total(state: GameState, id: String) -> float:
	var result := 0.0
	for island in IslandEconomy.ISLANDS:
		result += IslandEconomy.value(state, island, id)
	for route in state.economy.trips:
		if IslandEconomy.ROUTES[route][2] == id:
			result += float(state.economy.trips[route].cargo)
	return result

func send_session(state: GameState, kind: String, p: Dictionary) -> Dictionary:
	var s := GameSession.new()
	s.content = content
	s.state = state
	return send(s, kind, p)

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var fail_key := ""
	var writes := 0
	var fail_write_number := -1
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		writes += 1
		if key == fail_key or writes == fail_write_number:
			return {"ok": false, "error": "quota"}
		data[key] = payload
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}

func normalized(state: GameState) -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(state.to_snapshot_dict()), "", true)

func _test_persistence(s: GameSession) -> void:
	var branch := GameSession.new()
	branch.content = content
	branch.clock = GameClock.create(s.state.total_elapsed_seconds)
	branch.state = s.state.duplicate_state()
	s = branch
	for _attempt in range(50):
		if IslandEconomy.value(s.state, "home", "lingli") >= 200:
			break
		s.advance_time(10)
	var saved_job := craft(s.state, "liquid", "herb", 3)
	for _attempt in range(50):
		if saved_job.ok:
			break
		s.advance_time(10)
		saved_job = craft(s.state, "liquid", "herb", 3)
	expect(saved_job.ok, "saved branch earned Danxia batches: " + str(saved_job))
	if not saved_job.ok:
		return
	s.advance_time(6)
	expect(int(s.state.economy.jobs.herb.remaining) > 0 and s.state.economy.trips.has("liquid_home"), "save captures active Danxia batch and product cargo")
	var meta := {"save_id": "local", "saved_at_utc_ms": "100000", "settled_until_utc_ms": "100000", "sim_tick": "0"}
	var encoded := SaveCodec.encode(s.state, content.content_version, meta)
	active_fixture_json = encoded.get("json", "")
	if not OS.has_feature("web") and encoded.ok:
		var active_file := FileAccess.open("res://docs/verification/artifacts/res1-d2-active-fixture.json", FileAccess.WRITE)
		active_file.store_string(encoded.json)
		active_file.close()
	expect(encoded.ok, "D2 validates and encodes")
	if not encoded.ok:
		return
	var restored := SaveCodec.decode(encoded.json)
	expect(restored.ok and normalized(restored.state) == normalized(s.state), "D2 complete save roundtrip")
	var online := s.state.duplicate_state()
	var offline: GameState = restored.state
	TimeAdvancer.advance(online, content, 600)
	OfflineSettlement.settle(offline, content, 700000, 100000)
	expect(normalized(online) == normalized(offline), "600s offline equals online after reload")
	var partition := s.state.duplicate_state()
	for seconds in [7, 23, 101, 169, 300]:
		TimeAdvancer.advance(partition, content, seconds)
	expect(normalized(partition) == normalized(online), "600s complete partition equality")
	var legacy := s.state.duplicate_state()
	legacy.era_id = 2 # migration diagnostic only, excluded from earned flow
	legacy.economy.version = IslandProgression.LEGACY_VERSION
	legacy.economy.islands.herb = {"opened": false, "inventory": {}, "facilities": {"extractor": 1, "workshop": 1, "storage": 1}}
	legacy.economy.jobs.erase("home")
	legacy.economy.jobs.erase("herb")
	for id in ["grass_home", "herb_home", "liquid_home"]:
		legacy.economy.routes.erase(id)
		legacy.economy.trips.erase(id)
	var migrating := GameSession.new()
	migrating.content = content
	migrating.clock = GameClock.create(legacy.total_elapsed_seconds)
	migrating.state = legacy
	var adapter := MemoryAdapter.new()
	SaveManager.configure(content, adapter)
	adapter.fail_key = SaveManager.D2_ARCHIVE_KEY
	var before := normalized(legacy)
	expect(not SaveManager.activate_islands(migrating, meta).ok and before == normalized(migrating.state), "archive failure atomic")
	adapter.fail_key = ""
	expect(SaveManager.activate_islands(migrating, meta).ok, "C to D2 archive retry")
	expect(SaveCodec.decode(adapter.data[SaveManager.D2_ARCHIVE_KEY]).state.economy.version == IslandProgression.LEGACY_VERSION, "C original recoverable")
	var expected := legacy.economy.duplicate(true)
	expected.version = IslandProgression.VERSION
	expect(expected == migrating.state.economy, "migration preserves jobs cargo facilities inventories")
	expect(not SaveManager.activate_islands(migrating, meta).ok, "activation cannot repeat")
	var interrupted := GameSession.new()
	interrupted.content = content
	interrupted.clock = GameClock.create(legacy.total_elapsed_seconds)
	interrupted.state = legacy.duplicate_state()
	var interrupted_adapter := MemoryAdapter.new()
	SaveManager.configure(content, interrupted_adapter)
	interrupted_adapter.fail_write_number = 5
	var interrupted_before := normalized(interrupted.state)
	expect(not SaveManager.activate_islands(interrupted, meta).ok and normalized(interrupted.state) == interrupted_before, "candidate index failure leaves live C untouched")
	interrupted_adapter.fail_write_number = -1
	expect(SaveManager.activate_islands(interrupted, meta).ok and interrupted.state.economy == expected, "candidate retry extends once without losing C stock")
	var unknown := s.state.duplicate_state()
	unknown.economy.version = "res1-d-future"
	expect(not SaveCodec.encode(unknown, content.content_version, meta).ok, "unknown economy version rejected")
	interrupted_adapter.data[SaveSlots.SLOT_MAIN] = "corrupt"
	expect(SaveCodec.decode(SaveManager.slots().read_best(func(raw: String) -> int: return SaveCodec.decode(raw).state.revision if SaveCodec.decode(raw).ok else -1).json).ok, "corrupt generation recovers other slot")
	SaveManager.configure(content, adapter)
	adapter.fail_key = SaveSlots.INDEX_KEY
	var source := normalized(s.state)
	var failed := OfflineCoordinator.settle_state(s.state, content, 700000, 100000)
	expect(not failed.ok and source == normalized(s.state), "offline failed commit leaves live source")
	adapter.fail_key = ""
	var retry := OfflineCoordinator.settle_state(s.state, content, 700000, 100000)
	expect(retry.ok and normalized(retry.state) == normalized(online_with_revision(online)), "offline retry grants once")
	var reborn := s.state.duplicate_state()
	TimeAdvancer.advance(reborn, content, 50000) # earn exhaustion, no direct age injection
	expect(ReincarnationRules.apply_reincarnation(reborn, content, "normal").ok, "D2 reincarnation")
	expect(reborn.economy.version == IslandProgression.VERSION and reborn.economy.jobs.is_empty() and reborn.economy.trips.is_empty() and not reborn.economy.islands.herb.opened, "rebirth clears D2 cargo jobs Danxia")
	expect(IslandEconomy.validate(reborn).is_empty(), "reborn save valid")
	SaveManager.reset_for_tests()

func online_with_revision(state: GameState) -> GameState:
	var result := state.duplicate_state()
	result.revision += 1
	return result

func finish() -> Dictionary:
	return {"checks": checks, "failures": failures, "state": earned_state, "active_fixture": active_fixture_json}
