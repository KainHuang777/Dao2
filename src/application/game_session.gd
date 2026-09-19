class_name GameSession
extends RefCounted

const KNOWN_COMMAND_TYPES := ["gather", "upgrade_building"]
const COMMAND_REGISTRY_LIMIT := 256

var content: GameContent
var state: GameState
var clock: GameClock
var _command_order: Array = []
var _results: Dictionary = {}

static func create_new_game(content: GameContent) -> GameSession:
	var session := GameSession.new()
	session.content = content
	session.clock = GameClock.create(0.0)
	var state := GameState.new()
	state.era_id = 1
	state.level = 1
	state.onboarding_version = Onboarding.SCHEMA_VERSION
	var unlock := Onboarding.unlock_state(state.era_id, state.onboarding_version, state.buildings)
	for resource_id in content.resource_ids:
		state.resources[resource_id] = {
			"value": AmountCompat.zero(),
			"unlocked": resource_id in unlock.resources,
			"ever_obtained": false,
		}
	for building_id in content.building_ids:
		state.buildings[building_id] = 0
	session.state = state
	return session

func submit(command: Dictionary) -> Dictionary:
	if not _is_valid_shape(command):
		return _error_result("INVALID_COMMAND", {})
	if not (String(command.type) in KNOWN_COMMAND_TYPES):
		return _error_result("UNKNOWN_COMMAND", {"type": String(command.type)})
	var command_id := String(command.command_id)
	if _results.has(command_id):
		var original: Dictionary = _results[command_id]
		return {
			"ok": true,
			"duplicate": true,
			"new_revision": int(original.new_revision),
			"events": [],
			"changed_ids": [],
			"replayed": original,
		}
	if int(command.expected_revision) != state.revision:
		return _error_result("STALE_REVISION", {"expected": int(command.expected_revision), "actual": state.revision})
	var result: Dictionary = CommandProcessor.apply(content, state, command)
	result.duplicate = false
	if bool(result.ok):
		state.revision += 1
		result.new_revision = state.revision
		_remember(command_id, result)
	else:
		result.new_revision = state.revision
	return result

func advance_time(elapsed_seconds: float) -> Dictionary:
	var ticks := TimeAdvancer.ticks_for_elapsed(elapsed_seconds)
	if elapsed_seconds > 0.0:
		clock.advance(elapsed_seconds)
	if ticks <= 0:
		return {
			"ok": true,
			"ticks_advanced": 0,
			"events": [],
			"changed_ids": [],
			"stopped": null,
			"new_revision": state.revision,
		}
	var result: Dictionary = TimeAdvancer.advance(state, content, ticks)
	state.revision += 1
	result.ok = true
	result.new_revision = state.revision
	return result

func get_view() -> Dictionary:
	var rates := Production.compute_rates(content, state.buildings)
	var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
	var unlock := Onboarding.unlock_state(state.era_id, state.onboarding_version, state.buildings)
	var resources := {}
	for resource_id in content.resource_ids:
		var definition: Dictionary = content.resources[resource_id]
		var entry: Dictionary = state.resources[resource_id]
		resources[resource_id] = {
			"type": String(definition.type),
			"value": entry.value.serialize(),
			"rate": rates[resource_id].serialize(),
			"cap": caps[resource_id].serialize(),
			"unlocked": bool(entry.unlocked),
			"visible": bool(entry.unlocked),
			"ever_obtained": bool(entry.ever_obtained),
		}
	var buildings := {}
	for building_id in content.building_ids:
		var definition: Dictionary = content.buildings[building_id]
		var level := int(state.buildings.get(building_id, 0))
		var cap := CommandProcessor.level_cap(definition)
		var visible: bool = unlock.active and (building_id in unlock.buildings)
		var costs := {}
		var affordable := false
		if level < cap:
			var onboarding_active := Onboarding.is_active(state.onboarding_version, state.era_id)
			var base_cost := BuildingCosts.resolve_base_cost(building_id, definition.base_cost, onboarding_active)
			var next_costs := BuildingCosts.compute_cost(base_cost, level, float(definition.cost_factor))
			affordable = true
			for resource_id in next_costs:
				costs[resource_id] = next_costs[resource_id].serialize()
				var entry: Dictionary = state.resources[resource_id]
				var available: AmountCompat = entry.value.add(AmountCompat.from_number(0.000001))
				if available.compare_to(next_costs[resource_id]) < 0:
					affordable = false
		buildings[building_id] = {
			"level": level,
			"level_cap": cap,
			"max_level": int(definition.max_level),
			"era": int(definition.era),
			"prereq": definition.prereq,
			"visible": visible,
			"costs": costs,
			"affordable": affordable,
		}
	var era_def = content.era(state.era_id)
	var max_lifespan := Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id)
	var next_required := 0.0
	var era_view := {}
	if era_def != null:
		next_required = Cultivation.next_level_required_seconds(era_def, state.level, 0.0, 1.0)
		era_view = {
			"id": int(era_def.id),
			"name": String(era_def.name),
			"max_level": int(era_def.max_level),
			"resource_multiplier": float(era_def.resource_multiplier),
			"lifespan": float(era_def.lifespan),
		}
	return {
		"revision": state.revision,
		"era_id": state.era_id,
		"level": state.level,
		"onboarding_version": state.onboarding_version,
		"content_version": content.content_version,
		"training_seconds": state.training_seconds,
		"total_elapsed_seconds": state.total_elapsed_seconds,
		"next_level_required_seconds": next_required,
		"max_lifespan_seconds": max_lifespan,
		"era": era_view,
		"resources": resources,
		"buildings": buildings,
		"next_objective": unlock.next_objective,
	}

func _is_valid_shape(command: Dictionary) -> bool:
	if typeof(command) != TYPE_DICTIONARY:
		return false
	var command_id = command.get("command_id")
	if typeof(command_id) != TYPE_STRING or String(command_id).is_empty():
		return false
	var command_type = command.get("type")
	if typeof(command_type) != TYPE_STRING:
		return false
	var expected_revision = command.get("expected_revision")
	if not (typeof(expected_revision) == TYPE_INT or typeof(expected_revision) == TYPE_FLOAT):
		return false
	var payload = command.get("payload")
	if typeof(payload) != TYPE_DICTIONARY:
		return false
	match String(command_type):
		"gather":
			var resource_id = payload.get("resource_id")
			if typeof(resource_id) != TYPE_STRING or String(resource_id).is_empty():
				return false
		"upgrade_building":
			var building_id = payload.get("building_id")
			if typeof(building_id) != TYPE_STRING or String(building_id).is_empty():
				return false
	return true

func _remember(command_id: String, result: Dictionary) -> void:
	if not _results.has(command_id):
		_command_order.append(command_id)
	_results[command_id] = result
	while _command_order.size() > COMMAND_REGISTRY_LIMIT:
		_results.erase(_command_order.pop_front())

func _error_result(error: String, detail: Dictionary) -> Dictionary:
	var result := {"ok": false, "duplicate": false, "error": error, "new_revision": state.revision, "events": [], "changed_ids": []}
	if not detail.is_empty():
		result.detail = detail
	return result
