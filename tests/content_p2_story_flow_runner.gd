extends "res://tests/content_p2_supply_progression_runner.gd"
## Dated earned starts; production, commands and normal timed RNG, no inventory grants.
var OUT := (OS.get_environment("DAO_TEST_STORAGE_ROOT") if not OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else "res://.test-output").path_join("story2-flow/")
const META := {"save_id":"story2-earned","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}
var branches := []
var claims := []
var natural := []
func send(kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"type":kind,"payload":payload,"command_id":"story2-earned-flow-"+str(serial),"expected_revision":s.state.revision})
func save_snapshot(name: String) -> void:
	var encoded := SaveCodec.encode(s.state,content.content_version,META)
	check(encoded.ok,"encode earned "+name+str(encoded.get("error","")))
	if encoded.ok:
		var file := FileAccess.open(OUT+name+".json",FileAccess.WRITE)
		file.store_string(encoded.json)
func claim(id: String) -> void:
	check(StoryProgressP2.achievement_met(s.state,id),"earned condition "+id)
	if AchievementSystem.P2_DEFINITIONS[id].get("rewards",{}).get("resource",{}).has("spirit_grass_low"):
		# Make enough room through real recipes; never trim a full inventory.
		var count := int(ceil(float(AchievementSystem.P2_DEFINITIONS[id].rewards.resource.spirit_grass_low)/25.0))
		for resource in AlchemySystem.refinement_cost(s.state,"lifespan_pill"):
			check(ensure(resource,AlchemySystem.refinement_cost(s.state,"lifespan_pill")[resource].to_float()*count),"claim capacity materials")
		for i in count: check(send("refine_pill",{"pill_id":"lifespan_pill"}).ok,"use actual grass before claim")
		for attempt in 24:
			if not StoryProgress.claim_error(s.state,content,id).begins_with("STORY_DESTINATION_FULL:spirit_grass_low"): break
			for resource in AlchemySystem.refinement_cost(s.state,"lifespan_pill"): check(ensure(resource,AlchemySystem.refinement_cost(s.state,"lifespan_pill")[resource].to_float()),"retained grass capacity materials")
			check(send("refine_pill",{"pill_id":"lifespan_pill"}).ok,"consume retained over-cap grass legally")
	if id=="p2_mature_stag": save_snapshot("review-album")
	var reward: Dictionary = AchievementSystem.P2_DEFINITIONS[id].get("rewards",{}).get("resource",{})
	if reward.has("stone_low") and value("stone_low")+float(reward.stone_low)>StoryProgress.cap(s.state,content,"stone_low").to_float():
		check(build("storage_stone"),"upgrade actual stone storage for reward room")
	if reward.has("lingli") and value("lingli")+float(reward.lingli)>StoryProgress.cap(s.state,content,"lingli").to_float():
		for resource in AlchemySystem.refinement_cost(s.state,"nascent_breath_pill"): check(ensure(resource,AlchemySystem.refinement_cost(s.state,"nascent_breath_pill")[resource].to_float()),"real qi capacity materials")
		check(send("refine_pill",{"pill_id":"nascent_breath_pill"}).ok,"spend real qi before reward")
	var result := send("claim_achievement",{"achievement_id":id})
	check(result.ok,"earned claim "+id+str(result.get("error","")))
	if result.ok: claims.append({"id":id,"era":s.state.era_id,"result":result})
	check(not send("claim_achievement",{"achievement_id":id}).ok,"no double claim "+id)
func brew(id: String) -> void:
	for resource in AlchemySystem.refinement_cost(s.state,id):
		check(ensure(resource,AlchemySystem.refinement_cost(s.state,id)[resource].to_float()),"earned pill material "+resource)
	check(send("refine_pill",{"pill_id":id}).ok,"earned refine "+id)
	# Capacity/ward pills can be consumed with completed training; no synthetic gap.
	check(send("consume_pill",{"pill_id":id}).ok,"earned consume "+id)
func settle_pending() -> void:
	if not s.state.fortune.pending_encounter.is_empty():
		var pending: Dictionary = s.state.fortune.pending_encounter
		var result := send("resolve_fortune",{"option_index":mini(2,pending.options.size()-1),"instance_id":DecisionReceipt.pending_id(s.state)})
		check(result.ok,"depart existing normal encounter "+str(result.get("error","")))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach supply")
	for era in ([6] if OS.get_environment("DAO_STORY2_ERAS")=="6" else [4,5,6]):
		print("STORY2 earned branch era",era)
		serial += 10000
		var source := "res://docs/verification/artifacts/content-p2-supply-3/earned-era%d.json" % era
		var raw := FileAccess.get_file_as_string(source)
		var adapter := FileStorageAdapter.new(OUT+"storage-era"+str(era))
		SaveSlots.new(adapter).reset()
		check(adapter.write(SaveSlots.SLOT_MAIN,raw).ok,"seed dated earned source")
		SaveManager.configure(content,adapter)
		s = GameSession.new(); s.content = content; s.state = SaveManager.current_state()
		if s.state == null: check(false,"load earned source"); break
		check(SaveManager.save(s.state,META).ok,"commit actual migration")
		s.clock = GameClock.create(s.state.total_elapsed_seconds)
		var start := s.state.total_elapsed_seconds
		settle_pending()
		for island in (["deep"] if era == 4 else ["deep","ancient"] if era == 5 else ["deep","ancient","void"]):
			if not s.state.economy.islands[island].opened: check(opening(island),"earned opening "+island)
			for route in IslandEconomy.supply_data().routes:
				if IslandEconomy.supply_data().routes[route][0] == island:
					check(send("configure_route",{"route_id":route,"enabled":true,"target":"3000","reserve":"0"}).ok,"normal route "+route)
		check(tick(120,"real home arrivals"),"normal arrival timing")
		if era<6: claim("p2_deep_arrivals")
		if era >= 5: claim("p2_ancient_arrival")
		if era == 6: claim("p2_void_arrival")
		if era<6:
			brew("spirit_vessel_pill")
			brew("calm_tribulation_pill")
		if era == 5:
			brew("stone_vault_pill"); brew("silver_ward_pill")
			claim("p2_vessels_and_wards")
		if era in [4,5]:
			var beast := "frost_stag" if era == 4 else "herb_crane"
			check(send("acquire_beast",{"beast_id":beast}).ok,"earned beast acquire "+beast)
			for feed in 20:
				for resource in BeastSystem.feed_costs(s.state,beast): check(ensure(resource,BeastSystem.feed_costs(s.state,beast)[resource]),"earned feed material")
				if s.state.beasts.cooldown_remaining > 0: check(tick(s.state.beasts.cooldown_remaining,"natural feed cooldown"),"cooldown elapsed")
				check(send("feed_beast").ok,"earned feed "+str(feed))
			claim("p2_mature_stag" if era == 4 else "p2_mature_crane")
		# Normal countdown and saved fortune RNG; never trigger_fortune or inject pending.
		var found := false
		for attempt in (60 if era==4 else 0):
			if not s.state.fortune.pending_encounter.is_empty():
				if s.state.fortune.pending_encounter.get("content_batch") == "content-p2-story":
					found = true; break
				settle_pending()
			check(tick(600,"normal encounter countdown"),"normal timed encounter")
		if era==4: check(found,"normal timed P2 encounter era"+str(era))
		if found:
			var pending: Dictionary = s.state.fortune.pending_encounter.duplicate(true)
			# Leave a genuine earned + naturally generated review state before decision.
			save_snapshot("review-era"+str(era))
			check(SaveManager.save(s.state,META).ok,"save natural pending")
			var result := send("resolve_fortune",{"option_index":2,"instance_id":pending.instance_id})
			check(result.ok,"natural P2 formal decision")
			natural.append({"era":era,"pending":pending,"result":result,"age":s.state.total_elapsed_seconds})
		check(SaveManager.save(s.state,META).ok,"save representative results")
		SaveManager.configure(content,adapter)
		var reloaded := SaveManager.current_state()
		check(reloaded != null and JSON.stringify(reloaded.achievements)==JSON.stringify(s.state.achievements),"reload earned facts/claims")
		check(reloaded != null and JSON.stringify(reloaded.life_ledger.current.decisions) == JSON.stringify(s.state.life_ledger.current.decisions),"reload decision book")
		branches.append({"era":era,"source":source,"sha256":raw.sha256_text(),"start_age":start,"end_age":s.state.total_elapsed_seconds,"facts":StoryProgressP2.facts(s.state,true)})
		await process_frame
	var file := FileAccess.open(OUT+"flow.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"level":"L2","checks":checks,"failures":failures,"branches":branches,"claims":claims,"natural_encounters":natural,"waits":waits,"boundary":"Independent dated earned Era4-6 snapshots; formal commands and normally timed saved RNG with simulated seconds, not wall-clock or browser natural progression. No claim that all18 encounters occur or all18 achievements are naturally earned."},"\t"))
	print("STORY2 FLOW ",checks," failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
