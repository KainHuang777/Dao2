extends SceneTree
## Real Session commands on isolated diagnostic state; native renders are optional.
var checks := 0
var failures: Array[String] = []
var abode: Node
var panel: Control
var commands: Array[String] = []

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var reject_write := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		if reject_write: return {"ok": false, "error": "MFG3 injected quota"}
		data[key] = payload
		return {"ok": true}
	func exists(key: String) -> bool: return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}

func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: " + label)
func settle() -> void:
	for frame in 5: await process_frame
func snap() -> String:
	return JSON.stringify(abode.session.state.to_snapshot_dict(), "", true)
func capture(name_text: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/verification/artifacts/mfg-3/native-%s.png" % name_text)

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://mfg3-inline-runner"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	abode = script.new()
	root.add_child(abode)
	await settle()
	abode.set_process(false)
	abode.offline_summary.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(decoded.ok, "diagnostic fixture decodes")
	abode.session.state = decoded.state.duplicate_state()
	var state: GameState = abode.session.state
	state.economy.jobs = {}
	state.economy.routes = {}
	state.economy.trips = {}
	for id in abode.content.processing_catalog.resources:
		ProcessingInventory.write(state, id, AmountCompat.from_number(1000 if id in IslandEconomy.GLOBAL else 50))
		state.resources[id].unlocked = true
	for id in ["wood", "ore", "herb"]:
		state.economy.islands[id].opened = true
		for resource in abode.content.processing_catalog.resources:
			if not resource in IslandEconomy.GLOBAL:
				state.economy.islands[id].inventory[resource] = "50"
	var adapter := MemoryAdapter.new()
	SaveManager.configure(abode.content, adapter)
	var encoded := SaveCodec.encode(state, abode.content.content_version, {"save_id": "mfg3-diagnostic", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": str(int(state.total_elapsed_seconds))})
	check(encoded.ok, "diagnostic browser fixture encodes")
	if encoded.ok:
		var fixture_file := FileAccess.open("res://docs/verification/artifacts/mfg-3/fixture.json", FileAccess.WRITE)
		fixture_file.store_string(encoded.json)
		fixture_file.close()
	abode._refresh_hud()
	abode.feature_navigation.open("manufacturing")
	panel = abode.feature_navigation.manufacturing_panel
	panel.action_requested.connect(func(kind: String, _payload: Dictionary): commands.append(kind))
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await settle()
		var before := snap()
		var row: RecipeRow = panel.cards.bronze_essence.row
		panel.production.set_pref("bronze_essence", ProductionController.Mode.COUNT, ProductionController.MAX_COUNT)
		panel.refresh(abode.session.get_view(), abode.content.processing_catalog)
		row.settings.pressed.emit()
		await settle()
		check(panel.selected_recipe == "bronze_essence" and panel.detail_box.get_parent() == row.column and panel.list_box.visible, "settings opens exactly once inline " + str(vp))
		check(panel.cards.spirit_timber.root.visible, "other recipes remain in list " + str(vp))
		check(row.modes._buttons[1].text == "批數" and panel.batch_count.value == ProductionController.MAX_COUNT, "large count stays exact in settings without widening chip " + str(vp))
		for button in row.modes._buttons + [row.action, row.settings]:
			check(button.size.y >= 44 and button.size.x >= 44, "44px row control " + str(vp))
			check(button.get_global_rect().position.x >= panel.position.x and button.get_global_rect().end.x <= panel.get_global_rect().end.x, "row control fits horizontally " + str(vp))
		check(panel.detail_box.get_global_rect().end.x <= panel.get_global_rect().end.x, "inline settings fit horizontally " + str(vp))
		await capture("settings-%dx%d" % [vp.x,vp.y])
		panel.cards.spirit_timber.row.settings.pressed.emit()
		await settle()
		check(panel.detail_box.get_parent() == panel.cards.spirit_timber.column and row.settings.text == "設定", "opening another closes first " + str(vp))
		panel.back_to_list()
		await settle()
		check(panel.selected_recipe.is_empty() and not panel.detail_box.visible and panel.list_box.visible, "accordion closes " + str(vp))
		check(snap() == before and commands.is_empty(), "settings/navigation do not submit commands " + str(vp))
		await capture("list-%dx%d" % [vp.x,vp.y])
	var timber: RecipeRow = panel.cards.spirit_timber.row
	timber.modes._buttons[1].pressed.emit()
	panel.batch_count.value = 3
	panel.reserves.stone_low.value = 2
	panel.back_to_list()
	panel.select_recipe("spirit_timber")
	check(panel.mode.selected == 1 and panel.batch_count.value == 3 and panel.reserves.stone_low.value == 2, "count and reserve draft survive collapse/reopen")
	panel.back_to_list()
	var before_count := commands.size()
	timber.action.pressed.emit()
	state = abode.session.state
	check(commands.size() == before_count + 1 and commands.back() == "craft", "one click submits exactly one start")
	check(state.economy.jobs.wood.batches == 2 and float(state.economy.jobs.wood.reserves.stone_low) == 2.0, "quick start uses count and reserve draft")
	check(panel.cards.spirit_timber.row.modes._buttons[1].button_pressed, "running row shows actual counted job")
	for tick in 30: IslandEconomy.tick(state, abode.content.processing_catalog)
	abode._refresh_hud()
	check(not state.economy.jobs.has("wood"), "counted quick start finishes exact batch count")
	timber.modes._buttons[2].pressed.emit()
	timber.action.pressed.emit()
	state = abode.session.state
	before_count = commands.size()
	timber.action.pressed.emit()
	state = abode.session.state
	check(commands.size() == before_count + 1 and commands.back() == "stop_processing", "one click submits exactly one stop")
	check(timber.action.disabled and timber.action.text == "本批收尾", "finishing cannot issue a no-op stop or open settings")
	for tick in 10: IslandEconomy.tick(state, abode.content.processing_catalog)
	abode._refresh_hud()
	IslandEconomy._put(state, "wood", "stone_low", 0)
	abode._refresh_hud()
	before_count = commands.size()
	timber.action.pressed.emit()
	check(timber.action.disabled and commands.size() == before_count and panel.selected_recipe.is_empty(), "shortage start is disabled and never opens settings")
	IslandEconomy._put(state, "wood", "stone_low", 50)
	abode._refresh_hud()
	adapter.reject_write = true
	timber.action.pressed.emit()
	state = abode.session.state
	check(panel.retry_button.visible and state.economy.jobs.has("wood"), "quick start save refusal stays retryable")
	before_count = commands.size()
	adapter.reject_write = false
	panel.retry_button.pressed.emit()
	check(commands.size() == before_count and not panel.retry_button.visible, "save retry does not replay quick start")
	var restored: GameState = SaveManager.load_state()
	check(restored != null and restored.economy.jobs.wood.repeat, "reload retains actual repeat job")
	check(state.economy.jobs.keys().size() == 1, "one job per island remains enforced")
	abode.queue_free()
	await settle()
	print("MFG3 checks=%d failures=%s" % [checks, failures])
	quit(0 if failures.is_empty() else 1)
