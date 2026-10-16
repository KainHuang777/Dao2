extends SceneTree
func _init() -> void:
	var raw := FileAccess.get_file_as_string("docs/verification/artifacts/res1-c2-offline-fixture.json")
	var r := SaveCodec.decode(raw)
	print("DECODE ok=", r.get("ok", false), " err=", r.get("error", ""), " schema=", r.get("envelope", {}).get("schema_version", null) if r.has("envelope") else "")
	quit(0)
