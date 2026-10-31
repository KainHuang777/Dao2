class_name SectReformRelease
extends RefCounted
## Complete, source-archived release; historical defaults stay readable until
## startup commits all three feature versions in one candidate.
const SECT_VERSION := 3
const TALENT_VERSION := 4
const BEAST_VERSION := 2
const CONTENT_TAG := "+sect-reform-1"
const RULES_VERSION := "core-flow-26-sect-reform-1"

static func active(state: GameState) -> bool:
	return state != null and state.sect_version == SECT_VERSION

static func validate(state: GameState) -> String:
	var requested := active(state) or state.talent_version == TALENT_VERSION or state.beast_version == BEAST_VERSION or state.sect.has("guardian")
	if not requested: return ""
	if state.sect_version != SECT_VERSION or state.talent_version != TALENT_VERSION or state.beast_version != BEAST_VERSION: return "SECT_REFORM_VERSION_SET"
	var structural := BeastSaveContract.validate(state.beast_version, state.beasts, state.beast_souls, state.beast_talents)
	if not structural.is_empty(): return structural
	structural = SectSaveContract.validate(state.sect_version, state.sect)
	if not structural.is_empty(): return structural
	structural = TalentSystem.validate_state(state)
	if not structural.is_empty(): return structural
	var error := GuardianDiscovery.state_error(state)
	if not error.is_empty(): return error
	if state.sect.guardian.size() != 4 or not state.sect.guardian.has("legacy_permits"): return "SECT_REFORM_LEGACY_LEDGER"
	for id in GuardianBeasts.SPECIES:
		if not state.beast_souls.has(id): return "SECT_REFORM_SOULS_MISSING"
	for id in GuardianBeasts.TALENTS:
		if not state.beast_talents.has(id): return "SECT_REFORM_TALENTS_MISSING"
	var held_id: String = state.beasts.get("active", {}).get("id", "")
	if not held_id.is_empty() and held_id != "jade_fox" and not state.sect.guardian.permits.has(held_id) and not state.sect.guardian.legacy_permits.has(held_id): return "SECT_REFORM_ACTIVE_PERMIT"
	for task in state.sect.get("available_tasks", []) + ([state.sect.active_expedition] if state.sect.get("active_expedition") != null else []):
		if task.has("guardian_reward"):
			var claim_error := GuardianDiscovery.claim_error(state, task)
			if not claim_error.is_empty(): return claim_error
	return ""

static func prepare(source: GameState, raw: String, save_id: String) -> GameState:
	if active(source): return source.duplicate_state()
	var candidate: GameState
	if SectReformSave.active(source):
		candidate = source.duplicate_state()
		candidate.revision += 1
	else:
		candidate = SectReformSave.prepare(source, raw, save_id)
	# Snapshot rights before changing any feature version, and never use the
	# occupied slot, exhausted life or new supply requirements as disqualifiers.
	var legacy := {}
	for id in BeastSystem.BEAST_CONFIGS:
		var owned: bool = source.beasts.get("active", {}).get("id", "") == id or int(source.beast_souls.get(id, 0)) > 0
		for talent_id in BeastSystem.BEAST_TALENTS:
			if BeastSystem.BEAST_TALENTS[talent_id].beast_id == id and int(source.beast_talents.get(talent_id, 0)) > 0: owned = true
		if owned or BeastSystem.legacy_species_requirements(source, id).ok: legacy[id] = true
	candidate.sect.guardian = {"version": 1, "guardian_tokens": 0, "permits": {}, "legacy_permits": legacy}
	candidate.sect_version = SECT_VERSION
	candidate.talent_version = TALENT_VERSION
	candidate.beast_version = BEAST_VERSION
	for id in GuardianBeasts.SPECIES: candidate.beast_souls[id] = 0
	for id in GuardianBeasts.TALENTS: candidate.beast_talents[id] = 0
	return candidate
