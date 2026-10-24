extends Node
## Current-build integration review. Snapshots are earned by the CLI runner.
## Desktop browser interaction is reported separately from accelerated progression.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(value: StorageAdapter) -> void: backend=value
	func read(key: String) -> Dictionary: return backend.read(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func write(key: String,value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail",true)):
			return {"ok":false,"error":"P1_ACCEPT_TEST_WRITE_DENIED"}
		return backend.write(key,value)
var abode: Node
var elapsed := 0.0
var seq := 0
var clock_active := false
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	if not OS.has_feature("web"):
		load("res://src/abode/living_abode.gd").save_dir_override="user://content-p1-accept-isolated"
	abode=load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var selected := "second_base"
	if OS.has_feature("web"): selected=String(JavaScriptBridge.eval("parent.document.getElementById('scenario').value",true))
	if abode.session.state.era_id == 1 and abode.session.state.reincarnation_count == 0 and ReincarnationRules.building_level_sum(abode.session.state.buildings)==0 and selected != "blank":
		if not selected in ["second_base","integrated","reborn"]: push_error("invalid acceptance case"); return
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/content_p1_accept_"+selected+".json"))
		if not decoded.ok: push_error("earned acceptance snapshot failed to decode"); return
		abode.session.state=decoded.state
		abode._save_game()
	SaveManager.configure(abode.content,FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
func buttons(node: Node,result: Array) -> void:
	if node is Button and node.is_visible_in_tree():
		var r: Rect2=node.get_global_rect()
		result.append({"text":node.text,"path":str(node.get_path()),"disabled":node.disabled,"rect":[r.position.x,r.position.y,r.size.x,r.size.y]})
	for child in node.get_children(): buttons(child,result)
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	var realtime := OS.has_feature("web") and bool(JavaScriptBridge.eval("parent.document.getElementById('clock').checked",true))
	if realtime and not clock_active: abode._last_process_ticks_msec=Time.get_ticks_msec()
	clock_active=realtime
	abode.set_process(realtime)
	elapsed+=delta
	if elapsed<0.4: return
	elapsed=0
	abode._refresh_hud()
	var state: GameState=abode.session.state
	var actions: Array=[]
	buttons(abode,actions)
	seq+=1
	var data := {"seq":seq,"evidence":"earned CLI snapshots; browser clock paused unless enabled","viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"age":state.total_elapsed_seconds,"era":state.era_id,"level":state.level,"revision":state.revision,"hearts":state.dao_heart.serialize(),"rebirths":state.reincarnation_count,"skills":state.skills,"talents":state.talents,"pills":state.pills,"achievements":state.achievements,"sect":state.sect,"fortune":state.fortune,"beasts":state.beasts,"save_failed":abode.feature_navigation.shell.save_failed,"buttons":actions}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent="+JSON.stringify(JSON.stringify(data)),true)
