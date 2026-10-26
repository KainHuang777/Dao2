extends SceneTree
var checks := 0
var failures: Array[String] = []
class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new("user://ui-shell-1-fault")
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok": false, "error": "SHELL_WRITE_DENIED"} if fail_writes else backend.write(key, value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for n in 8: await process_frame
func capture(label: String, vp: Vector2i) -> void:
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("res://docs/verification/artifacts/ui-shell-1/%s-%sx%s.png" % [label,vp.x,vp.y])
func _run() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://ui-shell-1-runner"
	SaveSlots.new(FileStorageAdapter.new("user://ui-shell-1-runner")).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode._layout_for_size(Vector2(1280,720))
	var nav = abode.feature_navigation
	var shell = nav.shell
	abode._set_resource_display_mode(0)
	if shell.state.snapshot().home_preferences.messages_open: abode._toggle_guidance()
	var prefs: Dictionary = shell.state.snapshot().home_preferences
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(abode.content, adapter)
	abode.session.state.buildings.herb_farm = 3
	abode.session.state.resources.spirit_grass_low.value = AmountCompat.from_number(100)
	abode.session.state.resources.spirit_grass_low.unlocked = true
	abode.session.state.resources.spirit_grass_low.ever_obtained = true
	abode.session.state.resources.lingli.value = AmountCompat.from_number(200)
	abode._refresh_hud()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		nav.open("alchemy")
		abode._layout_for_size(Vector2(vp))
		await frames()
		capture("alchemy-inventory", vp)
		check(shell.compact_hud.visible and not abode.header.visible, "compact HUD %s" % vp)
		check(shell.compact_hud.get_global_rect().end.y <= nav.bar.position.y, "HUD clears tabs %s" % vp)
		check(not nav.bar.get_global_rect().intersects(abode.settings_menu.get_global_rect()), "settings clears tabs %s" % vp)
		check(abode.alchemy_panel._scroll.size.y >= 80, "recipe viewport %s" % vp)
		check(not abode.hint_panel.visible, "work hides home messages")
		check(shell.state.snapshot().home_preferences == prefs, "entry preserves preference")
		shell.collapse_button.pressed.emit()
		abode._refresh_hud()
		check(shell.state.snapshot().resources_collapsed and not abode.resource_ribbon.visible, "tick retains collapse")
		shell.resource_button.pressed.emit()
		await frames()
		check(shell.shield.visible and abode.resource_ribbon.visible and abode.camera.input_locked, "resource modal")
		capture("resources", vp)
		check(abode.resource_ribbon.z_index > shell.shield.z_index and shell.shield.z_index > nav.bar.z_index and shell.overlay_header.z_index > shell.shield.z_index, "modal draw and input order agree")
		check(not shell.effective.page_input, "resource modal blocks commands")
		check(abode.hud.get_child_count() - abode.resource_ribbon.get_index() <= 3, "resource above shield")
		nav.back()
		check(nav.page == "alchemy" and not shell.shield.visible, "drawer back retains page")
		shell.message_button.pressed.emit()
		await frames()
		check(abode.hint_panel.visible and shell.shield.visible, "message reading")
		capture("messages", vp)
		nav.back()
		check(nav.page == "alchemy" and shell.state.snapshot().home_preferences == prefs, "reading back retains preference")
		abode._toggle_save_controls()
		await frames()
		check(abode.save_controls.visible and nav.page == "alchemy", "save tool retains route")
		check(abode.save_controls._scroll.size.y > 80, "save tool scroll fits")
		capture("save-tool", vp)
		abode.save_controls.hide()
		check(not shell.shield.visible and nav.page == "alchemy", "native tool close returns route")
		abode._toggle_debug_panel()
		nav.back()
		check(not abode.debug_panel.visible and nav.page == "alchemy", "debug escape")
		if not DisplayServer.get_name() == "headless":
			await frames()
			root.get_texture().get_image().save_png("res://docs/verification/artifacts/ui-shell-1/alchemy-%sx%s.png" % [vp.x,vp.y])
		nav.home()
		await frames()
		check(abode.header.visible and not shell.compact_hud.visible, "home full HUD")
		check(shell.state.snapshot().home_preferences == prefs and abode.resource_display_mode == 0 and not abode.hint_panel.visible, "home restores closed preferences")
		if not DisplayServer.get_name() == "headless":
			root.get_texture().get_image().save_png("res://docs/verification/artifacts/ui-shell-1/home-%sx%s.png" % [vp.x,vp.y])
	# Real command + denied save + retry + reload; shell must not resubmit refine.
	nav.open("alchemy")
	adapter.fail_writes = true
	abode.alchemy_panel._widgets.cultivation_pill.refine.pressed.emit()
	check(shell.save_failed and shell.alert.visible, "save denial visible with messages closed")
	check(not shell.alert.get_global_rect().intersects(abode.alchemy_panel.get_global_rect()), "save alert reserves its own row")
	var snapshot: Dictionary = abode.session.state.to_snapshot_dict()
	abode._save_game()
	check(snapshot == abode.session.state.to_snapshot_dict(), "denied retry no second deduction")
	adapter.fail_writes = false
	abode._save_game()
	check(not shell.save_failed and snapshot == abode.session.state.to_snapshot_dict(), "save retry no mutation")
	var loaded: Variant = SaveManager.load_state()
	check(loaded != null and loaded.pills == abode.session.state.pills, "saved pill count reload")
	# Boundary roundtrip: legacy page does not take ownership of home preference.
	nav.open("skills")
	check(shell.managed() and shell.entry.visible, "all routes share shell")
	nav.open("alchemy")
	check(shell.managed() and shell.compact_hud.visible, "legacy return reapplies")
	# Replacement uses tokens without letting a tool's hide callback close reading.
	shell.open_tool(abode.save_controls)
	shell.toggle_overlay("messages")
	check(shell.state.snapshot().overlay == "messages" and not abode.save_controls.visible, "reading replaces tool atomically")
	shell.close_overlay()
	for mode in [0, 1, 2]:
		nav.home()
		abode._set_resource_display_mode(mode)
		var expected: Dictionary = shell.state.snapshot().home_preferences
		nav.open("alchemy")
		for vp in ([Vector2(1280,720), Vector2(844,390), Vector2(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280,720)]):
			abode._layout_for_size(vp)
			check(shell.state.snapshot().home_preferences == expected, "resize preserves all resource preferences")
		nav.home()
		check(abode.resource_display_mode == mode, "home restores all resource preferences")
		shell.toggle_overlay("resources")
		check(abode.resource_mode_buttons[0].get_parent().visible, "home drawer exposes mode controls")
		abode._set_resource_display_mode(0)
		check(shell.state.snapshot().overlay.is_empty(), "home close mode dismisses drawer")
	nav.open("alchemy")
	shell.open_tool(abode.save_controls)
	var stale: int = shell.state.snapshot().overlay_token
	abode._show_storage_block("隔離保存保護測試")
	check(shell.state.snapshot().overlay == "protection", "protection preempts tool")
	check(not shell.state.finish_overlay(stale, abode._presentation_view()), "stale tool cannot finish protection")
	nav.back()
	check(is_instance_valid(abode._storage_block_layer) and shell.state.snapshot().overlay == "protection", "Escape cannot dismiss protection")
	abode._storage_block_layer.queue_free()
	abode._storage_block_layer = null
	abode._layout_for_size(Vector2(800,360))
	check(shell.state.snapshot().overlay.is_empty(), "protection ends by lifecycle")
	abode.queue_free()
	await process_frame
	print("UI-SHELL-1 checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
