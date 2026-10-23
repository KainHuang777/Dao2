extends SceneTree
## Existing earned Era2 fixture; no direct inventory funding in this path.
const META := {"save_id":"sect-earned-isolated","saved_at_utc_ms":"0","settled_until_utc_ms":"0","sim_tick":"0"}
var failures := []
var checks := 0
var serial := 0
class Memory extends StorageAdapter:
	var data := {}
	func read(key: String) -> Dictionary: return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
	func exists(key: String) -> bool: return data.has(key)
	func write(key: String,value: String) -> Dictionary: data[key]=value; return {"ok":true}
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func send(s: GameSession,type: String,payload: Dictionary={}) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"earned-sect-"+str(serial),"expected_revision":s.state.revision,"type":type,"payload":payload})
func run() -> void:
	var c: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(c)
	var original := FileAccess.get_file_as_string("res://docs/verification/artifacts/early-flow1d-natural-foundation.json")
	var memory := Memory.new(); memory.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(c,memory)
	var state := SaveManager.current_state()
	check(state != null and state.era_id == 2 and state.sect.is_empty(),"earned Era2 starts unjoined")
	if state == null: quit(1); return
	var s := GameSession.new(); s.state = state; s.content = c; s.clock = GameClock.create(state.total_elapsed_seconds)
	seed(20261023)
	check(send(s,"join_sect",{"sect_name":"太虛天闕"}).ok,"formal join")
	var start_age := state.total_elapsed_seconds
	var completed := []
	for i in 15:
		if float(state.sect.contribution) >= 105: break
		if state.sect.available_tasks.is_empty():
			s.advance_time(float(state.sect.next_refresh_seconds))
			check(send(s,"refresh_sect_tasks").ok,"cooldown refresh")
		var selected: Dictionary = state.sect.available_tasks[0]
		for task in state.sect.available_tasks:
			if int(task.duration) < int(selected.duration): selected = task
		check(send(s,"start_sect_expedition",{"task_id":selected.id}).ok,"formal dispatch")
		check(s.advance_time(float(selected.duration)).ok,"simulated waiting")
		check(send(s,"claim_sect_expedition").ok,"formal claim")
		completed.append({"id":selected.id,"name":selected.name,"duration":selected.duration,"contribution":selected.rewards.contribution})
	check(float(state.sect.contribution)>=105,"earned contribution pays both actions")
	check(send(s,"learn_sect_technique",{"technique_id":"alchemy_herb_conservation"}).ok,"earned first technique")
	check(send(s,"buy_sect_market_item",{"item_id":"herb_nurture_supply"}).ok,"earned first item")
	check(SaveManager.save(state,META).ok,"earned path archives and saves")
	SaveManager.configure(c,memory)
	var reloaded := SaveManager.current_state()
	check(reloaded.sect.techniques.get("alchemy_herb_conservation",0)==1 and reloaded.pills.get("herb_nurture_pill",0)==1,"earned path reload")
	var encoded := SaveCodec.encode(state,c.content_version,META)
	FileAccess.open("res://src/verification/content_p1_sect_earned_fixture.json",FileAccess.WRITE).store_string(encoded.json)
	FileAccess.open("res://docs/verification/artifacts/content-p1-sect/progression.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source_sha256":original.sha256_text(),"completed":completed,"simulated_seconds":state.total_elapsed_seconds-start_age,"browser_natural_wait":false},"\t"))
	SaveManager.reset_for_tests()
	print("CONTENT-P1-SECT EARNED ",checks," checks failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
