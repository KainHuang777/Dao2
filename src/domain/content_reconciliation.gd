class_name ContentReconciliation
extends RefCounted

static func reconcile(state: GameState, content: GameContent) -> Dictionary:
	if state == null:
		return {"ok": false, "state": null, "report": {}, "error": "STATE_MISSING"}
	if content == null:
		return {"ok": false, "state": state, "report": {}, "error": "CONTENT_MISSING"}
	var resources: Dictionary = state.resources if state.resources is Dictionary else {}
	if not (state.resources is Dictionary):
		state.resources = resources
	var buildings: Dictionary = state.buildings if state.buildings is Dictionary else {}
	if not (state.buildings is Dictionary):
		state.buildings = buildings
	var pills: Dictionary = state.pills if state.pills is Dictionary else {}
	if not (state.pills is Dictionary):
		state.pills = pills
	var content_resource_ids: Array = content.resource_ids
	var content_building_ids: Array = content.building_ids
	var missing_resources_added: Array = []
	for resource_id in content_resource_ids:
		if not resources.has(resource_id):
			resources[resource_id] = {"value": AmountCompat.zero(), "unlocked": false, "ever_obtained": false}
			missing_resources_added.append(String(resource_id))
	var missing_buildings_added: Array = []
	for building_id in content_building_ids:
		if not buildings.has(building_id):
			buildings[building_id] = 0
			missing_buildings_added.append(String(building_id))
	var skill_ids_raw: Variant = content.skill_ids
	var content_skill_ids: Array = skill_ids_raw if skill_ids_raw is Array else []
	var skill_list_available: bool = not content_skill_ids.is_empty()
	var skills_raw: Variant = state.get("skills")
	var skills: Dictionary = skills_raw if skills_raw is Dictionary else {}
	var missing_skills_added: Array = []
	if skill_list_available:
		state.skills = skills
		for skill_id in content_skill_ids:
			if not skills.has(skill_id):
				skills[skill_id] = 0
				missing_skills_added.append(String(skill_id))
	var pills_migrated: Array = []
	var pills_conflicts: Array = []
	var pills_count: int = int(pills.get("foundation_pill", 0))
	if pills_count > 0:
		var resource_entry: Variant = resources.get("foundation_pill")
		var entry_amount: AmountCompat = AmountCompat.zero()
		var serialized_resource_value := "0"
		var entry_exists: bool = resource_entry is Dictionary
		if entry_exists:
			var resource_entry_dict: Dictionary = resource_entry
			var entry_value: Variant = resource_entry_dict.get("value")
			if entry_value is AmountCompat:
				entry_amount = entry_value
			elif entry_value is float or entry_value is int:
				entry_amount = AmountCompat.from_number(float(entry_value))
			elif entry_value is String:
				var parsed: Dictionary = AmountCompat.try_parse(entry_value)
				if bool(parsed.get("ok", false)) and parsed.get("value") is AmountCompat:
					entry_amount = parsed["value"]
				else:
					entry_amount = AmountCompat.zero()
			serialized_resource_value = entry_amount.serialize()
		if entry_exists and entry_amount.compare_to(AmountCompat.zero()) != 0:
			pills["foundation_pill"] = 0
			pills_conflicts.append({
				"pill_id": "foundation_pill",
				"pills_count": pills_count,
				"resource_value": serialized_resource_value,
				"resolution": "kept_resource_authority",
			})
		else:
			if not entry_exists:
				resources["foundation_pill"] = {"value": AmountCompat.zero(), "unlocked": false, "ever_obtained": false}
				if content_resource_ids.has("foundation_pill"):
					missing_resources_added.append("foundation_pill")
			var target_entry: Dictionary = resources["foundation_pill"]
			target_entry["value"] = entry_amount.add(AmountCompat.from_number(float(pills_count)))
			target_entry["ever_obtained"] = true
			pills["foundation_pill"] = 0
			pills_migrated.append("foundation_pill")
	var unknown_resources: Array = []
	for resource_id in resources:
		if not content_resource_ids.has(resource_id):
			unknown_resources.append(String(resource_id))
	var unknown_buildings: Array = []
	for building_id in buildings:
		if not content_building_ids.has(building_id):
			unknown_buildings.append(String(building_id))
	var unknown_skills: Array = []
	if skill_list_available:
		for skill_id in skills:
			if not content_skill_ids.has(skill_id):
				unknown_skills.append(String(skill_id))
	var unknown_pills: Array = []
	for pill_id in pills:
		if int(pills[pill_id]) > 0 and not resources.has(pill_id):
			unknown_pills.append(String(pill_id))
	var report := {
		"content_version": String(content.content_version),
		"missing_resources_added": missing_resources_added,
		"missing_buildings_added": missing_buildings_added,
		"missing_skills_added": missing_skills_added,
		"pills_migrated": pills_migrated,
		"pills_conflicts": pills_conflicts,
		"unknown_state_ids": {
			"resources": unknown_resources,
			"buildings": unknown_buildings,
			"skills": unknown_skills,
			"pills": unknown_pills,
		},
	}
	return {"ok": true, "state": state, "report": report, "error": ""}

static func unlock_eligible_resources(state: GameState, content: GameContent) -> Dictionary:
	if state == null or content == null:
		return {"ok": false, "unlocked": [], "errors": ["STATE_OR_CONTENT_MISSING"]}
	var newly_unlocked: Array = []
	for resource_id in content.resource_ids:
		var definition: Variant = content.resources.get(String(resource_id))
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var raw_unlock: Variant = (definition as Dictionary).get("unlock")
		if not (raw_unlock is Array) or (raw_unlock as Array).is_empty():
			continue
		var entry: Variant = state.resources.get(String(resource_id))
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var entry_dict: Dictionary = entry
		if bool(entry_dict.get("unlocked", false)):
			continue
		var status := ProgressionEvaluator.resource_status(state, content, String(resource_id))
		if String(status.get("status", "")) == "available" or String(status.get("status", "")) == "owned":
			entry_dict["unlocked"] = true
			newly_unlocked.append(String(resource_id))
	return {"ok": true, "unlocked": newly_unlocked, "errors": []}

static func is_retryable(error: Variant) -> bool:
	var code := ""
	if error is Dictionary:
		var error_dict: Dictionary = error
		code = String(error_dict.get("error", ""))
	elif error is String:
		code = error
	return code == "STATE_MISSING" or code == "CONTENT_MISSING" or code == "RECONCILE_SAVE_FAILED"