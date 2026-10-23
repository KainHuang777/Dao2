extends Node
## Isolated desktop-Web verification fixture, not earned player history.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail", true)):
			return {"ok": false, "error": "LEDGER_TEST_WRITE_DENIED"}
		return backend.write(key, value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)

var abode: Node
var elapsed := 0.0

func _ready() -> void:
	_start.call_deferred()

func _start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://ledger-0-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null:
		await get_tree().process_frame
	for n in 4:
		await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("ledger_fixture_v2", false):
		var state: GameState = abode.session.state
		state.reincarnation_count = 1
		StoryProgress.next_life(state) # Keep synthetic life fixture consistent with story v1.
		state.era_id = 2
		state.level = 4
		state.highest_era = 6
		state.total_elapsed_seconds = 100
		state.buildings.rebirth_lotus = 1
		state.buildings.hut = 2
		state.life_ledger = {}
		LifeLedger.initialize(state)
		LifeLedger.note(state, "building_built", "hut", "fixture-hut", 100)
		state.tutorial_flags.ledger_fixture_v2 = true
		state.tutorial_flags.seen_nine_realms_hook = true
		state.revision += 1
		abode._save_game()
	SaveManager.configure(abode.content, FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("reincarnation")

func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null:
		return
	elapsed += delta
	if elapsed < 0.25:
		return
	elapsed = 0
	var state: GameState = abode.session.state
	var data := {"fixture": true, "schema": SaveCodec.SCHEMA_VERSION, "life_ledger": abode.session.get_life_record(),
		"count": state.reincarnation_count, "dao_heart": state.dao_heart.serialize(),
		"save_failed": abode.feature_navigation.shell.save_failed, "revision": state.revision}
	if OS.has_feature("web"):
		JavaScriptBridge.eval("parent.document.getElementById('state').textContent = " + JSON.stringify(JSON.stringify(data)), true)
