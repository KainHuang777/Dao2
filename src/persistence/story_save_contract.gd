class_name StorySaveContract
extends RefCounted

static func validate(state: GameState) -> String:
	if state.story_version < 0 or state.story_version > StoryProgress.VERSION: return "STORY_VERSION"
	var fortune_error := rng_error(state.fortune, state.story_version)
	if not fortune_error.is_empty(): return fortune_error
	if JSON.stringify(state.achievements).to_utf8_buffer().size() > 16384: return "STORY_ACHIEVEMENTS_SIZE"
	for field in ["unlocked", "claimed", "stats"]:
		if state.achievements.has(field) and not state.achievements[field] is Dictionary: return "STORY_ACHIEVEMENT_TYPE"
	for id in state.achievements.get("claimed", {}):
		if str(id).begins_with("p1_") and (not AchievementSystem.P1_DEFINITIONS.has(id) or not state.achievements.claimed[id] is bool): return "STORY_CLAIM_FLAG"
	for id in state.achievements.get("unlocked", {}):
		if str(id).begins_with("p1_") and (not AchievementSystem.P1_DEFINITIONS.has(id) or not SectSaveContract.number(state.achievements.unlocked[id])): return "STORY_UNLOCK_FLAG"
	var story: Variant = state.achievements.get("story", {})
	if not story is Dictionary: return "STORY_TYPE"
	if state.story_version == 0:
		if not story.is_empty(): return "STORY_V0_FACTS"
		for key in ["unlocked", "claimed"]:
			for id in state.achievements.get(key, {}):
				if str(id).begins_with("p1_"): return "STORY_V0_NEW_ID"
		if str(state.fortune.get("pending_encounter", {}).get("id", "")).begins_with("enc_p1_"): return "STORY_V0_PENDING"
		return ""
	# Empty is valid only for a new unobserved state; it cannot authorize behavior.
	if story.is_empty():
		for field in ["unlocked", "claimed"]:
			for id in state.achievements.get(field, {}):
				if str(id).begins_with("p1_"): return "STORY_MISSING_FACTS"
		return ""
	if JSON.stringify(story).to_utf8_buffer().size() > 4096: return "STORY_SIZE"
	if not LifeLedger._keys(story, ["version", "started_life_id", "started_age_seconds", "current_life_id", "lifetime", "current"]): return "STORY_KEYS"
	if not SectSaveContract.integer(story.get("version"), 1) or story.version != 1 or not SectSaveContract.integer(story.get("started_life_id"), state.reincarnation_count + 1) or int(story.started_life_id) < 1: return "STORY_START_LIFE"
	if not SectSaveContract.number(story.get("started_age_seconds")): return "STORY_START_AGE"
	if not SectSaveContract.integer(story.get("current_life_id")) or int(story.current_life_id) != state.reincarnation_count + 1: return "STORY_CURRENT_LIFE"
	for field in ["lifetime", "current"]:
		var facts: Variant = story.get(field)
		var bools: Array = StoryProgress.LIFETIME if field == "lifetime" else StoryProgress.CURRENT
		if not facts is Dictionary or not LifeLedger._keys(facts, bools + StoryProgress.MASKS): return "STORY_FACT_KEYS"
		for key in bools:
			if not facts.get(key) is bool: return "STORY_FACT_BOOL"
		for key in StoryProgress.MASKS:
			if not SectSaveContract.integer(facts.get(key), 15): return "STORY_MASK"
	var l: Dictionary = story.lifetime
	var c: Dictionary = story.current
	for key in StoryProgress.CURRENT:
		if c[key] and not l[key]: return "STORY_FACT_SUBSET"
	for key in StoryProgress.MASKS:
		if int(c[key]) | int(l[key]) != int(l[key]): return "STORY_MASK_SUBSET"
	return validate_pending(state.fortune.get("pending_encounter", {}))

static func definition_error(def: Dictionary) -> String:
	if not LifeLedger._keys(def, ["id", "title", "desc", "min_era", "requires", "art", "options", "weight", "content_batch", "definition_version", "weather_bias", "shichen_bias", "realm_bias"]): return "STORY_DEFINITION_KEYS"
	if def.get("content_batch") != "content-p1-story" or def.get("definition_version") != 1: return "STORY_DEFINITION_VERSION"
	if not str(def.get("id", "")).begins_with("enc_p1_"): return "STORY_DEFINITION_ID"
	if not SectSaveContract.integer(def.get("min_era"), 3) or int(def.min_era) < 1 or def.get("weight") != 60: return "STORY_DEFINITION_WEIGHT_ERA"
	for key in ["weather_bias", "shichen_bias", "realm_bias"]:
		if def.get(key) != "": return "STORY_DEFINITION_BIAS"
	for key in ["title", "desc"]:
		if not SectSaveContract.text(def.get(key), 2048) or String(def[key]).is_empty(): return "STORY_DEFINITION_TEXT"
	if def.get("art") not in ["spring", "traveler", "industry", "sect", "beast", "ruins"]: return "STORY_DEFINITION_ART"
	if not def.get("requires") is Array or def.requires.size() > StoryProgress.REQUIRES.size(): return "STORY_REQUIRES"
	var seen := {}
	for key in def.requires:
		if key not in StoryProgress.REQUIRES or seen.has(key): return "STORY_REQUIRES"
		seen[key] = true
	if not def.get("options") is Array or def.options.size() != 3: return "STORY_OPTIONS"
	for option in def.options:
		if not option is Dictionary or not LifeLedger._keys(option, ["text", "costs", "rewards"]): return "STORY_OPTION_KEYS"
		if not SectSaveContract.text(option.get("text"), 256) or String(option.text).is_empty(): return "STORY_OPTION_TEXT"
		if not amounts(option.get("costs"), Production.BASIC_RESOURCE_KEYS): return "STORY_COSTS"
		var reward: Variant = option.get("rewards")
		if not reward is Dictionary: return "STORY_REWARDS"
		for key in reward:
			if key not in ["resources", "pills", "training_seconds", "log_text"]: return "STORY_REWARD_KEY"
		if not amounts(reward.get("resources", {}), Production.BASIC_RESOURCE_KEYS) or not amounts(reward.get("pills", {}), AlchemySystem.P1_IDS): return "STORY_REWARD_AMOUNTS"
		if not SectSaveContract.integer(reward.get("training_seconds", 0), 180): return "STORY_TRAINING"
		if not SectSaveContract.text(reward.get("log_text"), 2048) or String(reward.log_text).is_empty(): return "STORY_LOG"
	if not def.options[2].costs.is_empty() or def.options[2].rewards.size() != 1: return "STORY_FREE_OPTION"
	return ""

static func amounts(v: Variant, keys: Array) -> bool:
	if not v is Dictionary: return false
	for key in v:
		if key not in keys or not SectSaveContract.integer(v[key], 1000000) or int(v[key]) < 1: return false
	return true

static func digest(def: Dictionary) -> String:
	return JSON.stringify(def, "", true).sha256_text()

static func freeze(def: Dictionary, state: GameState) -> Dictionary:
	var pending := def.duplicate(true)
	pending.definition_digest = digest(def)
	pending.qualifications = StoryProgress.qualifications(state)
	pending.generation_era = state.era_id
	pending.generation_realm = state.current_realm
	return pending

static func validate_pending(pending: Dictionary) -> String:
	if pending.is_empty(): return ""
	var is_new := str(pending.get("id", "")).begins_with("enc_p1_")
	if not is_new:
		return "STORY_PENDING_BATCH" if pending.has("content_batch") else ""
	if JSON.stringify(pending).to_utf8_buffer().size() > 12288: return "STORY_PENDING_SIZE"
	var definition := {}
	for item in FortuneSystem.get_encounters():
		if item.id == pending.get("id"): definition = item; break
	if definition.is_empty(): return "STORY_PENDING_UNKNOWN"
	var copy := pending.duplicate(true)
	for key in ["instance_id", "definition_digest", "qualifications", "generation_era", "generation_realm"]: copy.erase(key)
	if digest(copy) != digest(definition) or pending.get("definition_digest") != digest(definition): return "STORY_PENDING_DIGEST"
	if not LifeLedger._hash(pending.get("instance_id")): return "STORY_PENDING_INSTANCE"
	if not SectSaveContract.integer(pending.get("generation_era"), 12) or int(pending.generation_era) < int(definition.min_era) or pending.get("generation_realm") != "realm_human": return "STORY_PENDING_ORIGIN"
	var q: Variant = pending.get("qualifications")
	if not q is Dictionary or not LifeLedger._keys(q, StoryProgress.REQUIRES): return "STORY_PENDING_QUALIFICATIONS"
	for key in q:
		if not q[key] is bool: return "STORY_PENDING_QUALIFICATIONS"
	for key in definition.requires:
		if not q[key]: return "STORY_PENDING_QUALIFICATIONS"
	return ""

static func rng_error(fortune: Dictionary, story_version: int) -> String:
	if not fortune.has("rng_version") and not fortune.has("rng_state"): return ""
	if story_version == 0: return "STORY_V0_RNG"
	if not SectSaveContract.integer(fortune.get("rng_version"), 1) or fortune.rng_version != 1: return "STORY_RNG_VERSION"
	if not SectSaveContract.integer(fortune.get("rng_state"), 4294967295): return "STORY_RNG_STATE"
	return ""

static func normalize(state: GameState) -> void:
	var story: Dictionary = state.achievements.get("story", {})
	if not story.is_empty():
		for key in ["version", "started_life_id", "current_life_id"]: story[key] = int(story[key])
		story.started_age_seconds = float(story.started_age_seconds)
		for field in ["lifetime", "current"]:
			for key in StoryProgress.MASKS: story[field][key] = int(story[field][key])
	if state.fortune.has("rng_version"):
		state.fortune.rng_version = int(state.fortune.rng_version)
		state.fortune.rng_state = int(state.fortune.rng_state)
	var pending: Dictionary = state.fortune.get("pending_encounter", {})
	if pending.get("content_batch") == "content-p1-story": pending.generation_era = int(pending.generation_era)
