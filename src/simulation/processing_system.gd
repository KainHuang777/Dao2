class_name ProcessingSystem
extends RefCounted
## Immediate atomic Craft remains the A contract; opt-in B uses timed local jobs.

static func craft(content: GameContent, state: GameState, payload: Dictionary) -> Dictionary:
	if not state.economy.is_empty():
		return IslandEconomy.command(content, state, "craft", payload)
	var catalog := content.processing_catalog
	if catalog.is_empty():
		return _failure("PROCESSING_NOT_ENABLED")
	var validated := ProcessingCatalog.validate(catalog)
	if not validated.ok:
		return _failure("INVALID_PROCESSING_CONTENT")
	var id: Variant = payload.get("recipe_id")
	if not id is String or not catalog.recipes.has(id):
		return _failure("UNKNOWN_RECIPE")
	var count: Variant = payload.get("count", 1)
	if not (count is int or count is float):
		return _failure("INVALID_COUNT")
	if is_nan(float(count)) or is_inf(float(count)) or float(count) != floor(float(count)) or float(count) < 1 or float(count) > 1000000:
		return _failure("INVALID_COUNT")
	if payload.get("recipe_version", 1) != 1:
		return _failure("RECIPE_VERSION_MISMATCH")
	var recipe: Dictionary = catalog.recipes[id]
	if state.era_id < int(recipe.era):
		return _failure("ERA_REQUIREMENT")
	for facility in recipe.facility:
		if int(state.buildings.get(facility, 0)) < int(recipe.facility[facility]):
			return _failure("FACILITY_REQUIREMENT", String(facility))
	var amounts := {}
	var touched: Array = recipe.inputs.keys()
	if not id in touched:
		touched.append(id)
	for resource in touched:
		var slot := ProcessingInventory.read(state, resource)
		if not slot.ok:
			return _failure(slot.error, resource)
		if not slot.unlocked:
			return _failure("RESOURCE_LOCKED", resource)
		amounts[resource] = slot.value
	var batch := AmountCompat.from_number(float(count))
	for resource in recipe.inputs:
		var cost: AmountCompat = AmountCompat.try_parse(recipe.inputs[resource]).value.multiply(batch)
		if cost.layer != 0 or cost.mag > 1.0e12:
			return _failure("UNSUPPORTED_AMOUNT", resource)
		# Layer-zero values were checked above. compare_to uses relative approximate
		# equality, which could accept a full warehouse or underpay a large cost.
		if amounts[resource].mag < cost.mag:
			return _failure("INSUFFICIENT_RESOURCE", resource)
		amounts[resource] = amounts[resource].subtract(cost)
	var output: AmountCompat = AmountCompat.try_parse(recipe.output).value.multiply(batch)
	var new_value: AmountCompat = amounts[id].add(output)
	var cap: AmountCompat = AmountCompat.try_parse(catalog.resources[id].cap).value
	if new_value.layer != 0 or new_value.mag > 1.0e12:
		return _failure("UNSUPPORTED_AMOUNT", id)
	if new_value.mag > cap.mag:
		return _failure("OUTPUT_FULL", id)
	amounts[id] = new_value
	# Validation completed; commit all deltas together. No clamping or partial batches.
	for resource in touched:
		ProcessingInventory.write(state, resource, amounts[resource])
	return {"ok": true, "events": [{"kind": "resource_crafted", "recipe_id": id, "recipe_version": 1, "count": int(count), "output": output.serialize()}], "changed_ids": touched}

static func _failure(error: String, resource_id: String = "") -> Dictionary:
	return {"ok": false, "error": error, "details": {"resource_id": resource_id}, "events": [], "changed_ids": []}
