class_name BeastSystem
extends RefCounted

const VERSION := 1
const P2_IDS := ["frost_stag", "herb_crane"]
const MAX_SOULS := 2147483647

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
	},
	"frost_stag": {
		"id": "frost_stag",
		"name": "霜角鹿",
		"unlock_era": 4,
		"feed_resource": {
			"refined_iron": 10,
			"spirit_grass_low": 20
		},
		"passive_type": "local_rate",
		"passive_base_value": 0.2,
		"island": "deep",
		"resources": [
			"refined_iron",
			"mithril",
			"cold_iron"
		],
		"desc": "霜角鹿提升指定地方採集產率。"
	},
	"herb_crane": {
		"id": "herb_crane",
		"name": "銜芝鶴",
		"unlock_era": 5,
		"feed_resource": {
			"spirit_grass_100y": 5,
			"spirit_grass_1000y": 2
		},
		"passive_type": "local_rate",
		"passive_base_value": 0.2,
		"island": "ancient",
		"resources": [
			"spirit_grass_1000y"
		],
		"desc": "銜芝鶴提升指定地方採集產率。"
	},
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
	},
	"stag_t1_boost": {
		"id": "stag_t1_boost",
		"name": "霜角引脈",
		"tier": 1,
		"cost": 1,
		"type": "beast_passive_boost",
		"value": 0.05,
		"beast_id": "frost_stag",
		"desc": "自己的非卵階段係數 +0.05"
	},
	"stag_t2_growth": {
		"id": "stag_t2_growth",
		"name": "寒息養靈",
		"tier": 2,
		"cost": 2,
		"type": "beast_growth_boost",
		"value": 0.3,
		"beast_id": "frost_stag",
		"desc": "自己的餵養經驗 +30%"
	},
	"stag_t3_discount": {
		"id": "stag_t3_discount",
		"name": "嚼礦化露",
		"tier": 3,
		"cost": 3,
		"type": "beast_feed_discount",
		"value": 0.4,
		"beast_id": "frost_stag",
		"desc": "自己的餵費取六成，逐資源向下取整、最低1"
	},
	"stag_t4_capacity": {
		"id": "stag_t4_capacity",
		"name": "霜窖藏珍",
		"tier": 4,
		"cost": 5,
		"type": "local_capacity_flat",
		"island": "deep",
		"value": 30,
		"beast_id": "frost_stag",
		"desc": "永久指定地方各資源容量 +30"
	},
	"crane_t1_boost": {
		"id": "crane_t1_boost",
		"name": "芝香引露",
		"tier": 1,
		"cost": 1,
		"type": "beast_passive_boost",
		"value": 0.05,
		"beast_id": "herb_crane",
		"desc": "自己的非卵階段係數 +0.05"
	},
	"crane_t2_growth": {
		"id": "crane_t2_growth",
		"name": "清唳養神",
		"tier": 2,
		"cost": 2,
		"type": "beast_growth_boost",
		"value": 0.3,
		"beast_id": "herb_crane",
		"desc": "自己的餵養經驗 +30%"
	},
	"crane_t3_discount": {
		"id": "crane_t3_discount",
		"name": "啄露辟穀",
		"tier": 3,
		"cost": 3,
		"type": "beast_feed_discount",
		"value": 0.4,
		"beast_id": "herb_crane",
		"desc": "自己的餵費取六成，逐資源向下取整、最低1"
	},
	"crane_t4_capacity": {
		"id": "crane_t4_capacity",
		"name": "芝圃留芳",
		"tier": 4,
		"cost": 5,
		"type": "local_capacity_flat",
		"island": "ancient",
		"value": 30,
		"beast_id": "herb_crane",
		"desc": "永久指定地方各資源容量 +30"
	},
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
	var eligibility := acquire_requirements(state, beast_id)
	if not eligibility.ok: return eligibility
	ensure_initialized(state)

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
	var beast: Dictionary = state.beasts.get("active", {})
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
		cur_entry.value = ResourceLedger.change(state, "home", res_id, cur_entry.value, cur_val.subtract(AmountCompat.from_number(needed)), "beast")

	# Compute exp gain with talent boost
	var growth_boost := 0.0
	for talent_id in state.beast_talents:
		if int(state.beast_talents[talent_id]) > 0 and BEAST_TALENTS.has(talent_id):
			var t_conf: Dictionary = BEAST_TALENTS[talent_id]
			if String(t_conf.get("beast_id", "")) == beast_id and String(t_conf.get("type", "")) == "beast_growth_boost":
				growth_boost += float(t_conf.get("value", 0.0))

	var exp_gain := int(floor(float(BASE_EXP_PER_FEED) * (1.0 + growth_boost)))
	if beast_id == "jade_fox":
		# floor(x + integer) = floor(x) + integer. Each P1 rank adds exactly
		# 10 XP; keep the old soul calculation and avoid 2.3*50 rounding to 114.
		exp_gain += 10 * clampi(int(state.talents.get("beast_bond_past_wisdom", 0)), 0, 5)
	if beast_id in ["iron_turtle", "fire_phoenix"] and state.talent_version >= TalentSystem.VERSION:
		exp_gain += 10 * int(state.talents.get("sacred_beast_nurture_memory", 0))
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
	if beast_id == "jade_fox" and new_stage == "mature": StoryProgress.mark(state, "fox_matured")

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
	if BEAST_TALENTS.has(talent_id) and BEAST_TALENTS[talent_id].beast_id in P2_IDS and state.beast_version < VERSION:
		return {"ok": false, "error": "BEAST_SAVE_REQUIRED"}
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
	if not reincarnation_error(state).is_empty(): return {"ok": false, "error": reincarnation_error(state)}
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
		var soul_percent := maxi(10, 100 - int(round(discount * 100)))
		var sect_percent := 100 - 2 * SectSystem.active_level(state, "fox_feed_conservation") if beast_id == "jade_fox" else 100
		if beast_id in ["iron_turtle", "fire_phoenix"] and state.era_id >= int(BEAST_CONFIGS[beast_id].unlock_era):
			sect_percent = 100 - 2 * SectSystem.active_level(state, "sacred_beast_feed_conservation")
		costs[id] = float(maxi(1, int(BEAST_CONFIGS[beast_id].feed_resource[id]) * soul_percent * sect_percent / 10000))
	return costs

static func get_view(state: GameState) -> Dictionary:
	# Read-only projection: opening a tab does not initialize or acquire a beast.
	var active: Dictionary = state.beasts.get("active", {}).duplicate(true)
	var requirements := {}
	for id in BEAST_CONFIGS: requirements[id] = acquire_requirements(state, id)
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
	if String(active.get("id", "")) in P2_IDS and not SectSystem.p2_life_error(state).is_empty():
		can_feed = false
		reason = "壽元已盡"
	var care := {}
	for id in BEAST_CONFIGS:
		var xp := BASE_EXP_PER_FEED
		for tid in state.beast_talents:
			var t: Dictionary = BEAST_TALENTS.get(tid,{})
			if int(state.beast_talents[tid]) > 0 and t.get("beast_id") == id and t.get("type") == "beast_growth_boost":
				xp = int(floor(float(BASE_EXP_PER_FEED)*(1.0+float(t.value))))
		var config: Dictionary = BEAST_CONFIGS[id]
		var island: String = config.get("island", "")
		var resource: String = config.get("resources", [""])[0]
		care[id] = {"costs":feed_costs(state,id),"next_xp":xp,"rate_bonus":local_rate_multiplier(state,island,resource)-1.0,"capacity_bonus":local_capacity_bonus(state,island)}
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
		if String(item.beast_id) in P2_IDS:
			item.can_unlock = item.can_unlock and state.beast_version >= VERSION and SectSystem.p2_life_error(state).is_empty()
		talents.append(item)
	return {"care": care, "acquire_requirements": requirements, "active": active, "feed_costs": costs, "can_feed": can_feed, "feed_reason": reason, "cooldown_remaining": cooldown, "souls": state.beast_souls.duplicate(true), "talents_view": talents}

## Pure projection shared by commands and Views; rejection cannot initialize state.
static func acquire_requirements(state: GameState, beast_id: String) -> Dictionary:
	if not state.beasts.get("active", {}).is_empty(): return {"ok": false, "error": "ALREADY_HAS_ACTIVE_BEAST"}
	if not BEAST_CONFIGS.has(beast_id): return {"ok": false, "error": "UNKNOWN_BEAST"}
	var config: Dictionary = BEAST_CONFIGS[beast_id]
	if state.era_id < int(config.unlock_era): return {"ok": false, "error": "INSUFFICIENT_ERA", "required_era": config.unlock_era}
	if beast_id in P2_IDS:
		if not SectSystem.p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
		if state.beast_version < VERSION: return {"ok": false, "error": "BEAST_SAVE_REQUIRED"}
		if not IslandEconomy.expanded(state): return {"ok": false, "error": "SUPPLY_REQUIRED"}
		if not state.economy.get("islands", {}).get(config.island, {}).get("opened", false): return {"ok": false, "error": "ISLAND_NOT_OPEN", "island": config.island}
	return {"ok": true}

static func local_rate_multiplier(state: GameState, island: String, resource: String) -> float:
	if state.beast_version < VERSION or not IslandEconomy.expanded(state): return 1.0
	if not state.economy.get("islands", {}).get(island, {}).get("opened", false): return 1.0
	var active: Dictionary = state.beasts.get("active", {})
	var id: String = active.get("id", "")
	if id not in P2_IDS: return 1.0
	var config: Dictionary = BEAST_CONFIGS[id]
	if config.island != island or resource not in config.resources: return 1.0
	var stage_mult := float(STAGE_CONFIGS.get(active.get("stage", "egg"), {}).get("multiplier", 0.0))
	if stage_mult <= 0: return 1.0
	for talent_id in state.beast_talents:
		var t: Dictionary = BEAST_TALENTS.get(talent_id, {})
		if int(state.beast_talents[talent_id]) > 0 and t.get("beast_id") == id and t.get("type") == "beast_passive_boost": stage_mult += float(t.value)
	return 1.0 + float(config.passive_base_value) * stage_mult

static func local_capacity_bonus(state: GameState, island: String) -> float:
	if state.beast_version < VERSION or not IslandEconomy.expanded(state): return 0.0
	if not state.economy.get("islands", {}).get(island, {}).get("opened", false): return 0.0
	var bonus := 0.0
	for id in state.beast_talents:
		var t: Dictionary = BEAST_TALENTS.get(id, {})
		if int(state.beast_talents[id]) > 0 and t.get("type") == "local_capacity_flat" and t.get("island") == island: bonus += float(t.value)
	return bonus

static func reincarnation_error(state: GameState) -> String:
	var active: Dictionary = state.beasts.get("active", {})
	if active.get("stage") == "mature" and int(state.beast_souls.get(active.get("id", ""), 0)) >= MAX_SOULS: return "BEAST_SOUL_OVERFLOW"
	return ""

static func effect_signature(state: GameState) -> Array:
	var active: Dictionary = state.beasts.get("active", {})
	return [state.beast_version, state.reincarnation_count, active.get("id", ""), active.get("stage", ""), state.beast_talents.duplicate(true)]
