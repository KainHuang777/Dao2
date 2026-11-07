class_name ResearchSystem
extends RefCounted
## Per-life research; official C nodes are isolated from the legacy launcher.
const VERSION := "econ-r1-research-1"
const MAX_SECONDS := 604800

static func initial() -> Dictionary:
	return {"completed": {}, "job": {}, "mastered": {}, "inherited_depth": 0}

static func validate_catalog(catalog: Dictionary, content: GameContent) -> String:
	if not catalog.get("version") is String or catalog.version != VERSION or not catalog.get("nodes") is Array: return "RESEARCH_CATALOG_VERSION"
	if catalog.nodes.size() > 64: return "RESEARCH_NODE_LIMIT"
	var nodes := {}
	for node in catalog.nodes:
		if not node is Dictionary or not node.get("id") is String or node.id.is_empty() or nodes.has(node.id): return "RESEARCH_ID"
		if not integer(node.get("era"), 2, 6) or not integer(node.get("seconds"), 10, MAX_SECONDS): return "RESEARCH_DURATION_ERA"
		if not node.get("prerequisites") is Array or not node.get("cost") is Dictionary or node.cost.is_empty() or not node.get("unlocks") is Array: return "RESEARCH_SHAPE"
		if not node.get("facility") is String or not content.buildings.has(node.facility): return "RESEARCH_FACILITY"
		if node.has("island") and (not node.island is String or node.island not in ["", "wood", "ore", "herb", "deep", "ancient", "void"]): return "RESEARCH_ISLAND"
		if node.has("produced"):
			if not node.produced is Array: return "RESEARCH_PRODUCED"
			var seen_produced := {}
			for resource in node.produced:
				if not resource is String or not content.resources.has(resource) or seen_produced.has(resource): return "RESEARCH_PRODUCED"
				seen_produced[resource] = true
		for resource in node.cost:
			if not content.resources.has(resource) or not integer(node.cost[resource], 1, 1000000000000): return "RESEARCH_COST"
		var unlocks := {}
		for unlock in node.unlocks:
			if not unlock is String or unlock.is_empty() or unlocks.has(unlock): return "RESEARCH_UNLOCK"
			unlocks[unlock] = true
		nodes[node.id] = node
	var resolved := {}
	while resolved.size() < nodes.size():
		var previous := resolved.size()
		for id in nodes:
			var ready := true
			var seen := {}
			for prerequisite in nodes[id].prerequisites:
				if not prerequisite is String or not nodes.has(prerequisite) or seen.has(prerequisite): return "RESEARCH_PREREQUISITE"
				seen[prerequisite] = true
				if not resolved.has(prerequisite): ready = false
				if int(nodes[prerequisite].era) > int(nodes[id].era): return "RESEARCH_ERA_ORDER"
			if ready: resolved[id] = true
		if resolved.size() == previous: return "RESEARCH_CYCLE"
	return ""

static func integer(value: Variant, lower: int, upper: int) -> bool:
	return EconomyEffects.finite(value) and float(value) == floor(float(value)) and float(value) >= lower and float(value) <= upper

static func node_for(catalog: Dictionary, id: String) -> Dictionary:
	for node in catalog.nodes:
		if node.id == id: return node
	return {}

static func depth(catalog: Dictionary, id: String, memo: Dictionary = {}) -> int:
	if memo.has(id): return memo[id]
	var node := node_for(catalog, id)
	var result := 0
	for prerequisite in node.prerequisites: result = maxi(result, depth(catalog, prerequisite, memo))
	memo[id] = result + 1
	return result + 1

static func inheritance(_catalog: Dictionary, research: Dictionary) -> Dictionary:
	var frontier := int(research.inherited_depth)
	# Unique highest completed frontier; repeating research/rebirth pays no currency.
	var raw := 0.5 if frontier >= 6 else 0.3 if frontier >= 3 else 0.15 if frontier >= 1 else 0.0
	return EconomyEffects.resolve("research_inheritance", "research", [{"effect_id":"research_frontier", "family":"research_inheritance", "scope":"research", "unit":"reduction", "stack_mode":"sum_then_dr", "limit":0.7, "source":"unique_completed_frontier", "value":raw}])

static func quote(catalog: Dictionary, research: Dictionary, state: GameState, id: String) -> Dictionary:
	var node := node_for(catalog, id)
	if node.is_empty(): return {"ok": false, "error": "RESEARCH_UNKNOWN"}
	if not research.job.is_empty(): return {"ok": false, "error": "RESEARCH_BUSY"}
	if research.completed.has(id): return {"ok": false, "error": "RESEARCH_COMPLETED"}
	if state.era_id < int(node.era): return {"ok": false, "error": "RESEARCH_ERA"}
	if int(state.buildings.get(node.facility, 0)) < 1: return {"ok": false, "error": "RESEARCH_FACILITY"}
	if not String(node.get("island", "")).is_empty() and not state.economy.get("islands", {}).get(node.island, {}).get("opened", false): return {"ok":false, "error":"RESEARCH_ISLAND"}
	for prerequisite in node.prerequisites:
		if not research.completed.has(prerequisite): return {"ok": false, "error": "RESEARCH_PREREQUISITE"}
	for resource in node.get("produced", []):
		if not state.resources.get(resource, {}).get("ever_obtained", false): return {"ok":false, "error":"RESEARCH_SAMPLE_REQUIRED"}
	var timing := EconomyEffects.duration(int(node.seconds), inheritance(catalog, research), 10)
	return {"ok": true, "id":id, "version":catalog.version, "paid":node.cost.duplicate(true), "duration":timing.seconds, "effect":timing.effect, "unlocks":node.unlocks.duplicate(true)}

static func start(catalog: Dictionary, research: Dictionary, state: GameState, id: String, content: GameContent) -> Dictionary:
	var q := availability(catalog, research, state, id, content)
	if not q.ok: return q
	for resource in q.paid:
		var slot: Dictionary = state.resources[resource]
		slot.value = ResourceLedger.change(state, "home", resource, slot.value, slot.value.subtract(AmountCompat.from_number(q.paid[resource])), "research")
	research.job = q.duplicate(true)
	research.job.erase("ok")
	research.job["remaining"] = q.duration
	return {"ok": true, "events":[{"kind":"research_started", "id":id}], "changed_ids":["research", "resources"]}

static func availability(catalog: Dictionary, research: Dictionary, state: GameState, id: String, content: GameContent) -> Dictionary:
	var q := quote(catalog, research, state, id)
	if not q.ok: return q
	if Lifespan.is_exhausted(state.total_elapsed_seconds, Lifespan.for_state(content.era_lifespan_entries(), state)):
		return {"ok": false, "error": "RESEARCH_LIFESPAN"}
	for resource in q.paid:
		var slot: Dictionary = state.resources.get(resource, {})
		if slot.is_empty() or not slot.get("unlocked", false): return {"ok": false, "error": "RESOURCE_LOCKED"}
		if slot.value.compare_to(AmountCompat.from_number(q.paid[resource])) < 0: return {"ok": false, "error": "INSUFFICIENT_RESOURCE"}
	return q

static func cancel(research: Dictionary) -> Dictionary:
	if research.job.is_empty(): return {"ok": false, "error": "RESEARCH_IDLE"}
	var id: String = research.job.id
	research.job = {}
	return {"ok": true, "events":[{"kind":"research_cancelled", "id":id, "refund":false}], "changed_ids":["research"]}

static func tick(research: Dictionary) -> Array:
	if research.job.is_empty(): return []
	research.job.remaining = int(research.job.remaining) - 1
	if research.job.remaining > 0: return []
	var id: String = research.job.id
	research.completed[id] = true
	research.mastered[id] = true
	research.job = {}
	return [{"kind":"research_completed", "id":id}]

static func reset_life(research: Dictionary, catalog: Dictionary) -> void:
	for id in research.mastered:
		research.inherited_depth = maxi(int(research.inherited_depth), depth(catalog, id))
	research.completed = {}
	research.job = {}

static func validate(research: Variant, catalog: Dictionary) -> String:
	if not research is Dictionary or research.size() != 4: return "RESEARCH_STATE"
	for key in ["completed", "mastered", "job"]:
		if not research.get(key) is Dictionary: return "RESEARCH_STATE"
	for key in ["completed", "mastered"]:
		for id in research[key]:
			if not id is String or node_for(catalog, id).is_empty() or not research[key][id] is bool or not research[key][id]: return "RESEARCH_STATE_ID"
			for prerequisite in node_for(catalog, id).prerequisites:
				if not research[key].has(prerequisite): return "RESEARCH_STATE_PREREQUISITE"
	var earned_depth := 0
	for id in research.mastered: earned_depth = maxi(earned_depth, depth(catalog, id))
	if not integer(research.get("inherited_depth"), 0, earned_depth): return "RESEARCH_INHERITED_DEPTH"
	for id in research.completed:
		if not research.mastered.has(id): return "RESEARCH_MASTERY"
	var job: Dictionary = research.job
	if job.is_empty(): return ""
	if not job.get("id") is String or not job.get("version") is String: return "RESEARCH_JOB_ID"
	var node := node_for(catalog, job.id)
	if node.is_empty() or research.completed.has(job.id) or job.get("version") != catalog.version: return "RESEARCH_JOB_ID"
	if not integer(job.get("duration"), 10, MAX_SECONDS) or not integer(job.get("remaining"), 1, int(job.duration)): return "RESEARCH_JOB_TIME"
	if not same(job.get("paid"), node.cost) or not same(job.get("unlocks"), node.unlocks): return "RESEARCH_JOB_FROZEN"
	for prerequisite in node.prerequisites:
		if not research.completed.has(prerequisite): return "RESEARCH_JOB_PREREQUISITE"
	var effect: Variant = job.get("effect")
	if not effect is Dictionary or not effect.get("sources") is Array or not EconomyEffects.finite(effect.get("raw")): return "RESEARCH_JOB_EFFECT"
	var resolved := EconomyEffects.resolve("research_inheritance", "research", effect.get("sources", []))
	if not resolved.ok or not same(resolved, effect) or not same(effect, inheritance(catalog, research)): return "RESEARCH_JOB_EFFECT"
	var timing := EconomyEffects.duration(int(node.seconds), resolved, 10)
	if timing.seconds != int(job.duration): return "RESEARCH_JOB_DURATION"
	return ""

static func same(a: Variant, b: Variant) -> bool:
	return JSON.stringify(SaveCodec._normalize_numbers(a), "", true) == JSON.stringify(SaveCodec._normalize_numbers(b), "", true)

static func has_unlock(catalog: Dictionary, research: Dictionary, capability: String) -> bool:
	for id in research.completed:
		if capability in node_for(catalog, id).unlocks: return true
	return false
