extends SceneTree
## Exact tick parity against the unprepared path, including boundary-changing multipliers.
var checks := 0
var failures: Array[String] = []
func _init() -> void:
	call_deferred("_run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
func snapshot(state: GameState) -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(state.to_snapshot_dict()), "", true)
func _run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var source: GameState = SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c2-offline-fixture.json")).state
	for no_op in ["zero_ticks", "exhausted"]:
		var idle := source.duplicate_state()
		idle.beasts = {}
		if no_op == "exhausted":
			idle.total_elapsed_seconds = 999999.0
		var before := snapshot(idle)
		TimeAdvancer.advance(idle, content, 0 if no_op == "zero_ticks" else 1)
		expect(snapshot(idle) == before, no_op + " must not initialize beast state")
	for mode in ["active", "buff_weather", "capacity", "lifespan", "contraction", "sect_beast", "expired_lifespan", "long_offline", "idle_buff", "realm_sink", "home_job"]:
		var slow := source.duplicate_state()
		var ticks := 12000 if mode == "long_offline" else 725
		if mode == "buff_weather":
			ChronoSystem.unlock_chrono(slow)
			BuffSystem.apply_buff(slow, "heaven_qi_surge", 2.5)
			BuffSystem.apply_buff(slow, "insight_glow", 61.0)
			BuffSystem.apply_buff(slow, "longevity_breath")
			slow.total_elapsed_seconds = 355.5
		if mode == "capacity":
			for id in slow.resources:
				slow.resources[id].value = AmountCompat.from_number(10000)
		if mode == "lifespan":
			slow.total_elapsed_seconds = 11998.5
		if mode == "contraction":
			ChronoSystem.unlock_chrono(slow)
			slow.total_elapsed_seconds = 1438.5 # Earth capacity -> metal on the second tick.
			for id in slow.resources:
				slow.resources[id].value = AmountCompat.from_number(345.125)
		if mode == "sect_beast":
			slow.sect = {"unlocked": true, "techniques": {"divine_farm": 2, "breathing_method": 3, "storage_talisman": 2, "essence_array": 2}}
			slow.beasts = {"active": {"id": "iron_turtle", "stage": "mature", "exp": 1000}, "cooldown_remaining": 2.5}
			slow.beast_talents = {"turtle_t4_passive": 1}
			ChronoSystem.unlock_chrono(slow)
		if mode == "expired_lifespan":
			slow.total_elapsed_seconds = 11999.5
			BuffSystem.apply_buff(slow, "temporary_life", 1.5, {"lifespan_bonus_years": 1.0})
		if mode == "idle_buff":
			TimeAdvancer.advance(slow, content, 2000)
			ChronoSystem.unlock_chrono(slow)
			BuffSystem.apply_buff(slow, "heaven_qi_surge", 90.5)
			BuffSystem.apply_buff(slow, "idle_production", 180.5, {"specific_resource_multiplier": {"wood": 0.75}})
		if mode == "realm_sink":
			TimeAdvancer.advance(slow, content, 2000)
			slow.realms_data.realm_spirit.outposts = {"celestial_hub": 3, "pure_pool": 3, "void_beacon": 1}
		if mode == "home_job":
			slow.economy.version = IslandEconomy.VERSION
			slow.economy.jobs.home = {"recipe_id": "spirit_timber", "recipe_version": 1, "remaining": 0, "batches": 0, "repeat": true, "reserves": {}, "status": "ready"}
		var fast := slow.duplicate_state()
		var chunked := slow.duplicate_state()
		var events: Array = []
		var executed := 0
		var stopped: Variant = null
		for tick in ticks:
			# Old one-second algorithm without invariant caches.
			var old := TimeAdvancer._advance_legacy(slow, content, 1)
			if old.ticks_advanced > 0:
				executed += 1
				events.append_array(IslandEconomy.tick(slow, content.processing_catalog))
			events.append_array(old.events)
			stopped = old.stopped
			if stopped != null:
				break
		var result := TimeAdvancer.advance(fast, content, ticks)
		expect(snapshot(fast) == snapshot(slow), mode + " exact snapshot / RNG / cargo / reservations")
		expect(events == result.events and executed == result.ticks_advanced and stopped == result.stopped, mode + " event order / lifespan")
		var prepared := TimeAdvancer.prepare_advance(chunked, content)
		var chunked_events: Array = []
		for tick in ticks:
			chunked_events.append_array(TimeAdvancer.advance(chunked, content, 1, prepared).events)
		expect(snapshot(chunked) == snapshot(fast), "shared async preparation " + mode)
		expect(chunked_events == events, "single tick fast path preserves event order " + mode)
		if mode == "long_offline":
			expect(int(prepared.economy.get("idle_ticks", 0)) > 0, "long run actually exercises stationary economy shortcut")
	# A home stock sink must wake blocked routes even within shared preparation.
	var idle := source.duplicate_state()
	TimeAdvancer.advance(idle, content, 2000)
	var idle_prepared := TimeAdvancer.prepare_advance(idle, content)
	TimeAdvancer.advance(idle, content, 10, idle_prepared)
	expect(idle_prepared.economy.has("idle_home"), "stationary economy detected")
	idle.resources.spirit_timber.value = AmountCompat.zero()
	var woken := idle.duplicate_state()
	var woke := TimeAdvancer.advance(idle, content, 1, idle_prepared)
	var wake_old := TimeAdvancer._advance_legacy(woken, content, 1)
	var wake_events := IslandEconomy.tick(woken, content.processing_catalog)
	wake_events.append_array(wake_old.events)
	expect(snapshot(idle) == snapshot(woken) and woke.events == wake_events, "home stock sink invalidates stationary cache")
	expect(idle.economy.trips.has("timber_home"), "blocked route departs immediately after stock sink")
	# A new settlement must rebuild invariants after a facility/building command.
	var changed := source.duplicate_state()
	TimeAdvancer.advance(changed, content, 5)
	changed.buildings.hut = int(changed.buildings.hut) + 1
	var reference := changed.duplicate_state()
	TimeAdvancer.advance(changed, content, 1)
	TimeAdvancer._advance_legacy(reference, content, 1)
	IslandEconomy.tick(reference, content.processing_catalog)
	expect(snapshot(changed) == snapshot(reference), "new settlement refreshes building invariants")
	# Godot coverage and metrics stay independent of installed system fonts.
	for pair in [[UiTypography.BASE_FONT, "res://assets/fonts/SourceHanSansTW-VF.ttf"], [UiTypography.CHAPTER_FONT, "res://assets/fonts/NotoSerifTC-VF.ttf"]]:
		var derived: FontFile = pair[0]
		derived.allow_system_fallback = false
		var original: FontFile = load(pair[1])
		for text in ["練氣築基・青木玄礦・壽元修煉", "銅精靈材・航線吞吐・庫容", "0123456789 +1.25/s"]:
			for index in text.length():
				var code: int = text.unicode_at(index)
				expect(derived.has_char(code), "runtime glyph " + String.chr(code))
			expect(derived.get_string_size(text) == original.get_string_size(text), "runtime font metrics " + text)
	if failures.is_empty():
		print("PASS: RES1-C2-PERF ", checks, " exact tick/font checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
