extends SceneTree
const Memory = preload("res://tests/sect_reform_save_runner.gd").Memory
const META := {"save_id":"sect-ui-review","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}
var checks := 0
var failures := []
var content: GameContent
func check(value: bool, note: String) -> void:
	checks += 1
	if not value: failures.append(note); print("FAIL ",note)
func _init() -> void: run.call_deferred()
func fixture() -> GameState:
	return SectLife.prepare(preload("res://tests/sect_reform_ui_fixture.gd").create(content))
func execute(s: GameState, action: String, payload: Dictionary = {}) -> Dictionary:
	if not payload.has("instance_id") and s.sect.life.competition.current != null: payload.instance_id = s.sect.life.competition.current.id
	return SectTournament.execute(content,s,action,payload)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	var s := fixture()
	SectLife.advance(s,299,true)
	check(s.sect.life.competition.current == null,"no early invitation")
	SectLife.advance(s,1,true)
	check(s.sect.life.competition.current.edition == 1,"300 second invite")
	var invite: Dictionary = s.sect.life.competition.current.duplicate(true)
	SectLife.advance(s,1800,true)
	check(SectLifeSave.same(invite,s.sect.life.competition.current),"offline missed editions retain original invite")
	var story_rng: int = s.sect.life.rng.story
	check(execute(s,"enter_sect_tournament",{"preparation":1}).ok,"entry")
	check(s.sect.life.rng.story == story_rng,"RNG independent")
	var t: Dictionary = s.sect.life.competition.current
	var frozen: Dictionary = t.frozen.duplicate(true)
	check(not execute(s,"choose_sect_trial",{"stage":1,"strategy":"steady"}).ok,"cannot skip stage")
	check(not execute(s,"claim_sect_tournament").ok,"cannot claim early")
	for stage in 3:
		check(execute(s,"choose_sect_trial",{"stage":stage,"strategy":"observe" if stage == 1 else "steady"}).ok,"stage %d" % stage)
		var raw := SaveCodec.encode(s,content.content_version,META)
		check(raw.ok,"encode stage %d: %s" % [stage,raw.get("error")])
		if raw.ok: check(SaveCodec.decode(raw.json).ok,"decode stage")
	var rank := SectTournament.order(frozen,t.choices).find(0)+1
	check(rank >= 1 and rank <= 8,"bounded rank")
	s.era_id = 4
	s.level = 10
	s.sect.techniques.breathing_method = 10
	check(SectLifeSave.same(frozen,t.frozen),"progress and method changes cannot change frozen baseline")
	var funds: AmountCompat = AmountCompat.try_parse(s.sect.contribution).value
	var id: String = t.id
	check(execute(s,"claim_sect_tournament").ok,"claim")
	check(AmountCompat.try_parse(s.sect.contribution).value.compare_to(funds.add(AmountCompat.from_number(SectTournament.reward(rank)) )) == 0,"exact total reward")
	check(not execute(s,"claim_sect_tournament",{"instance_id":id}).ok,"stale claim blocked")
	check(s.sect.life.best_ranks.taixu_sect == rank,"permanent best")
	SectTournament.offer(s)
	check(s.sect.life.competition.current == null and s.sect.life.competition.next_second == 2700,"no catchup award")
	SectLife.advance(s,600,true)
	check(s.sect.life.competition.current.edition == 5,"next future edition")
	check(execute(s,"skip_sect_tournament").ok,"skip")
	check(s.sect.life.competition.next_second == 3300,"skip next future")
	# Exact scoring, both risk outcomes and deterministic tie comparisons.
	var f := SectTournament.frozen(1,2,5,5,1)
	f.coins = [0,1,0]
	var rows := SectTournament.scores(f,["risk","risk","observe"])
	check(rows[0] == [52,72,58],"score arithmetic both risk outcomes")
	var saw := [false,false]
	for seed in range(1,40):
		var sample := SectTournament.frozen(seed,2,5,5,0)
		saw[int(sample.coins[0])] = true
		var order := SectTournament.order(sample,["steady","observe","risk"])
		check(order.size() == 8 and order.all(func(seat: int) -> bool: return order.count(seat) == 1),"eight unique deterministic seats")
	check(saw == [true,true],"both coin outcomes reachable")

	var tied := SectTournament.frozen(1,2,1,2,0)
	tied.offsets = [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]]
	tied.ties = [0,1,2,3,4,5,6,7]
	var choices := ["steady","steady","steady"]
	var ordered := SectTournament.order(tied,choices)
	check(ordered.find(0) < ordered.find(1),"equal totals and minimum use frozen tie order")
	tied.ties = [7,0,1,2,3,4,5,6]
	ordered = SectTournament.order(tied,choices)
	check(ordered.find(0) > ordered.find(1),"tie order does not favor player")
	tied.offsets[0] = [1,1,-2]
	ordered = SectTournament.order(tied,choices)
	check(ordered.find(0) < ordered.find(1),"minimum stage precedes tie order")
	for sect_id in SectIdentity.NAMES:
		var member := fixture()
		SectIdentity.write(member.sect,sect_id)
		SectLife.reset_life(member)
		SectLife.advance(member,300,true)
		check(execute(member,"enter_sect_tournament",{"preparation":2}).ok,"five sects entry "+sect_id)
		check(SectLifeSave.validate(member.sect).is_empty(),"five sects frozen save "+sect_id)
	var online := fixture()
	var offline := online.duplicate_state()
	TimeAdvancer.advance(online,content,901)
	OfflineClosedForm.advance(offline,content,901)
	check(SectLifeSave.same(online.sect.life,offline.sect.life),"offline invitation parity")
	check(offline.sect.life.competition.current.status == "invite","offline never enters or claims")
	var dead := fixture()
	SectLife.advance(dead,300,false)
	check(dead.sect.life.competition.current == null,"death tick does not offer")
	dead.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),dead)
	check(not execute(dead,"enter_sect_tournament",{"preparation":0}).ok,"exhausted cannot enter")
	# Full lifecycle via durable session, failed write and exact retry.
	SaveManager.reset_for_tests()
	var session := GameSession.new()
	session.content = content
	session.clock = GameClock.create(0)
	session.state = fixture()
	SectLife.advance(session.state,300,true)
	var raw := SaveCodec.encode(session.state,content.content_version,META)
	var mem := Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = raw.json
	SaveManager.configure(content,mem)
	id = session.state.sect.life.competition.current.id
	var before: Dictionary = session.state.sect.life.duplicate(true)
	mem.fail = SaveSlots.SLOT_BACKUP
	check(not session.sect_tournament("enter_sect_tournament",{"instance_id":id,"preparation":0}).ok,"rejected entry write")
	check(SectLifeSave.same(before,session.state.sect.life),"failed entry retains authority and RNG")
	var pending: String = SaveManager._core_pending.json
	check(not SaveManager.save(session.state,META).ok and pending == SaveManager._core_pending.json,"retry frozen bytes")
	mem.fail = ""
	check(SaveManager.save(session.state,META).ok,"entry retry")
	for stage in 3: check(session.sect_tournament("choose_sect_trial",{"instance_id":id,"stage":stage,"strategy":"steady"}).ok,"durable choice")
	var settled := session.state.duplicate_state()
	var cmd := {"type":"claim_sect_tournament","command_id":"claim-once","expected_revision":session.state.revision,"payload":{"instance_id":id}}
	# Both slots can alternate; target the next write using the slot selector.
	mem.fail = SaveSlots.SLOT_BACKUP if SaveCodec.decode(mem.data.get(SaveSlots.SLOT_MAIN,"")).get("state") != null and SaveCodec.decode(mem.data[SaveSlots.SLOT_MAIN]).state.revision == session.state.revision else SaveSlots.SLOT_MAIN
	check(not session.submit(cmd).ok,"claim write failure")
	check(SectLifeSave.same(settled.sect,session.state.sect),"failed claim no money")
	mem.fail = ""
	check(SaveManager.save(session.state,META).ok,"claim retry")
	var paid := String(session.state.sect.contribution)
	check(session.submit(cmd).get("duplicate",false) and session.state.sect.contribution == paid,"same command deduplicated")
	for mutation in ["coins","offsets","ties","phase","prep","edition","fields"]:
		var bad := settled.duplicate_state()
		var current: Dictionary = bad.sect.life.competition.current
		match mutation:
			"coins": current.frozen.coins[0] = 1-int(current.frozen.coins[0])
			"offsets": current.frozen.offsets[0][0] = 99
			"ties": current.frozen.ties[0] = current.frozen.ties[1]
			"phase": current.choices.pop_back()
			"prep": current.frozen.preparation = 4
			"edition": current.edition += 1
			"fields": current.reward_claimed = true
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"corruption rejected "+mutation)
	var exhausted := settled.duplicate_state()
	exhausted.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),exhausted)
	check(not execute(exhausted,"claim_sect_tournament").ok,"exhausted cannot claim")
	var partial := fixture()
	SectLife.advance(partial,300,true)
	execute(partial,"enter_sect_tournament",{"preparation":0})
	partial.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),partial)
	check(not execute(partial,"choose_sect_trial",{"stage":0,"strategy":"steady"}).ok,"exhausted cannot choose")
	var saved := SaveCodec.encode(session.state,content.content_version,META)
	check(saved.ok and SaveCodec.decode(saved.json).ok,"claimed reload")
	var best: Dictionary = session.state.sect.life.best_ranks.duplicate()
	SectLife.reset_life(session.state)
	check(session.state.sect.life.competition.current == null and session.state.sect.life.best_ranks == best,"new life drops pending retains best")
	# Old schema7 source migration preserves story and economy, archives source.
	SaveManager.reset_for_tests()
	var old := fixture()
	old.sect_version = 4
	old.sect.life.version = 1
	old.sect.life.content_version = 1
	old.sect.life.erase("competition")
	old.sect.life.erase("visit_round")
	var oldraw := SaveCodec.encode(old,content.content_version,META)
	check(oldraw.ok and SaveCodec.decode(oldraw.json).ok,"schema7 remains readable")
	mem = Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = oldraw.json
	SaveManager.configure(content,mem)
	check(SaveManager.commit_sect_life_startup().ok and SaveManager.current_state().sect_version == SectLife.SECT_VERSION,"schema7 migrates to9")
	check(mem.data.has(SectReformSave.ARCHIVE_PREFIX+oldraw.json.sha256_text()),"schema7 source archive")
	SaveManager.reset_for_tests()
	print("SECT-TOURNAMENT ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
