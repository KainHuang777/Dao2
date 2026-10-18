extends Node
## Isolated export only. Does not seed normal player progress.
var abode: Node
func _ready() -> void: _start.call_deferred()
func _start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null: await get_tree().process_frame
	for frame in 3: await get_tree().process_frame
	abode.offline_summary.hide()
	if not abode.session.state.tutorial_flags.get("uix_r11_fixture", false):
		abode.session.state.era_id = 2
		abode.session.state.buildings.hut = 1
		abode.session.state.tutorial_flags.uix_r11_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		abode.session.state.fortune.cooldown_remaining = 1800
		for id in abode.content.resource_ids:
			abode.session.state.resources[id].value = AmountCompat.from_number(1000)
		abode._save_game()
	abode._refresh_hud()
	abode.feature_navigation.open("decisions")
	if OS.has_feature("web"):
		var scenario := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('r11case')", true))
		if scenario in ["spirit", "long"]:
			abode.session.switch_realm("realm_spirit")
			abode._refresh_hud()
		if scenario == "long":
			abode.set_process(false)
			var view: Dictionary = abode.session.get_view()
			view.realm_decisions[1].name = "仙池靈露催熟・長標題與代價閱讀驗收".repeat(3)
			view.resources.money.value = "123456789012345678901234567890"
			abode.feature_navigation.action_panel.refresh(view)
