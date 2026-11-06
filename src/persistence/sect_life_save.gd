class_name SectLifeSave
extends RefCounted
## Strict bounded revision-1 records; frozen rewards are recomputed, never trusted.
static func keys(value: Variant, expected: Array) -> bool:
	if not value is Dictionary or value.size() != expected.size(): return false
	for key in expected:
		if not value.has(key): return false
	return true

static func same(a: Variant, b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a)) == JSON.parse_string(JSON.stringify(b))

static func validate(sect: Dictionary) -> String:
	var l: Variant = sect.get("life")
	var fields := ["version", "content_version", "life_seq", "sect_id", "tenure_seconds", "npcs", "chapter_mask", "choice_flags", "story_serial", "pending_story", "next_story_second", "reward_epoch", "story_reserved", "rng", "recent", "memories", "best_ranks"]
	if l is Dictionary and (l.get("version") == 2 or l.get("version") == 3 or l.get("version") == 4): fields.append("competition")
	if l is Dictionary and l.get("version") == 4: fields.append("visit_round")
	if not keys(l, fields): return "SECT_LIFE_FIELDS"
	if not SectSaveContract.integer(l.version,4) or int(l.version) not in [1,2,3,4] or l.content_version != (2 if int(l.version) >= 3 else 1): return "SECT_LIFE_VERSION"
	if l.version >= 2:
		var error := SectTournament.validate(l)
		if not error.is_empty(): return error
	if JSON.stringify(l).to_utf8_buffer().size() > 8192: return "SECT_LIFE_SIZE"
	for key in ["life_seq", "tenure_seconds", "story_serial", "next_story_second", "reward_epoch"]:
		if not SectSaveContract.integer(l[key]): return "SECT_LIFE_COUNTER"
	if not SectSaveContract.integer(l.story_reserved, 12) or int(l.story_reserved) % 2 != 0: return "SECT_LIFE_RESERVED"
	if int(l.reward_epoch) != int(l.tenure_seconds) / 600: return "SECT_LIFE_EPOCH"
	var id: Variant = l.sect_id
	if not id is String or (id != "" and not SectIdentity.NAMES.has(id)): return "SECT_LIFE_ID"
	if id != (sect.get("sect_id", "") if sect.get("unlocked", false) else ""): return "SECT_LIFE_MEMBERSHIP"
	if not keys(l.rng, ["version", "story", "tournament"]) or l.rng.version != 1: return "SECT_LIFE_RNG"
	for stream in ["story", "tournament"]:
		if not SectSaveContract.integer(l.rng[stream], 4294967295): return "SECT_LIFE_RNG"
	var npcs := SectLife.table(id, "npcs", int(l.content_version))
	var chapters := SectLife.table(id, "chapters", int(l.content_version))
	var daily := SectLife.table(id, "daily", int(l.content_version))
	if not keys(l.npcs, npcs): return "SECT_LIFE_NPCS"
	for npc in l.npcs.values():
		if not keys(npc, ["affinity", "met"]) or not SectSaveContract.integer(npc.affinity, 100) or not npc.met is bool: return "SECT_LIFE_AFFINITY"
	if not SectSaveContract.integer(l.chapter_mask, 63) or int(l.chapter_mask) not in [0, 1, 3, 7, 15, 31, 63]: return "SECT_LIFE_CHAPTER"
	if chapters.is_empty() and (l.chapter_mask != 0 or l.pending_story != null or l.story_serial != 0): return "SECT_LIFE_CONTENT_SECT"
	if not l.choice_flags is Dictionary: return "SECT_LIFE_FLAGS"
	var count := 0
	for i in range(chapters.size()):
		var key: String = SectLife.table(id, "flag_keys")[i]
		if int(l.chapter_mask) & (1 << i):
			count += 1
			if l.choice_flags.get(key) not in SectLife.table(id, "flag_values")[i] + ["decline"]: return "SECT_LIFE_FLAGS"
	if l.choice_flags.size() != count or int(l.story_serial) < count: return "SECT_LIFE_FLAGS"
	for field in ["memories", "best_ranks"]:
		if not l[field] is Dictionary or l[field].size() > 5: return "SECT_LIFE_META"
		for sect_id in l[field]:
			if not SectIdentity.NAMES.has(sect_id) or not SectSaveContract.integer(l[field][sect_id], 63 if field == "memories" else 8): return "SECT_LIFE_META"
	if int(l.memories.get(id, 0)) & int(l.chapter_mask) != int(l.chapter_mask): return "SECT_LIFE_MEMORY"
	if not l.recent is Array or l.recent.size() > 4: return "SECT_LIFE_RECENT"
	for r in l.recent:
		if not keys(r, ["id", "option", "tick"]) or r.id not in chapters + daily or r.option not in ["A", "B", "decline"] or not SectSaveContract.integer(r.tick, int(l.tenure_seconds)): return "SECT_LIFE_RECENT"
	if int(l.version) >= 4:
		if not keys(l.visit_round, ["version", "mask"]) or l.visit_round.version != 1 or not SectSaveContract.integer(l.visit_round.mask, 7): return "SECT_ROUND_FIELDS"
		var mask := int(l.visit_round.mask)
		if count < 6:
			var expected_mask := (1 << (count % 3)) - 1
			if count == 3 and mask == 7 and l.pending_story == null: expected_mask = 7
			if mask != expected_mask: return "SECT_ROUND_ORDER"
		if mask != 7 and int(l.next_story_second) != 0: return "SECT_ROUND_TIME"
		if mask == 7 and (l.pending_story != null or int(l.next_story_second) < SectLife.ROUND_COOLDOWN or int(l.next_story_second) > mini(SectLife.LIMIT, int(l.tenure_seconds) + SectLife.ROUND_COOLDOWN)): return "SECT_ROUND_TIME"
	var p: Variant = l.pending_story
	if p != null:
		if not keys(p, ["version", "template_id", "instance_id", "tick", "epoch", "paid", "options"]): return "SECT_LIFE_PENDING"
		if p.template_id not in chapters + daily or not p.paid is bool or not SectSaveContract.integer(p.tick, int(l.tenure_seconds)) or not SectSaveContract.integer(p.epoch): return "SECT_LIFE_PENDING"
		if chapters.is_empty() or p.epoch != int(p.tick) / 600 or int(l.story_serial) == 0: return "SECT_LIFE_PENDING"
		var chapter := chapters.find(p.template_id)
		if (chapter >= 0 and (chapter != count or int(p.tick) < SectLife.AGES[chapter])) or (chapter < 0 and count != 6): return "SECT_LIFE_PENDING_ORDER"
		if p.paid and p.epoch == l.reward_epoch and int(l.story_reserved) < 2: return "SECT_LIFE_RESERVED"
		if int(l.version) >= 4:
			var slot := chapter % 3 if chapter >= 0 else daily.find(p.template_id)
			if int(l.visit_round.mask) & (1 << slot): return "SECT_ROUND_REPEAT"
		var expected := SectLife.frozen(p.template_id, "%d:%s:%d" % [l.life_seq, id, l.story_serial], int(p.tick), int(p.epoch), p.paid)
		if not same(p, expected): return "SECT_LIFE_FROZEN"
	return ""
