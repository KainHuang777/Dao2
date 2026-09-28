extends SceneTree
## REF-A: regression coverage for scene facade, signal wiring and presentation-only operations.
## Optional --reference-script=res://... runs these same checks against a historical root script.
const TEST_DIR := "user://ref_a_presentation_saves"
var failed := false

func _init() -> void:
	_run.call_deferred()

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + message)

func _run() -> void:
	var script_path := "res://src/abode/living_abode.gd"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reference-script="):
			script_path = arg.trim_prefix("--reference-script=")
	var script = load(script_path)
	script.save_dir_override = TEST_DIR
	var slots := SaveSlots.new(FileStorageAdapter.new(TEST_DIR))
	slots.reset()
	var abode = script.new()
	abode.set_process(false)
	root.add_child(abode)
	await process_frame
	# Existing get_view/panels lazily initialize sect and realm presentation data.
	abode._toggle_sect_panel()
	abode._toggle_realm_modal()
	abode._toggle_sect_panel()
	abode._toggle_realm_modal()
	var initial: Dictionary = abode.session.state.to_snapshot_dict()
	var panels := ["save_controls", "reincarnation_panel", "alchemy_panel", "debug_panel", "realm_modal", "sect_panel"]
	var menu_ids := [2, 6, 7, 8, 9, 10]
	var identities := {}
	for key in panels:
		identities[key] = abode.get(key)
		_expect(abode.get(key).get_parent() == abode.hud, key + " keeps its original HUD parent")
	# Existing behavior permits simultaneous panels; do not introduce exclusive closing.
	for i in menu_ids.size():
		abode.more_menu.get_popup().id_pressed.emit(menu_ids[i])
		for j in range(i + 1):
			_expect(abode.get(panels[j]).visible, "opening another panel preserves existing visibility")
	for bounds in [Vector2(1280, 720), Vector2(844, 390), Vector2(360, 640), Vector2(360, 480)]:
		abode._layout_for_size(bounds)
		abode._refresh_hud()
		for key in panels:
			_expect(abode.get(key) == identities[key], "layout must not recreate public panel references")
	_expect(abode.session.state.to_snapshot_dict() == initial, "opening/layout/refresh must not mutate game state")
	for id in menu_ids:
		abode.more_menu.get_popup().id_pressed.emit(id)
	for key in panels:
		_expect(not abode.get(key).visible, "second toggle closes " + key)
	# Callbacks must still target the original root instance, once per signal.
	for spec in [["sect_panel", "join_sect_requested", "_on_sect_join_requested"], ["alchemy_panel", "refine_requested", "_on_alchemy_refine_requested"], ["realm_modal", "switch_realm_requested", "_on_switch_realm_requested"], ["reincarnation_panel", "reincarnate_requested", "_on_reincarnate_requested"]]:
		var connections: Array = abode.get(spec[0]).get_signal_connection_list(spec[1])
		_expect(connections.size() == 1, "exactly one scene callback for " + spec[1])
		if connections.size() == 1:
			_expect(connections[0].callable == Callable(abode, spec[2]), "original callback identity for " + spec[1])
	# Replacing the public session must not leave a controller holding stale state.
	var replacement := GameSession.create_new_game(abode.content)
	abode.session = replacement
	abode.state.session = replacement
	replacement.state.era_id = 2
	abode._refresh_hud()
	_expect(abode.realm_label.text.contains("築基"), "HUD reads the replacement session")
	replacement.state.dao_heart = AmountCompat.from_number(50.0)
	var revision: int = replacement.state.revision
	abode.reincarnation_panel.learn_talent_requested.emit("resource_inheritance")
	_expect(int(replacement.state.talents.get("resource_inheritance", 0)) == 1, "talent signal reaches the current session")
	_expect(replacement.state.revision == revision + 1, "talent signal submits exactly one command")
	_expect(replacement.state.dao_heart.to_float() == 45.0, "talent command deducts the original cost")
	_expect(SaveManager.current_state().to_snapshot_dict() == replacement.state.to_snapshot_dict(), "command result is saved before returning")
	var before_rejection: Dictionary = replacement.state.to_snapshot_dict()
	abode.alchemy_panel.refine_requested.emit("__missing_pill__", 1)
	_expect(abode.hint.text.begins_with("煉丹受阻"), "failed command dispatch preserves feedback")
	_expect(replacement.state.to_snapshot_dict() == before_rejection, "failed command preserves state")
	# GUI close actions must keep their existing internal hide + scene callback behavior.
	abode._toggle_sect_panel()
	abode.sect_panel._close_button.pressed.emit()
	_expect(not abode.sect_panel.visible, "sect close signal hides the panel")
	abode._toggle_debug_panel()
	abode._on_debug_closed()
	_expect(not abode.debug_panel.visible, "debug close restores closed state")
	abode.free()
	await process_frame
	_expect(not is_instance_valid(identities["save_controls"]), "scene teardown frees its panels")
	slots.reset()
	script.save_dir_override = ""
	if not failed:
		print("PASS: REF-A public facade, stacking, four layouts, signal identity, replacement session, save ordering and teardown.")
	quit(1 if failed else 0)
