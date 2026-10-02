class_name SectSystem
extends RefCounted

const UNLOCK_ERA := 2
const MAX_TECHNIQUE_LEVEL := 10
const EXPEDITION_SLOTS := 3

const SECT_NAMES := [
	"太虛天闕",
	"天劍聖宗",
	"縹緲仙宮",
	"萬佛靈宗",
	"紫霄玄門",
]

const RARITY_CONFIGS := {
	"common": {
		"name": "普通",
		"color": "#cccccc",
		"weight": 40,
		"duration": 60,
		"contrib_min": 15,
		"contrib_max": 30,
		"reward_mult": 1.0,
	},
	"uncommon": {
		"name": "優秀",
		"color": "#4caf50",
		"weight": 30,
		"duration": 120,
		"contrib_min": 30,
		"contrib_max": 60,
		"reward_mult": 1.5,
	},
	"rare": {
		"name": "稀有",
		"color": "#2196f3",
		"weight": 18,
		"duration": 300,
		"contrib_min": 60,
		"contrib_max": 120,
		"reward_mult": 2.0,
	},
	"epic": {
		"name": "史詩",
		"color": "#9c27b0",
		"weight": 10,
		"duration": 600,
		"contrib_min": 120,
		"contrib_max": 250,
		"reward_mult": 3.0,
	},
	"legendary": {
		"name": "傳說",
		"color": "#ff9800",
		"weight": 2,
		"duration": 900,
		"contrib_min": 300,
		"contrib_max": 600,
		"reward_mult": 5.0,
	},
}

const TASK_TEMPLATES := {
	"common": [
		{"name": "巡視靈田", "desc": "驅除靈田中滋生的小害蟲，確保靈穀生長。"},
		{"name": "清剿低階野獸", "desc": "清理後山出沒的一階野獸，維護外門安寧。"},
		{"name": "採集晨露草", "desc": "拂曉時分採集沾染朝露的靈草，供丹房研製。"}
	],
	"uncommon": [
		{"name": "護送百草商隊", "desc": "護送宗門靈草車隊前往凡間市集交易。"},
		{"name": "探查黑風妖窟", "desc": "深入黑風山脈偵察妖氣波動源頭。"},
		{"name": "修補山門法陣", "desc": "更換山門聚靈護陣受損的下品靈石陣角。"}
	],
	"rare": [
		{"name": "斬殺二階赤炎蟒", "desc": "剿滅盤踞火脈作亂的赤炎蟒，取其靈骨。"},
		{"name": "探索上古殘破洞府", "desc": "搜尋千年前散仙遺留在荒嶺中的殘存藏寶。"},
		{"name": "採擷玄陰朱果", "desc": "攀登極寒冰峰，採摘百年難得一現的靈果。"}
	],
	"epic": [
		{"name": "鎮壓幽冥魔隙", "desc": "聯手內門師兄結陣鎮壓突然滲透的幽冥濁氣。"},
		{"name": "奪取天外玄金", "desc": "爭奪墜落在絕地的天外隕鐵，供長老煉製法寶。"},
		{"name": "助長老凝練純陽真火", "desc": "入地底岩漿核心助長老接引地心真火。"}
	],
	"legendary": [
		{"name": "探尋太虛古秘境", "desc": "進入百年一啟的太虛仙境，尋求上古仙緣傳承。"},
		{"name": "斬殺四階化形大妖", "desc": "與宗門掌教一同圍剿為禍一方的化形妖王。"},
		{"name": "護衛九界跨界星陣", "desc": "引渡靈界星光，穩定九界跨界通道之陣眼。"}
	],
}

const TECHNIQUES := {
	"divine_farm": {
		"name": "神農靈訣",
		"desc": "以青木靈光灌溉靈根，每級提升靈草與靈木產能 10%。",
		"base_contrib": 50,
		"base_wood": 100,
		"cost_scale": 1.5,
		"max_level": 10,
	},
	"breathing_method": {
		"name": "周天吐納法",
		"desc": "運轉宗門正宗行氣法門，每級提升全洞府修煉速度 2%。",
		"base_contrib": 80,
		"base_stone_low": 5,
		"cost_scale": 1.6,
		"max_level": 10,
	},
	"storage_talisman": {
		"name": "乾坤納戒",
		"desc": "宗門特製儲物須彌納芥，每級提升所有基礎資源容量 10%。",
		"base_contrib": 60,
		"base_wood": 200,
		"cost_scale": 1.5,
		"max_level": 10,
	},
	"essence_array": {
		"name": "引靈大陣",
		"desc": "引導天地靈脈匯聚，每級提升靈氣儲存上限 20%。",
		"base_contrib": 100,
		"base_stone_low": 30,
		"cost_scale": 1.5,
		"max_level": 10,
	},
}

const MARKET_ITEMS := {
	"herb_bundle": {
		"name": "百草靈囊",
		"desc": "內含精選靈草 50 份，可用於日常煉丹或營造。",
		"cost": 30,
		"grant_resource": "herb",
		"grant_amount": 50.0,
		"limit": 20,
	},
	"stone_bundle": {
		"name": "靈石錦袋",
		"desc": "內含純淨下品靈石 10 枚，助益修行與宗門營建。",
		"cost": 50,
		"grant_resource": "stone_low",
		"grant_amount": 10.0,
		"limit": 20,
	},
	"foundation_pill": {
		"name": "築基神丹",
		"desc": "宗門長老親手煉製的築基靈丹，服之可延年益壽且增益產能。",
		"cost": 150,
		"grant_pill": "foundation_pill",
		"grant_count": 1,
		"limit": 5,
	},
	"spirit_crystal_shard": {
		"name": "極品靈晶",
		"desc": "靈界天靈洞天專屬高階靈能結晶，蘊含磅礴靈力。",
		"cost": 250,
		"grant_resource": "spirit_crystal",
		"grant_amount": 2.0,
		"limit": 5,
	},
}

static func is_unlocked(state: GameState) -> bool:
	return state.era_id >= UNLOCK_ERA or state.reincarnation_count >= 1

static func ensure_sect_state(state: GameState) -> Dictionary:
	if not (state.sect is Dictionary) or state.sect.is_empty():
		state.sect = {
			"unlocked": false,
			"sect_id": "taixu_sect",
			"sect_name": "太虛天闕",
			"sect_level": 1,
			"contribution": "0",
			"active_expedition": null,
			"available_tasks": [],
			"next_refresh_seconds": 0,
			"techniques": {},
			"market_purchases": {},
		}
	return state.sect

static func join_sect(state: GameState, sect_name: String = "") -> Dictionary:
	if not is_unlocked(state):
		return {"ok": false, "error": "SECT_LOCKED"}
	var sect: Dictionary = ensure_sect_state(state)
	if bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "ALREADY_JOINED_SECT"}
	
	sect["unlocked"] = true
	if not sect_name.is_empty():
		sect["sect_name"] = sect_name
	else:
		sect["sect_name"] = SECT_NAMES[0]
	
	# Generate initial tasks
	refresh_tasks(state, true)
	
	return {
		"ok": true,
		"events": [{
			"kind": "joined_sect",
			"sect_name": sect["sect_name"],
		}],
	}

static func refresh_tasks(state: GameState, force: bool = false) -> Dictionary:
	var sect: Dictionary = ensure_sect_state(state)
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	
	var current_tasks: Array = sect.get("available_tasks", [])
	if not force and not current_tasks.is_empty() and int(sect.get("next_refresh_seconds", 0)) > 0:
		return {"ok": false, "error": "REFRESH_COOLDOWN"}
	
	var new_tasks: Array = []
	for i in range(EXPEDITION_SLOTS):
		var task: Dictionary = _generate_random_task(state.era_id, i + 1, sect)
		new_tasks.append(task)
	
	sect["available_tasks"] = new_tasks
	sect["next_refresh_seconds"] = 300 # 5 minutes cooldown
	
	return {
		"ok": true,
		"tasks": new_tasks,
		"events": [{"kind": "tasks_refreshed", "count": new_tasks.size()}],
	}

static func _generate_random_task(era_id: int, slot_index: int, sect: Dictionary = {}) -> Dictionary:
	var rarity_key := _pick_rarity()
	var r_cfg: Dictionary = RARITY_CONFIGS[rarity_key]
	var templates: Array = TASK_TEMPLATES[rarity_key]
	var t_index := randi() % templates.size()
	var tmpl: Dictionary = templates[t_index]
	
	var task_seq: int = int(sect.get("task_counter", 0)) + 1
	if not sect.is_empty():
		sect["task_counter"] = task_seq
	var task_id := "task_%d_%d_%d" % [era_id, slot_index, task_seq]
	var contrib_min := int(r_cfg.get("contrib_min", 10))
	var contrib_max := int(r_cfg.get("contrib_max", 20))
	var contrib := contrib_min + (randi() % (contrib_max - contrib_min + 1))
	
	var rewards := {
		"contribution": contrib,
		"money": int(50 * float(r_cfg.reward_mult) * float(era_id)),
	}
	
	if rarity_key == "uncommon" or rarity_key == "rare":
		rewards["stone_low"] = maxi(1, int(2 * float(r_cfg.reward_mult)))
		rewards["herb"] = maxi(5, int(15 * float(r_cfg.reward_mult)))
	elif rarity_key == "epic":
		rewards["stone_low"] = maxi(5, int(5 * float(r_cfg.reward_mult)))
		rewards["bronze"] = 2
	elif rarity_key == "legendary":
		rewards["stone_low"] = maxi(10, int(10 * float(r_cfg.reward_mult)))
		rewards["bronze"] = 5
		rewards["special_buff"] = "epiphany"
	
	return {
		"id": task_id,
		"name": tmpl["name"],
		"desc": tmpl["desc"],
		"rarity": rarity_key,
		"rarity_name": r_cfg["name"],
		"rarity_color": r_cfg["color"],
		"duration": int(r_cfg["duration"]),
		"elapsed": 0,
		"rewards": rewards,
	}

static func _pick_rarity() -> String:
	var total_weight := 0
	for key in RARITY_CONFIGS:
		total_weight += int(RARITY_CONFIGS[key].weight)
	
	var roll := randi() % total_weight
	var current := 0
	for key in RARITY_CONFIGS:
		current += int(RARITY_CONFIGS[key].weight)
		if roll < current:
			return key
	return "common"

static func start_expedition(state: GameState, task_id: String) -> Dictionary:
	var sect: Dictionary = ensure_sect_state(state)
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	if sect.get("active_expedition") != null:
		return {"ok": false, "error": "EXPEDITION_ALREADY_ACTIVE"}
	
	var tasks: Array = sect.get("available_tasks", [])
	var target_index := -1
	var target_task: Dictionary = {}
	for i in range(tasks.size()):
		if String(tasks[i].get("id", "")) == task_id:
			target_index = i
			target_task = tasks[i]
			break
	
	if target_index < 0:
		return {"ok": false, "error": "TASK_NOT_FOUND"}
	
	tasks.remove_at(target_index)
	target_task["elapsed"] = 0
	sect["active_expedition"] = target_task
	
	return {
		"ok": true,
		"task": target_task,
		"events": [{
			"kind": "expedition_started",
			"task_id": task_id,
			"name": target_task.get("name", ""),
			"duration": target_task.get("duration", 0),
		}],
	}

static func claim_expedition_reward(state: GameState) -> Dictionary:
	var sect: Dictionary = ensure_sect_state(state)
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	var active = sect.get("active_expedition")
	if active == null or not (active is Dictionary):
		return {"ok": false, "error": "NO_ACTIVE_EXPEDITION"}
	
	var duration: int = int(active.get("duration", 0))
	var elapsed: int = int(active.get("elapsed", 0))
	if elapsed < duration:
		return {"ok": false, "error": "EXPEDITION_NOT_FINISHED", "remaining": duration - elapsed}
	
	var rewards: Dictionary = active.get("rewards", {})
	
	# Grant contribution
	var contrib_gain := int(rewards.get("contribution", 0))
	var cur_contrib := AmountCompat.try_parse(String(sect.get("contribution", "0")))
	var cur_val: AmountCompat = cur_contrib["value"] if bool(cur_contrib.get("ok", false)) else AmountCompat.zero()
	var new_val := cur_val.add(AmountCompat.from_number(float(contrib_gain)))
	sect["contribution"] = new_val.serialize()
	
	# Grant resources
	var granted: Dictionary = {"contribution": contrib_gain}
	for res_id in rewards:
		if res_id == "contribution" or res_id == "special_buff":
			continue
		var amount := float(rewards[res_id])
		if state.resources.has(res_id):
			var entry: Dictionary = state.resources[res_id]
			entry.value = (entry.value as AmountCompat).add(AmountCompat.from_number(amount))
			entry.ever_obtained = true
			entry.unlocked = true
			granted[res_id] = amount
	
	# Check special buff
	if rewards.has("special_buff") and String(rewards["special_buff"]) == "epiphany":
		BuffSystem.apply_buff(state, "epiphany", 60.0)
		granted["buff"] = "epiphany"
	
	sect["active_expedition"] = null
	
	return {
		"ok": true,
		"granted": granted,
		"events": [{
			"kind": "expedition_claimed",
			"task_name": active.get("name", ""),
			"granted": granted,
		}],
	}

static func learn_technique(state: GameState, tech_id: String) -> Dictionary:
	var sect: Dictionary = ensure_sect_state(state)
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	if not TECHNIQUES.has(tech_id):
		return {"ok": false, "error": "UNKNOWN_TECHNIQUE"}
	
	var def: Dictionary = TECHNIQUES[tech_id]
	var techs: Dictionary = sect.get("techniques", {})
	var cur_lvl := int(techs.get(tech_id, 0))
	if cur_lvl >= int(def.get("max_level", MAX_TECHNIQUE_LEVEL)):
		return {"ok": false, "error": "TECHNIQUE_MAX_LEVEL"}
	
	var next_lvl := cur_lvl + 1
	var scale := pow(float(def.get("cost_scale", 1.5)), float(cur_lvl))
	var req_contrib := int(ceil(float(def.get("base_contrib", 50)) * scale))
	
	# Check contribution
	var cur_contrib_parse := AmountCompat.try_parse(String(sect.get("contribution", "0")))
	var cur_contrib: AmountCompat = cur_contrib_parse["value"] if bool(cur_contrib_parse.get("ok", false)) else AmountCompat.zero()
	var req_contrib_amount := AmountCompat.from_number(float(req_contrib))
	if cur_contrib.compare_to(req_contrib_amount) < 0:
		return {"ok": false, "error": "INSUFFICIENT_CONTRIBUTION", "required": req_contrib}
	
	# Check resource costs
	if def.has("base_wood"):
		var req_wood := int(ceil(float(def.get("base_wood", 100)) * scale))
		var cur_wood: AmountCompat = state.resources.get("wood", {}).get("value", AmountCompat.zero())
		if cur_wood.compare_to(AmountCompat.from_number(float(req_wood))) < 0:
			return {"ok": false, "error": "INSUFFICIENT_WOOD", "required": req_wood}
	
	if def.has("base_stone_low"):
		var req_stone := int(ceil(float(def.get("base_stone_low", 5)) * scale))
		var cur_stone: AmountCompat = state.resources.get("stone_low", {}).get("value", AmountCompat.zero())
		if cur_stone.compare_to(AmountCompat.from_number(float(req_stone))) < 0:
			return {"ok": false, "error": "INSUFFICIENT_STONE", "required": req_stone}
	
	# Deduct costs
	sect["contribution"] = cur_contrib.subtract(req_contrib_amount).serialize()
	if def.has("base_wood"):
		var req_wood := int(ceil(float(def.get("base_wood", 100)) * scale))
		var w_entry: Dictionary = state.resources["wood"]
		w_entry.value = (w_entry.value as AmountCompat).subtract(AmountCompat.from_number(float(req_wood)))
	if def.has("base_stone_low"):
		var req_stone := int(ceil(float(def.get("base_stone_low", 5)) * scale))
		var s_entry: Dictionary = state.resources["stone_low"]
		s_entry.value = (s_entry.value as AmountCompat).subtract(AmountCompat.from_number(float(req_stone)))
	
	techs[tech_id] = next_lvl
	sect["techniques"] = techs
	
	return {
		"ok": true,
		"technique_id": tech_id,
		"new_level": next_lvl,
		"events": [{
			"kind": "technique_learned",
			"technique_id": tech_id,
			"level": next_lvl,
		}],
	}

static func buy_market_item(state: GameState, item_id: String) -> Dictionary:
	var sect: Dictionary = ensure_sect_state(state)
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	if not MARKET_ITEMS.has(item_id):
		return {"ok": false, "error": "UNKNOWN_MARKET_ITEM"}
	
	var def: Dictionary = MARKET_ITEMS[item_id]
	var purchases: Dictionary = sect.get("market_purchases", {})
	var count := int(purchases.get(item_id, 0))
	var limit := int(def.get("limit", 10))
	if count >= limit:
		return {"ok": false, "error": "PURCHASE_LIMIT_REACHED"}
	
	var cost := int(def.get("cost", 10))
	var cur_contrib_parse := AmountCompat.try_parse(String(sect.get("contribution", "0")))
	var cur_contrib: AmountCompat = cur_contrib_parse["value"] if bool(cur_contrib_parse.get("ok", false)) else AmountCompat.zero()
	var cost_amount := AmountCompat.from_number(float(cost))
	if cur_contrib.compare_to(cost_amount) < 0:
		return {"ok": false, "error": "INSUFFICIENT_CONTRIBUTION", "required": cost}
	
	# Deduct
	sect["contribution"] = cur_contrib.subtract(cost_amount).serialize()
	purchases[item_id] = count + 1
	sect["market_purchases"] = purchases
	
	# Grant item
	if def.has("grant_resource"):
		var res_id: String = def["grant_resource"]
		var amount: float = float(def["grant_amount"])
		if state.resources.has(res_id):
			var entry: Dictionary = state.resources[res_id]
			entry.value = (entry.value as AmountCompat).add(AmountCompat.from_number(amount))
			entry.ever_obtained = true
			entry.unlocked = true
	elif def.has("grant_pill"):
		var pill_id: String = def["grant_pill"]
		var cnt: int = int(def["grant_count"])
		if pill_id == "foundation_pill" and state.resources.has("foundation_pill"):
			var fp_entry: Dictionary = state.resources["foundation_pill"]
			fp_entry.value = (fp_entry.value as AmountCompat).add(AmountCompat.from_number(float(cnt))).clamp_amount(AmountCompat.zero(), AmountCompat.from_number(200.0))
			fp_entry.ever_obtained = true
			fp_entry.unlocked = true
		else:
			state.pills[pill_id] = int(state.pills.get(pill_id, 0)) + cnt
	
	return {
		"ok": true,
		"item_id": item_id,
		"purchase_count": purchases[item_id],
		"events": [{
			"kind": "market_item_bought",
			"item_id": item_id,
		}],
	}

static func compute_multipliers(state: GameState) -> Dictionary:
	var mults := {
		"production_herb_wood": 0.0,
		"cultivation_speed_bonus": 0.0,
		"storage_bonus": 0.0,
		"lingqi_cap_bonus": 0.0,
	}
	if not (state.sect is Dictionary) or state.sect.is_empty():
		return mults
	var techs: Dictionary = state.sect.get("techniques", {})
	if techs.has("divine_farm"):
		mults.production_herb_wood += float(techs["divine_farm"]) * 0.10
	if techs.has("breathing_method"):
		mults.cultivation_speed_bonus += float(techs["breathing_method"]) * 0.02
	if techs.has("storage_talisman"):
		mults.storage_bonus += float(techs["storage_talisman"]) * 0.10
	if techs.has("essence_array"):
		mults.lingqi_cap_bonus += float(techs["essence_array"]) * 0.20
	return mults

static func tick(state: GameState, elapsed_seconds: float) -> void:
	if not (state.sect is Dictionary) or state.sect.is_empty():
		return
	var sect: Dictionary = state.sect
	if not bool(sect.get("unlocked", false)):
		return
	
	# Advance active expedition
	var active = sect.get("active_expedition")
	if active != null and active is Dictionary:
		active["elapsed"] = mini(int(active.get("duration", 0)), int(active.get("elapsed", 0)) + int(ceil(elapsed_seconds)))
	
	# Advance refresh cooldown
	var refresh_cd := int(sect.get("next_refresh_seconds", 0))
	if refresh_cd > 0:
		sect["next_refresh_seconds"] = maxi(0, refresh_cd - int(ceil(elapsed_seconds)))

static func on_reincarnate(state: GameState) -> void:
	if not (state.sect is Dictionary) or state.sect.is_empty():
		return
	var sect: Dictionary = state.sect
	# Reset ongoing physical expedition and tasks
	sect["active_expedition"] = null
	sect["available_tasks"] = []
	sect["next_refresh_seconds"] = 0
	# Sect membership requires re-joining in new mortal life
	sect["unlocked"] = false
