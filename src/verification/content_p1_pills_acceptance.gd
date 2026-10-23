extends Node
## Explicit funded Era3 fixture, not earned natural progression.
## Paused isolated browser fixture; never loads a player namespace.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func write(key: String,value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail",true)):
			return {"ok":false,"error":"PILL_TEST_WRITE_DENIED"}
		return backend.write(key,value)
var abode: Node
var elapsed := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://content-p1-pills-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("content_p1_pills_fixture",false):
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/content_p1_pills_fixture.json"))
		if not decoded.ok: push_error("pill fixture decode failed"); return
		abode.session.state = decoded.state
		abode.session.state.tutorial_flags.content_p1_pills_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		abode._save_game()
	SaveManager.configure(abode.content,FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("alchemy")
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	abode.set_process(false)
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var panel = abode.alchemy_panel
	var rows := {}
	for id in panel._widgets:
		var w: Dictionary = panel._widgets[id]
		var r: Rect2 = w.refine.get_global_rect()
		var cr: Rect2 = w.consume.get_global_rect()
		rows[id] = {"refine":[r.position.x,r.position.y,r.size.x,r.size.y],"consume":[cr.position.x,cr.position.y,cr.size.x,cr.size.y],"refine_disabled":w.refine.disabled,"consume_disabled":w.consume.disabled,"status":w.status.text}
	var resources := {}
	for id in ["wood","spirit_grass_low","stone_low","lingli"]: resources[id] = state.resources[id].value.serialize()
	var data := {"fixture":"explicit funded Era3, paused isolated desktop UI", "pills":state.pills,"buffs":state.buffs,"resources":resources,"pill_version":state.pill_version,"revision":state.revision,"save_failed":abode.feature_navigation.shell.save_failed,"rows":rows}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent = "+JSON.stringify(JSON.stringify(data)),true)
