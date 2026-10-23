class_name SectSaveContract
extends RefCounted
## Versioned, bounded religious progress and frozen expedition payloads.

static func integer(v: Variant, maximum: int = 2147483647) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and float(v) >= 0 and float(v) <= maximum

static func number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) >= 0

static func text(v: Variant, cap: int) -> bool:
	return v is String and v.to_utf8_buffer().size() <= cap

static func validate(version: Variant, sect: Dictionary) -> String:
	if not integer(version, SectSystem.VERSION): return "SECT_VERSION"
	if JSON.stringify(sect).to_utf8_buffer().size() > 32768: return "SECT_SIZE"
	if sect.is_empty(): return ""
	if sect.has("unlocked") and not (sect.unlocked is bool): return "SECT_MEMBERSHIP"
	for key in ["sect_id", "sect_name"]:
		if sect.has(key) and not text(sect[key], 128): return "SECT_NAME"
	if not integer(sect.get("sect_level", 1)): return "SECT_LEVEL"
	if not integer(sect.get("task_counter", 0)): return "SECT_COUNTER"
	if not number(sect.get("next_refresh_seconds", 0)): return "SECT_REFRESH"
	var contribution: Variant = sect.get("contribution", "0")
	if not text(contribution, 256): return "SECT_CONTRIBUTION"
	var parsed := AmountCompat.try_parse(contribution)
	if not parsed.ok or parsed.value.sign < 0: return "SECT_CONTRIBUTION"
	for field in ["techniques", "market_purchases"]:
		var entries: Variant = sect.get(field, {})
		if not (entries is Dictionary): return "SECT_FIELD:" + field
		var definitions: Dictionary = SectSystem.TECHNIQUES if field == "techniques" else SectSystem.MARKET_ITEMS
		for id in entries:
			if not definitions.has(id): return "SECT_UNKNOWN_ID:" + str(id)
			if int(version) == 0 and definitions[id].has("min_era"): return "SECT_V0_NEW_ID"
			var limit := int(definitions[id].get("max_level", 0) if field == "techniques" else definitions[id].limit)
			if not integer(entries[id], limit): return "SECT_BOUND:" + str(id)
	var tasks: Variant = sect.get("available_tasks", [])
	if not (tasks is Array) or tasks.size() > 3: return "SECT_TASK_COUNT"
	var all_tasks: Array = tasks.duplicate(true)
	var active: Variant = sect.get("active_expedition")
	if active != null: all_tasks.append(active)
	var ids := {}
	for task in all_tasks:
		var error := validate_task(task, int(version))
		if not error.is_empty(): return error
		if ids.has(task.id): return "SECT_DUPLICATE_INSTANCE"
		ids[task.id] = true
	return ""

static func validate_task(task: Variant, version: int) -> String:
	if not (task is Dictionary): return "SECT_TASK_TYPE"
	if not text(task.get("id"), 128) or String(task.id).is_empty(): return "SECT_TASK_ID"
	if not text(task.get("name", ""), 128) or not text(task.get("desc", ""), 1024): return "SECT_TASK_TEXT"
	if not number(task.get("duration", 0)) or not number(task.get("elapsed", 0)): return "SECT_TASK_TIME"
	if float(task.get("elapsed", 0)) > float(task.get("duration", 0)): return "SECT_TASK_TIME"
	var rewards: Variant = task.get("rewards", {})
	if not (rewards is Dictionary) or rewards.size() > 8: return "SECT_TASK_REWARDS"
	for id in rewards:
		if id == "special_buff":
			if rewards[id] != "epiphany": return "SECT_TASK_BUFF"
		elif id not in ["contribution", "money", "wood", "stone_low", "spirit_grass_low", "black_copper", "herb", "bronze"] or not integer(rewards[id], 1000000):
			return "SECT_TASK_REWARD:" + str(id)
	if not task.has("template_id"): return "" # Bounded legacy snapshot, never infer a template.
	if version == 0 or not SectSystem.P1_TASKS.has(task.template_id): return "SECT_TEMPLATE_ID"
	var t: Dictionary = SectSystem.P1_TASKS[task.template_id]
	var era: Variant = task.get("generation_era")
	if not integer(era, 12) or int(era) < int(t.min_era): return "SECT_GENERATION_ERA"
	var cfg: Dictionary = SectSystem.RARITY_CONFIGS[t.rarity]
	if task.get("rarity") != t.rarity or task.get("name") != t.name or task.get("desc") != t.desc or task.get("duration") != cfg.duration: return "SECT_TEMPLATE_PAYLOAD"
	if task.get("rarity_name") != cfg.name or task.get("rarity_color") != cfg.color: return "SECT_TEMPLATE_PRESENTATION"
	var expected: Dictionary = t.rewards.duplicate(true)
	expected.money = int(50 * float(cfg.reward_mult) * int(era))
	if not integer(rewards.get("contribution"), int(cfg.contrib_max)) or int(rewards.contribution) < int(cfg.contrib_min): return "SECT_TEMPLATE_CONTRIBUTION"
	expected.contribution = rewards.contribution
	if rewards.size() != expected.size(): return "SECT_TEMPLATE_REWARDS"
	for id in expected:
		if not rewards.has(id) or not integer(rewards[id], 1000000) or int(rewards[id]) != int(expected[id]): return "SECT_TEMPLATE_REWARDS"
	return ""
