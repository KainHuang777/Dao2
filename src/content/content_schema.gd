class_name ContentSchema
extends RefCounted

const SUPPORTED_CONSUMABLE_EFFECT_KEYS := ["instant_training_seconds", "lifespan_bonus_years", "production_multiplier", "lifespan_bonus_seconds"]
const DEFAULT_LIFETIME_POLICY := "permanent_this_life"
const REQUIREMENT_TYPES := ["era", "building_level", "skill_level", "ever_obtained"]

static func validate_recipes(raw: Array, resource_ids: Dictionary, skill_ids: Dictionary, errors: Array) -> Array:
	var defs: Array = []
	var seen := {}
	for index in range(raw.size()):
		var label := "recipes[%d]" % index
		var entry = raw[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("%s: expected a JSON object" % label)
			continue
		var recipe_id = entry.get("id", "")
		if typeof(recipe_id) != TYPE_STRING or String(recipe_id).is_empty():
			errors.append("%s: id must be a non-empty string" % label)
			continue
		var id_text := String(recipe_id)
		label = "%s (%s)" % [label, id_text]
		if seen.has(id_text):
			errors.append("%s: duplicate recipe id" % label)
			continue
		seen[id_text] = true
		var inputs = entry.get("inputs")
		if typeof(inputs) != TYPE_DICTIONARY:
			errors.append("%s: inputs must be an object" % label)
			continue
		if inputs.is_empty():
			errors.append("%s: inputs must be a non-empty object" % label)
			continue
		var clean_inputs := {}
		var inputs_valid := true
		for resource_id in inputs:
			if typeof(resource_id) != TYPE_STRING or String(resource_id).is_empty():
				errors.append("%s: inputs keys must be non-empty resource ids" % label)
				inputs_valid = false
				break
			var amount = inputs[resource_id]
			if not _is_number(amount) or float(amount) < 0.0:
				errors.append("%s: inputs.%s must be a number >= 0" % [label, resource_id])
				inputs_valid = false
				break
			if not resource_ids.has(String(resource_id)):
				errors.append("%s: inputs references unknown resource '%s'" % [label, resource_id])
				inputs_valid = false
				break
			clean_inputs[String(resource_id)] = float(amount)
		if not inputs_valid:
			continue
		var output = entry.get("output")
		if typeof(output) != TYPE_DICTIONARY:
			errors.append("%s: output must be an object" % label)
			continue
		var output_resource = output.get("resource_id", "")
		if typeof(output_resource) != TYPE_STRING or String(output_resource).is_empty():
			errors.append("%s: output.resource_id must be a non-empty string" % label)
			continue
		if not resource_ids.has(String(output_resource)):
			errors.append("%s: output references unknown resource '%s'" % [label, output_resource])
			continue
		var output_amount = output.get("amount")
		if not _is_number(output_amount) or float(output_amount) <= 0.0:
			errors.append("%s: output.amount must be a number > 0" % label)
			continue
		var requirements := validate_requirement_shapes(entry.get("requirements", []), label, errors)
		var unlock_skill: Variant = entry.get("unlock_skill", null)
		var unlock_text := ""
		if unlock_skill != null:
			if typeof(unlock_skill) != TYPE_STRING or String(unlock_skill).is_empty():
				errors.append("%s: unlock_skill must be null or a non-empty string" % label)
				continue
			unlock_text = String(unlock_skill)
			if not skill_ids.has(unlock_text):
				errors.append("%s: unlock_skill references unknown skill '%s'" % [label, unlock_text])
				continue
		defs.append({
			"id": id_text,
			"inputs": clean_inputs,
			"output": {"resource_id": String(output_resource), "amount": float(output_amount)},
			"requirements": requirements,
			"unlock_skill": null if unlock_skill == null else unlock_text,
		})
	return defs

static func validate_consumables(raw: Array, resource_ids: Dictionary, errors: Array) -> Array:
	var defs: Array = []
	var seen := {}
	for index in range(raw.size()):
		var label := "consumables[%d]" % index
		var entry = raw[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("%s: expected a JSON object" % label)
			continue
		var resource_id = entry.get("resource_id", "")
		if typeof(resource_id) != TYPE_STRING or String(resource_id).is_empty():
			errors.append("%s: resource_id must be a non-empty string" % label)
			continue
		var id_text := String(resource_id)
		label = "%s (%s)" % [label, id_text]
		if seen.has(id_text):
			errors.append("%s: duplicate consumable resource id" % label)
			continue
		seen[id_text] = true
		if not resource_ids.has(id_text):
			errors.append("%s: references unknown resource '%s'" % [label, id_text])
			continue
		var consume_requirements := validate_requirement_shapes(entry.get("consume_requirements", []), label, errors)
		var effects = entry.get("effects")
		if typeof(effects) != TYPE_DICTIONARY:
			errors.append("%s: effects must be an object" % label)
			continue
		var clean_effects := {}
		var effects_valid := true
		for key in effects:
			var key_text := String(key)
			if not SUPPORTED_CONSUMABLE_EFFECT_KEYS.has(key_text):
				errors.append("%s: unsupported consumable effect key '%s'" % [label, key_text])
				effects_valid = false
				break
			var value = effects[key]
			if not _is_number(value):
				errors.append("%s: effects.%s must be a finite number" % [label, key_text])
				effects_valid = false
				break
			clean_effects[key_text] = float(value)
		if not effects_valid:
			continue
		var lifetime_value = entry.get("lifetime_policy", null)
		var policy := DEFAULT_LIFETIME_POLICY
		if lifetime_value != null:
			if typeof(lifetime_value) != TYPE_STRING or String(lifetime_value).is_empty():
				errors.append("%s: lifetime_policy must be null or a non-empty string" % label)
				continue
			policy = String(lifetime_value)
		defs.append({
			"resource_id": id_text,
			"consume_requirements": consume_requirements,
			"effects": clean_effects,
			"lifetime_policy": policy,
		})
	return defs

static func validate_skills(raw: Array, resource_ids: Dictionary, errors: Array) -> Array:
	var defs: Array = []
	var seen := {}
	for index in range(raw.size()):
		var label := "skills[%d]" % index
		var entry = raw[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("%s: expected a JSON object" % label)
			continue
		var skill_id = entry.get("id", "")
		if typeof(skill_id) != TYPE_STRING or String(skill_id).is_empty():
			errors.append("%s: id must be a non-empty string" % label)
			continue
		var id_text := String(skill_id)
		label = "%s (%s)" % [label, id_text]
		if seen.has(id_text):
			errors.append("%s: duplicate skill id" % label)
			continue
		seen[id_text] = true
		var name_key = entry.get("name_key", "")
		if typeof(name_key) != TYPE_STRING or String(name_key).is_empty():
			errors.append("%s: name_key must be a non-empty string" % label)
			continue
		var max_level = entry.get("max_level")
		if not _is_number(max_level) or float(max_level) < 1.0:
			errors.append("%s: max_level must be a number >= 1" % label)
			continue
		var cost = entry.get("cost")
		if typeof(cost) != TYPE_DICTIONARY:
			errors.append("%s: cost must be an object" % label)
			continue
		var clean_cost := {}
		var cost_valid := true
		for resource_id in cost:
			if typeof(resource_id) != TYPE_STRING or String(resource_id).is_empty():
				errors.append("%s: cost keys must be non-empty resource ids" % label)
				cost_valid = false
				break
			var amount = cost[resource_id]
			if not _is_number(amount) or float(amount) < 0.0:
				errors.append("%s: cost.%s must be a number >= 0" % [label, resource_id])
				cost_valid = false
				break
			if not resource_ids.has(String(resource_id)):
				errors.append("%s: cost references unknown resource '%s'" % [label, resource_id])
				cost_valid = false
				break
			clean_cost[String(resource_id)] = float(amount)
		if not cost_valid:
			continue
		var cost_resource: Variant = entry.get("cost_resource", null)
		var cost_resource_text := ""
		if cost_resource == null:
			if clean_cost.size() > 1:
				errors.append("%s: cost_resource is required when cost has more than one resource" % label)
				continue
			elif clean_cost.size() == 1:
				cost_resource_text = String(clean_cost.keys()[0])
		else:
			if typeof(cost_resource) != TYPE_STRING or String(cost_resource).is_empty():
				errors.append("%s: cost_resource must be null or a non-empty string" % label)
				continue
			cost_resource_text = String(cost_resource)
		if not cost_resource_text.is_empty() and not resource_ids.has(cost_resource_text):
			errors.append("%s: cost_resource references unknown resource '%s'" % [label, cost_resource_text])
			continue
		var effect: Variant = entry.get("effect", null)
		var cleaned_effect := {}
		if effect != null:
			if typeof(effect) != TYPE_DICTIONARY:
				errors.append("%s: effect must be an object" % label)
				continue
			var effect_type = effect.get("type", "")
			if typeof(effect_type) != TYPE_STRING or String(effect_type).is_empty():
				errors.append("%s: effect.type must be a non-empty string" % label)
				continue
			var effect_amount = effect.get("amount", null)
			if not _is_number(effect_amount) or float(effect_amount) < 0.0:
				errors.append("%s: effect.amount must be a number >= 0" % label)
				continue
			cleaned_effect = {"type": String(effect_type), "amount": float(effect_amount)}
		defs.append({
			"id": id_text,
			"name_key": String(name_key),
			"max_level": maxi(1, int(floor(float(max_level)))),
			"cost": clean_cost,
			"cost_resource": cost_resource_text,
			"effect": cleaned_effect,
		})
	return defs

static func validate_requirement_shapes(requirements: Variant, label: String, errors: Array) -> Array:
	if typeof(requirements) != TYPE_ARRAY:
		errors.append("%s: requirements must be an array" % label)
		return []
	var cleaned: Array = []
	for index in range(requirements.size()):
		var item_label := "%s[%d]" % [label, index]
		var entry = requirements[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("%s: expected a JSON object" % item_label)
			continue
		var req_type = entry.get("type", "")
		if typeof(req_type) != TYPE_STRING or String(req_type).is_empty():
			errors.append("%s: requirement type must be a non-empty string" % item_label)
			continue
		var type_text := String(req_type)
		if not REQUIREMENT_TYPES.has(type_text):
			errors.append("%s: unknown requirement type '%s'" % [item_label, type_text])
			continue
		if type_text == "era":
			var era_value = entry.get("era")
			if not _is_number(era_value):
				errors.append("%s: era must be a number" % item_label)
				continue
			cleaned.append({"type": type_text, "era": int(floor(float(era_value)))})
		elif type_text == "building_level":
			var building_id = entry.get("building", "")
			if typeof(building_id) != TYPE_STRING or String(building_id).is_empty():
				errors.append("%s: building must be a non-empty string" % item_label)
				continue
			var building_level = entry.get("level")
			if not _is_number(building_level) or float(building_level) < 1.0:
				errors.append("%s: level must be a number >= 1" % item_label)
				continue
			cleaned.append({"type": type_text, "building": String(building_id), "level": maxi(1, int(floor(float(building_level))))})
		elif type_text == "skill_level":
			var skill_id = entry.get("skill", "")
			if typeof(skill_id) != TYPE_STRING or String(skill_id).is_empty():
				errors.append("%s: skill must be a non-empty string" % item_label)
				continue
			var skill_level = entry.get("level")
			if not _is_number(skill_level) or float(skill_level) < 1.0:
				errors.append("%s: level must be a number >= 1" % item_label)
				continue
			cleaned.append({"type": type_text, "skill": String(skill_id), "level": maxi(1, int(floor(float(skill_level))))})
		else:
			var owned_resource = entry.get("resource", "")
			if typeof(owned_resource) != TYPE_STRING or String(owned_resource).is_empty():
				errors.append("%s: resource must be a non-empty string" % item_label)
				continue
			cleaned.append({"type": type_text, "resource": String(owned_resource)})
	return cleaned

static func _is_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		return not is_nan(value) and not is_inf(value)
	return false
