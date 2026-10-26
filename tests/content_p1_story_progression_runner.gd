extends "res://tests/early_v1c_skills_runner.gd"
## Legal command/time prefix; no direct resources, era or skill funding.
func _run() -> void:
	content = ContentLoader.load_directory("res://content").content
	helper.content = content
	check(IslandProgression.attach(content).ok,"official content")
	if play_prefix():
		var s := branch(era3_state)
		var start := s.state.total_elapsed_seconds
		accumulate_to(s,120,1.0)
		check(send(s,"learn_skill",{"skill_id":"greenwood_nourishment"}).ok,"earned greenwood")
		check(s.state.achievements.unlocked.has("p1_greenwood_student"),"earned A01 unlock")
		# Spend warehouse stock through formal crafting/building if necessary, never erase to make room.
		var before: String = s.state.resources.wood.value.serialize()
		var claimed := send(s,"claim_achievement",{"achievement_id":"p1_greenwood_student"})
		if not claimed.ok:
			# At this prefix wood storage can be expanded using earned stock.
			check(send(s,"upgrade_building",{"building_id":"storage_wood"}).ok,"earned warehouse space")
			claimed = send(s,"claim_achievement",{"achievement_id":"p1_greenwood_student"})
		check(claimed.ok,"earned A01 claim")
		var memory := Memory.new()
		SaveManager.configure(content,memory)
		check(SaveManager.save(s.state,SAVE_META).ok,"earned save")
		SaveManager.configure(content,memory)
		var loaded := SaveManager.current_state()
		check(loaded != null and loaded.achievements.claimed.get("p1_greenwood_student",false),"earned claim survives reload")
		var encoded := SaveCodec.encode(s.state,content.content_version,SAVE_META)
		if encoded.ok:
			var write_file_fixture := FileAccess.open("res://src/verification/content_p1_story_earned_fixture.json",FileAccess.WRITE)
			if write_file_fixture == null:
				push_error("write failed: " + str("res://src/verification/content_p1_story_earned_fixture.json"))
				RunnerResult.finish(self, 1)
			else:
				write_file_fixture.store_string(encoded.json)
		# Natural pool via real cooldown and legal commands; simulation is accelerated explicitly.
		var n := branch(s.state)
		var choices := []
		var found := false
		var natural_start := n.state.total_elapsed_seconds
		for attempt in 24:
			var pending: Dictionary = n.state.fortune.get("pending_encounter", {})
			if pending.is_empty():
				var waited := maxf(1,float(n.state.fortune.get("cooldown_remaining",1200)))
				var time := n.advance_time(waited)
				check(time.ok,"natural cooldown advance")
				if time.stopped != null: break
				pending = n.state.fortune.get("pending_encounter", {})
			if pending.is_empty(): break
			var index: int = pending.options.size()-1
			var is_new: bool = pending.get("content_batch") == "content-p1-story"
			choices.append({"id":pending.id,"age_seconds":n.state.total_elapsed_seconds,"new":is_new})
			check(send(n,"resolve_fortune",{"option_index":index,"instance_id":DecisionReceipt.pending_id(n.state)}).ok,"natural selected "+str(pending.id))
			if is_new: found = true; break
		check(found,"eligible new encounter naturally drawn")
		if found:
			SaveManager.configure(content,memory)
			check(SaveManager.save(n.state,SAVE_META).ok,"natural choice saved")
			SaveManager.configure(content,memory)
			var natural_loaded := SaveManager.current_state()
			check(natural_loaded != null and natural_loaded.fortune.pending_encounter.is_empty() and int(natural_loaded.fortune.total_fortunes_claimed) == int(n.state.fortune.total_fortunes_claimed),"natural choice survives reload")
		var write_file_progression := FileAccess.open("res://docs/verification/artifacts/content-p1-story/progression.json",FileAccess.WRITE)
		if write_file_progression == null:
			push_error("write failed: " + str("res://docs/verification/artifacts/content-p1-story/progression.json"))
			RunnerResult.finish(self, 1)
		else:
			write_file_progression.store_string(JSON.stringify({"checks":checks,"failures":failures,"simulated_seconds":s.state.total_elapsed_seconds-start,"wood_before":before,"natural_pool_choices":choices,"natural_pool_simulated_seconds":n.state.total_elapsed_seconds-natural_start,"evidence":"legal CLI commands and accelerated simulation through real cooldowns; no browser natural wait, no cooldown/seed/encounter injection"},"\t"))

	print("CONTENT-P1-STORY EARNED ",checks," checks failures=",JSON.stringify(failures))
	SaveManager.reset_for_tests()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)


