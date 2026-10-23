extends SceneTree
var checks := 0
var failures: Array[String] = []
const FIXTURE_PATH := "res://docs/verification/artifacts/res1-c2-offline-fixture.json"
const LAST_MS := 100000
const DURATIONS := [850, 600000, 172800000]
const BIG_MS := 172800000
const FORCED_LIFESPAN_BONUS_YEARS := 100000.0

func _init() -> void:
	call_deferred("_run")

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func snapshot(state: GameState) -> String:
	var data := state.to_snapshot_dict()
	var ledger: Dictionary = data.get("life_ledger", {})
	if not ledger.is_empty():
		ledger.current.erase("accounts")
		for life in ledger.archive: life.erase("accounts")
	return JSON.stringify(SaveCodec._normalize_numbers(data), "", true)

func _prepare(state: GameState) -> void:
	state.tick_remainder_seconds = 0.4
	state.pill_effects["lifespan_bonus_years"] = FORCED_LIFESPAN_BONUS_YEARS

func manual_settle(state: GameState, content: GameContent, now_utc_ms: int, last_settled_utc_ms: int) -> Dictionary:
	var p := OfflineSettlement.plan(now_utc_ms, last_settled_utc_ms)
	var away_ms: int = int(p["away_ms"])
	var effective_ms: int = int(p["effective_ms"])
	var carry := state.tick_remainder_seconds
	var away_seconds := float(away_ms) / 1000.0
	var effective_seconds := float(effective_ms) / 1000.0
	var away_ticks := TimeAdvancer.ticks_for_elapsed(carry + away_seconds)
	var full_ticks := TimeAdvancer.ticks_for_elapsed(carry + effective_seconds)
	var time_only_ticks := maxi(0, away_ticks - full_ticks)
	var stopped: Variant = null
	if full_ticks > 0:
		var result: Dictionary = TimeAdvancer.advance(state, content, full_ticks)
		stopped = result["stopped"]
		if stopped == null and time_only_ticks > 0:
			var time_only_result: Dictionary = TimeAdvancer.advance_time_only(state, content, time_only_ticks)
			stopped = time_only_result["stopped"]
	elif time_only_ticks > 0:
		var time_only_result: Dictionary = TimeAdvancer.advance_time_only(state, content, time_only_ticks)
		stopped = time_only_result["stopped"]
	if away_ms > 0:
		state.tick_remainder_seconds = 0.0 if stopped != null else maxf(0.0, carry + away_seconds - float(away_ticks) * float(TimeAdvancer.SECONDS_PER_TICK))
	var report := {
		"left_at_utc_ms": last_settled_utc_ms,
		"settled_at_utc_ms": now_utc_ms,
		"away_ms": away_ms,
		"effective_ms": effective_ms,
		"forfeited_ms": int(p["forfeited_ms"]),
		"effective_ticks": full_ticks,
		"time_only_ticks": time_only_ticks,
		"cap_applied": bool(p["cap_applied"]),
		"rollback": bool(p["rollback"]),
		"bootstrap": bool(p["bootstrap"]),
		"age_seconds": float(state.total_elapsed_seconds),
		"stopped": stopped,
		"report_id": "offline:" + str(now_utc_ms),
	}
	return {"report": report, "stopped": stopped}

func _run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string(FIXTURE_PATH))
	expect(bool(decoded.ok), "fixture decode")
	if not bool(decoded.ok):
		for label in failures:
			push_error(label)
		quit(1)
		return
	var fixture: GameState = decoded.state
	var closed_form_ms := 0.0
	var reference_ms := 0.0
	for duration in DURATIONS:
		var now_ms: int = LAST_MS + int(duration)
		var is_big: bool = int(duration) == BIG_MS
		var state_a: GameState = fixture.duplicate_state()
		_prepare(state_a)
		var state_b: GameState = fixture.duplicate_state()
		_prepare(state_b)
		var t0: int = Time.get_ticks_usec() if is_big else 0
		var settlement_a: Dictionary = OfflineSettlement.settle(state_a, content, now_ms, LAST_MS)
		if is_big:
			closed_form_ms = float(Time.get_ticks_usec() - t0) / 1000.0
			t0 = Time.get_ticks_usec()
		var settlement_b: Dictionary = manual_settle(state_b, content, now_ms, LAST_MS)
		if is_big:
			reference_ms = float(Time.get_ticks_usec() - t0) / 1000.0
		expect(ResourceLedger.equivalent(state_a.life_ledger.current.get("accounts", {}), state_b.life_ledger.current.get("accounts", {})), "resource Amount parity " + str(duration))
		expect(snapshot(state_a) == snapshot(state_b), "closed form snapshot equality " + str(duration))
		expect(bool(settlement_a["report"] == settlement_b["report"]), "closed form report equality " + str(duration))
	var det_a: GameState = fixture.duplicate_state()
	_prepare(det_a)
	var det_b: GameState = fixture.duplicate_state()
	_prepare(det_b)
	var det_settle_a: Dictionary = OfflineSettlement.settle(det_a, content, LAST_MS + 600000, LAST_MS)
	var det_settle_b: Dictionary = OfflineSettlement.settle(det_b, content, LAST_MS + 600000, LAST_MS)
	expect(snapshot(det_a) == snapshot(det_b), "determinism snapshot equality")
	expect(bool(det_settle_a["report"] == det_settle_b["report"]), "determinism report equality")
	var state_c: GameState = fixture.duplicate_state()
	_prepare(state_c)
	state_c.buffs["breakthrough_resonance"]["remaining_seconds"] = 90.5
	var state_d: GameState = fixture.duplicate_state()
	_prepare(state_d)
	state_d.buffs["breakthrough_resonance"]["remaining_seconds"] = 90.5
	OfflineSettlement.settle(state_c, content, LAST_MS + 600000, LAST_MS)
	manual_settle(state_d, content, LAST_MS + 600000, LAST_MS)
	expect(snapshot(state_c) == snapshot(state_d), "non-integer buff fallback parity")
	print("CLOSED_FORM_MS=%.3f REFERENCE_MS=%.3f" % [closed_form_ms, reference_ms])
	if failures.is_empty():
		print("PASS: OFFLINE_CLOSED_FORM_PARITY ", checks, " checks")
		quit(0)
	else:
		for label in failures:
			push_error(label)
		quit(1)
