class_name RealmSystem
extends RefCounted

const REALM_HUMAN := "realm_human"
const REALM_SPIRIT := "realm_spirit"

const SPIRIT_OUTPOSTS := {
	"celestial_hub": {
		"id": "celestial_hub",
		"name": "天樞陣眼",
		"description": "維繫跨界靈脈之核心樞紐。運轉消耗人界靈石，轉化提純為極品靈晶。",
		"max_level": 10,
		"base_cost": {"money": 100.0, "stone_low": 50.0},
		"cost_factor": 1.6,
		"stone_drain_per_s": 0.2, # 消耗人界靈石
		"crystal_prod_per_s": 0.1, # 產出靈晶
	},
	"pure_pool": {
		"id": "pure_pool",
		"name": "化靈仙池",
		"description": "融合天外仙露與靈晶，凝練天青靈液。池水生生不息，反哺全洞府修煉速度！",
		"max_level": 10,
		"base_cost": {"spirit_crystal": 10.0, "lingli": 300.0},
		"cost_factor": 1.8,
		"crystal_drain_per_s": 0.05,
		"nectar_prod_per_s": 0.05,
		"cultivation_boost_per_level": 0.15, # 每級 +15% 修煉速度反哺
	},
	"void_beacon": {
		"id": "void_beacon",
		"name": "虛空引靈台",
		"description": "感應太虛星辰靈機，擴展極品靈晶與天青靈液容量，並提升全靈界設施產能 10%。",
		"max_level": 10,
		"base_cost": {"spirit_crystal": 20.0, "black_copper": 100.0},
		"cost_factor": 1.8,
		"crystal_cap_per_level": 100.0,
		"nectar_cap_per_level": 50.0,
		"realm_mult_per_level": 0.10,
	}
}

static func is_spirit_realm_unlocked(state: GameState) -> bool:
	if state == null:
		return false
	if state.era_id >= 2 or state.reincarnation_count >= 1:
		return true
	var r_data: Dictionary = state.realms_data.get(REALM_SPIRIT, {})
	return bool(r_data.get("unlocked", false))

static func ensure_spirit_data(state: GameState) -> Dictionary:
	if not state.realms_data.has(REALM_SPIRIT):
		state.realms_data[REALM_SPIRIT] = {
			"unlocked": is_spirit_realm_unlocked(state),
			"spirit_crystal": 0.0,
			"azure_nectar": 0.0,
			"outposts": {
				"celestial_hub": 0,
				"pure_pool": 0,
				"void_beacon": 0,
			}
		}
	var data: Dictionary = state.realms_data[REALM_SPIRIT]
	if not data.has("outposts"):
		data["outposts"] = {"celestial_hub": 0, "pure_pool": 0, "void_beacon": 0}
	if is_spirit_realm_unlocked(state):
		data["unlocked"] = true
	return data

static func switch_realm(state: GameState, target_realm: String) -> Dictionary:
	if state == null:
		return {"ok": false, "error": "NULL_STATE"}
	if target_realm != REALM_HUMAN and target_realm != REALM_SPIRIT:
		return {"ok": false, "error": "INVALID_REALM"}
	if target_realm == REALM_SPIRIT and not is_spirit_realm_unlocked(state):
		return {"ok": false, "error": "SPIRIT_REALM_LOCKED"}

	var from_realm: String = state.current_realm
	state.current_realm = target_realm
	state.world_address = WorldAddress.default_for_realm(target_realm).to_address_string()
	ensure_spirit_data(state)

	return {
		"ok": true,
		"from_realm": from_realm,
		"current_realm": target_realm,
		"world_address": state.world_address,
		"events": [{
			"kind": "realm_switched",
			"from": from_realm,
			"to": target_realm,
			"world_address": state.world_address,
		}]
	}

static func compute_outpost_cost(outpost_id: String, cur_level: int) -> Dictionary:
	var def: Variant = SPIRIT_OUTPOSTS.get(outpost_id, null)
	if def == null:
		return {}
	var base_cost: Dictionary = def["base_cost"]
	var factor: float = float(def["cost_factor"])
	var mult: float = pow(factor, float(cur_level))
	var costs: Dictionary = {}
	for res_id in base_cost:
		costs[res_id] = float(base_cost[res_id]) * mult
	return costs

static func can_upgrade_outpost(state: GameState, outpost_id: String) -> Dictionary:
	if not is_spirit_realm_unlocked(state):
		return {"can_upgrade": false, "reason": "REALM_LOCKED"}
	var def: Variant = SPIRIT_OUTPOSTS.get(outpost_id, null)
	if def == null:
		return {"can_upgrade": false, "reason": "UNKNOWN_OUTPOST"}
	# Cost checks are read-only, including a first rejected construction.
	var data: Dictionary = state.realms_data.get(REALM_SPIRIT, {})
	var cur_lvl := int(data.get("outposts", {}).get(outpost_id, 0))
	if cur_lvl >= int(def["max_level"]):
		return {"can_upgrade": false, "reason": "MAX_LEVEL"}

	var costs := compute_outpost_cost(outpost_id, cur_lvl)
	for res_id in costs:
		var req := float(costs[res_id])
		if res_id == "spirit_crystal":
			if float(data.get("spirit_crystal", 0.0)) < req:
				return {"can_upgrade": false, "reason": "INSUFFICIENT_CRYSTAL", "required": req}
		elif res_id == "azure_nectar":
			if float(data.get("azure_nectar", 0.0)) < req:
				return {"can_upgrade": false, "reason": "INSUFFICIENT_NECTAR", "required": req}
		else:
			var cur_entry: Dictionary = state.resources.get(res_id, {})
			var cur_val: float = cur_entry.get("value", AmountCompat.zero()).to_float()
			if cur_val < req:
				return {"can_upgrade": false, "reason": "INSUFFICIENT_HUMAN_RESOURCE", "resource": res_id, "required": req}

	return {"can_upgrade": true, "costs": costs, "next_level": cur_lvl + 1}

static func upgrade_outpost(state: GameState, outpost_id: String) -> Dictionary:
	var check := can_upgrade_outpost(state, outpost_id)
	if not bool(check.get("can_upgrade", false)):
		return {"ok": false, "error": String(check.get("reason", "CANNOT_UPGRADE"))}
	var data := ensure_spirit_data(state)
	var costs: Dictionary = check["costs"]
	for res_id in costs:
		var req := float(costs[res_id])
		if res_id == "spirit_crystal":
			data["spirit_crystal"] = maxf(0.0, float(data.get("spirit_crystal", 0.0)) - req)
		elif res_id == "azure_nectar":
			data["azure_nectar"] = maxf(0.0, float(data.get("azure_nectar", 0.0)) - req)
		else:
			var entry: Dictionary = state.resources[res_id]
			entry.value = entry.value.subtract(AmountCompat.from_number(req)).clamp_amount(AmountCompat.zero(), AmountCompat.from_number(999999999.0))
	data["outposts"][outpost_id] = int(data["outposts"].get(outpost_id, 0)) + 1
	return {
		"ok": true,
		"outpost_id": outpost_id,
		"new_level": data["outposts"][outpost_id],
		"events": [{
			"kind": "outpost_upgraded",
			"outpost_id": outpost_id,
			"new_level": data["outposts"][outpost_id]
		}]
	}

static func get_feedback_cultivation_boost(state: GameState) -> float:
	if state == null or state.era_id < 2 or not state.realms_data.has(REALM_SPIRIT):
		return 0.0
	var data: Dictionary = state.realms_data[REALM_SPIRIT]
	var pool_lvl := int(data.get("outposts", {}).get("pure_pool", 0))
	return float(pool_lvl) * 0.15

static func tick(state: GameState, elapsed_seconds: float) -> Dictionary:
	if state == null or elapsed_seconds <= 0.0:
		return {}
	if state.era_id < 2 or not is_spirit_realm_unlocked(state):
		return {}
	var data := ensure_spirit_data(state)
	var outposts: Dictionary = data.get("outposts", {})
	var hub_lvl := int(outposts.get("celestial_hub", 0))
	var pool_lvl := int(outposts.get("pure_pool", 0))
	var beacon_lvl := int(outposts.get("void_beacon", 0))

	# Caps
	var crystal_cap := 100.0 + float(beacon_lvl) * 100.0
	var nectar_cap := 50.0 + float(beacon_lvl) * 50.0
	var realm_mult := 1.0 + float(beacon_lvl) * 0.10

	var cur_crystal := float(data.get("spirit_crystal", 0.0))
	var cur_nectar := float(data.get("azure_nectar", 0.0))

	# Capacity is reserved before charging inputs; a full output consumes nothing.
	if hub_lvl > 0:
		var stone_entry: Dictionary = state.resources.get("stone_low", {})
		var cur_stone: float = stone_entry.get("value", AmountCompat.zero()).to_float()
		var crystal_gain := minf(maxf(0.0, crystal_cap - cur_crystal), float(hub_lvl) * 0.1 * realm_mult * elapsed_seconds)
		crystal_gain = minf(crystal_gain, cur_stone * realm_mult * 0.5)
		if crystal_gain > 0.0:
			stone_entry.value = stone_entry.value.subtract(AmountCompat.from_number(crystal_gain * 2.0 / realm_mult))
			cur_crystal += crystal_gain
	if pool_lvl > 0:
		var nectar_gain := minf(maxf(0.0, nectar_cap - cur_nectar), float(pool_lvl) * 0.05 * realm_mult * elapsed_seconds)
		nectar_gain = minf(nectar_gain, cur_crystal * realm_mult)
		if nectar_gain > 0.0:
			cur_crystal -= nectar_gain / realm_mult
			cur_nectar += nectar_gain

	data["spirit_crystal"] = cur_crystal
	data["azure_nectar"] = cur_nectar

	return {
		"spirit_crystal": cur_crystal,
		"azure_nectar": cur_nectar,
		"crystal_cap": crystal_cap,
		"nectar_cap": nectar_cap,
	}

static func get_view(state: GameState) -> Dictionary:
	var unlocked := is_spirit_realm_unlocked(state)
	var current_realm: String = state.current_realm if state != null else REALM_HUMAN
	var data := ensure_spirit_data(state) if state != null else {}
	var outposts_view: Array = []
	var beacon_lvl := int(data.get("outposts", {}).get("void_beacon", 0)) if state != null else 0
	var crystal_cap := 100.0 + float(beacon_lvl) * 100.0
	var nectar_cap := 50.0 + float(beacon_lvl) * 50.0

	for op_id in SPIRIT_OUTPOSTS:
		var def: Dictionary = SPIRIT_OUTPOSTS[op_id]
		var cur_lvl: int = int(data.get("outposts", {}).get(op_id, 0)) if state != null else 0
		var can_upg := can_upgrade_outpost(state, op_id) if state != null else {"can_upgrade": false}
		outposts_view.append({
			"id": op_id,
			"name": def["name"],
			"description": def["description"],
			"level": cur_lvl,
			"max_level": def["max_level"],
			"costs": compute_outpost_cost(op_id, cur_lvl),
			"can_upgrade": bool(can_upg.get("can_upgrade", false)),
			"upgrade_reason": String(can_upg.get("reason", "")),
		})

	var addr_str: String = state.world_address if state != null else WorldAddress.default_home().to_address_string()
	var parsed_addr := WorldAddress.parse(addr_str)
	var law_data := ScaleLawContract.get_realm_law(current_realm)

	return {
		"current_realm": current_realm,
		"world_address": addr_str,
		"scale_tier": WorldAddress.ScaleTier.ABODE,
		"realm_law": law_data,
		"unlocked": unlocked,
		"spirit_crystal": float(data.get("spirit_crystal", 0.0)),
		"azure_nectar": float(data.get("azure_nectar", 0.0)),
		"crystal_cap": crystal_cap,
		"nectar_cap": nectar_cap,
		"cultivation_feedback_boost": get_feedback_cultivation_boost(state),
		"outposts": outposts_view,
	}
