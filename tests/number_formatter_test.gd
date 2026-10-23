extends SceneTree

const Formatter = preload("res://src/utils/number_formatter.gd")

func _init() -> void:
	var failures: Array[String] = []

	var assert_eq = func(actual: String, expected: String, desc: String):
		if actual != expected:
			failures.append("%s: expected '%s', got '%s'" % [desc, expected, actual])

	# 1. Null, 0, Negative 0
	assert_eq.call(Formatter.format_amount(null), "0", "null")
	assert_eq.call(Formatter.format_amount(0), "0", "int 0")
	assert_eq.call(Formatter.format_amount(0.0), "0", "float 0.0")
	assert_eq.call(Formatter.format_amount("0"), "0", "string 0")

	# 2. General numbers >= 10 (down to integer, no decimals)
	assert_eq.call(Formatter.format_amount(1105.74844602687), "1105", "1105.7484... -> 1105")
	assert_eq.call(Formatter.format_amount(1283.61971322647), "1283", "1283.6197... -> 1283")
	assert_eq.call(Formatter.format_amount(748.598928222975), "748", "748.5989... -> 748")
	assert_eq.call(Formatter.format_amount(10.0), "10", "10.0 -> 10")
	assert_eq.call(Formatter.format_amount(10.9), "10", "10.9 -> 10")
	assert_eq.call(Formatter.format_amount(9999), "9999", "9999 -> 9999")

	# 3. Numbers 1 <= x < 10 (1 decimal place, strip trailing zero)
	assert_eq.call(Formatter.format_amount(1.0), "1", "1.0 -> 1")
	assert_eq.call(Formatter.format_amount(1.5), "1.5", "1.5 -> 1.5")
	assert_eq.call(Formatter.format_amount(3.567), "3.5", "3.567 -> 3.5")
	assert_eq.call(Formatter.format_amount(9.99), "9.9", "9.99 -> 9.9")

	# 4. Small numbers 0.001 <= x < 1.0 (up to 3 decimal places, strip trailing zeros)
	assert_eq.call(Formatter.format_amount(0.5), "0.5", "0.5 -> 0.5")
	assert_eq.call(Formatter.format_amount(0.05), "0.05", "0.05 -> 0.05")
	assert_eq.call(Formatter.format_amount(0.001), "0.001", "0.001 -> 0.001")
	assert_eq.call(Formatter.format_amount(0.12345), "0.123", "0.12345 -> 0.123")

	# 5. Micro numbers 0 < x < 0.001
	assert_eq.call(Formatter.format_amount(0.0005), "<0.001", "0.0005 -> <0.001")
	assert_eq.call(Formatter.format_amount(0.00001), "<0.001", "0.00001 -> <0.001")

	# 6. Large numbers >= 10,000 (萬) and >= 100,000,000 (億)
	assert_eq.call(Formatter.format_amount(10000), "1萬", "10000 -> 1萬")
	assert_eq.call(Formatter.format_amount(12500), "1.2萬", "12500 -> 1.2萬")
	assert_eq.call(Formatter.format_amount(100000000), "1億", "100000000 -> 1億")
	assert_eq.call(Formatter.format_amount(350000000), "3.5億", "350000000 -> 3.5億")

	# 7. AmountCompat support
	var a1 := AmountCompat.from_number(1105.7484)
	assert_eq.call(Formatter.format_amount(a1), "1105", "AmountCompat 1105.7484")
	var a2 := AmountCompat.from_number(0.001)
	assert_eq.call(Formatter.format_amount(a2), "0.001", "AmountCompat 0.001")
	var a3 := AmountCompat.from_components(1, 1, 15.0)
	assert_eq.call(Formatter.format_amount(a3), "1e15", "AmountCompat 1e15")

	# 8. Rate formatting
	assert_eq.call(Formatter.format_rate(0), "0", "rate 0")
	assert_eq.call(Formatter.format_rate(10), "10", "rate 10")
	assert_eq.call(Formatter.format_rate(0.5), "0.5", "rate 0.5")
	assert_eq.call(Formatter.format_rate(0.001), "0.001", "rate 0.001")
	assert_eq.call(Formatter.format_rate(0.0001), "<0.001", "rate 0.0001")

	if failures.is_empty():
		print("PASS: NumberFormatter all tests passed.")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)
