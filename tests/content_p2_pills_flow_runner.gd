extends "res://tests/content_p2_supply_progression_runner.gd"
## Reuse the earned supply driver's commands, recursive crafting and lifespan maintenance.
const OUT := "res://docs/verification/artifacts/content-p2-pills-ui/"
var uses := []
func save_snapshot(name: String) -> void:
	var encoded := SaveCodec.encode(s.state,content.content_version,{"save_id":"pill2-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":str(int(s.state.total_elapsed_seconds))})
	check(encoded.ok,"snapshot "+name)
	if encoded.ok:
		var file := FileAccess.open(OUT+name+".json",FileAccess.WRITE)
		file.store_string(encoded.json)
func pill(id: String) -> bool:
	for resource in AlchemySystem.PILLS[id].cost:
		if not ensure(resource,float(AlchemySystem.PILLS[id].cost[resource])): return false
	if id in AlchemySystem.P2_TRAINING and s.get_view().training_complete:
		var costs := Cultivation.level_up_cost(content.eras[s.state.era_id],s.state.level,0)
		for resource in costs:
			if not ensure(resource,costs[resource].to_float()): return false
		if not send("level_up_cultivation").ok: return false
	var before := s.state.to_snapshot_dict()
	var refined := send("refine_pill",{"pill_id":id})
	check(refined.ok,"earned refine "+id)
	var preview := AlchemySystem.p2_preview(s.state,id)
	var consumed := send("consume_pill",{"pill_id":id})
	check(consumed.ok,"earned effective consume "+id+str(consumed.get("error","")))
	uses.append({"id":id,"era":s.state.era_id,"age":s.state.total_elapsed_seconds,"preview":preview,"before_resources":before.resources,"receipt":consumed})
	return refined.ok and consumed.ok
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"content")
	source_path = "res://docs/verification/artifacts/content-p2-supply-3/earned-era4.json"
	var raw := FileAccess.get_file_as_string(source_path)
	source_sha = raw.sha256_text()
	# Exercise the real migration/archive/candidate gate using an isolated directory.
	var test_root := OS.get_environment("DAO_TEST_STORAGE_ROOT")
	var adapter := FileStorageAdapter.new(test_root.path_join("pill2-earned-flow") if not test_root.is_empty() else "user://pill2-earned-flow")
	SaveSlots.new(adapter).reset()
	check(adapter.write(SaveSlots.SLOT_MAIN,raw).ok,"seed dated earned snapshot")
	SaveManager.configure(content,adapter)
	s = GameSession.new()
	s.content = content
	s.state = SaveManager.current_state()
	check(s.state != null,"load candidate")
	if s.state == null: RunnerResult.finish(self,1); return
	check(SaveManager.save(s.state,{"save_id":"pill2-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}).ok and not SaveManager.migration_pending(s.state),"commit migrated candidate")
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	check(s.state.era_id == 4 and s.state.level == 1 and s.state.skills.is_empty(),"earned Era4 level1 no skills")
	var start_age := s.state.total_elapsed_seconds
	var ok := true
	for era in [4,5,6]:
		print("PILL2 EARNED ERA ",era," age=",s.state.total_elapsed_seconds)
		if era == 5: ok = opening("ancient") and build("ancient_focus") and build("core_storehouse_5") and build("cultivation_focus_5")
		if era == 6: ok = opening("void") and build("void_focus") and build("cultivation_focus_6")
		if not ok: check(false,"earned supply era"+str(era)); break
		# Collect/craft/ship every ingredient using existing production and routes.
		var ids: Array = ["nascent_breath_pill","spirit_vessel_pill","calm_tribulation_pill"] if era == 4 else ["ancient_herb_dew_pill","stone_vault_pill","calm_tribulation_pill","silver_ward_pill"] if era == 5 else ["void_gathering_pill","void_meditation_pill"]
		for id in ids:
			if not pill(id): ok = false; break
		if not ok: break
		save_snapshot("earned-era"+str(era))
		if era < 6 and not ladder(era): check(false,"ladder era"+str(era)); ok = false; break
		await process_frame
	check(ok and s.state.era_id == 6,"continuous earned Era4 to Era6")
	check(uses.size() == 9,"all eight IDs effective; calm once per era")
	var report := {"level":"L2","source":source_path,"source_sha256":source_sha,"checks":checks,"failures":failures,"start_age":start_age,"end_age":s.state.total_elapsed_seconds,"waits":waits,"tribulation_trace":trace,"uses":uses,"evidence":"dated earned Era4 snapshot, continuous formal commands and simulated time; not browser natural-time progression"}
	var file := FileAccess.open(OUT+"flow.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("PILL2 FLOW ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
