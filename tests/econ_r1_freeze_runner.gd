extends SceneTree
var checks := 0
var failures: Array = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL " + label)

func _run() -> void:
	var fixture_text: String = FileAccess.get_file_as_string("res://tests/fixtures/econ_r1_f/tuning-freeze.json")
	var parsed: Variant = JSON.parse_string(fixture_text)
	_check(parsed is Dictionary, "fixture parse failure bytes=" + str(fixture_text.length()))
	if not parsed is Dictionary:
		_finish()
		return
	var fx: Dictionary = parsed
	_check(str(fx.get("version", "")) == "econ-r1-freeze-1", "fixture version expected=econ-r1-freeze-1 actual=" + str(fx.get("version", "")))
	_pins(fx)
	_constants(fx)
	_inheritance(fx)
	_durations()
	_slice(fx)
	_profile(fx)
	_finish()

func _finish() -> void:
	print("ECON-R1-F freeze checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func _pins(fx: Dictionary) -> void:
	var files: Dictionary = fx.get("files", {})
	for path in files:
		var file_path: String = str(path)
		var expected: String = files[path]
		var actual: String = FileAccess.get_sha256(file_path).to_lower()
		_check(actual == expected, file_path + " sha256 expected=" + expected + " actual=" + actual)

func _constants(fx: Dictionary) -> void:
	var effects: Dictionary = fx.get("effects", {})
	var limits: Dictionary = effects.get("limits", {})
	for key in EconomyEffects.LIMITS:
		var family: String = str(key)
		var expected: Variant = limits.get(family, null)
		_check(expected != null and is_equal_approx(float(expected), float(EconomyEffects.LIMITS[key])), "src/economy/economy_effects.gd LIMITS." + family + " expected=" + str(expected) + " actual=" + str(EconomyEffects.LIMITS[key]))
	_check(EconomyEffects.LIMITS.size() == limits.size(), "src/economy/economy_effects.gd LIMITS size expected=" + str(limits.size()) + " actual=" + str(EconomyEffects.LIMITS.size()))
	var precision: Variant = effects.get("precision", null)
	_check(precision != null and is_equal_approx(float(precision), EconomyEffects.PRECISION), "src/economy/economy_effects.gd PRECISION expected=" + str(precision) + " actual=" + str(EconomyEffects.PRECISION))
	var max_amount: Variant = effects.get("max_amount", null)
	_check(max_amount != null and is_equal_approx(float(max_amount), EconomyEffects.MAX_AMOUNT), "src/economy/economy_effects.gd MAX_AMOUNT expected=" + str(max_amount) + " actual=" + str(EconomyEffects.MAX_AMOUNT))
	_check(ResearchSystem.VERSION == str(fx.get("research_version", "")), "src/economy/research_system.gd VERSION expected=" + str(fx.get("research_version", "")) + " actual=" + ResearchSystem.VERSION)
	var research: Dictionary = fx.get("research", {})
	_check(ResearchSystem.MAX_SECONDS == int(research.get("max_seconds", -1)), "src/economy/research_system.gd MAX_SECONDS expected=" + str(research.get("max_seconds")) + " actual=" + str(ResearchSystem.MAX_SECONDS))
	_check(int(research.get("min_seconds", -1)) == 10, "fixture min_seconds expected=10 actual=" + str(research.get("min_seconds")))

func _inheritance(fx: Dictionary) -> void:
	var locked: Dictionary = fx.get("inheritance", {})
	var tiers: Array = locked.get("tiers", [])
	var research: Dictionary = ResearchSystem.initial()
	for frontier in [0, 1, 2, 3, 5, 6]:
		research.inherited_depth = int(frontier)
		var expected_raw: float = _tier_raw(tiers, int(frontier))
		var result: Dictionary = ResearchSystem.inheritance({}, research)
		if not result.ok:
			_check(false, "src/economy/research_system.gd inheritance frontier=" + str(frontier) + " not ok error=" + str(result.get("error", "")))
			continue
		_check(is_equal_approx(float(result.raw), expected_raw), "src/economy/research_system.gd inheritance raw frontier=" + str(frontier) + " expected=" + str(expected_raw) + " actual=" + str(result.raw))
		_check(is_equal_approx(float(result.effective), expected_raw), "src/economy/economy_effects.gd inheritance effective frontier=" + str(frontier) + " expected=" + str(expected_raw) + " actual=" + str(result.effective))
		_check(is_equal_approx(float(result.limit), float(locked.get("limit", 0.0))), "src/economy/economy_effects.gd inheritance limit expected=" + str(locked.get("limit")) + " actual=" + str(result.limit))
		var sources: Array = result.get("sources", [])
		if sources.size() == 1:
			_check(str(sources[0].get("effect_id", "")) == str(locked.get("effect_id", "")) and str(sources[0].get("source", "")) == str(locked.get("source", "")), "inheritance effect metadata frontier=" + str(frontier) + " effect_id expected=" + str(locked.get("effect_id")) + " actual=" + str(sources[0].get("effect_id", "")) + " source expected=" + str(locked.get("source")) + " actual=" + str(sources[0].get("source", "")))
		else:
			_check(false, "inheritance effect metadata frontier=" + str(frontier) + " sources size expected=1 actual=" + str(sources.size()))
		_check(EconomyEffects.valid_reduction(result), "inheritance valid reduction frontier=" + str(frontier))

func _tier_raw(tiers: Array, frontier: int) -> float:
	var best := -1
	var raw := 0.0
	for tier in tiers:
		var level: int = int(tier.get("frontier", -1))
		if level <= frontier and level >= best:
			best = level
			raw = float(tier.get("raw", 0.0))
	return raw

func _red(raw: float) -> Dictionary:
	var source: Dictionary = {"effect_id": "probe", "family": "research_inheritance", "scope": "research", "unit": "reduction", "stack_mode": "sum_then_dr", "limit": EconomyEffects.LIMITS["research_inheritance"], "source": "unique_completed_frontier", "value": raw}
	return EconomyEffects.resolve("research_inheritance", "research", [source])

func _durations() -> void:
	var red_zero: Dictionary = _red(0.0)
	var red_limit: Dictionary = _red(0.7)
	_check(red_zero.ok and red_limit.ok, "duration reduction resolve")
	if not (red_zero.ok and red_limit.ok):
		return
	_check(is_equal_approx(float(red_limit.effective), 0.6125), "src/economy/economy_effects.gd DR vector D(0.7,0.7) expected=0.6125 actual=" + str(red_limit.effective))
	var base_no_reduction: Dictionary = EconomyEffects.duration(100, red_zero, 10)
	if not base_no_reduction.ok:
		_check(false, "duration(100,0.0,10) not ok error=" + str(base_no_reduction.get("error", "")))
	else:
		_check(base_no_reduction.seconds == 100, "duration(100,0.0,10) seconds expected=100 actual=" + str(base_no_reduction.seconds))
	var limit_raw: Dictionary = EconomyEffects.duration(100, red_limit, 10)
	if not limit_raw.ok:
		_check(false, "duration(100,0.7,10) not ok error=" + str(limit_raw.get("error", "")))
	else:
		_check(limit_raw.seconds == 39, "duration(100,0.7,10) seconds expected=39 actual=" + str(limit_raw.seconds))
	var zero_base: Dictionary = EconomyEffects.duration(0, red_zero, 10)
	_check(not zero_base.ok and str(zero_base.get("error", "")) == "DURATION_DOMAIN", "duration(0,...) expected DURATION_DOMAIN actual=" + str(zero_base.get("error", "")))
	var floor_probe: Dictionary = EconomyEffects.duration(3, red_zero, 10)
	if not floor_probe.ok:
		_check(false, "duration(3,0.0,10) not ok")
	else:
		_check(floor_probe.seconds == 10, "duration(3,0.0,10) floor clamp expected=10 actual=" + str(floor_probe.seconds))
	var default_minimum: Dictionary = EconomyEffects.duration(100, red_limit)
	if not default_minimum.ok:
		_check(false, "duration(100,0.7) not ok")
	else:
		_check(default_minimum.seconds == 39, "duration(100,0.7) seconds expected=39 actual=" + str(default_minimum.seconds))

func _slice(fx: Dictionary) -> void:
	var built := EconomySlice.create_frontier()
	if not built.ok:
		_check(false, "src/economy/economy_slice.gd create_frontier ok=false error=" + str(built.get("error", "")))
		return
	if not built.content is GameContent:
		_check(false, "create_frontier content type unexpected")
		return
	var content: GameContent = built.content
	var catalog: Dictionary = built.catalog
	_check(str(catalog.get("version", "")) == str(fx.get("research_version", "")), "catalog version expected=" + str(fx.get("research_version")) + " actual=" + str(catalog.get("version")))
	var nodes: Array = catalog.get("nodes", [])
	_check(nodes.size() == 14, "catalog nodes size expected=14 actual=" + str(nodes.size()))
	var by_id: Dictionary = {}
	for node in nodes:
		var node_id: String = str(node.get("id", ""))
		_check(not node_id.is_empty() and not by_id.has(node_id), "catalog node id unique " + node_id)
		by_id[node_id] = node
	_check(by_id.size() == 14, "catalog unique ids expected=14 actual=" + str(by_id.size()))
	var locked: Dictionary = fx.get("nodes", {})
	_check(locked.size() == 14, "fixture nodes size expected=14 actual=" + str(locked.size()))
	for frozen_id in locked:
		var frozen_key: String = str(frozen_id)
		if not by_id.has(frozen_key):
			_check(false, "nodes " + frozen_key + " missing from catalog")
			continue
		_compare_node(locked[frozen_id], by_id[frozen_key], frozen_key)
	var data: Dictionary = EconomySlice.component_data()
	_strict(fx.get("components", {}), data, "components")
	_content(fx, content)

func _node_file(node_id: String) -> String:
	var index: int = int(node_id.substr(1))
	if index <= 7:
		return "content/research/econ_r1.json"
	if index <= 11:
		return "content/research/econ_r1_d1.json"
	return "content/research/econ_r1_d2.json"

func _compare_node(frozen: Variant, loaded: Variant, node_id: String) -> void:
	if not frozen is Dictionary or not loaded is Dictionary:
		_check(false, "nodes " + node_id + " wrong type expected=dictionary actual=" + str(typeof(loaded)))
		return
	var fx_node: Dictionary = frozen
	var loaded_node: Dictionary = loaded
	var path: String = _node_file(node_id) + " nodes." + node_id
	_check(loaded_node.has("id") and str(loaded_node.get("id")) == node_id, path + ".id expected=" + node_id + " actual=" + str(loaded_node.get("id")))
	for key in fx_node:
		var key_name: String = str(key)
		if key_name == "prereq":
			_strict(fx_node[key], loaded_node.get("prerequisites", "__missing__"), path + ".prereq")
			continue
		_strict(fx_node[key], loaded_node.get(key_name, "__missing__"), path + "." + key_name)
	for key in loaded_node:
		var loaded_key: String = str(key)
		if loaded_key == "id":
			continue
		if loaded_key == "prerequisites":
			loaded_key = "prereq"
		if not fx_node.has(loaded_key):
			_check(false, path + "." + str(key) + " extra loaded key not frozen")

func _strict(expected: Variant, actual: Variant, path: String) -> void:
	if expected is Dictionary:
		if not actual is Dictionary:
			_check(false, path + " expected dictionary actual=" + str(actual) + " types=" + str(typeof(expected)) + "/" + str(typeof(actual)))
			return
		var expected_map: Dictionary = expected
		var actual_map: Dictionary = actual
		for key in expected_map:
			var path_key: String = str(key)
			if not actual_map.has(path_key):
				_check(false, path + "." + path_key + " missing key")
				continue
			_strict(expected_map[key], actual_map[path_key], path + "." + path_key)
		for key in actual_map:
			if not expected_map.has(str(key)):
				_check(false, path + "." + str(key) + " extra key")
		return
	if expected is Array:
		if not actual is Array:
			_check(false, path + " expected array actual=" + str(actual) + " types=" + str(typeof(expected)) + "/" + str(typeof(actual)))
			return
		var expected_list: Array = expected
		var actual_list: Array = actual
		_check(expected_list.size() == actual_list.size(), path + " size expected=" + str(expected_list.size()) + " actual=" + str(actual_list.size()))
		var count: int = mini(expected_list.size(), actual_list.size())
		for index in count:
			_strict(expected_list[index], actual_list[index], path + "[" + str(index) + "]")
		return
	if typeof(expected) != typeof(actual) or expected != actual:
		_check(false, path + " expected=" + str(expected) + " actual=" + str(actual) + " types=" + str(typeof(expected)) + "/" + str(typeof(actual)))

func _content(fx: Dictionary, content: GameContent) -> void:
	var tag: String = str(content.content_version)
	_check(tag.ends_with("+econ-r1-d2-1"), "content content_version suffix expected=+econ-r1-d2-1 actual=" + tag)
	var comps: Dictionary = fx.get("components", {})
	var resources: Dictionary = comps.get("resources", {})
	for resource in ["mithril_matrix", "void_array"]:
		var resource_id: String = str(resource)
		if not content.resources.has(resource_id):
			_check(false, "content resources missing " + resource_id)
			continue
		var expected_max: float = float(resources.get(resource_id, {}).get("cap", "0"))
		var actual_max: Variant = content.resources[resource_id].get("max", null)
		_check(actual_max is float and is_equal_approx(float(actual_max), expected_max), "content." + resource_id + ".max expected=" + str(expected_max) + " actual=" + str(actual_max))
	for building in ["research_instruments", "matrix_storehouse", "void_condenser", "void_harvester"]:
		_check(content.buildings.has(str(building)), "content buildings exists " + str(building))
	var econ: Variant = content.processing_catalog.get("econ_r1", {})
	if not econ is Dictionary:
		_check(false, "content processing_catalog.econ_r1 missing")
	else:
		_check(econ.get("stage") == 6, "content processing_catalog.econ_r1.stage expected=6 actual=" + str(econ.get("stage", null)))

func _profile(fx: Dictionary) -> void:
	var locked: Dictionary = fx.get("profile", {})
	_check(EconomyProfile.PROFILE == str(locked.get("profile", "")), "src/economy/economy_profile.gd PROFILE expected=" + str(locked.get("profile")) + " actual=" + EconomyProfile.PROFILE)
	_check(EconomyProfile.SCHEMA == int(locked.get("schema", -1)), "src/economy/economy_profile.gd SCHEMA expected=" + str(locked.get("schema")) + " actual=" + str(EconomyProfile.SCHEMA))
	_check(EconomyProfile.RULES == str(locked.get("rules", "")), "src/economy/economy_profile.gd RULES expected=" + str(locked.get("rules")) + " actual=" + EconomyProfile.RULES)
	_check(EconomyProfile.ECONOMY == str(locked.get("economy", "")), "src/economy/economy_profile.gd ECONOMY expected=" + str(locked.get("economy")) + " actual=" + EconomyProfile.ECONOMY)
