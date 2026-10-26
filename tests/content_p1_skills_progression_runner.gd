extends "res://tests/early_v1c_skills_runner.gd"
## Reuse the earned Era1->3 command path; no resource/era/skill injection.
func _run() -> void:
	content = ContentLoader.load_directory("res://content").content
	helper.content = content
	check(IslandProgression.attach(content).ok,"official attach")
	if play_prefix():
		var fixture := FileAccess.open("res://src/verification/content_p1_skills_fixture.json",FileAccess.WRITE)
		if fixture == null:
			push_error("write failed: res://src/verification/content_p1_skills_fixture.json")
			RunnerResult.finish(self, 1)
		else:
			fixture.store_string(SaveCodec.encode(era3_state,content.content_version,SAVE_META).json)
		for group in [[era2_fresh,["greenwood_nourishment","ore_breath_refinement","herbal_spirit_nurture"]],[era3_state,["warehouse_preparation","alchemical_breath_control"]]]:
			var s := branch(group[0])
			check(s.state.sect.is_empty(),"no sect required")
			for id in group[1]:
				for level in range(1,4):
					var cost := float(content.skill_defs[id].cost)
					accumulate_to(s,cost,1.0)
					var before := points(s)
					check(send(s,"learn_skill",{"skill_id":id}).ok and s.state.skills[id] == level,"earned "+id+" L"+str(level))
					check(absf(before-points(s)-cost)<1e-6,"earned exact cost "+id)
			check(s.state.sect.is_empty(),"no sect added")
	var result := {"checks":checks,"failures":failures,"evidence":"CLI simulated time and official commands; not real-time browser progression"}
	var f := FileAccess.open("res://docs/verification/artifacts/content-p1-skills/progression.json",FileAccess.WRITE)
	if f == null:
		push_error("write failed: res://docs/verification/artifacts/content-p1-skills/progression.json")
		RunnerResult.finish(self, 1)
	else:
		f.store_string(JSON.stringify(result,"\t"))
	print("CONTENT-P1-SKILL progression ",JSON.stringify(result))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
