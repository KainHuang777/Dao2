extends SceneTree

## runtime_inspector_runner.gd
## Validates RuntimeInspector (production rate breakdown, healthy state checks,
## anomaly detection, negative boundaries, report generation, and DebugActions integration).
## Isolated in-memory tests; no player saves are touched.

var _failed := false

func _init() -> void:
	_run()

func _run() -> void:
	print("[RUNTIME_INSPECTOR_RUNNER] Starting RuntimeInspector diagnostics tests...")
	var content := (ContentLoader.load_directory("res://content")["content"] as GameContent)
	_test_fresh_game_health(content)
	_test_production_inspection(content)
	_test_anomaly_detection(content)
	_test_report_generation(content)
	await _test_panel_integration(content)
	
	if _failed:
		printerr("[RUNTIME_INSPECTOR_RUNNER] FAILED (exit 1)")
		quit(1)
	else:
		print("[RUNTIME_INSPECTOR_RUNNER] ALL RUNTIME INSPECTOR TESTS PASSED (exit 0)")
		quit(0)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		printerr("  FAIL: ", msg)
		_failed = true

func _new_session(content: GameContent) -> GameSession:
	return GameSession.create_new_game(content)

func _test_fresh_game_health(content: GameContent) -> void:
	var s := _new_session(content)
	var health := RuntimeInspector.inspect_health(s)
	_expect(bool(health.healthy), "fresh game session must be healthy")
	_expect((health.issues as Array).is_empty(), "fresh game must have 0 issues")
	var stats: Dictionary = health.stats
	_expect(int(stats.era_id) == s.state.era_id, "stats era_id matches")
	_expect(int(stats.level) == 1, "stats level matches")

func _test_production_inspection(content: GameContent) -> void:
	var s := _new_session(content)
	var prod := RuntimeInspector.inspect_production(s)
	_expect(bool(prod.ok), "inspect_production ok on fresh session")
	_expect(prod.has("global_multipliers"), "has global_multipliers dict")
	_expect(prod.has("resources"), "has resources dict")
	var res_dict: Dictionary = prod.resources
	for rid in s.state.resources:
		_expect(res_dict.has(rid), "resource breakdown contains %s" % rid)
		var r_entry: Dictionary = res_dict[rid]
		_expect(r_entry.has("net_rate_per_sec"), "has net_rate_per_sec")
		_expect(r_entry.has("current_amount"), "has current_amount")
		_expect(r_entry.has("cap_amount"), "has cap_amount")

func _test_anomaly_detection(content: GameContent) -> void:
	# 1. 境界非法
	var s1 := _new_session(content)
	s1.state.era_id = 999
	var h1 := RuntimeInspector.inspect_health(s1)
	_expect(not bool(h1.healthy), "invalid era_id must fail health check")
	_expect((h1.issues as Array).any(func(x): return "INVALID_ERA_ID" in String(x)), "issue records INVALID_ERA_ID")

	# 2. 資源為負
	var s2 := _new_session(content)
	var first_rid := String(content.resource_ids[0])
	s2.state.resources[first_rid]["value"] = AmountCompat.from_number(-50.0)
	var h2 := RuntimeInspector.inspect_health(s2)
	_expect(not bool(h2.healthy), "negative resource must fail health check")
	_expect((h2.issues as Array).any(func(x): return "NEGATIVE_RESOURCE" in String(x)), "issue records NEGATIVE_RESOURCE")

	# 3. 靈獸狀態損壞
	var s3 := _new_session(content)
	s3.state.beasts["active_beast_id"] = "ghost_dragon" # 非法 ID
	var h3 := RuntimeInspector.inspect_health(s3)
	_expect(not bool(h3.healthy), "invalid beast ID must fail health check")
	_expect((h3.issues as Array).any(func(x): return "INVALID_BEAST_ID" in String(x)), "issue records INVALID_BEAST_ID")

	# 4. 宗門派遣超限
	var s4 := _new_session(content)
	s4.state.sect["joined"] = true
	s4.state.sect["name"] = "太虛天闕"
	s4.state.sect["ongoing_expeditions"] = [{}, {}, {}, {}] # 4 個 (上限 3)
	var h4 := RuntimeInspector.inspect_health(s4)
	_expect(not bool(h4.healthy), "exceeded expedition slots must fail")
	_expect((h4.issues as Array).any(func(x): return "EXCEEDED_EXPEDITION_SLOTS" in String(x)), "issue records EXCEEDED_EXPEDITION_SLOTS")

func _test_report_generation(content: GameContent) -> void:
	var s := _new_session(content)
	var report := RuntimeInspector.generate_report(s)
	_expect(report.length() > 50, "report is non-empty")
	_expect(report.contains("遊戲運行時診斷報告"), "report has header")
	_expect(report.contains("【健全 PASS】"), "fresh game report reports PASS")
	_expect(report.contains("資源產銷與乘區拆解"), "report contains production breakdown")

func _test_panel_integration(content: GameContent) -> void:
	var s := _new_session(content)
	var r_health := DebugActions.run("inspect_health", {}, s)
	_expect(bool(r_health.ok), "DebugActions inspect_health action ok")
	_expect(bool(r_health.get("healthy", false)), "fresh session reports healthy=true")
	_expect(String(r_health.get("report", "")).length() > 0, "report included in return payload")

	var r_prod := DebugActions.run("inspect_prod", {}, s)
	_expect(bool(r_prod.ok), "DebugActions inspect_prod action ok")
	_expect(String(r_prod.get("msg", "")).contains("產銷分析完成"), "msg mentions completion")

	var panel := DebugPanel.new()
	root.add_child(panel)
	await process_frame
	var buttons := panel.find_children("Action_*", "Button", true, false)
	_expect(buttons.size() == 28, "panel exposes 28 extended action buttons including sandbox actions (got %d)" % buttons.size())
	panel.queue_free()
