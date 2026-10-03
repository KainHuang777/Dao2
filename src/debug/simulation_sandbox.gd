class_name SimulationSandbox
extends RefCounted
## Offline simulation and stress test sandbox for GameSession/GameState.
## Runs projections and stress tests in an isolated in-memory cloned session.
## Completely read-only with respect to the source session (zero mutation / side-effects).

## 執行離線推演模擬（例如 1小時、24小時、7天等）
static func run_offline_projection(session: GameSession, simulated_seconds: float) -> Dictionary:
	if session == null or session.state == null or session.content == null:
		return {"ok": false, "error": "SESSION_OR_STATE_NULL"}
	if simulated_seconds <= 0.0 or is_nan(simulated_seconds) or is_inf(simulated_seconds):
		return {"ok": false, "error": "INVALID_SIMULATED_SECONDS"}

	var sim_session := clone_session(session)
	if sim_session == null:
		return {"ok": false, "error": "SESSION_CLONE_FAILED"}

	var original_state := session.state
	var content := session.content

	# 1. 記錄起始快照指標
	var start_elapsed := original_state.total_elapsed_seconds
	var start_training := original_state.training_seconds
	var start_revision := original_state.revision
	var start_resources := {}
	for rid in original_state.resources:
		var entry: Dictionary = original_state.resources[rid]
		var val: AmountCompat = entry.get("value", AmountCompat.zero())
		start_resources[rid] = val.duplicate_amount()

	var start_buffs := BuffSystem.get_active_buffs_view(original_state)
	var start_fortune_cd: float = float(original_state.fortune.get("cooldown_remaining", 0.0))
	var start_sect_expeditions: Array = (original_state.sect.get("expeditions", []) as Array).duplicate(true)
	var start_beast_cd: float = float(original_state.beasts.get("cooldown_remaining", 0.0))

	# 計算壽元上限
	var multipliers := TalentSystem.compute_multipliers(original_state)
	var buff_multipliers := BuffSystem.compute_multipliers(original_state)
	var pill_lifespan_bonus := float(original_state.pill_effects.get("lifespan_bonus_years", 0.0)) + float(buff_multipliers.lifespan_bonus_years)
	var max_lifespan_sec := float(Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), original_state.era_id, float(multipliers.lifespan_bonus), pill_lifespan_bonus))
	var initial_remaining_lifespan := maxf(0.0, max_lifespan_sec - start_elapsed)

	# 2. 執行推進（分批或單次調用 GameSession.advance_time）
	var benchmark_start_msec := Time.get_ticks_usec()
	var advance_result := sim_session.advance_time(simulated_seconds)
	var benchmark_duration_usec := Time.get_ticks_usec() - benchmark_start_msec

	var sim_state := sim_session.state
	var ticks_executed: int = int(advance_result.get("ticks_advanced", 0))
	var stopped_reason = advance_result.get("stopped", null)
	var actual_advanced_seconds := float(ticks_executed) * float(TimeAdvancer.SECONDS_PER_TICK)

	# 3. 計算終態與產銷指標
	var end_elapsed := sim_state.total_elapsed_seconds
	var end_remaining_lifespan := maxf(0.0, max_lifespan_sec - end_elapsed)
	var lifespan_consumed_years := (actual_advanced_seconds) / 60.0

	# 取得終態倉容與產量
	var end_caps := Production.compute_caps(content, sim_state.buildings, sim_state.era_id, sim_state.onboarding_version)
	var resource_deltas := {}

	for rid in sim_state.resources:
		var start_amt: AmountCompat = start_resources.get(rid, AmountCompat.zero())
		var cur_entry: Dictionary = sim_state.resources[rid]
		var end_amt: AmountCompat = cur_entry.get("value", AmountCompat.zero())
		var cap_amt: AmountCompat = end_caps.get(rid, AmountCompat.zero())
		var is_unlocked: bool = bool(cur_entry.get("unlocked", false))

		var delta_amt := end_amt.subtract(start_amt)
		var is_capped := cap_amt.compare_to(AmountCompat.zero()) > 0 and end_amt.add(AmountCompat.from_number(0.0001)).compare_to(cap_amt) >= 0

		resource_deltas[rid] = {
			"unlocked": is_unlocked,
			"start_amount": start_amt.serialize(),
			"end_amount": end_amt.serialize(),
			"delta_amount": delta_amt.serialize(),
			"cap_amount": cap_amt.serialize(),
			"is_capped": is_capped,
		}

	# 4. 子系統事件推演結算
	var expired_buffs := []
	for b in start_buffs:
		var b_id := String(b.get("id", ""))
		var cur_b: Dictionary = sim_state.buffs.get(b_id, {})
		if cur_b.is_empty() or float(cur_b.get("remaining_seconds", 0.0)) <= 0.0:
			expired_buffs.append(b_id)

	var sect_completed_expeditions := 0
	var sim_expeditions: Array = sim_state.sect.get("expeditions", [])
	for exp in sim_expeditions:
		if exp is Dictionary and bool(exp.get("completed", false)):
			sect_completed_expeditions += 1

	var beast_cd_ready := start_beast_cd > 0.0 and float(sim_state.beasts.get("cooldown_remaining", 0.0)) <= 0.0
	var fortune_pending: bool = not (sim_state.fortune.get("pending_encounter", {}) as Dictionary).is_empty()
	var fortune_ready := (start_fortune_cd > 0.0 and float(sim_state.fortune.get("cooldown_remaining", 0.0)) <= 0.0) or fortune_pending

	return {
		"ok": true,
		"simulated_requested_seconds": simulated_seconds,
		"actual_advanced_seconds": actual_advanced_seconds,
		"ticks_advanced": ticks_executed,
		"stopped_reason": stopped_reason,
		"benchmark_duration_ms": float(benchmark_duration_usec) / 1000.0,
		"lifespan": {
			"max_lifespan_sec": max_lifespan_sec,
			"initial_remaining_sec": initial_remaining_lifespan,
			"end_remaining_sec": end_remaining_lifespan,
			"consumed_years": lifespan_consumed_years,
			"is_exhausted": stopped_reason == "lifespan_exhausted",
		},
		"resources": resource_deltas,
		"subsystems": {
			"expired_buffs": expired_buffs,
			"sect_completed_expeditions": sect_completed_expeditions,
			"beast_cd_ready": beast_cd_ready,
			"fortune_ready": fortune_ready,
		},
		"training": {
			"start_training_sec": start_training,
			"end_training_sec": sim_state.training_seconds,
			"delta_training_sec": sim_state.training_seconds - start_training,
		}
	}

## 極限推演壓力測試（支援最高 30 天或推至壽元極限）
static func run_stress_test(session: GameSession, max_seconds: float = 30 * 86400.0) -> Dictionary:
	if session == null or session.state == null:
		return {"ok": false, "error": "SESSION_OR_STATE_NULL"}

	var sim_session := clone_session(session)
	if sim_session == null:
		return {"ok": false, "error": "SESSION_CLONE_FAILED"}

	var start_benchmark := Time.get_ticks_usec()
	var proj := run_offline_projection(sim_session, max_seconds)
	var end_benchmark := Time.get_ticks_usec()

	if not bool(proj.get("ok", false)):
		return proj

	# 在推演後的終態執行全面健康檢測
	var health := RuntimeInspector.inspect_health(sim_session)
	var duration_ms: float = float(end_benchmark - start_benchmark) / 1000.0

	return {
		"ok": true,
		"stress_requested_seconds": max_seconds,
		"actual_advanced_seconds": proj.actual_advanced_seconds,
		"ticks_advanced": proj.ticks_advanced,
		"stopped_reason": proj.stopped_reason,
		"benchmark_duration_ms": duration_ms,
		"healthy": bool(health.healthy),
		"issues": health.issues,
		"projection_summary": proj,
	}

## 格式化文字報告
static func format_projection_report(result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "【推演失敗】錯誤代碼：%s" % str(result.get("error", "UNKNOWN"))

	var lines: Array[String] = []
	lines.append("==================================================")
	lines.append("       【離線數值推演與沙盒分析報告】")
	lines.append("==================================================")
	
	var req_sec: float = float(result.get("simulated_requested_seconds", 0.0))
	var act_sec: float = float(result.get("actual_advanced_seconds", 0.0))
	var stopped = result.get("stopped_reason", null)
	var bench_ms: float = float(result.get("benchmark_duration_ms", 0.0))
	
	lines.append("請求快進時長: %s (%.0f 秒)" % [_fmt_duration(req_sec), req_sec])
	lines.append("實際推進時長: %s (%.0f 秒, %d ticks)" % [_fmt_duration(act_sec), act_sec, int(result.get("ticks_advanced", 0))])
	if stopped != null:
		lines.append("提前停止原因: %s" % str(stopped))
	lines.append("推演運算耗時: %.2f ms" % bench_ms)
	lines.append("--------------------------------------------------")

	var ls: Dictionary = result.get("lifespan", {})
	lines.append("[壽元分析]")
	lines.append("  消耗壽元: %.2f 年" % float(ls.get("consumed_years", 0.0)))
	lines.append("  剩餘壽元: %.1f 年 (%.0f 秒)" % [float(ls.get("end_remaining_sec", 0.0)) / 60.0, float(ls.get("end_remaining_sec", 0.0))])
	if bool(ls.get("is_exhausted", false)):
		lines.append("  ⚠️ 警告: 推演期間壽元已自然耗盡！")

	lines.append("--------------------------------------------------")
	lines.append("[資源產銷與滿倉狀況]")
	var res_dict: Dictionary = result.get("resources", {})
	var capped_count := 0
	for rid in res_dict:
		var r: Dictionary = res_dict[rid]
		if not bool(r.get("unlocked", false)):
			continue
		var is_capped: bool = bool(r.get("is_capped", false))
		if is_capped:
			capped_count += 1
		var start_val: AmountCompat = AmountCompat.try_parse(String(r.get("start_amount", "0"))).value
		var end_val: AmountCompat = AmountCompat.try_parse(String(r.get("end_amount", "0"))).value
		var delta_val: AmountCompat = AmountCompat.try_parse(String(r.get("delta_amount", "0"))).value
		var cap_val: AmountCompat = AmountCompat.try_parse(String(r.get("cap_amount", "0"))).value
		
		var cap_tag := " [已滿倉]" if is_capped else ""
		lines.append("  - %-12s: %s -> %s (增量: +%s / 上限: %s)%s" % [
			rid,
			start_val.to_display_string(),
			end_val.to_display_string(),
			delta_val.to_display_string(),
			cap_val.to_display_string(),
			cap_tag
		])
	if capped_count > 0:
		lines.append("  ⚠️ 共有 %d 項資源已達倉容上限，後續產量將溢出浪費。" % capped_count)

	lines.append("--------------------------------------------------")
	var subs: Dictionary = result.get("subsystems", {})
	lines.append("[子系統結算狀況]")
	var expired: Array = subs.get("expired_buffs", [])
	lines.append("  BUFF 到期數量: %d 項%s" % [expired.size(), (" (" + ", ".join(expired) + ")") if not expired.is_empty() else ""])
	lines.append("  宗門完成派遣: %d 項" % int(subs.get("sect_completed_expeditions", 0)))
	lines.append("  靈獸餵養冷卻: %s" % ("已就緒" if bool(subs.get("beast_cd_ready", false)) else "未就緒/未出戰"))
	lines.append("  機緣冷卻狀況: %s" % ("已冷卻完畢" if bool(subs.get("fortune_ready", false)) else "無冷卻/未就緒"))
	lines.append("==================================================")

	return "\n".join(lines)

## 深拷貝獨立 GameSession（透過 duplicate_state 與複製時鐘，100% 記憶體隔離）
static func clone_session(source: GameSession) -> GameSession:
	if source == null or source.state == null or source.content == null:
		return null
	var sim_session := GameSession.new()
	sim_session.content = source.content
	sim_session.clock = GameClock.create(source.clock.now() if source.clock != null else 0.0)
	sim_session.state = source.state.duplicate_state()
	return sim_session

static func _fmt_duration(seconds: float) -> String:
	if seconds >= 86400.0:
		return "%.1f 天" % (seconds / 86400.0)
	if seconds >= 3600.0:
		return "%.1f 小時" % (seconds / 3600.0)
	return "%d 分鐘" % int(seconds / 60.0)
