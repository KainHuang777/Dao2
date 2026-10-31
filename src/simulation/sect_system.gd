class_name SectSystem
extends RefCounted

const UNLOCK_ERA := 2
const MAX_TECHNIQUE_LEVEL := 10
const EXPEDITION_SLOTS := 3

const SECT_NAMES := [
	"太虛天闕",
	"天劍聖宗",
	"縹緲仙宮",
	"萬佛靈宗",
	"紫霄玄門",
]

const RARITY_CONFIGS := {
	"common": {
		"name": "普通",
		"color": "#cccccc",
		"weight": 40,
		"duration": 60,
		"contrib_min": 15,
		"contrib_max": 30,
		"reward_mult": 1.0,
	},
	"uncommon": {
		"name": "優秀",
		"color": "#4caf50",
		"weight": 30,
		"duration": 120,
		"contrib_min": 30,
		"contrib_max": 60,
		"reward_mult": 1.5,
	},
	"rare": {
		"name": "稀有",
		"color": "#2196f3",
		"weight": 18,
		"duration": 300,
		"contrib_min": 60,
		"contrib_max": 120,
		"reward_mult": 2.0,
	},
	"epic": {
		"name": "史詩",
		"color": "#9c27b0",
		"weight": 10,
		"duration": 600,
		"contrib_min": 120,
		"contrib_max": 250,
		"reward_mult": 3.0,
	},
	"legendary": {
		"name": "傳說",
		"color": "#ff9800",
		"weight": 2,
		"duration": 900,
		"contrib_min": 300,
		"contrib_max": 600,
		"reward_mult": 5.0,
	},
}

const TASK_TEMPLATES := {
	"common": [
		{"name": "巡視靈田", "desc": "驅除靈田中滋生的小害蟲，確保靈穀生長。"},
		{"name": "清剿低階野獸", "desc": "清理後山出沒的一階野獸，維護外門安寧。"},
		{"name": "採集晨露草", "desc": "拂曉時分採集沾染朝露的靈草，供丹房研製。"}
	],
	"uncommon": [
		{"name": "護送百草商隊", "desc": "護送宗門靈草車隊前往凡間市集交易。"},
		{"name": "探查黑風妖窟", "desc": "深入黑風山脈偵察妖氣波動源頭。"},
		{"name": "修補山門法陣", "desc": "更換山門聚靈護陣受損的下品靈石陣角。"}
	],
	"rare": [
		{"name": "斬殺二階赤炎蟒", "desc": "剿滅盤踞火脈作亂的赤炎蟒，取其靈骨。"},
		{"name": "探索上古殘破洞府", "desc": "搜尋千年前散仙遺留在荒嶺中的殘存藏寶。"},
		{"name": "採擷玄陰朱果", "desc": "攀登極寒冰峰，採摘百年難得一現的靈果。"}
	],
	"epic": [
		{"name": "鎮壓幽冥魔隙", "desc": "聯手內門師兄結陣鎮壓突然滲透的幽冥濁氣。"},
		{"name": "奪取天外玄金", "desc": "爭奪墜落在絕地的天外隕鐵，供長老煉製法寶。"},
		{"name": "助長老凝練純陽真火", "desc": "入地底岩漿核心助長老接引地心真火。"}
	],
	"legendary": [
		{"name": "探尋太虛古秘境", "desc": "進入百年一啟的太虛仙境，尋求上古仙緣傳承。"},
		{"name": "斬殺四階化形大妖", "desc": "與宗門掌教一同圍剿為禍一方的化形妖王。"},
		{"name": "護衛九界跨界星陣", "desc": "引渡靈界星光，穩定九界跨界通道之陣眼。"}
	],
}

const VERSION := 2
const P2_TECHNIQUES := ["p2_pill_qi_conservation", "sacred_beast_feed_conservation"]
const P2_MARKET := ["refined_iron_reserve", "ancient_herb_reserve"]
const P2_PILL_IDS := [
	"nascent_breath_pill",
	"void_meditation_pill",
	"ancient_herb_dew_pill",
	"void_gathering_pill",
	"spirit_vessel_pill",
	"stone_vault_pill",
	"calm_tribulation_pill",
	"silver_ward_pill"
]
const P2_TASKS := {
	"deep_stock_register": {
		"template_id": "deep_stock_register",
		"name": "核錄寒銀礦簿",
		"desc": "核對寒銀採集帳冊，將宗門分配的少量精鐵交回祖島。",
		"rarity": "common",
		"min_era": 4,
		"requires_open_islands": [
			"deep"
		],
		"requires_active_beast": "",
		"rewards": {
			"refined_iron": 2
		}
	},
	"ancient_dew_register": {
		"template_id": "ancient_dew_register",
		"name": "登記古藥凝露",
		"desc": "整理古藥採集紀錄，領回宗門備下的一份千年草。",
		"rarity": "common",
		"min_era": 5,
		"requires_open_islands": [
			"ancient"
		],
		"requires_active_beast": "",
		"rewards": {
			"spirit_grass_1000y": 1
		}
	},
	"silver_convoy_accounts": {
		"template_id": "silver_convoy_accounts",
		"name": "核對寒銀回運",
		"desc": "核對寒銀航線收支，領回可供修行的秘銀與下品靈石。",
		"rarity": "uncommon",
		"min_era": 4,
		"requires_open_islands": [
			"deep"
		],
		"requires_active_beast": "",
		"rewards": {
			"mithril": 3,
			"stone_low": 10
		}
	},
	"ancient_herb_sorting": {
		"template_id": "ancient_herb_sorting",
		"name": "分揀古藥餘材",
		"desc": "協助宗門藥房分揀古藥，領回千年草與百年草。",
		"rarity": "uncommon",
		"min_era": 5,
		"requires_open_islands": [
			"ancient"
		],
		"requires_active_beast": "",
		"rewards": {
			"spirit_grass_1000y": 2,
			"spirit_grass_100y": 5
		}
	},
	"cold_iron_assay": {
		"template_id": "cold_iron_assay",
		"name": "校驗寒鐵純度",
		"desc": "替宗門記錄寒鐵與秘銀品質，領回可用礦材。",
		"rarity": "rare",
		"min_era": 4,
		"requires_open_islands": [
			"deep"
		],
		"requires_active_beast": "",
		"rewards": {
			"cold_iron": 6,
			"mithril": 3
		}
	},
	"ancient_pill_herb_catalog": {
		"template_id": "ancient_pill_herb_catalog",
		"name": "編錄千年丹材",
		"desc": "依藥齡編錄古藥丹材，領回兩類草藥供自行煉製。",
		"rarity": "rare",
		"min_era": 5,
		"requires_open_islands": [
			"ancient"
		],
		"requires_active_beast": "",
		"rewards": {
			"spirit_grass_1000y": 4,
			"spirit_grass_100y": 10
		}
	},
	"void_supply_chart": {
		"template_id": "void_supply_chart",
		"name": "繪核太虛供給圖",
		"desc": "協助宗門整理太虛物料圖，領回虛空精華與上品靈石。",
		"rarity": "epic",
		"min_era": 6,
		"requires_open_islands": [
			"void"
		],
		"requires_active_beast": "",
		"rewards": {
			"void_essence": 8,
			"stone_high": 1
		}
	},
	"tribulation_material_check": {
		"template_id": "tribulation_material_check",
		"name": "查驗護劫備材",
		"desc": "核查宗門護劫丹材，領回礦草自行使用，不代服丹或保證渡劫。",
		"rarity": "epic",
		"min_era": 5,
		"requires_open_islands": [
			"deep"
		],
		"requires_active_beast": "",
		"rewards": {
			"cold_iron": 8,
			"mithril": 5,
			"spirit_grass_100y": 10
		}
	},
	"turtle_nursery_reserve": {
		"template_id": "turtle_nursery_reserve",
		"name": "整備玄龜育苑",
		"desc": "協助宗門整備玄龜育苑，領回一份未折扣餵料；不自動餵養。",
		"rarity": "legendary",
		"min_era": 4,
		"requires_open_islands": [
			"deep"
		],
		"requires_active_beast": "iron_turtle",
		"rewards": {
			"refined_iron": 30,
			"stone_low": 100
		}
	},
	"phoenix_nursery_reserve": {
		"template_id": "phoenix_nursery_reserve",
		"name": "整備火鳳育苑",
		"desc": "協助宗門整備火鳳育苑，領回千年草與上品靈石；不發放靈獸。",
		"rarity": "legendary",
		"min_era": 6,
		"requires_open_islands": [
			"ancient"
		],
		"requires_active_beast": "fire_phoenix",
		"rewards": {
			"spirit_grass_1000y": 10,
			"stone_high": 2
		}
	}
}
const P1_TECHNIQUES := [
	"alchemy_herb_conservation",
	"fox_feed_conservation"
]
const P1_TASKS := {
	"home_supply_register": {
		"template_id": "home_supply_register",
		"name": "核錄祖島木料",
		"desc": "核對祖島木料收支，將可用餘料交還外門營造處。",
		"rarity": "common",
		"min_era": 2,
		"requires_open_islands": [],
		"requires_active_beast": "",
		"rewards": {
			"wood": 80
		}
	},
	"wood_ore_convoy": {
		"template_id": "wood_ore_convoy",
		"name": "協調雙島回運",
		"desc": "核對青木與玄礦兩島回運清單，整理玄礦餘料。",
		"rarity": "uncommon",
		"min_era": 2,
		"requires_open_islands": [
			"wood",
			"ore"
		],
		"requires_active_beast": "",
		"rewards": {
			"stone_low": 8
		}
	},
	"herb_island_inventory": {
		"template_id": "herb_island_inventory",
		"name": "盤點丹霞藥圃",
		"desc": "替丹霞島清點採收入庫的靈草，領回分配予丹房的藥材。",
		"rarity": "rare",
		"min_era": 3,
		"requires_open_islands": [
			"herb"
		],
		"requires_active_beast": "",
		"rewards": {
			"spirit_grass_low": 80
		}
	},
	"specialist_pill_preparation": {
		"template_id": "specialist_pill_preparation",
		"name": "籌備四脈丹材",
		"desc": "整理養木、育草、聚財與納靈四類丹材，回收可用草石。",
		"rarity": "epic",
		"min_era": 3,
		"requires_open_islands": [],
		"requires_active_beast": "",
		"rewards": {
			"spirit_grass_low": 120,
			"stone_low": 20
		}
	},
	"jade_fox_nursery": {
		"template_id": "jade_fox_nursery",
		"name": "整備靈狐育苑",
		"desc": "協助靈狐育苑整理靈草與圍欄用料，領回餘下養成物資。",
		"rarity": "legendary",
		"min_era": 3,
		"requires_open_islands": [],
		"requires_active_beast": "jade_fox",
		"rewards": {
			"wood": 300,
			"stone_low": 30,
			"spirit_grass_low": 150
		}
	}
}
const HERB_DISCOUNT_PILLS := [
	"cultivation_pill",
	"wood_nurture_pill",
	"wealth_gathering_pill",
	"qi_absorption_pill"
]

const TECHNIQUES := {
	"divine_farm": {
		"name": "神農靈訣",
		"desc": "以青木靈光灌溉靈根，每級提升靈草與靈木產能 10%。",
		"base_contrib": 50,
		"base_wood": 100,
		"cost_scale": 1.5,
		"max_level": 10,
	},
	"breathing_method": {
		"name": "周天吐納法",
		"desc": "運轉宗門正宗行氣法門，每級提升全洞府修煉速度 2%。",
		"base_contrib": 80,
		"base_stone_low": 5,
		"cost_scale": 1.6,
		"max_level": 10,
	},
	"storage_talisman": {
		"name": "乾坤納戒",
		"desc": "宗門特製儲物須彌納芥，每級提升所有基礎資源容量 10%。",
		"base_contrib": 60,
		"base_wood": 200,
		"cost_scale": 1.5,
		"max_level": 10,
	},
	"essence_array": {
		"name": "引靈大陣",
		"desc": "引導天地靈脈匯聚，每級提升靈氣儲存上限 20%。",
		"base_contrib": 100,
		"base_stone_low": 30,
		"cost_scale": 1.5,
		"max_level": 10,
	},
	"alchemy_herb_conservation": {
	"name": "丹房調息訣",
	"min_era": 2,
	"max_level": 5,
	"base_contrib": 60,
	"cost_scale": 1.5,
	"base_stone_low": 5,
	"desc": "已入宗且築基：四丹下品靈草費每階減2%，上限10%。"
},
	"fox_feed_conservation": {
	"name": "靈契養成法",
	"min_era": 3,
	"max_level": 5,
	"base_contrib": 90,
	"cost_scale": 1.5,
	"base_wood": 100,
	"desc": "已入宗且金丹：僅靈狐餵料每階減2%，最後取整，上限10%。"
},

	"p2_pill_qi_conservation": {
		"name": "玄煉節息訣",
		"min_era": 4,
		"max_level": 5,
		"base_stone_low": 10,
		"base_contrib": 120,
		"cost_scale": 1.5,
		"desc": "已入宗且元嬰：八種後期丹藥的直接靈力費每階減2%，上限10%；不折其他丹材。"
	},
	"sacred_beast_feed_conservation": {
		"name": "龜鳳育靈法",
		"min_era": 4,
		"max_level": 5,
		"base_wood": 200,
		"base_contrib": 150,
		"cost_scale": 1.5,
		"desc": "已入宗且元嬰：玄龜／火鳳餵費每階減2%，上限10%，與獸魂合算後取整；火鳳須煉虛，第二至五階餵草費不再下降。"
	},
}

const MARKET_ITEMS := {
	"herb_bundle": {
		"name": "百草靈囊",
		"desc": "內含精選靈草 50 份，可用於日常煉丹或營造。",
		"cost": 30,
		"grant_resource": "spirit_grass_low",
		"grant_amount": 50.0,
		"limit": 20,
	},
	"stone_bundle": {
		"name": "靈石錦袋",
		"desc": "內含純淨下品靈石 10 枚，助益修行與宗門營建。",
		"cost": 50,
		"grant_resource": "stone_low",
		"grant_amount": 10.0,
		"limit": 20,
	},
	"foundation_pill": {
		"name": "築基神丹",
		"desc": "宗門長老親手煉製的築基靈丹，服之可延年益壽且增益產能。",
		"cost": 150,
		"grant_pill": "foundation_pill",
		"grant_count": 1,
		"limit": 5,
	},
	"spirit_crystal_shard": {
		"name": "極品靈晶",
		"desc": "靈界天靈洞天專屬高階靈能結晶，蘊含磅礴靈力。",
		"cost": 250,
		"grant_resource": "spirit_crystal",
		"grant_amount": 2.0,
		"limit": 5,
	},
	"greenwood_bundle": {
	"name": "青木補給匣",
	"min_era": 2,
	"cost": 60,
	"limit": 10,
	"grant_resource": "wood",
	"grant_amount": 100,
	"desc": "祖島靈木100；需足額空倉，終身限購10次。"
},
	"herb_nurture_supply": {
	"name": "育草丹補給",
	"min_era": 2,
	"cost": 45,
	"limit": 10,
	"grant_pill": "herb_nurture_pill",
	"grant_count": 1,
	"desc": "育草丹1顆；祖島產草+100%／300秒，需另行服用，終身限購10次。"
},
	"refined_iron_reserve": {
		"name": "玄龜精鐵匣",
		"min_era": 4,
		"requires_open_island": "deep",
		"cost": 90,
		"grant_resource": "refined_iron",
		"grant_amount": 5,
		"limit": 10,
		"desc": "需已開來源島及足額空倉，終身限購10次；入祖島庫存，不自動使用。"
	},
	"ancient_herb_reserve": {
		"name": "千年藥材匣",
		"min_era": 5,
		"requires_open_island": "ancient",
		"cost": 120,
		"grant_resource": "spirit_grass_1000y",
		"grant_amount": 2,
		"limit": 10,
		"desc": "需已開來源島及足額空倉，終身限購10次；入祖島庫存，不自動使用。"
	},
}

static func is_unlocked(state: GameState) -> bool:
	return state.era_id >= UNLOCK_ERA or state.reincarnation_count >= 1

static func active_level(state: GameState, id: String) -> int:
	if SectSpecialization.METHODS.has(id): return SectSpecialization.level(state, id)
	if state == null or id not in P1_TECHNIQUES + P2_TECHNIQUES: return 0
	if id in P2_TECHNIQUES and not p2_ready(state): return 0
	if not bool(state.sect.get("unlocked", false)) or state.era_id < int(TECHNIQUES[id].min_era): return 0
	return clampi(int(state.sect.get("techniques", {}).get(id, 0)), 0, 5)

static func p2_ready(state: GameState) -> bool:
	return state != null and state.sect_version >= 2 and IslandEconomy.expanded(state)

static func p2_life_error(state: GameState) -> String:
	var content := SupplyContent.runtime_content()
	var maximum := Lifespan.for_state(content.era_lifespan_entries(), state)
	return "LIFESPAN_EXHAUSTED" if Lifespan.is_exhausted(state.total_elapsed_seconds, maximum) else ""

static func eligible_templates(state: GameState, rarity: String) -> Array:
	var result: Array = TASK_TEMPLATES[rarity].duplicate(true)
	if state == null or not bool(state.sect.get("unlocked", false)): return result
	if GuardianDiscovery.active(state):
		for i in range(result.size()): result[i]["guardian_template_id"] = "legacy_%s_%02d" % [rarity, i]
	var registered := P1_TASKS.duplicate(true)
	if p2_ready(state): registered.merge(P2_TASKS)
	for id in registered:
		var t: Dictionary = registered[id]
		if t.rarity != rarity or state.era_id < int(t.min_era): continue
		var eligible := true
		for island in t.requires_open_islands:
			eligible = eligible and bool(state.economy.get("islands", {}).get(island, {}).get("opened", false))
		if not String(t.requires_active_beast).is_empty():
			eligible = eligible and state.beasts.get("active", {}).get("id", "") == t.requires_active_beast
		if eligible:
			var entry := t.duplicate(true)
			if GuardianDiscovery.active(state): entry["guardian_template_id"] = id
			result.append(entry)
	if GuardianDiscovery.active(state): result.sort_custom(func(a, b): return a.guardian_template_id < b.guardian_template_id)
	return result

static func market_destination_error(state: GameState, id: String, content: GameContent = null) -> String:
	if id in P2_MARKET:
		if not p2_ready(state): return "MARKET_SUPPLY_REQUIRED"
		if not bool(state.sect.get("unlocked", false)): return "SECT_LOCKED"
		var life_error := p2_life_error(state)
		if not life_error.is_empty(): return life_error
		var def: Dictionary = MARKET_ITEMS[id]
		if state.era_id < int(def.min_era): return "MARKET_ERA_LOCKED"
		if not bool(state.economy.get("islands", {}).get(def.requires_open_island, {}).get("opened", false)): return "MARKET_ISLAND_LOCKED"
		if content == null: return "MARKET_CONTENT_REQUIRED"
		var catalog: Dictionary = content.processing_catalog
		var resource: String = def.grant_resource
		if not catalog.get("resources", {}).has(resource) or not state.resources.has(resource): return "MARKET_RESOURCE_MISSING"
		var cap_value: Variant = catalog.resources[resource].get("cap")
		if not SectSaveContract.number(cap_value) and not (cap_value is String and cap_value.is_valid_float()): return "MARKET_CAPACITY_INVALID"
		if not is_finite(float(cap_value)) or float(cap_value) < 0: return "MARKET_CAPACITY_INVALID"
		var cap := IslandEconomy.home_cap(state, resource, catalog)
		if not is_finite(cap) or cap < 0: return "MARKET_CAPACITY_INVALID"
		var held: AmountCompat = state.resources[resource].value
		var incoming := IslandEconomy.reserved(state, "home", resource, catalog)
		var needed := held.add(AmountCompat.from_number(incoming)).add(AmountCompat.from_number(def.grant_amount))
		return "MARKET_DESTINATION_FULL" if needed.compare_to(AmountCompat.from_number(cap)) > 0 else ""
	if id not in ["greenwood_bundle", "herb_nurture_supply"]: return ""
	if state.era_id < 2: return "MARKET_ERA_LOCKED"
	if id == "herb_nurture_supply":
		return "PILL_INVENTORY_CAP" if int(state.pills.get("herb_nurture_pill", 0)) > 999998 else ""
	if content == null: return "MARKET_CONTENT_REQUIRED"
	var cap: AmountCompat = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills).get("wood", AmountCompat.zero())
	var capacity_state := state.duplicate_state()
	var bonus := float(compute_multipliers(state).storage_bonus) + float(ChronoSystem.compute_multipliers(capacity_state).storage_bonus) + float(BeastSystem.compute_multipliers(capacity_state).all_capacity_mult)
	if bonus > 0: cap = cap.multiply(AmountCompat.from_number(1 + bonus))
	if not state.economy.is_empty() and content.processing_catalog.resources.has("wood"):
		cap = AmountCompat.from_number(minf(cap.to_float(), float(content.processing_catalog.resources.wood.cap)))
		cap = cap.subtract(AmountCompat.from_number(IslandEconomy.reserved(state, "home", "wood", content.processing_catalog)))
	var held: AmountCompat = state.resources.get("wood", {}).get("value", AmountCompat.zero())
	return "MARKET_DESTINATION_FULL" if held.add(AmountCompat.from_number(100)).compare_to(cap) > 0 else ""

static func ensure_sect_state(state: GameState) -> Dictionary:
	if not (state.sect is Dictionary) or state.sect.is_empty():
		state.sect = {
			"unlocked": false,
			"sect_id": "taixu_sect",
			"sect_name": "太虛天闕",
			"sect_level": 1,
			"contribution": "0",
			"active_expedition": null,
			"available_tasks": [],
			"next_refresh_seconds": 0,
			"techniques": {},
			"market_purchases": {},
		}
	return state.sect

static func join_sect(state: GameState, sect_name: String = "") -> Dictionary:
	if not is_unlocked(state):
		return {"ok": false, "error": "SECT_LOCKED"}
	var id := SectIdentity.canonical_id(sect_name if not sect_name.is_empty() else SECT_NAMES[0])
	if id.is_empty(): return {"ok": false, "error": "UNKNOWN_SECT"}
	var lineage_error := SectLineage.validate_state(state)
	if not lineage_error.is_empty(): return {"ok": false, "error": lineage_error}
	var sect: Dictionary = ensure_sect_state(state)
	if bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "ALREADY_JOINED_SECT"}
	if int(sect.get("task_counter", 0)) > 2147483647 - EXPEDITION_SLOTS:
		return {"ok": false, "error": "TASK_COUNTER_EXHAUSTED"}
	
	sect["unlocked"] = true
	SectIdentity.write(sect, id)
	SectLineage.observe(state)
	
	# Generate initial tasks
	refresh_tasks(state, true)
	
	return {
		"ok": true,
		"events": [{
			"kind": "joined_sect",
			"sect_id": id,
			"sect_name": sect["sect_name"],
		}],
	}

static func resolve_legacy_identity(state: GameState, id: String) -> Dictionary:
	if not SectIdentity.NAMES.has(id): return {"ok": false, "error": "UNKNOWN_SECT"}
	if not SectIdentity.view(state.sect).identity_pending:
		return {"ok": false, "error": "SECT_IDENTITY_NOT_PENDING"}
	# No task refresh, RNG draw, fee, reward, or progress counter.
	SectIdentity.write(state.sect, id)
	SectLineage.observe(state)
	return {"ok": true, "events": [{"kind": "sect_identity_resolved", "sect_id": id}], "changed_ids": ["sect"]}

static func refresh_tasks(state: GameState, force: bool = false) -> Dictionary:
	var sect: Dictionary = state.sect
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	if SectIdentity.view(sect).identity_pending:
		return {"ok": false, "error": "SECT_IDENTITY_PENDING"}
	
	if GuardianDiscovery.active(state):
		var guardian_error := GuardianDiscovery.state_error(state)
		if not guardian_error.is_empty(): return {"ok": false, "error": guardian_error}
		if not p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	var lineage_error := SectLineage.validate_state(state)
	if not lineage_error.is_empty(): return {"ok": false, "error": lineage_error}
	var current_tasks: Array = sect.get("available_tasks", [])
	if not force and not current_tasks.is_empty() and int(sect.get("next_refresh_seconds", 0)) > 0:
		return {"ok": false, "error": "REFRESH_COOLDOWN"}
	
	if int(sect.get("task_counter", 0)) > 2147483647 - EXPEDITION_SLOTS:
		return {"ok": false, "error": "TASK_COUNTER_EXHAUSTED"}
	var new_tasks: Array = []
	for i in range(EXPEDITION_SLOTS):
		var task: Dictionary = _generate_random_task(state.era_id, i + 1, sect, state)
		new_tasks.append(task)
	
	sect["available_tasks"] = new_tasks
	sect["next_refresh_seconds"] = 300 # 5 minutes cooldown
	
	return {
		"ok": true,
		"tasks": new_tasks,
		"events": [{"kind": "tasks_refreshed", "count": new_tasks.size()}],
	}

static func _generate_random_task(era_id: int, slot_index: int, sect: Dictionary = {}, state: GameState = null) -> Dictionary:
	var rarity_key := _pick_rarity(sect)
	var r_cfg: Dictionary = RARITY_CONFIGS[rarity_key]
	var templates: Array = eligible_templates(state, rarity_key)
	var t_index := _draw(sect, templates.size())
	var tmpl: Dictionary = templates[t_index]
	
	var task_seq: int = int(sect.get("task_counter", 0)) + 1
	if not sect.is_empty():
		sect["task_counter"] = task_seq
	var task_id := "task_%d_%d_%d" % [era_id, slot_index, task_seq]
	var contrib_min := int(r_cfg.get("contrib_min", 10))
	var contrib_max := int(r_cfg.get("contrib_max", 20))
	var contrib := contrib_min + _draw(sect, contrib_max - contrib_min + 1)
	
	var rewards := {
		"contribution": contrib,
		"money": int(50 * float(r_cfg.reward_mult) * float(era_id)),
	}
	
	if rarity_key == "uncommon" or rarity_key == "rare":
		rewards["stone_low"] = maxi(1, int(2 * float(r_cfg.reward_mult)))
		rewards["spirit_grass_low"] = maxi(5, int(15 * float(r_cfg.reward_mult)))
	elif rarity_key == "epic":
		rewards["stone_low"] = maxi(5, int(5 * float(r_cfg.reward_mult)))
		rewards["black_copper"] = 2
	elif rarity_key == "legendary":
		rewards["stone_low"] = maxi(10, int(10 * float(r_cfg.reward_mult)))
		rewards["black_copper"] = 5
		rewards["special_buff"] = "epiphany"
	
	if tmpl.has("template_id"):
		for key in rewards.keys():
			if key not in ["contribution", "money"]: rewards.erase(key)
		rewards.merge(tmpl.rewards, true)
	var task := {
		"id": task_id,
		"name": tmpl["name"],
		"desc": tmpl["desc"],
		"rarity": rarity_key,
		"rarity_name": r_cfg["name"],
		"rarity_color": r_cfg["color"],
		"duration": int(r_cfg["duration"]),
		"elapsed": 0,
		"rewards": rewards,
	}

	if tmpl.has("template_id"):
		task["template_id"] = tmpl.template_id
		task["generation_era"] = era_id
	if state != null: SectLineage.stamp(state, task)
	if GuardianDiscovery.active(state):
		task.guardian_template_id = tmpl.guardian_template_id
		var event_value := _unit_draw(sect)
		var species_value := _unit_draw(sect)
		GuardianDiscovery.stamp(state, task, event_value, species_value)
	return task

static func _unit_draw(sect: Dictionary) -> float:
	var rng := SeededRandom.from_state(int(sect.rng.state))
	var value := rng.next()
	sect.rng.state = rng.state
	return value

static func _draw(sect: Dictionary, bound: int) -> int:
	if not sect.has("core_save"): return randi() % bound
	var rng := SeededRandom.from_state(int(sect.rng.state))
	var value := rng.int_range(0, bound - 1)
	sect.rng.state = rng.state
	return value

static func _pick_rarity(sect: Dictionary = {}) -> String:
	var total_weight := 0
	for key in GuardianDiscovery.RARITIES:
		total_weight += int(RARITY_CONFIGS[key].weight)
	
	var roll := _draw(sect, total_weight)
	var current := 0
	for key in GuardianDiscovery.RARITIES:
		current += int(RARITY_CONFIGS[key].weight)
		if roll < current:
			return key
	return "common"

static func start_expedition(state: GameState, task_id: String) -> Dictionary:
	if GuardianDiscovery.active(state) and not p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	var sect: Dictionary = state.sect
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	if sect.get("active_expedition") != null:
		return {"ok": false, "error": "EXPEDITION_ALREADY_ACTIVE"}
	
	var tasks: Array = sect.get("available_tasks", [])
	var target_index := -1
	var target_task: Dictionary = {}
	for i in range(tasks.size()):
		if String(tasks[i].get("id", "")) == task_id:
			target_index = i
			target_task = tasks[i]
			break
	
	if target_index < 0:
		return {"ok": false, "error": "TASK_NOT_FOUND"}
	
	var guardian_error := GuardianDiscovery.claim_error(state, target_task)
	if not guardian_error.is_empty(): return {"ok": false, "error": guardian_error}
	tasks.remove_at(target_index)
	target_task["elapsed"] = 0
	sect["active_expedition"] = target_task
	
	return {
		"ok": true,
		"task": target_task,
		"events": [{
			"kind": "expedition_started",
			"task_id": task_id,
			"name": target_task.get("name", ""),
			"duration": target_task.get("duration", 0),
		}],
	}

static func claim_expedition_reward(state: GameState) -> Dictionary:
	var sect: Dictionary = state.sect
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	var active = sect.get("active_expedition")
	if active == null or not (active is Dictionary):
		return {"ok": false, "error": "NO_ACTIVE_EXPEDITION"}
	
	var payload_error := SectSaveContract.validate_task(active, state.sect_version)
	if not payload_error.is_empty(): return {"ok": false, "error": payload_error}
	var duration: int = int(active.get("duration", 0))
	var elapsed: int = int(active.get("elapsed", 0))
	if elapsed < duration:
		return {"ok": false, "error": "EXPEDITION_NOT_FINISHED", "remaining": duration - elapsed}
	
	var lineage_error := SectLineage.claim_error(state, active)
	if not lineage_error.is_empty(): return {"ok": false, "error": lineage_error}
	var guardian_error := GuardianDiscovery.claim_error(state, active)
	if not guardian_error.is_empty(): return {"ok": false, "error": guardian_error}
	var rewards: Dictionary = active.get("rewards", {})
	# Previous snapshots may still carry the old task reward names.
	var reward_aliases := {"herb": "spirit_grass_low", "bronze": "black_copper"}
	for reward_id in rewards:
		if reward_id in ["contribution", "special_buff"]:
			continue
		if not state.resources.has(String(reward_aliases.get(reward_id, reward_id))):
			return {"ok": false, "error": "REWARD_RESOURCE_MISSING"}
	
	# Grant contribution
	var contrib_gain := int(rewards.get("contribution", 0))
	var cur_contrib := AmountCompat.try_parse(String(sect.get("contribution", "0")))
	var cur_val: AmountCompat = cur_contrib["value"] if bool(cur_contrib.get("ok", false)) else AmountCompat.zero()
	var new_val := cur_val.add(AmountCompat.from_number(float(contrib_gain)))
	sect["contribution"] = new_val.serialize()
	
	# Grant resources
	var granted: Dictionary = {"contribution": contrib_gain}
	for res_id in rewards:
		if res_id == "contribution" or res_id == "special_buff":
			continue
		var amount := float(rewards[res_id])
		var target_id: String = reward_aliases.get(res_id, res_id)
		if state.resources.has(target_id):
			var entry: Dictionary = state.resources[target_id]
			entry.value = ResourceLedger.change(state, "home", target_id, entry.value, (entry.value as AmountCompat).add(AmountCompat.from_number(amount)), "sect", AmountCompat.from_number(amount))
			entry.ever_obtained = true
			entry.unlocked = true
			granted[target_id] = amount
	
	# Check special buff
	if rewards.has("special_buff") and String(rewards["special_buff"]) == "epiphany":
		BuffSystem.apply_buff(state, "epiphany", 60.0)
		granted["buff"] = "epiphany"
	
	if active.get("template_id", "") in ["home_supply_register", "wood_ore_convoy"]: StoryProgress.mark(state, "new_supply_claimed")
	StoryProgressP2.mark_id(state, "task_mask", StoryProgressP2.TASKS, str(active.get("template_id", "")))
	SectLineage.claimed(state, active)
	var guardian_event := GuardianDiscovery.claimed(state, active)
	sect["active_expedition"] = null
	
	return {
		"ok": true,
		"granted": granted,
		"events": [{
			"kind": "expedition_claimed",
			"task_name": active.get("name", ""),
			"granted": granted,
		}] + ([guardian_event] if not guardian_event.is_empty() else []),
	}

static func technique_requirements(state: GameState, tech_id: String) -> Dictionary:
	if SectSpecialization.METHODS.has(tech_id): return SectSpecialization.requirements(state, tech_id)
	var sect: Dictionary = state.sect
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	if not TECHNIQUES.has(tech_id):
		return {"ok": false, "error": "UNKNOWN_TECHNIQUE"}
	
	if tech_id in P2_TECHNIQUES and not p2_ready(state):
		return {"ok": false, "error": "TECHNIQUE_SUPPLY_REQUIRED"}
	if tech_id in P2_TECHNIQUES:
		var life_error := p2_life_error(state)
		if not life_error.is_empty(): return {"ok": false, "error": life_error}
	var def: Dictionary = TECHNIQUES[tech_id]
	if state.era_id < int(def.get("min_era", 1)):
		return {"ok": false, "error": "TECHNIQUE_ERA_LOCKED"}
	var techs: Dictionary = sect.get("techniques", {})
	var cur_lvl := int(techs.get(tech_id, 0))
	if cur_lvl >= int(def.get("max_level", MAX_TECHNIQUE_LEVEL)):
		return {"ok": false, "error": "TECHNIQUE_MAX_LEVEL"}
	
	var next_lvl := cur_lvl + 1
	var scale := pow(float(def.get("cost_scale", 1.5)), float(cur_lvl))
	var req_contrib := int(ceil(float(def.get("base_contrib", 50)) * scale))
	
	# Check contribution
	var cur_contrib_parse := AmountCompat.try_parse(String(sect.get("contribution", "0")))
	var cur_contrib: AmountCompat = cur_contrib_parse["value"] if bool(cur_contrib_parse.get("ok", false)) else AmountCompat.zero()
	var req_contrib_amount := AmountCompat.from_number(float(req_contrib))
	if cur_contrib.compare_to(req_contrib_amount) < 0:
		return {"ok": false, "error": "INSUFFICIENT_CONTRIBUTION", "required": req_contrib}
	
	# Check resource costs
	if def.has("base_wood"):
		var req_wood := int(ceil(float(def.get("base_wood", 100)) * scale))
		var cur_wood: AmountCompat = state.resources.get("wood", {}).get("value", AmountCompat.zero())
		if cur_wood.compare_to(AmountCompat.from_number(float(req_wood))) < 0:
			return {"ok": false, "error": "INSUFFICIENT_WOOD", "required": req_wood}
	
	if def.has("base_stone_low"):
		var req_stone := int(ceil(float(def.get("base_stone_low", 5)) * scale))
		var cur_stone: AmountCompat = state.resources.get("stone_low", {}).get("value", AmountCompat.zero())
		if cur_stone.compare_to(AmountCompat.from_number(float(req_stone))) < 0:
			return {"ok": false, "error": "INSUFFICIENT_STONE", "required": req_stone}
	
	return {"ok":true,"next_level":next_lvl,"scale":scale,"contribution":req_contrib}

static func learn_technique(state: GameState, tech_id: String) -> Dictionary:
	if SectSpecialization.METHODS.has(tech_id): return SectSpecialization.learn(state, tech_id)
	var requirements := technique_requirements(state, tech_id)
	if not requirements.ok: return requirements
	var sect: Dictionary = state.sect
	var def: Dictionary = TECHNIQUES[tech_id]
	var techs: Dictionary = sect.get("techniques", {})
	var next_lvl: int = requirements.next_level
	var scale: float = requirements.scale
	var cur_contrib: AmountCompat = AmountCompat.try_parse(String(sect.contribution)).value
	var req_contrib_amount := AmountCompat.from_number(requirements.contribution)
	# Deduct costs
	sect["contribution"] = cur_contrib.subtract(req_contrib_amount).serialize()
	if def.has("base_wood"):
		var req_wood := int(ceil(float(def.get("base_wood", 100)) * scale))
		var w_entry: Dictionary = state.resources["wood"]
		w_entry.value = ResourceLedger.change(state, "home", "wood", w_entry.value, (w_entry.value as AmountCompat).subtract(AmountCompat.from_number(float(req_wood))), "sect")
	if def.has("base_stone_low"):
		var req_stone := int(ceil(float(def.get("base_stone_low", 5)) * scale))
		var s_entry: Dictionary = state.resources["stone_low"]
		s_entry.value = ResourceLedger.change(state, "home", "stone_low", s_entry.value, (s_entry.value as AmountCompat).subtract(AmountCompat.from_number(float(req_stone))), "sect")
	
	techs[tech_id] = next_lvl
	sect["techniques"] = techs
	
	return {
		"ok": true,
		"technique_id": tech_id,
		"new_level": next_lvl,
		"events": [{
			"kind": "technique_learned",
			"technique_id": tech_id,
			"level": next_lvl,
		}],
	}

static func buy_market_item(state: GameState, item_id: String, content: GameContent = null) -> Dictionary:
	var sect: Dictionary = state.sect
	if not bool(sect.get("unlocked", false)):
		return {"ok": false, "error": "SECT_LOCKED"}
	if not MARKET_ITEMS.has(item_id):
		return {"ok": false, "error": "UNKNOWN_MARKET_ITEM"}
	
	var def: Dictionary = MARKET_ITEMS[item_id]
	var destination_error := market_destination_error(state, item_id, content)
	if not destination_error.is_empty(): return {"ok": false, "error": destination_error}
	var purchases: Dictionary = sect.get("market_purchases", {})
	var count := int(purchases.get(item_id, 0))
	var limit := int(def.get("limit", 10))
	if count >= limit:
		return {"ok": false, "error": "PURCHASE_LIMIT_REACHED"}
	
	var cost := int(def.get("cost", 10))
	var cur_contrib_parse := AmountCompat.try_parse(String(sect.get("contribution", "0")))
	var cur_contrib: AmountCompat = cur_contrib_parse["value"] if bool(cur_contrib_parse.get("ok", false)) else AmountCompat.zero()
	var cost_amount := AmountCompat.from_number(float(cost))
	if cur_contrib.compare_to(cost_amount) < 0:
		return {"ok": false, "error": "INSUFFICIENT_CONTRIBUTION", "required": cost}
	if def.has("grant_resource") and String(def.grant_resource) != "spirit_crystal" and not state.resources.has(String(def.grant_resource)):
		return {"ok": false, "error": "REWARD_RESOURCE_MISSING"}
	
	# Deduct
	sect["contribution"] = cur_contrib.subtract(cost_amount).serialize()
	purchases[item_id] = count + 1
	sect["market_purchases"] = purchases
	
	# Grant item
	if def.has("grant_resource"):
		var res_id: String = def["grant_resource"]
		var amount: float = float(def["grant_amount"])
		if res_id == "spirit_crystal":
			var realm_data := RealmSystem.ensure_spirit_data(state)
			ResourceLedger.change(state, "realm_spirit", "spirit_crystal", AmountCompat.from_number(float(realm_data.get("spirit_crystal", 0))), AmountCompat.from_number(float(realm_data.get("spirit_crystal", 0)) + amount), "sect")
			realm_data.spirit_crystal = float(realm_data.get("spirit_crystal", 0.0)) + amount
		elif state.resources.has(res_id):
			var entry: Dictionary = state.resources[res_id]
			entry.value = ResourceLedger.change(state, "home", res_id, entry.value, (entry.value as AmountCompat).add(AmountCompat.from_number(amount)), "sect", AmountCompat.from_number(amount))
			entry.ever_obtained = true
			entry.unlocked = true
	elif def.has("grant_pill"):
		var pill_id: String = def["grant_pill"]
		var cnt: int = int(def["grant_count"])
		state.pills[pill_id] = int(state.pills.get(pill_id, 0)) + cnt
	
	StoryProgressP2.mark_id(state, "market_mask", StoryProgressP2.MARKET, item_id)
	return {
		"ok": true,
		"item_id": item_id,
		"purchase_count": purchases[item_id],
		"events": [{
			"kind": "market_item_bought",
			"item_id": item_id,
		}],
	}

static func compute_multipliers(state: GameState) -> Dictionary:
	var mults := {
		"production_herb_wood": 0.0,
		"cultivation_speed_bonus": 0.0,
		"storage_bonus": 0.0,
		"lingqi_cap_bonus": 0.0,
	}
	if not (state.sect is Dictionary) or state.sect.is_empty():
		return mults
	var techs: Dictionary = state.sect.get("techniques", {})
	if techs.has("divine_farm"):
		mults.production_herb_wood += float(techs["divine_farm"]) * 0.10
	if techs.has("breathing_method"):
		mults.cultivation_speed_bonus += float(techs["breathing_method"]) * 0.02
	if techs.has("storage_talisman"):
		mults.storage_bonus += float(techs["storage_talisman"]) * 0.10
	if techs.has("essence_array"):
		mults.lingqi_cap_bonus += float(techs["essence_array"]) * 0.20
	mults.cultivation_speed_bonus += 0.02 * SectSpecialization.level(state, "taixu_inner_cycle") + SectLineage.bonus(state, "taixu")
	return mults

static func tick(state: GameState, elapsed_seconds: float, start_age: float = -1.0) -> void:
	if not (state.sect is Dictionary) or state.sect.is_empty():
		return
	var sect: Dictionary = state.sect
	if not bool(sect.get("unlocked", false)):
		return
	
	# Advance active expedition
	var active = sect.get("active_expedition")
	if active != null and active is Dictionary:
		var previous_elapsed := int(active.get("elapsed", 0))
		var duration := int(active.get("duration", 0))
		if previous_elapsed < duration and previous_elapsed + int(ceil(elapsed_seconds)) >= duration:
			var start := state.total_elapsed_seconds - elapsed_seconds if start_age < 0.0 else start_age
			LifeLedger.note(state, "expedition_completed", "sect", "expedition:" + str(start + float(duration - previous_elapsed)), start + float(duration - previous_elapsed))
		active["elapsed"] = mini(int(active.get("duration", 0)), int(active.get("elapsed", 0)) + int(ceil(elapsed_seconds)))
	
	# Advance refresh cooldown
	var refresh_cd := int(sect.get("next_refresh_seconds", 0))
	if refresh_cd > 0:
		sect["next_refresh_seconds"] = maxi(0, refresh_cd - int(ceil(elapsed_seconds)))

static func on_reincarnate(state: GameState) -> void:
	if not (state.sect is Dictionary) or state.sect.is_empty():
		return
	var sect: Dictionary = state.sect
	# Reset ongoing physical expedition and tasks
	sect["active_expedition"] = null
	sect["available_tasks"] = []
	sect["next_refresh_seconds"] = 0
	# Sect membership requires re-joining in new mortal life
	sect["unlocked"] = false
	if sect.has("identity_version"): sect["sect_id"] = ""
	SectLineage.next_life(state)
