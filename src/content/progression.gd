class_name ProgressionEvaluator
extends RefCounted

const STATUS_HIDDEN := "hidden"
const STATUS_TEASED := "teased"
const STATUS_AVAILABLE := "available"
const STATUS_OWNED := "owned"
const REASON_OK := "OK"
const REASON_UNKNOWN_TYPE := "REASON_UNKNOWN_TYPE"
const REASON_UNKNOWN_TARGET := "REASON_UNKNOWN_TARGET"
const REASON_ERA_NOT_REACHED := "REASON_ERA_NOT_REACHED"
const REASON_BUILDING_LEVEL_LOW := "REASON_BUILDING_LEVEL_LOW"
const REASON_SKILL_LEVEL_LOW := "REASON_SKILL_LEVEL_LOW"
const REASON_NOT_OBTAINED := "REASON_NOT_OBTAINED"
const REASON_MISSING_CONTENT := "REASON_MISSING_CONTENT"

static func requirement_is_met(state: GameState, requirement: Dictionary) -> Dictionary:
	var requirement_kind: Variant = requirement.get("type")
	if requirement_kind == "era":
		var era_value: Variant = requirement.get("era")
		if not _is_valid_positive_integer(era_value):
			return {"met": false, "reason": REASON_UNKNOWN_TARGET}
		var era := int(era_value)
		if era < 1:
			return {"met": false, "reason": REASON_UNKNOWN_TARGET}
		if int(state.era_id) >= era:
			return {"met": true, "reason": REASON_OK}
		return {"met": false, "reason": REASON_ERA_NOT_REACHED}
	if requirement_kind == "building_level":
		var building_id: Variant = requirement.get("building")
		if not _is_valid_id(building_id):
			return {"met": false, "reason": REASON_UNKNOWN_TARGET}
		var required_level: Variant = requirement.get("level")
		if not _is_valid_positive_integer(required_level):
			return {"met": false, "reason": REASON_UNKNOWN_TARGET}
		var current_level := int(state.buildings.get(String(building_id), 0))
		if current_level >= int(required_level):
			return {"met": true, "reason": REASON_OK}
		return {"met": false, "reason": REASON_BUILDING_LEVEL_LOW}
	if requirement_kind == "skill_level":
		var skill_id: Variant = requirement.get("skill")
		if not _is_valid_id(skill_id):
			return {"met": false, "reason": REASON_UNKNOWN_TARGET}
		var required_level: Variant = requirement.get("level")
		if not _is_valid_positive_integer(required_level):
			return {"met": false, "reason": REASON_UNKNOWN_TARGET}
		var skills_dict := _state_skills(state)
		var skill_level := int(skills_dict.get(String(skill_id), 0))
		if skill_level >= int(required_level):
			return {"met": true, "reason": REASON_OK}
		return {"met": false, "reason": REASON_SKILL_LEVEL_LOW}
	if requirement_kind == "ever_obtained":
		var resource_id: Variant = requirement.get("resource")
		if not _is_valid_id(resource_id):
			return {"met": false, "reason": REASON_UNKNOWN_TARGET}
		var entry: Variant = state.resources.get(String(resource_id))
		if typeof(entry) == TYPE_DICTIONARY:
			var entry_dict: Dictionary = entry
			if bool(entry_dict.get("ever_obtained", false)):
				return {"met": true, "reason": REASON_OK}
		return {"met": false, "reason": REASON_NOT_OBTAINED}
	return {"met": false, "reason": REASON_UNKNOWN_TYPE}

static func requirements_met(state: GameState, requirements: Array) -> Dictionary:
	for requirement in requirements:
		if typeof(requirement) != TYPE_DICTIONARY:
			return {"met": false, "reason": REASON_UNKNOWN_TYPE, "first_unmet": null}
		var result := requirement_is_met(state, requirement)
		if not bool(result["met"]):
			return {"met": false, "reason": String(result["reason"]), "first_unmet": requirement}
	return {"met": true, "reason": REASON_OK, "first_unmet": null}

static func resource_status(state: GameState, content: GameContent, resource_id: String) -> Dictionary:
	var definition: Variant = content.resources.get(resource_id)
	if typeof(definition) != TYPE_DICTIONARY:
		return {"status": STATUS_HIDDEN, "reason": REASON_MISSING_CONTENT}
	var definition_dict: Dictionary = definition
	var entry: Variant = state.resources.get(resource_id)
	if typeof(entry) == TYPE_DICTIONARY:
		var entry_dict: Dictionary = entry
		if bool(entry_dict.get("unlocked", false)):
			return {"status": STATUS_OWNED, "reason": REASON_OK}
	var requirements := _requirements_from_definition(definition_dict.get("unlock"))
	var state_era := int(state.era_id)
	for requirement in requirements:
		if typeof(requirement) != TYPE_DICTIONARY:
			continue
		var requirement_dict: Dictionary = requirement
		if requirement_dict.get("type") != "era":
			continue
		var era_value: Variant = requirement_dict.get("era")
		if not _is_valid_positive_integer(era_value):
			continue
		if int(era_value) > state_era:
			return {"status": STATUS_HIDDEN, "reason": REASON_ERA_NOT_REACHED}
	var gate := requirements_met(state, requirements)
	if not bool(gate["met"]):
		return {"status": STATUS_TEASED, "reason": String(gate["reason"])}
	return {"status": STATUS_AVAILABLE, "reason": REASON_OK}

static func building_status(state: GameState, content: GameContent, building_id: String) -> Dictionary:
	var definition: Variant = content.buildings.get(building_id)
	if typeof(definition) != TYPE_DICTIONARY:
		return {"status": STATUS_HIDDEN, "reason": REASON_MISSING_CONTENT}
	var definition_dict: Dictionary = definition
	if int(state.buildings.get(building_id, 0)) >= 1:
		return {"status": STATUS_OWNED, "reason": REASON_OK}
	var era := 1
	var era_value: Variant = definition_dict.get("era")
	if _is_valid_positive_integer(era_value):
		era = int(era_value)
	if era > int(state.era_id):
		return {"status": STATUS_HIDDEN, "reason": REASON_ERA_NOT_REACHED}
	var prereq: Variant = definition_dict.get("prereq")
	if typeof(prereq) == TYPE_DICTIONARY:
		var prereq_dict: Dictionary = prereq
		var prereq_requirement: Dictionary = {
			"type": "building_level",
			"building": prereq_dict.get("building", ""),
			"level": prereq_dict.get("level", 0),
		}
		var prereq_result := requirement_is_met(state, prereq_requirement)
		if not bool(prereq_result["met"]):
			return {"status": STATUS_TEASED, "reason": String(prereq_result["reason"])}
	var requirements := _requirements_from_definition(definition_dict.get("requirements"))
	var gate := requirements_met(state, requirements)
	if not bool(gate["met"]):
		return {"status": STATUS_TEASED, "reason": String(gate["reason"])}
	return {"status": STATUS_AVAILABLE, "reason": REASON_OK}

static func evaluate_all(state: GameState, content: GameContent) -> Dictionary:
	var resource_results: Dictionary = {}
	for resource_id in _ids_or_keys(content.resource_ids, content.resources):
		var id_text := String(resource_id)
		resource_results[id_text] = resource_status(state, content, id_text)
	var building_results: Dictionary = {}
	for building_id in _ids_or_keys(content.building_ids, content.buildings):
		var building_text := String(building_id)
		building_results[building_text] = building_status(state, content, building_text)
	return {"resources": resource_results, "buildings": building_results}

static func _requirements_from_definition(raw: Variant) -> Array:
	var requirements: Array = []
	if typeof(raw) == TYPE_ARRAY:
		for item in raw:
			requirements.append(item)
	return requirements

static func _ids_or_keys(ids_value: Variant, fallback: Dictionary) -> Array:
	var ids: Array = []
	if typeof(ids_value) == TYPE_ARRAY:
		for item in ids_value:
			ids.append(item)
		return ids
	for key in fallback:
		ids.append(key)
	return ids

static func _state_skills(state: GameState) -> Dictionary:
	var raw: Variant = state.get("skills")
	if typeof(raw) == TYPE_DICTIONARY:
		var dict: Dictionary = raw
		return dict
	return {}

static func _is_valid_id(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not String(value).is_empty()

static func _is_valid_positive_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return int(value) >= 1
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		return number >= 1.0 and number == floorf(number)
	return false
