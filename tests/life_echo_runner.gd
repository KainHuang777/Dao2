extends SceneTree
var checks := 0
var failures := []
var content: GameContent
const META := {"save_id":"echo-test", "saved_at_utc_ms":"100000", "settled_until_utc_ms":"100000", "sim_tick":"0"}
class Store extends StorageAdapter:
	var data := {}
	var denied := false
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key,""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if denied: return {"ok":false, "error":"ECHO_WRITE_DENIED"}
		data[key] = value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func canonical(value: Variant) -> String: return JSON.stringify(value, "", true)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var session := GameSession.create_new_game(content, 79)
	LifeEchoFixture.apply(session)
	var life: Dictionary = session.state.life_ledger.current
	var snapshot := canonical(session.state.to_snapshot_dict())
	var rows := LifeEcho.generate(life)
	check(rows.size() == 3 and LifeEcho.valid(rows), "three real-command chains valid")
	check(LifeLedger.validate(session.state.life_ledger, 1).is_empty(), "valid source ledger")
	for i in 30:
		check(rows == LifeEcho.generate(life), "stable deduplicated read")
	check(snapshot == canonical(session.state.to_snapshot_dict()), "reads preserve gameplay RNG/state")
	var replay_id: String = session.state.command_receipts.keys()[0]
	var replay := session.submit({"command_id":replay_id, "type":"resolve_fortune", "expected_revision":0, "payload":{"option_index":1}})
	check(replay.get("duplicate", false) and snapshot == canonical(session.state.to_snapshot_dict()), "actual command replay no duplicate echo/reward")
	# Exhaust all source presence combinations; a terminal alone cannot invent a past.
	var events: Array = life.events.duplicate(true)
	for mask in 1 << events.size():
		var probe := life.duplicate(true)
		probe.events = []
		for i in events.size():
			if mask & (1 << i): probe.events.append(events[i])
		var actual := LifeEcho.generate(probe)
		var kinds := []
		for event in probe.events: kinds.append(event.kind)
		var expected := int("cultivation_leveled_up" in kinds) + int("joined_sect" in kinds and "expedition_claimed" in kinds) + int("beast_acquired" in kinds and "beast_matured" in kinds)
		check(actual.size() == expected and LifeEcho.valid(actual), "presence mask " + str(mask))
	var probe := life.duplicate(true)
	probe.decisions.receipts[0].option_index = 0
	check(LifeEcho.generate(probe).size() == 2, "different choice no inscription")
	probe.decisions.receipts[0].option_index = 2
	check(LifeEcho.generate(probe).size() == 2, "third choice no inscription")
	probe.decisions.receipts[0].option_index = 1
	probe.decisions.receipts[0].at = 60.0
	check(LifeEcho.generate(probe).size() == 2, "same age ambiguous receipt ordering omitted")
	probe.decisions.receipts[0].at = 61.0
	check(LifeEcho.generate(probe).size() == 2, "reversed choice time omitted")
	probe = life.duplicate(true)
	probe.decisions.receipts[0].option = "同ID但內容已改"
	check(LifeEcho.generate(probe).size() == 2, "changed content cannot reuse choice identity")
	probe = life.duplicate(true)
	probe.decisions.receipts[0].life_id = 2
	check(LifeEcho.generate(probe).size() == 2, "different life receipt omitted")
	probe = life.duplicate(true)
	probe.events[-1].instance = "b".repeat(64)
	check(LifeEcho.generate(probe).size() == 2, "different beast instance omitted")
	probe.events[-1].instance = ""
	check(LifeEcho.generate(probe).size() == 2, "legacy beast missing identity omitted")
	probe = life.duplicate(true)
	probe.events[-1].subject = "cloud_dragon"
	check(LifeEcho.generate(probe).size() == 2, "different beast species omitted")
	probe = life.duplicate(true)
	probe.events.reverse()
	for i in probe.events.size(): probe.events[i].seq = i + 1
	check(LifeEcho.generate(probe).size() == 1, "reversed milestone order cannot qualify")
	probe = life.duplicate(true)
	probe.erase("decisions")
	check(LifeEcho.generate(probe).size() == 2, "old missing receipt no choice invented")
	for i in 12:
		LifeLedger.note(session.state, "beast_matured", "jade_fox", "repeat:" + str(i), 60, str(life.beast_instance))
	check(LifeEcho.generate(life) == rows, "repeated maturity keeps first chain once")
	var report := LifeReport.generate(life)
	check(LifeLedger.bytes(report) <= LifeLedger.TEXT_BYTES, "three echoes plus biography within 4KiB")
	var store := Store.new()
	SaveManager.configure(content, store)
	check(SaveManager.save(session.state, META).ok, "initial save")
	check(session.reincarnate().ok, "real reincarnation seals echoes")
	var frozen: String = session.state.life_ledger.archive[0].frozen_text
	check(LifeReport.read(session.state.life_ledger.archive[0]).echoes == rows, "actual final report frozen")
	check(LifeEcho.generate(session.state.life_ledger.current).is_empty(), "new life no inherited echoes")
	store.denied = true
	var before := canonical(session.state.to_snapshot_dict())
	for i in 2: check(not SaveManager.save(session.state, META).ok and before == canonical(session.state.to_snapshot_dict()), "denied retry no reseal/reward")
	store.denied = false
	check(SaveManager.save(session.state, META).ok and before == canonical(session.state.to_snapshot_dict()), "recovery only saves")
	SaveManager.configure(content, store)
	var loaded: GameState = SaveManager.current_state()
	check(loaded != null and loaded.life_ledger.archive[0].frozen_text == frozen, "durable frozen text")
	check(LifeReport.read(loaded.life_ledger.archive[0]).echoes == rows, "JSON source ages roundtrip")
	var excerpt: Dictionary = loaded.life_ledger.archive[0].duplicate(true)
	excerpt.events.clear()
	excerpt.erase("decisions")
	check(LifeReport.read(excerpt).echoes == rows, "frozen evidence survives source ring trimming")
	check(SaveManager.save(session.state, META).ok, "second sealed generation")
	store.data[SaveManager.slots().active_slot()] = "{"
	SaveManager.configure(content, store)
	check(SaveManager.current_state() != null and SaveManager.current_state().life_ledger.archive[0].frozen_text == frozen, "corrupt newest recovers frozen echoes from previous generation")
	var old: Dictionary = loaded.life_ledger.archive[0].duplicate(true)
	var old_report: Dictionary = JSON.parse_string(old.frozen_text)
	old_report.erase("echoes")
	old_report.erase("echo_version")
	old.frozen_text = canonical(old_report)
	check(not LifeReport.read(old).has("echoes"), "old sealed text never backfilled")
	var bad := report.duplicate(true)
	bad.echoes[0].sources = [null]
	old.frozen_text = canonical(bad)
	check(LifeReport.read(old).title_id == "unrecorded", "invalid frozen echo safe fallback")
	for invalid in [null, {}, [null], rows + rows]: check(not LifeEcho.valid(invalid), "invalid echo type/limit")
	await parity(session)
	print(JSON.stringify({"suite":"ATM-LIFE-C", "checks":checks, "failures":failures, "echo_bytes":LifeLedger.bytes(rows), "report_bytes":LifeLedger.bytes(report)}))
	quit(0 if failures.is_empty() else 1)

func parity(_session: GameSession) -> void:
	var seed := GameSession.create_new_game(content, 91)
	LifeEchoFixture.apply(seed)
	seed.state.abode_scenery = {}
	seed.state.economy = IslandEconomy.initial()
	# Remove fixture endpoints so advancement plus new committed commands must finish chains.
	seed.state.life_ledger.current.events = seed.state.life_ledger.current.events.slice(0, 2)
	seed.state.life_ledger.current.next_sequence = 3
	seed.state.beasts.active.stage = "growing"
	seed.state.beasts.active.exp = 990
	seed.state.beasts.cooldown_remaining = 0.0
	check(LifeEcho.generate(seed.state.life_ledger.current).is_empty(), "time parity begins with no completed echo")
	# Real expedition completion crossing in online and every offline path.
	seed.state.sect.active_expedition = {"name":"回程", "duration":7, "elapsed":0, "rewards":{"contribution":5}}
	var online := seed.state.duplicate_state()
	for i in 21: TimeAdvancer.advance(online, content, 1)
	var batch := seed.state.duplicate_state()
	TimeAdvancer.advance(batch, content, 21)
	var fast := seed.state.duplicate_state()
	var fast_result := OfflineClosedForm.advance(fast, content, 21)
	check(not fast_result.get("unsupported", false), "closed form exercised:" + str(fast_result))
	var offline := seed.state.duplicate_state()
	OfflineSettlement.settle(offline, content, 121000, 100000)
	var asynchronous := seed.state.duplicate_state()
	await OfflineCoordinator.compute_async(asynchronous, content, 121000, 100000, self)
	for other in [online, batch, fast, offline, asynchronous]:
		var continued := GameSession.new()
		continued.content = content
		continued.state = other
		continued.clock = GameClock.create(0)
		var claimed := continued.submit({"command_id":"parity-claim", "type":"claim_sect_expedition", "expected_revision":other.revision, "payload":{}})
		var fed := continued.submit({"command_id":"parity-feed", "type":"feed_beast", "expected_revision":other.revision, "payload":{}})
		check(claimed.ok and fed.ok, "time crossing followed by real claim and maturity")
		LifeLedger.note(other, "cultivation_leveled_up", "3:2", "parity-later-level", other.total_elapsed_seconds)
		check(LifeEcho.generate(other.life_ledger.current).size() == 3, "all chains finish after time progression")
	for other in [batch, fast, offline, asynchronous]:
		check(LifeEcho.generate(other.life_ledger.current) == LifeEcho.generate(online.life_ledger.current), "online/offline same echoes")
		var a: Dictionary = other.to_snapshot_dict()
		var b := online.to_snapshot_dict()
		a.erase("life_ledger")
		b.erase("life_ledger")
		check(canonical(a) == canonical(b), "time paths same economy/RNG")
