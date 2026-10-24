extends SceneTree
const Supply = preload("res://src/content/supply_content.gd")
const META := {"save_id": "supply2-isolated", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
var checks := 0
var failures: Array[String] = []
var serial := 0
var content: GameContent
var old_content: GameContent

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var fail_prefix := ""
	var corrupt_prefix := ""
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		if not fail_prefix.is_empty() and key.begins_with(fail_prefix): return {"ok": false, "error": "injected"}
		data[key] = "corrupt" if not corrupt_prefix.is_empty() and key.begins_with(corrupt_prefix) else payload
		return {"ok": true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}
	func exists(key: String) -> bool: return data.has(key)

func _init() -> void:
	old_content = ContentLoader.load_directory("res://content").content
	expect(IslandProgression.attach(old_content).ok, "old release attachment")
	content = ContentLoader.load_directory("res://content").content
	expect(IslandProgression.attach_supply(content).ok, "explicit supply attachment")
	if content.processing_catalog.get("version") != Supply.VERSION:
		quit(1)
		return
	_test_migration()
	_test_processing()
	_test_islands()
	_test_time()
	_test_caps_and_rebirth()
	_test_persistence()
	var dir := "res://docs/verification/artifacts/content-p2-supply"
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir + "/economy-contract.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"level": "L1", "stage": "SUPPLY-2", "checks": checks, "failures": failures}, "\t"))
	for failure in failures: push_error(failure)
	print("%s: SUPPLY-2 %d checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)

func expect(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func send(session: GameSession, type: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return session.submit({"command_id": "supply2-" + str(serial), "expected_revision": session.state.revision, "type": type, "payload": payload})

func stock(state: GameState, id: String, amount: float) -> void:
	state.resources[id] = {"value": AmountCompat.from_number(amount), "unlocked": true, "ever_obtained": amount > 0}

func old_session(version: String = IslandProgression.VERSION) -> GameSession:
	var session := GameSession.create_new_game(old_content, 20261024)
	session.state.era_id = 3
	for id in old_content.processing_catalog.resources: stock(session.state, id, 0)
	expect(send(session, "activate_islands").ok, "old activation")
	session.state.economy.version = version
	for id in ["wood", "ore"]: session.state.economy.islands[id].opened = true
	session.state.economy.islands.wood.inventory = {"wood": "130", "spirit_timber": "10"}
	session.state.economy.jobs.wood = {"recipe_id": "spirit_timber", "recipe_version": 1, "remaining": 4, "batches": 3, "repeat": true, "reserves": {"wood": "5"}, "status": "running", "pending": {"recipe_id": "spirit_timber", "recipe_version": 1, "remaining": 0, "batches": 2, "repeat": false, "reserves": {}, "status": "ready"}}
	session.state.economy.routes.timber_home = {"enabled": true, "reserve": "5", "target": "100", "level": 2}
	session.state.economy.trips.timber_home = {"version": 1, "remaining": 6, "cargo": "20"}
	return session

func supply_session(era: int = 6) -> GameSession:
	var session := GameSession.create_new_game(content, 20261024)
	session.state.era_id = era
	for id in content.processing_catalog.resources: stock(session.state, id, 0)
	expect(send(session, "activate_islands").ok, "seven island activation")
	return session

func normalized(state: GameState) -> String: return JSON.stringify(SaveCodec._normalize_numbers(state.to_snapshot_dict()), "", true)

func _test_migration() -> void:
	for version in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION]:
		var session := old_session(version)
		var before := normalized(session.state)
		var result := IslandProgression.prepare_supply(content, session.state)
		expect(result.ok, "old version validated " + version)
		if not result.ok: continue
		var state: GameState = result.state
		expect(before == normalized(session.state), "migration leaves source intact")
		for id in session.state.economy.islands:
			expect(state.economy.islands[id] == session.state.economy.islands[id], "old island exact " + id)
		for key in ["tick", "jobs", "routes", "trips"]:
			expect(state.economy[key] == session.state.economy[key], "old economy field exact " + key)
		for id in ["deep", "ancient", "void"]:
			expect(state.economy.islands[id] == {"opened": false, "inventory": {}}, "new island unopened empty " + id)
		expect(state.tribulation_roll_index == session.state.tribulation_roll_index and state.tribulation_seed == session.state.tribulation_seed, "no tribulation RNG consumed")
		expect(IslandEconomy.reserved(state, "home", "spirit_timber", content.processing_catalog) == 20, "cargo reservation preserved")
		expect(IslandEconomy.validate(state).is_empty(), "migrated seven island snapshot valid")
		expect(not IslandProgression.prepare_supply(content, state).ok, "migration cannot repeat")
	var empty := GameSession.create_new_game(old_content, 1)
	var disabled := IslandProgression.prepare_supply(content, empty.state)
	expect(disabled.ok and disabled.state.economy.is_empty(), "disabled remains explicit opt-in")
	expect(disabled.state.resources.void_essence.value.sign == 0, "disabled receives zero new stock")
	stock(empty.state, "wood", 1.0e13)
	expect(not IslandProgression.prepare_supply(content, empty.state).ok, "unsupported disabled legacy Amount cannot enter supply contract")
	var bad := old_session()
	bad.state.economy.islands.deep = {"opened": false, "inventory": {}}
	expect(not IslandProgression.prepare_supply(content, bad.state).ok, "old version cannot smuggle new island")
	bad = old_session()
	bad.state.economy.version = "unknown"
	expect(not IslandProgression.prepare_supply(content, bad.state).ok, "unknown version rejected")

func _test_processing() -> void:
	var session := supply_session(4)
	session.state.buildings.stone_mine = 3
	stock(session.state, "stone_low", 500)
	stock(session.state, "lingli", 1000)
	expect(send(session, "craft", {"recipe_id": "stone_mid_bulk"}).ok, "bulk batch starts")
	expect(IslandEconomy.value(session.state, "home", "stone_low") == 0 and IslandEconomy.value(session.state, "home", "lingli") == 0, "bulk atomic input deduction")
	expect(IslandEconomy.reserved(session.state, "home", "stone_mid", content.processing_catalog) == 100, "bulk reserves canonical product")
	expect(not session.state.resources.has("stone_mid_bulk"), "no phantom product stock")
	expect(IslandEconomy.validate(session.state).is_empty(), "running bulk validates")
	var encoded := SaveCodec.encode(session.state, content.content_version, META)
	expect(encoded.ok and SaveCodec.decode(encoded.get("json", "")).ok, "running batch snapshot round-trip")
	expect(JSON.parse_string(encoded.json).rules_version == SaveCodec.SKS_RULES_VERSION, "expanded v4 economy carries the sks rules identity")
	for i in range(10): IslandEconomy.tick(session.state, content.processing_catalog)
	expect(IslandEconomy.value(session.state, "home", "stone_mid") == 100, "bulk completes into mid-stone")
	expect(IslandEconomy.reserved(session.state, "home", "stone_mid", content.processing_catalog) == 0, "completion releases reservation")
	expect(session.state.life_ledger.current.accounts.rows.has("home:stone_mid"), "canonical product recorded in ledger")
	expect(not session.state.life_ledger.current.accounts.rows.has("home:stone_mid_bulk"), "ledger has no phantom material")
	stock(session.state, "stone_mid", IslandEconomy.home_cap(session.state, "stone_mid", content.processing_catalog) - 99)
	stock(session.state, "stone_low", 500)
	stock(session.state, "lingli", 1000)
	var before := normalized(session.state)
	expect(not send(session, "craft", {"recipe_id": "stone_mid_bulk"}).ok and before == normalized(session.state), "full bulk rejected without charge")
	var immediate := GameSession.create_new_game(content, 1)
	immediate.state.era_id = 4
	immediate.state.buildings.stone_mine = 3
	for pair in [["stone_low", 500], ["lingli", 1000], ["stone_mid", 0]]: stock(immediate.state, pair[0], pair[1])
	expect(send(immediate, "craft", {"recipe_id": "stone_mid_bulk"}).ok, "immediate contract product decoupled")
	expect(IslandEconomy.value(immediate.state, "home", "stone_mid") == 100, "immediate canonical output")
	var view := IslandEconomy.manufacturing_view(session.state, content.processing_catalog)
	expect(view.recipes.stone_mid_bulk.product_id == "stone_mid" and view.recipes.stone_mid_bulk.output == 100, "manufacturing view exposes product ID")
	expect(IslandEconomy.manufacturing_view(immediate.state, content.processing_catalog).recipes.size() == 11, "disabled new catalog view is safe")

func _test_islands() -> void:
	var session := supply_session()
	var before := normalized(session.state)
	expect(not send(session, "upgrade_building", {"building_id": "mineral_focus"}).ok and before == normalized(session.state), "dispatch requires opened island")
	for island in ["deep", "ancient", "void"]:
		var costs: Dictionary = IslandEconomy.supply_data().islands[island].cost
		for id in costs: stock(session.state, id, costs[id])
		expect(send(session, "open_island", {"island_id": island}).ok, "open charged " + island)
		for id in costs: expect(IslandEconomy.value(session.state, "home", id) == 0, "exact open cost " + id)
		expect(IslandProgression.capacity(session.state, island) == 300, "local cap 300 " + island)
		expect(not session.state.economy.islands[island].has("facilities"), "no phantom local workshop " + island)
		expect(not send(session, "craft", {"island_id": island, "recipe_id": "stone_high"}).ok, "new island cannot process")
		expect(not send(session, "upgrade_island_facility", {"island_id": island, "facility_id": "workshop"}).ok, "new island cannot upgrade phantom facility")
	for id in IslandEconomy.supply_data().routes:
		expect(send(session, "configure_route", {"route_id": id, "enabled": false}).ok, "free route configuration " + id)
		stock(session.state, "spirit_timber", 20)
		stock(session.state, "bronze_essence", 20)
		expect(send(session, "configure_route", {"route_id": id, "level": 3, "enabled": false}).ok, "new route level 3 " + id)
		expect(IslandEconomy.value(session.state, "home", "spirit_timber") == 0, "both upgrade steps charged")
		expect(not send(session, "configure_route", {"route_id": id, "level": 4}).ok, "route level 4 rejected")
		expect(IslandEconomy.departure_info(session.state, content.processing_catalog, id, session.state.economy.routes[id]).throughput == 30, "route capacity 30")
	for i in range(600): IslandEconomy.tick(session.state, content.processing_catalog)
	expect(is_equal_approx(IslandEconomy.value(session.state, "deep", "refined_iron"), 60), "600 seconds raw iron 60")
	expect(is_equal_approx(IslandEconomy.value(session.state, "ancient", "spirit_grass_1000y"), 24), "600 seconds raw grass 24")
	stock(session.state, "refined_iron", 30)
	stock(session.state, "formation_core", 2)
	expect(send(session, "upgrade_building", {"building_id": "mineral_focus"}).ok, "paid mineral dispatch")
	expect(IslandEconomy.rate(session.state, "deep", "refined_iron") == 0.2, "only local dispatch doubles gathering")
	expect(IslandEconomy.rate(session.state, "ancient", "spirit_grass_1000y") == 0.04, "dispatch leaves other island unchanged")
	session.state.economy.islands.deep.inventory.refined_iron = "299.95"
	IslandEconomy.tick(session.state, content.processing_catalog)
	expect(IslandEconomy.value(session.state, "deep", "refined_iron") == 300, "local production stops at cap")
	expect(IslandEconomy.validate(session.state).is_empty(), "seven islands twelve routes validate")
	var invalid := session.state.duplicate_state()
	invalid.economy.islands.deep.facilities = {"workshop": 1}
	expect(not IslandEconomy.validate(invalid).is_empty(), "phantom facility rejected on load")
	invalid = session.state.duplicate_state()
	invalid.economy.islands.deep.inventory.refined_iron = "301"
	expect(not IslandEconomy.validate(invalid).is_empty(), "local overflow rejected")

func _test_time() -> void:
	var session := supply_session()
	for id in ["wood", "stone_mid", "formation_core"]: stock(session.state, id, 100)
	expect(send(session, "open_island", {"island_id": "deep"}).ok, "time test island")
	expect(send(session, "configure_route", {"route_id": "deep_iron_home"}).ok, "time test route")
	var source := session.state.duplicate_state()
	var chunks := source.duplicate_state()
	for i in range(600): IslandEconomy.tick(source, content.processing_catalog)
	for i in range(6): OfflineEconomyJump.advance(chunks, content, 100, {})
	expect(normalized(source) == normalized(chunks), "600 one-second and six offline chunks exactly match with fractional cargo")
	expect(IslandEconomy.value(source, "home", "refined_iron") > 0, "new cargo reaches home")
	expect(source.life_ledger.current.accounts.rows.has("transit:refined_iron"), "new cargo transit ledger")
	expect(IslandEconomy.validate(source).is_empty(), "cargo snapshot reservation valid")
	var corrupt := source.duplicate_state()
	corrupt.economy.routes.deep_iron_home.level = 4
	expect(not IslandEconomy.validate(corrupt).is_empty(), "invalid new route level rejected")

func _test_persistence() -> void:
	for version in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION]:
		for fault in ["archive_write", "archive_readback", "slot_write", "index_write"]:
			var session := old_session(version)
			var original := SaveCodec.encode(session.state, old_content.content_version, META)
			expect(original.ok, "source encodes")
			if not original.ok: continue
			var adapter := MemoryAdapter.new()
			adapter.data.save_main = original.json
			adapter.data.save_index = JSON.stringify({"active_slot": "save_main", "revision": session.state.revision, "commit_sequence": 1})
			SaveManager.configure(content, adapter)
			var loaded: GameState = SaveManager.current_state()
			expect(loaded != null, "load candidate " + fault)
			if loaded == null: continue
			expect(loaded.economy.version == Supply.VERSION, "loaded economy upgraded")
			var before := normalized(loaded)
			var guarded := GameSession.new()
			guarded.content = content
			guarded.state = loaded
			guarded.clock = GameClock.create(loaded.total_elapsed_seconds)
			expect(send(guarded, "stop_processing", {"island_id": "wood"}).get("error") == "SUPPLY_SAVE_REQUIRED", "pending migration rejects additional commands")
			expect(not guarded.advance_time(600).ok, "pending migration blocks time and cargo")
			expect(not OfflineCoordinator.settle_state(loaded, content, 601000, 1000).ok and normalized(loaded) == before, "pending migration blocks offline settlement")
			match fault:
				"archive_write": adapter.fail_prefix = "save_before_supply_"
				"archive_readback": adapter.corrupt_prefix = "save_before_supply_"
				"slot_write": adapter.fail_prefix = "save_backup"
				"index_write": adapter.fail_prefix = "save_index"
			expect(not SaveManager.save(loaded, META).ok, "injected " + fault + " refused")
			expect(before == normalized(loaded), "failure preserves same candidate")
			expect(adapter.data.save_main == original.json, "old source slot preserved")
			adapter.fail_prefix = ""
			adapter.corrupt_prefix = ""
			var key := "save_before_supply_" + String(original.json).sha256_text()
			if fault == "archive_readback": adapter.data.erase(key)
			expect(SaveManager.save(loaded, META).ok, "save-only retry succeeds " + fault)
			expect(not SaveManager.supply_pending(loaded), "verified commit unlocks candidate")
			expect(adapter.data.get(key) == original.json, "exact original bytes archived and read back")
			expect(before == normalized(loaded), "retry never advances job/cargo/RNG")
			SaveManager.configure(content, adapter)
			var reloaded: GameState = SaveManager.current_state()
			expect(reloaded != null and normalized(reloaded) == before, "reload same upgraded result " + fault)
			# Corrupt the newest slot: verified old source is still recoverable.
			adapter.data.save_backup = "corrupt"
			SaveManager.configure(content, adapter)
			var recovered: GameState = SaveManager.current_state()
			expect(recovered != null and recovered.economy.jobs == session.state.economy.jobs, "recover previous valid generation")
	# The share/import route uses the same original-byte archive as slot loading.
	var source := old_session()
	var encoded := SaveCodec.encode(source.state, old_content.content_version, META)
	var adapter := MemoryAdapter.new()
	SaveManager.configure(content, adapter)
	var imported := SaveManager.import_share_string(Marshalls.utf8_to_base64(encoded.json))
	expect(imported.ok and imported.state.economy.version == Supply.VERSION, "old share import creates supply candidate")
	expect(SaveManager.supply_pending(imported.state), "import awaits archive and verified commit")
	expect(SaveManager.save(imported.state, META).ok, "import candidate commit")
	expect(adapter.data.get("save_before_supply_" + String(encoded.json).sha256_text()) == encoded.json, "import preserves exact original share JSON")

func _test_caps_and_rebirth() -> void:
	var session := supply_session(4)
	session.state.buildings.core_storehouse_3 = 1
	session.state.buildings.core_storehouse_4 = 1
	var cap := IslandEconomy.home_cap(session.state, "stone_low", content.processing_catalog)
	expect(cap >= 25000, "payable ancestor capacity includes new storehouses")
	session.state.beasts = {"active": {"id": "iron_turtle", "stage": "mature", "exp": 0}, "cooldown_remaining": 0.0}
	expect(IslandEconomy.home_cap(session.state, "refined_iron", content.processing_catalog) == 3750, "turtle increases new home iron cap once")
	expect(IslandProgression.capacity(session.state, "deep") == 300, "turtle does not multiply local cap")
	var before := normalized(session.state)
	IslandEconomy.home_cap(session.state, "refined_iron", content.processing_catalog)
	expect(normalized(session.state) == before, "capacity read never initializes source chrono/beasts")
	for id in ["wood", "stone_mid", "formation_core"]: stock(session.state, id, 100)
	expect(send(session, "open_island", {"island_id": "deep"}).ok, "rebirth test island")
	expect(send(session, "configure_route", {"route_id": "deep_iron_home"}).ok, "rebirth test route")
	var reference := session.state.duplicate_state()
	var aggregate := session.state.duplicate_state()
	var partition := session.state.duplicate_state()
	TimeAdvancer.advance(reference, content, 600)
	OfflineClosedForm.advance(aggregate, content, 600)
	for i in range(6): OfflineClosedForm.advance(partition, content, 100)
	expect(normalized(reference) == normalized(aggregate), "full offline production and gathering exactly matches 600 authoritative ticks")
	expect(normalized(reference) == normalized(partition), "600 simulated seconds match six partitions across time/chrono boundaries")
	session.state = reference
	session.state.buildings.rebirth_lotus = 1
	stock(session.state, "formation_core", 50)
	expect(send(session, "reincarnate").ok, "fixture rebirth command with new cargo")
	expect(session.state.economy.islands.size() == 7 and session.state.economy.jobs.is_empty() and session.state.economy.trips.is_empty(), "rebirth retains seven empty industry slots")
	for id in ["deep", "ancient", "void"]:
		expect(session.state.economy.islands[id] == {"opened": false, "inventory": {}}, "rebirth clears local new island " + id)
	for id in ["mineral_focus", "ancient_focus", "void_focus", "core_storehouse_4"]:
		expect(int(session.state.buildings.get(id, 0)) == 0, "rebirth clears new facility " + id)
	expect(IslandEconomy.value(session.state, "home", "refined_iron") == 0, "rebirth cannot duplicate local or transit iron into home")
	expect(IslandEconomy.validate(session.state).is_empty(), "new life supply snapshot validates")
