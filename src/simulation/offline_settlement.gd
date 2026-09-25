class_name OfflineSettlement
extends RefCounted

const CAP_MS := 86400000

static func plan(now_utc_ms: int, last_settled_utc_ms: int) -> Dictionary:
	if last_settled_utc_ms <= 0:
		return {
			"away_ms": 0,
			"effective_ms": 0,
			"forfeited_ms": 0,
			"cap_applied": false,
			"rollback": false,
			"bootstrap": true,
		}
	if now_utc_ms < last_settled_utc_ms:
		return {
			"away_ms": 0,
			"effective_ms": 0,
			"forfeited_ms": 0,
			"cap_applied": false,
			"rollback": true,
			"bootstrap": false,
		}
	var away := int(now_utc_ms - last_settled_utc_ms)
	var effective := mini(away, CAP_MS)
	var forfeited := int(away - effective)
	return {
		"away_ms": away,
		"effective_ms": effective,
		"forfeited_ms": forfeited,
		"cap_applied": away > CAP_MS,
		"rollback": false,
		"bootstrap": false,
	}

static func settle(state: GameState, content: GameContent, now_utc_ms: int, last_settled_utc_ms: int) -> Dictionary:
	var p := plan(now_utc_ms, last_settled_utc_ms)
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
