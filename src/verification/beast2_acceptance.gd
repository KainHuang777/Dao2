extends Node
## Isolated paused review: real UI commands and persistent Web storage.
var abode: Node
var elapsed := 0.0
var case_id := "era4"
var scene_ready := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	if OS.has_feature("web"):
		case_id = String(JavaScriptBridge.eval("parent.caseId",true))
		if case_id not in ["era4","era5","souls4","souls5"]: push_error("invalid case"); return
		var adapter := WebStorageAdapter.new("dao2_beast2_acceptance_v2_"+case_id)
		var status := adapter.begin_session()
		while status == "pending":
			await get_tree().process_frame
			status = adapter.session_status()
		if status != "ready": push_error("writer unavailable"); return
		if not adapter.exists(SaveSlots.SLOT_MAIN):
			var era := "era4" if case_id.ends_with("4") else "era5"
			var raw := FileAccess.get_file_as_string("res://src/verification/beast2-review-"+era+".json")
			var decoded := SaveCodec.decode(raw)
			if not decoded.ok: push_error("fixture decode"); return
			if case_id.begins_with("souls"):
				# Clearly separate synthetic budget fixture, never an earned-soul claim.
				decoded.state.beast_souls = {"frost_stag":11,"herb_crane":11}
			var now := str(int(Time.get_unix_time_from_system()*1000))
			var encoded := SaveCodec.encode(decoded.state,String(JSON.parse_string(raw).content_version),{"save_id":"beast2-"+case_id,"saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":"0"})
			if not encoded.ok or not adapter.write(SaveSlots.SLOT_MAIN,encoded.json).ok: push_error("seed failed"); return
		JavaScriptBridge.eval("const set = Storage.prototype.setItem; Storage.prototype.setItem = function(k,v) { if(parent.shellFail) throw new DOMException('BEAST2 isolated failure','QuotaExceededError'); return set.call(this,k,v); };",true)
	else:
		load("res://src/abode/living_abode.gd").save_dir_override = "res://docs/verification/artifacts/content-p2-beasts-ui/native-harness"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 6: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide(); abode.v2_rules_notice.hide()
	abode._refresh_hud()
	abode.feature_navigation.open("beasts")
	for i in 6: await get_tree().process_frame
	var page: Control = abode.feature_navigation.action_panel.beast_view
	page.scroll.ensure_control_visible(page.cards["frost_stag" if case_id.ends_with("4") else "herb_crane"].card)
	scene_ready = true
	print("BEAST2_REVIEW_READY ",case_id)
func _process(delta: float) -> void:
	if not scene_ready: return
	abode.set_process(false)
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var panel: Control = abode.feature_navigation.action_panel
	panel.refresh(abode.session.get_view())
	var rows := {}
	for key in panel.buttons:
		var b: Button = panel.buttons[key]
		var r := b.get_global_rect()
		rows[key] = {"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"disabled":b.disabled,"text":b.text,"visible":b.is_visible_in_tree()}
	var retry: Rect2 = panel.retry_button.get_global_rect()
	var stocks := {}
	for id in ["refined_iron","spirit_grass_low","spirit_grass_100y","spirit_grass_1000y"]: stocks[id] = state.resources.get(id,{}).get("value",AmountCompat.zero()).to_float()
	var data := {"case":case_id,"era":state.era_id,"active":state.beasts,"souls":state.beast_souls,"talents":state.beast_talents,"stocks":stocks,"revision":state.revision,"save_failed":abode.feature_navigation.shell.save_failed,"rows":rows,"retry":[retry.position.x,retry.position.y,retry.size.x,retry.size.y],"visible":panel.visible,"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"scroll":panel.beast_view.scroll.scroll_vertical}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState("+JSON.stringify(data)+")",true)
