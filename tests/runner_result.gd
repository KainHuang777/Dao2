extends RefCounted
class_name RunnerResult

static var _decided := false
static var _exit_code := 0

## Generated runner files belong to ignored storage, never the input evidence.
static func output_path(source_path: String) -> String:
	var base := OS.get_environment("DAO_TEST_STORAGE_ROOT")
	if base.is_empty(): base = "res://.test-output"
	if source_path.begins_with(base + "/") or source_path.begins_with(base + "\\"):
		return source_path
	var relative := source_path.trim_prefix("res://")
	var target := base.path_join(relative)
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	return target

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
