extends SceneTree
const META := {"save_id":"beast1-isolated","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}
const DIR := "res://docs/verification/artifacts/content-p2-beasts/"
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
		if key==read_fail: return {"ok":false,"error":"injected_read"}
		return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
	func write(key: String,value: String) -> Dictionary:
		if key==fail or fail=="*": return {"ok":false,"error":"injected_write"}
		data[key]="bad-readback" if key==corrupt else value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		print("FAIL: ",label)
func fresh() -> GameState: return GameSession.create_new_game(content,20261026).state
func encode(state: GameState) -> String:
	var result:=SaveCodec.encode(state,content.content_version,META)
	check(result.ok,"encode fixture "+str(result.get("error")))
	return result.get("json","")
func changed(raw: String,field: String,value: Variant) -> String:
	var env: Dictionary=JSON.parse_string(raw)
	env.state[field]=value; env.erase("checksum"); env.checksum=SaveCodec.compute_checksum(env)
	return JSON.stringify(env)
func run() -> void:
	content=ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach")
	_validation()
	for imported in [false,true]:
		for combined in [false,true]:
			for fault in ["archive_write","archive_read","archive_corrupt","slot_write","slot_corrupt","index","rescue_write","rescue_read"]:
				var old:=fresh(); old.beast_version=0
				old.beasts={"active":{"id":"jade_fox","exp":1000,"stage":"mature"},"cooldown_remaining":300}
				old.beast_souls={"jade_fox":7}; old.beast_talents={"fox_t1_boost":1}
				if combined: old.sect_version=1; old.pill_version=1; old.talent_version=2
				var raw: String=" \n"+encode(old)+"\n"
				var mem:=Memory.new(); mem.data[SaveSlots.SLOT_MAIN]=raw
				SaveManager.configure(content,mem)
				var candidate: GameState
				if imported:
					var result:=SaveManager.import_share_string(Marshalls.utf8_to_base64(raw))
					check(result.ok,"import accepted"); candidate=result.state
				else: candidate=SaveManager.current_state()
				check(candidate!=null,"candidate load")
				if candidate==null: continue
				check(candidate.beast_version==1 and SaveManager.migration_error(candidate)=="BEAST_SAVE_REQUIRED","beast pending gate")
				check(JSON.parse_string(JSON.stringify(candidate.beasts))==JSON.parse_string(JSON.stringify(old.beasts)) and candidate.beast_souls==old.beast_souls and candidate.beast_talents==old.beast_talents,"preserve original beast progress")
				var before:=candidate.to_snapshot_dict()
				check(not SaveManager.save(candidate.duplicate_state(),META).ok,"same candidate identity required")
				check(not SaveManager.import_share_string(Marshalls.utf8_to_base64(raw)).ok and SaveManager.import_legacy_text("{}").get("error")=="MIGRATION_PENDING","second import blocked")
				var s:=GameSession.new(); s.content=content; s.state=candidate; s.clock=GameClock.create(0)
				check(not s.feed_beast().ok and not s.advance_time(60).ok,"pending command time locked")
				check(not OfflineCoordinator.settle_state(candidate,content,61000,1000).ok and before==candidate.to_snapshot_dict(),"pending offline no mutation")
				var key: String="save_before_beasts_"+raw.sha256_text()
				var damaged:=key+"_damaged_"+"damaged".sha256_text()
				if fault=="archive_write": mem.fail=key
				elif fault=="archive_read": mem.read_fail=key
				elif fault=="archive_corrupt": mem.corrupt=key
				elif fault=="slot_write": mem.fail=SaveSlots.SLOT_BACKUP
				elif fault=="slot_corrupt": mem.corrupt=SaveSlots.SLOT_BACKUP
				elif fault=="index": mem.fail=SaveSlots.INDEX_KEY
				elif fault=="rescue_write": mem.data[key]="damaged"; mem.fail=damaged
				else: mem.data[key]="damaged"; mem.read_fail=damaged
				# Slot target can vary with import. Determine from the current index-free main.
				if imported and fault in ["slot_write","slot_corrupt"]:
					if fault=="slot_write": mem.fail=SaveSlots.SLOT_MAIN
					else: mem.corrupt=SaveSlots.SLOT_MAIN
				check(not SaveManager.save(candidate,META).ok and SaveManager.migration_pending(candidate),"failed save remains gated "+fault)
				check(not SaveManager.save(candidate,META).ok and before==candidate.to_snapshot_dict(),"repeated failure no reapply "+fault)
				mem.fail=""; mem.corrupt=""; mem.read_fail=""
				check(SaveManager.save(candidate,META).ok and not SaveManager.migration_pending(candidate),"recover same candidate "+fault)
				check(mem.data.get(key)==raw and before==candidate.to_snapshot_dict(),"exact raw archive no gift")
				if combined:
					for group in ["sect","pills","talents"]: check(mem.data.get("save_before_"+group+"_"+raw.sha256_text())==raw,"concurrent source "+group)
				SaveManager.configure(content,mem)
				var loaded:=SaveManager.current_state()
				check(loaded!=null and loaded.beast_version==1 and loaded.beasts==candidate.beasts and loaded.beast_souls==candidate.beast_souls,"reload retains progress")
				SaveManager.reset_for_tests()
	_receipts()
	_concurrent_supply()
	DirAccess.make_dir_recursive_absolute(DIR)
	var file:=FileAccess.open(DIR+"save.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P2-BEASTS-SAVE ",checks," checks failures=",JSON.stringify(failures))
	print("RUNNER_RESULT status=%s exit=%d" % ["PASS" if failures.is_empty() else "FAIL",0 if failures.is_empty() else 1])
	quit(0 if failures.is_empty() else 1)
func _validation() -> void:
	var good:=fresh(); var raw:=encode(good)
	check(JSON.parse_string(raw).rules_version==SaveCodec.BEAST_RULES_VERSION and JSON.parse_string(raw).schema_version==5,"rules23 schema5")
	var branch:=fresh(); branch.beast_version=0
	check(JSON.parse_string(encode(branch)).rules_version==SaveCodec.SECT_RULES_VERSION,"legacy beast preserves sect branch")
	branch.sect_version=1
	check(JSON.parse_string(encode(branch)).rules_version==SaveCodec.PILL_RULES_VERSION,"legacy beast preserves pill branch")
	branch.pill_version=1
	check(JSON.parse_string(encode(branch)).rules_version==SaveCodec.TALENT_RULES_VERSION,"legacy beast preserves talent branch")
	for version in [-1,2,true,0.5,"1",INF,NAN]: check(not BeastSaveContract.validate(version,{},{},{}).is_empty(),"invalid version")
	for id in BeastSystem.BEAST_CONFIGS:
		for exp_value in [0,99,100,499,500,999,1000,2147483647]:
			var stage: String="egg" if exp_value<100 else "young" if exp_value<500 else "growing" if exp_value<1000 else "mature"
			var beasts: Dictionary={"active":{"id":id,"exp":exp_value,"stage":stage},"cooldown_remaining":300}
			check(BeastSaveContract.validate(1,beasts,{},{}).is_empty(),"valid stage boundary")
			check(BeastSaveContract.validate(0,beasts,{},{}).is_empty()==(id not in BeastSystem.P2_IDS),"legacy whitelist")
			check(SaveCodec.decode(changed(raw,"beasts",beasts)).ok,"codec boundary roundtrip")
		for value in [-1,0.5,true,"1",2147483648,INF,NAN]:
			check(not BeastSaveContract.validate(1,{"active":{"id":id,"exp":value,"stage":"egg"}}, {},{}).is_empty(),"invalid XP")
			check(not BeastSaveContract.validate(1,{}, {id:value},{}).is_empty(),"invalid soul")
	for id in BeastSystem.BEAST_TALENTS:
		for value in [-1,2,true,0.5,"1",INF,NAN]: check(not BeastSaveContract.validate(1,{},{},{id:value}).is_empty(),"talent bound")
		if int(BeastSystem.BEAST_TALENTS[id].tier)>1: check(not BeastSaveContract.validate(1,{},{},{id:1}).is_empty(),"missing previous rejected")
	for beasts in [{"unknown":1},{"active":[]},{"active":{"id":"missing","exp":0,"stage":"egg"}},{"active":{"id":"jade_fox","exp":100,"stage":"egg"}},{"active":{"id":"jade_fox","exp":0,"stage":"egg","extra":1}},{"cooldown_remaining":1},{"active":{"id":"jade_fox","exp":0,"stage":"egg"},"cooldown_remaining":301}]:
		check(not BeastSaveContract.validate(1,beasts,{},{}).is_empty(),"bad fields")
	check(not BeastSaveContract.validate(1,{}, {"unknown":0},{}).is_empty(),"unknown soul even zero")
	check(not BeastSaveContract.validate(1,{}, {},{"unknown":0}).is_empty(),"unknown talent even zero")
	check(not BeastSaveContract.validate(1,{"padding":"x".repeat(65536)},{},{}).is_empty(),"64KiB bound")
	var old:=fresh(); old.beast_version=0; var legacy:=encode(old)
	var env: Dictionary=JSON.parse_string(legacy); env.state.erase("beast_version"); env.erase("checksum"); env.checksum=SaveCodec.compute_checksum(env)
	check(SaveCodec.decode(JSON.stringify(env)).ok and SaveCodec.decode(JSON.stringify(env)).state.beast_version==0,"missing legacy version")
	for bad in [changed(raw,"beast_version",2),changed(raw,"beasts",{"active":{"id":"jade_fox","exp":100,"stage":"egg"}}),"broken"]:
		var mem:=Memory.new(); mem.data={SaveSlots.SLOT_MAIN:bad,SaveSlots.SLOT_BACKUP:bad}
		SaveManager.configure(content,mem)
		check(SaveManager.current_state()==null and not SaveManager.save(good,META).ok,"untrusted refuses overwrite")
		check(mem.data[SaveSlots.SLOT_MAIN]==bad and mem.data[SaveSlots.SLOT_BACKUP]==bad,"bad originals intact")
		SaveManager.reset_for_tests()
func _receipts() -> void:
	for id in BeastSystem.P2_IDS:
		for operation in ["acquire","feed","talent","reincarnate"]:
			var s:=GameSession.create_new_game(content,20261026); s.state.era_id=6; s.state.highest_era=6
			check(s.submit({"command_id":"activate","type":"activate_islands","payload":{},"expected_revision":s.state.revision}).ok,"receipt activation")
			for island in s.state.economy.islands: s.state.economy.islands[island].opened=true
			for resource in s.state.resources: s.state.resources[resource].value=AmountCompat.from_number(1000)
			s.state.resources.foundation_pill.value=AmountCompat.zero()
			var kind: String={"acquire":"acquire_beast","feed":"feed_beast","talent":"unlock_beast_talent","reincarnate":"reincarnate"}[operation]
			var payload: Dictionary={"beast_id":id} if operation=="acquire" else {"talent_id":"stag_t1_boost" if id=="frost_stag" else "crane_t1_boost"} if operation=="talent" else {}
			if operation!="acquire": s.state.beasts={"active":{"id":id,"exp":1000 if operation=="reincarnate" else 0,"stage":"mature" if operation=="reincarnate" else "egg"},"cooldown_remaining":0}
			s.state.beast_souls[id]=11; s.state.buildings.rebirth_lotus=1
			var mem:=Memory.new(); SaveManager.configure(content,mem)
			var cmd: Dictionary={"command_id":"paid","type":kind,"payload":payload,"expected_revision":s.state.revision}
			check(s.submit(cmd).ok,"receipt command "+operation)
			var before:=s.state.to_snapshot_dict()
			check(s.submit(cmd).get("duplicate",false) and before==s.state.to_snapshot_dict(),"dedup same command")
			mem.fail="*"
			check(not SaveManager.save(s.state,META).ok and not SaveManager.save(s.state,META).ok and before==s.state.to_snapshot_dict(),"save retry no double debit")
			mem.fail=""; check(SaveManager.save(s.state,META).ok,"save paid candidate")
			SaveManager.configure(content,mem); s.state=SaveManager.current_state()
			check(s.state!=null and s.submit(cmd).get("duplicate",false),"reload dedup "+operation)
			SaveManager.reset_for_tests()

func _concurrent_supply() -> void:
	var historical: GameContent=ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(historical).ok,"historical content")
	for imported in [false,true]:
		var old:=GameSession.create_new_game(historical,20261026)
		old.state.era_id=3
		check(CommandProcessor.apply(historical,old.state,{"type":"activate_islands","payload":{}}).ok,"historical activation")
		old.state.beast_version=0; old.state.sect_version=1; old.state.pill_version=1; old.state.talent_version=2
		var encoded:=SaveCodec.encode(old.state,historical.content_version,META)
		check(encoded.ok,"concurrent encode")
		var raw: String=encoded.get("json","")
		var mem:=Memory.new(); mem.data[SaveSlots.SLOT_MAIN]=raw
		SaveManager.configure(content,mem)
		var candidate: GameState
		if imported:
			var result:=SaveManager.import_share_string(Marshalls.utf8_to_base64(raw))
			check(result.ok,"concurrent import"); candidate=result.state
		else: candidate=SaveManager.current_state()
		check(candidate!=null and SaveManager.supply_pending(candidate) and SaveManager.migration_error(candidate)=="BEAST_SAVE_REQUIRED","supply copy shares beast candidate")
		if candidate==null: continue
		var before:=candidate.to_snapshot_dict()
		mem.fail="save_before_beasts_"+raw.sha256_text()
		check(not SaveManager.save(candidate,META).ok and before==candidate.to_snapshot_dict(),"concurrent fault no second migration")
		mem.fail=""
		check(SaveManager.save(candidate,META).ok and not SaveManager.migration_pending(candidate),"all migration gates release")
		for group in ["supply","beasts","sect","pills","talents"]: check(mem.data.get("save_before_"+group+"_"+raw.sha256_text())==raw,"five concurrent raw archives "+group)
		SaveManager.reset_for_tests()
