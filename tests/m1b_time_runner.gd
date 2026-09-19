extends SceneTree

const CONTENT_DIR := "res://content"

var failures: Array[String] = []
var _content: GameContent

func _init() -> void:
    _content = _load_content()
    _test_training_vectors()
    _test_lifespan_vectors()
    _test_ticks()
    _test_segmented_equals_once()
    _test_capacity_clamp()
    _test_insufficient_resource()
    _test_level_up_consumes_and_resets_training()
    _test_age_not_reset_by_level_up()
    _test_max_level_no_level_up()
    _test_lifespan_exhausted_boundary()
    _test_no_system_clock()
    _test_determinism()
    _test_view_fields()
    if failures.is_empty():
        print("PASS: M1-B clock, ticks, cultivation, lifespan, boundaries, determinism.")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _expect(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
    if actual != expected:
        failures.append("%s; expected=%s actual=%s" % [label, str(expected), str(actual)])

func _expect_close(actual: float, expected: float, tolerance: float, label: String) -> void:
    if not is_finite(actual) or abs(actual - expected) > tolerance:
        failures.append("%s; expected=%s actual=%s" % [label, str(expected), str(actual)])

func _load_content() -> GameContent:
    var loaded := ContentLoader.load_directory(CONTENT_DIR)
    if bool(loaded.ok):
        return loaded.content
    failures.append("content load from %s failed: %s" % [CONTENT_DIR, str(loaded.get("errors", []))])
    var built := ContentLoader.build_content(
        [{"id": "lingli", "type": "basic", "max": 100, "rate": 0, "unlocked": true},
         {"id": "money", "type": "basic", "max": 200, "rate": 0, "unlocked": true},
         {"id": "wood", "type": "basic", "max": 100, "rate": 0, "unlocked": true},
         {"id": "stone_low", "type": "basic", "max": 100, "rate": 0, "unlocked": true}],
        [{"id": "hut", "era": 1, "max_level": 10, "cost_factor": 1.5, "prereq": null, "base_cost": {"lingli": 20}, "effect_weight": 1, "effects": {"lingli": 0.3}},
         {"id": "wooden_house", "era": 1, "max_level": 10, "cost_factor": 1.5, "prereq": null, "base_cost": {"money": 10}, "effect_weight": 1, "effects": {"money": 0.1}}],
        [{"id": 1, "name": "練氣期", "max_level": 10, "resource_multiplier": 1, "lifespan": 80,
          "level_up_requirements": {"base_time": 60, "time_multiplier": 1.15, "resources": {"lingli": 50}},
          "upgrade_requirements": {"level": 10, "capacity": {"lingli": 500}}}])
    if built.ok:
        return built.content
    return null

func _test_training_vectors() -> void:
    _expect_close(Cultivation.cumulative_training_time(10, 1.5, 0), 0.0, 0.0001, "cumulative_training_time(10,1.5,0)")
    _expect_close(Cultivation.cumulative_training_time(10, 1.5, 3), 47.5, 0.0001, "cumulative_training_time(10,1.5,3)")
    _expect_close(Cultivation.single_level_time(10, 1.5, 4), 33.75, 0.0001, "single_level_time(10,1.5,4)")
    _expect_close(Cultivation.apply_time_bonuses(100, 0.25, 0.5, 0.1), 36.0, 0.0001, "apply_time_bonuses(100,0.25,0.5,0.1)")
    _expect_close(Cultivation.apply_time_bonuses(100, 0, 0.01, 0.99), 1.0, 0.0001, "apply_time_bonuses(100,0,0.01,0.99)")
    var era_def = _content.era(1)
    _expect_close(Cultivation.single_level_time(60, 1.15, 1), 60.0, 0.0001, "single_level_time(60,1.15,1)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 2), 69.0, 0.0001, "single_level_time(60,1.15,2)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 3), 79.35, 0.0001, "single_level_time(60,1.15,3)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 4), 91.2525, 0.0001, "single_level_time(60,1.15,4)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 5), 104.940375, 0.0001, "single_level_time(60,1.15,5)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 6), 120.6814313, 0.0001, "single_level_time(60,1.15,6)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 7), 138.7836460, 0.0001, "single_level_time(60,1.15,7)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 8), 159.6011929, 0.0001, "single_level_time(60,1.15,8)")
    _expect_close(Cultivation.single_level_time(60, 1.15, 9), 183.5413718, 0.0001, "single_level_time(60,1.15,9)")
    _expect_close(Cultivation.next_level_required_seconds(era_def, 1, 0.0, 1.0), 60.0, 0.0001, "next_level_required_seconds(era_def,1,0.0,1.0)")

func _test_lifespan_vectors() -> void:
    var legacy_series := [{"era_id": 1, "lifespan": 80}, {"era_id": 2, "lifespan": 120}, {"era_id": 3, "lifespan": 540}]
    _expect_equal(Lifespan.max_lifespan_seconds(legacy_series, 1), 4800, "max_lifespan_seconds(series,1)")
    _expect_equal(Lifespan.max_lifespan_seconds(legacy_series, 2), 12000, "max_lifespan_seconds(series,2)")
    _expect_equal(Lifespan.max_lifespan_seconds(legacy_series, 3), 44400, "max_lifespan_seconds(series,3)")
    _expect_equal(Lifespan.max_lifespan_seconds(legacy_series, 2, 0.1, 5), 13500, "max_lifespan_seconds(series,2,0.1,5)")
    _expect_equal(Lifespan.max_lifespan_seconds(legacy_series, 4), 68400, "max_lifespan_seconds(series,4)")
    _expect_equal(Lifespan.is_exhausted(4800, 4800), true, "is_exhausted(4800,4800)")
    _expect_equal(Lifespan.is_exhausted(4799, 4800), false, "is_exhausted(4799,4800)")
    var entries := _content.era_lifespan_entries()
    _expect_equal(Lifespan.max_lifespan_seconds(entries, 1), 4800, "content path max_lifespan_seconds(entries,1)")

func _test_ticks() -> void:
    _expect_equal(TimeAdvancer.ticks_for_elapsed(0), 0, "ticks_for_elapsed(0)")
    _expect_equal(TimeAdvancer.ticks_for_elapsed(59), 0, "ticks_for_elapsed(59)")
    _expect_equal(TimeAdvancer.ticks_for_elapsed(60), 1, "ticks_for_elapsed(60)")
    _expect_equal(TimeAdvancer.ticks_for_elapsed(600), 10, "ticks_for_elapsed(600)")
    _expect_equal(TimeAdvancer.ticks_for_elapsed(-60), 0, "ticks_for_elapsed(-60)")

func _test_segmented_equals_once() -> void:
    var content := _load_content()
    _expect(content != null, "content loaded for segmented equals")
    # Session A: one advance_time(600.0)
    var session_a := GameSession.create_new_game(content)
    session_a.state.buildings["hut"] = 1
    var result_a := session_a.advance_time(600.0)
    _expect_equal(int(result_a.new_revision), 1, "session A revision")
    _expect_equal(result_a.ticks_advanced, 10, "session A ticks advanced")
    _expect_equal(session_a.state.total_elapsed_seconds, 600.0, "session A total_elapsed_seconds")
    # Session B: ten times advance_time(60.0)
    var session_b := GameSession.create_new_game(content)
    session_b.state.buildings["hut"] = 1
    for i in range(10):
        var result_b := session_b.advance_time(60.0)
    _expect_equal(int(session_b.state.revision), 10, "session B revision")
    _expect_equal(session_b.state.total_elapsed_seconds, 600.0, "session B total_elapsed_seconds")
    # Compare snapshots with revision erased
    var snap_a := session_a.state.to_snapshot_dict()
    var snap_b := session_b.state.to_snapshot_dict()
    snap_a.erase("revision")
    snap_b.erase("revision")
    _expect_equal(snap_a, snap_b, "segmented equals after revision erase")

func _test_capacity_clamp() -> void:
    var content := _load_content()
    _expect(content != null, "content loaded for capacity clamp")
    var session := GameSession.create_new_game(content)
    session.state.buildings["hut"] = 1
    var result := session.advance_time(4800.0)
    _expect_equal(result.ticks_advanced, 80, "capacity clamp ticks advanced to lifespan limit")
    _expect_equal(result.stopped, "lifespan_exhausted", "capacity clamp stops at lifespan")
    var view := session.get_view()
    var lingli_parsed := AmountCompat.try_parse(view.resources.lingli.value)
    _expect_close(lingli_parsed.value.mag, 250.0, 0.0001, "capacity clamp lingli value approx 250")
    _expect_equal(int(view.buildings.hut.level), 1, "hut level 1")
    _expect_equal(int(view.era.max_level), 10, "era max level 10")

func _test_insufficient_resource() -> void:
    var content := _load_content()
    _expect(content != null, "content loaded for insufficient resource")
    var session := GameSession.create_new_game(content)
    var result := session.advance_time(300.0)
    _expect_equal(session.state.level, 1, "insufficient resource level stays 1")
    _expect_equal(session.state.training_seconds, 300.0, "insufficient resource training_seconds 300.0")

func _test_level_up_consumes_and_resets_training() -> void:
    var content := _load_content()
    _expect(content != null, "content loaded for level up test")
    var session := GameSession.create_new_game(content)
    session.state.resources.lingli.value = AmountCompat.from_number(100.0)
    var result := session.advance_time(60.0)
    _expect_equal(session.state.level, 2, "level up consumes and resets training level 2")
    _expect_equal(session.state.training_seconds, 0.0, "level up consumes and resets training 0.0")
    var view := session.get_view()
    var lingli_parsed := AmountCompat.try_parse(view.resources.lingli.value)
    _expect_close(lingli_parsed.value.mag, 50.0, 0.0001, "level up consumes lingli to 50")
    _expect(result.changed_ids.has("level"), "level up changed_ids contains level")

func _test_age_not_reset_by_level_up() -> void:
    var content := _load_content()
    _expect(content != null, "content loaded for age not reset test")
    var session := GameSession.create_new_game(content)
    session.state.total_elapsed_seconds = 1000.0
    session.state.resources.lingli.value = AmountCompat.from_number(100.0)
    var result := session.advance_time(60.0)
    _expect_equal(session.state.total_elapsed_seconds, 1060.0, "age not reset total_elapsed 1060.0")
    _expect_equal(session.state.level, 2, "age not reset level 2")

func _test_max_level_no_level_up() -> void:
    var content := _load_content()
    _expect(content != null, "content loaded for max level test")
    var session := GameSession.create_new_game(content)
    session.state.level = 10
    var result := session.advance_time(120.0)
    _expect_equal(session.state.level, 10, "max level stays 10")
    _expect_equal(session.state.training_seconds, 120.0, "max level training accumulates to 120.0")
    var level_up_seen := false
    for event in result.events:
        if event.kind == "level_up":
            level_up_seen = true
            break
    _expect(not level_up_seen, "max level emits no level_up event")

func _test_lifespan_exhausted_boundary() -> void:
    # First session: 79 ticks, should not stop
    var content := _load_content()
    _expect(content != null, "content loaded for lifespan boundary")
    var session1 := GameSession.create_new_game(content)
    var result1 := session1.advance_time(4740.0)
    _expect_equal(result1.stopped, null, "lifespan boundary session1 stopped null")
    _expect_equal(result1.ticks_advanced, 79, "lifespan boundary session1 ticks 79")
    _expect_equal(session1.state.total_elapsed_seconds, 4740.0, "lifespan boundary session1 elapsed 4740.0")
    # Second session: 80 ticks, should stop
    var session2 := GameSession.create_new_game(content)
    var result2 := session2.advance_time(4800.0)
    _expect_equal(result2.stopped, "lifespan_exhausted", "lifespan boundary session2 stopped lifespan_exhausted")
    _expect_equal(result2.ticks_advanced, 80, "lifespan boundary session2 ticks 80")
    _expect_equal(session2.state.total_elapsed_seconds, 4800.0, "lifespan boundary session2 elapsed 4800.0")
    # Check event kind
    var exhaust_event_exists := false
    for event in result2.events:
        if event.kind == "lifespan_exhausted":
            exhaust_event_exists = true
            break
    _expect(exhaust_event_exists, "lifespan boundary event kind lifespan_exhausted exists")
    # Third session: 6000 seconds stops early
    var session3 := GameSession.create_new_game(content)
    var result3 := session3.advance_time(6000.0)
    _expect_equal(result3.ticks_advanced, 80, "lifespan boundary session3 ticks 80")
    _expect_equal(result3.stopped, "lifespan_exhausted", "lifespan boundary session3 stopped lifespan_exhausted")

func _test_no_system_clock() -> void:
    _scan_dir_for_clock("res://src/domain")
    _scan_dir_for_clock("res://src/simulation")

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
        if content.contains("Time.") or content.contains("OS."):
            failures.append("File %s contains Time. or OS. token" % file_path)
    var subdirs: PackedStringArray = access.get_directories()
    for subdir in subdirs:
        _scan_dir_for_clock(path.path_join(subdir))

func _test_determinism() -> void:
    var content := _load_content()
    _expect(content != null, "content loaded for determinism")
    var first := GameSession.create_new_game(content)
    var second := GameSession.create_new_game(content)
    # Sequence: advance_time(600.0), gather lingli, advance_time(180.0)
    var first_result := first.advance_time(600.0)
    var gather_cmd := {"command_id": "det1", "type": "gather", "payload": {"resource_id": "lingli"}, "expected_revision": int(first_result.new_revision)}
    var gather_result := first.submit(gather_cmd)
    _expect(bool(gather_result.ok), "determinism gather succeeds")
    var second_result := second.advance_time(600.0)
    var gather_result2 := second.submit(gather_cmd)
    _expect(bool(gather_result2.ok), "determinism second gather succeeds")
    var third_result := first.advance_time(180.0)
    var third_result2 := second.advance_time(180.0)
    # Compare snapshots with revision erased
    var snap_first := first.state.to_snapshot_dict()
    var snap_second := second.state.to_snapshot_dict()
    snap_first.erase("revision")
    snap_second.erase("revision")
    _expect_equal(snap_first, snap_second, "determinism snapshots equal after revision erase")
    # Compare views deeply equal
    var view_first := first.get_view()
    var view_second := second.get_view()
    _expect_equal(view_first, view_second, "determinism views deeply equal")

func _test_view_fields() -> void:
    var session := GameSession.create_new_game(_load_content())
    var view := session.get_view()
    _expect_equal(view.next_level_required_seconds, 60.0, "view next_level_required_seconds 60.0")
    _expect_equal(view.max_lifespan_seconds, 4800.0, "view max_lifespan_seconds 4800.0")
    _expect_equal(view.training_seconds, 0.0, "view training_seconds 0.0")
    _expect_equal(view.total_elapsed_seconds, 0.0, "view total_elapsed_seconds 0.0")
    _expect_equal(view.era.id, 1, "view era id 1")
    _expect_equal(view.era.max_level, 10, "view era max_level 10")
    _expect_equal(view.era.lifespan, 80, "view era lifespan 80")