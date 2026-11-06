class_name SectLife
extends RefCounted
## Versioned story rules. No wall clock, presentation RNG or expedition rewards.
const VERSION := 1
const SECT_VERSION := 7
const ROUND_RULES := "core-flow-30-sect-life-visit-round-1"
const ROUND_TAG := "+sect-life-visit-round-1"
const ROUND_COOLDOWN := 180
const EXPANSION_RULES := "core-flow-29-sect-life-content-2"
const EXPANSION_TAG := "+sect-life-content-2"
const RULES_VERSION := "core-flow-27-sect-life-1"
const CONTENT_TAG := "+sect-life-1"
const LIMIT := 2147483647
const NPCS := ["tx_shen_zhaowei", "tx_lu_jingxing", "tx_tang_xihe"]
const CHAPTERS := ["tx_book_first", "tx_cloud_first", "tx_debate_first", "tx_book_return", "tx_cloud_return", "tx_debate_return"]
const AGES := [0, 60, 120, 240, 360, 480]
const DAILY := ["tx_daily_book", "tx_daily_cloud", "tx_daily_debate"]
const FLAG_KEYS := ["book", "cloud", "debate", "book_end", "cloud_end", "debate_end"]
const FLAG_VALUES := [["collate", "order"], ["measure", "review"], ["steady", "counter"], ["record", "voice"], ["warn", "watch"], ["verify", "share"]]

static func active(state: GameState) -> bool:
	return state.sect_version in [4, 5, 6, SECT_VERSION]

static func initial(state: GameState, meta: Dictionary = {}) -> Dictionary:
	var id := String(state.sect.get("sect_id", "")) if state.sect.get("unlocked", false) else ""
	var seed_text := str(state.tribulation_seed) if state.tribulation_seed >= 0 else String(state.sect.get("core_save", {}).get("source_hash", "legacy-sect-life"))
	var prefix := seed_text + ":sect-life:1:%d:%s:" % [state.reincarnation_count, id]
	var npcs := {}
	if not id.is_empty():
		for npc in table(id, "npcs", 2 if state.sect_version >= 6 else 1): npcs[npc] = {"affinity": 0, "met": false}
	var life := {"version": (4 if state.sect_version >= 7 else 3 if state.sect_version >= 6 else 2), "content_version": (2 if state.sect_version >= 6 else 1), "life_seq": state.reincarnation_count, "sect_id": id,
		"tenure_seconds": 0, "npcs": npcs, "chapter_mask": 0, "choice_flags": {}, "story_serial": 0,
		"pending_story": null, "next_story_second": 0, "reward_epoch": 0, "story_reserved": 0,
		"rng": {"version": 1, "story": SeededRandom.from_seed(prefix + "story").state, "tournament": SeededRandom.from_seed(prefix + "tournament").state},
		"recent": [], "memories": meta.get("memories", {}).duplicate(true), "best_ranks": meta.get("best_ranks", {}).duplicate(true), "competition": SectTournament.initial()}
	if state.sect_version >= 7: life.visit_round = {"version": 1, "mask": 0}
	return life

static func reset_life(state: GameState) -> void:
	if active(state):
		state.sect.life = initial(state, state.sect.get("life", {}))
		if state.sect_version == 4:
			state.sect.life.version = 1
			state.sect.life.erase("competition")

static func prepare(source: GameState) -> GameState:
	var candidate := source.duplicate_state()
	candidate.sect_version = SECT_VERSION
	if active(source):
		candidate.sect.life.version = 4
		candidate.sect.life.content_version = 2
		if not candidate.sect.life.has("competition"): candidate.sect.life.competition = SectTournament.initial()
		for npc in table(String(candidate.sect.life.sect_id), "npcs"):
			if not candidate.sect.life.npcs.has(npc): candidate.sect.life.npcs[npc] = {"affinity": 0, "met": false}
		# Retain old frozen offers. A completed old batch starts a fresh wait;
		# never infer or replay missed daily rounds from elapsed tenure.
		if source.sect_version < 7:
			var l: Dictionary = candidate.sect.life
			var count := 0
			for i in 6:
				if int(l.chapter_mask) & (1 << i): count += 1
			var mask := (1 << (count % 3)) - 1
			if count > 0 and count % 3 == 0 and l.pending_story == null:
				mask = 7
				l.next_story_second = mini(LIMIT, int(l.tenure_seconds) + ROUND_COOLDOWN)
			elif l.pending_story != null or count < 6: l.next_story_second = 0
			l.visit_round = {"version": 1, "mask": mask}
	else: candidate.sect.life = initial(candidate)
	if candidate.sect.get("unlocked", false) and not candidate.sect.has("entry"):
		candidate.sect.entry = SectEntry.initial(true, candidate.sect.get("active_expedition") is Dictionary)
	candidate.revision += 1
	return candidate

static func available(state: GameState) -> bool:
	return active(state) and state.sect.get("unlocked", false) and not table(String(state.sect.life.sect_id), "npcs", int(state.sect.life.content_version)).is_empty()

static func advance(state: GameState, seconds: int, alive: bool) -> void:
	if seconds <= 0 or not active(state) or not state.sect.get("unlocked", false): return
	var l: Dictionary = state.sect.life
	l.tenure_seconds = mini(LIMIT, int(l.tenure_seconds) + seconds)
	var epoch := int(l.tenure_seconds) / 600
	if epoch != int(l.reward_epoch):
		l.reward_epoch = epoch
		l.story_reserved = 0
	if alive:
		offer(state)
		SectTournament.offer(state)

static func offer(state: GameState) -> void:
	if not available(state): return
	var l: Dictionary = state.sect.life
	if l.pending_story != null or int(l.story_serial) == LIMIT or int(l.tenure_seconds) == LIMIT: return
	var index := 0
	while index < 6 and int(l.chapter_mask) & (1 << index): index += 1
	var id := ""
	# Bits follow chapter/daily table slots, whose three entries map to distinct NPCs.
	var rounds := int(l.version) >= 4
	if rounds and int(l.visit_round.mask) == 7:
		if int(l.tenure_seconds) < int(l.next_story_second): return
		l.visit_round.mask = 0
		l.next_story_second = 0
	if index < 6:
		if int(l.tenure_seconds) < AGES[index]: return
		var entry := SectEntry.receipt(state)
		if index == 0 and not (entry.skip or (entry.intro_seen and entry.first_dispatch)): return
		id = table(String(l.sect_id), "chapters")[index]
	else:
		if int(l.tenure_seconds) < int(l.next_story_second): return
		var rng := SeededRandom.from_state(int(l.rng.story))
		var candidates: Array = []
		for i in 3:
			if not rounds or not (int(l.visit_round.mask) & (1 << i)): candidates.append(i)
		id = table(String(l.sect_id), "daily")[candidates[rng.int_range(0, candidates.size() - 1)]]
		l.rng.story = rng.state
	var paid := int(l.story_reserved) <= 10
	if paid: l.story_reserved += 2
	l.story_serial += 1
	l.pending_story = frozen(id, "%d:%s:%d" % [l.life_seq, l.sect_id, l.story_serial], int(l.tenure_seconds), int(l.reward_epoch), paid)

static func frozen(id: String, instance: String, tick: int, epoch: int, paid: bool) -> Dictionary:
	var sect := template_sect(id)
	var npcs := table(sect, "npcs")
	var chapter := table(sect, "chapters").find(id)
	var daily := table(sect, "daily").find(id)
	if chapter < 0 and daily < 0: return {}
	var npc: String = npcs[[0, 2, 1, 0, 2, 1][chapter]] if chapter >= 0 else npcs[[0, 2, 1][daily]]
	var options := {}
	for option in ["A", "B", "decline"]:
		var contribution := 0
		var affinity := {}
		if option != "decline":
			contribution = (2 if option == "A" else 0) if daily >= 0 else (1 if (chapter == 1 and option == "A") or (chapter != 1 and option == "B") else 2)
			affinity[npc] = (1 if option == "A" else 3) if daily >= 0 else (2 if contribution == 2 else 4)
			if chapter == 1 and option == "B": affinity[npcs[1]] = 1
		options[option] = {"contribution": contribution if paid else 0, "affinity": affinity}
	return {"version": 1, "template_id": id, "instance_id": instance, "tick": tick, "epoch": epoch, "paid": paid, "options": options}

static func resolve(content: GameContent, state: GameState, payload: Dictionary) -> Dictionary:
	if not available(state): return {"ok": false, "error": "SECT_LIFE_UNAVAILABLE"}
	if Lifespan.is_exhausted(state.total_elapsed_seconds, Lifespan.for_state(content.era_lifespan_entries(), state)): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	var l: Dictionary = state.sect.life
	var p: Variant = l.pending_story
	if p == null or payload.get("instance_id") != p.instance_id: return {"ok": false, "error": "SECT_STORY_INSTANCE"}
	var option: Variant = payload.get("option_id")
	if not option is String or not p.options.has(option): return {"ok": false, "error": "SECT_STORY_OPTION"}
	var reward: Dictionary = p.options[option]
	var contribution := AmountCompat.try_parse(String(state.sect.get("contribution", "0")))
	if not contribution.ok: return {"ok": false, "error": "SECT_CONTRIBUTION"}
	state.sect.contribution = contribution.value.add(AmountCompat.from_number(reward.contribution)).serialize()
	for npc in reward.affinity:
		l.npcs[npc].affinity = mini(100, int(l.npcs[npc].affinity) + int(reward.affinity[npc]))
		l.npcs[npc].met = true
	var chapter := table(String(l.sect_id), "chapters").find(p.template_id)
	if chapter >= 0:
		l.chapter_mask = int(l.chapter_mask) | (1 << chapter)
		l.choice_flags[table(String(l.sect_id), "flag_keys")[chapter]] = "decline" if option == "decline" else table(String(l.sect_id), "flag_values")[chapter][0 if option == "A" else 1]
		l.memories[l.sect_id] = int(l.memories.get(l.sect_id, 0)) | (1 << chapter)
	l.recent.append({"id": p.template_id, "option": option, "tick": l.tenure_seconds})
	if l.recent.size() > 4: l.recent.pop_front()
	l.pending_story = null
	if int(l.version) >= 4:
		var slot := chapter % 3 if chapter >= 0 else table(String(l.sect_id), "daily").find(p.template_id)
		l.visit_round.mask = int(l.visit_round.mask) | (1 << slot)
		if int(l.visit_round.mask) == 7: l.next_story_second = mini(LIMIT, int(l.tenure_seconds) + ROUND_COOLDOWN)
	elif int(l.chapter_mask) == 63:
		var rng := SeededRandom.from_state(int(l.rng.story))
		l.next_story_second = mini(LIMIT, int(l.tenure_seconds) + [180, 240, 300][rng.int_range(0, 2)])
		l.rng.story = rng.state
	return {"ok": true, "events": [{"kind": "sect_story_resolved", "template_id": p.template_id, "option_id": option, "contribution": reward.contribution}], "changed_ids": ["sect"]}

static func view(state: GameState) -> Dictionary:
	if not active(state): return {"available": false}
	var life: Variant = state.sect.get("life", null)
	if not (life is Dictionary) or life.is_empty(): return {"available": false}
	var result: Dictionary = life.duplicate(true)
	result.available = available(state)
	if result.pending_story != null:
		result.story_text = SectLifeContent.read(result.pending_story.template_id, result.choice_flags)
	return result

static func table(sect: String, field: String, revision: int = 2) -> Array:
	if sect == "taixu_sect":
		return {"npcs": NPCS, "chapters": CHAPTERS, "daily": DAILY, "flag_keys": FLAG_KEYS, "flag_values": FLAG_VALUES, "names": ["沈照微", "陸景行", "唐溪禾"], "greetings": ["經卷有缺頁，也不妨先讀眼前這一行。", "你若不同意，便拿一個能驗的法子來。", "雲先變了，鐘聲卻還沒到，你也看見了？"]}.get(field, [])
	if revision != 2: return []
	return SectLifeCatalog.SECTS.get(sect, {}).get(field, [])

static func template_sect(id: String) -> String:
	if id in CHAPTERS + DAILY: return "taixu_sect"
	for sect in SectLifeCatalog.SECTS:
		if id in table(sect, "chapters") + table(sect, "daily"): return sect
	return ""
