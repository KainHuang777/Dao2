extends RefCounted
## Pure presentation policy. No Node, Session, RNG, cost or persistence access.
## SHELL-2 applies effective display to the full canonical route matrix.
const GROUPS := {
	"management": {"title": "經營", "pages": [["buildings", "洞府建築"], ["outposts", "空島"], ["manufacturing", "製造"], ["transport", "運輸"]]},
	"cultivation": {"title": "修行", "pages": [["skills", "技能"], ["alchemy", "煉丹"], ["beasts", "靈獸"], ["achievements", "成就"], ["reincarnation", "輪迴天賦"]]},
	"journey": {"title": "遊歷", "pages": [["realms", "九界"], ["sect", "宗門"], ["fortune", "機緣"], ["decisions", "天道決策"]]},
}
const INVENTORY_ROUTES := ["buildings", "outposts", "manufacturing", "transport", "alchemy"]
const FOCUSED_ROUTES := ["skills", "beasts", "fortune", "decisions"]
const OVERLAY_PRIORITY := {"resources": 1, "messages": 1, "tool": 1, "report": 2, "sequence": 3, "protection": 4}

static func owner(route: String) -> String:
	for group in GROUPS:
		for entry in GROUPS[group].pages:
			if entry[0] == route:
				return group
	return ""

static func legal_route(route: String, view: Dictionary) -> String:
	if route == "home":
		return route
	var group := owner(route)
	if group.is_empty():
		return "home"
	if FeatureUnlocks.check(route, view).state != FeatureUnlocks.State.HIDDEN:
		return route
	# Same fallback order as the existing group navigator, including previews.
	for state in [FeatureUnlocks.State.AVAILABLE, FeatureUnlocks.State.PREVIEW]:
		for entry in GROUPS[group].pages:
			if FeatureUnlocks.check(entry[0], view).state == state:
				return entry[0]
	return "home"

static func resolve(state: Dictionary, vp: Vector2, context: Dictionary = {}) -> Dictionary:
	var route := String(state.get("route", "home"))
	var home := route == "home"
	# Existing docs07 breakpoint, with shared height pressure; HTML's1100 is not adopted.
	var portrait := vp.x < vp.y
	var wide := not portrait and vp.x >= 960.0 and vp.y >= 500.0 and vp.x >= vp.y * 1.45
	var prefs: Dictionary = state.get("home_preferences", {})
	var overlay := String(state.get("overlay", ""))
	var blocking := not overlay.is_empty() or portrait
	var confirmation := bool(state.get("confirmation", false))
	var resource_context := "none"
	if home:
		resource_context = "home"
	elif route in INVENTORY_ROUTES:
		resource_context = "inventory"
	elif route in FOCUSED_ROUTES:
		resource_context = "focused"
	elif route == "sect":
		resource_context = "inventory" if state.get("subpage", "") in ["techniques", "market"] else "focused"
	elif route == "reincarnation" and state.get("subpage", "") == "talents":
		resource_context = "focused"
	# Fortune's exact costs are provided by the real View adapter, never inferred here.
	if route == "fortune" and not bool(context.get("has_costs", false)):
		resource_context = "none"
	var mode := clampi(int(prefs.get("resource_mode", 1)), 0, 2) if home else 1
	var resource_open := resource_context != "none" and (mode > 0 if home else not bool(state.get("resources_collapsed", false)))
	var presentation := "hidden"
	if resource_open:
		presentation = "rail" if wide and resource_context in ["home", "inventory"] else "summary"
	if overlay == "resources" and not portrait:
		presentation = "drawer"
	var cinematic := overlay == "sequence"
	return {
		"route": route, "layout": "portrait" if portrait else ("wide" if wide else "compact"),
		"hud": "hidden" if portrait or cinematic or overlay == "protection" else ("full" if home else "compact"),
		"navigation": not portrait and not cinematic and overlay != "protection",
		"navigation_input": not blocking, "page_input": not blocking and not confirmation,
		"confirmation_input": not blocking and confirmation,
		"world_input": home and not blocking,
		"resource_context": resource_context, "resource_mode": mode,
		"resource_presentation": "hidden" if portrait or cinematic or overlay == "protection" else presentation,
		"resource_entry": not portrait and not cinematic and overlay != "protection" and resource_context != "none",
		"messages": "reading" if overlay == "messages" and not portrait else ("home" if home and not blocking and bool(prefs.get("messages_open", true)) and not bool(context.get("home_message_obstructs", false)) else "hidden"),
		"critical_alert": bool(context.get("save_failed", false)) or bool(context.get("lifespan_exhausted", false)),
		"overlay": overlay, "overlay_token": int(state.get("overlay_token", 0)),
	}
