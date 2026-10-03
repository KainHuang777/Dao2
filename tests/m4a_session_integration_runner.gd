extends SceneTree

var checks := 0
var failures := 0
var sequence := 0
var content: GameContent

func _init() -> void:
	content = ContentLoader.load_directory("res://content").content
	var s := GameSession.create_new_game(content)
	for kind in ["join_sect", "refresh_sect_tasks", "start_sect_expedition", "claim_sect_expedition", "learn_sect_technique", "buy_sect_market_item"]:
		_reject(s, kind, {}, "SECT_LOCKED" if kind in ["join_sect", "refresh_sect_tasks", "claim_sect_expedition"] else "")
	_reject(s, "switch_realm", {"target_realm": "realm_spirit"}, "SPIRIT_REALM_LOCKED")
	_reject(s, "upgrade_realm_outpost", {"outpost_id": "celestial_hub"}, "REALM_LOCKED")
	_reject(s, "apply_buff", {"buff_id": ""}, "EMPTY_BUFF_ID")
	_reject(s, "remove_buff", {"buff_id": ""}, "EMPTY_BUFF_ID")
	s.state.era_id = 2
	_reject(s, "upgrade_realm_outpost", {"outpost_id": "celestial_hub"}, "INSUFFICIENT_HUMAN_RESOURCE")
	_success(s, "join_sect", {"sect_name": "整合驗收宗門"})
	_reject(s, "join_sect", {}, "ALREADY_JOINED_SECT")
	_reject(s, "refresh_sect_tasks", {}, "REFRESH_COOLDOWN")
	_success(s, "refresh_sect_tasks", {"force": true})
	_reject(s, "start_sect_expedition", {"task_id": "missing"}, "TASK_NOT_FOUND")
	var task: Dictionary = s.state.sect.available_tasks[0]
	_success(s, "start_sect_expedition", {"task_id": task.id})
	_reject(s, "start_sect_expedition", {"task_id": task.id}, "EXPEDITION_ALREADY_ACTIVE")
	_reject(s, "claim_sect_expedition", {}, "EXPEDITION_NOT_FINISHED")
	s.advance_time(float(task.duration))
	_check(_ready_notice(s), "completion notification appears without granting reward")
	var money_before: AmountCompat = s.state.resources.money.value
	_success(s, "claim_sect_expedition", {})
	_check(s.state.resources.money.value.compare_to(money_before.add(AmountCompat.from_number(task.rewards.money))) == 0, "expedition reward granted once")
	_check(not _ready_notice(s), "claim clears notification")
	_reject(s, "claim_sect_expedition", {}, "NO_ACTIVE_EXPEDITION")
	_reject(s, "learn_sect_technique", {"technique_id": "missing"}, "UNKNOWN_TECHNIQUE")
	_reject(s, "buy_sect_market_item", {"item_id": "missing"}, "UNKNOWN_MARKET_ITEM")
	s.state.sect.contribution = "0"
	_reject(s, "learn_sect_technique", {"technique_id": "divine_farm"}, "INSUFFICIENT_CONTRIBUTION")
	_reject(s, "buy_sect_market_item", {"item_id": "herb_bundle"}, "INSUFFICIENT_CONTRIBUTION")
	s.state.sect.contribution = "10000"
	_reject(s, "learn_sect_technique", {"technique_id": "divine_farm"}, "INSUFFICIENT_WOOD")
	for id in content.resource_ids:
		s.state.resources[id].value = AmountCompat.from_number(10000)
	_success(s, "learn_sect_technique", {"technique_id": "divine_farm"})
	_check(s.state.sect.techniques.divine_farm == 1 and s.state.resources.wood.value.to_float() == 9900, "technique deducts exactly 100 wood")
	_success(s, "buy_sect_market_item", {"item_id": "herb_bundle"})
	_check(s.state.resources.spirit_grass_low.value.to_float() == 10050, "market grants exactly 50 herbs")
	_success(s, "buy_sect_market_item", {"item_id": "foundation_pill"})
	s.state.sect.market_purchases.herb_bundle = 20
	_reject(s, "buy_sect_market_item", {"item_id": "herb_bundle"}, "PURCHASE_LIMIT_REACHED")
	s.state.sect.techniques.divine_farm = 10
	_reject(s, "learn_sect_technique", {"technique_id": "divine_farm"}, "TECHNIQUE_MAX_LEVEL")
	_reject(s, "switch_realm", {"target_realm": "missing"}, "INVALID_REALM")
	_success(s, "switch_realm", {"target_realm": "realm_spirit"})
	_reject(s, "upgrade_realm_outpost", {"outpost_id": "missing"}, "UNKNOWN_OUTPOST")
	_success(s, "upgrade_realm_outpost", {"outpost_id": "celestial_hub"})
	_check(s.state.resources.money.value.to_float() == 9900 and s.state.resources.stone_low.value.to_float() == 9950, "outpost deducts exactly 100 money and 50 stone")
	_reject(s, "upgrade_realm_outpost", {"outpost_id": "pure_pool"}, "INSUFFICIENT_CRYSTAL")
	RealmSystem.ensure_spirit_data(s.state).spirit_crystal = 100
	_success(s, "buy_sect_market_item", {"item_id": "spirit_crystal_shard"})
	_check(s.state.realms_data.realm_spirit.spirit_crystal == 102, "market credits realm crystal balance")
	_success(s, "upgrade_realm_outpost", {"outpost_id": "pure_pool"})
	_success(s, "upgrade_realm_outpost", {"outpost_id": "void_beacon"})
	s.state.realms_data.realm_spirit.outposts.celestial_hub = 10
	_reject(s, "upgrade_realm_outpost", {"outpost_id": "celestial_hub"}, "MAX_LEVEL")
	_success(s, "apply_buff", {"buff_id": "spirit_surge", "duration": 300})
	s.advance_time(10)
	_success(s, "remove_buff", {"buff_id": "spirit_surge"})
	_success(s, "apply_buff", {"buff_id": "epiphany", "duration": 180})
	# In-flight and completed expeditions restore their notification from state.
	var next_task: Dictionary = s.state.sect.available_tasks[0]
	_success(s, "start_sect_expedition", {"task_id": next_task.id})
	s.advance_time(5)
	var restored := _reload(s)
	_check(not _ready_notice(restored), "unfinished expedition does not notify after reload")
	_check(restored.state.sect.active_expedition.elapsed == 5, "expedition elapsed restored")
	_check(restored.state.buffs == s.state.buffs and restored.get_view().buff_multipliers == s.get_view().buff_multipliers, "buff duration and effects restored")
	_check(restored.state.current_realm == "realm_spirit" and SaveCodec.compute_checksum(restored.state.realms_data) == SaveCodec.compute_checksum(s.state.realms_data), "realm progress restored")
	restored.advance_time(float(next_task.duration))
	restored = _reload(restored)
	_check(_ready_notice(restored), "completed notification restored")
	_success(restored, "claim_sect_expedition", {})
	_check(not _ready_notice(_reload(restored)), "claimed notification stays cleared on reload")
	_test_receipt_recovery(restored)
	var legacy_rewards := GameSession.create_new_game(content)
	legacy_rewards.state.era_id = 2
	legacy_rewards.join_sect()
	legacy_rewards.state.sect.active_expedition = {"name": "old task", "duration": 1, "elapsed": 1, "rewards": {"contribution": 10, "herb": 15, "bronze": 2}}
	_check(legacy_rewards.claim_sect_expedition().ok and legacy_rewards.state.resources.spirit_grass_low.value.to_float() == 15 and legacy_rewards.state.resources.black_copper.value.to_float() == 2, "old task reward aliases credit formal inventory")
	legacy_rewards.state.sect.active_expedition = {"name": "bad task", "duration": 1, "elapsed": 1, "rewards": {"contribution": 10, "missing": 2}}
	_reject(legacy_rewards, "claim_sect_expedition", {}, "REWARD_RESOURCE_MISSING")
	print("%s: M4-A-R1 Session integration (%d checks, %d failures)." % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _command(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	sequence += 1
	return {"command_id": "r1_%d" % sequence, "type": kind, "expected_revision": s.state.revision, "payload": payload}

func _snapshot(s: GameSession) -> String:
	return JSON.stringify(s.state.to_snapshot_dict(), "", true)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		failures += 1

func _reject(s: GameSession, kind: String, payload: Dictionary, error: String) -> void:
	var before := _snapshot(s)
	var command := _command(s, kind, payload)
	for retry in range(2):
		var result := s.submit(command)
		_check(not result.ok and (error.is_empty() or result.error == error), "%s rejection: %s" % [kind, result])
		_check(_snapshot(s) == before, kind + " rejected command must leave all state unchanged")
	print("REJECT: ", kind, " ", error)

func _success(s: GameSession, kind: String, payload: Dictionary) -> void:
	var command := _command(s, kind, payload)
	var revision := s.state.revision
	var stale := command.duplicate(true)
	stale.expected_revision = revision - 1
	var before := _snapshot(s)
	_check(s.submit(stale).get("error") == "STALE_REVISION" and _snapshot(s) == before, kind + " stale revision is atomic")
	var result := s.submit(command)
	_check(result.ok and not result.duplicate and s.state.revision == revision + 1, kind + " success: " + str(result))
	var after := _snapshot(s)
	var duplicate := s.submit(command)
	_check(duplicate.ok and duplicate.duplicate and duplicate.events.is_empty() and _snapshot(s) == after, kind + " duplicate does not change state or replay events")
	var restored := _reload(s)
	var loaded_before := _snapshot(restored)
	duplicate = restored.submit(command)
	_check(duplicate.ok and duplicate.duplicate and duplicate.events.is_empty() and _snapshot(restored) == loaded_before, kind + " duplicate after reload")
	print("SUCCESS + REPLAY + RELOAD: ", kind)

func _reload(s: GameSession) -> GameSession:
	var encoded := SaveCodec.encode(s.state, content.content_version, {"save_id": "m4a_r1", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"})
	_check(encoded.ok, "encode")
	var decoded := SaveCodec.decode(encoded.json)
	_check(decoded.ok, "decode: " + str(decoded.get("error")))
	var restored := GameSession.create_new_game(content)
	restored.state = decoded.state
	restored.clock = GameClock.create(restored.state.total_elapsed_seconds)
	return restored

func _ready_notice(s: GameSession) -> bool:
	for item in BuffHudBar.status_items(s.get_view(), s.state.sect):
		if item.id == "sect_ready":
			return true
	return false

class MemoryStorage extends StorageAdapter:
	var data := {}
	var fail_writes := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": ""}
	func write(key: String, value: String) -> Dictionary:
		if fail_writes:
			return {"ok": false, "error": "fixture_write_failure"}
		data[key] = value
		return {"ok": true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}

func _test_receipt_recovery(s: GameSession) -> void:
	var storage := MemoryStorage.new()
	SaveManager.configure(content, storage)
	_check(SaveManager.save(s.state, {}).ok, "initial isolated save")
	var command := _command(s, "buy_sect_market_item", {"item_id": "stone_bundle"})
	_check(s.submit(command).ok, "market before failed save")
	var before := _snapshot(s)
	storage.fail_writes = true
	_check(not SaveManager.save(s.state, {}).ok, "failed save reported")
	_check(s.submit(command).duplicate and _snapshot(s) == before, "retry after failed save does not double charge")
	storage.fail_writes = false
	_check(SaveManager.save(s.state, {}).ok, "save retry commits state and receipts")
	SaveManager.configure(content, storage)
	var loaded := GameSession.create_new_game(content)
	loaded.state = SaveManager.current_state()
	_check(loaded.submit(command).duplicate, "slot reload preserves retry receipt")
	# Corrupt newest generation: recover earlier valid snapshot and its receipt set.
	storage.data[SaveSlots.SLOT_BACKUP] = "broken"
	SaveManager.configure(content, storage)
	_check(SaveManager.current_state().revision == s.state.revision - 1, "corrupt newest save recovers valid generation")
	var encoded := SaveCodec.encode(s.state, content.content_version, {"save_id": "r1", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"})
	var old: Dictionary = JSON.parse_string(encoded.json)
	old.state.erase("command_receipts")
	old.erase("checksum")
	old.checksum = SaveCodec.compute_checksum(old)
	_check(SaveCodec.decode(JSON.stringify(old)).state.command_receipts.is_empty(), "older schema-2 snapshots default to empty receipts")
	var malformed: Dictionary = JSON.parse_string(encoded.json)
	malformed.state.command_receipts = {"bad": {"ok": true, "new_revision": s.state.revision + 1, "events": [], "changed_ids": []}}
	malformed.erase("checksum")
	malformed.checksum = SaveCodec.compute_checksum(malformed)
	_check(not SaveCodec.decode(JSON.stringify(malformed)).ok, "invalid receipts rejected despite valid checksum")
	# Bound survives canonical JSON key sorting; evict by revision, not dictionary order.
	var bounded := GameSession.create_new_game(content)
	for i in range(GameSession.COMMAND_REGISTRY_LIMIT + 1):
		bounded.submit({"command_id": "z_%d" % i, "type": "apply_buff", "expected_revision": bounded.state.revision, "payload": {"buff_id": "turtle_breath"}})
	bounded = _reload(bounded)
	_check(bounded.state.command_receipts.size() == 256 and not bounded.state.command_receipts.has("z_0"), "receipt window bounded to latest 256")
	bounded.apply_buff("turtle_breath")
	_check(not bounded.state.command_receipts.has("z_1") and bounded.state.command_receipts.has("z_256"), "oldest revision evicted after reload")
	SaveManager.reset_for_tests()

