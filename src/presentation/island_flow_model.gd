extends RefCounted
## Pure contextual remedies. Navigation never spends resources or alters policies.
const BUILDINGS := {"wood":"forest_farm","stone_low":"stone_mine","spirit_grass_low":"herb_farm","money":"wooden_house","lingli":"hut","lingqi":"hut"}
const STORAGE := {"wood":"storage_wood","stone_low":"storage_stone","spirit_grass_low":"storage_herb","money":"storage_money","lingli":"storage_lingli"}
const PRODUCTS := {"spirit_timber":"spirit_timber","bronze_essence":"bronze_essence","liquid":"liquid","stone_mid":"stone_mid","formation_core":"formation_core","foundation_pill":"foundation_pill"}
static func hub(view: Dictionary) -> bool:
	return int(view.get("economy",{}).get("hub_version",0)) >= 1
static func opened(view: Dictionary, id: String) -> bool:
	return id == "home" or bool(view.get("manufacturing", {}).get("islands", {}).get(id, {}).get("opened", false))
static func routes(view: Dictionary) -> Dictionary:
	var result: Dictionary = IslandEconomy.ROUTES.duplicate(true)
	for id in view.get("transport",{}):
		var definition: Array = view.transport[id].get("definition",[])
		if definition.size() >= 3: result[id] = definition
	return result
static func discovered(view: Dictionary, route: String) -> bool:
	if int(view.get("era_id", 1)) != 2: return true
	if route == "manufacturing": return opened(view, "wood") or opened(view, "ore")
	if route == "transport": return opened(view, "wood") or opened(view, "ore") if hub(view) else opened(view, "wood") and opened(view, "ore")
	return true
static func home_available(view: Dictionary, resource: String) -> float:
	var economy: Dictionary = view.get("economy",{})
	if not String(economy.get("version","")).is_empty(): return float(economy.get("inventory",{}).get("home",{}).get(resource,{}).get("available",0))
	var value: Variant = view.get("resources",{}).get(resource,{}).get("value",0)
	return value.to_float() if value is AmountCompat else float(value)
static func opening(view: Dictionary, island: String) -> Dictionary:
	var definition: Dictionary = IslandEconomy.ISLANDS.get(island,{})
	if int(view.get("era_id",1)) < int(definition.get("era",1)): return {}
	for id in definition.get("facility",{}):
		var building: Variant = view.get("buildings",{}).get(id,{})
		var level: int = int(building.get("level",0)) if building is Dictionary else int(building)
		if level < int(definition.facility[id]): return {"page":"buildings","id":id,"label":"前往所需設施"}
	for id in definition.get("cost",{"wood":20,"stone_low":10}):
		var required: float = float(definition.get("cost",{"wood":20,"stone_low":10})[id])
		if home_available(view,id) < required: return resource_fix(view,id,required,routes(view))
	return {}
static func resource_fix(view: Dictionary, resource: String, required: float, definitions: Dictionary) -> Dictionary:
	var cap_value: Variant = view.get("resources",{}).get(resource,{}).get("cap")
	var cap: float = cap_value.to_float() if cap_value is AmountCompat else float(cap_value) if cap_value != null else INF
	if required > cap and STORAGE.has(resource): return {"page":"buildings","id":STORAGE[resource],"label":"提升祖島容量"}
	if PRODUCTS.has(resource): return {"page":"manufacturing","id":PRODUCTS[resource],"label":"製造缺少材料"}
	var fallback := {}
	for id in definitions:
		var definition: Array = definitions[id]
		if definition[1] != "home" or definition[2] != resource: continue
		var info: Dictionary = view.get("transport",{}).get(id,{})
		if bool(info.get("legacy",false)): continue
		if not opened(view,definition[0]):
			fallback = {"page":"outposts","id":definition[0],"label":"開拓補料島"}
			continue
		var trip: Dictionary = info.get("trip",{})
		if not trip.is_empty(): return {"page":"transport","id":id,"label":"查看到貨","status":"缺料在途・%d秒到祖島" % int(trip.get("remaining",0))}
		var settings: Dictionary = info.get("settings",{})
		var reason: String = info.get("reason","")
		if bool(settings.get("enabled",false)):
			var message := "補給已啟用・等待原料出航"
			if reason == "TARGET_REACHED": message = "航線目標低於製造需求・請調整目標"
			elif reason == "DESTINATION_FULL": message = "祖島容量不足・請先使用或擴充"
			elif reason == "NO_SURPLUS": message = "來源保留量限制出貨・請調整政策" if float(settings.get("reserve",0)) > 0 else "產地採集中・等待原料"
			return {"page":"transport","id":id,"label":"查看補給設定","status":message}
		return {"page":"transport","id":id,"label":"啟用補給","status":"原料須先運到祖島","quick":true}
	if BUILDINGS.has(resource): return {"page":"buildings","id":BUILDINGS[resource],"label":"前往祖島生產"}
	return fallback if not fallback.is_empty() else {"page":"buildings","id":"home","label":"查看祖島資源"}
static func shortage(view: Dictionary, recipe: Dictionary, definitions: Dictionary) -> Dictionary:
	var island: String = recipe.get("island", "home")
	if not opened(view, island): return {"page": "outposts", "id": island, "label": "開拓產業島"}
	var local_fix := {}
	for resource in recipe.get("inputs", {}):
		var input: Dictionary = recipe.inputs[resource]
		if float(input.available) >= float(input.required): continue
		if hub(view): return resource_fix(view,resource,float(input.required),definitions)
		for id in definitions:
			var definition: Array = definitions[id]
			if definition[1] != island or definition[2] != resource: continue
			if not opened(view, definition[0]): return {"page": "outposts", "id": definition[0], "label": "開拓補料島"}
			return {"page": "transport", "id": id, "label": "運送缺料"}
		local_fix = {"page": "outposts", "id": island, "label": "採集／升級"} if island != "home" and String(input.get("source","home")) != "home" else {"page": "buildings", "id": BUILDINGS.get(resource,"home"), "label": "補充祖島資源"}
	return local_fix
