class_name SkillSystem
extends RefCounted
## Adapted from preserved master ff86f85: optional bonuses, authoritative Amount stock.
const VERSION := 4
const CONTENT_TAG := "+content-p1-skills"
const P2_CONTENT_TAG := "+content-sks-p2"
const SUPPORTED_VERSIONS := [0, 1, 2, 3, 4]
const P1_LIMITS := {"greenwood_nourishment": 3, "ore_breath_refinement": 3, "herbal_spirit_nurture": 3, "warehouse_preparation": 3, "alchemical_breath_control": 3}
const MATERIALS := ["wood", "stone_low", "spirit_grass_low"]
const PRODUCTION_BUILDINGS := ["wooden_house", "forest_farm", "stone_mine", "herb_farm"]
const EFFECTS := ["lingli_multiplier", "lingli_rate", "money_multiplier", "lingli_max", "money_max", "building_level_cap", "time_multiplier", "wood_multiplier", "stone_low_multiplier", "spirit_grass_low_multiplier", "p1_material_capacity_flat", "p1_alchemy_lingli_discount", "p2_home_capacity_multiplier", "p2_advanced_capacity_multiplier", "p2_craft_lingli_discount", "p2_deep_rate_multiplier", "p2_ancient_rate_multiplier", "p2_void_rate_multiplier", "p2_home_rate_multiplier", "p2_local_capacity_flat"]
const P2_SCOPE := {
	"nascent_soul_incubation": {"text": "祖島與加工庫存 23 種（含技能點）", "islands": []},
	"nascent_soul_mastery": {"text": "全境界修煉所需時間", "islands": []},
	"heavenly_craft": {"text": "祖島加工：中品批量、上品靈石", "islands": []},
	"deep_vein_resonance": {"text": "寒銀島：精鐵／秘銀／寒鐵採集率", "islands": ["deep"]},
	"void_expansion": {"text": "七種高階資源庫容", "islands": []},
	"spirit_transformation": {"text": "全境界修煉所需時間", "islands": []},
	"ancient_herb_attunement": {"text": "古藥島：千年靈草採集率", "islands": ["ancient"]},
	"spirit_sea_breath": {"text": "祖島靈力被動產率", "islands": []},
	"void_mastery": {"text": "祖島六種被動產率（含技能點）", "islands": []},
	"void_refinement": {"text": "全境界修煉所需時間", "islands": []},
	"void_essence_attunement": {"text": "太虛島：虛空精華採集率", "islands": ["void"]},
	"frontier_storekeeping": {"text": "寒銀／古藥／太虛島地方庫容", "islands": ["deep", "ancient", "void"]},
}
const ISLAND_NAMES := {"deep": "寒銀島", "ancient": "古藥島", "void": "太虛島"}

static func attach(content: GameContent) -> Dictionary:
	if not content.skill_defs.is_empty():
		return {"ok": true}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/skills/era2.json"))
	var raw_next: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/skills/era3.json"))
	var raw_p2: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/skills/era4_6.json"))
	var buildings_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/buildings/study.json"))
	if not raw is Array or not raw_next is Array or not raw_p2 is Array or not buildings_raw is Array:
		return {"ok": false, "error": "SKILL_CONTENT_FORMAT"}
	var definitions := {}
	for value in raw:
		var parsed := _parse_definition(value, definitions)
		if not parsed.ok:
			return parsed
		definitions[parsed.id] = parsed.def
	for value in raw_next:
		var parsed := _parse_definition(value, definitions)
		if not parsed.ok:
			return parsed
		definitions[parsed.id] = parsed.def
	for value in raw_p2:
		var parsed := _parse_definition(value, definitions)
		if not parsed.ok:
			return parsed
		definitions[parsed.id] = parsed.def
	for id in definitions:
		var requires: Variant = definitions[id].get("requires", {})
		if not requires is Dictionary:
			return {"ok": false, "error": "SKILL_REQUIRES"}
		if requires.is_empty():
			continue
		var skill_id: Variant = requires.get("skill_id", "")
		var req_level: Variant = requires.get("level", 1)
		if not (skill_id is String and definitions.has(skill_id) and (req_level is int or req_level is float) and is_finite(float(req_level)) and float(req_level) == floor(float(req_level)) and float(req_level) >= 1.0 and float(req_level) <= float(definitions[skill_id].get("max_level", 0))):
			return {"ok": false, "error": "SKILL_REQUIRES"}
	var resources: Array = content.resources.values().duplicate(true)
	if not content.resources.has("skill_point"):
		resources.append({"id": "skill_point", "type": "basic", "max": 200, "rate": 0, "unlocked": false})
	var buildings: Array = content.buildings.values().duplicate(true)
	buildings.append_array(buildings_raw)
	var expanded := ContentLoader.build_content(resources, buildings)
	if not expanded.ok:
		return expanded
	content.resources = expanded.content.resources
	content.resource_ids = expanded.content.resource_ids
	content.buildings = expanded.content.buildings
	content.building_ids = expanded.content.building_ids
	content.skill_defs = definitions
	content.content_version += CONTENT_TAG
	content.content_version += P2_CONTENT_TAG
	return {"ok": true}

static func _parse_definition(value: Variant, definitions: Dictionary) -> Dictionary:
	if not value is Dictionary:
		return {"ok": false, "error": "SKILL_DEFINITION"}
	var def: Dictionary = value
	var id: String = def.get("id", "")
	if id.is_empty() or definitions.has(id) or not def.get("effect", "") in EFFECTS:
		return {"ok": false, "error": "SKILL_DEFINITION"}
	var era: Variant = def.get("era", 2)
	if not (era is int or era is float) or not is_finite(float(era)) or float(era) != floor(float(era)) or float(era) < 1.0:
		return {"ok": false, "error": "SKILL_DEFINITION"}
	for key in ["cost", "amount", "max_level"]:
		var number: Variant = def.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or float(number) <= 0:
			return {"ok": false, "error": "SKILL_NUMBER"}
	if float(def.max_level) != floor(float(def.max_level)):
		return {"ok": false, "error": "SKILL_LEVEL"}
	return {"ok": true, "id": id, "def": def.duplicate(true)}

static func reconcile(content: GameContent, state: GameState) -> bool:
	if content.skill_defs.is_empty():
		return false
	var changed := state.skill_version != VERSION
	state.skill_version = VERSION
	if not state.resources.has("skill_point"):
		state.resources.skill_point = {"value": AmountCompat.zero(), "unlocked": false, "ever_obtained": false}
		changed = true
	for id in ["library", "scripture_hall"]:
		if not state.buildings.has(id):
			state.buildings[id] = 0
			changed = true
	sync_unlock(state)
	return changed

static func sync_unlock(state: GameState) -> void:
	if state.resources.has("skill_point"):
		state.resources.skill_point.unlocked = state.era_id >= 2 and int(state.buildings.get("library", 0)) > 0

static func learn(content: GameContent, state: GameState, id: String) -> Dictionary:
	var def: Dictionary = content.skill_defs.get(id, {})
	if def.is_empty():
		return _failure("UNKNOWN_SKILL")
	if state.era_id < 2 or int(state.buildings.get("library", 0)) < 1:
		return _failure("SKILL_STUDY_LOCKED")
	if state.era_id < int(def.get("era", 2)):
		return _failure("SKILL_ERA_LOCKED")
	var requires: Variant = def.get("requires", {})
	if requires is Dictionary and not requires.is_empty():
		if int(state.skills.get(str(requires.get("skill_id", "")), 0)) < int(requires.get("level", 1)):
			return _failure("SKILL_PREREQ_LOCKED")
	var level := int(state.skills.get(id, 0))
	if level >= int(def.max_level):
		return _failure("SKILL_MAX_LEVEL")
	var entry: Dictionary = state.resources.get("skill_point", {})
	if entry.is_empty() or not bool(entry.unlocked):
		return _failure("SKILL_STUDY_LOCKED")
	var cost := AmountCompat.from_number(float(def.cost))
	if entry.value.compare_to(cost) < 0:
		return _failure("INSUFFICIENT_SKILL_POINT")
	entry.value = ResourceLedger.change(state, "home", "skill_point", entry.value, entry.value.subtract(cost), "skill")
	state.skills[id] = level + 1
	return {"ok": true, "events": [{"kind": "skill_learned", "skill_id": id, "new_level": level + 1, "cost": cost.serialize()}], "changed_ids": ["skills", "skill_point"]}

static func effect(content: GameContent, skills: Dictionary, kind: String) -> float:
	var multiplier := kind.ends_with("_multiplier")
	var result := 1.0 if multiplier else 0.0
	for id in skills:
		var def: Dictionary = content.skill_defs.get(id, {})
		if def.get("effect", "") != kind:
			continue
		var level := clampi(int(skills[id]), 0, int(def.max_level))
		if multiplier:
			result *= pow(float(def.amount), level)
		else:
			result += float(def.amount) * level
	return result

static func level_bonus(content: GameContent, state: GameState, id: String) -> int:
	return int(effect(content, state.skills, "building_level_cap")) if id in PRODUCTION_BUILDINGS else 0

static func view(content: GameContent, state: GameState) -> Dictionary:
	var entry: Dictionary = state.resources.get("skill_point", {})
	var available: AmountCompat = entry.get("value", AmountCompat.zero())
	var opened := state.era_id >= 2 and int(state.buildings.get("library", 0)) > 0
	var items: Array = []
	for id in content.skill_defs:
		var def: Dictionary = content.skill_defs[id]
		var level := int(state.skills.get(id, 0))
		var reason := ""
		if not opened:
			reason = "SKILL_STUDY_LOCKED"
		elif state.era_id < int(def.get("era", 2)):
			reason = "SKILL_ERA_LOCKED"
		else:
			var requires: Variant = def.get("requires", {})
			if requires is Dictionary and not requires.is_empty() and int(state.skills.get(str(requires.get("skill_id", "")), 0)) < int(requires.get("level", 1)):
				reason = "SKILL_PREREQ_LOCKED"
		if reason.is_empty() and level >= int(def.max_level):
			reason = "SKILL_MAX_LEVEL"
		if reason.is_empty() and available.compare_to(AmountCompat.from_number(float(def.cost))) < 0:
			reason = "INSUFFICIENT_SKILL_POINT"
		var scope := _scope(id, state)
		items.append({"id": id, "name": def.name, "level": level, "max_level": int(def.max_level), "cost": str(def.cost), "description": def.description, "reason": reason, "can_learn": reason.is_empty(), "current_effect": _effect_text(def, level), "next_effect": _effect_text(def, mini(level + 1, int(def.max_level))), "scope": scope.text, "scope_islands": scope.islands, "scope_open": scope.open, "scope_note": scope.note})
	return {"available": available.serialize(), "opened": opened, "items": items}

static func _scope(id: String, state: GameState) -> Dictionary:
	var entry: Variant = P2_SCOPE.get(id, {})
	if not entry is Dictionary or (entry as Dictionary).is_empty():
		return {"text": "", "islands": [], "open": true, "note": ""}
	var data: Dictionary = entry
	var islands: Array = data.get("islands", [])
	if islands.is_empty():
		return {"text": String(data.get("text", "")), "islands": [], "open": true, "note": ""}
	var opened_islands := {}
	var economy: Variant = state.economy
	if economy is Dictionary:
		var raw: Variant = (economy as Dictionary).get("islands", {})
		if raw is Dictionary:
			opened_islands = raw
	var closed_names := PackedStringArray()
	for island in islands:
		var island_id := String(island)
		var island_entry: Variant = opened_islands.get(island_id, {})
		var is_open := island_entry is Dictionary and bool((island_entry as Dictionary).get("opened", false))
		if not is_open:
			closed_names.append(String(ISLAND_NAMES.get(island_id, island_id)))
	var note := ""
	if not closed_names.is_empty():
		note = "%s未開 · 收益 0" % "／".join(closed_names)
	return {"text": String(data.get("text", "")), "islands": islands.duplicate(), "open": closed_names.is_empty(), "note": note}

static func _effect_text(def: Dictionary, level: int) -> String:
	var amount := float(def.amount)
	match def.effect:
		"lingli_multiplier": return "靈力產率 ×%.3f" % pow(amount, level)
		"money_multiplier": return "金錢產率 ×%.3f" % pow(amount, level)
		"lingli_rate": return "基礎靈力產率 +%.0f" % (amount * level)
		"lingli_max": return "靈力容量 +%.0f" % (amount * level)
		"money_max": return "金錢容量 +%.0f" % (amount * level)
		"building_level_cap": return "四種生產設施上限 +%d" % int(amount * level)
		"time_multiplier": return "修煉時間 ×%.3f" % pow(amount, level)
		"wood_multiplier": return "祖島木產率 ×%.3f" % pow(amount, level)
		"stone_low_multiplier": return "祖島下品靈石產率 ×%.3f" % pow(amount, level)
		"spirit_grass_low_multiplier": return "祖島低階草產率 ×%.3f" % pow(amount, level)
		"p1_material_capacity_flat": return "祖島木／石／草庫容各 +%.0f" % (amount * level)
		"p1_alchemy_lingli_discount": return "指定直煉靈力費 ×%.2f" % (1.0 - amount * level)
		"p2_home_capacity_multiplier": return "指定祖島與加工庫容 ×%.3f（含技能點）" % pow(amount, level)
		"p2_advanced_capacity_multiplier": return "七種高階庫容 ×%.3f" % pow(amount, level)
		"p2_craft_lingli_discount": return "批量煉石靈力費 ×%.2f" % (1.0 - amount * level)
		"p2_deep_rate_multiplier": return "寒銀島採集率 ×%.3f" % pow(amount, level)
		"p2_ancient_rate_multiplier": return "古藥島採集率 ×%.3f" % pow(amount, level)
		"p2_void_rate_multiplier": return "太虛島採集率 ×%.3f" % pow(amount, level)
		"p2_home_rate_multiplier": return "祖島靈力／金錢／木／石／草／技能點產率 ×%.3f" % pow(amount, level)
		"p2_local_capacity_flat": return "已開寒銀／古藥／太虛島庫容各 +%.0f" % (amount * level)
	return def.description

static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error, "events": [], "changed_ids": []}

static func validate(version: int, skills: Dictionary) -> String:
	var limits := {"basic_meditation": 5, "qi_condensation": 5, "foundation_building": 5, "qi_storage_1": 1, "body_strengthening_1": 1, "building_mastery_1": 1, "golden_core_formation": 5}
	if version < 2:
		limits.erase("golden_core_formation")
	if version >= 3:
		limits.merge(P1_LIMITS)
	if version >= 4:
		limits.merge(SksP2Rules.LIMITS)
	if version not in SUPPORTED_VERSIONS or (version == 0 and not skills.is_empty()) or skills.size() > skill_count_limit(version):
		return "STATE_FIELD_TYPE:skills"
	for id in skills:
		var level: Variant = skills[id]
		if not limits.has(id) or not (level is int or level is float) or not is_finite(float(level)) or float(level) != floor(float(level)) or float(level) < 0 or float(level) > float(limits[id]):
			return "STATE_FIELD_TYPE:skills"
	return ""

static func skill_count_limit(version: int) -> int:
	return 24 if version >= 4 else 12

static func study_cap(state: GameState, base: AmountCompat) -> AmountCompat:
	var bonus := float(SectSystem.compute_multipliers(state).storage_bonus) + float(ChronoSystem.compute_multipliers(state).storage_bonus) + float(BeastSystem.compute_multipliers(state).all_capacity_mult)
	return base.multiply(AmountCompat.from_number(1.0 + bonus)) if bonus > 0.0 else base
