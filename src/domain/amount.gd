class_name Amount
extends RefCounted
## A bounded compatibility model for legacy break_eternity Decimal values.
##
## Values use the legacy sign/layer/mag representation. This M0-C probe keeps
## parsing, serialization and the operations required by the first rule slice;
## it deliberately returns a named parse error instead of converting bad input
## to zero.

const EXP_LIMIT := 9.0e15
const LAYER_DOWN := 15.954

var sign: int = 0
var layer: int = 0
var mag: float = 0.0

static func zero() -> Amount:
	return from_components(0, 0, 0.0)

static func from_number(value: float) -> Amount:
	if is_nan(value) or is_inf(value):
		return zero()
	return from_components(1 if value > 0.0 else -1 if value < 0.0 else 0, 0, absf(value))

static func from_components(value_sign: int, value_layer: int, value_mag: float) -> Amount:
	var result := Amount.new()
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
		var repeated_sign := -1 if repeated_match.get_string(1) == "-" else 1
		var repeated_mag := repeated_match.get_string(3).to_float()
		return {"ok": true, "value": from_components(repeated_sign, repeated_match.get_string(2).length(), repeated_mag)}
	var scientific := RegEx.new()
	scientific.compile("^([+-]?)(\\d+(?:\\.\\d+)?|\\.\\d+)(?:e([+-]?\\d+))?$")
	var match := scientific.search(text)
	if not match:
		return {"ok": false, "error": "INVALID_FORMAT"}
	var coeff := match.get_string(2).to_float()
	if coeff == 0.0:
		return {"ok": true, "value": zero()}
	var parsed_sign := -1 if match.get_string(1) == "-" else 1
	var exponent_text := match.get_string(3)
	if exponent_text.is_empty():
		return {"ok": true, "value": from_components(parsed_sign, 0, coeff)}
	var exponent := exponent_text.to_int()
	var logarithm := log(coeff) / log(10.0) + float(exponent)
	if logarithm > 308.0 or logarithm < -308.0:
		return {"ok": true, "value": from_components(parsed_sign, 1, logarithm)}
	return {"ok": true, "value": from_number(float(parsed_sign) * coeff * pow(10.0, exponent))}

func _normalize() -> void:
	if sign == 0 or mag == 0.0 and layer == 0:
		sign = 0
		layer = 0
		mag = 0.0
		return
	if is_nan(mag) or is_inf(mag):
		push_error("Amount does not accept non-finite components")
		sign = 0
		layer = 0
		mag = 0.0
		return
	if layer == 0:
		mag = absf(mag)
		if mag == 0.0:
			sign = 0
			return
	while layer > 0 and absf(mag) < LAYER_DOWN:
		layer -= 1
		mag = pow(10.0, mag)
	while absf(mag) > EXP_LIMIT:
		mag = log(absf(mag)) / log(10.0)
		layer += 1
	if layer == 0:
		mag = absf(mag)

func to_components() -> Dictionary:
	return {"sign": sign, "layer": layer, "mag": mag}

func to_json() -> String:
	return to_string()

func to_string() -> String:
	if sign == 0:
		return "0"
	var prefix := "-" if sign < 0 else ""
	if layer == 0:
		return prefix + _format_float(mag)
	if layer == 1:
		var exponent := floori(mag)
		var mantissa := pow(10.0, mag - float(exponent))
		return prefix + _format_float(mantissa) + "e" + str(exponent)
	return prefix + "e".repeat(layer) + _format_float(mag)

func compare_to(other: Amount) -> int:
	if sign != other.sign:
		return -1 if sign < other.sign else 1
	if sign == 0:
		return 0
	var raw := 0
	if layer != other.layer:
		raw = -1 if layer < other.layer else 1
	elif not is_equal_approx(mag, other.mag):
		raw = -1 if mag < other.mag else 1
	return raw * sign

func plus(other: Amount) -> Amount:
	if sign == 0:
		return other.duplicate_amount()
	if other.sign == 0:
		return duplicate_amount()
	if sign == other.sign and layer == 0 and other.layer == 0:
		return from_number(float(sign) * mag + float(other.sign) * other.mag)
	if sign == other.sign and layer == 1 and other.layer == 1:
		var high := maxf(mag, other.mag)
		var low := minf(mag, other.mag)
		var combined := high if high - low > 15.0 else high + log(1.0 + pow(10.0, low - high)) / log(10.0)
		return from_components(sign, 1, combined)
	return duplicate_amount() if compare_to(other) >= 0 else other.duplicate_amount()

func minus(other: Amount) -> Amount:
	var negated := other.duplicate_amount()
	negated.sign *= -1
	return plus(negated)

func times(other: Amount) -> Amount:
	if sign == 0 or other.sign == 0:
		return zero()
	if layer == 0 and other.layer == 0:
		var raw := mag * other.mag
		if not is_inf(raw):
			return from_number(float(sign * other.sign) * raw)
	if layer <= 1 and other.layer <= 1:
		return from_components(sign * other.sign, 1, _log10_abs() + other._log10_abs())
	return duplicate_amount() if compare_to(other) >= 0 else other.duplicate_amount()

func divided_by(other: Amount) -> Amount:
	if other.sign == 0:
		push_error("Amount division by zero")
		return zero()
	if sign == 0:
		return zero()
	if layer == 0 and other.layer == 0:
		return from_number(float(sign * other.sign) * mag / other.mag)
	if layer <= 1 and other.layer <= 1:
		return from_components(sign * other.sign, 1, _log10_abs() - other._log10_abs())
	return duplicate_amount()

func power(exponent: float) -> Amount:
	if sign == 0:
		return zero() if exponent > 0.0 else from_number(1.0)
	if layer == 0:
		var raw := pow(float(sign) * mag, exponent)
		if not is_nan(raw) and not is_inf(raw):
			return from_number(raw)
	if layer == 1:
		return from_components(1, 1, mag * exponent)
	return from_components(1, layer, mag * exponent)

func log10_amount() -> Amount:
	if sign <= 0:
		push_error("Amount log10 requires a positive value")
		return zero()
	if layer == 0:
		return from_number(log(mag) / log(10.0))
	if layer == 1:
		return from_number(mag)
	return from_components(1, layer - 1, mag)

func floor_amount() -> Amount:
	return from_number(floor(float(sign) * mag)) if layer == 0 else duplicate_amount()

func clamp_amount(minimum: Amount, maximum: Amount) -> Amount:
	if compare_to(minimum) < 0:
		return minimum.duplicate_amount()
	if compare_to(maximum) > 0:
		return maximum.duplicate_amount()
	return duplicate_amount()

func duplicate_amount() -> Amount:
	return from_components(sign, layer, mag)

func _log10_abs() -> float:
	if layer == 0:
		return log(mag) / log(10.0)
	return mag if layer == 1 else INF

static func _format_float(value: float) -> String:
	if is_equal_approx(value, floor(value)):
		return str(int(value))
	return str(value)
