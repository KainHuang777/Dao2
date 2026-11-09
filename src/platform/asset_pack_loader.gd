class_name AssetPackLoader
extends Node
## Lazy loading and dynamic mounting for optional/late-game DLC packs in Web builds.
## Keeps local runners and desktop builds zero-overhead (direct res:// fallback).

enum Status { NOT_LOADED, DOWNLOADING, MOUNTED, FAILED }

signal pack_loaded(pack_id: String, success: bool)
signal pack_progress(pack_id: String, percent: float)

const PACKS := {
	"dlc_sect_lore": {
		"file": "dlc_sect_lore.pck",
		"sample": "res://assets/ui/sect-life/sect_ceremony_banner.png",
		"title": "宗門百態與名山畫卷",
		"priority": 1
	},
	"dlc_beasts_features": {
		"file": "dlc_beasts_features.pck",
		"sample": "res://assets/ui/beasts-painted/sect-reform/taixu_baize.png",
		"title": "守護靈獸與輪迴天地",
		"priority": 2
	}
}

static var _instance: AssetPackLoader = null

var _status: Dictionary = {}
var _callbacks: Dictionary = {}
var _active_requests: Dictionary = {}
var _prefetch_started: bool = false

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

## Check whether a DLC pack is accessible (either already bundled or mounted).
static func is_pack_mounted(pack_id: String) -> bool:
	if not PACKS.has(pack_id):
		return true
	var sample_path: String = String(PACKS[pack_id].get("sample", ""))
	if sample_path != "" and (ResourceLoader.exists(sample_path) or FileAccess.file_exists(sample_path)):
		return true
	if _instance != null and _instance._status.get(pack_id, Status.NOT_LOADED) == Status.MOUNTED:
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
	if not PACKS.has(pack_id):
		if callback.is_valid():
			callback.call_deferred(true)
		return

	if is_pack_mounted(pack_id):
		_status[pack_id] = Status.MOUNTED
		if callback.is_valid():
			callback.call_deferred(true)
		return

	if callback.is_valid():
		(_callbacks[pack_id] as Array).append(callback)

	if _status.get(pack_id, Status.NOT_LOADED) == Status.DOWNLOADING:
		return

	var file_name: String = String(PACKS[pack_id].get("file", ""))
	var local_path := "user://" + file_name

	# Check if previously downloaded and stored in user://
	if FileAccess.file_exists(local_path):
		var ok := ProjectSettings.load_resource_pack(local_path)
		if ok:
			_status[pack_id] = Status.MOUNTED
			_dispatch_callbacks(pack_id, true)
			emit_signal("pack_loaded", pack_id, true)
			return

	# Only Web needs HTTP download; desktop/local uses direct res://
	if not OS.has_feature("web"):
		# On local non-web, if res:// didn't have it and user:// doesn't, mark mounted or fallback
		_status[pack_id] = Status.MOUNTED
		_dispatch_callbacks(pack_id, true)
		emit_signal("pack_loaded", pack_id, true)
		return

	_start_download(pack_id, file_name, local_path)

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

## Begins background download of all unmounted DLC packs one after another.
func start_background_prefetch() -> void:
	if _prefetch_started:
		return
	_prefetch_started = true
	var pack_ids := PACKS.keys()
	pack_ids.sort_custom(func(a: String, b: String) -> bool:
		return int(PACKS[a].get("priority", 99)) < int(PACKS[b].get("priority", 99))
	)
	_prefetch_next(pack_ids, 0)

func _prefetch_next(pack_ids: Array, index: int) -> void:
	if index >= pack_ids.size():
		return
	var pack_id: String = pack_ids[index]
	ensure_pack(pack_id, func(_success: bool) -> void:
		# Wait 2 seconds between background downloads to avoid saturating network/CPU
		await get_tree().create_timer(2.0).timeout
		_prefetch_next(pack_ids, index + 1)
	)

