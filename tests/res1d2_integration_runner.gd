extends SceneTree
## Same earned-flow contract runs natively and in the isolated Web test export.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var result: Dictionary = preload("res://src/verification/res1d2_contract.gd").new().run()
	if result.failures.is_empty():
		print("PASS: RES1-D2 %d checks; normal earned Era3, Danxia, T2/T3 consumption, atomic refusal, transport, conservation, 600s partitions." % result.checks)
		RunnerResult.finish(self, 0)
	else:
		for failure in result.failures:
			push_error(failure)
		RunnerResult.finish(self, 1)
