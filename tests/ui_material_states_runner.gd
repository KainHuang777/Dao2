extends SceneTree
## UI semantics regression: full materials must not bypass prerequisites.
var failed := false

func _init() -> void:
	_run.call_deferred()

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	var catalog = load("res://src/presentation/building_catalog.gd").new()
	catalog.theme = UiTypography.create_theme()
	root.add_child(catalog)
	catalog.configure_resources({"wood": "靈木", "money": "金錢"}, ["wood", "money"])
	catalog.configure([{"id": "core", "title": "測試", "entries": [{"id": "hut", "title": "茅屋", "role": "產出"}]}])
	catalog.set_layout_bounds(Rect2(0, 0, 380, 450))
	var resources := {"wood": {"value": "25", "visible": true}, "money": {"value": "100", "visible": true}}
	var entry := {"visible": true, "level": 0, "level_cap": 10, "costs": {"wood": "100", "money": "100"}, "affordable": false}
	catalog.refresh({"hut": entry}, resources)
	await process_frame
	var meter: ProgressBar = catalog.progress_bars.hut.bg
	_expect(is_equal_approx(meter.value, 0.25), "Demand meter uses the least sufficient material, not an average")
	_expect(catalog.upgrade_buttons.hut.disabled, "Partial materials keep construction disabled")
	_expect(meter.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Demand decoration does not steal row input")
	_expect(meter.position.x > 0 and meter.position.y + meter.size.y < catalog.rows.hut.size.y, "Meter stays inside authored borders")
	resources.wood.value = "100"
	entry.prereq = {"building": "wooden_house", "level": 2}
	catalog.refresh({"hut": entry}, resources)
	_expect(is_equal_approx(meter.value, 1.0), "Full materials show a full requirement meter")
	_expect(catalog.upgrade_buttons.hut.disabled and catalog.upgrade_buttons.hut.text == "前置不足", "Full meter does not enable a blocked command")
	_expect(catalog.rows.hut.text.contains("前置不足"), "Blocked state has a visible text label")
	entry.affordable = true
	catalog.refresh({"hut": entry}, resources)
	_expect(not catalog.upgrade_buttons.hut.disabled and catalog.upgrade_buttons.hut.text == "建造", "Domain affordability enables construction")
	_expect(catalog.rows.hut.text.contains("可建"), "Ready state remains readable without color")
	entry.level = 10
	entry.affordable = false
	catalog.refresh({"hut": entry}, resources)
	_expect(not meter.visible and catalog.upgrade_buttons.hut.disabled, "Capped rows hide progress and reject upgrades")
	entry.level = 1
	resources.wood.value = "0"
	catalog.refresh({"hut": entry}, resources)
	_expect(meter.visible and is_zero_approx(meter.value), "After refresh the old ready/full state is cleared")
	_expect(catalog.rows.hut.get_theme_stylebox("normal") is StyleBoxTexture, "Paper material survives status refreshes")
	catalog.queue_free()
	await process_frame
	var sect := SectPanel.new()
	sect.theme = UiTypography.create_theme()
	root.add_child(sect)
	var state := GameState.new()
	state.era_id = 2
	SectSystem.join_sect(state, "紫霄玄門")
	sect.update_view(state)
	for bounds in [Rect2(0, 0, 620, 600), Rect2(0, 0, 580, 330)]:
		sect.set_layout_bounds(bounds)
		await process_frame
		await process_frame
		_expect(sect._scroll.position.y < sect.size.y and sect._scroll.get_rect().end.y <= sect.size.y, "Wrapped header must leave the sect scroll content within panel bounds")
	sect.queue_free()
	await process_frame
	if not failed:
		print("PASS: material demand ratio, prerequisites, ready/capped/reset states, borders and input isolation")
	quit(1 if failed else 0)
