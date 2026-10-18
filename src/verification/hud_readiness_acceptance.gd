extends Node
## Isolated explicit level5/material fixture; never seeds the player origin.
var abode: Node
func _ready() -> void: _start.call_deferred()
func _start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for frame in 3: await get_tree().process_frame
	abode.offline_summary.hide()
	if not abode.session.state.tutorial_flags.get("hud_readiness_fixture",false):
		var s: GameState = abode.session.state
		s.level = 5
		s.training_seconds = Cultivation.next_level_required_seconds(abode.content.era(1),5,0.0,1.0)
		for id in ["hut","storage_lingli","storage_wood","storage_stone","stone_mine"]: s.buildings[id] = 1
		for id in ["lingli","wood","stone_low"]:
			s.resources[id].value = AmountCompat.from_number(200 if id != "stone_low" else 38)
			s.resources[id].unlocked = true
		s.tutorial_flags.hud_readiness_fixture = true
		s.tutorial_flags.seen_nine_realms_hook = true
		abode._save_game()
	abode._refresh_hud()
	if OS.has_feature("web"):
		var stage := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('life')",true))
		var samples := {"green":0.0,"yellow":1600.0,"orange":3200.0,"red":4320.0,"expired":4800.0}
		if samples.has(stage):
			abode.set_process(false)
			var view: Dictionary = abode.session.get_view().duplicate(true)
			view.total_elapsed_seconds = samples[stage]
			view.max_lifespan_seconds = 4800.0
			abode._hud_controller._refresh_hud(view)
