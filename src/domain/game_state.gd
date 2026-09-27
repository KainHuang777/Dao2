class_name GameState
extends RefCounted

var revision: int = 0
var era_id: int = 1
var level: int = 1
var onboarding_version: int = 1
var training_seconds: float = 0.0
var total_elapsed_seconds: float = 0.0
var tick_remainder_seconds: float = 0.0
var resources: Dictionary = {}
var buildings: Dictionary = {}
var tutorial_flags: Dictionary = {}
var reincarnation_count: int = 0
var highest_era: int = 1
var dao_heart: AmountCompat = AmountCompat.zero()
var dao_proof: int = 0
var talents: Dictionary = {}
var pills: Dictionary = {}
var pill_effects: Dictionary = {}
var buffs: Dictionary = {}
var current_realm: String = "realm_human"
var realms_data: Dictionary = {}
var sect: Dictionary = {}

func duplicate_state() -> GameState:
	var copy := GameState.new()
	copy.revision = revision
	copy.era_id = era_id
	copy.level = level
	copy.onboarding_version = onboarding_version
	copy.training_seconds = training_seconds
	copy.total_elapsed_seconds = total_elapsed_seconds
	copy.tick_remainder_seconds = tick_remainder_seconds
	copy.tutorial_flags = tutorial_flags.duplicate(true)
	copy.reincarnation_count = reincarnation_count
	copy.highest_era = highest_era
	copy.dao_heart = dao_heart.duplicate_amount() if dao_heart != null else AmountCompat.zero()
	copy.dao_proof = dao_proof
	copy.talents = talents.duplicate(true)
	copy.pills = pills.duplicate(true)
	copy.pill_effects = pill_effects.duplicate(true)
	copy.buffs = buffs.duplicate(true)
	copy.current_realm = current_realm
	copy.realms_data = realms_data.duplicate(true)
	copy.sect = sect.duplicate(true)
	for resource_id in resources:
		var entry: Dictionary = resources[resource_id]
		copy.resources[resource_id] = {
			"value": entry.value.duplicate_amount(),
			"unlocked": bool(entry.unlocked),
			"ever_obtained": bool(entry.ever_obtained),
		}
	for building_id in buildings:
		copy.buildings[building_id] = int(buildings[building_id])
	return copy

func to_snapshot_dict() -> Dictionary:
	var resource_snapshot := {}
	for resource_id in resources:
		var entry: Dictionary = resources[resource_id]
		resource_snapshot[resource_id] = {
			"value": entry.value.serialize(),
			"unlocked": bool(entry.unlocked),
			"ever_obtained": bool(entry.ever_obtained),
		}
	var building_snapshot := {}
	for building_id in buildings:
		building_snapshot[building_id] = int(buildings[building_id])
	return {
		"revision": revision,
		"era_id": era_id,
		"level": level,
		"onboarding_version": onboarding_version,
		"training_seconds": training_seconds,
		"total_elapsed_seconds": total_elapsed_seconds,
		"tick_remainder_seconds": tick_remainder_seconds,
		"resources": resource_snapshot,
		"buildings": building_snapshot,
		"tutorial_flags": tutorial_flags.duplicate(true),
		"reincarnation_count": reincarnation_count,
		"highest_era": highest_era,
		"dao_heart": dao_heart.serialize() if dao_heart != null else "0",
		"dao_proof": dao_proof,
		"talents": talents.duplicate(true),
		"pills": pills.duplicate(true),
		"pill_effects": pill_effects.duplicate(true),
		"buffs": buffs.duplicate(true),
		"current_realm": current_realm,
		"realms_data": realms_data.duplicate(true),
		"sect": sect.duplicate(true),
	}

