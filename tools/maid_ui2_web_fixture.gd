extends SceneTree

func _init() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	if content == null:
		quit(1)
		return
	if not IslandProgression.attach_supply(content).ok:
		quit(1)
		return
	var session := GameSession.create_new_game(content, 20261101)
	var state := session.state
	state.buildings.hut = 1
	state.buildings.herb_farm = 3
	for id in ["spirit_grass_low", "black_copper", "lingli", "money", "wood", "stone_low"]:
		state.resources[id] = {"value": AmountCompat.from_number(100000.0), "unlocked": true, "ever_obtained": true}
	state.resources["foundation_pill"] = {"value": AmountCompat.zero(), "unlocked": true, "ever_obtained": false}
	var recruited := session.recruit_maid("qingheng")
	if not bool(recruited.get("ok", false)):
		print("FIXTURE FAIL recruit: ", recruited)
		quit(1)
		return
	var assigned := session.assign_maid_duty("qingheng", {"kind": "steward_stock", "recipe_id": "foundation_pill", "target": 20, "reserve": {}})
	if not bool(assigned.get("ok", false)):
		print("FIXTURE FAIL assign: ", assigned)
		quit(1)
		return
	state.maid.maids.qingheng.duty_actions = 10
	var claimed := session.claim_maid_chapter("qingheng", "qingheng_1")
	if not bool(claimed.get("ok", false)):
		print("FIXTURE FAIL claim: ", claimed)
		quit(1)
		return
	var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
	var settled_ms := now_ms - 30 * 60 * 1000
	var probe_state := state.duplicate_state()
	var probe := OfflineSettlement.settle(probe_state, content, now_ms, settled_ms)
	var maid_report: Dictionary = probe["report"].get("maid", {})
	if int(maid_report.get("actions", 0)) <= 0:
		print("FIXTURE FAIL offline probe: ", probe["report"])
		print("FIXTURE duty status: ", probe_state.maid.maids.qingheng.duty)
		quit(1)
		return
	var meta := {
		"save_id": "maid_ui2_fixture",
		"saved_at_utc_ms": str(now_ms),
		"settled_until_utc_ms": str(settled_ms),
		"sim_tick": str(int(state.total_elapsed_seconds)),
	}
	var encoded := SaveCodec.encode(state, content.content_version, meta)
	if not encoded.ok:
		print("FIXTURE FAIL encode: ", encoded.get("error", ""))
		quit(1)
		return
	var file := FileAccess.open("res://docs/verification/artifacts/maid-ui2-duty-fixture.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	print("PASS: maid-ui2 fixture actions=%d units=%d" % [int(maid_report.get("actions", 0)), int(maid_report.get("units", 0))])
	quit(0)
