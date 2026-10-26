extends "res://tests/early_v1c_skills_runner.gd"
## Integration evidence uses only current content, earned inventory and formal commands.
const ACCEPT_DIR := "res://docs/verification/artifacts/content-p1-accept/"
var milestones: Array = []
var comparisons: Array = []

func mark(s: GameSession, label: String) -> void:
	milestones.append({"label":label,"age_seconds":s.state.total_elapsed_seconds,"era":s.state.era_id,"level":s.state.level,"revision":s.state.revision})
	print("ACCEPT milestone: ",label," age=",s.state.total_elapsed_seconds)

func save_case(s: GameSession, label: String) -> void:
	var encoded := SaveCodec.encode(s.state,content.content_version,SAVE_META)
	check(encoded.ok,"encode "+label)
	if encoded.ok:
		var write_file_encoded := FileAccess.open("res://src/verification/content_p1_accept_"+label+".json",FileAccess.WRITE)
		if write_file_encoded == null:
			push_error("write failed: " + str("res://src/verification/content_p1_accept_"+label+".json"))
			RunnerResult.finish(self, 1)
		else:
			write_file_encoded.store_string(encoded.json)
	var memory := Memory.new()
	SaveManager.configure(content,memory)
	check(SaveManager.save(s.state,SAVE_META).ok,"save "+label)
	SaveManager.configure(content,memory)
	var loaded := SaveManager.current_state()
	var canonical := SaveCodec.decode(encoded.json)
	# Rebirth clears buildings; the normal loader restores zero-valued study keys.
	# Account for this existing reconciliation and its revision, without inventing levels.
	if canonical.ok and SkillSystem.reconcile(content,canonical.state): canonical.state.revision+=1
	check(loaded != null and canonical.ok and loaded.to_snapshot_dict() == canonical.state.to_snapshot_dict(),"readback identical encoded state "+label)
	if loaded != null and canonical.ok and loaded.to_snapshot_dict() != canonical.state.to_snapshot_dict():
		var write_file_readback := FileAccess.open(ACCEPT_DIR+"readback-diff-"+label+".json",FileAccess.WRITE)
		if write_file_readback == null:
			push_error("write failed: " + str(ACCEPT_DIR+"readback-diff-"+label+".json"))
			RunnerResult.finish(self, 1)
		else:
			write_file_readback.store_string(JSON.stringify({"expected":canonical.state.to_snapshot_dict(),"actual":loaded.to_snapshot_dict()},"\t"))
	var before_retry := s.state.to_snapshot_dict()
	memory.refuse=true
	check(not SaveManager.save(s.state,SAVE_META).ok,"write refusal "+label)
	memory.refuse=false
	check(SaveManager.save(s.state,SAVE_META).ok and before_retry==s.state.to_snapshot_dict(),"save-only retry no gameplay replay "+label)
	SaveManager.reset_for_tests()

func earned(s: GameSession, kind: String, payload: Dictionary, label: String) -> bool:
	var result := send(s,kind,payload)
	check(result.ok,label+" "+str(result.get("error","")))
	return result.ok

func earn_sect(s: GameSession, target: float) -> void:
	if s.state.sect.is_empty(): earned(s,"join_sect",{"sect_name":"太虛天闕"},"join")
	for i in 20:
		if float(s.state.sect.contribution) >= target: break
		if s.state.sect.available_tasks.is_empty():
			s.advance_time(maxf(1,float(s.state.sect.next_refresh_seconds)))
			if not earned(s,"refresh_sect_tasks",{},"refresh"): return
		var task: Dictionary = s.state.sect.available_tasks[0]
		for candidate in s.state.sect.available_tasks:
			if int(candidate.duration) < int(task.duration): task = candidate
		if not earned(s,"start_sect_expedition",{"task_id":task.id},"dispatch "+str(task.id)): return
		s.advance_time(float(task.duration))
		if not earned(s,"claim_sect_expedition",{},"claim expedition"): return
	check(float(s.state.sect.contribution)>=target,"contribution naturally earned")

func rebuild(s: GameSession) -> bool:
	for id in BUILD_ORDER:
		if not helper.build(s,id): check(false,"second life build "+id); return false
	if not level_to(s,10): check(false,"second life Era1 Lv10"); return false
	if not earned(s,"breakthrough_era",{},"second life Era2"): return false
	if s.state.economy.is_empty():
		if not earned(s,"activate_islands",{},"second life islands"): return false
	for island in ["wood","ore"]:
		if not earned(s,"open_island",{"island_id":island},"second life open"): return false
	for route in IslandEconomy.ROUTES:
		if IslandEconomy.ROUTES[route][0] != "herb": earned(s,"configure_route",{"route_id":route},"second life route")
	for pair in [["spirit_timber","wood"],["bronze_essence","ore"]]:
		check(helper.wait_craft(s,pair[0],pair[1]),"second life producer")
	for i in 30: check(helper.wait_recipe(s,"liquid"),"second life liquid")
	check(helper.build(s,"library"),"second life library")
	check(helper.build(s,"storage_wood"),"second life wood storage")
	check(helper.build(s,"scripture_hall"),"second life scripture")
	if not level_to(s,10): check(false,"second life Era2 Lv10"); return false
	check(helper.build(s,"foundation_reservoir") and helper.build(s,"foundation_reservoir"),"second life reservoir")
	return earned(s,"breakthrough_era",{},"second life Era3")

func compare(s: GameSession, id: String) -> void:
	print("ACCEPT compare: ",id)
	var b := branch(s.state)
	if id != "retain": earned(b,"learn_talent",{"talent_id":id},"second life purchase "+id)
	var record := {"choice":id,"hearts":b.state.dao_heart.to_float(),"rates":{},"age_at_choice":b.state.total_elapsed_seconds}
	record.max_lifespan_seconds=b.get_view().max_lifespan_seconds
	record.cultivation_multiplier=TalentSystem.compute_multipliers(b.state).cultivation_speed_bonus
	for resource in ["wood","stone_low","spirit_grass_low","money","lingli"]:
		record.rates[resource] = view_number(b,resource,"rate")
	# One paid pill at a shared uncapped Era3 training state; no training reset.
	var before := b.state.training_seconds
	earned(b,"refine_pill",{"pill_id":"cultivation_pill"},"earned training pill "+id)
	earned(b,"consume_pill",{"pill_id":"cultivation_pill"},"use training pill "+id)
	record.pill_training_seconds = b.state.training_seconds-before
	check(is_equal_approx(float(record.pill_training_seconds),66 if id=="alchemical_past_wisdom" else 60),"uncapped paid pill benefit "+id)
	earned(b,"acquire_beast",{"beast_id":"jade_fox"},"earned fox "+id)
	var feeding_start := b.state.total_elapsed_seconds
	var feeds := 0
	var grass_spent := 0.0
	for i in 25:
		if b.state.beasts.active.stage == "mature": break
		var cd := float(b.state.beasts.get("cooldown_remaining",0))
		if cd > 0: b.advance_time(cd)
		var grass_before: float = b.state.resources.spirit_grass_low.value.to_float()
		if not earned(b,"feed_beast",{},"earned feed "+id): break
		grass_spent += grass_before-b.state.resources.spirit_grass_low.value.to_float()
		feeds += 1
	check(b.state.beasts.active.stage == "mature","fox maturity "+id)
	record.feeds_to_mature = feeds
	record.feed_grass = grass_spent
	record.feed_elapsed_seconds = b.state.total_elapsed_seconds-feeding_start
	check(feeds==(17 if id=="beast_bond_past_wisdom" else 20),"paid feed count "+id)
	save_case(b,id)
	comparisons.append(record)

func _run() -> void:
	content = ContentLoader.load_directory("res://content").content
	helper.content = content
	check(IslandProgression.attach(content).ok,"current content attached")
	seed(20261023) # Reproducible sect choices; fortune has its own persisted stream.
	if play_prefix():
		var s := branch(era3_state)
		mark(s,"blank-to-Era3 legal prefix; accelerated CLI")
		for id in ["greenwood_nourishment","ore_breath_refinement","herbal_spirit_nurture","warehouse_preparation","alchemical_breath_control"]:
			accumulate_to(s,float(content.skill_defs[id].cost),1)
			earned(s,"learn_skill",{"skill_id":id},"integrated skill "+id)
		mark(s,"five new skills")
		for id in AlchemySystem.P1_IDS:
			earned(s,"refine_pill",{"pill_id":id},"integrated refine "+id)
			earned(s,"consume_pill",{"pill_id":id},"integrated consume "+id)
		mark(s,"four paid pills active")
		earn_sect(s,250)
		for id in ["alchemy_herb_conservation","fox_feed_conservation"]:
			earned(s,"learn_sect_technique",{"technique_id":id},"integrated technique "+id)
		earned(s,"buy_sect_market_item",{"item_id":"herb_nurture_supply"},"integrated market")
		mark(s,"sect contribution spent")
		if not earned(s,"claim_achievement",{"achievement_id":"p1_greenwood_student"},"integrated achievement"):
			check(helper.build(s,"storage_wood"),"earned extra wood space")
			earned(s,"claim_achievement",{"achievement_id":"p1_greenwood_student"},"claim after capacity expansion")
		var found := false
		for i in 30:
			if s.state.fortune.get("pending_encounter",{}).is_empty(): s.advance_time(maxf(1,float(s.state.fortune.get("cooldown_remaining",1200))))
			var pending: Dictionary = s.state.fortune.get("pending_encounter",{})
			if pending.is_empty(): break
			var fresh: bool = pending.get("content_batch","") == "content-p1-story"
			if not earned(s,"resolve_fortune",{"option_index":pending.options.size()-1,"instance_id":DecisionReceipt.pending_id(s.state)},"natural fortune "+str(pending.id)): break
			if fresh: found=true; break
		check(found,"new fortune naturally selected without seed/cooldown injection")
		mark(s,"natural new fortune")
		save_case(s,"integrated")
		# Eligibility is earned by actual lifespan exhaustion, never by setting age/buildings.
		while not s.get_reincarnation_preview().eligible:
			var time := s.advance_time(3600)
			check(time.ok,"wait for natural lifespan exhaustion")
		mark(s,"lifespan exhausted")
		check(earned(s,"reincarnate",{"mode":"normal"},"formal first rebirth") and s.state.dao_heart.to_float()==20,"first rebirth earns twenty hearts")
		check(s.state.skills.is_empty() and s.state.pills.is_empty() and ReincarnationRules.building_level_sum(s.state.buildings)==0,"life-bound content reset")
		mark(s,"second life begins")
		save_case(s,"reborn")
		if rebuild(s):
			mark(s,"second life rebuilt to Era3 without buying talents")
			save_case(s,"second_base")
			for id in ["retain","alchemical_past_wisdom","artisan_past_wisdom","beast_bond_past_wisdom","resource_inheritance","lifespan_extension","innate_dao_body"]:
				compare(s,id)
	var result := {"checks":checks,"failures":failures,"content_version":content.content_version,"milestones":milestones,"comparisons":comparisons,"evidence":"Current-source legal commands, accelerated simulation, same earned second-life Era3 state at choice. No inventory/era/cooldown/fortune injection. Rates include held-heart opportunity cost. No browser natural-wait claim."}
	var write_file_integration := FileAccess.open(ACCEPT_DIR+"integration.json",FileAccess.WRITE)
	if write_file_integration == null:
		push_error("write failed: " + str(ACCEPT_DIR+"integration.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_integration.store_string(JSON.stringify(result,"\t"))
	print("CONTENT-P1-ACCEPT ",checks," checks failures=",JSON.stringify(failures))
	SaveManager.reset_for_tests()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
