extends SceneTree
const FIXTURE_PATH := "res://docs/verification/artifacts/res1-c2-offline-fixture.json"
const SETTLE_NOW_MS := 172900000
const SETTLE_LAST_MS := 100000
const RELOAD_AWAY_MS := 11000
const EXPECTED_TICKS := 86400
const FORCED_LIFESPAN_BONUS_YEARS := 100000.0

func _initialize() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string(FIXTURE_PATH))
	if not decoded.ok:
		quit(1)
		return
	var state: GameState = decoded.state
	var session := GameSession.new()
	session.content = content
	session.state = state
	session.clock = GameClock.create(state.total_elapsed_seconds)
	state.pill_effects["lifespan_bonus_years"] = FORCED_LIFESPAN_BONUS_YEARS
	var forced_max_seconds := _forced_max_seconds(state, content)
	print("PROBE_LIFESPAN_FORCED=1")
	print("PROBE_MAX_SECONDS=%d" % int(forced_max_seconds))
	print("PROBE_HEADROOM_TICKS=%d" % maxi(0, int(ceil(forced_max_seconds - float(state.total_elapsed_seconds)))))
	var working: GameState = state.duplicate_state()
	var offline: GameState = state.duplicate_state()
	var age_before := float(offline.total_elapsed_seconds)
	var settle_start := Time.get_ticks_usec()
	var settlement: Dictionary = OfflineSettlement.settle(offline, content, SETTLE_NOW_MS, SETTLE_LAST_MS)
	var settle_us := Time.get_ticks_usec() - settle_start
	var report: Dictionary = settlement["report"]
	var planned_ticks := int(report["effective_ticks"])
	var stopped: Variant = settlement["stopped"]
	print("OFFLINE_CPU_86400: %.3f ticks=%d" % [float(settle_us) / 1000.0, planned_ticks])
	if stopped == null or str(stopped) == "":
		print("OFFLINE_CPU_86400_FULL: %.3f" % (float(settle_us) / 1000.0))
	else:
		var headroom_ticks := maxi(0, int(ceil(forced_max_seconds - age_before)))
		var executed_estimate := mini(planned_ticks, headroom_ticks)
		print("OFFLINE_CPU_86400_STOPPED: reason=%s executed=%d" % [str(stopped), executed_estimate])
	var advance_start := Time.get_ticks_usec()
	var advance_result: Dictionary = TimeAdvancer.advance(working, content, EXPECTED_TICKS)
	var advance_us := Time.get_ticks_usec() - advance_start
	print("ADVANCE_86400_COARSE: %.3f executed=%d stopped=%s" % [float(advance_us) / 1000.0, int(advance_result["ticks_advanced"]), str(advance_result["stopped"])])
	var reload_start := Time.get_ticks_usec()
	OfflineSettlement.settle(offline, content, SETTLE_NOW_MS + RELOAD_AWAY_MS, SETTLE_NOW_MS)
	var reload_us := Time.get_ticks_usec() - reload_start
	print("OFFLINE_CPU_RELOAD: %.3f" % (float(reload_us) / 1000.0))
	if planned_ticks != EXPECTED_TICKS:
		print("WARN: effective_ticks=%d" % planned_ticks)
	print("PROBE_DONE=1")
	quit(0)

func _forced_max_seconds(state: GameState, content: GameContent) -> float:
	var talent := TalentSystem.compute_multipliers(state)
	var buffs := BuffSystem.compute_multipliers(state)
	var pill_bonus := float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + float(buffs.get("lifespan_bonus_years", 0.0))
	return float(Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id, float(talent.get("lifespan_bonus", 0.0)), pill_bonus))
