extends Node
## Explicit isolated UI fixture, not a natural progression claim.
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
	var exhaustion_fixture := OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('r7f1')", true)) == "1"
	if not abode.session.state.tutorial_flags.get("uix_r7_fixture",false):
		abode.session.state.dao_heart = AmountCompat.from_number(50)
		abode.session.state.buildings.rebirth_lotus = 1
		abode.session.state.tutorial_flags.uix_r7_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		if exhaustion_fixture:
			# Explicit fixture: five seconds before expiry; actual Session time triggers the UI.
			abode.session.state.total_elapsed_seconds = Lifespan.max_lifespan_seconds(abode.content.era_lifespan_entries(), 1, 0.0, 0.0) - 5.0
		abode._save_game()
	abode._refresh_hud()
	if exhaustion_fixture:
		abode.set_process(true)
	else:
		abode.feature_navigation.open("reincarnation")
