class_name OfflineEconomyJump
extends RefCounted

const VALID_VERSIONS := ["res1-b-1", "res1-d-2", "res1-c-1"]

static func advance(state: GameState, content: GameContent, ticks: int, prepared: Dictionary) -> Dictionary:
	var catalog: Dictionary = content.processing_catalog
	var error := _structure_error(state, catalog)
	if not error.is_empty() or not _integer_invariants(state, catalog):
		if ticks <= 0:
			return {"unsupported": true, "reason": error if not error.is_empty() else "invariants"}
		var events: Array = []
		for _i in range(ticks):
			events.append_array(IslandEconomy.tick(state, catalog))
		return {"events": events, "exact": true}
	if ticks <= 0:
		return {"events": [], "exact": true}
	var events: Array = []
	var left := ticks
	while left > 0:
		var k := _next_event_offset(state, catalog, left)
		if k > 1:
			_jump(state, catalog, k - 1)
			_countdown(state, k - 1)
			left -= k - 1
		var lean: Variant = _lean_tick(state, catalog)
		if lean is Array:
			events.append_array(lean as Array)
		else:
			events.append_array(IslandEconomy.tick(state, catalog))
		left -= 1
	return {"events": events, "exact": true}

static func next_home_boundary(state: GameState, content: GameContent, prepared: Dictionary, horizon: int) -> int:
	if horizon <= 0:
		return -1
	var catalog: Dictionary = content.processing_catalog
	if state.economy.is_empty() or catalog.is_empty():
		return -1
	var best := -1
	for route_id in state.economy.trips:
		var trip: Dictionary = state.economy.trips[route_id]
		if IslandEconomy.route_defs(state).has(route_id) and String(IslandEconomy.route_defs(state)[route_id][1]) == "home":
			best = _min_offset(best, int(trip.remaining), horizon)
	var home_job: Dictionary = state.economy.jobs.get("home", {})
	if not home_job.is_empty():
		if int(home_job.remaining) > 0:
			best = _min_offset(best, int(home_job.remaining), horizon)
		else:
			var hcand := _job_retry_offset(state, catalog, "home", home_job, horizon)
			if hcand >= 1:
				best = _min_offset(best, hcand, horizon)
	for route_id in state.economy.routes:
		var route: Dictionary = state.economy.routes[route_id]
		if not IslandEconomy.route_defs(state).has(route_id) or not bool(route.enabled) or state.economy.trips.has(route_id):
			continue
		var def: Array = IslandEconomy.route_defs(state)[route_id]
		if String(def[1]) != "home":
			continue
		var info := IslandEconomy.departure_info(state, catalog, route_id, route)
		if float(info.cargo) > 0.0:
			best = _min_offset(best, 1, horizon)
			continue
		if float(info.need) <= 0.0 or float(info.space) <= 0.0 or float(info.throughput) <= 0.0:
			continue
		var cross := _surplus_crossing(state, catalog, String(def[0]), String(def[2]), float(route.reserve), horizon)
		if cross >= 1:
			best = _min_offset(best, cross, horizon)
	return best

static func _min_offset(current: int, candidate: int, horizon: int) -> int:
	var clamped := mini(maxi(candidate, 1), horizon)
	if current < 0 or clamped < current:
		return clamped
	return current

static func _next_event_offset(state: GameState, catalog: Dictionary, cap: int) -> int:
	var best := cap
	for route_id in state.economy.trips:
		best = _min_offset(best, int(state.economy.trips[route_id].remaining), cap)
	for island in state.economy.jobs:
		var job: Dictionary = state.economy.jobs[island]
		if int(job.remaining) > 0:
			best = _min_offset(best, int(job.remaining), cap)
		elif int(job.batches) > 0 or bool(job.repeat):
			var cand := _job_retry_offset(state, catalog, String(island), job, cap)
			if cand >= 1:
				best = _min_offset(best, cand, cap)
	for route_id in state.economy.routes:
		var route: Dictionary = state.economy.routes[route_id]
		if not IslandEconomy.route_defs(state).has(route_id) or not bool(route.enabled) or state.economy.trips.has(route_id):
			continue
		var info := IslandEconomy.departure_info(state, catalog, route_id, route)
		if float(info.cargo) > 0.0:
			return 1
		if float(info.need) <= 0.0 or float(info.space) <= 0.0 or float(info.throughput) <= 0.0:
			continue
		var def: Array = IslandEconomy.route_defs(state)[route_id]
		var cross := _surplus_crossing(state, catalog, String(def[0]), String(def[2]), float(route.reserve), cap)
		if cross >= 1:
			best = _min_offset(best, cross, cap)
	return best

static func _surplus_crossing(state: GameState, catalog: Dictionary, source: String, cargo_id: String, reserve: float, horizon: int) -> int:
	if source == "home" or cargo_id == "home":
		return -1
	var rates: Dictionary = IslandEconomy.island_defs(state).get(source, {}).get("rates", {})
	if not rates.has(cargo_id):
		return -1
	var multiplier := int(state.economy.islands[source].facilities.extractor) if IslandProgression.active(state) else 1
	var rate := float(rates[cargo_id]) * float(multiplier)
	if rate <= 0.0:
		return -1
	var v0 := IslandEconomy.value(state, source, cargo_id)
	var reserved_c := IslandEconomy.reserved(state, source, cargo_id, catalog)
	var cap := IslandProgression.capacity(state, source)
	if not _is_int(v0) or not _is_int(reserved_c) or not _is_int(cap):
		return -1
	var limit := cap - reserved_c
	var headroom := 9007199254740992.0
	if absf(v0) + rate * float(horizon) > headroom or absf(limit) > headroom:
		return -1
	for k in range(1, horizon + 1):
		var value_k := minf(v0 + rate * float(k), limit)
		if value_k - reserve > 0.0:
			return k
		if value_k >= limit and limit - reserve <= 0.0:
			return -1
	return -1

static func _jump(state: GameState, catalog: Dictionary, n: int) -> void:
	for island in IslandEconomy.island_defs(state):
		if island == "home" or not bool(state.economy.islands[island].opened):
			continue
		var extractor := int(state.economy.islands[island].facilities.extractor) if IslandProgression.active(state) else 1
		var cap := IslandProgression.capacity(state, island)
		for id in IslandEconomy.island_defs(state)[island].rates:
			var rate := float(IslandEconomy.island_defs(state)[island].rates[id]) * float(extractor)
			var v0 := IslandEconomy.value(state, island, id)
			var reserved_c := IslandEconomy.reserved(state, island, id, catalog)
			var target := minf(v0 + rate * float(n), cap - reserved_c)
			IslandEconomy._put(state, island, id, target, "production", rate * n)

static func _countdown(state: GameState, n: int) -> void:
	state.economy.tick = int(state.economy.tick) + n
	for route_id in state.economy.trips:
		state.economy.trips[route_id].remaining = int(state.economy.trips[route_id].remaining) - n
	for island in state.economy.jobs:
		var job: Dictionary = state.economy.jobs[island]
		if int(job.remaining) > 0:
			job.remaining = int(job.remaining) - n

static func _lean_tick(state: GameState, catalog: Dictionary) -> Variant:
	var fills: Array = []
	for island in IslandEconomy.island_defs(state):
		if island == "home" or not bool(state.economy.islands[island].opened):
			continue
		var extractor := int(state.economy.islands[island].facilities.extractor) if IslandProgression.active(state) else 1
		for id in IslandEconomy.island_defs(state)[island].rates:
			var rate := float(IslandEconomy.island_defs(state)[island].rates[id]) * float(extractor)
			var delta := minf(rate, IslandEconomy.free_space(state, island, id, catalog))
			if not _is_int(delta):
				return null
			fills.append([island, id, delta, rate])
	state.economy.tick = int(state.economy.tick) + 1
	for pair in fills:
		var island: String = pair[0]
		var id: String = pair[1]
		var delta: float = pair[2]
		IslandEconomy._put(state, island, id, IslandEconomy.value(state, island, id) + delta, "production", float(pair[3]))
	var events: Array = []
	var routes: Array = state.economy.trips.keys()
	routes.sort()
	for id in routes:
		var trip: Dictionary = state.economy.trips[id]
		trip.remaining = int(trip.remaining) - 1
		if int(trip.remaining) == 0:
			var def: Array = IslandEconomy.route_defs(state)[id]
			var cargo := float(trip.cargo)
			var story_before := IslandEconomy.value(state, def[1], def[2])
			IslandEconomy._put(state, def[1], def[2], IslandEconomy.value(state, def[1], def[2]) + cargo, "transfer", cargo)
			StoryProgress.arrived(state, id, IslandEconomy.value(state, def[1], def[2]) - story_before)
			Onboarding.supply_arrived(state, id, cargo)
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
			IslandEconomy._put(state, island, product, IslandEconomy.value(state, island, product) + float(catalog.recipes[id].output))
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
		var error := IslandEconomy._start(state, catalog, island, job)
		job.status = error if not error.is_empty() else "running"
	routes = state.economy.routes.keys()
	routes.sort()
	for id in routes:
		var route: Dictionary = state.economy.routes[id]
		if not route.enabled or state.economy.trips.has(id):
			continue
		var info := IslandEconomy.departure_info(state, catalog, id, route)
		var cargo := float(info.cargo)
		if cargo > 0:
			var def: Array = IslandEconomy.route_defs(state)[id]
			IslandEconomy._put(state, def[0], def[2], IslandEconomy.value(state, def[0], def[2]) - cargo, "transfer", -cargo)
			state.economy.trips[id] = {"version": 1, "cargo": AmountCompat.from_number(cargo).serialize(), "remaining": 10}
			events.append({"kind": "cargo_departed", "route_id": id})
	return events

static func _integer_invariants(state: GameState, catalog: Dictionary) -> bool:
	if catalog.is_empty():
		return false
	for island in IslandEconomy.island_defs(state):
		if island == "home" or not bool(state.economy.islands[island].opened):
			continue
		if IslandProgression.active(state):
			var facilities: Variant = state.economy.islands[island].get("facilities", {})
			var extractor: Variant = (facilities as Dictionary).get("extractor", 0) if facilities is Dictionary else 0
			if not _is_int(float(extractor)) or int(extractor) < 1:
				return false
		var cap := IslandProgression.capacity(state, island)
		if not _is_int(cap):
			return false
		for id in IslandEconomy.island_defs(state)[island].rates:
			if not _is_int(float(IslandEconomy.island_defs(state)[island].rates[id])):
				return false
			var parsed_inv := float(String(state.economy.islands[island].inventory.get(id, "0")))
			if not _is_int(parsed_inv):
				return false
		for id in state.economy.islands[island].inventory:
			if not _is_int(float(String(state.economy.islands[island].inventory[id]))):
				return false
	for route_id in state.economy.trips:
		var trip: Dictionary = state.economy.trips[route_id]
		if not _is_int(float(trip.cargo)):
			return false
	for route_id in state.economy.routes:
		var route: Dictionary = state.economy.routes[route_id]
		if not _is_int(float(route.reserve)) or not _is_int(float(route.target)):
			return false
	for job_id in state.economy.jobs:
		var job: Dictionary = state.economy.jobs[job_id]
		var recipe: Dictionary = catalog.recipes.get(String(job.recipe_id), {})
		if recipe.is_empty():
			return false
		if not _is_int(float(recipe.output)):
			return false
		for input_id in recipe.inputs:
			if not _is_int(float(recipe.inputs[input_id])):
				return false
	return true

static func _job_retry_offset(state: GameState, catalog: Dictionary, island: String, job: Dictionary, horizon: int) -> int:
	var recipe: Dictionary = catalog.recipes.get(String(job.recipe_id), {})
	if recipe.is_empty():
		return 1
	var reserves: Dictionary = job.get("reserves", {})
	var worst := 0
	for input_id in recipe.inputs:
		var required := float(recipe.inputs[input_id])
		if island == "home" or IslandEconomy.GLOBAL.has(input_id):
			return 1
		var available := IslandEconomy.value(state, island, input_id) - float(reserves.get(input_id, "0"))
		if available >= required:
			continue
		var rate := _island_fill_rate(state, island, input_id)
		if rate <= 0.0:
			continue
		var room := IslandEconomy.free_space(state, island, input_id, catalog)
		if not _is_int(room) or not _is_int(available) or not _is_int(rate):
			return 1
		if room <= 0.0:
			continue
		var limit := available + room
		var found := -1
		for k in range(1, horizon + 1):
			var value_k := minf(available + rate * float(k), limit)
			if value_k - float(reserves.get(input_id, "0")) >= required:
				found = k
				break
		if found < 0:
			continue
		worst = maxi(worst, found)
	if worst <= 0:
		var room0 := IslandEconomy.free_space(state, island, ProcessingCatalog.product_id(catalog, String(job.recipe_id)), catalog)
		if room0 < float(recipe.output):
			var unlock0 := _output_room_offset(state, catalog, island, String(job.recipe_id), horizon)
			return unlock0 if unlock0 >= 1 else -1
		return 1
	var output_room := IslandEconomy.free_space(state, island, ProcessingCatalog.product_id(catalog, String(job.recipe_id)), catalog)
	if output_room < float(recipe.output):
		var unlock := _output_room_offset(state, catalog, island, String(job.recipe_id), horizon)
		if unlock < 0:
			return -1
		return maxi(worst, unlock)
	return worst

static func _output_room_offset(state: GameState, catalog: Dictionary, island: String, id: String, horizon: int) -> int:
	var rate := _island_fill_rate(state, island, id)
	if rate <= 0.0:
		return -1
	var room := IslandEconomy.free_space(state, island, id, catalog)
	var needed := float(catalog.recipes[id].output)
	var found := -1
	for k in range(1, horizon + 1):
		if room + rate * float(k) >= needed:
			found = k
			break
	return found

static func _island_fill_rate(state: GameState, island: String, id: String) -> float:
	if island == "home":
		return 0.0
	var rates: Dictionary = IslandEconomy.island_defs(state).get(island, {}).get("rates", {})
	if not rates.has(id):
		return 0.0
	var extractor := int(state.economy.islands[island].facilities.extractor) if IslandProgression.active(state) else 1
	return float(rates[id]) * float(extractor)

static func _structure_error(state: GameState, catalog: Dictionary) -> String:
	if catalog.is_empty():
		return "no_catalog"
	var e: Dictionary = state.economy
	if not String(e.get("version", "")) in VALID_VERSIONS:
		return "bad_version"
	for key in ["islands", "jobs", "routes", "trips"]:
		if not e.get(key) is Dictionary:
			return "bad_field:" + key
	for route_id in e.trips:
		var trip: Variant = e.trips[route_id]
		if not trip is Dictionary or not _is_int(float(trip.get("remaining", NAN))) or int(trip.remaining) < 1 or int(trip.remaining) > 10:
			return "bad_trip:" + String(route_id)
	for island in e.jobs:
		var job: Variant = e.jobs[island]
		if not job is Dictionary or not catalog.recipes.has(String(job.get("recipe_id", ""))):
			return "bad_job:" + String(island)
		if not _is_int(float(job.get("remaining", NAN))) or int(job.remaining) < 0:
			return "bad_job_remaining:" + String(island)
		if not _is_int(float(job.get("batches", NAN))) or int(job.batches) < 0 or not job.get("repeat") is bool:
			return "bad_job_fields:" + String(island)
	return ""

static func _is_int(v: float) -> bool:
	return is_finite(v) and v == floor(v) and absf(v) <= 9007199254740992.0
