class_name WebStorageAdapter
extends StorageAdapter

const DEFAULT_NAMESPACE := "dao2"

var _namespace: String
var _bridge: Object = null
var _persistent_confirmed := false

func _init(p_namespace: String = DEFAULT_NAMESPACE) -> void:
	_namespace = p_namespace

func _storage_key(key: String) -> String:
	return _namespace + ":" + key

func read(key: String) -> Dictionary:
	if not OS.has_feature("web"):
		return {"ok": false, "data": "", "error": "not_web"}
	var bridge := _js_bridge()
	if bridge == null:
		return {"ok": false, "data": "", "error": "bridge_unavailable"}
	var k := _storage_key(key)
	var js_code := "(function() { try { var val = window.localStorage.getItem(%s); return val === null ? null : val; } catch (e) { return null; } })()" % JSON.stringify(k)
	var val: Variant = bridge.call("eval", js_code)
	if val == null:
		return {"ok": false, "data": "", "error": "missing"}
	return {"ok": true, "data": String(val), "error": ""}

func write(key: String, data: String) -> Dictionary:
	if not OS.has_feature("web"):
		return {"ok": false, "error": "not_web"}
	var bridge := _js_bridge()
	if bridge == null:
		return {"ok": false, "error": "bridge_unavailable"}
	var k := _storage_key(key)
	var js_code := "(function() { try { window.localStorage.setItem(%s, %s); return 'ok'; } catch (e) { return String(e && e.message ? e.message : e); } })()" % [JSON.stringify(k), JSON.stringify(data)]
	var res: Variant = bridge.call("eval", js_code)
	if String(res) == "ok":
		_persistent_confirmed = true
		return {"ok": true, "error": ""}
	return {"ok": false, "error": String(res)}

func erase(key: String) -> Dictionary:
	if not OS.has_feature("web"):
		return {"ok": false, "error": "not_web"}
	var bridge := _js_bridge()
	if bridge == null:
		return {"ok": false, "error": "bridge_unavailable"}
	var k := _storage_key(key)
	var js_code := "(function() { try { window.localStorage.removeItem(%s); return 'ok'; } catch (e) { return String(e && e.message ? e.message : e); } })()" % JSON.stringify(k)
	var res: Variant = bridge.call("eval", js_code)
	if String(res) == "ok":
		return {"ok": true, "error": ""}
	return {"ok": false, "error": String(res)}

func exists(key: String) -> bool:
	if not OS.has_feature("web"):
		return false
	var bridge := _js_bridge()
	if bridge == null:
		return false
	var k := _storage_key(key)
	var js_code := "(function() { try { return window.localStorage.getItem(%s) !== null; } catch (e) { return false; } })()" % JSON.stringify(k)
	var res: Variant = bridge.call("eval", js_code)
	return bool(res)

func backend_name() -> String:
	return "web_localstorage"

func is_persistent() -> bool:
	return _persistent_confirmed

func _js_bridge() -> Object:
	if _bridge == null:
		_bridge = Engine.get_singleton("JavaScriptBridge")
	return _bridge