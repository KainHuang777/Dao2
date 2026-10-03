extends SceneTree
var failed := false
func _init() -> void:
	_run.call_deferred()
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("ISLAND1: " + message)
func _session() -> GameSession:
	var loaded := ContentLoader.load_directory("res://content")
	return GameSession.create_new_game(loaded.content)
func _unlock(session: GameSession) -> void:
	session.state.buildings.hut = 2
	session.state.buildings.forest_farm = 1
	session.state.buildings.herb_farm = 1
	session.state.buildings.stone_mine = 1
	for id in ["wood", "spirit_grass_low", "stone_low"]:
		session.state.resources[id].unlocked = true
func _command(session: GameSession, id: String, command_id: String) -> Dictionary:
	return {"command_id": command_id, "type": "claim_abode_scenery", "expected_revision": session.state.revision, "payload": {"find_id": id}}
func _encode(state: GameState) -> Dictionary:
	return SaveCodec.encode(state, "test", {"save_id": "island-test", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"})
func _run() -> void:
	var session := _session()
	AbodeScenery.advance(session.state, 500)
	check(session.state.abode_scenery.is_empty(), "locked new game has no finds")
	_unlock(session)
	var split := session.state.duplicate_state()
	AbodeScenery.advance(session.state, 1200)
	for tick in 1200:
		AbodeScenery.advance(split, 1)
	check(session.state.abode_scenery == split.abode_scenery, "one large offline interval equals segmented ticks")
	check(session.state.abode_scenery.active.size() == 2, "offline bounded to two, no automatic rewards")
	var ids: Array = []
	var seen: Dictionary = {}
	for cycle in 40:
		var entry: Dictionary = session.state.abode_scenery.active[0].duplicate(true)
		seen[entry.kind] = true
		ids.append(entry.id)
		var rid: String = AbodeScenery.DEFINITIONS[entry.kind].resource_id
		session.state.resources[rid].value = AmountCompat.zero()
		var cmd := _command(session, entry.id, "claim" + str(cycle))
		var before := session.state.to_snapshot_dict()
		cmd.expected_revision = -1
		check(not session.submit(cmd).ok and before == session.state.to_snapshot_dict(), "stale claim is neutral")
		cmd.expected_revision = session.state.revision
		var result := session.submit(cmd)
		check(result.ok and session.state.resources[rid].value.to_float() == float(entry.amount), "claim grants exactly stored batch")
		before = session.state.to_snapshot_dict()
		check(session.submit(cmd).duplicate and before == session.state.to_snapshot_dict(), "same command ID cannot duplicate reward")
		check(not session.submit(_command(session, entry.id, "repeat" + str(cycle))).ok, "same find with new command cannot reward again")
		AbodeScenery.advance(session.state, 100)
	check(seen.size() == 3, "all three resource finds occur")
	var entry: Dictionary = session.state.abode_scenery.active[0]
	var rid: String = AbodeScenery.DEFINITIONS[entry.kind].resource_id
	var cap: AmountCompat = Production.compute_caps(session.content, session.state.buildings, session.state.era_id, session.state.onboarding_version)[rid]
	session.state.resources[rid].value = cap
	var before := session.state.to_snapshot_dict()
	check(session.submit(_command(session, entry.id, "full")).get("error") == "SCENERY_CAPACITY_FULL", "full capacity rejects")
	check(before == session.state.to_snapshot_dict(), "full capacity retains find and inventory")
	session.state.resources[rid].value = cap.subtract(AmountCompat.from_number(1))
	var partial := session.submit(_command(session, entry.id, "partial"))
	check(partial.ok and partial.events[0].amount == "1" and session.state.resources[rid].value.compare_to(cap) == 0, "partial room credits actual amount, never exceeds cap")
	entry = session.state.abode_scenery.active[0]
	rid = AbodeScenery.DEFINITIONS[entry.kind].resource_id
	session.state.resources[rid].unlocked = false
	before = session.state.to_snapshot_dict()
	check(session.submit(_command(session, entry.id, "locked")).get("error") == "RESOURCE_LOCKED" and before == session.state.to_snapshot_dict(), "locked claim neutral")
	session.state.resources[rid].unlocked = true
	session.state.current_realm = "realm_spirit"
	check(AbodeScenery.get_view(session.state).is_empty() and not session.submit(_command(session, entry.id, "away")).ok, "home finds hidden and blocked away")
	session.state.current_realm = "realm_human"
	var encoded := _encode(session.state)
	var decoded := SaveCodec.decode(encoded.json)
	check(decoded.ok and SaveCodec.compute_checksum(decoded.state.to_snapshot_dict()) == SaveCodec.compute_checksum(session.state.to_snapshot_dict()), "save roundtrip retains RNG, timer, IDs and rewards (JSON numeric equivalence)")
	var restored := _session()
	restored.state = decoded.state
	check(not restored.submit(_command(restored, ids[0], "after-reload")).ok, "consumed ID cannot reward after reload")
	var legacy: Dictionary = JSON.parse_string(encoded.json)
	legacy.state.erase("abode_scenery")
	legacy.erase("checksum")
	legacy.checksum = SaveCodec.compute_checksum(legacy)
	var old := SaveCodec.decode(JSON.stringify(legacy))
	check(old.ok and old.state.abode_scenery.is_empty(), "old schema-2 save additive migration")
	var corrupt: Dictionary = JSON.parse_string(encoded.json)
	corrupt.state.abode_scenery.active[0].amount = 9999
	corrupt.erase("checksum")
	corrupt.checksum = SaveCodec.compute_checksum(corrupt)
	check(SaveCodec.decode(JSON.stringify(corrupt)).get("error") == "SCENERY_AMOUNT", "malformed reward rejected despite valid checksum")
	# Existing two-generation recovery applies to new scenery data too.
	var slots := SaveSlots.new(FileStorageAdapter.new("user://island1_codec_runner"))
	slots.reset()
	check(slots.commit(encoded.json, session.state.revision).ok, "isolated persistent save")
	var persisted := slots.read_best(func(json: String) -> int:
		var decoded_save := SaveCodec.decode(json)
		return decoded_save.state.revision if decoded_save.ok else -1)
	check(persisted.ok and SaveCodec.decode(persisted.json).state.abode_scenery == session.state.abode_scenery, "persistent load retains pending finds")
	slots.reset()
	# Real time path, not only direct scenery advancement.
	var timed := _session()
	_unlock(timed)
	timed.advance_time(12)
	check(timed.state.abode_scenery.active.size() == 1, "Session time integrates first spawn")
	var fresh := _session()
	_unlock(fresh)
	fresh.state.era_id = 2
	fresh.state.level = 10
	fresh.state.total_elapsed_seconds = float(Lifespan.max_lifespan_seconds(fresh.content.era_lifespan_entries(), 2))
	fresh.state.abode_scenery = session.state.abode_scenery.duplicate(true)
	var reborn := ReincarnationRules.apply_reincarnation(fresh.state, fresh.content, "normal")
	check(reborn.ok and fresh.state.abode_scenery.is_empty(), "reincarnation clears old-life finds")
	print("ISLAND1_CORE ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
