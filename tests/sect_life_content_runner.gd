extends SceneTree
const Memory = preload("res://tests/sect_reform_save_runner.gd").Memory
const META := {"save_id":"sect-ui-review","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}
var checks := 0
var failures: Array[String] = []
var content: GameContent
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok: failures.append(note); print("FAIL ",note)
func _init() -> void: run.call_deferred()
func fixture(id: String, legacy: bool = false) -> GameState:
	var s: GameState = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
	SectIdentity.write(s.sect,id)
	SectLineage.observe(s)
	s.sect.available_tasks = []
	SectSystem.refresh_tasks(s)
	s = SectLife.prepare(s)
	if legacy:
		s.sect_version = 5
		s.sect.life = SectLife.initial(s)
	s.sect.entry = SectEntry.initial()
	s.sect.entry.skip = true
	return s
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	var ids := {}
	for sid in SectIdentity.NAMES:
		var chapters := SectLife.table(sid,"chapters")
		var daily := SectLife.table(sid,"daily")
		check(chapters.size() == 6 and daily.size() == 3 and SectLife.table(sid,"npcs").size() == 3,"bounded tables "+sid)
		for id in chapters+daily+SectLife.table(sid,"npcs"):
			check(not ids.has(id) and id.to_utf8_buffer().size() <= 48,"unique bounded ID "+id)
			ids[id] = true
		for choice in ["A","B","decline"]:
			var s := fixture(sid)
			var expedition_rng: Dictionary = s.sect.rng.duplicate(true)
			for i in 6:
				SectLife.advance(s,maxi(1,maxi(SectLife.AGES[i],int(s.sect.life.next_story_second))-int(s.sect.life.tenure_seconds)),true)
				var p: Dictionary = s.sect.life.pending_story
				check(p.template_id == chapters[i],"chapter order "+sid+str(i))
				var prose := SectLifeContent.read(p.template_id,s.sect.life.choice_flags)
				check(not prose.text.is_empty() and not prose.A.is_empty() and not prose.responses[choice].is_empty(),"complete prose "+p.template_id+choice)
				if i >= 3 and sid != "taixu_sect":
					var row: Dictionary = SectLifeCatalog.SECTS[sid].stories[p.template_id]
					check(prose.text.begins_with(row.callbacks[s.sect.life.choice_flags[row.callback_key]]),"exact branch callback "+choice)
				check(SectLife.resolve(content,s,{"instance_id":p.instance_id,"option_id":choice}).ok,"resolve "+sid+choice)
				check(SectLifeSave.validate(s.sect).is_empty(),"valid after chapter "+sid+str(i))
			check(s.sect.life.story_reserved == 12 and s.sect.life.memories[sid] == 63 and s.sect.life.recent.size() == 4,"cap memory bounded history "+sid)
			check(SectLifeSave.same(expedition_rng,s.sect.rng),"expedition stream untouched")
			s.sect.life.next_story_second = s.sect.life.tenure_seconds
			SectLife.offer(s)
			check(not s.sect.life.pending_story.paid and s.sect.life.pending_story.template_id in daily,"daily capped single slot "+sid)
			var a := s.duplicate_state()
			var b := s.duplicate_state()
			SectLife.advance(a,600,true)
			for i in 600: SectLife.advance(b,1,true)
			check(SectLifeSave.same(a.sect.life,b.sect.life),"whole split RNG parity "+sid)
			var raw := SaveCodec.encode(s,content.content_version,META)
			check(raw.ok and SaveCodec.decode(raw.json).ok,"schema9 roundtrip "+sid+str(raw.get("error"))+str(SaveCodec.decode(raw.get("json", "")).get("error")))
			check(JSON.stringify(s.sect).to_utf8_buffer().size() < 32768 and JSON.stringify(s.sect.life).to_utf8_buffer().size() < 8192,"bounded payload "+sid)
			var corrupt := s.sect.duplicate(true)
			corrupt.life.npcs["foreign_npc"] = {"affinity":0,"met":false}
			check(not SectLifeSave.validate(corrupt).is_empty(),"foreign NPC rejected")
			corrupt = s.sect.duplicate(true)
			corrupt.life.recent[0].id = "zx_chart_first" if sid != "zixiao_sect" else "tx_book_first"
			check(not SectLifeSave.validate(corrupt).is_empty(),"foreign recent rejected")
			corrupt = s.sect.duplicate(true)
			corrupt.life.choice_flags["foreign_flag"] = "inspect"
			check(not SectLifeSave.validate(corrupt).is_empty(),"foreign flags rejected")
			corrupt = s.sect.duplicate(true)
			corrupt.life.pending_story = SectLife.frozen("zx_chart_first" if sid != "zixiao_sect" else "tx_book_first","bad",500,0,true)
			check(not SectLifeSave.validate(corrupt).is_empty(),"foreign pending rejected")
			var memories: Dictionary = s.sect.life.memories.duplicate(true)
			s.reincarnation_count += 1
			SectSystem.on_reincarnate(s)
			check(SectLifeSave.same(memories,s.sect.life.memories) and s.sect.life.npcs.is_empty(),"rebirth retains only small meta "+sid)
		# Legacy schema8, including already entered opponents, migrates atomically.
		SaveManager.reset_for_tests()
		var old := fixture(sid,true)
		SectLife.advance(old,360,true)
		check(SectTournament.execute(content,old,"enter_sect_tournament",{"instance_id":old.sect.life.competition.current.id,"preparation":1}).ok,"legacy entered tournament "+sid)
		var before: Dictionary = old.sect.life.duplicate(true)
		var economy := old.to_snapshot_dict()
		var raw := SaveCodec.encode(old,content.content_version,META)
		check(raw.ok and SaveCodec.decode(raw.json).ok,"schema8 original readable "+sid)
		var memory := Memory.new()
		memory.data[SaveSlots.SLOT_MAIN] = raw.json
		SaveManager.configure(content,memory)
		var session := GameSession.new()
		session.content = content; session.state = old; session.clock = GameClock.create(0)
		memory.fail = SaveSlots.SLOT_BACKUP
		check(not SaveManager.activate_sect_life(session,META).ok and session.state.sect_version == 5,"denied migration retains authority "+sid)
		check(SectLifeSave.same(before,session.state.sect.life),"failed migration unchanged RNG and tournament")
		memory.fail = ""
		check(SaveManager.save(session.state,META).ok,"migration retry "+sid)
		var l: Dictionary = session.state.sect.life
		check(session.state.sect_version == SectLife.SECT_VERSION and l.npcs.size() == 3 and l.content_version == 2,"new version and exactly three NPCs "+sid)
		for field in ["tenure_seconds","rng","pending_story","competition","reward_epoch","story_reserved","story_serial","choice_flags"]:
			check(SectLifeSave.same(before[field],l[field]),"migration preserves "+sid+field)
		check(session.state.sect.contribution == economy.sect.contribution and SectLifeSave.same(session.state.sect.entry,economy.sect.entry),"migration preserves economy and entry")
		check(memory.data.has(SectReformSave.ARCHIVE_PREFIX+raw.json.sha256_text()),"exact source archived "+sid)
		check(not l.competition.current.has("roster_version"),"legacy roster stays revision1")
		check(SectLifeSave.validate(session.state.sect).is_empty(),"migrated validation "+sid)
		SectTournament.execute(content,session.state,"abandon_sect_tournament",{"instance_id":l.competition.current.id})
		SectLife.advance(session.state,600,true)
		SectTournament.execute(content,session.state,"enter_sect_tournament",{"instance_id":l.competition.current.id,"preparation":0})
		check(l.competition.current.get("roster_version") == 2 and SectLifeSave.validate(session.state.sect).is_empty(),"new edition uses content2 familiar faces")
		# Same command transaction and dedupe for each new sect, with exact frozen rewards.
		SaveManager.reset_for_tests()
		memory = Memory.new()
		var baseline := SaveCodec.encode(session.state,content.content_version,META)
		memory.data[SaveSlots.SLOT_MAIN] = baseline.json
		SaveManager.configure(content,memory)
		var pending: Dictionary = session.state.sect.life.pending_story
		var authority := session.state.to_snapshot_dict()
		var command := {"command_id":"expanded-story-"+sid,"type":"resolve_sect_story","expected_revision":session.state.revision,"payload":{"instance_id":pending.instance_id,"option_id":"B"}}
		memory.fail = SaveSlots.SLOT_BACKUP
		check(not session.submit(command).ok and SectLifeSave.same(authority,session.state.to_snapshot_dict()),"new story denied without mutation "+sid)
		memory.fail = ""
		check(SaveManager.save(session.state,META).ok,"new story exact retry "+sid)
		check(session.state.sect.life.choice_flags[SectLife.table(sid,"flag_keys")[0]] == SectLife.table(sid,"flag_values")[0][1],"local B flag committed "+sid)
		check(session.submit(command).get("duplicate",false),"command retry dedupe "+sid)
		check(not session.resolve_sect_story(pending.instance_id,"B").ok,"stale instance no new reward "+sid)
	SaveManager.reset_for_tests()
	print("SECT-LIFE-CONTENT ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
