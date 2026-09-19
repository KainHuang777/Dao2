class_name WebStorageAdapter
extends StorageAdapter

const DEFAULT_NAMESPACE := "dao2"
const _WRAPPER_TEMPLATE := """(function () {
	if (window.__dao2storage) {
		return;
	}
	var dbPromise = null;
	function openDatabase() {
		if (!dbPromise) {
			dbPromise = new Promise(function (resolve, reject) {
				var request = indexedDB.open("%s", 1);
				request.onupgradeneeded = function (event) {
					var db = event.target.result;
					if (!db.objectStoreNames.contains("kv")) {
						db.createObjectStore("kv");
					}
				};
				request.onsuccess = function (event) {
					resolve(event.target.result);
				};
				request.onerror = function (event) {
					reject(event.target.error);
				};
			});
		}
		return dbPromise;
	}
	function run(kind, key, data) {
		var seq = (window.__dao2storageSeq || 0) + 1;
		window.__dao2storageSeq = seq;
		var pending = { id: seq, kind: kind, key: key, ok: false, data: null, error: "pending" };
		window.__dao2storagePending = pending;
		openDatabase().then(function (db) {
			var mode = (kind === "write" || kind === "erase") ? "readwrite" : "readonly";
			var transaction = db.transaction("kv", mode);
			var store = transaction.objectStore("kv");
			if (kind === "write") {
				store.put(data, key);
				transaction.oncomplete = function () {
					pending.ok = true;
					pending.error = "";
				};
				transaction.onerror = function (event) {
					pending.ok = false;
					pending.error = String(event.target.error || "idb_error");
				};
			} else if (kind === "read") {
				var readRequest = store.get(key);
				readRequest.onsuccess = function () {
					pending.ok = true;
					pending.data = readRequest.result === undefined ? null : readRequest.result;
					pending.error = "";
				};
				readRequest.onerror = function (event) {
					pending.ok = false;
					pending.error = String(event.target.error || "idb_error");
				};
			} else if (kind === "erase") {
				store.delete(key);
				transaction.oncomplete = function () {
					pending.ok = true;
					pending.error = "";
				};
				transaction.onerror = function (event) {
					pending.ok = false;
					pending.error = String(event.target.error || "idb_error");
				};
			}
		}).catch(function (error) {
			pending.ok = false;
			pending.error = String(error && error.message ? error.message : error);
		});
		return String(seq);
	}
	function poll(id) {
		var pending = window.__dao2storagePending || null;
		if (pending === null || pending.id !== id) {
			return JSON.stringify({ id: id, ok: false, data: null, error: "pending" });
		}
		return JSON.stringify(pending);
	}
	window.__dao2storage = { run: run, poll: poll };
})();"""

var _namespace: String
var _persistent_confirmed := false
var _bridge: Object = null
var _wrapper_installed := false

func _init(p_namespace: String = DEFAULT_NAMESPACE) -> void:
	_namespace = p_namespace

func read(key: String) -> Dictionary:
	if not OS.has_feature("web"):
		return {"ok": false, "data": "", "error": "not_web"}
	var bridge := _js_bridge()
	if bridge == null:
		return {"ok": false, "data": "", "error": "not_web"}
	if not _install_wrapper(bridge):
		return {"ok": false, "data": "", "error": "bridge_failed"}
	var request_id := _web_run(bridge, "read", key, "")
	if request_id == "":
		return {"ok": false, "data": "", "error": "bridge_failed"}
	var polled: Variant = _web_poll(bridge, request_id)
	if not (polled is Dictionary):
		return {"ok": false, "data": "", "error": "bridge_failed"}
	if not polled.get("ok", false):
		return {"ok": false, "data": "", "error": String(polled.get("error", "pending"))}
	var value: Variant = polled.get("data")
	if value == null:
		return {"ok": false, "data": "", "error": "missing"}
	return {"ok": true, "data": String(value), "error": ""}

func write(key: String, data: String) -> Dictionary:
	if not OS.has_feature("web"):
		return {"ok": false, "error": "not_web"}
	var bridge := _js_bridge()
	if bridge == null:
		return {"ok": false, "error": "not_web"}
	if not _install_wrapper(bridge):
		return {"ok": false, "error": "bridge_failed"}
	var request_id := _web_run(bridge, "write", key, data)
	if request_id == "":
		return {"ok": false, "error": "bridge_failed"}
	var polled: Variant = _web_poll(bridge, request_id)
	if not (polled is Dictionary):
		return {"ok": false, "error": "bridge_failed"}
	if not polled.get("ok", false):
		return {"ok": false, "error": String(polled.get("error", "pending"))}
	_persistent_confirmed = true
	return {"ok": true, "error": ""}

func erase(key: String) -> Dictionary:
	if not OS.has_feature("web"):
		return {"ok": false, "error": "not_web"}
	var bridge := _js_bridge()
	if bridge == null:
		return {"ok": false, "error": "not_web"}
	if not _install_wrapper(bridge):
		return {"ok": false, "error": "bridge_failed"}
	var request_id := _web_run(bridge, "erase", key, "")
	if request_id == "":
		return {"ok": false, "error": "bridge_failed"}
	var polled: Variant = _web_poll(bridge, request_id)
	if not (polled is Dictionary):
		return {"ok": false, "error": "bridge_failed"}
	if not polled.get("ok", false):
		return {"ok": false, "error": String(polled.get("error", "pending"))}
	_persistent_confirmed = true
	return {"ok": true, "error": ""}

func exists(key: String) -> bool:
	if not OS.has_feature("web"):
		return false
	var bridge := _js_bridge()
	if bridge == null:
		return false
	if not _install_wrapper(bridge):
		return false
	var request_id := _web_run(bridge, "read", key, "")
	if request_id == "":
		return false
	var polled: Variant = _web_poll(bridge, request_id)
	if not (polled is Dictionary):
		return false
	if not polled.get("ok", false):
		return false
	return polled.get("data") != null

func backend_name() -> String:
	return "web_indexeddb"

func is_persistent() -> bool:
	return _persistent_confirmed

func _js_bridge() -> Object:
	if _bridge == null:
		_bridge = Engine.get_singleton("JavaScriptBridge")
	return _bridge

func _install_wrapper(bridge: Object) -> bool:
	if _wrapper_installed:
		return true
	var marker: Variant = _eval_js(bridge, "typeof window.__dao2storage")
	if marker != "object":
		_eval_js(bridge, _WRAPPER_TEMPLATE % _namespace)
		marker = _eval_js(bridge, "typeof window.__dao2storage")
	if marker != "object":
		return false
	_wrapper_installed = true
	return true

func _web_run(bridge: Object, kind: String, key: String, data: String) -> String:
	var code := "window.__dao2storage.run(" + JSON.stringify(kind) + "," + JSON.stringify(key) + "," + JSON.stringify(data) + ")"
	var result: Variant = _eval_js(bridge, code)
	if result == null:
		return ""
	return String(result)

func _web_poll(bridge: Object, request_id: String) -> Variant:
	var code := "window.__dao2storage.poll(" + request_id + ")"
	var result: Variant = _eval_js(bridge, code)
	if result == null:
		return {}
	var parsed: Variant = JSON.parse_string(String(result))
	if parsed is Dictionary:
		return parsed
	return {}

func _eval_js(bridge: Object, code: String) -> Variant:
	return bridge.call("eval", code)