class_name BuffSystem
extends RefCounted

const DEFINITIONS := {
	"spirit_surge": {
		"id": "spirit_surge",
		"name": "天靈氣湧",
		"icon_text": "湧",
		"color": "#4fe3c1",
		"description": "天地靈脈噴湧，全洞府產率 +30%，靈氣產率額外 +50%。",
		"default_duration": 300.0,
		"is_permanent": false,
		"transmigratable": false,
		"effects": {
			"production_multiplier": 0.30,
			"specific_resource_multiplier": {
				"lingli": 0.50
			}
		}
	},
	"epiphany": {
		"id": "epiphany",
		"name": "頓悟靈光",
		"icon_text": "悟",
		"color": "#ffd700",
		"description": "福至心靈，天道共鳴。修煉速度 +100%。",
		"default_duration": 180.0,
		"is_permanent": false,
		"transmigratable": false,
		"effects": {
			"cultivation_speed_bonus": 1.00
		}
	},
	"breakthrough_resonance": {
		"id": "breakthrough_resonance",
		"name": "破境餘韻",
		"icon_text": "破",
		"color": "#e888ff",
		"description": "大境界突破後的造化反饋。全產率 +20%，修煉速度 +30%。",
		"default_duration": 120.0,
		"is_permanent": false,
		"transmigratable": false,
		"effects": {
			"production_multiplier": 0.20,
			"cultivation_speed_bonus": 0.30
		}
	},
	"turtle_breath": {
		"id": "turtle_breath",
		"name": "長生龜息",
		"icon_text": "壽",
		"color": "#77f29b",
		"description": "上古龜息吐納秘法，固本延年。當世壽元上限 +10 祀。",
		"default_duration": 0.0,
		"is_permanent": true,
		"transmigratable": false,
		"effects": {
			"lifespan_bonus_years": 10.0
		}
	}
}

static func get_definition(buff_id: String) -> Variant:
	return DEFINITIONS.get(buff_id, null)

static func apply_buff(state: GameState, buff_id: String, duration: float = -1.0, custom_effects: Dictionary = {}, transmigratable: bool = false) -> Dictionary:
	if state == null:
		return {"ok": false, "error": "NULL_STATE"}
	var def: Variant = get_definition(buff_id)
	var name: String = buff_id
	var icon_text: String = "符"
	var color: String = "#ffffff"
	var description: String = ""
	var is_permanent: bool = false
	var effects: Dictionary = {}
	var trans: bool = transmigratable

	if def != null:
		name = String(def.get("name", buff_id))
		icon_text = String(def.get("icon_text", "符"))
		color = String(def.get("color", "#ffffff"))
		description = String(def.get("description", ""))
		is_permanent = bool(def.get("is_permanent", false))
		trans = trans or bool(def.get("transmigratable", false))
		effects = (def.get("effects", {}) as Dictionary).duplicate(true)
		if duration < 0.0 and not is_permanent:
			duration = float(def.get("default_duration", 60.0))
	else:
		if duration < 0.0:
			duration = 60.0

	for k in custom_effects:
		effects[k] = custom_effects[k]

	var remaining := 0.0 if is_permanent else maxf(0.0, duration)
	if state.buffs.has(buff_id):
		var existing: Dictionary = state.buffs[buff_id]
		if not is_permanent and not bool(existing.get("is_permanent", false)):
			# Refresh to maximum duration or extend
			remaining = maxf(float(existing.get("remaining_seconds", 0.0)), duration)

	var entry: Dictionary = {
		"id": buff_id,
		"name": name,
		"icon_text": icon_text,
		"color": color,
		"description": description,
		"is_permanent": is_permanent,
		"duration_seconds": duration,
		"remaining_seconds": remaining,
		"transmigratable": trans,
		"effects": effects,
	}

	state.buffs[buff_id] = entry
	return {
		"ok": true,
		"buff": entry,
		"events": [{
			"kind": "buff_applied",
			"buff_id": buff_id,
			"remaining_seconds": remaining,
		}]
	}

static func remove_buff(state: GameState, buff_id: String) -> bool:
	if state == null or not state.buffs.has(buff_id):
		return false
	state.buffs.erase(buff_id)
	return true

static func tick(state: GameState, elapsed_seconds: float) -> Dictionary:
	if state == null or state.buffs.is_empty() or elapsed_seconds <= 0.0:
		return {"expired": []}
	var expired: Array = []
	var to_erase: Array = []
	for buff_id in state.buffs:
		var entry: Dictionary = state.buffs[buff_id]
		if bool(entry.get("is_permanent", false)):
			continue
		var rem := float(entry.get("remaining_seconds", 0.0)) - elapsed_seconds
		if rem <= 0.0:
			to_erase.append(buff_id)
			expired.append(buff_id)
		else:
			entry["remaining_seconds"] = rem
	for buff_id in to_erase:
		state.buffs.erase(buff_id)
	return {"expired": expired}

static func compute_multipliers(state: GameState) -> Dictionary:
	var res := {
		"global_production_multiplier": 0.0,
		"cultivation_speed_bonus": 0.0,
		"lifespan_bonus_years": 0.0,
		"specific_resource_multipliers": {},
	}
	if state == null or state.buffs.is_empty():
		return res

	for buff_id in state.buffs:
		var entry: Dictionary = state.buffs[buff_id]
		var effects: Dictionary = entry.get("effects", {})
		if effects.has("production_multiplier"):
			res.global_production_multiplier += float(effects["production_multiplier"])
		if effects.has("cultivation_speed_bonus"):
			res.cultivation_speed_bonus += float(effects["cultivation_speed_bonus"])
		if effects.has("lifespan_bonus_years"):
			res.lifespan_bonus_years += float(effects["lifespan_bonus_years"])
		if effects.has("specific_resource_multiplier"):
			var spec_map: Dictionary = effects["specific_resource_multiplier"]
			for r_id in spec_map:
				var cur_val: float = float(res.specific_resource_multipliers.get(r_id, 0.0))
				res.specific_resource_multipliers[r_id] = cur_val + float(spec_map[r_id])
	return res

static func get_active_buffs_view(state: GameState) -> Array:
	if state == null or state.buffs.is_empty():
		return []
	var list: Array = []
	for buff_id in state.buffs:
		var entry: Dictionary = state.buffs[buff_id]
		var rem := float(entry.get("remaining_seconds", 0.0))
		var is_perm := bool(entry.get("is_permanent", false))
		var formatted := ""
		if is_perm:
			formatted = "常駐"
		else:
			var total_sec := int(ceil(rem))
			var m := total_sec / 60
			var s := total_sec % 60
			formatted = "%02d:%02d" % [m, s]
		list.append({
			"id": buff_id,
			"name": entry.get("name", buff_id),
			"icon_text": entry.get("icon_text", "符"),
			"color": entry.get("color", "#ffffff"),
			"description": entry.get("description", ""),
			"is_permanent": is_perm,
			"remaining_seconds": rem,
			"formatted_remaining": formatted,
			"effects": entry.get("effects", {}),
		})
	return list
