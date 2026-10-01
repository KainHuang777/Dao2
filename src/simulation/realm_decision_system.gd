class_name RealmDecisionSystem
extends RefCounted

## RealmDecisionSystem
## Manages realm-specific strategic decisions (天道戰略決策) across all Nine Realms.
## Handles validation, resource costs, cooldown management, and deterministic reward application.

const DEFAULT_DECISIONS_PATH := "res://content/realms/realm_decisions.json"

static var _cached_decisions: Array = []
static var _is_initialized: bool = false

static func load_decisions(path: String = DEFAULT_DECISIONS_PATH) -> Array:
	if _is_initialized and not _cached_decisions.is_empty():
		return _cached_decisions

	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var text := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(text)
			if parsed is Array:
				_cached_decisions = parsed
				_is_initialized = true
				return _cached_decisions

	_cached_decisions = []
	_is_initialized = true
	return _cached_decisions

static func set_cached_decisions_for_testing(decisions: Array) -> void:
	_cached_decisions = decisions.duplicate(true)
	_is_initialized = true

static func ensure_initialized(state: GameState) -> void:
	if state == null:
		return
	if not (state.realm_decisions is Dictionary):
		state.realm_decisions = {}
	if not state.realm_decisions.has("cooldowns") or not (state.realm_decisions["cooldowns"] is Dictionary):
		state.realm_decisions["cooldowns"] = {}
	if not state.realm_decisions.has("usage_counts") or not (state.realm_decisions["usage_counts"] is Dictionary):
		state.realm_decisions["usage_counts"] = {}
	if not state.realm_decisions.has("total_decisions_executed"):
		state.realm_decisions["total_decisions_executed"] = 0

static func get_decision_by_id(decision_id: String) -> Dictionary:
	var decisions := load_decisions()
	for dec in decisions:
		if dec is Dictionary and String(dec.get("id", "")) == decision_id:
			return dec
	return {}

static func get_decisions_for_realm(realm_id: String) -> Array:
	var decisions := load_decisions()
	var result: Array = []
	for dec in decisions:
		if dec is Dictionary and String(dec.get("realm_id", "")) == realm_id:
			result.append(dec)
	return result

## Returns decision views for a realm with cooldown and usability status
static func get_realm_decisions_view(state: GameState, realm_id: String) -> Array:
	ensure_initialized(state)
	var decisions := get_decisions_for_realm(realm_id)
	var cooldowns: Dictionary = state.realm_decisions.get("cooldowns", {})
	var current_era: int = state.era_id
	var views: Array = []

	for dec in decisions:
		var d_id: String = String(dec.get("id", ""))
		var min_era: int = int(dec.get("min_era", 1))
		var cd_remain: float = float(cooldowns.get(d_id, 0.0))
		var era_met: bool = current_era >= min_era
		var cd_ready: bool = cd_remain <= 0.0
		var costs_met: bool = check_costs_met(state, dec.get("costs", {}))

		var view_item: Dictionary = dec.duplicate(true)
		view_item["cooldown_remaining"] = maxf(0.0, cd_remain)
		view_item["is_ready"] = era_met and cd_ready and costs_met
		view_item["era_met"] = era_met
		view_item["costs_met"] = costs_met
		views.append(view_item)

	return views

static func check_costs_met(state: GameState, costs: Dictionary) -> bool:
	if state == null:
		return false
	if costs.is_empty():
		return true

	for res_id in costs:
		var cost_val: float = float(costs[res_id])
		if cost_val <= 0.0:
			continue
		if res_id == "lifespan_seconds":
			continue
		if not state.resources.has(res_id):
			return false
		var cur_val: AmountCompat = state.resources[res_id].value
		if cur_val.compare_to(AmountCompat.from_number(cost_val)) < 0:
			return false

	return true

## Executes a realm strategic decision
static func execute_decision(state: GameState, realm_id: String, decision_id: String) -> Dictionary:
	ensure_initialized(state)
	var dec := get_decision_by_id(decision_id)
	if dec.is_empty():
		return {"ok": false, "error": "DECISION_NOT_FOUND", "message": "天道決策不存在: %s" % decision_id}

	var d_realm: String = String(dec.get("realm_id", ""))
	if not realm_id.is_empty() and d_realm != realm_id:
		return {"ok": false, "error": "REALM_MISMATCH", "message": "此決策屬於 %s，當前所選界域為 %s" % [d_realm, realm_id]}

	var min_era: int = int(dec.get("min_era", 1))
	if state.era_id < min_era:
		return {"ok": false, "error": "ERA_TOO_LOW", "message": "境界不足，需要境界 Era %d" % min_era}

	var cooldowns: Dictionary = state.realm_decisions["cooldowns"]
	var cd_remain: float = float(cooldowns.get(decision_id, 0.0))
	if cd_remain > 0.0:
		return {"ok": false, "error": "COOLDOWN_ACTIVE", "message": "決策尚在冷卻中（剩餘 %.1f 秒）" % cd_remain}

	var costs: Dictionary = dec.get("costs", {})
	if not check_costs_met(state, costs):
		return {"ok": false, "error": "INSUFFICIENT_COSTS", "message": "資糧不足，無法施行天道決策"}

	# Deduct costs atomically
	for res_id in costs:
		var cost_val: float = float(costs[res_id])
		if cost_val <= 0.0:
			continue
		if res_id == "lifespan_seconds":
			# Advance elapsed seconds (lifespan burn)
			state.total_elapsed_seconds += cost_val
		elif state.resources.has(res_id):
			var cur_amt: AmountCompat = state.resources[res_id].value
			state.resources[res_id]["value"] = cur_amt.subtract(AmountCompat.from_number(cost_val))

	# Apply cooldown and usage
	var base_cd: float = float(dec.get("cooldown_seconds", 60.0))
	cooldowns[decision_id] = base_cd

	var counts: Dictionary = state.realm_decisions["usage_counts"]
	counts[decision_id] = int(counts.get(decision_id, 0)) + 1
	state.realm_decisions["total_decisions_executed"] = int(state.realm_decisions.get("total_decisions_executed", 0)) + 1

	# Apply effects
	var effects: Dictionary = dec.get("effects", {})
	var applied_summary: Dictionary = {}

	# 1. Resource grants
	if effects.has("resources") and effects["resources"] is Dictionary:
		var res_dict: Dictionary = effects["resources"]
		for res_key in res_dict:
			var gain_val: float = float(res_dict[res_key])
			if gain_val > 0.0:
				if not state.resources.has(res_key):
					state.resources[res_key] = {
						"value": AmountCompat.from_number(gain_val),
						"unlocked": true,
						"ever_obtained": true
					}
				else:
					var cur_amt: AmountCompat = state.resources[res_key].value
					state.resources[res_key]["value"] = cur_amt.add(AmountCompat.from_number(gain_val))
					state.resources[res_key]["unlocked"] = true
					state.resources[res_key]["ever_obtained"] = true
		applied_summary["resources"] = res_dict

	# 2. Training seconds grant
	if effects.has("training_seconds"):
		var t_sec := float(effects.get("training_seconds", 0.0))
		if t_sec > 0.0:
			state.training_seconds += t_sec
			applied_summary["training_seconds"] = t_sec

	# 3. Dao Heart bonus
	if effects.has("dao_heart_bonus"):
		var dh_bonus := float(effects.get("dao_heart_bonus", 0.0))
		if dh_bonus > 0.0:
			if state.dao_heart == null:
				state.dao_heart = AmountCompat.zero()
			state.dao_heart = state.dao_heart.add(AmountCompat.from_number(dh_bonus))
			applied_summary["dao_heart_bonus"] = dh_bonus

	# 4. Buff grant
	if effects.has("buff_id"):
		var b_id := String(effects.get("buff_id", ""))
		if not b_id.is_empty():
			BuffSystem.apply_buff(state, b_id)
			applied_summary["buff_id"] = b_id

	var log_msg: String = String(effects.get("log_text", "施行天道決策成功。"))
	return {
		"ok": true,
		"decision_id": decision_id,
		"realm_id": d_realm,
		"cooldown_seconds": base_cd,
		"applied_effects": applied_summary,
		"log_text": log_msg
	}

## Ticks cooldown timers down with delta time
static func advance_time(state: GameState, delta_seconds: float) -> void:
	if state == null or delta_seconds <= 0.0:
		return
	ensure_initialized(state)
	var cooldowns: Dictionary = state.realm_decisions.get("cooldowns", {})
	if cooldowns.is_empty():
		return

	var keys := cooldowns.keys()
	for k in keys:
		var rem: float = float(cooldowns[k])
		if rem > 0.0:
			rem -= delta_seconds
			if rem <= 0.0:
				cooldowns.erase(k)
			else:
				cooldowns[k] = rem
