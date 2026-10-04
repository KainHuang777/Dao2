class_name OfflineCoordinator
extends RefCounted

static func settle(now_utc_ms: int) -> Dictionary:
	var state: Variant = SaveManager.load_state()
	if state == null:
		return {"ok": false, "report": {}, "error": "NO_STATE", "committed": false, "state": null}
	var content: Variant = SaveManager.content()
	if content == null:
		return {"ok": false, "report": {}, "error": "NO_CONTENT", "committed": false, "state": null}
	var last_settled: int = SaveManager.last_settled_utc_ms()
	return settle_state(state, content, now_utc_ms, last_settled)

static func settle_state(state: GameState, content: GameContent, now_utc_ms: int, last_settled: int) -> Dictionary:
	# Also used for live background recovery; the source is unchanged on failure.
	var working: GameState = state.duplicate_state()
	var settlement: Dictionary = OfflineSettlement.settle(working, content, now_utc_ms, last_settled)
	return _commit(state, working, settlement, now_utc_ms)

static func _commit(state: GameState, working: GameState, settlement: Dictionary, now_utc_ms: int) -> Dictionary:
	var report: Dictionary = settlement["report"]
	if bool(report["rollback"]):
		return {"ok": true, "report": report, "error": "", "committed": false, "state": state}
	working.revision += 1
	var sim_tick: int = int(floor(working.total_elapsed_seconds / float(TimeAdvancer.SECONDS_PER_TICK)))
	var meta: Dictionary = {
		"save_id": "local",
		"saved_at_utc_ms": str(now_utc_ms),
		"settled_until_utc_ms": str(now_utc_ms),
		"sim_tick": str(sim_tick),
		"last_offline_report": report,
	}
	var save_result: Dictionary = SaveManager.save(working, meta)
	if not bool(save_result.get("ok", false)):
		return {"ok": false, "report": report, "error": "SAVE_FAILED", "detail": save_result.get("error", ""), "committed": false, "state": state}
	return {"ok": true, "report": report, "error": "", "committed": true, "state": working}

static func settle_async(now_utc_ms: int, tree: SceneTree, progress: Callable = Callable()) -> Dictionary:
	var state: GameState = SaveManager.load_state()
	if state == null:
		return {"ok": false, "error": "NO_STATE", "state": null}
	return await settle_state_async(state, SaveManager.content(), now_utc_ms, SaveManager.last_settled_utc_ms(), tree, progress)

static func settle_state_async(state: GameState, content: GameContent, now_utc_ms: int, last_settled: int, tree: SceneTree, progress: Callable = Callable()) -> Dictionary:
	var working := state.duplicate_state()
	var settlement := await compute_async(working, content, now_utc_ms, last_settled, tree, progress)
	return _commit(state, working, settlement, now_utc_ms)

static func compute_async(state: GameState, content: GameContent, now_utc_ms: int, last_settled_utc_ms: int, tree: SceneTree, progress: Callable = Callable()) -> Dictionary:
	var p := OfflineSettlement.plan(now_utc_ms, last_settled_utc_ms)
	var away_ms: int = int(p["away_ms"])
	var effective_ms: int = int(p["effective_ms"])
	var carry := state.tick_remainder_seconds
	var away_seconds := float(away_ms) / 1000.0
	var effective_seconds := float(effective_ms) / 1000.0
	var away_ticks := TimeAdvancer.ticks_for_elapsed(carry + away_seconds)
	var full_ticks := TimeAdvancer.ticks_for_elapsed(carry + effective_seconds)
	var time_only_ticks := maxi(0, away_ticks - full_ticks)
	var stopped = null
	if full_ticks > 0:
		var result: Dictionary = await _advance_yielding(state, content, full_ticks, tree, progress)
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

# Wall-clock budget controls only yielding, never simulation results.
static func _advance_yielding(state: GameState, content: GameContent, ticks: int, tree: SceneTree, progress: Callable) -> Dictionary:
	if state.economy.is_empty():
		# Preserve legacy aggregate semantics until its own event-boundary refactor.
		await tree.process_frame
		return TimeAdvancer.advance(state, content, ticks)
	var executed := 0
	var stopped: Variant = null
	var budget := FrameBudget.new()
	var prepared := TimeAdvancer.prepare_advance(state, content)
	while executed < ticks and stopped == null:
		budget.begin()
		while executed < ticks and budget.has_time():
			var result := TimeAdvancer.advance(state, content, 1, prepared)
			executed += int(result.ticks_advanced)
			stopped = result.stopped
			if stopped != null or int(result.ticks_advanced) == 0:
				break
		if progress.is_valid():
			progress.call(executed, ticks)
		await tree.process_frame
		if stopped != null:
			break
	return {"ticks_advanced": executed, "stopped": stopped}
