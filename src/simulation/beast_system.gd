class_name BeastSystem
extends RefCounted

const BASE_COOLDOWN := 300.0
const MIN_COOLDOWN := 60.0
const BASE_EXP_PER_FEED := 50

const BEAST_CONFIGS := {
	"jade_fox": {
		"id": "jade_fox",
		"name": "靈狐",
		"unlock_era": 3,
		"feed_resource": {"spirit_grass_low": 50},
		"passive_type": "money_rate",
		"passive_base_value": 0.20,
		"desc": "青丘靈狐，天生親和靈脈，擅聚靈石財氣。"
	},
	"iron_turtle": {
		"id": "iron_turtle",
		"name": "玄龜",
		"unlock_era": 4,
		"feed_resource": {"refined_iron": 30, "stone_low": 100},
		"passive_type": "cap_stone_iron",
		"passive_base_value": 0.25,
		"desc": "玄甲厚土，背負巨山，大幅拓寬石料與精鐵倉儲。"
	},
	"fire_phoenix": {
		"id": "fire_phoenix",
		"name": "火鳳",
		"unlock_era": 6,
		"feed_resource": {"spirit_grass_1000y": 10},
		"passive_type": "cultivation_speed_bonus",
		"passive_base_value": 0.15,
		"desc": "九天神鳳，浴火涅槃，離火真意助修士洗髓加速修煉。"
	},
	"cloud_serpent": {
		"id": "cloud_serpent",
		"name": "雲蛟",
		"unlock_era": 8,
		"feed_resource": {"void_essence": 20, "star_metal": 5},
		"passive_type": "global_production_multiplier",
		"passive_base_value": 0.12,
		"desc": "太虛雲蛟，吞吐宇內靈機，提升整座洞府天地產率。"
	}
}

const STAGE_CONFIGS := {
	"egg": {
		"name": "靈卵",
		"max_exp": 100,
		"multiplier": 0.0,
		"next_stage": "young"
	},
	"young": {
		"name": "幼獸",
		"max_exp": 500,
		"multiplier": 0.50,
		"next_stage": "growing"
	},
	"growing": {
		"name": "成長期",
		"max_exp": 1000,
		"multiplier": 0.75,
		"next_stage": "mature"
	},
	"mature": {
		"name": "成熟期",
		"max_exp": 2147483647,
		"multiplier": 1.00,
		"next_stage": "mature"
	}
}

const BEAST_TALENTS := {
	# Jade Fox
	"fox_t1_boost": {
		"id": "fox_t1_boost",
		"beast_id": "jade_fox",
		"tier": 1,
		"cost": 1,
		"type": "beast_passive_boost",
		"value": 0.05,
		"name": "通靈媚影",
		"desc": "靈狐出戰被動倍率提升 +5%"
	},
	"fox_t2_speed": {
		"id": "fox_t2_speed",
		"beast_id": "jade_fox",
		"tier": 2,
		"cost": 2,
		"type": "beast_growth_boost",
		"value": 0.30,
		"name": "靈慧天生",
		"desc": "餵養靈狐時獲得的經驗值 +30%"
	},
	"fox_t3_cheap": {
		"id": "fox_t3_cheap",
		"beast_id": "jade_fox",
		"tier": 3,
		"cost": 3,
		"type": "beast_feed_discount",
		"value": 0.40,
		"name": "辟穀化納",
		"desc": "餵養靈狐時消耗的材料減少 40%"
	},
	"fox_t4_passive": {
		"id": "fox_t4_passive",
		"beast_id": "jade_fox",
		"tier": 4,
		"cost": 5,
		"type": "production_herb",
		"value": 0.10,
		"name": "九尾銜草",
		"desc": "常駐全局靈草產率 +10%"
	},

	# Iron Turtle
	"turtle_t1_boost": {
		"id": "turtle_t1_boost",
		"beast_id": "iron_turtle",
		"tier": 1,
		"cost": 1,
		"type": "beast_passive_boost",
		"value": 0.05,
		"name": "玄甲護山",
		"desc": "玄龜出戰被動倍率提升 +5%"
	},
	"turtle_t2_speed": {
		"id": "turtle_t2_speed",
		"beast_id": "iron_turtle",
		"tier": 2,
		"cost": 2,
		"type": "beast_growth_boost",
		"value": 0.30,
		"name": "厚積薄發",
		"desc": "餵養玄龜時獲得的經驗值 +30%"
	},
	"turtle_t3_cheap": {
		"id": "turtle_t3_cheap",
		"beast_id": "iron_turtle",
		"tier": 3,
		"cost": 3,
		"type": "beast_feed_discount",
		"value": 0.40,
		"name": "吞石化晶",
		"desc": "餵養玄龜時消耗的材料減少 40%"
	},
	"turtle_t4_passive": {
		"id": "turtle_t4_passive",
		"beast_id": "iron_turtle",
		"tier": 4,
		"cost": 5,
		"type": "production_stone_iron",
		"value": 0.10,
		"name": "玄冥馱峰",
		"desc": "常駐全局石材與精鐵產率 +10%"
	},

	# Fire Phoenix
	"phoenix_t1_boost": {
		"id": "phoenix_t1_boost",
		"beast_id": "fire_phoenix",
		"tier": 1,
		"cost": 1,
		"type": "beast_passive_boost",
		"value": 0.05,
		"name": "涅槃神光",
		"desc": "火鳳出戰被動倍率提升 +5%"
	},
	"phoenix_t2_speed": {
		"id": "phoenix_t2_speed",
		"beast_id": "fire_phoenix",
		"tier": 2,
		"cost": 2,
		"type": "beast_growth_boost",
		"value": 0.30,
		"name": "鳳雛初啼",
		"desc": "餵養火鳳時獲得的經驗值 +30%"
	},
	"phoenix_t3_cheap": {
		"id": "phoenix_t3_cheap",
		"beast_id": "fire_phoenix",
		"tier": 3,
		"cost": 3,
		"type": "beast_feed_discount",
		"value": 0.40,
		"name": "離火聚精",
		"desc": "餵養火鳳時消耗的材料減少 40%"
	},
	"phoenix_t4_passive": {
		"id": "phoenix_t4_passive",
		"beast_id": "fire_phoenix",
		"tier": 4,
		"cost": 5,
		"type": "cultivation_speed_bonus",
		"value": 0.10,
		"name": "天火燎原",
		"desc": "常駐全局修煉速度 +10%"
	},

	# Cloud Serpent
	"serpent_t1_boost": {
		"id": "serpent_t1_boost",
		"beast_id": "cloud_serpent",
		"tier": 1,
		"cost": 1,
		"type": "beast_passive_boost",
		"value": 0.05,
		"name": "騰雲弄霧",
		"desc": "雲蛟出戰被動倍率提升 +5%"
	},
	"serpent_t2_speed": {
		"id": "serpent_t2_speed",
		"beast_id": "cloud_serpent",
		"tier": 2,
		"cost": 2,
		"type": "beast_growth_boost",
		"value": 0.30,
		"name": "化龍之兆",
		"desc": "餵養雲蛟時獲得的經驗值 +30%"
	},
	"serpent_t3_cheap": {
		"id": "serpent_t3_cheap",
		"beast_id": "cloud_serpent",
		"tier": 3,
		"cost": 3,
		"type": "beast_feed_discount",
		"value": 0.40,
		"name": "吞納虛空",
		"desc": "餵養雲蛟時消耗的材料減少 40%"
	},
	"serpent_t4_passive": {
		"id": "serpent_t4_passive",
		"beast_id": "cloud_serpent",
		"tier": 4,
		"cost": 5,
		"type": "all_capacity_mult",
		"value": 0.10,
		"name": "太虛真容",
		"desc": "常駐全局各項容量上限 +10%"
	}
}

static func ensure_initialized(state: GameState) -> void:
	if state == null:
		return
	if not (state.beasts is Dictionary):
		state.beasts = {}
	if not state.beasts.has("active"):
		state.beasts["active"] = {}
	if not state.beasts.has("cooldown_remaining"):
		state.beasts["cooldown_remaining"] = 0.0
	if not (state.beast_souls is Dictionary):
		state.beast_souls = {}
	if not (state.beast_talents is Dictionary):
		state.beast_talents = {}

static func get_active_beast(state: GameState) -> Dictionary:
	ensure_initialized(state)
	var active: Variant = state.beasts.get("active", {})
	if active is Dictionary:
		return active as Dictionary
	return {}

static func acquire_beast(state: GameState, beast_id: String) -> Dictionary:
	ensure_initialized(state)
	var active := get_active_beast(state)
	if not active.is_empty():
		return {"ok": false, "error": "ALREADY_HAS_ACTIVE_BEAST"}
	if not BEAST_CONFIGS.has(beast_id):
		return {"ok": false, "error": "UNKNOWN_BEAST"}
	var config: Dictionary = BEAST_CONFIGS[beast_id]
	if state.era_id < int(config.get("unlock_era", 1)):
		return {"ok": false, "error": "INSUFFICIENT_ERA", "required_era": int(config.get("unlock_era", 1))}

	var beast_data := {
		"id": beast_id,
		"stage": "egg",
		"exp": 0
	}
	state.beasts["active"] = beast_data
	state.beasts["cooldown_remaining"] = 0.0

	return {
		"ok": true,
		"beast": beast_data,
		"events": [{
			"kind": "beast_acquired",
			"beast_id": beast_id,
			"stage": "egg"
		}]
	}

static func feed_beast(state: GameState) -> Dictionary:
	ensure_initialized(state)
	var beast := get_active_beast(state)
	if beast.is_empty():
		return {"ok": false, "error": "NO_ACTIVE_BEAST"}
	var stage: String = String(beast.get("stage", "egg"))
	if stage == "mature":
		return {"ok": false, "error": "BEAST_ALREADY_MATURE"}

	var cd: float = float(state.beasts.get("cooldown_remaining", 0.0))
	if cd > 0.0001:
		return {"ok": false, "error": "FEED_ON_COOLDOWN", "cooldown_remaining": cd}

	var beast_id: String = String(beast.get("id", ""))
	var config: Dictionary = BEAST_CONFIGS.get(beast_id, {})
	if config.is_empty():
		return {"ok": false, "error": "UNKNOWN_BEAST"}

	# One cost source shared by command validation and presentation.
	var final_costs := feed_costs(state, beast_id)
	for res_id in final_costs:
		var needed: float = float(final_costs[res_id])
		var cur_entry: Dictionary = state.resources.get(res_id, {})
		var cur_val: AmountCompat = cur_entry.get("value", AmountCompat.zero())
		if cur_val.compare_to(AmountCompat.from_number(needed)) < 0:
			return {
				"ok": false,
				"error": "INSUFFICIENT_FEED_RESOURCE",
				"resource_id": res_id,
				"required": needed,
				"available": cur_val.to_float()
			}

	# Spend resources
	for res_id in final_costs:
		var needed: float = final_costs[res_id]
		var cur_entry: Dictionary = state.resources[res_id]
		var cur_val: AmountCompat = cur_entry["value"]
		cur_entry["value"] = cur_val.subtract(AmountCompat.from_number(needed))

	# Compute exp gain with talent boost
	var growth_boost := 0.0
	for talent_id in state.beast_talents:
		if int(state.beast_talents[talent_id]) > 0 and BEAST_TALENTS.has(talent_id):
			var t_conf: Dictionary = BEAST_TALENTS[talent_id]
			if String(t_conf.get("beast_id", "")) == beast_id and String(t_conf.get("type", "")) == "beast_growth_boost":
				growth_boost += float(t_conf.get("value", 0.0))

	var exp_gain := int(floor(float(BASE_EXP_PER_FEED) * (1.0 + growth_boost)))
	var cur_exp: int = int(beast.get("exp", 0)) + exp_gain
	beast["exp"] = cur_exp

	# Update stage
	var old_stage: String = stage
	var new_stage: String = old_stage
	var stage_conf: Dictionary = STAGE_CONFIGS.get(old_stage, {})
	if cur_exp >= int(stage_conf.get("max_exp", 999999)):
		new_stage = String(stage_conf.get("next_stage", old_stage))
		# Check if it advances further (e.g. huge exp gain)
		while new_stage != "mature":
			var next_conf: Dictionary = STAGE_CONFIGS.get(new_stage, {})
			if cur_exp >= int(next_conf.get("max_exp", 999999)):
				new_stage = String(next_conf.get("next_stage", new_stage))
			else:
				break
	beast["stage"] = new_stage

	# Set cooldown
	state.beasts["cooldown_remaining"] = BASE_COOLDOWN

	var events: Array = [{
		"kind": "beast_fed",
		"beast_id": beast_id,
		"exp_gained": exp_gain,
		"total_exp": cur_exp,
		"stage": new_stage,
		"costs": final_costs
	}]
	if new_stage != old_stage:
		events.append({
			"kind": "beast_stage_up",
			"beast_id": beast_id,
			"previous_stage": old_stage,
			"new_stage": new_stage
		})

	return {
		"ok": true,
		"beast": beast,
		"exp_gained": exp_gain,
		"stage": new_stage,
		"events": events
	}

static func unlock_talent(state: GameState, talent_id: String) -> Dictionary:
	ensure_initialized(state)
	if not BEAST_TALENTS.has(talent_id):
		return {"ok": false, "error": "UNKNOWN_BEAST_TALENT"}
	if int(state.beast_talents.get(talent_id, 0)) > 0:
		return {"ok": false, "error": "TALENT_ALREADY_UNLOCKED"}

	var config: Dictionary = BEAST_TALENTS[talent_id]
	var beast_id: String = String(config.get("beast_id", ""))
	var tier: int = int(config.get("tier", 1))
	var cost: int = int(config.get("cost", 1))

	# Pre-requisite check
	if tier > 1:
		var has_prev := false
		for t_id in BEAST_TALENTS:
			var t: Dictionary = BEAST_TALENTS[t_id]
			if String(t.get("beast_id", "")) == beast_id and int(t.get("tier", 0)) == tier - 1:
				if int(state.beast_talents.get(t_id, 0)) > 0:
					has_prev = true
					break
		if not has_prev:
			return {"ok": false, "error": "PREV_TIER_REQUIRED", "required_tier": tier - 1}

	var cur_souls: int = int(state.beast_souls.get(beast_id, 0))
	if cur_souls < cost:
		return {
			"ok": false,
			"error": "INSUFFICIENT_BEAST_SOULS",
			"beast_id": beast_id,
			"required": cost,
			"available": cur_souls
		}

	# Spend souls and unlock
	state.beast_souls[beast_id] = cur_souls - cost
	state.beast_talents[talent_id] = 1

	return {
		"ok": true,
		"talent_id": talent_id,
		"remaining_souls": state.beast_souls[beast_id],
		"events": [{
			"kind": "beast_talent_unlocked",
			"talent_id": talent_id,
			"beast_id": beast_id,
			"tier": tier
		}]
	}

static func on_reincarnate(state: GameState) -> Dictionary:
	ensure_initialized(state)
	var beast := get_active_beast(state)
	var gained_souls: Dictionary = {}

	if not beast.is_empty():
		var stage: String = String(beast.get("stage", "egg"))
		var beast_id: String = String(beast.get("id", ""))
		if stage == "mature" and not beast_id.is_empty():
			var cur_s: int = int(state.beast_souls.get(beast_id, 0))
			state.beast_souls[beast_id] = cur_s + 1
			gained_souls[beast_id] = 1

	# Reset active beast and cooldown for the new life
	state.beasts["active"] = {}
	state.beasts["cooldown_remaining"] = 0.0

	return {
		"gained_souls": gained_souls,
		"beast_souls": state.beast_souls.duplicate(true)
	}

static func tick(state: GameState, delta: float) -> void:
	if state == null:
		return
	ensure_initialized(state)
	var cd: float = float(state.beasts.get("cooldown_remaining", 0.0))
	if cd > 0.0:
		state.beasts["cooldown_remaining"] = maxf(0.0, cd - delta)

static func compute_multipliers(state: GameState) -> Dictionary:
	var res := {
		"cultivation_speed_bonus": 0.0,
		"global_production_multiplier": 0.0,
		"money_rate": 0.0,
		"cap_stone_iron": 0.0,
		"production_herb": 0.0,
		"production_stone_iron": 0.0,
		"all_capacity_mult": 0.0,
	}
	if state == null:
		return res
	ensure_initialized(state)

	# 1. Active Beast Passive
	var beast := get_active_beast(state)
	if not beast.is_empty():
		var beast_id: String = String(beast.get("id", ""))
		var stage: String = String(beast.get("stage", "egg"))
		var config: Dictionary = BEAST_CONFIGS.get(beast_id, {})
		var stage_conf: Dictionary = STAGE_CONFIGS.get(stage, {})
		if not config.is_empty() and not stage_conf.is_empty():
			var stage_mult: float = float(stage_conf.get("multiplier", 0.0))
			if stage_mult > 0.0:
				# T1 talent bonus
				var talent_boost := 0.0
				for talent_id in state.beast_talents:
					if int(state.beast_talents[talent_id]) > 0 and BEAST_TALENTS.has(talent_id):
						var t_conf: Dictionary = BEAST_TALENTS[talent_id]
						if String(t_conf.get("beast_id", "")) == beast_id and String(t_conf.get("type", "")) == "beast_passive_boost":
							talent_boost += float(t_conf.get("value", 0.0))
				var final_mult: float = stage_mult + talent_boost
				var p_type: String = String(config.get("passive_type", ""))
				var base_val: float = float(config.get("passive_base_value", 0.0))
				if res.has(p_type):
					res[p_type] += base_val * final_mult

	# 2. Permanent Tier 4 Talents
	for talent_id in state.beast_talents:
		if int(state.beast_talents[talent_id]) > 0 and BEAST_TALENTS.has(talent_id):
			var t_conf: Dictionary = BEAST_TALENTS[talent_id]
			if int(t_conf.get("tier", 0)) == 4:
				var t_type: String = String(t_conf.get("type", ""))
				var val: float = float(t_conf.get("value", 0.0))
				if res.has(t_type):
					res[t_type] += val

	return res

static func feed_costs(state: GameState, beast_id: String) -> Dictionary:
	var discount := 0.0
	for talent_id in state.beast_talents:
		if int(state.beast_talents[talent_id]) > 0 and BEAST_TALENTS.has(talent_id):
			var talent: Dictionary = BEAST_TALENTS[talent_id]
			if String(talent.beast_id) == beast_id and String(talent.type) == "beast_feed_discount":
				discount += float(talent.value)
	var costs := {}
	for id in BEAST_CONFIGS.get(beast_id, {}).get("feed_resource", {}):
		costs[id] = maxf(1.0, floor(float(BEAST_CONFIGS[beast_id].feed_resource[id]) * maxf(0.1, 1.0 - discount)))
	return costs

static func get_view(state: GameState) -> Dictionary:
	# Read-only projection: opening a tab does not initialize or acquire a beast.
	var active: Dictionary = state.beasts.get("active", {}).duplicate(true)
	var costs := feed_costs(state, String(active.get("id", "")))
	var can_feed := not active.is_empty() and String(active.get("stage", "egg")) != "mature"
	var reason := "已成熟" if not active.is_empty() else "尚未結契"
	var cooldown: float = float(state.beasts.get("cooldown_remaining", 0.0))
	if can_feed:
		reason = "餵料不足"
		if cooldown > 0.0001:
			can_feed = false
			reason = "等待餵食冷卻"
		else:
			for id in costs:
				var amount: AmountCompat = state.resources.get(id, {}).get("value", AmountCompat.zero())
				can_feed = can_feed and amount.compare_to(AmountCompat.from_number(float(costs[id]))) >= 0
	var talents: Array = []
	for id in BEAST_TALENTS:
		var item: Dictionary = BEAST_TALENTS[id].duplicate(true)
		item.owned = int(state.beast_talents.get(id, 0)) > 0
		var previous := int(item.tier) == 1
		for prev_id in BEAST_TALENTS:
			var prev: Dictionary = BEAST_TALENTS[prev_id]
			if prev.beast_id == item.beast_id and int(prev.tier) == int(item.tier) - 1 and int(state.beast_talents.get(prev_id, 0)) > 0:
				previous = true
		item.can_unlock = not item.owned and previous and int(state.beast_souls.get(item.beast_id, 0)) >= int(item.cost)
		talents.append(item)
	return {"active": active, "feed_costs": costs, "can_feed": can_feed, "feed_reason": reason, "cooldown_remaining": cooldown, "souls": state.beast_souls.duplicate(true), "talents_view": talents}
