extends SceneTree
## Synthetic eligibility/transaction contracts; natural representative flow is STORY-2.
var DIR := (OS.get_environment("DAO_TEST_STORAGE_ROOT") if not OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else "res://.test-output").path_join("story1/")
const META := {"save_id":"story2-isolated", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var checks := 0
var failures: Array[String] = []
var serial := 0
var content: GameContent
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ", label)
func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"story2-"+str(serial), "expected_revision":s.state.revision, "type":kind, "payload":payload})
func fresh() -> GameSession:
	var s := GameSession.create_new_game(content, 20261027)
	s.state.era_id = 6; s.state.highest_era = 6
	check(send(s,"activate_islands").ok, "activation")
	s.state.reincarnation_count = 1; StoryProgress.next_life(s.state)
	for id in s.state.economy.islands: s.state.economy.islands[id].opened = true
	for id in s.state.resources: s.state.resources[id].value = AmountCompat.zero()
	s.state.buildings = {"hut":2, "wooden_house":2, "storage_lingli":6, "storage_stone":6, "storage_wood":2, "storage_herb":2, "core_storehouse_3":1, "core_storehouse_4":1, "core_storehouse_5":1}
	SectSystem.ensure_sect_state(s.state); s.state.sect.unlocked = true; s.state.sect.current_sect = SectSystem.SECT_NAMES[0]
	for key in StoryProgressP2.MASKS:
		s.state.achievements.story.p2.lifetime[key] = StoryProgressP2.MASKS[key]
		s.state.achievements.story.p2.current[key] = StoryProgressP2.MASKS[key]
	for id in TalentSystem.P2_IDS: s.state.talents[id] = 1
	FortuneSystem.ensure_initialized(s.state)
	s.state.life_ledger = {}; LifeLedger.initialize(s.state, true)
	return s
func invite(s: GameSession, def: Dictionary) -> void:
	var active := "frost_stag" if "active_stag" in def.requires else "herb_crane" if "active_crane" in def.requires else "fire_phoenix"
	s.state.beasts = {"active":{"id":active,"stage":"egg","exp":0}, "cooldown_remaining":0}
	var pending := StorySaveContract.freeze(def, s.state)
	pending.instance_id = (def.id + str(serial)).sha256_text()
	s.state.fortune.pending_encounter = pending
func reject(s: GameSession, index: int, label: String) -> void:
	var before := s.state.to_snapshot_dict()
	var result := send(s,"resolve_fortune",{"option_index":index})
	check(not result.ok and before == s.state.to_snapshot_dict(), label + str(result.get("error", "")))
func run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	check(loaded.ok,"content load "+str(loaded.get("errors")))
	content = loaded.content
	check(IslandProgression.attach_supply(content).ok,"attach supply")
	check(AchievementSystem.DEFINITIONS.size() == 48,"48 achievements")
	check(FortuneSystem.get_encounters().size() == 56,"56 encounters")
	var count := 0
	for def in FortuneSystem.get_encounters():
		if def.get("content_batch") != "content-p2-story": continue
		count += 1
		var s := fresh(); invite(s,def)
		check(StoryProgress.eligible(s.state, def), def.id+" eligible")
		check(StorySaveContract.validate_pending(s.state.fortune.pending_encounter).is_empty(), "frozen definition")
		for key in def.requires:
			var q := StoryProgressP2.qualifications(s.state)
			check(q[key], def.id+" requires "+key)
		for fault in ["era", "realm", "version", "supply"]:
			var state := s.state.duplicate_state()
			if fault == "era": state.era_id = 3; state.highest_era = 12
			elif fault == "realm": state.current_realm = "realm_spirit"
			elif fault == "version": state.story_version = 1
			else: state.economy = {}
			check(not StoryProgress.eligible(state,def), def.id+" excludes "+fault)
		if "active_stag" in def.requires or "active_crane" in def.requires or "active_phoenix" in def.requires:
			var state := s.state.duplicate_state(); state.beasts.active.id = "jade_fox"
			check(not StoryProgress.eligible(state,def), "wrong beast excluded")
		for index in 3:
			s = fresh(); invite(s,def)
			var option: Dictionary = def.options[index]
			for id in option.costs: s.state.resources[id].value = AmountCompat.from_number(float(option.costs[id]) + 10)
			var before := s.state.duplicate_state()
			var command := {"command_id":"duplicate-"+def.id+str(index), "expected_revision":s.state.revision, "type":"resolve_fortune", "payload":{"option_index":index,"instance_id":s.state.fortune.pending_encounter.instance_id}}
			var result := s.submit(command)
			check(result.ok, def.id+" success "+str(index)+str(result.get("error")))
			if not result.ok: continue
			check(s.state.fortune.pending_encounter.is_empty(), "clears pending")
			for id in result.events[0].receipt.resources:
				var row: Dictionary = result.events[0].receipt.resources[id]
				check(DecisionReceipt._amount(row.before).subtract(DecisionReceipt._amount(row.paid)).add(DecisionReceipt._amount(row.gained)).compare_to(DecisionReceipt._amount(row.after)) == 0, "Amount receipt "+id)
			check(StoryProgressP2.facts(s.state) == StoryProgressP2.facts(before) and StoryProgressP2.facts(s.state,true) == StoryProgressP2.facts(before,true), "trades do not forge action bits")
			check(s.state.total_elapsed_seconds == before.total_elapsed_seconds and s.state.pills == before.pills and s.state.beasts == before.beasts and s.state.fortune.rng_state == before.fortune.rng_state, "no time/pill/beast/RNG side effects")
			var committed := s.state.to_snapshot_dict()
			check(s.submit(command).get("duplicate",false) and committed == s.state.to_snapshot_dict(), "same command replay")
			check(not send(s,"resolve_fortune",{"option_index":index}).ok, "no second resolution")
			var encoded := SaveCodec.encode(s.state,content.content_version,META)
			check(encoded.ok,"receipt encodes "+str(encoded.get("error")))
			if encoded.ok: check(SaveCodec.decode(encoded.json).ok,"receipt reload")
			for cost in option.costs:
				s = fresh(); invite(s,def)
				for id in option.costs: s.state.resources[id].value = AmountCompat.from_number(option.costs[id])
				s.state.resources[cost].value = AmountCompat.zero()
				reject(s,index,def.id+" shortage "+cost)
			for resource in option.rewards.get("resources", {}):
				s = fresh(); invite(s,def)
				for id in option.costs: s.state.resources[id].value = AmountCompat.from_number(option.costs[id])
				s.state.resources[resource].value = StoryProgress.cap(s.state,content,resource).subtract(AmountCompat.from_number(float(option.rewards.resources[resource])-1))
				reject(s,index,def.id+" partial capacity "+resource)
				s.state.resources[resource].value = AmountCompat.from_number(1e100)
				reject(s,index,def.id+" precision "+resource)
			if option.rewards.has("training_seconds"):
				s = fresh(); invite(s,def)
				for id in option.costs: s.state.resources[id].value = AmountCompat.from_number(option.costs[id])
				var ceiling := Cultivation.next_level_required_seconds(content.era(6),1,0.0,1.0)
				s.state.training_seconds = ceiling
				check(s.get_view().fortune.option_errors[index] == "STORY_NO_TRAINING_GAIN", "View agrees with full training rejection")
				check(s.get_view().fortune.option_errors[2].is_empty(), "full training still allows free departure")
				check(StoryProgress.reason("STORY_NO_TRAINING_GAIN") == "當級修煉已滿，請先晉階", "readable full training reason")
				reject(s,index,"zero benefit")
				s.state.training_seconds = ceiling - 1
				check(send(s,"resolve_fortune",{"option_index":index}).ok and s.state.training_seconds == ceiling,"clamped one second benefit")
			s = fresh(); invite(s,def)
			for id in option.costs: s.state.resources[id].value = AmountCompat.from_number(option.costs[id])
			s.state.total_elapsed_seconds = 1e9
			reject(s,index,"exhausted")
		# Free departure remains possible with every inventory overfull.
		s = fresh(); invite(s,def)
		for id in s.state.resources: s.state.resources[id].value = AmountCompat.from_number(1e100)
		check(send(s,"resolve_fortune",{"option_index":2}).ok,"free leave overfull")
	check(count == 18,"18 P2 definitions")
	_achievements()
	_boundaries()
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR+"core.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"synthetic contracts, not natural acquisition"},"\t"))
	print("CONTENT-P2-STORY ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
func _achievements() -> void:
	var s := fresh()
	for id in ["deep_vein_resonance","ancient_herb_attunement","spirit_sea_breath","void_essence_attunement","frontier_storekeeping"]: s.state.skills[id] = 1
	for id in SectSystem.P2_TECHNIQUES: s.state.sect.techniques[id] = 1
	AchievementSystem.check_achievements(s.state,content)
	for id in AchievementSystem.P2_DEFINITIONS:
		check(s.state.achievements.unlocked.has(id),"unlocked "+id)
		for resource in s.state.resources: s.state.resources[resource].value = AmountCompat.zero()
		var reward: Dictionary = AchievementSystem.P2_DEFINITIONS[id].rewards
		var before := DecisionReceipt._amount(s.state.sect.contribution)
		check(send(s,"claim_achievement",{"achievement_id":id}).ok,"claim "+id)
		for resource in reward.get("resource",{}): check(s.state.resources[resource].value.compare_to(AmountCompat.from_number(reward.resource[resource])) == 0,"exact reward")
		if reward.has("sect_contribution"): check(DecisionReceipt._amount(s.state.sect.contribution).subtract(before).compare_to(AmountCompat.from_number(reward.sect_contribution)) == 0,"exact contribution")
		check(not send(s,"claim_achievement",{"achievement_id":id}).ok,"one lifetime claim")
	var lifetime := StoryProgressP2.facts(s.state,true).duplicate()
	s.state.reincarnation_count += 1; StoryProgress.next_life(s.state)
	check(StoryProgressP2.facts(s.state) == StoryProgressP2.blank() and StoryProgressP2.facts(s.state,true) == lifetime and s.state.achievements.claimed.size() == 18,"life reset only current")
	s.state.era_id = 1; s.state.achievements.unlocked.clear()
	check(not StoryProgressP2.achievement_met(s.state,"p2_second_nascent") and not StoryProgressP2.achievement_met(s.state,"p2_second_void"),"highest era cannot authorize current snapshot")
	AchievementSystem.reset_achievements(s.state); StoryProgress.ensure(s.state)
	check(StoryProgressP2.facts(s.state,true) == StoryProgressP2.blank(),"debug reset clears facts")
	for id in AchievementSystem.P2_DEFINITIONS:
		s = fresh(); s.state.achievements.unlocked[id] = 0.0
		var reward: Dictionary = AchievementSystem.P2_DEFINITIONS[id].rewards
		for resource in reward.get("resource", {}): s.state.resources[resource].value = StoryProgress.cap(s.state,content,resource)
		if reward.has("sect_contribution"): s.state.sect.contribution = "1e100"
		var before := s.state.to_snapshot_dict()
		check(not send(s,"claim_achievement",{"achievement_id":id}).ok and before == s.state.to_snapshot_dict(),"claim full/precision atomic "+id)
		s.state.total_elapsed_seconds = 1e9
		check(StoryProgress.claim_error(s.state,content,id) == "LIFESPAN_EXHAUSTED","exhausted claim")

func _boundaries() -> void:
	var s := fresh()
	var limit := StoryProgress.cap(s.state,content,"refined_iron")
	check(limit.to_float() >= 3000,"high resource authoritative cap")
	s.state.resources.refined_iron.value = limit.add(AmountCompat.from_number(5))
	check(StoryProgress.transaction_error(s.state,content,{"refined_iron":10},{"resources":{"refined_iron":5}}).is_empty(),"payment frees destination capacity")
	check(not StoryProgress.transaction_error(s.state,content,{"refined_iron":9},{"resources":{"refined_iron":5}}).is_empty(),"post-payment cap+1 rejects")
	s.state.economy.trips.deep_iron_home = {"version":1,"remaining":5,"cargo":"10"}
	s.state.resources.refined_iron.value = limit.subtract(AmountCompat.from_number(10))
	check(not StoryProgress.transaction_error(s.state,content,{}, {"resources":{"refined_iron":1}}).is_empty(),"reserved cargo cannot be spent as free capacity")
	for def in FortuneSystem.get_encounters():
		if def.get("content_batch") != "content-p2-story": continue
		for index in 2:
			var option: Dictionary = def.options[index]
			for cost in option.costs:
				s = fresh(); invite(s,def)
				for id in option.costs: s.state.resources[id].value = AmountCompat.from_number(option.costs[id])
				s.state.resources[cost].value = AmountCompat.from_number(float(option.costs[cost]) - 0.000000001)
				reject(s,index,"tiny actual shortfall "+cost)
				s.state.resources[cost].value = AmountCompat.from_number(1e100)
				reject(s,index,"unrepresentable debit "+cost)
