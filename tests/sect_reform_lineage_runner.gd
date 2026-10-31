extends SceneTree
const META := {"save_id":"sect-lineage-isolated", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
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
func fresh() -> GameSession: return GameSession.create_new_game(content, 20261030)
func cmd(s: GameSession, kind: String, payload := {}, receipt := "") -> Dictionary:
	return {"command_id": receipt if not receipt.is_empty() else kind + str(s.state.revision), "expected_revision":s.state.revision, "type":kind, "payload":payload}
func same(a: GameState, b: GameState) -> bool:
	return JSON.stringify(a.to_snapshot_dict()) == JSON.stringify(b.to_snapshot_dict())
func join(s: GameSession, id: String, era := 2) -> void:
	s.state.era_id = era
	SectLineage.observe(s.state)
	var joined := s.join_sect(id)
	check(joined.ok, "join " + id + str(joined.get("error", "")))
	SectLineage.observe(s.state)
func claims(s: GameSession, count := 3) -> void:
	for i in range(count):
		if s.state.sect.available_tasks.is_empty():
			s.state.sect.next_refresh_seconds = 0
			check(s.refresh_sect_tasks().ok, "refresh")
		if s.state.sect.available_tasks.is_empty(): return
		var task: Dictionary = s.state.sect.available_tasks[0]
		check(s.start_sect_expedition(task.id).ok, "start")
		var before: int = s.state.sect.lineage.life_claimed
		check(not s.claim_sect_expedition().ok and s.state.sect.lineage.life_claimed == before, "unfinished no credit")
		SectSystem.tick(s.state, task.duration)
		check(s.state.sect.lineage.life_claimed == before, "finished but unclaimed no credit")
		var command := cmd(s, "claim_sect_expedition")
		check(s.submit(command).ok, "claim")
		check(s.state.sect.lineage.life_claimed == before + 1, "one credit")
		var after := s.state.duplicate_state()
		check(s.submit(command).get("duplicate", false) and same(after, s.state), "claim receipt duplicate")
		check(not s.claim_sect_expedition().ok and same(after,s.state), "empty cannot claim again")
func rebirth(s: GameSession, receipt := "") -> Dictionary:
	s.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),s.state)
	var command := cmd(s,"reincarnate",{},receipt)
	check(s.submit(command).ok,"eligible reincarnation")
	return command
func roundtrip(s: GameSession) -> void:
	var encoded := SaveCodec.encode(s.state,content.content_version,META)
	check(encoded.ok,"encode " + str(encoded.get("error")))
	var decoded := SaveCodec.decode(encoded.get("json",""))
	check(decoded.ok,"decode " + str(decoded.get("error")))
	if decoded.ok:
		check(JSON.parse_string(JSON.stringify(decoded.state.sect)) == JSON.parse_string(JSON.stringify(s.state.sect)), "lineage roundtrip")

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach supply")
	check(SectLineage.achievement_definitions().size() == 16,"16 fixed titles")
	check(AchievementSystem.DEFINITIONS.has("sect_five_paths"),"registered titles")
	var s := fresh()
	var before := s.state.duplicate_state()
	SectLineage.view(s.state)
	check(same(before,s.state), "view never initializes old state")
	for row in AchievementSystem.get_achievement_view(s.state,content).achievements:
		if SectLineage.ACHIEVEMENTS.has(row.id): check(row.name == "未明傳承", "hidden title")
	before = s.state.duplicate_state()
	check(not s.learn_talent("taixu_lineage").ok and same(before,s.state),"hidden cannot buy")
	# No history can be inferred from total rebirths, highest era, or the legacy taixu default.
	s.state.reincarnation_count = 99
	s.state.highest_era = 6
	s.state.achievements.story.current_life_id = 100
	s.state.life_ledger = {}
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	s.state.sect.sect_name = "天劍聖宗"
	s.state.era_id = 2
	var legacy := s.state.sect.duplicate(true)
	roundtrip(s)
	check(s.state.sect == legacy and SectLineage.completed(s.state,"tianjian_sect") == 0,"legacy no backfill or mutation")
	s.state.sect.active_expedition = {"id":"old", "duration":60, "elapsed":60, "rewards":{"contribution":15,"money":50}}
	check(s.claim_sect_expedition().ok and not s.state.sect.has("lineage"),"old completed task no credit")
	check(s.refresh_sect_tasks(true).ok,"new generation opts into credit feature")
	check(s.state.sect.lineage.life_seq == 99 and SectLineage.completed(s.state,"tianjian_sect") == 0,"current seq only")
	claims(s,2)
	check(not SectLineage.qualifies(s.state),"two claims insufficient")
	rebirth(s)
	check(SectLineage.completed(s.state,"tianjian_sect") == 0 and s.state.sect.lineage.life_claimed == 0,"nonqualifying reset")
	# Complete 25 isolated simulated lives with production task instances and real commands.
	s = fresh()
	for key in SectLineage.KEYS:
		for life in range(1,6):
			join(s,key + "_sect")
			claims(s)
			check(SectLineage.qualifies(s.state),"three claims candidate")
			before = s.state.duplicate_state()
			check(not s.submit(cmd(s,"reincarnate")).ok and same(before,s.state),"no new early-rebirth shortcut")
			var command := rebirth(s,"rebirth-" + key + str(life))
			check(SectLineage.completed(s.state,key + "_sect") == life,"one effective life")
			check(s.state.sect.lineage.life_seq == s.state.reincarnation_count and s.state.sect.lineage.last_settled_life_seq == s.state.reincarnation_count - 1,"sequence monotonic")
			check(s.state.sect.lineage.life_claimed == 0 and s.state.sect.lineage.life_sect_id == "" and s.state.sect.lineage.life_peak_era == 1,"clear current only")
			before = s.state.duplicate_state()
			check(s.submit(command).get("duplicate",false) and same(before,s.state),"reincarnation receipt duplicate")
			var id: String = key + "_lineage"
			if life in [1,3,5]:
				var ach: String = "sect_" + key + "_lineage_" + str(life)
				check(s.state.achievements.unlocked.has(ach),"title revealed atomically")
				var can_before := TalentSystem.can_learn(s.state,id)
				var wallet := s.state.dao_heart.serialize()
				var proof := s.state.dao_proof
				var contrib: String = s.state.sect.contribution
				var resources := s.state.resources.duplicate(true)
				# Alternate buy/claim order; title collection never changes qualification or currency.
				if life == 3: check(s.learn_talent(id).ok,"buy before title")
				check(s.submit(cmd(s,"claim_achievement",{"achievement_id":ach})).ok,"claim title")
				if life != 3:
					check(wallet == s.state.dao_heart.serialize(),"title zero Dao heart")
					check(can_before.can_learn == TalentSystem.can_learn(s.state,id).can_learn,"claim independent eligibility")
					check(s.learn_talent(id).ok,"buy after title")
				var rank: int = SectLineage.THRESHOLDS.find(life) + 1
				check(SectLineage.rank(s.state,id) == rank,"rank exact")
				check(AmountCompat.try_parse(wallet).value.subtract(s.state.dao_heart).compare_to(AmountCompat.from_number(SectLineage.COSTS[rank-1])) == 0,"exact Dao cost")
				check(s.state.dao_proof == proof and s.state.sect.contribution == contrib,"title no proof or contribution")
				check(JSON.stringify(resources) == JSON.stringify(s.state.resources),"title no materials")
				check(SectLineage.bonus(s.state,key) == 0.0,"new life dormant")
			before = s.state.duplicate_state()
			check(not s.learn_talent(key + "_lineage").ok and same(before,s.state),"next rank threshold or max blocks no cost")
			roundtrip(s)
	check(s.state.achievements.unlocked.has("sect_five_paths"),"five paths")
	# Each passive activates only for its matching current membership, after Era1.
	for key in SectLineage.KEYS:
		join(s,key + "_sect",1)
		check(is_zero_approx(SectLineage.bonus(s.state,key)),"Era1 dormant")
		s.state.era_id = 2
		SectLineage.observe(s.state)
		for other in SectLineage.KEYS:
			check(is_equal_approx(SectLineage.bonus(s.state,other),0.06 if other == key else 0.0),"membership exclusion")
		check(is_equal_approx(SectSystem.compute_multipliers(s.state).cultivation_speed_bonus,0.06 if key == "taixu" else 0.0),"cultivation additive")
		check(is_equal_approx(SectSpecialization.capacity_bonus(s.state,"lingli"),0.06 if key == "zixiao" else 0.0),"lingli cap only")
		check(SectSpecialization.capacity_bonus(s.state,"wood") == 0.0,"lineage no material cap")
		for island in SectSpecialization.GATHER:
			for resource in SectSpecialization.GATHER[island]:
				var match_key := "tianjian" if island in ["ore","deep"] else "piaomiao"
				check(is_equal_approx(SectSpecialization.gather_bonus(s.state,island,resource),0.06 if key == match_key else 0.0),"gather whitelist additive")
		check(SectSpecialization.gather_bonus(s.state,"wood","wood") == 0.0,"not wood")
		check(SectSpecialization.duration(s.state,"bronze_essence",20) == 20,"no lineage forge speed")
		var cap := Lifespan.max_lifespan_seconds(content.era_lifespan_entries(),2,0.06 if key == "wanfo" else 0.0)
		check(Lifespan.for_state(content.era_lifespan_entries(),s.state) == cap,"lifespan shared helper")
		# New lineage effect must invalidate prepared state and preserve online/offline parity.
		var online := s.state.duplicate_state()
		var offline := s.state.duplicate_state()
		offline.sect.lineage.learned[key + "_lineage"] = 0
		var prepared := TimeAdvancer.prepare_advance(offline,content)
		offline.sect.lineage.learned[key + "_lineage"] = 3
		for i in range(6): TimeAdvancer.advance(online,content,1)
		OfflineClosedForm.advance(offline,content,6,prepared)
		check(same(online,offline),"online/offline parity " + key)
		SectSystem.on_reincarnate(s.state)
	# Exhaustion cannot be repaired by buying the new longevity talent.
	var exhausted := fresh()
	join(exhausted,"wanfo_sect")
	exhausted.state.reincarnation_count = 5
	exhausted.state.sect.lineage.life_seq = 5
	exhausted.state.sect.lineage.completed_lives.wanfo_sect = 5
	exhausted.state.dao_heart = AmountCompat.from_number(100)
	exhausted.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),exhausted.state)
	before = exhausted.state.duplicate_state()
	check(not exhausted.learn_talent("wanfo_lineage").ok and same(before,exhausted.state),"exhaustion no resurrection")
	# Save failures retain the exact settled state and receipts; reload retry never re-awards.
	var mem := Memory.new()
	var saved := fresh()
	join(saved,"taixu_sect")
	claims(saved)
	var replay := rebirth(saved,"saved-rebirth")
	SaveManager.configure(content,mem)
	mem.fail = true
	before = saved.state.duplicate_state()
	check(not SaveManager.save(saved.state,META).ok and not SaveManager.save(saved.state,META).ok and same(before,saved.state),"refused writes preserve result")
	mem.fail = false
	check(SaveManager.save(saved.state,META).ok,"save retry")
	SaveManager.configure(content,mem)
	saved.state = SaveManager.current_state()
	check(saved.state != null,"reload saved lineage")
	if saved.state != null:
		check(saved.submit(replay).get("duplicate",false) and SectLineage.completed(saved.state,"taixu_sect") == 1,"reload replay no double life")
		check(saved.learn_talent("taixu_lineage").ok,"buy persisted unlocked unclaimed")
	SaveManager.reset_for_tests()
	# New feature data is strict on both encode and decode (decode validates after JSON normalization).
	for kind in ["missing_marker", "unknown_key", "unknown_rank", "fractional_rank", "insufficient_lives", "forged_title", "bad_claim_flag", "stale_task", "missing_task_marker"]:
		var broken := saved.state.duplicate_state()
		match kind:
			"missing_marker": broken.sect.erase("lineage")
			"unknown_key": broken.sect.lineage.completed_lives.forged_sect = 1
			"unknown_rank": broken.sect.lineage.learned.forged_lineage = 1
			"fractional_rank": broken.sect.lineage.learned.taixu_lineage = 1.5
			"insufficient_lives": broken.sect.lineage.learned.taixu_lineage = 3
			"forged_title": broken.achievements.unlocked.sect_forged = 0
			"bad_claim_flag": broken.achievements.claimed.sect_taixu_lineage_1 = 1
			"stale_task", "missing_task_marker":
				broken.era_id = 2
				SectLineage.observe(broken)
				SectSystem.join_sect(broken,"taixu_sect")
				if kind == "stale_task": broken.sect.available_tasks[0].lineage_credit.life_seq += 1
				else: broken.sect.erase("lineage")
		check(not SaveCodec.encode(broken,content.content_version,META).ok,"reject feature corruption " + kind)
		check(not SaveCodec._state_from_snapshot(broken.to_snapshot_dict()).ok,"decode rejects corruption " + kind)
	# Claims from an old in-flight task still yield no credit after new-task generation.
	var old_active := fresh()
	join(old_active,"taixu_sect")
	old_active.state.sect.active_expedition = {"id":"pre-reform", "duration":1, "elapsed":1, "rewards":{"contribution":15}}
	check(old_active.claim_sect_expedition().ok and old_active.state.sect.lineage.life_claimed == 0,"old active no credit under new marker")
	# Era1 may join after rebirth but cannot qualify without an observed Era2 peak.
	var era1 := fresh()
	era1.state.reincarnation_count = 1
	StoryProgress.next_life(era1.state)
	era1.state.life_ledger = {}
	join(era1,"taixu_sect",1)
	claims(era1)
	check(not SectLineage.qualifies(era1.state),"Era1 three claims insufficient")
	rebirth(era1)
	check(SectLineage.completed(era1.state,"taixu_sect") == 0,"Era1 no effective life")
	join(era1,"taixu_sect",2)
	era1.state.era_id = 1 # Equivalent to a later demotion: observed peak is retained.
	claims(era1)
	check(SectLineage.qualifies(era1.state),"peak survives demotion")
	rebirth(era1)
	check(SectLineage.completed(era1.state,"taixu_sect") == 1,"peak used at settlement")
	# A refused settlement save must leave the previous durable generation recoverable.
	var durable := fresh()
	join(durable,"taixu_sect")
	claims(durable)
	durable.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),durable.state)
	mem = Memory.new()
	SaveManager.configure(content,mem)
	check(SaveManager.save(durable.state,META).ok,"save before settlement")
	var durable_command := cmd(durable,"reincarnate",{},"durable-rebirth")
	check(durable.submit(durable_command).ok,"settle candidate")
	mem.fail = true
	check(not SaveManager.save(durable.state,META).ok,"refuse candidate save")
	mem.fail = false
	SaveManager.configure(content,mem)
	var recovered := SaveManager.current_state()
	check(recovered != null,"recover previous durable generation")
	if recovered != null:
		durable.state = recovered
		check(SectLineage.completed(recovered,"taixu_sect") == 0 and recovered.sect.lineage.life_claimed == 3,"failed save did not leak effective life")
		check(durable.submit(durable_command).ok and SectLineage.completed(durable.state,"taixu_sect") == 1,"retry from durable baseline once")
		check(SaveManager.save(durable.state,META).ok,"persist retried settlement")
		SaveManager.configure(content,mem)
		durable.state = SaveManager.current_state()
		check(durable.state != null and durable.submit(durable_command).get("duplicate",false),"persisted retry receipt")
	SaveManager.reset_for_tests()
	var claim_limit := fresh()
	join(claim_limit,"taixu_sect")
	var task_id: String = claim_limit.state.sect.available_tasks[0].id
	check(claim_limit.start_sect_expedition(task_id).ok,"overflow task start")
	SectSystem.tick(claim_limit.state,900)
	claim_limit.state.sect.lineage.life_claimed = SectLineage.LIMIT
	before = claim_limit.state.duplicate_state()
	var refused := claim_limit.claim_sect_expedition()
	check(refused.get("error") == "SECT_LINEAGE_OVERFLOW" and same(before,claim_limit.state),"claim overflow no partial rewards")
	# Bounded data refuses unknown, malformed and inconsistent payloads.
	for field in ["version","life_seq","life_claimed","life_peak_era","last_settled_life_seq"]:
		for bad in [-2,1.5,true,"1",INF,NAN,2147483648]:
			var broken := before.duplicate_state()
			broken.sect.lineage[field] = bad
			check(not SaveCodec.encode(broken,content.content_version,META).ok,"bad counter " + field + str(bad))
	for bad in [true, 1, {}, "forged_sect"]:
		var broken := before.duplicate_state()
		broken.sect.lineage.life_sect_id = bad
		check(not SaveCodec.encode(broken,content.content_version,META).ok,"invalid life identity type or ID")
	var overflow := fresh()
	join(overflow,"taixu_sect")
	claims(overflow)
	overflow.state.reincarnation_count = SectLineage.LIMIT
	overflow.state.sect.lineage.life_seq = SectLineage.LIMIT
	for task in overflow.state.sect.available_tasks: task.lineage_credit.life_seq = SectLineage.LIMIT
	before = overflow.state.duplicate_state()
	overflow.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),overflow.state)
	before = overflow.state.duplicate_state()
	check(overflow.submit(cmd(overflow,"reincarnate")).get("error") == "SECT_LINEAGE_OVERFLOW" and same(before,overflow.state),"sequence overflow atomic refusal")
	print("SECT-REFORM-LINEAGE ", checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
