extends SceneTree
## In-memory audit only: never opens SaveManager or user:// player slots.

func _init() -> void:
	var loaded: Dictionary = ContentLoader.load_directory("res://content")
	if not bool(loaded.get("ok", false)):
		push_error(str(loaded))
		quit(1)
		return
	var content: GameContent = loaded.content
	var session := GameSession.create_new_game(content)
	# Explicit completed-era fixture; this is not a timed new-player playthrough.
	for id in content.building_ids:
		session.state.buildings[id] = CommandProcessor.level_cap(content.buildings[id])
	for id in content.resource_ids:
		session.state.resources[id].unlocked = true
	session.state.level = 10
	var before := session.get_view()
	var breakthrough := session.submit({"command_id": "audit-breakthrough", "type": "breakthrough_era", "expected_revision": 0, "payload": {}})
	if not bool(breakthrough.get("ok", false)):
		push_error(str(breakthrough))
		quit(1)
		return
	var after := session.get_view()
	var new_buildings: Array = []
	var new_resources: Array = []
	for id in after.buildings:
		if bool(after.buildings[id].visible) and not bool(before.buildings.get(id, {}).get("visible", false)):
			new_buildings.append(id)
	for id in after.resources:
		if bool(after.resources[id].visible) and not bool(before.resources.get(id, {}).get("visible", false)):
			new_resources.append(id)
	var raw_resources: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/resources/era1.json"))
	var raw_buildings: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/buildings/era1.json"))
	var advanced := raw_resources.duplicate(true)
	advanced.append({"id": "audit_advanced", "type": "advance", "max": 100, "rate": 0, "unlocked": false})
	var advanced_result := ContentLoader.build_content(advanced, raw_buildings)
	var with_metadata := raw_resources.duplicate(true)
	with_metadata[0]["prereqEra"] = 2
	with_metadata[0]["prereqSkill"] = "basic_meditation"
	with_metadata[0]["recipe"] = {"wood": 1}
	var metadata_result := ContentLoader.build_content(with_metadata, raw_buildings)
	var plain_result := ContentLoader.build_content(raw_resources, raw_buildings)
	var pill_session := GameSession.create_new_game(content)
	pill_session.state.era_id = 2
	for id in pill_session.state.resources:
		pill_session.state.resources[id].value = AmountCompat.from_number(1000000.0)
	pill_session.state.resources["foundation_pill"].value = AmountCompat.zero()
	var refine := pill_session.refine_pill("foundation_pill", 201)
	if not bool(refine.get("ok", false)):
		push_error(str(refine))
		quit(1)
		return
	var pill_resource_value: String = pill_session.state.resources["foundation_pill"].value.serialize()
	var pill_count: int = int(pill_session.state.pills.get("foundation_pill", 0))
	# Simulate a snapshot containing resources but no pills inventory, as legacy mapping can do.
	pill_session.state.pills.clear()
	var consume_without_duplicate_inventory := AlchemySystem.can_consume(pill_session.state, "foundation_pill", 1)
	var encoded := SaveCodec.encode(session.state, content.content_version, {"save_id": "audit-memory", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"})
	if not bool(encoded.get("ok", false)):
		push_error(str(encoded))
		quit(1)
		return
	var decoded := SaveCodec.decode(String(encoded.json))
	if not bool(decoded.get("ok", false)):
		push_error(str(decoded))
		quit(1)
		return
	var expanded_content: GameContent = ContentLoader.build_content(raw_resources + [{"id": "audit_new_resource", "type": "basic", "max": 10, "rate": 0, "unlocked": false}], raw_buildings).content
	var evidence := {
		"scope": "in_memory_fixture_not_browser_or_real_time_playthrough",
		"resource_count": content.resource_ids.size(), "building_count": content.building_ids.size(), "era_ids": content.era_ids,
		"breakthrough_ok": breakthrough.ok, "after_era": session.state.era_id,
		"new_visible_buildings": new_buildings, "new_visible_resources": new_resources,
		"alchemy_ids": AlchemySystem.PILLS.keys(),
		"generic_craft_registered": "craft" in GameSession.KNOWN_COMMAND_TYPES,
		"advance_type_accepted": advanced_result.ok, "advance_errors": advanced_result.get("errors", []),
		"prereq_and_recipe_retained": metadata_result.content.resources.lingli.has("prereqEra") or metadata_result.content.resources.lingli.has("recipe"),
		"metadata_changes_content_hash": metadata_result.content.content_version != plain_result.content.content_version,
		"foundation_refine_201_ok": refine.ok, "foundation_resource_value": pill_resource_value, "foundation_pills_count": pill_count,
		"foundation_base_cap": content.resources.foundation_pill.max,
		"foundation_consume_from_resource_only": consume_without_duplicate_inventory,
		"snapshot_roundtrip_ok": decoded.ok,
		"added_content_resource_in_restored_state": decoded.state.resources.has("audit_new_resource"),
		"expanded_content_has_added_resource": expanded_content.resources.has("audit_new_resource"),
		"lingli_cap_before": before.resources.lingli.cap, "lingli_cap_after": after.resources.lingli.cap,
		"era2_has_next_era": content.era(3) != null,
	}
	var file := FileAccess.open("res://docs/verification/artifacts/content-progression-audit/runtime.json", FileAccess.WRITE)
	if file == null:
		push_error("audit evidence output failed")
		quit(1)
		return
	file.store_string(JSON.stringify(evidence, "\t") + "\n")
	file.close()
	print("CONTENT_PROGRESSION_AUDIT: ", JSON.stringify(evidence))
	quit(0)
