extends RefCounted
## Test-only ownership policy composed over existing B rules; no release registration.
const PATH := "res://tests/fixtures/res1d1/era3.json"

static func attach(content: GameContent) -> Dictionary:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(fixture.fixture_version == "res1-d1-1")
	content.eras[3] = fixture.era
	content.era_ids.append(3)
	content.processing_catalog = ProcessingCatalog.load_file().catalog
	content.buildings.storage_lingli.effects.lingli_max = fixture.capacity_proposal.per_level
	content.content_version += "+isolated-res1-d1-1"
	return fixture

static func craft(content: GameContent, state: GameState, p: Dictionary, fixture: Dictionary) -> Dictionary:
	var id: String = p.get("recipe_id", "")
	if fixture.producers.has(id) and fixture.producers[id] != p.get("island_id", "home"):
		return {"ok": false, "error": "RECIPE_ISLAND_REQUIREMENT"}
	return ProcessingSystem.craft(content, state, p)
