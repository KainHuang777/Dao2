extends RefCounted
## Read-only discovery and shortage routing. Never stores tutorial progress.
static func opened(view: Dictionary, id: String) -> bool:
	return id == "home" or bool(view.get("manufacturing", {}).get("islands", {}).get(id, {}).get("opened", false))

static func discovered(view: Dictionary, route: String) -> bool:
	if int(view.get("era_id", 1)) != 2: return true
	if route == "manufacturing": return opened(view, "wood") or opened(view, "ore")
	if route == "transport": return opened(view, "wood") and opened(view, "ore")
	return true

static func shortage(view: Dictionary, recipe: Dictionary, routes: Dictionary) -> Dictionary:
	var island: String = recipe.get("island", "home")
	if not opened(view, island): return {"page": "outposts", "id": island, "label": "開拓"}
	var local_fix := {}
	for resource in recipe.get("inputs", {}):
		var input: Dictionary = recipe.inputs[resource]
		if float(input.available) >= float(input.required): continue
		for id in routes:
			var def: Array = routes[id]
			if def[1] != island or def[2] != resource: continue
			if not opened(view, def[0]): return {"page": "outposts", "id": def[0], "label": "開拓補料島"}
			return {"page": "transport", "id": id, "label": "運送缺料"}
		local_fix = {"page": "outposts", "id": island, "label": "採集／升級"} if island != "home" and String(input.get("source","home")) != "home" else {"page": "buildings", "id": "home", "label": "補充祖島資源"}
	return local_fix
