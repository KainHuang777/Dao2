extends Node
## Paused desktop harness. Named earned snapshots, real commands and Web storage.
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
		if case_id not in ["era4","era6"]: push_error("invalid case"); return
		var adapter := WebStorageAdapter.new("dao2_sect2_acceptance_"+case_id)
		var status := adapter.begin_session()
		while status == "pending":
			await get_tree().process_frame
			status = adapter.session_status()
		if status != "ready": push_error("test writer unavailable"); return
		if not adapter.exists(SaveSlots.SLOT_MAIN):
			var raw := FileAccess.get_file_as_string("res://src/verification/sect2-"+case_id+".json")
			var decoded := SaveCodec.decode(raw)
			if not decoded.ok: push_error("fixture decode failed"); return
			var now := str(int(Time.get_unix_time_from_system()*1000))
			var encoded := SaveCodec.encode(decoded.state,String(JSON.parse_string(raw).content_version),{"save_id":"sect2-"+case_id,"saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":"0"})
			if not encoded.ok or not adapter.write(SaveSlots.SLOT_MAIN,encoded.json).ok: push_error("seed failed"); return
		JavaScriptBridge.eval("const set = Storage.prototype.setItem; Storage.prototype.setItem = function(k,v) { if(parent.shellFail) throw new DOMException('SECT2 isolated failure','QuotaExceededError'); return set.call(this,k,v); };",true)
	else:
		load("res://src/abode/living_abode.gd").save_dir_override = "user://sect2-native-review"
	if not OS.has_feature("web"):
		var content: GameContent = ContentLoader.load_directory("res://content").content
		IslandProgression.attach_supply(content)
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/sect2-era4.json"))
		var adapter := FileStorageAdapter.new("res://docs/verification/artifacts/content-p2-sect-ui/native-storage")
		SaveSlots.new(adapter).reset()
		var now := str(int(Time.get_unix_time_from_system()*1000))
		var encoded := SaveCodec.encode(decoded.state, content.content_version, {"save_id":"sect2-native","saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":"0"})
		adapter.write(SaveSlots.SLOT_MAIN,encoded.json)
		load("res://src/abode/living_abode.gd").save_dir_override = "res://docs/verification/artifacts/content-p2-sect-ui/native-storage"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 6: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode._refresh_hud()
	abode.feature_navigation.open("sect")
	scene_ready = true
	print("SECT2_REVIEW_READY era=",abode.session.state.era_id)
func _process(delta: float) -> void:
	if not scene_ready: return
	abode.set_process(false)
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var panel: SectPanel = abode.sect_panel
	# Paused review still settles the pressed-button rebuild guard, like normal refresh.
	panel.update_view(state)
	var rows := {}
	for grid in panel._grids:
		for card in grid.get_children():
			if not card.has_meta("content_id"): continue
			var id: String = card.get_meta("content_id")
			var row = card.get_child(0)
			var action: Button = row.get_child(row.get_child_count()-1)
			var r := action.get_global_rect()
			rows[id] = {"action":[r.position.x,r.position.y,r.size.x,r.size.y],"disabled":action.disabled,"text":action.text,"art":row.get_child(0) is TextureRect and row.get_child(0).texture != null}
	var data := {"case":case_id,"era":state.era_id,"contribution":state.sect.get("contribution"),"techniques":state.sect.get("techniques"),"purchases":state.sect.get("market_purchases"),"revision":state.revision,"save_failed":abode.feature_navigation.shell.save_failed,"rows":rows,"visible":panel.visible,"tab":panel._current_tab,"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"scroll":panel._scroll.scroll_vertical}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState("+JSON.stringify(data)+")",true)
