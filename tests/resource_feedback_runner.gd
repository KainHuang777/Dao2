extends SceneTree
var failures: Array[String] = []
var checks := 0
func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	var s := GameSession.create_new_game(content)
	s.state.reincarnation_count = 3
	s.state.buildings.stone_mine = 3
	s.state.resources.stone_low.unlocked = true
	s.state.resources.stone_low.value = AmountCompat.from_number(3.22)
	var data := RealmSystem.ensure_spirit_data(s.state)
	data.outposts = {"celestial_hub": 10, "pure_pool": 10, "void_beacon": 0}
	data.spirit_crystal = 89.3
	data.azure_nectar = 50.0
	var previous := 3.22
	for i in range(600):
		TimeAdvancer.advance(s.state, content, 1)
		var current: float = s.state.resources.stone_low.value.to_float()
		check(current >= previous, "EAR1 passive stone never falls tick " + str(i))
		previous = current
	check(data.spirit_crystal == 89.3 and data.azure_nectar == 50, "inherited realm industry frozen in EAR1")
	check(RealmSystem.get_feedback_cultivation_boost(s.state) == 0, "EAR1 suspended realm has no passive boost")
	s.state.era_id = 2
	data.spirit_crystal = 100.0
	s.state.resources.stone_low.value = AmountCompat.from_number(20)
	RealmSystem.tick(s.state, 60)
	check(s.state.resources.stone_low.value.to_float() == 20 and data.spirit_crystal == 100, "both full outputs consume nothing")
	data.outposts.pure_pool = 0
	data.spirit_crystal = 99.95
	RealmSystem.tick(s.state, 10)
	check(is_equal_approx(s.state.resources.stone_low.value.to_float(), 19.9), "charge only output headroom")
	check(data.spirit_crystal == 100, "partial batch fills exactly")
	data.spirit_crystal = 0.0
	s.state.resources.stone_low.value = AmountCompat.from_number(0.01)
	RealmSystem.tick(s.state, 10)
	check(is_equal_approx(data.spirit_crystal, 0.005) and s.state.resources.stone_low.value.to_float() >= 0, "shortage uses available inputs without negative stock")
	var scene = load("res://src/abode/living_abode.gd")
	scene.save_dir_override = "user://resource_feedback_runner"
	var slots := SaveSlots.new(FileStorageAdapter.new(scene.save_dir_override))
	slots.reset()
	var abode = scene.new()
	root.add_child(abode)
	abode.set_process(false)
	await process_frame
	abode.offline_summary.visible = false
	abode.session.state.reincarnation_count = 3
	abode.session.state.dao_heart = AmountCompat.from_number(104)
	abode.session.state.dao_proof = 5
	abode.session.state.beast_souls = {"jade_fox": 2}
	RealmSystem.ensure_spirit_data(abode.session.state)
	abode._refresh_hud()
	for vp in [Vector2(1280, 720), Vector2(844, 390)]:
		abode._layout_for_size(vp)
		for mode in [0, 1, 2]:
			abode._set_resource_display_mode(mode)
			await process_frame
			var catalog = abode.building_catalog
			for id in ["realm_crystal", "realm_nectar", "dao_heart", "dao_proof", "soul_jade_fox"]:
				check(catalog.resource_buttons.has(id), "shared card exists " + id)
				check(catalog.resource_buttons[id].get_parent() == catalog.resource_grid, "shared scrolling layout " + id)
				check(not catalog.resource_gather_buttons[id].visible, "shared currency cannot gather " + id)
				check(catalog.resource_buttons[id].custom_minimum_size.y == (38 if mode == 1 else 56), "shared mode density " + id)
			check(catalog.resource_grid.visible == (mode != 0), "mode closes all resources")
			check(not catalog.resource_value_labels.dao_heart.text.contains("/0"), "uncapped currency never displays invalid capacity")
	# Reusing a projection must still update all resource display transitions.
	var catalog = abode.building_catalog
	var resources := {"wood": {"value": "4", "cap": "10", "rate": "1", "visible": true, "unlocked": true, "type": "basic"}}
	catalog.refresh({}, resources, 1)
	check(catalog.resource_gather_buttons.wood.visible and not catalog.resource_gather_buttons.wood.disabled, "EAR1 gathering stays available below cap")
	resources.wood.value = "10"
	catalog.refresh({}, resources, 1)
	check(catalog.resource_value_labels.wood.text.contains("滿倉") and catalog.resource_gather_buttons.wood.disabled, "reused projection reaches full stock immediately")
	resources.wood.value = "3"
	catalog.refresh({}, resources, 1)
	check(not catalog.resource_value_labels.wood.text.contains("滿") and not catalog.resource_gather_buttons.wood.disabled, "spending below cap clears full state")
	catalog.set_resource_display_mode(1)
	check(not catalog.resource_value_labels.wood.text.contains("/10"), "quantity mode drops capacity at unchanged stock")
	catalog.set_resource_display_mode(2)
	check(catalog.resource_value_labels.wood.text.contains("/10"), "full mode restores capacity at unchanged stock")
	catalog.refresh({}, resources, 2)
	check(not catalog.resource_gather_buttons.wood.visible, "Era change disables manual gathering at unchanged stock")
	resources.wood.visible = false
	catalog.refresh({}, resources, 2)
	check(not catalog.resource_buttons.wood.visible, "resource disappearance hides card")
	resources.wood.visible = true
	catalog.refresh({}, resources, 2)
	check(catalog.resource_buttons.wood.visible, "resource reappearance restores card")
	catalog.refresh_shared_resources({}, {})
	check(not catalog.resource_buttons.soul_jade_fox.visible, "removed shared soul hides its old card")
	catalog.refresh_shared_resources({"dao_heart": {"value": "7", "visible": true, "uncapped": true}}, {"dao_heart": "道心"})
	check(catalog.resource_value_labels.dao_heart.text.contains("7") and catalog.resource_buttons.dao_heart.visible, "shared currency reappears with current stock")
	# Debug refresh ignores revision; resize after a successful command observes revision.
	abode.session.state.dao_proof = 9
	abode._refresh_hud()
	check(catalog.resource_value_labels.dao_proof.text.contains("9"), "explicit debug refresh reads changed state")
	RuntimeProfile.enabled = true
	RuntimeProfile.begin_frame()
	abode._refresh_hud(false)
	check(not RuntimeProfile._spans.has("view_build"), "unchanged periodic HUD reuses guarded View")
	RuntimeProfile.end_frame()
	abode.session.state.dao_proof = 10
	abode.session.state.revision += 1
	RuntimeProfile.begin_frame()
	abode._refresh_hud(false)
	check(RuntimeProfile._spans.has("view_build") and catalog.resource_value_labels.dao_proof.text.contains("10"), "periodic HUD revision refresh reads current stock")
	RuntimeProfile.end_frame()
	RuntimeProfile.enabled = false
	abode.session.state.revision += 1
	var current_view: Dictionary = abode._presentation_view()
	check(current_view == abode.session.get_view(), "revision change invalidates guarded presentation View")
	var replacement := GameSession.create_new_game(content)
	abode.session.state = replacement.state
	check(abode._presentation_view() == abode.session.get_view(), "state replacement invalidates View even at repeated revision")
	abode._refresh_hud()
	check(not catalog.resource_buttons.dao_proof.visible, "new state removes prior shared progress from HUD")
	abode.free()
	slots.reset()
	if failures.is_empty():
		print("PASS: RESOURCE-FEEDBACK-R1 %d checks" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
