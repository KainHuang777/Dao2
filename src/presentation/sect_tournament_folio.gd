class_name SectTournamentFolio
extends VBoxContainer
signal requested(action: String, payload: Dictionary)
var _signature := ""
var preparation := 0
var _reading: VBoxContainer
var _status: Label
var _actions: HFlowContainer
func text(value: String) -> void: SectReformUi.text(_reading,value)
func action(label: String, command: String, payload: Dictionary, blocked: bool) -> void:
	var button := InscriptionAction.new()
	button.text = label
	button.custom_minimum_size.y = 44
	button.disabled = blocked
	button.pressed.connect(func(): requested.emit(command,payload))
	_actions.add_child(button)
func refresh(v: Dictionary, blocked: bool) -> void:
	var c: Dictionary = v.get("competition",{})
	var signature := JSON.stringify([c,v.get("best_ranks"),v.get("sect_id"),blocked,preparation])
	if signature == _signature: return
	_signature = signature
	for child in get_children(): remove_child(child); child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_reading = VBoxContainer.new()
	_reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_reading)
	_status = SectReformUi.text(self,"")
	_status.hide()
	_actions = HFlowContainer.new()
	add_child(_actions)
	if c.is_empty(): text("宗門大比尚不可用。"); return
	var themes: Array = SectTournament.THEMES.get(v.sect_id,["定息","辨理","問心"])
	text("宗門大比 · 八席三段試煉")
	text("同境分組；無報名費、無截止。離線不代選，關頁可續賽。名冊為當屆同境投影。\n總分高者先；同分先比最低段，再比當屆籤序。第1／2／3／4～8名：18／14／10／6貢獻。")
	var t: Variant = c.current
	if t == null:
		text("尚無訪帖；下一邀請最早宗齡 %d 祀。" % (int(c.next_second)/60))
	elif t.status == "invite":
		text("第%d屆訪帖 · 報名時凍結修為、功法、名冊與全部抽樣。\n每段＝40＋2×(層數−1)＋有效功法(上限10)＋本宗3＋準備4＋策略。新入宗不保證前三。" % t.edition)
		var row := HFlowContainer.new()
		_reading.add_child(row)
		for i in 3:
			var tab := GameTab.new()
			tab.text = "準備"+themes[i]
			tab.set_pressed_no_signal(preparation == i)
			tab.pressed.connect(func(): preparation = i; _signature = ""; refresh(v,blocked))
			row.add_child(tab)
		action("報名入場","enter_sect_tournament",{"instance_id":t.id,"preparation":preparation},blocked)
		action("本屆暫不參加","skip_sect_tournament",{"instance_id":t.id},blocked)
	else:
		var f: Dictionary = t.frozen
		text("第%d屆 · 境界組%d · 凍結層數%d／有效功法%d · 準備%s\n宗齡%d秒凍結；突破、改功法與增益不改本屆基準。\n三段依序：%s／%s／%s" % [t.edition,f.era,f.level,f.technique,themes[int(f.preparation)],t.tick,themes[0],themes[1],themes[2]])
		var rows := SectTournament.scores(f,t.choices)
		var ranking := SectTournament.order(f,t.choices)
		var seats: Array = range(8) if ranking.is_empty() else ranking
		for seat in seats:
			var who: String = "你" if seat == 0 else (SectLife.table(String(v.sect_id), "names")[[2,4,6].find(seat)] if (v.sect_id == "taixu_sect" or t.get("roster_version", 1) == 2) and seat in [2,4,6] else "同境修士%d" % seat)
			var scores: Array = rows[seat]
			var total := 0
			for n in scores: total += int(n)
			text("%s · %s · 合計%d · 籤序%d%s" % [who,str(scores),total,int(f.ties[seat])+1," · 第%d名" % (ranking.find(seat)+1) if not ranking.is_empty() else ""])
		if t.status == "entered":
			var stage: int = t.choices.size()
			_status.show()
			_status.text = "第%d段 · %s：穩健+5；進取50%%為−4／50%%為+12；觀察%s。" % [stage+1,themes[stage],"+7（已準備，另加準備4）" if stage == int(f.preparation) else "+2（未準備）"]
			for i in 3: action(["穩健","進取","觀察"][i],"choose_sect_trial",{"instance_id":t.id,"stage":stage,"strategy":SectTournament.STRATEGIES[i]},blocked)
		else:
			_status.show()
			_status.text = "已結算 · 第%d名 · 待領%d貢獻" % [ranking.find(0)+1,SectTournament.reward(ranking.find(0)+1)]
			action("領取本屆獎勵","claim_sect_tournament",{"instance_id":t.id},blocked)
		_status.tooltip_text = _status.text
		# Separate confirmation prevents a single accidental click abandoning a run.
		var abandon := InscriptionAction.new()
		abandon.text = "放棄本屆…"
		abandon.disabled = blocked
		abandon.pressed.connect(func():
			abandon.hide()
			action("確認放棄（無補償）","abandon_sect_tournament",{"instance_id":t.id},blocked))
		_actions.add_child(abandon)
	var best := int(v.get("best_ranks",{}).get(v.get("sect_id",""),0))
	text("最佳名次：" + ("尚無" if best == 0 else "第%d名%s" % [best," · 大比魁首" if best == 1 else ""]))
	text("最近四屆（本世）")
	for r in c.recent: text("第%d屆 · %s%s" % [r.edition,{"claimed":"已領","skipped":"婉拒","abandoned":"棄賽"}[r.status]," · 第%d名" % r.rank if r.rank > 0 else ""])
	if blocked: text(v.get("blocked_reason","操作暫不可用。"))
