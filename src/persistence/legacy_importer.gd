class_name LegacyImporter
extends RefCounted

const SUPPORTED_VERSION := "1.0"
const BACKFILL_POLICY := "none"

const _BASE64_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
const _KNOWN_TOP_KEYS := [
	"v", "o", "t", "p", "r", "b", "s", "beastData",
	"version", "onboardingVersion", "timestamp", "player", "resources", "buildings", "sect", "beast",
]

static func decode_input(input_text: String) -> Dictionary:
	var text := _strip_whitespace(input_text)
	if text.is_empty():
		return {"ok": false, "error": "EMPTY", "raw_json": ""}
	if text.begins_with("{"):
		return {"ok": true, "error": "", "raw_json": text}
	if is_base64(text):
		var decoded := Marshalls.base64_to_utf8(text)
		if decoded.is_empty():
			return {"ok": false, "error": "BASE64_DECODE", "raw_json": ""}
		var decoded_text := _strip_whitespace(decoded)
		if decoded_text.is_empty():
			return {"ok": false, "error": "BASE64_DECODE", "raw_json": ""}
		return {"ok": true, "error": "", "raw_json": decoded_text}
	return {"ok": false, "error": "NOT_JSON_OR_BASE64", "raw_json": ""}

static func is_base64(text: String) -> bool:
	if text.is_empty():
		return false
	for index in range(text.length()):
		var character := text[index]
		if not _BASE64_CHARS.contains(character):
			return false
	return true

static func deserialize_amount(raw: Variant) -> Dictionary:
	if raw is String:
		var parse_result: Dictionary = AmountCompat.try_parse(String(raw))
		if not bool(parse_result.get("ok", false)):
			return {"ok": false, "error": "INVALID_AMOUNT:" + String(parse_result.get("error", "PARSE")), "value": null, "layer": 0, "form": "string"}
		var parsed_value: AmountCompat = parse_result["value"]
		return {"ok": true, "error": "", "value": parsed_value, "layer": int(parsed_value.layer), "form": "string"}
	if raw is int or raw is float:
		var number := float(raw)
		if is_nan(number) or is_inf(number):
			return {"ok": false, "error": "INVALID_AMOUNT:NON_FINITE", "value": null, "layer": 0, "form": "number"}
		return {"ok": true, "error": "", "value": AmountCompat.from_number(number), "layer": 0, "form": "number"}
	if raw is Dictionary:
		var raw_dict: Dictionary = raw
		if raw_dict.has("sign") and raw_dict.has("mag") and raw_dict.has("layer"):
			var value_sign := int(raw_dict["sign"])
			var value_layer := int(raw_dict["layer"])
			var value_mag := float(raw_dict["mag"])
			if is_nan(value_mag) or is_inf(value_mag):
				return {"ok": false, "error": "INVALID_AMOUNT:NON_FINITE", "value": null, "layer": 0, "form": "components"}
			var value: AmountCompat = AmountCompat.from_components(value_sign, value_layer, value_mag)
			return {"ok": true, "error": "", "value": value, "layer": int(value.layer), "form": "components"}
		return {"ok": false, "error": "INVALID_AMOUNT:SHAPE", "value": null, "layer": 0, "form": "unknown"}
	return {"ok": false, "error": "INVALID_AMOUNT", "value": null, "layer": 0, "form": "unknown"}

static func build_report(data: Dictionary, content: GameContent) -> Dictionary:
	var compact := data.has("v") or data.has("p") or data.has("r")
	var format_version := String(data.get("v", data.get("version", "")))
	var timestamp := int(data.get("t", data.get("timestamp", 0)))
	var has_version := data.has("v") or data.has("version")
	var player_result := _player_of(data)
	var resources_result := _resources_of(data)
	var buildings_result := _buildings_of(data)
	var has_sect := data.has("s") or data.has("sect")
	var has_beast := data.has("beastData") or data.has("beast")
	var mapped_fields: Array = []
	var ignored_fields: Array = []
	for key in data.keys():
		var key_string := String(key)
		if _KNOWN_TOP_KEYS.has(key_string):
			mapped_fields.append(key_string)
		else:
			ignored_fields.append(key_string)
	mapped_fields.sort()
	ignored_fields.sort()
	var known_resources := {}
	for resource_id in content.resource_ids:
		known_resources[String(resource_id)] = true
	var known_buildings := {}
	for building_id in content.building_ids:
		known_buildings[String(building_id)] = true
	var unknown_resource_ids: Array = []
	var unknown_building_ids: Array = []
	var amount_issues: Array = []
	var high_layer_amounts: Array = []
	var resource_entries := _legacy_resource_map(data)
	for raw_resource_id in resource_entries.keys():
		var resource_id := String(raw_resource_id)
		if not known_resources.has(resource_id):
			unknown_resource_ids.append(resource_id)
			continue
		var entry_variant: Variant = resource_entries[raw_resource_id]
		var amount_raw: Variant = entry_variant
		if entry_variant is Dictionary:
			var entry_dict: Dictionary = entry_variant
			amount_raw = entry_dict.get("v", entry_dict.get("value", "0"))
		var amount_result := deserialize_amount(amount_raw)
		if not bool(amount_result["ok"]):
			amount_issues.append(resource_id + ":" + String(amount_result["error"]))
		elif int(amount_result["layer"]) >= 2:
			high_layer_amounts.append(resource_id + ":layer=" + str(int(amount_result["layer"])))
	var building_entries := _legacy_building_map(data)
	for raw_building_id in building_entries.keys():
		var building_id := String(raw_building_id)
		if not known_buildings.has(building_id):
			unknown_building_ids.append(building_id)
			continue
		var level := _building_level_of(building_entries[raw_building_id], building_id)
		if level < 0:
			amount_issues.append(building_id + ":BUILDING_LEVEL_NEGATIVE")
	unknown_resource_ids.sort()
	unknown_building_ids.sort()
	amount_issues.sort()
	high_layer_amounts.sort()
	var missing_fields: Array = []
	for expected in ["version", "player", "resources", "buildings"]:
		if not mapped_fields.has(_compact_or_long(expected, compact)):
			missing_fields.append(expected)
	var warnings: Array = []
	if not player_result.ok:
		warnings.append("PLAYER_MISSING")
	if not has_beast:
		warnings.append("BEAST_DATA_MISSING")
	if has_sect:
		warnings.append("SECT_NOT_MAPPED")
	warnings.sort()
	return {
		"source_format": "compact" if compact else "long",
		"format_version": format_version,
		"source_timestamp_ms": timestamp,
		"has_version": has_version,
		"has_player": player_result.ok,
		"has_resources": resources_result.ok,
		"has_buildings": buildings_result.ok,
		"has_sect": has_sect,
		"has_beast": has_beast,
		"mapped_fields": mapped_fields,
		"ignored_fields": ignored_fields,
		"unknown_resource_ids": unknown_resource_ids,
		"unknown_building_ids": unknown_building_ids,
		"missing_fields": missing_fields,
		"amount_issues": amount_issues,
		"high_layer_amounts": high_layer_amounts,
		"warnings": warnings,
		"backfill_policy": BACKFILL_POLICY,
	}

static func map_state(data: Dictionary, content: GameContent, report: Dictionary) -> GameState:
	var state := GameState.new()
	var player: Dictionary = {}
	var player_raw: Variant = data.get("p", data.get("player", null))
	if player_raw is Dictionary:
		player = player_raw
	state.era_id = maxi(1, int(player.get("eraId", 1)))
	state.level = maxi(1, int(player.get("level", 1)))
	state.onboarding_version = int(data.get("o", data.get("onboardingVersion", 0)))
	state.training_seconds = 0.0
	state.total_elapsed_seconds = 0.0
	state.revision = 0
	state.resources = {}
	state.buildings = {}
	var known_resources := {}
	for resource_id in content.resource_ids:
		var resource_key := String(resource_id)
		known_resources[resource_key] = true
		state.resources[resource_key] = {
			"value": AmountCompat.zero(),
			"unlocked": false,
			"ever_obtained": false,
		}
	var legacy_resources := _legacy_resource_map(data)
	for raw_resource_id in legacy_resources.keys():
		var resource_key := String(raw_resource_id)
		if not known_resources.has(resource_key):
			continue
		var entry: Variant = legacy_resources[raw_resource_id]
		if not (entry is Dictionary):
			continue
		var legacy_entry: Dictionary = entry
		var amount_result := deserialize_amount(legacy_entry.get("v", legacy_entry.get("value", "0")))
		var new_entry: Dictionary = state.resources[resource_key]
		if bool(amount_result["ok"]):
			new_entry["value"] = amount_result["value"]
		new_entry["unlocked"] = bool(_truthy(legacy_entry.get("u", legacy_entry.get("unlocked", false))))
		new_entry["ever_obtained"] = bool(_truthy(legacy_entry.get("e", legacy_entry.get("everObtained", false))))
	var known_buildings := {}
	for building_id in content.building_ids:
		var building_key := String(building_id)
		known_buildings[building_key] = true
		state.buildings[building_key] = 0
	var legacy_buildings := _legacy_building_map(data)
	for raw_building_id in legacy_buildings.keys():
		var building_key := String(raw_building_id)
		if not known_buildings.has(building_key):
			continue
		var level := _building_level_of(legacy_buildings[raw_building_id], building_key)
		if level >= 0:
			state.buildings[building_key] = level
	return state

static func import_text(input_text: String, content: GameContent) -> Dictionary:
	var decoded := decode_input(input_text)
	if not bool(decoded["ok"]):
		return {"ok": false, "error": String(decoded["error"]), "report": {}, "state": null, "raw_json": String(decoded["raw_json"])}
	var raw_json := String(decoded["raw_json"])
	var parsed: Variant = JSON.parse_string(raw_json)
	if parsed == null:
		return {"ok": false, "error": "JSON_PARSE", "report": {}, "state": null, "raw_json": raw_json}
	if not (parsed is Dictionary):
		return {"ok": false, "error": "NOT_OBJECT", "report": {}, "state": null, "raw_json": raw_json}
	var data: Dictionary = parsed
	var report := build_report(data, content)
	var state := map_state(data, content, report)
	return {"ok": true, "error": "", "report": report, "state": state, "raw_json": raw_json}

static func _strip_whitespace(text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\s+")
	return regex.sub(text, "", true)

static func _player_of(data: Dictionary) -> Dictionary:
	var raw: Variant = data.get("p", data.get("player", null))
	if raw is Dictionary:
		return {"ok": true, "player": raw, "error": ""}
	return {"ok": false, "player": {}, "error": "PLAYER_MISSING"}

static func _resources_of(data: Dictionary) -> Dictionary:
	var raw: Variant = data.get("r", data.get("resources", null))
	if raw is Dictionary:
		return {"ok": true, "map": raw, "error": ""}
	return {"ok": false, "map": {}, "error": "RESOURCES_MISSING"}

static func _buildings_of(data: Dictionary) -> Dictionary:
	var raw: Variant = data.get("b", data.get("buildings", null))
	if raw is Dictionary:
		return {"ok": true, "map": raw, "error": ""}
	return {"ok": false, "map": {}, "error": "BUILDINGS_MISSING"}

static func _compact_or_long(expected: String, compact: bool) -> String:
	if expected == "version":
		return "v" if compact else "version"
	if expected == "player":
		return "p" if compact else "player"
	if expected == "resources":
		return "r" if compact else "resources"
	if expected == "buildings":
		return "b" if compact else "buildings"
	return expected

static func _truthy(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int:
		return int(value) != 0
	if value is float:
		return not is_equal_approx(float(value), 0.0)
	if value is String:
		return String(value) == "1" or String(value).to_lower() == "true"
	return false

static func _building_level_of(raw: Variant, fallback_id: String) -> int:
	if raw is int or raw is float:
		return int(raw)
	if raw is Dictionary:
		var entry: Dictionary = raw
		if entry.has("level"):
			return int(entry["level"])
		if entry.has("id"):
			return 0
	return -1

static func _legacy_resource_map(data: Dictionary) -> Dictionary:
	var result := _resources_of(data)
	return result["map"] if result.ok else {}

static func _legacy_building_map(data: Dictionary) -> Dictionary:
	var raw: Variant = data.get("b", data.get("buildings", null))
	if not (raw is Dictionary):
		return {}
	var container: Dictionary = raw
	if container.has("buildings") and (container["buildings"] is Dictionary):
		container = container["buildings"]
	elif container.has("b") and (container["b"] is Dictionary):
		container = container["b"]
	var result := {}
	for raw_building_id in container.keys():
		var building_key := String(raw_building_id)
		var entry: Variant = container[raw_building_id]
		if entry is int or entry is float:
			result[building_key] = entry
		elif entry is Dictionary:
			var entry_dict: Dictionary = entry
			var id_key := String(entry_dict.get("id", building_key))
			result[id_key] = entry_dict.get("level", 0)
	return result
