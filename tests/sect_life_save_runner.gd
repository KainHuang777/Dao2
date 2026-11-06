extends SceneTree
const Memory = preload("res://tests/sect_reform_save_runner.gd").Memory
const META := {"save_id":"sect-ui-review", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ", message)
func _init() -> void: run.call_deferred()
func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	var s := GameSession.new()
	s.content = content
	s.clock = GameClock.create(0)
	s.state = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
	var legacy_contrib: String = s.state.sect.contribution
	var legacy_tasks: Array = s.state.sect.available_tasks.duplicate(true)
	var old := SaveCodec.encode(s.state, content.content_version, META)
	check(old.ok and SaveCodec.decode(old.json).ok, "old schema6 still accepted")
	var mem := Memory.new()
	mem.write(SaveSlots.SLOT_MAIN, old.json)
	SaveManager.configure(content, mem)
	mem.fail = SaveSlots.SLOT_BACKUP
	var result := SaveManager.activate_sect_life(s, META)
	check(not result.ok and s.state.sect_version == 3, "migration denied keeps old authority")
	check(SaveManager.core_save_pending(s.state), "migration owns frozen candidate")
	check(mem.data.values().has(old.json), "original raw retained")
	mem.fail = ""
	check(SaveManager.save(s.state, META).ok and SectLife.active(s.state), "migration retry commits exact candidate")
	check(s.state.sect.life.tenure_seconds == 0 and s.state.sect.entry.legacy_review and not s.state.sect.entry.first_claim, "old membership starts zero unknown claim")
	check(s.state.sect.contribution == legacy_contrib and SectLifeSave.same(legacy_tasks, s.state.sect.available_tasks), "migration preserves old economy and frozen tasks")
	check(mem.data.has(SectReformSave.ARCHIVE_PREFIX + old.json.sha256_text()), "source archived by hash")
	var writes := mem.writes
	check(SaveManager.commit_sect_life_startup().ok and mem.writes == writes, "life startup idempotent")
	s.state.sect.entry.skip = true
	TimeAdvancer.advance(s.state, content, 1)
	var p: Dictionary = s.state.sect.life.pending_story.duplicate(true)
	var source := SaveCodec.encode(s.state, content.content_version, META)
	check(source.ok, "life schema encode")
	var decoded := SaveCodec.decode(source.get("json", ""))
	check(decoded.ok and decoded.envelope.schema_version == SaveCodec.LIFE_SCHEMA_VERSION and decoded.envelope.rules_version == SectLife.ROUND_RULES, "schema9 rules and content bound")
	check(SaveCodec.classify_envelope(decoded.envelope) == "current", "schema7 not future blocked")
	check(SectLifeSave.same(decoded.state.sect.life, s.state.sect.life), "full frozen roundtrip")
	check(SaveCodec.feature_content_version(decoded.envelope.content_version, decoded.state) == decoded.envelope.content_version, "feature content suffixes idempotent")
	# Fresh isolated storage makes backup the next target for a rejected command.
	SaveManager.reset_for_tests()
	mem = Memory.new()
	mem.write(SaveSlots.SLOT_MAIN, source.json)
	SaveManager.configure(content, mem)
	var before: Dictionary = s.state.sect.duplicate(true)
	var command := {"command_id":"story-once", "type":"resolve_sect_story", "expected_revision":s.state.revision, "payload":{"instance_id":p.instance_id,"option_id":"A"}}
	mem.fail = SaveSlots.SLOT_BACKUP
	result = s.submit(command)
	check(not result.ok and SectLifeSave.same(before, s.state.sect), "choice denied leaves all economy RNG and story intact")
	check(not s.submit(command).ok, "pending candidate blocks another command")
	mem.fail = ""
	check(SaveManager.save(s.state, META).ok, "choice retry durable")
	check(s.state.sect.life.chapter_mask == 1 and s.state.sect.life.pending_story == null, "choice commits exactly once")
	var after := String(s.state.sect.contribution)
	check(s.submit(command).get("duplicate", false) and s.state.sect.contribution == after, "same command replay no reward")
	check(not s.resolve_sect_story(p.instance_id, "A").ok, "different command stale instance rejected")
	var best_raw: String = mem.data[SaveSlots.SLOT_BACKUP]
	var invalid := JSON.parse_string(best_raw) as Dictionary
	invalid.state.sect.life.npcs.tx_shen_zhaowei.affinity = 101
	invalid.erase("checksum")
	invalid.checksum = SaveCodec.compute_checksum(invalid)
	mem.data[SaveSlots.SLOT_BACKUP] = JSON.stringify(invalid)
	SaveManager.configure(content, mem)
	var restored := SaveManager.current_state()
	check(restored != null and restored.sect.life.chapter_mask == 0, "invalid latest restores prior valid generation")
	for mutation in ["reward", "version", "rng", "extra", "sequence", "epoch", "flags"]:
		var bad: GameState = decoded.state.duplicate_state()
		match mutation:
			"reward": bad.sect.life.pending_story.options.A.contribution = 99
			"version": bad.sect.life.content_version = 99
			"rng": bad.sect.life.rng.story = -1
			"extra": bad.sect.life.extra = "unknown"
			"sequence": bad.sect.life.life_seq += 1
			"epoch": bad.sect.life.reward_epoch = 99
			"flags": bad.sect.life.choice_flags.book = "invented"
		check(not SaveCodec.encode(bad, content.content_version, META).ok, "reject corrupt " + mutation)
	var downgraded: GameState = decoded.state.duplicate_state()
	downgraded.sect_version = 3
	check(not SaveCodec.encode(downgraded, content.content_version, META).ok, "old version cannot carry new fields")
	# Four legal legacy tasks at their documented UTF-8 maxima, all methods and
	# ledgers plus full lifecycle state. No deletion/truncation or raised budget.
	var maximum: GameState = decoded.state.duplicate_state()
	maximum.sect.available_tasks = []
	maximum.sect.active_expedition = null
	for i in range(4):
		var task := {"id":str(i).repeat(128), "name":"n".repeat(128), "desc":"d".repeat(1024), "duration":900, "elapsed":899,
			"rewards":{"contribution":1000000,"money":1000000,"wood":1000000,"stone_low":1000000,"spirit_grass_low":1000000,"black_copper":1000000,"herb":1000000,"bronze":1000000}}
		if i == 3: maximum.sect.active_expedition = task
		else: maximum.sect.available_tasks.append(task)
	for id in SectSystem.TECHNIQUES: maximum.sect.techniques[id] = SectSystem.TECHNIQUES[id].max_level
	for id in SectSpecialization.METHODS: maximum.sect.techniques[id] = 5
	for id in SectSystem.MARKET_ITEMS: maximum.sect.market_purchases[id] = SectSystem.MARKET_ITEMS[id].limit
	maximum.sect.contribution = "1e250"
	maximum.sect.guardian.guardian_tokens = 120
	for id in GuardianDiscovery.TARGETS: maximum.sect.guardian.permits[id] = true
	for id in BeastSystem.BEAST_CONFIGS: maximum.sect.guardian.legacy_permits[id] = true
	maximum.sect.task_counter = SectLife.LIMIT
	var l: Dictionary = maximum.sect.life
	l.tenure_seconds = SectLife.LIMIT - 1
	l.reward_epoch = int(l.tenure_seconds) / 600
	l.story_reserved = 12
	l.story_serial = SectLife.LIMIT
	l.chapter_mask = 63
	for i in range(6): l.choice_flags[SectLife.FLAG_KEYS[i]] = SectLife.FLAG_VALUES[i][1]
	for id in SectIdentity.NAMES:
		l.memories[id] = 63
		l.best_ranks[id] = 1
	for npc in l.npcs.values(): npc.affinity = 100; npc.met = true
	l.recent = []
	for _i in range(4): l.recent.append({"id":"tx_debate_return", "option":"decline", "tick":SectLife.LIMIT-1})
	l.pending_story = SectLife.frozen("tx_daily_debate", "%d:taixu_sect:%d" % [l.life_seq, l.story_serial], int(l.tenure_seconds), int(l.reward_epoch), true)
	SectTournament.offer(maximum)
	var competition: Dictionary = l.competition
	var tournament_id: String = competition.current.id
	check(SectTournament.execute(content,maximum,"enter_sect_tournament",{"instance_id":tournament_id,"preparation":2}).ok,"capacity includes frozen eight-seat tournament")
	for stage in 3: SectTournament.execute(content,maximum,"choose_sect_trial",{"instance_id":tournament_id,"stage":stage,"strategy":"risk"})
	for edition in range(int(competition.cursor)-4,int(competition.cursor)):
		competition.recent.append({"edition":edition,"status":"claimed","rank":1})
	var bytes := JSON.stringify(maximum.sect).to_utf8_buffer().size()
	print("SECT-LIFE capacity sect=",bytes," life=",JSON.stringify(l).to_utf8_buffer().size())
	check(bytes <= 32768 and JSON.stringify(l).to_utf8_buffer().size() <= 8192, "maximum composed payload budgets")
	var max_encoded := SaveCodec.encode(maximum, content.content_version, META)
	check(max_encoded.ok and SaveCodec.decode(max_encoded.get("json", "")).ok, "maximum legal combined payload roundtrip")
	for sid in SectLifeCatalog.SECTS:
		var composed := maximum.duplicate_state()
		SectIdentity.write(composed.sect,sid)
		SectLineage.observe(composed)
		var life: Dictionary = composed.sect.life
		life.sect_id = sid
		life.npcs = {}
		for npc in SectLife.table(sid,"npcs"): life.npcs[npc] = {"affinity":100,"met":true}
		life.choice_flags = {}
		for i in 6: life.choice_flags[SectLife.table(sid,"flag_keys")[i]] = SectLife.table(sid,"flag_values")[i][1]
		for r in life.recent: r.id = SectLife.table(sid,"chapters")[5]
		life.pending_story = SectLife.frozen(SectLife.table(sid,"daily")[2],"%d:%s:%d" % [life.life_seq,sid,life.story_serial],int(life.tenure_seconds),int(life.reward_epoch),true)
		life.competition.current.id = "%d:%s:T%d" % [life.life_seq,sid,life.competition.cursor]
		var packed_bytes := JSON.stringify(composed.sect).to_utf8_buffer().size()
		var life_bytes := JSON.stringify(life).to_utf8_buffer().size()
		print("SECT-LIFE capacity ",sid," sect=",packed_bytes," life=",life_bytes)
		var encoded := SaveCodec.encode(composed,content.content_version,META)
		check(packed_bytes <= 32768 and life_bytes <= 8192 and encoded.ok and SaveCodec.decode(encoded.get("json", "")).ok,"four old tasks and full expanded payload "+sid)
	# Preserve legal extended legacy dictionaries near the old hard limit.
	SaveManager.reset_for_tests()
	var packed: GameState = decoded.state.duplicate_state()
	packed.sect.erase("life")
	packed.sect_version = 3
	packed.sect.legacy_extension = "x".repeat(32750 - JSON.stringify(packed.sect).to_utf8_buffer().size() - 25)
	var packed_raw := SaveCodec.encode(packed, content.content_version, META)
	check(packed_raw.ok, "near-cap legacy source still legal")
	mem = Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = packed_raw.get("json", "")
	SaveManager.configure(content, mem)
	result = SaveManager.commit_sect_life_startup()
	check(result.ok and result.get("life_unavailable") == "SECT_SIZE" and SaveManager.current_state().sect_version == 3, "capacity leaves legacy playable without false migration")
	check(not SaveManager.core_save_pending(SaveManager.current_state()), "capacity failure does not leave blocking transaction")
	SaveManager.reset_for_tests()
	# Daily resolution advances the dedicated RNG while staging the next delay.
	s.state = decoded.state.duplicate_state()
	SectLife.advance(s.state, 500, true)
	for _i in range(6):
		SectLife.advance(s.state, maxi(1, int(s.state.sect.life.next_story_second) - int(s.state.sect.life.tenure_seconds)), true)
		SectLife.resolve(content, s.state, {"instance_id":s.state.sect.life.pending_story.instance_id,"option_id":"decline"})
	SectLife.advance(s.state, 300, true)
	var daily_id: String = s.state.sect.life.pending_story.instance_id
	var expected := s.state.duplicate_state()
	SectLife.resolve(content, expected, {"instance_id":daily_id,"option_id":"A"})
	var daily_raw := SaveCodec.encode(s.state, content.content_version, META)
	mem = Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = daily_raw.json
	SaveManager.configure(content, mem)
	mem.fail = SaveSlots.SLOT_BACKUP
	check(not s.resolve_sect_story(daily_id, "A").ok, "daily rejected write")
	var frozen_candidate: String = SaveManager._core_pending.json
	check(not SaveManager.save(s.state, META).ok and frozen_candidate == SaveManager._core_pending.json, "daily repeated retry never redraws")
	mem.fail = ""
	mem.lost_response = SaveSlots.SLOT_BACKUP
	check(SaveManager.save(s.state, META).ok, "durable daily write with lost response reconciles")
	check(SectLifeSave.same(expected.sect.life, s.state.sect.life), "daily retry commits exactly expected RNG and next delay")
	check(s.state.sect.lineage.life_claimed == decoded.state.sect.lineage.life_claimed, "stories not expedition claims")
	SaveManager.reset_for_tests()
	round_migration_checks(content, decoded.state)
	print("SECT-LIFE-SAVE ", checks, " checks failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func round_migration_checks(content: GameContent, baseline: GameState) -> void:
	var old := baseline.duplicate_state()
	old.sect_version = 6
	old.sect.life.version = 3
	old.sect.life.erase("visit_round")
	SectLife.advance(old, 1000, true)
	for count in 7:
		for pending in [false, true]:
			var source := old.duplicate_state()
			if pending: SectLife.offer(source)
			else: source.sect.life.pending_story = null
			if count == 6 and pending:
				source.sect.life.next_story_second = source.sect.life.tenure_seconds
				SectLife.offer(source)
			var raw := SaveCodec.encode(source, content.content_version, META)
			check(raw.ok and SaveCodec.decode(raw.get("json", "")).ok, "schema9 remains readable count=" + str(count))
			var authority := source.to_snapshot_dict()
			var expected := SectLife.prepare(source)
			var mem := Memory.new()
			mem.data[SaveSlots.SLOT_MAIN] = raw.json
			SaveManager.reset_for_tests()
			SaveManager.configure(content, mem)
			var session := GameSession.new()
			session.content = content; session.state = source; session.clock = GameClock.create(0)
			mem.fail = SectReformSave.ARCHIVE_PREFIX + raw.json.sha256_text()
			check(not SaveManager.activate_sect_life(session, META).ok and SectLifeSave.same(authority, session.state.to_snapshot_dict()), "archive rejection keeps schema9 authoritative")
			var frozen: String = SaveManager._core_pending.json
			mem.fail = ""
			mem.corrupt = SaveSlots.SLOT_BACKUP
			check(not SaveManager.save(session.state, META).ok and SaveManager._core_pending.json == frozen and SectLifeSave.same(authority, session.state.to_snapshot_dict()), "corrupt candidate readback rejects unchanged bytes")
			mem.corrupt = ""
			check(SaveManager.save(session.state, META).ok and SectLifeSave.same(expected.to_snapshot_dict(), session.state.to_snapshot_dict()), "retry commits exact schema10 candidate")
			for field in ["pending_story","rng","competition","chapter_mask","choice_flags","npcs","tenure_seconds","story_reserved"]:
				check(SectLifeSave.same(source.sect.life[field], session.state.sect.life[field]), "schema9 preserves " + field)
			check(mem.data.get(SectReformSave.ARCHIVE_PREFIX + raw.json.sha256_text()) == raw.json, "exact schema9 archive")
			var migrated := session.state.to_snapshot_dict()
			SaveManager.configure(content, mem)
			var restored := SaveManager.current_state()
			check(restored != null and SectLifeSave.same(migrated, restored.to_snapshot_dict()), "schema10 reload retains round and frozen story")
			var writes := mem.writes
			check(SaveManager.commit_sect_life_startup().ok and mem.writes == writes, "round migration startup idempotent")
		if count < 6:
			SectLife.offer(old)
			check(SectLife.resolve(content, old, {"instance_id":old.sect.life.pending_story.instance_id,"option_id":"B"}).ok, "advance old chapter")
	SaveManager.reset_for_tests()
	# Third answer commits the cooldown atomically; repeated commands cannot shift it.
	var session := GameSession.new()
	session.content = content; session.clock = GameClock.create(0)
	session.state = SectLife.prepare(preload("res://tests/sect_reform_ui_fixture.gd").create(content))
	session.state.sect.entry = SectEntry.initial()
	session.state.sect.entry.skip = true
	SectLife.advance(session.state, 1000, true)
	for i in 2:
		SectLife.offer(session.state)
		SectLife.resolve(content, session.state, {"instance_id":session.state.sect.life.pending_story.instance_id,"option_id":"A"})
	SectLife.offer(session.state)
	var p: Dictionary = session.state.sect.life.pending_story
	var raw := SaveCodec.encode(session.state, content.content_version, META)
	var mem := Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = raw.json
	SaveManager.configure(content, mem)
	var command := {"command_id":"third-visit", "type":"resolve_sect_story", "expected_revision":session.state.revision, "payload":{"instance_id":p.instance_id,"option_id":"decline"}}
	mem.fail = SaveSlots.SLOT_BACKUP
	check(not session.submit(command).ok and session.state.sect.life.visit_round.mask == 3 and session.state.sect.life.next_story_second == 0, "failed third answer starts no cooldown")
	mem.fail = ""
	check(SaveManager.save(session.state, META).ok and session.state.sect.life.visit_round.mask == 7 and session.state.sect.life.next_story_second == 1180, "third decline retry starts exact cooldown")
	var committed := session.state.to_snapshot_dict()
	check(session.submit(command).get("duplicate", false) and SectLifeSave.same(committed, session.state.to_snapshot_dict()), "third answer replay never restarts cooldown")
	SaveManager.configure(content, mem)
	check(SaveManager.current_state().sect.life.next_story_second == 1180, "cooldown survives reload")
	for field in ["mask", "time", "repeat", "version"]:
		var bad := session.state.duplicate_state()
		match field:
			"mask": bad.sect.life.visit_round.mask = 8
			"time": bad.sect.life.next_story_second = 0
			"repeat": bad.sect.life.pending_story = p
			"version": bad.sect.life.visit_round.version = 2
		check(not SaveCodec.encode(bad, content.content_version, META).ok, "invalid round rejected " + field)
	SaveManager.reset_for_tests()
