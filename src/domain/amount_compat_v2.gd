class_name AmountCompatV2
extends AmountCompat
## M0-C presentation wrapper: Godot's default float conversion shortens values
## that legacy Decimal serializes with its IEEE-754 tail. Keep 17 significant
## digits for persistent Amount strings.

static func from_components(value_sign: int, value_layer: int, value_mag: float) -> AmountCompatV2:
	var result := AmountCompatV2.new()
	result.sign = 1 if value_sign > 0 else -1 if value_sign < 0 else 0
	result.layer = maxi(0, value_layer)
	result.mag = value_mag
	result._normalize()
	return result

static func from_number(value: float) -> AmountCompatV2:
	return from_components(1 if value > 0.0 else -1 if value < 0.0 else 0, 0, absf(value))

static func try_parse(raw: String) -> Dictionary:
	var parsed := AmountCompat.try_parse(raw)
	if not parsed.ok:
		return parsed
	var base: AmountCompat = parsed.value
	return {"ok": true, "value": from_components(base.sign, base.layer, base.mag)}

func to_display_string() -> String:
	if sign == 0:
		return "0"
	var prefix := "-" if sign < 0 else ""
	if layer == 0:
		return prefix + _format_legacy_float(mag)
	if layer == 1:
		var exponent := floori(mag)
		return prefix + _format_legacy_float(pow(10.0, mag - float(exponent))) + "e" + str(exponent)
	return prefix + "e".repeat(layer) + _format_legacy_float(mag)

func add(other: AmountCompat) -> AmountCompatV2:
	return _wrap(super.add(other))

func subtract(other: AmountCompat) -> AmountCompatV2:
	return _wrap(super.subtract(other))

func multiply(other: AmountCompat) -> AmountCompatV2:
	return _wrap(super.multiply(other))

func divide(other: AmountCompat) -> AmountCompatV2:
	return _wrap(super.divide(other))

func pow_amount(exponent: float) -> AmountCompatV2:
	return _wrap(super.pow_amount(exponent))

func log10_amount() -> AmountCompatV2:
	return _wrap(super.log10_amount())

func floor_amount() -> AmountCompatV2:
	return _wrap(super.floor_amount())

func clamp_amount(minimum: AmountCompat, maximum: AmountCompat) -> AmountCompatV2:
	return _wrap(super.clamp_amount(minimum, maximum))

func duplicate_amount() -> AmountCompatV2:
	return from_components(sign, layer, mag)

static func _wrap(value: AmountCompat) -> AmountCompatV2:
	return from_components(value.sign, value.layer, value.mag)

static func _format_legacy_float(value: float) -> String:
	if is_equal_approx(value, floor(value)):
		return str(int(value))
	return "%.17g" % value
