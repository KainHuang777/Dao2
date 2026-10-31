extends SceneTree
## BEAST-3 release migration and real persistence transactions. Fixtures are
## isolated, funded contracts; simulated time is not natural player progress.
const META := {"save_id": "beast3", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
var content: GameContent
var checks := 0
var four_task_payload_bytes := 0
var failures: Array[String] = []

class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	var corrupt := ""
	var read_fail := ""
	var lost_response := ""
	var hide_after_write := ""
	var writes := 0
	func read(key: String) -> Dictionary:
		if key == read_fail: return {"ok": false, "error": "injected_read"}
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		writes += 1
		if key == fail: return {"ok": false, "error": "injected_write"}
		data[key] = "broken" if key == corrupt else value
		if key == hide_after_write: read_fail = key
		return {"ok": key != lost_response, "error": "lost_response" if key == lost_response else ""}
	func exists(key: String) -> bool: return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}
	func clear_faults() -> void:
		fail = ""; corrupt = ""; read_fail = ""; lost_response = ""; hide_after_write = ""

func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ", label)
func dump(name: String, value: Variant) -> void:
	var path := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/" + name)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(value, "\t")); file.close()
func same(a: Variant, b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a)) == JSON.parse_string(JSON.stringify(b))
func fresh(era: int = 3) -> GameSession:
	var s := GameSession.create_new_game(content, 31)
	s.state.era_id = era; s.state.highest_era = era
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	SectIdentity.write(s.state.sect, "tianjian_sect")
	check(IslandProgression.command(content, s.state, "activate_islands", {}).ok, "canonical island fixture")
	s.state.economy.islands.herb.opened = true
	s.state.resources.spirit_grass_low.value = AmountCompat.from_number(5000)
	return s
func seed_store(adapter: StorageAdapter, s: GameSession) -> String:
	var encoded := SaveCodec.encode(s.state, content.content_version, META)
	check(encoded.ok, "seed encode " + str(encoded.get("error")))
	var raw: String = " \n" + encoded.get("json", "") + "\n"
	check(adapter.write(SaveSlots.SLOT_MAIN, raw).ok, "seed exact source")
	SaveManager.configure(content, adapter)
	return raw
func cmd(s: GameSession, kind: String, payload := {}, id := "command") -> Dictionary:
	return {"command_id": id, "expected_revision": s.state.revision, "type": kind, "payload": payload}
func ready(mem: StorageAdapter) -> GameSession:
	var s := fresh()
	seed_store(mem, s)
	check(SaveManager.activate_sect_reform_release(s, META).ok, "release activation")
	return s
func encoded(state: GameState) -> Dictionary: return SaveCodec.encode(state, content.content_version, META)
func readback(mem: StorageAdapter, s: GameSession) -> void:
	SaveManager.configure(content, mem)
	s.state = SaveManager.current_state()
	check(s.state != null and SectReformRelease.active(s.state), "reload complete release")
	if s.state != null: check(SectReformRelease.validate(s.state).is_empty(), "reload validates complete contract")

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "attach supply")
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--readback":
		_child_readback(args[1])
		RunnerResult.finish(self, 0 if failures.is_empty() else 1)
		return
	_rights()
	_migration_faults()
	_versions_and_old_schemas()
	_command_faults()
	_discovery_flow()
	_hub_and_core()
	_file_roundtrip()
	SaveManager.reset_for_tests()
	var output := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/release.json")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var report := FileAccess.open(output, FileAccess.WRITE)
	if report == null: check(false, "report write")
	else: report.store_string(JSON.stringify({"checks": checks, "four_task_payload_bytes": four_task_payload_bytes, "failures": failures}, "\t")); report.close()
	print("BEAST-3 checks=", checks, " failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func _rights() -> void:
	for era in [2, 3, 4, 5, 6, 8]:
		for opened in [false, true]:
			var s := fresh(era)
			s.state.economy.islands.deep.opened = opened
			s.state.economy.islands.ancient.opened = opened
			s.state.beasts = {"active": {"id": "jade_fox", "exp": 100, "stage": "young"}, "cooldown_remaining": 123.0}
			var before := s.state.to_snapshot_dict()
			var candidate := SectReformRelease.prepare(s.state, "source", "id")
			check(same(before, s.state.to_snapshot_dict()), "prepare leaves source unchanged")
			for id in BeastSystem.BEAST_CONFIGS:
				var expected: bool = id == "jade_fox" or BeastSystem.legacy_species_requirements(s.state, id).ok
				check(candidate.sect.guardian.legacy_permits.has(id) == expected, "independent historical eligibility " + id)
			check(candidate.beasts == s.state.beasts and candidate.sect.guardian.guardian_tokens == 0 and candidate.sect.guardian.permits.is_empty(), "old growth preserved, no free tokens/new permits")
			check(SectReformRelease.validate(candidate).is_empty(), "all grandfather candidates valid")
	for id in BeastSystem.BEAST_CONFIGS:
		for evidence in ["active", "soul", "talent"]:
			var s := fresh(2)
			if evidence == "active": s.state.beasts = {"active": {"id": id, "exp": 999, "stage": "growing"}, "cooldown_remaining": 77.0}
			elif evidence == "soul": s.state.beast_souls[id] = 7
			else:
				for talent_id in BeastSystem.BEAST_TALENTS:
					if BeastSystem.BEAST_TALENTS[talent_id].beast_id == id and BeastSystem.BEAST_TALENTS[talent_id].tier == 1: s.state.beast_talents[talent_id] = 1
			var candidate := SectReformRelease.prepare(s.state, "source", "id")
			check(candidate.sect.guardian.legacy_permits.has(id), "ownership preserves right below original era " + evidence + id)
			for old_id in s.state.beast_souls: check(candidate.beast_souls[old_id] == s.state.beast_souls[old_id], "old souls untouched")
			for talent_id in s.state.beast_talents: check(candidate.beast_talents[talent_id] == s.state.beast_talents[talent_id], "old talents untouched")
	var s := fresh(6)
	s.state.total_elapsed_seconds = 1e9
	s.state = SectReformRelease.prepare(s.state, "source", "id")
	check(s.state.sect.guardian.legacy_permits.has("iron_turtle") and s.state.sect.guardian.legacy_permits.has("fire_phoenix"), "exhaustion cannot revoke pre-update species rights")
	s.state.total_elapsed_seconds = 0
	check(BeastSystem.acquire_requirements(s.state, "iron_turtle").ok and BeastSystem.acquire_requirements(s.state, "fire_phoenix").ok, "legacy turtle/phoenix do not gain new source gates")
	s.state.era_id = 3
	check(not BeastSystem.acquire_requirements(s.state, "iron_turtle").ok, "legacy cannot bypass original era")
	s.state.era_id = 6; s.state.sect.guardian.legacy_permits.erase("iron_turtle")
	s.state.sect.guardian.permits.iron_turtle = true
	check(not BeastSystem.acquire_requirements(s.state, "iron_turtle").ok, "new turtle permit still requires deep")
	s.state.economy.islands.deep.opened = true
	check(BeastSystem.acquire_requirements(s.state, "iron_turtle").ok, "new turtle source gate satisfied")
	for id in GuardianBeasts.SPECIES:
		var candidate := SectReformRelease.prepare(fresh().state, "source", "id")
		check(not BeastSystem.acquire_requirements(candidate, id).ok, "new beasts never grandfathered")
		candidate.sect.guardian.permits[id] = true
		check(BeastSystem.acquire_beast(candidate, id).ok and candidate.beasts.active.id == id, "formal guardian acquisition " + id)
		check(not BeastSystem.acquire_beast(candidate, "jade_fox").ok, "one slot across eleven species")
		check(candidate.sect.guardian.permits[id] == true, "acquisition does not consume permit")
		check(encoded(candidate).ok and SaveCodec.decode(encoded(candidate).json).ok, "guardian active persists " + id)

func _migration_faults() -> void:
	for fault in ["archive_write", "archive_read", "archive_corrupt", "rescue", "write", "hidden", "response", "index"]:
		var mem := Memory.new(); var s := fresh(4)
		var raw := seed_store(mem, s)
		var key := SectReformSave.ARCHIVE_PREFIX + raw.sha256_text()
		if fault == "archive_write": mem.fail = key
		if fault == "archive_read": mem.read_fail = key
		if fault == "archive_corrupt": mem.corrupt = key
		if fault == "rescue": mem.data[key] = "wrong archive"; mem.fail = key + "_damaged_" + "wrong archive".sha256_text()
		if fault == "write": mem.fail = SaveSlots.SLOT_BACKUP
		if fault == "hidden": mem.hide_after_write = SaveSlots.SLOT_BACKUP
		if fault == "response": mem.lost_response = SaveSlots.SLOT_BACKUP
		if fault == "index": mem.fail = SaveSlots.INDEX_KEY
		var before := s.state.to_snapshot_dict()
		var result := SaveManager.activate_sect_reform_release(s, META)
		if fault in ["response", "index"]:
			check(result.ok and result.get("reconciled", false), "durable activation reconciled " + fault)
		else:
			check(not result.ok and same(before, s.state.to_snapshot_dict()), "migration failure preserves live " + fault)
			check(SaveManager.migration_pending(s.state), "whole candidate owns retry")
			var frozen: String = SaveManager._core_pending.json
			check(not s.submit(cmd(s, "gather", {"resource_id": "wood"})).ok and not s.advance_time(1).ok, "pending blocks all commands/time")
			check(Marshalls.base64_to_utf8(SaveManager.export_share_string(s.state)) == raw, "pending exports exact source")
			check(not SaveManager.import_share_string(Marshalls.utf8_to_base64(raw)).ok, "pending prevents replacement import")
			check(not SaveManager.save(s.state, META).ok and SaveManager._core_pending.json == frozen, "failed retry retains identical candidate")
			mem.clear_faults()
			check(SaveManager.save(s.state, META).ok, "same candidate retry succeeds " + fault)
		check(mem.data[key] == raw, "immutable source archive exact")
		check(SectReformRelease.active(s.state), "versions enabled only after commit")
		var write_count := mem.writes
		check(SaveManager.commit_sect_reform_startup().ok and mem.writes == write_count, "idempotent startup does not regrant")
		readback(mem, s)
		check(s.state.sect.guardian.guardian_tokens == 0, "migration gifts no tokens after reload")
		SaveManager.reset_for_tests()
	# Nondurable restart recreates the same candidate from the same original.
	for durable in [false, true]:
		var mem := Memory.new(); var s := fresh(4); seed_store(mem, s)
		if durable: mem.hide_after_write = SaveSlots.SLOT_BACKUP
		else: mem.fail = SaveSlots.SLOT_BACKUP
		check(not SaveManager.activate_sect_reform_release(s, META).ok, "interrupted activation")
		var frozen: String = SaveManager._core_pending.json
		mem.clear_faults(); SaveManager.configure(content, mem); s.state = SaveManager.current_state()
		if durable: check(SectReformRelease.active(s.state), "restart recognizes committed unindexed release")
		else:
			check(not SectReformRelease.active(s.state), "restart retains old generation")
			check(SaveManager.activate_sect_reform_release(s, META).ok, "restart migration")
		var best := SaveManager.slots().read_best(func(value: String) -> int: return SaveCodec.decode(value).state.revision if SaveCodec.decode(value).ok else -1)
		if best.ok and best.json != frozen:
			dump("restart-before.json", JSON.parse_string(frozen)); dump("restart-after.json", JSON.parse_string(best.json))
		check(best.ok and (best.json == frozen if durable else same(JSON.parse_string(best.json), JSON.parse_string(frozen))), "restart retains the same rights/seed, durable bytes exact")
		SaveManager.reset_for_tests()

func _versions_and_old_schemas() -> void:
	var mem := Memory.new(); var s := ready(mem)
	var raw: String = encoded(s.state).json
	var envelope: Dictionary = JSON.parse_string(raw)
	check(envelope.schema_version == 6 and envelope.rules_version == SectReformRelease.RULES_VERSION and envelope.content_version.ends_with("+sect-reform-1"), "schema6/rules26/content tag together")
	check(s.state.sect_version == 3 and s.state.talent_version == 4 and s.state.beast_version == 2, "feature version set 3/4/2")
	check(not TalentSystem.reconcile(s.state), "reconcile cannot downgrade talent4")
	var before_view := s.state.to_snapshot_dict()
	var view := BeastSystem.get_view(s.state)
	check(view.guardian_care.size() == 5 and view.acquire_requirements.size() == 11 and same(before_view, s.state.to_snapshot_dict()), "eleven-species View is read-only")
	for id in view.acquire_requirements: check(view.acquire_requirements[id] == BeastSystem.acquire_requirements(s.state, id), "View/command share acquire gates " + id)
	for field in ["sect_version", "talent_version", "beast_version"]:
		var bad := s.state.duplicate_state(); bad.set(field, int(bad.get(field)) - 1)
		check(not encoded(bad).ok, "mixed feature versions rejected " + field)
	for key in ["guardian_tokens", "permits", "legacy_permits", "version", "extra"]:
		var bad := s.state.duplicate_state(); bad.sect.guardian[key] = null
		check(not encoded(bad).ok, "invalid permanent ledger rejected " + key)
	for id in ["bogus", "taixu_baize"]:
		var bad := s.state.duplicate_state(); bad.sect.guardian.legacy_permits[id] = true
		check(not encoded(bad).ok, "legacy whitelist forbids fake/new species")
	for schema in [5, 7]:
		var bad: Dictionary = envelope.duplicate(true); bad.schema_version = schema
		bad.erase("checksum"); bad.checksum = SaveCodec.compute_checksum(bad)
		check(not SaveCodec.decode(JSON.stringify(bad)).ok, "schema downgrade/future rejected")
	for field in ["rules_version", "content_version"]:
		var bad: Dictionary = envelope.duplicate(true); bad[field] = "old"
		bad.erase("checksum"); bad.checksum = SaveCodec.compute_checksum(bad)
		check(not SaveCodec.decode(JSON.stringify(bad)).ok, "wrong release identity rejected")
	var measured := s.state.duplicate_state()
	measured.era_id = 6; measured.highest_era = 6
	measured.economy.islands.deep.opened = true; measured.economy.islands.ancient.opened = true
	measured.sect.active_expedition = SectSystem._generate_random_task(6, 1, measured.sect, measured)
	measured.sect.available_tasks = []
	for i in range(3): measured.sect.available_tasks.append(SectSystem._generate_random_task(6, i + 1, measured.sect, measured))
	four_task_payload_bytes = JSON.stringify(measured.sect).to_utf8_buffer().size()
	check(four_task_payload_bytes <= 32768 and encoded(measured).ok, "four frozen tasks fit existing32KiB bound")
	for field in ["schema_version", "talent_version"]:
		var fractional: Dictionary = envelope.duplicate(true)
		if field == "schema_version": fractional[field] = 6.0000001
		else: fractional.state[field] = 4.0000001
		fractional.erase("checksum"); fractional.checksum = SaveCodec.compute_checksum(fractional)
		check(not SaveCodec.decode(JSON.stringify(fractional)).ok, "fractional release version rejected exactly")
	SaveManager.reset_for_tests()
	var future: Dictionary = envelope.duplicate(true); future.schema_version = 7
	future.erase("checksum"); future.checksum = SaveCodec.compute_checksum(future)
	mem = Memory.new(); mem.data[SaveSlots.SLOT_MAIN] = JSON.stringify(future)
	mem.data[SaveSlots.SLOT_BACKUP] = raw
	var preserved: Dictionary = mem.data.duplicate(true)
	SaveManager.configure(content, mem)
	check(SaveManager.current_state() == null and SaveManager.load_error() == "SCHEMA_VERSION_UNKNOWN", "future schema blocks fallback overwrite")
	check(not SaveManager.save(s.state, META).ok and mem.data == preserved, "future raw slots preserved exactly")
	SaveManager.reset_for_tests()
	for schema in [2, 3, 4, 5]:
		s = fresh(); s.state.economy = {}; s.state.sect_version = 0; s.state.beast_version = 0; s.state.talent_version = 2
		envelope = JSON.parse_string(encoded(s.state).json); envelope.schema_version = schema
		if schema < 5: envelope.state.erase("life_ledger")
		envelope.erase("checksum"); envelope.checksum = SaveCodec.compute_checksum(envelope)
		raw = " \n" + JSON.stringify(envelope) + "\n"
		mem = Memory.new(); mem.data[SaveSlots.SLOT_MAIN] = raw; SaveManager.configure(content, mem)
		s.state = SaveManager.current_state()
		check(s.state != null, "legacy schema loads " + str(schema))
		if s.state == null: continue
		if SaveManager.migration_pending(s.state): check(SaveManager.save(s.state, META).ok, "prior feature chain commits")
		check(SaveManager.commit_sect_reform_startup().ok and SectReformRelease.active(SaveManager.current_state()), "normal startup migrates schema " + str(schema))
		SaveManager.reset_for_tests()

func _command_faults() -> void:
	for kind in ["redeem_guardian_permit", "acquire_beast", "feed_beast", "unlock_beast_talent", "claim_sect_expedition", "reincarnate"]:
		for fault in ["write", "hidden", "response", "index"]:
			var mem := Memory.new(); var s := ready(mem)
			s.state.sect.guardian.guardian_tokens = 24
			var payload := {}
			if kind == "redeem_guardian_permit": payload = {"target_id": "taixu_baize"}
			else: s.state.sect.guardian.permits.taixu_baize = true
			if kind in ["feed_beast", "reincarnate"]: check(BeastSystem.acquire_beast(s.state, "taixu_baize").ok, "funded owned beast fixture")
			if kind == "acquire_beast": payload = {"beast_id": "taixu_baize"}
			if kind == "unlock_beast_talent": s.state.beast_souls.taixu_baize = 1; payload = {"talent_id": "baize_t1_resonance"}
			if kind == "reincarnate":
				s.state.beasts.active.exp = 1000; s.state.beasts.active.stage = "mature"
				s.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(), s.state)
			if kind == "claim_sect_expedition":
				var task := SectSystem._generate_random_task(s.state.era_id, 1, s.state.sect, s.state)
				task.elapsed = task.duration; s.state.sect.active_expedition = task
			check(SaveManager.save(s.state, META).ok, "funded precommand snapshot")
			var target := SaveSlots.SLOT_MAIN if SaveManager.slots().active_slot() == SaveSlots.SLOT_BACKUP else SaveSlots.SLOT_BACKUP
			if fault == "write": mem.fail = target
			if fault == "hidden": mem.hide_after_write = target
			if fault == "response": mem.lost_response = target
			if fault == "index": mem.fail = SaveSlots.INDEX_KEY
			var command := cmd(s, kind, payload, kind + "-once")
			var before := s.state.to_snapshot_dict()
			var result := s.submit(command)
			if fault in ["write", "hidden"]:
				check(not result.ok and same(before, s.state.to_snapshot_dict()), "command failure atomic " + kind)
				var frozen: String = SaveManager._core_pending.json
				check(not SaveManager.save(s.state, META).ok and SaveManager._core_pending.json == frozen, "same candidate repeated retry " + kind)
				mem.clear_faults(); check(SaveManager.save(s.state, META).ok, "command retry commits " + kind)
			else: check(result.ok and result.get("reconciled", false), "durable command recovered " + kind)
			var after := s.state.to_snapshot_dict()
			check(s.submit(command).get("duplicate", false) and same(after, s.state.to_snapshot_dict()), "same receipt no second settlement " + kind)
			mem.clear_faults(); readback(mem, s)
			check(s.submit(command).get("duplicate", false), "reload durable receipt " + kind)
			if kind == "redeem_guardian_permit": check(s.state.sect.guardian.guardian_tokens == 12 and s.state.sect.guardian.permits.taixu_baize, "twelve charged exactly once")
			if kind == "feed_beast": check(s.state.beasts.active.exp == 50 and s.state.resources.spirit_grass_low.value.to_float() == 4950, "one feed exact XP/Amount")
			if kind == "unlock_beast_talent": check(s.state.beast_talents.baize_t1_resonance == 1 and s.state.beast_souls.taixu_baize == 0, "one same-species soul charged")
			if kind == "claim_sect_expedition": check(s.state.sect.guardian.guardian_tokens == 25 and s.state.sect.lineage.life_claimed == 1, "claim token and lineage only once")
			if kind == "reincarnate": check(s.state.reincarnation_count == 1 and s.state.beast_souls.taixu_baize == 1 and s.state.sect.guardian.permits.taixu_baize, "one rebirth soul and persistent permit")
			SaveManager.reset_for_tests()

func _discovery_flow() -> void:
	var mem := Memory.new(); var s := ready(mem)
	var task := {}
	for i in range(1000):
		task = SectSystem._generate_random_task(s.state.era_id, 1, s.state.sect, s.state)
		if not task.guardian_reward.permit_id.is_empty(): break
	check(not task.guardian_reward.permit_id.is_empty(), "actual private stream produced discovery")
	if task.guardian_reward.permit_id.is_empty(): return
	var id: String = task.guardian_reward.permit_id
	s.state.sect.available_tasks = [task]
	check(SaveManager.save(s.state, META).ok, "frozen discovered candidate saved")
	var frozen: Dictionary = task.guardian_reward.duplicate(true)
	readback(mem, s)
	check(same(s.state.sect.available_tasks[0].guardian_reward, frozen), "saved discovery never redraws")
	check(s.submit(cmd(s, "start_sect_expedition", {"task_id": task.id}, "start")).ok, "formal dispatch discovered task")
	SectSystem.tick(s.state, task.duration)
	check(s.submit(cmd(s, "claim_sect_expedition", {}, "claim")).ok, "formal discovery claim")
	check(s.state.sect.guardian.guardian_tokens == 1 and s.state.sect.guardian.permits.has(id) and s.state.beasts.get("active", {}).is_empty(), "new permit without auto acquisition")
	check(s.submit(cmd(s, "acquire_beast", {"beast_id": id}, "acquire")).ok, "choose discovered guardian")
	check(s.submit(cmd(s, "feed_beast", {}, "feed")).ok, "formal guardian feed")
	readback(mem, s)
	check(s.state.beasts.active.exp == 50 and s.state.beasts.active.id == id, "discovery/acquire/feed survives reload")
	for i in range(1, 20):
		BeastSystem.tick(s.state, 300)
		check(s.submit(cmd(s, "feed_beast", {}, "mature-feed-" + str(i))).ok, "durable feed to maturity")
	check(s.state.beasts.active.stage == "mature" and s.state.beasts.active.exp == 1000, "twenty actual feeds mature")
	s.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(), s.state)
	check(s.submit(cmd(s, "reincarnate", {}, "earned-beast-rebirth")).ok, "formal exhausted-life rebirth")
	check(s.state.beast_souls[id] == 1 and s.state.sect.guardian.permits.has(id), "one same-species soul, permanent permit survives")
	var talent_id: String = GuardianBeasts.SPECIES[id][1] + GuardianBeasts.SUFFIXES[0]
	check(s.submit(cmd(s, "unlock_beast_talent", {"talent_id": talent_id}, "earned-beast-t1")).ok, "earned soul pays same species T1")
	readback(mem, s)
	check(s.state.beast_talents[talent_id] == 1 and s.state.beast_souls[id] == 0 and s.state.reincarnation_count == 1, "next-life T1 survives save/reload")
	check(not BeastSystem.acquire_requirements(s.state, id).ok, "permanent permit cannot bypass next-life era/source")
	SaveManager.reset_for_tests()

func _hub_and_core() -> void:
	var mem := Memory.new(); var s := fresh(4)
	s.state.sect.techniques = {"divine_farm": 3}; s.state.sect.contribution = "5000"
	s.state.sect.available_tasks = [{"id": "legacy-dispatch", "name": "舊派遣", "duration": 60, "elapsed": 17, "rewards": {"money": 50, "contribution": 15}}]
	s.state.buildings.hut = 2; s.state.buildings.stone_mine = 3; s.state.buildings.herb_farm = 3
	for resource_id in content.processing_catalog.resources: s.state.resources[resource_id].unlocked = true
	check(IslandEconomy.activate_hub(s.state).ok, "hub fixture")
	s.state.economy.islands.ore.opened = true
	IslandEconomy._put(s.state, "home", "stone_low", 100)
	IslandEconomy._put(s.state, "home", "black_copper", 30)
	IslandEconomy._put(s.state, "ore", "black_copper", 30)
	check(ProcessingSystem.craft(content, s.state, {"island_id": "ore", "recipe_id": "bronze_essence", "repeat": true}).ok, "paid hub job fixture")
	check(IslandEconomy.command(content, s.state, "configure_route", {"route_id": "copper_home", "enabled": true, "reserve": "3", "target": "10", "level": 1}).ok, "real cargo policy")
	IslandEconomy._put(s.state, "home", "black_copper", 0)
	IslandEconomy.tick(s.state, content.processing_catalog)
	check(not s.state.economy.trips.is_empty(), "real cargo in transit")
	var before := s.state.to_snapshot_dict()
	seed_store(mem, s)
	check(SaveManager.activate_sect_reform_release(s, META).ok, "hub release migration")
	check(same(before.economy, s.state.to_snapshot_dict().economy) and same(before.resources, s.state.to_snapshot_dict().resources), "paid work/cargo/inventory unchanged")
	check(s.state.sect.available_tasks == before.sect.available_tasks and s.state.sect.techniques == before.sect.techniques, "legacy task and investments unchanged")
	SaveManager.reset_for_tests()
	# Existing CORE private stream and lineage are retained rather than reseeded.
	mem = Memory.new(); s = fresh(); seed_store(mem, s); check(SaveManager.activate_sect_reform(s, META).ok, "preexisting CORE")
	check(s.submit(cmd(s, "refresh_sect_tasks", {}, "core-refresh")).ok, "CORE-generated credit")
	var prior: Dictionary = s.state.sect.duplicate(true)
	check(SaveManager.activate_sect_reform_release(s, META).ok, "upgrade existing CORE")
	check(s.state.sect.rng == prior.rng and s.state.sect.lineage == prior.lineage and s.state.sect.available_tasks == prior.available_tasks and s.state.sect.core_save == prior.core_save, "existing seed/credit/source identity untouched")
	SaveManager.reset_for_tests()

func _file_roundtrip() -> void:
	var path := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/release-store-" + str(Time.get_ticks_usec()))
	var adapter := FileStorageAdapter.new(path); var s := ready(adapter)
	s.state.sect.guardian.guardian_tokens = 12
	check(SaveManager.save(s.state, META).ok, "file funded fixture")
	check(s.submit(cmd(s, "redeem_guardian_permit", {"target_id": "taixu_baize"}, "file-redeem")).ok, "file redeem")
	check(s.submit(cmd(s, "acquire_beast", {"beast_id": "taixu_baize"}, "file-acquire")).ok, "file acquire")
	check(s.submit(cmd(s, "feed_beast", {}, "file-feed")).ok, "file feed")
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/sect_reform_release_runner.gd", "--", "--readback", path], output, true)
	check(code == 0, "separate-process readback " + str(output))
	SaveManager.reset_for_tests()
func _child_readback(path: String) -> void:
	var adapter := FileStorageAdapter.new(path); var s := GameSession.new(); s.content = content; s.clock = GameClock.create(0)
	readback(adapter, s)
	if s.state == null: return
	check(s.state.sect.guardian.guardian_tokens == 0 and s.state.sect.guardian.permits.taixu_baize, "child permanent permit and exact token fee")
	check(s.state.beasts.active.id == "taixu_baize" and s.state.beasts.active.exp == 50 and s.state.resources.spirit_grass_low.value.to_float() == 4950, "child exact one acquisition/feed")
	for kind in ["redeem", "acquire", "feed"]:
		var command_type := "redeem_guardian_permit" if kind == "redeem" else "acquire_beast" if kind == "acquire" else "feed_beast"
		var payload := {"target_id": "taixu_baize"} if kind == "redeem" else {"beast_id": "taixu_baize"} if kind == "acquire" else {}
		check(s.submit(cmd(s, command_type, payload, "file-" + kind)).get("duplicate", false), "child receipt dedup " + kind)
	print("BEAST-3 CHILD checks=", checks, " failures=", JSON.stringify(failures))
