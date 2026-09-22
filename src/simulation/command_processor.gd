class_name CommandProcessor
extends RefCounted

const GLOBAL_BASE_LEVEL_CAP := 10
const AFFORD_TOLERANCE := 0.000001
const ZERO_SNAP := 0.000000001

static func apply(content: GameContent, state: GameState, command: Dictionary) -> Dictionary:
	match String(command.type):
		"gather":
			return _apply_gather(content, state, command.payload)
		"upgrade_building":
			return _apply_upgrade(content, state, command.payload)
		"level_up_cultivation":
			return _apply_level_up(content, state, command.payload)
		"breakthrough_era":
			return _apply_breakthrough(content, state, command.payload)
		"reincarnate":
			return _apply_reincarnate(content, state, command.payload)
		"learn_talent":
			return _apply_learn_talent(content, state, command.payload)
	return _failure("UNKNOWN_COMMAND", {})


static func level_cap(definition: Dictionary) -> int:
	return mini(int(definition.max_level), GLOBAL_BASE_LEVEL_CAP)

static func _apply_gather(content: GameContent, state: GameState, payload: Dictionary) -> Dictionary:
	var resource_id := String(payload.resource_id)
	var definition = content.resource(resource_id)
	if definition == null:
		return _failure("UNKNOWN_RESOURCE", {"resource_id": resource_id})
	if String(definition.type) != "basic":
		return _failure("NOT_BASIC_RESOURCE", {"resource_id": resource_id})
	var entry: Dictionary = state.resources[resource_id]
	if not bool(entry.unlocked):
		return _failure("RESOURCE_LOCKED", {"resource_id": resource_id})
	var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
	var amount := AmountCompat.from_number(1.0)
	var new_value: AmountCompat = entry.value.add(amount).clamp_amount(AmountCompat.zero(), caps[resource_id])
	entry.value = new_value
	entry.ever_obtained = true
	return {
		"ok": true,
		"events": [{"kind": "resource_gathered", "resource_id": resource_id, "amount": amount.serialize()}],
		"changed_ids": [resource_id],
	}

static func _apply_upgrade(content: GameContent, state: GameState, payload: Dictionary) -> Dictionary:
	var building_id := String(payload.building_id)
	var definition = content.building(building_id)
	if definition == null:
		return _failure("UNKNOWN_BUILDING", {"building_id": building_id})
	var level := int(state.buildings.get(building_id, 0))
	if level == 0 and state.era_id < int(definition.era):
		return _failure("ERA_REQUIREMENT", {"building_id": building_id, "required_era": int(definition.era), "player_era": state.era_id})
	var cap := level_cap(definition)
	if level >= cap:
		return _failure("LEVEL_CAP", {"building_id": building_id, "level": level, "level_cap": cap})
	var unlock_before := Onboarding.unlock_state(state.era_id, state.onboarding_version, state.buildings)
	if level == 0:
		if unlock_before.active and not (building_id in unlock_before.buildings):
			return _failure("BUILDING_LOCKED", {"building_id": building_id})
		var prereq = definition.prereq
		if prereq != null:
			var required := maxi(1, int(floor(float(prereq.level))))
			if int(state.buildings.get(String(prereq.building), 0)) < required:
				return _failure("PREREQ_UNSATISFIED", {"building_id": building_id, "prereq_building": String(prereq.building), "prereq_level": required})
	var onboarding_active := Onboarding.is_active(state.onboarding_version, state.era_id)
	var base_cost := BuildingCosts.resolve_base_cost(building_id, definition.base_cost, onboarding_active)
	var costs := BuildingCosts.compute_cost(base_cost, level, float(definition.cost_factor))
	for resource_id in costs:
		var cost_entry: Dictionary = state.resources[resource_id]
		var available: AmountCompat = cost_entry.value.add(AmountCompat.from_number(AFFORD_TOLERANCE))
		if available.compare_to(costs[resource_id]) < 0:
			return _failure("INSUFFICIENT_RESOURCE", {
				"building_id": building_id,
				"resource_id": resource_id,
				"required": costs[resource_id].serialize(),
				"available": cost_entry.value.serialize(),
			})
	for resource_id in costs:
		var paid_entry: Dictionary = state.resources[resource_id]
		var after: AmountCompat = paid_entry.value.subtract(costs[resource_id])
		if after.compare_to(AmountCompat.from_number(ZERO_SNAP)) < 0:
			after = AmountCompat.zero()
		paid_entry.value = after
	state.buildings[building_id] = level + 1
	var unlock_after := Onboarding.unlock_state(state.era_id, state.onboarding_version, state.buildings)
	var events: Array = [{"kind": "building_upgraded", "building_id": building_id, "new_level": level + 1}]
	var changed_ids: Array = [building_id]
	for resource_id in unlock_after.resources:
		var resource_entry: Dictionary = state.resources[resource_id]
		if not bool(resource_entry.unlocked):
			resource_entry.unlocked = true
			events.append({"kind": "resource_unlocked", "resource_id": resource_id})
		if not (resource_id in unlock_before.resources):
			changed_ids.append(resource_id)
	for visible_id in unlock_after.buildings:
		if not (visible_id in unlock_before.buildings):
			changed_ids.append(visible_id)
	return {"ok": true, "events": events, "changed_ids": changed_ids}

static func _apply_level_up(content: GameContent, state: GameState, _payload: Dictionary) -> Dictionary:
	var era_def: Variant = content.era(state.era_id)
	if era_def == null:
		return _failure("UNKNOWN_ERA", {"era_id": state.era_id})
	if state.level >= int(era_def.max_level):
		return _failure("MAX_LEVEL_REACHED", {"era_id": state.era_id, "level": state.level})
	var req_time := Cultivation.next_level_required_seconds(era_def, state.level, 0.0, 1.0)
	if state.training_seconds < req_time - AFFORD_TOLERANCE:
		return _failure("INSUFFICIENT_TRAINING", {"required": req_time, "available": state.training_seconds})
	var costs: Dictionary = Cultivation.level_up_cost(era_def, state.level, 0.0)
	for resource_id in costs:
		var entry: Dictionary = state.resources.get(resource_id, {})
		if entry.is_empty():
			return _failure("MISSING_RESOURCE_ENTRY", {"resource_id": resource_id})
		var available: AmountCompat = entry.value.add(AmountCompat.from_number(AFFORD_TOLERANCE))
		if available.compare_to(costs[resource_id]) < 0:
			return _failure("INSUFFICIENT_RESOURCE", {
				"resource_id": resource_id,
				"required": costs[resource_id].serialize(),
				"available": entry.value.serialize()
			})
	for resource_id in costs:
		var entry: Dictionary = state.resources[resource_id]
		var after: AmountCompat = entry.value.subtract(costs[resource_id])
		if after.compare_to(AmountCompat.from_number(ZERO_SNAP)) < 0:
			after = AmountCompat.zero()
		entry.value = after
	state.level += 1
	state.training_seconds = 0.0
	return {
		"ok": true,
		"events": [{"kind": "cultivation_leveled_up", "era_id": state.era_id, "new_level": state.level}],
		"changed_ids": ["cultivation_level"]
	}

static func _apply_breakthrough(content: GameContent, state: GameState, _payload: Dictionary) -> Dictionary:
	var era_def: Variant = content.era(state.era_id)
	if era_def == null:
		return _failure("UNKNOWN_ERA", {"era_id": state.era_id})
	var next_era: Variant = content.era(state.era_id + 1)
	if next_era == null:
		return _failure("NO_NEXT_ERA", {"current_era": state.era_id})
	if state.level < int(era_def.max_level):
		return _failure("ERA_NOT_MAX_LEVEL", {"required": int(era_def.max_level), "current": state.level})
	var upgrade_req: Dictionary = era_def.get("upgrade_requirements", {})
	var req_caps: Dictionary = upgrade_req.get("capacity", {})
	var cur_caps: Dictionary = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
	for r_id in req_caps:
		var needed: float = float(req_caps[r_id])
		var current_cap: AmountCompat = cur_caps.get(r_id, AmountCompat.zero())
		if current_cap.compare_to(AmountCompat.from_number(needed)) < 0:
			return _failure("INSUFFICIENT_CAPACITY", {
				"resource_id": r_id,
				"required_capacity": needed,
				"current_capacity": current_cap.to_float()
			})
	var from_era := state.era_id
	state.era_id += 1
	state.level = 1
	state.training_seconds = 0.0
	return {
		"ok": true,
		"events": [{"kind": "era_breakthrough", "from_era": from_era, "to_era": state.era_id}],
		"changed_ids": ["era_id", "cultivation_level"]
	}

static func _apply_reincarnate(content: GameContent, state: GameState, payload: Dictionary) -> Dictionary:
	var mode: String = String(payload.get("mode", "normal"))
	return ReincarnationRules.apply_reincarnation(state, content, mode)

static func _apply_learn_talent(_content: GameContent, state: GameState, payload: Dictionary) -> Dictionary:
	var talent_id: String = String(payload.get("talent_id", ""))
	if talent_id.is_empty():
		return _failure("EMPTY_TALENT_ID", {})
	return TalentSystem.learn(state, talent_id)

static func _failure(error: String, detail: Dictionary) -> Dictionary:
	var result := {"ok": false, "error": error, "events": [], "changed_ids": []}
	if not detail.is_empty():
		result.detail = detail
	return result
