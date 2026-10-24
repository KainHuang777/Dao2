class_name IslandEconomy
extends RefCounted
## RES1-B opt-in rules. Home inventory aliases resources, never copies it.
## All quantities use the RES1-A layer-zero <= 1e12 Amount contract.

const VERSION := "res1-b-1"
const Supply = preload("res://src/content/supply_content.gd")
static var _supply: Dictionary = {}
static var _islands: Dictionary = {}
static var _routes: Dictionary = {}
static var _durations: Dictionary = {}

static func supply_data() -> Dictionary:
	if _supply.is_empty():
		_supply = Supply.load_file().get("data", {})
	return _supply

static func expanded(state: GameState) -> bool:
	return state.economy.get("version") == Supply.VERSION

static func island_defs(state: GameState) -> Dictionary:
	if not expanded(state): return ISLANDS
	if _islands.is_empty():
		_islands = ISLANDS.duplicate(true)
		for id in supply_data().islands:
			_islands[id] = supply_data().islands[id].duplicate(true)
			_islands[id].facility = {}
	return _islands

static func route_defs(state: GameState) -> Dictionary:
	if not expanded(state): return ROUTES
	if _routes.is_empty():
		_routes = ROUTES.duplicate(true)
		_routes.merge(supply_data().routes)
	return _routes

static func durations(state: GameState) -> Dictionary:
	if not expanded(state): return DURATIONS
	if _durations.is_empty():
		_durations = DURATIONS.duplicate()
		_durations.merge(supply_data().durations)
	return _durations

static func route_level_cap(state: GameState, id: String) -> int:
	return 3 if expanded(state) and supply_data().routes.has(id) else 2

static func rate(state: GameState, island: String, id: String) -> float:
	if expanded(state) and supply_data().islands.has(island):
		var focus: String = supply_data().dispatch[island]
		return float(supply_data().islands[island].rates.get(id, 0)) * (2.0 if int(state.buildings.get(focus, 0)) > 0 else 1.0) * SksP2Rules.local_rate_multiplier(island, state.skills)
	return float(ISLANDS[island].rates.get(id, 0)) * (int(state.economy.islands[island].facilities.extractor) if IslandProgression.active(state) else 1)

static func home_cap(state: GameState, id: String, catalog: Dictionary) -> float:
	var cap := float(catalog.resources[id].cap)
	# Existing profiles retain their original fixed processing caps.
	if expanded(state):
		var copy := GameState.new()
		copy.beasts = state.beasts.duplicate(true)
		copy.beast_talents = state.beast_talents.duplicate(true)
		copy.chrono = state.chrono.duplicate(true)
		copy.total_elapsed_seconds = state.total_elapsed_seconds
		copy.era_id = state.era_id
		copy.sect = state.sect
		var caps := Production.compute_caps(Supply.runtime_content(), state.buildings, state.era_id, state.onboarding_version, state.skills)
		if caps.has(id): cap = caps[id].to_float()
		var beast := BeastSystem.compute_multipliers(copy)
		var bonus := float(beast.all_capacity_mult) + float(SectSystem.compute_multipliers(copy).storage_bonus) + float(ChronoSystem.compute_multipliers(copy).storage_bonus)
		if id in ["stone_low", "refined_iron"]: bonus += float(beast.cap_stone_iron)
		cap *= 1.0 + bonus
	return floor(cap)
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
		if content.processing_catalog.get("version") == Supply.VERSION:
			state.economy.version = Supply.VERSION
			for id in state.economy.islands:
				state.economy.islands[id].facilities = {"extractor": 1, "workshop": 1, "storage": 1}
			for id in supply_data().islands:
				state.economy.islands[id] = {"opened": false, "inventory": {}}
		return _success("economy_migrated")
	if state.economy.is_empty():
		return _fail("ECONOMY_NOT_MIGRATED")
	if IslandProgression.active(state) and state.era_id < 2:
		return _fail("ERA_REQUIREMENT")
	var island: Variant = p.get("island_id", "home")
	if not island is String or not island_defs(state).has(island):
		return _fail("UNKNOWN_ISLAND")
	if kind == "open_island":
		if state.economy.get("version") == IslandProgression.LEGACY_VERSION and island == "herb":
			return _fail("ERA_REQUIREMENT")
		if state.economy.islands[island].opened:
			return _fail("ISLAND_ALREADY_OPEN")
		if state.era_id < int(island_defs(state)[island].era):
			return _fail("ERA_REQUIREMENT")
		var costs: Dictionary = island_defs(state)[island].get("cost", {"wood": 20, "stone_low": 10})
		for id in costs:
			if value(state, "home", id) < float(costs[id]): return _fail("INSUFFICIENT_RESOURCE")
		for id in costs:
			_put(state, "home", id, value(state, "home", id) - float(costs[id]), "building")
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
	if not id is String or not route_defs(state).has(id):
		return _fail("UNKNOWN_ROUTE")
	var def: Array = route_defs(state)[id]
	if not state.economy.islands[def[0]].opened or not state.economy.islands[def[1]].opened:
		return _fail("ISLAND_NOT_OPEN")
	var enabled: Variant = p.get("enabled", true)
	var reserve: Variant = p.get("reserve", "0")
	var target: Variant = p.get("target", "100")
	var level: Variant = p.get("level", 1)
	if not enabled is bool or not _amount(reserve) or not _amount(target) or not _integer(level, 1, route_level_cap(state, id)):
		return _fail("INVALID_ROUTE_SETTINGS")
	var old: Dictionary = state.economy.routes.get(id, {"level": 1})
	if int(level) < int(old.level):
		return _fail("ROUTE_LEVEL_DOWNGRADE")
	if int(level) > int(old.level):
		var costs := route_upgrade_cost(state, int(level) - int(old.level))
		for resource in costs:
			if value(state, "home", resource) < float(costs[resource]):
				return _fail("INSUFFICIENT_RESOURCE")
		for resource in costs:
			_put(state, "home", resource, value(state, "home", resource) - float(costs[resource]), "building")
	# Current trip keeps its cargo and duration; settings only affect the next departure.
	state.economy.routes[id] = {"enabled": enabled, "reserve": reserve, "target": target, "level": int(level)}
	return _success("route_configured")

static func value(state: GameState, island: String, id: String) -> float:
	if island == "home" or id in GLOBAL:
		if not state.resources.has(id):
			return 0.0
		return state.resources[id].value.to_float()
	return float(state.economy.islands[island].inventory.get(id, "0"))

static func _put(state: GameState, island: String, id: String, amount: float, category: String = "processing", nominal: float = 0.0) -> void:
	var scope := "home" if island == "home" or id in GLOBAL else island
	var before := AmountCompat.from_number(value(state, island, id))
	var observed := AmountCompat.from_number(amount)
	if scope != "home": observed = ResourceLedger.amount(observed.serialize())
	ResourceLedger.change(state, scope, id, before, observed, category, AmountCompat.from_number(nominal) if nominal != 0 else null)
	if island == "home" or id in GLOBAL:
		ProcessingInventory.write(state, id, AmountCompat.from_number(amount), "untracked")
	else:
		state.economy.islands[island].inventory[id] = AmountCompat.from_number(amount).serialize()

static func reserved(state: GameState, island: String, id: String, catalog: Dictionary) -> float:
	var total := 0.0
	for route in state.economy.get("trips", {}):
		var trip: Dictionary = state.economy.trips[route]
		if route_defs(state)[route][1] == island and route_defs(state)[route][2] == id:
			total += float(trip.cargo)
	var job: Dictionary = state.economy.get("jobs", {}).get(island, {})
	if not job.is_empty() and int(job.remaining) > 0 and ProcessingCatalog.product_id(catalog, job.recipe_id) == id:
		total += float(catalog.recipes[job.recipe_id].output)
	return total

static func free_space(state: GameState, island: String, id: String, catalog: Dictionary) -> float:
	var cap := home_cap(state, id, catalog) if island == "home" else IslandProgression.capacity(state, island)
	return maxf(0, cap - value(state, island, id) - reserved(state, island, id, catalog))

static func effective_inputs(state: GameState, catalog: Dictionary, island: String, recipe_id: String) -> Dictionary:
	var result := {}
	for id in catalog.recipes[recipe_id].inputs:
		result[id] = SksP2Rules.discounted_amount(recipe_id, island, String(id), String(catalog.recipes[recipe_id].inputs[id]), state.skills)
	return result

static func _start(state: GameState, catalog: Dictionary, island: String, job: Dictionary) -> String:
	var error := _check_start(state, catalog, island, job)
	if not error.is_empty():
		return error
	var inputs := effective_inputs(state, catalog, island, String(job.recipe_id))
	for id in inputs:
		_put(state, island, id, value(state, island, id) - float(inputs[id]))
	job.remaining = IslandProgression.duration(state, island, job.recipe_id)
	job.batches = maxi(0, int(job.batches) - 1)
	job.status = "running"
	return ""

static func _check_start(state: GameState, catalog: Dictionary, island: String, job: Dictionary) -> String:
	# Shared read-only eligibility: presentation and execution use the same gates.
	var recipe: Dictionary = catalog.recipes[job.recipe_id]
	if IslandProgression.active(state) and not IslandProgression.owns(state, island, job.recipe_id):
		return "RECIPE_ISLAND_REQUIREMENT"
	if state.era_id < int(recipe.era):
		return "ERA_REQUIREMENT"
	var facilities: Dictionary = state.buildings if island == "home" else island_defs(state)[island].facility
	for facility in recipe.facility:
		if int(facilities.get(facility, 0)) < int(recipe.facility[facility]):
			return "FACILITY_REQUIREMENT"
	var inputs := effective_inputs(state, catalog, island, job.recipe_id)
	for id in recipe.inputs:
		if island == "home" or id in GLOBAL:
			var slot := ProcessingInventory.read(state, id)
			if not slot.ok:
				return slot.error
			if not slot.unlocked:
				return "RESOURCE_LOCKED"
		if value(state, island, id) - float(job.reserves.get(id, "0")) < float(inputs[id]):
			return "INSUFFICIENT_RESOURCE"
	if island == "home":
		var output_slot := ProcessingInventory.read(state, ProcessingCatalog.product_id(catalog, job.recipe_id))
		if not output_slot.ok:
			return output_slot.error
		if not output_slot.unlocked:
			return "RESOURCE_LOCKED"
	if free_space(state, island, ProcessingCatalog.product_id(catalog, job.recipe_id), catalog) < float(recipe.output):
		return "OUTPUT_FULL"
	return ""

static func manufacturing_view(state: GameState, catalog: Dictionary) -> Dictionary:
	var result := {"recipes": {}, "islands": {}}
	if catalog.is_empty():
		return result
	var active := IslandProgression.active(state) and state.era_id >= 2
	for island in island_defs(state):
		var opened: bool = active and bool(state.economy.get("islands", {}).get(island, {}).get("opened", false))
		var facilities: Dictionary = state.economy.get("islands", {}).get(island, {}).get("facilities", {})
		var level := int(facilities.get("extractor", 1))
		var rates := {}
		for id in island_defs(state)[island].rates:
			rates[id] = rate(state, island, id) if opened else 0.0
		result.islands[island] = {"opened": opened, "capacity": IslandProgression.capacity(state, island) if active else 100.0, "rates": rates}
	for id in catalog.recipes:
		var island := "home"
		for owner in IslandProgression.RECIPES:
			if IslandProgression.RECIPES[owner] == id:
				island = owner
		# Era2's approved home recipe must be reachable through the same UI
		# contract as commands; Danxia becomes the default owner at Era3.
		if id == "liquid" and state.era_id == 2:
			island = "home"
		var recipe: Dictionary = catalog.recipes[id]
		var reason := "ECONOMY_NOT_MIGRATED"
		if active:
			if not result.islands[island].opened:
				reason = "ISLAND_NOT_OPEN"
			else:
				reason = _check_start(state, catalog, island, {"recipe_id": id, "reserves": {}})
		var inputs := {}
		var effective := effective_inputs(state, catalog, island, id)
		for resource in recipe.inputs:
			inputs[resource] = {"available": value(state, island, resource) if island == "home" or resource in GLOBAL or active else 0.0, "required": float(effective[resource]), "source": "home" if resource in GLOBAL else island}
		var duration: int = durations(state).get(id, supply_data().durations.get(id, 1))
		result.recipes[id] = {"island": island, "duration": IslandProgression.duration(state, island, id) if active and durations(state).has(id) else duration, "reason": reason, "inputs": inputs, "output": float(recipe.output), "product_id": ProcessingCatalog.product_id(catalog, id), "capacity": home_cap(state, ProcessingCatalog.product_id(catalog, id), catalog) if island == "home" else result.islands[island].capacity}
	return result

static func tick_prepared(state: GameState, catalog: Dictionary, prepared: Dictionary) -> Array:
	# Only reusable inside one command-free advance. A stationary economy has
	# no timers; its only external input is home stock (production/realm sinks).
	if prepared.has("idle_home") and _same_home(state, prepared.idle_home):
		state.economy.tick = int(state.economy.tick) + 1
		for island in island_defs(state):
			if island == "home" or not state.economy.islands[island].opened: continue
			for id in island_defs(state)[island].rates:
				var rate := rate(state, island, id)
				var held := AmountCompat.from_number(value(state, island, id))
				ResourceLedger.change(state, island, id, held, held, "production", AmountCompat.from_number(rate))
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
	for island in island_defs(state):
		if island == "home" or not state.economy.islands[island].opened:
			continue
		for id in island_defs(state)[island].rates:
			var rate := rate(state, island, id)
			var delta := minf(rate, free_space(state, island, id, catalog))
			_put(state, island, id, value(state, island, id) + delta, "production", rate)
	var routes: Array = state.economy.trips.keys()
	routes.sort()
	for id in routes:
		var trip: Dictionary = state.economy.trips[id]
		trip.remaining = int(trip.remaining) - 1
		if int(trip.remaining) == 0:
			var def: Array = route_defs(state)[id]
			var story_before := IslandEconomy.value(state, def[1], def[2])
			_put(state, def[1], def[2], value(state, def[1], def[2]) + float(trip.cargo), "transfer", float(trip.cargo))
			StoryProgress.arrived(state, id, IslandEconomy.value(state, def[1], def[2]) - story_before)
			Onboarding.supply_arrived(state, id, float(trip.cargo))
			state.economy.trips.erase(id)
			LifeLedger.cargo_arrived(state, String(id))
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
			var product := ProcessingCatalog.product_id(catalog, id)
			_put(state, island, product, value(state, island, product) + float(catalog.recipes[id].output))
			StoryProgress.completed(state, island, id)
			Onboarding.supply_completed(state, island, id)
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
		var def: Array = route_defs(state)[id]
		var cargo: float = departure_info(state, catalog, id, route).cargo
		if cargo > 0:
			_put(state, def[0], def[2], value(state, def[0], def[2]) - cargo, "transfer", -cargo)
			state.economy.trips[id] = {"version": 1, "cargo": AmountCompat.from_number(cargo).serialize(), "remaining": 10}
			events.append({"kind": "cargo_departed", "route_id": id})
	return events

static func departure_info(state: GameState, catalog: Dictionary, id: String, route: Dictionary) -> Dictionary:
	# Shared read-only departure calculation: UI waiting reasons use the actual gate.
	var def: Array = route_defs(state)[id]
	var source := value(state, def[0], def[2])
	var destination := value(state, def[1], def[2])
	var reservation := reserved(state, def[1], def[2], catalog)
	var surplus := maxf(0, source - float(route.reserve))
	var need := maxf(0, float(route.target) - destination - reservation)
	var space := free_space(state, def[1], def[2], catalog)
	var throughput := 10.0 * int(route.level)
	return {"source": source, "destination": destination, "reserved": reservation, "surplus": surplus, "need": need, "space": space, "throughput": throughput, "cargo": minf(minf(surplus, need), minf(throughput, space))}

static func transport_view(state: GameState, catalog: Dictionary) -> Dictionary:
	var result := {}
	# Potential routes remain inspectable before opt-in; commands still use state.
	var definitions := route_defs(state).duplicate(true)
	var supply_profile: bool = catalog.get("version") == Supply.VERSION
	if supply_profile: definitions.merge(supply_data().routes)
	for id in definitions:
		var def: Array = definitions[id]
		var route: Dictionary = state.economy.get("routes", {}).get(id, {"enabled": false, "reserve": "0", "target": "100", "level": 1})
		var trip: Dictionary = state.economy.get("trips", {}).get(id, {})
		var closed: Array[String] = []
		for endpoint in [def[0], def[1]]:
			if not bool(state.economy.get("islands", {}).get(endpoint, {}).get("opened", false)):
				closed.append(endpoint)
		var reason := ""
		var info := {}
		if state.economy.is_empty():
			reason = "ECONOMY_NOT_MIGRATED"
		elif not closed.is_empty():
			reason = "ISLAND_NOT_OPEN"
		else:
			info = departure_info(state, catalog, id, route)
			if not trip.is_empty():
				reason = "IN_TRANSIT"
			elif not bool(route.enabled):
				reason = "STOPPED"
			elif info.space <= 0:
				reason = "DESTINATION_FULL"
			elif info.need <= 0:
				reason = "TARGET_REACHED"
			elif info.surplus <= 0:
				reason = "NO_SURPLUS"
			else:
				reason = "READY"
		# An actual full load plus remaining supply/demand supports a capacity hint.
		var loaded_backlog := not info.is_empty() and bool(route.enabled) and not trip.is_empty() and float(trip.cargo) >= float(info.throughput) and float(info.surplus) > 0 and float(info.need) > 0 and float(info.space) > 0
		result[id] = {"level_cap": 3 if supply_profile and supply_data().routes.has(id) else route_level_cap(state, id), "upgrade_cost": route_upgrade_cost(state, 1, supply_profile), "settings": route.duplicate(true), "trip": trip.duplicate(true), "closed": closed, "ready": reason not in ["ECONOMY_NOT_MIGRATED", "ISLAND_NOT_OPEN"], "reason": reason, "stock": info, "loaded_backlog": loaded_backlog}
	return result

static func view(state: GameState, catalog: Dictionary) -> Dictionary:
	if state.economy.is_empty():
		return {}
	var result := state.economy.duplicate(true)
	result.inventory = {}
	for island in island_defs(state):
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
	if e.has("early_supply") and not Onboarding.validate_supply(e.early_supply):
		return "ECONOMY_EARLY_SUPPLY"
	if not e.get("version") in [VERSION, IslandProgression.VERSION, IslandProgression.LEGACY_VERSION, Supply.VERSION] or not _integer(e.get("tick"), 0, 2000000000):
		return "ECONOMY_VERSION_OR_TICK"
	for key in ["islands", "jobs", "routes", "trips"]:
		if not e.get(key) is Dictionary:
			return "ECONOMY_FIELD:" + key
	if e.islands.size() != island_defs(state).size() or e.jobs.size() > island_defs(state).size() or e.routes.size() > route_defs(state).size() or e.trips.size() > route_defs(state).size():
		return "ECONOMY_LIMIT"
	var loaded := Supply.load_file() if expanded(state) else ProcessingCatalog.load_file()
	if not loaded.ok:
		return "ECONOMY_CONTENT"
	var catalog: Dictionary = loaded.catalog
	for id in catalog.resources:
		if not ProcessingInventory.read(state, id).ok:
			return "ECONOMY_RESOURCE:" + id
	for island in island_defs(state):
		var slot: Variant = e.islands.get(island)
		if not slot is Dictionary or not slot.get("opened") is bool or not slot.get("inventory") is Dictionary:
			return "ECONOMY_ISLAND"
		if IslandProgression.active(state) and not supply_data().islands.has(island):
			if not slot.get("facilities") is Dictionary or slot.facilities.size() != 3:
				return "ECONOMY_FACILITIES"
			for facility in IslandProgression.FACILITIES:
				if not _integer(slot.facilities.get(facility), 1, 3):
					return "ECONOMY_FACILITY_LEVEL"
				if (island == "home" or not slot.opened) and int(slot.facilities[facility]) != 1:
					return "ECONOMY_CLOSED_FACILITY"
			if island == "herb" and slot.opened and e.version == IslandProgression.LEGACY_VERSION:
				return "ECONOMY_FUTURE_ISLAND"
		if expanded(state) and supply_data().islands.has(island) and slot.size() != 2:
			return "ECONOMY_NEW_ISLAND_FIELDS"
		if island == "home" and (not slot.opened or not slot.inventory.is_empty()):
			return "ECONOMY_HOME_ALIAS"
		if not slot.opened and not slot.inventory.is_empty():
			return "ECONOMY_CLOSED_INVENTORY"
		for id in slot.inventory:
			if id in GLOBAL or not catalog.resources.has(id) or not _amount(slot.inventory[id]) or float(slot.inventory[id]) > IslandProgression.capacity(state, island):
				return "ECONOMY_LOCAL_AMOUNT"
	for island in e.jobs:
		var job: Variant = e.jobs[island]
		if not island_defs(state).has(island) or not e.islands[island].opened or not job is Dictionary:
			return "ECONOMY_JOB"
		var id: Variant = job.get("recipe_id")
		if not id is String or not durations(state).has(id) or job.get("recipe_version") != 1:
			return "ECONOMY_RECIPE_VERSION"
		if IslandProgression.active(state) and not IslandProgression.owns(state, island, id):
			return "ECONOMY_RECIPE_ISLAND"
		if not _integer(job.get("remaining"), 0, durations(state)[id]) or not _integer(job.get("batches"), 0, 1000000) or not job.get("repeat") is bool or not job.get("status") is String or not job.get("reserves") is Dictionary:
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
		if not route_defs(state).has(id) or not route is Dictionary:
			return "ECONOMY_ROUTE"
		if not route.get("enabled") is bool or not _amount(route.get("reserve")) or not _amount(route.get("target")) or not _integer(route.get("level"), 1, route_level_cap(state, id)):
			return "ECONOMY_ROUTE_FIELDS"
		if not e.islands[route_defs(state)[id][0]].opened or not e.islands[route_defs(state)[id][1]].opened:
			return "ECONOMY_CLOSED_ROUTE"
	for id in e.trips:
		var trip: Variant = e.trips[id]
		if not e.routes.has(id) or not trip is Dictionary or trip.get("version") != 1:
			return "ECONOMY_TRIP_VERSION"
		if not _integer(trip.get("remaining"), 1, 10) or not _amount(trip.get("cargo")) or float(trip.cargo) <= 0 or float(trip.cargo) > 10 * route_level_cap(state, id):
			return "ECONOMY_TRIP_FIELDS"
	for island in island_defs(state):
		for id in catalog.resources:
			if island != "home" and id in GLOBAL:
				continue
			var held := reserved(state, island, id, catalog)
			var cap := home_cap(state, id, catalog) if island == "home" else IslandProgression.capacity(state, island)
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

static func route_upgrade_cost(state: GameState, steps: int = 1, progression_profile: bool = false) -> Dictionary:
	var costs := {"spirit_timber": 10, "bronze_essence": 10} if IslandProgression.active(state) or progression_profile else {"wood": 20}
	for id in costs: costs[id] *= steps
	return costs
