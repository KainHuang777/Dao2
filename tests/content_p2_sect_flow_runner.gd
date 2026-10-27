extends "res://tests/content_p2_supply_progression_runner.gd"
## Two independent dated earned branches. No injected contribution, task or inventory.
var OUT := (OS.get_environment("DAO_TEST_STORAGE_ROOT") if not OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else "res://.test-output").path_join("sect2-earned-flow/")
var branches := []
func save_snapshot(name: String) -> void:
	var encoded := SaveCodec.encode(s.state,content.content_version,{"save_id":"sect2-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":str(int(s.state.total_elapsed_seconds))})
	check(encoded.ok,"snapshot "+name)
	if encoded.ok:
		var file := FileAccess.open(OUT+name+".json",FileAccess.WRITE)
		file.store_string(encoded.json)
func earn(target: float, completed: Array) -> bool:
	for attempt in 80:
		if float(s.state.sect.contribution) >= target: return true
		if s.state.sect.available_tasks.is_empty():
			if not tick(float(s.state.sect.next_refresh_seconds),"refresh cooldown"): return false
			if not send("refresh_sect_tasks").ok: return false
		var task: Dictionary = s.state.sect.available_tasks[0]
		for candidate in s.state.sect.available_tasks:
			if candidate.duration < task.duration: task = candidate
		if not send("start_sect_expedition",{"task_id":task.id}).ok: return false
		if not tick(float(task.duration),"expedition"): return false
		if not send("claim_sect_expedition").ok: return false
		completed.append(task.duplicate(true))
		print("SECT2 earned era",s.state.era_id," contribution=",s.state.sect.contribution," elapsed=",s.state.total_elapsed_seconds)
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach supply")
	for era in [4,6]:
		serial += 10000
		source_path = "res://docs/verification/artifacts/content-p2-supply-3/earned-era%d.json" % era
		var raw := FileAccess.get_file_as_string(source_path)
		var adapter := FileStorageAdapter.new(OUT+"isolated-storage/era"+str(era))
		SaveSlots.new(adapter).reset()
		check(adapter.write(SaveSlots.SLOT_MAIN,raw).ok,"seed isolated earned source")
		SaveManager.configure(content,adapter)
		s = GameSession.new(); s.content = content; s.state = SaveManager.current_state()
		check(s.state != null,"load candidate")
		if s.state == null: break
		check(SaveManager.save(s.state,{"save_id":"sect2-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}).ok,"commit migration")
		s.clock = GameClock.create(s.state.total_elapsed_seconds)
		var start_age := s.state.total_elapsed_seconds
		if not s.state.economy.islands.deep.opened:
			check(opening("deep") and build("mineral_focus") and build("core_storehouse_4"),"earned deep supply")
		check(send("join_sect",{"sect_name":"太虛天闕"}).ok,"formal join")
		var completed := []
		check(earn(600,completed),"naturally generated tasks earn 600")
		check(ensure("wood",450) and ensure("stone_low",200),"naturally collect study materials")
		save_snapshot("review-era"+str(era))
		for id in SectSystem.P2_TECHNIQUES:
			var before := float(s.state.sect.contribution)
			check(send("learn_sect_technique",{"technique_id":id}).ok,"earned first rank "+id)
			check(before-float(s.state.sect.contribution)==float(SectSystem.TECHNIQUES[id].base_contrib),"exact contribution cost")
		var item := "refined_iron_reserve" if era==4 else "ancient_herb_reserve"
		var resource: String = SectSystem.MARKET_ITEMS[item].grant_resource
		# Full stock is consumed through a real recipe if needed; never trim inventory.
		if not SectSystem.market_destination_error(s.state,item,content).is_empty():
			var recipe := "ancient_herb_dew_pill" if era==4 else "spirit_vessel_pill"
			for ingredient in AlchemySystem.refinement_cost(s.state,recipe):
				check(ensure(ingredient,AlchemySystem.refinement_cost(s.state,recipe)[ingredient].to_float()),"collect capacity recipe material")
			check(send("refine_pill",{"pill_id":recipe}).ok,"use stock for capacity")
		var before := value(resource)
		check(send("buy_sect_market_item",{"item_id":item}).ok,"earned supply purchase "+item)
		check(value(resource)-before==float(SectSystem.MARKET_ITEMS[item].grant_amount),"whole package once")
		if era==4:
			check(send("acquire_beast",{"beast_id":"iron_turtle"}).ok,"earned turtle acquire")
			check(ensure("refined_iron",29) and ensure("stone_low",98),"collect turtle feed")
		else:
			check(s.state.beasts.active.id=="fire_phoenix","earned phoenix source")
			check(ensure("spirit_grass_1000y",9),"collect phoenix feed")
		if float(s.state.beasts.cooldown_remaining)>0: check(tick(float(s.state.beasts.cooldown_remaining),"feed cooldown"),"legal cooldown")
		var costs := BeastSystem.feed_costs(s.state,s.state.beasts.active.id)
		var feed_before := {}
		for id in costs: feed_before[id] = value(id)
		check(send("feed_beast").ok,"earned discounted feed era"+str(era))
		for id in costs: check(is_equal_approx(feed_before[id]-value(id),float(costs[id])),"exact feed material "+id)
		check(costs.get("refined_iron",29)==29 and costs.get("spirit_grass_1000y",9)==9,"rank1 real feed")
		save_snapshot("after-era"+str(era))
		check(SaveManager.save(s.state,{"save_id":"sect2-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}).ok,"save earned result")
		SaveManager.configure(content,adapter)
		var reloaded := SaveManager.current_state()
		check(JSON.parse_string(JSON.stringify(reloaded.sect.techniques))==JSON.parse_string(JSON.stringify(s.state.sect.techniques)) and JSON.parse_string(JSON.stringify(reloaded.sect.market_purchases))==JSON.parse_string(JSON.stringify(s.state.sect.market_purchases)),"earned reload persists")
		branches.append({"era":era,"source":source_path,"source_sha256":raw.sha256_text(),"start_age":start_age,"end_age":s.state.total_elapsed_seconds,"completed_natural_samples":completed,"feed_costs":costs})
		await process_frame
	var file := FileAccess.open(OUT+"flow.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"level":"L2","checks":checks,"failures":failures,"branches":branches,"waits":waits,"evidence":"two independent earned sources; formal commands plus simulated waits, not wall-clock/browser progression; ten forced template fixtures tested separately in SECT-1"},"\t"))
	print("SECT2 FLOW ",checks," failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
