class_name OfflineCoordinator
extends RefCounted

static func settle(now_utc_ms: int) -> Dictionary:
	var state: Variant = SaveManager.load_state()
	if state == null:
		return {"ok": false, "report": {}, "error": "NO_STATE", "committed": false, "state": null}
	var content: Variant = SaveManager.content()
	if content == null:
		return {"ok": false, "report": {}, "error": "NO_CONTENT", "committed": false, "state": null}
	var last_settled: int = SaveManager.last_settled_utc_ms()
	var working: GameState = state.duplicate_state()
	var settlement: Dictionary = OfflineSettlement.settle(working, content, now_utc_ms, last_settled)
	var report: Dictionary = settlement["report"]
	if bool(report["rollback"]):
		return {"ok": true, "report": report, "error": "", "committed": false, "state": state}
	working.revision += 1
	var sim_tick: int = int(floor(working.total_elapsed_seconds / 60.0))
	var meta: Dictionary = {
		"save_id": "local",
		"saved_at_utc_ms": str(now_utc_ms),
		"settled_until_utc_ms": str(now_utc_ms),
		"sim_tick": str(sim_tick),
		"last_offline_report": report,
	}
	var save_result: Dictionary = SaveManager.save(working, meta)
	if not bool(save_result.get("ok", false)):
		return {"ok": false, "report": report, "error": "SAVE_FAILED", "committed": false, "state": state}
	return {"ok": true, "report": report, "error": "", "committed": true, "state": working}
