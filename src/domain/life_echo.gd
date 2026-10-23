class_name LifeEcho
extends RefCounted
## Bounded, original retrospective chains. Reads committed facts only; no RNG or rewards.
const VERSION := 1
const LIMIT := 3
const BYTES := 2800

static func _source(event: Dictionary, label: String) -> Dictionary:
	return {"id": str(event.id), "at": float(event.at), "label": label + " · #" + str(int(event.seq))}

static func _row(id: String, title: String, text: String, sources: Array) -> Dictionary:
	return {"id": id, "title": title, "text": text, "sources": sources}

static func _first(events: Array, kind: String) -> Dictionary:
	for event in events:
		if event.kind == kind: return event
	return {}

static func _after(events: Array, first: Dictionary, kind: String, instance: String = "") -> Dictionary:
	if first.is_empty(): return {}
	for event in events:
		if event.kind == kind and int(event.seq) > int(first.seq) and float(event.at) >= float(first.at) and (instance.is_empty() or (event.instance == instance and event.subject == first.subject)): return event
	return {}

static func generate(life: Dictionary) -> Array:
	var rows := []
	var events: Array = life.get("events", [])
	# One supported choice chain: the actual cave inscription choice, then a later level.
	# Strict age order: receipts and milestones do not share a sequence namespace.
	for receipt in life.get("decisions", {}).get("receipts", []):
		if receipt.encounter_id != "enc_ancient_cave" or int(receipt.option_index) != 1 or receipt.option != "凝神參悟石壁心法殘篇" or int(receipt.life_id) != int(life.life_id): continue
		for event in events:
			if event.kind == "cultivation_leveled_up" and float(event.at) > float(receipt.at):
				rows.append(_row("inscription", "石壁之後", "你曾停在殘府石壁前，選擇參悟殘篇。後來卷中又記下一次晉階；石壁已遠，修行仍有新頁。", [{"id":str(receipt.instance_id), "at":float(receipt.at), "label":"機緣所選：參悟石壁殘篇（選項2）"}, _source(event, "修行晉階")]))
				break
		if not rows.is_empty(): break
	var joined := _first(events, "joined_sect")
	var claimed := _after(events, joined, "expedition_claimed")
	if not claimed.is_empty():
		rows.append(_row("sect", "山門回程", "入宗時，山門添了一筆名字。此後你領回委託所得，派出的那一程，終在卷中留下回筆。", [_source(joined, "加入宗門"), _source(claimed, "委託領取")]))
	for event in events:
		if event.kind != "beast_acquired" or str(event.instance).is_empty(): continue
		var mature := _after(events, event, "beast_matured", str(event.instance))
		if mature.is_empty() or mature.subject != event.subject: continue
		rows.append(_row("beast", "同行漸長", "初得靈獸時，卷中只有相逢的一筆。後來，同一位旅伴已長成；從初見到成熟，同行的日子有了兩處落款。", [_source(event, "取得靈獸"), _source(mature, "同一靈獸成熟")]))
		break
	return rows

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() > LIMIT or LifeLedger.bytes(value) > BYTES: return false
	var ids := {}
	for row in value:
		if not row is Dictionary or not LifeLedger._keys(row, ["id", "title", "text", "sources"]): return false
		if not row.id in ["inscription", "sect", "beast"] or ids.has(row.id): return false
		ids[row.id] = true
		for key in ["title", "text"]:
			if not row[key] is String or row[key].to_utf8_buffer().size() > 384: return false
		if not row.sources is Array or row.sources.size() != 2: return false
		for source in row.sources:
			if not source is Dictionary or not LifeLedger._keys(source, ["id", "at", "label"]): return false
			if not LifeLedger._hash(source.id) or not LifeLedger._number(source.at) or not source.label is String or source.label.to_utf8_buffer().size() > 128: return false
		if float(row.sources[1].at) < float(row.sources[0].at): return false
	return true
