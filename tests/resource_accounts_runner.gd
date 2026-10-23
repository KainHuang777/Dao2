extends SceneTree
var checks := 0
var failures := []
class FaultStore extends StorageAdapter:
	var data := {}
	var denied := false
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key, ""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if denied: return {"ok":false,"error":"ACCOUNTS_WRITE_DENIED"}
		data[key] = value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)
var content: GameContent
const META := {"save_id":"accounts-test", "saved_at_utc_ms":"100000", "settled_until_utc_ms":"100000", "sim_tick":"0"}
func _init() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func row(state: GameState, key: String) -> Dictionary: return state.life_ledger.current.accounts.rows.get(key, {})
func command(s: GameSession, type: String, payload: Dictionary = {}) -> Dictionary:
	return s.submit({"command_id":type + str(s.state.revision), "type":type, "expected_revision":s.state.revision, "payload":payload})
func equations(book: Dictionary, label: String) -> void:
	check(ResourceLedger.validate(book).is_empty(), label + " structural")
	for key in book.rows:
		var r: Dictionary = book.rows[key]
		var expected := ResourceLedger.amount(r.opening).add(ResourceAccountsView.total(r.income)).subtract(ResourceAccountsView.total(r.expense)).add(ResourceLedger.amount(r.adjustment))
		if expected.compare_to(ResourceLedger.amount(r.closing)) != 0: print("EQ ", label, " ", key, " expected=", expected.to_components(), " row=", r)
		check(expected.compare_to(ResourceLedger.amount(r.closing)) == 0, label + " equation " + key)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var s := GameSession.create_new_game(content, 17)
	check(s.get_resource_accounts().coverage == "complete", "new life coverage")
	s.state.resources.wood.unlocked = true
	var old := s.state.to_snapshot_dict()
	check(not command(s, "gather", {"resource_id":"missing"}).ok and old == s.state.to_snapshot_dict(), "rejection unchanged")
	check(command(s, "gather", {"resource_id":"wood"}).ok, "gather accepted")
	check(row(s.state, "home:wood").income.gather == "1", "gather gross")
	# The production clamps a contraction separately from attempts that never enter stock.
	ResourceLedger.change(s.state, "home", "wood", AmountCompat.from_number(100), AmountCompat.from_number(50), "production", AmountCompat.from_number(5))
	check(row(s.state, "home:wood").adjustment == "49" and row(s.state, "home:wood").overflow == "5", "contraction plus explicit external gap")
	for encounter in FortuneSystem.get_encounters():
		for option in encounter.options.size():
			var session := GameSession.create_new_game(content, 4)
			FortuneSystem.ensure_initialized(session.state)
			session.state.fortune.pending_encounter = encounter.duplicate(true)
			for id in session.state.resources: session.state.resources[id].value = AmountCompat.from_number(1000000)
			var result := session.resolve_fortune(option)
			if not result.ok: continue
			for id in result.events[0].receipt.resources:
				var receipt: Dictionary = result.events[0].receipt.resources[id]
				var r := row(session.state, "home:" + id)
				# A zero-effect option may legitimately have no category entries.
				check(r.expense.get("fortune", "0") == receipt.paid and r.income.get("fortune", "0") == receipt.gained and r.overflow == receipt.overflow, "receipt gross parity " + encounter.id)
			equations(session.get_resource_accounts(), "fortune")
	var mix := GameSession.create_new_game(content, 4)
	FortuneSystem.ensure_initialized(mix.state)
	mix.state.resources.wood.value = AmountCompat.from_number(100)
	mix.state.fortune.pending_encounter = {"id":"same", "title":"same", "options":[{"text":"same", "costs":{"wood":20}, "rewards":{"resources":{"wood":30}}}]}
	var result := mix.resolve_fortune(0)
	check(result.ok and row(mix.state, "home:wood").income.fortune == "30" and row(mix.state, "home:wood").expense.fortune == "20", "same transaction gross not net")
	var saved := SaveCodec.encode(mix.state, content.content_version, META)
	check(saved.ok, "encode")
	var decoded := SaveCodec.decode(saved.json)
	check(decoded.ok and decoded.state.life_ledger == mix.state.life_ledger, "JSON roundtrip")
	var deep := mix.get_resource_accounts()
	deep.rows.clear()
	check(not mix.get_resource_accounts().rows.is_empty(), "read API copy")
	var missing := mix.state.to_snapshot_dict()
	missing.life_ledger.current.erase("accounts")
	var migrated := SaveCodec._state_from_snapshot(missing)
	check(migrated.ok and not migrated.state.life_ledger.current.has("accounts"), "old schema5 not fabricated")
	migrated.state.total_elapsed_seconds = 600
	command(mix, "gather", {"resource_id":"wood"})
	ResourceLedger.change(migrated.state, "home", "wood", AmountCompat.from_number(110), AmountCompat.from_number(111), "gather")
	check(migrated.state.life_ledger.current.accounts.coverage == "partial" and migrated.state.life_ledger.current.accounts.started_at == 600, "import starts partial at observation")
	transport()
	parity()
	persistence(mix)
	limits(mix)
	print("LEDGER-1 ", checks, " checks failures=", failures)
	quit(0 if failures.is_empty() else 1)
func transport() -> void:
	var state := GameSession.create_new_game(content, 7).state
	state.economy = IslandEconomy.initial()
	state.economy.islands.wood.opened = true
	IslandEconomy._put(state, "wood", "wood", 100, "production", 100)
	IslandEconomy._put(state, "wood", "wood", 80, "transfer")
	check(row(state, "transit:wood").closing == "20", "cargo inventory")
	state.economy.trips["wood_ore"] = {"cargo":"20", "remaining":1}
	IslandEconomy._put(state, "ore", "wood", 20, "transfer")
	check(row(state, "transit:wood").closing == "0", "arrival clears transit")
	equations(state.life_ledger.current.accounts, "transport")
	var inc := AmountCompat.zero()
	var exp := AmountCompat.zero()
	for key in state.life_ledger.current.accounts.rows:
		if key.ends_with(":wood"):
			var r: Dictionary = row(state, key)
			inc = inc.add(ResourceAccountsView.total(r.income, false))
			exp = exp.add(ResourceAccountsView.total(r.expense, false))
	check(inc.serialize() == "100" and exp.serialize() == "0", "consolidated transfer excluded")
	state.economy.trips.clear()
	IslandEconomy._put(state, "wood", "wood", 2.1, "adjustment")
	IslandEconomy._put(state, "ore", "wood", 0.2, "adjustment")
	IslandEconomy._put(state, "wood", "wood", 2.0, "transfer", -0.1)
	state.economy.trips.wood_ore = {"version":1, "cargo":"0.1", "remaining":1}
	IslandEconomy._put(state, "ore", "wood", 0.2 + 0.1, "transfer", 0.1)
	check(row(state, "transit:wood").closing == "0", "fractional cargo never negative")
	check(ResourceLedger.validate(state.life_ledger.current.accounts).is_empty(), "fractional transport valid")
	# Local string serialization is part of the original committed inventory.
	IslandEconomy._put(state, "wood", "wood", 1999.998, "production", 1999.998)
	check(ResourceLedger.amount(row(state, "wood:wood").closing).compare_to(AmountCompat.from_number(IslandEconomy.value(state, "wood", "wood"))) == 0, "observe actual serialized local stock")
func parity() -> void:
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/ledger-1/parity-source.json"))
	check(decoded.ok, "offline fixture")
	if not decoded.ok: return
	for seconds in [1, 60, 240, 1800]:
		var a: GameState = decoded.state.duplicate_state()
		var b: GameState = decoded.state.duplicate_state()
		var online := TimeAdvancer.prepare_advance(a, content)
		var start_us := Time.get_ticks_usec()
		for tick in seconds: TimeAdvancer.advance(a, content, 1, online)
		var online_us := Time.get_ticks_usec() - start_us
		start_us = Time.get_ticks_usec()
		var result := OfflineClosedForm.advance(b, content, seconds)
		print("ACCOUNT_BENCH seconds=", seconds, " online_us=", online_us, " offline_us=", Time.get_ticks_usec() - start_us, " bytes=", LifeLedger.bytes(b.life_ledger.current.accounts))
		check(not result.get("unsupported", false), "optimized supported")
		var snapshot_a := a.to_snapshot_dict()
		var snapshot_b := b.to_snapshot_dict()
		snapshot_a.erase("life_ledger")
		snapshot_b.erase("life_ledger")
		check(JSON.stringify(SaveCodec._normalize_numbers(snapshot_a), "", true) == JSON.stringify(SaveCodec._normalize_numbers(snapshot_b), "", true), "economic and RNG parity " + str(seconds))
		equations(a.life_ledger.current.accounts, "online")
		equations(b.life_ledger.current.accounts, "offline")
		# Compare value contracts, not dictionary int/float JSON representation.
		var aa: Dictionary = a.life_ledger.current.accounts
		var bb: Dictionary = b.life_ledger.current.accounts
		check(aa.coverage == bb.coverage and aa.omitted == bb.omitted and aa.rows.keys() == bb.rows.keys(), "account coverage parity " + str(seconds))
		for key in aa.rows:
			for field in ["opening", "closing", "adjustment", "overflow"]:
				check(ResourceLedger.amount(aa.rows[key][field]).compare_to(ResourceLedger.amount(bb.rows[key][field])) == 0, "account Amount parity " + str(seconds) + key + field)
			for field in ["income", "expense"]:
				check(aa.rows[key][field].keys() == bb.rows[key][field].keys(), "account categories parity")
				for category in aa.rows[key][field]:
					check(ResourceLedger.amount(aa.rows[key][field][category]).compare_to(ResourceLedger.amount(bb.rows[key][field][category])) == 0, "account category Amount parity " + str(seconds) + key)

func limits(s: GameSession) -> void:
	for n in 200:
		ResourceLedger.change(s.state, "home", "fixture_" + str(n), AmountCompat.zero(), AmountCompat.from_number(n), "achievement")
	check(s.get_resource_accounts().rows.size() <= ResourceLedger.LIMIT and s.get_resource_accounts().coverage == "partial", "bounded omission")
	check(LifeLedger.bytes(s.get_resource_accounts()) <= ResourceLedger.BUDGET, "byte budget")
	s.state.buildings.rebirth_lotus = 1
	var previous := s.state.reincarnation_count + 1
	check(command(s, "reincarnate", {"mode":"normal"}).ok, "seal committed")
	check(not s.get_resource_accounts(previous).is_empty(), "sealed accounts API")
	check(s.get_resource_accounts().coverage == "complete", "new opening complete")
	check(LifeLedger.validate(s.state.life_ledger, s.state.reincarnation_count + 1).is_empty(), "sealed bounded valid")
	var stressed := GameSession.create_new_game(content, 8).state
	for n in 70:
		for category in ResourceLedger.CATEGORIES:
			if category == "transfer": continue
			ResourceLedger.change(stressed, "home", "bounded_" + str(n), AmountCompat.from_number(1), AmountCompat.from_number(2), category)
	check(LifeLedger.bytes(stressed.life_ledger.current.accounts) <= ResourceLedger.BUDGET, "multi-category byte budget")
	check(stressed.life_ledger.current.accounts.coverage == "partial", "multi-category omission visible")
	check(ResourceLedger.validate(stressed.life_ledger.current.accounts).is_empty(), "multi-category structure valid")
	var bad := s.get_resource_accounts()
	bad.version = 999
	check(ResourceLedger.validate(bad) == "ACCOUNTS_VERSION", "unknown version rejected")
	bad = s.get_resource_accounts()
	bad.rows["home:wood"].income["unknown"] = "1"
	check(ResourceLedger.validate(bad) == "ACCOUNTS_CATEGORY", "unknown category rejected")
	check(ResourceAccountsView.ratio(AmountCompat.try_parse("ee30").value, AmountCompat.try_parse("ee40").value) >= 0, "huge chart bounded")



func persistence(s: GameSession) -> void:
	var store := FaultStore.new()
	SaveManager.configure(content, store)
	check(SaveManager.save(s.state, META).ok, "persist initial")
	var original := s.state.to_snapshot_dict()
	store.denied = true
	check(not SaveManager.save(s.state, META).ok and s.state.to_snapshot_dict() == original, "denied save leaves ledger readable")
	check(not SaveManager.save(s.state, META).ok and s.state.to_snapshot_dict() == original, "failed retry never records again")
	store.denied = false
	check(SaveManager.save(s.state, META).ok and s.state.to_snapshot_dict() == original, "retry save only")
	SaveManager.configure(content, store)
	var loaded: GameState = SaveManager.current_state()
	check(loaded != null and loaded.life_ledger == s.state.life_ledger, "reload exact accounts")
	var newest := SaveManager.slots().active_slot()
	var bad: Dictionary = JSON.parse_string(store.data[newest])
	bad.state.life_ledger.current.accounts.version = 999
	bad.erase("checksum")
	bad.checksum = SaveCodec.compute_checksum(bad)
	var invalid := JSON.stringify(bad)
	store.data[newest] = invalid
	SaveManager.configure(content, store)
	check(SaveManager.current_state() != null and SaveManager.current_state().life_ledger == loaded.life_ledger, "account unknown version fallback generation")
	for slot in [SaveSlots.SLOT_MAIN, SaveSlots.SLOT_BACKUP]: store.data[slot] = invalid
	SaveManager.configure(content, store)
	check(SaveManager.current_state() == null and not SaveManager.save(s.state, META).ok, "two invalid account generations refuse overwrite")
	# Full-precision counters preserve repeated fractional flow near integer display rounding.
	var state := GameSession.create_new_game(content, 7).state
	for n in 2000:
		ResourceLedger.change(state, "home", "wood", AmountCompat.from_number(n * 0.999999), AmountCompat.from_number((n + 1) * 0.999999), "production", AmountCompat.from_number(0.999999))
	var r := row(state, "home:wood")
	check(ResourceLedger.amount(r.income.production).compare_to(AmountCompat.from_number(1999.998)) == 0, "fractional flow not display-rounded")
	check(r.overflow == "0", "floating addition residue is not lost production")
	equations(state.life_ledger.current.accounts, "fractions")

