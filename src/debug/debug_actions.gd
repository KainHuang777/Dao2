class_name DebugActions
extends RefCounted
## DEBUG-only state manipulation. Pure logic over GameSession; no UI or persistence.
## Every action returns {"ok": bool, "msg": String}. Callers save/refresh afterwards.

const RES_STEP_AMOUNTS := [1000.0, 100000.0, 10000000.0]
const SECT_CONTRIBUTION_STEP := 1000.0
const BEAST_SOUL_STEP := 10
const WARP_SECONDS_LIMIT := 7 * 86400.0

static func run(action_id: String, params: Dictionary, session: GameSession) -> Dictionary:
	if session == null or session.state == null:
		return _fail("沒有進行中的遊戲 Session")
	match action_id:
		"era_step":
			return era_step(session, int(params.get("delta", 1)))
		"res_add":
			return res_add(session, float(params.get("amount", 1000.0)))
		"res_fill":
			return res_fill_to_cap(session)
		"res_clear":
			return res_clear(session)
		"sect_open":
			return sect_open(session)
		"sect_refresh":
			return sect_refresh(session)
		"sect_finish":
			return sect_finish_expedition(session)
		"sect_contribution":
			return sect_add_contribution(session, float(params.get("amount", SECT_CONTRIBUTION_STEP)))
		"beast_acquire":
			return beast_acquire(session, String(params.get("beast_id", "")))
		"beast_mature":
			return beast_mature(session)
		"beast_souls":
			return beast_add_souls(session, int(params.get("amount", BEAST_SOUL_STEP)))
		"beast_cooldown":
			return beast_clear_cooldown(session)
		"chrono_unlock":
			return chrono_unlock(session)
		"chrono_next_shichen":
			return chrono_advance_to_next(session, ChronoSystem.SECONDS_PER_SHICHEN)
		"chrono_next_weather":
			return chrono_advance_to_next(session, ChronoSystem.WEATHER_CYCLE_SECONDS)
		"fortune_trigger":
			return fortune_trigger(session)
		"time_warp":
			return time_warp(session, float(params.get("seconds", 3600.0)))
		"inspect_health":
			return inspect_health_action(session)
		"inspect_prod":
			return inspect_prod_action(session)
		"sim_offline":
			return sim_offline_action(session, float(params.get("seconds", 86400.0)))
		"sim_stress":
			return sim_stress_action(session, float(params.get("seconds", 30 * 86400.0)))
	return _fail("未知的 DEBUG 動作：%s" % action_id)

## 境界：上一／下一個已配置 Era；重置層級與修煉進度（與輪迴／突破不同，不發獎勵）。
static func era_step(session: GameSession, delta: int) -> Dictionary:
	var state := session.state
	var ids: Array = session.content.era_ids
	var idx := ids.find(state.era_id)
	if idx < 0:
		return _fail("當前境界 %d 不在內容設定中" % state.era_id)
	var target := clampi(idx + delta, 0, ids.size() - 1)
	if target == idx:
		return _fail("已是%s境界" % ("最高" if delta > 0 else "最低"))
	state.era_id = int(ids[target])
	state.level = 1
	state.training_seconds = 0.0
	state.highest_era = maxi(state.highest_era, state.era_id)
	return _ok("境界跳轉至 Era %d（%s），層級重置為 LV1" % [state.era_id, _era_name(session, state.era_id)])

static func res_add(session: GameSession, amount: float) -> Dictionary:
	var add_amt := AmountCompat.from_number(amount)
	for r_id in session.state.resources:
		var entry: Dictionary = session.state.resources[r_id]
		entry.value = entry.value.add(add_amt)
		entry.unlocked = true
		entry.ever_obtained = true
	return _ok("全部基礎資源 +%s" % _fmt(amount))

## 補到「建築基礎容量」；不含天時／靈獸等倍率，僅供快速擺滿倉庫。
static func res_fill_to_cap(session: GameSession) -> Dictionary:
	var state := session.state
	var caps := Production.compute_caps(session.content, state.buildings, state.era_id, state.onboarding_version)
	var filled := 0
	for r_id in state.resources:
		if not caps.has(r_id):
			continue
		var entry: Dictionary = state.resources[r_id]
		var cap: AmountCompat = caps[r_id]
		if entry.value.compare_to(cap) < 0:
			entry.value = cap.duplicate_amount()
			filled += 1
		entry.unlocked = true
		entry.ever_obtained = true
	return _ok("已將 %d 項資源補滿至基礎容量" % filled)

static func res_clear(session: GameSession) -> Dictionary:
	for r_id in session.state.resources:
		session.state.resources[r_id].value = AmountCompat.zero()
	return _ok("全部資源已清零（可測試缺料／瓶頸）")

## 宗門：略過 Era 門檻直接入門並產生任務。
static func sect_open(session: GameSession) -> Dictionary:
	var sect := SectSystem.ensure_sect_state(session.state)
	if bool(sect.get("unlocked", false)):
		return _fail("已加入宗門，可用「刷新任務」")
	sect["unlocked"] = true
	sect["sect_name"] = SectSystem.SECT_NAMES[0]
	SectSystem.refresh_tasks(session.state, true)
	return _ok("已加入「%s」並生成任務" % sect["sect_name"])

static func sect_refresh(session: GameSession) -> Dictionary:
	if not bool(SectSystem.ensure_sect_state(session.state).get("unlocked", false)):
		return _fail("尚未加入宗門，請先使用「加入宗門」")
	var res := SectSystem.refresh_tasks(session.state, true)
	return _ok("宗門任務已強制刷新") if bool(res.get("ok", false)) else _fail(str(res.get("error", "FAIL")))

static func sect_finish_expedition(session: GameSession) -> Dictionary:
	var sect := SectSystem.ensure_sect_state(session.state)
	var active = sect.get("active_expedition")
	if active == null or not (active is Dictionary):
		return _fail("目前沒有進行中的派遣")
	active["elapsed"] = int(active.get("duration", 0))
	return _ok("派遣「%s」已立即完成，可領取獎勵" % String(active.get("name", "")))

static func sect_add_contribution(session: GameSession, amount: float) -> Dictionary:
	var sect := SectSystem.ensure_sect_state(session.state)
	if not bool(sect.get("unlocked", false)):
		return _fail("尚未加入宗門，請先使用「加入宗門」")
	var parsed := AmountCompat.try_parse(String(sect.get("contribution", "0")))
	var cur: AmountCompat = parsed["value"] if bool(parsed.get("ok", false)) else AmountCompat.zero()
	sect["contribution"] = cur.add(AmountCompat.from_number(amount)).serialize()
	return _ok("宗門貢獻 +%s" % _fmt(amount))

## 靈獸：略過 Era 門檻與既有出戰獸，直接換成新的靈卵。
static func beast_acquire(session: GameSession, beast_id: String) -> Dictionary:
	if not BeastSystem.BEAST_CONFIGS.has(beast_id):
		return _fail("未知靈獸：%s" % beast_id)
	BeastSystem.ensure_initialized(session.state)
	session.state.beasts["active"] = {"id": beast_id, "stage": "egg", "exp": 0}
	session.state.beasts["cooldown_remaining"] = 0.0
	return _ok("已獲得靈獸「%s」（靈卵）" % String(BeastSystem.BEAST_CONFIGS[beast_id].name))

static func beast_mature(session: GameSession) -> Dictionary:
	var beast := BeastSystem.get_active_beast(session.state)
	if beast.is_empty():
		return _fail("目前沒有出戰靈獸")
	beast["stage"] = "mature"
	beast["exp"] = int(BeastSystem.STAGE_CONFIGS["growing"].max_exp)
	session.state.beasts["cooldown_remaining"] = 0.0
	return _ok("靈獸已直升成熟期")

static func beast_add_souls(session: GameSession, amount: int) -> Dictionary:
	BeastSystem.ensure_initialized(session.state)
	for beast_id in BeastSystem.BEAST_CONFIGS:
		session.state.beast_souls[beast_id] = int(session.state.beast_souls.get(beast_id, 0)) + amount
	return _ok("四大靈獸獸魂各 +%d" % amount)

static func beast_clear_cooldown(session: GameSession) -> Dictionary:
	BeastSystem.ensure_initialized(session.state)
	session.state.beasts["cooldown_remaining"] = 0.0
	return _ok("餵養冷卻已清除")

## 天時：僅解鎖旗標；時辰與天候由 total_elapsed_seconds 推算，需用時間快進切換。
static func chrono_unlock(session: GameSession) -> Dictionary:
	ChronoSystem.unlock_chrono(session.state)
	return _ok("天時系統已解鎖")

static func chrono_advance_to_next(session: GameSession, cycle_seconds: float) -> Dictionary:
	var remain := cycle_seconds - fmod(session.state.total_elapsed_seconds, cycle_seconds)
	var res := time_warp(session, remain + 1.0)
	if not bool(res.ok):
		return res
	ChronoSystem.tick(session.state, 0.0)
	var shichen := ChronoSystem.get_current_shichen(session.state)
	var weather := ChronoSystem.get_current_weather(session.state)
	return _ok("已推進至 %s・%s（%s）" % [shichen.get("name", ""), weather.get("name", ""), res.msg])

## 強制觸發機緣：由當前 Era 可用奇遇中隨機挑一個為待決（已有待決則拒絕）。
static func fortune_trigger(session: GameSession) -> Dictionary:
	var state := session.state
	FortuneSystem.ensure_initialized(state)
	if not (state.fortune.get("pending_encounter", {}) as Dictionary).is_empty():
		return _fail("已有待決奇遇，請先處理")
	var candidates: Array = []
	for enc in FortuneSystem.get_encounters():
		if state.era_id >= int(enc.get("min_era", 1)):
			candidates.append(enc)
	if candidates.is_empty():
		return _fail("當前境界沒有可用奇遇")
	var chosen: Dictionary = (candidates[randi() % candidates.size()] as Dictionary).duplicate(true)
	state.fortune["pending_encounter"] = chosen
	state.fortune["encounter_history_count"] = int(state.fortune.get("encounter_history_count", 0)) + 1
	state.fortune["cooldown_remaining"] = FortuneSystem.compute_cooldown_for_era(state.era_id)
	return _ok("已觸發奇遇「%s」" % String(chosen.get("title", chosen.get("id", ""))))

## 時間快進：走正式 GameSession.advance_time（含壽元、BUFF、宗門、天時），壽盡會自動停止。
static func time_warp(session: GameSession, seconds: float) -> Dictionary:
	if seconds <= 0.0 or seconds > WARP_SECONDS_LIMIT:
		return _fail("快進秒數須介於 0 與 %d 之間" % int(WARP_SECONDS_LIMIT))
	var res := session.advance_time(seconds)
	var ticks := int(res.get("ticks_advanced", 0))
	var stopped = res.get("stopped", null)
	if stopped != null:
		return _ok("快進 %s，於 %d 秒後停止：%s" % [_fmt_duration(seconds), ticks, str(stopped)])
	return _ok("快進 %s（%d tick）" % [_fmt_duration(seconds), ticks])

static func inspect_health_action(session: GameSession) -> Dictionary:
	var report := RuntimeInspector.generate_report(session)
	print("\n" + report + "\n")
	var health := RuntimeInspector.inspect_health(session)
	var status_text := "【健全 PASS】" if bool(health.healthy) else "【異常 FAIL: %d 項】" % (health.issues as Array).size()
	return {"ok": true, "msg": "診斷完畢：%s (詳見控制台輸出與檢測報告)" % status_text, "report": report, "healthy": bool(health.healthy)}

static func inspect_prod_action(session: GameSession) -> Dictionary:
	var prod := RuntimeInspector.inspect_production(session)
	if not bool(prod.get("ok", false)):
		return _fail("產銷檢測失敗")
	var g_mult: float = float(prod.get("global_multipliers", {}).get("total_combined_global", 1.0))
	var unlocked_count: int = (prod.get("resources", {}) as Dictionary).values().filter(func(r): return bool(r.get("unlocked", false))).size()
	var report := RuntimeInspector.generate_report(session)
	print("\n" + report + "\n")
	return {"ok": true, "msg": "產銷分析完成：全域產率 x%.2f，已解鎖 %d 項資源" % [g_mult, unlocked_count], "report": report}

static func sim_offline_action(session: GameSession, seconds: float) -> Dictionary:
	var proj := SimulationSandbox.run_offline_projection(session, seconds)
	if not bool(proj.get("ok", false)):
		return _fail("推演失敗：%s" % str(proj.get("error", "UNKNOWN")))
	var report := SimulationSandbox.format_projection_report(proj)
	print("\n" + report + "\n")
	var capped_count := 0
	var res_dict: Dictionary = proj.get("resources", {})
	for rid in res_dict:
		if bool(res_dict[rid].get("is_capped", false)):
			capped_count += 1
	var stopped = proj.get("stopped_reason", null)
	var stopped_note := ("（停止：%s）" % str(stopped)) if stopped != null else ""
	return {
		"ok": true,
		"msg": "推演完成（%s）：耗時 %.1fms，滿倉 %d 項%s" % [_fmt_duration(seconds), float(proj.get("benchmark_duration_ms", 0.0)), capped_count, stopped_note],
		"report": report,
		"projection": proj,
	}

static func sim_stress_action(session: GameSession, seconds: float) -> Dictionary:
	var stress := SimulationSandbox.run_stress_test(session, seconds)
	if not bool(stress.get("ok", false)):
		return _fail("壓測失敗：%s" % str(stress.get("error", "UNKNOWN")))
	var summary: Dictionary = stress.get("projection_summary", {})
	var report := SimulationSandbox.format_projection_report(summary)
	print("\n" + report + "\n")
	var is_healthy: bool = bool(stress.get("healthy", false))
	var health_str := "健康無異常" if is_healthy else "⚠️ 發現異常！"
	return {
		"ok": true,
		"msg": "壓測完畢（%s）：終態%s，運算耗時 %.1fms" % [_fmt_duration(seconds), health_str, float(stress.get("benchmark_duration_ms", 0.0))],
		"report": report,
		"stress": stress,
	}

static func _era_name(session: GameSession, era_id: int) -> String:
	var def: Variant = session.content.era(era_id)
	return "?" if def == null else String(def.get("name", "?"))

static func _fmt(value: float) -> String:
	return AmountCompat.from_number(value).to_display_string()

static func _fmt_duration(seconds: float) -> String:
	if seconds >= 3600.0:
		return "%.1f 小時" % (seconds / 3600.0)
	return "%d 分鐘" % int(seconds / 60.0)

static func _ok(msg: String) -> Dictionary:
	return {"ok": true, "msg": msg}

static func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}
