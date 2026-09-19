extends SceneTree

const CONTENT_DIR := "res://content"

var failures: Array[String] = []
var _content: GameContent = null
var _slots: SaveSlots = null
var _storage_adapter: StorageAdapter = null

func _init() -> void:
    _storage_adapter = FileStorageAdapter.new("user://m1c_test_slots")
    _slots = SaveSlots.new(_storage_adapter)
    _slots.reset()
    _load_content()
    _test_codec_round_trip()
    _test_envelope_fields()
    _test_checksum()
    _test_slots_rotation()
    _test_corruption_recovery()
    _test_no_double_overwrite()
    _test_import_failure_preserves_progress()
    _test_export_import_round_trip()
    _test_revision_selection()
    _test_validator_rejection()
    _test_no_system_clock()
    _slots.reset()
    if failures.is_empty():
        print("PASS: M1-C save codec, two-slot persistence, checksum, export/import.")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _load_content() -> void:
    var loaded := ContentLoader.load_directory(CONTENT_DIR)
    if bool(loaded.ok):
        _content = loaded.content
    else:
        failures.append("content load from %s failed: %s" % [CONTENT_DIR, str(loaded.get("errors", []))])

func _expect(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
    if actual != expected:
        failures.append("%s; expected=%s actual=%s" % [label, str(expected), str(actual)])

func _test_codec_round_trip() -> void:
    if _content == null:
        _expect(false, "codec round trip: content not loaded")
        return
    var session := GameSession.create_new_game(_content)
    var state := session.state
    var meta := {"save_id": "test_roundtrip", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
    var encode_result := SaveCodec.encode(state, "0.1.0", meta)
    _expect(encode_result.ok, "encode succeeded")
    if not encode_result.ok:
        return
    var decode_result := SaveCodec.decode(encode_result.json)
    _expect(decode_result.ok, "decode succeeded")
    if not decode_result.ok:
        return
    _expect_equal(decode_result.state.revision, state.revision, "round trip preserves revision")
    _expect_equal(SaveCodec.revision_of(decode_result.envelope), state.revision, "envelope revision matches state revision")
    var original_snap := state.to_snapshot_dict()
    var decoded_snap: Dictionary = decode_result.state.to_snapshot_dict()
    _expect_equal(original_snap, decoded_snap, "state snapshot round-trip equal including revision")

func _test_envelope_fields() -> void:
    if _content == null:
        _expect(false, "envelope fields: content not loaded")
        return
    var session := GameSession.create_new_game(_content)
    var state := session.state
    var meta := {"save_id": "envelope_test", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
    var encode_result := SaveCodec.encode(state, "0.1.0", meta)
    _expect(encode_result.ok, "encode succeeded for envelope check")
    if not encode_result.ok:
        return
    var envelope: String = String(encode_result.json)
    var env_dict := JSON.parse_string(envelope) as Dictionary
    _expect(env_dict.has("schema_version"), "envelope has schema_version")
    _expect(env_dict.has("game_version"), "envelope has game_version")
    _expect(env_dict.has("rules_version"), "envelope has rules_version")
    _expect(env_dict.has("amount_format_version"), "envelope has amount_format_version")
    _expect(env_dict.has("generator_version"), "envelope has generator_version")
    _expect(env_dict.has("save_id"), "envelope has save_id")
    _expect(env_dict.has("revision"), "envelope has revision")
    _expect(env_dict.has("saved_at_utc_ms"), "envelope has saved_at_utc_ms")
    _expect(env_dict.has("settled_until_utc_ms"), "envelope has settled_until_utc_ms")
    _expect(env_dict.has("sim_tick"), "envelope has sim_tick")
    _expect(env_dict.has("rng_streams"), "envelope has rng_streams")
    _expect(env_dict["saved_at_utc_ms"] is String, "saved_at_utc_ms is string type")
    _expect(env_dict["settled_until_utc_ms"] is String, "settled_until_utc_ms is string type")
    _expect(env_dict["sim_tick"] is String, "sim_tick is string type")

func _test_checksum() -> void:
    if _content == null:
        _expect(false, "checksum: content not loaded")
        return
    var session := GameSession.create_new_game(_content)
    var state := session.state
    var meta := {"save_id": "checksum_test", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
    var encode_result := SaveCodec.encode(state, "0.1.0", meta)
    _expect(encode_result.ok, "encode succeeded for checksum check")
    if not encode_result.ok:
        return
    var envelope: String = String(encode_result.json)
    var env_dict := JSON.parse_string(envelope) as Dictionary
    _expect(SaveCodec.verify_checksum(env_dict), "verify_checksum returns true for valid envelope")
    env_dict["saved_at_utc_ms"] = "9999999999"
    _expect(not SaveCodec.verify_checksum(env_dict), "verify_checksum returns false after modification")
    var modified_json := JSON.stringify(env_dict, "", true)
    var decode_result := SaveCodec.decode(modified_json)
    _expect(not decode_result.ok, "decode returns ok:false when checksum invalid")

func _test_slots_rotation() -> void:
    # First commit
    var json1 := "{\"revision\":0,\"era_id\":1,\"level\":1,\"resources\":{},\"buildings\":{}}"
    var commit1 := _slots.commit(json1, 0)
    _expect(commit1.ok, "first commit succeeded")
    _expect(commit1.active_slot == "save_main", "first commit active slot is save_main")
    _expect(commit1.commit_sequence == 1, "first commit sequence is 1")
    # Second commit
    var json2 := "{\"revision\":1,\"era_id\":1,\"level\":1,\"resources\":{},\"buildings\":{}}"
    var commit2 := _slots.commit(json2, 1)
    _expect(commit2.ok, "second commit succeeded")
    _expect(commit2.active_slot == "save_backup", "second commit active slot is save_backup")
    _expect(commit2.commit_sequence == 2, "second commit sequence is 2")
    var read_main: Dictionary = _storage_adapter.read(SaveSlots.SLOT_MAIN)
    _expect(bool(read_main.get("ok", false)), "save_main is readable after rotation")
    if bool(read_main.get("ok", false)):
        _expect_equal(String(read_main["data"]), json1, "save_main still holds the first payload")
    var read_backup: Dictionary = _storage_adapter.read(SaveSlots.SLOT_BACKUP)
    _expect(bool(read_backup.get("ok", false)), "save_backup is readable after rotation")
    if bool(read_backup.get("ok", false)):
        _expect_equal(String(read_backup["data"]), json2, "save_backup holds the second payload")
    var read1 := _slots.read_best()
    _expect(read1.ok, "read_best succeeds after rotation")
    if read1.ok:
        _expect_equal(read1.revision, 1, "read_best returns the latest revision after rotation")

func _test_corruption_recovery() -> void:
    var json_valid := "{\"revision\":5,\"era_id\":1,\"level\":1,\"resources\":{},\"buildings\":{}}"
    var commit1 := _slots.commit(json_valid, 5)
    _expect(commit1.ok, "initial commit succeeded")
    var active: String = _slots.active_slot()
    _expect(active != "", "active slot is set before corruption")
    var other: String = SaveSlots.SLOT_BACKUP
    if active == SaveSlots.SLOT_BACKUP:
        other = SaveSlots.SLOT_MAIN
    var other_read: Dictionary = _storage_adapter.read(other)
    _expect(bool(other_read.get("ok", false)), "the surviving slot is readable before corruption")
    var other_revision: int = -1
    if bool(other_read.get("ok", false)):
        var parsed_other: Variant = JSON.parse_string(String(other_read["data"]))
        if parsed_other is Dictionary:
            other_revision = int(parsed_other.get("revision", -1))
    var corrupt: Dictionary = _storage_adapter.write(active, "CORRUPTED_SLOT_CONTENT")
    _expect(bool(corrupt.get("ok", false)), "corrupting the active slot on storage succeeded")
    var read_best := _slots.read_best()
    _expect(read_best.ok, "read_best succeeds after active slot corruption")
    if read_best.ok:
        _expect(read_best.slot != active, "read_best falls back to the other slot")
        _expect_equal(read_best.revision, other_revision, "read_best returns the surviving slot revision")

func _test_no_double_overwrite() -> void:
    # Commit valid data to main slot
    var json_valid := "{\"revision\":3,\"era_id\":1,\"level\":1,\"resources\":{},\"buildings\":{}}"
    var commit1 := _slots.commit(json_valid, 3)
    _expect(commit1.ok, "valid commit to main succeeded")
    # Write invalid content to backup slot (non-active)
    var json_invalid := "CORRUPTED_DATA_NOT_VALID_JSON"
    var commit2 := _slots.commit(json_invalid, 0)
    _expect(commit2.ok, "raw string commit to the non-active slot is written")
    var read_best := _slots.read_best()
    _expect(read_best.ok, "read_best succeeds after double overwrite attempt")
    if read_best.ok:
        _expect_equal(read_best.revision, 3, "read_best ignores the corrupt slot and returns revision 3")
        _expect(not String(read_best.json).contains("CORRUPTED"), "read_best never returns the corrupt payload")

func _test_import_failure_preserves_progress() -> void:
    var before_state: Variant = SaveManager.load_state()
    _expect(before_state != null, "load_state returns a state before import")
    if before_state == null:
        return
    var before_snap: Dictionary = before_state.to_snapshot_dict()
    var import_result := SaveManager.import_share_string("INVALID_SHARE_CODE_12345")
    _expect(not import_result.ok, "import with invalid share code returns ok:false")
    var after_state: Variant = SaveManager.load_state()
    _expect(after_state != null, "load_state returns a state after import")
    if after_state == null:
        return
    _expect_equal(after_state.to_snapshot_dict(), before_snap, "import failure preserves progress snapshot")

func _test_export_import_round_trip() -> void:
    var before_state: Variant = SaveManager.load_state()
    _expect(before_state != null, "load_state returns a state before export")
    if before_state == null:
        return
    var before_snap: Dictionary = before_state.to_snapshot_dict()
    var export_result := SaveManager.export_share_string()
    _expect(String(export_result) != "", "export_share_string returns non-empty string")
    if String(export_result) == "":
        return
    var import_result := SaveManager.import_share_string(export_result)
    _expect(import_result.ok, "import with exported share code succeeds")
    if import_result.ok:
        var imported_state: Variant = import_result.get("state", null)
        _expect(imported_state != null, "import returns a decoded state")
        if imported_state != null:
            _expect_equal(imported_state.to_snapshot_dict(), before_snap, "export/import round trip preserves snapshot")
    var after_state: Variant = SaveManager.load_state()
    _expect(after_state != null, "load_state returns a state after import")
    if after_state != null:
        _expect_equal(after_state.to_snapshot_dict(), before_snap, "import does not overwrite current progress")

func _test_revision_selection() -> void:
    # Commit revision 1 to main slot
    var json1 := "{\"revision\":1,\"era_id\":1,\"level\":1,\"resources\":{},\"buildings\":{}}"
    _slots.commit(json1, 1)
    # Commit revision 2 to backup slot
    var json2 := "{\"revision\":2,\"era_id\":1,\"level\":1,\"resources\":{},\"buildings\":{}}"
    _slots.commit(json2, 2)
    # read_best should select revision 2 (larger)
    var read_best := _slots.read_best()
    _expect(read_best.ok, "read_best succeeds")
    if read_best.ok:
        _expect(read_best.revision == 2, "read_best selects higher revision")

func _test_validator_rejection() -> void:
    # Validator that always returns -1 (invalid)
    var always_invalid: Callable = func(json: String) -> int: return -1
    var read_best := _slots.read_best(always_invalid)
    _expect(not read_best.ok, "read_best returns ok:false with invalid validator")

func _test_no_system_clock() -> void:
    _scan_dir_for_clock("res://src/persistence")

func _scan_dir_for_clock(path: String) -> void:
    var access: DirAccess = DirAccess.open(path)
    if access == null:
        return
    var files: PackedStringArray = access.get_files()
    for file in files:
        if file.ends_with(".uid"):
            continue
        var file_path: String = path.path_join(file)
        var content: String = FileAccess.get_file_as_string(file_path)
        if content.contains("Time.") or content.contains("OS.get_"):
            failures.append("File %s contains Time. or OS. token" % file_path)
    var subdirs: PackedStringArray = access.get_directories()
    for subdir in subdirs:
        _scan_dir_for_clock(path.path_join(subdir))