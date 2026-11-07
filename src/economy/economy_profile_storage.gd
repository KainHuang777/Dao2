class_name EconomyProfileStorage
extends StorageAdapter
## Fixed key prefix prevents caller-selected profiles from touching legacy keys.
const PREFIX := "econ_r1_"
var _base: StorageAdapter
func _init(base: StorageAdapter) -> void: _base = base
func read(key: String) -> Dictionary: return _base.read(PREFIX + key)
func write(key: String, value: String) -> Dictionary: return _base.write(PREFIX + key, value)
func erase(key: String) -> Dictionary: return _base.erase(PREFIX + key)
func exists(key: String) -> bool: return _base.exists(PREFIX + key)
