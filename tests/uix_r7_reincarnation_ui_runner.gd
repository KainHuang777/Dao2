extends SceneTree
var failed := false
var checks := 0
class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new("user://uix-r7-fault")
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok":false,"error":"R7_WRITE_DENIED"} if fail_writes else backend.write(key,value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
func _init() -> void: _run.call_deferred()
func check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(msg)
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r7-runner"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(abode.content,adapter)
	var panel: ReincarnationPanel = abode.reincarnation_panel
	abode.feature_navigation.open("reincarnation")
	check(panel._reincarnate_action_button.disabled,"new life cannot reincarnate")
	check(panel._reincarnate_button is GameTab and panel._close_button is CloseSeal,"shared controls")
	abode.session.state.dao_heart = AmountCompat.from_number(50)
	abode.session.state.buildings.rebirth_lotus = 1
	abode._refresh_hud()
	panel._on_reincarnate_action_pressed()
	check(panel._confirming and abode.session.state.reincarnation_count == 0,"confirmation sends no command")
	panel._cancel_button.pressed.emit()
	check(not panel._confirming and abode.session.state.reincarnation_count == 0,"cancel preserves state")
	panel._switch_tab("talents")
	var row: PanelContainer = panel._talent_rows.resource_inheritance
	var learn: Button = row.find_child("LearnButton",true,false)
	adapter.fail_writes = true
	learn.pressed.emit()
	check(abode.session.state.talents.resource_inheritance == 1 and abode.session.state.dao_heart.to_float() == 45,"real command consumes once")
	check(panel._retry_button.visible and panel._feedback.text.contains("保存失敗"),"write failure in page")
	var committed: Dictionary = abode.session.state.to_snapshot_dict()
	panel._retry_button.pressed.emit()
	check(panel._retry_button.visible and committed == abode.session.state.to_snapshot_dict(),"denied retry does not learn again")
	adapter.fail_writes = false
	panel._retry_button.pressed.emit()
	check(not panel._retry_button.visible and committed == abode.session.state.to_snapshot_dict(),"retry only saves")
	SaveManager.configure(abode.content,adapter)
	check(SaveManager.current_state().talents.resource_inheritance == 1,"disk reload keeps talent")
	check(SaveManager.current_state().dao_heart.to_float() == 45,"disk reload keeps payment")
	panel.set_save_result({"ok":false})
	check(await abode._settle_web_background(int(Time.get_unix_time_from_system()*1000)),"background recovery saves")
	check(not panel._pending_save and not panel._retry_button.visible,"background recovery clears stale error")
	panel._switch_tab("reincarnate")
	check(not panel._feedback_row.visible, "saved talent receipt does not displace life summary")
	panel._switch_tab("talents")
	abode.session.state.talents.innate_dao_body = 10
	abode._refresh_hud()
	check(panel._talent_rows.innate_dao_body.find_child("LearnButton",true,false).disabled,"max talent disabled")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		panel._feedback_row.hide()
		panel._switch_tab("talents")
		for frame in 8: await process_frame
		check(panel._body_scroll.size.y >= 80,"readable scroll viewport")
		check(panel._hero.visible and panel._hero.custom_minimum_size.x <= (300 if vp.x == 1280 else 96),"life illustration fits landscape")
		for id in panel._talent_rows:
			var card: PanelContainer = panel._talent_rows[id]
			check(card.size.x <= panel._body_scroll.size.x,"card fits width")
			check(card.find_child("TalentArt",true,false).texture != null,"generated art loaded")
			check(card.find_child("LearnButton",true,false).size.y >= 44,"44px action")
		var fixed_y: float = panel._tab_row.global_position.y
		panel._body_scroll.scroll_vertical = 10000
		for frame in 4: await process_frame
		check(is_equal_approx(fixed_y,panel._tab_row.global_position.y),"tabs fixed while content scrolls")
		panel._switch_tab("reincarnate")
		panel._on_reincarnate_action_pressed()
		for frame in 6: await process_frame
		check(panel.get_global_rect().encloses(panel._footer.get_global_rect()),"confirm and cancel inside bounds")
		var rail_safe_bottom := 20.0 if vp.y >= 500 else 14.0
		check(panel._footer.get_global_rect().end.y <= panel.get_global_rect().end.y - rail_safe_bottom + 0.5, "actions clear painted bottom rod plus reading gap")
		check(panel._root_box.global_position.y >= panel.global_position.y + (20.0 if vp.y >= 500 else 10.0) - 0.5, "content clears painted top rod")
		panel.hide()
		check(not panel._confirming,"leaving page cancels confirmation")
		panel.show()
	# Exhaustion auto-route waits for blocking reports, then offers once per life.
	abode.feature_navigation.home()
	abode.session.state.total_elapsed_seconds = 200000.0
	abode.offline_summary.show()
	abode._refresh_hud()
	await process_frame
	check(abode.feature_navigation.page != "reincarnation", "offline report has priority")
	abode.offline_summary.hide()
	abode._refresh_hud()
	await process_frame
	check(abode.feature_navigation.page == "reincarnation" and panel.visible, "exhaustion opens canonical page")
	check(panel._exhausted and panel._life_title.text == "命燈已熄", "spent life visual state")
	check(panel._hero.texture.resource_path.ends_with("life_lamp_spent.png"), "spent lamp illustration")
	panel._body_scroll.scroll_vertical = 0
	for frame in 8: await process_frame
	check(panel._compact_rewards.get_global_rect().end.y <= panel._body_scroll.get_global_rect().end.y + 0.5, "short exhaustion rewards remain inside viewport after frame padding")
	panel._on_close_pressed()
	abode._refresh_hud()
	await process_frame
	check(not panel.visible, "dismissed exhaustion does not steal navigation")
	abode._lifespan_prompted_cycle = -1
	abode._refresh_hud()
	await process_frame
	check(panel.visible, "reloaded exhausted life is offered again")
	panel._on_reincarnate_action_pressed()
	check(panel._reincarnate_desc_label.visible and panel._confirm_label.visible, "confirmation discloses reset details")
	panel._cancel_confirmation()
	check(not panel._reincarnate_desc_label.visible and panel._body_scroll.scroll_vertical == 0, "cancel restores compact overview")
	for frame in 8: await process_frame
	check(absf(panel._reincarnate_action_button.get_global_rect().get_center().x - panel.get_global_rect().get_center().x) < 2, "primary action centered")
	abode.feature_navigation.home()
	abode.session.state.reincarnation_count += 1
	StoryProgress.next_life(abode.session.state) # Keep synthetic life fixture consistent with story v1.
	abode.session.state.total_elapsed_seconds = 0.0
	abode._refresh_hud()
	await process_frame
	check(not panel.visible, "living lotus qualification does not auto-open")
	abode.session.state.total_elapsed_seconds = 200000.0
	abode._refresh_hud()
	await process_frame
	check(panel.visible, "new life can trigger a fresh exhaustion prompt")
	abode.feature_navigation.home()
	abode.session.state.total_elapsed_seconds = 0.0
	abode._refresh_hud()
	await process_frame
	abode.session.state.total_elapsed_seconds = 200000.0
	abode._refresh_hud()
	await process_frame
	check(panel.visible, "renewed lifespan can expire again within the same cycle")
	abode.queue_free()
	await process_frame
	print("UIX-R7 %d checks failed=%s" % [checks,failed])
	quit(1 if failed else 0)
