extends Node
## Isolated synthetic Era6 scene for desktop mouse presentation checks; paused rule clock.
var abode: Node
var ready_review := false
func _ready() -> void: start.call_deferred()
func start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 12: await get_tree().process_frame
	abode.set_process(false)
	var diagnostic := GameSession.create_new_game(abode.content)
	diagnostic.state.era_id = 6
	diagnostic.submit({"type":"activate_islands","command_id":"world46-review","expected_revision":0,"payload":{}})
	for id in diagnostic.state.economy.islands: diagnostic.state.economy.islands[id].opened = true
	abode.session.state = diagnostic.state
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode._refresh_hud()
	abode.feature_navigation.home()
	abode.island_world.enter("deep")
	ready_review = true
func scan(node: Node, result: Array) -> void:
	if node is Button and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		result.append({"text":node.text,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"disabled":node.disabled})
	for child in node.get_children(): scan(child,result)
func _process(_delta: float) -> void:
	if not ready_review: return
	abode.set_process(false)
	abode.island_world.refresh()
	var controls := []
	scan(abode.hud,controls)
	var data := {"current":abode.island_world.current,"route":abode.feature_navigation.page,"group":abode.feature_navigation.group,"island":abode.feature_navigation.island_panel.island,"buttons":controls,"viewport":get_viewport().get_visible_rect().size}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState("+JSON.stringify(data)+")",true)
