extends Node
## Explicit display fixture. Never included in normal Web export.
var abode: Node
var claim_clicks := 0

func _ready() -> void:
	_start.call_deferred()

func _start() -> void:
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	# Web _ready awaits its storage lock; a single frame is insufficient.
	while abode.feature_navigation == null or abode.session == null:
		await get_tree().process_frame
	for frame in 3: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	# Isolated origin only: prepare a real eligible achievement, not a natural-flow test.
	abode.session.state.buildings.hut = 1
	AchievementSystem.check_achievements(abode.session.state)
	abode._refresh_hud()
	abode.feature_navigation.open("achievements")
	abode.achievement_panel.claim_requested.connect(func(_id: String):
		claim_clicks += 1
		_apply_text.call_deferred())
	_apply_text()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_report)
	add_child(timer)
	timer.start()

func _apply_text() -> void:
	var view: Dictionary = AchievementSystem.get_achievement_view(abode.session.state)
	for item in view.achievements:
		if item.id == "build_first_hut":
			item.name = "仙家草廬・累世洞府營造功業驗收長標題"
			item.rewards_desc = "道心 +999999999999999999999、道證 +999999999999、靈木 +999999999999999999999"
	abode.achievement_panel.update_view(view)
	abode.achievement_panel._filters._buttons[2].pressed.emit()

func _rect(control: Control) -> Array:
	var r := control.get_global_rect()
	return [r.position.x, r.position.y, r.size.x, r.size.y]

func _report() -> void:
	if not OS.has_feature("web"): return
	var panel: AchievementPanel = abode.achievement_panel
	var card: Control = panel._achievement_items.build_first_hut
	var report := {"fixture": "display-only long title/reward; real reward remains wood100", "viewport": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y], "panel": _rect(panel), "scroll": _rect(panel._scroll), "card": _rect(card), "reward": _rect(card.get_node("HBox/Info/Reward")), "action": _rect(card.get_node("HBox/Action")), "close": _rect(abode.feature_navigation.back_button), "claim_clicks": claim_clicks, "claimed": abode.session.state.achievements.claimed.has("build_first_hut"), "page": abode.feature_navigation.page}
	var script := "var p=document.getElementById('r6-evidence');if(!p){p=document.createElement('pre');p.id='r6-evidence';p.hidden=true;document.body.appendChild(p);}p.textContent=%s;" % JSON.stringify(JSON.stringify(report))
	JavaScriptBridge.eval(script)
