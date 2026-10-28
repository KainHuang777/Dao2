extends SceneTree
const Management = preload("res://src/presentation/island_management_panel.gd")
const Manufacturing = preload("res://src/presentation/manufacturing_panel.gd")
const Transport = preload("res://src/presentation/island_transport_panel.gd")
var actions := []
var checks := 0
var failures := []
class MemoryAdapter extends StorageAdapter:
	var data := {}
	var reject := false
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key,""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if reject: return {"ok":false,"error":"injected"}
		data[key] = value
		return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for i in 4: await process_frame
func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"supply attach")
	var old: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(old)
	var adapter := MemoryAdapter.new()
	var old_session := GameSession.create_new_game(old)
	SaveManager.configure(old,adapter)
	check(SaveManager.save(old_session.state,{"save_id":"supply3-test","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"}).ok,"isolated old save")
	SaveManager.configure(content,adapter)
	var candidate: GameState = SaveManager.load_state()
	var before := JSON.stringify(candidate.to_snapshot_dict())
	check(SaveManager.supply_pending(candidate),"startup migration pending")
	adapter.reject = true
	check(not SaveManager.commit_supply_startup().ok,"startup refusal")
	check(SaveManager.supply_pending(candidate) and before == JSON.stringify(candidate.to_snapshot_dict()),"refusal retains exact candidate")
	check(not OfflineCoordinator.settle_state(candidate,content,2000,1000).ok,"offline blocked before migration commit")
	adapter.reject = false
	check(SaveManager.commit_supply_startup().ok,"same candidate retry")
	check(SaveManager.last_settled_utc_ms() == 1000 and not SaveManager.supply_pending(candidate),"migration preserves old offline cursor")
	check(OfflineCoordinator.settle(2000).ok,"offline starts after commit")
	check(SaveManager.last_settled_utc_ms() == 2000,"cursor advances only after settlement")
	var session := GameSession.create_new_game(content)
	session.state.era_id = 6 # synthetic UI contract, not earned gameplay
	check(session.submit({"type":"activate_islands","payload":{},"command_id":"ui-activate","expected_revision":session.state.revision}).ok,"synthetic activation")
	for island in session.state.economy.islands: session.state.economy.islands[island].opened = true
	check(session.advance_time(2).ok,"new-island production advances")
	var roundtrip := SaveCodec.encode(session.state,content.content_version,{"save_id":"ui-scopes","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"2"})
	check(roundtrip.ok,"new-island accounts encode: "+str(roundtrip.get("error","")))
	if roundtrip.ok: check(SaveCodec.decode(roundtrip.json).ok,"new-island accounts decode")
	var boundary := GameSession.create_new_game(content)
	boundary.state.era_id = 4
	var old_limit: float = boundary.get_view().max_lifespan_seconds
	boundary.state.total_elapsed_seconds = old_limit + 1
	boundary.state.pill_effects.lifespan_bonus_years = 10.0
	check(boundary.advance_time(1).ticks_advanced == 1,"session honors extended lifespan beyond original limit")
	session.state.resources.stone_mid.value = AmountCompat.from_number(123)
	for focus_island in IslandEconomy.supply_data().dispatch:
		var focus: String = IslandEconomy.supply_data().dispatch[focus_island]
		for id in content.buildings[focus].base_cost:
			session.state.resources[id].value = AmountCompat.from_number(float(content.buildings[focus].base_cost[id]))
		session.state.economy.islands[focus_island].opened = false
		check(not session.get_view().buildings[focus].affordable and session.get_view().buildings[focus].required_island == focus_island,"dispatch blocked by own closed island "+focus)
		session.state.economy.islands[focus_island].opened = true
		check(session.get_view().buildings[focus].affordable,"dispatch affordable only after opening "+focus)
	var panel := Management.new()
	var manufacturing := Manufacturing.new()
	var transport := Transport.new()
	for node in [panel,manufacturing,transport]: root.add_child(node)
	transport.action_requested.connect(func(kind: String, payload: Dictionary): actions.append({"kind":kind,"payload":payload}))
	for viewport in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		# Each size verifies the same level-one starting policy independently.
		for id in IslandEconomy.supply_data().routes:
			session.state.economy.routes[id] = {"enabled":true,"level":1,"reserve":"0","target":"3000"}
		root.size = viewport
		for node in [panel,manufacturing,transport]:
			node.set_layout_bounds(Rect2(Vector2.ZERO,Vector2(viewport)-Vector2(80,160)))
			node.refresh(session.get_view(),content.processing_catalog)
		await frames()
		for island in ["deep","ancient","void"]:
			panel.select_island(island)
			await frames()
			check(panel.facility_buttons.is_empty(),"no fake remote workshops "+island)
			check(not panel.world_button.disabled,"opened island has layered world route "+island)
			check(panel.summary.text.contains("300"),"local capacity visible "+island)
			session.state.economy.islands[island].opened = false
			panel.refresh(session.get_view(),content.processing_catalog)
			check(panel.opening_tiles.keys() == IslandEconomy.supply_data().islands[island].cost.keys(),"approved opening costs "+island)
			session.state.economy.islands[island].opened = true
		manufacturing.refresh(session.get_view(),content.processing_catalog)
		check(manufacturing.cards.size() == 11,"eleven recipe rows")
		var card: Dictionary = manufacturing.cards.stone_mid_bulk
		check(card.output_tile.icon.resource_id == "stone_mid","bulk uses actual product tile")
		check(card.time.text.contains("123"),"bulk reads middle-stone stock")
		manufacturing.select_recipe("stone_mid_bulk")
		check(manufacturing.detail_stock.text.contains("123"),"bulk detail stock")
		check(transport.route_widgets.size() == 12,"twelve routes")
		for id in IslandEconomy.supply_data().routes:
			transport.select_route(id)
			check(transport.upgrade_button.text.contains("10→20"),"route level1 "+id)
			var paid: Dictionary = transport._info(id)
			check(transport.upgrade_costs.visible and transport.upgrade_costs.visible_tiles() == paid.upgrade_cost.size() and not transport.upgrade_button.text.contains("祖島支付"),"actual one-step payment "+id)
			session.state.economy.routes[id] = {"enabled":false,"level":2,"reserve":"7","target":"99"}
			transport.refresh(session.get_view(),content.processing_catalog)
			check(transport.upgrade_button.text.contains("20→30"),"route level2 "+id)
			transport.upgrade_button.pressed.emit()
			check(actions.back().payload.level == 3 and not actions.back().payload.enabled and actions.back().payload.reserve == "7" and actions.back().payload.target == "99","third level preserves committed policy "+id)
			session.state.economy.routes[id].level = 3
			transport.refresh(session.get_view(),content.processing_catalog)
			check(transport.upgrade_button.disabled,"third level cap "+id)
			check(transport.upgrade_button.size.y >= 44 or transport.upgrade_button.custom_minimum_size.y >= 44,"route hit size "+id)
		transport.back_to_list()
	var fallback_tile = preload("res://src/presentation/recipe_material_tile.gd").new()
	root.add_child(fallback_tile)
	fallback_tile.refresh("mithril", "秘銀", 5, 10, "祖島")
	check(not fallback_tile.caption.visible and fallback_tile.tooltip_text.contains("秘銀") and fallback_tile.tooltip_text.contains("祖島"),"unillustrated material retains full name and source in tooltip")
	fallback_tile.queue_free()
	var legacy_story := GameState.new()
	legacy_story.story_version = 0
	StoryProgress.next_life(legacy_story)
	check(not legacy_story.achievements.has("story"),"legacy next-life does not fabricate version-one facts")
	var current_story := GameState.new()
	current_story.story_version = StoryProgress.VERSION
	StoryProgress.ensure(current_story)
	current_story.reincarnation_count = 1
	StoryProgress.next_life(current_story)
	check(current_story.achievements.story.current_life_id == 2,"current story next-life still advances")
	var unopened := GameSession.create_new_game(content)
	unopened.state.era_id = 2
	transport.refresh(unopened.get_view(),content.processing_catalog)
	for id in IslandEconomy.supply_data().routes:
		transport.select_route(id)
		check(transport.save_button.disabled and transport.detail_status.text.contains("先啟用"),"unactivated future route read-only "+id)
	var report := {"level":"L1","checks":checks,"failures":failures}
	DirAccess.make_dir_recursive_absolute("res://docs/verification/artifacts/content-p2-supply-3")
	var write_file_ui := FileAccess.open(RunnerResult.output_path("res://docs/verification/artifacts/content-p2-supply-3/ui-contract.json"),FileAccess.WRITE)
	if write_file_ui == null:
		push_error("write failed: " + str("res://docs/verification/artifacts/content-p2-supply-3/ui-contract.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_ui.store_string(JSON.stringify(report,"\t"))
	print("SUPPLY-3 UI ",JSON.stringify(report))
	for node in [panel,manufacturing,transport]: node.queue_free()
	await frames()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)


