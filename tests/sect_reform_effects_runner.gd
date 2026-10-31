extends SceneTree
const META := {"save_id":"sect-effects-isolated", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var content: GameContent
var checks := 0
var failures: Array[String] = []
class Memory extends StorageAdapter:
	var data := {}
	var fail := false
	func exists(key: String) -> bool: return data.has(key)
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key,""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if fail: return {"ok":false, "error":"injected_write"}
		data[key] = value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ", label)
func fresh(sect: String, era := 5) -> GameSession:
	var s := GameSession.create_new_game(content, 20261030)
	s.state.era_id = era
	check(s.join_sect(sect).ok, "join " + sect)
	s.state.sect.contribution = "100000"
	s.state.resources.stone_low.value = AmountCompat.from_number(10000)
	return s
func give(s: GameSession, id: String, n := 5) -> void:
	s.state.sect.techniques_version = 1
	s.state.sect.techniques[id] = n
func activate(s: GameSession) -> void:
	s.state.buildings.hut = 2
	s.state.buildings.stone_mine = 3
	s.state.buildings.herb_farm = 3
	check(IslandProgression.command(content,s.state,"activate_islands",{"hub":true}).ok,"activate formal supply")
func send(s: GameSession, id: String, receipt := "learn") -> Dictionary:
	return s.submit({"command_id":receipt, "expected_revision":s.state.revision, "type":"learn_sect_technique", "payload":{"technique_id":id}})
func same(a: GameState, b: GameState) -> bool:
	return JSON.stringify(a.to_snapshot_dict()) == JSON.stringify(b.to_snapshot_dict())
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "supply attach")
	for id in SectSpecialization.METHODS:
		var def: Array = SectSpecialization.METHODS[id]
		var s := fresh(def[0])
		var is_a: bool = def[1] == "A"
		if not is_a:
			check(not SectSystem.learn_technique(s.state,id).ok, "B requires A " + id)
			for a in SectSpecialization.METHODS:
				if SectSpecialization.METHODS[a][0] == def[0] and SectSpecialization.METHODS[a][1] == "A": give(s,a)
		for n in range(5):
			var before_contribution: float = AmountCompat.try_parse(s.state.sect.contribution).value.to_float()
			var before_stone := (s.state.resources.stone_low.value as AmountCompat).to_float()
			check(SectSystem.learn_technique(s.state,id).ok, "learn " + id + str(n))
			check(is_equal_approx(before_contribution - AmountCompat.try_parse(s.state.sect.contribution).value.to_float(), (SectSpecialization.A_CONTRIBUTION if is_a else SectSpecialization.B_CONTRIBUTION)[n]), "exact contribution")
			check(is_equal_approx(before_stone - (s.state.resources.stone_low.value as AmountCompat).to_float(), (SectSpecialization.A_STONE if is_a else SectSpecialization.B_STONE)[n]), "exact stones")
		var frozen := s.state.duplicate_state()
		check(not SectSystem.learn_technique(s.state,id).ok and same(s.state,frozen), "max no charge")
		for era in range(1,7):
			s.state.era_id = era
			check(SectSpecialization.level(s.state,id) == (0 if era < (2 if is_a else 3) else (3 if era < (4 if is_a else 5) else 5)), "active era gate " + id + str(era))
		SectSystem.on_reincarnate(s.state)
		check(SectSpecialization.level(s.state,id) == 0 and s.state.sect.techniques[id] == 5, "permanent dormant")
		s.state.reincarnation_count = 1
		SectLineage.next_life(s.state) # Keep the synthetic next-life fixture coherent.
		check(s.join_sect("wanfo_sect" if def[0] != "wanfo_sect" else "taixu_sect").ok, "other life join")
		check(SectSpecialization.level(s.state,id) == 0, "other sect dormant")
		var gated := fresh(def[0],2)
		give(gated,id,3)
		check(SectSystem.technique_requirements(gated.state,id).get("error") == "TECHNIQUE_ERA_LOCKED","fourth rank era gate")
		gated.state.era_id = 4 if is_a else 5
		if not is_a:
			for a in SectSpecialization.METHODS:
				if SectSpecialization.METHODS[a][0] == def[0] and SectSpecialization.METHODS[a][1] == "A": give(gated,a,3)
			check(SectSystem.technique_requirements(gated.state,id).get("error") == "TECHNIQUE_PREREQUISITE","B fourth needs A5")
			for a in SectSpecialization.METHODS:
				if SectSpecialization.METHODS[a][0] == def[0] and SectSpecialization.METHODS[a][1] == "A": give(gated,a)
		check(SectSystem.technique_requirements(gated.state,id).ok,"fourth rank gates satisfied")
	var s := fresh("wanfo_sect")
	var base := Lifespan.for_state(content.era_lifespan_entries(),s.state)
	s.state.talents.lifespan_extension = 1
	s.state.pill_effects.lifespan_bonus_years = 7
	give(s,"wanfo_life_lamp")
	give(s,"wanfo_enduring_body")
	var maximum := Lifespan.for_state(content.era_lifespan_entries(),s.state)
	check(maximum == floor(base / 60.0 * 1.2 + 17) * 60, "flat and ratio shared formula")
	check(s.get_view().max_lifespan_seconds == maximum, "Session lifespan agrees")
	s.state.total_elapsed_seconds = maximum
	s.state.sect.techniques.wanfo_life_lamp = 4
	var before := s.state.duplicate_state()
	check(not SectSystem.learn_technique(s.state,"wanfo_life_lamp").ok and same(s.state,before), "no exhausted self rescue")
	check(ReincarnationRules.check_eligibility(s.state,content).can_reincarnate, "rebirth exhaustion agrees")
	check(TimeAdvancer.advance(s.state,content,1).ticks_advanced == 0, "tick exhaustion agrees")
	check(SectSystem.p2_life_error(s.state) == "LIFESPAN_EXHAUSTED", "sect exhaustion agrees")
	s = fresh("taixu_sect")
	give(s,"taixu_inner_cycle")
	give(s,"taixu_qi_spring")
	s.state.sect.techniques.breathing_method = 5
	var normal := s.state.duplicate_state()
	normal.sect.techniques.erase("taixu_qi_spring")
	TimeAdvancer.advance(s.state,content,1)
	TimeAdvancer.advance(normal,content,1)
	check(is_equal_approx(s.state.training_seconds,1.2), "additive cultivation")
	check(is_equal_approx((s.state.resources.lingli.value as AmountCompat).to_float(),(normal.resources.lingli.value as AmountCompat).to_float()*1.15), "natural lingli only")
	var prepared := TimeAdvancer.prepare_advance(s.state,content)
	activate(s)
	prepared = TimeAdvancer.prepare_advance(s.state,content)
	TimeAdvancer.advance(s.state,content,1,prepared)
	s.state.sect.unlocked = false
	var training := s.state.training_seconds
	TimeAdvancer.advance(s.state,content,1,prepared)
	check(is_equal_approx(s.state.training_seconds-training,1.1), "prepared invalidates sect change")
	for sect in SectIdentity.NAMES:
		s = fresh(sect)
		activate(s)
		for id in SectSpecialization.METHODS:
			if SectSpecialization.METHODS[id][0] == sect: give(s,id)
		BuffSystem.apply_buff(s.state,"epiphany",5)
		var online := s.state.duplicate_state()
		var offline := s.state.duplicate_state()
		for _i in range(20): TimeAdvancer.advance(online,content,1)
		OfflineClosedForm.advance(offline,content,20)
		check(same(online,offline), "offline exact " + sect)
		# A player may buy methods before activating the multi-island economy.
		s.state.economy = {}
		online = s.state.duplicate_state()
		offline = s.state.duplicate_state()
		for _i in range(20): TimeAdvancer.advance(online,content,1)
		OfflineClosedForm.advance(offline,content,20)
		check(same(online,offline), "pre-island offline exact " + sect)
	s = fresh("piaomiao_sect")
	give(s,"piaomiao_pill_measure")
	s.state.sect.techniques.alchemy_herb_conservation = 5
	for pill in ["cultivation_pill","wood_nurture_pill","wealth_gathering_pill","qi_absorption_pill","lifespan_pill","tribulation_pill"]:
		var resource := "spirit_grass_100y" if pill == "tribulation_pill" else "spirit_grass_low"
		var discounted: AmountCompat = AlchemySystem.refinement_cost(s.state,pill,7)[resource]
		s.state.sect.techniques.piaomiao_pill_measure = 0
		var original: AmountCompat = AlchemySystem.refinement_cost(s.state,pill,7)[resource]
		check(discounted.compare_to(original.multiply(AmountCompat.from_number(90)).divide(AmountCompat.from_number(100))) == 0, "Amount batch discount " + pill)
		s.state.sect.techniques.piaomiao_pill_measure = 5
	check(SectSpecialization.pill_discount_level(s.state,"foundation_pill","spirit_grass_low") == 0, "no processing discount")
	for sect in ["tianjian_sect","piaomiao_sect"]:
		s = fresh(sect)
		activate(s)
		give(s,"tianjian_ore_vein")
		give(s,"piaomiao_herb_garden")
		for island in SectSpecialization.GATHER:
			for resource in SectSpecialization.GATHER[island]:
				var expected := 0.2 if (island in ["ore","deep"]) == (sect == "tianjian_sect") else 0.0
				check(is_equal_approx(SectSpecialization.gather_bonus(s.state,island,resource),expected),"gather allowlist")
				s.state.economy.islands[island].opened = true
				var boosted := IslandEconomy.rate(s.state,island,resource)
				s.state.sect.unlocked = false
				var raw := IslandEconomy.rate(s.state,island,resource)
				s.state.sect.unlocked = true
				check(is_equal_approx(boosted,raw*(1.0+expected)),"actual local rate")
		check(SectSpecialization.gather_bonus(s.state,"home","stone_low") == 0 and SectSpecialization.gather_bonus(s.state,"wood","wood") == 0,"no home or wood gather")
	s = fresh("zixiao_sect")
	activate(s)
	give(s,"zixiao_spirit_vessel")
	give(s,"zixiao_material_vault")
	s.state.sect.techniques.storage_talisman = 2
	for resource in ["lingli"] + SectSpecialization.MATERIALS:
		var caps := Production.pill_caps(s.state,Production.compute_caps(content,s.state.buildings,5,s.state.onboarding_version,s.state.skills))
		check((caps[resource] as AmountCompat).compare_to(StoryProgress.cap(s.state,content,resource)) == 0,"capacity authorities " + resource)
		if content.processing_catalog.resources.has(resource): check(is_equal_approx(caps[resource].to_float(),IslandEconomy.home_cap(s.state,resource,content.processing_catalog)),"home cap agrees " + resource)
	check(SectSpecialization.capacity_bonus(s.state,"money") == 0 and SectSpecialization.capacity_bonus(s.state,"lingqi") == 0,"capacity excludes")
	s.state.resources.lingli.value = AmountCompat.from_number(100000)
	s.state.sect.unlocked = false
	TimeAdvancer.advance(s.state,content,1)
	check((s.state.resources.lingli.value as AmountCompat).to_float() == 100000,"contraction retains stock")
	s = fresh("tianjian_sect")
	give(s,"tianjian_forge_rhythm")
	for n in range(6):
		s.state.sect.techniques.tianjian_forge_rhythm = n
		check(SectSpecialization.duration(s.state,"bronze_essence",10) == [10,10,10,10,9,9][n],"10 second rounding")
		check(SectSpecialization.duration(s.state,"formation_core",20) == [20,20,19,19,18,18][n],"20 second rounding")
	check(SectSpecialization.duration(s.state,"liquid",10) == 10,"forge excludes")
	activate(s)
	for resource in ["wood","stone_low","black_copper","bronze_essence"]:
		IslandEconomy._put(s.state,"home",resource,100 if resource != "bronze_essence" else 0)
		s.state.resources[resource].unlocked = true
	check(IslandEconomy.command(content,s.state,"open_island",{"island_id":"ore"}).ok,"open ore for forge")
	var request := {"island_id":"ore", "recipe_id":"bronze_essence", "count":2}
	var crafted := IslandEconomy.command(content,s.state,"craft",request)
	check(crafted.ok,"paid forge batch " + str(crafted.get("error","")))
	if not crafted.ok:
		RunnerResult.finish(self,1)
		return
	check(s.state.economy.jobs.ore.remaining == 9,"actual accelerated duration")
	var stock := IslandEconomy.value(s.state,"home","black_copper")
	SectSystem.on_reincarnate(s.state) # Isolate membership reset from the full inventory-reset transaction.
	var encoded := SaveCodec.encode(s.state,content.content_version,META)
	check(encoded.ok,"frozen batch encode " + str(encoded.get("error","")))
	var decoded := SaveCodec.decode(encoded.get("json",""))
	check(decoded.ok,"frozen batch decode")
	if decoded.ok:
		s.state = decoded.state
		check(s.state.economy.jobs.ore.remaining == 9 and IslandEconomy.value(s.state,"home","black_copper") == stock,"paid duration and costs frozen on reload")
		for _i in range(9): IslandEconomy.tick(s.state,content.processing_catalog)
		check(s.state.economy.jobs.ore.remaining == 10,"next batch uses current effects")
	_test_save()
	var report := FileAccess.open(RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/effects.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("SECT-REFORM-EFFECTS ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)

func _test_save() -> void:
	var s := fresh("wanfo_sect",2)
	var initial := s.state.duplicate_state()
	s.state.resources.stone_low.value = AmountCompat.zero()
	var before := s.state.duplicate_state()
	check(not SectSystem.learn_technique(s.state,"wanfo_life_lamp").ok and same(before,s.state),"insufficient cost atomic")
	s.state = initial
	# Use the existing command envelope, revision and receipt path.
	var cmd := {"command_id":"effect-save", "expected_revision":s.state.revision, "type":"learn_sect_technique", "payload":{"technique_id":"wanfo_life_lamp"}}
	check(s.submit(cmd).ok,"command learns")
	before = s.state.duplicate_state()
	check(s.submit(cmd).get("duplicate",false) and same(before,s.state),"duplicate no charge")
	var mem := Memory.new()
	SaveManager.configure(content,mem)
	mem.fail = true
	check(not SaveManager.save(s.state,META).ok and not SaveManager.save(s.state,META).ok and same(before,s.state),"save failure retains result")
	mem.fail = false
	check(SaveManager.save(s.state,META).ok,"retry same result")
	SaveManager.configure(content,mem)
	s.state = SaveManager.current_state()
	check(s.state != null,"reload effects")
	if s.state != null: check(s.state.sect.techniques.wanfo_life_lamp == 1 and s.submit(cmd).get("duplicate",false),"reload rank receipt")
	SaveManager.reset_for_tests()
	for version in [0,2,true,"1",1.5]:
		var bad := before.sect.duplicate(true)
		bad.techniques_version = version
		check(not SectSaveContract.validate(2,bad).is_empty(),"bad feature version")
	var bad := before.sect.duplicate(true)
	bad.erase("techniques_version")
	check(not SectSaveContract.validate(2,bad).is_empty(),"new IDs need version")
	bad = before.sect.duplicate(true)
	bad.techniques.wanfo_life_lamp = 6
	check(not SectSaveContract.validate(2,bad).is_empty(),"rank bound")
	check(not SectSaveContract.validate(1,before.sect).is_empty(),"feature cannot downgrade sect base version")
