extends Node
## Explicit fixture on an isolated HTTP origin; production scene/rules unchanged.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail", true)):
			return {"ok": false, "error": "SHELL_TEST_WRITE_DENIED"}
		return backend.write(key, value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
var abode: Node
var elapsed := 0.0
func _ready() -> void: _start.call_deferred()
func _start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://ui-shell-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null: await get_tree().process_frame
	for n in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("shell_fixture", false):
		if OS.has_feature("ui_shell_matrix_acceptance"):
			var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/ui_shell_2_fixture.json"))
			assert(decoded.ok, "isolated earned-era3 fixture must decode")
			abode.session.state = decoded.state.duplicate_state()
			abode.session.state.reincarnation_count = 1
			StoryProgress.next_life(abode.session.state) # Keep synthetic life fixture consistent with story v1.
			abode.session.state.buildings.library = 1
			abode.session.state.resources.skill_point.value = AmountCompat.from_number(100)
		abode.session.state.buildings.herb_farm = 3
		abode.session.state.resources.spirit_grass_low.value = AmountCompat.from_number(100)
		abode.session.state.resources.spirit_grass_low.unlocked = true
		abode.session.state.resources.spirit_grass_low.ever_obtained = true
		abode.session.state.resources.lingli.value = AmountCompat.from_number(200)
		abode.session.state.tutorial_flags.shell_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		abode._save_game()
	SaveManager.configure(abode.content, FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("buildings" if OS.has_feature("ui_shell_matrix_acceptance") else "alchemy")
func _process(delta: float) -> void:
	if abode == null or abode.feature_navigation == null: return
	elapsed += delta
	if elapsed < 0.3: return
	elapsed = 0
	var shell = abode.feature_navigation.shell
	var snap: Dictionary = shell.state.snapshot()
	var data := {"route": snap.route, "overlay": snap.overlay, "home": snap.home_preferences,
		"collapsed": snap.resources_collapsed, "pills": abode.session.state.pills,
		"grass": abode.session.state.resources.spirit_grass_low.value.to_float(),
		"save_failed": shell.save_failed, "size": str(abode.hud.size)}
	data["context"] = shell.effective.get("resource_context", "")
	data["subpage"] = snap.subpage
	data["skill_points"] = str(abode.session.state.resources.skill_point.value.to_float())
	data["manufacturing_drafts"] = abode.feature_navigation.manufacturing_panel.recipe_drafts
	data["transport_drafts"] = abode.feature_navigation.transport_panel.drafts
	if OS.has_feature("web"):
		JavaScriptBridge.eval("parent.document.getElementById('state').textContent = " + JSON.stringify(JSON.stringify(data)), true)
