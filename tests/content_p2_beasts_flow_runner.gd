extends "res://tests/content_p2_supply_progression_runner.gd"
## Two independent earned empty-slot branches. Only time simulation, no grant commands.
const OUT := "res://docs/verification/artifacts/content-p2-beasts-ui/"
const META := {"save_id":"beast2-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}
var branches := []
func save_snapshot(name: String) -> void:
	var encoded := SaveCodec.encode(s.state,content.content_version,META)
	check(encoded.ok,"snapshot "+name)
	if encoded.ok:
		var f := FileAccess.open(OUT+name+".json",FileAccess.WRITE)
		f.store_string(encoded.json)
		if name.begins_with("review-") or name == "reborn-t1":
			var runtime := FileAccess.open("res://src/verification/beast2-"+name+".json",FileAccess.WRITE)
			runtime.store_string(encoded.json)

func load_earned(era: int) -> bool:
	serial += 10000
	var source := "res://docs/verification/artifacts/content-p2-supply-3/earned-era%d.json" % era
	var raw := FileAccess.get_file_as_string(source)
	var adapter := FileStorageAdapter.new(OUT+"isolated-flow/era"+str(era))
	SaveSlots.new(adapter).reset()
	check(adapter.write(SaveSlots.SLOT_MAIN,raw).ok,"seed earned source")
	SaveManager.configure(content,adapter)
	s = GameSession.new(); s.content = content; s.state = SaveManager.current_state()
	if s.state == null: check(false,"load earned"); return false
	check(SaveManager.save(s.state,META).ok,"commit migration")
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	branches.append({"era":era,"source":source,"sha256":raw.sha256_text(),"start_age":s.state.total_elapsed_seconds})
	return true

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach supply")
	for era in [4,5]:
		if not load_earned(era): break
		var id := "frost_stag" if era == 4 else "herb_crane"
		var island := "deep" if era == 4 else "ancient"
		check(s.state.beasts.get("active",{}).is_empty(),"earned empty slot")
		if not s.state.economy.islands.deep.opened: check(opening("deep") and build("mineral_focus") and build("core_storehouse_4"),"formal deep opening/routes")
		if era == 5 and not s.state.economy.islands.ancient.opened: check(opening("ancient") and build("ancient_focus") and build("core_storehouse_5"),"formal ancient opening/routes")
		var costs := BeastSystem.feed_costs(s.state,id)
		for resource in costs: check(ensure(resource,float(costs[resource])),"natural first feed supply "+resource)
		save_snapshot("review-era"+str(era))
		check(send("acquire_beast",{"beast_id":id}).ok,"formal acquire "+id)
		var first_age := s.state.total_elapsed_seconds
		for i in 20:
			for resource in costs: check(ensure(resource,float(costs[resource])),"natural feed supply "+resource)
			var cooldown: float = s.state.beasts.cooldown_remaining
			if cooldown > 0: check(tick(cooldown,"manual feed cooldown"),"formal simulated cooldown")
			var before := {}
			for resource in costs: before[resource] = value(resource)
			check(send("feed_beast").ok,"manual feed "+id+str(i))
			for resource in costs: check(is_equal_approx(before[resource]-value(resource),float(costs[resource])),"exact home charge "+resource)
			check(s.state.beasts.active.exp == (i+1)*50,"no automatic XP")
			await process_frame
		check(s.state.beasts.active.stage == "mature" and int(s.state.beast_souls.get(id,0)) == 0,"mature awards no soul")
		check(s.state.total_elapsed_seconds-first_age >= 5700,"minimum simulated cooldown duration")
		var resource := "refined_iron" if era == 4 else "spirit_grass_1000y"
		check(is_equal_approx(BeastSystem.local_rate_multiplier(s.state,island,resource),1.2),"real mature local effect")
		save_snapshot("mature-era"+str(era))
		check(SaveManager.save(s.state,META).ok,"save mature")
		var original := s.state.beasts.duplicate(true)
		SaveManager.configure(content,SaveManager.adapter())
		check(SaveManager.current_state().beasts == original,"reload mature exact")
		branches[-1].mature_age = s.state.total_elapsed_seconds
		if era == 4:
			var max_age: float = s.get_view().max_lifespan_seconds
			var result := OfflineSettlement.settle(s.state,content,1000+int(ceil(max_age-s.state.total_elapsed_seconds+1))*1000,1000)
			s.clock = GameClock.create(s.state.total_elapsed_seconds)
			check(result.get("stopped") == "lifespan_exhausted","formal simulated lifespan exhaustion")
			check(send("reincarnate",{"mode":"normal"}).ok,"formal mature rebirth")
			check(int(s.state.beast_souls.get(id,0)) == 1 and s.state.beasts.active.is_empty(),"one soul only on rebirth")
			check(send("unlock_beast_talent",{"talent_id":"stag_t1_boost"}).ok,"spend earned one soul T1")
			check(int(s.state.beast_souls[id]) == 0 and s.state.beast_talents.stag_t1_boost == 1,"earned exact debit")
			check(BeastSystem.local_rate_multiplier(s.state,"deep","refined_iron") == 1,"new life unopened island has no premature bonus")
			save_snapshot("reborn-t1")
			check(SaveManager.save(s.state,META).ok,"save reborn talent")
			SaveManager.configure(content,SaveManager.adapter())
			check(SaveManager.current_state().beast_talents.stag_t1_boost == 1,"new-life T1 persists reload")
	# Existing beasts: legal alternatives from the same earned sources, never replace an active beast.
	for era in [4,6]:
		if not load_earned(era): break
		var id := "iron_turtle" if era == 4 else "fire_phoenix"
		if era == 4:
			if not s.state.economy.islands.deep.opened: check(opening("deep") and build("mineral_focus"),"turtle legal supply")
			check(send("acquire_beast",{"beast_id":id}).ok,"legal turtle alternate")
		else: check(s.state.beasts.active.id == id,"phoenix already earned in source")
		for resource in BeastSystem.feed_costs(s.state,id): check(ensure(resource,BeastSystem.feed_costs(s.state,id)[resource]),"legacy natural supply")
		if s.state.beasts.cooldown_remaining > 0: check(tick(s.state.beasts.cooldown_remaining,"legacy cooldown"),"legacy cooldown")
		check(send("feed_beast").ok,"legacy representative feed "+id)
	var file := FileAccess.open(OUT+"flow.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"level":"L2","checks":checks,"failures":failures,"branches":branches,"waits":waits,"boundary":"Independent audited earned snapshots, formal migration/open/routes/feed/rebirth, simulated time. New-life earned T1 retention and unopened zero verified; qualified next-life effect is separate synthetic contract evidence, not a second natural climb."},"\t"))
	print("BEAST2 FLOW ",checks," failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
