extends Node
## Explicit isolated UI fixture; never claim natural progression.
var abode: Node
func _ready() -> void: _start.call_deferred()
func _start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null:
		await get_tree().process_frame
	for frame in 3: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	if not abode.session.state.tutorial_flags.get("uix_r8_fixture",false):
		abode.session.state.era_id = 2
		abode.session.state.buildings.library = 1
		abode.session.state.buildings.scripture_hall = 1
		SkillSystem.sync_unlock(abode.session.state)
		abode.session.state.resources.skill_point.value = AmountCompat.from_number(6200)
		abode.session.state.tutorial_flags.uix_r8_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		abode._save_game()
	abode._refresh_hud()
	abode.feature_navigation.open("skills")
	if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('r8long')", true)) == "1":
		var view: Dictionary = abode.session.get_view().duplicate(true)
		view.skills.available = "123456789012345678901234567890"
		view.skills.items[0].name = "基礎冥想・長名稱閱讀與換行驗收"
		abode.feature_navigation.action_panel.skill_view.refresh(view)
