extends Node
## Explicit Era3 fixture -> formal reincarnation earns 20 hearts in CLI.
## Paused isolated browser fixture; never loads a player namespace.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func write(key: String,value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail",true)):
			return {"ok":false,"error":"TALENT_TEST_WRITE_DENIED"}
		return backend.write(key,value)
var abode: Node
var elapsed := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://content-p1-talents-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("content_p1_talents_fixture",false):
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/content_p1_talents_fixture.json"))
		if not decoded.ok: push_error("talent fixture decode failed"); return
		abode.session.state = decoded.state
		abode.session.state.tutorial_flags.content_p1_talents_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		abode._save_game()
	SaveManager.configure(abode.content,FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("reincarnation")
	abode.reincarnation_panel._switch_tab("talents")
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	abode.set_process(false)
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var panel = abode.reincarnation_panel
	var rows := {}
	for id in panel._talent_rows:
		var row = panel._talent_rows[id]
		var button: Button = row.find_child("LearnButton",true,false)
		var r := button.get_global_rect()
		rows[id] = {"x":r.position.x,"y":r.position.y,"w":r.size.x,"h":r.size.y,"disabled":button.disabled}
	var data := {"fixture":"explicit Era3 -> formal CLI rebirth; paused isolated desktop UI", "talents":state.talents,"dao_heart":state.dao_heart.serialize(),"talent_version":state.talent_version,"revision":state.revision,"reincarnation_count":state.reincarnation_count,"save_failed":abode.feature_navigation.shell.save_failed,"rows":rows,"tab":panel._active_tab}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent = "+JSON.stringify(JSON.stringify(data)),true)
