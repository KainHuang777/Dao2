class_name FileStorageAdapter
extends StorageAdapter

const DEFAULT_DIR := "user://saves"

var _dir_path: String

func _init(dir_path: String = DEFAULT_DIR) -> void:
	_dir_path = dir_path

func path_for(key: String) -> String:
	return _dir_path.path_join(_safe_key(key) + ".json")

func read(key: String) -> Dictionary:
	var path := path_for(key)
	if not FileAccess.file_exists(path):
		return {"ok": false, "data": "", "error": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "data": "", "error": error_string(FileAccess.get_open_error())}
	var data := file.get_as_text()
	file.close()
	return {"ok": true, "data": data, "error": ""}

func write(key: String, data: String) -> Dictionary:
	var path := path_for(key)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(_dir_path)
	if mkdir_error != OK:
		return {"ok": false, "error": error_string(mkdir_error)}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": error_string(FileAccess.get_open_error())}
	file.store_string(data)
	file.close()
	var verify := FileAccess.open(path, FileAccess.READ)
	if verify == null:
		return {"ok": false, "error": "verify_open_failed"}
	var stored := verify.get_as_text()
	verify.close()
	if stored != data:
		return {"ok": false, "error": "verify_mismatch"}
	return {"ok": true, "error": ""}

func erase(key: String) -> Dictionary:
	var path := path_for(key)
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "missing"}
	var remove_error := DirAccess.remove_absolute(path)
	if remove_error != OK:
		return {"ok": false, "error": error_string(remove_error)}
	return {"ok": true, "error": ""}

func exists(key: String) -> bool:
	return FileAccess.file_exists(path_for(key))

func backend_name() -> String:
	return "file"

func is_persistent() -> bool:
	return true

func _safe_key(key: String) -> String:
	return key.replace("/", "_").replace("\\", "_")