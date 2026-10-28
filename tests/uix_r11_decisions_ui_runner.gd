extends SceneTree
var checks := 0
var failed := false
class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new(("user://uix-r11-fault" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("uix-r11-fault")))
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok":false,"error":"R11_WRITE_DENIED"} if fail_writes else backend.write(key,value)
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
	script.save_dir_override = ("user://uix-r11-runner" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("uix-r11-runner"))
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var nav = abode.feature_navigation
	nav.open("decisions")
	var panel = nav.action_panel
	var page = panel.decision_view
	check(page.cards.size() == 2 and page.heading.text.contains("人界"), "human realm only")
	for row in page.cards.values(): check(row.art.texture != null, "human art imported")
	check(page.buttons["decision:human_compile_dao_canon"].disabled, "resource shortage")
	for id in ["money", "wood", "lingli", "spirit_grass_low"]:
		abode.session.state.resources[id].value = AmountCompat.from_number(1000)
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(abode.content,adapter)
	abode._refresh_hud()
	var button: Button = page.buttons["decision:human_compile_dao_canon"]
	var snapshot: Dictionary = abode.session.state.to_snapshot_dict()
	for n in 30: panel.refresh(abode.session.get_view())
	check(button == page.buttons["decision:human_compile_dao_canon"] and snapshot == abode.session.state.to_snapshot_dict(), "refresh preserves target and state")
	adapter.fail_writes = true
	button.pressed.emit()
	check(abode.session.state.resources.money.value.to_float() == 950 and abode.session.state.resources.wood.value.to_float() == 970, "deduct50 money30 wood")
	check(abode.session.state.training_seconds == 60 and abode.session.state.buffs.has("insight_glow"), "training and buff applied")
	check(panel.save_failed and panel.retry_button.visible and button.disabled, "denial and cooldown visible")
	check(page.cards.human_compile_dao_canon.state.text.count("已施行") == 1, "execution count appears once")
	snapshot = abode.session.state.to_snapshot_dict()
	panel.retry_button.pressed.emit()
	check(snapshot == abode.session.state.to_snapshot_dict() and panel.save_failed, "denied retry cannot execute")
	adapter.fail_writes = false
	panel.retry_button.pressed.emit()
	check(not panel.save_failed and snapshot == abode.session.state.to_snapshot_dict(), "recovered retry only saves")
	SaveManager.configure(abode.content,ToggleAdapter.new())
	var loaded: Variant = SaveManager.load_state()
	check(loaded != null and loaded.realm_decisions.usage_counts.human_compile_dao_canon == 1 and loaded.resources.money.value.to_float() == 950, "fresh disk one execution")
	var result: Dictionary = abode.session.execute_realm_decision("realm_human", "human_compile_dao_canon")
	check(not result.ok and result.error == "COOLDOWN_ACTIVE", "duplicate during cooldown rejected")
	page.buttons["decision:human_irrigate_spiritual_vein"].pressed.emit()
	check(abode.session.state.resources.lingli.value.to_float() == 1100 and abode.session.state.resources.spirit_grass_low.value.to_float() == 1020, "canonical grants100 qi20 herbs")
	check(not abode.session.state.resources.has("herb") and not abode.session.state.resources.has("lingqi"), "no invisible legacy balances")
	abode.session.state.era_id = 2
	result = abode.session.switch_realm("realm_spirit")
	check(result.ok, "official spirit switch")
	abode._refresh_hud()
	check(page.cards.size() == 2 and page.cards.has("spirit_attune_lingchao") and page.heading.text.contains("靈界"), "switch replaces cards")
	result = abode.session.execute_realm_decision("realm_human", "human_compile_dao_canon")
	check(not result.ok and result.error == "REALM_MISMATCH", "foreign realm command rejected")
	abode.session.state.era_id = 1
	abode._refresh_hud()
	check(page.buttons["decision:spirit_attune_lingchao"].disabled and page.cards.spirit_attune_lingchao.state.text.contains("第 2 境"), "era gate in view")
	abode.session.state.era_id = 2
	abode._refresh_hud()
	page.buttons["decision:spirit_nurture_celestial_herb"].pressed.emit()
	check(abode.session.state.resources.spirit_grass_low.value.to_float() == 1080, "spirit grants60 canonical herbs")
	page.buttons["decision:spirit_attune_lingchao"].pressed.emit()
	check(abode.session.state.resources.spirit_crystal.value.to_float() == 5 and abode.session.state.resources.lingli.value.to_float() == 1400, "spirit grants crystals and canonical qi")
	RealmDecisionSystem.advance_time(abode.session.state, 301)
	abode._refresh_hud()
	check(not page.buttons["decision:spirit_attune_lingchao"].disabled, "cooldown expiry re-enables")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		var long_view: Dictionary = abode.session.get_view()
		long_view.realm_decisions[1].name = "仙池靈露催熟・長標題與代價閱讀驗收".repeat(3)
		long_view.resources.money.value = "123456789012345678901234567890"
		panel.refresh(long_view)
		await frames()
		check(panel.get_global_rect().encloses(page.scroll.get_global_rect()), "scroll within paper")
		print("R11 viewport=%s panel=%s content=%s feedback=%s" % [vp, panel.size, page.scroll.size, panel.status.size])
		check(page.scroll.size.y >= 64, "readable viewport")
		for row in page.cards.values():
			check(row.art.texture != null, "painted decision art")
			check(row.card.size.x <= page.scroll.size.x + 1, "card fits width")
			check(row.action.size.y >= 44, "44px action")
		var y: float = page.heading.global_position.y
		page.scroll.scroll_vertical = 10000
		await frames()
		check(is_equal_approx(y,page.heading.global_position.y), "heading fixed")
		var last: Control = page.cards.spirit_nurture_celestial_herb.action
		check(page.scroll.get_global_rect().encloses(last.get_global_rect()), "last action reachable")
		check(last.get_global_rect().end.y <= panel.get_global_rect().end.y - (20 if vp.y >= 500 else 14) + 1, "rod safety")
		for resource in page.cards.spirit_nurture_celestial_herb.costs.tiles:
			var tile = page.cards.spirit_nurture_celestial_herb.costs.tiles[resource]
			if tile.visible:
				check(tile.get_global_rect().end.x <= panel.get_global_rect().end.x, "large cost fits")
		page.scroll.scroll_vertical = 0
		nav.home()
		check(not panel.visible, "home returns")
		nav.open("decisions")
		await frames()
	nav.open("skills")
	check(panel.skill_view.visible and not page.visible, "skills mode retained")
	nav.open("beasts")
	check(panel.beast_view.visible and not panel._scroll.visible and not page.visible, "beasts mode retained")
	print("R11 %d checks failed=%s" % [checks, failed])
	abode.queue_free()
	await process_frame
	RunnerResult.finish(self, 1 if failed else 0)
