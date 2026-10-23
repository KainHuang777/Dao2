extends Node
## Isolated origin / save directory. No gameplay time runs in this fixture.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail", true)):
			return {"ok":false, "error":"ECHO_TEST_WRITE_DENIED"}
		return backend.write(key, value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
var abode: Node
var elapsed := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start.call_deferred()
func _start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://atm-life-c-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	abode.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null: await get_tree().process_frame
	for n in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("life_echo_fixture_v2", false):
		abode.session.state.reincarnation_count = 1
		StoryProgress.next_life(abode.session.state) # Keep synthetic life fixture consistent with story v1.
		LifeEchoFixture.apply(abode.session)
		abode._save_game()
	SaveManager.configure(abode.content, FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("reincarnation")
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var data := {"fixture":true, "count":state.reincarnation_count, "dao_heart":state.dao_heart.serialize(), "life_ledger":abode.session.get_life_record(), "report":abode.session.get_life_report(), "save_failed":abode.feature_navigation.shell.save_failed}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent = " + JSON.stringify(JSON.stringify(data)), true)
