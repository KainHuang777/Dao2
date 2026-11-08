extends SceneTree

var checks := 0
var failures: Array[String] = []
var serial := 0
const META := {"save_id":"hub-test","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var fail_key := ""
	var fail_hub := false
	func read(key: String) -> Dictionary:
		return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
	func write(key: String, payload: String) -> Dictionary:
		if (not fail_key.is_empty() and key.begins_with(fail_key)) or (fail_hub and payload.contains('"hub_version"')): return {"ok":false,"error":"injected hub save failure"}
		data[key] = payload
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"hub-"+str(serial),"type":kind,"expected_revision":s.state.revision,"payload":payload})

func session(formal := false) -> GameSession:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	check((IslandProgression.attach_supply(content) if formal else IslandProgression.attach(content)).ok,"content attach")
	var s := GameSession.create_new_game(content, 1)
	s.state.era_id = 3
	s.state.buildings.hut = 2
	s.state.buildings.stone_mine = 3
	s.state.buildings.herb_farm = 3
	for id in content.processing_catalog.resources:
		s.state.resources[id] = {"value":AmountCompat.zero(),"unlocked":true,"ever_obtained":false}
	IslandEconomy._put(s.state,"home","wood",100)
	IslandEconomy._put(s.state,"home","stone_low",100)
	check(send(s,"activate_islands",{"hub":formal}).ok,"activate islands")
	for island in ["wood","ore","herb"]: check(send(s,"open_island",{"island_id":island}).ok,"open "+island)
	return s

func tick(s: GameSession, seconds: int) -> void:
	for n in seconds: IslandEconomy.tick(s.state,s.content.processing_catalog)

func work(s: GameSession, lane: String, recipe: String, repeat := false) -> Dictionary:
	return send(s,"craft",{"island_id":lane,"recipe_id":recipe,"repeat":repeat})

func value(s: GameSession, resource: String, scope := "home") -> float:
	return IslandEconomy.value(s.state,scope,resource)

func _run() -> void:
	var s := session()
	check(not IslandEconomy.hub(s.state),"legacy activation retains old contract")
	IslandEconomy._put(s.state,"wood","wood",30)
	IslandEconomy._put(s.state,"wood","stone_low",15)
	IslandEconomy._put(s.state,"ore","stone_low",20)
	check(work(s,"wood","spirit_timber",true).ok,"legacy paid batch begins")
	check(send(s,"switch_processing",{"island_id":"wood","recipe_id":"spirit_timber","repeat":true}).ok,"legacy pending switch queued")
	check(send(s,"configure_route",{"route_id":"ore_wood","enabled":true,"reserve":"3","target":"27","level":1}).ok,"legacy custom route")
	tick(s,1)
	var original_trip: Dictionary = s.state.economy.trips.ore_wood.duplicate(true)
	var settings: Dictionary = s.state.economy.routes.ore_wood.duplicate(true)
	var before_local := value(s,"wood","wood")
	var before_home := value(s,"wood")
	check(send(s,"activate_hub").ok,"explicit migration")
	check(IslandEconomy.hub(s.state),"versioned hub active")
	check(not s.state.economy.routes.has("copper_home"),"legacy conversion leaves raw routes manual")
	check(s.state.economy.trips.ore_wood == original_trip and s.state.economy.routes.ore_wood == settings,"migration preserves trip and exact policy")
	check(value(s,"wood","wood") == before_local and value(s,"wood") == before_home,"migration no inventory move/grant/payment")
	check(s.state.economy.hub_legacy_jobs.has("wood"),"already paid batch keeps original output reservation")
	var encoded := SaveCodec.encode(s.state,s.content.content_version,META)
	check(encoded.ok,"migrated save encodes")
	var decoded := SaveCodec.decode(encoded.get("json",""))
	check(decoded.ok,"migrated save decodes")
	if decoded.ok: s.state = decoded.state
	tick(s,9)
	check(value(s,"spirit_timber","wood") == 1 and value(s,"spirit_timber") == 0,"legacy paid batch completes exactly once locally")
	check(not s.state.economy.hub_legacy_jobs.has("wood"),"legacy output marker drains")
	tick(s,1)
	check(not s.state.economy.trips.has("ore_wood"),"retired cargo arrives but never redeparts")
	check(s.state.economy.routes.ore_wood == settings,"retired policy retained unchanged")
	check(not send(s,"configure_route",{"route_id":"ore_wood","enabled":true}).ok,"retired route rejects new changes")
	check(send(s,"stop_processing",{"island_id":"wood"}).ok,"stop transitioned repeat")
	tick(s,10)
	# Every new lane consumes/produces at the hub while remaining independently timed.
	IslandEconomy._put(s.state,"home","wood",40)
	IslandEconomy._put(s.state,"home","stone_low",40)
	IslandEconomy._put(s.state,"home","black_copper",20)
	var timber_before := value(s,"spirit_timber")
	check(work(s,"wood","spirit_timber").ok,"hub timber starts")
	check(work(s,"ore","bronze_essence").ok,"parallel hub bronze starts")
	check(value(s,"wood") == 30 and value(s,"black_copper") == 10 and value(s,"stone_low") == 30,"both lanes pay hub inventory exactly once")
	check(IslandEconomy.reserved(s.state,"home","spirit_timber",s.content.processing_catalog)==1,"hub output reserved")
	check(IslandEconomy.reserved(s.state,"wood","spirit_timber",s.content.processing_catalog)==0,"new job no local output reservation")
	var view := IslandEconomy.manufacturing_view(s.state,s.content.processing_catalog)
	check(view.recipes.spirit_timber.island == "wood" and view.recipes.spirit_timber.output_island == "home" and view.recipes.spirit_timber.inputs.wood.source == "home","view distinguishes lane from inventory")
	tick(s,10)
	check(value(s,"spirit_timber")==timber_before+1 and value(s,"bronze_essence")==1,"parallel outputs delivered directly home")
	check(value(s,"spirit_timber","wood")==1,"old local product preserved alongside new output")
	check(IslandEconomy.validate(s.state).is_empty(),"hub state validates after jobs and old arrivals")
	# Local material is not spendable until a real shipment arrives.
	IslandEconomy._put(s.state,"home","black_copper",0)
	check(not work(s,"ore","bronze_essence").ok,"local ore cannot masquerade as home material")
	check(send(s,"configure_route",{"route_id":"copper_home","enabled":true,"reserve":"7","target":"10","level":1}).ok,"single-island home route can start")
	tick(s,1)
	check(value(s,"black_copper")==0 and s.state.economy.trips.has("copper_home"),"departure not arrival")
	tick(s,10)
	check(value(s,"black_copper")==10,"raw cargo really arrives home")
	check(work(s,"ore","bronze_essence").ok,"arrival supplies central manufacture")
	check(send(s,"configure_route",{"route_id":"copper_home","enabled":false,"reserve":"7","target":"10","level":1}).ok,"stop raw route")
	check(s.state.economy.routes.copper_home.reserve=="7" and s.state.economy.routes.copper_home.target=="10","toggle keeps custom policy")
	IslandEconomy._put(s.state,"home","spirit_grass_low",20)
	IslandEconomy._put(s.state,"home","lingli",200)
	var liquid_cap := IslandEconomy.home_cap(s.state,"liquid",s.content.processing_catalog)
	IslandEconomy._put(s.state,"home","liquid",liquid_cap-1)
	check(work(s,"herb","liquid").ok,"first parallel lane reserves final hub slot")
	check(not work(s,"home","liquid").ok,"second lane cannot overbook shared hub output capacity")
	check(IslandEconomy.validate(s.state).is_empty(),"shared reservations retain valid save")
	var invalid := s.state.duplicate_state()
	invalid.economy.hub_version = 99
	check(IslandEconomy.validate(invalid)=="ECONOMY_HUB_VERSION","unknown hub version rejected")
	var formal := session(true)
	check(IslandEconomy.hub(formal.state),"formal new activation defaults hub")
	check(IslandEconomy.route_defs(formal.state).has("copper_home"),"formal raw routes exposed")
	_test_persistence()
	_test_auto_haul()
	_browser_fixture()
	for failure in failures: push_error(failure)
	print("HUB ECONOMY: %d checks; failures=%s" % [checks,str(failures)])
	RunnerResult.finish(self,0 if failures.is_empty() else 1)

func _test_persistence() -> void:
	var s := session()
	var adapter := MemoryAdapter.new()
	SaveManager.configure(s.content,adapter)
	var before := JSON.stringify(s.state.to_snapshot_dict(),"",true)
	adapter.fail_key = SaveManager.HUB_ARCHIVE_KEY
	check(not SaveManager.activate_hub(s,META).ok,"archive failure reported")
	check(JSON.stringify(s.state.to_snapshot_dict(),"",true)==before,"archive failure leaves live state unchanged")
	adapter.fail_key = ""
	adapter.fail_hub = true
	check(not SaveManager.activate_hub(s,META).ok,"candidate write failure reported")
	check(JSON.stringify(s.state.to_snapshot_dict(),"",true)==before,"candidate failure leaves live state unchanged")
	var archive_key := ""
	for key in adapter.data:
		if String(key).begins_with(SaveManager.HUB_ARCHIVE_KEY): archive_key = key
	check(not archive_key.is_empty(),"candidate failure retains immutable original archive")
	adapter.data[archive_key] = "injected damaged archive bytes"
	adapter.fail_hub = false
	var committed := SaveManager.activate_hub(s,META)
	check(committed.ok,"retry migration succeeds")
	check(IslandEconomy.hub(s.state),"candidate committed to live only on success")
	check(not SaveManager.activate_hub(s,META).ok,"repeat migration refused")
	var original := SaveCodec.decode(adapter.data.get(committed.get("archive_key",""),""))
	check(original.ok and not IslandEconomy.hub(original.state),"recoverable original archive remains legacy")
	var rescued := false
	for key in adapter.data:
		if String(key).contains("_damaged_") and adapter.data[key] == "injected damaged archive bytes": rescued = true
	check(rescued,"retry preserves damaged bytes and repairs verified source archive")
	SaveManager.configure(s.content,adapter)
	var reloaded: GameState = SaveManager.load_state()
	check(reloaded != null and IslandEconomy.hub(reloaded),"saved hub survives reload")

func _test_auto_haul() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"auto haul supply content")
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json"))
	check(decoded.ok,"auto haul earned Era2 source")
	if not decoded.ok: return
	var prepared := IslandProgression.prepare_supply(content,decoded.state)
	check(prepared.ok,"auto haul source reconciles")
	if not prepared.ok: return
	var s := GameSession.new()
	s.content = content
	s.state = prepared.state
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	# Isolate a copper shortage from the earned opening fixture.
	IslandEconomy._put(s.state,"home","black_copper",0)
	var adapter := MemoryAdapter.new()
	SaveManager.configure(content,adapter)
	var before := s.state.to_snapshot_dict()
	var wood := value(s,"wood")
	var stone := value(s,"stone_low")
	check(not SaveManager.activate_islands(s,META,"herb").ok,"Era2 first opening rejects later island")
	check(s.state.to_snapshot_dict() == before,"rejected opening leaves stock and economy untouched")
	adapter.fail_hub = true
	check(not SaveManager.activate_islands(s,META,"ore").ok,"first opening reports rejected candidate write")
	check(s.state.to_snapshot_dict() == before,"rejected write leaves payment and route unpublished")
	adapter.fail_hub = false
	check(SaveManager.activate_islands(s,META,"ore").ok,"first opening retries successfully")
	check(value(s,"wood") == wood-20 and value(s,"stone_low") == stone-10,"opening pays exactly once")
	var route: Dictionary = s.get_view().transport.copper_home.settings
	check(route == {"enabled":true,"reserve":"0","target":"100","level":1},"opening immediately exposes the default copper route")
	check(s.state.economy.routes.get("raw_stone_home") == route and not s.state.economy.routes.has("wood_home"),"ore opens both its raw routes and leaves wood closed")
	var opened := s.state.to_snapshot_dict()
	check(not send(s,"open_island",{"island_id":"ore"}).ok and s.state.to_snapshot_dict() == opened,"repeated opening keeps stock and route")
	check(s.state.economy.jobs.is_empty() and s.state.economy.trips.is_empty(),"opening creates only the route policy")
	var full := s.state.duplicate_state()
	var catalog := content.processing_catalog
	IslandEconomy._put(full,"home","black_copper",IslandEconomy.home_cap(full,"black_copper",catalog))
	TimeAdvancer.advance(full,content,5)
	check(not full.economy.trips.has("copper_home") and IslandEconomy.transport_view(full,catalog).copper_home.reason == "DESTINATION_FULL","full destination prevents departure")
	IslandEconomy._put(full,"home","black_copper",0)
	TimeAdvancer.advance(full,content,1)
	check(full.economy.trips.has("copper_home"),"freeing destination storage resumes shipping")
	s.advance_time(1)
	var trip: Dictionary = s.get_view().transport.copper_home.trip
	check(int(trip.get("remaining",0)) == 10 and float(trip.get("cargo",0)) > 0 and float(trip.get("cargo",0)) <= 10,"automatic departure uses normal travel time and cargo limit")
	check(value(s,"black_copper") < 1 and work(s,"ore","bronze_essence").get("error") == "INSUFFICIENT_RESOURCE","cargo cannot be spent in transit")
	check(SaveManager.save(s.state,META).ok,"in-transit state persists")
	SaveManager.configure(content,adapter)
	var reloaded: GameState = SaveManager.load_state()
	check(reloaded != null and reloaded.economy.trips.get("copper_home") == trip,"reloaded cargo and timer match")
	if reloaded == null: return
	check(SaveManager.commit_supply_startup().ok,"finish any earned fixture startup reconciliation")
	s.state = reloaded
	var offline := reloaded.duplicate_state()
	s.advance_time(20)
	OfflineSettlement.settle(offline,content,21000,1000)
	check(s.state.economy == offline.economy and is_equal_approx(value(s,"black_copper"),IslandEconomy.value(offline,"home","black_copper")),"online and offline logistics agree from the same saved state")
	check(value(s,"black_copper") >= 10 and value(s,"bronze_essence") == 0,"copper arrives automatically and waits for player order")
	check(work(s,"ore","bronze_essence").ok,"player uses delivered copper for central manufacturing")
	s.advance_time(10)
	check(value(s,"bronze_essence") == 1 and value(s,"bronze_essence","ore") == 0,"finished bronze enters ancestor inventory")
	# Fund the route upgrade separately from the single-batch proof above.
	IslandEconomy._put(s.state,"home","spirit_timber",10)
	IslandEconomy._put(s.state,"home","bronze_essence",11)
	check(send(s,"configure_route",{"route_id":"copper_home","enabled":false,"reserve":"3","target":"27","level":2}).ok,"manual pause and upgrade on automatic route")
	var paused: Dictionary = s.state.economy.routes.copper_home.duplicate(true)
	check(send(s,"open_island",{"island_id":"wood"}).ok and s.state.economy.routes.get("wood_home") == route,"wood opening enables its own route")
	IslandEconomy._put(s.state,"home","wood",0)
	IslandEconomy._put(s.state,"home","stone_low",0)
	var deliveries: Array = s.advance_time(21).events
	for id in ["wood_home","raw_stone_home"]:
		check(deliveries.any(func(event: Dictionary) -> bool: return event.kind == "cargo_arrived" and event.route_id == id),"automatic delivery " + id)
	check(s.state.economy.routes.copper_home == paused and not s.state.economy.trips.has("copper_home"),"opening and ticks preserve paused custom policy")
	var saved := SaveManager.save(s.state,META)
	check(saved.ok,"custom policies persist: " + str(saved.get("error","")))
	SaveManager.configure(content,adapter)
	reloaded = SaveManager.load_state()
	check(reloaded != null and reloaded.economy.routes.copper_home == paused,"reload keeps stopped route, reserves, target and level")
	IslandEconomy._put(s.state,"home","black_copper",10)
	check(work(s,"ore","bronze_essence",true).ok,"player explicitly starts repeat manufacturing")
	s.advance_time(10)
	check(s.state.economy.jobs.get("ore",{}).get("status") == "INSUFFICIENT_RESOURCE","paid repeat job waits when the next batch lacks copper")
	paused.enabled = true
	paused.route_id = "copper_home"
	check(send(s,"configure_route",paused).ok,"player resumes copper shipping")
	s.advance_time(20)
	check(int(s.state.economy.jobs.get("ore",{}).get("remaining",0)) > 0 or value(s,"bronze_essence") > 2,"delivered copper resumes the existing repeat order")
	check(s.state.economy.trips.has("copper_home"),"reincarnation fixture has actual cargo")
	s.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),s.state)
	check(send(s,"reincarnate",{"mode":"normal"}).ok,"reincarnation commits normally")
	check(s.state.economy.routes.is_empty() and s.state.economy.trips.is_empty() and s.state.economy.jobs.is_empty() and not s.state.economy.islands.ore.opened,"reincarnation clears current-life openings, jobs and shipments")
	check(s.state.economy.get("hub_version") == IslandEconomy.HUB_AUTO_HAUL_VERSION,"next life retains the automatic opening policy")

func _browser_fixture() -> void:
	# Reuse the audited normal-command Era2 fixture; no injected resources.
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json"))
	check(decoded.ok,"earned Era2 browser fixture source")
	var content: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"browser formal supply attach")
	var prepared := IslandProgression.prepare_supply(content,decoded.state)
	check(prepared.ok,"browser fixture reconcile")
	if not prepared.ok: return
	var s := GameSession.new()
	s.content = content
	s.state = prepared.state
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	SaveManager.configure(content,MemoryAdapter.new())
	var now := str(int(Time.get_unix_time_from_system()*1000))
	var meta := {"save_id":"hub-browser","saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":str(int(s.state.total_elapsed_seconds))}
	check(SaveManager.activate_islands(s,meta).ok and IslandEconomy.hub(s.state),"live activation defaults hub transactionally")
	var encoded := SaveCodec.encode(s.state,content.content_version,meta)
	check(encoded.ok and SaveCodec.decode(encoded.get("json","")).ok,"browser hub fixture verified")
	if encoded.ok:
		var path := RunnerResult.output_path("res://hub-browser-start.json")
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(encoded.json)
		file.close()
		print("HUB_BROWSER_FIXTURE "+path)
