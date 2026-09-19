extends SceneTree

const CONTENT_DIR := "res://content"
const SAMPLE_DIR := "res://tests/fixtures/legacy/import_samples"
const TEST_SLOTS_DIR := "user://m1e_test_slots"

var failures: Array[String] = []
var _content: GameContent = null

func _init() -> void:
    SaveManager.reset_for_tests()
    _load_content()
    _test_decode_json()
    _test_decode_base64()
    _test_decode_empty_and_invalid()
    _test_format_detection()
    _test_mapping_core()
    _test_long_key_mapping()
    _test_unknown_ids()
    _test_missing_beast()
    _test_bignum()
    _test_invalid_amount()
    _test_corrupt()
    _test_report_determinism()
    _test_import_preserves_raw()
    _test_import_new_slot()
    _test_no_system_clock()
    _test_backfill_policy()
    SaveManager.reset_for_tests()
    if failures.is_empty():
        print("PASS: M1-E legacy import decode, mapping, reports, and slot commit.")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _load_content() -> void:
    var loaded: Dictionary = ContentLoader.load_directory(CONTENT_DIR)
    if bool(loaded.get("ok", false)):
        _content = loaded["content"]
    else:
        failures.append("content load from %s failed: %s" % [CONTENT_DIR, str(loaded.get("errors", []))])

func _expect(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
    if actual != expected:
        failures.append("%s; expected=%s actual=%s" % [label, str(expected), str(actual)])

func _scan_dir_for_clock(path: String) -> void:
    var access: DirAccess = DirAccess.open(path)
    if access == null:
        failures.append("clock scan: directory %s is not readable" % path)
        return
    var files: PackedStringArray = access.get_files()
    for file in files:
        if file.ends_with(".uid"):
            continue
        var file_path: String = path.path_join(file)
        var source: String = FileAccess.get_file_as_string(file_path)
        if source.contains("Time.") or source.contains("OS.get_"):
            failures.append("File %s contains Time. or OS.get_ token" % file_path)
    var subdirs: PackedStringArray = access.get_directories()
    for subdir in subdirs:
        _scan_dir_for_clock(path.path_join(subdir))

func _read_sample(name: String) -> String:
    var sample_path: String = SAMPLE_DIR.path_join(name)
    var text: String = FileAccess.get_file_as_string(sample_path)
    if text.is_empty():
        failures.append("sample %s is missing or empty" % sample_path)
    return text

func _sample_data(name: String) -> Dictionary:
    var decoded: Dictionary = LegacyImporter.decode_input(_read_sample(name))
    if not bool(decoded.get("ok", false)):
        failures.append("sample %s failed to decode: %s" % [name, String(decoded.get("error", ""))])
        return {}
    var parsed: Variant = JSON.parse_string(String(decoded["raw_json"]))
    if not (parsed is Dictionary):
        failures.append("sample %s is not a JSON object" % name)
        return {}
    var data: Dictionary = parsed
    return data

func _amount_of(text: String) -> AmountCompat:
    var parsed: Dictionary = AmountCompat.try_parse(text)
    if not bool(parsed.get("ok", false)):
        failures.append("reference amount failed to parse: " + text)
        return AmountCompat.zero()
    var value: AmountCompat = parsed["value"]
    return value

func _resource_entry(state: GameState, resource_id: String) -> Dictionary:
    if state == null or not state.resources.has(resource_id):
        failures.append("state has no resource entry: " + resource_id)
        return {}
    var entry: Dictionary = state.resources[resource_id]
    return entry

func _amount_equals(state: GameState, resource_id: String, text: String, label: String) -> void:
    var entry: Dictionary = _resource_entry(state, resource_id)
    if entry.is_empty():
        return
    var amount: AmountCompat = entry["value"]
    _expect_equal(amount.compare_to(_amount_of(text)), 0, label)

func _test_decode_json() -> void:
    var text: String = _read_sample("compact_opening.json")
    var decoded: Dictionary = LegacyImporter.decode_input(text)
    _expect(bool(decoded.get("ok", false)), "decode json: compact_opening.json decodes as json text")
    _expect_equal(String(decoded.get("error", "?")), "", "decode json: successful decode carries no error")
    var raw_json: String = String(decoded.get("raw_json", ""))
    _expect(not raw_json.is_empty(), "decode json: raw_json is not empty")
    var parsed: Variant = JSON.parse_string(raw_json)
    _expect(parsed is Dictionary, "decode json: raw_json parses back to a Dictionary")
    if parsed is Dictionary:
        var data: Dictionary = parsed
        _expect_equal(String(data.get("v", "")), "1.0", "decode json: version key v survives")
    var direct: Dictionary = LegacyImporter.decode_input("{\"v\":\"1.0\"}")
    _expect_equal(String(direct.get("raw_json", "")), "{\"v\":\"1.0\"}", "decode json: json text returns as raw_json")

func _test_decode_base64() -> void:
    var text: String = _read_sample("compact_midgame.b64.txt")
    _expect(LegacyImporter.is_base64(text.strip_edges()), "decode base64: sample is standard base64")
    var decoded: Dictionary = LegacyImporter.decode_input(text)
    _expect(bool(decoded.get("ok", false)), "decode base64: compact_midgame.b64.txt decodes")
    var parsed: Variant = JSON.parse_string(String(decoded.get("raw_json", "")))
    _expect(parsed is Dictionary, "decode base64: decoded text is a JSON object")
    if parsed is Dictionary:
        var data: Dictionary = parsed
        var player: Dictionary = data.get("p", {})
        _expect_equal(int(player.get("eraId", 0)), 2, "decode base64: era id survives the base64 round trip")
    var encoded: String = Marshalls.utf8_to_base64("{\"v\":\"1.0\"}")
    var round_trip: Dictionary = LegacyImporter.decode_input(encoded)
    _expect(bool(round_trip.get("ok", false)), "decode base64: synthetic base64 decodes")
    _expect_equal(String(round_trip.get("raw_json", "")), "{\"v\":\"1.0\"}", "decode base64: raw_json equals the original json text")

func _test_decode_empty_and_invalid() -> void:
    var empty_decoded: Dictionary = LegacyImporter.decode_input("")
    _expect_equal(bool(empty_decoded.get("ok", true)), false, "empty input: decode ok is false")
    _expect_equal(String(empty_decoded.get("error", "")), "EMPTY", "empty input: error is EMPTY")
    var blank_decoded: Dictionary = LegacyImporter.decode_input("  \n\t ")
    _expect_equal(String(blank_decoded.get("error", "")), "EMPTY", "empty input: whitespace-only input is EMPTY")
    var junk_decoded: Dictionary = LegacyImporter.decode_input("%%% not a save %%%")
    _expect_equal(bool(junk_decoded.get("ok", true)), false, "invalid input: garbage decodes with ok false")
    _expect_equal(String(junk_decoded.get("error", "")), "NOT_JSON_OR_BASE64", "invalid input: garbage error is NOT_JSON_OR_BASE64")
    _expect(not LegacyImporter.is_base64(""), "invalid input: empty text is not base64")
    _expect(not LegacyImporter.is_base64("bad!chars"), "invalid input: punctuation is not base64")
    _expect(LegacyImporter.is_base64("aGVsbG8="), "invalid input: canonical base64 is recognized")

func _test_format_detection() -> void:
    if _content == null:
        _expect(false, "format detection: content not loaded")
        return
    var compact_data: Dictionary = _sample_data("compact_opening.json")
    var long_data: Dictionary = _sample_data("long_midgame.json")
    var mid_data: Dictionary = _sample_data("compact_midgame.b64.txt")
    if compact_data.is_empty() or long_data.is_empty() or mid_data.is_empty():
        return
    var compact_report: Dictionary = LegacyImporter.build_report(compact_data, _content)
    var long_report: Dictionary = LegacyImporter.build_report(long_data, _content)
    var mid_report: Dictionary = LegacyImporter.build_report(mid_data, _content)
    _expect_equal(String(compact_report.get("source_format", "")), "compact", "format detection: short-key save is compact")
    _expect_equal(String(long_report.get("source_format", "")), "long", "format detection: long-key save is long")
    _expect_equal(String(mid_report.get("source_format", "")), "compact", "format detection: base64 compact save is compact")
    _expect_equal(String(compact_report.get("format_version", "")), "1.0", "format detection: format_version from v")
    _expect_equal(String(long_report.get("format_version", "")), "1.0", "format detection: format_version from version")
    _expect_equal(int(compact_report.get("source_timestamp_ms", 0)), 1700000000000, "format detection: compact timestamp read from t")
    _expect_equal(int(long_report.get("source_timestamp_ms", 0)), 1700000000000, "format detection: long timestamp read from timestamp")

func _test_mapping_core() -> void:
    if _content == null:
        _expect(false, "mapping core: content not loaded")
        return
    var data: Dictionary = _sample_data("compact_opening.json")
    if data.is_empty():
        return
    var report: Dictionary = LegacyImporter.build_report(data, _content)
    _expect_equal(bool(report.get("has_version", false)), true, "mapping core: has_version is true")
    _expect_equal(bool(report.get("has_player", false)), true, "mapping core: has_player is true")
    _expect_equal(bool(report.get("has_resources", false)), true, "mapping core: has_resources is true")
    _expect_equal(bool(report.get("has_buildings", false)), true, "mapping core: has_buildings is true")
    _expect_equal(bool(report.get("has_sect", false)), false, "mapping core: opening save reports no sect")
    _expect_equal(bool(report.get("has_beast", false)), false, "mapping core: opening save reports no beast")
    var unknowns: Array = report.get("unknown_resource_ids", [])
    _expect_equal(unknowns, [], "mapping core: opening save has no unknown resource ids")
    var state: GameState = LegacyImporter.map_state(data, _content, report)
    if state == null:
        _expect(false, "mapping core: map_state returns a GameState")
        return
    _expect_equal(state.era_id, 1, "mapping core: era_id maps from p.eraId")
    _expect_equal(state.level, 1, "mapping core: level maps from p.level")
    _expect_equal(state.onboarding_version, 1, "mapping core: onboarding_version maps from o")
    _expect_equal(state.resources.size(), _content.resource_ids.size(), "mapping core: every known resource exists exactly once")
    _expect_equal(state.buildings.size(), _content.building_ids.size(), "mapping core: every known building exists exactly once")
    _amount_equals(state, "lingli", "12", "mapping core: lingli value 12 maps")
    var entry: Dictionary = _resource_entry(state, "lingli")
    _expect_equal(bool(entry.get("unlocked", false)), true, "mapping core: u=1 maps to unlocked true")
    _expect_equal(bool(entry.get("ever_obtained", false)), true, "mapping core: e=1 maps to ever_obtained true")
    var money_entry: Dictionary = _resource_entry(state, "money")
    _expect_equal(bool(money_entry.get("unlocked", true)), false, "mapping core: u=0 maps to unlocked false")
    _expect_equal(int(state.buildings.get("hut", -1)), 1, "mapping core: compact building level maps to hut")
    _expect_equal(int(state.buildings.get("wooden_house", -1)), 0, "mapping core: absent building defaults to level zero")
    _expect_equal(state.revision, 0, "mapping core: mapped state revision starts at zero")
    var mid_data: Dictionary = _sample_data("compact_midgame.b64.txt")
    if mid_data.is_empty():
        return
    var mid_report: Dictionary = LegacyImporter.build_report(mid_data, _content)
    var mid_state: GameState = LegacyImporter.map_state(mid_data, _content, mid_report)
    if mid_state == null:
        _expect(false, "mapping core: mid-game map_state returns a GameState")
        return
    _expect_equal(mid_state.era_id, 2, "mapping core: mid-game era_id maps to 2")
    _expect_equal(mid_state.level, 4, "mapping core: mid-game level maps to 4")
    _expect_equal(mid_state.onboarding_version, 2, "mapping core: mid-game onboarding_version maps to 2")
    _expect_equal(int(mid_state.buildings.get("wooden_house", -1)), 3, "mapping core: mid-game wooden_house maps to 3")
    _expect_equal(int(mid_state.buildings.get("storage_wood", -1)), 1, "mapping core: mid-game storage_wood maps to 1")
    _amount_equals(mid_state, "money", "2500", "mapping core: mid-game money maps to 2500")
    var reinc_data: Dictionary = _sample_data("long_reincarnation.json")
    if reinc_data.is_empty():
        return
    var reinc_report: Dictionary = LegacyImporter.build_report(reinc_data, _content)
    var reinc_state: GameState = LegacyImporter.map_state(reinc_data, _content, reinc_report)
    if reinc_state == null:
        _expect(false, "mapping core: reincarnation map_state returns a GameState")
        return
    _expect_equal(reinc_state.era_id, 1, "mapping core: rebirthCount 23 and highestEraEver 3 never raise era_id above eraId")
    _expect_equal(reinc_state.level, 5, "mapping core: reincarnation level maps from player.level")

func _test_long_key_mapping() -> void:
    if _content == null:
        _expect(false, "long keys: content not loaded")
        return
    var data: Dictionary = _sample_data("long_midgame.json")
    if data.is_empty():
        return
    var report: Dictionary = LegacyImporter.build_report(data, _content)
    var state: GameState = LegacyImporter.map_state(data, _content, report)
    if state == null:
        _expect(false, "long keys: map_state returns a GameState")
        return
    _expect_equal(state.era_id, 1, "long keys: eraId maps from the long player object")
    _expect_equal(state.level, 5, "long keys: level maps from the long player object")
    _expect_equal(state.onboarding_version, 0, "long keys: missing onboarding version defaults to zero")
    _amount_equals(state, "lingli", "212.3739509996405", "long keys: long value string maps to the resource amount")
    _amount_equals(state, "money", "100", "long keys: second long value string maps unchanged")
    var entry: Dictionary = _resource_entry(state, "lingli")
    _expect_equal(bool(entry.get("unlocked", false)), true, "long keys: unlocked maps from the long key")
    _expect_equal(bool(entry.get("ever_obtained", false)), true, "long keys: everObtained maps to ever_obtained")
    _expect_equal(int(state.buildings.get("hut", -1)), 2, "long keys: nested {id,level} map yields hut level 2")
    _expect_equal(int(state.buildings.get("wooden_house", -1)), 1, "long keys: nested {id,level} map yields wooden_house level 1")
    _expect(not state.resources.has("hut_unknown"), "long keys: unknown resource id stays out of the state")
    var unknowns: Array = report.get("unknown_resource_ids", [])
    _expect(unknowns.has("hut_unknown"), "long keys: unknown resource id is reported")

func _test_unknown_ids() -> void:
    if _content == null:
        _expect(false, "unknown ids: content not loaded")
        return
    var data: Dictionary = _sample_data("unknown_ids.json")
    if data.is_empty():
        return
    var report: Dictionary = LegacyImporter.build_report(data, _content)
    var unknown_resources: Array = report.get("unknown_resource_ids", [])
    var unknown_buildings: Array = report.get("unknown_building_ids", [])
    _expect_equal(unknown_resources, ["ghost_crystal", "void_essence"], "unknown ids: unknown resources reported in sorted order")
    _expect_equal(unknown_buildings, ["dark_pagoda", "spirit_spring"], "unknown ids: unknown buildings reported in sorted order")
    var state: GameState = LegacyImporter.map_state(data, _content, report)
    if state == null:
        _expect(false, "unknown ids: map_state returns a GameState")
        return
    _expect(not state.resources.has("ghost_crystal"), "unknown ids: unknown resource never enters state")
    _expect(not state.resources.has("void_essence"), "unknown ids: second unknown resource never enters state")
    _expect(not state.buildings.has("dark_pagoda"), "unknown ids: unknown building never enters state")
    _expect(not state.buildings.has("spirit_spring"), "unknown ids: second unknown building never enters state")
    _expect_equal(int(state.buildings.get("hut", -1)), 2, "unknown ids: known building beside unknown ids still maps")
    _expect_equal(int(state.buildings.get("wooden_house", -1)), 1, "unknown ids: second known building still maps")
    _amount_equals(state, "lingli", "30", "unknown ids: known resource beside unknown ids still maps")

func _test_missing_beast() -> void:
    if _content == null:
        _expect(false, "missing beast: content not loaded")
        return
    var text: String = _read_sample("long_beast_missing.json")
    var imported: Dictionary = LegacyImporter.import_text(text, _content)
    _expect(bool(imported.get("ok", false)), "missing beast: save without beastData still imports successfully")
    if not bool(imported.get("ok", false)):
        return
    var report: Dictionary = imported.get("report", {})
    _expect_equal(bool(report.get("has_beast", true)), false, "missing beast: has_beast is false")
    var warnings: Array = report.get("warnings", [])
    _expect(not warnings.is_empty(), "missing beast: a warning is recorded for the absent beast data")
    var mid_data: Dictionary = _sample_data("compact_midgame.b64.txt")
    if mid_data.is_empty():
        return
    var mid_report: Dictionary = LegacyImporter.build_report(mid_data, _content)
    _expect_equal(bool(mid_report.get("has_beast", false)), true, "missing beast: beastData presence is detected")
    _expect_equal(bool(mid_report.get("has_sect", false)), true, "missing beast: compact s key is detected as sect presence")

func _test_bignum() -> void:
    if _content == null:
        _expect(false, "bignum: content not loaded")
        return
    var big: Dictionary = LegacyImporter.deserialize_amount("1e1000")
    _expect(bool(big.get("ok", false)), "bignum: 1e1000 deserializes")
    _expect(int(big.get("layer", 0)) >= 1, "bignum: 1e1000 keeps layer one or deeper")
    var ee5: Dictionary = LegacyImporter.deserialize_amount("ee5")
    _expect(bool(ee5.get("ok", false)), "bignum: ee5 deserializes")
    _expect_equal(String(ee5.get("form", "")), "string", "bignum: ee5 form is string")
    if not bool(ee5.get("ok", false)):
        return
    var ee5_value: AmountCompat = ee5["value"]
    _expect_equal(ee5_value.compare_to(_amount_of("1e100000")), 0, "bignum: ee5 preserves its magnitude")
    var components: Dictionary = LegacyImporter.deserialize_amount({"sign": 1, "mag": 5, "layer": 2})
    _expect(bool(components.get("ok", false)), "bignum: sign/mag/layer components deserialize")
    _expect_equal(String(components.get("form", "")), "components", "bignum: component form is reported")
    if bool(components.get("ok", false)):
        var components_value: AmountCompat = components["value"]
        _expect_equal(components_value.compare_to(ee5_value), 0, "bignum: components equal the matching ee string")
    var data: Dictionary = _sample_data("long_bignum.json")
    if data.is_empty():
        return
    var report: Dictionary = LegacyImporter.build_report(data, _content)
    var issues: Array = report.get("amount_issues", [])
    _expect(issues.is_empty(), "bignum: none of the big amounts became issues")
    var highs: Array = report.get("high_layer_amounts", [])
    _expect(highs.has("wood:layer=2"), "bignum: ee20 is recorded as a layer two amount")
    for entry_variant in highs:
        var entry: String = String(entry_variant)
        _expect(entry.contains(":layer="), "bignum: high layer entries follow the id-colon-layer form: " + entry)
        if entry.contains(":layer="):
            _expect(int(entry.split("=")[1]) >= 2, "bignum: recorded high layers are at least two: " + entry)
    var state: GameState = LegacyImporter.map_state(data, _content, report)
    if state == null:
        _expect(false, "bignum: map_state returns a GameState")
        return
    _amount_equals(state, "stone_low", "1e1000", "bignum: 1e1000 survives into the mapped state")
    var wood_entry: Dictionary = _resource_entry(state, "wood")
    if not wood_entry.is_empty():
        var wood_amount: AmountCompat = wood_entry["value"]
        _expect(wood_amount.layer >= 2, "bignum: mapped ee20 still sits at layer two or deeper")

func _test_invalid_amount() -> void:
    if _content == null:
        _expect(false, "invalid amount: content not loaded")
        return
    var garbage: Dictionary = LegacyImporter.deserialize_amount("not a number")
    _expect(not bool(garbage.get("ok", true)), "invalid amount: garbage string is rejected")
    var shape: Dictionary = LegacyImporter.deserialize_amount({"mag": 5})
    _expect(not bool(shape.get("ok", true)), "invalid amount: component object without sign is rejected")
    var numeric: Dictionary = LegacyImporter.deserialize_amount(12)
    _expect(bool(numeric.get("ok", false)), "invalid amount: plain numbers are accepted")
    _expect_equal(String(numeric.get("form", "")), "number", "invalid amount: number form is reported")
    var bad_text: String = "{\"version\":\"1.0\",\"timestamp\":1700000000000,\"player\":{\"eraId\":1,\"level\":1},\"resources\":{\"lingli\":{\"value\":\"12abc5\",\"unlocked\":true,\"everObtained\":true}},\"buildings\":{}}"
    var imported: Dictionary = LegacyImporter.import_text(bad_text, _content)
    _expect(bool(imported.get("ok", false)), "invalid amount: import with a broken value still completes")
    if not bool(imported.get("ok", false)):
        return
    var report: Dictionary = imported.get("report", {})
    var issues: Array = report.get("amount_issues", [])
    _expect_equal(issues.size(), 1, "invalid amount: the broken resource is recorded exactly once")
    if issues.size() >= 1:
        _expect(String(issues[0]).begins_with("lingli:"), "invalid amount: the issue names the resource id")
    var imported_state: GameState = imported["state"] as GameState
    if imported_state == null:
        _expect(false, "invalid amount: state is still produced")
        return
    var rejected: Dictionary = _resource_entry(imported_state, "lingli")
    if not rejected.is_empty():
        var rejected_amount: AmountCompat = rejected["value"]
        _expect_equal(rejected_amount.compare_to(AmountCompat.zero()), 0, "invalid amount: rejected value falls back to the empty entry")

func _test_corrupt() -> void:
    if _content == null:
        _expect(false, "corrupt: content not loaded")
        return
    var truncated: Dictionary = LegacyImporter.import_text(_read_sample("corrupt_truncated.txt"), _content)
    _expect_equal(bool(truncated.get("ok", true)), false, "corrupt: truncated base64 import fails without crashing")
    _expect(not String(truncated.get("error", "")).is_empty(), "corrupt: truncated base64 carries an error code")
    var broken_json: Dictionary = LegacyImporter.import_text(_read_sample("corrupt_json.json"), _content)
    _expect_equal(bool(broken_json.get("ok", true)), false, "corrupt: malformed json import fails without crashing")
    _expect_equal(String(broken_json.get("error", "")), "JSON_PARSE", "corrupt: malformed json reports JSON_PARSE")
    var empty_import: Dictionary = LegacyImporter.import_text("", _content)
    _expect_equal(String(empty_import.get("error", "")), "EMPTY", "corrupt: empty import reports EMPTY")

func _test_report_determinism() -> void:
    if _content == null:
        _expect(false, "report determinism: content not loaded")
        return
    var data: Dictionary = _sample_data("long_bignum.json")
    if data.is_empty():
        return
    var first: Dictionary = LegacyImporter.build_report(data, _content)
    var second: Dictionary = LegacyImporter.build_report(data, _content)
    _expect_equal(second, first, "report determinism: two builds of the same data return equal reports")
    var text: String = _read_sample("compact_midgame.b64.txt")
    var run_a: Dictionary = LegacyImporter.import_text(text, _content)
    var run_b: Dictionary = LegacyImporter.import_text(text, _content)
    _expect_equal(run_b.get("report", {}), run_a.get("report", {}), "report determinism: repeated imports produce equal reports")
    _expect_equal(String(run_b.get("raw_json", "")), String(run_a.get("raw_json", "")), "report determinism: raw_json is stable across runs")

func _test_import_preserves_raw() -> void:
    if _content == null:
        _expect(false, "preserves raw: content not loaded")
        return
    SaveManager.reset_for_tests()
    SaveManager.configure(_content, FileStorageAdapter.new(TEST_SLOTS_DIR))
    SaveManager.slots().reset()
    var text: String = _read_sample("compact_opening.json")
    var decoded: Dictionary = LegacyImporter.decode_input(text)
    var result: Dictionary = SaveManager.import_legacy_text(text)
    _expect(bool(result.get("ok", false)), "preserves raw: SaveManager import succeeds")
    if not bool(result.get("ok", false)):
        return
    var report: Dictionary = result.get("report", {})
    _expect_equal(String(report.get("source_format", "")), "compact", "preserves raw: the report travels with the import result")
    _expect_equal(SaveManager.legacy_raw(), String(decoded.get("raw_json", "")), "preserves raw: legacy_raw equals the decoded raw json")
    var b64_text: String = _read_sample("compact_midgame.b64.txt")
    var b64_decoded: Dictionary = LegacyImporter.decode_input(b64_text)
    var b64_result: Dictionary = SaveManager.import_legacy_text(b64_text)
    _expect(bool(b64_result.get("ok", false)), "preserves raw: base64 import succeeds through SaveManager")
    if bool(b64_result.get("ok", false)):
        _expect_equal(SaveManager.legacy_raw(), String(b64_decoded.get("raw_json", "")), "preserves raw: base64 input preserves the decoded json text")

func _test_import_new_slot() -> void:
    if _content == null:
        _expect(false, "new slot: content not loaded")
        return
    SaveManager.reset_for_tests()
    SaveManager.configure(_content, FileStorageAdapter.new(TEST_SLOTS_DIR))
    SaveManager.slots().reset()
    var text: String = _read_sample("compact_opening.json")
    var result: Dictionary = SaveManager.import_legacy_text(text)
    _expect(bool(result.get("ok", false)), "new slot: import succeeds")
    if not bool(result.get("ok", false)):
        return
    var loaded: Variant = SaveManager.load_state()
    _expect(loaded is GameState, "new slot: load_state returns a GameState after the import commit")
    if not (loaded is GameState):
        return
    var state: GameState = loaded as GameState
    _expect_equal(state.era_id, 1, "new slot: mapped era survives the slot commit")
    _expect_equal(state.level, 1, "new slot: mapped level survives the slot commit")
    _expect_equal(int(state.buildings.get("hut", -1)), 1, "new slot: mapped building value survives the slot commit")
    _amount_equals(state, "lingli", "12", "new slot: mapped resource value survives the slot commit")
    _expect(state.revision >= 1, "new slot: the imported commit carries a positive revision")
    _expect_equal(SaveManager.last_settled_utc_ms(), 0, "new slot: the committed cursor stays at zero (no backfill)")
    var bad_result: Dictionary = SaveManager.import_legacy_text("!!! neither json nor base64 !!!")
    _expect_equal(bool(bad_result.get("ok", true)), false, "new slot: failed manager import reports ok false")

func _test_no_system_clock() -> void:
    _scan_dir_for_clock("res://src/persistence")

func _test_backfill_policy() -> void:
    if _content == null:
        _expect(false, "backfill policy: content not loaded")
        return
    var data: Dictionary = _sample_data("long_midgame.json")
    if data.is_empty():
        return
    var report: Dictionary = LegacyImporter.build_report(data, _content)
    _expect_equal(String(report.get("backfill_policy", "")), "none", "backfill policy: report declares none")
    _expect_equal(LegacyImporter.BACKFILL_POLICY, "none", "backfill policy: frozen constant is none")
    var state: GameState = LegacyImporter.map_state(data, _content, report)
    if state == null:
        _expect(false, "backfill policy: map_state returns a GameState")
        return
    _expect_equal(state.training_seconds, 0.0, "backfill policy: no offline seconds are backfilled into training")
    _expect_equal(state.total_elapsed_seconds, 0.0, "backfill policy: no age is backfilled from the old timestamp")
