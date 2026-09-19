extends SceneTree

const CONTENT_DIR := "res://content"
const TEST_SLOTS_DIR := "user://m1d_test_slots"
const CAP_MS := 86400000
const TWO_DAYS_MS := 172800000
const BASE_CURSOR_MS := 1

var failures: Array[String] = []
var _content: GameContent = null

func _init() -> void:
    SaveManager.reset_for_tests()
    _load_content()
    _test_plan_arithmetic()
    _test_cap_24h()
    _test_reopen_no_double_grant()
    _test_reload_no_regrant()
    _test_rollback()
    _test_age_full_interval()
    _test_lifespan_limit()
    _test_save_failure_retry()
    _test_cursor_commit()
    _test_no_system_clock()
    _test_determinism()
    _test_duplicate_state_isolation()
    _test_summary_no_reward()
    SaveManager.reset_for_tests()
    if failures.is_empty():
        print("PASS: M1-D offline settlement, cap 24h, cursor commit, no double grant.")
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
        var content: String = FileAccess.get_file_as_string(file_path)
        if content.contains("Time.") or content.contains("OS.get_"):
            failures.append("File %s contains Time. or OS.get_ token" % file_path)
    var subdirs: PackedStringArray = access.get_directories()
    for subdir in subdirs:
        _scan_dir_for_clock(path.path_join(subdir))

func _test_plan_arithmetic() -> void:
    _expect_equal(OfflineSettlement.CAP_MS, 86400000, "plan arithmetic: frozen CAP_MS equals 24 hours in milliseconds")
    var boot: Dictionary = OfflineSettlement.plan(-1, 0)
    _expect_equal(bool(boot["bootstrap"]), true, "plan arithmetic: last cursor 0 bootstraps even with a negative now")
    _expect_equal(int(boot["away_ms"]), 0, "plan arithmetic: bootstrap away_ms is zero")
    _expect_equal(int(boot["effective_ms"]), 0, "plan arithmetic: bootstrap effective_ms is zero")
    _expect_equal(int(boot["forfeited_ms"]), 0, "plan arithmetic: bootstrap forfeited_ms is zero")
    _expect_equal(bool(boot["cap_applied"]), false, "plan arithmetic: bootstrap applies no cap")
    _expect_equal(bool(boot["rollback"]), false, "plan arithmetic: bootstrap is not a rollback")
    var boot_48h: Dictionary = OfflineSettlement.plan(TWO_DAYS_MS, 0)
    _expect_equal(bool(boot_48h["bootstrap"]), true, "plan arithmetic: cursor 0 always bootstraps and never grants on first run (frozen rule: last<=0 -> bootstrap)")
    _expect_equal(int(boot_48h["away_ms"]), 0, "plan arithmetic: bootstrap at cursor 0 reports zero away even 48h later")
    var span48: Dictionary = OfflineSettlement.plan(TWO_DAYS_MS + BASE_CURSOR_MS, BASE_CURSOR_MS)
    _expect_equal(int(span48["away_ms"]), TWO_DAYS_MS, "plan arithmetic: 48h interval reports away_ms of 172800000")
    _expect_equal(int(span48["effective_ms"]), CAP_MS, "plan arithmetic: 48h interval is capped to 24h of effective time")
    _expect_equal(int(span48["forfeited_ms"]), TWO_DAYS_MS - CAP_MS, "plan arithmetic: the second 24h is forfeited")
    _expect_equal(bool(span48["cap_applied"]), true, "plan arithmetic: cap_applied is true beyond 24h")
    _expect_equal(bool(span48["rollback"]), false, "plan arithmetic: forward interval is not a rollback")
    _expect_equal(bool(span48["bootstrap"]), false, "plan arithmetic: positive cursor is not a bootstrap")
    var at_cap: Dictionary = OfflineSettlement.plan(CAP_MS + BASE_CURSOR_MS, BASE_CURSOR_MS)
    _expect_equal(int(at_cap["away_ms"]), CAP_MS, "plan arithmetic: interval of exactly 24h reports away_ms of 86400000")
    _expect_equal(int(at_cap["effective_ms"]), CAP_MS, "plan arithmetic: exactly 24h keeps all of its effective time")
    _expect_equal(int(at_cap["forfeited_ms"]), 0, "plan arithmetic: exactly 24h forfeits nothing")
    _expect_equal(bool(at_cap["cap_applied"]), false, "plan arithmetic: frozen rule cap_applied = away > CAP_MS means exactly 24h is not flagged")
    var past_cap: Dictionary = OfflineSettlement.plan(CAP_MS + BASE_CURSOR_MS + 1, BASE_CURSOR_MS)
    _expect_equal(int(past_cap["away_ms"]), CAP_MS + 1, "plan arithmetic: 24h plus 1ms interval reports the extra millisecond")
    _expect_equal(int(past_cap["effective_ms"]), CAP_MS, "plan arithmetic: 24h plus 1ms is capped at 24h")
    _expect_equal(int(past_cap["forfeited_ms"]), 1, "plan arithmetic: 24h plus 1ms forfeits exactly 1ms")
    _expect_equal(bool(past_cap["cap_applied"]), true, "plan arithmetic: cap_applied is true one millisecond past 24h")
    var back: Dictionary = OfflineSettlement.plan(1000, 86400000)
    _expect_equal(bool(back["rollback"]), true, "plan arithmetic: now before cursor flags rollback")
    _expect_equal(int(back["away_ms"]), 0, "plan arithmetic: rollback grants no away time")
    _expect_equal(int(back["effective_ms"]), 0, "plan arithmetic: rollback grants no effective time")
    _expect_equal(int(back["forfeited_ms"]), 0, "plan arithmetic: rollback forfeits nothing")
    _expect_equal(bool(back["cap_applied"]), false, "plan arithmetic: rollback applies no cap")
    _expect_equal(bool(back["bootstrap"]), false, "plan arithmetic: rollback is not a bootstrap")

func _test_cap_24h() -> void:
    if _content == null:
        _expect(false, "cap 24h: content not loaded")
        return
    var state: GameState = GameSession.create_new_game(_content).state
    var settled: Dictionary = OfflineSettlement.settle(state, _content, TWO_DAYS_MS + BASE_CURSOR_MS, BASE_CURSOR_MS)
    var report: Dictionary = settled["report"]
    _expect_equal(int(report["away_ms"]), TWO_DAYS_MS, "cap 24h: report away_ms covers the full 48h interval")
    _expect_equal(int(report["effective_ms"]), CAP_MS, "cap 24h: report effective_ms is clamped to 24h")
    _expect_equal(int(report["forfeited_ms"]), TWO_DAYS_MS - CAP_MS, "cap 24h: report forfeited_ms is the second 24h")
    _expect_equal(bool(report["cap_applied"]), true, "cap 24h: report cap_applied flag is set")
    _expect_equal(int(report["effective_ticks"]), 1440, "cap 24h: exactly 1440 reward ticks (86400s / 60s) are granted for 48h away")
    _expect_equal(int(report["time_only_ticks"]), 1440, "cap 24h: the remaining 1440 ticks advance age only, no rewards")
    _expect_equal(int(report["left_at_utc_ms"]), BASE_CURSOR_MS, "cap 24h: report left_at_utc_ms echoes the previous cursor")
    _expect_equal(int(report["settled_at_utc_ms"]), TWO_DAYS_MS + BASE_CURSOR_MS, "cap 24h: report settled_at_utc_ms echoes now")
    _expect_equal(String(report["report_id"]), "offline:" + str(TWO_DAYS_MS + BASE_CURSOR_MS), "cap 24h: report_id follows the offline:<now> format")

func _test_reopen_no_double_grant() -> void:
    if _content == null:
        _expect(false, "reopen no double grant: content not loaded")
        return
    var state: GameState = GameSession.create_new_game(_content).state
    state.era_id = 8
    var first: Dictionary = OfflineSettlement.settle(state, _content, TWO_DAYS_MS + BASE_CURSOR_MS, BASE_CURSOR_MS)
    var first_report: Dictionary = first["report"]
    _expect_equal(int(first_report["away_ms"]), TWO_DAYS_MS, "reopen no double grant: first settlement sees the full 48h interval")
    _expect_equal(int(first_report["age_seconds"]), 172800, "reopen no double grant: first settlement ages the state by the full 48h")
    var elapsed_after_first: float = state.total_elapsed_seconds
    var snapshot_after_first: Dictionary = state.to_snapshot_dict()
    var second: Dictionary = OfflineSettlement.settle(state, _content, TWO_DAYS_MS + BASE_CURSOR_MS, TWO_DAYS_MS + BASE_CURSOR_MS)
    var second_report: Dictionary = second["report"]
    _expect_equal(int(second_report["away_ms"]), 0, "reopen no double grant: reopening at the committed cursor sees zero away time")
    _expect_equal(int(second_report["effective_ms"]), 0, "reopen no double grant: reopening grants zero effective time")
    _expect_equal(int(second_report["effective_ticks"]), 0, "reopen no double grant: reopening runs zero reward ticks")
    _expect_equal(int(second_report["time_only_ticks"]), 0, "reopen no double grant: reopening runs zero age-only ticks")
    _expect_equal(bool(second_report["rollback"]), false, "reopen no double grant: equal clocks are treated as zero interval, not a rollback")
    _expect_equal(state.total_elapsed_seconds, elapsed_after_first, "reopen no double grant: age is untouched by the reopen settlement")
    _expect_equal(state.to_snapshot_dict(), snapshot_after_first, "reopen no double grant: resources are untouched by the reopen settlement")

func _test_reload_no_regrant() -> void:
    if _content == null:
        _expect(false, "reload no regrant: content not loaded")
        return
    SaveManager.reset_for_tests()
    SaveManager.configure(_content, FileStorageAdapter.new(TEST_SLOTS_DIR))
    SaveManager.slots().reset()
    var first: Dictionary = OfflineCoordinator.settle(172800001)
    _expect_equal(bool(first["ok"]), true, "reload no regrant: first coordinator settlement succeeds")
    _expect_equal(bool(first["committed"]), true, "reload no regrant: first coordinator settlement commits")
    var cursor_after_first: int = SaveManager.last_settled_utc_ms()
    _expect_equal(cursor_after_first, 172800001, "reload no regrant: cursor is committed to 172800001")
    var first_report: Dictionary = first["report"]
    var first_report_id: String = String(first_report["report_id"])
    SaveManager.configure(_content, FileStorageAdapter.new(TEST_SLOTS_DIR))
    var reloaded_state: GameState = SaveManager.load_state() as GameState
    if reloaded_state == null:
        _expect(false, "reload no regrant: state reloads from the slot files on disk")
        return
    _expect_equal(SaveManager.last_settled_utc_ms(), cursor_after_first, "reload no regrant: the cursor survives a simulated process reload")
    var stored_report: Variant = SaveManager.envelope().get("last_offline_report")
    if stored_report is Dictionary:
        var stored_report_dict: Dictionary = stored_report
        _expect_equal(String(stored_report_dict["report_id"]), first_report_id, "reload no regrant: last_offline_report reads back with the committed report_id")
    else:
        _expect(false, "reload no regrant: envelope last_offline_report is a Dictionary after reload")
    var before_snap: Dictionary = reloaded_state.to_snapshot_dict()
    var second: Dictionary = OfflineCoordinator.settle(172800001)
    var second_report: Dictionary = second["report"]
    _expect_equal(int(second_report["away_ms"]), 0, "reload no regrant: a settlement at the committed cursor sees zero away time")
    _expect_equal(int(second_report["effective_ms"]), 0, "reload no regrant: a settlement at the committed cursor grants zero effective time")
    var after_state: GameState = SaveManager.load_state() as GameState
    if after_state != null:
        var after_snap: Dictionary = after_state.to_snapshot_dict()
        _expect_equal(after_snap["total_elapsed_seconds"], before_snap["total_elapsed_seconds"], "reload no regrant: age is untouched by the duplicate settlement")
    else:
        _expect(false, "reload no regrant: state still loads after the duplicate settlement")
    _expect_equal(SaveManager.last_settled_utc_ms(), cursor_after_first, "reload no regrant: the cursor is unchanged after the duplicate settlement")

func _test_rollback() -> void:
    if _content == null:
        _expect(false, "rollback: content not loaded")
        return
    var state: GameState = GameSession.create_new_game(_content).state
    state.total_elapsed_seconds = 100.0
    var settled: Dictionary = OfflineSettlement.settle(state, _content, 1000000000, 2000000000)
    var report: Dictionary = settled["report"]
    _expect_equal(bool(report["rollback"]), true, "rollback: settling with now before the cursor flags rollback")
    _expect_equal(int(report["away_ms"]), 0, "rollback: a backwards clock grants no away time")
    _expect_equal(int(report["effective_ms"]), 0, "rollback: a backwards clock grants no effective time")
    _expect_equal(state.total_elapsed_seconds, 100.0, "rollback: a backwards clock never rewinds age")
    var adapter: FileStorageAdapter = FileStorageAdapter.new(TEST_SLOTS_DIR)
    SaveManager.configure(_content, adapter)
    SaveManager.slots().reset()
    var seed_state: GameState = GameSession.create_new_game(_content).state
    var seed_meta: Dictionary = {"save_id": "local", "saved_at_utc_ms": "2000000000", "settled_until_utc_ms": "2000000000", "sim_tick": "0"}
    var seeded: Dictionary = SaveManager.save(seed_state, seed_meta)
    _expect(bool(seeded.get("ok", false)), "rollback: seed save at the future cursor commits")
    var settled_back: Dictionary = OfflineCoordinator.settle(1000000000)
    _expect_equal(bool(settled_back["ok"]), true, "rollback: coordinator reports a rollback without an error")
    _expect_equal(bool(settled_back["committed"]), false, "rollback: coordinator never commits a rollback settlement")
    _expect_equal(SaveManager.last_settled_utc_ms(), 2000000000, "rollback: the cursor never moves backwards")

func _test_age_full_interval() -> void:
    if _content == null:
        _expect(false, "age full interval: content not loaded")
        return
    var state: GameState = GameSession.create_new_game(_content).state
    state.era_id = 8
    var settled: Dictionary = OfflineSettlement.settle(state, _content, TWO_DAYS_MS + BASE_CURSOR_MS, BASE_CURSOR_MS)
    var report: Dictionary = settled["report"]
    _expect(report["stopped"] == null, "age full interval: era 8 cumulative lifespan of 214800s covers the whole 48h interval (era 1 would clamp at 4800s)")
    _expect_equal(int(state.total_elapsed_seconds), 172800, "age full interval: the full 48h of age advances even though only 24h earns rewards (2880 ticks x 60s)")
    _expect_equal(int(report["effective_ticks"]), 1440, "age full interval: only the first 24h of ticks earned rewards")
    _expect_equal(int(report["time_only_ticks"]), 1440, "age full interval: the second 24h of ticks was age-only")
    _expect_equal(float(report["age_seconds"]), state.total_elapsed_seconds, "age full interval: report age_seconds matches the settled state age")
    var era1: GameState = GameSession.create_new_game(_content).state
    var era1_settled: Dictionary = OfflineSettlement.settle(era1, _content, TWO_DAYS_MS + BASE_CURSOR_MS, BASE_CURSOR_MS)
    var era1_report: Dictionary = era1_settled["report"]
    var era1_stopped: Variant = era1_report["stopped"]
    _expect(era1_stopped != null and String(era1_stopped) == "lifespan_exhausted", "age full interval: era 1 documents the lifespan clamp instead of reaching 172800s")
    _expect_equal(int(era1.total_elapsed_seconds), 4800, "age full interval: era 1 clamp lands exactly on the 4800s lifespan (80 years x 60)")

func _test_lifespan_limit() -> void:
    if _content == null:
        _expect(false, "lifespan limit: content not loaded")
        return
    var state: GameState = GameSession.create_new_game(_content).state
    var settled: Dictionary = OfflineSettlement.settle(state, _content, 1000000000, BASE_CURSOR_MS)
    var report: Dictionary = settled["report"]
    var stopped: Variant = report["stopped"]
    _expect(stopped != null and String(stopped) == "lifespan_exhausted", "lifespan limit: a huge interval on era 1 stops with lifespan_exhausted")
    var top_stopped: Variant = settled["stopped"]
    _expect(top_stopped != null and String(top_stopped) == "lifespan_exhausted", "lifespan limit: top-level stopped mirrors report stopped")
    _expect_equal(int(state.total_elapsed_seconds), 4800, "lifespan limit: era 1 settles frozen at the 4800s lifespan (80 years x 60)")
    _expect_equal(bool(report["cap_applied"]), true, "lifespan limit: the 24h reward cap still applied to the huge interval")

func _test_save_failure_retry() -> void:
    if _content == null:
        _expect(false, "save failure retry: content not loaded")
        return
    var toggle: ToggleAdapter = ToggleAdapter.new(FileStorageAdapter.new(TEST_SLOTS_DIR))
    SaveManager.configure(_content, toggle)
    SaveManager.slots().reset()
    var base: GameState = GameSession.create_new_game(_content).state
    var base_meta: Dictionary = {"save_id": "local", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
    var seeded: Dictionary = SaveManager.save(base, base_meta)
    _expect(bool(seeded.get("ok", false)), "save failure retry: baseline save at cursor 1000 commits")
    _expect_equal(SaveManager.last_settled_utc_ms(), 1000, "save failure retry: envelope cursor reads back as 1000")
    toggle.fail_writes = true
    var first: Dictionary = OfflineCoordinator.settle(172800000)
    _expect_equal(bool(first["ok"]), false, "save failure retry: a failed commit reports ok false")
    _expect_equal(String(first["error"]), "SAVE_FAILED", "save failure retry: a failed commit reports SAVE_FAILED")
    _expect_equal(bool(first["committed"]), false, "save failure retry: a failed commit is not marked committed")
    var failed_state: GameState = first["state"] as GameState
    if failed_state != null:
        _expect_equal(failed_state.total_elapsed_seconds, 0.0, "save failure retry: the failed settlement leaves the cached state untouched")
    else:
        _expect(false, "save failure retry: failed result still carries the pre-settlement state")
    _expect_equal(SaveManager.last_settled_utc_ms(), 1000, "save failure retry: the cursor stays at 1000 after a failed save")
    toggle.fail_writes = false
    var second: Dictionary = OfflineCoordinator.settle(172800000)
    _expect_equal(bool(second["ok"]), true, "save failure retry: retry after storage recovers reports ok true")
    _expect_equal(bool(second["committed"]), true, "save failure retry: retry after storage recovers commits")
    var control: GameState = GameSession.create_new_game(_content).state
    var control_settled: Dictionary = OfflineSettlement.settle(control, _content, 172800000, 1000)
    var control_report: Dictionary = control_settled["report"]
    var second_report: Dictionary = second["report"]
    _expect_equal(int(second_report["away_ms"]), int(control_report["away_ms"]), "save failure retry: retried away_ms equals a single fresh settlement (no double grant)")
    var second_state: GameState = second["state"] as GameState
    if second_state != null:
        _expect_equal(int(second_state.total_elapsed_seconds), int(control.total_elapsed_seconds), "save failure retry: retried age equals exactly one settlement of age (4800 via era 1 lifespan)")
        var retry_snap: Dictionary = second_state.to_snapshot_dict()
        retry_snap.erase("revision")
        var control_snap: Dictionary = control.to_snapshot_dict()
        control_snap.erase("revision")
        _expect_equal(retry_snap, control_snap, "save failure retry: retried snapshot equals a single fresh settlement snapshot (no double grant)")
    else:
        _expect(false, "save failure retry: committed result carries the working state")
    _expect_equal(SaveManager.last_settled_utc_ms(), 172800000, "save failure retry: cursor committed to now only after the save succeeded")

func _test_cursor_commit() -> void:
    if _content == null:
        _expect(false, "cursor commit: content not loaded")
        return
    var adapter: FileStorageAdapter = FileStorageAdapter.new(TEST_SLOTS_DIR)
    SaveManager.configure(_content, adapter)
    SaveManager.slots().reset()
    var initial: GameState = GameSession.create_new_game(_content).state
    var initial_meta: Dictionary = {"save_id": "local", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
    var seeded: Dictionary = SaveManager.save(initial, initial_meta)
    _expect(bool(seeded.get("ok", false)), "cursor commit: initial save at cursor 0 commits")
    var first: Dictionary = OfflineCoordinator.settle(TWO_DAYS_MS)
    _expect_equal(bool(first["ok"]), true, "cursor commit: bootstrap settlement succeeds")
    _expect_equal(bool(first["committed"]), true, "cursor commit: bootstrap settlement commits")
    var first_report: Dictionary = first["report"]
    _expect_equal(bool(first_report["bootstrap"]), true, "cursor commit: settlement from cursor 0 is a bootstrap")
    _expect_equal(int(first_report["away_ms"]), 0, "cursor commit: bootstrap grants no away time")
    _expect_equal(SaveManager.last_settled_utc_ms(), TWO_DAYS_MS, "cursor commit: bootstrap still moves the cursor to now")
    var forfeit_now: int = TWO_DAYS_MS + TWO_DAYS_MS
    var second: Dictionary = OfflineCoordinator.settle(forfeit_now)
    _expect_equal(bool(second["committed"]), true, "cursor commit: a forfeited over-cap interval still commits")
    var second_report: Dictionary = second["report"]
    _expect_equal(int(second_report["away_ms"]), TWO_DAYS_MS, "cursor commit: second stage sees the full 48h interval")
    _expect_equal(int(second_report["forfeited_ms"]), CAP_MS, "cursor commit: second stage forfeits 24h beyond the cap")
    _expect_equal(bool(second_report["cap_applied"]), true, "cursor commit: second stage flags the cap")
    _expect_equal(SaveManager.last_settled_utc_ms(), forfeit_now, "cursor commit: cursor jumps to now even though 24h was forfeited")

func _test_no_system_clock() -> void:
    _scan_dir_for_clock("res://src/simulation")
    var coordinator_source: String = FileAccess.get_file_as_string("res://src/application/offline_coordinator.gd")
    if coordinator_source.is_empty():
        failures.append("clock scan: res://src/application/offline_coordinator.gd is not readable")
    if coordinator_source.contains("Time.") or coordinator_source.contains("OS.get_"):
        failures.append("File res://src/application/offline_coordinator.gd contains Time. or OS.get_ token")

func _test_determinism() -> void:
    if _content == null:
        _expect(false, "determinism: content not loaded")
        return
    var state_a: GameState = GameSession.create_new_game(_content).state
    var state_b: GameState = GameSession.create_new_game(_content).state
    var settled_a: Dictionary = OfflineSettlement.settle(state_a, _content, 172800001, 1)
    var settled_b: Dictionary = OfflineSettlement.settle(state_b, _content, 172800001, 1)
    var report_a: Dictionary = settled_a["report"]
    var report_b: Dictionary = settled_b["report"]
    _expect_equal(report_a, report_b, "determinism: two independent offline settlements of identical fresh states produce equal reports")
    _expect_equal(int(report_a["effective_ticks"]), int(report_b["effective_ticks"]), "determinism: effective_ticks are equal across the two runs")
    _expect_equal(int(report_a["time_only_ticks"]), int(report_b["time_only_ticks"]), "determinism: time_only_ticks are equal across the two runs")
    var snap_a: Dictionary = state_a.to_snapshot_dict()
    var snap_b: Dictionary = state_b.to_snapshot_dict()
    snap_a.erase("revision")
    snap_b.erase("revision")
    _expect_equal(snap_a, snap_b, "determinism: the two settled states produce equal snapshots (revision erased)")

func _test_duplicate_state_isolation() -> void:
    if _content == null:
        _expect(false, "duplicate isolation: content not loaded")
        return
    var session: GameSession = GameSession.create_new_game(_content)
    var original: GameState = session.state
    var copy: GameState = original.duplicate_state()
    _expect(not is_same(copy, original), "duplicate isolation: duplicate_state returns a distinct GameState instance")
    var original_resources: Dictionary = original.resources
    var copy_resources: Dictionary = copy.resources
    var resource_id: String = "lingli"
    if not original_resources.has(resource_id):
        resource_id = String(original_resources.keys()[0])
    var original_entry: Dictionary = original_resources[resource_id]
    var copy_entry: Dictionary = copy_resources[resource_id]
    _expect(not is_same(copy_entry["value"], original_entry["value"]), "duplicate isolation: resource amounts are deep-copied, not shared references")
    var original_value: AmountCompat = original_entry["value"]
    var original_value_before: AmountCompat = original_value.duplicate_amount()
    copy_entry["value"] = AmountCompat.from_number(999.0)
    _expect_equal(original_value.compare_to(original_value_before), 0, "duplicate isolation: mutating the copy never writes through to the original")
    _expect_equal(copy.total_elapsed_seconds, original.total_elapsed_seconds, "duplicate isolation: the copy carries the original age")
    _expect_equal(copy.revision, original.revision, "duplicate isolation: the copy carries the original revision")

func _test_summary_no_reward() -> void:
    var summary_source: String = FileAccess.get_file_as_string("res://src/presentation/offline_summary.gd")
    if summary_source.is_empty():
        failures.append("summary no reward: res://src/presentation/offline_summary.gd is not readable")
        return
    _expect(not summary_source.contains("SaveManager"), "summary no reward: OfflineSummary never references SaveManager")
    _expect(not summary_source.contains("OfflineCoordinator"), "summary no reward: OfflineSummary never references OfflineCoordinator")
    _expect(not summary_source.contains("OfflineSettlement"), "summary no reward: OfflineSummary never calls settlement logic")
    _expect(not summary_source.contains(".commit("), "summary no reward: OfflineSummary never commits saves")
    _expect(not summary_source.contains(".save("), "summary no reward: OfflineSummary never saves directly")
    _expect(not summary_source.contains("import_share_string"), "summary no reward: OfflineSummary never imports share strings")
    _expect(summary_source.contains("visible = false"), "summary no reward: closing the summary only hides it (visible = false in the close handler)")

class ToggleAdapter extends StorageAdapter:
    var inner: FileStorageAdapter = null
    var fail_writes: bool = false

    func _init(target: FileStorageAdapter) -> void:
        inner = target

    func read(key: String) -> Dictionary:
        return inner.read(key)

    func write(key: String, data: String) -> Dictionary:
        if fail_writes:
            return {"ok": false, "error": "boom"}
        return inner.write(key, data)

    func erase(key: String) -> Dictionary:
        return inner.erase(key)

    func exists(key: String) -> bool:
        return inner.exists(key)

    func backend_name() -> String:
        return inner.backend_name()

    func is_persistent() -> bool:
        return inner.is_persistent()
