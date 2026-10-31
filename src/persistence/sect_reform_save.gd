class_name SectReformSave
extends RefCounted
## Atomic CORE/release contract: source archive, frozen candidate, exact readback.
const VERSION := 1
const ARCHIVE_PREFIX := "save_before_sect_reform_"
const COMMANDS := ["redeem_guardian_permit", "join_sect", "resolve_legacy_sect_identity", "refresh_sect_tasks", "start_sect_expedition", "claim_sect_expedition", "learn_sect_technique", "buy_sect_market_item", "learn_talent", "claim_achievement", "reincarnate", "acquire_beast", "feed_beast", "unlock_beast_talent"]

static func receipt_value(value: Variant) -> Variant:
	if value is AmountCompat: return value.serialize()
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = receipt_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(receipt_value(item))
		return result
	return value

static func active(state: GameState) -> bool:
	return state != null and state.sect.has("core_save")

static func prepare(source: GameState, raw: String, save_id: String) -> GameState:
	var candidate := source.duplicate_state()
	SectSystem.ensure_sect_state(candidate)
	var identity := SectIdentity.view(candidate.sect)
	if not identity.sect_id.is_empty():
		SectIdentity.write(candidate.sect, identity.sect_id)
	elif not identity.unlocked:
		candidate.sect.identity_version = SectIdentity.VERSION
		candidate.sect.sect_id = ""
	else:
		# Unknown legacy membership stays unresolved; no invented affiliation.
		candidate.sect.sect_id = ""
	candidate.sect.techniques_version = 1
	SectLineage.ensure(candidate)
	candidate.sect.core_save = {"version": VERSION, "source_hash": raw.sha256_text(), "save_id": save_id}
	candidate.sect.rng = {"version": 1, "state": SeededRandom.from_seed(save_id + ":" + raw.sha256_text() + ":sect-reform-1").state}
	candidate.revision += 1
	return candidate

static func validate(sect: Dictionary) -> String:
	if not sect.has("core_save"):
		return "SECT_CORE_RNG_WITHOUT_MARKER" if sect.has("rng") else ""
	var marker: Variant = sect.core_save
	if not (marker is Dictionary) or marker.size() != 3: return "SECT_CORE_MARKER"
	if not SectSaveContract.integer(marker.get("version"), VERSION) or marker.version != VERSION: return "SECT_CORE_VERSION"
	var hash_value: Variant = marker.get("source_hash")
	if not (hash_value is String) or hash_value.length() != 64: return "SECT_CORE_HASH"
	for c in hash_value:
		if not c in "0123456789abcdef": return "SECT_CORE_HASH"
	if not SectSaveContract.text(marker.get("save_id"), 256) or marker.save_id.is_empty(): return "SECT_CORE_SAVE_ID"
	if sect.get("techniques_version") != 1 or not sect.has("lineage"): return "SECT_CORE_FEATURES"
	var rng: Variant = sect.get("rng")
	if not (rng is Dictionary) or rng.size() != 2: return "SECT_CORE_RNG"
	if not SectSaveContract.integer(rng.get("version"), 1) or rng.version != 1 or not SectSaveContract.integer(rng.get("state"), 4294967295): return "SECT_CORE_RNG"
	return ""

static func archive(adapter: StorageAdapter, raw: String) -> Dictionary:
	var key := ARCHIVE_PREFIX + raw.sha256_text()
	var original := adapter.read(key)
	if original.ok and original.data != raw:
		var damaged_key := key + "_damaged_" + String(original.data).sha256_text()
		var rescued := _write_verified(adapter, damaged_key, original.data)
		if not rescued.ok: return {"ok": false, "error": "SECT_CORE_ARCHIVE_RESCUE"}
	elif not original.ok and original.get("error") != "missing":
		return {"ok": false, "error": "SECT_CORE_ARCHIVE_READ"}
	if not original.ok or original.data != raw:
		var written := _write_verified(adapter, key, raw)
		if not written.ok: return {"ok": false, "error": "SECT_CORE_ARCHIVE_READBACK"}
	return {"ok": true, "archive_key": key}

static func _write_verified(adapter: StorageAdapter, key: String, raw: String) -> Dictionary:
	var written := adapter.write(key, raw)
	# A backend can durably write and then lose its response. Exact readback is
	# the authority, including the frozen command receipt and all costs/rewards.
	var readback := adapter.read(key)
	return {"ok": readback.ok and readback.data == raw, "write_ok": written.ok}
