extends SceneTree

# Starts with a real blank GameSession. Every building cost is paid through
# player commands or elapsed production; the test never grants resources.
const LivingAbodeScene = preload("res://scenes/living_abode.tscn")
var failures: Array[String] = []
var command_index := 0
var session: GameSession

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	if not bool(loaded.ok):
		_finish("content did not load: %s" % str(loaded.errors))
		return
	session = GameSession.create_new_game(loaded.content)
	_expect(session.get_view().resources.lingli.value == "0", "blank game has zero lingli")
	_expect(_build("hut"), "blank game can build hut from gathering")
	var rate_one := _amount(session.get_view().resources.lingli.rate)
	_expect(rate_one > 0.0, "hut level 1 creates lingli income")
	var first_second := GameSession.new()
	first_second.content = session.content
	first_second.state = session.state.duplicate_state()
	first_second.clock = GameClock.create(0.0)
	var first_second_before := _amount(first_second.get_view().resources.lingli.value)
	var first_second_result := first_second.advance_time(1.0)
	_expect(int(first_second_result.ticks_advanced) == 1, "one elapsed second executes one production tick")
	_expect(is_equal_approx(_amount(first_second.get_view().resources.lingli.value) - first_second_before, rate_one), "first second deposits the displayed production rate")

	var one_shot := GameSession.new()
	one_shot.content = session.content
	one_shot.state = session.state.duplicate_state()
	one_shot.clock = GameClock.create(0.0)
	one_shot.advance_time(60.0)
	for index in range(240):
		session.advance_time(0.25)
	_expect(session.state.total_elapsed_seconds == 60.0, "240 frame sized advances execute sixty one-second ticks")
	_expect(_amount(session.get_view().resources.lingli.value) > 0.0, "first production minute increases spendable lingli")
	_expect(session.state.level == 1, "time does not auto spend lingli on cultivation")
	_expect(session.state.resources.lingli.value.serialize() == one_shot.state.resources.lingli.value.serialize(), "frame advances match one shot production")
	_expect(_build("hut"), "hut level 2 is affordable from earned lingli")
	var rate_two := _amount(session.get_view().resources.lingli.rate)
	_expect(rate_two > rate_one, "hut upgrade increases lingli production rate")
	var prereq_probe := GameSession.new()
	prereq_probe.content = session.content
	prereq_probe.state = session.state.duplicate_state()
	prereq_probe.clock = GameClock.create(0.0)
	prereq_probe.state.resources.money.value = AmountCompat.from_number(50.0)
	prereq_probe.state.resources.wood.value = AmountCompat.from_number(20.0)
	_expect(bool(prereq_probe.get_view().buildings.storage_lingli.visible) and not bool(prereq_probe.get_view().buildings.storage_lingli.affordable), "storage_lingli stays disabled even when affordable by inventory but prerequisite is missing")

	var probe := GameSession.new()
	probe.content = session.content
	probe.state = session.state.duplicate_state()
	probe.clock = GameClock.create(0.0)
	probe.state.tick_remainder_seconds = 0.0
	probe.advance_time(0.25)
	var encoded := SaveCodec.encode(probe.state, session.content.content_version, {
		"save_id": "positive-flow", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "1"
	})
	_expect(bool(encoded.ok), "sub-second save encodes")
	if bool(encoded.ok):
		var old_envelope: Dictionary = JSON.parse_string(String(encoded.json))
		(old_envelope.state as Dictionary).erase("tick_remainder_seconds")
		old_envelope.erase("checksum")
		old_envelope.checksum = SaveCodec.compute_checksum(old_envelope)
		var old_decoded := SaveCodec.decode(JSON.stringify(old_envelope))
		_expect(bool(old_decoded.ok) and old_decoded.state.tick_remainder_seconds == 0.0, "prior saves without remainder load at zero")
		var legacy_envelope: Dictionary = JSON.parse_string(String(encoded.json))
		(legacy_envelope.state as Dictionary).tick_remainder_seconds = 17.25
		legacy_envelope.rules_version = "core-flow-2"
		legacy_envelope.erase("checksum")
		legacy_envelope.checksum = SaveCodec.compute_checksum(legacy_envelope)
		var legacy_decoded := SaveCodec.decode(JSON.stringify(legacy_envelope))
		_expect(bool(legacy_decoded.ok) and is_equal_approx(legacy_decoded.state.tick_remainder_seconds, 17.25), "prior sixty-second carry remains readable")
		if bool(legacy_decoded.ok):
			var legacy_session := GameSession.new()
			legacy_session.content = session.content
			legacy_session.state = legacy_decoded.state
			legacy_session.clock = GameClock.create(0.0)
			var migrated := legacy_session.advance_time(0.75)
			_expect(int(migrated.ticks_advanced) == 18 and legacy_session.state.tick_remainder_seconds == 0.0, "prior carry settles into one-second ticks")
		var decoded := SaveCodec.decode(String(encoded.json))
		_expect(bool(decoded.ok), "partial tick save decodes")
		if bool(decoded.ok):
			var restored := GameSession.new()
			restored.content = session.content
			restored.state = decoded.state
			restored.clock = GameClock.create(0.0)
			_expect(is_equal_approx(restored.state.tick_remainder_seconds, 0.25), "save retains sub-second progress")
			var offline_state: GameState = decoded.state.duplicate_state()
			var tick_result := restored.advance_time(0.75)
			_expect(int(tick_result.ticks_advanced) == 1, "reloaded remainder completes next tick")
			var offline_result := OfflineSettlement.settle(offline_state, session.content, 100750, 100000)
			_expect(offline_state.total_elapsed_seconds == probe.state.total_elapsed_seconds + 1.0, "offline continuation completes saved partial tick")
			_expect(int(offline_result.report.effective_ticks) == 1, "offline report counts carried tick")

	# The button is the actual scene route for the first money required by the house.
	var living_script = preload("res://src/abode/living_abode.gd")
	living_script.save_dir_override = "user://core_positive_flow_saves"
	var slots := SaveSlots.new(FileStorageAdapter.new("user://core_positive_flow_saves"))
	slots.reset()
	var abode = LivingAbodeScene.instantiate()
	root.add_child(abode)
	await process_frame
	abode.session = session
	abode.state = abode.AbodeStateCompat.new(session)
	abode._refresh_hud()
	_expect(abode.realm_label.text.contains("練氣期") and abode._hud_controller._rank_label.text.contains("1/10 層"), "HUD prominently shows the current cultivation era and level")
	_expect(abode.realm_progress_label.text.contains("修煉") and abode._hud_controller._lifespan_text.text.contains("壽元"), "HUD separates training and lifespan into their own rows")
	abode._toggle_building_catalog()
	abode._select_building_from_catalog("storage_lingli")
	_expect(abode.upgrade_button.disabled and abode.upgrade_button.text.contains("靈植場"), "building detail explains missing prerequisite")
	_expect(abode.building_catalog.resource_buttons["money"].visible and abode.building_catalog.resource_buttons["money"] is PanelContainer, "money appears as a passive resource readout after hut")
	_expect(abode.building_catalog.resource_gather_buttons["money"].visible, "money card exposes inline gather action")
	var money_before := _amount(session.get_view().resources.money.value)
	abode.building_catalog.resource_gather_buttons["money"].pressed.emit()
	_expect(_amount(session.get_view().resources.money.value) == money_before + 1.0, "money control sends the gather command")
	abode.queue_free()
	await process_frame
	slots.reset()
	living_script.save_dir_override = ""

	for target in ["wooden_house", "wooden_house", "forest_farm", "forest_farm", "forest_farm", "stone_mine", "stone_mine", "stone_mine", "herb_farm", "herb_farm", "herb_farm", "storage_lingli", "storage_money", "storage_stone", "storage_wood", "storage_herb"]:
		if not _build(target):
			break
	for target in session.content.building_ids:
		_expect(int(session.state.buildings[target]) >= 1, "positive flow reaches %s without injected resources" % target)
	_expect(bool(session.state.resources.black_copper.unlocked), "mine unlocks its black copper output")
	_expect(_amount(session.get_view().resources.black_copper.rate) > 0.0, "mine has black copper production")
	var production_probe := GameSession.new()
	production_probe.content = session.content
	production_probe.state = session.state.duplicate_state()
	production_probe.clock = GameClock.create(0.0)
	for resource_id in ["lingli", "money", "wood", "stone_low", "black_copper", "spirit_grass_low"]:
		production_probe.state.resources[resource_id].value = AmountCompat.zero()
	production_probe.advance_time(60.0)
	for resource_id in ["lingli", "money", "wood", "stone_low", "black_copper", "spirit_grass_low"]:
		_expect(_amount(production_probe.get_view().resources[resource_id].value) > 0.0, "%s actually enters inventory after one production tick" % resource_id)

	var era_probe := GameSession.new()
	era_probe.content = session.content
	era_probe.state = session.state.duplicate_state()
	era_probe.clock = GameClock.create(0.0)
	era_probe.state.era_id = 2
	var era_rate := _amount(era_probe.get_view().resources.lingli.rate)
	_expect(is_equal_approx(era_rate, _amount(session.get_view().resources.lingli.rate) * 2.0), "Era 2 rate view doubles building output")
	era_probe.state.dao_heart = AmountCompat.from_number(100.0)
	_expect(_amount(era_probe.get_view().resources.lingli.rate) > era_rate, "dao heart boosts displayed building output")
	var before_breakthrough_rate := _amount(session.get_view().resources.lingli.rate)
	var training_ticks := 0
	while session.state.level < 10 and training_ticks < 60:
		if not bool(session.get_view().can_level_up):
			session.advance_time(60.0)
			training_ticks += 1
		else:
			if not _submit("level_up_cultivation", {}):
				break
	_expect(session.state.level == 10, "earned production and time reach cultivation level 10")
	_expect(bool(session.get_view().can_breakthrough), "earned buildings provide first breakthrough capacity")
	if bool(session.get_view().can_breakthrough):
		_expect(_submit("breakthrough_era", {}), "first era breakthrough succeeds without injected progress")
		_expect(session.state.era_id == 2, "positive flow reaches Era 2")
		_expect(is_equal_approx(_amount(session.get_view().resources.lingli.rate), before_breakthrough_rate * 2.0), "actual breakthrough doubles building income")
		session.state.buildings["rebirth_lotus"] = 1
		_expect(_submit("reincarnate", {"mode": "normal"}), "early reincarnation with rebirth lotus succeeds")
		_expect(session.state.reincarnation_count == 1 and session.state.era_id == 1, "reincarnation begins the next life")
		_expect(_amount(session.get_view().resources.lingli.value) == 0, "no automatic reincarnation supply without a talent")
		_expect(_build("hut"), "free gathering can rebuild a hut after a zero-stock rebirth")

	_finish("")

func _build(building_id: String) -> bool:
	var view := session.get_view()
	var building: Dictionary = view.buildings[building_id]
	if not bool(building.visible):
		failures.append("building is not reachable: %s" % building_id)
		return false
	for resource_id in building.costs:
		var required := _amount(building.costs[resource_id])
		var resource: Dictionary = view.resources[resource_id]
		if not bool(resource.unlocked) or required > _amount(resource.cap):
			failures.append("no usable source or capacity for %s required by %s" % [resource_id, building_id])
			return false
		var attempts := 0
		while _amount(session.get_view().resources[resource_id].value) < required:
			attempts += 1
			if attempts > 1000 or not _submit("gather", {"resource_id": resource_id}):
				failures.append("cannot gather %s for %s" % [resource_id, building_id])
				return false
	var old_level := int(session.state.buildings.get(building_id, 0))
	if not _submit("upgrade_building", {"building_id": building_id}):
		failures.append("cannot build or upgrade %s" % building_id)
		return false
	_expect(int(session.state.buildings[building_id]) == old_level + 1, "%s increases one level" % building_id)
	return true

func _submit(command_type: String, payload: Dictionary) -> bool:
	command_index += 1
	var result := session.submit({"command_id": "flow-%d" % command_index, "type": command_type, "expected_revision": session.state.revision, "payload": payload})
	if not bool(result.ok):
		failures.append("%s %s failed: %s" % [command_type, str(payload), str(result.get("error", "UNKNOWN"))])
	return bool(result.ok)

func _amount(raw: Variant) -> float:
	var parsed := AmountCompat.try_parse(str(raw))
	return (parsed.value as AmountCompat).to_float() if bool(parsed.ok) else NAN

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _finish(fatal: String) -> void:
	if not fatal.is_empty():
		failures.append(fatal)
	if failures.is_empty():
		print("PASS: blank game reaches every Era 1 building, first breakthrough and next life; production, money UI, saves, and multipliers.")
		quit(0)
	else:
		for failure in failures:
			push_error("CORE FLOW: " + failure)
		quit(1)
