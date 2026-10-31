extends SceneTree
const META := {"save_id":"local", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var content: GameContent
var checks := 0
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
		if key == read_fail: return {"ok":false, "error":"injected_read"}
		return {"ok":data.has(key), "data":data.get(key,""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		writes += 1
		if key == fail: return {"ok":false, "error":"injected_write"}
		data[key] = ("{}" if key in [SaveSlots.SLOT_MAIN,SaveSlots.SLOT_BACKUP] else "damaged") if key == corrupt else value
		if key == hide_after_write: read_fail = key
		return {"ok":key != lost_response, "error":"response_lost" if key == lost_response else ""}
	func exists(key: String) -> bool: return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}

func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ",label)
func same(a: Variant, b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a)) == JSON.parse_string(JSON.stringify(b))
func fresh() -> GameSession:
	var s := GameSession.create_new_game(content,20261030)
	s.state.era_id = 2
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	s.state.sect.sect_name = "天劍聖宗"
	s.state.sect.sect_id = "taixu_sect" # Actual old bug, resolved by official name.
	s.state.sect.contribution = "5000"
	s.state.sect.techniques = {"divine_farm":3}
	s.state.resources.stone_low.value = AmountCompat.from_number(1000)
	s.state.sect.available_tasks = [{"id":"legacy-task", "duration":60,"elapsed":0,"rewards":{"money":50,"contribution":15},"name":"舊委託"}]
	return s
func seed_store(mem: StorageAdapter, s: GameSession) -> String:
	var encoded := SaveCodec.encode(s.state,content.content_version,META)
	check(encoded.ok,"fixture encode " + str(encoded.get("error")))
	var raw: String = " \n" + encoded.get("json", "") + "\n"
	check(mem.write(SaveSlots.SLOT_MAIN,raw).ok,"seed original")
	SaveManager.configure(content,mem)
	return raw
func cmd(s: GameSession, kind: String, payload := {}, id := "test-command") -> Dictionary:
	return {"command_id":id,"expected_revision":s.state.revision,"type":kind,"payload":payload}
func ready(mem: Memory) -> GameSession:
	var s := fresh()
	seed_store(mem,s)
	var result := SaveManager.activate_sect_reform(s,META)
	check(result.ok,"activate " + str(result.get("error")))
	return s

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach supply")
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--readback":
		_file_readback(args[1])
		quit(0 if failures.is_empty() else 1)
		return
	_migrations()
	_crash_recovery()
	_legacy_chain()
	_commands()
	_lineage_and_rebirth()
	_hub_preservation()
	_validation()
	_file_roundtrip()
	await _native_boot()
	SaveManager.reset_for_tests()
	var output := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/save.json")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("SECT-REFORM-SAVE ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)

func _native_boot() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/native-" + str(Time.get_ticks_usec()))
	var abode = script.new()
	root.add_child(abode)
	for n in 300:
		if abode.session != null and abode.feature_navigation != null: break
		await process_frame
	check(abode.session != null,"normal native startup completes")
	if abode.session != null:
		abode.set_process(false)
		check(SectReformRelease.active(abode.session.state) and SectReformRelease.validate(abode.session.state).is_empty(),"normal startup commits complete schema6 release")
		check(not SaveManager.migration_pending(abode.session.state),"startup only opens commands after commit")
		var saved := SaveManager.slots().read_best(func(raw: String) -> int:
			var decoded := SaveCodec.decode(raw)
			return decoded.state.revision if decoded.ok else -1)
		check(saved.ok and SectReformSave.active(SaveCodec.decode(saved.json).state),"native startup marker durable")
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	SaveManager.reset_for_tests()

func _lineage_and_rebirth() -> void:
	for fault in ["write","hidden","response"]:
		var mem := Memory.new(); var s := ready(mem)
		# Eligibility fixture; the actual settlement and purchases use commands.
		s.state.sect.lineage.life_claimed = 3
		s.state.beasts = {"active":{"id":"jade_fox","exp":1000,"stage":"mature"},"cooldown_remaining":0}
		s.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),s.state)
		check(SaveManager.save(s.state,META).ok,"eligible source committed")
		var before := s.state.to_snapshot_dict()
		var target := SaveSlots.SLOT_BACKUP
		if fault == "write": mem.fail = target
		if fault == "hidden": mem.hide_after_write = target
		if fault == "response": mem.lost_response = target
		var command := cmd(s,"reincarnate",{},"one-rebirth")
		var result := s.submit(command)
		if fault != "response":
			check(not result.ok and same(before,s.state.to_snapshot_dict()),"rebirth failure atomic " + fault)
			mem.fail = ""; mem.hide_after_write = ""; mem.read_fail = ""
			result = SaveManager.save(s.state,META)
		check(result.ok,"rebirth retry/response readback " + fault)
		check(s.state.reincarnation_count == 1 and s.state.sect.lineage.completed_lives.tianjian_sect == 1,"one effective life")
		check(s.state.beast_souls.get("jade_fox") == 1,"one original species soul")
		check(s.state.achievements.unlocked.has("sect_tianjian_lineage_1"),"title in same commit")
		var after := s.state.to_snapshot_dict()
		SaveManager.configure(content,mem); s.state = SaveManager.current_state()
		var duplicate := s.submit(command)
		check(duplicate.get("duplicate",false) and same(after,s.state.to_snapshot_dict()),"rebirth durable dedup")
		check(duplicate.get("replayed",{}).get("reward",{}).get("dao_heart") == "15","durable Amount receipt uses value")
		var buy := cmd(s,"learn_talent",{"talent_id":"tianjian_lineage"},"lineage-buy")
		var wallet := s.state.dao_heart.serialize()
		mem.fail = SaveSlots.SLOT_MAIN
		check(not s.submit(buy).ok and s.state.dao_heart.serialize() == wallet,"lineage purchase failure atomic")
		mem.fail = ""
		check(SaveManager.save(s.state,META).ok and SectLineage.rank(s.state,"tianjian_lineage") == 1,"lineage retry one rank")
		check(s.state.dao_heart.compare_to(AmountCompat.from_number(10)) == 0,"lineage one five-heart payment")
		check(s.submit(buy).get("duplicate",false),"lineage durable receipt")
		var title := cmd(s,"claim_achievement",{"achievement_id":"sect_tianjian_lineage_1"},"title-claim")
		check(s.submit(title).ok and s.state.achievements.claimed.get("sect_tianjian_lineage_1",false),"title candidate claim")
		check(s.state.dao_heart.compare_to(AmountCompat.from_number(10)) == 0,"title pays no currency")
		SaveManager.reset_for_tests()

func _hub_preservation() -> void:
	var s := fresh()
	s.state.era_id = 3; s.state.buildings.hut = 2; s.state.buildings.stone_mine = 3; s.state.buildings.herb_farm = 3
	for id in content.processing_catalog.resources:
		s.state.resources[id] = {"value":AmountCompat.zero(),"unlocked":true,"ever_obtained":false}
	IslandEconomy._put(s.state,"home","wood",100)
	IslandEconomy._put(s.state,"home","stone_low",100)
	check(s.submit(cmd(s,"activate_islands",{"hub":true},"islands")).ok,"hub fixture activate")
	for island in ["wood","ore"]:
		check(s.submit(cmd(s,"open_island",{"island_id":island},"open-"+island)).ok,"hub fixture open")
	IslandEconomy._put(s.state,"home","black_copper",30)
	IslandEconomy._put(s.state,"ore","black_copper",30)
	check(s.submit(cmd(s,"craft",{"island_id":"ore","recipe_id":"bronze_essence","repeat":true},"paid-batch")).ok,"hub fixture paid batch")
	check(s.submit(cmd(s,"configure_route",{"route_id":"copper_home","enabled":true,"reserve":"3","target":"10","level":1},"cargo-policy")).ok,"hub fixture policy")
	IslandEconomy._put(s.state,"home","black_copper",0)
	IslandEconomy.tick(s.state,content.processing_catalog)
	check(not s.state.economy.trips.is_empty(),"hub fixture real cargo")
	var before := s.state.to_snapshot_dict()
	var mem := Memory.new(); var raw := seed_store(mem,s)
	check(SaveManager.activate_sect_reform(s,META).ok,"hub core migration")
	check(same(before.economy,s.state.economy) and same(before.resources,s.state.to_snapshot_dict().resources),"hub paid work/cargo/policy/inventory frozen")
	check(mem.data[SectReformSave.ARCHIVE_PREFIX+raw.sha256_text()] == raw,"hub original retained")
	var encoded := SaveCodec.encode(s.state,content.content_version,META)
	check(encoded.ok and JSON.parse_string(encoded.json).rules_version == SaveCodec.HUB_RULES_VERSION,"hub rules retain authority")
	SaveManager.reset_for_tests()

func _migrations() -> void:
	for fault in ["none","archive_write","archive_read","archive_corrupt","slot_write","slot_corrupt","slot_read","archive_lost","slot_lost","index","index_lost"]:
		var mem := Memory.new()
		var s := fresh()
		var raw := seed_store(mem,s)
		var before := s.state.to_snapshot_dict()
		var key := SectReformSave.ARCHIVE_PREFIX + raw.sha256_text()
		if fault == "archive_write": mem.fail = key
		if fault == "archive_read": mem.read_fail = key
		if fault == "archive_corrupt": mem.corrupt = key
		if fault == "slot_write": mem.fail = SaveSlots.SLOT_BACKUP
		if fault == "slot_corrupt": mem.corrupt = SaveSlots.SLOT_BACKUP
		if fault == "slot_read": mem.hide_after_write = SaveSlots.SLOT_BACKUP
		if fault == "archive_lost": mem.lost_response = key
		if fault == "slot_lost": mem.lost_response = SaveSlots.SLOT_BACKUP
		if fault == "index": mem.fail = SaveSlots.INDEX_KEY
		if fault == "index_lost": mem.lost_response = SaveSlots.INDEX_KEY
		var result := SaveManager.activate_sect_reform(s,META)
		if fault in ["archive_write","archive_read","archive_corrupt","slot_write","slot_corrupt","slot_read"]:
			check(not result.ok and same(before,s.state.to_snapshot_dict()),"failure live unchanged " + fault)
			check(SaveManager.migration_pending(s.state),"pending gate " + fault)
			check(SaveManager.sect_reform_original() == raw,"exact exportable original " + fault)
			check(Marshalls.base64_to_utf8(SaveManager.export_share_string(s.state,META)) == raw,"share exports immutable raw " + fault)
			check(not s.submit(cmd(s,"gather",{"resource_id":"wood"})).ok,"command blocked " + fault)
			check(not s.advance_time(1).ok,"time blocked " + fault)
			check(not OfflineCoordinator.settle_state(s.state,content,2000,1000).ok,"offline blocked " + fault)
			check(not SaveManager.import_share_string(Marshalls.utf8_to_base64(raw)).ok,"import blocked " + fault)
			check(not SaveManager.save(s.state.duplicate_state(),META).ok,"foreign candidate blocked " + fault)
			mem.fail = ""; mem.corrupt = ""; mem.read_fail = ""; mem.hide_after_write = ""
			result = SaveManager.save(s.state,META)
		check(result.ok and SectReformSave.active(s.state),"migration success/retry " + fault + str(result.get("error")))
		if not result.ok: continue
		check(mem.data[key] == raw and mem.data[SaveSlots.SLOT_MAIN] == raw,"original bytes retained " + fault)
		check(s.state.sect.sect_id == "tianjian_sect","canonical name authority")
		check(same(s.state.sect.available_tasks,before.sect.available_tasks),"no frozen task rewrite")
		check(same(s.state.sect.techniques,before.sect.techniques),"legacy investments")
		check(same(s.state.economy,before.economy) and same(s.state.beasts,before.beasts),"economy/beasts unchanged")
		check(s.state.sect.lineage.life_claimed == 0 and s.state.sect.lineage.completed_lives.tianjian_sect == 0,"no historic credit")
		if fault == "archive_corrupt": check(mem.data.get(key+"_damaged_"+"damaged".sha256_text()) == "damaged","damaged archive rescued")
		var snapshot := s.state.to_snapshot_dict()
		SaveManager.configure(content,mem)
		var loaded := SaveManager.current_state()
		check(loaded != null and same(snapshot,loaded.to_snapshot_dict()),"reload exact marker no gifts")
		check(not SaveManager.activate_sect_reform(s,META).ok,"no repeat activation")
		SaveManager.reset_for_tests()

func _crash_recovery() -> void:
	for durable in [false,true]:
		var mem := Memory.new(); var s := ready(mem)
		var before := s.state.to_snapshot_dict()
		if durable: mem.hide_after_write = SaveSlots.SLOT_MAIN
		else: mem.fail = SaveSlots.SLOT_MAIN
		var command := cmd(s,"learn_sect_technique",{"technique_id":"tianjian_ore_vein"},"crash-paid")
		check(not s.submit(command).ok,"simulate interrupted response")
		mem.fail = ""; mem.read_fail = ""; mem.hide_after_write = ""
		SaveManager.configure(content,mem); s.state = SaveManager.current_state()
		if durable:
			check(s.state.sect.techniques.get("tianjian_ore_vein") == 1,"recover unindexed committed generation")
			check(s.submit(command).get("duplicate",false),"crash durable receipt")
		else:
			check(same(before,s.state.to_snapshot_dict()),"failed write reload last durable generation")
			check(s.submit(command).ok and s.state.sect.techniques.get("tianjian_ore_vein") == 1,"reapply only after nondurable crash")
		SaveManager.reset_for_tests()

func _legacy_chain() -> void:
	for schema in [2,3,4,5]:
		var s := fresh()
		s.state.sect_version = 0; s.state.beast_version = 0; s.state.talent_version = 2; s.state.pill_version = 1
		var encoded := SaveCodec.encode(s.state,content.content_version,META)
		var envelope: Dictionary = JSON.parse_string(encoded.json)
		envelope.schema_version = schema
		if schema < 5: envelope.state.erase("life_ledger")
		envelope.erase("checksum"); envelope.checksum = SaveCodec.compute_checksum(envelope)
		var raw := " \n" + JSON.stringify(envelope) + "\n"
		var mem := Memory.new(); mem.data[SaveSlots.SLOT_MAIN] = raw
		SaveManager.configure(content,mem)
		s.state = SaveManager.current_state()
		check(s.state != null,"old schema loads " + str(schema))
		if s.state == null: continue
		check(SaveManager.migration_pending(s.state),"older features have own startup gate")
		check(SaveManager.save(s.state,META).ok,"commit prior feature migration")
		check(SaveManager.activate_sect_reform(s,META).ok,"core follows complete older migration")
		check(mem.data.get("save_before_sect_"+raw.sha256_text()) == raw,"preexisting raw archive retained")
		check(s.state.sect.techniques.divine_farm == 3 and s.state.sect.lineage.completed_lives.tianjian_sect == 0,"old chain no lost investment/history backfill")
		SaveManager.reset_for_tests()
	# Unknown and unjoined old names are distinct and do not invent identity.
	for joined in [true,false]:
		var mem := Memory.new(); var s := fresh()
		s.state.sect.unlocked = joined; s.state.sect.sect_name = "未知古宗"
		seed_store(mem,s)
		check(SaveManager.activate_sect_reform(s,META).ok,"unknown/unjoined migration")
		check(SectIdentity.view(s.state.sect).identity_pending == joined and s.state.sect.sect_id == "","pending identity preserved")
		SaveManager.reset_for_tests()

func _commands() -> void:
	for fault in ["write","corrupt","hidden","response","index"]:
		var mem := Memory.new(); var s := ready(mem)
		var before := s.state.to_snapshot_dict()
		var target := SaveSlots.SLOT_MAIN
		if fault == "write": mem.fail = target
		if fault == "corrupt": mem.corrupt = target
		if fault == "hidden": mem.hide_after_write = target
		if fault == "response": mem.lost_response = target
		if fault == "index": mem.fail = SaveSlots.INDEX_KEY
		var command := cmd(s,"learn_sect_technique",{"technique_id":"tianjian_ore_vein"})
		var result := s.submit(command)
		if fault in ["write","corrupt","hidden"]:
			check(not result.ok and same(before,s.state.to_snapshot_dict()),"command failure keeps live " + fault)
			check(not s.submit(command).ok,"cannot replay pending")
			mem.fail = ""; mem.corrupt = ""; mem.read_fail = ""; mem.hide_after_write = ""
			result = SaveManager.save(s.state,META)
		check(result.ok and s.state.sect.techniques.get("tianjian_ore_vein") == 1,"paid command committed " + fault)
		check(s.state.sect.contribution == "4920" and s.state.resources.stone_low.value.compare_to(AmountCompat.from_number(995)) == 0,"exact single payment")
		var snapshot := s.state.to_snapshot_dict()
		check(s.submit(command).get("duplicate",false) and same(snapshot,s.state.to_snapshot_dict()),"live receipt dedup")
		SaveManager.configure(content,mem)
		s.state = SaveManager.current_state()
		check(s.submit(command).get("duplicate",false) and same(snapshot,s.state.to_snapshot_dict()),"reload receipt dedup")
		SaveManager.reset_for_tests()
	# Refresh draws only the frozen candidate's private RNG; retries never redraw.
	var mem := Memory.new(); var s := ready(mem)
	s.state.sect.next_refresh_seconds = 0
	var old_rng: int = s.state.sect.rng.state
	mem.fail = SaveSlots.SLOT_MAIN
	check(not s.submit(cmd(s,"refresh_sect_tasks",{},"rng-refresh")).ok,"refresh save rejected")
	check(s.state.sect.rng.state == old_rng,"live RNG unchanged on failure")
	mem.fail = ""
	check(SaveManager.save(s.state,META).ok,"refresh retry")
	check(s.state.sect.rng.state != old_rng and s.state.sect.available_tasks.size() == 3,"one frozen draw committed")
	SaveManager.reset_for_tests()

func _validation() -> void:
	var mem := Memory.new(); var s := ready(mem)
	for field in ["version","source_hash","save_id"]:
		var bad := s.state.duplicate_state()
		bad.sect.core_save[field] = 2 if field == "version" else "" if field == "save_id" else "invalid"
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"marker reject " + field)
	for value in [-1,1.5,true,"1",4294967296,INF,NAN]:
		var bad := s.state.duplicate_state(); bad.sect.rng.state = value
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"bounded RNG " + str(value))
	check(not s.submit({"command_id":"bad","expected_revision":s.state.revision,"type":"unknown","payload":{}}).ok,"whitelist")
	var stale := cmd(s,"learn_sect_technique",{"technique_id":"tianjian_ore_vein"}); stale.expected_revision -= 1
	check(not s.submit(stale).ok,"stale revision")
	SaveManager.reset_for_tests()

func _file_roundtrip() -> void:
	var path := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/file-store-" + str(Time.get_ticks_usec()))
	var adapter := FileStorageAdapter.new(path)
	var s := fresh(); var raw := seed_store(adapter,s)
	check(SaveManager.activate_sect_reform(s,META).ok,"file migration")
	check(s.submit(cmd(s,"learn_sect_technique",{"technique_id":"tianjian_ore_vein"},"file-paid")).ok,"file paid command")
	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/sect_reform_save_runner.gd","--","--readback",path],output,true)
	check(exit_code == 0,"new process readback " + str(output))
	check(adapter.read(SectReformSave.ARCHIVE_PREFIX+raw.sha256_text()).data == raw,"file original archive exact")
	SaveManager.reset_for_tests()

func _file_readback(path: String) -> void:
	SaveManager.configure(content,FileStorageAdapter.new(path))
	var s := GameSession.new(); s.content = content; s.clock = GameClock.create(0)
	s.state = SaveManager.current_state()
	check(s.state != null and SectReformSave.active(s.state),"child persisted marker")
	if s.state == null: return
	check(s.state.sect.techniques.get("tianjian_ore_vein") == 1 and s.state.sect.contribution == "4920","child paid exactly once")
	check(s.submit(cmd(s,"learn_sect_technique",{"technique_id":"tianjian_ore_vein"},"file-paid")).get("duplicate",false),"child durable receipt")
	print("SECT-REFORM-SAVE CHILD ",checks," checks failures=",JSON.stringify(failures))
