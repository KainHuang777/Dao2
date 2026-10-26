extends Node
## Explicit funded, paused test state; separate namespace, never player progress.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func write(key: String, value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail",true)):
			return {"ok":false,"error":"SECT_TEST_WRITE_DENIED"}
		return backend.write(key,value)
var abode: Node
var elapsed := 0.0
var _clock_active := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "" if OS.has_feature("web") else ("user://content-p1-sect-acceptance" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("content-p1-sect"))
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("content_p1_sect_fixture",false):
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/content_p1_sect_fixture.json"))
		if not decoded.ok: push_error("sect fixture decode failed: " + str(decoded.error)); return
		if OS.has_feature("web") and String(JavaScriptBridge.eval("parent.document.getElementById('template').value",true)) == "earned-era2":
			var raw := FileAccess.get_file_as_string("res://src/verification/content_p1_sect_earned_start.json")
			decoded = SaveManager.import_share_string(Marshalls.utf8_to_base64(raw))
			if not decoded.ok: push_error("earned Era2 decode failed"); return
			decoded.state.tutorial_flags.sect_earned_origin = true
		abode.session.state = decoded.state
		abode.session.state.tutorial_flags.content_p1_sect_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		if OS.has_feature("web"):
			var template := String(JavaScriptBridge.eval("parent.document.getElementById('template').value",true))
			var tasks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://src/verification/content_p1_sect_tasks.json"))
			if tasks.has(template): abode.session.state.sect.available_tasks = [tasks[template]]
		abode._save_game()
	SaveManager.configure(abode.content,FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("sect")
func buttons(node: Node, result: Array) -> void:
	if node is Button and node.is_visible_in_tree():
		var r: Rect2 = node.get_global_rect()
		result.append({"text":node.text,"disabled":node.disabled,"rect":[r.position.x,r.position.y,r.size.x,r.size.y]})
	for child in node.get_children(): buttons(child,result)
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	var realtime := OS.has_feature("web") and bool(JavaScriptBridge.eval("parent.document.getElementById('clock').checked",true))
	if realtime and not _clock_active: abode._last_process_ticks_msec = Time.get_ticks_msec()
	_clock_active = realtime
	abode.set_process(realtime)
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("parent.document.getElementById('advance').checked",true)):
		JavaScriptBridge.eval("parent.document.getElementById('advance').checked=false",true)
		var active: Variant = abode.session.state.sect.get("active_expedition")
		if active is Dictionary:
			abode.session.advance_time(maxf(0, float(active.duration)-float(active.elapsed)))
			abode._refresh_hud()
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	# Paused fixtures still refresh after the pressed-button rebuild guard releases.
	if abode.sect_panel != null: abode.sect_panel.update_view(state)
	var resources := {}
	for id in ["wood","stone_low","spirit_grass_low","lingli"]: resources[id] = state.resources[id].value.serialize()
	var actions := []
	buttons(abode.sect_panel, actions)
	var origin := "earned Era2 import" if state.tutorial_flags.get("sect_earned_origin",false) else "funded Era3"
	var data := {"fixture":origin + " isolated", "era_id":state.era_id,"age_seconds":state.total_elapsed_seconds,"sect":state.sect,"resources":resources,"pills":state.pills,"sect_version":state.sect_version,"revision":state.revision,"save_failed":abode.feature_navigation.shell.save_failed,"buttons":actions}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent = "+JSON.stringify(JSON.stringify(data)),true)
