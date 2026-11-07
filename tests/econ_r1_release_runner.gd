extends SceneTree

const AbodeScript = preload("res://src/abode/living_abode.gd")
const AbodeScene = preload("res://scenes/living_abode.tscn")
const GameSessionScript = preload("res://src/application/game_session.gd")
const Play = preload("res://src/economy/economy_play_session.gd")
const Policy = preload("res://src/presentation/ui_shell_policy.gd")
const META := {"save_id": "econ-r1-f", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
const RESOURCE_SAMPLE := ["lingli", "money", "wood", "stone_low"]
const FRONTIER_DIR_NAME := "econ-r1-frontier"

var _failures: Array[String] = []
var _checks := 0
var _content: GameContent
var _dir := ""

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	_dir = RunnerResult.output_path("res://econ-r1-release")
	AbodeScript.save_dir_override = _dir
	var adapter := FileStorageAdapter.new(_dir)
	SaveSlots.new(adapter).reset()
	var abode = AbodeScene.instantiate()
	root.add_child(abode)
	await process_frame
	if abode == null or abode.session == null or abode.content == null:
		push_error("ECON-R1-F unrecoverable: legacy scene boot failed")
		_failures.append("legacy scene boot")
		if abode != null:
			abode.set_process(false)
			abode.queue_free()
			await process_frame
		_finish()
		return
	_content = abode.content
	_check(not abode.economy_edition, "booted edition is legacy")
	_check(not abode._requested_economy_edition(), "default request selects legacy edition")
	_check(abode._economy_session == null, "no economy play session owner")
	_check(abode.session.get_script() == GameSessionScript, "session is the legacy GameSession script")
	_check(not (abode.session is Play), "session is not an EconomyPlaySession")
	var view: Dictionary = abode.session.get_view()
	_check(not view.has("research"), "legacy view exposes no research key")
	_check(FeatureUnlocks.check("research", view).state == FeatureUnlocks.State.HIDDEN, "research unlock hidden for legacy view")
	var legal: String = Policy.legal_route("research", view)
	_check(legal != "research", "policy research route not self")
	_check(legal == "buildings", "policy research falls back to buildings")
	var live_state: GameState = abode.session.state
	abode.set_process(false)
	var before := _snapshot_of(live_state)
	_check(not (before.resources as Dictionary).is_empty(), "legacy resource sample present")
	var saved: Dictionary = SaveManager.save(live_state, META)
	_check(bool(saved.get("ok", false)), "legacy save commits")
	abode.queue_free()
	await process_frame
	if bool(saved.get("ok", false)):
		SaveManager.reset_for_tests()
		SaveManager.configure(_content, FileStorageAdapter.new(_dir))
		var reloaded: GameState = SaveManager.load_state() as GameState
		_check(reloaded != null, "legacy reload returns state")
		_check(SaveManager.load_error() == "", "legacy reload clears load error")
		if reloaded != null:
			var after := _snapshot_of(reloaded)
			_check(int(before.era_id) == int(after.era_id) and int(after.era_id) == int(live_state.era_id), "era preserved across reload")
			_check(int(before.level) == int(after.level), "level preserved across reload")
			_check(int(before.revision) == int(after.revision), "revision preserved across reload")
			_check(before.resources == after.resources, "resource sample preserved across reload")
			_check(SectLifeSave.same(live_state.to_snapshot_dict(), reloaded.to_snapshot_dict()), "full snapshot identical after reload")
	_old_schemas()
	var future_adapter := FileStorageAdapter.new(_dir.path_join("schema-future"))
	var fut := _fixture_state()
	var future_encode: Dictionary = SaveCodec.encode(fut.state, _content.content_version, META)
	if bool(future_encode.get("ok", false)):
		var future_parsed: Variant = JSON.parse_string(String(future_encode["json"]))
		if future_parsed is Dictionary:
			var future_envelope: Dictionary = future_parsed
			future_envelope.schema_version = SaveCodec.LIFE_SCHEMA_VERSION + 1
			future_envelope.erase("checksum")
			future_envelope.checksum = SaveCodec.compute_checksum(future_envelope)
			var future_raw: String = " \n" + JSON.stringify(future_envelope) + "\n"
			var future_slots := SaveSlots.new(future_adapter)
			future_slots.reset()
			_check(bool(future_slots.commit(future_raw, int(future_envelope.revision)).ok), "future schema committed")
			SaveManager.reset_for_tests()
			SaveManager.configure(_content, future_adapter)
			var loaded_future: GameState = SaveManager.load_state() as GameState
			_check(loaded_future == null, "future schema blocks load")
			_check(SaveManager.load_error() == "SCHEMA_VERSION_UNKNOWN", "future schema load error named")
			_check(not bool(SaveManager.save(fut.state, META).get("ok", false)), "future schema save refused")
			_check(String(future_adapter.read(SaveSlots.SLOT_MAIN).get("data", "")) == future_raw, "future schema bytes preserved")
	_isolation(adapter)
	_finish()

func _fixture_state() -> GameSession:
	var s := GameSession.create_new_game(_content, 31)
	s.state.era_id = 3
	s.state.highest_era = 3
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	SectIdentity.write(s.state.sect, "tianjian_sect")
	if s.state.resources.has("spirit_grass_low"):
		s.state.resources["spirit_grass_low"]["value"] = AmountCompat.from_number(5000)
	s.state.economy = {}
	s.state.sect_version = 0
	s.state.beast_version = 0
	s.state.talent_version = 2
	return s

func _old_schemas() -> void:
	for schema in [2, 3, 4, 5]:
		var s := _fixture_state()
		var era: int = s.state.era_id
		var level: int = s.state.level
		var encode: Dictionary = SaveCodec.encode(s.state, _content.content_version, META)
		_check(bool(encode.get("ok", false)), "syntactic encode schema " + str(schema))
		if not bool(encode.get("ok", false)):
			continue
		var parsed: Variant = JSON.parse_string(String(encode["json"]))
		_check(parsed is Dictionary, "syntactic envelope parses " + str(schema))
		if not (parsed is Dictionary):
			continue
		var envelope: Dictionary = parsed
		envelope.schema_version = schema
		if schema < 5:
			(envelope.state as Dictionary).erase("life_ledger")
		envelope.erase("checksum")
		envelope.checksum = SaveCodec.compute_checksum(envelope)
		var raw: String = " \n" + JSON.stringify(envelope) + "\n"
		var schema_adapter := FileStorageAdapter.new(_dir.path_join("schema-" + str(schema)))
		var schema_slots := SaveSlots.new(schema_adapter)
		schema_slots.reset()
		_check(bool(schema_slots.commit(raw, int(envelope.revision)).get("ok", false)), "schema " + str(schema) + " committed through SaveSlots")
		SaveManager.reset_for_tests()
		SaveManager.configure(_content, schema_adapter)
		var loaded: GameState = SaveManager.load_state() as GameState
		_check(loaded != null, "schema " + str(schema) + " loads through SaveManager")
		if loaded != null:
			_check(loaded.era_id == era, "schema " + str(schema) + " era preserved")
			_check(loaded.level == level, "schema " + str(schema) + " level preserved")

func _isolation(legacy: FileStorageAdapter) -> void:
	_check(not legacy.exists(EconomyProfileStorage.PREFIX + SaveSlots.SLOT_MAIN), "legacy adapter has no econ main key")
	_check(not legacy.exists(EconomyProfileStorage.PREFIX + SaveSlots.SLOT_BACKUP), "legacy adapter has no econ backup key")
	_check(not legacy.exists(EconomyProfileStorage.PREFIX + SaveSlots.INDEX_KEY), "legacy adapter has no econ index key")
	_check(EconomyProfileStorage.PREFIX == "econ_r1_", "econ key prefix is econ_r1_")
	_check(not EconomyProfileStorage.new(FileStorageAdapter.new(_dir)).exists(SaveSlots.SLOT_MAIN), "econ profile probe finds nothing in legacy bytes")
	var da := DirAccess.open(_dir)
	_check(da != null, "legacy storage directory openable")
	if da != null:
		var contaminated := false
		for entry in da.get_files():
			if String(entry).begins_with(EconomyProfileStorage.PREFIX):
				contaminated = true
		for entry in da.get_directories():
			if String(entry).begins_with(EconomyProfileStorage.PREFIX):
				contaminated = true
		_check(not contaminated, "legacy storage has no econ prefixed names")
	var frontier := _dir.path_join(FRONTIER_DIR_NAME)
	if DirAccess.dir_exists_absolute(frontier):
		var fd := DirAccess.open(frontier)
		_check(fd != null and fd.get_files().is_empty() and fd.get_directories().is_empty(), "econ namespace dir empty after legacy boot")
	else:
		_check(true, "econ namespace dir not created by legacy boot")

func _snapshot_of(state: GameState) -> Dictionary:
	var full: Dictionary = state.to_snapshot_dict()
	var all_resources: Dictionary = full.get("resources", {})
	var sample: Dictionary = {}
	for id in RESOURCE_SAMPLE:
		if all_resources.has(id):
			sample[id] = all_resources[id]
	return {"era_id": int(full.get("era_id", 0)), "level": int(full.get("level", 0)), "revision": int(full.get("revision", -1)), "resources": sample}

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)

func _finish() -> void:
	AbodeScript.save_dir_override = ""
	SaveManager.reset_for_tests()
	print("ECON-R1-F release checks=%d failures=%s" % [_checks, JSON.stringify(_failures)])
	RunnerResult.finish(self, 0 if _failures.is_empty() else 1)
