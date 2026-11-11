class_name SectEntry
extends RefCounted
## ENTRY-only tutorial receipt. No life clock, story RNG, NPCs or rewards.
const FLAGS := ["invite_seen", "intro_seen", "first_dispatch", "first_claim", "skip", "legacy_review"]

static func initial(legacy: bool = false, dispatched: bool = false) -> Dictionary:
	return {"version": 1, "invite_seen": false, "intro_seen": false, "first_dispatch": dispatched, "first_claim": false, "skip": false, "legacy_review": legacy}

static func validate(sect: Dictionary) -> String:
	if not sect.has("entry"): return ""
	var e: Variant = sect.entry
	if not e is Dictionary or e.size() != 7 or e.get("version") != 1: return "SECT_ENTRY_VERSION"
	for key in FLAGS:
		if not e.get(key) is bool: return "SECT_ENTRY_FLAG"
	if e.first_claim and not e.first_dispatch: return "SECT_ENTRY_ORDER"
	return ""

static func receipt(state: GameState) -> Dictionary:
	return state.sect.get("entry", initial(bool(state.sect.get("unlocked", false)), state.sect.get("active_expedition") is Dictionary)).duplicate(true)

static func invitation(state: GameState) -> bool:
	if not SectSystem.is_unlocked(state) or bool(state.sect.get("unlocked", false)) or receipt(state).invite_seen: return false
	return true

static func acknowledge(state: GameState, action: String) -> Dictionary:
	if not SectSystem.is_unlocked(state): return {"ok": false, "error": "SECT_LOCKED"}
	if action not in ["later", "intro", "skip", "review", "finish"]: return {"ok": false, "error": "SECT_ENTRY_ACTION"}
	var e := receipt(state)
	if action != "later" and not bool(state.sect.get("unlocked", false)): return {"ok": false, "error": "SECT_LOCKED"}
	if action == "finish" and not e.first_claim: return {"ok": false, "error": "SECT_ENTRY_FIRST_CLAIM"}
	e.invite_seen = true
	if action == "intro": e.intro_seen = true
	if action in ["skip", "review", "finish"]: e.skip = true
	state.sect.entry = e
	return {"ok": true, "events": [{"kind": "sect_entry_acknowledged", "action": action}], "changed_ids": ["sect"]}

static func note(state: GameState, key: String) -> void:
	var e := receipt(state)
	e[key] = true
	if key == "first_claim": e.first_dispatch = true
	state.sect.entry = e

static func guidance(state: GameState) -> Dictionary:
	if not SectSystem.is_unlocked(state): return {}
	var e := receipt(state)
	if not bool(state.sect.get("unlocked", false)):
		return {"step": "invitation", "text": "山門訪帖：可擇一宗拜入，歷練所得貢獻可研習功法或兌換物資。也可稍後，繼續準備金丹。"}
	if e.skip: return {}
	if e.legacy_review:
		return {"step": "review", "text": "舊宗門進度保留。派遣、功法與坊市照常可用；首次領取歷史不明，不補發獎勵。可閱讀無獎回顧後繼續。"}
	if not e.intro_seen:
		return {"step": "intro", "text": "見禮：歡迎入山。先接一份合資格的短委託，回報所得貢獻可用於功法或坊市。導覽可略過，不影響修行。"}
	if e.first_claim:
		var owned := AmountCompat.try_parse(String(state.sect.get("contribution", "0")))
		var target := "坊市靈石錦袋需50貢獻；可先繼續歷練，不必立即購買。"
		for id in SectSystem.MARKET_ITEMS:
			if id != "stone_bundle": continue
			var item: Dictionary = SectSystem.MARKET_ITEMS[id]
			if int(item.get("min_era", 1)) > state.era_id: continue
			if int(state.sect.get("market_purchases", {}).get(id, 0)) >= int(item.get("limit", 0)): continue
			if owned.ok and owned.value.compare_to(AmountCompat.from_number(float(item.cost))) >= 0:
				target = "可到坊市查看%s（%s貢獻）；購買為可選。" % [item.name, str(item.cost)]
				break
		return {"step": "report", "text": "首報已完成。" + target}
	var active: Variant = state.sect.get("active_expedition")
	if active is Dictionary:
		return {"step": "dispatch", "text": "首務進行中；倒數結束後手動領取，關頁不代領。可繼續修行與建設。"}
	var recommended := ""
	var duration := 2147483647
	for task in state.sect.get("available_tasks", []):
		if int(task.get("min_era", 1)) > state.era_id or not GuardianDiscovery.claim_error(state, task).is_empty(): continue
		if int(task.get("duration", 0)) < duration:
			recommended = String(task.id)
			duration = int(task.duration)
	return {"step": "dispatch", "task_id": recommended, "text": "推薦當前最短的合資格委託；派遣仍由你確認。" if not recommended.is_empty() else "目前沒有合資格委託；可用下方正常刷新入口，冷卻不會被導覽跳過。"}
