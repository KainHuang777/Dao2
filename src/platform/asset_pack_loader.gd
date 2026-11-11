class_name AssetPackLoader
extends Node
## Lazy loading and dynamic mounting for optional/late-game DLC packs in Web builds.
## Keeps local runners and desktop builds zero-overhead (direct res:// fallback).

enum Status { NOT_LOADED, DOWNLOADING, MOUNTED, FAILED }

signal pack_loaded(pack_id: String, success: bool)
signal pack_progress(pack_id: String, percent: float)

const PACKS := {
	"era2_assets": {
		"file": "era2_assets.pck",
		"sample": "res://assets/ui/sect-life/taixu-gate-portrait.png",
		"title": "築基宗門與天道機緣",
		"era": 2,
		"priority": 1
	},
	"era3_assets": {
		"file": "era3_assets.pck",
		"sample": "res://assets/ui/beasts-painted/sect-reform/taixu_baize.png",
		"title": "守護靈獸與輪迴天地",
		"era": 3,
		"priority": 2
	}
}

const ALIASES := {
	"dlc_sect_lore": "era2_assets",
	"dlc_beasts_features": "era3_assets"
}

static var _instance: AssetPackLoader = null

var _status: Dictionary = {}
var _callbacks: Dictionary = {}
var _active_requests: Dictionary = {}
var _prefetch_started: bool = false
var _last_prefetched_era: int = 0

func _init() -> void:
	_instance = self
	for pack_id in PACKS.keys():
		_status[pack_id] = Status.NOT_LOADED
		_callbacks[pack_id] = []

func _enter_tree() -> void:
	if _instance == null:
		_instance = self

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

static func canonical_id(pack_id: String) -> String:
	return ALIASES.get(pack_id, pack_id)

## Check whether a DLC pack is accessible (either already bundled or mounted).
static func is_pack_mounted(pack_id: String) -> bool:
	var cid := canonical_id(pack_id)
	if not PACKS.has(cid):
		return true
	var sample_path: String = String(PACKS[cid].get("sample", ""))
	if sample_path != "" and (ResourceLoader.exists(sample_path) or FileAccess.file_exists(sample_path)):
		return true
	if _instance != null and _instance._status.get(cid, Status.NOT_LOADED) == Status.MOUNTED:
		return true
	return false

## Safely loads a texture, returning fallback if pack not yet mounted.
static func load_texture_safe(res_path: String, fallback: Texture2D = null) -> Texture2D:
	if res_path != "" and ResourceLoader.exists(res_path):
		return load(res_path) as Texture2D
	return fallback

## Returns the singleton instance if instantiated.
static func get_instance() -> AssetPackLoader:
	return _instance

## Ensures the requested pack is loaded and mounted, invoking callback(success).
func ensure_pack(pack_id: String, callback: Callable = Callable()) -> void:
	var cid := canonical_id(pack_id)
	if not PACKS.has(cid):
		if callback.is_valid():
			callback.call_deferred(true)
		return

	if is_pack_mounted(cid):
		_status[cid] = Status.MOUNTED
		if callback.is_valid():
			callback.call_deferred(true)
		return

	if callback.is_valid():
		if not _callbacks.has(cid):
			_callbacks[cid] = []
		(_callbacks[cid] as Array).append(callback)

	if _status.get(cid, Status.NOT_LOADED) == Status.DOWNLOADING:
		return

	var file_name: String = String(PACKS[cid].get("file", ""))
	var local_path := "user://" + file_name

	# Check if previously downloaded and stored in user://
	if FileAccess.file_exists(local_path):
		var ok := ProjectSettings.load_resource_pack(local_path)
		if ok:
			_status[cid] = Status.MOUNTED
			_dispatch_callbacks(cid, true)
			emit_signal("pack_loaded", cid, true)
			emit_signal("pack_loaded", pack_id, true)
			return

	# Only Web needs HTTP download; desktop/local uses direct res://
	if not OS.has_feature("web"):
		_status[cid] = Status.MOUNTED
		_dispatch_callbacks(cid, true)
		emit_signal("pack_loaded", cid, true)
		emit_signal("pack_loaded", pack_id, true)
		return

	_start_download(cid, file_name, local_path)

func _start_download(pack_id: String, file_name: String, local_path: String) -> void:
	_status[pack_id] = Status.DOWNLOADING
	var http := HTTPRequest.new()
	add_child(http)
	_active_requests[pack_id] = http

	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		_active_requests.erase(pack_id)

		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or body.is_empty():
			_status[pack_id] = Status.FAILED
			_dispatch_callbacks(pack_id, false)
			emit_signal("pack_loaded", pack_id, false)
			return

		var file := FileAccess.open(local_path, FileAccess.WRITE)
		if file == null:
			_status[pack_id] = Status.FAILED
			_dispatch_callbacks(pack_id, false)
			emit_signal("pack_loaded", pack_id, false)
			return

		file.store_buffer(body)
		file.close()

		var mounted := ProjectSettings.load_resource_pack(local_path)
		if mounted:
			_status[pack_id] = Status.MOUNTED
			_dispatch_callbacks(pack_id, true)
			emit_signal("pack_loaded", pack_id, true)
		else:
			_status[pack_id] = Status.FAILED
			_dispatch_callbacks(pack_id, false)
			emit_signal("pack_loaded", pack_id, false)
	)

	# Relative path requests file from same web directory
	var error := http.request(file_name)
	if error != OK:
		http.queue_free()
		_active_requests.erase(pack_id)
		_status[pack_id] = Status.FAILED
		_dispatch_callbacks(pack_id, false)
		emit_signal("pack_loaded", pack_id, false)

func _dispatch_callbacks(pack_id: String, success: bool) -> void:
	var list: Array = _callbacks.get(pack_id, [])
	_callbacks[pack_id] = []
	for cb in list:
		if (cb as Callable).is_valid():
			(cb as Callable).call_deferred(success)

## Preloads next EAR assets based on player's current progression era.
## EAR1 background preloads EAR2; EAR2 background preloads EAR3+.
func prefetch_for_era(current_era: int) -> void:
	_last_prefetched_era = current_era
	if current_era <= 1:
		ensure_pack("era2_assets")
	elif current_era == 2:
		ensure_pack("era2_assets", func(_ok: bool):
			ensure_pack("era3_assets")
		)
	else:
		ensure_pack("era2_assets", func(_ok: bool):
			ensure_pack("era3_assets")
		)

## Begins background download pipeline starting with current ERA.
func start_background_prefetch() -> void:
	if _prefetch_started:
		return
	_prefetch_started = true
	prefetch_for_era(_last_prefetched_era if _last_prefetched_era > 0 else 1)
