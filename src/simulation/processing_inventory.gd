class_name ProcessingInventory
extends RefCounted
## resources is authoritative; foundation_pill in pills is a compatibility mirror.
## Reads never add both stores and never initialize state on rejection.

static func read(state: GameState, resource_id: String) -> Dictionary:
	var entry: Variant = state.resources.get(resource_id)
	if not entry is Dictionary or not entry.get("value") is AmountCompat:
		return {"ok": false, "error": "MISSING_RESOURCE_ENTRY"}
	var value: AmountCompat = entry.value
	if value.layer != 0 or value.sign < 0 or is_nan(value.mag) or is_inf(value.mag) or value.mag > 1.0e12:
		return {"ok": false, "error": "UNSUPPORTED_AMOUNT"}
	if resource_id == "foundation_pill":
		var mirror: Variant = state.pills.get(resource_id, 0)
		if not (mirror is int or mirror is float) or float(mirror) != floor(float(mirror)) or float(value.sign) * value.mag != float(mirror):
			return {"ok": false, "error": "INVENTORY_CONFLICT"}
	return {"ok": true, "value": value.duplicate_amount(), "unlocked": bool(entry.get("unlocked", false))}

static func write(state: GameState, resource_id: String, value: AmountCompat) -> void:
	state.resources[resource_id].value = value
	state.resources[resource_id].ever_obtained = bool(state.resources[resource_id].ever_obtained) or value.sign > 0
	if resource_id == "foundation_pill":
		state.pills[resource_id] = int(value.mag) if value.sign > 0 else 0
