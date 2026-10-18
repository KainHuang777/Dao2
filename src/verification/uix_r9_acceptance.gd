extends Node
## Explicit isolated fixture, not evidence of natural progression or balance.
var abode: Node
func _ready() -> void: _start.call_deferred()
func _start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.feature_navigation == null or abode.session == null:
		await get_tree().process_frame
	for frame in 3: await get_tree().process_frame
	abode.offline_summary.hide()
	if not abode.session.state.tutorial_flags.get("uix_r9_fixture",false):
		abode.session.state.era_id = 2
		abode.session.state.buildings.hut = 1
		for id in abode.content.resource_ids:
			abode.session.state.resources[id].value = AmountCompat.from_number(10000)
		abode.session.state.tutorial_flags.uix_r9_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('r9funded')",true)) == "1":
			abode.session.join_sect("太虛天闕")
			abode.session.state.sect.contribution = "1000"
			abode.session.state.sect.available_tasks = [{"id":"r9_fixture_task","name":"巡視靈田","desc":"隔離測試資料","rarity":"common","rarity_name":"普通","duration":5,"elapsed":0,"rewards":{"contribution":80,"money":100}}]
		abode._save_game()
	abode._refresh_hud()
	abode.feature_navigation.open("sect")
	if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('r9long')",true)) == "1":
		abode.set_process(false)
		var panel: SectPanel = abode.sect_panel
		panel._cached_sect_data = abode.session.state.sect.duplicate(true)
		panel._cached_sect_data.unlocked = true
		panel._cached_sect_data.available_tasks = [{"id":"view_only","name":"宗門歷練・長名稱與長敘事閱讀驗收","desc":"這是只修改呈現資料的長文驗收，保留完整內捲與固定操作，不寫入玩家狀態。","duration":900,"rarity_name":"傳說","rewards":{"money":123456789012345,"contribution":600}}]
		panel._contrib_label.text = "貢獻：1.234568e29"
		panel._contrib_label.tooltip_text = "123456789012345678901234567890"
		panel._switch_tab(SectPanel.TabMode.EXPEDITIONS)
