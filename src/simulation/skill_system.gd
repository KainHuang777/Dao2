class_name SkillSystem
extends RefCounted

static func get_definition(content: GameContent, skill_id: String) -> Variant:
	return content.skill(skill_id)

static func get_cost(def: Dictionary) -> AmountCompat:
	var costs: Dictionary = def.get("cost", {})
	var cost_resource := String(def.get("cost_resource", ""))
	if cost_resource.is_empty() or not costs.has(cost_resource):
		return AmountCompat.zero()
	return AmountCompat.from_number(float(costs[cost_resource]))

static func can_learn(content: GameContent, state: GameState, skill_id: String) -> Dictionary:
	var def: Variant = content.skill(skill_id)
	if def == null:
		return {"can_learn": false, "reason": "UNKNOWN_SKILL"}
	var skill_def: Dictionary = def
	var cur_level := int(state.skills.get(skill_id, 0))
	var max_level := int(skill_def.get("max_level", 0))
	if cur_level >= max_level:
		return {"can_learn": false, "reason": "SKILL_MAX_LEVEL", "level": cur_level, "max_level": max_level}
	var costs: Dictionary = skill_def.get("cost", {})
	if costs.is_empty():
		return {"can_learn": false, "reason": "SKILL_COST_MISSING"}
	var cost_resource := String(skill_def.get("cost_resource", ""))
	if cost_resource.is_empty():
		for resource_id in costs:
			cost_resource = String(resource_id)
			break
	if not costs.has(cost_resource):
		return {"can_learn": false, "reason": "SKILL_COST_MISSING"}
	var cost := get_cost(skill_def)
	var entry: Variant = state.resources.get(cost_resource)
	if entry == null or not (entry is Dictionary):
		return {"can_learn": false, "reason": "MISSING_RESOURCE_ENTRY", "resource_id": cost_resource}
	var resource_entry: Dictionary = entry
	if not bool(resource_entry.get("unlocked", false)):
		return {"can_learn": false, "reason": "RESOURCE_LOCKED", "resource_id": cost_resource}
	var value: AmountCompat = resource_entry["value"]
	var available: AmountCompat = value.add(AmountCompat.from_number(0.000001))
	if available.compare_to(cost) < 0:
		return {
			"can_learn": false,
			"reason": "INSUFFICIENT_RESOURCE",
			"resource_id": cost_resource,
			"required": cost.serialize(),
			"current": value.serialize(),
		}
	return {"can_learn": true, "cost": cost, "cost_resource": cost_resource, "next_level": cur_level + 1}

static func learn(content: GameContent, state: GameState, skill_id: String) -> Dictionary:
	var check := can_learn(content, state, skill_id)
	if not bool(check.get("can_learn", false)):
		return {
			"ok": false,
			"error": String(check.get("reason", "CANNOT_LEARN")),
			"events": [],
			"changed_ids": [],
			"detail": check,
		}
	var cost: AmountCompat = check["cost"]
	var cost_resource := String(check["cost_resource"])
	var entry: Dictionary = state.resources[cost_resource]
	var value: AmountCompat = entry["value"]
	var after: AmountCompat = value.subtract(cost)
	if after.compare_to(AmountCompat.from_number(0.000000001)) < 0:
		after = AmountCompat.zero()
	entry["value"] = after
	var next_level := int(check["next_level"])
	state.skills[skill_id] = next_level
	var event := {
		"kind": "skill_learned",
		"skill_id": skill_id,
		"new_level": next_level,
		"cost_resource": cost_resource,
		"cost": cost.serialize(),
		"remaining": after.serialize(),
	}
	return {
		"ok": true,
		"events": [event],
		"changed_ids": [cost_resource, "skills"],
	}

static func get_view(content: GameContent, state: GameState) -> Array:
	var view: Array = []
	for skill_id in content.skill_ids:
		var def: Variant = content.skill(String(skill_id))
		if def == null:
			continue
		var skill_def: Dictionary = def
		var level := int(state.skills.get(String(skill_id), 0))
		var costs := {}
		var cost_map: Dictionary = skill_def.get("cost", {})
		for resource_id in cost_map:
			costs[String(resource_id)] = AmountCompat.from_number(float(cost_map[resource_id])).serialize()
		var check := can_learn(content, state, String(skill_id))
		view.append({
			"id": String(skill_id),
			"name_key": String(skill_def.get("name_key", "")),
			"level": level,
			"max_level": int(skill_def.get("max_level", 0)),
			"cost": costs,
			"cost_resource": String(skill_def.get("cost_resource", "")),
			"can_learn": bool(check.get("can_learn", false)),
			"reason": String(check.get("reason", "")),
		})
	return view
