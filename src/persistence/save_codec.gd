class_name SaveCodec
extends RefCounted

const SCHEMA_VERSION := 2
const GAME_VERSION := "0.1.0"
const RULES_VERSION := "offline-24h-1"
const AMOUNT_FORMAT_VERSION := 1
const GENERATOR_VERSION := 1

static func encode(state: GameState, content_version: String, meta: Dictionary) -> Dictionary:
	if state == null:
		return {"ok": false, "json": "", "error": "STATE_MISSING"}
	if content_version.is_empty():
		return {"ok": false, "json": "", "error": "CONTENT_VERSION_EMPTY"}
	for key in ["save_id", "saved_at_utc_ms", "settled_until_utc_ms", "sim_tick"]:
		if not meta.has(key) or not (meta[key] is String):
			return {"ok": false, "json": "", "error": "META_FIELD_INVALID:" + key}
	var rng_streams: Variant = meta.get("rng_streams", {})
	if not (rng_streams is Dictionary):
		return {"ok": false, "json": "", "error": "META_FIELD_INVALID:rng_streams"}
	var envelope := {
		"schema_version": SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"content_version": content_version,
		"rules_version": RULES_VERSION,
		"amount_format_version": AMOUNT_FORMAT_VERSION,
		"generator_version": GENERATOR_VERSION,
		"save_id": meta["save_id"],
		"revision": int(state.revision),
		"saved_at_utc_ms": meta["saved_at_utc_ms"],
		"settled_until_utc_ms": meta["settled_until_utc_ms"],
		"sim_tick": meta["sim_tick"],
		"state": state.to_snapshot_dict(),
		"rng_streams": rng_streams,
		"last_offline_report": meta.get("last_offline_report", null),
	}
	envelope["checksum"] = compute_checksum(envelope)
	return {"ok": true, "json": JSON.stringify(envelope, "", true), "error": ""}

static func decode(json_text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null:
		return {"ok": false, "state": null, "envelope": {}, "error": "JSON_PARSE"}
	if not (parsed is Dictionary):
		return {"ok": false, "state": null, "envelope": {}, "error": "ENVELOPE_TYPE"}
	var envelope: Dictionary = parsed
	if not envelope.has("schema_version") or not _is_int(envelope["schema_version"]):
		return {"ok": false, "state": null, "envelope": envelope, "error": "SCHEMA_VERSION_TYPE"}
	if _to_int(envelope["schema_version"]) != SCHEMA_VERSION:
		return {"ok": false, "state": null, "envelope": envelope, "error": "SCHEMA_VERSION_UNKNOWN"}
	if not verify_checksum(envelope):
		return {"ok": false, "state": null, "envelope": envelope, "error": "CHECKSUM"}
	var type_error := _validate_envelope_types(envelope)
	if not type_error.is_empty():
		return {"ok": false, "state": null, "envelope": envelope, "error": type_error}
	var state_result := _state_from_snapshot(envelope["state"])
	if not bool(state_result["ok"]):
		return {"ok": false, "state": null, "envelope": envelope, "error": String(state_result["error"])}
	if _to_int(state_result["state"].revision) != _to_int(envelope["revision"]):
		return {"ok": false, "state": null, "envelope": envelope, "error": "REVISION_MISMATCH"}
	return {"ok": true, "state": state_result["state"], "envelope": envelope, "error": ""}

static func compute_checksum(envelope_without_checksum: Dictionary) -> String:
	var payload := JSON.stringify(_normalize_numbers(envelope_without_checksum), "", true)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(payload.to_utf8_buffer())
	return context.finish().hex_encode()

static func _normalize_numbers(value: Variant) -> Variant:
	if value is float:
		var number: float = value
		if is_finite(number) and is_equal_approx(number, floor(number)) and abs(number) < 9000000000000000.0:
			return int(number)
		return number
	if value is Array:
		var normalized_array: Array = []
		for item in value:
			normalized_array.append(_normalize_numbers(item))
		return normalized_array
	if value is Dictionary:
		var normalized_dict: Dictionary = {}
		for key in value.keys():
			normalized_dict[key] = _normalize_numbers(value[key])
		return normalized_dict
	return value

static func verify_checksum(envelope: Dictionary) -> bool:
	if not envelope.has("checksum") or not (envelope["checksum"] is String):
		return false
	var without_checksum: Dictionary = envelope.duplicate(true)
	without_checksum.erase("checksum")
	var expected := compute_checksum(without_checksum)
	return String(envelope["checksum"]).to_lower() == expected

static func revision_of(envelope: Dictionary) -> int:
	if not envelope.has("revision") or not _is_int(envelope["revision"]):
		return -1
	return _to_int(envelope["revision"])

static func _validate_envelope_types(envelope: Dictionary) -> String:
	for key in ["game_version", "content_version", "rules_version", "save_id"]:
		if not (envelope.get(key) is String):
			return "FIELD_TYPE:" + key
	if not _is_int(envelope.get("revision")):
		return "FIELD_TYPE:revision"
	for key in ["saved_at_utc_ms", "settled_until_utc_ms", "sim_tick"]:
		if not _is_decimal_string(envelope.get(key)):
			return "FIELD_TYPE:" + key
	if not (envelope.get("state") is Dictionary):
		return "FIELD_TYPE:state"
	if not (envelope.get("rng_streams") is Dictionary):
		return "FIELD_TYPE:rng_streams"
	if not _is_int(envelope.get("amount_format_version")) or _to_int(envelope["amount_format_version"]) != AMOUNT_FORMAT_VERSION:
		return "FIELD_TYPE:amount_format_version"
	if not _is_int(envelope.get("generator_version")):
		return "FIELD_TYPE:generator_version"
	return ""

static func _state_from_snapshot(snapshot: Variant) -> Dictionary:
	if not (snapshot is Dictionary):
		return {"ok": false, "state": null, "error": "STATE_TYPE"}
	var snapshot_dict: Dictionary = snapshot
	if not _is_int(snapshot_dict.get("revision")):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:revision"}
	if not _is_int(snapshot_dict.get("era_id")):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:era_id"}
	if not _is_int(snapshot_dict.get("level")):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:level"}
	if not _is_int(snapshot_dict.get("onboarding_version")):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:onboarding_version"}
	if not _is_number(snapshot_dict.get("training_seconds")):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:training_seconds"}
	if not _is_number(snapshot_dict.get("total_elapsed_seconds")):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:total_elapsed_seconds"}
	if not (snapshot_dict.get("resources") is Dictionary):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:resources"}
	if not (snapshot_dict.get("buildings") is Dictionary):
		return {"ok": false, "state": null, "error": "STATE_FIELD_TYPE:buildings"}
	var resources_data: Dictionary = snapshot_dict["resources"]
	var resources: Dictionary = {}
	for resource_id in resources_data:
		var entry: Variant = resources_data[resource_id]
		if not (entry is Dictionary):
			return {"ok": false, "state": null, "error": "STATE_RESOURCE_ENTRY_TYPE:" + String(resource_id)}
		var entry_dict: Dictionary = entry
		if not (entry_dict.get("value") is String):
			return {"ok": false, "state": null, "error": "STATE_RESOURCE_VALUE_TYPE:" + String(resource_id)}
		var amount_result: Dictionary = AmountCompat.try_parse(String(entry_dict["value"]))
		if not bool(amount_result.get("ok", false)):
			return {"ok": false, "state": null, "error": "STATE_RESOURCE_AMOUNT:" + String(resource_id) + ":" + String(amount_result.get("error", "PARSE"))}
		if not (entry_dict.get("unlocked") is bool) or not (entry_dict.get("ever_obtained") is bool):
			return {"ok": false, "state": null, "error": "STATE_RESOURCE_FLAG_TYPE:" + String(resource_id)}
		resources[resource_id] = {
			"value": amount_result["value"],
			"unlocked": bool(entry_dict["unlocked"]),
			"ever_obtained": bool(entry_dict["ever_obtained"]),
		}
	var buildings_data: Dictionary = snapshot_dict["buildings"]
	var buildings: Dictionary = {}
	for building_id in buildings_data:
		if not _is_int(buildings_data[building_id]):
			return {"ok": false, "state": null, "error": "STATE_BUILDING_LEVEL_TYPE:" + String(building_id)}
		buildings[building_id] = _to_int(buildings_data[building_id])
	var state := GameState.new()
	state.revision = _to_int(snapshot_dict["revision"])
	state.era_id = _to_int(snapshot_dict["era_id"])
	state.level = _to_int(snapshot_dict["level"])
	state.onboarding_version = _to_int(snapshot_dict["onboarding_version"])
	state.training_seconds = _to_float(snapshot_dict["training_seconds"])
	state.total_elapsed_seconds = _to_float(snapshot_dict["total_elapsed_seconds"])
	state.resources = resources
	state.buildings = buildings
	return {"ok": true, "state": state, "error": ""}

static func _is_int(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return not is_nan(value) and not is_inf(value) and is_equal_approx(value, floor(value))
	return false

static func _is_number(value: Variant) -> bool:
	if value is float:
		return not is_nan(value) and not is_inf(value)
	return value is int

static func _is_decimal_string(value: Variant) -> bool:
	if not (value is String):
		return false
	var text: String = value
	if text.is_empty():
		return false
	if text[0] == "-":
		text = text.substr(1)
	if text.is_empty():
		return false
	for index in range(text.length()):
		var character := text[index]
		if character < "0" or character > "9":
			return false
	return true

static func _to_int(value: Variant) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	return 0

static func _to_float(value: Variant) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	return 0.0
