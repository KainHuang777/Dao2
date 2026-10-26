extends SceneTree
const DIR := "res://docs/verification/artifacts/content-p2-talents-ui/"
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("UI FAILURE ",label)
func frames() -> void:
	for i in 8: await process_frame
func run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://talent2-ui-runner"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.session.state.reincarnation_count = 1
	abode.session.state.highest_era = 4
	var page: ReincarnationPanel = abode.reincarnation_panel
	abode.feature_navigation.open("reincarnation")
	page._switch_tab("talents")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		abode.feature_navigation.open("reincarnation")
		page._switch_tab("talents")
		await frames()
		check(page._talent_rows.size() == 9,"nine cards")
		check(page._talents_button is GameTab and page._close_button is CloseSeal,"shared controls")
		for gate in ["rebirth","highest","budget","eligible","max"]:
			var s: GameState = abode.session.state
			s.reincarnation_count = 0 if gate == "rebirth" else 1
			s.highest_era = 3 if gate == "highest" else 4
			s.dao_heart = AmountCompat.from_number(5 if gate == "budget" else 1000)
			s.talents = {}
			if gate == "max":
				for id in TalentSystem.P2_IDS: s.talents[id] = 5
			page.refresh(abode.session.get_view())
			await frames()
			for id in TalentSystem.P2_IDS:
				var row: PanelContainer = page._talent_rows[id]
				var button: Button = row.find_child("LearnButton",true,false)
				var desc: Label = row.find_child("TalentDesc",true,false)
				check(button.disabled == (gate != "eligible"),"rule gate "+gate+" "+id)
				check(button.text == {"rebirth":"需首次輪迴","highest":"需最高元嬰","budget":"道心不足","eligible":"參悟","max":"圓滿"}[gate],"visible reason "+gate+" "+id)
				if gate != "eligible": continue
				check(row.find_child("TalentArt",true,false).texture != null,"art "+id)
				check("→" in desc.text and "目前加成：" not in desc.text,"specific next effect "+id)
				check(button.size.x >= 44 and button.size.y >= 44,"44px "+id)
				page._body_scroll.ensure_control_visible(row)
				await frames()
				check(page._body_scroll.get_global_rect().encloses(button.get_global_rect()),"reachable "+id)
				check(row.size.x <= page._body_scroll.size.x+1 and row.size.y <= page._body_scroll.size.y,"card fits "+id)
				check(desc.size.y >= desc.get_minimum_size().y,"description not clipped "+id)
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(DIR+"native-"+str(vp.x)+"-"+id+".png")
		abode.feature_navigation.home()
		check(not page.visible,"return home")
		abode.feature_navigation.open("reincarnation")
	var file := FileAccess.open(DIR+"ui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("TALENT-2 UI ",checks," checks failures=",JSON.stringify(failures))
	abode.queue_free()
	await frames()
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
