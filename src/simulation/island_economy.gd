class_name IslandEconomy
extends RefCounted
## RES1-B opt-in rules. Home inventory aliases resources, never copies it.
## All quantities use the RES1-A layer-zero <= 1e12 Amount contract.

const VERSION := "res1-b-1"
const GLOBAL := ["money", "lingli", "lingqi"]
const ISLANDS := {
	"home": {"era": 1, "rates": {}, "facility": {}},
	"wood": {"era": 2, "rates": {"wood": 2}, "facility": {"hut": 2}},
	"ore": {"era": 2, "rates": {"stone_low": 2, "black_copper": 2}, "facility": {"stone_mine": 3}},
	"herb": {"era": 3, "rates": {"spirit_grass_low": 2, "spirit_grass_100y": 1}, "facility": {"herb_farm": 3}},
}
const DURATIONS := {"bronze_essence": 10, "spirit_timber": 10, "formation_core": 20, "liquid": 10, "foundation_pill": 20, "stone_mid": 10, "golden_core_pill": 30, "talisman": 10}
# One loaded leg per 10-second round trip. No empty-return inventory or losses.
const ROUTES := {
	"wood_ore": ["wood", "ore", "wood"],
	"ore_wood": ["ore", "wood", "stone_low"],
	"timber_home": ["wood", "home", "spirit_timber"],
	"bronze_home": ["ore", "home", "bronze_essence"],
	"grass_home": ["herb", "home", "spirit_grass_low"],
	"herb_home": ["herb", "home", "spirit_grass_100y"],
	"liquid_home": ["herb", "home", "liquid"],
}

static func initial() -> Dictionary:
	var islands := {}
	for id in ISLANDS:
		islands[id] = {"opened": id == "home", "inventory": {}}
	return {"version": VERSION, "tick": 0, "islands": islands, "jobs": {}, "routes": {}, "trips": {}}

static func migration_preview(state: GameState, catalog: Dictionary) -> Dictionary:
	if not state.economy.is_empty():
		return _fail("ALREADY_MIGRATED")
	if not ProcessingCatalog.validate(catalog).ok:
		return _fail("INVALID_PROCESSING_CONTENT")
	for id in state.resources:
		if not _amount(state.resources[id].value.serialize()):
			return _fail("UNSUPPORTED_AMOUNT")
	if state.resources.has("foundation_pill") and not ProcessingInventory.read(state, "foundation_pill").ok:
		return _fail("INVENTORY_CONFLICT")
	return {"ok": true, "version": VERSION, "home_alias": state.resources.keys(), "unopened": ["wood", "ore", "herb"], "buildings_preserved": true, "realm_inventory": "unchanged; excluded from recipes", "pill_policy": "resources authoritative; mirror must agree", "events": [], "changed_ids": []}

static func command(content: GameContent, state: GameState, kind: String, p: Dictionary) -> Dictionary:
	if content.processing_catalog.is_empty():
		return _fail("PROCESSING_NOT_ENABLED")
	if kind == "migrate_processing":
		var preview := migration_preview(state, content.processing_catalog)
		if not preview.ok:
			return preview
		for id in content.processing_catalog.resources:
			if not state.resources.has(id):
				state.resources[id] = {"value": AmountCompat.zero(), "unlocked": int(content.processing_catalog.resources[id].era) <= state.era_id, "ever_obtained": false}
		state.economy = initial()
		return _success("economy_migrated")
	if state.economy.is_empty():
		return _fail("ECONOMY_NOT_MIGRATED")
	if IslandProgression.active(state) and state.era_id < 2:
		return _fail("ERA_REQUIREMENT")
	var island: Variant = p.get("island_id", "home")
	if not island is String or not ISLANDS.has(island):
		return _fail("UNKNOWN_ISLAND")
	if kind == "open_island":
		if state.economy.get("version") == IslandProgression.LEGACY_VERSION and island == "herb":
			return _fail("ERA_REQUIREMENT")
		if state.economy.islands[island].opened:
			return _fail("ISLAND_ALREADY_OPEN")
		if state.era_id < int(ISLANDS[island].era):
			return _fail("ERA_REQUIREMENT")
		if value(state, "home", "wood") < 20 or value(state, "home", "stone_low") < 10:
			return _fail("INSUFFICIENT_RESOURCE")
		_put(state, "home", "wood", value(state, "home", "wood") - 20)
		_put(state, "home", "stone_low", value(state, "home", "stone_low") - 10)
		state.economy.islands[island].opened = true
		return _success("island_opened")
	if kind == "configure_route":
		return _configure_route(state, p)
	if not state.economy.islands[island].opened:
		return _fail("ISLAND_NOT_OPEN")
	if kind == "switch_processing":
		if not state.economy.jobs.has(island):
			return _fail("NO_JOB")
		# Validate the next request on an isolated copy. Shortage/full output may wait.
		var trial := state.duplicate_state()
		trial.economy.jobs.erase(island)
		var checked := command(content, trial, "craft", p)
		if not checked.ok and not checked.error in ["INSUFFICIENT_RESOURCE", "OUTPUT_FULL"]:
			return checked
		var next := {"recipe_id": p.recipe_id, "recipe_version": 1, "remaining": 0, "batches": int(p.get("count", 1)), "repeat": p.get("repeat", false), "reserves": p.get("reserves", {}).duplicate(true), "status": "ready"}
		if int(state.economy.jobs[island].remaining) == 0:
			state.economy.jobs[island] = next
		else:
			state.economy.jobs[island].pending = next
		return _success("processing_switch_queued")
	if kind == "stop_processing":
		if not state.economy.jobs.has(island):
			return _fail("NO_JOB")
		state.economy.jobs[island].batches = 0
		state.economy.jobs[island].repeat = false
		state.economy.jobs[island].erase("pending")
		if int(state.economy.jobs[island].remaining) == 0:
			state.economy.jobs.erase(island)
		return _success("processing_stopped_after_batch")
	if kind == "craft":
		if state.economy.jobs.has(island):
			return _fail("JOB_BUSY")
		var id: Variant = p.get("recipe_id")
		if not id is String or not content.processing_catalog.recipes.has(id):
			return _fail("UNKNOWN_RECIPE")
		if p.get("recipe_version", 1) != 1:
			return _fail("RECIPE_VERSION_MISMATCH")
		var count: Variant = p.get("count", 1)
		var repeating: Variant = p.get("repeat", false)
		var reserves: Variant = p.get("reserves", {})
		if not _integer(count, 1, 1000000) or not repeating is bool:
			return _fail("INVALID_COUNT")
		if not reserves is Dictionary:
			return _fail("INVALID_RESERVE")
		for resource in reserves:
			if not content.processing_catalog.recipes[id].inputs.has(resource) or not _amount(reserves[resource]):
				return _fail("INVALID_RESERVE")
		var job := {"recipe_id": id, "recipe_version": 1, "remaining": 0, "batches": int(count), "repeat": repeating, "reserves": reserves.duplicate(true), "status": "ready"}
		var error := _start(state, content.processing_catalog, island, job)
		if not error.is_empty():
			return _fail(error)
		state.economy.jobs[island] = job
		return _success("processing_started")
	return _fail("UNKNOWN_COMMAND")

static func _configure_route(state: GameState, p: Dictionary) -> Dictionary:
	var id: Variant = p.get("route_id")
	if not id is String or not ROUTES.has(id):
		return _fail("UNKNOWN_ROUTE")
	var def: Array = ROUTES[id]
	if not state.economy.islands[def[0]].opened or not state.economy.islands[def[1]].opened:
		return _fail("ISLAND_NOT_OPEN")
	var enabled: Variant = p.get("enabled", true)
	var reserve: Variant = p.get("reserve", "0")
	var target: Variant = p.get("target", "100")
	var level: Variant = p.get("level", 1)
	if not enabled is bool or not _amount(reserve) or not _amount(target) or not _integer(level, 1, 2):
		return _fail("INVALID_ROUTE_SETTINGS")
	var old: Dictionary = state.economy.routes.get(id, {"level": 1})
	if int(level) < int(old.level):
		return _fail("ROUTE_LEVEL_DOWNGRADE")
	if int(level) > int(old.level):
		var costs := {"wood": 20}
		if IslandProgression.active(state):
			costs = {"spirit_timber": 2, "bronze_essence": 2}
		for resource in costs:
			if value(state, "home", resource) < float(costs[resource]):
				return _fail("INSUFFICIENT_RESOURCE")
		for resource in costs:
			_put(state, "home", resource, value(state, "home", resource) - float(costs[resource]))
	# Current trip keeps its cargo and duration; settings only affect the next departure.
	state.economy.routes[id] = {"enabled": enabled, "reserve": reserve, "target": target, "level": int(level)}
	return _success("route_configured")

static func value(state: GameState, island: String, id: String) -> float:
	if island == "home" or id in GLOBAL:
		if not state.resources.has(id):
			return 0.0
		return state.resources[id].value.to_float()
	return float(state.economy.islands[island].inventory.get(id, "0"))

static func _put(state: GameState, island: String, id: String, amount: float) -> void:
	if island == "home" or id in GLOBAL:
		ProcessingInventory.write(state, id, AmountCompat.from_number(amount))
	else:
		state.economy.islands[island].inventory[id] = AmountCompat.from_number(amount).serialize()

static func reserved(state: GameState, island: String, id: String, catalog: Dictionary) -> float:
	var total := 0.0
	for route in state.economy.get("trips", {}):
		var trip: Dictionary = state.economy.trips[route]
		if ROUTES[route][1] == island and ROUTES[route][2] == id:
			total += float(trip.cargo)
	var job: Dictionary = state.economy.get("jobs", {}).get(island, {})
	if not job.is_empty() and int(job.remaining) > 0 and job.recipe_id == id:
		total += float(catalog.recipes[id].output)
	return total

static func free_space(state: GameState, island: String, id: String, catalog: Dictionary) -> float:
	var cap := float(catalog.resources[id].cap) if island == "home" else IslandProgression.capacity(state, island)
	return maxf(0, cap - value(state, island, id) - reserved(state, island, id, catalog))

static func _start(state: GameState, catalog: Dictionary, island: String, job: Dictionary) -> String:
	var recipe: Dictionary = catalog.recipes[job.recipe_id]
	if IslandProgression.active(state) and not IslandProgression.owns(state, island, job.recipe_id):
		return "RECIPE_ISLAND_REQUIREMENT"
	if state.era_id < int(recipe.era):
		return "ERA_REQUIREMENT"
	var facilities: Dictionary = state.buildings if island == "home" else ISLANDS[island].facility
	for facility in recipe.facility:
		if int(facilities.get(facility, 0)) < int(recipe.facility[facility]):
			return "FACILITY_REQUIREMENT"
	for id in recipe.inputs:
		if island == "home" or id in GLOBAL:
			var slot := ProcessingInventory.read(state, id)
			if not slot.ok:
				return slot.error
			if not slot.unlocked:
				return "RESOURCE_LOCKED"
		if value(state, island, id) - float(job.reserves.get(id, "0")) < float(recipe.inputs[id]):
			return "INSUFFICIENT_RESOURCE"
	if island == "home":
		var output_slot := ProcessingInventory.read(state, job.recipe_id)
		if not output_slot.ok:
			return output_slot.error
		if not output_slot.unlocked:
			return "RESOURCE_LOCKED"
	if free_space(state, island, job.recipe_id, catalog) < float(recipe.output):
		return "OUTPUT_FULL"
	for id in recipe.inputs:
		_put(state, island, id, value(state, island, id) - float(recipe.inputs[id]))
	job.remaining = IslandProgression.duration(state, island, job.recipe_id)
	job.batches = maxi(0, int(job.batches) - 1)
	job.status = "running"
	return ""

static func tick_prepared(state: GameState, catalog: Dictionary, prepared: Dictionary) -> Array:
	# Only reusable inside one command-free advance. A stationary economy has
	# no timers; its only external input is home stock (production/realm sinks).
	if prepared.has("idle_home") and _same_home(state, prepared.idle_home):
		state.economy.tick = int(state.economy.tick) + 1
		prepared.idle_ticks = int(prepared.get("idle_ticks", 0)) + 1
		return []
	prepared.erase("idle_home")
	var candidate: bool = state.economy.trips.is_empty()
	for job in state.economy.jobs.values():
		if int(job.remaining) > 0:
			candidate = false
			break
	var before := {}
	var home: Array = []
	if candidate:
		before = state.economy.duplicate(true)
		before.erase("tick")
		home = _home_values(state)
	var events := tick(state, catalog)
	if candidate and events.is_empty() and _same_home(state, home):
		# Compare all saved island fields, including status/pending switches and
		# string normalization. No timer or speculative capacity assumption.
		var after := state.economy.duplicate(true)
		after.erase("tick")
		if before == after:
			prepared.idle_home = home
	return events

static func _home_values(state: GameState) -> Array:
	var result: Array = []
	for id in state.resources:
		# Tick systems retain each resource entry and replace only its Amount.
		# Holding the entry avoids repeated resource-ID hash lookups every tick.
		result.append([state.resources[id], state.resources[id].value])
	return result

static func _same_home(state: GameState, values: Array) -> bool:
	# Amount operations replace values; they never mutate held Amount objects.
	if state.resources.size() != values.size():
		return false
	for pair in values:
		if pair[0].value != pair[1]:
			return false
	return true

static func tick(state: GameState, catalog: Dictionary) -> Array:
	var events: Array = []
	state.economy.tick = int(state.economy.tick) + 1
	# Stable order: production (legacy + local), arrivals, completions, jobs, departures.
	for island in ISLANDS:
		if island == "home" or not state.economy.islands[island].opened:
			continue
		for id in ISLANDS[island].rates:
			var multiplier := int(state.economy.islands[island].facilities.extractor) if IslandProgression.active(state) else 1
			var rate := float(ISLANDS[island].rates[id]) * multiplier
			var delta := minf(rate, free_space(state, island, id, catalog))
			_put(state, island, id, value(state, island, id) + delta)
	var routes: Array = state.economy.trips.keys()
	routes.sort()
	for id in routes:
		var trip: Dictionary = state.economy.trips[id]
		trip.remaining = int(trip.remaining) - 1
		if int(trip.remaining) == 0:
			var def: Array = ROUTES[id]
			_put(state, def[1], def[2], value(state, def[1], def[2]) + float(trip.cargo))
			state.economy.trips.erase(id)
			events.append({"kind": "cargo_arrived", "route_id": id})
	var islands: Array = state.economy.jobs.keys()
	islands.sort()
	for island in islands:
		var job: Dictionary = state.economy.jobs[island]
		if int(job.remaining) <= 0:
			continue
		job.remaining = int(job.remaining) - 1
		if int(job.remaining) == 0:
			var id: String = job.recipe_id
			_put(state, island, id, value(state, island, id) + float(catalog.recipes[id].output))
			events.append({"kind": "processing_completed", "island_id": island, "recipe_id": id})
	for island in islands:
		var job: Dictionary = state.economy.jobs[island]
		if int(job.remaining) > 0:
			continue
		if job.has("pending"):
			job = job.pending
			state.economy.jobs[island] = job
		if int(job.batches) == 0 and not job.repeat:
			state.economy.jobs.erase(island)
			continue
		var error := _start(state, catalog, island, job)
		job.status = error if not error.is_empty() else "running"
	routes = state.economy.routes.keys()
	routes.sort()
	for id in routes:
		var route: Dictionary = state.economy.routes[id]
		if not route.enabled or state.economy.trips.has(id):
			continue
		var def: Array = ROUTES[id]
		var available := maxf(0, value(state, def[0], def[2]) - float(route.reserve))
		var need := maxf(0, float(route.target) - value(state, def[1], def[2]) - reserved(state, def[1], def[2], catalog))
		var cargo := minf(minf(available, need), minf(10.0 * int(route.level), free_space(state, def[1], def[2], catalog)))
		if cargo > 0:
			_put(state, def[0], def[2], value(state, def[0], def[2]) - cargo)
			state.economy.trips[id] = {"version": 1, "cargo": AmountCompat.from_number(cargo).serialize(), "remaining": 10}
			events.append({"kind": "cargo_departed", "route_id": id})
	return events

static func view(state: GameState, catalog: Dictionary) -> Dictionary:
	if state.economy.is_empty():
		return {}
	var result := state.economy.duplicate(true)
	result.inventory = {}
	for island in ISLANDS:
		result.inventory[island] = {}
		for id in catalog.resources:
			if island != "home" and id in GLOBAL:
				continue
			result.inventory[island][id] = {"available": value(state, island, id), "reserved": reserved(state, island, id, catalog)}
	return result

static func reincarnation_preview(state: GameState) -> Dictionary:
	return {"cleared": ["island openings", "local inventories", "jobs and consumed inputs", "cargo and reservations"], "inheritance": "existing capacity-based grant once; no refund or sum of cargo", "economy_was_enabled": not state.economy.is_empty()}

static func validate(state: GameState) -> String:
	var e := state.economy
	if e.is_empty():
		return ""
	if not e.get("version") in [VERSION, IslandProgression.VERSION, IslandProgression.LEGACY_VERSION] or not _integer(e.get("tick"), 0, 2000000000):
		return "ECONOMY_VERSION_OR_TICK"
	for key in ["islands", "jobs", "routes", "trips"]:
		if not e.get(key) is Dictionary:
			return "ECONOMY_FIELD:" + key
	if e.islands.size() != ISLANDS.size() or e.jobs.size() > ISLANDS.size() or e.routes.size() > ROUTES.size() or e.trips.size() > ROUTES.size():
		return "ECONOMY_LIMIT"
	var loaded := ProcessingCatalog.load_file()
	if not loaded.ok:
		return "ECONOMY_CONTENT"
	var catalog: Dictionary = loaded.catalog
	for id in catalog.resources:
		if not ProcessingInventory.read(state, id).ok:
			return "ECONOMY_RESOURCE:" + id
	for island in ISLANDS:
		var slot: Variant = e.islands.get(island)
		if not slot is Dictionary or not slot.get("opened") is bool or not slot.get("inventory") is Dictionary:
			return "ECONOMY_ISLAND"
		if IslandProgression.active(state):
			if not slot.get("facilities") is Dictionary or slot.facilities.size() != 3:
				return "ECONOMY_FACILITIES"
			for facility in IslandProgression.FACILITIES:
				if not _integer(slot.facilities.get(facility), 1, 3):
					return "ECONOMY_FACILITY_LEVEL"
				if (island == "home" or not slot.opened) and int(slot.facilities[facility]) != 1:
					return "ECONOMY_CLOSED_FACILITY"
			if island == "herb" and slot.opened and e.version == IslandProgression.LEGACY_VERSION:
				return "ECONOMY_FUTURE_ISLAND"
		if island == "home" and (not slot.opened or not slot.inventory.is_empty()):
			return "ECONOMY_HOME_ALIAS"
		if not slot.opened and not slot.inventory.is_empty():
			return "ECONOMY_CLOSED_INVENTORY"
		for id in slot.inventory:
			if id in GLOBAL or not catalog.resources.has(id) or not _amount(slot.inventory[id]) or float(slot.inventory[id]) > IslandProgression.capacity(state, island):
				return "ECONOMY_LOCAL_AMOUNT"
	for island in e.jobs:
		var job: Variant = e.jobs[island]
		if not ISLANDS.has(island) or not e.islands[island].opened or not job is Dictionary:
			return "ECONOMY_JOB"
		var id: Variant = job.get("recipe_id")
		if not id is String or not DURATIONS.has(id) or job.get("recipe_version") != 1:
			return "ECONOMY_RECIPE_VERSION"
		if IslandProgression.active(state) and not IslandProgression.owns(state, island, id):
			return "ECONOMY_RECIPE_ISLAND"
		if not _integer(job.get("remaining"), 0, DURATIONS[id]) or not _integer(job.get("batches"), 0, 1000000) or not job.get("repeat") is bool or not job.get("status") is String or not job.get("reserves") is Dictionary:
			return "ECONOMY_JOB_FIELDS"
		for resource in job.reserves:
			if not catalog.recipes[id].inputs.has(resource) or not _amount(job.reserves[resource]):
				return "ECONOMY_JOB_RESERVE"
		if job.has("pending"):
			var pending: Variant = job.pending
			if not pending is Dictionary or pending.has("pending") or pending.get("remaining") != 0:
				return "ECONOMY_PENDING_JOB"
			var trial := state.duplicate_state()
			trial.economy.jobs[island] = pending
			# Remove other pending jobs to keep the structural check bounded/nonrecursive.
			for other in trial.economy.jobs:
				trial.economy.jobs[other].erase("pending")
			var pending_error := validate(trial)
			if not pending_error.is_empty():
				return pending_error
	for id in e.routes:
		var route: Variant = e.routes[id]
		if not ROUTES.has(id) or not route is Dictionary:
			return "ECONOMY_ROUTE"
		if not route.get("enabled") is bool or not _amount(route.get("reserve")) or not _amount(route.get("target")) or not _integer(route.get("level"), 1, 2):
			return "ECONOMY_ROUTE_FIELDS"
		if not e.islands[ROUTES[id][0]].opened or not e.islands[ROUTES[id][1]].opened:
			return "ECONOMY_CLOSED_ROUTE"
	for id in e.trips:
		var trip: Variant = e.trips[id]
		if not e.routes.has(id) or not trip is Dictionary or trip.get("version") != 1:
			return "ECONOMY_TRIP_VERSION"
		if not _integer(trip.get("remaining"), 1, 10) or not _amount(trip.get("cargo")) or float(trip.cargo) <= 0 or float(trip.cargo) > 20:
			return "ECONOMY_TRIP_FIELDS"
	for island in ISLANDS:
		for id in catalog.resources:
			if island != "home" and id in GLOBAL:
				continue
			var held := reserved(state, island, id, catalog)
			var cap := float(catalog.resources[id].cap) if island == "home" else IslandProgression.capacity(state, island)
			# Existing home stock may exceed the B prototype cap, but no new reservation may.
			if held > 0 and value(state, island, id) + held > cap:
				return "ECONOMY_RESERVATION_OVERFLOW"
	return ""

static func _integer(v: Variant, low: int, high: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and float(v) >= low and float(v) <= high

static func _amount(v: Variant) -> bool:
	if not v is String:
		return false
	var a := AmountCompat.try_parse(v)
	return a.ok and a.value.layer == 0 and a.value.sign >= 0 and a.value.mag <= 1e12

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "events": [], "changed_ids": []}

static func _success(kind: String) -> Dictionary:
	return {"ok": true, "events": [{"kind": kind}], "changed_ids": ["economy", "resources"]}
