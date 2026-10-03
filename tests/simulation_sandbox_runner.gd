extends SceneTree

## simulation_sandbox_runner.gd
## Validates SimulationSandbox:
## 1. Zero mutation / session isolation (source state unaffected).
## 2. Accurate projection metrics (lifespan, elapsed, training, resources).
## 3. Cap detection and resource overflow tagging.
## 4. Subsystem simulation (buff expiration, sect completion, beast/fortune CD).
## 5. Lifespan exhaustion early stop handling.
## 6. Stress test scalability and health diagnosis at 30 days.
## 7. Report formatting and DebugActions integration.

var _failed := false

func _init() -> void:
	_run()

func _run() -> void:
	print("[SIMULATION_SANDBOX_RUNNER] Starting SimulationSandbox unit tests...")
	var content := (ContentLoader.load_directory("res://content")["content"] as GameContent)
	
	_test_session_isolation(content)
	_test_projection_metrics(content)
	_test_cap_detection(content)
	_test_lifespan_exhaustion(content)
	_test_subsystems_projection(content)
	_test_stress_test(content)
	_test_report_formatting(content)
	await _test_debug_actions_integration(content)

	if _failed:
		printerr("[SIMULATION_SANDBOX_RUNNER] FAILED (exit 1)")
		quit(1)
	else:
		print("[SIMULATION_SANDBOX_RUNNER] ALL SIMULATION SANDBOX TESTS PASSED (exit 0)")
		quit(0)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		printerr("  FAIL: ", msg)
		_failed = true

func _new_session(content: GameContent) -> GameSession:
	return GameSession.create_new_game(content)

## 1. 隔離性檢驗：推演後來源 session 狀態不得有任何改動
func _test_session_isolation(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.buildings["hut"] = 2
	var prev_rev := s.state.revision
	var prev_elapsed := s.state.total_elapsed_seconds
	var prev_wood: float = (s.state.resources["wood"].value as AmountCompat).to_float()

	var proj := SimulationSandbox.run_offline_projection(s, 86400.0)
	_expect(bool(proj.ok), "run_offline_projection returns ok")
	_expect(s.state.revision == prev_rev, "source revision unchanged")
	_expect(s.state.total_elapsed_seconds == prev_elapsed, "source total_elapsed_seconds unchanged")
	_expect((s.state.resources["wood"].value as AmountCompat).to_float() == prev_wood, "source resources unchanged")

## 2. 數值指標檢驗：推進秒數、修煉時間、資源增量計算
func _test_projection_metrics(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.buildings["hut"] = 1
	var proj := SimulationSandbox.run_offline_projection(s, 3600.0)
	_expect(bool(proj.ok), "1 hour projection ok")
	_expect(float(proj.simulated_requested_seconds) == 3600.0, "requested seconds matches")
	_expect(float(proj.actual_advanced_seconds) == 3600.0, "actual advanced matches requested")
	_expect(int(proj.ticks_advanced) == 3600, "ticks advanced matches 3600")
	_expect(proj.stopped_reason == null, "stopped_reason is null for normal run")

	var ls: Dictionary = proj.lifespan
	_expect(float(ls.consumed_years) > 0.0, "lifespan consumed > 0")
	_expect(float(ls.end_remaining_sec) < float(ls.initial_remaining_sec), "remaining lifespan decreased")

	var tr: Dictionary = proj.training
	_expect(float(tr.delta_training_sec) == 3600.0, "training time advanced by 3600s")

## 3. 滿倉與溢出標籤檢驗
func _test_cap_detection(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.buildings["hut"] = 2
	# 3600 秒 (1小時)，hut 2 級的產出必定達到早期靈氣倉容上限 (250)
	var proj := SimulationSandbox.run_offline_projection(s, 3600.0)
	var res_dict: Dictionary = proj.resources
	_expect(res_dict.has("lingli"), "resources contains lingli")
	var lingli_entry: Dictionary = res_dict["lingli"]
	_expect(bool(lingli_entry.is_capped), "lingli is detected as capped after 1h")
	var end_amt: AmountCompat = AmountCompat.try_parse(String(lingli_entry.end_amount)).value
	var cap_amt: AmountCompat = AmountCompat.try_parse(String(lingli_entry.cap_amount)).value
	_expect(end_amt.compare_to(cap_amt) <= 0, "end amount does not exceed cap")

## 4. 壽元耗竭提前終止檢驗
func _test_lifespan_exhaustion(content: GameContent) -> void:
	var s := _new_session(content)
	var era_entry = content.era(s.state.era_id)
	var max_sec := float(era_entry.lifespan) * 60.0
	# 將當前已流逝時間設為極接近極限
	s.state.total_elapsed_seconds = max_sec - 100.0

	var proj := SimulationSandbox.run_offline_projection(s, 500.0) # 請求 500 秒，但應在 100 秒時停下
	_expect(bool(proj.ok), "projection runs ok")
	_expect(proj.stopped_reason == "lifespan_exhausted", "stops on lifespan_exhausted")
	_expect(int(proj.ticks_advanced) <= 100, "ticks advanced clamped to remaining lifespan")
	_expect(bool(proj.lifespan.is_exhausted), "lifespan.is_exhausted is true")

## 5. 子系統事件推演結算（BUFF 到期、宗門完成、靈獸與機緣 CD）
func _test_subsystems_projection(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.buffs["spiritual_surge"] = {
		"id": "spiritual_surge",
		"remaining_seconds": 600.0,
		"effect": {"type": "production_multiplier", "value": 1.0}
	}
	s.state.beasts["cooldown_remaining"] = 300.0
	s.state.fortune["cooldown_remaining"] = 1800.0

	var proj := SimulationSandbox.run_offline_projection(s, 3600.0) # 快進 1 小時
	var subs: Dictionary = proj.subsystems
	var expired: Array = subs.expired_buffs
	_expect("spiritual_surge" in expired, "spiritual_surge is tagged as expired")
	_expect(bool(subs.beast_cd_ready), "beast cooldown ready after 1h")
	_expect(bool(subs.fortune_ready), "fortune cooldown ready after 1h")

## 6. 30 天極限壓測
func _test_stress_test(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.buildings["hut"] = 1
	var stress := SimulationSandbox.run_stress_test(s, 30 * 86400.0)
	_expect(bool(stress.ok), "stress test returns ok")
	_expect(bool(stress.healthy), "stress test endpoint state is healthy")
	_expect((stress.issues as Array).is_empty(), "0 issues found in stress test")
	_expect(float(stress.benchmark_duration_ms) >= 0.0, "benchmark recorded")

## 7. 報告格式化檢驗
func _test_report_formatting(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.buildings["hut"] = 1
	var proj := SimulationSandbox.run_offline_projection(s, 3600.0)
	var text := SimulationSandbox.format_projection_report(proj)
	_expect(text.contains("【離線數值推演與沙盒分析報告】"), "report has correct title")
	_expect(text.contains("請求快進時長"), "report mentions requested duration")
	_expect(text.contains("消耗壽元"), "report mentions lifespan")
	_expect(text.contains("子系統結算狀況"), "report mentions subsystems")

## 8. DebugActions 整合檢驗
func _test_debug_actions_integration(content: GameContent) -> void:
	var s := _new_session(content)
	s.state.buildings["hut"] = 1
	var r1 := DebugActions.run("sim_offline", {"seconds": 3600.0}, s)
	_expect(bool(r1.ok), "DebugActions sim_offline ok")
	_expect(String(r1.get("msg", "")).contains("推演完成"), "msg mentions completion")
	_expect(r1.has("report"), "contains report")

	var r2 := DebugActions.run("sim_stress", {"seconds": 86400.0}, s)
	_expect(bool(r2.ok), "DebugActions sim_stress ok")
	_expect(String(r2.get("msg", "")).contains("壓測完畢"), "msg mentions stress completion")
	_expect(r2.has("stress"), "contains stress payload")
