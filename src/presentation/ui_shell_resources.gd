extends RefCounted
## Read-only resource context. Costs remain in the existing command cards.
const Icon = preload("res://src/presentation/resource_icon.gd")
const NumberFormatter = preload("res://src/utils/number_formatter.gd")
static func describe(snapshot: Dictionary, view: Dictionary, nav: RefCounted) -> Dictionary:
	var route: String = snapshot.route
	var resources: Dictionary = view.get("resources", {})
	var lines: Array[String] = []
	var summary := "資源"
	var has_costs := false
	match route:
		"home", "buildings", "alchemy":
			summary = "靈草 %s" % _value(resources, "spirit_grass_low") if route == "alchemy" else "建設材料"
			for id in ["lingli", "wood", "stone_low", "spirit_grass_low"]:
				lines.append("%s %s" % [_name(id), _value(resources, id)])
		"outposts", "manufacturing", "transport":
			var islands: Array = []
			if route == "outposts": islands = [nav.island_panel.island]
			elif route == "manufacturing":
				if not nav.manufacturing_panel.selected_recipe.is_empty(): islands = [nav.manufacturing_panel.island]
				else: islands = [nav.manufacturing_panel.island_filter] if not nav.manufacturing_panel.island_filter.is_empty() else view.get("manufacturing", {}).get("islands", {}).keys()
			elif not nav.transport_panel.selected_route.is_empty():
				var def: Array = nav.transport_panel._routes()[nav.transport_panel.selected_route]
				islands = [def[0], def[1]]
			else: islands = [nav.transport_panel.island]
			summary = "當地庫存" if route != "transport" else "航線庫存"
			var economy: Dictionary = view.get("economy", {})
			if route == "outposts" and (nav._legacy_outposts or nav.abode.content.processing_catalog.is_empty()):
				lines.append("靈界據點\n極品靈晶 %s／%s\n天青靈液 %s／%s" % [view.get("realm", {}).get("spirit_crystal", 0), view.get("realm", {}).get("crystal_cap", 0), view.get("realm", {}).get("azure_nectar", 0), view.get("realm", {}).get("nectar_cap", 0)])
			else:
				for island in islands:
					lines.append(IslandProgression.NAMES.get(island, island) + "・當地")
					var stock: Dictionary = economy.get("inventory", {}).get(island, {})
					if stock.is_empty(): lines.append("尚無當地庫存；開拓成本見原卡。")
					for id in stock:
						var slot: Dictionary = stock[id]
						if island != "home" and float(slot.get("available", 0)) == 0 and float(slot.get("reserved", 0)) == 0 and not view.get("manufacturing", {}).get("islands", {}).get(island, {}).get("rates", {}).has(id): continue
						var capacity: Variant = resources.get(id, {}).get("cap", "—") if island == "home" else view.get("manufacturing", {}).get("islands", {}).get(island, {}).get("capacity", "—")
						lines.append("%s\n可用 %s・預留 %s\n容量 %s" % [_name(id), _number(slot.get("available", 0)), _number(slot.get("reserved", 0)), _number(capacity)])
				for id in economy.get("routes", {}):
					var def: Array = nav.transport_panel._routes().get(id, [])
					if def.size() >= 2 and (def[0] in islands or def[1] in islands):
						lines.append("%s → %s・%s\n在途 %s" % [IslandProgression.NAMES.get(def[0], def[0]), IslandProgression.NAMES.get(def[1], def[1]), _name(def[2]), _number(economy.get("trips", {}).get(id, {}).get("cargo", 0))])
				lines.append("祖島付款材料")
				for id in ["wood", "stone_low", "spirit_timber", "bronze_essence", "lingli"]:
					lines.append("%s %s" % [_name(id), _value(resources, id)])
		"skills":
			summary = "技能點 %s" % _value(resources, "skill_point")
			lines.append(summary)
		"beasts":
			var beast: Dictionary = view.get("beast", {})
			summary = "餵養／獸魂"
			for id in beast.get("feed_costs", {}):
				lines.append("%s %s／需求 %s" % [_name(id), _value(resources, id), beast.feed_costs[id]])
			for id in beast.get("souls", {}): lines.append("%s獸魂 %s" % [BeastSystem.BEAST_CONFIGS.get(id, {}).get("name", id), beast.souls[id]])
		"sect":
			summary = "貢獻 %s" % view.get("sect", {}).get("contribution", "0")
			lines.append(summary)
			if snapshot.subpage in ["techniques", "market"]:
				for id in resources:
					if bool(resources[id].get("visible", false)): lines.append("%s %s" % [_name(id), _value(resources, id)])
		"fortune":
			var pending: Dictionary = view.get("fortune", {}).get("pending_encounter", {})
			summary = "機緣成本"
			for option in pending.get("options", []):
				var cost: Dictionary = option.get("costs", {})
				for id in cost:
					has_costs = true
					var key := FortuneSystem.resource_key(resources, id)
					lines.append("%s %s／需求 %s" % [_name(key), _value(resources, key), cost[id]])
		"decisions":
			summary = "法令資源"
			var ids := {}
			for item in view.get("realm_decisions", []):
				for id in item.get("costs", {}): ids[id] = true
			for id in ids: lines.append("%s %s" % [_name(id), _value(resources, id)])
		"reincarnation":
			summary = "道心 %s" % view.get("dao_heart", "0")
			lines.append(summary)
			lines.append("道證 %s" % view.get("dao_proof", "0"))
	if nav.island_flow.visible and route in ["outposts","manufacturing","transport"]:
		summary = "製造庫存" if route == "manufacturing" else "航線庫存" if route == "transport" else "工程材料"
	return {"summary": summary, "details": "\n".join(lines), "has_costs": has_costs}

## Structured inventory for the shared icon panel. Values come straight from the
## real View; missing fields stay null and are marked in "provided".
const CURRENCY_IDS := ["lingli", "money", "skill_point", "spirit_crystal", "azure_nectar", "contribution", "dao_heart", "dao_proof"]
const PAYMENT_IDS := ["wood", "stone_low", "spirit_timber", "bronze_essence", "lingli"]
const PREFERRED_IDS := ["lingli", "money", "wood", "spirit_grass_low", "stone_low", "black_copper"]

static func inventory(snapshot: Dictionary, view: Dictionary, nav: RefCounted) -> Dictionary:
	var route := String(snapshot.get("route", ""))
	var result := {"supported": false, "context": route, "title": "庫存", "groups": [], "notes": []}
	if route == "sect":
		if String(snapshot.get("subpage", "")) in ["techniques", "market"]:
			var sect := _sect_inventory(view)
			sect.scope = "sect:" + String(snapshot.get("subpage", ""))
			return sect
		result.notes.append("宗門歷練沿用卡片內的獎勵與資源顯示")
		return result
	if route in ["skills", "beasts", "fortune", "decisions", "reincarnation"]:
		return _focused_inventory(snapshot, view)
	if route not in ["outposts", "manufacturing", "transport"]:
		result.notes.append("TODO IMM-1B／1C：此頁尚未接入圖像庫存")
		return result
	# Legacy realm outposts keep their existing text costs until a later stage.
	if route == "outposts" and (nav._legacy_outposts or nav.abode.content.processing_catalog.is_empty()):
		result.notes.append("舊靈界據點沿用文字成本列")
		return result
	if nav.island_flow.visible:
		return _island_work_inventory(view,nav)
	var islands: Array = []
	match route:
		"outposts":
			islands = [nav.island_panel.island]
		"manufacturing":
			if not nav.manufacturing_panel.selected_recipe.is_empty():
				islands = [nav.manufacturing_panel.island]
			elif not nav.manufacturing_panel.island_filter.is_empty():
				islands = [nav.manufacturing_panel.island_filter]
			else:
				islands = view.get("manufacturing", {}).get("islands", {}).keys()
		"transport":
			if nav.transport_panel.selected_route.is_empty():
				islands = [nav.transport_panel.island]
			else:
				var ends: Array = nav.transport_panel._routes().get(nav.transport_panel.selected_route, [])
				islands = [ends[0], ends[1]] if ends.size() >= 2 else [nav.transport_panel.island]
	if route == "manufacturing" and preload("res://src/presentation/island_flow_model.gd").hub(view): islands = ["home"]
	var economy: Dictionary = view.get("economy", {})
	var resources: Dictionary = view.get("resources", {})
	var manufacturing: Dictionary = view.get("manufacturing", {})
	var context_islands := islands.duplicate()
	if not "home" in islands:
		islands.append("home")
	var demand := _demand(route, view, nav)
	var groups: Array = []
	for island in islands:
		var stock: Dictionary = economy.get("inventory", {}).get(island, {})
		if stock.is_empty() and not island in context_islands:
			continue
		var rates: Dictionary = manufacturing.get("islands", {}).get(island, {}).get("rates", {})
		var payment_only: bool = island == "home" and not island in context_islands
		var group := {
			"id": "island:" + String(island),
			"title": String(IslandProgression.NAMES.get(island, island)) + ("・工程材料" if payment_only else "・當地"),
			"items": [],
		}
		for id in _ordered_ids(stock):
			if payment_only and not id in PAYMENT_IDS:
				continue
			var slot: Dictionary = stock[id]
			var available := float(slot.get("available", 0))
			var reserved := float(slot.get("reserved", 0))
			var key := "%s:%s" % [island, id]
			if available == 0.0 and reserved == 0.0 and not demand.has(key) and not rates.has(id) and not (island == "home" and bool(resources.get(id, {}).get("visible", false))):
				continue
			var item := {
				"key": key, "id": id, "name": Icon.get_resource_name(id),
				"kind": "currency" if id in CURRENCY_IDS else "item",
				"island": island, "source": String(IslandProgression.NAMES.get(island, island)),
				"display": "available", "provided": {},
				"available": null, "reserved": null, "capacity": null,
				"demand": null, "transit": null, "eta": null,
			}
			if slot.has("available"):
				item.available = slot.available
				item.provided.available = true
			if slot.has("reserved"):
				item.reserved = slot.reserved
				item.provided.reserved = true
			var capacity: Variant = _capacity(view, island, id)
			if capacity != null:
				item.capacity = capacity
				item.provided.capacity = true
			if demand.has(key):
				item.demand = demand[key]
				item.provided.demand = true
			var transit := _transit_to(economy, nav, island, id)
			if transit > 0.0:
				item.transit = transit
				item.provided.transit = true
			group.items.append(item)
		groups.append(group)
	var transit_group := _transit_group(economy, nav, context_islands)
	if not transit_group.items.is_empty():
		groups.append(transit_group)
	result.supported = true
	result.context = route
	result.scope = route + "|" + ",".join(context_islands)
	result.groups = groups
	return result

static func _ordered_ids(stock: Dictionary) -> Array:
	var ordered: Array = []
	for id in PREFERRED_IDS:
		if stock.has(id):
			ordered.append(id)
	for id in stock:
		if not id in ordered:
			ordered.append(id)
	return ordered

static func _island_work_inventory(view: Dictionary, nav: RefCounted) -> Dictionary:
	var panel = nav.island_flow
	var groups: Array = []
	var refs := {}
	var demands := {}
	var scope: String = panel.page + ":" + panel.island
	var title := "工程材料"
	if panel.page == "manufacturing":
		var recipe: Dictionary = view.get("manufacturing",{}).get("recipes",{}).get(panel.recipe,{})
		scope += ":" + panel.recipe
		title = "原料與產物持有量"
		for id in recipe.get("inputs",{}):
			var input: Dictionary = recipe.inputs[id]
			var source: String = input.get("source",recipe.island)
			if not refs.has(source): refs[source] = []
			refs[source].append(id)
			demands[source + ":" + id] = input.get("required")
		if not recipe.is_empty():
			var owner: String = recipe.get("output_island",recipe.island)
			var product: String = recipe.get("product_id",panel.recipe)
			if not refs.has(owner): refs[owner] = []
			if not product in refs[owner]: refs[owner].append(product)
			if owner != "home":
				if not refs.has("home"): refs.home = []
				if not product in refs.home: refs.home.append(product)
	elif panel.page == "transport" and panel._routes().has(panel.route):
		title = "航線兩端持有量"
		scope += ":" + panel.route
		var ends: Array = panel._routes()[panel.route]
		refs[ends[0]] = [ends[2]]
		refs[ends[1]] = [ends[2]]
	else:
		var cost: Dictionary = IslandEconomy.ISLANDS.get(panel.island,{}).get("cost",{"wood":20,"stone_low":10})
		if panel.managing_island:
			var facility: String = ["extractor","storage","workshop"][maxi(0,panel.facility.selected-1)]
			var level := int(view.get("economy",{}).get("islands",{}).get(panel.island,{}).get("facilities",{}).get(facility,1))
			cost = IslandProgression.upgrade_cost(facility,level)
		refs.home = cost.keys()
		for id in cost: demands["home:"+id] = cost[id]
	for owner in refs:
		var group := {"id":"work:"+owner,"title":String(IslandProgression.NAMES.get(owner,owner)) + ("・集中製造庫存" if preload("res://src/presentation/island_flow_model.gd").hub(view) and owner == "home" else "・可用庫存"),"items":[]}
		for id in refs[owner]:
			var key: String = owner + ":" + id
			var slot: Dictionary = view.get("economy",{}).get("inventory",{}).get(owner,{}).get(id,{})
			var item := _resource_item(view,id,key) if owner == "home" else _counter(key,id,Icon.get_resource_name(id),slot.get("available"),String(IslandProgression.NAMES.get(owner,owner)))
			item.island = owner
			item.kind = "currency" if id in CURRENCY_IDS else "item"
			if owner != "home":
				item.capacity = _capacity(view,owner,id)
				item.provided.capacity = item.capacity != null
				item.reserved = slot.get("reserved")
				item.provided.reserved = item.reserved != null
			if demands.has(key):
				item.demand = demands[key]
				item.provided.demand = true
			group.items.append(item)
		groups.append(group)
	return {"supported":true,"context":panel.page,"scope":scope,"title":title,"groups":groups,"notes":[]}

static func _capacity(view: Dictionary, island: String, id: String) -> Variant:
	if island == "home":
		var slot: Dictionary = view.get("resources", {}).get(id, {})
		return slot.get("cap", null) if slot.has("cap") else null
	var island_data: Dictionary = view.get("manufacturing", {}).get("islands", {}).get(island, {})
	return island_data.get("capacity", null) if island_data.has("capacity") else null

static func _demand(route: String, view: Dictionary, nav: RefCounted) -> Dictionary:
	var out := {}
	if route != "manufacturing" or String(nav.manufacturing_panel.selected_recipe).is_empty():
		return out
	var recipe_id := String(nav.manufacturing_panel.selected_recipe)
	var info: Dictionary = view.get("manufacturing", {}).get("recipes", {}).get(recipe_id, {})
	for id in info.get("inputs", {}):
		var input: Dictionary = info.inputs[id]
		var island := String(input.get("source", nav.manufacturing_panel.island))
		out["%s:%s" % [island, id]] = input.get("required")
	return out

static func _transit_to(economy: Dictionary, nav: RefCounted, island: String, id: String) -> float:
	var total := 0.0
	for route_id in economy.get("trips", {}):
		var ends: Array = nav.transport_panel._routes().get(route_id, [])
		if ends.size() >= 3 and String(ends[1]) == island and String(ends[2]) == id:
			total += float(economy.trips[route_id].get("cargo", 0))
	return total

static func _transit_group(economy: Dictionary, nav: RefCounted, context_islands: Array) -> Dictionary:
	var group := {"id": "transit", "title": "在途", "items": []}
	for route_id in economy.get("trips", {}):
		var trip: Dictionary = economy.trips[route_id]
		var cargo := float(trip.get("cargo", 0))
		var ends: Array = nav.transport_panel._routes().get(route_id, [])
		if cargo <= 0.0 or ends.size() < 3:
			continue
		if ends[0] in context_islands or ends[1] in context_islands:
			group.items.append({
				"key": "transit:%s:%s" % [route_id, ends[2]], "id": String(ends[2]),
				"name": Icon.get_resource_name(String(ends[2])), "kind": "item",
				"island": String(ends[0]),
				"source": "%s → %s" % [IslandProgression.NAMES.get(ends[0], ends[0]), IslandProgression.NAMES.get(ends[1], ends[1])],
				"display": "transit", "provided": {"transit": true, "eta": true} if trip.has("remaining") else {"transit": true},
				"available": null, "reserved": null, "capacity": null,
				"demand": null, "transit": trip.cargo, "eta": trip.get("remaining", null),
			})
	return group

static func _sect_inventory(view: Dictionary) -> Dictionary:
	var group := {"id": "sect:main", "title": "宗門貢獻", "items": []}
	var sect: Dictionary = view.get("sect", {})
	if sect.has("contribution"):
		group.items.append({
			"key": "sect:contribution", "id": "contribution", "name": "貢獻",
			"kind": "currency", "island": "sect", "source": "宗門",
			"display": "available", "provided": {"available": true},
			"available": sect.contribution, "reserved": null, "capacity": null,
			"demand": null, "transit": null, "eta": null,
		})
	var home := {"id": "sect:home", "title": "祖島材料", "items": []}
	for id in view.get("resources", {}):
		var slot: Dictionary = view.resources[id]
		if not bool(slot.get("visible", false)):
			continue
		home.items.append(_resource_item(view, id, "sect:home:%s" % id))
	return {"supported": true, "context": "sect", "title": "宗門資源", "groups": [group, home], "notes": []}

## Focused routes read the same View data as their page cards; the shared drawer
## shows the typed icon groups without inventing capacity or spend semantics.
static func _focused_inventory(snapshot: Dictionary, view: Dictionary) -> Dictionary:
	var route := String(snapshot.get("route", ""))
	var groups: Array = []
	match route:
		"skills":
			groups.append({"id": "skills:points", "title": "技能點", "items": [_counter("skills:skill_point", "skill_point", "技能點", view.get("resources", {}).get("skill_point", {}).get("value"), "當世") ]})
		"reincarnation":
			groups.append({"id": "reincarnation:currency", "title": "傳承", "items": [
				_counter("reincarnation:dao_heart", "dao_heart", "道心", view.get("dao_heart"), "傳承"),
				_counter("reincarnation:dao_proof", "dao_proof", "道證", view.get("dao_proof"), "傳承") ]})
		"beasts":
			var beast: Dictionary = view.get("beast", {})
			var food := {"id": "beasts:food", "title": "餵養材料", "items": []}
			var feed_ids: Array[String] = []
			for id in beast.get("feed_costs", {}):
				feed_ids.append(String(id))
			for beast_id in beast.get("care", {}):
				for id in beast.care[beast_id].get("costs", {}):
					if not feed_ids.has(String(id)):
						feed_ids.append(String(id))
			for id in feed_ids:
				var item := _resource_item(view, id, "beasts:food:%s" % id)
				if beast.get("feed_costs", {}).has(id):
					item.demand = beast.feed_costs[id]
					item.provided.demand = true
				food.items.append(item)
			var souls := {"id": "beasts:souls", "title": "獸魂", "items": []}
			for id in beast.get("souls", {}):
				var item := _counter("beasts:soul:%s" % id, id, String(BeastSystem.BEAST_CONFIGS.get(id, {}).get("name", id)) + "獸魂", beast.souls[id], "獸魂")
				item.kind = "soul"
				souls.items.append(item)
			groups = [food, souls]
		"fortune":
			var pending: Dictionary = view.get("fortune", {}).get("pending_encounter", {})
			var options: Array = pending.get("options", [])
			for index in options.size():
				var option: Dictionary = options[index]
				var group := {"id": "fortune:option:%d" % index, "title": String(option.get("text", "選項%d" % (index + 1))), "items": []}
				for id in option.get("costs", {}):
					var canonical := FortuneSystem.resource_key(view.get("resources", {}), id)
					var item := _resource_item(view, canonical, "fortune:%d:%s" % [index, canonical])
					item.demand = option.costs[id]
					item.provided.demand = true
					group.items.append(item)
				if not group.items.is_empty(): groups.append(group)
		"decisions":
			for decision in view.get("realm_decisions", []):
				var group := {"id": "decisions:%s" % decision.id, "title": String(decision.get("name", decision.id)), "items": []}
				for id in decision.get("costs", {}):
					if str(id) == "lifespan_seconds":
						continue
					var canonical := RealmDecisionSystem.resource_key(view.get("resources", {}), id)
					var item := _resource_item(view, canonical, "decisions:%s:%s" % [decision.id, canonical])
					item.demand = decision.costs[id]
					item.provided.demand = true
					group.items.append(item)
				if not group.items.is_empty(): groups.append(group)
	return {"supported": true, "context": route, "title": "相關資源", "groups": groups, "notes": []}

static func _counter(key: String, id: String, name: String, value: Variant, source: String) -> Dictionary:
	return {"key": key, "id": id, "name": name, "kind": "currency", "island": "", "source": source,
		"display": "available", "provided": {"available": true} if value != null else {},
		"available": value, "reserved": null, "capacity": null, "demand": null, "transit": null, "eta": null}

static func _resource_item(view: Dictionary, id: String, key: String) -> Dictionary:
	var resources: Dictionary = view.get("resources", {})
	var slot: Dictionary = resources.get(id, {})
	var item := _counter(key, id, Icon.get_resource_name(id), slot.get("value"), "祖島")
	item.island = "home"
	item.kind = "currency" if id in CURRENCY_IDS else "item"
	if slot.has("cap"):
		item.capacity = slot.cap
		item.provided.capacity = true
	var inventory_slot: Dictionary = view.get("economy", {}).get("inventory", {}).get("home", {}).get(id, {})
	if inventory_slot.has("available"):
		item.available = inventory_slot.available
		item.provided.available = true
	if inventory_slot.has("reserved"):
		item.reserved = inventory_slot.reserved
		item.provided.reserved = true
	return item

static func _value(resources: Dictionary, id: String) -> String:
	return _number(resources.get(id, {}).get("value", "0"))

static func _number(value: Variant) -> String:
	return NumberFormatter.format_amount(value)

static func _name(id: String) -> String:
	return Icon.get_resource_name(id)
