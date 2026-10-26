extends SceneTree
const P2_SKILL_IDS := ["nascent_soul_incubation", "nascent_soul_mastery", "heavenly_craft", "deep_vein_resonance", "void_expansion", "spirit_transformation", "ancient_herb_attunement", "spirit_sea_breath", "void_mastery", "void_refinement", "void_essence_attunement", "frontier_storekeeping"]
var checks := 0
var failed := false
class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new(("user://uix-r8-fault" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("uix-r8-fault")))
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok":false,"error":"R8_WRITE_DENIED"} if fail_writes else backend.write(key,value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(label)
func frames() -> void:
	for n in 12: await process_frame
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = ("user://uix-r8-runner" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("uix-r8-runner"))
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var nav = abode.feature_navigation
	nav.open("skills")
	var panel = nav.action_panel
	var page = panel.skill_view
	check(page.cards.size() == 24, "twenty-four skill cards")
	var scope_closed := 0
	for item in abode.session.get_view().skills.items:
		if not P2_SKILL_IDS.has(item.id):
			continue
		check(page.cards[item.id].scope.visible and page.cards[item.id].scope.text.begins_with("作用：" + String(item.scope)), "scope card text: " + item.id)
		if not bool(item.scope_open):
			check(page.cards[item.id].scope.text.contains("收益 0"), "closed local island shows zero: " + item.id)
			scope_closed += 1
	check(scope_closed > 0, "closed local island evidence exists")
	check(page.buttons["skill:basic_meditation"].disabled, "Era1 unavailable")
	abode.session.state.era_id = 2
	abode._refresh_hud()
	check(page.buttons["skill:basic_meditation"].disabled, "library required")
	abode.session.state.buildings.library = 1
	SkillSystem.sync_unlock(abode.session.state)
	abode._refresh_hud()
	check(page.buttons["skill:basic_meditation"].text == "點數不足", "point shortage")
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(abode.content,adapter)
	abode.session.state.resources.skill_point.value = AmountCompat.from_number(6200)
	abode._refresh_hud()
	var button: Button = page.buttons["skill:basic_meditation"]
	adapter.fail_writes = true
	button.pressed.emit()
	check(abode.session.state.skills.basic_meditation == 1 and abode.session.state.resources.skill_point.value.to_float() == 6110, "real learn deducts90")
	check(panel.save_failed and panel.retry_button.visible, "save denial offers retry")
	var snapshot: Dictionary = abode.session.state.to_snapshot_dict()
	panel.retry_button.pressed.emit()
	check(snapshot == abode.session.state.to_snapshot_dict() and panel.save_failed, "denied retry cannot learn twice")
	adapter.fail_writes = false
	panel.retry_button.pressed.emit()
	check(not panel.save_failed and not panel.retry_button.visible and snapshot == abode.session.state.to_snapshot_dict(), "retry saved without mutation")
	check(page.buttons["skill:basic_meditation"] == button, "refresh retains mouse target")
	check(page.cards.basic_meditation.effect.text.contains("1.100") and page.cards.basic_meditation.effect.text.contains("1.210"), "current and next cumulative multiplier")
	SaveManager.configure(abode.content,ToggleAdapter.new())
	var loaded: Variant = SaveManager.load_state()
	check(loaded != null and loaded.skills.basic_meditation == 1 and loaded.resources.skill_point.value.to_float() == 6110, "isolated disk reload")
	abode.session.state.skills.qi_storage_1 = 1
	abode._refresh_hud()
	check(page.buttons["skill:qi_storage_1"].disabled and page.buttons["skill:qi_storage_1"].text == "已滿級", "max level")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		check(panel.get_global_rect().encloses(page.scroll.get_global_rect()), "scroll within paper")
		check(page.scroll.size.y >= 64, "readable scroll height")
		for row_id in page.cards:
			var row: Dictionary = page.cards[row_id]
			check(row.art.texture != null, "painted skill art: " + row_id)
			check(row.card.size.x <= page.scroll.size.x + 1, "card fits width")
			check(row.action.size.y >= 44, "44px action")
		var y: float = page.heading.global_position.y
		page.scroll.scroll_vertical = 10000
		await frames()
		check(is_equal_approx(y,page.heading.global_position.y), "heading fixed")
		var last: Control = page.cards[page.cards.keys()[page.cards.size() - 1]].action
		check(page.scroll.get_global_rect().encloses(last.get_global_rect()), "last action reachable")
		check(last.get_global_rect().end.y <= panel.get_global_rect().end.y - (20 if vp.y >= 500 else 14) + 1, "bottom rod safety")
		panel.show_result("操作完成，進度已更新。")
		await frames()
		print("SKILL_FEEDBACK viewport=%s scroll=%s card=%s heading=%s panel=%s" % [vp,page.scroll.size,page.cards.golden_core_formation.card.size,page.heading.size,panel.size])
		check(page.scroll.size.y >= page.cards.golden_core_formation.card.size.y, "success feedback leaves a complete skill card")
		if vp.y < 500:
			check(not panel.status.visible and nav.shell.resource_button.tooltip_text.contains("操作完成") and nav.shell.resource_button.text.contains("已更新"), "compact feedback merged in fixed shell resource summary")
		page.scroll.scroll_vertical = 0
		nav.home()
		check(not panel.visible, "home returns")
		nav.open("skills")
		await frames()
		check(not nav.bar.get_global_rect().intersects(abode.settings_menu.get_global_rect()), "reopen close clears settings")
	# A long future amount must wrap without moving the cost/action column.
	abode._layout_for_size(Vector2(1280,720))
	await frames()
	var view: Dictionary = abode.session.get_view()
	view.skills.available = "123456789012345678901234567890"
	page.refresh(view)
	await frames()
	check(page.heading.size.x <= page.size.x, "long amount wraps in header")
	page.buttons["study:"].pressed.emit()
	check(nav.page == "buildings", "existing study route")
	nav.open("beasts")
	check(not page.visible and panel.buttons.has("acquire:jade_fox"), "beasts shared mode preserved")
	nav.open("decisions")
	check(not page.visible and not panel.buttons.is_empty(), "decisions shared mode preserved")
	nav.open("skills")
	check(page.buttons.size() == 25 and panel.buttons.size() == 25, "skills buttons survive shared-mode roundtrip")
	abode.queue_free()
	await process_frame
	print("UIX-R8 %d checks failed=%s" % [checks,failed])
	RunnerResult.finish(self, 1 if failed else 0)
