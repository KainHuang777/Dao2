extends SceneTree
var checks := 0
var failures := []
func check(value: bool, note: String) -> void:
	checks += 1
	if not value: failures.append(note); print("FAIL ",note)
func _init() -> void: run.call_deferred()
func frames() -> void:
	for i in 6: await process_frame
func button(node: Node,value: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == value: return child
		var found := button(child,value)
		if found != null: return found
	return null
func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	SaveManager._content = content
	var s := SectLife.prepare(preload("res://tests/sect_reform_ui_fixture.gd").create(content))
	SectLife.advance(s,300,true)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280,720)
	var panel := SectPanel.new()
	root.add_child(panel)
	panel.set_layout_bounds(Rect2(20,20,1240,640))
	panel.update_view(s)
	panel._switch_tab(SectPanel.TabMode.TOURNAMENT)
	await frames()
	check(panel._tournament.visible and not panel._scroll.visible and not panel._folio.visible,"single tournament work area")
	var before := s.to_snapshot_dict()
	var requests := []
	panel.tournament_requested.connect(func(action: String,payload: Dictionary): requests.append([action,payload]))
	var enter := button(panel,"報名入場")
	check(enter != null and enter.size.y >= 44,"entry 44px")
	check(panel._tournament.get_global_rect().encloses(enter.get_global_rect()),"entry in fixed footer")
	enter.grab_focus()
	SectLife.advance(s,1,true)
	panel.update_view(s)
	await frames()
	check(is_instance_valid(enter) and enter.has_focus(),"tick keeps focus")
	enter.pressed.emit()
	check(requests.size() == 1 and requests[0][0] == "enter_sect_tournament","UI emits command")
	before.sect.life.tenure_seconds += 1
	check(SectLifeSave.same(before,s.to_snapshot_dict()),"UI emits without state mutation")
	var id: String = s.sect.life.competition.current.id
	SectTournament.execute(content,s,"enter_sect_tournament",{"instance_id":id,"preparation":0})
	for stage in 3:
		panel.update_view(s)
		await frames()
		check(button(panel,"穩健") != null,"trial strategy visible")
		check(panel._tournament._status.visible and panel._tournament.get_global_rect().encloses(panel._tournament._status.get_global_rect()),"fixed risk summary remains visible")
		SectTournament.execute(content,s,"choose_sect_trial",{"instance_id":id,"stage":stage,"strategy":"steady"})
	panel.update_view(s)
	await frames()
	var claim := button(panel,"領取本屆獎勵")
	check(claim != null and panel._tournament.get_global_rect().encloses(claim.get_global_rect()),"claim fixed footer")
	panel.set_command_result({"ok":false,"error":"SECT_CORE_SAVE_REQUIRED"},{})
	panel._pending_save = true
	panel.update_view(s)
	await frames()
	check(button(panel,"領取本屆獎勵").disabled,"pending save blocks claim")
	panel._pending_save = false
	panel.update_view(s)
	await frames()
	var abandon := button(panel,"放棄本屆…")
	abandon.pressed.emit()
	await frames()
	check(button(panel,"確認放棄（無補償）") != null and requests.size() == 1,"abandon requires separate confirmation")
	panel.queue_free()
	await frames()
	SaveManager.reset_for_tests()
	print("SECT-TOURNAMENT-UI ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
