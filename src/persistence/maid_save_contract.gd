class_name MaidSaveContract
extends RefCounted

const VERSION := 1
const MAX_BYTES := 16384
const COOLDOWN_CAP := 86400
const STATUS_CAP := 64
const ENTRY_KEYS := ["recruited", "bond", "chapters", "duty", "duty_actions", "reunion_pending", "first_duty_done"]
const STEWARD_KEYS := ["kind", "paused", "cooldown", "status", "recipe_id", "target", "reserve"]
const OVERSEE_KEYS := ["kind", "paused", "cooldown", "status", "building_id"]
const RESTOCK_KEYS := ["kind", "paused", "cooldown", "status", "pill_id", "target", "reserve"]

static func validate(data: Variant) -> String:
	if not (data is Dictionary): return "MAID_TYPE"
	var block: Dictionary = data
	if block.is_empty(): return ""
	if JSON.stringify(block).to_utf8_buffer().size() > MAX_BYTES: return "MAID_SIZE"
	if block.size() != 2 or not block.has("version") or not block.has("maids"): return "MAID_KEYS"
	var version: Variant = block["version"]
	if not SectSaveContract.integer(version) or int(version) != VERSION: return "MAID_VERSION"
	var maids: Variant = block["maids"]
	if not (maids is Dictionary): return "MAID_MAIDS"
	var maid_block: Dictionary = maids
	for maid_id in maid_block:
		if not (maid_id is String) or not MaidRules.MAID_IDS.has(maid_id): return "MAID_ID"
		var entry_error := _validate_entry(maid_block[maid_id], String(maid_id))
		if not entry_error.is_empty(): return entry_error
	return ""

static func normalize(data: Dictionary) -> Dictionary:
	if data.is_empty(): return {}
	var version: Variant = data.get("version")
	if not SectSaveContract.integer(version) or int(version) != VERSION: return {}
	var maids: Variant = data.get("maids")
	if not (maids is Dictionary): return {}
	var maid_block: Dictionary = maids
	var out_maids := {}
	for maid_id in MaidRules.MAID_IDS:
		if not maid_block.has(maid_id): continue
		var entry: Variant = maid_block[maid_id]
		if entry is Dictionary: out_maids[maid_id] = _normalize_entry(entry, String(maid_id))
	return {"version": VERSION, "maids": out_maids}

static func _validate_entry(value: Variant, maid_id: String) -> String:
	if not (value is Dictionary): return "MAID_ENTRY"
	var entry: Dictionary = value
	if entry.size() != ENTRY_KEYS.size(): return "MAID_ENTRY"
	for key in ENTRY_KEYS:
		if not entry.has(key): return "MAID_ENTRY"
	if not (entry["recruited"] is bool): return "MAID_ENTRY"
	if not SectSaveContract.integer(entry["bond"]): return "MAID_BOND"
	var chapters: Variant = entry["chapters"]
	if not (chapters is Dictionary): return "MAID_CHAPTER"
	var chapter_flags: Dictionary = chapters
	for chapter_id in chapter_flags:
		if not (chapter_id is String) or MaidRules.chapter(maid_id, String(chapter_id)).is_empty(): return "MAID_CHAPTER"
		var claimed: Variant = chapter_flags[chapter_id]
		if not (claimed is bool) or not bool(claimed): return "MAID_CHAPTER"
	var duty_error := _validate_duty(entry["duty"])
	if not duty_error.is_empty(): return duty_error
	if not SectSaveContract.integer(entry["duty_actions"]): return "MAID_ENTRY"
	if not (entry["reunion_pending"] is bool): return "MAID_ENTRY"
	if not (entry["first_duty_done"] is bool): return "MAID_ENTRY"
	return ""

static func _validate_duty(value: Variant) -> String:
	if not (value is Dictionary): return "MAID_DUTY"
	var duty: Dictionary = value
	if duty.is_empty(): return ""
	if not (duty.get("kind") is String): return "MAID_DUTY"
	var kind: String = String(duty["kind"])
	var expected: Array = STEWARD_KEYS if kind == "steward_stock" else OVERSEE_KEYS if kind == "oversee_build" else RESTOCK_KEYS if kind == "restock_pills" else []
	if expected.is_empty(): return "MAID_DUTY"
	if duty.size() != expected.size(): return "MAID_DUTY"
	for key in expected:
		if not duty.has(key): return "MAID_DUTY"
	if not (duty["paused"] is bool): return "MAID_DUTY"
	if not SectSaveContract.integer(duty["cooldown"], COOLDOWN_CAP): return "MAID_DUTY"
	if not SectSaveContract.text(duty["status"], STATUS_CAP) or String(duty["status"]).is_empty(): return "MAID_DUTY"
	if kind == "oversee_build":
		if not (duty["building_id"] is String) or String(duty["building_id"]).is_empty(): return "MAID_DUTY"
		return ""
	var id_key: String = "recipe_id" if kind == "steward_stock" else "pill_id"
	if not (duty[id_key] is String) or String(duty[id_key]).is_empty(): return "MAID_DUTY"
	if not SectSaveContract.integer(duty["target"]) or int(duty["target"]) < 1: return "MAID_DUTY"
	return _validate_reserve(duty["reserve"])

static func _validate_reserve(value: Variant) -> String:
	if not (value is Dictionary): return "MAID_DUTY"
	var reserve: Dictionary = value
	for key in reserve:
		if not (key is String): return "MAID_DUTY"
		var item: Variant = reserve[key]
		if item is String:
			var text := String(item).strip_edges()
			if text.is_empty(): return "MAID_DUTY"
			var parsed := float(text) if text.is_valid_float() else NAN
			if not is_finite(parsed) or parsed < 0.0: return "MAID_DUTY"
		elif item is int:
			if int(item) < 0: return "MAID_DUTY"
		elif item is float:
			if not is_finite(float(item)) or float(item) < 0.0: return "MAID_DUTY"
		else: return "MAID_DUTY"
	return ""

static func _normalize_entry(value: Variant, maid_id: String) -> Dictionary:
	var entry: Dictionary = value
	var chapters_out := {}
	var chapters_in: Variant = entry.get("chapters")
	if chapters_in is Dictionary:
		var chapter_source: Dictionary = chapters_in
		for definition in MaidRules.chapters(maid_id):
			var chapter_id: String = String(definition.get("id", ""))
			if chapter_source.get(chapter_id, false) == true: chapters_out[chapter_id] = true
	var recruited: Variant = entry.get("recruited", false)
	var bond: Variant = entry.get("bond", 0)
	var actions: Variant = entry.get("duty_actions", 0)
	var reunion: Variant = entry.get("reunion_pending", false)
	var first: Variant = entry.get("first_duty_done", false)
	var result := {}
	result["recruited"] = recruited is bool and bool(recruited)
	result["bond"] = int(bond) if SectSaveContract.integer(bond) else 0
	result["chapters"] = chapters_out
	result["duty"] = _normalize_duty(entry.get("duty", {}))
	result["duty_actions"] = int(actions) if SectSaveContract.integer(actions) else 0
	result["reunion_pending"] = reunion is bool and bool(reunion)
	result["first_duty_done"] = first is bool and bool(first)
	return result

static func _normalize_duty(value: Variant) -> Dictionary:
	if not (value is Dictionary): return {}
	var duty: Dictionary = value
	if duty.is_empty() or not (duty.get("kind") is String): return {}
	var kind: String = String(duty["kind"])
	var result := {}
	if kind == "steward_stock":
		result["kind"] = kind
		result["paused"] = bool(duty.get("paused", false))
		result["cooldown"] = int(duty.get("cooldown", 0))
		result["status"] = String(duty.get("status", ""))
		result["recipe_id"] = String(duty.get("recipe_id", ""))
		result["target"] = int(duty.get("target", 1))
		result["reserve"] = _normalize_reserve(duty.get("reserve", {}))
		return result
	if kind == "oversee_build":
		result["kind"] = kind
		result["paused"] = bool(duty.get("paused", false))
		result["cooldown"] = int(duty.get("cooldown", 0))
		result["status"] = String(duty.get("status", ""))
		result["building_id"] = String(duty.get("building_id", ""))
		return result
	if kind == "restock_pills":
		result["kind"] = kind
		result["paused"] = bool(duty.get("paused", false))
		result["cooldown"] = int(duty.get("cooldown", 0))
		result["status"] = String(duty.get("status", ""))
		result["pill_id"] = String(duty.get("pill_id", ""))
		result["target"] = int(duty.get("target", 1))
		result["reserve"] = _normalize_reserve(duty.get("reserve", {}))
		return result
	return {}

static func _normalize_reserve(value: Variant) -> Dictionary:
	var result := {}
	if not (value is Dictionary): return result
	var reserve: Dictionary = value
	for key in reserve:
		if not (key is String): continue
		var item: Variant = reserve[key]
		if item is String:
			result[key] = String(item)
		elif item is int:
			result[key] = int(item)
		elif item is float:
			var number: float = float(item)
			result[key] = int(number) if is_finite(number) and number == floorf(number) else number
	return result
