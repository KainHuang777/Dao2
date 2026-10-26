class_name BeastSaveContract
extends RefCounted
## Strict historical and v1 payload bounds. Validation never repairs progress.

static func validate(version: Variant, beasts: Dictionary, souls: Dictionary, talents: Dictionary) -> String:
	if not SectSaveContract.integer(version, BeastSystem.VERSION): return "BEAST_VERSION"
	if JSON.stringify([beasts, souls, talents]).to_utf8_buffer().size() > 65536: return "BEAST_SIZE"
	for key in beasts:
		if key not in ["active", "cooldown_remaining"]: return "BEAST_FIELD"
	var active: Variant = beasts.get("active", {})
	if not active is Dictionary: return "BEAST_ACTIVE_TYPE"
	if not active.is_empty():
		if active.size() != 3 or not active.has_all(["id", "stage", "exp"]): return "BEAST_ACTIVE_FIELDS"
		if not active.id is String or not BeastSystem.BEAST_CONFIGS.has(active.id): return "BEAST_ID"
		if int(version) == 0 and active.id in BeastSystem.P2_IDS: return "BEAST_V0_NEW_ID"
		if not SectSaveContract.integer(active.exp): return "BEAST_EXP"
		var expected := "egg" if active.exp < 100 else "young" if active.exp < 500 else "growing" if active.exp < 1000 else "mature"
		if active.stage != expected: return "BEAST_STAGE"
	var cd: Variant = beasts.get("cooldown_remaining", 0)
	if not SectSaveContract.number(cd) or float(cd) > 300 or (active.is_empty() and float(cd) != 0): return "BEAST_COOLDOWN"
	for id in souls:
		if not BeastSystem.BEAST_CONFIGS.has(id): return "BEAST_SOUL_ID"
		if int(version) == 0 and id in BeastSystem.P2_IDS: return "BEAST_V0_NEW_ID"
		if not SectSaveContract.integer(souls[id]): return "BEAST_SOUL_VALUE"
	for id in talents:
		if not BeastSystem.BEAST_TALENTS.has(id): return "BEAST_TALENT_ID"
		var t: Dictionary = BeastSystem.BEAST_TALENTS[id]
		if int(version) == 0 and t.beast_id in BeastSystem.P2_IDS: return "BEAST_V0_NEW_ID"
		if not SectSaveContract.integer(talents[id], 1): return "BEAST_TALENT_VALUE"
		if int(talents[id]) == 0 or int(t.tier) == 1: continue
		var previous := false
		for prev_id in BeastSystem.BEAST_TALENTS:
			var prev: Dictionary = BeastSystem.BEAST_TALENTS[prev_id]
			if prev.beast_id == t.beast_id and int(prev.tier) == int(t.tier) - 1 and talents.get(prev_id, 0) == 1: previous = true
		if not previous: return "BEAST_TALENT_PREREQUISITE"
	return ""
