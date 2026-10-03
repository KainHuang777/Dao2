class_name AchievementSystem
extends RefCounted

const CATEGORIES := {
	"cultivation": "修道境界",
	"abode": "洞府營造",
	"alchemy": "丹道仙途",
	"sect": "宗門修道",
	"beast_fate": "造化靈獸",
	"reincarnation": "輪迴超脫"
}

const DEFINITIONS := {
	# 修道境界
	"era_qi": {
		"id": "era_qi",
		"name": "初窺門徑",
		"category": "cultivation",
		"desc": "突破凡胎，達到引氣入體二層（修為漸長）。",
		"rewards": {"dao_heart": 5},
		"rewards_desc": "道心 +5"
	},
	"era_foundation": {
		"id": "era_foundation",
		"name": "築基有成",
		"category": "cultivation",
		"desc": "鑄就無垢道基，正式踏入築基期（第 2 境）。",
		"rewards": {"dao_heart": 20, "dao_proof": 1},
		"rewards_desc": "道心 +20、道證 +1"
	},
	"era_golden_core": {
		"id": "era_golden_core",
		"name": "結成金丹",
		"category": "cultivation",
		"desc": "一顆金丹吞入腹，始知我命不由天（第 3 境）。",
		"rewards": {"dao_heart": 100, "dao_proof": 2},
		"rewards_desc": "道心 +100、道證 +2"
	},
	"era_nascent_soul": {
		"id": "era_nascent_soul",
		"name": "元嬰大能",
		"category": "cultivation",
		"desc": "破丹成嬰，神遊天地，傲立群修（第 4 境）。",
		"rewards": {"dao_heart": 500, "dao_proof": 5},
		"rewards_desc": "道心 +500、道證 +5"
	},

	# 洞府營造
	"build_first_hut": {
		"id": "build_first_hut",
		"name": "仙家草廬",
		"category": "abode",
		"desc": "修築首座茅屋，於荒僻空島立下安身之所。",
		"rewards": {"resource": {"wood": 100}},
		"rewards_desc": "靈木 +100"
	},
	"build_sum_10": {
		"id": "build_sum_10",
		"name": "洞天初成",
		"category": "abode",
		"desc": "洞府百廢俱興，全建築總等級累計達到 10 級。",
		"rewards": {"resource": {"money": 100, "stone_low": 50}},
		"rewards_desc": "金錢 +100、靈石 +50"
	},
	"build_lingqi_array": {
		"id": "build_lingqi_array",
		"name": "聚靈之陣",
		"category": "abode",
		"desc": "引地脈之氣，修造聚靈陣匯聚天地精華。",
		"rewards": {"resource": {"lingqi": 200}},
		"rewards_desc": "靈氣 +200"
	},
	"scenery_harvest": {
		"id": "scenery_harvest",
		"name": "採菊東籬",
		"category": "abode",
		"desc": "漫步洞府崖畔，首次採收洞府小景資糧。",
		"rewards": {"dao_heart": 10},
		"rewards_desc": "道心 +10"
	},

	# 丹道仙途
	"craft_first_pill": {
		"id": "craft_first_pill",
		"name": "丹爐初啟",
		"category": "alchemy",
		"desc": "以靈植為引，真火為薪，首次煉製一枚仙丹。",
		"rewards": {"resource": {"herb": 50}},
		"rewards_desc": "靈草 +50"
	},
	"consume_pill": {
		"id": "consume_pill",
		"name": "金丹入腹",
		"category": "alchemy",
		"desc": "吞服靈丹妙藥，洗髓伐經，發揮藥石之效。",
		"rewards": {"dao_heart": 15},
		"rewards_desc": "道心 +15"
	},

	# 宗門修道
	"join_first_sect": {
		"id": "join_first_sect",
		"name": "拜入仙門",
		"category": "sect",
		"desc": "尋訪名山大川，正式拜入正統修仙宗門山門。",
		"rewards": {"sect_contribution": 100},
		"rewards_desc": "宗門貢獻 +100"
	},
	"complete_expedition": {
		"id": "complete_expedition",
		"name": "宗門柱石",
		"category": "sect",
		"desc": "完成宗門委託派遣任務，為宗門立下汗馬功勞。",
		"rewards": {"sect_contribution": 50, "dao_heart": 10},
		"rewards_desc": "貢獻 +50、道心 +10"
	},
	"learn_technique": {
		"id": "learn_technique",
		"name": "妙法真傳",
		"category": "sect",
		"desc": "參悟宗門藏經閣真傳，修習一門宗門真訣。",
		"rewards": {"dao_heart": 25},
		"rewards_desc": "道心 +25"
	},

	# 造化靈獸
	"bond_beast": {
		"id": "bond_beast",
		"name": "靈獸締約",
		"category": "beast_fate",
		"desc": "以血脈為誓，首次與上古靈獸締結共生契約。",
		"rewards": {"dao_heart": 30},
		"rewards_desc": "道心 +30"
	},
	"feed_beast": {
		"id": "feed_beast",
		"name": "悉心育化",
		"category": "beast_fate",
		"desc": "以珍稀資糧哺育靈獸，助力其蛻變成長。",
		"rewards": {"resource": {"money": 100}},
		"rewards_desc": "金錢 +100"
	},
	"fortune_choice": {
		"id": "fortune_choice",
		"name": "仙緣造化",
		"category": "beast_fate",
		"desc": "遊歷諸天時遭遇天地機緣，並做出審慎決策。",
		"rewards": {"dao_heart": 15},
		"rewards_desc": "道心 +15"
	},

	# 輪迴超脫
	"first_reincarnate": {
		"id": "first_reincarnate",
		"name": "一世沉浮",
		"category": "reincarnation",
		"desc": "道盡途窮或兵解轉世，首次踏入六道輪迴大道。",
		"rewards": {"dao_heart": 50, "dao_proof": 1},
		"rewards_desc": "道心 +50、道證 +1"
	},
	"dao_heart_100": {
		"id": "dao_heart_100",
		"name": "道心明澈",
		"category": "reincarnation",
		"desc": "累世苦修，累積獲得超過 100 點無上道心。",
		"rewards": {"dao_proof": 2},
		"rewards_desc": "道證 +2"
	}
}

static func ensure_achievements_state(state: GameState) -> Dictionary:
	if not (state.achievements is Dictionary):
		state.achievements = {}
	if not state.achievements.has("unlocked") or not (state.achievements["unlocked"] is Dictionary):
		state.achievements["unlocked"] = {}
	if not state.achievements.has("claimed") or not (state.achievements["claimed"] is Dictionary):
		state.achievements["claimed"] = {}
	if not state.achievements.has("stats") or not (state.achievements["stats"] is Dictionary):
		state.achievements["stats"] = {}
	return state.achievements

static func record_stat(state: GameState, stat_key: String, delta: int = 1) -> void:
	var ach := ensure_achievements_state(state)
	var stats: Dictionary = ach["stats"]
	stats[stat_key] = int(stats.get(stat_key, 0)) + delta

static func check_achievements(state: GameState, content: GameContent = null) -> Array[String]:
	var ach := ensure_achievements_state(state)
	var unlocked: Dictionary = ach["unlocked"]
	var stats: Dictionary = ach["stats"]
	var newly_unlocked: Array[String] = []

	var bld_sum := 0
	for b_id in state.buildings:
		bld_sum += int(state.buildings[b_id])

	for id in DEFINITIONS:
		if unlocked.has(id):
			continue
		var is_met := false
		match id:
			"era_qi":
				is_met = state.era_id > 1 or (state.era_id == 1 and state.level >= 2) or state.highest_era > 1
			"era_foundation":
				is_met = state.era_id >= 2 or state.highest_era >= 2
			"era_golden_core":
				is_met = state.era_id >= 3 or state.highest_era >= 3
			"era_nascent_soul":
				is_met = state.era_id >= 4 or state.highest_era >= 4
			"build_first_hut":
				is_met = int(state.buildings.get("hut", 0)) >= 1
			"build_sum_10":
				is_met = bld_sum >= 10
			"build_lingqi_array":
				is_met = int(state.buildings.get("lingqi_array", 0)) >= 1
			"scenery_harvest":
				is_met = int(stats.get("total_harvests", 0)) >= 1
			"craft_first_pill":
				is_met = int(stats.get("pills_crafted", 0)) >= 1 or not state.pills.is_empty() or int(state.pill_effects.get("total_consumed", 0)) > 0
			"consume_pill":
				is_met = int(state.pill_effects.get("total_consumed", 0)) >= 1
			"join_first_sect":
				is_met = not String(state.sect.get("current_sect", "")).is_empty()
			"complete_expedition":
				is_met = int(state.sect.get("completed_tasks", 0)) >= 1 or int(stats.get("sect_tasks", 0)) >= 1
			"learn_technique":
				is_met = not (state.sect.get("techniques", {}) as Dictionary).is_empty()
			"bond_beast":
				is_met = not (state.beasts.get("active", {}) as Dictionary).is_empty() or not (state.beast_souls as Dictionary).is_empty() or int(stats.get("bonded_beasts", 0)) >= 1
			"feed_beast":
				is_met = int(stats.get("beast_feedings", 0)) >= 1 or int(state.beasts.get("active", {}).get("exp", 0)) > 0 or String(state.beasts.get("active", {}).get("stage", "")) in ["juvenile", "growth", "mature"]
			"fortune_choice":
				is_met = int(stats.get("fortune_resolved", 0)) >= 1 or not (state.fortune.get("history", []) as Array).is_empty()
			"first_reincarnate":
				is_met = state.reincarnation_count >= 1
			"dao_heart_100":
				var dh_val := state.dao_heart.to_float() if state.dao_heart != null else 0.0
				is_met = dh_val >= 100.0

		if is_met:
			unlocked[id] = state.total_elapsed_seconds
			newly_unlocked.append(id)

	return newly_unlocked

static func claim_reward(state: GameState, content: GameContent, achievement_id: String) -> Dictionary:
	if not DEFINITIONS.has(achievement_id):
		return {"ok": false, "error": "UNKNOWN_ACHIEVEMENT", "message": "未知成就 ID"}
	var def: Dictionary = DEFINITIONS[achievement_id]
	var ach := ensure_achievements_state(state)
	var unlocked: Dictionary = ach["unlocked"]
	var claimed: Dictionary = ach["claimed"]

	if not unlocked.has(achievement_id):
		return {"ok": false, "error": "ACHIEVEMENT_NOT_UNLOCKED", "message": "成就尚未達成，無法領取"}
	if bool(claimed.get(achievement_id, false)):
		return {"ok": false, "error": "ALREADY_CLAIMED", "message": "此成就獎勵已領取"}

	var rewards: Dictionary = def.get("rewards", {})
	if rewards.has("dao_heart"):
		var dh_add := float(rewards["dao_heart"])
		if state.dao_heart == null:
			state.dao_heart = AmountCompat.from_number(dh_add)
		else:
			state.dao_heart = state.dao_heart.add(AmountCompat.from_number(dh_add))

	if rewards.has("dao_proof"):
		state.dao_proof += int(rewards["dao_proof"])

	if rewards.has("sect_contribution"):
		if not (state.sect is Dictionary):
			state.sect = {}
		state.sect["contribution"] = int(state.sect.get("contribution", 0)) + int(rewards["sect_contribution"])

	if rewards.has("resource"):
		var res_dict: Dictionary = rewards["resource"]
		for res_id in res_dict:
			var add_val := float(res_dict[res_id])
			if state.resources.has(res_id):
				var entry: Dictionary = state.resources[res_id]
				entry.unlocked = true
				entry.ever_obtained = true
				if entry.has("value") and entry.value is AmountCompat:
					entry.value = entry.value.add(AmountCompat.from_number(add_val))
			else:
				state.resources[res_id] = {
					"value": AmountCompat.from_number(add_val),
					"unlocked": true,
					"ever_obtained": true
				}

	claimed[achievement_id] = true
	return {
		"ok": true,
		"achievement_id": achievement_id,
		"rewards": rewards,
		"message": "成功領取成就獎勵：%s" % def.get("rewards_desc", "")
	}

static func reset_achievements(state: GameState) -> void:
	state.achievements = {
		"unlocked": {},
		"claimed": {},
		"stats": {}
	}

static func get_achievement_view(state: GameState) -> Dictionary:
	var ach := ensure_achievements_state(state)
	var unlocked: Dictionary = ach["unlocked"]
	var claimed: Dictionary = ach["claimed"]

	var total_count := DEFINITIONS.size()
	var unlocked_count := unlocked.size()
	var claimed_count := claimed.size()
	var unclaimed_count := 0

	var list: Array[Dictionary] = []
	for id in DEFINITIONS:
		var def: Dictionary = DEFINITIONS[id]
		var is_unlocked := unlocked.has(id)
		var is_claimed := bool(claimed.get(id, false))
		if is_unlocked and not is_claimed:
			unclaimed_count += 1
		list.append({
			"id": id,
			"name": def.name,
			"category": def.category,
			"category_name": CATEGORIES.get(def.category, "其他"),
			"desc": def.desc,
			"rewards_desc": def.rewards_desc,
			"unlocked": is_unlocked,
			"claimed": is_claimed,
			"can_claim": is_unlocked and not is_claimed
		})

	var completion_percent := (float(unlocked_count) / float(total_count) * 100.0) if total_count > 0 else 0.0

	return {
		"total_count": total_count,
		"unlocked_count": unlocked_count,
		"claimed_count": claimed_count,
		"unclaimed_count": unclaimed_count,
		"completion_percent": completion_percent,
		"achievements": list
	}
