extends SceneTree
## Synthetic isolated rule fixtures; earned representative flow belongs to PILL-2.
const DIR := "res://docs/verification/artifacts/content-p2-pills/"
var content: GameContent
var checks := 0
var failures: Array[String] = []
var serial := 0
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)
func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"pill2-"+str(serial),"type":kind,"payload":payload,"expected_revision":s.state.revision})
func fresh(era: int = 6) -> GameSession:
	var s := GameSession.create_new_game(content, 20261025)
	s.state.era_id = era
	s.state.highest_era = 6
	s.state.buildings.core_storehouse_4 = 1
	s.state.buildings.core_storehouse_5 = 1
	check(send(s,"activate_islands").ok,"synthetic supply activation")
	for island in s.state.economy.islands: s.state.economy.islands[island].opened = true
	for id in s.state.resources:
		s.state.resources[id].unlocked = true
		s.state.resources[id].value = AmountCompat.from_number(1000000)
	return s
func rejected(s: GameSession, kind: String, payload: Dictionary, label: String) -> void:
	var before := s.state.to_snapshot_dict()
	var result := send(s,kind,payload)
	check(not result.ok and result.events.is_empty() and before == s.state.to_snapshot_dict(),label)
func previous_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0,value)
	bytes.encode_u64(0,bytes.decode_u64(0)-1)
	return bytes.decode_double(0)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach")
	check(AlchemySystem.PILLS.size() == 20,"20 definitions")
	for id in AlchemySystem.P2_IDS:
		for n in [1,99]:
			var s := fresh()
			var cost := AlchemySystem.refinement_cost(s.state,id,n)
			for resource in cost:
				var short: float = cost[resource].to_float()-0.00001
				s.state.resources[resource].value = AmountCompat.from_number(short)
				rejected(s,"refine_pill",{"pill_id":id,"count":n},id+" short "+resource+str(n))
				s.state.resources[resource].value = AmountCompat.from_number(previous_float(cost[resource].to_float()))
				rejected(s,"refine_pill",{"pill_id":id,"count":n},id+" representable shortfall "+resource+str(n))
				s.state.resources[resource].value = AmountCompat.from_number(1000000)
			var before := s.state.duplicate_state()
			var refined := send(s,"refine_pill",{"pill_id":id,"count":n})
			check(refined.ok and s.state.pills[id] == n,id+" refine "+str(n))
			for resource in cost:
				check(is_equal_approx(before.resources[resource].value.subtract(s.state.resources[resource].value).to_float(), cost[resource].to_float()),id+" exact debit")
			check(not s.state.resources.has(id),id+" no mirror")
		var s := fresh(5 if id == "silver_ward_pill" else 6)
		s.state.pills[id] = 99
		for n in [true,0,-1,1.5,"1",INF,NAN,100]:
			for kind in ["refine_pill","consume_pill"]: rejected(s,kind,{"pill_id":id,"count":n},id+" invalid "+str(n))
		for gate in ["era","version","supply","island","building","lifespan"]:
			var original := s.state
			s.state = original.duplicate_state()
			if gate == "era": s.state.era_id = int(AlchemySystem.PILLS[id].min_era)-1
			elif gate == "version": s.state.pill_version = 1
			elif gate == "supply": s.state.economy = {}
			elif gate == "island":
				if id not in AlchemySystem.P2_TIMED:
					s.state = original
					continue
				s.state.economy.islands["ancient" if id == "ancient_herb_dew_pill" else "void"].opened = false
			elif gate == "building":
				if id not in AlchemySystem.P2_CAPACITY:
					s.state = original
					continue
				s.state.buildings[AlchemySystem.P2_CAPACITY[id].building] = 0
			else: s.state.total_elapsed_seconds = 99999999
			for kind in ["refine_pill","consume_pill"]: rejected(s,kind,{"pill_id":id},id+" gate "+gate)
			s.state = original
		s.state.pills[id] = 999998
		rejected(s,"refine_pill",{"pill_id":id,"count":2},id+" inventory overflow")
		check(send(s,"refine_pill",{"pill_id":id}).ok and s.state.pills[id] == 999999,id+" max inventory")
		rejected(s,"refine_pill",{"pill_id":id},id+" full inventory")
		# All accepted discount sources must leave new costs unchanged.
		var plain := AlchemySystem.refinement_cost(s.state,id)
		s.state.skills.alchemical_breath_control = 3
		s.state.talents = {"elixir_conservation_memory":5,"alchemical_past_wisdom":1}
		var discounted := AlchemySystem.refinement_cost(s.state,id)
		for resource in plain: check(plain[resource].subtract(discounted[resource]).sign == 0,id+" no discount")
	_test_training()
	_test_timed()
	_test_capacity()
	_test_wards()
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR+"core.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P2-PILLS ",checks," checks failures=",JSON.stringify(failures))
	print("RUNNER_RESULT status=%s exit=%d" % ["PASS" if failures.is_empty() else "FAIL",0 if failures.is_empty() else 1])
	quit(0 if failures.is_empty() else 1)
func _test_training() -> void:
	var s := fresh()
	s.state.pills = {"nascent_breath_pill":99,"void_meditation_pill":99}
	var elapsed := s.state.total_elapsed_seconds
	check(send(s,"consume_pill",{"pill_id":"nascent_breath_pill"}).ok and is_equal_approx(s.state.training_seconds,900),"training first 900")
	var preview := AlchemySystem.p2_preview(s.state,"void_meditation_pill")
	check(send(s,"consume_pill",{"pill_id":"void_meditation_pill"}).ok and is_equal_approx(s.state.training_seconds,900+minf(1530, float(preview.training_gain))),"training shared decay")
	check(s.state.total_elapsed_seconds == elapsed and AlchemySystem.stack_count(s.state,"p2_training") == 2,"training no time")
	s.state.training_seconds = 0
	s.state.pill_effects.stacks.p2_training = 98
	check(send(s,"consume_pill",{"pill_id":"nascent_breath_pill"}).ok and AlchemySystem.stack_count(s.state,"p2_training") == 99,"k98 accepted")
	rejected(s,"consume_pill",{"pill_id":"void_meditation_pill"},"k99 refuses other ID")
	s.state.pill_effects.erase("stacks")
	s.state.training_seconds = 0
	s.state.pills.void_meditation_pill = 99
	check(send(s,"consume_pill",{"pill_id":"void_meditation_pill","count":99}).ok,"batch99 training")
	check(is_equal_approx(s.state.training_seconds,AlchemySystem.p2_preview(s.state,"void_meditation_pill").training_gain+s.state.training_seconds),"current level capped")
	rejected(s,"consume_pill",{"pill_id":"nascent_breath_pill"},"complete rejects")
	s.state.level = 10
	s.state.training_seconds = 0
	s.state.pill_effects.erase("stacks")
	rejected(s,"consume_pill",{"pill_id":"nascent_breath_pill"},"max level no need")
func _test_timed() -> void:
	for id in AlchemySystem.P2_TIMED:
		var s := fresh()
		s.state.pills[id] = 99
		var island := "ancient" if id == "ancient_herb_dew_pill" else "void"
		var resource := "spirit_grass_1000y" if island == "ancient" else "void_essence"
		var base := IslandEconomy.rate(s.state,island,resource)
		check(send(s,"consume_pill",{"pill_id":id}).ok,"timed first")
		rejected(s,"consume_pill",{"pill_id":id},"no net extension")
		check(is_equal_approx(IslandEconomy.rate(s.state,island,resource),base*1.5),"local x1.5")
		BuffSystem.tick(s.state,7)
		check(AlchemySystem.p2_preview(s.state,id).net_extension_seconds == 7,"net seven preview")
		check(send(s,"consume_pill",{"pill_id":id}).ok and AlchemySystem.p1_remaining(s.state,id) == 600,"net seven refresh")
		rejected(s,"consume_pill",{"pill_id":id,"count":7},"max timed batch")
		check(send(s,"consume_pill",{"pill_id":id,"count":6}).ok and AlchemySystem.p1_remaining(s.state,id) == 3600,"batch6")
		# Empty stock and no enabled routes: known exact integral, including last buff tick.
		s.state.economy.islands[island].inventory[resource] = "0"
		BuffSystem.apply_buff(s.state,AlchemySystem.PILLS[id].effects.buff_id,600)
		s.state.buffs[AlchemySystem.PILLS[id].effects.buff_id].remaining_seconds = 600
		var a := s.state.duplicate_state()
		var b := s.state.duplicate_state()
		TimeAdvancer.advance(a,content,601)
		TimeAdvancer.advance(b,content,593)
		OfflineClosedForm.advance(b,content,8)
		check(is_equal_approx(IslandEconomy.value(a,island,resource),base*901),"600 complete boosted seconds "+id)
		check(a.to_snapshot_dict() == b.to_snapshot_dict(),"split/closedform exact "+id)
		check(not a.buffs.has(AlchemySystem.PILLS[id].effects.buff_id),"expired")
		s.state.economy.islands[island].inventory[resource] = "300"
		TimeAdvancer.advance(s.state,content,5)
		check(IslandEconomy.value(s.state,island,resource) == 300,"full local warehouse")
		# Existing dispatch, study and reincarnation multipliers multiply once.
		s.state.buildings[IslandEconomy.supply_data().dispatch[island]] = 1
		s.state.skills["ancient_herb_attunement" if island == "ancient" else "void_essence_attunement"] = 2
		s.state.talents.frontier_prospector_memory = 3
		check(is_equal_approx(IslandEconomy.rate(s.state,island,resource),base*2*pow(1.1,2)*1.3*1.5),"dispatch/study/talent/pill multiply once")
		BuffSystem.remove_buff(s.state,AlchemySystem.PILLS[id].effects.buff_id)
		check(is_equal_approx(IslandEconomy.rate(s.state,island,resource),base*2*pow(1.1,2)*1.3),"expiry preserves other rate sources")
func _test_capacity() -> void:
	for id in AlchemySystem.P2_CAPACITY:
		var s := fresh()
		var resource: String = AlchemySystem.P2_CAPACITY[id].resource
		var base_caps := Production.compute_caps(content,s.state.buildings,6,1,s.state.skills)
		var base: float = LifeHistory.observed_caps(s.state,content)[resource].to_float()
		var stock: float = s.state.resources[resource].value.to_float()
		s.state.pills[id] = 6
		check(send(s,"consume_pill",{"pill_id":id,"count":5}).ok,"capacity batch5")
		var expected: float = base+float(AlchemySystem.P2_CAPACITY[id].flat)*5
		check(s.state.resources[resource].value.to_float() == stock,"no free stock")
		check(is_equal_approx(Production.pill_caps(s.state,base_caps)[resource].to_float(),expected),"authority flat last")
		check(is_equal_approx(AmountCompat.try_parse(s.get_view().resources[resource].cap).value.to_float(),expected),"view capacity")
		check(is_equal_approx(LifeHistory.observed_caps(s.state,content)[resource].to_float(),expected),"history capacity")
		if content.processing_catalog.resources.has(resource): check(is_equal_approx(IslandEconomy.home_cap(s.state,resource,content.processing_catalog),expected),"processing capacity")
		rejected(s,"consume_pill",{"pill_id":id},"sixth capacity atomic")
		s.state.era_id = 3
		check(AlchemySystem.capacity_bonus(s.state,resource) == float(AlchemySystem.P2_CAPACITY[id].flat)*5,"demotion keeps capacity")
		s.state.era_id = 4
		s.state.total_elapsed_seconds = 9999999
		check(send(s,"reincarnate",{"mode":"normal"}).ok and s.state.pills.is_empty() and s.state.pill_effects.is_empty(),"rebirth clears")
		# A permanent beast capacity multiplier and skill must never multiply the flat.
		s = fresh()
		s.state.beast_talents.serpent_t4_passive = 1
		s.state.skills.nascent_soul_incubation = 2
		base = LifeHistory.observed_caps(s.state,content)[resource].to_float()
		s.state.pills[id] = 2
		check(send(s,"consume_pill",{"pill_id":id}).ok,"capacity with existing multipliers")
		expected = floor(base)+float(AlchemySystem.P2_CAPACITY[id].flat)
		var caps := Production.compute_caps(content,s.state.buildings,6,1,s.state.skills)
		check(is_equal_approx(Production.pill_caps(s.state,caps)[resource].to_float(),expected),"flat after all multipliers")
		check(is_equal_approx(LifeHistory.observed_caps(s.state,content)[resource].to_float(),expected),"history agrees with boosted cap")
		if resource == "stone_mid":
			# Paid output reservations survive capacity use; the same cap frees room.
			for facility in content.processing_catalog.recipes.stone_mid_bulk.facility:
				s.state.buildings[facility] = content.processing_catalog.recipes.stone_mid_bulk.facility[facility]
			s.state.resources[resource].value = AmountCompat.from_number(expected-100)
			check(send(s,"craft",{"recipe_id":"stone_mid_bulk"}).ok,"reserve paid bulk output")
			var reserved := IslandEconomy.reserved(s.state,"home",resource,content.processing_catalog)
			check(reserved == 100,"reservation held")
			check(send(s,"consume_pill",{"pill_id":id}).ok and IslandEconomy.reserved(s.state,"home",resource,content.processing_catalog) == reserved,"capacity preserves paid reservation")
			TimeAdvancer.advance(s.state,content,10)
			check(IslandEconomy.reserved(s.state,"home",resource,content.processing_catalog) == 0 and is_equal_approx(s.state.resources[resource].value.to_float(),expected),"paid bulk completes within enlarged cap")
func _test_wards() -> void:
	for era in [4,5]:
		var s := fresh(era)
		s.state.pills = {"calm_tribulation_pill":3,"silver_ward_pill":3}
		var base := TribulationRules.state_probability(s.state)
		check(send(s,"consume_pill",{"pill_id":"calm_tribulation_pill"}).ok and is_equal_approx(TribulationRules.state_probability(s.state),base+0.03),"ward +3")
		rejected(s,"consume_pill",{"pill_id":"calm_tribulation_pill"},"ward duplicate")
		if era == 5: check(send(s,"consume_pill",{"pill_id":"silver_ward_pill"}).ok and is_equal_approx(TribulationRules.state_probability(s.state),0.68),"ward +5")
		else: rejected(s,"consume_pill",{"pill_id":"silver_ward_pill"},"silver era4")
		var roll_index := s.state.tribulation_roll_index
		rejected(s,"breakthrough_era",{},"rejected breakthrough preserves wards")
		check(s.state.tribulation_roll_index == roll_index and AlchemySystem.stack_count(s.state,"calm_tribulation_pill") == 1,"no reroll on rejection")
		# A synthetic sufficient capacity fixture exercises both actual roll outcomes.
		for success in [false,true]:
			var test := fresh(era)
			test.state.level = 10
			test.state.pill_effects = {"stacks":{"calm_tribulation_pill":1,"p2_training":12},"p2_capacity_counts":{"spirit_vessel_pill":2}}
			for building in content.building_ids:
				if int(content.buildings[building].era) <= era: test.state.buildings[building] = int(content.buildings[building].max_level)
			while TribulationRules.is_success(TribulationRules.roll(test.state.tribulation_seed,0),TribulationRules.state_probability(test.state)) != success: test.state.tribulation_seed += 1
			var probability := TribulationRules.state_probability(test.state)
			var result := send(test,"breakthrough_era")
			check(result.ok and test.state.tribulation_roll_index == 1 and not test.state.pill_effects.has("stacks"),"actual roll clears stacks "+str(success)+JSON.stringify(result.get("error")))
			check(test.state.pill_effects.p2_capacity_counts.spirit_vessel_pill == 2,"actual roll keeps capacity")
			if result.ok: check(is_equal_approx(result.events[0].get("probability",probability),probability),"receipt probability")
	var s := fresh(4)
	s.state.pills.calm_tribulation_pill = 1
	s.state.pill_effects.stacks = {"tribulation_pill":99}
	rejected(s,"consume_pill",{"pill_id":"calm_tribulation_pill"},"95 percent no benefit")
	s = fresh(6)
	s.state.pills = {"calm_tribulation_pill":1,"silver_ward_pill":1}
	for id in AlchemySystem.P2_WARDS: rejected(s,"consume_pill",{"pill_id":id},"era6 no next ward")
