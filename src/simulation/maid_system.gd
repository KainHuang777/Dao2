class_name MaidSystem
extends RefCounted

const SAVE_VERSION := 2
const MAX_ACTIONS_PER_ADVANCE := 1000
const XIANGZHI_BOND := 40
const ART_READY := ["qingheng", "nuomeizi", "danxia"]
const DISPLAY_DEFAULT := {"expanded": true, "maid_id": ""}

static func ensure_state(state: GameState) -> void:
	if state == null:
		return
	var raw: Variant = state.get("maid")
	if raw is Dictionary and not raw.is_empty():
		return
	state.set("maid", {"version": SAVE_VERSION, "maids": {}, "display": DISPLAY_DEFAULT.duplicate(true)})

static func display(state: GameState) -> Dictionary:
	if state == null: return DISPLAY_DEFAULT.duplicate(true)
	return _normalize_display(_maid_state(state).get("display"))

static func set_display(state: GameState, expanded: bool, maid_id: String) -> Dictionary:
	if not maid_id.is_empty() and not MaidRules.MAID_IDS.has(maid_id):
		return {"ok": false, "error": "UNKNOWN_MAID", "events": [], "changed_ids": []}
	var root := _maid_state(state).duplicate(true)
	if root.is_empty():
		root = {"version": SAVE_VERSION, "maids": {}}
	var current := _normalize_display(root.get("display"))
	var upgraded := int(root.get("version", 0)) != SAVE_VERSION or not (root.get("display") is Dictionary)
	if not upgraded and bool(current["expanded"]) == expanded and String(current["maid_id"]) == maid_id:
		return {"ok": true, "events": [], "changed_ids": []}
	root["version"] = SAVE_VERSION
	if not root.get("maids") is Dictionary:
		root["maids"] = {}
	root["display"] = {"expanded": expanded, "maid_id": maid_id}
	state.set("maid", root)
	return {
		"ok": true,
		"events": [{"kind": "maid_display_set", "expanded": expanded, "maid_id": maid_id}],
		"changed_ids": ["maid"],
	}

static func _plain_name(raw: String) -> String:
	var start := -1
	for index in raw.length():
		var code := raw.unicode_at(index)
		if code >= 0x3400 and code <= 0x9FFF:
			start = index
			break
	return raw.substr(start) if start > 0 else raw

static func _resource_label(catalog: Dictionary, resource_id: String) -> String:
	var raw_defs: Variant = catalog.get("resources", {})
	if raw_defs is Dictionary:
		var def: Variant = (raw_defs as Dictionary).get(resource_id)
		if def is Dictionary:
			var name := String(def.get("name", resource_id))
			if not name.is_empty():
				return _plain_name(name)
	var raw_pill: Variant = AlchemySystem.PILLS.get(resource_id)
	if raw_pill is Dictionary:
		var pill_name := String(raw_pill.get("name", resource_id))
		if not pill_name.is_empty():
			return _plain_name(pill_name)
	return resource_id

static func _owned_state_amount(state: GameState, resource_id: String) -> float:
	var raw_pill: Variant = AlchemySystem.PILLS.get(resource_id)
	if raw_pill is Dictionary:
		return float(_pill_units(state, resource_id))
	return IslandEconomy.value(state, "home", resource_id)

static func _recipe_option(state: GameState, catalog: Dictionary, recipe_id: String, recipe_name: String, recipe: Dictionary) -> Dictionary:
	var input_rows: Array = []
	var inputs: Variant = recipe.get("inputs")
	if inputs is Dictionary:
		for input_id in inputs:
			var input_key := String(input_id)
			input_rows.append({
				"id": input_key,
				"name": _resource_label(catalog, input_key),
				"per_batch": _amount_number(inputs[input_id]),
				"stock": IslandEconomy.value(state, "home", input_key),
			})
	var output := _amount_number(recipe.get("output"))
	if not is_finite(output) or output <= 0.0:
		output = 1.0
	var product := ProcessingCatalog.product_id(catalog, recipe_id)
	return {
		"id": recipe_id,
		"name": recipe_name,
		"output": output,
		"stock": _stock_units(state, catalog, product),
		"inputs": input_rows,
	}

static func _pill_option(state: GameState, catalog: Dictionary, pill_id: String, pill_name: String) -> Dictionary:
	var cost_rows: Array = []
	var cost: Variant = AlchemySystem.refinement_cost(state, pill_id, 1)
	if cost is Dictionary:
		for resource_id in cost:
			var cost_key := String(resource_id)
			cost_rows.append({
				"id": cost_key,
				"name": _resource_label(catalog, cost_key),
				"per_unit": _amount_number(cost[resource_id]),
				"stock": _owned_state_amount(state, cost_key),
			})
	return {"id": pill_id, "name": pill_name, "stock": _pill_units(state, pill_id), "cost": cost_rows}

static func get_view(state: GameState, content: GameContent) -> Dictionary:
	var catalog: Dictionary = content.processing_catalog if content != null else {}
	var recipes_opts: Array = []
	var recipes: Variant = catalog.get("recipes")
	if recipes is Dictionary:
		for recipe_id in recipes:
			var raw_recipe: Variant = recipes[recipe_id]
			var recipe_name := String(recipe_id)
			if raw_recipe is Dictionary:
				recipe_name = String(raw_recipe.get("name", recipe_id))
				if recipe_name == String(recipe_id):
					var catalog_resources: Variant = catalog.get("resources", {})
					if catalog_resources is Dictionary:
						var product := ProcessingCatalog.product_id(catalog, String(recipe_id))
						var product_def: Variant = (catalog_resources as Dictionary).get(product)
						if product_def is Dictionary:
							recipe_name = String(product_def.get("name", recipe_name))
			recipes_opts.append(_recipe_option(state, catalog, String(recipe_id), _plain_name(recipe_name), raw_recipe if raw_recipe is Dictionary else {}))
	var buildings_opts: Array = []
	var building_defs: Dictionary = content.buildings if content != null else {}
	var buildings_raw: Variant = state.buildings
	if not buildings_raw is Dictionary:
		buildings_raw = {}
	for building_id in buildings_raw:
		var raw_def: Variant = building_defs.get(String(building_id))
		var building_name := String(building_id)
		if raw_def is Dictionary:
			building_name = String(raw_def.get("name", building_id))
		buildings_opts.append({"id": String(building_id), "name": building_name})
	var pills_opts: Array = []
	for pill_id in AlchemySystem.PILLS:
		var raw_pill: Variant = AlchemySystem.PILLS[pill_id]
		var pill_name := String(pill_id)
		if raw_pill is Dictionary:
			pill_name = String(raw_pill.get("name", pill_id))
		pills_opts.append(_pill_option(state, catalog, String(pill_id), pill_name))
	var result := {
		"version": SAVE_VERSION,
		"bond_levels": MaidRules.BOND_LEVELS.duplicate(true),
		"active_duty": "",
		"active_duties": [],
		"display": display(state),
		"maids": {},
	}
	for maid_id in MaidRules.MAIDS:
		var mid := String(maid_id)
		var info: Dictionary = MaidRules.MAIDS[mid]
		var entry := _entry(state, mid)
		var recruited := bool(entry.get("recruited", false))
		var bond := _int_of(entry.get("bond", 0))
		var level: Dictionary = MaidRules.bond_level(bond)
		var next_level: Dictionary = MaidRules.next_bond(bond)
		var next_at := -1
		if not next_level.is_empty():
			next_at = _int_of(next_level.get("at", -1))
		var reason := recruit_error(state, mid)
		var chapters_view: Array = []
		for chapter_def in MaidRules.chapters(mid):
			var chapter_id := String(chapter_def.get("id", ""))
			var hint := _chapter_hint(state, mid, chapter_id)
			chapters_view.append({
				"id": chapter_id,
				"title": String(chapter_def.get("title", "")),
				"bond": _int_of(chapter_def.get("bond", 0)),
				"claimed": bool(hint.claimed),
				"can_claim": bool(hint.can),
				"reason": String(hint.reason),
			})
		var duty_view := _duty_view(entry, state, content)
		if not duty_view.is_empty() and not bool(duty_view.get("paused", false)):
			result.active_duties.append(mid)
			if String(result.get("active_duty", "")).is_empty():
				result.active_duty = mid
		var options := {
			"recipes": recipes_opts.duplicate(true),
			"buildings": buildings_opts.duplicate(true),
			"pills": pills_opts.duplicate(true),
		}
		result.maids[mid] = {
			"id": mid,
			"name": String(info.get("name", "")),
			"role": String(info.get("role", "")),
			"recruited": recruited,
			"bond": bond,
			"bond_name": String(level.get("name", "")),
			"next_bond_name": String(next_level.get("name", "")),
			"next_bond_at": next_at,
			"recruit": {"can": reason.is_empty(), "reason": reason},
			"chapters": chapters_view,
			"duty": duty_view,
			"duty_actions": _int_of(entry.get("duty_actions", 0)),
			"reunion_pending": bool(entry.get("reunion_pending", false)),
			"art_ready": ART_READY.has(mid),
			"options": options,
		}
	return result

static func recruit_error(state: GameState, maid_id: String) -> String:
	if not MaidRules.MAIDS.has(maid_id):
		return "UNKNOWN_MAID"
	if bool(_entry(state, maid_id).get("recruited", false)):
		return "ALREADY_RECRUITED"
	if maid_id == "qingheng":
		if int(state.era_id) < 1 or int(state.buildings.get("hut", 0)) < 1:
			return "MAID_REQUIREMENT"
		return ""
	var qingheng := _entry(state, "qingheng")
	if not bool(qingheng.get("recruited", false)) or _int_of(qingheng.get("bond", 0)) < XIANGZHI_BOND:
		return "MAID_REQUIREMENT"
	if int(state.era_id) < 2:
		return "MAID_REQUIREMENT"
	if maid_id == "danxia" and not AlchemySystem.is_unlocked(state):
		return "ALCHEMY_LOCKED"
	return ""

static func recruit(state: GameState, maid_id: String) -> Dictionary:
	var error := recruit_error(state, maid_id)
	if not error.is_empty():
		return _fail(error)
	var entry := _ensure_entry(state, maid_id)
	entry.recruited = true
	entry.reunion_pending = false
	return {"ok": true, "events": [{"kind": "maid_recruited", "maid_id": maid_id}], "changed_ids": ["maid"]}

static func assign_duty(state: GameState, content: GameContent, maid_id: String, duty: Dictionary) -> Dictionary:
	if not MaidRules.MAIDS.has(maid_id):
		return _fail("UNKNOWN_MAID")
	var entry := _entry(state, maid_id)
	if entry.is_empty() or not bool(entry.get("recruited", false)):
		return _fail("UNKNOWN_MAID")
	var kind: Variant = duty.get("kind")
	var expected := String(MaidRules.MAIDS[maid_id].get("duty", ""))
	if not kind is String or String(kind) != expected:
		return _fail("DUTY_KIND")
	var cleaned := {}
	match expected:
		"steward_stock":
			var steward_error := _validate_steward(state, content, duty)
			if not steward_error.is_empty():
				return _fail(steward_error)
			cleaned = {
				"kind": "steward_stock",
				"paused": false,
				"cooldown": _cadence_for("steward_stock"),
				"status": "RUNNING",
				"recipe_id": String(duty.get("recipe_id", "")),
				"target": int(duty.get("target", 0)),
				"reserve": _clean_reserve(duty.get("reserve", {})),
			}
		"oversee_build":
			var oversee_error := _validate_oversee(state, content, duty)
			if not oversee_error.is_empty():
				return _fail(oversee_error)
			cleaned = {
				"kind": "oversee_build",
				"paused": false,
				"cooldown": _cadence_for("oversee_build"),
				"status": "RUNNING",
				"building_id": String(duty.get("building_id", "")),
			}
		"restock_pills":
			var restock_error := _validate_restock(duty)
			if not restock_error.is_empty():
				return _fail(restock_error)
			cleaned = {
				"kind": "restock_pills",
				"paused": false,
				"cooldown": _cadence_for("restock_pills"),
				"status": "RUNNING",
				"pill_id": String(duty.get("pill_id", "")),
				"target": int(duty.get("target", 0)),
				"reserve": _clean_reserve(duty.get("reserve", {})),
			}
		_:
			return _fail("DUTY_KIND")
	entry.duty = cleaned
	return {"ok": true, "events": [], "changed_ids": ["maid"]}

static func clear_duty(state: GameState, maid_id: String) -> Dictionary:
	if not MaidRules.MAIDS.has(maid_id):
		return _fail("UNKNOWN_MAID")
	var entry := _entry(state, maid_id)
	if entry.is_empty() or not bool(entry.get("recruited", false)):
		return _fail("UNKNOWN_MAID")
	entry.duty = {}
	return {"ok": true, "events": [], "changed_ids": ["maid"]}

static func set_duty_paused(state: GameState, maid_id: String, paused: bool) -> Dictionary:
	if not MaidRules.MAIDS.has(maid_id):
		return _fail("UNKNOWN_MAID")
	var entry := _entry(state, maid_id)
	if entry.is_empty() or not bool(entry.get("recruited", false)):
		return _fail("UNKNOWN_MAID")
	var raw: Variant = entry.get("duty")
	if not raw is Dictionary or raw.is_empty():
		return _fail("DUTY_NONE")
	var duty: Dictionary = raw
	duty.paused = paused
	duty.status = "PAUSED" if paused else "RUNNING"
	return {"ok": true, "events": [], "changed_ids": ["maid"]}

static func execute_duty(state: GameState, content: GameContent, maid_id: String) -> Dictionary:
	if not MaidRules.MAIDS.has(maid_id):
		return _fail("UNKNOWN_MAID")
	var entry := _entry(state, maid_id)
	if entry.is_empty() or not bool(entry.get("recruited", false)):
		return _fail("UNKNOWN_MAID")
	var raw: Variant = entry.get("duty")
	if not raw is Dictionary or raw.is_empty():
		return _fail("DUTY_NONE")
	var duty: Dictionary = raw
	if bool(duty.get("paused", false)):
		return _fail("PAUSED")
	var cadence := _cadence(duty)
	var action := _run_action(state, content, maid_id, duty)
	var events: Array = []
	if bool(action.get("ok", false)):
		duty.cooldown = cadence
		if bool(action.get("noop", false)):
			duty.status = String(action.get("status", "RUNNING"))
			return {"ok": true, "events": events, "changed_ids": ["maid"]}
		duty.status = "RUNNING"
		_record_success(maid_id, entry, duty, int(action.get("units", 0)), events)
		var changed: Array = ["maid"]
		var extras: Variant = action.get("extras", [])
		if extras is Array:
			for extra in extras:
				if not changed.has(extra):
					changed.append(extra)
		return {"ok": true, "events": events, "changed_ids": changed}
	duty.cooldown = cadence
	duty.status = String(action.get("error", "INSUFFICIENT_RESOURCE"))
	return _fail(duty.status)

static func claim_chapter(state: GameState, maid_id: String, chapter_id: String) -> Dictionary:
	var hint := _chapter_hint(state, maid_id, chapter_id)
	if not bool(hint.can):
		return _fail(String(hint.reason))
	var entry := _entry(state, maid_id)
	var amount := 0
	for chapter_def in MaidRules.chapters(maid_id):
		if String(chapter_def.get("id", "")) == chapter_id:
			amount = _int_of(chapter_def.get("bond", 0))
			break
	var flags: Variant = entry.get("chapters")
	if not flags is Dictionary:
		flags = {}
		entry.chapters = flags
	flags[chapter_id] = true
	entry.bond = _int_of(entry.get("bond", 0)) + amount
	return {"ok": true, "events": [{"kind": "maid_chapter_claimed", "maid_id": maid_id, "chapter_id": chapter_id, "bond": amount}], "changed_ids": ["maid"]}

static func chapter_status(state: GameState, maid_id: String, chapter_id: String) -> Dictionary:
	var hint := _chapter_hint(state, maid_id, chapter_id)
	return {"claimed": bool(hint.claimed), "can_claim": bool(hint.can), "reason": String(hint.reason)}

static func reunion(state: GameState, maid_id: String) -> Dictionary:
	if not MaidRules.MAIDS.has(maid_id):
		return _fail("UNKNOWN_MAID")
	var entry := _entry(state, maid_id)
	if entry.is_empty() or not bool(entry.get("recruited", false)):
		return _fail("UNKNOWN_MAID")
	if not bool(entry.get("reunion_pending", false)):
		return _fail("NO_REUNION")
	entry.reunion_pending = false
	return {"ok": true, "events": [{"kind": "maid_reunion", "maid_id": maid_id}], "changed_ids": ["maid"]}

static func advance(content: GameContent, state: GameState, ticks: int, max_actions: int) -> Dictionary:
	var events: Array = []
	var extras: Array = []
	var limit := clampi(max_actions, 0, MAX_ACTIONS_PER_ADVANCE)
	if limit <= 0:
		return {"ok": true, "events": events, "changed_ids": []}
	var remaining := int(ticks)
	if remaining <= 0:
		return {"ok": true, "events": events, "changed_ids": []}
	var maids := _maids_map(state)
	if maids.is_empty():
		return {"ok": true, "events": events, "changed_ids": []}
	var ids: Array = maids.keys()
	ids.sort()
	var lanes: Array = []
	for maid_id in ids:
		var entry_var: Variant = maids.get(maid_id)
		if not entry_var is Dictionary:
			continue
		var entry: Dictionary = entry_var
		var raw: Variant = entry.get("duty")
		if not raw is Dictionary or (raw as Dictionary).is_empty():
			continue
		var duty: Dictionary = raw
		if bool(duty.get("paused", false)):
			continue
		lanes.append({"id": String(maid_id), "entry": entry, "duty": duty})
	if lanes.is_empty():
		return {"ok": true, "events": events, "changed_ids": []}
	var actions := 0
	while actions < limit:
		if remaining > 0:
			var step := remaining
			for lane in lanes:
				var tick_duty: Dictionary = lane.duty
				step = mini(step, maxi(0, _int_of(tick_duty.get("cooldown", 0))))
			if step > 0:
				for lane in lanes:
					var tick_duty: Dictionary = lane.duty
					tick_duty.cooldown = maxi(0, _int_of(tick_duty.get("cooldown", 0)) - step)
				remaining -= step
		var pick: Dictionary = {}
		for lane in lanes:
			var ready_duty: Dictionary = lane.duty
			if _int_of(ready_duty.get("cooldown", 0)) > 0:
				continue
			if pick.is_empty() or _less_served(lane, pick):
				pick = lane
		if pick.is_empty():
			break
		var maid_id := String(pick.id)
		var entry: Dictionary = pick.entry
		var duty: Dictionary = pick.duty
		var cadence := _cadence(duty)
		var action := _run_action(state, content, maid_id, duty)
		actions += 1
		if bool(action.get("ok", false)):
			duty.cooldown = cadence
			if bool(action.get("noop", false)):
				duty.status = String(action.get("status", "RUNNING"))
			else:
				duty.status = "RUNNING"
				_record_success(maid_id, entry, duty, int(action.get("units", 0)), events)
				var action_extras: Variant = action.get("extras", [])
				if action_extras is Array:
					for extra in action_extras:
						if not extras.has(extra):
							extras.append(extra)
		else:
			duty.cooldown = cadence
			duty.status = String(action.get("error", "INSUFFICIENT_RESOURCE"))
	var changed: Array = ["maid"]
	for extra in extras:
		if not changed.has(extra):
			changed.append(extra)
	return {"ok": true, "events": events, "changed_ids": changed}

static func _less_served(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_entry: Dictionary = candidate.entry
	var current_entry: Dictionary = current.entry
	var candidate_actions := _int_of(candidate_entry.get("duty_actions", 0))
	var current_actions := _int_of(current_entry.get("duty_actions", 0))
	if candidate_actions != current_actions:
		return candidate_actions < current_actions
	return String(candidate.id) < String(current.id)

static func offline_report(events: Array) -> Dictionary:
	var actions := 0
	var units := 0
	var kinds := {}
	var first_duty := 0
	for raw in events:
		if not raw is Dictionary:
			continue
		var event: Dictionary = raw
		match String(event.get("kind", "")):
			"maid_duty_executed":
				actions += 1
				units += _int_of(event.get("units", 0))
				var kind := String(event.get("duty_kind", ""))
				kinds[kind] = _int_of(kinds.get(kind, 0)) + 1
			"maid_first_duty":
				first_duty += 1
	if actions <= 0:
		return {}
	return {"actions": actions, "units": units, "kinds": kinds, "first_duty": first_duty}

static func on_reincarnate(state: GameState) -> Dictionary:
	var root := _maid_state(state)
	if root.is_empty():
		return {"ok": true, "events": [], "changed_ids": []}
	var maids := _maids_map(state)
	if maids.is_empty():
		return {"ok": true, "events": [], "changed_ids": []}
	var changed := false
	for maid_id in maids:
		var entry_var: Variant = maids.get(maid_id)
		if not entry_var is Dictionary:
			continue
		var entry: Dictionary = entry_var
		if not bool(entry.get("recruited", false)):
			continue
		changed = true
		var raw: Variant = entry.get("duty")
		if raw is Dictionary and not raw.is_empty():
			var duty: Dictionary = raw
			duty.paused = true
			duty.cooldown = 0
			duty.status = "PAUSED"
		entry.reunion_pending = true
	if changed:
		return {"ok": true, "events": [{"kind": "maid_reunion_pending"}], "changed_ids": ["maid"]}
	return {"ok": true, "events": [], "changed_ids": []}

static func status_text(code: String) -> String:
	match code:
		"IDLE":
			return "尚未指派"
		"RUNNING":
			return "運作中"
		"TARGET_REACHED":
			return "已達目標"
		"INSUFFICIENT_RESOURCE":
			return "材料不足"
		"OUTPUT_FULL":
			return "庫存已滿"
		"LEVEL_CAP":
			return "已達上限"
		"ALCHEMY_LOCKED":
			return "丹道未開"
		"PILL_LOCKED":
			return "丹藥未解鎖"
		"UNKNOWN_RECIPE":
			return "配方未知"
		"UNKNOWN_PILL":
			return "丹藥未知"
		"PAUSED":
			return "已暫停"
		"BLOCKED":
			return "產線忙碌"
		"BUILDING_UNKNOWN":
			return "建築未知"
		"BUILDING_LOCKED":
			return "建築未解鎖"
		"ERA_REQUIREMENT":
			return "境界不足"
		"DUTY_NONE":
			return "尚未指派"
	return code

static func _maid_state(state: GameState) -> Dictionary:
	var raw: Variant = state.get("maid")
	if raw is Dictionary:
		return raw
	return {}

static func _normalize_display(value: Variant) -> Dictionary:
	var result := DISPLAY_DEFAULT.duplicate(true)
	if not (value is Dictionary): return result
	var display: Dictionary = value
	var expanded: Variant = display.get("expanded")
	if expanded is bool: result["expanded"] = bool(expanded)
	var maid_id: Variant = display.get("maid_id")
	if maid_id is String and MaidRules.MAID_IDS.has(String(maid_id)): result["maid_id"] = String(maid_id)
	return result

static func _maids_map(state: GameState) -> Dictionary:
	var raw: Variant = _maid_state(state).get("maids")
	if raw is Dictionary:
		return raw
	return {}

static func _entry(state: GameState, maid_id: String) -> Dictionary:
	var raw: Variant = _maids_map(state).get(maid_id)
	if raw is Dictionary:
		return raw
	return {}

static func _ensure_entry(state: GameState, maid_id: String) -> Dictionary:
	var root := _maid_state(state)
	if root.is_empty():
		root = {"version": SAVE_VERSION, "maids": {}}
	root["version"] = SAVE_VERSION
	if not (root.get("display") is Dictionary):
		root["display"] = DISPLAY_DEFAULT.duplicate(true)
	var maids: Variant = root.get("maids")
	if not maids is Dictionary:
		maids = {}
	var current_var: Variant = maids.get(maid_id)
	var current: Dictionary = current_var if current_var is Dictionary else {}
	var defaults := {
		"recruited": false,
		"bond": 0,
		"chapters": {},
		"duty": {},
		"duty_actions": 0,
		"reunion_pending": false,
		"first_duty_done": false,
	}
	for key in defaults:
		if not current.has(key):
			current[key] = defaults[key]
	if not current.chapters is Dictionary:
		current.chapters = {}
	if not current.duty is Dictionary:
		current.duty = {}
	current.recruited = bool(current.recruited)
	current.bond = _int_of(current.bond)
	current.duty_actions = _int_of(current.duty_actions)
	current.reunion_pending = bool(current.reunion_pending)
	current.first_duty_done = bool(current.first_duty_done)
	maids[maid_id] = current
	root.maids = maids
	state.set("maid", root)
	return current

static func _cadence(duty: Dictionary) -> int:
	return _cadence_for(String(duty.get("kind", "")))

static func _cadence_for(kind: String) -> int:
	return maxi(1, _int_of(MaidRules.DUTY_CADENCE_SECONDS.get(kind, 10)))

static func _duty_view(entry: Dictionary, state: GameState, content: GameContent) -> Dictionary:
	var raw: Variant = entry.get("duty")
	if not raw is Dictionary or raw.is_empty():
		return {}
	var duty: Dictionary = raw
	var kind := String(duty.get("kind", ""))
	var view := {
		"kind": kind,
		"paused": bool(duty.get("paused", false)),
		"cooldown": _int_of(duty.get("cooldown", 0)),
		"status": String(duty.get("status", "RUNNING")),
		"status_text": status_text(String(duty.get("status", "RUNNING"))),
	}
	if kind == "steward_stock":
		view.recipe_id = String(duty.get("recipe_id", ""))
		view.target = _int_of(duty.get("target", 0))
		view.reserve = _safe_dict(duty.get("reserve", {}))
	elif kind == "oversee_build":
		view.building_id = String(duty.get("building_id", ""))
	elif kind == "restock_pills":
		view.pill_id = String(duty.get("pill_id", ""))
		view.target = _int_of(duty.get("target", 0))
		view.reserve = _safe_dict(duty.get("reserve", {}))
	var shortage := _duty_shortage(state, content, duty)
	if not shortage.is_empty():
		view.shortage = shortage
		view.shortage_text = _shortage_text(shortage)
	return view

static func _duty_shortage(state: GameState, content: GameContent, duty: Dictionary) -> Dictionary:
	match String(duty.get("kind", "")):
		"steward_stock":
			return _steward_shortage(state, content, duty)
		"restock_pills":
			return _restock_shortage(state, content, duty)
		"oversee_build":
			return _oversee_shortage(state, content, duty)
	return {}

static func _shortage_row(state: GameState, catalog: Dictionary, resource_id: String, required: float, reserve: float, pill_based: bool) -> Dictionary:
	var owned := float(_pill_units(state, resource_id)) if pill_based else IslandEconomy.value(state, "home", resource_id)
	var available := maxf(0.0, owned - reserve)
	return {
		"id": resource_id,
		"name": _resource_label(catalog, resource_id),
		"required": required,
		"stock": owned,
		"reserve": reserve,
		"missing": maxf(0.0, required - available),
	}

static func _shortage_text(shortage: Dictionary) -> String:
	var rows: Variant = shortage.get("inputs", [])
	if not rows is Array or (rows as Array).is_empty():
		return ""
	var row: Dictionary = (rows as Array)[0]
	var name := String(row.get("name", row.get("id", "")))
	var missing := _amount_string(row.get("missing", 0.0))
	var required := _amount_string(row.get("required", 0.0))
	var stock := _amount_string(row.get("stock", 0.0))
	var reserve := _amount_string(row.get("reserve", 0.0))
	if float(row.get("reserve", 0.0)) > 0.0:
		return "%s不足 %s（需 %s，現有 %s，保留 %s）" % [name, missing, required, stock, reserve]
	return "%s不足 %s（需 %s，現有 %s）" % [name, missing, required, stock]

static func _amount_string(raw: Variant) -> String:
	return AmountCompat.from_number(_amount_number(raw)).to_display_string()

static func _steward_shortage(state: GameState, content: GameContent, duty: Dictionary) -> Dictionary:
	var catalog: Dictionary = content.processing_catalog if content != null else {}
	var recipes: Variant = catalog.get("recipes")
	var recipe_id := String(duty.get("recipe_id", ""))
	if not recipes is Dictionary or not (recipes as Dictionary).has(recipe_id):
		return {}
	var recipe: Dictionary = (recipes as Dictionary)[recipe_id]
	var product := ProcessingCatalog.product_id(catalog, recipe_id)
	var stock := _stock_units(state, catalog, product)
	var need := _int_of(duty.get("target", 0)) - stock
	if need <= 0:
		return {}
	var output := _amount_number(recipe.get("output"))
	if not is_finite(output) or output < 1.0:
		output = 1.0
	var desired := maxi(1, int(ceilf(float(need) / output)))
	var batches := mini(MaidRules.MAX_UNITS_PER_ACTION, desired)
	var inputs: Variant = recipe.get("inputs")
	if not inputs is Dictionary:
		return {}
	var reserve: Variant = duty.get("reserve", {})
	var worst: Dictionary = {}
	var worst_ratio := 2.0
	for input_id in inputs:
		var per_batch := _amount_number(inputs[input_id])
		if not is_finite(per_batch) or per_batch <= 0.0:
			continue
		var input_key := String(input_id)
		var required := per_batch * float(batches)
		var reserve_amount := _reserve_number(reserve, input_key)
		var owned := IslandEconomy.value(state, "home", input_key)
		var available := maxf(0.0, owned - reserve_amount)
		if available + CommandProcessor.AFFORD_TOLERANCE >= required:
			continue
		var ratio := available / required if required > 0.0 else 0.0
		if worst.is_empty() or ratio < worst_ratio:
			worst_ratio = ratio
			worst = _shortage_row(state, catalog, input_key, required, reserve_amount, false)
	if worst.is_empty():
		return {}
	return {"code": "INSUFFICIENT_RESOURCE", "requested": batches, "output": output, "target": _int_of(duty.get("target", 0)), "stock": stock, "inputs": [worst]}

static func _restock_shortage(state: GameState, content: GameContent, duty: Dictionary) -> Dictionary:
	var pill_id := String(duty.get("pill_id", ""))
	if not AlchemySystem.PILLS.has(pill_id):
		return {}
	var stock := _pill_units(state, pill_id)
	var need := _int_of(duty.get("target", 0)) - stock
	if need <= 0:
		return {}
	var desired := mini(MaidRules.MAX_UNITS_PER_ACTION, need)
	var reserve: Variant = duty.get("reserve", {})
	var last_reason := ""
	var count := desired
	while count >= 1:
		var check := AlchemySystem.can_refine(state, pill_id, count)
		if bool(check.get("can_refine", false)):
			var cost: Variant = AlchemySystem.refinement_cost(state, pill_id, count)
			if cost is Dictionary and _reserve_allows(state, reserve, cost):
				return {}
			last_reason = "INSUFFICIENT_RESOURCE"
		else:
			last_reason = String(check.get("reason", "INSUFFICIENT_RESOURCE"))
		count -= 1
	if last_reason != "INSUFFICIENT_RESOURCE":
		return {}
	var unit_cost: Variant = AlchemySystem.refinement_cost(state, pill_id, 1)
	if not unit_cost is Dictionary:
		return {}
	var catalog: Dictionary = content.processing_catalog if content != null else {}
	var worst: Dictionary = {}
	var worst_ratio := 2.0
	for resource_id in unit_cost:
		var resource_key := String(resource_id)
		var per_unit := _amount_number(unit_cost[resource_id])
		var required := per_unit * float(desired)
		var reserve_amount := _reserve_number(reserve, resource_key)
		var pill_based: bool = unit_cost[resource_id] is int
		var owned := float(_pill_units(state, resource_key)) if pill_based else IslandEconomy.value(state, "home", resource_key)
		var available := maxf(0.0, owned - reserve_amount)
		if available + CommandProcessor.AFFORD_TOLERANCE >= required:
			continue
		var ratio := available / required if required > 0.0 else 0.0
		if worst.is_empty() or ratio < worst_ratio:
			worst_ratio = ratio
			worst = _shortage_row(state, catalog, resource_key, required, reserve_amount, pill_based)
	if worst.is_empty():
		return {}
	return {"code": "INSUFFICIENT_RESOURCE", "requested": desired, "target": _int_of(duty.get("target", 0)), "stock": stock, "inputs": [worst]}

static func _oversee_shortage(state: GameState, content: GameContent, duty: Dictionary) -> Dictionary:
	if content == null:
		return {}
	var building_id := String(duty.get("building_id", ""))
	var raw_level: Variant = state.buildings.get(building_id)
	if not (raw_level is int or raw_level is float):
		return {}
	var level := int(raw_level)
	var def: Variant = content.buildings.get(building_id)
	if not def is Dictionary:
		return {}
	var building_def: Dictionary = def
	if level >= CommandProcessor.level_cap(building_def, content, state):
		return {}
	var onboarding_active := Onboarding.is_active(state.onboarding_version, state.era_id)
	var base_cost := BuildingCosts.resolve_base_cost(building_id, building_def.get("base_cost", {}), onboarding_active)
	var costs := BuildingCosts.compute_cost(base_cost, level, float(building_def.get("cost_factor", 1.0)))
	var catalog: Dictionary = content.processing_catalog
	var worst: Dictionary = {}
	var worst_ratio := 2.0
	for resource_id in costs:
		var resource_key := String(resource_id)
		var required := _amount_number(costs[resource_id])
		if required <= 0.0:
			continue
		var owned := IslandEconomy.value(state, "home", resource_key)
		if owned + CommandProcessor.AFFORD_TOLERANCE >= required:
			continue
		var ratio := owned / required
		if worst.is_empty() or ratio < worst_ratio:
			worst_ratio = ratio
			worst = _shortage_row(state, catalog, resource_key, required, 0.0, false)
	if worst.is_empty():
		return {}
	return {"code": "INSUFFICIENT_RESOURCE", "building_id": building_id, "level": level, "inputs": [worst]}


static func _safe_dict(raw: Variant) -> Dictionary:
	return raw.duplicate(true) if raw is Dictionary else {}

static func _run_action(state: GameState, content: GameContent, maid_id: String, duty: Dictionary) -> Dictionary:
	match String(duty.get("kind", "")):
		"steward_stock":
			return _perform_steward(state, content, maid_id, duty)
		"oversee_build":
			return _perform_oversee(state, content, maid_id, duty)
		"restock_pills":
			return _perform_restock(state, content, maid_id, duty)
	return {"ok": false, "error": "DUTY_KIND"}

static func _perform_steward(state: GameState, content: GameContent, maid_id: String, duty: Dictionary) -> Dictionary:
	var catalog: Dictionary = content.processing_catalog if content != null else {}
	var recipes: Variant = catalog.get("recipes")
	if not recipes is Dictionary:
		return {"ok": false, "error": "UNKNOWN_RECIPE"}
	var recipe_id := String(duty.get("recipe_id", ""))
	if not recipes.has(recipe_id):
		return {"ok": false, "error": "UNKNOWN_RECIPE"}
	var recipe: Dictionary = recipes[recipe_id]
	var product := ProcessingCatalog.product_id(catalog, recipe_id)
	var stock := _stock_units(state, catalog, product)
	var need := _int_of(duty.get("target", 0)) - stock
	if need <= 0:
		return {"ok": true, "noop": true, "status": "TARGET_REACHED"}
	var output_per_batch := _amount_number(recipe.get("output"))
	if not is_finite(output_per_batch) or output_per_batch < 1.0:
		output_per_batch = 1.0
	var desired := int(ceilf(float(need) / output_per_batch))
	if desired < 1:
		desired = 1
	var batches := mini(MaidRules.MAX_UNITS_PER_ACTION, desired)
	var inputs: Variant = recipe.get("inputs")
	if not inputs is Dictionary:
		return {"ok": false, "error": "UNKNOWN_RECIPE"}
	for input_id in inputs:
		var per_batch := _amount_number(inputs[input_id])
		if not is_finite(per_batch) or per_batch <= 0.0:
			continue
		var available := IslandEconomy.value(state, "home", String(input_id)) - _reserve_number(duty.get("reserve", {}), String(input_id))
		if not is_finite(available) or available < 0.0:
			available = 0.0
		batches = mini(batches, int(floor(available / per_batch)))
	var space_batches := batches
	var catalog_resources: Variant = catalog.get("resources")
	if catalog_resources is Dictionary and catalog_resources.has(product):
		var space := IslandEconomy.free_space(state, "home", product, catalog)
		space_batches = int(floor(maxf(0.0, space) / output_per_batch))
	if space_batches <= 0:
		return {"ok": false, "error": "OUTPUT_FULL"}
	if batches <= 0:
		return {"ok": false, "error": "INSUFFICIENT_RESOURCE"}
	if batches > space_batches:
		batches = space_batches
	var result := {}
	if state.economy.is_empty():
		result = CommandProcessor.apply(content, state, {"type": "craft", "command_id": "maid:" + maid_id, "payload": {"recipe_id": recipe_id, "count": batches, "recipe_version": 1}})
	else:
		result = IslandEconomy.command(content, state, "craft", {"island_id": "home", "recipe_id": recipe_id, "count": batches, "repeat": false, "reserves": _reserve_strings(duty.get("reserve", {})), "recipe_version": 1})
	if not bool(result.get("ok", false)):
		var error := String(result.get("error", "INSUFFICIENT_RESOURCE"))
		if error == "JOB_BUSY":
			return {"ok": false, "error": "BLOCKED"}
		return {"ok": false, "error": error}
	return {"ok": true, "units": batches, "extras": ["resources"]}

static func _perform_oversee(state: GameState, content: GameContent, maid_id: String, duty: Dictionary) -> Dictionary:
	if content == null:
		return {"ok": false, "error": "BUILDING_UNKNOWN"}
	var building_id := String(duty.get("building_id", ""))
	var raw_level: Variant = state.buildings.get(building_id)
	if not (raw_level is int or raw_level is float):
		return {"ok": false, "error": "BUILDING_UNKNOWN"}
	var level := int(raw_level)
	var def: Variant = content.buildings.get(building_id)
	if not def is Dictionary:
		return {"ok": false, "error": "BUILDING_UNKNOWN"}
	var building_def: Dictionary = def
	var cap := CommandProcessor.level_cap(building_def, content, state)
	if level >= cap:
		return {"ok": true, "noop": true, "status": "LEVEL_CAP"}
	var result := CommandProcessor.apply(content, state, {"type": "upgrade_building", "command_id": "maid:" + maid_id, "payload": {"building_id": building_id}})
	if not bool(result.get("ok", false)):
		return {"ok": false, "error": String(result.get("error", "INSUFFICIENT_RESOURCE"))}
	return {"ok": true, "units": 1, "extras": ["buildings"]}

static func _perform_restock(state: GameState, content: GameContent, maid_id: String, duty: Dictionary) -> Dictionary:
	var pill_id := String(duty.get("pill_id", ""))
	var def: Variant = AlchemySystem.PILLS.get(pill_id)
	if not def is Dictionary:
		return {"ok": false, "error": "UNKNOWN_PILL"}
	var need := _int_of(duty.get("target", 0)) - _pill_units(state, pill_id)
	if need <= 0:
		return {"ok": true, "noop": true, "status": "TARGET_REACHED"}
	var desired := mini(MaidRules.MAX_UNITS_PER_ACTION, need)
	var chosen := 0
	var last_reason := "INSUFFICIENT_RESOURCE"
	var reserve: Variant = duty.get("reserve", {})
	var count := desired
	while count >= 1:
		var check := AlchemySystem.can_refine(state, pill_id, count)
		if bool(check.get("can_refine", false)):
			var cost: Variant = AlchemySystem.refinement_cost(state, pill_id, count)
			if cost is Dictionary and _reserve_allows(state, reserve, cost):
				chosen = count
				break
			last_reason = "INSUFFICIENT_RESOURCE"
		else:
			last_reason = String(check.get("reason", "INSUFFICIENT_RESOURCE"))
		count -= 1
	if chosen == 0:
		return {"ok": false, "error": last_reason}
	var result := CommandProcessor.apply(content, state, {"type": "refine_pill", "command_id": "maid:" + maid_id, "payload": {"pill_id": pill_id, "count": chosen}})
	if not bool(result.get("ok", false)):
		var error := String(result.get("error", "INSUFFICIENT_RESOURCE"))
		if error == "JOB_BUSY":
			return {"ok": false, "error": "BLOCKED"}
		return {"ok": false, "error": error}
	return {"ok": true, "units": chosen, "extras": ["pills", "resources"]}

static func _reserve_allows(state: GameState, reserve: Variant, cost: Dictionary) -> bool:
	for resource_id in cost:
		var required: Variant = cost[resource_id]
		var reserved_amount := _reserve_number(reserve, String(resource_id))
		if required is int:
			if float(_int_of(state.pills.get(String(resource_id), 0))) - reserved_amount < float(required):
				return false
		else:
			var amount := required as AmountCompat
			if amount == null:
				return false
			var required_value := amount.to_float()
			if not is_finite(required_value):
				return false
			var available := IslandEconomy.value(state, "home", String(resource_id)) - reserved_amount
			if available < required_value:
				return false
	return true

static func _stock_units(state: GameState, catalog: Dictionary, product: String) -> int:
	if product == "foundation_pill":
		return maxi(0, _int_of(state.pills.get(product, 0)))
	if catalog.is_empty():
		return 0
	var raw_entry: Variant = state.resources.get(product)
	if not raw_entry is Dictionary or not raw_entry.get("value") is AmountCompat:
		return 0
	var amount := raw_entry.value as AmountCompat
	var stock := amount.to_float()
	if not is_finite(stock):
		return 0
	return maxi(0, int(floor(stock)))

static func _pill_units(state: GameState, pill_id: String) -> int:
	return maxi(0, _int_of(state.pills.get(pill_id, 0)))

static func _amount_number(raw: Variant) -> float:
	if raw is AmountCompat:
		return (raw as AmountCompat).to_float()
	if raw is int or raw is float:
		var direct := float(raw)
		return direct if is_finite(direct) else 0.0
	if raw is String:
		var parsed := AmountCompat.try_parse(raw)
		if not bool(parsed.get("ok", false)):
			return 0.0
		var value: Variant = parsed.get("value")
		if value is AmountCompat:
			return (value as AmountCompat).to_float()
	return 0.0

static func _record_success(maid_id: String, entry: Dictionary, duty: Dictionary, units: int, events: Array) -> void:
	entry.duty_actions = _int_of(entry.get("duty_actions", 0)) + 1
	events.append({
		"kind": "maid_duty_executed",
		"maid_id": maid_id,
		"duty_kind": String(duty.get("kind", "")),
		"units": units,
	})
	if not bool(entry.get("first_duty_done", false)):
		entry.first_duty_done = true
		entry.bond = _int_of(entry.get("bond", 0)) + MaidRules.FIRST_DUTY_BOND
		events.append({"kind": "maid_first_duty", "maid_id": maid_id})

static func _chapter_hint(state: GameState, maid_id: String, chapter_id: String) -> Dictionary:
	if not MaidRules.MAIDS.has(maid_id):
		return {"claimed": false, "can": false, "reason": "CHAPTER_UNKNOWN"}
	var entry := _entry(state, maid_id)
	if not bool(entry.get("recruited", false)):
		return {"claimed": false, "can": false, "reason": "CHAPTER_UNKNOWN"}
	var list := MaidRules.chapters(maid_id)
	var index := -1
	var def := {}
	for i in range(list.size()):
		var candidate: Dictionary = list[i]
		if String(candidate.get("id", "")) == chapter_id:
			index = i
			def = candidate
			break
	if index < 0:
		return {"claimed": false, "can": false, "reason": "CHAPTER_UNKNOWN"}
	var flags_var: Variant = entry.get("chapters")
	var flags := {}
	if flags_var is Dictionary:
		flags = flags_var
	if bool(flags.get(chapter_id, false)):
		return {"claimed": true, "can": false, "reason": "CHAPTER_CLAIMED"}
	if index > 0 and not bool(flags.get(String(list[index - 1].get("id", "")), false)):
		return {"claimed": false, "can": false, "reason": "CHAPTER_LOCKED"}
	if not _requirement_met(state, entry, def):
		return {"claimed": false, "can": false, "reason": "CHAPTER_REQUIREMENT"}
	return {"claimed": false, "can": true, "reason": ""}

static func _requirement_met(state: GameState, entry: Dictionary, def: Dictionary) -> bool:
	match String(def.get("requires", "")):
		"duty_units":
			return _int_of(entry.get("duty_actions", 0)) >= _int_of(def.get("amount", 0))
		"sect_unlocked":
			return bool(state.sect.get("unlocked", false))
		"any_skill":
			for value in state.skills.values():
				if (value is int or value is float) and is_finite(float(value)) and float(value) >= 1.0:
					return true
			return false
		"beast_active":
			var active: Variant = state.beasts.get("active", {})
			return active is Dictionary and not active.is_empty()
		"reincarnation_talent":
			return state.reincarnation_count >= 1 and not state.talents.is_empty()
	return false

static func _validate_steward(state: GameState, content: GameContent, duty: Dictionary) -> String:
	if content == null:
		return "UNKNOWN_RECIPE"
	var catalog: Dictionary = content.processing_catalog
	var recipes: Variant = catalog.get("recipes")
	if not recipes is Dictionary:
		return "UNKNOWN_RECIPE"
	var recipe_id: Variant = duty.get("recipe_id")
	if not recipe_id is String or String(recipe_id).is_empty() or not recipes.has(recipe_id):
		return "UNKNOWN_RECIPE"
	if _int_of(duty.get("target", 0)) < 1:
		return "INVALID_TARGET"
	var reserve_error := _validate_reserve(duty.get("reserve", {}), recipes[recipe_id])
	if not reserve_error.is_empty():
		return reserve_error
	return ""

static func _validate_oversee(state: GameState, content: GameContent, duty: Dictionary) -> String:
	var building_id: Variant = duty.get("building_id")
	if not building_id is String or String(building_id).is_empty():
		return "BUILDING_UNKNOWN"
	if content == null or not content.buildings.has(building_id):
		return "BUILDING_UNKNOWN"
	if not state.buildings.has(building_id):
		return "BUILDING_LOCKED"
	return ""

static func _validate_restock(duty: Dictionary) -> String:
	var pill_id: Variant = duty.get("pill_id")
	if not pill_id is String or String(pill_id).is_empty() or not AlchemySystem.PILLS.has(pill_id):
		return "UNKNOWN_PILL"
	if _int_of(duty.get("target", 0)) < 1:
		return "INVALID_TARGET"
	return _validate_reserve(duty.get("reserve", {}), {})

static func _validate_reserve(raw: Variant, recipe: Dictionary) -> String:
	if not raw is Dictionary:
		return "INVALID_RESERVE"
	var inputs: Variant = recipe.get("inputs", {})
	for key in raw:
		if not key is String:
			return "INVALID_RESERVE"
		var amount := _reserve_number(raw, String(key))
		if not is_finite(amount) or amount < 0.0:
			return "INVALID_RESERVE"
		if inputs is Dictionary and not inputs.is_empty() and not inputs.has(key):
			return "INVALID_RESERVE"
	return ""

static func _clean_reserve(raw: Variant) -> Dictionary:
	var result := {}
	if not raw is Dictionary:
		return result
	for key in raw:
		if not key is String:
			continue
		var amount := _reserve_number(raw, String(key))
		if not is_finite(amount) or amount < 0.0:
			continue
		result[String(key)] = int(amount) if amount == floorf(amount) else amount
	return result

static func _reserve_strings(raw: Variant) -> Dictionary:
	var result := {}
	if not raw is Dictionary:
		return result
	for key in raw:
		if not key is String:
			continue
		var amount := _reserve_number(raw, String(key))
		if not is_finite(amount) or amount < 0.0:
			continue
		result[String(key)] = str(int(amount)) if amount == floorf(amount) else str(amount)
	return result

static func _reserve_number(raw: Variant, resource_id: String) -> float:
	if not raw is Dictionary:
		return 0.0
	var value: Variant = raw.get(resource_id, 0)
	if value is int or value is float:
		var direct := float(value)
		return direct if is_finite(direct) else -1.0
	if value is String:
		var text := String(value).strip_edges()
		if text.is_empty():
			return 0.0
		if text.is_valid_float():
			var number := float(text)
			return number if is_finite(number) else -1.0
		var parsed := AmountCompat.try_parse(text)
		if bool(parsed.get("ok", false)):
			var amount: Variant = parsed.get("value")
			if amount is AmountCompat:
				return (amount as AmountCompat).to_float()
	return -1.0

static func _int_of(raw: Variant) -> int:
	if raw is int or raw is float:
		var value := float(raw)
		if is_finite(value) and absf(value) < 9.2e18:
			return int(value)
	return 0

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "events": [], "changed_ids": []}
