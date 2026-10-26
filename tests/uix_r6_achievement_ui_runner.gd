extends SceneTree
var failed := false
var checks := 0
class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new("user://uix-r6-claims")
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok": false, "error": "R6_WRITE_DENIED"} if fail_writes else backend.write(key, value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
func _init() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(message)
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r6-ui-runner"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var panel: AchievementPanel = abode.achievement_panel
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(abode.content, adapter)
	abode.session.state.level = 2
	abode.session.state.buildings.hut = 1
	AchievementSystem.check_achievements(abode.session.state)
	abode._refresh_hud()
	abode.feature_navigation.open("achievements")
	check(panel._achievement_items.size() == 18, "18 achievement cards")
	check(panel._filters._buttons.size() == 7, "all + six canonical categories")
	for i in range(1, 7):
		check(panel._filters._buttons[i].icon != null, "category representative icon")
	check(panel._close_button is CloseSeal, "shared close seal")
	for id in AchievementSystem.DEFINITIONS:
		var card: Control = panel._achievement_items[id]
		check(card.get_node("HBox/Badge").texture != null, "badge loaded: " + id)
		check(card.get_node("HBox/Info/Reward").get_theme_font_size("font_size") >= 16, "readable reward")
		check(card.get_node("HBox/Info").get_child_count() == 2, "only title and reward text")
	var card: Control = panel._achievement_items.build_first_hut
	var button: Button = card.get_node("HBox/Action")
	check(not button.disabled and button.text == "領取獎勵", "claimable from real view")
	check(panel._achievement_items.era_golden_core.get_node("HBox/Action").disabled, "locked command disabled")
	var wood_before: float = abode.session.state.resources.wood.value.to_float()
	adapter.fail_writes = true
	button.pressed.emit()
	check(abode.session.state.resources.wood.value.to_float() == wood_before + 100, "real signal grants once")
	check(button.disabled and button.text == "已領取", "claim refreshes card")
	check(panel._retry_button.visible and panel._status_label.text.contains("保存失敗"), "failed write visible with retry")
	check(abode.feature_navigation.tab_buttons.achievements.text.contains("1"), "tab pending count updates")
	check(not abode.session.claim_achievement("build_first_hut").ok, "duplicate rejected")
	var committed: Dictionary = abode.session.state.to_snapshot_dict()
	adapter.fail_writes = false
	panel._retry_button.pressed.emit()
	check(not panel._retry_button.visible, "retry succeeds")
	check(abode.session.state.to_snapshot_dict() == committed, "save retry never grants again")
	SaveManager.configure(abode.content, adapter)
	var restored: GameState = SaveManager.current_state()
	check(restored.achievements.claimed.get("build_first_hut", false), "disk reload retains claim")
	check(restored.resources.wood.value.to_float() == wood_before + 100, "disk reload retains exact reward")
	adapter.fail_writes = true
	abode._on_achievement_claim_requested("era_qi")
	var dao_after_claim: float = abode.session.state.dao_heart.to_float()
	var retry_cursor: int = int(Time.get_unix_time_from_system() * 1000.0)
	check(not await abode._settle_web_background(retry_cursor), "background retry reports denied write")
	check(panel._retry_button.visible and panel._status_label.text.contains("保存失敗"), "failed background retry keeps error")
	adapter.fail_writes = false
	check(await abode._settle_web_background(retry_cursor), "background retry commits claim")
	check(not panel._retry_button.visible and panel._status_label.text == "領取結果已保存。", "background recovery clears stale achievement error")
	check(abode.session.state.dao_heart.to_float() == dao_after_claim, "background recovery never awards again")
	panel.set_save_result({"ok": false, "error": "R6_WRITE_DENIED"})
	check(abode._save_game().ok and not panel._retry_button.visible, "ordinary successful save also clears pending error")
	panel.show_status_message("領取成功！")
	abode._save_game()
	check(panel._status_label.text == "領取成功！", "unrelated saves preserve ordinary feedback")
	check(not abode.reincarnation_button._red_dot.visible, "last claim clears dock red dot")
	for index in range(1, 7):
		panel._filters._buttons[index].pressed.emit()
		for item in panel._achievement_items.values():
			check(item.visible == (item.get_meta("category") == panel._category_ids[index]), "filter visibility")
	panel._filters._buttons[0].pressed.emit()
	panel.show_status_message("")
	for vp in ([Vector2(1280,720),Vector2(844,390),Vector2(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280,720)]):
		abode._layout_for_size(vp)
		for frame in 5: await process_frame
		check(panel._scroll.size.y > 20, "scroll has usable height")
		check(panel._achievements_list.columns == (2 if vp.x >= 1100 else 1), "responsive grid columns")
		check(panel._scroll.get_global_rect().end.y <= panel.get_global_rect().end.y, "scroll bounded")
		check(panel._filters_scroll.get_global_rect().position.y < panel._scroll.global_position.y, "fixed filters above scroll")
		var old_close: Vector2 = abode.feature_navigation.back_button.global_position
		panel._scroll.scroll_vertical = 500
		await process_frame
		check(abode.feature_navigation.back_button.global_position == old_close, "shell close remains fixed")
		check(button.custom_minimum_size.y >= 44, "claim hit height")
		var badge: TextureRect = card.get_node("HBox/Badge")
		check(badge.custom_minimum_size.x == (128 if vp.x == 1280 else 112), "enlarged badge follows available height")
		check(panel._summary_label.visible == (vp.x == 1280), "short landscape reserves space for artwork")
		if vp.x != 1280:
			panel.set_save_result({"ok": false, "error": "R6_WRITE_DENIED"})
			for frame in 8: await process_frame
			check(badge.size.y + 8 <= panel._scroll.size.y, "save feedback still leaves complete badge visible")
			panel.set_save_result({"ok": true})
			panel.show_status_message("")
			for frame in 8: await process_frame
		var old_action := button.size.x
		var fake := AchievementSystem.get_achievement_view(abode.session.state)
		fake.achievements[4].rewards_desc = "道心 +999999999999999999999、道證 +999999999999"
		panel.update_view(fake)
		for frame in 5: await process_frame
		check(button.size.x == old_action, "long rewards do not move action width")
		panel.update_view(abode.session.get_view())
	panel.show_status_message("成就乃累世道業。")
	check(panel._status_label.visible, "status survives regular refresh")
	panel._close_button.pressed.emit()
	check(abode.feature_navigation.page.is_empty(), "close returns home")
	abode.queue_free()
	await process_frame
	print("UIX-R6 %d checks, failed=%s" % [checks, failed])
	RunnerResult.finish(self, 1 if failed else 0)
