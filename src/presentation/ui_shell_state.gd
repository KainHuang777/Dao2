extends RefCounted
## In-memory intent, independent of visible Controls. Not part of GameState/save.
const Policy = preload("res://src/presentation/ui_shell_policy.gd")
var _route := "home"
var _subpage := ""
var _home_preferences := {"resource_mode": 1, "messages_open": true}
var _resources_collapsed := false
var _overlay := ""
var _overlay_token := 0
var _confirmation := false
var _detail := false

func snapshot() -> Dictionary:
	return {"route": _route, "subpage": _subpage,
		"home_preferences": _home_preferences.duplicate(true),
		"resources_collapsed": _resources_collapsed, "overlay": _overlay,
		"overlay_token": _overlay_token, "confirmation": _confirmation, "detail": _detail}

func set_home_preferences(resource_mode: int, messages_open: bool) -> void:
	_home_preferences = {"resource_mode": clampi(resource_mode, 0, 2), "messages_open": messages_open}

func navigate(route: String, view: Dictionary, subpage: String = "") -> bool:
	if not _overlay.is_empty():
		return false
	var target := Policy.legal_route(route, view)
	if target != _route:
		_resources_collapsed = false
		_confirmation = false
		_detail = false
	if target != _route or subpage != _subpage:
		_confirmation = false
		_detail = false
	_route = target
	_subpage = subpage if target == route else ""
	return true

func revalidate(view: Dictionary) -> void:
	var target := Policy.legal_route(_route, view)
	if target != _route:
		_route = target
		_subpage = ""
		_resources_collapsed = false
		_confirmation = false
		_detail = false

func collapse_resources(collapsed: bool) -> void:
	_resources_collapsed = collapsed

func set_confirmation(active: bool) -> void:
	_confirmation = active

func set_subpage(subpage: String) -> void:
	# The owning page retains its tab and drafts; ticks only observe that context.
	_subpage = subpage

func set_detail(active: bool) -> void:
	_detail = active

func open_overlay(kind: String) -> int:
	if not Policy.OVERLAY_PRIORITY.has(kind):
		return 0
	if not _overlay.is_empty() and Policy.OVERLAY_PRIORITY[kind] < Policy.OVERLAY_PRIORITY[_overlay]:
		return 0
	# At most one overlay. Replacement invalidates every earlier close callback.
	_overlay_token += 1
	_overlay = kind
	return _overlay_token

func finish_overlay(token: int, view: Dictionary) -> bool:
	if _overlay.is_empty() or token != _overlay_token:
		return false
	_overlay = ""
	revalidate(view)
	return true

func escape(view: Dictionary) -> String:
	if not _overlay.is_empty():
		if _overlay in ["report", "sequence", "protection"]:
			return "blocked"
		finish_overlay(_overlay_token, view)
		return "overlay"
	if _confirmation:
		_confirmation = false
		return "confirmation"
	if _detail:
		_detail = false
		return "detail"
	if _route != "home":
		navigate("home", view)
		return "home"
	return "none"
