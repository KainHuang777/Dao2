extends SceneTree
## Recover only the prior accepted fixture bytes from its frozen candidate PCK.
func _init() -> void:
	var source := "res://src/verification/content_p1_pills_fixture.json"
	var data := FileAccess.get_file_as_bytes(source)
	if data.is_empty():
		push_error("Prior packed fixture missing; run outside the loose source root against ContentP1PillsAcceptance PCK")
		quit(1)
		return
	var output := FileAccess.open("E:/WORK/Dao2/build/sect-prior-pills-fixture.json",FileAccess.WRITE)
	output.store_buffer(data)
	print("EXTRACT_PRIOR_FIXTURE ",data.size())
	quit(0)
