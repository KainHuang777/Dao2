class_name FortuneSystem
extends RefCounted

const DEFAULT_ENCOUNTERS_PATH := "res://content/encounters/encounters.json"
static var _cached_encounters: Array = []

static func get_encounters() -> Array:
	if not _cached_encounters.is_empty():
		return _cached_encounters
	var result := ContentLoader.load_encounters(DEFAULT_ENCOUNTERS_PATH)
	if result.ok and result.encounters is Array:
		_cached_encounters = result.encounters
	return _cached_encounters

static func set_cached_encounters_for_testing(encounters: Array) -> void:
	_cached_encounters = encounters

static func ensure_initialized(state: GameState) -> void:
	if state == null:
		return
	if not (state.fortune is Dictionary) or state.fortune.is_empty():
		var era: int = max(1, state.era_id)
		var base_cd: float = compute_cooldown_for_era(era)
		state.fortune = {
			"cooldown_remaining": base_cd,
			"pending_encounter": {},
			"encounter_history_count": 0,
			"total_fortunes_claimed": 0,
		}
	else:
		if not state.fortune.has("cooldown_remaining"):
			state.fortune["cooldown_remaining"] = compute_cooldown_for_era(max(1, state.era_id))
		if not state.fortune.has("pending_encounter"):
			state.fortune["pending_encounter"] = {}
		if not state.fortune.has("encounter_history_count"):
			state.fortune["encounter_history_count"] = 0
		if not state.fortune.has("total_fortunes_claimed"):
			state.fortune["total_fortunes_claimed"] = 0

## 依照境界決定每小時觸發次數（如 Era 1 每小時 1 次，Era 3 每小時最多 3 次）
static func compute_max_per_hour(era_id: int) -> int:
	return maxi(1, era_id)

## 依每小時次數計算冷卻時間（秒）
static func compute_cooldown_for_era(era_id: int) -> float:
	var per_hour := compute_max_per_hour(era_id)
	return 3600.0 / float(per_hour)

static func advance_time(state: GameState, delta_seconds: float, rng: SeededRandom = null) -> Dictionary:
	ensure_initialized(state)
	if delta_seconds <= 0.0:
		return {"triggered": false}
	
	# 若當前已有未決策奇遇，則冷卻倒數暫停，避免堆積干擾玩家
	var pending: Dictionary = state.fortune.get("pending_encounter", {})
	if not pending.is_empty():
		return {"triggered": false}
	
	var remaining: float = float(state.fortune.get("cooldown_remaining", 0.0))
	remaining -= delta_seconds
	
	if remaining <= 0.0:
		# 冷卻歸零，觸發奇遇
		var enc := trigger_fortune(state, rng)
		if not enc.is_empty():
			return {"triggered": true, "encounter": enc}
		else:
			# 若無可用奇遇，重置冷卻
			var era: int = max(1, state.era_id)
			state.fortune["cooldown_remaining"] = compute_cooldown_for_era(era)
			return {"triggered": false}
	else:
		state.fortune["cooldown_remaining"] = remaining
		return {"triggered": false}

static func trigger_fortune(state: GameState, rng: SeededRandom = null) -> Dictionary:
	ensure_initialized(state)
	var encounters := get_encounters()
	if encounters.is_empty():
		return {}
	
	# 篩選符合最低境界之奇遇
	var candidates: Array = []
	var weights: Array = []
	var current_era: int = state.era_id
	var current_weather: String = ""
	var current_shichen_name: String = ""
	
	if state.chrono is Dictionary:
		current_weather = String(state.chrono.get("current_weather", ""))
		var s_idx: int = int(state.chrono.get("current_shichen_index", 0))
		if s_idx >= 0 and s_idx < ChronoSystem.SHICHEN_DATA.size():
			current_shichen_name = String(ChronoSystem.SHICHEN_DATA[s_idx].get("short", ""))
	
	var aspiration: String = state.aspiration_realm
	
	for enc in encounters:
		var min_era: int = int(enc.get("min_era", 1))
		if current_era < min_era:
			continue
		
		var w: float = float(enc.get("weight", 100))
		# 天時天候偏向加成
		var w_bias: String = String(enc.get("weather_bias", ""))
		if not w_bias.is_empty() and w_bias == current_weather:
			w *= 1.5
		
		# 時辰偏向加成
		var s_bias: String = String(enc.get("shichen_bias", ""))
		if not s_bias.is_empty() and s_bias == current_shichen_name:
			w *= 1.5
		
		# 當前身處界域加成（身處該界主導奇遇，3.0x）
		var r_bias: String = String(enc.get("realm_bias", ""))
		var cur_realm: String = state.current_realm
		if not r_bias.is_empty() and not cur_realm.is_empty() and r_bias == cur_realm:
			w *= 3.0
		
		# 心印嚮往界域加成（九界道法聯動，2.0x）
		if not r_bias.is_empty() and not aspiration.is_empty() and r_bias == aspiration:
			w *= 2.0
		
		candidates.append(enc)
		weights.append(w)
	
	if candidates.is_empty():
		return {}
	
	# 輪盤賭加權隨機選擇
	var total_weight: float = 0.0
	for weight in weights:
		total_weight += weight
	
	var chosen_index: int = 0
	if rng != null:
		var roll: float = rng.next() * total_weight
		var accum: float = 0.0
		for i in range(candidates.size()):
			accum += weights[i]
			if roll <= accum:
				chosen_index = i
				break
	else:
		# 無注入 rng 時取首項作為確定性 fallback
		chosen_index = 0
	
	var chosen: Dictionary = candidates[chosen_index].duplicate(true)
	state.fortune["pending_encounter"] = chosen
	state.fortune["encounter_history_count"] = int(state.fortune.get("encounter_history_count", 0)) + 1
	# 重置冷卻
	state.fortune["cooldown_remaining"] = compute_cooldown_for_era(current_era)
	return chosen

static func resolve_fortune(state: GameState, option_index: int, _rng: SeededRandom = null) -> Dictionary:
	ensure_initialized(state)
	var pending: Dictionary = state.fortune.get("pending_encounter", {})
	if pending.is_empty():
		return {"ok": false, "error": "NO_PENDING_ENCOUNTER"}
	
	var options: Array = pending.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return {"ok": false, "error": "INVALID_OPTION_INDEX"}
	
	var option: Dictionary = options[option_index]
	var costs: Dictionary = option.get("costs", {})
	
	# 檢查消耗資源
	for res_id in costs:
		var cost_val: float = float(costs[res_id])
		if cost_val > 0.0:
			if not state.resources.has(res_id):
				return {"ok": false, "error": "INSUFFICIENT_RESOURCE:" + res_id}
			var cur_amt: AmountCompat = state.resources[res_id].value
			if cur_amt.compare_to(AmountCompat.from_number(cost_val)) < 0:
				return {"ok": false, "error": "INSUFFICIENT_RESOURCE:" + res_id}
	
	# 扣除消耗
	for res_id in costs:
		var cost_val: float = float(costs[res_id])
		if cost_val > 0.0:
			var cur_amt: AmountCompat = state.resources[res_id].value
			state.resources[res_id]["value"] = cur_amt.subtract(AmountCompat.from_number(cost_val))
	
	# 發放獎勵
	var rewards: Dictionary = option.get("rewards", {})
	var log_text: String = String(rewards.get("log_text", "獲得奇遇機緣。"))
	
	# 1. 資源獎勵
	var res_rewards: Dictionary = rewards.get("resources", {})
	for res_id in res_rewards:
		var gain_val: float = float(res_rewards[res_id])
		if gain_val > 0.0:
			if not state.resources.has(res_id):
				state.resources[res_id] = {
					"value": AmountCompat.from_number(gain_val),
					"unlocked": true,
					"ever_obtained": true
				}
			else:
				var cur_amt: AmountCompat = state.resources[res_id].value
				state.resources[res_id]["value"] = cur_amt.add(AmountCompat.from_number(gain_val))
				state.resources[res_id]["unlocked"] = true
				state.resources[res_id]["ever_obtained"] = true
	
	# 2. 修煉秒數獎勵
	var training_gain: float = float(rewards.get("training_seconds", 0.0))
	if training_gain > 0.0:
		state.training_seconds += training_gain
	
	# 3. 丹藥獎勵
	var pill_rewards: Dictionary = rewards.get("pills", {})
	for pill_id in pill_rewards:
		var count: int = int(pill_rewards[pill_id])
		if count > 0:
			if not state.pills.has(pill_id):
				state.pills[pill_id] = count
			else:
				state.pills[pill_id] = int(state.pills[pill_id]) + count
	
	# 4. BUFF 獎勵
	var buff_id: String = String(rewards.get("buff_id", ""))
	if not buff_id.is_empty():
		BuffSystem.apply_buff(state, buff_id)
	
	# 結算完畢，清除 pending 並記錄計數
	state.fortune["pending_encounter"] = {}
	state.fortune["total_fortunes_claimed"] = int(state.fortune.get("total_fortunes_claimed", 0)) + 1
	
	return {
		"ok": true,
		"log": log_text,
		"rewards": rewards
	}
