class_name GameState
extends RefCounted

var revision: int = 0
var era_id: int = 1
var level: int = 1
var onboarding_version: int = 1
var training_seconds: float = 0.0
var total_elapsed_seconds: float = 0.0
var resources: Dictionary = {}
var buildings: Dictionary = {}
var tutorial_flags: Dictionary = {}

func duplicate_state() -> GameState:
	var copy := GameState.new()
	copy.revision = revision
	copy.era_id = era_id
	copy.level = level
	copy.onboarding_version = onboarding_version
	copy.training_seconds = training_seconds
	copy.total_elapsed_seconds = total_elapsed_seconds
	copy.tutorial_flags = tutorial_flags.duplicate(true)
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
		"resources": resource_snapshot,
		"buildings": building_snapshot,
		"tutorial_flags": tutorial_flags.duplicate(true),
	}
