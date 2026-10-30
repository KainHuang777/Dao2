class_name Onboarding
extends RefCounted

const SCHEMA_VERSION := 1
const HUT_LINGLI_CAPACITY_PER_LEVEL := 150
const MILESTONES := [
	{"building": "hut", "level": 2},
	{"building": "wooden_house", "level": 2},
	{"building": "forest_farm", "level": 3},
	{"building": "stone_mine", "level": 3},
	{"building": "herb_farm", "level": 3},
]

static func is_active(onboarding_version: int, era_id: int) -> bool:
	return era_id == 1 and onboarding_version >= SCHEMA_VERSION

static func unlock_state(era_id: int, onboarding_version: int, buildings: Dictionary) -> Dictionary:
	if not is_active(onboarding_version, era_id):
		return {"active": false, "resources": [], "buildings": [], "next_objective": null}
	var hut := _level(buildings, "hut")
	var wooden_house := _level(buildings, "wooden_house")
	var forest_farm := _level(buildings, "forest_farm")
	var stone_mine := _level(buildings, "stone_mine")
	var herb_farm := _level(buildings, "herb_farm")
	var resources: Array = ["lingli"]
	var visible: Array = ["hut"]
	if hut >= 1:
		resources.append("money")
		resources.append("wood")
	if hut >= 2:
		visible.append("wooden_house")
		visible.append("storage_lingli")
		visible.append("storage_money")
	if wooden_house >= 2:
		visible.append("forest_farm")
	if forest_farm >= 3:
		visible.append("stone_mine")
	if stone_mine >= 1:
		resources.append("stone_low")
		resources.append("black_copper")
		visible.append("storage_stone")
	if stone_mine >= 3:
		visible.append("herb_farm")
	if herb_farm >= 1:
		resources.append("spirit_grass_low")
		visible.append("storage_wood")
		visible.append("storage_herb")
	if herb_farm >= 3:
		resources.append("foundation_pill")
	var next_objective: Variant = null
	for milestone in MILESTONES:
		if _level(buildings, milestone.building) < milestone.level:
			next_objective = {"kind": "building", "id": milestone.building}
			break
	return {"active": true, "resources": resources, "buildings": visible, "next_objective": next_objective}

static func hut_lingli_capacity(era_id: int, onboarding_version: int, buildings: Dictionary) -> int:
	if not is_active(onboarding_version, era_id):
		return 0
	return _level(buildings, "hut") * HUT_LINGLI_CAPACITY_PER_LEVEL

static func _level(buildings: Dictionary, building_id: String) -> int:
	return int(buildings.get(building_id, 0))

# Read-only current-life goals. Optional alchemy never becomes a historical
# completion gate, so reloads and older saves need no new persisted fields.
static func early_guidance(state: GameState, era: Variant, resources: Dictionary, can_level_up: bool, can_breakthrough: bool, next_required: float) -> Dictionary:
	if state.era_id == 2 and (IslandEconomy.hub(state) or state.economy.get("version") == IslandProgression.VERSION):
		var supply := supply_guidance(state)
		if supply.step in ["complete", "legacy"]:
			return golden_guidance(state, era, resources, can_level_up, can_breakthrough, next_required)
		return supply
	if state.era_id == 3 and era is Dictionary and not era.is_empty():
		return golden_guidance(state, era, resources, can_level_up, can_breakthrough, next_required)
	if state.era_id == 2 and state.economy.get("version") != IslandProgression.VERSION:
		return {"title": "下一步：開拓玄礦島", "text": "已入築基。前往經營→空島，先支付祖島靈木20＋下品靈石10開拓玄礦島，將原料運回祖島製造銅精，再介紹青木供給。首次付款會同時啟用產業，祖島庫存與建築保留、不複製；輪迴清除當世島嶼、加工與貨物。", "route": "outposts", "optional_alchemy": false}
	if state.era_id != 1 or not (era is Dictionary) or era.is_empty():
		return {}
	var chain := unlock_state(state.era_id, state.onboarding_version, state.buildings)
	if chain.next_objective != null:
		return {}
	var required: float = float(era.get("upgrade_requirements", {}).get("capacity", {}).get("lingli", 0))
	var capacity := AmountCompat.try_parse(String(resources.get("lingli", {}).get("cap", "0")))
	var cap_value: float = capacity.value.to_float() if capacity.ok else 0.0
	var title := "下一步：修至練氣十層，準備築基"
	var route := "cultivation"
	var text := "主目標：練氣 %d/%d 層；靈力容量 %.0f/%.0f。容量是可儲存上限，不是目前庫存。\n" % [state.level, int(era.max_level), cap_value, required]
	if cap_value < required:
		route = "storage_lingli"
		text += "容量尚不足，前往經營→洞府建築提升聚靈壇；若前置未滿足，先將靈植場升至3階。\n"
	if state.level < int(era.max_level):
		if can_level_up:
			text += "本次修煉與扣料已足，可按「晉階」。建設與修煉可並行。\n"
		else:
			text += "本次需修煉 %.0f 秒；目前進度見修煉條。晉階仍需支付靈力，請查看晉階按鈕的缺料提示。\n" % next_required
	else:
		title = "下一步：突破至築基" if can_breakthrough else "下一步：補足築基容量"
		text += "條件已足，可按「突破」。升境不要求靈力庫存滿倉。\n" if can_breakthrough else "練氣層級已足，補足容量後即可突破。\n"
	text += "可選支線：修行→煉丹，煉製聚靈丹再服用可增加60秒修煉進度；草不足可回靈植場採集，若已能晉階請先晉階。可直接繼續主線，無須煉丹。築基丹只提升當世產率，不是築基必需品。"
	return {"title": title, "text": text, "route": route, "optional_alchemy": AlchemySystem.is_unlocked(state)}

# Versioned current-life history shares economy snapshot/recovery/reset authority.
# Older economies omit this field; historical operations are never invented.
const SUPPLY_FLAGS := ["timber_done", "bronze_done", "timber_home", "bronze_home"]

static func initial_supply() -> Dictionary:
	return {"version": 1, "ore_delivered": 0.0, "timber_done": false, "bronze_done": false, "timber_home": 0.0, "bronze_home": 0.0}

static func validate_supply(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 6 or value.get("version") != 1:
		return false
	var ore: Variant = value.get("ore_delivered")
	if not (ore is float or ore is int) or not is_finite(float(ore)) or float(ore) < 0 or float(ore) > 5:
		return false
	for key in SUPPLY_FLAGS:
		if key.ends_with("_done"):
			if not value.get(key) is bool:
				return false
		else:
			var amount: Variant = value.get(key)
			if not (amount is float or amount is int) or not is_finite(float(amount)) or float(amount) < 0 or float(amount) > 1:
				return false
	return true

static func supply_arrived(state: GameState, route: String, cargo: float) -> void:
	if not state.economy.has("early_supply"):
		return
	var progress: Dictionary = state.economy.early_supply
	if route == "ore_wood":
		progress.ore_delivered = minf(5.0, float(progress.ore_delivered) + cargo)
	elif route == "timber_home":
		progress.timber_home = minf(1.0, float(progress.timber_home) + cargo)
	elif route == "bronze_home":
		progress.bronze_home = minf(1.0, float(progress.bronze_home) + cargo)

static func supply_completed(state: GameState, island: String, recipe: String) -> void:
	if not state.economy.has("early_supply"):
		return
	if island == "wood" and recipe == "spirit_timber":
		state.economy.early_supply.timber_done = true
	elif island == "ore" and recipe == "bronze_essence":
		state.economy.early_supply.bronze_done = true

static func supply_guidance(state: GameState) -> Dictionary:
	if IslandEconomy.hub(state): return hub_guidance(state)
	var islands: Dictionary = state.economy.get("islands", {})
	var missing: Array[String] = []
	for id in ["wood", "ore"]:
		if not bool(islands.get(id, {}).get("opened", false)):
			missing.append(IslandProgression.NAMES[id])
	if not missing.is_empty():
		return _supply_goal("F1", "開拓雙島", "尚待開拓：%s。每島從祖島支付靈木20＋下品靈石10；已開拓島不用重做。採集、加工與倉儲一階即可完成首批供給。" % "、".join(missing), "outposts")
	if not state.economy.has("early_supply"):
		return _supply_goal("legacy", "雙島供給說明（可選）", "此舊檔沒有首批供給歷史，不要求補做。可到經營→運輸／製造查看玄礦送料、兩島加工與回運；主線可繼續準備金丹，技能與宗門可稍後處理。", "transport")
	var p: Dictionary = state.economy.early_supply
	if float(p.ore_delivered) < 5:
		var goal := _supply_goal("F2", "玄礦送料到青木", "下品靈石已實際送達 %.2f/5。設定玄礦→青木航線；設定成功與出發都不算到貨。一階航線即可，先用保留量0、目標量至少5。來源採集缺貨、保留量擋貨、目標量已滿與滿倉，請查看航線狀態；在途仍需等待到貨。" % float(p.ore_delivered), "transport")
		goal.route_id = "ore_wood"
		return goal
	if not p.timber_done or not p.bronze_done:
		var pending: Array[String] = []
		if not p.timber_done:
			pending.append("青木靈材：地方靈木10＋下品靈石5")
		if not p.bronze_done:
			pending.append("玄礦銅精：地方玄銅10＋下品靈石5")
		return _supply_goal("F3", "雙島各完成一批加工", "尚待真正完工：%s。各做一批，基礎10秒；開始工作不算完成。缺料看地方庫存，不是祖島庫存；若滿倉，先回運產物騰出空間。首批不用升加工坊。" % "；".join(pending), "manufacturing")
	if float(p.timber_home) < 1 or float(p.bronze_home) < 1:
		var pending: Array[String] = []
		if float(p.timber_home) < 1:
			pending.append("靈材")
		if float(p.bronze_home) < 1:
			pending.append("銅精")
		var goal := _supply_goal("F4", "首批產物回祖島", "尚待實際回運：%s各至少1。開啟青木靈材／玄礦銅精→祖島航線，保留量0、目標量至少1；在途貨物等到貨才完成。祖島滿倉先使用材料騰出空間。到貨紀錄在材料用掉後仍保留；保留後續陣芯材料，首批不必升運力。" % "、".join(pending), "transport")
		goal.route_id = "timber_home" if float(p.timber_home) < 1 else "bronze_home"
		return goal
	return _supply_goal("complete", "雙島供給已接通", "靈材與銅精首批已真正回到祖島，可維持加工與回運。接著可選研習技能或宗門任務；也可繼續修至築基十層、提升靈力容量至2000，準備金丹。支線不阻擋升境。", "cultivation")

# Hub goals are derived from authoritative inventory/history, never from UI visits.
static func hub_guidance(state: GameState) -> Dictionary:
	if not state.economy.has("early_supply"):
		return _supply_goal("legacy", "祖島集中加工", "既有進度保留，無須補做教學。外島採集原料送祖島，各工作線在祖島加工；可直接繼續修行。", "manufacturing")
	var p: Dictionary = state.economy.early_supply
	var islands: Dictionary = state.economy.islands
	if not bool(islands.get("ore", {}).get("opened", false)):
		var goal := _supply_goal("H1", "開拓玄礦島", "祖島支付靈木20與下品靈石10。玄礦採集玄銅與下品靈石，運回祖島供精煉使用。", "outposts")
		goal.island_id = "ore"
		return goal
	if not bool(p.bronze_done) and IslandEconomy.value(state, "home", "bronze_essence") < 1:
		for pair in [["black_copper", 10, "copper_home", "玄銅"], ["stone_low", 5, "raw_stone_home", "下品靈石"]]:
			if IslandEconomy.value(state, "home", pair[0]) < float(pair[1]):
				var goal := _supply_goal("H2", "原料送達祖島", "銅精在祖島加工，尚缺%s。啟用玄礦→祖島原料補給；已在途時等待抵達，啟航不代表材料已可用。" % pair[3], "transport")
				goal.route_id = pair[2]
				goal.island_id = "ore"
				return goal
		var goal := _supply_goal("H3", "祖島製造一批銅精", "祖島玄銅10＋下品靈石5→銅精1。先完成單批，再選持續製造；完工產物直接留在祖島。", "manufacturing")
		goal.island_id = "ore"
		goal.recipe_id = "bronze_essence"
		return goal
	if not bool(islands.get("wood", {}).get("opened", false)):
		var goal := _supply_goal("H4", "開拓青木供應靈木", "銅精小循環已完成，可選持續製造並維持原料補給。接著開拓青木島，將靈木運回祖島供木作使用。", "outposts")
		goal.island_id = "wood"
		return goal
	if not bool(p.timber_done) and IslandEconomy.value(state, "home", "spirit_timber") < 1:
		if IslandEconomy.value(state, "home", "wood") < 10:
			var goal := _supply_goal("H5", "青木原料補給", "靈材在祖島加工。啟用青木→祖島靈木補給；保留原配方，到貨後即可製造。", "transport")
			goal.route_id = "wood_home"
			return goal
		var goal := _supply_goal("H6", "祖島製造靈材", "祖島靈木10＋下品靈石5→靈材1。缺石沿用玄礦補給；木作與精煉可平行運作，成品直接用於祖島建設與修行。", "manufacturing")
		goal.island_id = "wood"
		goal.recipe_id = "spirit_timber"
		return goal
	return _supply_goal("complete", "祖島供給已接通", "銅精與靈材已完成，可持續加工並按需補給；技能與宗門可稍後，主線繼續準備金丹。", "cultivation")

static func _supply_goal(step: String, title: String, text: String, route: String) -> Dictionary:
	return {"step": step, "title": "下一步：" + title, "text": text, "route": route, "optional_alchemy": false}

# F5/F6 remain optional alongside F7. Current authoritative state suffices:
# no persisted dismissal, invented arrival history or additional unlock gate.
static func golden_guidance(state: GameState, era: Variant, resources: Dictionary, can_level_up: bool, can_breakthrough: bool, next_required: float) -> Dictionary:
	if not era is Dictionary or era.is_empty():
		return {}
	if state.era_id == 2:
		var capacity := _resource_number(resources, "lingli", "cap")
		var required := float(era.get("upgrade_requirements", {}).get("capacity", {}).get("lingli", 2000))
		var route := "cultivation"
		var text := "主目標：築基 %d/%d 層；靈力容量 %.0f/%.0f。容量是儲存上限，升境不用滿倉，也不需要金丹道具。\n" % [state.level, int(era.max_level), capacity, required]
		if capacity < required:
			route = "storage_lingli" if _level(state.buildings, "storage_lingli") < 2 else "foundation_reservoir"
			text += "先將聚靈壇升至2階，解鎖築基靈池；靈池2階提供2000容量增量。缺料查看建築詳情；庫容不足先擴對應庫房。\n"
		if state.level < int(era.max_level):
			text += "修煉與建設可並行；本次需修煉 %.0f 秒，晉階仍支付靈力。%s\n" % [next_required, "本次已足，可晉階。" if can_level_up else "等待修煉條與扣料條件。"]
		else:
			text += "條件已足，可突破至金丹。\n" if can_breakthrough else "層級已足，補足容量即可突破。\n"
		var goal := _supply_goal("F7", "準備金丹" if not can_breakthrough else "突破至金丹", text + optional_branches(state, resources), route)
		goal.optional_skills = int(state.skills.get("basic_meditation", 0)) < 1
		goal.optional_sect = state.sect.get("active_expedition") == null
		goal.skills_route = "skills" if _level(state.buildings, "library") > 0 else ("storage_wood" if _resource_number(resources, "wood", "cap") < 200 else ("storage_money" if _resource_number(resources, "money", "cap") < 500 else "library"))
		return goal
	if state.era_id != 3:
		return {}
	if state.level >= 2:
		var beast := BeastSystem.get_active_beast(state)
		if beast.is_empty():
			return _supply_goal("G4", "可選結契靈狐", "金丹首次晉階已完成。可到修行→靈獸免費結契靈狐，再從祖島支付低階靈草50餵食一次；也可稍後，繼續修行與供給。第一次餵食仍是靈卵，不要求成熟或獸魂天賦。", "beasts")
		if int(beast.get("exp", 0)) == 0 and beast.get("stage", "egg") == "egg":
			return _supply_goal("G4", "可選首次餵食", "已結契，尚未首次餵食。到修行→靈獸查看實際餵食成本；靈狐無天賦時需祖島低階靈草50，缺料回靈植場或丹霞原料回運。餵食可稍後，不阻擋修行。", "beasts")
		var stage := String(BeastSystem.STAGE_CONFIGS.get(beast.get("stage", "egg"), {}).get("name", "靈卵"))
		return _supply_goal("complete", "首段供給與修行完成", "金丹首次晉階與首次餵食已完成；目前為%s。無天賦首次餵食得50經驗，仍是靈卵；基礎冷卻300秒，冷卻後可再餵養。繼續修行與維持供給，無須等孵化。" % stage, "cultivation")
	if not IslandEconomy.hub(state) and state.economy.get("version") != IslandProgression.VERSION:
		return _supply_goal("G1", "啟用金丹產業", "此已有金丹進度的檔案未啟用目前空島產業。前往經營→空島保留原檔並啟用；不要求補做練氣、技能、宗門或雙島首批教學。", "outposts")
	if IslandEconomy.hub(state) and IslandEconomy.value(state, "home", "liquid") < 1:
		var goal := _supply_goal("G1", "祖島煉製丹液", "丹液在祖島使用低階靈草5與靈力50煉製。缺草可由丹霞運回祖島；祖島已有材料可直接加工。", "manufacturing")
		goal.island_id = "home"
		goal.recipe_id = "liquid"
		return goal
	if not IslandEconomy.hub(state) and not state.economy.get("islands", {}).get("herb", {}).get("opened", false):
		return _supply_goal("G1", "開拓丹霞供給", "已入金丹。開拓丹霞從祖島支付靈木20＋下品靈石10；丹液需丹霞地方低階草5＋全域靈力50，基礎10秒。丹霞不是進入金丹的前置。", "outposts")
	if IslandEconomy.value(state, "home", "liquid") < 1:
		var goal := _supply_goal("G1", "丹液製作與回運", "金丹首次晉階需祖島丹液1。丹霞以地方低階草5＋全域靈力50製作，基礎10秒，完工後開啟丹液→祖島航線。設定／出發不算到貨；祖島要有可用丹液。草回運若搶料，先停航或保留5；停航仍完成在途。", "manufacturing")
		goal.island_id = "herb"
		goal.recipe_id = "liquid"
		if IslandEconomy.value(state, "herb", "liquid") >= 1 or state.economy.get("trips", {}).has("liquid_home"):
			goal.route = "transport"
			goal.route_id = "liquid_home"
		return goal
	var text := "金丹首次晉階支付祖島靈力2000＋金錢500＋中品靈石50＋丹液1＋陣芯1，並需修煉 %.0f 秒。祖島單一產線，兩配方串行安排。\n" % next_required
	for pair in [["stone_mid", 50, "中品靈石"], ["formation_core", 1, "陣芯"]]:
		if IslandEconomy.value(state, "home", pair[0]) < pair[1]:
			var goal := _supply_goal("G2", "祖島加工" + pair[2], text + "中品靈石每顆用下品靈石5＋靈力10，基礎10秒；陣芯用靈材2＋銅精2，基礎20秒。陣芯缺料回雙島製造與回運，不必升運力；尚未開拓的雙島可到經營→空島開拓。", "manufacturing")
			goal.island_id = "home"
			goal.recipe_id = pair[0]
			return goal
	return _supply_goal("G3", "金丹首次晉階", text + ("材料與修煉已足，可晉階至金丹二層。" if can_level_up else "加工材料已足；等待修煉條，並查看晉階缺少的靈力／金錢。容量不足先擴聚靈壇／靈池或錢莊。") + "保存失敗只重試保存，動畫不發材料。技能、宗門與靈獸均可稍後處理。", "cultivation")

static func _resource_number(resources: Dictionary, id: String, field: String) -> float:
	var parsed := AmountCompat.try_parse(String(resources.get(id, {}).get(field, "0")))
	return parsed.value.to_float() if parsed.ok else 0.0

static func optional_branches(state: GameState, resources: Dictionary) -> String:
	var text := "F5 可選技能："
	if int(state.skills.get("basic_meditation", 0)) >= 1:
		text += "基礎冥想已學會。\n"
	elif _level(state.buildings, "library") < 1:
		text += "藏經閣需金錢500＋靈木200＋下品靈石50＋低階草20；木容量不足200先擴靈木庫，金錢容量不足500先擴錢莊。建閣後等研習90點學基礎冥想；等待時主線照常。\n"
	else:
		text += "藏經閣已建，研習滿90點可學基礎冥想；等待時主線照常。\n"
	text += "F6 可選宗門：遊歷→宗門加入後派遣一項可用任務；任務背景進行，完成後由通知前往領獎，不等領獎才準備金丹。\n稍後處理：直接前往主目標，無須完成兩支線。"
	return text
