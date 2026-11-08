extends SceneTree
## A blank startup plus a funded Era2 presentation fixture, both in isolated storage.

const Abode = preload("res://src/abode/living_abode.gd")
const Play = preload("res://src/economy/economy_play_session.gd")
const LegacyMarker := "legacy untouched"

class EconomyAbode extends Abode:
	func _requested_economy_edition() -> bool:
		return true

var _failures: Array[String] = []
var _checks := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	Abode.save_dir_override = RunnerResult.output_path("res://econ-r1-play")
	var legacy := FileStorageAdapter.new(Abode.save_dir_override)
	var adapter := FileStorageAdapter.new(Abode.save_dir_override.path_join("econ-r1-frontier"))
	_check(legacy.write(SaveSlots.SLOT_MAIN, LegacyMarker).ok, "isolated legacy sentinel written")
	var loaded := EconomySlice.create_frontier()
	var abode := EconomyAbode.new()
	root.add_child(abode)
	var entry := abode.get_node_or_null("StartupAction")
	_check(entry != null and abode.session == null, "fresh profile requires explicit action")
	if entry == null:
		_finish()
		return
	_check(not EconomyProfileStorage.new(adapter).exists(SaveSlots.SLOT_MAIN), "entry has not written")
	var create: Button = entry.find_children("*", "Button", true, false)[0]
	_check(create.text == "建立工藝新檔" and create.custom_minimum_size.y >= 44, "new edition action")
	create.pressed.emit()
	await process_frame
	_check(abode.session is Play and abode.session.state.era_id == 1, "normal scene uses blank frontier profile")
	_check(FeatureUnlocks.check("research", abode.session.get_view()).state == FeatureUnlocks.State.HIDDEN, "Era1 route gated")
	_check(abode._modal_manager._record_tutorial("aspired_realm", "realm_spirit"), "presentation preference commits through profile")
	_check(not abode._modal_manager._record_tutorial("aspired_realm", "unknown"), "unknown aspiration rejected")
	abode.queue_free()
	await process_frame
	var opened := EconomyProfile.open(loaded.content, adapter, loaded.catalog)
	var profile: EconomyProfile = opened.profile
	_check(profile.committed_game().state.tutorial_flags.aspired_realm == "realm_spirit", "presentation preference survives decoder")
	var fixture := profile.committed_game()
	fixture.state.era_id = 2
	fixture.state.onboarding_version = 0
	fixture.state.buildings.hut = 2
	fixture.state.buildings.stone_mine = 3
	fixture.state.buildings.research_seat = 1
	for id in ["wood", "stone_low", "money", "black_copper"]:
		fixture.state.resources[id].value = AmountCompat.from_number(60)
		fixture.state.resources[id].unlocked = true
	_check(profile._stage(fixture, ResearchSystem.initial(), {"ok":true}, Play.now_ms()).ok, "funded UI fixture staged")
	var fixture_save: Dictionary = SaveSlots.new(EconomyProfileStorage.new(adapter)).read_best(profile._revision_of)
	var fixture_file := FileAccess.open(RunnerResult.output_path("res://econ-r1-play/browser-era2.json"), FileAccess.WRITE)
	fixture_file.store_string(fixture_save.json)
	fixture_file.close()
	abode = EconomyAbode.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	var nav: RefCounted = abode.feature_navigation
	var session: Play = abode.session
	_check(nav != null and session.state.era_id == 2, "startup continues the existing profile")
	var blocked := session.submit({"command_id":"blocked", "type":"open_island", "expected_revision":session.state.revision, "payload":{"island_id":"herb"}})
	_check(not blocked.ok and session.state.economy.is_empty(), "failed first opening rolls back activation")
	nav.open("outposts")
	nav._on_island_action("open_island", {"island_id":"wood"})
	_check(IslandEconomy.hub(session.state) and session.state.economy.islands.wood.opened, "first opening activates hub and opens island together")
	_check(session.get_view().transport.wood_home.settings.enabled, "first opening also commits automatic wood shipping")
	_check(session.get_view().manufacturing.recipes.spirit_timber.reason == "RESEARCH_REQUIRED:R01", "automatic shipping leaves recipe research gate in place")
	nav.open("research")
	await process_frame
	var panel: Control = nav.research_panel
	var row: Dictionary = panel._rows.R01
	_check(panel.visible and not panel._close.visible and nav.back_button.visible, "research uses shared workbench and close")
	_check(row.start.custom_minimum_size.y == 44 and not row.start.disabled, "ready R01 has actionable 44px control")
	_check("工時 120 → 120 秒" in row.detail.text and "靈木" in row.detail.text, "research quote and payment shown")
	_check(not panel._rows.R14.root.visible, "future research stays undiscovered")
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		abode._layout_for_size(Vector2(vp))
		await process_frame
		await process_frame
		var work: RefCounted = nav.shell.workbench
		_check(work.panel.get_global_rect().encloses(nav.back_button.get_global_rect()), "canonical close stays inside paper " + str(vp))
		_check(panel.get_global_rect().encloses(panel._cancel.get_global_rect()), "fixed research control stays inside " + str(vp))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(RunnerResult.output_path("res://econ-r1-play/research-%dx%d.png" % [vp.x, vp.y]))
	var wood: float = session.state.resources.wood.value.to_float()
	row.start.pressed.emit()
	_check(session.state.resources.wood.value.to_float() == wood - 30.0, "R01 pays once")
	_check(session.profile.research_view().state.job.id == "R01", "paid work is active")
	var reopened := EconomyProfile.open(loaded.content, adapter, loaded.catalog)
	_check(reopened.ok and reopened.profile.research_view().state.job.id == "R01", "paid work reopens through decoder")
	var baseline: EconomyProfile = reopened.profile
	var cursor := baseline.settled_until() + 121000
	var sync := baseline.settle_to(cursor)
	# Use a separate adapter with exact pre-settlement bytes for async comparison.
	var fixture_slots := EconomyProfileStorage.new(FileStorageAdapter.new(Abode.save_dir_override.path_join("async")))
	_check(fixture_slots.write(SaveSlots.SLOT_MAIN, session.profile._source).ok, "async source isolated")
	var alternate := EconomyProfile.open(loaded.content, fixture_slots._base, loaded.catalog)
	var async_result: Dictionary = await alternate.profile.settle_to_async(cursor, self, func(_done: int, _total: int): pass)
	_check(sync.ok and async_result.ok and baseline.research_view() == alternate.profile.research_view(), "sync and frame-yielded settlement agree")
	_check(SectLifeSave.same(baseline.committed_game().state.to_snapshot_dict(), alternate.profile.committed_game().state.to_snapshot_dict()), "all committed settlement fields agree")
	_check(baseline.committed_game().state.total_elapsed_seconds == alternate.profile.committed_game().state.total_elapsed_seconds, "settlement age agrees")
	_check(baseline.committed_game().get_view().manufacturing.recipes.spirit_timber.reason == "FACILITY_REQUIREMENT", "completed R01 exposes next facility gate")
	_check(legacy.read(SaveSlots.SLOT_MAIN).data == LegacyMarker, "legacy sentinel preserved")
	abode.queue_free()
	await process_frame
	_finish()

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok: _failures.append(label)

func _finish() -> void:
	Abode.save_dir_override = ""
	print("ECON-R1-E checks=%d failures=%s" % [_checks, JSON.stringify(_failures)])
	RunnerResult.finish(self, 0 if _failures.is_empty() else 1)
