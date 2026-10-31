class_name SectLineage
extends RefCounted
## CORE-3 bounded feature. Old snapshots remain untouched until new tasks are generated.
const VERSION := 1
const LIMIT := 2147483647
const KEYS := ["taixu", "tianjian", "piaomiao", "wanfo", "zixiao"]
const NAMES := ["太虛", "天劍", "縹緲", "萬佛", "紫霄"]
const TALENT_NAMES := ["太虛道種", "劍脈宿根", "丹庭宿根", "蓮心宿根", "紫府宿根"]
const EFFECTS := ["修速", "指定外島礦採集", "指定外島草採集", "壽元比例", "祖島靈力容量"]
const THRESHOLDS := [1, 3, 5]
const COSTS := [5, 10, 20]
const TALENT_IDS := ["taixu_lineage", "tianjian_lineage", "piaomiao_lineage", "wanfo_lineage", "zixiao_lineage"]
const ACHIEVEMENTS := {
	"sect_taixu_lineage_1": {
		"id": "sect_taixu_lineage_1",
		"name": "太虛初傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 1 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：太虛初傳",
		"sect_id": "taixu_sect",
		"required_lives": 1
	},
	"sect_taixu_lineage_3": {
		"id": "sect_taixu_lineage_3",
		"name": "太虛承道",
		"category": "sect",
		"desc": "成功完成該宗有效世數 3 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：太虛承道",
		"sect_id": "taixu_sect",
		"required_lives": 3
	},
	"sect_taixu_lineage_5": {
		"id": "sect_taixu_lineage_5",
		"name": "太虛真傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 5 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：太虛真傳",
		"sect_id": "taixu_sect",
		"required_lives": 5
	},
	"sect_tianjian_lineage_1": {
		"id": "sect_tianjian_lineage_1",
		"name": "天劍初傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 1 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：天劍初傳",
		"sect_id": "tianjian_sect",
		"required_lives": 1
	},
	"sect_tianjian_lineage_3": {
		"id": "sect_tianjian_lineage_3",
		"name": "天劍承道",
		"category": "sect",
		"desc": "成功完成該宗有效世數 3 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：天劍承道",
		"sect_id": "tianjian_sect",
		"required_lives": 3
	},
	"sect_tianjian_lineage_5": {
		"id": "sect_tianjian_lineage_5",
		"name": "天劍真傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 5 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：天劍真傳",
		"sect_id": "tianjian_sect",
		"required_lives": 5
	},
	"sect_piaomiao_lineage_1": {
		"id": "sect_piaomiao_lineage_1",
		"name": "縹緲初傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 1 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：縹緲初傳",
		"sect_id": "piaomiao_sect",
		"required_lives": 1
	},
	"sect_piaomiao_lineage_3": {
		"id": "sect_piaomiao_lineage_3",
		"name": "縹緲承道",
		"category": "sect",
		"desc": "成功完成該宗有效世數 3 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：縹緲承道",
		"sect_id": "piaomiao_sect",
		"required_lives": 3
	},
	"sect_piaomiao_lineage_5": {
		"id": "sect_piaomiao_lineage_5",
		"name": "縹緲真傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 5 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：縹緲真傳",
		"sect_id": "piaomiao_sect",
		"required_lives": 5
	},
	"sect_wanfo_lineage_1": {
		"id": "sect_wanfo_lineage_1",
		"name": "萬佛初傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 1 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：萬佛初傳",
		"sect_id": "wanfo_sect",
		"required_lives": 1
	},
	"sect_wanfo_lineage_3": {
		"id": "sect_wanfo_lineage_3",
		"name": "萬佛承道",
		"category": "sect",
		"desc": "成功完成該宗有效世數 3 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：萬佛承道",
		"sect_id": "wanfo_sect",
		"required_lives": 3
	},
	"sect_wanfo_lineage_5": {
		"id": "sect_wanfo_lineage_5",
		"name": "萬佛真傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 5 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：萬佛真傳",
		"sect_id": "wanfo_sect",
		"required_lives": 5
	},
	"sect_zixiao_lineage_1": {
		"id": "sect_zixiao_lineage_1",
		"name": "紫霄初傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 1 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：紫霄初傳",
		"sect_id": "zixiao_sect",
		"required_lives": 1
	},
	"sect_zixiao_lineage_3": {
		"id": "sect_zixiao_lineage_3",
		"name": "紫霄承道",
		"category": "sect",
		"desc": "成功完成該宗有效世數 3 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：紫霄承道",
		"sect_id": "zixiao_sect",
		"required_lives": 3
	},
	"sect_zixiao_lineage_5": {
		"id": "sect_zixiao_lineage_5",
		"name": "紫霄真傳",
		"category": "sect",
		"desc": "成功完成該宗有效世數 5 次（築基、正式領取3件新委託及成功輪迴）。",
		"rewards": {},
		"rewards_desc": "紀念稱號：紫霄真傳",
		"sect_id": "zixiao_sect",
		"required_lives": 5
	},
	"sect_five_paths": {
		"id": "sect_five_paths",
		"name": "五宗問道",
		"category": "sect",
		"desc": "五宗各完成至少1有效世。",
		"rewards": {},
		"rewards_desc": "紀念稱號：五宗問道"
	}
}

static func talent_ids() -> Array:
	return TALENT_IDS

static func definition(id: String) -> Variant:
	var index := talent_ids().find(id)
	if index < 0: return null
	return {"id": id, "name": TALENT_NAMES[index], "max_level": 3, "base_cost": 5, "cost_factor": 2.0, "description": "每階" + EFFECTS[index] + "+2%；當世所屬宗門且築基後啟用，跨世保留"}

static func initial(state: GameState) -> Dictionary:
	var counts := {}
	var learned := {}
	for key in KEYS:
		counts[key + "_sect"] = 0
		learned[key + "_lineage"] = 0
	return {"version": VERSION, "life_seq": state.reincarnation_count, "life_sect_id": SectIdentity.view(state.sect).sect_id,
		"life_claimed": 0, "life_peak_era": state.era_id, "last_settled_life_seq": -1, "completed_lives": counts, "learned": learned}

static func ensure(state: GameState) -> Dictionary:
	if not state.sect.has("lineage"): state.sect.lineage = initial(state)
	return state.sect.lineage

static func observe(state: GameState) -> void:
	if not state.sect.has("lineage"): return
	state.sect.lineage.life_peak_era = maxi(int(state.sect.lineage.life_peak_era), state.era_id)
	state.sect.lineage.life_sect_id = SectIdentity.view(state.sect).sect_id

static func stamp(state: GameState, task: Dictionary) -> void:
	var data := ensure(state)
	observe(state)
	task.lineage_credit = {"version": VERSION, "life_seq": data.life_seq, "sect_id": data.life_sect_id}

static func task_error(task: Dictionary) -> String:
	if not task.has("lineage_credit"): return ""
	var credit: Variant = task.lineage_credit
	if not credit is Dictionary or credit.size() != 3: return "SECT_LINEAGE_TASK"
	if not SectSaveContract.integer(credit.get("version"), VERSION) or credit.version != VERSION: return "SECT_LINEAGE_TASK_VERSION"
	if not SectSaveContract.integer(credit.get("life_seq")) or not SectIdentity.NAMES.has(credit.get("sect_id")): return "SECT_LINEAGE_TASK"
	return ""

static func claim_error(state: GameState, task: Dictionary) -> String:
	var error := task_error(task)
	if not error.is_empty() or not task.has("lineage_credit"): return error
	error = validate_state(state)
	if not error.is_empty(): return error
	if not state.sect.has("lineage"): return "SECT_LINEAGE_MISSING"
	var data: Dictionary = state.sect.lineage
	if task.lineage_credit.life_seq != data.life_seq or task.lineage_credit.sect_id != SectIdentity.view(state.sect).sect_id: return "SECT_LINEAGE_TASK_LIFE"
	return "SECT_LINEAGE_OVERFLOW" if data.life_claimed >= LIMIT else ""

static func claimed(state: GameState, task: Dictionary) -> void:
	if not task.has("lineage_credit"): return # No historical backfill.
	observe(state)
	state.sect.lineage.life_claimed += 1

static func qualifies(state: GameState) -> bool:
	if not state.sect.has("lineage"): return false
	var data: Dictionary = state.sect.lineage
	var id: String = SectIdentity.view(state.sect).sect_id
	return not id.is_empty() and data.life_sect_id == id and maxi(data.life_peak_era, state.era_id) >= 2 and data.life_claimed >= 3 and data.last_settled_life_seq < data.life_seq

static func settlement_error(state: GameState) -> String:
	var error := validate_state(state)
	if not error.is_empty(): return error
	if state.reincarnation_count >= LIMIT: return "SECT_LINEAGE_OVERFLOW"
	if qualifies(state) and state.sect.lineage.completed_lives[SectIdentity.view(state.sect).sect_id] >= LIMIT: return "SECT_LINEAGE_OVERFLOW"
	return ""

static func settle(state: GameState) -> void:
	if not state.sect.has("lineage"): return
	observe(state)
	if qualifies(state): state.sect.lineage.completed_lives[state.sect.lineage.life_sect_id] += 1
	state.sect.lineage.last_settled_life_seq = state.sect.lineage.life_seq
	# Reveal before clearing membership; claiming titles is independent of eligibility.
	AchievementSystem.check_achievements(state)

static func next_life(state: GameState) -> void:
	if not state.sect.has("lineage"): return
	var data: Dictionary = state.sect.lineage
	data.life_seq = state.reincarnation_count
	data.life_sect_id = ""
	data.life_claimed = 0
	data.life_peak_era = state.era_id

static func completed(state: GameState, sect: String) -> int:
	return int(state.sect.get("lineage", {}).get("completed_lives", {}).get(sect, 0))

static func rank(state: GameState, id: String) -> int:
	return int(state.sect.get("lineage", {}).get("learned", {}).get(id, 0))

static func bonus(state: GameState, key: String) -> float:
	if state == null or state.era_id < 2 or SectIdentity.view(state.sect).sect_id != key + "_sect": return 0.0
	return 0.02 * rank(state, key + "_lineage")

static func can_learn(state: GameState, id: String) -> Dictionary:
	var error := validate_state(state)
	var index := talent_ids().find(id)
	var current := rank(state, id)
	if error.is_empty() and index < 0: error = "UNKNOWN_TALENT"
	if error.is_empty() and not SectSystem.p2_life_error(state).is_empty(): error = "LIFESPAN_EXHAUSTED"
	if error.is_empty() and current >= 3: error = "TALENT_MAX_LEVEL"
	if error.is_empty() and completed(state, KEYS[index] + "_sect") < THRESHOLDS[current]: error = "SECT_LINEAGE_LIVES_REQUIRED"
	if error.is_empty() and state.dao_heart.compare_to(AmountCompat.from_number(COSTS[current])) < 0: error = "INSUFFICIENT_DAO_HEART"
	if not error.is_empty(): return {"can_learn": false, "reason": error}
	return {"can_learn": true, "cost": AmountCompat.from_number(COSTS[current]), "next_level": current + 1}

static func learn(state: GameState, id: String) -> Dictionary:
	var check := can_learn(state, id)
	if not check.can_learn: return {"ok": false, "error": check.reason, "events": [], "changed_ids": []}
	state.dao_heart = state.dao_heart.subtract(check.cost)
	state.sect.lineage.learned[id] = check.next_level
	return {"ok": true, "events": [{"kind": "talent_learned", "talent_id": id, "new_level": check.next_level, "cost": check.cost.serialize()}], "changed_ids": ["sect", "talents", "dao_heart"]}

static func achievement_definitions() -> Dictionary:
	return ACHIEVEMENTS

static func achievement_met(state: GameState, id: String) -> bool:
	if id == "sect_five_paths":
		for key in KEYS:
			if completed(state, key + "_sect") < 1: return false
		return true
	var def: Dictionary = achievement_definitions().get(id, {})
	return not def.is_empty() and completed(state, def.sect_id) >= def.required_lives

static func revealed(state: GameState, id: String) -> bool:
	if id == "sect_five_paths":
		for key in KEYS:
			if completed(state, key + "_sect") > 0: return true
		return false
	var def: Dictionary = achievement_definitions().get(id, {})
	return not def.is_empty() and completed(state, def.sect_id) > 0

static func view(state: GameState) -> Dictionary:
	var data: Dictionary = state.sect.get("lineage", initial(state))
	var options := {}
	for id in talent_ids():
		var key := String(id).trim_suffix("_lineage")
		var known := completed(state, key + "_sect") > 0
		var current := rank(state, id)
		options[id] = {"name": definition(id).name if known else "未明傳承", "revealed": known, "completed_lives": completed(state, key + "_sect"), "learned_level": current, "active_bonus": bonus(state, key), "thresholds": THRESHOLDS if known else [], "next_cost": COSTS[current] if known and current < 3 else 0, "requirements": can_learn(state, id), "dormant_reason": "" if bonus(state, key) > 0 else ("尚未購入" if current == 0 else "需當世加入對應宗門且築基")}
	return {"life_seq": data.life_seq, "life_sect_id": data.life_sect_id, "life_claimed": data.life_claimed, "life_peak_era": maxi(data.life_peak_era, state.era_id), "qualifies_on_reincarnation": qualifies(state), "talents": options}

static func validate(sect: Dictionary) -> String:
	var identity_error := SectIdentity.validate(sect)
	if not identity_error.is_empty(): return identity_error
	if not sect.has("lineage"): return ""
	var data: Variant = sect.lineage
	if not data is Dictionary or data.size() != 8: return "SECT_LINEAGE_STRUCTURE"
	if not SectSaveContract.integer(data.get("version"), VERSION) or data.version != VERSION: return "SECT_LINEAGE_VERSION"
	for field in ["life_seq", "life_claimed", "life_peak_era"]:
		if not SectSaveContract.integer(data.get(field), 12 if field == "life_peak_era" else LIMIT): return "SECT_LINEAGE_COUNTER"
	if data.life_peak_era < 1: return "SECT_LINEAGE_PEAK"
	var last: Variant = data.get("last_settled_life_seq")
	if not (last is int or last is float) or not is_finite(float(last)) or float(last) != floor(float(last)) or last < -1 or last >= data.life_seq: return "SECT_LINEAGE_SEQUENCE"
	if not data.get("life_sect_id") is String or data.life_sect_id != SectIdentity.view(sect).sect_id: return "SECT_LINEAGE_IDENTITY"
	for field in ["completed_lives", "learned"]:
		var entries: Variant = data.get(field)
		if not entries is Dictionary or entries.size() != 5: return "SECT_LINEAGE_KEYS"
		for key in KEYS:
			var id: String = key + ("_sect" if field == "completed_lives" else "_lineage")
			if not SectSaveContract.integer(entries.get(id), LIMIT if field == "completed_lives" else 3): return "SECT_LINEAGE_VALUE"
	for key in KEYS:
		var learned: int = data.learned[key + "_lineage"]
		if learned > 0 and data.completed_lives[key + "_sect"] < THRESHOLDS[learned - 1]: return "SECT_LINEAGE_RANK"
	return ""

static func validate_state(state: GameState) -> String:
	var error := validate(state.sect)
	if not error.is_empty(): return error
	if not SectSaveContract.integer(state.reincarnation_count): return "SECT_LINEAGE_SEQUENCE"
	for field in ["unlocked", "claimed"]:
		var entries: Variant = state.achievements.get(field, {})
		if not entries is Dictionary: return "SECT_LINEAGE_ACHIEVEMENT"
		for id in entries:
			if not String(id).begins_with("sect_"): continue
			if not ACHIEVEMENTS.has(id): return "SECT_LINEAGE_ACHIEVEMENT_ID"
			if field == "unlocked":
				if not SectSaveContract.number(entries[id]) or not achievement_met(state,id): return "SECT_LINEAGE_ACHIEVEMENT"
			else:
				if not entries[id] is bool: return "SECT_LINEAGE_CLAIM_FLAG"
				if entries[id] and not state.achievements.get("unlocked", {}).has(id): return "SECT_LINEAGE_CLAIM_FLAG"
	var tasks: Variant = state.sect.get("available_tasks", [])
	if not tasks is Array: return "SECT_TASK_COUNT"
	tasks = tasks.duplicate()
	if state.sect.get("active_expedition") != null: tasks.append(state.sect.active_expedition)
	for task in tasks:
		if not task is Dictionary: return "SECT_TASK_TYPE"
		error = task_error(task)
		if not error.is_empty(): return error
	if not state.sect.has("lineage"):
		for task in tasks:
			if task.has("lineage_credit"): return "SECT_LINEAGE_MISSING"
		return ""
	var data: Dictionary = state.sect.lineage
	if data.life_seq != state.reincarnation_count: return "SECT_LINEAGE_LIFE"
	var total := 0
	for n in data.completed_lives.values(): total += int(n)
	if total > state.reincarnation_count: return "SECT_LINEAGE_TOTAL"
	for task in tasks:
		if task.has("lineage_credit") and (task.lineage_credit.life_seq != data.life_seq or task.lineage_credit.sect_id != data.life_sect_id): return "SECT_LINEAGE_TASK_LIFE"
	return ""
