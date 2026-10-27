extends Node
## Earned CLI review snapshots; paused desktop mouse and real Web save failure/retry.
var abode: Node
var elapsed := 0.0
var case_id := "album"
var scene_ready := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	case_id = String(JavaScriptBridge.eval("parent.caseId",true)) if OS.has_feature("web") else "album"
	if case_id not in ["album","event"]: push_error("invalid case"); return
	if OS.has_feature("web"):
		var adapter := WebStorageAdapter.new("dao2_story2_acceptance_"+case_id)
		var status := adapter.begin_session()
		while status == "pending":
			await get_tree().process_frame
			status = adapter.session_status()
		if status != "ready": push_error("writer unavailable"); return
		if not adapter.exists(SaveSlots.SLOT_MAIN):
			var raw := FileAccess.get_file_as_string("res://src/verification/story2-review-"+case_id+".json")
			var decoded := SaveCodec.decode(raw)
			if not decoded.ok: push_error("earned fixture decode"); return
			var now := str(int(Time.get_unix_time_from_system()*1000))
			var encoded := SaveCodec.encode(decoded.state,String(JSON.parse_string(raw).content_version),{"save_id":"story2-"+case_id,"saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":"0"})
			if not encoded.ok or not adapter.write(SaveSlots.SLOT_MAIN,encoded.json).ok: push_error("seed failed"); return
		JavaScriptBridge.eval("const set=Storage.prototype.setItem; Storage.prototype.setItem=function(k,v){if(parent.shellFail)throw new DOMException('STORY2 isolated write denial','QuotaExceededError');return set.call(this,k,v)}",true)
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 12: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide(); abode.v2_rules_notice.hide()
	abode._refresh_hud(); abode.feature_navigation.open("achievements" if case_id=="album" else "fortune")
	for i in 6: await get_tree().process_frame
	if case_id=="album":
		abode.achievement_panel._scroll.scroll_vertical = 0
	else:
		var modal: FortuneModal = abode.fortune_modal
		if not modal._option_rows.is_empty(): modal._body_scroll.ensure_control_visible(modal._option_rows[-1].button)
	scene_ready = true
	print("STORY2_REVIEW_READY ",case_id)
func buttons(node: Node, result: Array) -> void:
	if node is Button and node.is_visible_in_tree():
		var r: Rect2 = node.get_global_rect()
		result.append({"path":str(node.get_path()),"text":node.text,"disabled":node.disabled,"rect":[r.position.x,r.position.y,r.size.x,r.size.y]})
	for child in node.get_children(): buttons(child,result)
func _process(delta: float) -> void:
	if not scene_ready: return
	abode.set_process(false)
	elapsed += delta
	if elapsed<0.25: return
	elapsed=0
	var state: GameState = abode.session.state
	var actions := []
	buttons(abode.hud,actions)
	if abode._storage_block_layer != null: buttons(abode._storage_block_layer,actions)
	var data := {"case":case_id,"era":state.era_id,"age":state.total_elapsed_seconds,"revision":state.revision,"achievements":state.achievements,"fortune":state.fortune,"book":abode.session.get_decision_book(),"save_failed":abode.feature_navigation.shell.save_failed,"buttons":actions,"route":abode.feature_navigation.shell.state.snapshot().route,"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y]}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState("+JSON.stringify(data)+")",true)
