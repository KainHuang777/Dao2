extends "res://tests/content_p2_story_runner.gd"
## Funded fixtures exercise real command and online/offline hooks, not natural play.
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach supply")
	_pills()
	_arrivals()
	_sect()
	_beasts()
	_rng()
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR+"events.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"funded command fixtures and simulated time; no natural player pacing claim"},"\t"))
	print("CONTENT-P2-STORY-EVENTS ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
func clean() -> GameSession:
	var s := fresh()
	s.state.achievements.story.p2.lifetime = StoryProgressP2.blank(); s.state.achievements.story.p2.current = StoryProgressP2.blank()
	s.state.achievements.unlocked.clear(); s.state.skills = {}; s.state.talents = {}
	for id in s.state.resources: s.state.resources[id].value = AmountCompat.from_number(10000)
	s.state.resources.foundation_pill.value = AmountCompat.zero()
	return s
func _pills() -> void:
	for id in AlchemySystem.P2_IDS:
		var s := clean()
		s.state.era_id = 5 if id == "silver_ward_pill" else 4 if id == "calm_tribulation_pill" else 6
		for building in content.building_ids: s.state.buildings[building] = 1
		var index := AlchemySystem.P2_IDS.find(id)
		check(send(s,"refine_pill",{"pill_id":id,"count":1}).ok,"official refine "+id)
		check(StoryProgressP2.facts(s.state,true).refined_mask == 1 << index,"refine isolated bit")
		var result := send(s,"consume_pill",{"pill_id":id,"count":1})
		check(result.ok,"official consume "+id+str(result.get("error")))
		check(StoryProgressP2.facts(s.state,true).consumed_mask == 1 << index,"consume isolated bit")
		var facts := StoryProgressP2.facts(s.state,true).duplicate()
		check(not send(s,"consume_pill",{"pill_id":id,"count":1}).ok and StoryProgressP2.facts(s.state,true) == facts,"empty consume no flags")
func _arrivals() -> void:
	var s := clean()
	for id in s.state.resources: s.state.resources[id].value = AmountCompat.zero()
	for route in StoryProgressP2.ARRIVALS:
		var source: String = IslandEconomy.route_defs(s.state)[route][0]
		var resource: String = IslandEconomy.route_defs(s.state)[route][2]
		s.state.economy.islands[source].inventory[resource] = "10"
		check(send(s,"configure_route",{"route_id":route}).ok,"configure route "+route)
	check(StoryProgressP2.facts(s.state,true).arrival_mask == 0,"dispatch not arrival")
	var offline := s.state.duplicate_state()
	var prepared := s.state.duplicate_state()
	TimeAdvancer.advance(s.state,content,100)
	OfflineSettlement.settle(offline,content,101000,1000)
	OfflineEconomyJump.advance(prepared,content,100,{})
	check(StoryProgressP2.facts(s.state,true).arrival_mask == 31,"five actual home arrivals")
	check(StoryProgressP2.facts(offline,true) == StoryProgressP2.facts(s.state,true),"online/offline identical masks")
	check(StoryProgressP2.facts(prepared,true).arrival_mask == 31,"prepared offline arrival hooks")
	# Legal full inventories prevent dispatch; the observer separately rejects zero delta.
	for route in StoryProgressP2.ARRIVALS:
		var blocked := clean()
		var resource: String = IslandEconomy.route_defs(blocked.state)[route][2]
		blocked.state.resources[resource].value = AmountCompat.from_number(IslandEconomy.home_cap(blocked.state,resource,content.processing_catalog))
		check(send(blocked,"configure_route",{"route_id":route}).ok,"full route configured")
		for i in 20: IslandEconomy.tick(blocked.state,content.processing_catalog)
		StoryProgress.arrived(blocked.state,route,0)
		check(StoryProgressP2.facts(blocked.state,true).arrival_mask == 0 and not blocked.state.economy.trips.has(route),"full no departure and zero delta not fact "+route)
func _sect() -> void:
	for id in StoryProgressP2.TASKS:
		var s := clean()
		for resource in s.state.resources: s.state.resources[resource].value = AmountCompat.zero()
		var t: Dictionary = SectSystem.P2_TASKS[id]
		var cfg: Dictionary = SectSystem.RARITY_CONFIGS[t.rarity]
		var rewards: Dictionary = t.rewards.duplicate(true); rewards.contribution = cfg.contrib_min; rewards.money = int(50*float(cfg.reward_mult)*6)
		var task := {"id":"story2-task-"+id,"template_id":id,"generation_era":6,"name":t.name,"desc":t.desc,"rarity":t.rarity,"rarity_name":cfg.name,"rarity_color":cfg.color,"duration":cfg.duration,"elapsed":0,"rewards":rewards}
		s.state.sect.available_tasks = [task]
		check(send(s,"start_sect_expedition",{"task_id":task.id}).ok,"dispatch "+id)
		check(not send(s,"claim_sect_expedition").ok and StoryProgressP2.facts(s.state,true).task_mask == 0,"early claim not fact")
		SectSystem.tick(s.state,float(cfg.duration))
		check(StoryProgressP2.facts(s.state,true).task_mask == 0,"completed unclaimed not fact")
		check(send(s,"claim_sect_expedition").ok,"claim "+id)
		check(StoryProgressP2.facts(s.state,true).task_mask == 1 << StoryProgressP2.TASKS.find(id),"specific template bit")
	for id in StoryProgressP2.MARKET:
		var s := clean(); s.state.sect.contribution = "10000"
		for resource in s.state.resources: s.state.resources[resource].value = AmountCompat.zero()
		check(send(s,"buy_sect_market_item",{"item_id":id}).ok,"official purchase "+id)
		check(StoryProgressP2.facts(s.state,true).market_mask == 1 << StoryProgressP2.MARKET.find(id),"market isolated bit")
	var s := clean(); var f: Dictionary = s.state.achievements.story.p2.lifetime
	f.task_mask = 1 | 4 | 128
	check(not StoryProgressP2.achievement_met(s.state,"p2_frontier_commissions"),"three deep tasks not three groups")
	f.task_mask = 128 | 2 | 64
	check(StoryProgressP2.achievement_met(s.state,"p2_frontier_commissions"),"ward task belongs to deep")
func _beasts() -> void:
	var s := clean()
	for id in StoryProgressP2.BEASTS:
		s.state.beasts = {"active":{"id":id,"stage":"growing","exp":950},"cooldown_remaining":0}
		var result := send(s,"feed_beast")
		check(result.ok,"final official feed "+id+str(result.get("error")))
		check(s.state.beasts.active.stage == "mature" and int(StoryProgressP2.facts(s.state,true).mature_mask) & (1 << StoryProgressP2.BEASTS.find(id)) != 0,"mature fact "+id)
		s.state.total_elapsed_seconds = 1e9
		var result_reborn := send(s,"reincarnate",{"mode":"normal"})
		check(result_reborn.ok,"official exhausted rebirth "+str(result_reborn.get("error")))
		check(StoryProgressP2.facts(s.state).mature_mask == 0,"maturity current cleared")
		s.state.era_id = 6; s.state.total_elapsed_seconds = 0
		for island in s.state.economy.islands: s.state.economy.islands[island].opened = true
		for resource in s.state.resources: s.state.resources[resource].value = AmountCompat.from_number(10000)
	check(StoryProgressP2.facts(s.state,true).mature_mask == 15,"four beasts across separate official lives")
func _rng() -> void:
	var s := fresh(); var sequence := s.state.duplicate_state()
	var seen := {}
	for i in 128:
		s.state.fortune.pending_encounter = {}; sequence.fortune.pending_encounter = {}
		var actual := FortuneSystem.trigger_fortune(s.state)
		var replay := FortuneSystem.trigger_fortune(sequence)
		check(actual == replay and s.state.fortune.rng_state == sequence.fortune.rng_state,"saved RNG replay")
		seen[actual.id] = true
		var rng_before: int = s.state.fortune.rng_state
		s.get_view(); FortuneSystem.trigger_fortune(s.state)
		check(rng_before == s.state.fortune.rng_state,"view/pending no draw")
		var encoded := SaveCodec.encode(s.state,content.content_version,META)
		check(encoded.ok,"pending/RNG encode")
		if encoded.ok: sequence = SaveCodec.decode(encoded.json).state
	check(seen.size() > 1,"default RNG varied")
