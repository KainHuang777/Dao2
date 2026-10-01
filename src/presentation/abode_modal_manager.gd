extends RefCounted
## Secondary panels: creation, layout and event dispatch, preserving existing stacking.
## The scene facade owns public properties; callbacks stay bound to the scene.
## Node references are non-owning; no second session or persistent state is created.

var _abode: Node
var _text_camera_was_locked := false

func _init(abode: Node) -> void:
	_abode = abode

func create_panels() -> void:
	var save_ctrl_script = preload("res://src/presentation/save_controls.gd")
	_abode.save_controls = save_ctrl_script.new()
	_abode.save_controls.visible = false
	_abode.save_controls.position = Vector2(300, 100)
	_abode.hud.add_child(_abode.save_controls)

	var offline_sum_script = preload("res://src/presentation/offline_summary.gd")
	_abode.offline_summary = offline_sum_script.new()
	_abode.offline_summary.visible = false
	_abode.offline_summary.position = Vector2(300, 100)
	_abode.hud.add_child(_abode.offline_summary)

	var bt_seq_script = preload("res://src/presentation/breakthrough_sequence.gd")
	_abode.breakthrough_seq = bt_seq_script.new()
	_abode.hud.add_child(_abode.breakthrough_seq)
	_abode.breakthrough_seq.world_fx = _abode.island_fx
	_abode.breakthrough_seq.sequence_started.connect(_abode._on_breakthrough_sequence_started)
	_abode.breakthrough_seq.sequence_finished.connect(_abode._on_breakthrough_sequence_finished)
	_abode.breakthrough_seq.save_retry_requested.connect(_abode._retry_breakthrough_save)

	var rc_script = preload("res://src/presentation/reincarnation_panel.gd")
	_abode.reincarnation_panel = rc_script.new()
	_abode.reincarnation_panel.visible = false
	_abode.reincarnation_panel.reincarnate_requested.connect(_abode._on_reincarnate_requested)
	_abode.reincarnation_panel.learn_talent_requested.connect(_abode._on_learn_talent_requested)
	_abode.reincarnation_panel.close_requested.connect(_abode._on_reincarnation_closed)
	_abode.hud.add_child(_abode.reincarnation_panel)

	var rc_seq_script = preload("res://src/presentation/reincarnation_sequence.gd")
	_abode.reincarnation_seq = rc_seq_script.new()
	_abode.reincarnation_seq.visible = false
	_abode.reincarnation_seq.sequence_started.connect(_abode._on_reincarnation_sequence_started)
	_abode.reincarnation_seq.sequence_finished.connect(_abode._on_reincarnation_sequence_finished)
	_abode.hud.add_child(_abode.reincarnation_seq)

	var nr_script = preload("res://src/presentation/nine_realms_preview.gd")
	_abode.nine_realms_preview = nr_script.new()
	_abode.nine_realms_preview.aspiration_changed.connect(_abode._on_nine_realms_aspiration_changed)
	_abode.hud.add_child(_abode.nine_realms_preview)

	var alc_script = preload("res://src/presentation/alchemy_panel.gd")
	_abode.alchemy_panel = alc_script.new()
	_abode.alchemy_panel.visible = false
	_abode.alchemy_panel.refine_requested.connect(_abode._on_alchemy_refine_requested)
	_abode.alchemy_panel.consume_requested.connect(_abode._on_alchemy_consume_requested)
	_abode.alchemy_panel.close_requested.connect(_abode._on_alchemy_closed)
	_abode.hud.add_child(_abode.alchemy_panel)

	var sect_script = preload("res://src/presentation/sect_panel.gd")
	_abode.sect_panel = sect_script.new()
	_abode.sect_panel.visible = false
	_abode.sect_panel.join_sect_requested.connect(_abode._on_sect_join_requested)
	_abode.sect_panel.refresh_tasks_requested.connect(_abode._on_sect_refresh_tasks_requested)
	_abode.sect_panel.start_expedition_requested.connect(_abode._on_sect_start_expedition_requested)
	_abode.sect_panel.claim_expedition_requested.connect(_abode._on_sect_claim_expedition_requested)
	_abode.sect_panel.learn_technique_requested.connect(_abode._on_sect_learn_technique_requested)
	_abode.sect_panel.buy_market_item_requested.connect(_abode._on_sect_buy_market_item_requested)
	_abode.sect_panel.close_requested.connect(_abode._on_sect_closed)
	_abode.hud.add_child(_abode.sect_panel)

	var dbg_script = preload("res://src/presentation/debug_panel.gd")
	_abode.debug_panel = dbg_script.new()
	_abode.debug_panel.visible = false
	_abode.debug_panel.auto_build_toggled.connect(_abode._on_debug_auto_build_toggled)
	_abode.debug_panel.manual_upgrade_requested.connect(_abode._on_debug_manual_upgrade_requested)
	_abode.debug_panel.boost_era_level_requested.connect(_abode._on_debug_boost_era_level_requested)
	_abode.debug_panel.add_resources_requested.connect(_abode._on_debug_add_resources_requested)
	_abode.debug_panel.apply_buff_requested.connect(_abode._on_debug_apply_buff_requested)
	_abode.debug_panel.close_requested.connect(_abode._on_debug_closed)
	_abode.hud.add_child(_abode.debug_panel)

	var rlm_script = preload("res://src/presentation/realm_teleport_modal.gd")
	_abode.realm_modal = rlm_script.new()
	_abode.realm_modal.visible = false
	_abode.realm_modal.switch_realm_requested.connect(_abode._on_switch_realm_requested)
	_abode.realm_modal.upgrade_outpost_requested.connect(_abode._on_upgrade_outpost_requested)
	_abode.realm_modal.close_requested.connect(_abode._on_realm_modal_closed)
	_abode.hud.add_child(_abode.realm_modal)

	var ftn_script = preload("res://src/presentation/fortune_modal.gd")
	_abode.fortune_modal = ftn_script.new()
	_abode.fortune_modal.visible = false
	_abode.fortune_modal.trigger_requested.connect(_abode._on_fortune_trigger_requested)
	_abode.fortune_modal.resolve_requested.connect(_abode._on_fortune_resolve_requested)
	_abode.fortune_modal.close_requested.connect(_abode._on_fortune_closed)
	_abode.hud.add_child(_abode.fortune_modal)
	_abode.text_transition = preload("res://src/presentation/text_transition.gd").new()
	_abode.hud.add_child(_abode.text_transition)
	_abode.text_transition.sequence_started.connect(func():
		_text_camera_was_locked = _abode.camera.input_locked
		_abode.camera.dragging = false
		_abode.camera.contacts.clear()
		_abode.camera.input_locked = true)
	_abode.text_transition.sequence_finished.connect(func(_skipped: bool):
		_abode.camera.input_locked = _text_camera_was_locked)


func layout_panels(vp: Vector2, margin: float, portrait: bool) -> void:
	if _abode.save_controls != null:
		var save_rect := Rect2(margin, margin, minf(480.0, vp.x - margin * 2.0), minf(460.0, vp.y - margin * 2.0))
		if portrait:
			save_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		_abode.save_controls.call("set_layout_bounds", save_rect)
	if _abode.offline_summary != null:
		var offline_rect := Rect2(margin, margin, minf(480.0, vp.x - margin * 2.0), minf(300.0, vp.y - margin * 2.0))
		if portrait:
			offline_rect = Rect2(12, vp.y * 0.32, vp.x - 24, vp.y * 0.60)
		_abode.offline_summary.call("set_layout_bounds", offline_rect)
	if _abode.nine_realms_preview != null:
		_abode.nine_realms_preview.position = Vector2.ZERO
		_abode.nine_realms_preview.size = vp
	if _abode.breakthrough_seq != null:
		_abode.breakthrough_seq.position = Vector2.ZERO
		_abode.breakthrough_seq.size = vp
		if _abode.breakthrough_seq.visible:
			_abode._fit_breakthrough_camera(vp)
			_abode._mask_breakthrough_hud()
	if _abode.reincarnation_seq != null:
		_abode.reincarnation_seq.call("set_layout_bounds", Rect2(Vector2.ZERO, vp))
	if _abode.reincarnation_panel != null:
		var rc_rect := Rect2(margin, margin, minf(540.0, vp.x - margin * 2.0), minf(560.0, vp.y - margin * 2.0))
		if portrait:
			rc_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		_abode.reincarnation_panel.call("set_layout_bounds", rc_rect)
	if _abode.alchemy_panel != null:
		var alc_rect := Rect2(margin, margin, minf(540.0, vp.x - margin * 2.0), minf(560.0, vp.y - margin * 2.0))
		if portrait:
			alc_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		_abode.alchemy_panel.call("set_layout_bounds", alc_rect)
	if _abode.debug_panel != null:
		var dbg_rect := Rect2(margin, margin, minf(540.0, vp.x - margin * 2.0), minf(520.0, vp.y - margin * 2.0))
		if portrait:
			dbg_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		_abode.debug_panel.call("set_layout_bounds", dbg_rect)
	if _abode.realm_modal != null:
		var rlm_rect := Rect2(margin, margin, minf(540.0, vp.x - margin * 2.0), minf(560.0, vp.y - margin * 2.0))
		if portrait:
			rlm_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		_abode.realm_modal.call("set_layout_bounds", rlm_rect)
	if _abode.sect_panel != null:
		var target_w := minf(620.0, vp.x - margin * 2.0)
		var target_h := minf(600.0, vp.y - margin * 2.0)
		var target_x := maxf(margin, (vp.x - target_w) * 0.5)
		var target_y := maxf(margin, (vp.y - target_h) * 0.5)
		var sct_rect := Rect2(target_x, target_y, target_w, target_h)
		if portrait:
			sct_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		_abode.sect_panel.call("set_layout_bounds", sct_rect)
	if _abode.fortune_modal != null:
		var target_w := minf(540.0, vp.x - margin * 2.0)
		var target_h := minf(520.0, vp.y - margin * 2.0)
		var target_x := maxf(margin, (vp.x - target_w) * 0.5)
		var target_y := maxf(margin, (vp.y - target_h) * 0.5)
		var ftn_rect := Rect2(target_x, target_y, target_w, target_h)
		if portrait:
			ftn_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		_abode.fortune_modal.call("set_layout_bounds", ftn_rect)




func trigger_nine_realms_hook(is_replay: bool = false) -> void:
	if _abode.nine_realms_preview == null:
		return
	var current_aspire: String = String(_abode.session.state.tutorial_flags.get("aspired_realm", ""))
	_abode.nine_realms_preview.play_hook(_abode.camera, current_aspire, Callable(_abode, "_on_nine_realms_closed"), _abode.reduced, is_replay)

func _open_nine_realms_overview() -> void:
	if _abode.nine_realms_preview == null:
		return
	var current_aspire: String = String(_abode.session.state.tutorial_flags.get("aspired_realm", ""))
	_abode.nine_realms_preview.show_overview(_abode.camera, current_aspire, Callable(_abode, "_on_nine_realms_closed"))

func _on_nine_realms_aspiration_changed(realm_id: String) -> void:
	if _abode.session and _abode.session.state:
		_abode.session.state.tutorial_flags["aspired_realm"] = realm_id
		_abode._save_game()
		_abode.hint.text = "已標記心之所向，大道在前，且行眼前事。"

func _on_nine_realms_closed() -> void:
	_abode._refresh_hud()

func _toggle_save_controls() -> void:
	if _abode.save_controls:
		_abode.save_controls.visible = not _abode.save_controls.visible
		_abode._layout()

func _display_offline_summary(report: Dictionary) -> void:
	if _abode.offline_summary and not report.is_empty():
		_abode.offline_summary.show_report(report)
		_abode._layout()

func _on_settings_menu_pressed(id: int) -> void:
	match id:
		102:
			# Illustrative fixture, never a breakthrough command or a state mutation.
			_abode.text_transition.play("境界等級提升至 LV2", "築基期 ERA2 — 壽元剩餘 80祀", {"reduced_motion": _abode.reduced_motion})
		101:
			_abode._toggle_bgm()
		1:
			_abode._toggle_motion()
			_update_settings_menu_labels()
		2:
			_abode._toggle_save_controls()
		4:
			_abode._show_help()
		8:
			_abode._toggle_debug_panel()

func _update_settings_menu_labels() -> void:
	if _abode.settings_menu == null:
		return
	var popup: PopupMenu = _abode.settings_menu.get_popup()
	var bgm_idx: int = popup.get_item_index(101)
	if bgm_idx >= 0:
		var bgm_state: String = "開" if _abode.is_bgm_enabled else "關"
		popup.set_item_text(bgm_idx, "背景音樂：%s" % bgm_state)
	var motion_idx: int = popup.get_item_index(1)
	if motion_idx >= 0:
		var motion_state: String = "開" if _abode.reduced_motion else "關"
		popup.set_item_text(motion_idx, "低特效：%s" % motion_state)

func _on_more_menu_pressed(id: int) -> void:
	match id:
		1:
			_abode._toggle_motion()
		2:
			_abode._toggle_save_controls()
		3:
			_abode._open_nine_realms_overview()
		4:
			_abode._show_help()
		5:
			if _abode.session != null and _abode.session.state != null and _abode.session.state.era_id >= 2:
				_abode._replay_breakthrough()
		6:
			_abode._toggle_reincarnation_panel()
		7:
			_abode._toggle_alchemy_panel()
		8:
			_abode._toggle_debug_panel()
		9:
			_abode._toggle_realm_modal()
		10:
			_abode._toggle_sect_panel()
		11:
			_abode._toggle_fortune_modal()

func _toggle_sect_panel() -> void:
	if _abode.sect_panel == null:
		return
	_abode.sect_panel.visible = not _abode.sect_panel.visible
	if _abode.sect_panel.visible:
		if _abode.session != null and _abode.session.state != null:
			_abode.sect_panel.call("update_view", _abode.session.state)
		_abode._layout()

func _on_sect_join_requested(sect_name: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.join_sect(sect_name)
	if bool(res.get("ok", false)):
		_abode.hint.text = "恭賀道友拜入【%s】！獲賜外門弟子令，可領取宗門委託。" % sect_name
		_abode._save_game()
		_abode._refresh_hud()
	else:
		var err_str: String = str(res.get("error", "FAIL"))
		_abode.hint.text = "拜入宗門未遂：%s" % err_str
	if _abode.sect_panel != null and _abode.sect_panel.visible and _abode.session.state != null:
		_abode.sect_panel.call("update_view", _abode.session.state)

func _on_sect_refresh_tasks_requested() -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.refresh_sect_tasks(false)
	if bool(res.get("ok", false)):
		_abode.hint.text = "宗門懸賞告示已煥然一新！"
		_abode._save_game()
		_abode._refresh_hud()
	else:
		_abode.hint.text = "刷新委託受阻：%s" % str(res.get("error", "FAIL"))

func _on_sect_start_expedition_requested(task_id: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.start_sect_expedition(task_id)
	if bool(res.get("ok", false)):
		_abode.hint.text = "分身領命出征！正在歷練天下。"
		_abode._save_game()
		_abode._refresh_hud()
	else:
		_abode.hint.text = "派遣受阻：%s" % str(res.get("error", "FAIL"))

func _on_sect_claim_expedition_requested() -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.claim_sect_expedition()
	if bool(res.get("ok", false)):
		_abode.hint.text = "歷練弟子圓滿歸來！豐厚物資與宗門功勳已入庫。"
		_abode._save_game()
		_abode._refresh_hud()
	else:
		_abode.hint.text = "結算失敗：%s" % str(res.get("error", "FAIL"))

func _on_sect_learn_technique_requested(tech_id: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.learn_sect_technique(tech_id)
	if bool(res.get("ok", false)):
		_abode.hint.text = "福至心靈！宗門真訣更進一層。"
		_abode._save_game()
		_abode._refresh_hud()
	else:
		_abode.hint.text = "參悟受阻：%s" % str(res.get("error", "FAIL"))

func _on_sect_buy_market_item_requested(item_id: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.buy_sect_market_item(item_id)
	if bool(res.get("ok", false)):
		_abode.hint.text = "坊市交割順利，珍稀物資已收歸囊中！"
		_abode._save_game()
		_abode._refresh_hud()
	else:
		_abode.hint.text = "兌換受阻：%s" % str(res.get("error", "FAIL"))

func _on_sect_closed() -> void:
	if _abode.sect_panel != null:
		_abode.sect_panel.visible = false
	_abode._refresh_hud()

func _toggle_realm_modal() -> void:
	if _abode.realm_modal == null:
		return
	_abode.realm_modal.visible = not _abode.realm_modal.visible
	if _abode.realm_modal.visible:
		if _abode.session != null:
			_abode.realm_modal.call("refresh", _abode.session.get_view())
		_abode._layout()

func _on_switch_realm_requested(target_realm: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.switch_realm(target_realm)
	if bool(res.get("ok", false)):
		var r_name := "靈界 · 天靈洞天" if target_realm == "realm_spirit" else "人界 · 祖基仙府"
		_abode.hint.text = "破界成功！神識跨越虛空，降臨【%s】。" % r_name
		_abode._save_game()
		_abode._refresh_hud()
	else:
		_abode.hint.text = "跨界受阻：%s" % str(res.get("error", "FAIL"))

func _on_upgrade_outpost_requested(outpost_id: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.upgrade_realm_outpost(outpost_id)
	if bool(res.get("ok", false)):
		_abode.hint.text = "靈界據點晉升成功！造化增幅持續運轉。"
		_abode._save_game()
		_abode._refresh_hud()
	else:
		_abode.hint.text = "據點晉升受阻：%s" % str(res.get("error", "FAIL"))

func _on_realm_modal_closed() -> void:
	_abode._refresh_hud()

func _toggle_alchemy_panel() -> void:
	if _abode.alchemy_panel == null:
		return
	_abode.alchemy_panel.visible = not _abode.alchemy_panel.visible
	if _abode.alchemy_panel.visible:
		if _abode.session != null:
			_abode.alchemy_panel.call("update_view", _abode.session.get_view())
		_abode._layout()

func _on_alchemy_refine_requested(pill_id: String, count: int) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.refine_pill(pill_id, count)
	if bool(res.get("ok", false)):
		_abode.hint.text = "丹爐火候純青，煉製成功！"
		_abode._save_game()
		_abode._refresh_hud()
		if _abode.alchemy_panel != null and _abode.alchemy_panel.visible:
			_abode.alchemy_panel.call("update_view", _abode.session.get_view())
	else:
		_abode.hint.text = "煉丹受阻：%s" % str(res.get("error", "FAIL"))

func _on_alchemy_consume_requested(pill_id: String, count: int) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.consume_pill(pill_id, count)
	if bool(res.get("ok", false)):
		_abode.hint.text = "靈丹入腹，化作滾滾修為生機！"
		_abode._save_game()
		_abode._refresh_hud()
		if _abode.alchemy_panel != null and _abode.alchemy_panel.visible:
			_abode.alchemy_panel.call("update_view", _abode.session.get_view())
	else:
		_abode.hint.text = "服丹受阻：%s" % str(res.get("error", "FAIL"))

func _on_alchemy_closed() -> void:
	if _abode.alchemy_panel != null:
		_abode.alchemy_panel.visible = false
	_abode._refresh_hud()

func _toggle_fortune_modal() -> void:
	if _abode.fortune_modal == null:
		return
	_abode.fortune_modal.visible = not _abode.fortune_modal.visible
	if _abode.fortune_modal.visible:
		if _abode.session != null:
			_abode.fortune_modal.call("refresh", _abode.session.get_view())
		_abode._layout()

func _on_fortune_trigger_requested() -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.trigger_fortune()
	if bool(res.get("ok", false)):
		_abode.hint.text = "【機緣感應】心神契合天地，引動天機奇遇降臨！"
		_abode._save_game()
	else:
		_abode.hint.text = "【推演未果】" + String(res.get("error", "暫無機緣"))
	if _abode.fortune_modal != null and _abode.fortune_modal.visible:
		_abode.fortune_modal.call("refresh", _abode.session.get_view())
	_abode._refresh_hud()

func _on_fortune_resolve_requested(option_index: int) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.resolve_fortune(option_index)
	if bool(res.get("ok", false)):
		var events: Array = res.get("events", [])
		var log_msg: String = "結算機緣成功。"
		if not events.is_empty() and events[0] is Dictionary:
			log_msg = String(events[0].get("log", "結算機緣成功。"))
		_abode.hint.text = "【機緣結算】" + log_msg
		_abode._save_game()
		if _abode.fortune_modal != null:
			_abode.fortune_modal.call("set_result_message", log_msg)
	else:
		_abode.hint.text = "【機緣抉擇失敗】" + String(res.get("error", "資糧不足"))
	if _abode.fortune_modal != null and _abode.fortune_modal.visible:
		_abode.fortune_modal.call("refresh", _abode.session.get_view())
	_abode._refresh_hud()

func _on_fortune_closed() -> void:
	if _abode.fortune_modal != null:
		_abode.fortune_modal.visible = false
	_abode._refresh_hud()


func _toggle_debug_panel() -> void:
	if _abode.debug_panel == null:
		return
	_abode.debug_panel.visible = not _abode.debug_panel.visible
	if _abode.debug_panel.visible:
		_abode._layout()

func _on_debug_closed() -> void:
	if _abode.debug_panel != null:
		_abode.debug_panel.visible = false
	_abode._layout()

func _on_debug_auto_build_toggled(enabled: bool) -> void:
	_abode.debug_auto_build_active = enabled
	if enabled:
		_abode.debug_auto_build_timer = 30.0
		var msg := "[DEBUG] 每 30 秒自動隨機建造已啟動。"
		_abode.hint.text = msg
		if _abode.debug_panel != null:
			_abode.debug_panel.call("set_status_message", msg)
			_abode.debug_panel.call("update_auto_build_ui", _abode.debug_auto_build_timer)
	else:
		var msg := "[DEBUG] 每 30 秒自動隨機建造已暫停。"
		_abode.hint.text = msg
		if _abode.debug_panel != null:
			_abode.debug_panel.call("set_status_message", msg)
			_abode.debug_panel.call("update_auto_build_ui", 0.0)

func _on_debug_manual_upgrade_requested() -> void:
	_abode._debug_perform_random_upgrade()

func _on_debug_boost_era_level_requested() -> void:
	_abode._debug_boost_era_level_10()

func _on_debug_add_resources_requested() -> void:
	_abode._debug_add_resources()

func _on_debug_apply_buff_requested(buff_id: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.apply_buff(buff_id)
	_abode._refresh_hud()
	if bool(res.get("ok", false)):
		var def = BuffSystem.get_definition(buff_id)
		var b_name: String = String(def.get("name", buff_id)) if def != null else buff_id
		var msg := "[DEBUG] 狀態增益施加成功：【%s】" % b_name
		_abode.hint.text = msg
		if _abode.debug_panel != null:
			_abode.debug_panel.call("set_status_message", msg)
	else:
		_abode.hint.text = "[DEBUG] 施加 BUFF 失敗：%s" % str(res.get("error", "FAIL"))

func _toggle_reincarnation_panel() -> void:
	if _abode.reincarnation_panel == null:
		return
	_abode.reincarnation_panel.visible = not _abode.reincarnation_panel.visible
	if _abode.reincarnation_panel.visible:
		if _abode.session != null:
			_abode.reincarnation_panel.call("refresh", _abode.session.get_view())
		_abode._layout()

func _on_reincarnate_requested(mode: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.reincarnate(mode)
	if bool(res.get("ok", false)):
		_abode.hint.text = "天地玄黃，轉世功成！重塑肉身，再續大道仙途。"
		_abode._save_game()
		if _abode.reincarnation_panel != null:
			_abode.reincarnation_panel.visible = false
		_abode._return_home()
		_abode._refresh_hud()
		print("ABODE_REINCARNATION: cycle=", _abode.session.state.reincarnation_count)
		var is_first_reincarnation: bool = not bool(_abode.session.state.tutorial_flags.get("seen_nine_realms_hook", false))
		if is_first_reincarnation:
			_abode.session.state.tutorial_flags["seen_nine_realms_hook"] = true
			_abode._save_game()
			_abode.trigger_nine_realms_hook(false)

		var dao_heart_gain := 0
		var events: Array = res.get("events", [])
		for ev in events:
			if ev is Dictionary and ev.get("kind") == "reincarnated":
				var dh_val = ev.get("gained_dao_heart", 0)
				if dh_val is String:
					var p := AmountCompat.try_parse(dh_val)
					if bool(p.get("ok", false)):
						dao_heart_gain = int((p["value"] as AmountCompat).to_float())
				elif dh_val is int or dh_val is float:
					dao_heart_gain = int(dh_val)
				break
		if dao_heart_gain <= 0 and _abode.session != null:
			var prev_reward: Dictionary = _abode.session.get_reincarnation_preview()
			var prev_dh = prev_reward.get("dao_heart", 0)
			if prev_dh is String:
				var p := AmountCompat.try_parse(prev_dh)
				if bool(p.get("ok", false)):
					dao_heart_gain = int((p["value"] as AmountCompat).to_float())
			elif prev_dh is int or prev_dh is float:
				dao_heart_gain = int(prev_dh)
		if _abode.reincarnation_seq != null:
			_abode.reincarnation_seq.play(_abode.camera, _abode.session.state.reincarnation_count, dao_heart_gain, Callable(), _abode.reduced)
		else:
			_abode._refresh_hud()
	else:
		_abode.hint.text = "轉世受阻：%s" % str(res.get("error", "FAIL"))

func _on_learn_talent_requested(talent_id: String) -> void:
	if _abode.session == null:
		return
	var res: Dictionary = _abode.session.learn_talent(talent_id)
	if bool(res.get("ok", false)):
		_abode.hint.text = "參悟成功！道心感應，玄妙自生。"
		_abode._save_game()
		_abode._refresh_hud()
		if _abode.reincarnation_panel != null and _abode.reincarnation_panel.visible:
			_abode.reincarnation_panel.call("refresh", _abode.session.get_view())
		print("ABODE_TALENT_LEARNED: ", talent_id, " level=", _abode.session.state.talents.get(talent_id, 0))
	else:
		_abode.hint.text = "參悟受阻：%s" % str(res.get("error", "FAIL"))

func _on_reincarnation_closed() -> void:
	_abode._refresh_hud()
