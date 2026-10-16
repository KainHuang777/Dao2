extends SceneTree

# Test-only restore tool (user-approved Option A, 2026-10-16).
# Reconstructs the schema-4 envelope for the state snapshot captured in
# 63-resume-era2-level10.json and emits the exact localStorage payloads the
# game can decode, using SaveCodec itself for checksum + decode preflight.

const EVIDENCE_PATH := "res://docs/verification/artifacts/d2-natural-20261016/63-resume-era2-level10.json"
const OUT_DIR := "res://docs/verification/artifacts/d2-natural-20261016/restore"

func _initialize() -> void:
	var failures: Array[String] = []
	var evidence_text := FileAccess.get_file_as_string(EVIDENCE_PATH)
	if evidence_text.is_empty():
		failures.append("EVIDENCE_EMPTY")
		_finish(failures, {})
		return
	var evidence: Variant = JSON.parse_string(evidence_text)
	if not (evidence is Dictionary):
		failures.append("EVIDENCE_PARSE")
		_finish(failures, {})
		return
	var ev: Dictionary = evidence
	if not (ev.get("after") is Dictionary) or not (ev["after"].get("state") is Dictionary):
		failures.append("EVIDENCE_STATE_MISSING")
		_finish(failures, {})
		return
	var after: Dictionary = ev["after"]
	var snapshot: Dictionary = after["state"]
	var snapshot_revision := _as_int(snapshot.get("revision", -1))
	if snapshot_revision < 1:
		failures.append("SNAPSHOT_REVISION_INVALID")
		_finish(failures, snapshot)
		return
	if after.has("revision") and _as_int(after["revision"]) != snapshot_revision:
		failures.append("AFTER_REVISION_MISMATCH")

	var loaded: Dictionary = ContentLoader.load_directory("res://content")
	if not bool(loaded.get("ok", false)):
		failures.append("CONTENT_LOAD_FAILED")
		_finish(failures, snapshot)
		return
	var content: GameContent = loaded["content"]
	var attached: Dictionary = IslandProgression.attach(content)
	if not bool(attached.get("ok", false)):
		failures.append("ISLAND_ATTACH_FAILED:" + String(attached.get("error", "")))
		_finish(failures, snapshot)
		return
	var content_version := String(content.content_version)
	if content_version.is_empty():
		failures.append("CONTENT_VERSION_EMPTY")

	var now_s := int(Time.get_unix_time_from_system())
	var stamp := str(now_s)
	var meta := {
		"save_id": "restore-63-" + stamp,
		"saved_at_utc_ms": str(now_s * 1000),
		"settled_until_utc_ms": str(now_s * 1000),
		"sim_tick": str(now_s * 1000),
	}
	var envelope: Dictionary = {
		"schema_version": SaveCodec.SCHEMA_VERSION,
		"game_version": SaveCodec.GAME_VERSION,
		"content_version": content_version,
		"rules_version": SaveCodec.RULES_VERSION,
		"amount_format_version": SaveCodec.AMOUNT_FORMAT_VERSION,
		"generator_version": SaveCodec.GENERATOR_VERSION,
		"save_id": meta["save_id"],
		"revision": snapshot_revision,
		"saved_at_utc_ms": meta["saved_at_utc_ms"],
		"settled_until_utc_ms": meta["settled_until_utc_ms"],
		"sim_tick": meta["sim_tick"],
		"state": snapshot,
		"rng_streams": {},
		"last_offline_report": null,
	}
	var json_text := JSON.stringify(envelope, "", true)
	var reparsed: Variant = JSON.parse_string(json_text)
	if not (reparsed is Dictionary):
		failures.append("ROUNDTRIP_PARSE")
		_finish(failures, snapshot)
		return
	var checksum := SaveCodec.compute_checksum(reparsed)
	var final_json := json_text.left(json_text.length() - 1) + ',"checksum":"' + checksum + '"}'

	var decoded: Dictionary = SaveCodec.decode(final_json)
	var decode_ok := bool(decoded.get("ok", false))
	if not decode_ok:
		failures.append("DECODE_PREFLIGHT:" + String(decoded.get("error", "")))
	var decoded_revision := -1
	var summary := {}
	if decode_ok:
		var state_obj: GameState = decoded["state"]
		decoded_revision = int(state_obj.revision)
		if decoded_revision != snapshot_revision:
			failures.append("DECODE_REVISION_MISMATCH")
		summary = {
			"era_id": int(state_obj.era_id),
			"level": int(state_obj.level),
			"total_elapsed_seconds": float(state_obj.total_elapsed_seconds),
			"training_seconds": float(state_obj.training_seconds),
			"skill_version": int(state_obj.skill_version),
			"skills": state_obj.skills.duplicate(),
			"economy_version": String(state_obj.economy.get("version", "")),
			"reincarnation_count": int(state_obj.reincarnation_count),
			"dao_proof": int(state_obj.dao_proof),
			"resource_count": state_obj.resources.size(),
			"building_count": state_obj.buildings.size(),
			"tribulation_seed": int(state_obj.tribulation_seed),
		}
		for rid in ["ling_shi", "liquid", "spirit_timber", "bronze_essence", "ling_qi"]:
			if state_obj.resources.has(rid):
				summary[rid] = state_obj.resources[rid]["value"].serialize()

	var index_payload := {
		"commit_sequence": snapshot_revision + 1,
		"active_slot": SaveSlots.SLOT_MAIN,
		"revision": snapshot_revision,
	}
	var report := {
		"ok": failures.is_empty(),
		"failures": failures,
		"evidence_path": EVIDENCE_PATH,
		"content_version": content_version,
		"save_id": meta["save_id"],
		"saved_at_utc_ms": meta["saved_at_utc_ms"],
		"settled_until_utc_ms": meta["settled_until_utc_ms"],
		"sim_tick": meta["sim_tick"],
		"checksum": checksum,
		"decode_ok": decode_ok,
		"decoded_revision": decoded_revision,
		"state_summary": summary,
		"utc": Time.get_datetime_string_from_system(true, true),
	}
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var envelope_file := FileAccess.open(OUT_DIR + "/restore_envelope.json", FileAccess.WRITE)
	envelope_file.store_string(final_json)
	envelope_file.close()
	var index_file := FileAccess.open(OUT_DIR + "/restore_index.json", FileAccess.WRITE)
	index_file.store_string(JSON.stringify(index_payload))
	index_file.close()
	var report_file := FileAccess.open(OUT_DIR + "/restore_report.json", FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report, "", 2))
	report_file.close()
	print(JSON.stringify(report, "", 2))
	_finish(failures, snapshot)

func _finish(failures: Array[String], snapshot: Dictionary) -> void:
	if failures.is_empty():
		print("RESTORE_BUILD_OK snapshot_revision=" + str(_as_int(snapshot.get("revision", -1))))
		quit(0)
	else:
		print("RESTORE_BUILD_FAILED " + ",".join(failures))
		quit(1)

func _as_int(value: Variant) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	return -1
