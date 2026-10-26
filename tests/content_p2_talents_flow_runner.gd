extends SceneTree
const DIR := "res://docs/verification/artifacts/content-p2-talents-ui/"
const META := {"save_id":"talent2-earned", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var checks := 0
var failures := []
var serial := 0
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FLOW FAILURE ",label)
func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"type":kind,"payload":payload,"command_id":"talent2-flow-"+str(serial),"expected_revision":s.state.revision})
func save_fixture(state: GameState, content: GameContent, name: String) -> void:
	var encoded := SaveCodec.encode(state,content.content_version,META)
	check(encoded.ok,"encode "+name+str(encoded.get("error","")))
	if encoded.ok:
		var file := FileAccess.open("res://src/verification/talent2-"+name+".json",FileAccess.WRITE)
		file.store_string(encoded.json)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var content: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"supply attached")
	var source := "res://docs/verification/artifacts/content-p2-supply-3/earned-era4.json"
	var raw := FileAccess.get_file_as_string(source)
	var decoded := SaveCodec.decode(raw)
	check(decoded.ok,"inherited legal Era4 snapshot decodes")
	if not decoded.ok: RunnerResult.finish(self,1); return
	var s := GameSession.new()
	s.content = content
	s.state = decoded.state
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	check(s.state.era_id == 4 and s.state.reincarnation_count == 0 and s.state.dao_heart.to_float() == 0,"no injected gate or hearts")
	TalentSystem.reconcile(s.state)
	SkillSystem.reconcile(content,s.state)
	StoryProgress.migrate(s.state)
	var max_age := float(s.get_view().max_lifespan_seconds)
	var age_before := s.state.total_elapsed_seconds
	print("FLOW offline Era4 ",age_before," -> ",max_age)
	var result := OfflineSettlement.settle(s.state,content,1000+int(ceil(max_age-age_before+1))*1000,1000)
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	print("FLOW offline done ",s.state.total_elapsed_seconds)
	check(result.stopped == "lifespan_exhausted" and s.state.total_elapsed_seconds >= max_age,"legal offline time reaches lifespan exhaustion")
	check(send(s,"reincarnate",{"mode":"normal"}).ok,"formal Era4 reincarnation")
	check(s.state.era_id == 1 and s.state.reincarnation_count == 1 and s.state.highest_era == 4 and s.state.dao_heart.to_float() == 25,"earns 25 hearts, keeps highest Era4")
	save_fixture(s.state,content,"earned")
	var reborn := SaveCodec.encode(s.state,content.content_version,META)
	var choices := {}
	for id in TalentSystem.P2_IDS:
		s.state = SaveCodec.decode(reborn.json).state
		s.clock = GameClock.create(0)
		check(s.get_view().talent_options[id].can_learn,"era1 option matches command "+id)
		check(send(s,"learn_talent",{"talent_id":id}).ok,"earned first rank "+id)
		check(s.state.talents[id] == 1 and s.state.dao_heart.to_float() == 15,"exact earned debit "+id)
		var before := s.state.to_snapshot_dict()
		check(not send(s,"learn_talent",{"talent_id":id}).ok and before == s.state.to_snapshot_dict(),"rank2 unaffordable atomic "+id)
		var roundtrip := SaveCodec.encode(s.state,content.content_version,META)
		check(roundtrip.ok and SaveCodec.decode(roundtrip.json).state.talents[id] == 1,"reload retains "+id)
		choices[id] = {"hearts":s.state.dao_heart.serialize(),"talents":s.state.talents.duplicate(true),"production_multiplier":s.get_view().multipliers.global_production_multiplier}
		# Continue legally through this Era1 life to prove a second rebirth retains the purchase.
		var life := float(s.get_view().max_lifespan_seconds)
		var second := OfflineSettlement.settle(s.state,content,1000+int(ceil(life+1))*1000,1000)
		s.clock = GameClock.create(s.state.total_elapsed_seconds)
		check(second.stopped == "lifespan_exhausted","second life expires "+id)
		check(send(s,"reincarnate",{"mode":"normal"}).ok and s.state.talents[id] == 1 and s.state.highest_era == 4,"cross-life retention "+id)
	# Separate fixtures for UI rejection / five-rank display. These are explicitly synthetic.
	s.state = SaveCodec.decode(reborn.json).state
	s.state.dao_heart = AmountCompat.from_number(1000)
	save_fixture(s.state,content,"synthetic-budget")
	for id in TalentSystem.P2_IDS:
		for rank in range(5):
			var balance := s.state.dao_heart.to_float()
			check(send(s,"learn_talent",{"talent_id":id}).ok and s.state.dao_heart.to_float() == balance-[10,20,40,80,160][rank],"five-rank debit "+id)
		var before := s.state.to_snapshot_dict()
		check(not send(s,"learn_talent",{"talent_id":id}).ok and before == s.state.to_snapshot_dict(),"max rejects "+id)
	save_fixture(s.state,content,"synthetic-max")
	s.state = SaveCodec.decode(reborn.json).state
	s.state.talent_version = 2
	save_fixture(s.state,content,"old-earned")
	var report := {"checks":checks,"failures":failures,"source":source,"source_sha256":raw.sha256_text(),"source_age":age_before,"max_age":max_age,"legal_rebirth_hearts":25,"choices":choices,"boundary":"inherited audited Era4 command-earned snapshot -> legal simulated time -> formal rebirth; not a new blank-save or browser natural long run; max/budget fixtures synthetic"}
	var file := FileAccess.open(DIR+"flow.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("TALENT-2 FLOW ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
