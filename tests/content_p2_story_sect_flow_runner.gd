extends "res://tests/content_p2_story_flow_runner.gd"
## Independent earned Era6 branch for commissions, techniques and market facts.
func run() -> void:
	OUT = OUT.path_join("sect/")
	DirAccess.make_dir_recursive_absolute(OUT)
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"supply")
	var source := "res://docs/verification/artifacts/content-p2-supply-3/earned-era6.json"
	var raw := FileAccess.get_file_as_string(source)
	var adapter := FileStorageAdapter.new(OUT+"storage")
	SaveSlots.new(adapter).reset(); check(adapter.write(SaveSlots.SLOT_MAIN,raw).ok,"seed earned source")
	SaveManager.configure(content,adapter)
	s = GameSession.new(); s.content = content; s.state = SaveManager.current_state()
	check(s.state != null,"load earned")
	if s.state == null: RunnerResult.finish(self,1); return
	check(SaveManager.save(s.state,META).ok,"commit migration")
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	for island in ["deep","ancient","void"]:
		if not s.state.economy.islands[island].opened: check(opening(island),"earned island")
	check(send("join_sect",{"sect_name":"太虛天闕"}).ok,"join actual sect")
	var tasks := []
	for attempt in 80:
		if float(s.state.sect.contribution)>=600 and int(StoryProgressP2.facts(s.state,true).task_mask)!=0: break
		if s.state.sect.available_tasks.is_empty():
			check(tick(float(s.state.sect.next_refresh_seconds),"actual task refresh"),"refresh time")
			check(send("refresh_sect_tasks").ok,"normal generated tasks")
		var task: Dictionary = s.state.sect.available_tasks[0]
		for candidate in s.state.sect.available_tasks:
			if candidate.duration < task.duration: task = candidate
		check(send("start_sect_expedition",{"task_id":task.id}).ok,"dispatch generated "+task.id)
		check(tick(float(task.duration),"actual expedition time"),"complete real duration")
		check(send("claim_sect_expedition").ok,"claim generated task")
		tasks.append(task)
	check(int(StoryProgressP2.facts(s.state,true).task_mask)!=0,"earned P2 task fact")
	check(ensure("wood",450) and ensure("stone_low",200),"earned study materials")
	for id in SectSystem.P2_TECHNIQUES: check(send("learn_sect_technique",{"technique_id":id}).ok,"earned study "+id)
	claim("p2_two_sect_methods")
	# Real recipes create room for the two indivisible market bundles.
	for item in SectSystem.P2_MARKET:
		if not SectSystem.market_destination_error(s.state,item,content).is_empty():
			var recipe := "ancient_herb_dew_pill" if item=="refined_iron_reserve" else "void_meditation_pill"
			var count := 3 if item=="refined_iron_reserve" else 1
			for resource in AlchemySystem.refinement_cost(s.state,recipe): check(ensure(resource,AlchemySystem.refinement_cost(s.state,recipe)[resource].to_float()*count),"market capacity materials")
			for i in count: check(send("refine_pill",{"pill_id":recipe}).ok,"make real market room")
			for attempt in 24:
				if SectSystem.market_destination_error(s.state,item,content).is_empty(): break
				for resource in AlchemySystem.refinement_cost(s.state,recipe): check(ensure(resource,AlchemySystem.refinement_cost(s.state,recipe)[resource].to_float()),"remaining capacity materials")
				check(send("refine_pill",{"pill_id":recipe}).ok,"spend retained over-cap stock legally")
		var result := send("buy_sect_market_item",{"item_id":item})
		check(result.ok,"earned market "+item+str(result.get("error","")))
	claim("p2_two_reserves")
	for id in ["nascent_breath_pill","void_meditation_pill"]:
		for resource in AlchemySystem.refinement_cost(s.state,id): check(ensure(resource,AlchemySystem.refinement_cost(s.state,id)[resource].to_float()),"earned double-furnace ingredients")
		check(send("refine_pill",{"pill_id":id}).ok,"personally refine "+id)
	claim("p2_training_alchemist")
	brew("ancient_herb_dew_pill"); brew("void_gathering_pill")
	claim("p2_local_elixirs")
	check(SaveManager.save(s.state,META).ok,"save earned sect facts")
	SaveManager.configure(content,adapter)
	check(JSON.stringify(SaveManager.current_state().achievements)==JSON.stringify(s.state.achievements),"reload earned sect facts")
	var file := FileAccess.open(OUT+"flow.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"level":"L2","checks":checks,"failures":failures,"source":source,"source_sha256":raw.sha256_text(),"tasks":tasks,"claims":claims,"facts":StoryProgressP2.facts(s.state,true),"waits":waits},"\t"))
	print("STORY2 SECT FLOW ",checks," failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
