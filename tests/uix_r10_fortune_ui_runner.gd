extends SceneTree
var checks := 0
var failed := false
class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new("user://uix-r10-fault")
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String,value: String) -> Dictionary: return {"ok":false,"error":"R10_WRITE_DENIED"} if fail_writes else backend.write(key,value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
func _init() -> void: _run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(label)
func frames() -> void:
	for n in 15: await process_frame
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r10-runner"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var panel: FortuneModal = abode.fortune_modal
	abode.feature_navigation.open("fortune")
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(abode.content,adapter)
	check(panel._mapping.size()==26,"all26 real event IDs mapped")
	for enc in FortuneSystem.get_encounters():
		check(panel._mapping.has(enc.id) and ResourceLoader.exists(panel.ART_DIR+str(panel._mapping.get(enc.id))+".png"),"art for"+str(enc.id))
	abode.session.state.fortune.cooldown_remaining = 600
	abode._refresh_hud()
	check(panel._trigger_btn.disabled,"cooldown disables trigger")
	abode.session.state.fortune.cooldown_remaining = 0
	abode._refresh_hud()
	check(not panel._trigger_btn.disabled,"ready trigger")
	panel._trigger_btn.pressed.emit()
	check(not abode.session.state.fortune.pending_encounter.is_empty(),"real routed trigger")
	var pending: Dictionary = abode.session.state.fortune.pending_encounter.duplicate(true)
	SaveManager.configure(abode.content,ToggleAdapter.new())
	var loaded: Variant = SaveManager.load_state()
	check(loaded != null and loaded.fortune.pending_encounter == pending,"pending encounter survives fresh disk load")
	var stable: Button = panel._option_rows[0].button
	var snapshot: Dictionary = abode.session.state.to_snapshot_dict()
	for n in 30: panel.refresh(abode.session.get_view())
	check(panel._option_rows[0].button == stable,"refresh preserves press target")
	check(snapshot == abode.session.state.to_snapshot_dict(),"refresh cannot reroll state or RNG")
	# Exact existing paid encounter for cost and retry contract; fixture only.
	for enc in FortuneSystem.get_encounters():
		if enc.id == "enc_wandering_taoist": abode.session.state.fortune.pending_encounter = enc.duplicate(true)
	abode.session.state.resources.spirit_grass_low.value = AmountCompat.from_number(0)
	abode._refresh_hud()
	check(panel._option_rows[0].button.disabled,"real paid option shortage")
	abode.session.state.resources.spirit_grass_low.value = AmountCompat.from_number(1000)
	abode._refresh_hud()
	check(not panel._option_rows[0].button.disabled,"stock update enables existing button")
	SaveManager.configure(abode.content,adapter)
	adapter.fail_writes = true
	var before := int(abode.session.state.fortune.total_fortunes_claimed)
	panel._option_rows[0].button.pressed.emit()
	check(abode.session.state.fortune.pending_encounter.is_empty(),"real option settles")
	check(int(abode.session.state.fortune.total_fortunes_claimed)==before+1,"one claim")
	check(abode.session.state.resources.spirit_grass_low.value.compare_to(AmountCompat.from_number(980))==0,"canonical grass cost20")
	check(panel._pending_save and panel._retry.visible,"write failure in page")
	check(not panel._result_message.is_empty() and panel._encounter_title.text=="機緣已結算","result persists through refresh")
	snapshot = abode.session.state.to_snapshot_dict()
	panel._retry.pressed.emit()
	check(panel._pending_save and snapshot==abode.session.state.to_snapshot_dict(),"failed retry cannot repeat settlement")
	adapter.fail_writes = false
	panel._retry.pressed.emit()
	check(not panel._pending_save and snapshot==abode.session.state.to_snapshot_dict(),"recovered retry saves only")
	SaveManager.configure(abode.content,ToggleAdapter.new())
	loaded = SaveManager.load_state()
	check(loaded != null and loaded.fortune.pending_encounter.is_empty() and int(loaded.fortune.total_fortunes_claimed)==before+1,"reloaded single settlement")
	# View-only long narrative/cost test, no fake gameplay rewards.
	var view: Dictionary = abode.session.get_view()
	view.fortune.has_pending = true
	view.fortune.pending_encounter = pending.duplicate(true)
	view.fortune.pending_encounter.title = "天機奇遇・長標題閱讀與選項驗收"
	view.fortune.pending_encounter.desc = "山間雲霧散去，一段往事浮現。".repeat(80)
	view.fortune.pending_encounter.options[0].costs = {"herb":100}
	view.resources.spirit_grass_low.value = "123456789012345678901234567890"
	panel.refresh(view)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		print("R10_GEOMETRY ",vp," margin=",panel._margin.size," content=",panel._content.size," scroll=",panel._body_scroll.size," min=",panel._margin.get_combined_minimum_size()," mode=",panel._body_scroll.vertical_scroll_mode)
		check(panel._body_scroll.size.y > 70,"readable scroll"+str(vp))
		check(panel._body_scroll.get_global_rect().end.y <= panel.get_global_rect().end.y-14+1,"scroll safe bottom%s panel=%s scroll=%s" % [vp,panel.get_global_rect(),panel._body_scroll.get_global_rect()])
		var close: Button = abode.feature_navigation.back_button
		check(close.get_global_rect().size.x>=44 and close.get_global_rect().size.y>=44,"fixed close44"+str(vp))
		panel._body_scroll.scroll_vertical = 100000
		await frames()
		var last: Button = panel._option_rows.back().button
		check(last.size.y>=44 and panel._body_scroll.get_global_rect().encloses(last.get_global_rect()),"last option scroll reachable"+str(vp))
		check(panel._story.get_global_rect().end.x <= panel.get_global_rect().end.x,"long number no horizontal overflow"+str(vp))
	abode.queue_free()
	await process_frame
	print("UIX-R10 %d checks failed=%s" % [checks,failed])
	quit(1 if failed else 0)
