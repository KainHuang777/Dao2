extends SceneTree

const FIXTURE_PATH := "res://tests/fixtures/legacy/m0-c-v1.json"
const CORRECTION_PATH := "res://tests/fixtures/legacy/m0-c-v2.json"
const EPSILON := 0.000000000001

var failures: Array[String] = []

func _init() -> void:
	var fixture := JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH)) as Dictionary
	var corrections := JSON.parse_string(FileAccess.get_file_as_string(CORRECTION_PATH)) as Dictionary
	for item in fixture.amounts:
		var parsed := AmountCompatV2.try_parse(item.input)
		_expect(parsed.ok, "Amount parses %s" % item.input)
		if parsed.ok:
			var amount: AmountCompatV2 = parsed.value
			_expect_equal(amount.to_display_string(), item.string, "Amount string %s" % item.input)
			_expect_equal(amount.sign, int(item.components.sign), "Amount sign %s" % item.input)
			_expect_equal(amount.layer, int(item.components.layer), "Amount layer %s" % item.input)
			_expect_close(amount.mag, float(item.components.mag), "Amount mag %s" % item.input)
	for item in fixture.invalid_amounts:
		var invalid := AmountCompatV2.try_parse(item.input)
		_expect(not invalid.ok, "Amount rejects %s" % item.input)
		_expect_equal(invalid.error, item.error, "Amount error %s" % item.input)
	var huge := _amount("1e100")
	_expect_equal(huge.add(huge).to_display_string(), fixture.arithmetic.plus_equal, "Amount plus equal")
	_expect_equal(huge.add(_amount("1")).to_display_string(), fixture.arithmetic.plus_dominant, "Amount plus dominant")
	_expect_equal(huge.subtract(_amount("9e99")).to_display_string(), fixture.arithmetic.minus, "Amount subtract")
	_expect_equal(huge.multiply(_amount("1e20")).to_display_string(), fixture.arithmetic.times, "Amount multiply")
	_expect_equal(huge.divide(_amount("1e20")).to_display_string(), fixture.arithmetic.divided_by, "Amount divide")
	_expect_equal(huge.pow_amount(2.0).to_display_string(), fixture.arithmetic.power, "Amount power")
	_expect_equal(huge.log10_amount().to_display_string(), fixture.arithmetic.log10, "Amount log10")
	_expect_equal(_amount("-3.5").floor_amount().to_display_string(), fixture.arithmetic.floor_negative, "Amount floor")
	_expect_equal(_amount("ee20").clamp_amount(_amount("1e100"), _amount("1e1000000")).to_display_string(), corrections.corrections.arithmetic.clamp, "Amount clamp")
	for vector in fixture.seeded_random:
		var rng := SeededRandomCompat.from_seed(vector.seed)
		for expected in vector.first:
			_expect_close(rng.next(), float(expected), "RNG stream %s" % str(vector.seed))
		_expect_equal(rng.state, int(vector.state), "RNG state %s" % str(vector.seed))
		_expect_close(SeededRandomCompat.from_state(rng.state).next(), float(vector.resumed), "RNG resume %s" % str(vector.seed))
		var branch := SeededRandomCompat.from_state(rng.state)
		_expect_equal(branch.int_range(3, 9), int(vector.int_range), "RNG int range %s" % str(vector.seed))
		_expect_equal(branch.trial(0.5), bool(vector.trial), "RNG trial %s" % str(vector.seed))
		_expect_equal(branch.weighted(["wood", "stone", "herb"], [1, 0, 3]), vector.weighted, "RNG weighted %s" % str(vector.seed))
	if failures.is_empty():
		print("PASS: M0-C AmountCompatV2 and SeededRandomCompat match legacy fixture.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _amount(raw: String) -> AmountCompatV2:
	return AmountCompatV2.try_parse(raw).value

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s; expected=%s actual=%s" % [label, str(expected), str(actual)])

func _expect_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > EPSILON:
		failures.append("%s; expected=%s actual=%s" % [label, str(expected), str(actual)])
