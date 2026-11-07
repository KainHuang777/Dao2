extends SceneTree
# Test-only nodes prove B contracts; they are not C balance content or earned progress.
var checks := 0
var failures: Array = []
var content: GameContent
var catalog: Dictionary
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	var read_fail := ""
	var corrupt := ""
	var lost := ""
	func read(key: String) -> Dictionary:
		if key == read_fail: return {"ok":false,"error":"injected_read"}
		return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if key == fail: return {"ok":false,"error":"injected_write"}
		data[key] = "corrupt" if key == corrupt else value
		return {"ok":key != lost,"error":"lost_response" if key == lost else ""}
	func exists(key: String) -> bool: return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL ",label)
func same(a: Variant,b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a,"",true)) == JSON.parse_string(JSON.stringify(b,"",true))
func source(id: String,family: String,value: float,scope: String="test") -> Dictionary:
	return {"effect_id":id,"family":family,"scope":scope,"unit":"reduction","stack_mode":"sum_then_dr","limit":EconomyEffects.LIMITS[family],"source":"fixture","value":value}
func command(p: EconomyProfile,type: String,payload: Dictionary={},id: String="") -> Dictionary:
	return {"command_id":id if not id.is_empty() else type+str(p._game.state.revision),"expected_revision":p._game.state.revision,"type":type,"payload":payload}
func create(mem: Memory) -> EconomyProfile:
	var opened := EconomyProfile.open(content,mem,catalog,true)
	check(opened.ok,"create profile "+str(opened.get("error")))
	return opened.profile
func prepare(p: EconomyProfile) -> void:
	p._game.state.era_id=2
	p._game.state.buildings.library=1
	for id in ["wood","stone_low"]:
		p._game.state.resources[id].unlocked=true
		p._game.state.resources[id].value=AmountCompat.from_number(100)
	p._game.state.revision+=1
	check(p._stage(p._game,p._research,{"ok":true}).ok,"persist explicit fixture")
func start(p: EconomyProfile,id: String="test1") -> Dictionary:
	return p.submit(command(p,"start_research",{"research_id":id}))
func run() -> void:
	content=ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"runtime supply")
	catalog={"version":ResearchSystem.VERSION,"nodes":[
		{"id":"test1","era":2,"seconds":20,"facility":"library","prerequisites":[],"cost":{"wood":3,"stone_low":2},"unlocks":["fixture_recipe"]},
		{"id":"test2","era":2,"seconds":30,"facility":"library","prerequisites":["test1"],"cost":{"wood":4},"unlocks":[]}]}
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--readback":
		var readback := EconomyProfile.open(content,FileStorageAdapter.new(args[1]),catalog)
		check(readback.ok,"second process load")
		if readback.ok:
			check(readback.profile._research.job.remaining==19,"second process remaining")
			check(readback.profile._game.state.resources.wood.value.to_float()==97,"second process paid")
		RunnerResult.finish(self,0 if failures.is_empty() else 1)
		return
	_effects()
	_catalog()
	_research()
	_time_and_lives()
	_storage()
	_failure_boundaries()
	_utc_settlement()
	_file_roundtrip()
	print("ECON-R1-B ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
func _effects() -> void:
	for limit in [0.5,0.7,0.8]:
		var previous := -1.0
		for raw in [0.0,0.01,0.2,0.375,0.5,0.525,0.6,0.8,1.6,100.0]:
			var r := EconomyEffects.dr(raw,limit)
			check(r.ok and r.effective>=previous and r.effective<limit,"DR monotonic bounded")
			previous=r.effective
	check(is_equal_approx(EconomyEffects.dr(0.8,0.8).effective,0.7),"published vector")
	for bad in [-1.0,INF,NAN]: check(not EconomyEffects.dr(bad,0.8).ok,"reject negative/nonfinite")
	check(not EconomyEffects.dr(1,0).ok,"reject zero limit")
	var sources := [source("skill","building_cost",0.4),source("sect","building_cost",0.4),source("work","work_time",0.5)]
	var r := EconomyEffects.resolve("building_cost","test",sources)
	check(r.ok and is_equal_approx(r.effective,0.7) and r.sources.size()==2,"sum then one DR per family")
	check(EconomyEffects.resolve("building_cost","other",sources).effective==0,"scope isolation")
	check(not EconomyEffects.resolve("building_cost","test",[sources[0],sources[0]]).ok,"duplicate rejected")
	var bad: Dictionary=sources[0].duplicate(true)
	bad.unit="multiplier"
	check(not EconomyEffects.resolve("building_cost","test",[bad]).ok,"mixed units rejected")
	var one := EconomyEffects.cost(AmountCompat.from_number(1),1,false,r)
	var batch := EconomyEffects.cost(AmountCompat.from_number(1),37,false,r)
	check(one.ok and batch.ok and is_equal_approx(batch.amount.to_float(),one.amount.to_float()*37),"no split/batch arbitrage")
	check(EconomyEffects.cost(AmountCompat.from_number(1),37,true,r).amount.to_float()==37,"core components undiscounted")
	check(not EconomyEffects.cost(AmountCompat.from_number(1.5),1,true,r).ok,"discrete integer required")
	check(not EconomyEffects.cost(AmountCompat.from_number(1e13),1,false,r).ok,"Amount boundary")
	check(EconomyEffects.cost(AmountCompat.from_number(1e-9),1,false,r).amount.sign==1,"required raw never free")
	var timing := EconomyEffects.resolve("work_time","test",[source("speed","work_time",100)])
	check(EconomyEffects.duration(1,timing).seconds==1,"one tick minimum")
	check(not EconomyEffects.duration(10,r).ok,"family cannot leak to time")
func _catalog() -> void:
	check(ResearchSystem.validate_catalog(catalog,content).is_empty(),"valid fixture catalog")
	var official := EconomySlice.create()
	check(official.ok and ResearchSystem.validate_catalog(official.catalog,official.content).is_empty() and official.catalog.nodes.size() == 7,"official C nodes validated separately from B fixtures")
	for field in ["cycle","missing","cost","era","facility","duplicate"]:
		var bad := catalog.duplicate(true)
		match field:
			"cycle": bad.nodes[0].prerequisites=["test2"]
			"missing": bad.nodes[1].prerequisites=["unknown"]
			"cost": bad.nodes[0].cost.wood=0
			"era": bad.nodes[0].era=7
			"facility": bad.nodes[0].facility="absent"
			"duplicate": bad.nodes.append(bad.nodes[0])
		check(not ResearchSystem.validate_catalog(bad,content).is_empty(),"invalid catalog "+field)
func _research() -> void:
	var p := create(Memory.new())
	check(not start(p).ok,"era gate")
	p._game.state.era_id=2
	check(not start(p).ok,"facility gate")
	prepare(p)
	check(not start(p,"test2").ok,"prerequisite gate")
	p._game.state.resources.stone_low.value=AmountCompat.zero()
	var before := p.view()
	check(not start(p).ok and same(before,p.view()),"missing material atomic")
	p._game.state.resources.stone_low.value=AmountCompat.from_number(100)
	var cmd := command(p,"start_research",{"research_id":"test1"},"research-one")
	var result := p.submit(cmd)
	check(result.ok,"start " + str(result))
	if not result.ok: return
	check(p._game.state.resources.wood.value.to_float()==97 and p._game.state.resources.stone_low.value.to_float()==98,"home paid once")
	check(p._research.job.duration==20 and p._research.job.remaining==20,"frozen duration")
	check(not start(p,"test2").ok,"single slot")
	check(p.submit(cmd).get("duplicate",false),"duplicate before stale revision")
	check(p.advance_time(19).ok and not p._research.completed.has("test1"),"no early completion")
	check(p.advance_time(1).ok and p._research.completed.has("test1") and p._research.job.is_empty(),"completion boundary")
	check(not start(p).ok,"cannot repeat same life")
	check(p.quote_research("test2").duration==30,"first-life frontier does not grant inheritance early")
	check(start(p,"test2").ok,"next prerequisite")
	var paid: String=p._game.state.resources.wood.value.serialize()
	check(p.submit(command(p,"cancel_research")).ok,"cancel")
	check(p._game.state.resources.wood.value.serialize()==paid and not p._research.mastered.has("test2"),"no refund or cancelled mastery")
	var v := p.view()
	v.research.mastered.test2=true
	check(not p._research.mastered.has("test2"),"view copy")
	for field in ["remaining","duration","paid","effect"]:
		var data := p._research.duplicate(true)
		data.job={"id":"test2","version":ResearchSystem.VERSION,"remaining":1,"duration":30,"paid":{"wood":4},"unlocks":[],"effect":ResearchSystem.inheritance(catalog,ResearchSystem.initial())}
		match field:
			"remaining": data.job.remaining=-1
			"duration": data.job.duration=999
			"paid": data.job.paid={}
			"effect": data.job.effect={}
		check(not ResearchSystem.validate(data,catalog).is_empty(),"invalid frozen "+field)
func _time_and_lives() -> void:
	var a := create(Memory.new())
	var b := create(Memory.new())
	prepare(a); prepare(b)
	check(start(a).ok and start(b).ok,"time fixture starts")
	check(a.advance_time(20).ok,"offline batch")
	for i in 20: check(b.advance_time(1).ok,"online tick")
	check(same(a.view().state,b.view().state) and same(a._research,b._research),"online/offline full state equality")
	var c := create(Memory.new())
	prepare(c);check(start(c).ok,"fraction fixture")
	check(c.advance_time(0.4).ok and c.advance_time(0.6).ok and c._research.job.remaining==19,"fractional clock")
	check(not c.advance_time(NAN).ok and not c.advance_time(-1).ok,"invalid elapsed")
	c._game.state.total_elapsed_seconds=Lifespan.for_state(content.era_lifespan_entries(),c._game.state)-1
	check(c.advance_time(30).ok and c._research.job.remaining==18,"only final living tick counts")
	var remaining: int=c._research.job.remaining
	check(c.advance_time(30).ok and c._research.job.remaining==remaining,"death freezes research")
	var mastery: Dictionary = a._research.mastered.duplicate(true)
	a._game.state.total_elapsed_seconds=Lifespan.for_state(content.era_lifespan_entries(),a._game.state)
	check(a.submit(command(a,"reincarnate")).ok,"real reincarnation command")
	check(a._research.completed.is_empty() and a._research.job.is_empty() and same(a._research.mastered,mastery),"per life reset unique mastery")
	prepare(a)
	var q := a.quote_research("test1")
	check(q.ok and q.duration==17 and q.paid==catalog.nodes[0].cost,"inheritance time only full materials")
	check(start(a).ok and a.advance_time(17).ok,"second life paid re-research")
	check(same(a._research.mastered,mastery),"no mastery farm")
	var d := create(Memory.new())
	prepare(d);check(start(d).ok,"unfinished fixture")
	d._game.state.total_elapsed_seconds=Lifespan.for_state(content.era_lifespan_entries(),d._game.state)
	check(d.submit(command(d,"reincarnate")).ok and d._research.job.is_empty() and d._research.mastered.is_empty(),"unfinished life cleared")
func _storage() -> void:
	var mem := Memory.new()
	mem.data.save_main="legacy exact bytes"
	mem.data.save_index="legacy index"
	var p := create(mem)
	prepare(p)
	var original: String=p._source
	check(not EconomyProfile.open(content,mem,catalog,true).ok,"no overwrite existing")
	for stage in ["archive","candidate","readback","index","lost"]:
		var target := EconomyProfileStorage.PREFIX+(SaveSlots.SLOT_BACKUP if p._slots.active_slot()==SaveSlots.SLOT_MAIN else SaveSlots.SLOT_MAIN)
		if stage=="archive": mem.fail=EconomyProfileStorage.PREFIX+"source_before_commit"
		if stage=="candidate": mem.fail=target
		if stage=="readback": mem.corrupt=target
		if stage=="index": mem.fail=EconomyProfileStorage.PREFIX+SaveSlots.INDEX_KEY
		if stage=="lost": mem.lost=target
		var before := p.view()
		var cmd := command(p,"start_research",{"research_id":"test1"},"fault-"+stage)
		check(not p.submit(cmd).ok,"failure "+stage)
		check(same(before.state,p.view().state) and same(before.research,p.view().research),"live unchanged "+stage)
		check(not p.submit(command(p,"gather",{"resource_id":"lingli"})).ok and not p.advance_time(1).ok,"pending freezes "+stage)
		var pending: String=p._pending
		mem.fail="";mem.corrupt="";mem.lost=""
		check(p.retry_save().ok and p._source==pending,"exact retry "+stage)
		check(p._game.state.resources.wood.value.to_float()==float(before.state.resources.wood.value)-3,"one payment "+stage)
		check(p.submit(cmd).get("duplicate",false),"receipt "+stage)
		var loaded := EconomyProfile.open(content,mem,catalog)
		check(loaded.ok and same(loaded.profile.view().state,p.view().state) and same(loaded.profile._research,p._research),"reload "+stage)
		check(p.submit(command(p,"cancel_research")).ok,"clear job")
	check(mem.data.save_main=="legacy exact bytes" and mem.data.save_index=="legacy index","legacy bytes untouched")
	check(not SaveCodec.decode(p._source).ok,"legacy refuses new envelope")
	check(p._decode(original).ok,"versioned archived source")
	check(p._decode("{}").error=="PROFILE_LEGACY_UNSUPPORTED","named import rejection")
	var forged: Dictionary=JSON.parse_string(p._source)
	for field in ["profile","schema_version","rules_version","economy_version","research_version","content_version","catalog_sha256"]:
		var bad := forged.duplicate(true)
		bad[field]="unknown"
		bad.checksum=EconomyProfile._checksum(bad)
		check(not p._decode(JSON.stringify(bad)).ok,"version rejection "+field)
	forged.research.mastered={"absent":true}
	forged.checksum=EconomyProfile._checksum(forged)
	check(not p._decode(JSON.stringify(forged)).ok,"invalid rehashed research")
	var future: Dictionary = JSON.parse_string(p._source)
	future.rules_version="econ-r1-rules-future"
	future.checksum=EconomyProfile._checksum(future)
	var old_backup: String=mem.data[EconomyProfileStorage.PREFIX+SaveSlots.SLOT_BACKUP]
	mem.data[EconomyProfileStorage.PREFIX+SaveSlots.SLOT_BACKUP]=JSON.stringify(future)
	check(EconomyProfile.open(content,mem,catalog).get("error")=="PROFILE_VERSION:rules_version","no fallback downgrade over future generation")
	mem.data[EconomyProfileStorage.PREFIX+SaveSlots.SLOT_BACKUP]=old_backup
	var changed := catalog.duplicate(true)
	changed.nodes[0].seconds=21
	check(not EconomyProfile.open(content,mem,changed).ok,"catalog change rejected")
	mem.read_fail=EconomyProfileStorage.PREFIX+SaveSlots.SLOT_MAIN
	check(not EconomyProfile.open(content,mem,catalog,true).ok,"read denial never resets")
	mem.read_fail=""
	mem.data[EconomyProfileStorage.PREFIX+p._slots.active_slot()]="corrupt"
	check(EconomyProfile.open(content,mem,catalog).ok,"fallback previous generation")
	mem.data[EconomyProfileStorage.PREFIX+SaveSlots.SLOT_MAIN]="corrupt"
	mem.data[EconomyProfileStorage.PREFIX+SaveSlots.SLOT_BACKUP]="corrupt"
	check(not EconomyProfile.open(content,mem,catalog,true).ok,"both corrupt refuse overwrite")
	var init_mem := Memory.new()
	init_mem.fail=EconomyProfileStorage.PREFIX+SaveSlots.SLOT_MAIN
	var init := EconomyProfile.open(content,init_mem,catalog,true)
	check(not init.ok and init.has("profile"),"initial failure retains owner")
	init_mem.fail=""
	check(init.profile.retry_save().ok,"initial retry")


func _failure_boundaries() -> void:
	var mem := Memory.new()
	var p := create(mem)
	prepare(p);check(start(p).ok,"completion failure fixture")
	check(p.advance_time(19).ok,"completion fixture elapsed")
	var before := p.view()
	var target := EconomyProfileStorage.PREFIX+(SaveSlots.SLOT_BACKUP if p._slots.active_slot()==SaveSlots.SLOT_MAIN else SaveSlots.SLOT_MAIN)
	mem.fail=target
	check(not p.advance_time(1).ok and same(before.research,p._research),"completion refusal leaves live pending job")
	var pending: String=p._pending
	mem.fail=""
	check(p.retry_save().ok and p._source==pending and p._research.completed.has("test1"),"completion retry exactly once")
	check(ResearchSystem.has_unlock(catalog,p._research,"fixture_recipe"),"completed unlock available")
	p._game.state.total_elapsed_seconds=Lifespan.for_state(content.era_lifespan_entries(),p._game.state)
	before=p.view()
	var cmd := command(p,"reincarnate",{},"rebirth-refusal")
	mem.fail=EconomyProfileStorage.PREFIX+SaveSlots.INDEX_KEY
	check(not p.submit(cmd).ok and same(before.state,p.view().state),"rebirth refusal keeps old live life")
	pending=p._pending
	mem.fail=""
	# Simulated crash after candidate write but before index response: reload candidate.
	var crash := EconomyProfile.open(content,mem,catalog)
	check(crash.ok and crash.profile._game.state.reincarnation_count==1,"recover unindexed newer life")
	check(crash.profile.submit(cmd).get("duplicate",false),"crash recovery rebirth dedup")
	check(p.retry_save().ok and p._source==pending and p._game.state.reincarnation_count==1,"rebirth retry no second reward")
	check(not ResearchSystem.has_unlock(catalog,p._research,"fixture_recipe"),"reset removes capability")
	var stale := EconomyProfile.open(content,mem,catalog).profile as EconomyProfile
	check(p.advance_time(1).ok,"advance durable owner")
	check(not stale.advance_time(2).ok and stale.retry_save().get("error")=="PROFILE_SOURCE_CHANGED","stale writer refuses overwrite")
	# Malformed types must be named errors, never SCRIPT ERROR.
	for value in [null,[],1,"bad"]:
		var raw: Dictionary=JSON.parse_string(p._source)
		raw.research={"completed":{},"mastered":{},"inherited_depth":0,"job":{"id":value}}
		raw.checksum=EconomyProfile._checksum(raw)
		check(not p.inspect_save(JSON.stringify(raw)).ok,"malformed job rejected")
	var forged := p._research.duplicate(true)
	forged.job={"id":"test1","version":ResearchSystem.VERSION,"remaining":10,"duration":10,"paid":{"wood":3,"stone_low":2},"unlocks":["fixture_recipe"],"effect":EconomyEffects.resolve("research_inheritance","research",[source("forged","research_inheritance",100,"research")])}
	check(not ResearchSystem.validate(forged,catalog).is_empty(),"cannot forge inherited acceleration")
	var index_only := Memory.new()
	index_only.data[EconomyProfileStorage.PREFIX+SaveSlots.INDEX_KEY]="{}"
	check(not EconomyProfile.open(content,index_only,catalog,true).ok,"orphan index never reset")
	var initial_corrupt := Memory.new()
	initial_corrupt.corrupt=EconomyProfileStorage.PREFIX+SaveSlots.SLOT_MAIN
	var opened := EconomyProfile.open(content,initial_corrupt,catalog,true)
	check(not opened.ok,"initial readback corruption")
	initial_corrupt.corrupt=""
	check(opened.profile.retry_save().ok,"initial corrupt candidate exact retry")

func _file_roundtrip() -> void:
	var directory := RunnerResult.output_path("res://docs/verification/artifacts/econ-r1-b/native-"+str(Time.get_ticks_usec()))
	var opened := EconomyProfile.open(content,FileStorageAdapter.new(directory),catalog,true)
	check(opened.ok,"isolated file create")
	if not opened.ok: return
	var p: EconomyProfile=opened.profile
	prepare(p)
	check(start(p).ok and p.advance_time(1).ok,"isolated file progress")
	var output: Array=[]
	var exit_code := OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/econ_r1_contract_runner.gd","--","--readback",directory],output,true)
	check(exit_code==0 and "RUNNER_RESULT status=PASS" in str(output) and not "SCRIPT ERROR:" in str(output),"separate process durable reload "+str(output))

func _utc_settlement() -> void:
	var mem := Memory.new()
	var p := create(mem)
	prepare(p);check(start(p).ok,"UTC fixture starts")
	check(p.settle_to(100000).ok and p._research.job.remaining==20,"UTC bootstrap grants no elapsed time")
	var before := p.view()
	mem.fail=EconomyProfileStorage.PREFIX+SaveSlots.INDEX_KEY
	check(not p.settle_to(101000).ok and same(before.state,p.view().state) and p._settled_until==100000,"UTC refusal keeps live cursor and time")
	var pending: String=p._pending
	mem.fail=""
	check(p.retry_save().ok and p._source==pending and p._settled_until==101000 and p._research.job.remaining==19,"UTC retry commits one tick and cursor")
	var loaded := EconomyProfile.open(content,mem,catalog).profile as EconomyProfile
	check(loaded.settle_to(101000).ticks_advanced==0 and loaded._research.job.remaining==19,"reload same UTC cannot replay gap")
	check(loaded.settle_to(100000).report.rollback and loaded._settled_until==101000,"rollback never moves cursor backward")
	loaded._game.state.total_elapsed_seconds=Lifespan.for_state(content.era_lifespan_entries(),loaded._game.state)-1
	var long := loaded.settle_to(101000+OfflineSettlement.CAP_MS*2)
	check(long.ok and long.report.cap_applied and long.report.forfeited_ms==OfflineSettlement.CAP_MS and loaded._research.job.remaining==18,"48h policy and final living tick")
	check(loaded.settle_to(101000+OfflineSettlement.CAP_MS*2).ticks_advanced==0,"forfeited interval consumed")
