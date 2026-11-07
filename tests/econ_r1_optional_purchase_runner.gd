extends "res://tests/econ_r1_baseline_runner.gd"
## Separate earned branch: optional buildings must not alter the three baselines.

func ladder(era: int) -> bool:
	if era == 2:
		if not build("library") or not build("scripture_hall"): return false
	return super.ladder(era)

func run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	if not loaded.ok: RunnerResult.finish(self,1); return
	content = loaded.content
	if not IslandProgression.attach_supply(content).ok: RunnerResult.finish(self,1); return
	stage_limit = 2
	var result := baseline("optional_purchases")
	for id in ["library", "scripture_hall"]:
		check(int(s.state.buildings[id]) > 0,"earned optional purchase "+id)
	var report := {"task":"ECON-R1-A","engine":Engine.get_version_info().string,"content_version":content.content_version,"dispatch":IslandEconomy.supply_data().dispatch,"purchase_probes":[result],"failures":failures}
	var path := RunnerResult.output_path("res://econ-r1-a/optional-purchases.json")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures.append("output_write")
	else: file.store_string(JSON.stringify(report,"\t",true)); file.close()
	print("ECON-A optional report=",path," failures=",failures)
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
