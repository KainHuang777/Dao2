extends RefCounted
## Era 1 two-strategy pacing bot. Uses a real GameSession and real commands only:
## no resource grants, no direct state edits. "active" reacts every second and
## clicks; "idle" returns every `interval` seconds, clicks a bounded number of
## times, then buys greedily.

const CHAIN := [
	["hut", 2], ["wooden_house", 2], ["forest_farm", 3],
	["stone_mine", 3], ["herb_farm", 3], ["storage_lingli", 1],
]
const EXTRAS := [
	"wooden_house", "forest_farm", "stone_mine", "herb_farm", "storage_lingli",
	"storage_money", "storage_wood", "storage_stone", "storage_herb",
]
const EXTRA_LEVEL_LIMIT := 6
const OVERFLOW_IDS := ["lingli", "money", "wood", "stone_low", "spirit_grass_low"]
const PILL_ID := "cultivation_pill"
const PILL_SECONDS := 60.0

var session: GameSession
var _cmd := 0
var _use_pills := false
var _chain_done_t := -1.0
var _lv10_t := -1.0
var _ready_t := -1.0
var _purchases := 0
var _clicks := 0
var _pills := 0
var _horizon_levels := -1
var _horizon_cult_level := -1
var _overflow := {}

func _init(content: GameContent) -> void:
	session = GameSession.create_new_game(content)
	for id in OVERFLOW_IDS:
		_overflow[id] = 0.0

## mode: "active" or "idle". Returns a metrics dictionary.
func run(mode: String, p: Dictionary) -> Dictionary:
	_use_pills = bool(p.get("use_pills", false))
	var max_seconds := int(p.max_seconds)
	var horizon := int(p.horizon)
	var step := 1 if mode == "active" else int(p.interval)
	var clicks := int(p.clicks_per_second) if mode == "active" else int(p.visit_clicks)
	var t := 0
	var stuck_since := 0.0
	var last_signature := ""
	_act(clicks, float(t))
	while t < max_seconds and _ready_t < 0.0:
		_advance(float(step))
		t += step
		_act(clicks, float(t))
		if _horizon_levels < 0 and t >= horizon:
			_snapshot_horizon()
		var signature := _signature()
		if signature != last_signature:
			last_signature = signature
			stuck_since = float(t)
		elif float(t) - stuck_since > 900.0 and mode == "active":
			break
	if _horizon_levels < 0:
		_snapshot_horizon()
	return {
		"mode": mode, "use_pills": _use_pills, "end_seconds": t,
		"t_chain_done": _chain_done_t, "t_lv10": _lv10_t, "t_ready": _ready_t,
		"levels_at_horizon": _horizon_levels, "cult_level_at_horizon": _horizon_cult_level,
		"purchases": _purchases, "clicks": _clicks, "pills": _pills,
		"overflow": _overflow.duplicate(),
		"stuck": _ready_t < 0.0,
	}

func _advance(seconds: float) -> void:
	# Overflow estimate: stock + rate*dt beyond the cap is production the player lost.
	var view := session.get_view()
	for id in OVERFLOW_IDS:
		var r: Dictionary = view.resources[id]
		if not bool(r.unlocked):
			continue
		var over := _f(r.value) + _f(r.rate) * seconds - _f(r.cap)
		if over > 0.0:
			_overflow[id] += over
	session.advance_time(seconds)

func _signature() -> String:
	var s := session.state
	return "%d|%s" % [s.level, str(s.buildings)]

func _snapshot_horizon() -> void:
	var total := 0
	for id in session.state.buildings:
		total += int(session.state.buildings[id])
	_horizon_levels = total
	_horizon_cult_level = session.state.level

func _act(clicks: int, t: float) -> void:
	var budget := clicks
	var progress := true
	var guard := 0
	while progress and guard < 400:
		guard += 1
		progress = false
		var view := session.get_view()
		if bool(view.can_level_up):
			if _submit("level_up_cultivation", {}):
				progress = true
				if session.state.level >= 10 and _lv10_t < 0.0:
					_lv10_t = t
				continue
		if bool(view.can_breakthrough) and _ready_t < 0.0:
			_ready_t = t
			return
		if _use_pills and _chain_done_t >= 0.0 and _try_pill(view):
			progress = true
			continue
		var target := _next_target(view)
		if target != "":
			var building: Dictionary = view.buildings[target]
			if bool(building.affordable):
				if _submit("upgrade_building", {"building_id": target}):
					_purchases += 1
					_update_chain(t)
					progress = true
					continue
			var spent := _click_shortfall(view, building.costs, budget)
			if spent > 0:
				budget -= spent
				progress = true
				continue
		# Level-up that only lacks resources, or a pill that only lacks herb/lingli.
		if budget > 0:
			var need := _levelup_or_pill_need(view)
			if not need.is_empty():
				var spent2 := _click_shortfall(view, need, budget)
				if spent2 > 0:
					budget -= spent2
					progress = true

func _levelup_or_pill_need(view: Dictionary) -> Dictionary:
	var s := session.state
	var req: float = float(view.next_level_required_seconds)
	if s.level < 10 and not view.level_up_costs.is_empty() and s.training_seconds >= req - 0.001:
		return view.level_up_costs
	if _use_pills and _chain_done_t >= 0.0 and AlchemySystem.is_unlocked(s) and req - s.training_seconds >= PILL_SECONDS * 0.5:
		var cost: Dictionary = {}
		for id in AlchemySystem.PILLS[PILL_ID].cost:
			cost[id] = str(AlchemySystem.PILLS[PILL_ID].cost[id])
		return cost
	return {}

func _try_pill(_view: Dictionary) -> bool:
	var s := session.state
	if not AlchemySystem.is_unlocked(s):
		return false
	if s.level >= 10:
		return false
	var ceiling := _training_ceiling()
	if ceiling - s.training_seconds < PILL_SECONDS * 0.5:
		return false
	if not bool(AlchemySystem.can_refine(s, PILL_ID, 1).get("can_refine", false)):
		return false
	var refined := session.refine_pill(PILL_ID, 1)
	if not bool(refined.get("ok", false)):
		return false
	var consumed := session.consume_pill(PILL_ID, 1)
	if bool(consumed.get("ok", false)):
		_pills += 1
		return true
	return false

func _training_ceiling() -> float:
	var s := session.state
	var era_def: Variant = session.content.era(s.era_id)
	if era_def == null:
		return 0.0
	return Cultivation.next_level_required_seconds(era_def, s.level, 0.0, 1.0)

func _next_target(view: Dictionary) -> String:
	for step in CHAIN:
		if int(view.buildings[step[0]].level) < int(step[1]):
			return String(step[0])
	var best := ""
	var best_cost := INF
	for id in EXTRAS:
		var b: Dictionary = view.buildings[id]
		if not bool(b.visible) or int(b.level) >= mini(EXTRA_LEVEL_LIMIT, int(b.level_cap)):
			continue
		var total := 0.0
		for rid in b.costs:
			total += _f(b.costs[rid])
		if total < best_cost:
			best_cost = total
			best = id
	return best

func _update_chain(t: float) -> void:
	if _chain_done_t >= 0.0:
		return
	for step in CHAIN:
		if int(session.state.buildings[step[0]]) < int(step[1]):
			return
	_chain_done_t = t

## Clicks the first short unlocked resource; returns clicks spent.
func _click_shortfall(view: Dictionary, costs: Dictionary, budget: int) -> int:
	var spent := 0
	for rid in costs:
		var r: Dictionary = view.resources.get(rid, {})
		if r.is_empty() or not bool(r.unlocked):
			continue
		var deficit := _f(costs[rid]) - _f(r.value)
		if deficit <= 0.0 or _f(costs[rid]) > _f(r.cap):
			continue
		var n := mini(int(ceil(deficit)), budget - spent)
		for _i in range(n):
			if not _submit("gather", {"resource_id": rid}):
				break
			spent += 1
			_clicks += 1
		if spent >= budget:
			break
	return spent

func _submit(kind: String, payload: Dictionary) -> bool:
	_cmd += 1
	var result := session.submit({"command_id": "pace-%d" % _cmd, "type": kind, "expected_revision": session.state.revision, "payload": payload})
	return bool(result.get("ok", false))

static func _f(raw: Variant) -> float:
	var parsed := AmountCompat.try_parse(str(raw))
	return (parsed.value as AmountCompat).to_float() if bool(parsed.ok) else 0.0
