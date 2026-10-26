extends RefCounted
class_name RunnerResult

static var _decided := false
static var _exit_code := 0

static func finish(tree: SceneTree, exit_code: int) -> void:
	if _decided:
		if _exit_code == 0 and exit_code != 0:
			print("RUNNER_RESULT CONFLICT exit=%d" % exit_code)
			tree.quit(1)
		else:
			tree.quit(1 if _exit_code != 0 else 0)
		return
	_decided = true
	_exit_code = exit_code
	print("RUNNER_RESULT status=%s exit=%d" % ["PASS" if exit_code == 0 else "FAIL", exit_code])
	tree.quit(exit_code)
