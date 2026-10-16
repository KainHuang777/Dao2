class_name AlchemySystem
extends RefCounted

const COUNT_CAP := 99
const STACK_CAP := 99
const STACK_DECAY := 0.85
const HIGH_CULTIVATION_TRAINING := 300.0
const STACKED_PILL_IDS := ["high_cultivation_pill", "golden_tribulation_pill", "tribulation_pill"]

const PILLS := {
	"cultivation_pill": {
		"id": "cultivation_pill",
		"name": "聚靈丹",
		"tier": 1,
		"min_era": 1,
		"description": "凝聚草木精華所煉丹藥，服用後直接注入 60 秒修煉進度。",
		"cost": {
			"spirit_grass_low": 10.0,
			"lingli": 50.0,
		},
		"effects": {
			"instant_training_seconds": 60.0,
		}
	},
	"lifespan_pill": {
		"id": "lifespan_pill",
		"name": "延壽丹",
		"tier": 4,
		"min_era": 4,
		"description": "溫潤生機之靈丹，服用後使當世壽元上限永久增加 10 祀。",
		"cost": {
			"spirit_grass_low": 25.0,
			"wood": 20.0,
			"money": 30.0,
		},
		"effects": {
			"lifespan_bonus_years": 10.0,
		}
	},
	"foundation_pill": {
		"id": "foundation_pill",
		"name": "築基丹",
		"tier": 2,
		"min_era": 1,
		"description": "固本培元之靈丹，服用後永久提高當世全洞府資源產率 10%。不是突破至築基的必需品。",
		"cost": {
			"spirit_grass_low": 50.0,
			"black_copper": 20.0,
			"lingli": 200.0,
		},
		"effects": {
			"production_multiplier": 0.1,
		}
	},
	"high_cultivation_pill": {
		"id": "high_cultivation_pill",
		"name": "上品聚靈丹",
		"tier": 2,
		"min_era": 2,
		"description": "上品聚靈之丹，服用後注入 300 秒修煉進度；同一境界內連續服用效果遞減。",
		"cost": {
			"spirit_grass_100y": 5.0,
			"lingli": 200.0,
		},
		"effects": {
			"instant_training_seconds": 300.0,
		}
	},
	"spirit_tide_pill": {
		"id": "spirit_tide_pill",
		"name": "靈潮丹",
		"tier": 2,
		"min_era": 2,
		"description": "引動靈潮，300 秒內全洞府產率 +50%。",
		"cost": {
			"liquid": 2.0,
			"lingli": 100.0,
		},
		"effects": {
			"buff_id": "spirit_tide",
			"buff_duration_seconds": 300.0,
		}
	},
	"golden_tribulation_pill": {
		"id": "golden_tribulation_pill",
		"name": "金丹渡劫丹",
		"tier": 3,
		"min_era": 3,
		"description": "金丹護體，提高本境渡劫成功率（同境遞減）。",
		"cost": {
			"foundation_pill": 1.0,
			"stone_mid": 3.0,
			"spirit_grass_100y": 2.0,
		},
		"effects": {
			"tribulation_bonus": 0.03,
		}
	},
	"quick_output_pill": {
		"id": "quick_output_pill",
		"name": "速產丹",
		"tier": 3,
		"min_era": 3,
		"description": "丹力催發，600 秒內全洞府產率 +20%。",
		"cost": {
			"talisman": 1.0,
			"liquid": 2.0,
		},
		"effects": {
			"buff_id": "quick_output",
			"buff_duration_seconds": 600.0,
		}
	},
	"tribulation_pill": {
		"id": "tribulation_pill",
		"name": "渡劫丹",
		"tier": 4,
		"min_era": 4,
		"description": "渡劫護法之丹，提高本境渡劫成功率（同境遞減）。",
		"cost": {
			"golden_tribulation_pill": 1.0,
			"spirit_grass_100y": 3.0,
			"spirit_timber": 2.0,
		},
		"effects": {
			"tribulation_bonus": 0.05,
		}
	}
}

static func is_unlocked(state: GameState) -> bool:
	if state == null:
		return false
	if state.era_id >= 2:
		return true
	var herb_level: int = int(state.buildings.get("herb_farm", 0))
	return herb_level >= 3

static func get_definition(pill_id: String) -> Variant:
	return PILLS.get(pill_id, null)

static func stack_count(state: GameState, pill_id: String) -> int:
	if state == null:
		return 0
	var stacks: Dictionary = state.pill_effects.get("stacks", {}) as Dictionary
	return int(stacks.get(pill_id, 0))

static func reset_stacks(state: GameState) -> void:
	if state == null:
		return
	state.pill_effects.erase("stacks")

static func can_refine(state: GameState, pill_id: String, count: int = 1) -> Dictionary:
	if count < 1 or count > COUNT_CAP:
		return {"can_refine": false, "reason": "INVALID_COUNT"}
	if not is_unlocked(state):
		return {"can_refine": false, "reason": "ALCHEMY_LOCKED"}
	var def: Variant = get_definition(pill_id)
	if def == null:
		return {"can_refine": false, "reason": "UNKNOWN_PILL"}
	if state.era_id < int(def["min_era"]):
		return {"can_refine": false, "reason": "PILL_LOCKED", "required_era": int(def["min_era"])}
	var cost_def: Dictionary = def["cost"]
	var total_cost: Dictionary = {}
	for res_id in cost_def:
		var unit_cost := float(cost_def[res_id])
		if PILLS.has(res_id):
			var required_pills: int = int(round(unit_cost * float(count)))
			var current_pills: int = int(state.pills.get(res_id, 0))
			if current_pills < required_pills:
				return {
					"can_refine": false,
					"reason": "INSUFFICIENT_RESOURCE",
					"resource_id": res_id,
					"required": required_pills,
					"current": current_pills,
				}
			total_cost[res_id] = required_pills
		else:
			var required_amount := AmountCompat.from_number(unit_cost * float(count))
			total_cost[res_id] = required_amount
			var cur_res: Dictionary = state.resources.get(res_id, {})
			var cur_val: AmountCompat = cur_res.get("value", AmountCompat.zero())
			if cur_val.compare_to(required_amount) < 0:
				return {
					"can_refine": false,
					"reason": "INSUFFICIENT_RESOURCE",
					"resource_id": res_id,
					"required": required_amount.serialize(),
					"current": cur_val.serialize(),
				}
	return {"can_refine": true, "cost": total_cost, "count": count}

static func refine(state: GameState, pill_id: String, count: int = 1) -> Dictionary:
	var check := can_refine(state, pill_id, count)
	if not bool(check.get("can_refine", false)):
		return {"ok": false, "error": String(check.get("reason", "CANNOT_REFINE")), "details": check}
	var total_cost: Dictionary = check["cost"]
	var changed_ids: Array = []
	var used_pill_ingredient := false
	for res_id in total_cost:
		var cost_value: Variant = total_cost[res_id]
		if cost_value is int:
			state.pills[res_id] = int(state.pills.get(res_id, 0)) - int(cost_value)
			used_pill_ingredient = true
			if res_id == "foundation_pill" and state.resources.has("foundation_pill"):
				var fp_entry: Dictionary = state.resources["foundation_pill"]
				fp_entry.value = fp_entry.value.subtract(AmountCompat.from_number(float(int(cost_value)))).clamp_amount(AmountCompat.zero(), AmountCompat.from_number(999999999.0))
		else:
			var cost_amount := cost_value as AmountCompat
			var entry: Dictionary = state.resources[res_id]
			entry.value = entry.value.subtract(cost_amount)
			changed_ids.append(res_id)
	if used_pill_ingredient:
		changed_ids.append("pills")
	state.pills[pill_id] = int(state.pills.get(pill_id, 0)) + count
	if pill_id == "foundation_pill" and state.resources.has("foundation_pill"):
		var fp_entry: Dictionary = state.resources["foundation_pill"]
		fp_entry.value = fp_entry.value.add(AmountCompat.from_number(float(count)))
		fp_entry.ever_obtained = true
		if not changed_ids.has("foundation_pill"):
			changed_ids.append("foundation_pill")
	return {
		"ok": true,
		"events": [{
			"kind": "pill_refined",
			"pill_id": pill_id,
			"count": count,
			"new_total": state.pills[pill_id],
		}],
		"changed_ids": changed_ids,
	}

static func can_consume(state: GameState, pill_id: String, count: int = 1) -> Dictionary:
	if count < 1 or count > COUNT_CAP:
		return {"can_consume": false, "reason": "INVALID_COUNT"}
	var def: Variant = get_definition(pill_id)
	if def == null:
		return {"can_consume": false, "reason": "UNKNOWN_PILL"}
	var cur_count: int = int(state.pills.get(pill_id, 0))
	if cur_count < count:
		return {
			"can_consume": false,
			"reason": "INSUFFICIENT_PILL",
			"pill_id": pill_id,
			"required": count,
			"current": cur_count,
		}
	if STACKED_PILL_IDS.has(pill_id):
		var cur_stack: int = stack_count(state, pill_id)
		if cur_stack + count > STACK_CAP:
			return {
				"can_consume": false,
				"reason": "PILL_STACK_LIMIT",
				"pill_id": pill_id,
				"current": cur_stack,
				"required": count,
			}
	return {"can_consume": true, "count": count}

static func consume(state: GameState, pill_id: String, count: int = 1, training_ceiling: float = -1.0) -> Dictionary:
	var check := can_consume(state, pill_id, count)
	if not bool(check.get("can_consume", false)):
		return {"ok": false, "error": String(check.get("reason", "CANNOT_CONSUME")), "details": check}
	var def: Dictionary = get_definition(pill_id)
	state.pills[pill_id] = int(state.pills.get(pill_id, 0)) - count
	if pill_id == "foundation_pill" and state.resources.has("foundation_pill"):
		var fp_entry: Dictionary = state.resources["foundation_pill"]
		fp_entry.value = fp_entry.value.subtract(AmountCompat.from_number(float(count))).clamp_amount(AmountCompat.zero(), AmountCompat.from_number(999999999.0))
	var effects: Dictionary = def.get("effects", {}) as Dictionary
	var applied_effects: Dictionary = {}
	var buffs_changed := false
	if pill_id == "high_cultivation_pill":
		var stack_k: int = stack_count(state, pill_id)
		var decay_factor: float = pow(STACK_DECAY, float(stack_k))
		var decay_block: float = (1.0 - pow(STACK_DECAY, float(count))) / (1.0 - STACK_DECAY)
		var stacked_gain: float = HIGH_CULTIVATION_TRAINING * decay_factor * decay_block
		if training_ceiling > 0.0:
			var stacked_allowed: float = maxf(training_ceiling - state.training_seconds, 0.0)
			stacked_gain = minf(stacked_gain, stacked_allowed)
		state.training_seconds += stacked_gain
		applied_effects["training_gain"] = stacked_gain
	elif effects.has("instant_training_seconds"):
		var applied_gain := float(effects["instant_training_seconds"]) * float(count)
		if training_ceiling > 0.0:
			var allowed := maxf(training_ceiling - state.training_seconds, 0.0)
			applied_gain = minf(applied_gain, allowed)
		state.training_seconds += applied_gain
		applied_effects["training_gain"] = applied_gain
	if effects.has("lifespan_bonus_years"):
		var lifespan_gain := float(effects["lifespan_bonus_years"]) * float(count)
		state.pill_effects["lifespan_bonus_years"] = float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + lifespan_gain
		applied_effects["lifespan_gain"] = lifespan_gain
	if effects.has("production_multiplier"):
		var prod_gain := float(effects["production_multiplier"]) * float(count)
		state.pill_effects["production_multiplier"] = float(state.pill_effects.get("production_multiplier", 0.0)) + prod_gain
		applied_effects["production_gain"] = prod_gain
	if effects.has("buff_id"):
		var buff_id: String = String(effects["buff_id"])
		var buff_duration: float = float(effects.get("buff_duration_seconds", 0.0)) * float(count)
		BuffSystem.apply_buff(state, buff_id, buff_duration)
		applied_effects["buff_id"] = buff_id
		applied_effects["duration_seconds"] = minf(buff_duration, BuffSystem.MAX_TIMED_DURATION)
		buffs_changed = true
	if effects.has("tribulation_bonus"):
		applied_effects["tribulation_bonus_pending"] = float(effects["tribulation_bonus"]) * float(count)
	if STACKED_PILL_IDS.has(pill_id):
		var stack_map: Dictionary = state.pill_effects.get("stacks", {}) as Dictionary
		if not state.pill_effects.has("stacks"):
			state.pill_effects["stacks"] = stack_map
		stack_map[pill_id] = stack_count(state, pill_id) + count
	state.pill_effects["total_consumed"] = int(state.pill_effects.get("total_consumed", 0)) + count
	var changed_ids: Array = []
	if buffs_changed:
		changed_ids.append("buffs")
	return {
		"ok": true,
		"events": [{
			"kind": "pill_consumed",
			"pill_id": pill_id,
			"count": count,
			"applied_effects": applied_effects,
		}],
		"changed_ids": changed_ids,
	}

static func get_view(state: GameState) -> Dictionary:
	var unlocked := is_unlocked(state)
	var list: Array = []
	for pill_id in PILLS:
		var def: Dictionary = PILLS[pill_id]
		var count: int = int(state.pills.get(pill_id, 0)) if state != null else 0
		var can_ref: bool = bool(can_refine(state, pill_id, 1).get("can_refine", false)) if (unlocked and state != null) else false
		var can_con: bool = bool(can_consume(state, pill_id, 1).get("can_consume", false)) if (state != null) else false
		var min_era: int = int(def["min_era"])
		var locked_by_era: bool = state != null and state.era_id < min_era
		list.append({
			"id": pill_id,
			"name": def["name"],
			"tier": def["tier"],
			"min_era": min_era,
			"locked_by_era": locked_by_era,
			"description": def["description"],
			"cost": def["cost"],
			"effects": def["effects"],
			"count": count,
			"can_refine": can_ref,
			"manufacturing_link": IslandProgression.active(state) and state.era_id >= 2 and pill_id == "foundation_pill",
			"can_consume": can_con,
		})
	return {
		"unlocked": unlocked,
		"pills": list,
		"effects": state.pill_effects.duplicate(true) if state != null else {},
	}
