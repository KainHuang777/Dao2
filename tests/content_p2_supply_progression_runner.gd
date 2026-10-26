extends SceneTree
var content: GameContent
var s: GameSession
var serial := 0
var checks := 0
var failures := []
var waits := {}
var trace := []
var maintenance := false
var source_path := "res://docs/verification/artifacts/res1-d2-earned-era3.json"
var source_sha := ""
var DIR := "res://docs/verification/artifacts/content-p2-supply-3/" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("supply3-flow/")
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FLOW FAILURE ",label)
func send(kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"type":kind,"payload":payload,"command_id":"supply3-flow-"+str(serial),"expected_revision":s.state.revision})
func value(id: String) -> float: return IslandEconomy.value(s.state,"home",id)
func tick(seconds: float, reason: String) -> bool:
	if not maintenance and s.get_view().max_lifespan_seconds - s.state.total_elapsed_seconds < 2000:
		maintenance = true
		var materials := {"spirit_grass_low":25,"wood":20,"money":30}
		for id in materials:
			if not ensure(id,materials[id]): maintenance = false; return false
		var brew := send("refine_pill",{"pill_id":"lifespan_pill","count":1})
		if not brew.ok: print("BREW ",brew); maintenance = false; return false
		var use := send("consume_pill",{"pill_id":"lifespan_pill"})
		if not use.ok: print("CONSUME ",use); maintenance = false; return false
		maintenance = false
	var result := s.advance_time(seconds)
	if result.get("stopped") != null:
		print("TIME_STOPPED ",result.get("stopped")," age=",s.state.total_elapsed_seconds)
		return false
	waits[reason] = float(waits.get(reason,0)) + seconds
	return result.get("ok",false)
func ensure(id: String, target: float, depth: int = 0) -> bool:
	if depth > 12: print("DEPTH ",id); return false
	var recipe := "stone_mid_bulk" if id == "stone_mid" and s.state.era_id >= 4 else id
	for attempt in 2000:
		if value(id) + 0.000001 >= target: return true
		if content.processing_catalog.recipes.has(recipe):
			var def: Dictionary = content.processing_catalog.recipes[recipe]
			var owner := "herb" if recipe == "liquid" and s.state.era_id >= 3 else "home"
			var count := mini(100, maxi(1,int(ceil((target-value(id))/float(def.output)))))
			# Bound each ingredient batch by its true capacity.
			for input in def.inputs:
				var cap := float(s.get_view().resources[input].cap)
				count = mini(count,maxi(1,int(floor(cap/float(def.inputs[input])))))
			for input in def.inputs:
				if not ensure(input,float(def.inputs[input])*count,depth+1): return false
			var started := send("craft",{"recipe_id":recipe,"island_id":owner,"count":count})
			if not started.ok:
				print("CRAFT ",recipe," ",started)
				return false
			while s.state.economy.jobs.has(owner):
				if not tick(10,"craft:"+recipe): return false
		else:
			if not tick(60,"supply:"+id): return false
	print("ENSURE TIMEOUT ",id," need ",target," have ",value(id))
	return false
func build(id: String) -> bool:
	var def: Dictionary = content.buildings[id]
	if def.prereq != null and int(s.state.buildings.get(def.prereq.building,0)) < int(def.prereq.level):
		while int(s.state.buildings.get(def.prereq.building,0)) < int(def.prereq.level):
			if not build(def.prereq.building): return false
	var costs: Dictionary = s.get_view().buildings[id].costs
	for resource in costs:
		if not ensure(resource,float(costs[resource])): return false
	var result := send("upgrade_building",{"building_id":id})
	if not result.ok: print("BUILD ",id," ",result)
	return result.ok
func opening(id: String) -> bool:
	for resource in IslandEconomy.supply_data().islands[id].cost:
		if not ensure(resource,IslandEconomy.supply_data().islands[id].cost[resource]): return false
	if not send("open_island",{"island_id":id}).ok: return false
	for route in IslandEconomy.supply_data().routes:
		if IslandEconomy.supply_data().routes[route][0] == id:
			if not send("configure_route",{"route_id":route,"enabled":true,"target":"3000","reserve":"0"}).ok: return false
	return true
func save_snapshot(name: String) -> void:
	var saved := SaveCodec.encode(s.state,content.content_version,{"save_id":"supply3-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":str(int(s.state.total_elapsed_seconds))})
	check(saved.ok,"earned snapshot "+name)
	if not saved.ok: print("SNAPSHOT_ERROR ",name," ",saved.error)
	if saved.ok:
		var write_file_snapshot := FileAccess.open(DIR+name+".json",FileAccess.WRITE)
		if write_file_snapshot == null:
			push_error("write failed: " + str(DIR+name+".json"))
			RunnerResult.finish(self, 1)
		else:
			write_file_snapshot.store_string(saved.json)
func ladder(era: int) -> bool:
	for attempt in 20:
		while s.state.level < 10:
			var costs := Cultivation.level_up_cost(content.eras[era],s.state.level,0)
			for id in costs:
				if not ensure(id,costs[id].to_float()): return false
			print("TRACE ladder era",era," lvl",s.state.level)
			while not s.get_view().training_complete:
				if not tick(60,"training:era"+str(era)): return false
			var result := send("level_up_cultivation")
			check(result.ok,"earned era%d level%d" % [era,s.state.level])
			if not result.ok: print(result);return false
			save_snapshot("last-earned-level")
		if era == 6: return true
		var result := send("breakthrough_era")
		check(result.ok,"breakthrough command era"+str(era))
		trace.append({"from":era,"to":s.state.era_id,"age":s.state.total_elapsed_seconds,"result":result})
		if s.state.era_id == era+1: return true
		if s.state.era_id != era: print("FAILED TRIBULATION ",s.state.era_id);return false
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"content")
	var resume := OS.get_environment("DAO_SUPPLY3_RESUME")
	if not resume.is_empty():
		source_path = resume
		serial = 100000
	var source_raw := FileAccess.get_file_as_string(source_path)
	source_sha = source_raw.sha256_text()
	var decoded := SaveCodec.decode(source_raw)
	check(decoded.ok,"dated earned D2 source")
	s = GameSession.new()
	s.content = content
	s.state = decoded.state if decoded.state.economy.get("version") == IslandProgression.SUPPLY_VERSION else IslandProgression.prepare_supply(content,decoded.state).state
	s.state.tribulation_seed = 1
	s.state.tribulation_roll_index = 0
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	check(s.state.skills.is_empty(),"no-skill earned source")
	var ok := true
	for era in ([3,4,5,6] if resume.is_empty() else []):
		print("FLOW ERA ",era," age=",s.state.total_elapsed_seconds)
		if era == 3: ok = build("core_storehouse_3")
		if era == 4:
			ok = opening("deep") and build("mineral_focus") and build("core_storehouse_4") and build("cultivation_focus_4")
			if ok:
				ok = ensure("refined_iron",30) and ensure("stone_low",100)
				# A legal alternative branch buys/feeds a turtle, then returns to this earned state.
				var branch := s.state.duplicate_state()
				check(send("acquire_beast",{"beast_id":"iron_turtle"}).ok,"earned turtle acquire")
				var iron_before := value("refined_iron")
				check(send("feed_beast").ok and value("refined_iron") == iron_before-30,"earned turtle real feed")
				s.state = branch
		if era == 5: ok = opening("ancient") and build("ancient_focus") and build("core_storehouse_5") and build("cultivation_focus_5")
		if era == 6:
			print("TRACE era6 start age=",s.state.total_elapsed_seconds)
			ok = opening("void") and build("void_focus") and build("cultivation_focus_6")
			print("TRACE era6 build ok=",ok)
			if ok:
				ok = ensure("spirit_grass_1000y",10)
				print("TRACE era6 grass ok=",ok)
				check(send("acquire_beast",{"beast_id":"fire_phoenix"}).ok,"earned phoenix acquire")
				var grass_before := value("spirit_grass_1000y")
				check(send("feed_beast").ok and value("spirit_grass_1000y") == grass_before-10,"earned phoenix real feed")
				print("TRACE era6 feed done")
		if not ok: check(false,"supply/build era"+str(era)); break
		print("TRACE pre-snapshot era",era)
		save_snapshot("earned-era"+str(era))
		print("TRACE pre-ladder era",era)
		if not ladder(era): check(false,"ladder era"+str(era));break
		print("TRACE post-ladder era",era)
		await process_frame
	check(s.state.era_id == 6 and s.state.level == 10,"no-skill Era6 level10")
	if failures.is_empty():
		save_snapshot("earned-era6-level10")
		check(not send("breakthrough_era").ok,"Era7 remains closed")
		var remaining: float = s.get_view().max_lifespan_seconds - s.state.total_elapsed_seconds
		var aged := s.advance_time(remaining + 1)
		check(aged.get("stopped") == "lifespan_exhausted","natural simulated lifespan exhaustion before rebirth")
		var rebirth := send("reincarnate",{"mode":"normal","tribulation_seed":20261024})
		check(rebirth.ok,"earned reincarnation: "+str(rebirth.get("error","")))
		for id in ["deep","ancient","void"]: check(not s.state.economy.islands[id].opened,"reincarnation closes "+id)
		check(s.state.skills.is_empty(),"no skills purchased")
		save_snapshot("earned-reborn")
	print("TRACE tail start failures=",failures.size())
	var report := {"level":"L2","source_path":source_path,"source_sha256":source_sha,"checks":checks,"failures":failures,"waits_seconds":waits,"trace":trace,"age":s.state.total_elapsed_seconds}
	var write_file_flow := FileAccess.open(DIR+"earned-flow.json",FileAccess.WRITE)
	if write_file_flow == null:
		push_error("write failed: " + str(DIR+"earned-flow.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_flow.store_string(JSON.stringify(report,"\t"))
	print("SUPPLY-3 FLOW ",JSON.stringify(report))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
