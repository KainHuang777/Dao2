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
				else: islands = [nav.manufacturing_panel.island_filter] if not nav.manufacturing_panel.island_filter.is_empty() else ["home", "wood", "ore", "herb"]
			elif not nav.transport_panel.selected_route.is_empty():
				var def: Array = IslandEconomy.ROUTES[nav.transport_panel.selected_route]
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
						var capacity: Variant = resources.get(id, {}).get("cap", "—") if island == "home" else view.get("manufacturing", {}).get("islands", {}).get(island, {}).get("capacity", "—")
						lines.append("%s\n可用 %s・預留 %s\n容量 %s" % [_name(id), _number(slot.get("available", 0)), _number(slot.get("reserved", 0)), _number(capacity)])
				for id in economy.get("routes", {}):
					var def: Array = IslandEconomy.ROUTES.get(id, [])
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
	return {"summary": summary, "details": "\n".join(lines), "has_costs": has_costs}

static func _value(resources: Dictionary, id: String) -> String:
	return _number(resources.get(id, {}).get("value", "0"))

static func _number(value: Variant) -> String:
	return NumberFormatter.format_amount(value)

static func _name(id: String) -> String:
	return Icon.get_resource_name(id)
