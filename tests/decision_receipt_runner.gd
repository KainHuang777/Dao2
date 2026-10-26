extends SceneTree
var checks := 0
var failures := []
var content: GameContent
const META := {"save_id":"decision-test", "saved_at_utc_ms":"100000", "settled_until_utc_ms":"100000", "sim_tick":"0"}
class FaultStore extends StorageAdapter:
	var data := {}
	var denied := false
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key,""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if denied: return {"ok":false,"error":"DECISION_WRITE_DENIED"}
		data[key] = value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)
func _init() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func command(session: GameSession, id: String, option: int, instance: String = "") -> Dictionary:
	return {"command_id": id, "type": "resolve_fortune", "expected_revision": session.state.revision, "payload": {"option_index": option, "instance_id": instance}}
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	for encounter in FortuneSystem.get_encounters():
		for option in encounter.options.size():
			for stock in [0, 0.1, 20, 1000000, 1e16, 1e30]:
				var session := GameSession.create_new_game(content, 17)
				var state := session.state
				FortuneSystem.ensure_initialized(state)
				state.fortune.pending_encounter = encounter.duplicate(true)
				for id in state.resources: state.resources[id].value = AmountCompat.from_number(stock)
				var before := state.to_snapshot_dict()
				var cmd := command(session, "choice", option, DecisionReceipt.pending_id(state))
				var result := session.submit(cmd)
				if not result.ok:
					check(state.to_snapshot_dict() == before, "rejected unchanged:" + encounter.id)
					continue
				var r: Dictionary = result.events[0].receipt
				check(r.life_id == 1, "same life")
				check(state.fortune.pending_encounter.is_empty(), "cleared")
				check(session.get_decision_book().receipts[0] == r, "single authority")
				check(LifeLedger.validate(state.life_ledger, 1).is_empty(), "valid:" + encounter.id + ":" + str(option))
				var snapshot := state.to_snapshot_dict()
				check(session.submit(cmd).get("duplicate", false) and state.to_snapshot_dict() == snapshot, "command replay")
				check(not session.resolve_fortune(option).ok and state.to_snapshot_dict() == snapshot, "new command no repeat")
				var decoded := SaveCodec._state_from_snapshot(JSON.parse_string(JSON.stringify(snapshot)))
				check(decoded.ok and decoded.state.life_ledger == state.life_ledger, "roundtrip:" + encounter.id + ":" + str(option))
	# Same-resource debit and credit must remain two entries, even when net positive.
	var s := GameSession.create_new_game(content, 17)
	FortuneSystem.ensure_initialized(s.state)
	s.state.resources.wood.value = AmountCompat.from_number(100)
	s.state.fortune.pending_encounter = {"id": "synthetic", "title": "對帳", "options": [{"text": "交換", "costs": {"wood":20}, "rewards": {"resources":{"wood":30}, "training_seconds":3.5, "pills":{"cultivation_pill":1}, "buff_id":"epiphany"}}]}
	var old_id := DecisionReceipt.pending_id(s.state)
	var no := s.submit(command(s, "stale", 0, "f".repeat(64)))
	check(not no.ok and no.error == "STALE_PENDING_ENCOUNTER", "stale instance rejected")
	var result := s.submit(command(s, "mix", 0, old_id))
	var row: Dictionary = result.events[0].receipt.resources.wood
	check(row.paid == "20" and row.gained == "30" and row.after == "110" and row.overflow == "0", "gross not net; no added cap")
	check(not DecisionBookView.preview_text({"resources":{"herb":3,"lingqi":2},"pills":{"cultivation_pill":1}}).contains("herb"), "localized previews")
	var huge := GameSession.create_new_game(content, 18)
	FortuneSystem.ensure_initialized(huge.state)
	huge.state.resources.wood.value = AmountCompat.from_number(1e30)
	huge.state.fortune.pending_encounter = {"id":"precision", "title":"precision", "options":[{"text":"precision", "costs":{"wood":20}, "rewards":{"resources":{"wood":30}}}]}
	var huge_result := huge.resolve_fortune(0)
	var huge_row: Dictionary = huge_result.events[0].receipt.resources.wood
	check(huge_row.paid == "0" and huge_row.gained == "0" and huge_row.overflow == "30", "actual deltas at Amount precision boundary")
	persistence(s)
	var book := s.get_decision_book()
	book.receipts.clear()
	check(s.get_decision_book().receipts.size() == 1, "read deep copy")
	# Trigger/read/time do not replace a pending encounter or consume another draw.
	var enc := FortuneSystem.trigger_fortune(s.state)
	var id := DecisionReceipt.pending_id(s.state)
	var count := int(s.state.fortune.encounter_history_count)
	check(FortuneSystem.trigger_fortune(s.state) == enc and DecisionReceipt.pending_id(s.state) == id and int(s.state.fortune.encounter_history_count) == count, "pending direct trigger stable")
	s.advance_time(3)
	check(s.state.total_elapsed_seconds > 0 and DecisionReceipt.pending_id(s.state) == id, "world continues while pending")
	# Retained receipts are bounded; old entries omitted whole; seal uses original 32KiB.
	for n in 20:
		s.resolve_fortune(0)
		FortuneSystem.trigger_fortune(s.state)
	check(s.get_decision_book().receipts.size() == DecisionReceipt.LIMIT and int(s.get_decision_book().omitted) > 0, "bounded book")
	var sealed_id := s.state.reincarnation_count + 1
	LifeLedger.seal(s.state, "rebirth_lotus", "seal")
	s.state.reincarnation_count += 1
	StoryProgress.next_life(s.state) # Keep synthetic life fixture consistent with story v1.
	s.state.total_elapsed_seconds = 0
	LifeLedger.begin_next(s.state)
	check(not s.get_decision_book(sealed_id).is_empty() and s.get_decision_book().is_empty(), "archive keeps book next life missing")
	check(LifeLedger.validate(s.state.life_ledger, 2).is_empty(), "seal validity")
	var invalid := s.state.life_ledger.duplicate(true)
	invalid.archive[0].decisions.version = 999
	check(not LifeLedger.validate(invalid, 2).is_empty(), "unknown receipt version rejects")
	invalid = s.state.life_ledger.duplicate(true)
	invalid.archive[0].decisions.receipts[0].resources.values()[0].after = "-1"
	check(not LifeLedger.validate(invalid, 2).is_empty(), "corrupt amounts reject")
	# Receipt ring shares the original current/sealed byte budgets with milestone events.
	var dense := GameSession.create_new_game(content, 9).state
	for n in 64: LifeLedger.note(dense, "cultivation_leveled_up", "x".repeat(90), str(n), 0)
	var template: Dictionary = result.events[0].receipt.duplicate(true)
	for n in 12:
		template.life_id = 1
		template.instance_id = str(n).sha256_text()
		template.source = ("source" + str(n)).sha256_text()
		for key in ["option", "title", "log"]: template[key] = "字".repeat(600)
		DecisionReceipt.record(dense, template)
	check(LifeLedger.bytes(dense.life_ledger.current) <= LifeLedger.CURRENT_BYTES and DecisionReceipt.validate(dense.life_ledger.current.decisions, dense.life_ledger.current).is_empty(), "dense current budget")
	LifeLedger.seal(dense, "rebirth_lotus", "dense")
	check(LifeLedger.bytes(dense.life_ledger.archive[0]) <= LifeLedger.SEALED_BYTES and LifeLedger._validate_life(dense.life_ledger.archive[0], true).is_empty(), "dense seal budget")
	print("DECISION-1 ", checks, " checks failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)


func persistence(session: GameSession) -> void:
	var store := FaultStore.new()
	SaveManager.configure(content, store)
	check(SaveManager.save(session.state, META).ok, "receipt saved")
	var before := session.state.to_snapshot_dict()
	store.denied = true
	check(not SaveManager.save(session.state, META).ok and session.state.to_snapshot_dict() == before, "denied save no mutation")
	check(not SaveManager.save(session.state, META).ok and session.state.to_snapshot_dict() == before, "denied retry no mutation")
	store.denied = false
	check(SaveManager.save(session.state, META).ok and session.state.to_snapshot_dict() == before, "save retry only")
	SaveManager.configure(content, store)
	var loaded: GameState = SaveManager.current_state()
	check(loaded != null and loaded.life_ledger == session.state.life_ledger and loaded.resources.wood.value.serialize() == "110", "durable exact receipt")
	var newest := SaveManager.slots().active_slot()
	var bad: Dictionary = JSON.parse_string(store.data[newest])
	bad.state.life_ledger.current.decisions.version = 999
	bad.erase("checksum")
	bad.checksum = SaveCodec.compute_checksum(bad)
	var invalid := JSON.stringify(bad)
	store.data[newest] = invalid
	SaveManager.configure(content, store)
	check(SaveManager.current_state() != null and SaveManager.current_state().life_ledger == loaded.life_ledger, "unknown version fallback generation")
	for slot in [SaveSlots.SLOT_MAIN, SaveSlots.SLOT_BACKUP]: store.data[slot] = invalid
	SaveManager.configure(content, store)
	check(SaveManager.current_state() == null and not SaveManager.save(session.state, META).ok, "both invalid refuse overwrite")
