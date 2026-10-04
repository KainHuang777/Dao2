class_name AbodeScenery
extends RefCounted
## Optional, bounded home-island finds. This RNG never shares cosmetic/fortune streams.
const VERSION := 1
const MAX_ACTIVE := 2
const SLOT_COUNT := 4
const DEFINITIONS := {
	"wood": {"name": "靈木萌枝", "resource_id": "wood", "min": 5, "max": 9},
	"herb": {"name": "靈草花簇", "resource_id": "spirit_grass_low", "min": 3, "max": 5},
	"stone": {"name": "靈石露頭", "resource_id": "stone_low", "min": 2, "max": 4},
}

static func advance(state: GameState, elapsed: float) -> Array:
	var events: Array = []
	# A full island has no timer/RNG work or eligible-kind lookup to perform.
	if not state.abode_scenery.is_empty() and state.abode_scenery.active.size() >= MAX_ACTIVE:
		return events
	var eligible: Array = []
	for kind in DEFINITIONS:
		if bool(state.resources.get(DEFINITIONS[kind].resource_id, {}).get("unlocked", false)):
			eligible.append(kind)
	if eligible.is_empty() or elapsed <= 0.0:
		return events
	if state.abode_scenery.is_empty():
		var initial := SeededRandom.from_seed("abode-scenery-v1:" + state.world_address + ":" + str(state.reincarnation_count))
		state.abode_scenery = {"version": VERSION, "rng_state": initial.state, "serial": 0, "remaining": 12.0, "active": []}
	var data: Dictionary = state.abode_scenery
	# A full island pauses this clock; no backlog or refresh-generated new finds.
	while data.active.size() < MAX_ACTIVE:
		if elapsed < float(data.remaining):
			data.remaining = float(data.remaining) - elapsed
			break
		elapsed -= float(data.remaining)
		var rng := SeededRandom.from_state(int(data.rng_state))
		var candidates := eligible.duplicate()
		var slots: Array = range(SLOT_COUNT)
		for entry in data.active:
			candidates.erase(entry.kind)
			slots.erase(int(entry.slot))
		if candidates.is_empty():
			candidates = eligible.duplicate()
		var kind: String = candidates[rng.int_range(0, candidates.size() - 1)]
		var definition: Dictionary = DEFINITIONS[kind]
		data.serial = int(data.serial) + 1
		var entry := {"id": "%d:%d" % [state.reincarnation_count, int(data.serial)], "kind": kind,
			"slot": slots[rng.int_range(0, slots.size() - 1)], "amount": rng.int_range(int(definition.min), int(definition.max))}
		data.active.append(entry)
		data.remaining = float(rng.int_range(45, 90))
		data.rng_state = rng.state
		events.append({"kind": "abode_scenery_spawned", "find_id": entry.id})
	return events

static func claim(content: GameContent, state: GameState, find_id: String) -> Dictionary:
	if state.current_realm != "realm_human":
		return _failure("SCENERY_AWAY")
	var entries: Array = state.abode_scenery.get("active", [])
	for index in entries.size():
		var entry: Dictionary = entries[index]
		if String(entry.id) != find_id:
			continue
		var definition: Dictionary = DEFINITIONS[entry.kind]
		var resource_id: String = definition.resource_id
		var resource: Dictionary = state.resources.get(resource_id, {})
		if not bool(resource.get("unlocked", false)):
			return _failure("RESOURCE_LOCKED")
		var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
		var value: AmountCompat = resource.value
		var room: AmountCompat = (caps[resource_id] as AmountCompat).subtract(value)
		if room.compare_to(AmountCompat.zero()) <= 0:
			return _failure("SCENERY_CAPACITY_FULL")
		var amount := AmountCompat.from_number(int(entry.amount))
		if amount.compare_to(room) > 0:
			amount = room
		resource.value = value.add(amount)
		resource.ever_obtained = true
		entries.remove_at(index)
		AchievementSystem.record_stat(state, "total_harvests", 1)
		AchievementSystem.check_achievements(state, content)
		return {"ok": true, "events": [{"kind": "abode_scenery_claimed", "find_id": find_id,
			"name": definition.name, "resource_id": resource_id, "amount": amount.serialize()}],
			"changed_ids": ["abode_scenery", resource_id]}
	return _failure("SCENERY_NOT_FOUND")

static func get_view(state: GameState) -> Array:
	var result: Array = []
	if state.current_realm != "realm_human":
		return result
	for entry in state.abode_scenery.get("active", []):
		var definition: Dictionary = DEFINITIONS[entry.kind]
		if bool(state.resources.get(definition.resource_id, {}).get("unlocked", false)):
			var view: Dictionary = entry.duplicate(true)
			view.name = definition.name
			view.resource_id = definition.resource_id
			result.append(view)
	return result

static func validate_snapshot(value: Variant) -> String:
	if not value is Dictionary:
		return "SCENERY_TYPE"
	if value.is_empty():
		return "" # Additive migration of existing schema-2 saves.
	if not SaveCodec._is_int(value.get("version")) or int(value.version) != VERSION:
		return "SCENERY_VERSION"
	for key in ["rng_state", "serial"]:
		if not SaveCodec._is_int(value.get(key)) or float(value[key]) < 0.0:
			return "SCENERY_FIELD:" + key
	if float(value.rng_state) > 4294967295.0 or float(value.serial) > 9007199254740991.0:
		return "SCENERY_RANGE"
	if not SaveCodec._is_number(value.get("remaining")) or float(value.remaining) < 0.0 or float(value.remaining) > 90.0:
		return "SCENERY_TIMER"
	if not value.get("active") is Array or value.active.size() > MAX_ACTIVE:
		return "SCENERY_ACTIVE"
	var ids: Array = []
	var slots: Array = []
	for entry in value.active:
		if not entry is Dictionary or not entry.get("id") is String or entry.id.is_empty() or ids.has(entry.id):
			return "SCENERY_ID"
		if not entry.get("kind") is String or not DEFINITIONS.has(entry.kind):
			return "SCENERY_KIND"
		if not SaveCodec._is_int(entry.get("slot")) or int(entry.slot) < 0 or int(entry.slot) >= SLOT_COUNT or slots.has(int(entry.slot)):
			return "SCENERY_SLOT"
		var definition: Dictionary = DEFINITIONS[entry.kind]
		if not SaveCodec._is_int(entry.get("amount")) or int(entry.amount) < int(definition.min) or int(entry.amount) > int(definition.max):
			return "SCENERY_AMOUNT"
		ids.append(entry.id)
		slots.append(int(entry.slot))
	return ""

static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error, "events": [], "changed_ids": []}
