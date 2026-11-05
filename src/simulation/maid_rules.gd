class_name MaidRules
extends RefCounted

const VERSION := 1
const MAID_IDS := ["qingheng", "nuomeizi", "danxia"]
const MAIDS := {
	"qingheng": {"name": "青蘅", "role": "洞府侍女", "duty": "steward_stock", "recruit_era": 1},
	"nuomeizi": {"name": "糯美子", "role": "劍侍", "duty": "oversee_build", "recruit_era": 2},
	"danxia": {"name": "丹霞", "role": "丹師", "duty": "restock_pills", "recruit_era": 2},
}
const BOND_LEVELS := [
	{"id": "chushi", "name": "初識", "at": 0},
	{"id": "xiangzhi", "name": "相知", "at": 40},
	{"id": "xinren", "name": "信任", "at": 100},
	{"id": "tongdao", "name": "同道", "at": 200},
]
const CHAPTERS := {
	"qingheng": [
		{"id": "qingheng_1", "title": "一盞燈", "bond": 20, "requires": "duty_units", "amount": 10},
		{"id": "qingheng_2", "title": "宗門來信", "bond": 30, "requires": "sect_unlocked"},
		{"id": "qingheng_3", "title": "前世燈火", "bond": 50, "requires": "reincarnation_talent"},
		{"id": "qingheng_4", "title": "燈影同行", "bond": 90, "requires": "duty_units", "amount": 20},
	],
	"nuomeizi": [
		{"id": "nuomeizi_1", "title": "第一道劍痕", "bond": 20, "requires": "duty_units", "amount": 3},
		{"id": "nuomeizi_2", "title": "功法相印", "bond": 30, "requires": "any_skill"},
		{"id": "nuomeizi_3", "title": "劍鳴舊世", "bond": 50, "requires": "reincarnation_talent"},
		{"id": "nuomeizi_4", "title": "以劍為盟", "bond": 90, "requires": "duty_units", "amount": 15},
	],
	"danxia": [
		{"id": "danxia_1", "title": "爐火初溫", "bond": 20, "requires": "duty_units", "amount": 5},
		{"id": "danxia_2", "title": "靈獸銜丹", "bond": 30, "requires": "beast_active"},
		{"id": "danxia_3", "title": "丹心照夜", "bond": 50, "requires": "reincarnation_talent"},
		{"id": "danxia_4", "title": "同守一爐", "bond": 90, "requires": "duty_units", "amount": 20},
	],
}
const DUTY_CADENCE_SECONDS := {"steward_stock": 10, "oversee_build": 30, "restock_pills": 10}
const DUTY_PRESETS := {
	"steward_stock": [
		{"id": "steady", "name": "常備", "target": 5, "reserve_ratio": 0.2},
		{"id": "ample", "name": "充裕", "target": 10, "reserve_ratio": 0.1},
		{"id": "rush", "name": "趕工", "target": 20, "reserve_ratio": 0.0},
	],
	"oversee_build": [],
	"restock_pills": [
		{"id": "steady", "name": "常備", "target": 5, "reserve_ratio": 0.2},
		{"id": "ample", "name": "充裕", "target": 10, "reserve_ratio": 0.1},
		{"id": "rush", "name": "趕工", "target": 20, "reserve_ratio": 0.0},
	],
}
const MAX_UNITS_PER_ACTION := 5
const MAX_ACTIONS_PER_CALL := 5
const FIRST_DUTY_BOND := 10

static func maid(maid_id: String) -> Dictionary:
	return MAIDS.get(maid_id, {})

static func chapters(maid_id: String) -> Array:
	return CHAPTERS.get(maid_id, [])

static func duty_presets(kind: String) -> Array:
	return DUTY_PRESETS.get(kind, [])

static func chapter(maid_id: String, chapter_id: String) -> Dictionary:
	for entry in chapters(maid_id):
		if String(entry.id) == chapter_id:
			return entry
	return {}

static func bond_level(points: int) -> Dictionary:
	var result: Dictionary = BOND_LEVELS[0]
	for entry in BOND_LEVELS:
		if points >= int(entry.at):
			result = entry
	return result

static func next_bond(points: int) -> Dictionary:
	for entry in BOND_LEVELS:
		if points < int(entry.at):
			return entry
	return {}
