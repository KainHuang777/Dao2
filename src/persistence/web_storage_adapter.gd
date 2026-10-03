class_name WebStorageAdapter
extends StorageAdapter
## Authoritative localStorage and lifetime Web Lock; no expiring timer leases.
const DEFAULT_NAMESPACE := "dao2"
var _namespace: String
var _bridge: Object = null
var _persistent_confirmed := false

func _init(p_namespace: String = DEFAULT_NAMESPACE) -> void:
	_namespace = p_namespace

func _storage_key(key: String) -> String:
	return _namespace + ":" + key

func begin_session() -> String:
	if not OS.has_feature("web"):
		return "not_web"
	var script := """(function(ns) {
		window.dao2StorageSessions = window.dao2StorageSessions || Object.create(null);
		if (window.dao2StorageSessions[ns]) return window.dao2StorageSessions[ns].status;
		const s = window.dao2StorageSessions[ns] = {status: 'pending'};
		if (!navigator.locks) return s.status = 'locks_unavailable';
		navigator.locks.request(ns + ':writer', {mode: 'exclusive', ifAvailable: true}, lock => {
			if (!lock) { s.status = 'writer_busy'; return; }
			s.status = 'ready';
			return new Promise(resolve => { s.release = () => { s.status = 'released'; resolve(); }; });
		}).catch(() => { s.status = 'lock_failed'; });
		window.addEventListener('pagehide', () => { if (s.release) s.release(); }, {once: true});
		return s.status;
	})(%s)""" % JSON.stringify(_namespace)
	return String(_eval(script))

func session_status() -> String:
	return String(_eval("(window.dao2StorageSessions && window.dao2StorageSessions[%s] || {}).status || 'not_started'" % JSON.stringify(_namespace)))

func release_session() -> void:
	_eval("(function(s) { if(s && s.release) s.release(); })(window.dao2StorageSessions && window.dao2StorageSessions[%s])" % JSON.stringify(_namespace))

func read(key: String) -> Dictionary:
	return _operation("read", key)

func write(key: String, data: String) -> Dictionary:
	var result := _operation("write", key, data)
	if result.ok:
		_persistent_confirmed = true
	return result

func erase(key: String) -> Dictionary:
	return _operation("erase", key)

func exists(key: String) -> bool:
	return bool(read(key).ok)

func backend_name() -> String:
	return "web_localstorage"

func is_persistent() -> bool:
	return _persistent_confirmed

func _operation(operation: String, key: String, data: String = "") -> Dictionary:
	if not OS.has_feature("web"):
		return {"ok": false, "data": "", "error": "not_web"}
	if _js_bridge() == null:
		return {"ok": false, "data": "", "error": "bridge_unavailable"}
	var script := """(function(ns, op, key, data) {
		try {
			if(op !== 'read') {
				const s = window.dao2StorageSessions && window.dao2StorageSessions[ns];
				if(!s || s.status !== 'ready') return JSON.stringify({ok:false,data:'',error:'writer_not_owned'});
			}
			if(op === 'read') {
				const value = localStorage.getItem(key);
				return JSON.stringify({ok:value !== null,data:value || '',error:value === null ? 'missing' : ''});
			}
			if(op === 'write') localStorage.setItem(key, data);
			else localStorage.removeItem(key);
			return JSON.stringify({ok:true,data:'',error:''});
		} catch(e) { return JSON.stringify({ok:false,data:'',error:e.name || 'storage_failed'}); }
	})(%s,%s,%s,%s)""" % [JSON.stringify(_namespace), JSON.stringify(operation), JSON.stringify(_storage_key(key)), JSON.stringify(data)]
	var parsed: Variant = JSON.parse_string(String(_eval(script)))
	if parsed is Dictionary:
		return parsed
	return {"ok": false, "data": "", "error": "bridge_invalid_result"}

func _eval(script: String) -> Variant:
	var bridge := _js_bridge()
	return bridge.call("eval", script) if bridge != null else null

func _js_bridge() -> Object:
	if _bridge == null:
		_bridge = Engine.get_singleton("JavaScriptBridge")
	return _bridge
