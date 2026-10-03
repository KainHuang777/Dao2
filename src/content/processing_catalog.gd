class_name ProcessingCatalog
extends RefCounted
## Opt-in RES1-A contract. Release activation requires the RES1-B Web save gate and RES1-C integration.

static func load_file(path: String = "res://content/recipes/era1_3.json") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["processing catalog missing: " + path]}
	return validate(JSON.parse_string(FileAccess.get_file_as_string(path)))

static func validate(raw: Variant) -> Dictionary:
	var errors: Array = []
	if not raw is Dictionary or not raw.get("resources") is Dictionary or not raw.get("recipes") is Dictionary:
		return {"ok": false, "errors": ["resources and recipes must be dictionaries"]}
	if raw.get("version", "") != "res1-a-1":
		errors.append("unknown processing version")
	for id in raw.resources:
		var r: Variant = raw.resources[id]
		if not r is Dictionary or not _small_integer(r.get("era")) or not _small_integer(r.get("tier")) or not r.get("source") is String or not r.get("sinks") is Array:
			errors.append("invalid resource: " + String(id))
			continue
		if r.sinks.is_empty() or r.source.is_empty():
			errors.append("source/sink missing: " + String(id))
		if not _positive_amount(r.get("cap")):
			errors.append("invalid cap: " + String(id))
	for id in raw.recipes:
		var r: Variant = raw.recipes[id]
		if not r is Dictionary or not r.get("inputs") is Dictionary or not r.get("facility") is Dictionary or not r.get("skills") is Dictionary or not _small_integer(r.get("era")):
			errors.append("invalid recipe: " + String(id))
			continue
		if not raw.resources.has(id) or r.inputs.is_empty() or r.facility.is_empty() or not _positive_amount(r.get("output")) or r.get("version") != 1:
			errors.append("invalid output/version: " + String(id))
		elif raw.resources[id] is Dictionary and raw.resources[id].get("era") != r.era:
			errors.append("output Era mismatch: " + String(id))
		for input in r.inputs:
			if not raw.resources.has(input) or not _positive_amount(r.inputs[input]):
				errors.append("invalid ingredient: %s -> %s" % [id, input])
		for facility in r.facility:
			if not facility in ["hut", "herb_farm", "stone_mine"] or not _small_integer(r.facility[facility]):
				errors.append("invalid facility: " + String(id))
		# No new skill system is introduced in A. Legacy requirements live in the fixture.
		if not r.skills.is_empty():
			errors.append("unsupported skill gate: " + String(id))
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "catalog": {}}
	# Dependency closure checks both cycles and gates needing a future Era ingredient.
	var reachable: Array = []
	for era in [1, 2, 3]:
		for id in raw.resources:
			if not raw.recipes.has(id) and raw.resources[id] is Dictionary and int(raw.resources[id].get("era", 99)) <= era and not id in reachable:
				reachable.append(id)
		for _pass in range(raw.recipes.size()):
			for id in raw.recipes:
				var r: Variant = raw.recipes[id]
				if not r is Dictionary or not r.get("inputs") is Dictionary or int(r.get("era", 99)) > era or id in reachable:
					continue
				var ready := true
				for input in r.inputs:
					ready = ready and input in reachable
				if ready:
					reachable.append(id)
		for id in raw.recipes:
			if raw.recipes[id] is Dictionary and int(raw.recipes[id].get("era", 99)) <= era and not id in reachable:
				errors.append("unreachable recipe at Era %d: %s" % [era, id])
	return {"ok": errors.is_empty(), "errors": errors, "catalog": raw.duplicate(true) if errors.is_empty() else {}}

static func _positive_amount(raw: Variant) -> bool:
	if not raw is String:
		return false
	var parsed := AmountCompat.try_parse(raw)
	return bool(parsed.ok) and parsed.value.layer == 0 and parsed.value.sign > 0 and parsed.value.mag <= 1.0e12

static func _small_integer(raw: Variant) -> bool:
	return (raw is int or raw is float) and float(raw) >= 1.0 and float(raw) <= 3.0 and float(raw) == floor(float(raw))
