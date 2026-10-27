extends SceneTree
const META := {"save_id":"sect2-isolated","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}
var DIR := RunnerResult.output_path("res://docs/verification/artifacts/content-p2-sect/")
var checks := 0
var failures: Array[String] = []
var content: GameContent
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	var corrupt := ""
	var read_fail := ""
	func exists(key: String) -> bool: return data.has(key)
	func read(key: String) -> Dictionary:
		if key == read_fail: return {"ok":false,"error":"injected_read"}
		return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
	func write(key: String,value: String) -> Dictionary:
		if key == fail or fail == "*": return {"ok":false,"error":"injected_write"}
		data[key] = "bad-readback" if key == corrupt else value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ",label)
func fresh() -> GameState:
	return GameSession.create_new_game(content,20261025).state
func encode(state: GameState) -> String:
	var result := SaveCodec.encode(state,content.content_version,META)
	check(result.ok,"encode fixture "+str(result.get("error")))
	return result.get("json", "")
func changed(raw: String,field: String,value: Variant) -> String:
	var env: Dictionary = JSON.parse_string(raw)
	env.state[field] = value
	env.erase("checksum")
	env.checksum = SaveCodec.compute_checksum(env)
	return JSON.stringify(env)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach")
	for version in [0,1]:
		for imported in [false,true]:
			for fault in ["archive_write","archive_read","archive_corrupt","slot_write","slot_corrupt","index"]:
				var old := fresh()
				old.sect_version = version
				old.pill_version = 1
				old.talent_version = 2 # Concurrent migrations must retain their own source.
				SectSystem.ensure_sect_state(old)
				old.sect.contribution="123"
				old.sect.techniques={"divine_farm":3}
				old.sect.market_purchases={"herb_bundle":4}
				old.sect.available_tasks=[{"id":"legacy-frozen","name":"舊委託","desc":"原樣保留","duration":60,"elapsed":0,"rewards":{"contribution":15,"money":50,"herb":5}}]
				var raw := " \n"+encode(old)+"\n"
				var mem := Memory.new()
				mem.data[SaveSlots.SLOT_MAIN] = raw
				SaveManager.configure(content,mem)
				var candidate: GameState
				if imported:
					var result := SaveManager.import_share_string(Marshalls.utf8_to_base64(raw))
					check(result.ok,"import accepted")
					candidate = result.state
				else: candidate = SaveManager.current_state()
				if candidate == null:
					check(false,"candidate load "+SaveManager.load_error())
					continue
				check(candidate.sect_version == 2 and SaveManager.migration_pending(candidate),"sect2 pending")
				check(JSON.parse_string(JSON.stringify(candidate.sect))==JSON.parse_string(JSON.stringify(old.sect)),"migration preserves old ranks contribution counts frozen tasks")
				var session := GameSession.new()
				session.content = content
				session.state = candidate
				var before := candidate.to_snapshot_dict()
				check(not SaveManager.save(candidate.duplicate_state(),META).ok,"candidate identity required")
				check(not SaveManager.import_share_string(Marshalls.utf8_to_base64(raw)).ok,"second import cannot replace originals")
				check(SaveManager.import_legacy_text("{}").get("error")=="MIGRATION_PENDING","legacy import cannot bypass candidate")
				var cmd := {"command_id":"blocked","type":"gather","payload":{"resource_id":"wood"},"expected_revision":candidate.revision}
				check(not session.submit(cmd).ok and not session.advance_time(60).ok,"pending command/time blocked")
				check(not OfflineCoordinator.settle_state(candidate,content,61000,1000).ok and before == candidate.to_snapshot_dict(),"pending offline no mutation")
				var key := "save_before_sect_"+raw.sha256_text()
				if fault == "archive_write": mem.fail = key
				elif fault == "archive_read": mem.read_fail = key
				elif fault == "archive_corrupt": mem.corrupt = key
				elif fault == "slot_write": mem.fail = SaveSlots.SLOT_MAIN if imported else SaveSlots.SLOT_BACKUP
				elif fault == "slot_corrupt": mem.corrupt = SaveSlots.SLOT_MAIN if imported else SaveSlots.SLOT_BACKUP
				else: mem.fail = SaveSlots.INDEX_KEY
				var saved := SaveManager.save(candidate,META)
				check(not saved.ok and SaveManager.migration_pending(candidate) and before == candidate.to_snapshot_dict(),"failure retains candidate "+fault)
				check(not SaveManager.save(candidate,META).ok and before == candidate.to_snapshot_dict(),"repeat failure no reapply")
				mem.fail = ""
				mem.corrupt = ""
				mem.read_fail = ""
				check(SaveManager.save(candidate,META).ok and not SaveManager.migration_pending(candidate) and before == candidate.to_snapshot_dict(),"retry same candidate")
				check(mem.data.get(key) == raw and mem.data.get("save_before_talents_"+raw.sha256_text()) == raw and mem.data.get("save_before_pills_"+raw.sha256_text()) == raw,"concurrent exact archives")
				SaveManager.configure(content,mem)
				var loaded := SaveManager.current_state()
				check(loaded != null and loaded.sect_version == 2 and loaded.pills.is_empty() and loaded.pill_effects.is_empty(),"reload no gift")
				SaveManager.reset_for_tests()
	_test_validation()
	_test_concurrent_supply()
	_test_receipts()
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR+"save.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P2-SECT-SAVE ",checks," checks failures=",JSON.stringify(failures))
	print("RUNNER_RESULT status=%s exit=%d" % ["PASS" if failures.is_empty() else "FAIL",0 if failures.is_empty() else 1])
	quit(0 if failures.is_empty() else 1)
func task(id: String) -> Dictionary:
	var t: Dictionary = SectSystem.P2_TASKS[id]
	var cfg: Dictionary = SectSystem.RARITY_CONFIGS[t.rarity]
	var rewards: Dictionary = t.rewards.duplicate(true)
	rewards.contribution=cfg.contrib_min; rewards.money=int(50*float(cfg.reward_mult)*6)
	return {"id":"frozen-"+id,"template_id":id,"generation_era":6,"name":t.name,"desc":t.desc,"rarity":t.rarity,"rarity_name":cfg.name,"rarity_color":cfg.color,"duration":cfg.duration,"elapsed":0,"rewards":rewards}
func _test_validation() -> void:
	var good := fresh()
	SectSystem.ensure_sect_state(good)
	good.sect.techniques={"p2_pill_qi_conservation":5,"sacred_beast_feed_conservation":1}
	good.sect.market_purchases={"refined_iron_reserve":10,"ancient_herb_reserve":2}
	var raw := encode(good)
	check(SaveCodec.decode(raw).ok,"v2 roundtrip")
	check(JSON.parse_string(raw).rules_version==SaveCodec.STORY2_RULES_VERSION and JSON.parse_string(raw).schema_version==5,"sect rules schema5")
	for version in [0,1,3,true,1.5]: check(not SaveCodec.decode(changed(raw,"sect_version",version)).ok,"version rejects "+str(version))
	for field in ["techniques","market_purchases"]:
		for id in (SectSystem.P2_TECHNIQUES if field=="techniques" else SectSystem.P2_MARKET):
			for value in [-1,6 if field=="techniques" else 11,true,1.5,"1",INF,NAN]:
				var sect := good.sect.duplicate(true); sect[field]={id:value}
				check(not SectSaveContract.validate(2,sect).is_empty(),"bounded typed "+id)
			for version in [0,1]:
				var sect := good.sect.duplicate(true); sect[field]={id:0}
				check(not SectSaveContract.validate(version,sect).is_empty(),"old version no zero new ID")
	for id in SectSystem.P2_TASKS:
		var frozen := task(id)
		check(SectSaveContract.validate_task(frozen,2).is_empty(),"valid frozen "+id)
		for version in [0,1]: check(not SectSaveContract.validate_task(frozen,version).is_empty(),"old cannot new template")
		for field in ["template_id","name","desc","rarity","rarity_name","rarity_color","duration","generation_era"]:
			var bad := frozen.duplicate(true)
			bad[field] = "forged" if frozen[field] is String else 0
			check(not SectSaveContract.validate_task(bad,2).is_empty(),"forged field "+field+id)
		for resource in frozen.rewards:
			for value in [-1,true,1.5,"1",INF,NAN,1000001]:
				var bad := frozen.duplicate(true); bad.rewards[resource]=value
				check(not SectSaveContract.validate_task(bad,2).is_empty(),"forged reward "+resource)
		var bad := frozen.duplicate(true); bad.rewards.special_buff="epiphany"
		check(not SectSaveContract.validate_task(bad,2).is_empty(),"no extra buff")
		bad=frozen.duplicate(true); bad.rewards.money+=1
		check(not SectSaveContract.validate_task(bad,2).is_empty(),"exact money")
		bad=frozen.duplicate(true); bad.elapsed=bad.duration+1
		check(not SectSaveContract.validate_task(bad,2).is_empty(),"elapsed bound")
		var legacy := frozen.duplicate(true); legacy.erase("template_id")
		legacy.rewards={"money":50,"contribution":15,"refined_iron":2}
		check(not SectSaveContract.validate_task(legacy,2).is_empty(),"untagged legacy cannot high resource")
		legacy.template_id="home_supply_register"; legacy.name=SectSystem.P1_TASKS.home_supply_register.name
		check(not SectSaveContract.validate_task(legacy,2).is_empty(),"P1 cannot high resource")
		good.sect.available_tasks=[frozen]
		check(SaveCodec.decode(encode(good)).ok,"new task codec roundtrip "+id)
		good.sect.active_expedition=frozen.duplicate(true)
		check(not SaveCodec.encode(good,content.content_version,META).ok,"duplicate instance rejected")
		good.sect.active_expedition=null; good.sect.available_tasks=[]
	for payload in ["broken",changed(raw,"sect_version",3)]:
		var mem := Memory.new(); mem.data={SaveSlots.SLOT_MAIN:payload,SaveSlots.SLOT_BACKUP:payload}
		SaveManager.configure(content,mem)
		check(SaveManager.current_state()==null and not SaveManager.save(good,META).ok,"untrusted no overwrite")
		check(mem.data[SaveSlots.SLOT_MAIN]==payload and mem.data[SaveSlots.SLOT_BACKUP]==payload,"invalid original intact")
		SaveManager.reset_for_tests()
	# Sect-only migration names its gate, and missing version is historical v0.
	var old := fresh(); old.sect_version=0
	var original := encode(old)
	var envelope: Dictionary = JSON.parse_string(original)
	envelope.state.erase("sect_version"); envelope.erase("checksum"); envelope.checksum=SaveCodec.compute_checksum(envelope)
	original=JSON.stringify(envelope)
	var mem := Memory.new(); mem.data[SaveSlots.SLOT_MAIN]=original
	SaveManager.configure(content,mem)
	var candidate := SaveManager.current_state()
	check(candidate!=null and SaveManager.migration_error(candidate)=="SECT_SAVE_REQUIRED","missing version sect-only gate")
	check(SaveManager.commit_supply_startup().ok and mem.data.get("save_before_sect_"+original.sha256_text())==original,"startup commit exact source")
	SaveManager.reset_for_tests()
func _test_concurrent_supply() -> void:
	var old_content: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(old_content).ok,"old content attach")
	for imported in [false,true]:
		var old := GameSession.create_new_game(old_content,20261025)
		old.state.era_id=3
		check(CommandProcessor.apply(old_content,old.state,{"type":"activate_islands","payload":{}}).ok,"old economy activation")
		old.state.sect_version=1; old.state.pill_version=1; old.state.talent_version=2
		var raw_result := SaveCodec.encode(old.state,old_content.content_version,META)
		check(raw_result.ok,"old combined encode")
		var raw: String = raw_result.get("json","")
		var mem := Memory.new(); mem.data[SaveSlots.SLOT_MAIN]=raw
		SaveManager.configure(content,mem)
		var candidate: GameState
		if imported:
			var result := SaveManager.import_share_string(Marshalls.utf8_to_base64(raw))
			check(result.ok,"concurrent supply import")
			candidate=result.state
		else: candidate=SaveManager.current_state()
		check(candidate!=null and SaveManager.supply_pending(candidate) and SaveManager.migration_pending(candidate),"all pointers share prepared supply candidate")
		if candidate==null: continue
		var before := candidate.to_snapshot_dict()
		mem.fail="save_before_sect_"+raw.sha256_text()
		check(not SaveManager.save(candidate,META).ok and before==candidate.to_snapshot_dict(),"concurrent sect fault no reapply supply")
		mem.fail=""
		check(SaveManager.save(candidate,META).ok and not SaveManager.migration_pending(candidate),"concurrent commit releases all gates")
		for group in ["supply","sect","pills","talents"]: check(mem.data.get("save_before_"+group+"_"+raw.sha256_text())==raw,"concurrent exact original "+group)
		SaveManager.reset_for_tests()
func _test_receipts() -> void:
	var cases: Array = []
	for id in SectSystem.P2_TECHNIQUES: cases.append(["learn_sect_technique",{"technique_id":id}])
	for id in SectSystem.P2_MARKET: cases.append(["buy_sect_market_item",{"item_id":id}])
	for id in SectSystem.P2_TASKS: cases.append(["claim_sect_expedition",{"fixture":id}])
	for item in cases:
		var mem := Memory.new(); SaveManager.configure(content,mem)
		var session := GameSession.create_new_game(content,20261025)
		session.state.era_id=6; session.state.highest_era=6
		check(CommandProcessor.apply(content,session.state,{"type":"activate_islands","payload":{}}).ok,"receipt activation")
		for island in session.state.economy.islands: session.state.economy.islands[island].opened=true
		for id in session.state.resources: session.state.resources[id].value=AmountCompat.from_number(10000)
		session.state.resources.foundation_pill.value=AmountCompat.zero()
		for id in ["refined_iron","spirit_grass_1000y"]: session.state.resources[id].value=AmountCompat.zero()
		SectSystem.ensure_sect_state(session.state); session.state.sect.unlocked=true; session.state.sect.contribution="10000"
		var payload: Dictionary = item[1].duplicate(true)
		if payload.has("fixture"):
			var frozen := task(payload.fixture); frozen.elapsed=frozen.duration
			session.state.sect.active_expedition=frozen; payload={}
		var cmd := {"command_id":"paid-"+str(item),"type":item[0],"payload":payload,"expected_revision":session.state.revision}
		check(session.submit(cmd).ok,"per ID command "+str(item))
		var before := session.state.to_snapshot_dict()
		check(session.submit(cmd).get("duplicate",false) and before==session.state.to_snapshot_dict(),"same command dedup")
		mem.fail="*"
		check(not SaveManager.save(session.state,META).ok and not SaveManager.save(session.state,META).ok and before==session.state.to_snapshot_dict(),"paid save retries no mutation")
		mem.fail=""
		var saved := SaveManager.save(session.state,META)
		check(saved.ok,"save paid candidate "+str(saved.get("error")))
		SaveManager.configure(content,mem); session.state=SaveManager.current_state()
		check(session.state!=null and session.submit(cmd).get("duplicate",false),"reload receipt dedup")
		if session.state!=null: check(JSON.parse_string(JSON.stringify(before))==JSON.parse_string(JSON.stringify(session.state.to_snapshot_dict())),"roundtrip values stable")
		SaveManager.reset_for_tests()
