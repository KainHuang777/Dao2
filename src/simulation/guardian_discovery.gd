class_name GuardianDiscovery
extends RefCounted
## Frozen rewards and permanent permits installed by the atomic release migration.
const VERSION := 1
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const TARGETS := ["taixu_baize", "tianjian_suanni", "piaomiao_jade_hare", "wanfo_lotus_elephant", "zixiao_star_tapir", "iron_turtle", "frost_stag", "herb_crane", "fire_phoenix", "cloud_serpent"]
const SECTS := ["taixu_sect", "tianjian_sect", "piaomiao_sect", "wanfo_sect", "zixiao_sect"]
const SOURCES := ["herb", "deep", "ancient"]

static func active(state: GameState) -> bool:
	return state != null and state.beast_version == GuardianBeasts.VERSION and state.sect.has("guardian")

static func ledger_error(ledger: Variant) -> String:
	if not (ledger is Dictionary) or ledger.size() not in [3, 4]: return "GUARDIAN_LEDGER"
	if not SectSaveContract.integer(ledger.get("version"), VERSION) or ledger.version != VERSION: return "GUARDIAN_VERSION"
	if not SectSaveContract.integer(ledger.get("guardian_tokens"), 120): return "GUARDIAN_TOKENS"
	var permits: Variant = ledger.get("permits")
	if not (permits is Dictionary) or permits.size() > TARGETS.size(): return "GUARDIAN_PERMITS"
	for id in permits:
		if id not in TARGETS or not (permits[id] is bool) or permits[id] != true: return "GUARDIAN_PERMIT"
	if ledger.has("legacy_permits"):
		var legacy: Variant = ledger.legacy_permits
		if not (legacy is Dictionary) or legacy.size() > 6: return "GUARDIAN_LEGACY_PERMITS"
		for id in legacy:
			if not BeastSystem.BEAST_CONFIGS.has(id) or not (legacy[id] is bool) or legacy[id] != true: return "GUARDIAN_LEGACY_PERMIT"
	elif ledger.size() == 4: return "GUARDIAN_LEDGER"
	return ""

static func state_error(state: GameState) -> String:
	if not active(state): return "GUARDIAN_RELEASE_REQUIRED"
	var error := ledger_error(state.sect.guardian)
	if not error.is_empty(): return error
	error = SectReformSave.validate(state.sect)
	if not state.sect.has("core_save") or not error.is_empty(): return "GUARDIAN_CORE_REQUIRED"
	return SectLineage.validate_state(state)

static func permit_owned(state: GameState, target_id: String) -> bool:
	return state_error(state).is_empty() and target_id in TARGETS and state.sect.guardian.permits.has(target_id)

static func conditions(state: GameState) -> Dictionary:
	var result := {}
	for source in SOURCES: result[source] = bool(state.economy.get("islands", {}).get(source, {}).get("opened", false))
	return result

static func pool(era: int, opened: Dictionary) -> Array:
	var ids: Array = []
	if era >= 3 and opened.get("herb", false): ids.append_array(TARGETS.slice(0, 5))
	if era >= 4 and opened.get("deep", false): ids.append_array(["iron_turtle", "frost_stag"])
	if era >= 5 and opened.get("ancient", false): ids.append("herb_crane")
	if era >= 6 and opened.get("ancient", false): ids.append("fire_phoenix")
	# cloud_serpent has no complete authoritative feeding supply yet. Do not
	# invent a source flag, accept a caller boolean, or unlock it by Era alone.
	ids.sort()
	return ids

static func choose(ids: Array, sect_id: String, value: float) -> String:
	if ids.is_empty(): return ""
	var representative := String(TARGETS[SECTS.find(sect_id)]) if sect_id in SECTS else ""
	var total := ids.size() + (2 if representative in ids else 0)
	var roll := floori(value * total)
	for id in ids:
		roll -= 3 if id == representative else 1
		if roll < 0: return id
	return ""

static func stamp(state: GameState, task: Dictionary, event_value: float, species_value: float) -> void:
	var opened := conditions(state)
	var ids := pool(state.era_id, opened)
	var sect_id: String = SectIdentity.view(state.sect).sect_id
	var eligible := not sect_id.is_empty() and state.era_id >= 3 and not ids.is_empty()
	var rate := 0.1 if task.rarity == "epic" else 0.2 if task.rarity == "legendary" else 0.0
	task.guardian_reward = {"version": VERSION, "pool_version": VERSION,
		"generation_life_seq": state.reincarnation_count, "generation_era": state.era_id,
		"generation_sect_id": sect_id, "token_base": 1 if eligible else 0,
		"permit_id": choose(ids, sect_id, species_value) if eligible and event_value < rate else "",
		"pool_ids": ids, "conditions": opened}

static func task_error(task: Dictionary) -> String:
	if not task.has("guardian_reward"): return "GUARDIAN_REWARD" if task.has("guardian_template_id") else ""
	var reward: Variant = task.guardian_reward
	if not (reward is Dictionary) or reward.size() != 9: return "GUARDIAN_REWARD"
	for key in ["version", "pool_version"]:
		if not SectSaveContract.integer(reward.get(key), VERSION) or reward[key] != VERSION: return "GUARDIAN_REWARD_VERSION"
	if not SectSaveContract.integer(reward.get("generation_life_seq")): return "GUARDIAN_LIFE"
	if not SectSaveContract.integer(reward.get("generation_era"), 12) or reward.generation_era < 1: return "GUARDIAN_ERA"
	if reward.get("generation_sect_id") not in SECTS: return "GUARDIAN_SECT"
	var opened: Variant = reward.get("conditions")
	if not (opened is Dictionary) or opened.size() != SOURCES.size(): return "GUARDIAN_CONDITIONS"
	for source in SOURCES:
		if not (opened.get(source) is bool): return "GUARDIAN_CONDITIONS"
	var ids := pool(int(reward.generation_era), opened)
	if not (reward.get("pool_ids") is Array) or reward.pool_ids != ids: return "GUARDIAN_POOL"
	var expected := 1 if reward.generation_era >= 3 and not ids.is_empty() else 0
	if not SectSaveContract.integer(reward.get("token_base"), 1) or reward.token_base != expected: return "GUARDIAN_TOKEN_BASE"
	var permit: Variant = reward.get("permit_id")
	if not (permit is String) or (not permit.is_empty() and (permit not in ids or expected == 0 or task.get("rarity") not in ["epic", "legendary"])): return "GUARDIAN_FROZEN_PERMIT"
	var credit: Variant = task.get("lineage_credit")
	if not (credit is Dictionary) or credit.get("life_seq") != reward.generation_life_seq or credit.get("sect_id") != reward.generation_sect_id: return "GUARDIAN_CREDIT"
	if task.has("generation_era") and task.generation_era != reward.generation_era: return "GUARDIAN_ERA"
	var key: Variant = task.get("guardian_template_id")
	if not (key is String): return "GUARDIAN_TEMPLATE"
	if task.has("template_id"):
		if key != task.template_id: return "GUARDIAN_TEMPLATE"
	else:
		var found := false
		var rarity: Variant = task.get("rarity")
		if rarity not in RARITIES: return "GUARDIAN_TEMPLATE"
		var templates: Array = SectSystem.TASK_TEMPLATES[rarity]
		for i in range(templates.size()):
			if key == "legacy_%s_%02d" % [rarity, i]:
				found = task.get("name") == templates[i].name and task.get("desc") == templates[i].desc and task.get("duration") == SectSystem.RARITY_CONFIGS[rarity].duration
		if not found: return "GUARDIAN_TEMPLATE"
	return ""

static func claim_error(state: GameState, task: Dictionary) -> String:
	if not task.has("guardian_reward"): return ""
	var error := state_error(state)
	if not error.is_empty(): return error
	error = task_error(task)
	if not error.is_empty(): return error
	var reward: Dictionary = task.guardian_reward
	if reward.generation_life_seq != state.reincarnation_count or reward.generation_sect_id != SectIdentity.view(state.sect).sect_id: return "GUARDIAN_GENERATION_MISMATCH"
	return ""

## Called only after every claim check, in the same candidate as dispatch removal.
static func claimed(state: GameState, task: Dictionary) -> Dictionary:
	if not task.has("guardian_reward"): return {}
	var reward: Dictionary = task.guardian_reward
	var ledger: Dictionary = state.sect.guardian
	var gain := int(reward.token_base)
	var duplicate := false
	var id := String(reward.permit_id)
	if not id.is_empty():
		duplicate = ledger.permits.has(id) or ledger.get("legacy_permits", {}).has(id)
		if duplicate: gain += 2
		else: ledger.permits[id] = true
	var previous := int(ledger.guardian_tokens)
	ledger.guardian_tokens = mini(120, previous + gain)
	return {"kind": "guardian_reward_claimed", "permit_id": id, "duplicate_permit": duplicate,
		"tokens_gained": int(ledger.guardian_tokens) - previous, "tokens_overflow": maxi(0, previous + gain - 120),
		"guardian_tokens": ledger.guardian_tokens}

static func redeem_requirements(state: GameState, target_id: String) -> Dictionary:
	var error := state_error(state)
	if not error.is_empty(): return {"ok": false, "error": error}
	return _redeem_eligibility(state, target_id)

## View calls this only after complete release validation, once per projection.
static func _redeem_eligibility(state: GameState, target_id: String) -> Dictionary:
	if not state.sect.get("unlocked", false): return {"ok": false, "error": "SECT_LOCKED"}
	if SectIdentity.view(state.sect).sect_id.is_empty(): return {"ok": false, "error": "SECT_IDENTITY_PENDING"}
	if not SectSystem.p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	if target_id not in TARGETS: return {"ok": false, "error": "UNKNOWN_GUARDIAN_TARGET"}
	if target_id not in pool(state.era_id, conditions(state)): return {"ok": false, "error": "GUARDIAN_SUPPLY_REQUIRED"}
	var ledger: Dictionary = state.sect.guardian
	if ledger.permits.has(target_id) or ledger.get("legacy_permits", {}).has(target_id): return {"ok": false, "error": "GUARDIAN_PERMIT_OWNED"}
	if ledger.guardian_tokens < 12: return {"ok": false, "error": "INSUFFICIENT_GUARDIAN_TOKENS"}
	return {"ok": true}

static func redeem(state: GameState, target_id: String) -> Dictionary:
	var check := redeem_requirements(state, target_id)
	if not check.ok: return check
	var ledger: Dictionary = state.sect.guardian
	ledger.guardian_tokens -= 12
	ledger.permits[target_id] = true
	return {"ok": true, "changed_ids": ["sect"], "events": [{"kind": "guardian_permit_redeemed", "permit_id": target_id, "guardian_tokens": ledger.guardian_tokens}]}
