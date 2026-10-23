extends SceneTree

var checks := 0
var failures: Array[String] = []
var content: GameContent
const META := {"save_id": "ledger-test", "saved_at_utc_ms": "100000", "settled_until_utc_ms": "100000", "sim_tick": "0"}

class FaultStore extends StorageAdapter:
	var data := {}
	var denied := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if denied:
			return {"ok": false, "error": "QuotaExceededError"}
		data[key] = value
		return {"ok": true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func submit(session: GameSession, kind: String, payload: Dictionary, id: String) -> Dictionary:
	return session.submit({"type": kind, "payload": payload, "command_id": id, "expected_revision": session.state.revision})

func encoded(state: GameState) -> String:
	var result := SaveCodec.encode(state, content.content_version, META)
	check(result.ok, "encode:" + String(result.error))
	return result.json

func resigned(envelope: Dictionary) -> String:
	envelope.erase("checksum")
	envelope.checksum = SaveCodec.compute_checksum(envelope)
	return JSON.stringify(envelope)

func canonical(v: Variant) -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(v), "", true)

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var session := GameSession.create_new_game(content, 72)
	check(session.state.life_ledger.current.coverage == "complete", "new complete")
	var before := canonical(session.state.life_ledger)
	check(not submit(session, "upgrade_building", {"building_id": "not-real"}, "deny").ok, "reject command")
	check(canonical(session.state.life_ledger) == before, "rejection records nothing")
	for id in session.state.resources:
		session.state.resources[id].value = AmountCompat.from_number(10000000)
	check(submit(session, "upgrade_building", {"building_id": "hut"}, "build-hut").ok, "real hut build")
	check(session.state.life_ledger.current.events.size() == 1, "only hut fact")
	before = canonical(session.state.life_ledger)
	check(submit(session, "upgrade_building", {"building_id": "hut"}, "build-hut").duplicate, "duplicate receipt")
	check(canonical(session.state.life_ledger) == before, "duplicate not recorded")
	check(session.state.tribulation_seed == 72 and session.state.tribulation_roll_index == 0, "recorder no RNG")
	var clone := session.state.duplicate_state()
	clone.life_ledger.current.events[0].subject = "changed"
	check(session.state.life_ledger.current.events[0].subject == "hut", "deep copy")
	var decoded := SaveCodec.decode(encoded(session.state))
	check(decoded.ok and decoded.state.life_ledger == session.state.life_ledger, "codec native typed roundtrip")
	check(LifeLedger.coverage(GameState.new()) == "missing", "missing coverage")
	check(LifeLedger.coverage(session.state, "fortune_receipt") == "unsupported", "unsupported coverage")
	for schema in [2, 3, 4]:
		var old: Dictionary = JSON.parse_string(encoded(session.state))
		old.schema_version = schema
		old.state.erase("life_ledger")
		old.state.total_elapsed_seconds = 1234
		old.state.highest_era = 9
		var migrated := SaveCodec.decode(resigned(old))
		check(migrated.ok, "decode old schema" + str(schema))
		if migrated.ok:
			check(migrated.state.life_ledger.current.coverage == "partial", "old partial")
			check(migrated.state.life_ledger.current.started_at == 1234, "import boundary")
			check(migrated.state.life_ledger.current.peak.era_id == 1 and migrated.state.life_ledger.current.events.is_empty(), "no invented past or cross-life peak")
	var raw: Dictionary = JSON.parse_string(encoded(session.state))
	for mutate in ["version", "extra", "oversize", "sequence", "future", "unknown-kind", "missing"]:
		var bad := raw.duplicate(true)
		match mutate:
			"version": bad.state.life_ledger.version = 99
			"extra": bad.state.life_ledger.secret = "payload"
			"oversize": bad.state.life_ledger.current.frozen_text = "🌙".repeat(1025)
			"sequence": bad.state.life_ledger.current.events[0].seq = 0
			"future": bad.state.life_ledger.current.events[0].at = 999999
			"unknown-kind": bad.state.life_ledger.current.events[0].kind = "invented"
			"missing": bad.state.erase("life_ledger")
		check(not SaveCodec.decode(resigned(bad)).ok, "reject " + mutate)
	var tampered := raw.duplicate(true)
	tampered.state.life_ledger.current.coverage = "partial"
	check(SaveCodec.decode(JSON.stringify(tampered)).error == "CHECKSUM", "checksum before narrative")
	# Repeated advancement after a failure is distinct evidence, not first-only coalescing.
	LifeLedger.note(session.state, "era_breakthrough", "2:3", "before-failure", 0)
	LifeLedger.note(session.state, "tribulation_failed", "3:2", "failure", 0)
	LifeLedger.note(session.state, "era_breakthrough", "2:3", "after-failure", 0)
	check(session.state.life_ledger.current.events.size() == 4, "post-failure progress retained")
	var beast_session := GameSession.create_new_game(content, 11)
	beast_session.state.era_id = 3
	for resource_id in beast_session.state.resources:
		beast_session.state.resources[resource_id].value = AmountCompat.from_number(1000000)
	check(submit(beast_session, "acquire_beast", {"beast_id": "jade_fox"}, "acquire-one").ok, "real acquisition")
	beast_session.state.beasts.active.stage = "growing"
	beast_session.state.beasts.active.exp = 990
	check(submit(beast_session, "feed_beast", {}, "mature-one").ok, "real maturity")
	var beast_events: Array = beast_session.state.life_ledger.current.events
	check(beast_events.size() == 2 and beast_events[0].instance == beast_events[1].instance and not String(beast_events[0].instance).is_empty(), "same acquired instance")
	var read_copy := beast_session.get_life_record()
	read_copy.current.events.clear()
	check(beast_session.state.life_ledger.current.events.size() == 2, "read-only record API copy")
	await time_parity()
	archive_and_faults()
	limits()
	var result := {"checks": checks, "failures": failures, "schema": SaveCodec.SCHEMA_VERSION, "retained_lives": LifeLedger.RETAINED_LIVES}
	DirAccess.make_dir_recursive_absolute("res://docs/verification/artifacts/ledger-0")
	var file := FileAccess.open("res://docs/verification/artifacts/ledger-0/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

func time_parity() -> void:
	var seed := GameSession.create_new_game(content, 9).state
	seed.economy = IslandEconomy.initial()
	# Actual ready expedition crossing, without task RNG in the comparison.
	seed.sect = {"unlocked": true, "active_expedition": {"duration": 7, "elapsed": 0}, "next_refresh_seconds": 0}
	var online := seed.duplicate_state()
	for i in range(21):
		TimeAdvancer.advance(online, content, 1)
	var batch := seed.duplicate_state()
	TimeAdvancer.advance(batch, content, 21)
	var fast := seed.duplicate_state()
	var fast_result := OfflineClosedForm.advance(fast, content, 21)
	check(not fast_result.get("unsupported", false), "fast path exercised:" + str(fast_result))
	var offline := seed.duplicate_state()
	OfflineSettlement.settle(offline, content, 121000, 100000)
	var asynchronous := seed.duplicate_state()
	await OfflineCoordinator.compute_async(asynchronous, content, 121000, 100000, self)
	for other in [batch, fast, offline, asynchronous]:
		check(canonical(other.life_ledger) == canonical(online.life_ledger), "online/batch/fast/offline/async facts")
		var a: Dictionary = other.to_snapshot_dict()
		var b := online.to_snapshot_dict()
		a.erase("life_ledger")
		b.erase("life_ledger")
		check(canonical(a) == canonical(b), "economy and RNG unchanged across time modes")
	check(online.life_ledger.current.events[0].at == 7, "expedition exact crossing")
	check(online.life_ledger.current.events[0].kind == "expedition_completed", "completion not dispatch")
	# Exercise economic fast tick and ordinary tick with an actual trip.
	seed = GameSession.create_new_game(content, 9).state
	seed.economy = IslandEconomy.initial()
	# Select a real route ID rather than assuming the display label.
	var route_id: String = IslandEconomy.ROUTES.keys()[0]
	seed.economy.trips.clear()
	seed.economy.trips[route_id] = {"version": 1, "cargo": "1", "remaining": 5}
	online = seed.duplicate_state()
	batch = seed.duplicate_state()
	for i in range(12):
		TimeAdvancer.advance(online, content, 1)
	TimeAdvancer.advance(batch, content, 12)
	fast = seed.duplicate_state()
	fast_result = OfflineClosedForm.advance(fast, content, 12)
	check(not fast_result.get("unsupported", false), "transport fast path")
	for other in [batch, fast]:
		check(canonical(other.life_ledger) == canonical(online.life_ledger), "transport time parity")
	check(online.life_ledger.current.events[0].at == 5, "arrival exact second")
	check(LifeLedger.validate(fast.life_ledger, 1).is_empty(), "transport valid")
	# time-only lifespan has no phantom yields and shares exhausted fact.
	seed = GameSession.create_new_game(content, 9).state
	online = seed.duplicate_state()
	TimeAdvancer.advance_time_only(online, content, 1000000)
	check(online.life_ledger.current.events.back().kind == "lifespan_exhausted", "time-only exhaustion")
	check(LifeLedger.validate(online.life_ledger, 1).is_empty(), "time-only valid")
	var store := FaultStore.new()
	SaveManager.configure(content, store)
	check(SaveManager.save(seed, META).ok, "offline source save")
	store.denied = true
	before_offline_failure(seed)

func before_offline_failure(state: GameState) -> void:
	var before := canonical(state.to_snapshot_dict())
	var result := OfflineCoordinator.settle_state(state, content, 105000, 100000)
	check(not result.ok and not result.committed, "offline denial")
	check(canonical(state.to_snapshot_dict()) == before, "offline denial leaves source untouched")

func archive_and_faults() -> void:
	var session := GameSession.create_new_game(content, 11)
	var store := FaultStore.new()
	SaveManager.configure(content, store)
	check(SaveManager.save(session.state, META).ok, "baseline saved")
	for generation in range(12):
		session.state.buildings["rebirth_lotus"] = 1
		session.state.era_id = 3
		session.state.level = 7
		session.advance_time(3)
		var preview_before := canonical(session.state.to_snapshot_dict())
		session.get_reincarnation_preview()
		check(canonical(session.state.to_snapshot_dict()) == preview_before, "preview is read-only")
		# A fact after preview must be included in the real seal.
		LifeLedger.note(session.state, "pill_refined", "late-pill", "late-" + str(generation), session.state.total_elapsed_seconds)
		var result := submit(session, "reincarnate", {}, "rebirth-" + str(generation))
		check(result.ok, "reincarnation committed")
		var count: int = session.state.life_ledger.archive.size()
		check(count == mini(generation + 1, 9), "retain nine")
		var last: Dictionary = session.state.life_ledger.archive.back()
		check(last.life_id == generation + 1 and last.end_state.era_id == 3 and last.end_state.level == 7, "final facts before reset")
		check(last.events.back().subject == "late-pill", "fresh final fact")
		check(last.end_state.reason == "rebirth_lotus", "early not death")
		check(session.state.life_ledger.current.life_id == generation + 2 and session.state.life_ledger.current.events.is_empty(), "new life separate")
		var committed := canonical(session.state.to_snapshot_dict())
		store.denied = true
		check(not SaveManager.save(session.state, META).ok, "refused write")
		check(canonical(session.state.to_snapshot_dict()) == committed, "failed save retains readable outcome")
		store.denied = false
		check(SaveManager.save(session.state, META).ok, "save-only retry")
		check(canonical(session.state.to_snapshot_dict()) == committed, "retry no reward or seal mutation")
		check(submit(session, "reincarnate", {}, "rebirth-" + str(generation)).duplicate, "replayed rebirth")
		SaveManager.configure(content, store)
		var loaded: GameState = SaveManager.current_state()
		check(loaded != null and canonical(loaded.life_ledger) == canonical(session.state.life_ledger), "reload seal")
	check(session.state.life_ledger.archive.front().life_id == 4, "oldest three evicted")
	# Bad newest narrative must choose intact older slot, rather than discard history.
	var newest := SaveManager.slots().active_slot()
	var broken: Dictionary = JSON.parse_string(store.data[newest])
	broken.state.life_ledger.version = 99
	store.data[newest] = resigned(broken)
	SaveManager.configure(content, store)
	check(SaveManager.current_state() != null, "unknown narrative recovers alternate generation")
	for slot in [SaveSlots.SLOT_MAIN, SaveSlots.SLOT_BACKUP]:
		store.data[slot] = resigned(broken)
	SaveManager.configure(content, store)
	check(SaveManager.current_state() == null, "both unknown refuse replacement")
	check(not SaveManager.save(session.state, META).ok, "bad versions not overwritten")
	# Original bytes must survive migration and failed first save.
	store = FaultStore.new()
	var old: Dictionary = JSON.parse_string(encoded(session.state))
	old.schema_version = 4
	old.state.erase("life_ledger")
	var original := resigned(old)
	store.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(content, store)
	var migrated: GameState = SaveManager.current_state()
	check(migrated != null, "load schema4 migration")
	store.denied = true
	check(not SaveManager.save(migrated, META).ok, "migration backup refusal")
	check(store.data[SaveSlots.SLOT_MAIN] == original, "original not overwritten")
	store.denied = false
	check(SaveManager.save(migrated, META).ok, "migration retry")
	check(store.data.get("save_before_ledger_" + original.sha256_text()) == original, "exact pre-migration archive")

func limits() -> void:
	var state := GameSession.create_new_game(content, 4).state
	for i in range(1000):
		LifeLedger.note(state, "skill_learned", "修行🌙-" + str(i), "source-" + str(i), 0)
	check(state.life_ledger.current.events.size() == 64, "bounded events")
	check(state.life_ledger.current.omitted_count == 936, "omitted whole events")
	check(state.life_ledger.current.coverage == "partial", "omission visible")
	check(state.life_ledger.current.events.front().subject == "修行🌙-0", "first anchor survives")
	check(state.life_ledger.current.events.back().subject == "修行🌙-999", "latest survives")
	check(LifeLedger.validate(state.life_ledger, 1).is_empty(), "bounded unicode valid")
	var n: int = state.life_ledger.current.events.size()
	LifeLedger.note(state, "skill_learned", "🌙".repeat(100), "oversize", 0)
	check(state.life_ledger.current.events.size() == n and state.life_ledger.current.omitted_count == 937, "oversized whole omission")
	check(LifeLedger.bytes(state.life_ledger) <= LifeLedger.TOTAL_BYTES, "total byte budget")
	for event in state.life_ledger.current.events:
		check(LifeLedger.bytes(event) <= 384, "event UTF8 budget")
