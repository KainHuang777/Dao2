extends "res://tests/res1b_economy_runner.gd"
## Existing actual manufacturing/cargo chain, observed through online/offline paths.
func _init() -> void:
	catalog = ProcessingCatalog.load_file().catalog
	var online := _chain()
	var offline := online.state.duplicate_state()
	_expect(not StoryProgress.facts(online.state,true).timber_completed,"dispatch is not completion")
	TimeAdvancer.advance(online.state,online.content,600)
	OfflineSettlement.settle(offline,online.content,601000,1000)
	for state in [online.state,offline]:
		var facts := StoryProgress.facts(state,true)
		_expect(facts.timber_completed,"actual wood batch completed")
		_expect(facts.timber_arrived and facts.bronze_arrived and facts.positive_home_arrival,"both actual cargoes arrived")
		_expect(state.achievements.unlocked.has("p1_timber_workshop") and state.achievements.unlocked.has("p1_homebound_cargo"),"time events unlock new achievements without UI callback")
	_expect(StoryProgress.facts(online.state,true)==StoryProgress.facts(offline,true),"online/offline same fixed facts")
	_expect(AccountChecks.same(online.state,offline),"online/offline exact economy RNG and achievements")
	var s := _session(false)
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	var template: Dictionary = SectSystem.P1_TASKS.home_supply_register
	var config: Dictionary = SectSystem.RARITY_CONFIGS[template.rarity]
	var rewards: Dictionary = template.rewards.duplicate(true)
	rewards.contribution = config.contrib_min; rewards.money = int(50*float(config.reward_mult)*3)
	var task := {"id":"story-event-task","template_id":"home_supply_register","generation_era":3,"name":template.name,"desc":template.desc,"rarity":template.rarity,"rarity_name":config.name,"rarity_color":config.color,"duration":config.duration,"elapsed":0,"rewards":rewards}
	s.state.sect.available_tasks = [task]
	_expect(_send(s,"start_sect_expedition",{"task_id":task.id}).ok,"dispatch official supply task")
	_expect(not StoryProgress.facts(s.state,true).new_supply_claimed,"dispatched not claimed")
	_expect(not _send(s,"claim_sect_expedition").ok,"unfinished rejects")
	s.advance_time(float(config.duration))
	_expect(not StoryProgress.facts(s.state,true).new_supply_claimed,"completed but unclaimed not fact")
	_expect(_send(s,"claim_sect_expedition").ok,"official supply claim")
	_expect(StoryProgress.facts(s.state,true).new_supply_claimed and s.state.achievements.unlocked.has("p1_supply_commission"),"claim commits supply fact")
	_expect(not _send(s,"claim_sect_expedition").ok,"claim cannot repeat")
	var write_file_events := FileAccess.open(RunnerResult.output_path("res://docs/verification/artifacts/content-p1-story/events.json"),FileAccess.WRITE)
	if write_file_events == null:
		push_error("write failed: " + str("res://docs/verification/artifacts/content-p1-story/events.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_events.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":"actual recipe/arrival tick hooks and formal expedition commands; funded recipe fixtures, not natural player progression"},"\t"))
	print("CONTENT-P1-STORY EVENTS ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
