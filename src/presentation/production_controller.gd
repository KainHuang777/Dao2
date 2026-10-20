class_name ProductionController
extends RefCounted
## Pure UI-side mapping from intent (start / stop / mode / reserve ratio) to the
## existing craft / switch_processing / stop_processing commands. No state is
## written to the core; mode preferences live only in this object's memory.

enum Mode { SINGLE, COUNT, REPEAT }

const MAX_COUNT := 1000000
const RATIO_STEPS := [0, 25, 50, 75, 100]

## recipe_id -> {"mode": Mode, "count": int}; reset on reload (UI memory only).
var prefs := {}

func pref(recipe_id: String) -> Dictionary:
	return prefs.get(recipe_id, {"mode": Mode.SINGLE, "count": 1})

func set_pref(recipe_id: String, mode: int, count: int = 1) -> void:
	prefs[recipe_id] = {"mode": mode, "count": clampi(count, 1, MAX_COUNT)}

## Cycle single -> repeat -> single (the chip row sets count modes explicitly).
func cycle_mode(recipe_id: String) -> int:
	var current: Dictionary = pref(recipe_id)
	var next: int = Mode.REPEAT if int(current.mode) != Mode.REPEAT else Mode.SINGLE
	set_pref(recipe_id, next, int(current.count))
	return next

static func is_running(job: Dictionary, recipe_id: String) -> bool:
	return not job.is_empty() and job.get("recipe_id") == recipe_id

## Running, last batch only, nothing queued: stop would have no effect.
static func finishing(job: Dictionary) -> bool:
	return int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false)

## Payload shared by craft and switch_processing.
static func work_payload(island: String, recipe_id: String, mode: int, count: int, reserves: Dictionary) -> Dictionary:
	return {"island_id": island, "recipe_id": recipe_id, "count": clampi(count, 1, MAX_COUNT) if mode == Mode.COUNT else 1, "repeat": mode == Mode.REPEAT, "reserves": reserves}

static func start_command(job: Dictionary) -> String:
	return "craft" if job.is_empty() else "switch_processing"

## Ratio (0..100 percent of stock at send time) -> absolute reserve strings.
## inputs: resource -> {"available": float}. Floor keeps reserve <= stock.
static func reserves_from_ratio(inputs: Dictionary, ratios: Dictionary) -> Dictionary:
	var result := {}
	for resource in inputs:
		var percent := clampf(float(ratios.get(resource, 0)), 0.0, 100.0)
		result[resource] = str(floorf(float(inputs[resource].available) * percent / 100.0))
	return result

## 100% reserve can never start; UI shows red and disables start (core still validates).
static func ratio_blocks_start(ratios: Dictionary) -> bool:
	for resource in ratios:
		if float(ratios[resource]) >= 100.0:
			return true
	return false

## Single-meaning card actions. Returns {"command": "", "payload": {}} when none.
static func start_action(job: Dictionary, info: Dictionary, recipe_id: String, pref_state: Dictionary = {}) -> Dictionary:
	if not job.is_empty() or not String(info.get("reason", "")).is_empty():
		return {"command": "", "payload": {}}
	var mode: int = int(pref_state.get("mode", Mode.SINGLE))
	var payload := work_payload(String(info.island), recipe_id, mode, int(pref_state.get("count", 1)), {})
	return {"command": "craft", "payload": payload}

static func stop_action(job: Dictionary, island: String) -> Dictionary:
	if job.is_empty() or finishing(job):
		return {"command": "", "payload": {}}
	return {"command": "stop_processing", "payload": {"island_id": island}}
