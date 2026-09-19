class_name AmountCompat
extends RefCounted
## Bounded break_eternity-compatible value for the first formal rule slice.
## It preserves legacy sign/layer/mag values and does not silently turn bad
## input into zero. Complex operations above layer one stay out of scope for
## this probe and are recorded in the M0-C support-boundary ADR.

const EXP_LIMIT := 9.0e15
const LAYER_DOWN := 15.954

var sign: int = 0
var layer: int = 0
var mag: float = 0.0

static func zero() -> AmountCompat:
	return from_components(0, 0, 0.0)

static func from_number(value: float) -> AmountCompat:
	if is_nan(value) or is_inf(value):
		return zero()
	return from_components(1 if value > 0.0 else -1 if value < 0.0 else 0, 0, absf(value))

static func from_components(value_sign: int, value_layer: int, value_mag: float) -> AmountCompat:
	var result := AmountCompat.new()
	result.sign = 1 if value_sign > 0 else -1 if value_sign < 0 else 0
	result.layer = maxi(0, value_layer)
	result.mag = value_mag
	result._normalize()
	return result

static func try_parse(raw: String) -> Dictionary:
	var text := raw.strip_edges().to_lower()
	if text.is_empty():
		return {"ok": false, "error": "EMPTY"}
	if text == "nan" or text.contains("inf"):
		return {"ok": false, "error": "NON_FINITE"}
	var repeated := RegEx.new()
	repeated.compile("^([+-]?)(e{2,})([+-]?\\d+(?:\\.\\d+)?)$")
	var repeated_match := repeated.search(text)
	if repeated_match:
		return {"ok": true, "value": from_components(-1 if repeated_match.get_string(1) == "-" else 1, repeated_match.get_string(2).length(), repeated_match.get_string(3).to_float())}
	var scientific := RegEx.new()
	scientific.compile("^([+-]?)(\\d+(?:\\.\\d+)?|\\.\\d+)(?:e([+-]?\\d+))?$")
	var match := scientific.search(text)
	if not match:
		return {"ok": false, "error": "INVALID_FORMAT"}
	var coefficient := match.get_string(2).to_float()
	if coefficient == 0.0:
		return {"ok": true, "value": zero()}
	var value_sign := -1 if match.get_string(1) == "-" else 1
	var exponent_text := match.get_string(3)
	if exponent_text.is_empty():
		return {"ok": true, "value": from_components(value_sign, 0, coefficient)}
	return {"ok": true, "value": from_components(value_sign, 1, log(coefficient) / log(10.0) + float(exponent_text.to_int()))}

func _normalize() -> void:
	if sign == 0 or (layer == 0 and mag == 0.0):
		sign = 0
		layer = 0
		mag = 0.0
		return
	if is_nan(mag) or is_inf(mag):
		push_error("AmountCompat does not accept non-finite components")
		sign = 0
		layer = 0
		mag = 0.0
		return
	if layer == 0:
		mag = absf(mag)
	while layer > 0 and mag > 0.0 and mag < LAYER_DOWN:
		layer -= 1
		mag = pow(10.0, mag)
	while absf(mag) > EXP_LIMIT:
		mag = log(absf(mag)) / log(10.0)
		layer += 1

func to_components() -> Dictionary:
	return {"sign": sign, "layer": layer, "mag": mag}

func serialize() -> String:
	return to_display_string()

func to_float() -> float:
	if sign == 0:
		return 0.0
	if layer == 0:
		return float(sign) * mag
	if layer == 1:
		return float(sign) * pow(10.0, mag)
	return INF if sign > 0 else -INF

func to_display_string() -> String:
	if sign == 0:
		return "0"
	var prefix := "-" if sign < 0 else ""
	if layer == 0:
		return prefix + _format_float(mag)
	if layer == 1:
		var exponent := floori(mag)
		return prefix + _format_float(pow(10.0, mag - float(exponent))) + "e" + str(exponent)
	return prefix + "e".repeat(layer) + _format_float(mag)

func compare_to(other: AmountCompat) -> int:
	if sign != other.sign:
		return -1 if sign < other.sign else 1
	if sign == 0:
		return 0
	var unsigned_compare := 0
	if layer != other.layer:
		unsigned_compare = -1 if layer < other.layer else 1
	elif not is_equal_approx(mag, other.mag):
		unsigned_compare = -1 if mag < other.mag else 1
	return unsigned_compare * sign

func add(other: AmountCompat) -> AmountCompat:
	if sign == 0:
		return other.duplicate_amount()
	if other.sign == 0:
		return duplicate_amount()
	if layer == 0 and other.layer == 0:
		return from_number(float(sign) * mag + float(other.sign) * other.mag)
	if layer == 1 and other.layer == 1:
		var high := maxf(mag, other.mag)
		var low := minf(mag, other.mag)
		var high_sign := sign if mag >= other.mag else other.sign
		if sign == other.sign:
			return from_components(high_sign, 1, high if high - low > 15.0 else high + log(1.0 + pow(10.0, low - high)) / log(10.0))
		if is_equal_approx(high, low):
			return zero()
		return from_components(high_sign, 1, high if high - low > 15.0 else high + log(1.0 - pow(10.0, low - high)) / log(10.0))
	return duplicate_amount() if compare_to(other) >= 0 else other.duplicate_amount()

func subtract(other: AmountCompat) -> AmountCompat:
	var negated := other.duplicate_amount()
	negated.sign *= -1
	return add(negated)

func multiply(other: AmountCompat) -> AmountCompat:
	if sign == 0 or other.sign == 0:
		return zero()
	if layer == 0 and other.layer == 0:
		return from_number(float(sign * other.sign) * mag * other.mag)
	if layer <= 1 and other.layer <= 1:
		return from_components(sign * other.sign, 1, _log10_abs() + other._log10_abs())
	return duplicate_amount() if compare_to(other) >= 0 else other.duplicate_amount()

func divide(other: AmountCompat) -> AmountCompat:
	if other.sign == 0:
		push_error("AmountCompat division by zero")
		return zero()
	if sign == 0:
		return zero()
	if layer == 0 and other.layer == 0:
		return from_number(float(sign * other.sign) * mag / other.mag)
	if layer <= 1 and other.layer <= 1:
		return from_components(sign * other.sign, 1, _log10_abs() - other._log10_abs())
	return duplicate_amount()

func pow_amount(exponent: float) -> AmountCompat:
	if sign == 0:
		return zero() if exponent > 0.0 else from_number(1.0)
	if layer == 0:
		var raw := pow(float(sign) * mag, exponent)
		if not is_nan(raw) and not is_inf(raw):
			return from_number(raw)
	if layer == 1:
		return from_components(1, 1, mag * exponent)
	return from_components(1, layer, mag * exponent)

func log10_amount() -> AmountCompat:
	if sign <= 0:
		push_error("AmountCompat log10 requires a positive value")
		return zero()
	if layer == 0:
		return from_number(log(mag) / log(10.0))
	if layer == 1:
		return from_number(mag)
	return from_components(1, layer - 1, mag)

func floor_amount() -> AmountCompat:
	if layer != 0:
		return duplicate_amount()
	return from_number(floor(float(sign) * mag))

func clamp_amount(minimum: AmountCompat, maximum: AmountCompat) -> AmountCompat:
	if compare_to(minimum) < 0:
		return minimum.duplicate_amount()
	if compare_to(maximum) > 0:
		return maximum.duplicate_amount()
	return duplicate_amount()

func duplicate_amount() -> AmountCompat:
	return from_components(sign, layer, mag)

func _log10_abs() -> float:
	return log(mag) / log(10.0) if layer == 0 else mag

static func _format_float(value: float) -> String:
	if is_equal_approx(value, floor(value)):
		return str(int(value))
	return str(value)
