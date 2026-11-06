extends SceneTree
var failures: Array[String] = []
var checks := 0
var content: GameContent
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ", message)
func _init() -> void: run.call_deferred()
func fixture() -> GameState:
	var state: GameState = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
	state.sect.entry = SectEntry.initial()
	state.sect.entry.skip = true
	return SectLife.prepare(state)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	var s := fixture()
	var before := s.to_snapshot_dict()
	TimeAdvancer.advance(s, content, 0)
	check(SectLifeSave.same(before, s.to_snapshot_dict()), "zero tick no initialization or RNG")
	var blocked := s.duplicate_state()
	blocked.sect.entry.skip = false
	TimeAdvancer.advance(blocked, content, 1)
	check(blocked.sect.life.pending_story == null, "greeting and first dispatch required")
	blocked.sect.entry.intro_seen = true
	blocked.sect.entry.first_dispatch = true
	TimeAdvancer.advance(blocked, content, 1)
	check(blocked.sect.life.pending_story.template_id == SectLife.CHAPTERS[0], "E1 after real tutorial receipts")
	var whole := s.duplicate_state()
	var split := s.duplicate_state()
	TimeAdvancer.advance(whole, content, 601)
	for _i in range(601): TimeAdvancer.advance(split, content, 1)
	check(SectLifeSave.same(whole.sect.life, split.sect.life), "whole and split exact life and RNG")
	check(whole.sect.life.pending_story.tick == 1 and whole.sect.life.story_serial == 1, "pending retained without catchup backlog")
	var offline := s.duplicate_state()
	OfflineClosedForm.advance(offline, content, 601)
	check(SectLifeSave.same(whole.sect.life, offline.sect.life), "offline common path exact")
	var age := s.duplicate_state()
	TimeAdvancer.advance_time_only(age, content, 601)
	check(SectLifeSave.same(whole.sect.life, age.sect.life), "age-only accepted ticks exact")
	var old_rng: Dictionary = s.sect.rng.duplicate()
	for i in range(6):
		SectLife.advance(s, maxi(1, maxi(SectLife.AGES[i], int(s.sect.life.next_story_second)) - int(s.sect.life.tenure_seconds)), true)
		var p: Dictionary = s.sect.life.pending_story
		check(p.template_id == SectLife.CHAPTERS[i], "fixed chapter priority %d" % i)
		check(SectLifeSave.validate(s.sect).is_empty(), "frozen chapter valid %d" % i)
		var contrib := String(s.sect.contribution)
		var result := SectLife.resolve(content, s, {"instance_id": p.instance_id, "option_id": "decline" if i == 0 else "B"})
		check(result.ok, "resolve %d" % i)
		check(not SectLife.resolve(content, s, {"instance_id": p.instance_id, "option_id": "B"}).ok, "stale instance rejected %d" % i)
		if i == 0: check(contrib == s.sect.contribution, "decline grants zero")
	check(s.sect.life.chapter_mask == 63 and s.sect.life.memories.taixu_sect == 63, "all chapters recorded")
	check(s.sect.life.recent.size() == 4 and SectLifeSave.same(old_rng, s.sect.rng), "bounded recent and independent expedition stream")
	check("上回未及" in SectLifeContent.read(SectLife.CHAPTERS[3], s.sect.life.choice_flags).text, "declined predecessor neutral callback")
	check(SectLifeContent.read(SectLife.CHAPTERS[3], {"book":"order"}).A == "列出索引", "choice-specific later text")
	check(int(s.sect.life.next_story_second) - int(s.sect.life.tenure_seconds) == 180, "first daily starts after E6")
	var daily := s.duplicate_state()
	SectLife.advance(daily, int(daily.sect.life.next_story_second) - int(daily.sect.life.tenure_seconds), true)
	check(daily.sect.life.pending_story.template_id in SectLife.DAILY, "daily only after chapters")
	for i in range(3):
		var reward := SectLife.frozen(SectLife.DAILY[i], "test", 1, 0, true)
		check(reward.options.A.affinity.has(SectLife.NPCS[[0,2,1][i]]), "daily correct NPC %d" % i)
	for npc in daily.sect.life.npcs.values(): npc.affinity = 100
	var p: Dictionary = daily.sect.life.pending_story
	SectLife.resolve(content, daily, {"instance_id": p.instance_id, "option_id":"B"})
	check(daily.sect.life.npcs.values().all(func(n: Dictionary) -> bool: return n.affinity == 100), "affinity clamped")
	# Six chapters reserve the whole epoch even when all are declined.
	var cap := fixture()
	SectLife.advance(cap, 1, true)
	for i in range(6):
		SectLife.advance(cap, maxi(1, maxi(SectLife.AGES[i], int(cap.sect.life.next_story_second)) - int(cap.sect.life.tenure_seconds)), true)
		SectLife.resolve(content, cap, {"instance_id":cap.sect.life.pending_story.instance_id, "option_id":"decline"})
	check(cap.sect.life.story_reserved == 12, "declining never refunds reservation")
	cap.sect.life.next_story_second = cap.sect.life.tenure_seconds
	SectLife.offer(cap)
	check(not cap.sect.life.pending_story.paid and cap.sect.life.pending_story.options.A.contribution == 0, "exhausted epoch freezes zero currency")
	var frozen: Dictionary = cap.sect.life.pending_story.duplicate(true)
	SectLife.advance(cap, 1000, true)
	check(SectLifeSave.same(frozen, cap.sect.life.pending_story), "epoch change cannot replace promised reward")
	var exhausted := fixture()
	exhausted.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(), exhausted) - 1
	TimeAdvancer.advance(exhausted, content, 10)
	check(exhausted.sect.life.tenure_seconds == 1 and exhausted.sect.life.pending_story == null, "last accepted tick ages without offer")
	var limit := fixture()
	limit.sect.life.story_serial = SectLife.LIMIT
	SectLife.advance(limit, 5, true)
	check(limit.sect.life.pending_story == null and limit.sect.life.story_serial == SectLife.LIMIT, "serial never wraps")
	var meta: Dictionary = s.sect.life.memories.duplicate()
	s.reincarnation_count += 1
	SectSystem.on_reincarnate(s)
	check(s.sect.life.tenure_seconds == 0 and s.sect.life.pending_story == null and s.sect.life.npcs.is_empty(), "rebirth clears mortal stories")
	check(SectLifeSave.same(meta, s.sect.life.memories), "rebirth retains memories")
	SectSystem.join_sect(s, "太虛天闕")
	check(s.sect.life.npcs.size() == 3 and s.sect.life.chapter_mask == 0, "rejoin starts fresh NPCs")
	check(SectSaveContract.validate(s.sect_version, s.sect).is_empty(), "rejoined save valid")
	round_checks()
	print("SECT-LIFE-CORE ", checks, " checks failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func round_checks() -> void:
	for sid in SectIdentity.NAMES:
		var s := fixture()
		SectIdentity.write(s.sect, sid)
		SectLineage.observe(s)
		s.sect.life = SectLife.initial(s)
		SectLife.advance(s, 10000, true)
		for batch in 4:
			var seen := {}
			for slot in 3:
				SectLife.advance(s, 1, true)
				var p: Dictionary = s.sect.life.pending_story
				var daily := SectLife.table(sid, "daily").find(p.template_id)
				var index := SectLife.table(sid, "chapters").find(p.template_id)
				var npc: String = SectLife.table(sid, "npcs")[[0,2,1][index % 3 if index >= 0 else daily]]
				check(not seen.has(npc), "each fellow once " + sid + str(batch) + str(slot))
				seen[npc] = true
				var held: Dictionary = p.duplicate(true)
				SectLife.advance(s, 1000, true)
				check(SectLifeSave.same(held, s.sect.life.pending_story), "late pending never replaced")
				check(SectLife.resolve(content, s, {"instance_id":p.instance_id,"option_id":"decline" if slot == 2 else "A"}).ok, "round answer or decline")
				check(SectLifeSave.validate(s.sect).is_empty(), "round save valid")
			check(s.sect.life.visit_round.mask == 7 and s.sect.life.next_story_second == s.sect.life.tenure_seconds + 180, "cooldown starts on last answer")
			var paused: Dictionary = s.sect.life.duplicate(true)
			SectLife.advance(s, 0, true)
			check(SectLifeSave.same(paused, s.sect.life), "zero accepted seconds pauses cooldown")
			SectLife.offer(s)
			SectLife.advance(s, 179, true)
			check(s.sect.life.pending_story == null, "no fourth or early refresh")
			var whole := s.duplicate_state()
			var split := s.duplicate_state()
			var offline := s.duplicate_state()
			TimeAdvancer.advance(whole, content, 2)
			for i in 2: TimeAdvancer.advance(split, content, 1)
			OfflineClosedForm.advance(offline, content, 2)
			check(SectLifeSave.same(whole.sect.life, split.sect.life) and SectLifeSave.same(whole.sect.life, offline.sect.life), "cooldown boundary whole split offline exact")
			SectLife.advance(s, 1, true)
			check(s.sect.life.pending_story != null and s.sect.life.visit_round.mask == 0, "exact deadline opens one slot")
			var held: Dictionary = s.sect.life.pending_story.duplicate(true)
			SectLife.advance(s, 86400, true)
			check(SectLifeSave.same(held, s.sect.life.pending_story) and s.sect.life.visit_round.mask == 0, "long offline creates no round debt")
		var dead := s.duplicate_state()
		dead.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(), dead)
		var before := dead.to_snapshot_dict()
		TimeAdvancer.advance(dead, content, 10)
		check(not SectLife.resolve(content, dead, {"instance_id":dead.sect.life.pending_story.instance_id,"option_id":"A"}).ok and SectLifeSave.same(before, dead.to_snapshot_dict()), "death read-only")
		SectLife.reset_life(s)
		check(s.sect.life.visit_round.mask == 0 and s.sect.life.next_story_second == 0, "rebirth clears round")
