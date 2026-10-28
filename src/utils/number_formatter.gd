class_name NumberFormatter
extends RefCounted

## Global presentation utility for game numbers:
## Adaptive Precision Rules:
## - null / NaN / INF -> "0"
## - layer > 0 AmountCompat -> exponential notation (e.g. 1.23e16)
## - 0.0 -> "0"
## - val >= 1e12 -> exponential notation (e.g. 1e12, 1e15)
## - val >= 100,000,000 -> "%.1f億" (e.g. 1.5億, 2億)
## - val >= 10,000 -> "%.1f萬" (e.g. 1.2萬, 3萬)
## - 10 <= val < 10,000 -> integer floor (e.g. 1105, 748, 1283)
## - 1 <= val < 10 -> 1 decimal place with floor, strip trailing zero (e.g. 3.5, 9.9, 7)
## - 0.001 <= val < 1 -> up to 3 decimal places with floor, strip trailing zero (e.g. 0.5, 0.05, 0.001)
## - 0 < val < 0.001 -> "<0.001"
## - Negative values prefixed with "-"

static func format_amount(raw: Variant) -> String:
	if raw == null:
		return "0"
	if raw is AmountCompat:
		if raw.sign == 0:
			return "0"
		if raw.layer > 0:
			return raw.to_display_string()
		return _format_float(float(raw.sign) * raw.mag)
	if typeof(raw) == TYPE_STRING:
		var s := (raw as String).strip_edges()
		if s.is_empty():
			return "0"
		var parsed := AmountCompat.try_parse(s)
		if bool(parsed.get("ok", false)):
			var a: AmountCompat = parsed["value"]
			if a.sign == 0:
				return "0"
			if a.layer > 0:
				return a.to_display_string()
			return _format_float(float(a.sign) * a.mag)
		if s.is_valid_float():
			return _format_float(s.to_float())
		return s
	if typeof(raw) in [TYPE_FLOAT, TYPE_INT]:
		return _format_float(float(raw))
	return str(raw)

## Unabbreviated value for tips and audits; visible cells keep format_amount.
static func exact_amount(raw: Variant) -> String:
	if raw == null:
		return "未提供"
	if raw is AmountCompat:
		if raw.sign == 0:
			return "0"
		if raw.layer > 0:
			return raw.to_display_string()
		return _exact_float(float(raw.sign) * raw.mag)
	if typeof(raw) == TYPE_STRING:
		var s := (raw as String).strip_edges()
		return s if not s.is_empty() else "未提供"
	if typeof(raw) == TYPE_INT:
		return str(raw)
	if typeof(raw) == TYPE_FLOAT:
		return _exact_float(float(raw))
	return str(raw)

static func _exact_float(val: float) -> String:
	if is_nan(val) or is_inf(val):
		return "未提供"
	if absf(val) < 1.0e15 and val == roundf(val):
		return str(int(roundf(val)))
	return str(val)

static func format_rate(raw: Variant) -> String:
	if raw == null:
		return "0"
	var val: float = 0.0
	if raw is AmountCompat:
		if raw.sign == 0:
			return "0"
		if raw.layer > 0:
			return raw.to_display_string()
		val = float(raw.sign) * raw.mag
	elif typeof(raw) == TYPE_STRING:
		var s := (raw as String).strip_edges()
		if s.is_valid_float():
			val = s.to_float()
		else:
			return s
	elif typeof(raw) in [TYPE_FLOAT, TYPE_INT]:
		val = float(raw)
	else:
		return str(raw)

	if is_nan(val) or is_inf(val) or is_zero_approx(val):
		return "0"

	var prefix := "-" if val < 0.0 else ""
	var abs_val := absf(val)

	if is_equal_approx(abs_val, roundf(abs_val)):
		return prefix + str(int(roundf(abs_val)))
	if abs_val >= 10.0:
		return prefix + str(int(roundf(abs_val)))
	if abs_val >= 1.0:
		var v := floorf(abs_val * 10.0 + 0.000001) / 10.0
		return prefix + ("%.1f" % v).rstrip("0").trim_suffix(".")
	if abs_val >= 0.001:
		var v := floorf(abs_val * 1000.0 + 0.000001) / 1000.0
		return prefix + ("%.3f" % v).rstrip("0").trim_suffix(".")
	return prefix + "<0.001"

static func _format_float(val: float) -> String:
	if is_nan(val) or is_inf(val) or is_zero_approx(val):
		return "0"

	var prefix := "-" if val < 0.0 else ""
	var abs_val := absf(val)

	# 1. 超大數 (>= 1e12 兆以上，轉科學記號)
	if abs_val >= 1.0e12:
		var exp_val := floorf(log(abs_val) / log(10.0) + 1e-9)
		var coeff := abs_val / pow(10.0, exp_val)
		if coeff >= 9.99999:
			coeff = 1.0
			exp_val += 1.0
		if is_equal_approx(coeff, 1.0):
			return prefix + "1e" + str(int(exp_val))
		var coeff_str := ("%.2f" % coeff).rstrip("0").trim_suffix(".")
		return prefix + coeff_str + "e" + str(int(exp_val))

	# 2. 億級 (>= 100,000,000)
	if abs_val >= 100000000.0:
		var raw_yi := abs_val / 100000000.0
		var v := floorf(raw_yi * 10.0 + 0.000001) / 10.0
		var s := ("%.1f" % v).rstrip("0").trim_suffix(".")
		return prefix + s + "億"

	# 3. 萬級 (>= 10,000)
	if abs_val >= 10000.0:
		var raw_wan := abs_val / 10000.0
		var v := floorf(raw_wan * 10.0 + 0.000001) / 10.0
		var s := ("%.1f" % v).rstrip("0").trim_suffix(".")
		return prefix + s + "萬"

	# 4. 常規整數 (10 <= abs_val < 10,000)
	# 一律向下取整為整數，避免小數點雜訊
	if abs_val >= 10.0:
		return prefix + str(int(floorf(abs_val)))

	# 5. 1 <= abs_val < 10
	# 保留 1 位小數（向下截斷避免虛假進位），去除末尾 .0
	if abs_val >= 1.0:
		var v := floorf(abs_val * 10.0 + 0.000001) / 10.0
		var s := ("%.1f" % v).rstrip("0").trim_suffix(".")
		return prefix + s

	# 6. 0.001 <= abs_val < 1.0
	# 保留最多 3 位小數（向下截斷），去除末尾 0 與點
	if abs_val >= 0.001:
		var v := floorf(abs_val * 1000.0 + 0.000001) / 1000.0
		var s := ("%.3f" % v).rstrip("0").trim_suffix(".")
		return prefix + s

	# 7. 極微量 0 < abs_val < 0.001
	return prefix + "<0.001"
