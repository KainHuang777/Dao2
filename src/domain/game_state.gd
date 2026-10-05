class_name GameState
extends RefCounted

var revision: int = 0
const COMMAND_RECEIPT_LIMIT := 256
var command_receipts: Dictionary = {}
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
var chrono: Dictionary = {}
var world_address: String = "universe_0/sector_human_0/realm_human/region_cloud_peak/loc_home_island"
var aspiration_realm: String = ""
var discovered_worlds: Dictionary = {}
var fortune: Dictionary = {}
var realm_decisions: Dictionary = {}
var beasts: Dictionary = {}
var beast_souls: Dictionary = {}
var beast_talents: Dictionary = {}
var abode_scenery: Dictionary = {}
var achievements: Dictionary = {}
var economy: Dictionary = {}
var skill_version: int = 0
var skills: Dictionary = {}

func duplicate_state() -> GameState:
	var copy := GameState.new()
	copy.revision = revision
	copy.command_receipts = command_receipts.duplicate(true)
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
	copy.chrono = chrono.duplicate(true)
	copy.world_address = world_address
	copy.aspiration_realm = aspiration_realm
	copy.discovered_worlds = discovered_worlds.duplicate(true)
	copy.fortune = fortune.duplicate(true)
	copy.realm_decisions = realm_decisions.duplicate(true)
	copy.beasts = beasts.duplicate(true)
	copy.beast_souls = beast_souls.duplicate(true)
	copy.beast_talents = beast_talents.duplicate(true)
	copy.abode_scenery = abode_scenery.duplicate(true)
	copy.achievements = achievements.duplicate(true)
	copy.economy = economy.duplicate(true)
	copy.skill_version = skill_version
	copy.skills = skills.duplicate(true)
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
		"command_receipts": command_receipts.duplicate(true),
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
		"chrono": chrono.duplicate(true),
		"world_address": world_address,
		"aspiration_realm": aspiration_realm,
		"discovered_worlds": discovered_worlds.duplicate(true),
		"fortune": fortune.duplicate(true),
		"realm_decisions": realm_decisions.duplicate(true),
		"beasts": beasts.duplicate(true),
		"beast_souls": beast_souls.duplicate(true),
		"beast_talents": beast_talents.duplicate(true),
		"abode_scenery": abode_scenery.duplicate(true),
		"achievements": achievements.duplicate(true),
		"economy": economy.duplicate(true),
		"skill_version": skill_version,
		"skills": skills.duplicate(true),
	}
