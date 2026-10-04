class_name ChronoSystem
extends RefCounted

const SECONDS_PER_SHICHEN := 60.0
const SHICHEN_COUNT := 12
const DAY_CYCLE_SECONDS := 720.0 # 12 * 60s
const WEATHER_CYCLE_SECONDS := 360.0 # 6 shichen per weather

const SHICHEN_DATA := [
	{"name": "子時", "short": "子", "element": "水", "desc": "夜半極陰，萬籟俱寂，吐納靜修。修煉速度 +10%。", "cultivation": 0.10, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "丑時", "short": "丑", "element": "土", "desc": "雞鳴未起，地脈沉凝，蓄勢待發。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "寅時", "short": "寅", "element": "木", "desc": "平旦天光，微陽漸啟，晨風初動。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "卯時", "short": "卯", "element": "木", "desc": "日出東方，紫氣氤氳，靈潮初漲。靈氣產率 +15%。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.15, "herb": 0.0},
	{"name": "辰時", "short": "辰", "element": "土", "desc": "食時天地正氣，朝霞映照。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "巳時", "short": "巳", "element": "火", "desc": "隅中陽氣盛，天地溫煦。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "午時", "short": "午", "element": "火", "desc": "日中純陽，草木蓬勃，百脈暢達。全洞府產率 +10%。", "cultivation": 0.0, "global_prod": 0.10, "lingqi": 0.0, "herb": 0.0},
	{"name": "未時", "short": "未", "element": "土", "desc": "日昳陽衰，和風徐徐。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "申時", "short": "申", "element": "金", "desc": "晡時天朗氣清，金光萬道。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "酉時", "short": "酉", "element": "金", "desc": "日落西山，夕華凝露，滋養靈植。靈草產率 +15%。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.15},
	{"name": "戌時", "short": "戌", "element": "土", "desc": "黃昏入定，煙嵐四合。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0},
	{"name": "亥時", "short": "亥", "element": "水", "desc": "人定陰盛，星漢燦爛。", "cultivation": 0.0, "global_prod": 0.0, "lingqi": 0.0, "herb": 0.0}
]

const WEATHER_DATA := {
	"water": {
		"id": "water",
		"name": "坎水運",
		"desc": "天地水靈澎湃，清泉奔流。靈氣產率 +15%。",
		"color": "#4fc3f7",
		"effects": {
			"lingqi": 0.15
		}
	},
	"wood": {
		"id": "wood",
		"name": "巽木運",
		"desc": "青木長生之氣盛，春回洞府。靈草產率 +25%，木材產率 +15%。",
		"color": "#81c784",
		"effects": {
			"herb": 0.25,
			"wood": 0.15
		}
	},
	"fire": {
		"id": "fire",
		"name": "離火運",
		"desc": "南明離火淬天，道心如熾。修煉速度 +15%。",
		"color": "#ff8a65",
		"effects": {
			"cultivation": 0.15
		}
	},
	"earth": {
		"id": "earth",
		"name": "坤土運",
		"desc": "厚德載物，山嶽鎮守。資源儲存上限 +15%。",
		"color": "#dce775",
		"effects": {
			"storage": 0.15
		}
	},
	"metal": {
		"id": "metal",
		"name": "乾金運",
		"desc": "天門白虎金煞，地脈生金。靈石產率 +20%。",
		"color": "#ffd54f",
		"effects": {
			"money": 0.20
		}
	}
}

const WEATHER_ORDER := ["water", "wood", "fire", "earth", "metal"]

static func ensure_initialized(state: GameState) -> void:
	if state == null:
		return
	if not state.chrono is Dictionary or state.chrono.is_empty():
		state.chrono = {
			"unlocked": false,
			"shichen_index": 0,
			"weather_id": "water",
			"shichen_progress": 0.0,
			"cycle_day": 1
		}
	_sync_from_elapsed(state)

static func unlock_chrono(state: GameState) -> void:
	ensure_initialized(state)
	state.chrono["unlocked"] = true

static func is_unlocked(state: GameState) -> bool:
	if state == null or not state.chrono is Dictionary:
		return false
	return bool(state.chrono.get("unlocked", false))

static func _sync_from_elapsed(state: GameState) -> void:
	var total_secs := maxf(0.0, state.total_elapsed_seconds)
	var day_num := int(floor(total_secs / DAY_CYCLE_SECONDS)) + 1
	var sec_in_day := fmod(total_secs, DAY_CYCLE_SECONDS)
	var shichen_idx := int(floor(sec_in_day / SECONDS_PER_SHICHEN)) % SHICHEN_COUNT
	var shichen_prog := fmod(sec_in_day, SECONDS_PER_SHICHEN) / SECONDS_PER_SHICHEN
	
	var weather_idx := int(floor(total_secs / WEATHER_CYCLE_SECONDS)) % WEATHER_ORDER.size()
	var weather_id: String = WEATHER_ORDER[weather_idx]
	
	state.chrono["shichen_index"] = shichen_idx
	state.chrono["weather_id"] = weather_id
	state.chrono["shichen_progress"] = shichen_prog
	state.chrono["cycle_day"] = day_num

static func tick(state: GameState, _elapsed_seconds: float) -> void:
	ensure_initialized(state)
	# ensure_initialized already synchronizes all saved progress from elapsed.

static func get_current_shichen(state: GameState) -> Dictionary:
	ensure_initialized(state)
	var idx: int = int(state.chrono.get("shichen_index", 0))
	if idx < 0 or idx >= SHICHEN_DATA.size():
		idx = 0
	var data: Dictionary = SHICHEN_DATA[idx].duplicate(true)
	data["progress"] = float(state.chrono.get("shichen_progress", 0.0))
	data["day"] = int(state.chrono.get("cycle_day", 1))
	data["unlocked"] = is_unlocked(state)
	return data

static func get_current_weather(state: GameState) -> Dictionary:
	ensure_initialized(state)
	var wid: String = String(state.chrono.get("weather_id", "water"))
	if not WEATHER_DATA.has(wid):
		wid = "water"
	var data: Dictionary = WEATHER_DATA[wid].duplicate(true)
	data["unlocked"] = is_unlocked(state)
	return data

static func compute_multipliers(state: GameState) -> Dictionary:
	ensure_initialized(state)
	var result := {
		"global_production_multiplier": 0.0,
		"cultivation_speed_bonus": 0.0,
		"storage_bonus": 0.0,
		"specific_resource_multipliers": {}
	}
	if not is_unlocked(state):
		return result

	
	var shichen := get_current_shichen(state)
	result["cultivation_speed_bonus"] += float(shichen.get("cultivation", 0.0))
	result["global_production_multiplier"] += float(shichen.get("global_prod", 0.0))
	
	var lq_shichen: float = float(shichen.get("lingqi", 0.0))
	if lq_shichen > 0.0:
		result["specific_resource_multipliers"]["lingqi"] = lq_shichen
	var herb_shichen: float = float(shichen.get("herb", 0.0))
	if herb_shichen > 0.0:
		result["specific_resource_multipliers"]["herb"] = herb_shichen
		
	var weather := get_current_weather(state)
	var effects: Dictionary = weather.get("effects", {})
	if effects.has("cultivation"):
		result["cultivation_speed_bonus"] += float(effects["cultivation"])
	if effects.has("storage"):
		result["storage_bonus"] += float(effects["storage"])
	
	for res_id in ["lingqi", "herb", "wood", "money"]:
		if effects.has(res_id):
			var cur: float = float(result["specific_resource_multipliers"].get(res_id, 0.0))
			result["specific_resource_multipliers"][res_id] = cur + float(effects[res_id])
			
	return result
