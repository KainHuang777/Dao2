class_name LifeReport
extends RefCounted
## Deterministic prose from one validated LifeLedger record. Never observes inventory/RNG.
const VERSION := "report-1a-2-echo"
const ORDER := ["cloud", "after", "core", "routes", "companion", "sect", "garden", "hut", "quiet", "fallback"]
const TITLES := ["雲外初行", "劫後續途", "丹成有記", "雲路相連", "同行一程", "山門留跡", "草木成居", "一屋初築", "靜修有痕", "此世行跡"]
const COPY := [
	["初居山中，築屋修行。", "其後開拓青木、玄礦兩島，往來漸遠。", "及至結丹，山中所記又添一頁。"],
	["曾於渡劫中受挫。", "此後仍有晉階之記，修行未止於當日。"],
	["此世曾結金丹，留下一頁修行之記。"],
	["先後開拓青木、玄礦兩島。", "航船已有貨物運抵，雲路開始承載往來。"],
	["此世得一靈獸。", "後見其長成，同行之日於此有記。"],
	["此世入宗門，留名山中。", "委託已有完成之記，不只一紙派遣。"],
	["先築一屋，而後建成靈草圃。", "居處之外，又添一處草木之地。"],
	["此世有築屋之記，山中初有棲身之所。"],
	["此世修行曾進一層，留有晉階之記。"],
	["卷中所存有限，未有完整紀錄。"]]

static func _first(events: Array, kind: String, subject: String = "") -> Dictionary:
	for event in events:
		if event.kind == kind and (subject.is_empty() or event.subject == subject):
			return event
	return {}

static func _after(events: Array, first: Dictionary, kind: String, instance: String = "") -> Dictionary:
	if first.is_empty(): return {}
	for event in events:
		if event.kind == kind and int(event.seq) > int(first.seq) and (instance.is_empty() or event.instance == instance):
			return event
	return {}

static func _refs(events: Array) -> Array:
	var result := []
	for event in events:
		if not event.is_empty() and not int(event.seq) in result: result.append(int(event.seq))
	return result

static func generate(life: Dictionary, reason: String = "living") -> Dictionary:
	var events: Array = life.get("events", [])
	var hut := _first(events, "building_built", "hut")
	var wood := _first(events, "island_opened", "wood")
	var ore := _first(events, "island_opened", "ore")
	var core := _first(events, "era_breakthrough", "2:3")
	var failed := _first(events, "tribulation_failed")
	var later := _after(events, failed, "cultivation_leveled_up")
	var arrival := _first(events, "cargo_arrived")
	var beast := {}
	var mature := {}
	# A later acquired beast can qualify even when an earlier one did not mature.
	for event in events:
		if event.kind == "beast_acquired" and not String(event.instance).is_empty():
			var candidate := _after(events, event, "beast_matured", String(event.instance))
			if not candidate.is_empty() and candidate.subject == event.subject:
				beast = event
				mature = candidate
				break
	var sect := _first(events, "joined_sect")
	var quest := _after(events, sect, "expedition_completed")
	var garden := _first(events, "building_built", "herb_farm")
	var level := _first(events, "cultivation_leveled_up")
	var index := 9
	var sources := [[]]
	# The temporal words in the cloud copy require this order, even if all facts exist.
	if not hut.is_empty() and not wood.is_empty() and not ore.is_empty() and not core.is_empty() and int(hut.seq) < mini(int(wood.seq), int(ore.seq)) and int(core.seq) > maxi(int(wood.seq), int(ore.seq)):
		index = 0
		sources = [[hut], [wood, ore], [core]]
	elif not later.is_empty():
		index = 1
		sources = [[failed], [later]]
	elif not core.is_empty():
		index = 2
		sources = [[core]]
	elif not wood.is_empty() and not ore.is_empty() and not arrival.is_empty():
		index = 3
		sources = [[wood, ore], [arrival]]
	elif not mature.is_empty():
		index = 4
		sources = [[beast], [mature]]
	elif not quest.is_empty():
		index = 5
		sources = [[sect], [quest]]
	elif not hut.is_empty() and not garden.is_empty():
		index = 6
		sources = [[hut, garden], [garden]]
	elif not hut.is_empty():
		index = 7
		sources = [[hut]]
	elif not level.is_empty():
		index = 8
		sources = [[level]]
	var sentences := []
	var all_refs := []
	for n in COPY[index].size():
		var text: String = COPY[index][n]
		if index == 6 and n == 0 and int(hut.seq) > int(garden.seq):
			text = "此世築屋，亦建成靈草圃。"
		var refs := _refs(sources[n])
		sentences.append({"text": text, "refs": refs})
		for ref in refs:
			if not ref in all_refs: all_refs.append(ref)
	var traces := all_refs.slice(0, 3)
	if index == 0: traces = [int(hut.seq), int(wood.seq), int(core.seq)]
	var closing := "行跡仍在續寫。"
	if reason == "lifespan_exhausted": closing = "一世行止，於此收卷。"
	elif reason == "rebirth_lotus": closing = "此卷暫擱，待另啟新程。"
	var report := {"version": VERSION, "title_id": ORDER[index], "title": TITLES[index], "closing": closing, "sentences": sentences, "traces": traces}
	var echoes := LifeEcho.generate(life)
	if not echoes.is_empty():
		report.echo_version = LifeEcho.VERSION
		report.echoes = echoes
	return report

static func read(life: Dictionary, reason: String = "living") -> Dictionary:
	if life.get("end_state", {}).is_empty(): return generate(life, reason)
	# Older facts without frozen text remain readable, but do not acquire a new past biography.
	var frozen: Variant = JSON.parse_string(String(life.get("frozen_text", ""))) if not String(life.get("frozen_text", "")).is_empty() else null
	if frozen is Dictionary and frozen.get("title") is String and frozen.get("closing") is String and frozen.get("sentences") is Array and frozen.get("traces") is Array:
		var safe: bool = frozen.sentences.size() <= 3 and frozen.traces.size() <= 3
		if frozen.has("echoes"):
			safe = safe and frozen.get("echo_version") == LifeEcho.VERSION and LifeEcho.valid(frozen.echoes)
			if safe: frozen.echo_version = int(frozen.echo_version)
		for sentence in frozen.sentences:
			if not sentence is Dictionary or not sentence.get("text") is String or not sentence.get("refs") is Array:
				safe = false
				break
			for n in sentence.refs.size():
				if not sentence.refs[n] is float and not sentence.refs[n] is int:
					safe = false
					break
				sentence.refs[n] = int(sentence.refs[n])
		for n in frozen.traces.size():
			if not frozen.traces[n] is float and not frozen.traces[n] is int:
				safe = false
				break
			frozen.traces[n] = int(frozen.traces[n])
		if safe: return frozen.duplicate(true)
	return {"version": "", "title_id": "unrecorded", "title": "此世行跡", "closing": "此世小傳未記錄。", "sentences": [], "traces": []}
