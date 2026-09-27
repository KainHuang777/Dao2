class_name GameSession
extends RefCounted

const KNOWN_COMMAND_TYPES := ["gather", "upgrade_building", "level_up_cultivation", "breakthrough_era", "reincarnate", "learn_talent", "refine_pill", "consume_pill"]
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
	if is_nan(elapsed_seconds) or is_inf(elapsed_seconds) or elapsed_seconds <= 0.0:
		return {"ok": true, "ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": null, "new_revision": state.revision}
	clock.advance(elapsed_seconds)
	var max_seconds := Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id, float(TalentSystem.compute_multipliers(state).lifespan_bonus))
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		state.tick_remainder_seconds = 0.0
		return {"ok": true, "ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": "lifespan_exhausted", "new_revision": state.revision}
	var accumulated := state.tick_remainder_seconds + elapsed_seconds
	var ticks := TimeAdvancer.ticks_for_elapsed(accumulated)
	if ticks <= 0:
		state.tick_remainder_seconds = accumulated
		return {
			"ok": true,
			"ticks_advanced": 0,
			"events": [],
			"changed_ids": [],
			"stopped": null,
			"new_revision": state.revision,
		}
	var result: Dictionary = TimeAdvancer.advance(state, content, ticks)
	state.tick_remainder_seconds = 0.0 if result.stopped != null else maxf(0.0, accumulated - float(ticks) * float(TimeAdvancer.SECONDS_PER_TICK))
	state.revision += 1
	result.ok = true
	result.new_revision = state.revision
	return result

func get_view() -> Dictionary:
	var era_definition: Variant = content.era(state.era_id)
	var era_multiplier := 1.0 if era_definition == null else float(era_definition.resource_multiplier)
	var rates := Production.compute_rates(content, state.buildings, era_multiplier * float(TalentSystem.compute_multipliers(state).global_production_multiplier))
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
		# Onboarding gates the first era only. Existing buildings and earlier-era
		# definitions remain manageable after cultivation advances.
		var visible: bool = level > 0 or (unlock.active and (building_id in unlock.buildings)) or (not unlock.active and int(definition.era) <= state.era_id)
		var costs := {}
		var affordable := false
		if level < cap:
			var onboarding_active := Onboarding.is_active(state.onboarding_version, state.era_id)
			var base_cost := BuildingCosts.resolve_base_cost(building_id, definition.base_cost, onboarding_active)
			var next_costs := BuildingCosts.compute_cost(base_cost, level, float(definition.cost_factor))
			affordable = visible and (level > 0 or state.era_id >= int(definition.era))
			if level == 0 and definition.prereq != null:
				var required_level := int(definition.prereq.level)
				if int(state.buildings.get(String(definition.prereq.building), 0)) < required_level:
					affordable = false
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
	var buff_multipliers := BuffSystem.compute_multipliers(state)
	var talent_lifespan_bonus := float(state.talents.get("lifespan_extension", 0)) * 0.1
	var pill_lifespan_bonus := float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + float(buff_multipliers.lifespan_bonus_years)
	var max_lifespan := Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id, talent_lifespan_bonus, pill_lifespan_bonus)
	var next_required := 0.0
	var era_view := {}
	var can_level_up := false
	var can_breakthrough := false
	var level_up_costs := {}
	var breakthrough_req := {}
	if era_def != null:
		if state.level < int(era_def.max_level):
			next_required = Cultivation.next_level_required_seconds(era_def, state.level, 0.0, 1.0)
			var costs: Dictionary = Cultivation.level_up_cost(era_def, state.level, 0.0)
			can_level_up = (state.training_seconds >= next_required)
			for r_id in costs:
				level_up_costs[r_id] = costs[r_id].serialize()
				var res_entry: Dictionary = state.resources.get(r_id, {})
				if res_entry.is_empty() or res_entry.value.add(AmountCompat.from_number(0.000001)).compare_to(costs[r_id]) < 0:
					can_level_up = false
		else:
			var next_era = content.era(state.era_id + 1)
			if next_era != null:
				var upg: Dictionary = era_def.get("upgrade_requirements", {})
				var upg_caps: Dictionary = upg.get("capacity", {})
				breakthrough_req = upg_caps
				can_breakthrough = true
				for r_id in upg_caps:
					var req_val: float = float(upg_caps[r_id])
					var cur_cap: AmountCompat = caps.get(r_id, AmountCompat.zero())
					if cur_cap.compare_to(AmountCompat.from_number(req_val)) < 0:
						can_breakthrough = false
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
		"tick_remainder_seconds": state.tick_remainder_seconds,
		"next_level_required_seconds": next_required,
		"max_lifespan_seconds": max_lifespan,
		"can_level_up": can_level_up,
		"can_breakthrough": can_breakthrough,
		"level_up_costs": level_up_costs,
		"breakthrough_requirements": breakthrough_req,
		"era": era_view,
		"resources": resources,
		"buildings": buildings,
		"next_objective": unlock.next_objective,
		"reincarnation_count": state.reincarnation_count,
		"highest_era": state.highest_era,
		"dao_heart": state.dao_heart.serialize() if state.dao_heart != null else "0",
		"dao_proof": state.dao_proof,
		"talents": state.talents.duplicate(true),
		"pills": state.pills.duplicate(true),
		"pill_effects": state.pill_effects.duplicate(true),
		"alchemy": AlchemySystem.get_view(state),
		"buffs": BuffSystem.get_active_buffs_view(state),
		"buff_multipliers": buff_multipliers,
		"realm": RealmSystem.get_view(state),
		"multipliers": TalentSystem.compute_multipliers(state),
		"reincarnation_preview": get_reincarnation_preview(),
	}

func reincarnate(mode: String = "normal") -> Dictionary:
	return submit({
		"command_id": "reincarnate_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "reincarnate",
		"expected_revision": state.revision,
		"payload": {"mode": mode},
	})

func learn_talent(talent_id: String) -> Dictionary:
	return submit({
		"command_id": "learn_talent_" + talent_id + "_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "learn_talent",
		"expected_revision": state.revision,
		"payload": {"talent_id": talent_id},
	})

func refine_pill(pill_id: String, count: int = 1) -> Dictionary:
	return submit({
		"command_id": "refine_pill_" + pill_id + "_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "refine_pill",
		"expected_revision": state.revision,
		"payload": {"pill_id": pill_id, "count": count},
	})

func consume_pill(pill_id: String, count: int = 1) -> Dictionary:
	return submit({
		"command_id": "consume_pill_" + pill_id + "_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "consume_pill",
		"expected_revision": state.revision,
		"payload": {"pill_id": pill_id, "count": count},
	})

func get_reincarnation_preview(mode: String = "normal") -> Dictionary:
	var b_sum := ReincarnationRules.building_level_sum(state.buildings)
	var reward := ReincarnationRules.compute_reward(b_sum, state.era_id, mode)
	var check := ReincarnationRules.check_eligibility(state, content)
	return {
		"eligible": bool(check.get("can_reincarnate", false)),
		"reason": String(check.get("reason", "")),
		"building_sum": b_sum,
		"dao_heart": (reward["dao_heart"] as AmountCompat).serialize(),
		"dao_proof": reward["dao_proof"],
		"era_floor": reward["era_floor"],
		"current_reincarnation_count": state.reincarnation_count,
		"next_reincarnation_count": state.reincarnation_count + 1,
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
		"level_up_cultivation", "breakthrough_era", "reincarnate":
			return true
		"learn_talent":
			var talent_id = payload.get("talent_id")
			if typeof(talent_id) != TYPE_STRING or String(talent_id).is_empty():
				return false
			return true
		"refine_pill", "consume_pill":
			var pill_id = payload.get("pill_id")
			if typeof(pill_id) != TYPE_STRING or String(pill_id).is_empty():
				return false
			return true
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

func apply_buff(buff_id: String, duration: float = -1.0, custom_effects: Dictionary = {}, transmigratable: bool = false) -> Dictionary:
	return submit({
		"command_id": "apply_buff_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "apply_buff",
		"expected_revision": state.revision,
		"payload": {
			"buff_id": buff_id,
			"duration": duration,
			"custom_effects": custom_effects,
			"transmigratable": transmigratable,
		},
	})

func remove_buff(buff_id: String) -> Dictionary:
	return submit({
		"command_id": "remove_buff_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "remove_buff",
		"expected_revision": state.revision,
		"payload": {"buff_id": buff_id},
	})

func switch_realm(target_realm_id: String) -> Dictionary:
	return submit({
		"command_id": "switch_realm_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "switch_realm",
		"expected_revision": state.revision,
		"payload": {"target_realm": target_realm_id},
	})

func upgrade_realm_outpost(outpost_id: String) -> Dictionary:
	return submit({
		"command_id": "upg_outpost_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "upgrade_realm_outpost",
		"expected_revision": state.revision,
		"payload": {"outpost_id": outpost_id},
	})

func join_sect(sect_name: String = "") -> Dictionary:
	return submit({
		"command_id": "join_sect_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "join_sect",
		"expected_revision": state.revision,
		"payload": {"sect_name": sect_name},
	})

func refresh_sect_tasks(force: bool = false) -> Dictionary:
	return submit({
		"command_id": "refresh_sect_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "refresh_sect_tasks",
		"expected_revision": state.revision,
		"payload": {"force": force},
	})

func start_sect_expedition(task_id: String) -> Dictionary:
	return submit({
		"command_id": "start_exped_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "start_sect_expedition",
		"expected_revision": state.revision,
		"payload": {"task_id": task_id},
	})

func claim_sect_expedition() -> Dictionary:
	return submit({
		"command_id": "claim_exped_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "claim_sect_expedition",
		"expected_revision": state.revision,
		"payload": {},
	})

func learn_sect_technique(technique_id: String) -> Dictionary:
	return submit({
		"command_id": "learn_tech_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "learn_sect_technique",
		"expected_revision": state.revision,
		"payload": {"technique_id": technique_id},
	})

func buy_sect_market_item(item_id: String) -> Dictionary:
	return submit({
		"command_id": "buy_item_" + str(state.revision) + "_" + str(Time.get_ticks_msec()),
		"type": "buy_sect_market_item",
		"expected_revision": state.revision,
		"payload": {"item_id": item_id},
	})
