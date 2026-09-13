class_name SeededRandomCompat
extends RefCounted
## Exact legacy Mulberry32 stream with xfnv1a UTF-16 string hashing.
## Kept as the M0-C compatibility contract until the initial candidate is
## consolidated into the production-facing SeededRandom class.

const U32_MASK: int = 0xffffffff
const DEFAULT_NON_ZERO_STATE: int = 0x9e3779b9
const FNV_OFFSET: int = 0x811c9dc5
const FNV_PRIME: int = 0x01000193

var state: int

static func from_seed(seed: Variant) -> SeededRandomCompat:
	var initial := 0
	if seed is String:
		initial = _hash_utf16(seed)
	elif seed is int or seed is float:
		initial = _u32(int(seed))
	else:
		push_error("SeededRandom seed must be String, int, or float")
	var result := SeededRandomCompat.new()
	result.state = DEFAULT_NON_ZERO_STATE if initial == 0 else initial
	return result

static func from_state(saved_state: int) -> SeededRandomCompat:
	var result := SeededRandomCompat.new()
	result.state = _u32(saved_state)
	return result

func next() -> float:
	var a := _u32(state + 0x6d2b79f5)
	var t := _imul(_u32(a ^ _urshift(a, 15)), _u32(a | 1))
	t = _u32(t + _imul(_u32(t ^ _urshift(t, 7)), _u32(t | 61))) ^ t
	state = a
	return float(_u32(t ^ _urshift(t, 14))) / 4294967296.0

func int_range(minimum: int, maximum: int) -> int:
	return floori(next() * float(maximum - minimum + 1)) + minimum

func trial(probability: float) -> bool:
	return next() < probability

func weighted(items: Array, weights: Array) -> Variant:
	if items.is_empty() or items.size() != weights.size():
		push_error("SeededRandom.weighted requires equally sized non-empty arrays")
		return null
	var total := 0.0
	for weight in weights:
		total += maxf(0.0, float(weight))
	var roll := next() * total
	var accumulated := 0.0
	for index in items.size():
		accumulated += maxf(0.0, float(weights[index]))
		if roll < accumulated:
			return items[index]
	return items.back()

func fork() -> SeededRandomCompat:
	return from_state(state)

static func _hash_utf16(seed: String) -> int:
	var hash := FNV_OFFSET
	for index in seed.length():
		var codepoint := seed.unicode_at(index)
		if codepoint <= 0xffff:
			hash = _hash_code_unit(hash, codepoint)
		else:
			var shifted := codepoint - 0x10000
			hash = _hash_code_unit(hash, 0xd800 + (shifted >> 10))
			hash = _hash_code_unit(hash, 0xdc00 + (shifted & 0x3ff))
	hash = _imul(_u32(hash ^ _urshift(hash, 13)), 0x85ebca6b)
	hash = _imul(_u32(hash ^ _urshift(hash, 16)), 0xc2b2ae35)
	return _u32(hash)

static func _hash_code_unit(hash: int, code_unit: int) -> int:
	return _imul(_u32(hash ^ code_unit), FNV_PRIME)

static func _u32(value: int) -> int:
	return value & U32_MASK

static func _urshift(value: int, count: int) -> int:
	return (value & U32_MASK) >> count

static func _imul(left: int, right: int) -> int:
	var low_left := left & 0xffff
	var high_left := _urshift(left, 16) & 0xffff
	var low_right := right & 0xffff
	var high_right := _urshift(right, 16) & 0xffff
	return _u32(low_left * low_right + ((high_left * low_right + low_left * high_right) << 16))
