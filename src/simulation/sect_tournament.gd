class_name SectTournament
extends RefCounted
## Scoring/RNG revision 1; all sampled inputs freeze at entry.
const RULES := "core-flow-28-sect-tournament-1"
const TAG := "+sect-tournament-1"
const STRATEGIES := ["steady", "risk", "observe"]
const THEMES := {"taixu_sect":["定息","辨理","問心"], "tianjian_sect":["養鋒","試鋒","論劍"], "piaomiao_sect":["識草","辨藥","調方"], "wanfo_sect":["定念","照心","問心"], "zixiao_sect":["觀星","演陣","合陣"]}
static func initial() -> Dictionary:
	return {"scoring_version":1, "cursor":0, "next_second":300, "current":null, "recent":[]}
static func available(s: GameState) -> bool:
	return s.sect_version in [5, 6, 7] and s.sect.get("unlocked", false) and THEMES.has(s.sect.life.sect_id)
static func offer(s: GameState) -> void:
	if not available(s): return
	var l: Dictionary = s.sect.life
	var c: Dictionary = l.competition
	if c.current != null or int(l.tenure_seconds) < int(c.next_second) or int(l.tenure_seconds) == SectLife.LIMIT: return
	var edition := 1 + (int(l.tenure_seconds) - 300) / 600
	if edition <= int(c.cursor): return
	c.cursor = edition
	c.current = {"id":"%d:%s:T%d" % [l.life_seq,l.sect_id,edition], "edition":edition, "status":"invite"}
static func frozen(seed: int, era: int, level: int, technique: int, prep: int) -> Dictionary:
	var rng := SeededRandom.from_state(seed)
	var coins := []
	for i in 3: coins.append(rng.int_range(0,1))
	var offsets := []
	for seat in 7:
		var stages := []
		for stage in 3: stages.append(rng.int_range(-2,2))
		offsets.append(stages)
	var ties := range(8)
	for i in range(7,0,-1):
		var j := rng.int_range(0,i)
		var previous: int = ties[i]
		ties[i] = ties[j]
		ties[j] = previous
	return {"seed":seed,"era":era,"level":level,"technique":technique,"preparation":prep,"coins":coins,"offsets":offsets,"ties":ties,"rng_after":rng.state}
static func scores(f: Dictionary, choices: Array) -> Array:
	var rows := []
	var player := []
	for i in choices.size():
		var modifier: int = 5 if choices[i] == "steady" else ((-4 if int(f.coins[i]) == 0 else 12) if choices[i] == "risk" else (7 if i == int(f.preparation) else 2))
		player.append(40 + 2*(int(f.level)-1) + int(f.technique) + 3 + (4 if i == int(f.preparation) else 0) + modifier)
	rows.append(player)
	for seat in range(1,8):
		var stages := []
		for i in 3: stages.append(42 + 3*(seat-1) + 8 + (4 if i == (seat-1)%3 else 0) + int(f.offsets[seat-1][i]))
		rows.append(stages)
	return rows
static func order(f: Dictionary, choices: Array) -> Array:
	if choices.size() != 3: return []
	var rows := scores(f, choices)
	var seats := range(8)
	seats.sort_custom(func(a: int,b: int) -> bool:
		var aa: Array = rows[a]
		var bb: Array = rows[b]
		var total_a: int = aa[0]+aa[1]+aa[2]
		var total_b: int = bb[0]+bb[1]+bb[2]
		if total_a != total_b: return total_a > total_b
		if aa.min() != bb.min(): return aa.min() > bb.min()
		return f.ties[a] < f.ties[b])
	return seats
static func reward(rank: int) -> int:
	return [18,14,10,6,6,6,6,6][rank-1]
static func close(l: Dictionary, status: String, rank: int = 0) -> void:
	var c: Dictionary = l.competition
	c.recent.append({"edition":c.current.edition,"status":status,"rank":rank})
	if c.recent.size() > 4: c.recent.pop_front()
	c.current = null
	c.next_second = mini(SectLife.LIMIT, 300 + (1 + (maxi(300,int(l.tenure_seconds))-300)/600)*600)
static func execute(content: GameContent, s: GameState, action: String, p: Dictionary) -> Dictionary:
	if not available(s): return {"ok":false,"error":"SECT_TOURNAMENT_UNAVAILABLE"}
	if Lifespan.is_exhausted(s.total_elapsed_seconds,Lifespan.for_state(content.era_lifespan_entries(),s)): return {"ok":false,"error":"LIFESPAN_EXHAUSTED"}
	var l: Dictionary = s.sect.life
	var t: Variant = l.competition.current
	if t == null or p.get("instance_id") != t.id: return {"ok":false,"error":"SECT_TOURNAMENT_INSTANCE"}
	match action:
		"skip_sect_tournament":
			if t.status != "invite": return {"ok":false,"error":"SECT_TOURNAMENT_PHASE"}
			close(l,"skipped")
		"enter_sect_tournament":
			if t.status != "invite" or not SectSaveContract.integer(p.get("preparation"),2): return {"ok":false,"error":"SECT_TOURNAMENT_PREPARATION"}
			var technique := clampi(int(s.sect.techniques.get("breathing_method",0)),0,10)
			for id in SectSpecialization.METHODS: technique += SectSpecialization.level(s,id)
			t.frozen = frozen(int(l.rng.tournament),s.era_id,s.level,mini(10,technique),int(p.preparation))
			l.rng.tournament = t.frozen.rng_after
			t.tick = l.tenure_seconds
			t.choices = []
			t.status = "entered"
			if int(l.content_version) >= 2: t.roster_version = 2
		"choose_sect_trial":
			if t.status != "entered" or not SectSaveContract.integer(p.get("stage"),2) or int(p.stage) != t.choices.size() or p.get("strategy") not in STRATEGIES: return {"ok":false,"error":"SECT_TOURNAMENT_STRATEGY"}
			t.choices.append(p.strategy)
			if t.choices.size() == 3: t.status = "settled"
		"claim_sect_tournament":
			if t.status != "settled": return {"ok":false,"error":"SECT_TOURNAMENT_PHASE"}
			var rank := order(t.frozen,t.choices).find(0)+1
			var amount := AmountCompat.try_parse(s.sect.contribution)
			if not amount.ok: return {"ok":false,"error":"SECT_CONTRIBUTION"}
			s.sect.contribution = amount.value.add(AmountCompat.from_number(reward(rank))).serialize()
			var best := int(l.best_ranks.get(l.sect_id,0))
			l.best_ranks[l.sect_id] = rank if best == 0 else mini(best,rank)
			close(l,"claimed",rank)
		"abandon_sect_tournament":
			if t.status == "invite": return {"ok":false,"error":"SECT_TOURNAMENT_PHASE"}
			close(l,"abandoned")
		_: return {"ok":false,"error":"SECT_TOURNAMENT_ACTION"}
	return {"ok":true,"changed_ids":["sect"],"events":[{"kind":action}]}
static func validate(l: Dictionary) -> String:
	var c: Variant = l.competition
	if not SectLifeSave.keys(c,["scoring_version","cursor","next_second","current","recent"]) or c.scoring_version != 1: return "SECT_TOURNAMENT_FIELDS"
	if not SectSaveContract.integer(c.cursor) or not SectSaveContract.integer(c.next_second) or int(c.next_second) < 300: return "SECT_TOURNAMENT_CURSOR"
	if not c.recent is Array or c.recent.size() > 4: return "SECT_TOURNAMENT_HISTORY"
	var previous := 0
	for r in c.recent:
		if not SectLifeSave.keys(r,["edition","status","rank"]) or not SectSaveContract.integer(r.edition,int(c.cursor)) or int(r.edition) <= previous or r.status not in ["skipped","abandoned","claimed"] or not SectSaveContract.integer(r.rank,8): return "SECT_TOURNAMENT_HISTORY"
		if (r.status == "claimed") != (r.rank > 0): return "SECT_TOURNAMENT_HISTORY"
		previous = int(r.edition)
	var t: Variant = c.current
	if t == null:
		if int(c.next_second) < mini(SectLife.LIMIT,300+int(c.cursor)*600): return "SECT_TOURNAMENT_CURSOR"
		return "" if l.sect_id != "" or c.cursor == 0 else "SECT_TOURNAMENT_MEMBERSHIP"
	if not t is Dictionary or t.get("status") not in ["invite","entered","settled"]: return "SECT_TOURNAMENT_PHASE"
	var fields := ["id","edition","status"] if t.status == "invite" else ["id","edition","status","frozen","choices","tick"]
	if t.has("roster_version"):
		if l.version < 3 or t.status == "invite" or t.roster_version != 2: return "SECT_TOURNAMENT_ROSTER"
		fields.append("roster_version")
	if not SectLifeSave.keys(t,fields): return "SECT_TOURNAMENT_FIELDS"
	if l.sect_id == "" or not SectSaveContract.integer(t.edition) or t.edition != c.cursor or int(t.edition) <= previous or t.id != "%d:%s:T%d" % [l.life_seq,l.sect_id,t.edition] or int(l.tenure_seconds) < 300+600*(int(t.edition)-1): return "SECT_TOURNAMENT_INSTANCE"
	if t.status == "invite": return ""
	if not SectSaveContract.integer(t.tick,int(l.tenure_seconds)) or int(t.tick) < 300+600*(int(t.edition)-1): return "SECT_TOURNAMENT_TICK"
	var f: Variant = t.frozen
	if not SectLifeSave.keys(f,["seed","era","level","technique","preparation","coins","offsets","ties","rng_after"]): return "SECT_TOURNAMENT_FROZEN"
	if not SectSaveContract.integer(f.seed,4294967295) or not SectSaveContract.integer(f.era,12) or f.era < 1 or not SectSaveContract.integer(f.level,10) or f.level < 1 or not SectSaveContract.integer(f.technique,10) or not SectSaveContract.integer(f.preparation,2): return "SECT_TOURNAMENT_BASELINE"
	if not SectLifeSave.same(f,frozen(int(f.seed),int(f.era),int(f.level),int(f.technique),int(f.preparation))) or f.rng_after != l.rng.tournament: return "SECT_TOURNAMENT_FROZEN"
	if not t.choices is Array or t.choices.size() > 3 or (t.status == "settled") != (t.choices.size() == 3): return "SECT_TOURNAMENT_PHASE"
	for strategy in t.choices:
		if strategy not in STRATEGIES: return "SECT_TOURNAMENT_STRATEGY"
	return ""
