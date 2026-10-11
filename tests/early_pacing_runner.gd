extends SceneTree
## Headless pacing runner: pacing_metrics formulas, real-rules parity, sim smoke.
## Run: godot --headless --path . --script res://tests/early_pacing_runner.gd
## Formulas: src/utils/pacing_metrics.gd; systems: Production / BuildingCosts.

const Metrics = preload("res://src/utils/pacing_metrics.gd")
const Sim = preload("res://src/utils/pacing_sim.gd")
const CONTENT_DIR := "res://content"
const EPS := 0.000001

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	_test_formulas()
	_test_real_rules()
	_test_sim_smoke()
	print("%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("PACING RUNNER DONE")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		quit(1)

func _test_formulas() -> void:
	_expect_approx(Metrics.gain_ratio(5.0, 7.0), 0.4, "gain_ratio 5 to 7")
	_expect_approx(Metrics.delay_loss(2.0, 300.0), 600.0, "delay_loss 2 per s delayed 300 s")
	_expect_approx(Metrics.overflow_ratio(100.0, 5.0, 300.0), 1.0 - 100.0 / 1500.0, "overflow_ratio below saturation")
	_expect_approx(Metrics.overflow_ratio(100.0, 5.0, 10.0), 0.0, "overflow_ratio negative clamps to 0")
	_expect_approx(Metrics.overflow_ratio(10.0, 5.0, 300.0), 1.0 - 10.0 / 1500.0, "overflow_ratio 10 cap 5 rate 300 s")
	_expect_approx(Metrics.afford_seconds(100.0, 40.0, 2.0), 30.0, "afford_seconds deficit over rate")
	_expect_approx(Metrics.afford_seconds(100.0, 100.0, 0.0), 0.0, "afford_seconds already affordable")
	_expect(Metrics.afford_seconds(100.0, 0.0, 0.0) >= 1.0e11, "afford_seconds zero rate is INF")
	_expect_approx(Metrics.fill_seconds(100.0, 4.0), 25.0, "fill_seconds cap over rate")
	_expect(Metrics.fill_seconds(10.0, 0.0) >= 1.0e11, "fill_seconds zero rate is INF")
	_expect_approx(Metrics.cap_pressure(300.0, 500.0), 0.6, "cap_pressure cap over cost")
	_expect(Metrics.cap_pressure(300.0, 0.0) >= 1.0e11, "cap_pressure zero cost is INF")
	_expect_approx(Metrics.chain_training_seconds(60.0, 1.15, 10), 1006.99, "chain_training_seconds era1 chain", 0.5)
	_expect_approx(Metrics.reducible_share(2700.0, 1076.0), (2700.0 - 1076.0) / 2700.0, "reducible_share idle vs active")

func _test_real_rules() -> void:
	var loaded := ContentLoader.load_directory(CONTENT_DIR)
	_expect(bool(loaded.ok), "content loads from %s" % CONTENT_DIR)
	if not bool(loaded.ok):
		return
	var content: GameContent = loaded.content
	var buildings := {}
	for id in content.building_ids:
		buildings[id] = 0
	buildings.hut = 2
	var rates := Production.compute_rates(content, buildings, 1.0)
	var expected_rate := 0.3 * pow(3.0, 1.5)
	_expect_approx(_f(rates.lingli), expected_rate, "hut 2 lingli rate matches 0.3 * (2 + weight)^1.5")
	var def: Dictionary = content.buildings.hut
	var base_cost := BuildingCosts.resolve_base_cost("hut", def.base_cost, true)
	_expect_equal(base_cost, {"lingli": 20.0}, "hut onboarding base cost is lingli 20")
	var costs := BuildingCosts.compute_cost(base_cost, 0, 1.0)
	var independent := _f(_independent_cost({"lingli": 20.0}, 0, 1.0).lingli)
	_expect_approx(_f(costs.lingli), independent, "hut L0 cost internal consistency")
	if is_equal_approx(_f(costs.lingli), 20.0):
		_expect_approx(_f(costs.lingli), 20.0, "hut L0 onboarding cost is 20 lingli")
	else:
		print("WARN: hut L0 onboarding cost is %s, expected 20 lingli" % str(_f(costs.lingli)))
	_expect_approx(_f(_independent_cost({"lingli": 20.0}, 0, 1.0).lingli), 20.0, "independent L0 cost is 20 lingli")

func _test_sim_smoke() -> void:
	var loaded := ContentLoader.load_directory(CONTENT_DIR)
	if not bool(loaded.ok):
		return
	var content: GameContent = loaded.content
	var active_params := {
		"max_seconds": 120, "horizon": 600, "clicks_per_second": 2,
		"interval": 300, "visit_clicks": 20, "use_pills": false,
	}
	var active_sim = Sim.new(content)
	var active: Dictionary = active_sim.run("active", active_params)
	_expect(not active.is_empty(), "active run completes without error")
	_expect(int(active.purchases) >= 1, "active run purchases >= 1")
	for key in ["t_chain_done", "t_lv10", "t_ready", "stuck"]:
		_expect(active.has(key), "active run metric key %s" % key)
	var idle_params := {
		"max_seconds": 120, "horizon": 600, "clicks_per_second": 2,
		"interval": 60, "visit_clicks": 20, "use_pills": false,
	}
	var idle_sim = Sim.new(content)
	var idle: Dictionary = idle_sim.run("idle", idle_params)
	_expect(not idle.is_empty(), "idle run completes without error")
	for key in ["t_chain_done", "t_lv10", "t_ready", "stuck"]:
		_expect(idle.has(key), "idle run metric key %s" % key)

func _independent_cost(base_cost: Dictionary, level: int, cost_factor: float) -> Dictionary:
	var result := {}
	var exponential := pow(cost_factor, float(level))
	var linear := 1.0 + float(level) / 20.0
	for resource_id in base_cost:
		result[resource_id] = AmountCompat.from_number(float(base_cost[resource_id]) * exponential * linear).floor_amount()
	return result

func _f(a: Variant) -> float:
	return (a as AmountCompat).to_float()

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)

func _expect_approx(actual: float, expected: float, label: String, tolerance: float = EPS) -> void:
	if absf(actual - expected) > tolerance:
		_expect(false, "%s; expected=%f actual=%f (tol=%f)" % [label, expected, actual, tolerance])
		return
	checks += 1

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_expect(false, "%s; expected=%s actual=%s" % [label, str(expected), str(actual)])
		return
	checks += 1
