class_name ContentLoader
extends RefCounted

const MANIFEST_FILE := "manifest.json"
const SUPPORTED_MANIFEST_VERSION := 1
const DEFAULT_COST_FACTOR := 1.15
const RESOURCE_TYPES := ["basic", "crafted", "advanced"]
const ALLOWED_BONUS_KEYS := ["all_rate", "all_max", "synthetic_max_mult"]
const RESOURCE_OPTIONAL_FIELDS := ["name_key", "category", "display_group", "display_order", "unlock"]
const BUILDING_OPTIONAL_FIELDS := ["name_key", "display_group", "display_order", "requirements"]
const RESOURCE_CATEGORIES := ["basic", "crafted", "advanced"]

static func load_directory(base_dir: String) -> Dictionary:
	var manifest_path := base_dir.path_join(MANIFEST_FILE)
	if not FileAccess.file_exists(manifest_path):
		return {"ok": false, "errors": ["missing manifest: %s" % manifest_path]}
	var errors: Array = []
	var manifest = _parse_json_file(manifest_path, errors, "manifest")
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	if typeof(manifest) != TYPE_DICTIONARY:
		return {"ok": false, "errors": ["manifest: expected a JSON object"]}
	if int(manifest.get("manifest_version", 0)) != SUPPORTED_MANIFEST_VERSION:
		return {"ok": false, "errors": ["manifest: unsupported manifest_version %s" % str(manifest.get("manifest_version"))]}
	var resource_files: Variant = manifest.get("resource_files", [])
	var building_files: Variant = manifest.get("building_files", [])
	var era_files: Variant = manifest.get("era_files", [])
	if typeof(resource_files) != TYPE_ARRAY or typeof(building_files) != TYPE_ARRAY or typeof(era_files) != TYPE_ARRAY:
		return {"ok": false, "errors": ["manifest: resource_files, building_files and era_files must be arrays"]}
	var recipe_files: Variant = manifest.get("recipe_files", [])
	var consumable_files: Variant = manifest.get("consumable_files", [])
	var skill_files: Variant = manifest.get("skill_files", [])
	if typeof(recipe_files) != TYPE_ARRAY or typeof(consumable_files) != TYPE_ARRAY or typeof(skill_files) != TYPE_ARRAY:
		return {"ok": false, "errors": ["manifest: recipe_files, consumable_files and skill_files must be arrays if present"]}
	var resources: Array = []
	for entry in resource_files:
		_append_definition_file(base_dir, String(entry), "resources", resources, errors)
	var buildings: Array = []
	for entry in building_files:
		_append_definition_file(base_dir, String(entry), "buildings", buildings, errors)
	var eras: Array = []
	for entry in era_files:
		_append_definition_file(base_dir, String(entry), "eras", eras, errors)
	var recipes: Array = []
	for entry in recipe_files:
		_append_definition_file(base_dir, String(entry), "recipes", recipes, errors)
	var consumables: Array = []
	for entry in consumable_files:
		_append_definition_file(base_dir, String(entry), "consumables", consumables, errors)
	var skills: Array = []
	for entry in skill_files:
		_append_definition_file(base_dir, String(entry), "skills", skills, errors)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	return build_content(resources, buildings, eras, recipes, consumables, skills)

static func build_content(resources: Array, buildings: Array, eras: Array = [], recipes: Array = [], consumables: Array = [], skills: Array = []) -> Dictionary:
	var errors: Array = []
	var resource_defs: Array = _validate_resources(resources, errors)
	var building_defs: Array = _validate_buildings(buildings, errors)
	var era_defs: Array = _validate_eras(eras, errors)
	var resource_ids := {}
	for def in resource_defs:
		resource_ids[def.id] = true
	var building_ids := {}
	for def in building_defs:
		building_ids[def.id] = true
	_validate_references(building_defs, resource_ids, errors)
	_validate_era_references(era_defs, resource_ids, errors)
	var skill_defs: Array = ContentSchema.validate_skills(skills, resource_ids, errors)
	var skill_ids := {}
	for def in skill_defs:
		skill_ids[def.id] = true
	var recipe_defs: Array = ContentSchema.validate_recipes(recipes, resource_ids, skill_ids, errors)
	var consumable_defs: Array = ContentSchema.validate_consumables(consumables, resource_ids, errors)
	var building_ids_set := {}
	for def in building_defs:
		building_ids_set[def.id] = true
	for def in building_defs:
		_validate_requirement_targets(def.get("requirements", []), "buildings (%s)" % def.id, resource_ids, building_ids_set, skill_ids, errors)
	for def in recipe_defs:
		_validate_requirement_targets(def.get("requirements", []), "recipes (%s)" % def.id, resource_ids, building_ids_set, skill_ids, errors)
	for def in consumable_defs:
		_validate_requirement_targets(def.get("consume_requirements", []), "consumables (%s)" % def.resource_id, resource_ids, building_ids_set, skill_ids, errors)
	var cycle := _detect_prereq_cycle(building_defs)
	if not cycle.is_empty():
		errors.append("prereq cycle detected: %s" % " -> ".join(PackedStringArray(cycle)))
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var content := GameContent.new()
	for def in resource_defs:
		content.resource_ids.append(def.id)
		content.resources[def.id] = def
	for def in building_defs:
		content.building_ids.append(def.id)
		content.buildings[def.id] = def
	for def in era_defs:
		content.era_ids.append(def.id)
		content.eras[def.id] = def
	for def in recipe_defs:
		content.recipe_ids.append(def.id)
		content.recipes[def.id] = def
	for def in consumable_defs:
		content.consumable_ids.append(def.resource_id)
		content.consumables[def.resource_id] = def
	for def in skill_defs:
		content.skill_ids.append(def.id)
		content.skills[def.id] = def
	content.content_version = _compute_version(resource_defs, building_defs, era_defs, recipe_defs, consumable_defs, skill_defs)
	return {"ok": true, "content": content}

static func _validate_resources(raw: Array, errors: Array) -> Array:
	var defs: Array = []
	var seen := {}
	for index in range(raw.size()):
		var label := "resources[%d]" % index
		var entry = raw[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("%s: expected a JSON object" % label)
			continue
		var resource_id := String(entry.get("id", ""))
		if not resource_id.is_empty():
			label = "%s (%s)" % [label, resource_id]
		if resource_id.is_empty():
			errors.append("%s: id must be a non-empty string" % label)
			continue
		if seen.has(resource_id):
			errors.append("%s: duplicate resource id" % label)
			continue
		seen[resource_id] = true
		var resource_type := String(entry.get("type", ""))
		if not (resource_type in RESOURCE_TYPES):
			errors.append("%s: type must be one of %s" % [label, ", ".join(PackedStringArray(RESOURCE_TYPES))])
			continue
		var max_value = entry.get("max")
		if not _is_number(max_value) or float(max_value) < 0.0:
			errors.append("%s: max must be a number >= 0" % label)
			continue
		var rate_value = entry.get("rate")
		if not _is_number(rate_value) or float(rate_value) < 0.0:
			errors.append("%s: rate must be a number >= 0" % label)
			continue
		var unlocked_value = entry.get("unlocked")
		if typeof(unlocked_value) != TYPE_BOOL:
			errors.append("%s: unlocked must be a boolean" % label)
			continue
		var required_fields := ["id", "type", "max", "rate", "unlocked"]
		var unknown_fields: Array = []
		for entry_key in entry:
			var key_text := String(entry_key)
			if not key_text.is_empty() and not (key_text in required_fields) and not (key_text in RESOURCE_OPTIONAL_FIELDS):
				unknown_fields.append(key_text)
		if not unknown_fields.is_empty():
			errors.append("%s: unknown resource field(s) '%s'" % [label, ", ".join(PackedStringArray(unknown_fields))])
			continue
		var name_key := String(entry.get("name_key", ""))
		var category := String(entry.get("category", "basic"))
		if not category.is_empty() and not (category in RESOURCE_CATEGORIES):
			errors.append("%s: category must be one of %s" % [label, ", ".join(PackedStringArray(RESOURCE_CATEGORIES))])
			continue
		var display_group := String(entry.get("display_group", ""))
		var display_order_value = entry.get("display_order", 0)
		if not _is_number(display_order_value) or float(display_order_value) < 0.0:
			errors.append("%s: display_order must be a number >= 0" % label)
			continue
		var unlock_defs: Array = []
		if entry.get("unlock", null) != null:
			unlock_defs = ContentSchema.validate_requirement_shapes(entry.unlock, label, errors)
		defs.append({
			"id": resource_id,
			"type": resource_type,
			"max": float(max_value),
			"rate": float(rate_value),
			"unlocked": unlocked_value,
			"name_key": name_key,
			"category": "basic" if category.is_empty() else category,
			"display_group": display_group,
			"display_order": int(floor(float(display_order_value))),
			"unlock": unlock_defs,
		})
	return defs

static func _validate_buildings(raw: Array, errors: Array) -> Array:
	var defs: Array = []
	var seen := {}
	for index in range(raw.size()):
		var label := "buildings[%d]" % index
		var entry = raw[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("%s: expected a JSON object" % label)
			continue
		var building_id := String(entry.get("id", ""))
		if not building_id.is_empty():
			label = "%s (%s)" % [label, building_id]
		if building_id.is_empty():
			errors.append("%s: id must be a non-empty string" % label)
			continue
		if seen.has(building_id):
			errors.append("%s: duplicate building id" % label)
			continue
		seen[building_id] = true
		var known_fields := ["id", "era", "max_level", "cost_factor", "base_cost", "prereq", "effects", "effect_weight"]
		var unknown_fields: Array = []
		for entry_key in entry:
			var key_text := String(entry_key)
			if not key_text.is_empty() and not (key_text in known_fields) and not (key_text in BUILDING_OPTIONAL_FIELDS):
				unknown_fields.append(key_text)
		if not unknown_fields.is_empty():
			errors.append("%s: unknown building field(s) '%s'" % [label, ", ".join(PackedStringArray(unknown_fields))])
			continue
		var building_name_key := String(entry.get("name_key", ""))
		var building_display_group := String(entry.get("display_group", ""))
		var building_display_order_value = entry.get("display_order", 0)
		if not _is_number(building_display_order_value) or float(building_display_order_value) < 0.0:
			errors.append("%s: display_order must be a number >= 0" % label)
			continue
		var building_requirements: Array = []
		if entry.get("requirements", null) != null:
			building_requirements = ContentSchema.validate_requirement_shapes(entry.requirements, label, errors)
		var era_value = entry.get("era")
		if not _is_number(era_value) or float(era_value) < 1.0:
			errors.append("%s: era must be a number >= 1" % label)
			continue
		var max_level = entry.get("max_level")
		if not _is_number(max_level) or float(max_level) < 1.0:
			errors.append("%s: max_level must be a number >= 1" % label)
			continue
		var cost_factor = entry.get("cost_factor", DEFAULT_COST_FACTOR)
		if not _is_number(cost_factor) or float(cost_factor) <= 0.0:
			errors.append("%s: cost_factor must be a number > 0" % label)
			continue
		var base_cost = entry.get("base_cost")
		if typeof(base_cost) != TYPE_DICTIONARY:
			errors.append("%s: base_cost must be an object" % label)
			continue
		var base_cost_clean := {}
		var base_cost_valid := true
		for resource_id in base_cost:
			if typeof(resource_id) != TYPE_STRING or String(resource_id).is_empty():
				errors.append("%s: base_cost keys must be non-empty resource ids" % label)
				base_cost_valid = false
				break
			var amount = base_cost[resource_id]
			if not _is_number(amount) or float(amount) < 0.0:
				errors.append("%s: base_cost.%s must be a number >= 0" % [label, resource_id])
				base_cost_valid = false
				break
			base_cost_clean[String(resource_id)] = float(amount)
		if not base_cost_valid:
			continue
		var prereq = entry.get("prereq")
		var prereq_clean: Variant = null
		if prereq != null:
			if typeof(prereq) != TYPE_DICTIONARY or typeof(prereq.get("building", "")) != TYPE_STRING or String(prereq.get("building", "")).is_empty() or not _is_number(prereq.get("level")) or float(prereq.get("level")) < 1.0:
				errors.append("%s: prereq must be null or {building: non-empty string, level: number >= 1}" % label)
				continue
			prereq_clean = {
				"building": String(prereq.building),
				"level": maxi(1, int(floor(float(prereq.level)))),
			}
		var effects = entry.get("effects")
		if typeof(effects) != TYPE_DICTIONARY:
			errors.append("%s: effects must be an object" % label)
			continue
		var effects_clean := {}
		var needs_weight := false
		var effects_valid := true
		for key in effects:
			var key_text := String(key)
			if key_text.is_empty():
				errors.append("%s: effect keys must be non-empty strings" % label)
				effects_valid = false
				break
			var value = effects[key]
			if not _is_number(value) or float(value) < 0.0:
				errors.append("%s: effects.%s must be a number >= 0" % [label, key_text])
				effects_valid = false
				break
			if not key_text.ends_with("_max") and key_text != "all_max":
				needs_weight = true
			effects_clean[key_text] = float(value)
		if not effects_valid:
			continue
		var weight = entry.get("effect_weight", null)
		if weight != null and (not _is_number(weight) or float(weight) < 0.0):
			errors.append("%s: effect_weight must be null or a number >= 0" % label)
			continue
		if needs_weight and weight == null:
			errors.append("%s: effect_weight is required when rate effects are present" % label)
			continue
		defs.append({
			"id": building_id,
			"era": int(era_value),
			"max_level": int(max_level),
			"cost_factor": float(cost_factor),
			"base_cost": base_cost_clean,
			"prereq": prereq_clean,
			"effect_weight": null if weight == null else float(weight),
			"effects": effects_clean,
			"name_key": building_name_key,
			"display_group": building_display_group,
			"display_order": int(floor(float(building_display_order_value))),
			"requirements": building_requirements,
		})
	return defs

static func _validate_references(building_defs: Array, resource_ids: Dictionary, errors: Array) -> void:
	for def in building_defs:
		var label := "buildings (%s)" % def.id
		for resource_id in def.base_cost:
			if not resource_ids.has(resource_id):
				errors.append("%s: base_cost references unknown resource '%s'" % [label, resource_id])
		var prereq = def.prereq
		if prereq != null:
			var target = _find_building(building_defs, prereq.building)
			if target == null:
				errors.append("%s: prereq references unknown building '%s'" % [label, prereq.building])
		for key in def.effects:
			var key_text := String(key)
			if key_text == "all_rate" or key_text == "all_max" or key_text == "synthetic_max_mult":
				continue
			if key_text.ends_with("_max"):
				var target_resource := key_text.substr(0, key_text.length() - 4)
				if not resource_ids.has(target_resource):
					errors.append("%s: effect '%s' references unknown resource '%s'" % [label, key_text, target_resource])
			elif not resource_ids.has(key_text):
				errors.append("%s: effect '%s' references unknown resource" % [label, key_text])

static func _validate_era_references(era_defs: Array, resource_ids: Dictionary, errors: Array) -> void:
	for def in era_defs:
		var label := "eras (era %d)" % int(def.id)
		var level_up: Dictionary = def.level_up_requirements
		for resource_id in level_up.resources:
			if not resource_ids.has(resource_id):
				errors.append("%s: level_up_requirements.resources references unknown resource '%s'" % [label, resource_id])
		var lv9 = level_up.lv9_item
		if lv9 != null and not resource_ids.has(lv9.type):
			errors.append("%s: level_up_requirements.lv9_item references unknown resource '%s'" % [label, lv9.type])
		var upgrade: Dictionary = def.upgrade_requirements
		for key in upgrade.capacity:
			var target := String(key)
			if target.ends_with("_max"):
				target = target.substr(0, target.length() - 4)
			if not resource_ids.has(target):
				errors.append("%s: upgrade_requirements.capacity '%s' references unknown resource '%s'" % [label, key, target])

static func _validate_eras(raw: Array, errors: Array) -> Array:
	var defs: Array = []
	var seen := {}
	for index in range(raw.size()):
		var label := "eras[%d]" % index
		var entry = raw[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("%s: expected a JSON object" % label)
			continue
		var era_value = entry.get("id")
		if not _is_number(era_value) or float(era_value) < 1.0 or float(era_value) != floor(float(era_value)):
			errors.append("%s: id must be an integer >= 1" % label)
			continue
		var era_key := int(era_value)
		label = "%s (era %d)" % [label, era_key]
		if seen.has(era_key):
			errors.append("%s: duplicate era id" % label)
			continue
		seen[era_key] = true
		var max_level = entry.get("max_level")
		if not _is_number(max_level) or float(max_level) < 1.0:
			errors.append("%s: max_level must be a number >= 1" % label)
			continue
		var multiplier = entry.get("resource_multiplier", 1.0)
		if not _is_number(multiplier) or float(multiplier) <= 0.0:
			errors.append("%s: resource_multiplier must be a number > 0" % label)
			continue
		var lifespan = entry.get("lifespan")
		if not _is_number(lifespan) or float(lifespan) <= 0.0:
			errors.append("%s: lifespan must be a number > 0" % label)
			continue
		var level_up = entry.get("level_up_requirements")
		if typeof(level_up) != TYPE_DICTIONARY:
			errors.append("%s: level_up_requirements must be an object" % label)
			continue
		var base_time = level_up.get("base_time")
		if not _is_number(base_time) or float(base_time) < 0.0:
			errors.append("%s: level_up_requirements.base_time must be a number >= 0" % label)
			continue
		var time_multiplier = level_up.get("time_multiplier")
		if not _is_number(time_multiplier) or float(time_multiplier) <= 0.0:
			errors.append("%s: level_up_requirements.time_multiplier must be a number > 0" % label)
			continue
		var raw_resources = level_up.get("resources")
		if typeof(raw_resources) != TYPE_DICTIONARY:
			errors.append("%s: level_up_requirements.resources must be an object" % label)
			continue
		var clean_resources := {}
		var resources_valid := true
		for resource_id in raw_resources:
			var amount = raw_resources[resource_id]
			if typeof(resource_id) != TYPE_STRING or String(resource_id).is_empty() or not _is_number(amount) or float(amount) < 0.0:
				errors.append("%s: level_up_requirements.resources must map non-empty ids to numbers >= 0" % label)
				resources_valid = false
				break
			clean_resources[String(resource_id)] = float(amount)
		if not resources_valid:
			continue
		var lv9_clean: Variant = null
		var raw_lv9 = level_up.get("lv9_item", null)
		if raw_lv9 != null:
			if typeof(raw_lv9) != TYPE_DICTIONARY or typeof(raw_lv9.get("type", "")) != TYPE_STRING or String(raw_lv9.get("type", "")).is_empty() or not _is_number(raw_lv9.get("amount")) or float(raw_lv9.get("amount")) < 0.0:
				errors.append("%s: level_up_requirements.lv9_item must be null or {type: non-empty string, amount: number >= 0}" % label)
				continue
			lv9_clean = {"type": String(raw_lv9.type), "amount": float(raw_lv9.amount)}
		var upgrade_clean := {"level": 0.0, "capacity": {}}
		var raw_upgrade = entry.get("upgrade_requirements", null)
		if raw_upgrade != null:
			if typeof(raw_upgrade) != TYPE_DICTIONARY:
				errors.append("%s: upgrade_requirements must be an object" % label)
				continue
			var upgrade_level = raw_upgrade.get("level", 0)
			if not _is_number(upgrade_level) or float(upgrade_level) < 0.0:
				errors.append("%s: upgrade_requirements.level must be a number >= 0" % label)
				continue
			var raw_capacity = raw_upgrade.get("capacity", {})
			if typeof(raw_capacity) != TYPE_DICTIONARY:
				errors.append("%s: upgrade_requirements.capacity must be an object" % label)
				continue
			var clean_capacity := {}
			var capacity_valid := true
			for key in raw_capacity:
				var amount = raw_capacity[key]
				if typeof(key) != TYPE_STRING or String(key).is_empty() or not _is_number(amount) or float(amount) < 0.0:
					errors.append("%s: upgrade_requirements.capacity must map non-empty keys to numbers >= 0" % label)
					capacity_valid = false
					break
				clean_capacity[String(key)] = float(amount)
			if not capacity_valid:
				continue
			upgrade_clean = {"level": float(upgrade_level), "capacity": clean_capacity}
		defs.append({
			"id": era_key,
			"name": String(entry.get("name", "")),
			"max_level": int(max_level),
			"resource_multiplier": float(multiplier),
			"lifespan": float(lifespan),
			"level_up_requirements": {
				"base_time": float(base_time),
				"time_multiplier": float(time_multiplier),
				"resources": clean_resources,
				"lv9_item": lv9_clean,
			},
			"upgrade_requirements": upgrade_clean,
		})
	return defs

static func _validate_requirement_targets(requirements: Variant, label: String, resource_ids: Dictionary, building_ids: Dictionary, skill_ids: Dictionary, errors: Array) -> void:
	if not (requirements is Array):
		return
	for requirement in requirements:
		if not (requirement is Dictionary):
			continue
		var requirement_type := String(requirement.get("type", ""))
		if requirement_type == "building_level":
			var building_target := String(requirement.get("building", ""))
			if not building_ids.has(building_target):
				errors.append("%s: requirement references unknown building '%s'" % [label, building_target])
		elif requirement_type == "ever_obtained":
			var resource_target := String(requirement.get("resource", ""))
			if not resource_ids.has(resource_target):
				errors.append("%s: requirement references unknown resource '%s'" % [label, resource_target])
		elif requirement_type == "skill_level":
			var skill_target := String(requirement.get("skill", ""))
			if not skill_ids.is_empty() and not skill_ids.has(skill_target):
				errors.append("%s: requirement references unknown skill '%s'" % [label, skill_target])

static func _find_building(building_defs: Array, building_id: String) -> Variant:
	for def in building_defs:
		if def.id == building_id:
			return def
	return null

static func _detect_prereq_cycle(building_defs: Array) -> Array:
	var edges := {}
	for def in building_defs:
		var prereq = def.prereq
		edges[def.id] = "" if prereq == null else String(prereq.building)
	var finished := {}
	var active := {}
	for root in edges:
		if finished.has(root) or active.has(root):
			continue
		var path: Array = [root]
		while not path.is_empty():
			var node = path[path.size() - 1]
			if not active.has(node):
				active[node] = path.size() - 1
			var next_node = edges.get(node, "")
			if String(next_node).is_empty() or finished.has(next_node):
				finished[node] = true
				active.erase(node)
				path.pop_back()
				continue
			if active.has(next_node):
				var cycle: Array = []
				for index in range(int(active[next_node]), path.size()):
					cycle.append(path[index])
				cycle.append(next_node)
				return cycle
			path.append(next_node)
	return []

static func _compute_version(resource_defs: Array, building_defs: Array, era_defs: Array, recipe_defs: Array = [], consumable_defs: Array = [], skill_defs: Array = []) -> String:
	var payload := JSON.stringify({"resources": resource_defs, "buildings": building_defs, "eras": era_defs, "recipes": recipe_defs, "consumables": consumable_defs, "skills": skill_defs})
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(payload.to_utf8_buffer())
	return context.finish().hex_encode()

static func _append_definition_file(base_dir: String, relative_path: String, kind: String, target: Array, errors: Array) -> void:
	var file_path := base_dir.path_join(relative_path)
	if not FileAccess.file_exists(file_path):
		errors.append("%s file missing: %s" % [kind, file_path])
		return
	var parsed = _parse_json_file(file_path, errors, kind)
	if typeof(parsed) == TYPE_ARRAY:
		target.append_array(parsed)
	elif parsed != null:
		errors.append("%s file must contain a JSON array: %s" % [kind, file_path])

static func _parse_json_file(file_path: String, errors: Array, kind: String) -> Variant:
	var text := FileAccess.get_file_as_string(file_path)
	var parsed = JSON.parse_string(text)
	if parsed == null and text.strip_edges() != "null":
		errors.append("%s file is not valid JSON: %s" % [kind, file_path])
		return null
	return parsed

static func _is_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		return not is_nan(value) and not is_inf(value)
	return false

static func load_realms(file_path: String = "res://content/realms/realms.json") -> Dictionary:
	var errors: Array = []
	if not FileAccess.file_exists(file_path):
		return {"ok": false, "errors": ["realms file missing: %s" % file_path], "realms": []}
	var parsed = _parse_json_file(file_path, errors, "realms")
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "realms": []}
	if typeof(parsed) != TYPE_ARRAY:
		return {"ok": false, "errors": ["realms file must contain a JSON array"], "realms": []}
	var validated := _validate_realms(parsed, errors)
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "realms": []}
	return {"ok": true, "errors": [], "realms": validated}

static func _validate_realms(realms: Array, errors: Array) -> Array:
	var validated: Array = []
	var seen_ids := {}
	for index in range(realms.size()):
		var entry = realms[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("realms[%d]: expected object" % index)
			continue
		var r_id = entry.get("id", null)
		if typeof(r_id) != TYPE_STRING or String(r_id).is_empty():
			errors.append("realms[%d]: id must be non-empty string" % index)
			continue
		var id_str := String(r_id)
		if seen_ids.has(id_str):
			errors.append("duplicate realm id: %s" % id_str)
			continue
		seen_ids[id_str] = true
		var cult_factor := float(entry.get("cultivation_factor", 1.0))
		var lifespan_ratio := float(entry.get("lifespan_flow_ratio", 1.0))
		var pool_scale := float(entry.get("lingqi_pool_scale", 1.0))
		if cult_factor <= 0.0 or is_nan(cult_factor) or is_inf(cult_factor):
			errors.append("realm %s: cultivation_factor must be positive finite number" % id_str)
		if lifespan_ratio <= 0.0 or is_nan(lifespan_ratio) or is_inf(lifespan_ratio):
			errors.append("realm %s: lifespan_flow_ratio must be positive finite number" % id_str)
		if pool_scale <= 0.0 or is_nan(pool_scale) or is_inf(pool_scale):
			errors.append("realm %s: lingqi_pool_scale must be positive finite number" % id_str)
		validated.append({
			"id": id_str,
			"name": String(entry.get("name", id_str)),
			"title": String(entry.get("title", "")),
			"description": String(entry.get("description", "")),
			"law_summary": String(entry.get("law_summary", "")),
			"law_details": String(entry.get("law_details", "")),
			"status": String(entry.get("status", "locked")),
			"cultivation_factor": cult_factor,
			"lifespan_flow_ratio": lifespan_ratio,
			"lingqi_pool_scale": pool_scale,
			"allowed_resource_tags": Array(entry.get("allowed_resource_tags", []))
		})
	return validated

static func load_encounters(file_path: String = "res://content/encounters/encounters.json") -> Dictionary:
	var errors: Array = []
	if not FileAccess.file_exists(file_path):
		return {"ok": false, "errors": ["encounters file missing: %s" % file_path], "encounters": []}
	var parsed = _parse_json_file(file_path, errors, "encounters")
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "encounters": []}
	if typeof(parsed) != TYPE_ARRAY:
		return {"ok": false, "errors": ["encounters file must contain a JSON array"], "encounters": []}
	var validated := _validate_encounters(parsed, errors)
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "encounters": []}
	return {"ok": true, "errors": [], "encounters": validated}

static func _validate_encounters(encounters: Array, errors: Array) -> Array:
	var validated: Array = []
	var seen_ids := {}
	for index in range(encounters.size()):
		var entry = encounters[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("encounters[%d]: expected object" % index)
			continue
		var e_id = entry.get("id", null)
		if typeof(e_id) != TYPE_STRING or String(e_id).is_empty():
			errors.append("encounters[%d]: id must be non-empty string" % index)
			continue
		var id_str := String(e_id)
		if seen_ids.has(id_str):
			errors.append("duplicate encounter id: %s" % id_str)
			continue
		seen_ids[id_str] = true
		var options = entry.get("options", [])
		if typeof(options) != TYPE_ARRAY or options.is_empty():
			errors.append("encounter %s: must have non-empty options array" % id_str)
			continue
		validated.append(entry.duplicate(true))
	return validated

