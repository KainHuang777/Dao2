extends SceneTree
func _init() -> void:
 var raw := FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c2-offline-fixture.json")
 var decoded := SaveCodec.decode(raw)
 print("FIXTURE_DECODE: ", decoded.get("error"), " ok=", decoded.ok)
 var e: Dictionary = JSON.parse_string(raw)
 var original: String = e.checksum
 e.erase("checksum")
 print("HASH: original=", original, " parsed=", SaveCodec.compute_checksum(e))
 quit(0 if decoded.ok else 1)
