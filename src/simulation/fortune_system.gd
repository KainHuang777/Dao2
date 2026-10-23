class_name FortuneSystem
extends RefCounted

const DEFAULT_ENCOUNTERS_PATH := "res://content/encounters/encounters.json"
static var _cached_encounters: Array = []

## Encounter data retains legacy names; use the live economy when available.
static func resource_key(resources: Dictionary, raw_id: String) -> String:
	var canonical := str({"herb":"spirit_grass_low", "lingqi":"lingli"}.get(raw_id,raw_id))
	return canonical if resources.has(canonical) else raw_id

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
	if state.story_version == StoryProgress.VERSION and not state.fortune.has("rng_version"):
		state.fortune.rng_version = 1
		state.fortune.rng_state = SeededRandom.from_seed("fortune-v1|%d" % state.tribulation_seed).state

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
	if not state.fortune.get("pending_encounter", {}).is_empty():
		return state.fortune.pending_encounter.duplicate(true)
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
		
		if str(enc.get("id", "")).begins_with("enc_p1_") and not StoryProgress.eligible(state, enc):
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
	var owns_rng := rng == null and state.story_version == StoryProgress.VERSION
	if owns_rng: rng = SeededRandom.from_state(int(state.fortune.rng_state))
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
	
	if owns_rng: state.fortune.rng_state = rng.state
	var chosen: Dictionary = candidates[chosen_index].duplicate(true)
	if chosen.get("content_batch") == "content-p1-story": chosen = StorySaveContract.freeze(chosen, state)
	chosen["instance_id"] = ("%d|%d|%s" % [state.reincarnation_count + 1, int(state.fortune.get("encounter_history_count", 0)) + 1, str(chosen.get("id", ""))]).sha256_text()
	state.fortune["pending_encounter"] = chosen
	state.fortune["encounter_history_count"] = int(state.fortune.get("encounter_history_count", 0)) + 1
	# 重置冷卻
	state.fortune["cooldown_remaining"] = compute_cooldown_for_era(current_era)
	return chosen

static func resolve_fortune(state: GameState, option_index: int, _rng: SeededRandom = null, source: String = "", expected_instance: String = "", content: GameContent = null) -> Dictionary:
	ensure_initialized(state)
	var pending: Dictionary = state.fortune.get("pending_encounter", {})
	if pending.is_empty():
		return {"ok": false, "error": "NO_PENDING_ENCOUNTER"}
	
	if pending.has("instance_id") and not LifeLedger._hash(pending.instance_id):
		return {"ok": false, "error": "INVALID_PENDING_INSTANCE"}
	var instance := DecisionReceipt.pending_id(state)
	if not expected_instance.is_empty() and expected_instance != instance:
		return {"ok": false, "error": "STALE_PENDING_ENCOUNTER"}
	var options: Array = pending.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return {"ok": false, "error": "INVALID_OPTION_INDEX"}
	
	var payload_error := StorySaveContract.validate_pending(pending)
	if not payload_error.is_empty(): return {"ok": false, "error": payload_error}
	var option: Dictionary = options[option_index]
	var costs: Dictionary = option.get("costs", {})
	
	var is_story: bool = pending.get("content_batch") == "content-p1-story"
	if is_story:
		if content == null: return {"ok": false, "error": "STORY_CONTENT_REQUIRED"}
		var story_error := StoryProgress.transaction_error(state, content, costs, option.get("rewards", {}))
		if not story_error.is_empty(): return {"ok": false, "error": story_error}
	# P1 pill cap applies to all encounter sources, including retained legacy invites.
	for id in option.get("rewards", {}).get("pills", {}):
		if id in AlchemySystem.P1_IDS and int(state.pills.get(id, 0)) + int(option.rewards.pills[id]) > AlchemySystem.P1_INVENTORY_CAP: return {"ok": false, "error": "PILL_INVENTORY_LIMIT"}
	# 檢查消耗資源
	for raw_id in costs:
		var res_id := resource_key(state.resources,str(raw_id))
		var cost_val: float = float(costs[raw_id])
		if cost_val > 0.0:
			if not state.resources.has(res_id):
				return {"ok": false, "error": "INSUFFICIENT_RESOURCE:" + res_id}
			var cur_amt: AmountCompat = state.resources[res_id].value
			if cur_amt.compare_to(AmountCompat.from_number(cost_val)) < 0:
				return {"ok": false, "error": "INSUFFICIENT_RESOURCE:" + res_id}
	
	var receipt := {"version": DecisionReceipt.VERSION, "instance_id": instance,
		"source": (source if not source.is_empty() else "fortune:" + instance).sha256_text(),
		"life_id": state.reincarnation_count + 1, "at": state.total_elapsed_seconds,
		"encounter_id": str(pending.get("id", "")), "title": str(pending.get("title", "")),
		"option_index": option_index, "option": str(option.get("text", "")), "log": "",
		"resources": {}, "training": {}, "pills": {}, "buff": {}}
	var ids := {}
	for raw in costs: ids[resource_key(state.resources, str(raw))] = true
	for raw in option.get("rewards", {}).get("resources", {}): ids[resource_key(state.resources, str(raw))] = true
	for id in ids:
		receipt.resources[id] = {"before": _stock(state, id).serialize(), "paid": "0", "nominal": "0", "gained": "0", "overflow": "0", "after": "0"}
	# 扣除消耗
	for raw_id in costs:
		var res_id := resource_key(state.resources,str(raw_id))
		var cost_val: float = float(costs[raw_id])
		if cost_val > 0.0:
			var cur_amt: AmountCompat = state.resources[res_id].value
			state.resources[res_id].value = ResourceLedger.change(state, "home", res_id, state.resources[res_id].value, cur_amt.subtract(AmountCompat.from_number(cost_val)), "fortune")
			receipt.resources[res_id].paid = DecisionReceipt._amount(receipt.resources[res_id].paid).add(cur_amt.subtract(state.resources[res_id].value)).serialize()
	
	# 發放獎勵
	var rewards: Dictionary = option.get("rewards", {})
	var log_text: String = String(rewards.get("log_text", "獲得奇遇機緣。"))
	
	# 1. 資源獎勵
	var res_rewards: Dictionary = rewards.get("resources", {})
	for raw_id in res_rewards:
		var res_id := resource_key(state.resources,str(raw_id))
		var gain_val: float = float(res_rewards[raw_id])
		if gain_val > 0.0:
			receipt.resources[res_id].nominal = DecisionReceipt._amount(receipt.resources[res_id].nominal).add(AmountCompat.from_number(gain_val)).serialize()
			if not state.resources.has(res_id):
				state.resources[res_id] = {
					"value": ResourceLedger.change(state, "home", res_id, AmountCompat.zero(), AmountCompat.from_number(gain_val), "fortune", AmountCompat.from_number(gain_val)),
					"unlocked": true,
					"ever_obtained": true
				}
			else:
				var cur_amt: AmountCompat = state.resources[res_id].value
				state.resources[res_id].value = ResourceLedger.change(state, "home", res_id, state.resources[res_id].value, cur_amt.add(AmountCompat.from_number(gain_val)), "fortune", AmountCompat.from_number(gain_val))
				state.resources[res_id]["unlocked"] = true
				state.resources[res_id]["ever_obtained"] = true
	
	# 2. 修煉秒數獎勵
	var training_gain: float = float(rewards.get("training_seconds", 0.0))
	var training_before := state.training_seconds
	if training_gain > 0.0:
		if is_story:
			var era: Variant = content.era(state.era_id)
			var ceiling := Cultivation.next_level_required_seconds(era, state.level, 0.0, SkillSystem.effect(content, state.skills, "time_multiplier")) if era != null else state.training_seconds
			state.training_seconds = maxf(state.training_seconds, minf(state.training_seconds + training_gain, ceiling))
		else:
			state.training_seconds += training_gain
	
	receipt.training = {"before": training_before, "gained": state.training_seconds - training_before, "after": state.training_seconds}
	# 3. 丹藥獎勵
	var pill_rewards: Dictionary = rewards.get("pills", {})
	for pill_id in pill_rewards:
		var count: int = int(pill_rewards[pill_id])
		var before := int(state.pills.get(pill_id, 0))
		if count > 0:
			if not state.pills.has(pill_id):
				state.pills[pill_id] = count
			else:
				state.pills[pill_id] = int(state.pills[pill_id]) + count
	
			receipt.pills[pill_id] = {"before": before, "gained": int(state.pills[pill_id]) - before, "after": int(state.pills[pill_id])}
	# 4. BUFF 獎勵
	var buff_id: String = String(rewards.get("buff_id", ""))
	if not buff_id.is_empty():
		var before := float(state.buffs.get(buff_id, {}).get("remaining_seconds", 0))
		BuffSystem.apply_buff(state, buff_id)
		receipt.buff = {"id": buff_id, "before": before, "after": float(state.buffs[buff_id].remaining_seconds), "permanent": bool(state.buffs[buff_id].is_permanent)}
	
	receipt.log = log_text
	for id in receipt.resources:
		var row: Dictionary = receipt.resources[id]
		row.after = _stock(state, id).serialize()
		var paid := DecisionReceipt._amount(row.paid)
		var after_cost := DecisionReceipt._amount(row.before).subtract(paid)
		var gained := _stock(state, id).subtract(after_cost).clamp_amount(AmountCompat.zero(), DecisionReceipt._amount(row.nominal))
		row.gained = gained.serialize()
		row.overflow = DecisionReceipt._amount(row.nominal).subtract(gained).serialize()
	DecisionReceipt.record(state, receipt)
	# 結算完畢，清除 pending 並記錄計數
	state.fortune["pending_encounter"] = {}
	state.fortune["total_fortunes_claimed"] = int(state.fortune.get("total_fortunes_claimed", 0)) + 1
	
	return {
		"ok": true,
		"log": log_text,
		"rewards": rewards,
		"receipt": receipt
	}

static func _stock(state: GameState, id: String) -> AmountCompat:
	return state.resources.get(id, {}).get("value", AmountCompat.zero())
