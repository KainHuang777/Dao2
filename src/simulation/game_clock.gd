class_name GameClock
extends RefCounted

var utc_seconds: float = 0.0

static func create(initial_utc_seconds: float) -> GameClock:
	var clock := GameClock.new()
	clock.utc_seconds = initial_utc_seconds
	return clock

func now() -> float:
	return utc_seconds

func advance(seconds: float) -> float:
	if is_nan(seconds) or is_inf(seconds):
		return utc_seconds
	utc_seconds += maxf(0.0, seconds)
	return utc_seconds

func set_now(value: float) -> void:
	utc_seconds = value
