class_name StorageAdapter
extends RefCounted

func read(key: String) -> Dictionary:
	return {"ok": false, "data": "", "error": "not_implemented"}

func write(key: String, data: String) -> Dictionary:
	return {"ok": false, "error": "not_implemented"}

func erase(key: String) -> Dictionary:
	return {"ok": false, "error": "not_implemented"}

func exists(key: String) -> bool:
	return false

func backend_name() -> String:
	return "abstract"

func is_persistent() -> bool:
	return false
