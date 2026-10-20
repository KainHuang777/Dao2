extends Node
## Isolated acceptance only: the normal build has no Era4 fixture or seeding.
const Fixture = preload("res://src/verification/trib0_fixture.gd")
var abode: Node
func _ready() -> void: _start.call_deferred()
func _start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null: await get_tree().process_frame
	for frame in 3: await get_tree().process_frame
	Fixture.attach(abode.content)
	abode.offline_summary.hide()
	if not abode.session.state.tutorial_flags.get("trib0_fixture", false):
		var success := false
		if OS.has_feature("web"):
			success = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('case')", true)) == "success"
		Fixture.seed_state(abode.session.state, success)
		abode.session.state.tutorial_flags.trib0_fixture = true
		abode.session.state.tutorial_flags.v2_rules_notice_seen = true
		abode.session.state.fortune.cooldown_remaining = 1800
		abode._save_game()
	abode._refresh_hud()
	print("TRIB0_FIXTURE_READY era=",abode.session.state.era_id," roll_index=",abode.session.state.tribulation_roll_index)
