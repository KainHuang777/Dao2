extends Node
## Synthetic isolated fixture. Human mouse input uses the production panels.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail", true)): return {"ok":false,"error":"DECISION_TEST_WRITE_DENIED"}
		return backend.write(key, value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
var abode: Node
var elapsed := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://decision-1-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	abode.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null: await get_tree().process_frame
	for n in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var state: GameState = abode.session.state
	if not state.tutorial_flags.get("decision_fixture", false):
		state.reincarnation_count = 1
		StoryProgress.next_life(state) # Keep synthetic life fixture consistent with story v1.
		state.life_ledger = {}
		LifeLedger.initialize(state, true)
		FortuneSystem.ensure_initialized(state)
		for enc in FortuneSystem.get_encounters():
			if enc.id == "enc_wandering_taoist":
				state.fortune.pending_encounter = enc.duplicate(true)
		state.resources.spirit_grass_low.value = AmountCompat.from_number(50)
		state.tutorial_flags.decision_fixture = true
		state.revision += 1
		abode._save_game()
	SaveManager.configure(abode.content, FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("fortune")
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var data := {"fixture":true, "count":state.fortune.get("total_fortunes_claimed",0), "grass":state.resources.spirit_grass_low.value.serialize(), "pending":DecisionReceipt.pending_id(state), "book":abode.session.get_decision_book(), "save_failed":abode.feature_navigation.shell.save_failed}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent = " + JSON.stringify(JSON.stringify(data)), true)
