extends SceneTree
var checks := 0
var failures := []
class FaultStore extends StorageAdapter:
	var data := {}
	var denied := false
	func read(key: String) -> Dictionary: return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if denied: return {"ok": false, "error": "HISTORY_WRITE_DENIED"}
		data[key] = value
		return {"ok": true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}
	func exists(key: String) -> bool: return data.has(key)
var content: GameContent
const META := {"save_id":"history-test", "saved_at_utc_ms":"100000", "settled_until_utc_ms":"100000", "sim_tick":"0"}
func _init() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var s := GameSession.create_new_game(content, 17)
	LifeHistoryFixture.apply(s)
	check(LifeLedger.validate(s.state.life_ledger, 3).is_empty(), "synthetic records valid")
	check(not s.state.life_ledger.archive[0].has("history"), "missing old history not filled")
	var long_life: Dictionary = s.state.life_ledger.archive[1]
	check(long_life.until == 4800000 and long_life.history.samples.back().at == 4800000, "long life final age retained")
	check(long_life.history.samples[0].at == 0 and long_life.history.omitted > 0, "first observation and explicit thinning")
	check(long_life.history.samples.size() <= LifeHistory.LIMIT and LifeLedger.bytes(long_life.history) <= LifeHistory.BUDGET, "bounded sampling")
	var saved := SaveCodec.encode(s.state, content.content_version, META)
	check(saved.ok, "encode")
	var decoded := SaveCodec.decode(saved.json)
	check(decoded.ok and decoded.state.life_ledger == s.state.life_ledger, "exact history reload")
	var read := s.get_life_record()
	read.archive.clear()
	check(s.get_life_record().archive.size() == 2, "deep read copy")
	var before := s.state.to_snapshot_dict()
	var rejected := s.submit({"command_id":"bad", "type":"gather", "expected_revision":s.state.revision, "payload":{"resource_id":"missing"}})
	check(not rejected.ok and before == s.state.to_snapshot_dict(), "rejected command no sampling")
	var h: Dictionary = long_life.history
	for mutation in ["version", "amount", "time", "duplicate", "key", "limit", "negative", "shape"]:
		var bad: Dictionary = long_life.duplicate(true)
		match mutation:
			"version": bad.history.version = 2
			"amount": bad.history.samples[0].rows["home:wood"][0] = "NaN"
			"time": bad.history.samples[0].at = bad.until + 1
			"duplicate": bad.history.samples.append(bad.history.samples.back())
			"key": bad.history.samples[0].rows["other:wood"] = ["0", "1"]
			"limit":
				for n in 20: bad.history.samples.append(h.samples.back())
			"negative": bad.history.samples[0].rows["home:wood"][0] = "-1"
			"shape": bad.history.unknown = true
		check(not LifeHistory.validate(bad.history, bad).is_empty(), "reject " + mutation)
	for n in 4:
		var a := float(long_life.until) * n / 4
		var b := float(long_life.until) * (n + 1) / 4
		var interval := LifeHistory.interval(long_life, a, b)
		for point in interval.samples: check(float(point.at) >= a and float(point.at) <= b, "interval exact bounds")
		for event in interval.events: check(float(event.at) >= a and float(event.at) <= b, "event exact bounds")
	# Same supported one-second/optimized path, age-grid samples and Amount values.
	var source := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/ledger-1/parity-source.json"))
	check(source.ok, "owned parity source")
	var a: GameState = source.state.duplicate_state()
	var b: GameState = source.state.duplicate_state()
	a.life_ledger.current.erase("history")
	b.life_ledger.current.erase("history")
	TimeAdvancer.advance(a, content, 1800)
	var fast := OfflineClosedForm.advance(b, content, 1800)
	check(not fast.get("unsupported", false), "optimized supported")
	check(a.life_ledger.current.history.samples.size() == b.life_ledger.current.history.samples.size(), "online offline sample counts")
	for i in a.life_ledger.current.history.samples.size():
		var pa: Dictionary = a.life_ledger.current.history.samples[i]
		var pb: Dictionary = b.life_ledger.current.history.samples[i]
		check(pa.at == pb.at and pa.rows.keys() == pb.rows.keys(), "aligned age scope")
		for key in pa.rows:
			for field in 2:
				if pa.rows[key][field] == null or pb.rows[key][field] == null:
					check(pa.rows[key][field] == pb.rows[key][field], "unknown capacity parity")
					continue
				check(ResourceLedger.amount(pa.rows[key][field]).compare_to(ResourceLedger.amount(pb.rows[key][field])) == 0, "sample amount parity")
	var aa := a.to_snapshot_dict()
	var bb := b.to_snapshot_dict()
	aa.erase("life_ledger")
	bb.erase("life_ledger")
	check(JSON.stringify(SaveCodec._normalize_numbers(aa), "", true) == JSON.stringify(SaveCodec._normalize_numbers(bb), "", true), "economic RNG parity")
	var store := FaultStore.new()
	SaveManager.configure(content, store)
	check(SaveManager.save(s.state, META).ok, "persist initial")
	var original := s.state.to_snapshot_dict()
	store.denied = true
	for n in 2: check(not SaveManager.save(s.state, META).ok and original == s.state.to_snapshot_dict(), "denied retry read only")
	store.denied = false
	check(SaveManager.save(s.state, META).ok, "recover save")
	SaveManager.configure(content, store)
	check(SaveManager.current_state().life_ledger == s.state.life_ledger, "reload retained history and rewards")
	var newest := SaveManager.slots().active_slot()
	var invalid: Dictionary = JSON.parse_string(store.data[newest])
	invalid.state.life_ledger.current.history.version = 999
	invalid.erase("checksum")
	invalid.checksum = SaveCodec.compute_checksum(invalid)
	store.data[newest] = JSON.stringify(invalid)
	SaveManager.configure(content, store)
	check(SaveManager.current_state() != null, "unknown history alternate generation")
	for slot in [SaveSlots.SLOT_MAIN, SaveSlots.SLOT_BACKUP]: store.data[slot] = JSON.stringify(invalid)
	SaveManager.configure(content, store)
	check(SaveManager.current_state() == null and not SaveManager.save(s.state, META).ok, "both invalid refuse overwrite")
	# New unknown fields do not turn financial rewards into inferred values.
	var bad_settlement := s.state.life_ledger.duplicate(true)
	bad_settlement.archive[1].settlement.dao_heart = "-1"
	check(not LifeLedger.validate(bad_settlement, 3).is_empty(), "invalid sealed reward rejected")
	var huge := s.state.duplicate_state()
	huge.resources.wood.unlocked = true
	huge.resources.wood.value = AmountCompat.try_parse("ee30").value
	LifeHistory.observe(huge, content, true)
	check(huge.life_ledger.current.history.samples.back().rows["home:wood"][0] == "ee30", "huge amount stays encoded")
	check(LifeLedger.validate(huge.life_ledger, 3).is_empty(), "huge observation valid")
	var projected := GameSession.create_new_game(content, 42).state
	projected.resources.wood.unlocked = true
	projected.sect = {"techniques":{"storage_talisman":1}}
	projected.chrono = {}
	projected.beasts = {}
	var original_projection := projected.to_snapshot_dict()
	var cap := LifeHistory.observed_caps(projected, content)
	var base_caps := Production.compute_caps(content, projected.buildings, projected.era_id, projected.onboarding_version, projected.skills)
	check(cap.wood.compare_to(base_caps.wood.multiply(AmountCompat.from_number(1.1))) == 0, "capacity includes current sect multiplier")
	check(projected.to_snapshot_dict() == original_projection, "capacity observation does not initialise gameplay dictionaries")
	var retention := GameSession.create_new_game(content, 51)
	for n in 12:
		retention.state.buildings.rebirth_lotus = 1
		retention.state.total_elapsed_seconds = 1200
		check(ReincarnationRules.apply_reincarnation(retention.state, content, "normal", "retain" + str(n)).ok, "seal retention")
	check(retention.state.life_ledger.archive.size() == 9 and retention.state.life_ledger.archive[0].life_id == 4, "retains latest nine lives only")
	check(LifeLedger.bytes(retention.state.life_ledger) <= LifeLedger.TOTAL_BYTES and LifeLedger.validate(retention.state.life_ledger, 13).is_empty(), "nine lives within inherited total budget")
	print("REPORT-2 ", checks, " checks failures=", failures)
	quit(0 if failures.is_empty() else 1)

