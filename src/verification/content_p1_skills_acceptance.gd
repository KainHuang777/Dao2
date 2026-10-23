extends Node
## Isolated earned CLI fixture; paused gameplay for reproducible mouse checks.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func write(key: String,value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail",true)):
			return {"ok":false,"error":"P1_TEST_WRITE_DENIED"}
		return backend.write(key,value)
var abode: Node
var elapsed := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start.call_deferred()
func _start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://content-p1-skills-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	abode.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("content_p1_skills_fixture",false):
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/content_p1_skills_fixture.json"))
		if not decoded.ok: push_error("earned fixture decode failed"); return
		abode.session.state = decoded.state
		abode.session.state.tutorial_flags.content_p1_skills_fixture = true
		abode._save_game()
	SaveManager.configure(abode.content,FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("skills")
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	abode.set_process(false)
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var data := {"fixture":"earned CLI; paused; not browser natural progression", "skills":state.skills,"points":state.resources.skill_point.value.serialize(),"save_failed":abode.feature_navigation.shell.save_failed,"skill_version":state.skill_version,"revision":state.revision,"cost":AlchemySystem.get_view(state).pills[0].cost,"resources":abode.session.get_view().resources}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent = "+JSON.stringify(JSON.stringify(data)),true)
