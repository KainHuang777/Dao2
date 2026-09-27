class_name AlchemySystem
extends RefCounted

const PILLS := {
	"cultivation_pill": {
		"id": "cultivation_pill",
		"name": "聚靈丹",
		"tier": 1,
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
		"tier": 1,
		"description": "溫潤生機之靈丹，服用後使當世壽元上限永久增加 5 祀（300 秒）。",
		"cost": {
			"spirit_grass_low": 25.0,
			"wood": 20.0,
			"money": 30.0,
		},
		"effects": {
			"lifespan_bonus_years": 5.0,
		}
	},
	"foundation_pill": {
		"id": "foundation_pill",
		"name": "築基丹",
		"tier": 2,
		"description": "洗髓伐毛、固本培元之極品靈丹，為突破築基之至寶。服用後永久提高全洞府資源產率 10%。",
		"cost": {
			"spirit_grass_low": 50.0,
			"black_copper": 20.0,
			"lingli": 200.0,
		},
		"effects": {
			"production_multiplier": 0.1,
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

static func can_refine(state: GameState, pill_id: String, count: int = 1) -> Dictionary:
	if count <= 0:
		return {"can_refine": false, "reason": "INVALID_COUNT"}
	if not is_unlocked(state):
		return {"can_refine": false, "reason": "ALCHEMY_LOCKED"}
	var def: Variant = get_definition(pill_id)
	if def == null:
		return {"can_refine": false, "reason": "UNKNOWN_PILL"}
	var cost_def: Dictionary = def["cost"]
	var total_cost: Dictionary = {}
	for res_id in cost_def:
		var unit_cost := float(cost_def[res_id])
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
	for res_id in total_cost:
		var cost_amount: AmountCompat = total_cost[res_id]
		var entry: Dictionary = state.resources[res_id]
		entry.value = entry.value.subtract(cost_amount)
		changed_ids.append(res_id)
	state.pills[pill_id] = int(state.pills.get(pill_id, 0)) + count
	# If foundation_pill is represented in resources table, keep in sync
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
	if count <= 0:
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
	return {"can_consume": true, "count": count}

static func consume(state: GameState, pill_id: String, count: int = 1) -> Dictionary:
	var check := can_consume(state, pill_id, count)
	if not bool(check.get("can_consume", false)):
		return {"ok": false, "error": String(check.get("reason", "CANNOT_CONSUME")), "details": check}
	var def: Dictionary = get_definition(pill_id)
	state.pills[pill_id] = int(state.pills.get(pill_id, 0)) - count
	if pill_id == "foundation_pill" and state.resources.has("foundation_pill"):
		var fp_entry: Dictionary = state.resources["foundation_pill"]
		fp_entry.value = fp_entry.value.subtract(AmountCompat.from_number(float(count))).clamp_amount(AmountCompat.zero(), AmountCompat.from_number(999999999.0))
	var effects: Dictionary = def.get("effects", {})
	var applied_effects: Dictionary = {}
	if effects.has("instant_training_seconds"):
		var training_gain := float(effects["instant_training_seconds"]) * float(count)
		state.training_seconds += training_gain
		applied_effects["training_gain"] = training_gain
	if effects.has("lifespan_bonus_years"):
		var lifespan_gain := float(effects["lifespan_bonus_years"]) * float(count)
		state.pill_effects["lifespan_bonus_years"] = float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + lifespan_gain
		applied_effects["lifespan_gain"] = lifespan_gain
	if effects.has("production_multiplier"):
		var prod_gain := float(effects["production_multiplier"]) * float(count)
		state.pill_effects["production_multiplier"] = float(state.pill_effects.get("production_multiplier", 0.0)) + prod_gain
		applied_effects["production_gain"] = prod_gain
	state.pill_effects["total_consumed"] = int(state.pill_effects.get("total_consumed", 0)) + count
	return {
		"ok": true,
		"events": [{
			"kind": "pill_consumed",
			"pill_id": pill_id,
			"count": count,
			"applied_effects": applied_effects,
		}],
		"changed_ids": [],
	}

static func get_view(state: GameState) -> Dictionary:
	var unlocked := is_unlocked(state)
	var list: Array = []
	for pill_id in PILLS:
		var def: Dictionary = PILLS[pill_id]
		var count: int = int(state.pills.get(pill_id, 0)) if state != null else 0
		var can_ref: bool = bool(can_refine(state, pill_id, 1).get("can_refine", false)) if (unlocked and state != null) else false
		var can_con: bool = bool(can_consume(state, pill_id, 1).get("can_consume", false)) if (state != null) else false
		list.append({
			"id": pill_id,
			"name": def["name"],
			"tier": def["tier"],
			"description": def["description"],
			"cost": def["cost"],
			"effects": def["effects"],
			"count": count,
			"can_refine": can_ref,
			"can_consume": can_con,
		})
	return {
		"unlocked": unlocked,
		"pills": list,
		"effects": state.pill_effects.duplicate(true) if state != null else {},
	}
