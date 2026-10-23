extends SceneTree
const META := {"save_id":"content-p1-sect-isolated","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0","rng_streams":{}}
const DIR := "res://docs/verification/artifacts/content-p1-sect/"
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	func read(key: String) -> Dictionary: return {"ok":true,"data":data[key]} if data.has(key) else {"ok":false,"error":"missing"}
	func exists(key: String) -> bool: return data.has(key)
	func erase(key: String) -> Dictionary: data.erase(key); return {"ok":true}
	func write(key: String, value: String) -> Dictionary:
		if fail == "*" or fail == key: return {"ok":false,"error":"TEST_DENIED"}
		data[key] = value
		return {"ok":true}
var checks := 0
var failures := []
var seq := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)
func send(s: GameSession, type: String, payload: Dictionary = {}) -> Dictionary:
	seq += 1
	return s.submit({"type":type,"command_id":"q-"+str(seq),"expected_revision":s.state.revision,"payload":payload})
func funded(c: GameContent) -> GameSession:
	var s := GameSession.create_new_game(c,123)
	s.state.era_id = 3
	s.state.buildings = {"hut":2,"wooden_house":2,"forest_farm":3,"stone_mine":3,"herb_farm":3}
	for id in s.state.resources: s.state.resources[id].value = AmountCompat.from_number(100000)
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	s.state.sect.contribution = "10000"
	return s
func frozen(id: String, instance: String = "q-fixture") -> Dictionary:
	var t: Dictionary = SectSystem.P1_TASKS[id]
	var cfg: Dictionary = SectSystem.RARITY_CONFIGS[t.rarity]
	var reward: Dictionary = t.rewards.duplicate(true)
	reward.contribution = cfg.contrib_min
	reward.money = int(50 * float(cfg.reward_mult) * 3)
	return {"id":instance,"template_id":id,"generation_era":3,"name":t.name,"desc":t.desc,"rarity":t.rarity,"rarity_name":cfg.name,"rarity_color":cfg.color,"duration":cfg.duration,"elapsed":0,"rewards":reward}
func _init() -> void: run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var c: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(c).ok,"attach")
	check(SectSystem.TECHNIQUES.size() == 6 and SectSystem.MARKET_ITEMS.size() == 6,"6 techniques 6 goods")
	var contribution_costs := [[60,90,135,203,304],[90,135,203,304,456]]
	var material_costs := [[5,8,12,17,26],[100,150,225,338,507]]
	for index in 2:
		var id: String = SectSystem.P1_TECHNIQUES[index]
		var s := funded(c)
		for level in 5:
			var contribution := float(s.state.sect.contribution)
			var resource := "stone_low" if index == 0 else "wood"
			var before: float = s.state.resources[resource].value.to_float()
			check(send(s,"learn_sect_technique",{"technique_id":id}).ok,id+" learns "+str(level))
			check(contribution - float(s.state.sect.contribution) == contribution_costs[index][level],id+" contribution "+str(level))
			check(before - s.state.resources[resource].value.to_float() == material_costs[index][level],id+" material "+str(level))
		for reason in ["max","era","membership","contribution","material","unknown"]:
			s = funded(c)
			if reason == "max": s.state.sect.techniques[id] = 5
			if reason == "era": s.state.era_id = int(SectSystem.TECHNIQUES[id].min_era)-1
			if reason == "membership": s.state.sect.unlocked = false
			if reason == "contribution": s.state.sect.contribution = "0"
			if reason == "material": s.state.resources["stone_low" if index == 0 else "wood"].value = AmountCompat.zero()
			var before := s.state.to_snapshot_dict()
			check(not send(s,"learn_sect_technique",{"technique_id":"unknown" if reason == "unknown" else id}).ok and before == s.state.to_snapshot_dict(),id+" atomic "+reason)
	# All twelve recipes, both gates, six ranks, four skill ranks and batch endpoints.
	for id in AlchemySystem.PILLS:
		for level in 6:
			for skill in 4:
				var s := funded(c)
				s.state.sect.techniques.alchemy_herb_conservation = level
				s.state.skills.alchemical_breath_control = skill
				for count in [1,3,99]:
					var costs := AlchemySystem.refinement_cost(s.state,id,count)
					for res in AlchemySystem.PILLS[id].cost:
						var expected: float = float(AlchemySystem.PILLS[id].cost[res]) * count
						if res == "spirit_grass_low" and id in SectSystem.HERB_DISCOUNT_PILLS: expected *= (100.0-2*level)/100
						if res == "lingli" and id in AlchemySystem.LINGLI_DISCOUNT_PILLS: expected *= 1-0.05*skill
						check(is_equal_approx(float(costs[res]) if costs[res] is int else costs[res].to_float(),expected),"recipe "+id+res+str([level,skill,count]))
	var s := funded(c)
	s.state.sect.techniques.alchemy_herb_conservation = 5
	s.state.skills.alchemical_breath_control = 3
	var grass: float = s.state.resources.spirit_grass_low.value.to_float()
	var qi: float = s.state.resources.lingli.value.to_float()
	var result := send(s,"refine_pill",{"pill_id":"cultivation_pill","count":99})
	check(result.ok and is_equal_approx(grass-s.state.resources.spirit_grass_low.value.to_float(),891) and is_equal_approx(qi-s.state.resources.lingli.value.to_float(),4207.5),"99 actual paid")
	check(result.events[0].paid_cost.spirit_grass_low == "891","paid receipt same")
	for soul in [false,true]:
		for level in 6:
			s = funded(c)
			s.state.sect.techniques.fox_feed_conservation = level
			if soul: s.state.beast_talents.fox_t3_cheap = 1
			var expected: int = [30,29,28,28,27,27][level] if soul else 50-level
			check(BeastSystem.feed_costs(s.state,"jade_fox").spirit_grass_low == expected,"fox cost "+str([soul,level]))
			for talent in 6:
				var fed := funded(c)
				fed.state.sect.techniques.fox_feed_conservation = level
				fed.state.talents.beast_bond_past_wisdom = talent
				fed.state.beasts = {"active":{"id":"jade_fox","stage":"egg","exp":0},"cooldown_remaining":0.0}
				if soul: fed.state.beast_talents = {"fox_t3_cheap":1,"fox_t2_speed":1}
				var before_feed: float = fed.state.resources.spirit_grass_low.value.to_float()
				var feed_result := send(fed,"feed_beast")
				check(feed_result.ok and before_feed-fed.state.resources.spirit_grass_low.value.to_float() == expected,"feed paid "+str([soul,level,talent]))
				check(fed.state.beasts.active.exp == (65 if soul else 50) + 10*talent and fed.state.beasts.cooldown_remaining == 300,"XP/cooldown unchanged "+str([soul,level,talent]))
				var snapshot := fed.state.to_snapshot_dict()
				check(not send(fed,"feed_beast").ok and snapshot == fed.state.to_snapshot_dict(),"cooldown atomic")
			for beast in BeastSystem.BEAST_CONFIGS:
				if beast == "jade_fox": continue
				var without := s.state.duplicate_state()
				without.sect.techniques.clear()
				check(BeastSystem.feed_costs(s.state,beast) == BeastSystem.feed_costs(without,beast),"other beast "+beast)
	for era in [1,2,3]:
		for joined in [false,true]:
			s = funded(c); s.state.era_id = era; s.state.sect.unlocked = joined
			s.state.sect.techniques = {"alchemy_herb_conservation":5,"fox_feed_conservation":5}
			check(SectSystem.active_level(s.state,"alchemy_herb_conservation") == (5 if joined and era>=2 else 0),"alchemy gate")
			check(SectSystem.active_level(s.state,"fox_feed_conservation") == (5 if joined and era>=3 else 0),"fox gate")
	# Eligibility is per rarity, not an alternative rarity roll. Freeze every profile.
	for era in [1,2,3]:
		for mask in 8:
			for beast in [false,true]:
				s = funded(c); s.state.era_id = era
				s.state.economy = {"islands":{}}
				for i in 3: s.state.economy.islands[["wood","ore","herb"][i]] = {"opened":bool(mask & (1 << i))}
				if beast: s.state.beasts.active = {"id":"jade_fox"}
				for id in SectSystem.P1_TASKS:
					var t: Dictionary = SectSystem.P1_TASKS[id]
					var expected: bool = era >= int(t.min_era) and (beast or t.requires_active_beast == "")
					for island in t.requires_open_islands: expected = expected and s.state.economy.islands[island].opened
					check(SectSystem.eligible_templates(s.state,t.rarity).size() == (4 if expected else 3),"eligibility "+id+str([era,mask,beast]))
	for id in SectSystem.P1_TASKS:
		s = funded(c)
		var task := frozen(id)
		s.state.sect.available_tasks = [task]
		check(SectSaveContract.validate(1,s.state.sect).is_empty(),"valid profile "+id)
		check(send(s,"start_sect_expedition",{"task_id":task.id}).ok,"start "+id)
		var before := s.state.to_snapshot_dict()
		check(not send(s,"claim_sect_expedition").ok and before == s.state.to_snapshot_dict(),"unfinished "+id)
		s.state.beasts.clear(); s.state.economy.clear()
		SectSystem.tick(s.state,float(task.duration))
		var money: float = s.state.resources.money.value.to_float()
		check(send(s,"claim_sect_expedition").ok and s.state.sect.active_expedition == null,"claim frozen "+id)
		check(s.state.resources.money.value.to_float() - money == task.rewards.money,"money once "+id)
		for resource in SectSystem.P1_TASKS[id].rewards:
			check(s.state.resources[resource].value.to_float() == 100000+SectSystem.P1_TASKS[id].rewards[resource],"resource profile "+id+resource)
		before = s.state.to_snapshot_dict()
		check(not send(s,"claim_sect_expedition").ok and before == s.state.to_snapshot_dict(),"no double claim "+id)
	# Exercise actual random generation, all five newly registered IDs, frozen roundtrip.
	s = funded(c)
	s.state.economy = {"islands":{"wood":{"opened":true},"ore":{"opened":true},"herb":{"opened":true}}}
	s.state.beasts.active = {"id":"jade_fox"}
	seed(1729)
	var seen := {}
	for i in 4000:
		var task := SectSystem._generate_random_task(3,1,s.state.sect,s.state)
		check(SectSaveContract.validate_task(JSON.parse_string(JSON.stringify(task)),1).is_empty(),"generated payload "+str(i))
		if task.has("template_id"): seen[task.template_id] = true
	check(seen.size() == 5,"all five real RNG profiles")
	s.state.sect.task_counter = 2147483646
	var exhausted := s.state.to_snapshot_dict()
	check(not send(s,"refresh_sect_tasks",{"force":true}).ok and exhausted == s.state.to_snapshot_dict(),"counter exhaustion atomic")
	# Existing snapshots without template ID remain payable as stored.
	s = funded(c)
	s.state.sect.active_expedition = {"id":"old-instance","name":"舊委託","duration":60,"elapsed":60,"rewards":{"contribution":15,"money":100,"herb":20}}
	check(send(s,"claim_sect_expedition").ok and s.state.resources.spirit_grass_low.value.to_float() == 100020,"legacy instance keeps payload")
	for id in ["greenwood_bundle","herb_nurture_supply"]:
		s = funded(c); s.state.resources.wood.value = AmountCompat.zero()
		for i in 10:
			s.state.resources.wood.value = AmountCompat.zero()
			check(send(s,"buy_sect_market_item",{"item_id":id}).ok,"buy "+id+str(i))
		check(s.state.sect.market_purchases[id] == 10,"lifetime count")
		var before := s.state.to_snapshot_dict()
		check(not send(s,"buy_sect_market_item",{"item_id":id}).ok and before == s.state.to_snapshot_dict(),"11th atomic")
		check(s.state.buffs.is_empty(),"purchase never consumes")
		for reason in ["era","member","contribution","full"]:
			s = funded(c); s.state.resources.wood.value = AmountCompat.zero()
			if reason == "era": s.state.era_id = 1
			if reason == "member": s.state.sect.unlocked = false
			if reason == "contribution": s.state.sect.contribution = "0"
			if reason == "full":
				if id == "greenwood_bundle": s.state.resources.wood.value = AmountCompat.from_number(999999)
				else: s.state.pills.herb_nurture_pill = 999999
			before = s.state.to_snapshot_dict()
			check(not send(s,"buy_sect_market_item",{"item_id":id}).ok and before == s.state.to_snapshot_dict(),"market atomic "+id+reason)
	# Reincarnation keeps permanent ranks/contribution/lifetime purchases, disables effects.
	s = funded(c); s.state.sect.techniques = {"alchemy_herb_conservation":5,"fox_feed_conservation":5}; s.state.sect.market_purchases.greenwood_bundle = 7
	var permanent := s.state.sect.duplicate(true)
	s.state.total_elapsed_seconds = 999999
	check(send(s,"reincarnate",{"mode":"normal"}).ok,"real reincarnation")
	for key in ["techniques","contribution","market_purchases"]: check(s.state.sect[key] == permanent[key],"permanent "+key)
	check(SectSystem.active_level(s.state,"alchemy_herb_conservation") == 0,"rebirth inactive")
	check(send(s,"join_sect").ok and SectSystem.active_level(s.state,"alchemy_herb_conservation") == 0,"rejoin era1 inactive")
	# Reject forged, malformed and future subversions at both encode and decode.
	s = funded(c)
	var encoded := SaveCodec.encode(s.state,c.content_version,META)
	if not encoded.ok:
		print("ENCODE FAILED: ", encoded, " checks=", checks, " failures=", failures)
		quit(1)
		return
	var env: Dictionary = JSON.parse_string(encoded.json)
	for malformed in ["negative_contribution","unknown_technique","counter","oversize","duplicate","bad_time","v0_new_id"]:
		var candidate := env.duplicate(true)
		match malformed:
			"negative_contribution": candidate.state.sect.contribution = "-1"
			"unknown_technique": candidate.state.sect.techniques.unknown = 1
			"counter": candidate.state.sect.task_counter = 2147483648
			"oversize": candidate.state.sect.extra = "x".repeat(32769)
			"duplicate": candidate.state.sect.available_tasks = [frozen("home_supply_register"),frozen("home_supply_register")]
			"bad_time":
				candidate.state.sect.active_expedition = frozen("home_supply_register")
				candidate.state.sect.active_expedition.elapsed = 61
			"v0_new_id":
				candidate.state.erase("sect_version")
				candidate.state.sect.techniques.alchemy_herb_conservation = 1
		var invalid_raw := rehash(candidate)
		check(not SaveCodec.decode(invalid_raw).ok,"malformed rejected "+malformed)
		var invalid_store := Memory.new(); invalid_store.data[SaveSlots.SLOT_MAIN] = invalid_raw
		SaveManager.configure(c,invalid_store)
		check(SaveManager.current_state() == null and SaveManager.load_error().begins_with("SECT_") and invalid_store.data[SaveSlots.SLOT_MAIN] == invalid_raw,"malformed original retained with reason "+malformed)
		SaveManager.reset_for_tests()
	for bad in [true,-1,2,1.5,"1"]:
		var candidate := env.duplicate(true); candidate.state.sect_version = bad
		check(not decode(candidate).ok,"version reject "+str(bad))
	for field in ["techniques","market_purchases"]:
		for bad in [true,-1,6 if field=="techniques" else 11,1.5,"2"]:
			var candidate := env.duplicate(true)
			candidate.state.sect[field]["alchemy_herb_conservation" if field=="techniques" else "greenwood_bundle"] = bad
			check(not decode(candidate).ok,"bound reject "+field+str(bad))
	for id in SectSystem.P1_TASKS:
		var candidate := env.duplicate(true); candidate.state.sect.available_tasks = [frozen(id)]
		var decoded_profile := decode(candidate)
		check(decoded_profile.ok,"decode profile "+id+str(decoded_profile.get("error", "")))
		candidate.state.sect.available_tasks[0].rewards.wood = 12345
		check(not decode(candidate).ok,"forged reward "+id)
	var old := env.duplicate(true); old.state.erase("sect_version")
	var original := rehash(old)
	var mem := Memory.new(); mem.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(c,mem)
	var migrated := SaveManager.current_state()
	check(migrated != null and migrated.sect_version == 1,"v0 migrate")
	var archive := "save_before_sect_"+original.sha256_text()
	mem.fail = archive
	check(not SaveManager.save(migrated,META).ok and mem.data[SaveSlots.SLOT_MAIN] == original,"archive denial retains original")
	mem.fail = ""
	check(SaveManager.save(migrated,META).ok and mem.data[archive] == original,"exact original readback")
	mem = Memory.new()
	SaveManager.configure(c,mem)
	s = funded(c); s.state.resources.wood.value = AmountCompat.zero()
	check(send(s,"buy_sect_market_item",{"item_id":"greenwood_bundle"}).ok,"paid before denial")
	mem.fail = "*"; check(not SaveManager.save(s.state,META).ok,"slot denial")
	mem.fail = ""; check(SaveManager.save(s.state,META).ok,"save only retry")
	SaveManager.configure(c,mem)
	var loaded := SaveManager.current_state()
	check(loaded.sect.get("market_purchases", {}).get("greenwood_bundle", 0) == 1 and loaded.resources.wood.value.to_float() == 100 and loaded.sect.contribution == "9940","reload no double pay")
	mem.data[SaveSlots.SLOT_BACKUP] = mem.data[SaveSlots.SLOT_MAIN]
	mem.data[SaveSlots.SLOT_MAIN] = "broken"; SaveManager.configure(c,mem)
	check(SaveManager.current_state() != null,"corrupt main recovery")
	SaveManager.reset_for_tests()
	# Paused, explicitly funded fixture for three-size UI and browser tests.
	s = funded(c); s.state.resources.wood.value = AmountCompat.zero()
	s.state.sect.available_tasks = [frozen("home_supply_register")]
	s.state.beasts.active = {"id":"jade_fox","stage":"egg","experience":0,"last_feed_age":-300}
	FileAccess.open("res://src/verification/content_p1_sect_fixture.json",FileAccess.WRITE).store_string(SaveCodec.encode(s.state,c.content_version,META).json)
	var profiles := {}
	for id in SectSystem.P1_TASKS: profiles[id] = frozen(id,"q-"+id)
	FileAccess.open("res://src/verification/content_p1_sect_tasks.json",FileAccess.WRITE).store_string(JSON.stringify(profiles))
	FileAccess.open(DIR+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P1-SECT ",checks," checks failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
func rehash(env: Dictionary) -> String:
	env.erase("checksum"); env.checksum = SaveCodec.compute_checksum(env)
	return JSON.stringify(env)
func decode(env: Dictionary) -> Dictionary: return SaveCodec.decode(rehash(env))
