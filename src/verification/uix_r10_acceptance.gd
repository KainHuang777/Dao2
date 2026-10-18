extends Node
## Isolated fixture only, never natural progression evidence.
var abode: Node
func _ready() -> void: _start.call_deferred()
func _start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null: await get_tree().process_frame
	for frame in 3: await get_tree().process_frame
	abode.offline_summary.hide()
	if not abode.session.state.tutorial_flags.get("uix_r10_fixture",false):
		abode.session.state.era_id = 2
		abode.session.state.buildings.hut = 1
		abode.session.state.tutorial_flags.uix_r10_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		abode.session.state.fortune.cooldown_remaining = 1800
		for id in abode.content.resource_ids:
			abode.session.state.resources[id].value = AmountCompat.from_number(1000)
		for enc in FortuneSystem.get_encounters():
			if enc.id == "enc_wandering_taoist": abode.session.state.fortune.pending_encounter = enc.duplicate(true)
		abode._save_game()
	abode._refresh_hud()
	abode.feature_navigation.open("fortune")
	if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('r10long')",true)) == "1":
		abode.set_process(false)
		var view: Dictionary = abode.session.get_view()
		view.fortune.has_pending = true
		view.fortune.pending_encounter = FortuneSystem.get_encounters()[2].duplicate(true)
		view.fortune.pending_encounter.title = "天機奇遇・長敘事與長標題閱讀驗收"
		view.fortune.pending_encounter.desc = "山間雲霧散去，往事浮現；天地流轉，靜候修士抉擇。".repeat(80)
		view.resources.spirit_grass_low.value = "123456789012345678901234567890"
		abode.fortune_modal.refresh(view)
