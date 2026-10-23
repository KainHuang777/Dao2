extends SceneTree
func _init() -> void:
	if not ProjectSettings.load_resource_pack("res://build/web-content-p1-talents/index.pck", true):
		quit(1)
		return
	var raw := FileAccess.get_file_as_bytes("res://src/verification/content_p1_talents_fixture.json")
	var out := FileAccess.open("res://docs/verification/artifacts/ui-art-edge/talents-fixture-original.json", FileAccess.WRITE)
	out.store_buffer(raw)
	out.close()
	print("Original packed fixture recovered, bytes=",raw.size())
	quit()

