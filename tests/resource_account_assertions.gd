extends RefCounted
## Existing economic/RNG snapshots stay exact. Grouped account additions use
## the declared Amount comparison; no economic field is rounded or removed.
static func economic_snapshot(state: GameState) -> String:
	var data := state.to_snapshot_dict()
	var ledger: Dictionary = data.get("life_ledger", {})
	if not ledger.is_empty():
		ledger.current.erase("accounts")
		ledger.current.erase("history")
		for life in ledger.archive:
			life.erase("accounts")
			life.erase("history")
	return JSON.stringify(SaveCodec._normalize_numbers(data), "", true)
static func accounts_equal(a: GameState, b: GameState) -> bool:
	var aa: Dictionary = a.life_ledger
	var bb: Dictionary = b.life_ledger
	if aa.is_empty() or bb.is_empty(): return aa == bb
	if not ResourceLedger.equivalent(aa.current.get("accounts", {}), bb.current.get("accounts", {})): return false
	if aa.archive.size() != bb.archive.size(): return false
	for index in aa.archive.size():
		if not ResourceLedger.equivalent(aa.archive[index].get("accounts", {}), bb.archive[index].get("accounts", {})): return false
	return true
static func history_equal(a: GameState, b: GameState) -> bool:
	if a.life_ledger.is_empty() or b.life_ledger.is_empty(): return a.life_ledger == b.life_ledger
	var aa: Array = a.life_ledger.archive.duplicate()
	aa.append(a.life_ledger.current)
	var bb: Array = b.life_ledger.archive.duplicate()
	bb.append(b.life_ledger.current)
	if aa.size() != bb.size(): return false
	for i in aa.size():
		var x: Dictionary = aa[i].get("history", {})
		var y: Dictionary = bb[i].get("history", {})
		if x.is_empty() or y.is_empty():
			if x != y: return false
			continue
		if not LifeHistory.validate(x, aa[i]).is_empty() or not LifeHistory.validate(y, bb[i]).is_empty(): return false
		if not LifeHistory.equivalent(x, y): return false
	return true
static func same(a: GameState, b: GameState) -> bool:
	return economic_snapshot(a) == economic_snapshot(b) and accounts_equal(a, b) and history_equal(a, b)
