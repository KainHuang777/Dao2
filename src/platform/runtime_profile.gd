class_name RuntimeProfile
extends RefCounted
## Opt-in diagnostic timing only. Never reads or changes game/save state.
## The isolated /profile.html observer supplies this bridge; normal play is off.
static var enabled := false
static var _bridge: JavaScriptObject
static var _frame_start := 0
static var _spans: Dictionary = {}

static func configure_web() -> void:
	enabled = false
	_bridge = null
	# get_interface logs an engine error for an absent global. Normal exports
	# intentionally have no observer, so check presence before resolving it.
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("typeof window.dao2RuntimeProfile === 'object' && window.dao2RuntimeProfile !== null")):
		_bridge = JavaScriptBridge.get_interface("dao2RuntimeProfile")
		enabled = _bridge != null

static func begin_frame() -> void:
	if not enabled:
		return
	_spans = {}
	_frame_start = Time.get_ticks_usec()

static func begin() -> int:
	return Time.get_ticks_usec() if enabled and _frame_start > 0 else 0

static func end(section: String, started: int) -> void:
	if started == 0:
		return
	_spans[section] = int(_spans.get(section, 0)) + Time.get_ticks_usec() - started

static func end_frame() -> void:
	if not enabled or _frame_start == 0:
		return
	var duration := Time.get_ticks_usec() - _frame_start
	_frame_start = 0
	if _bridge != null:
		_bridge.record(duration, JSON.stringify(_spans))
