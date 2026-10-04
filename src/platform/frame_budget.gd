class_name FrameBudget
extends RefCounted
## Monotonic scheduling budget. Never supplied as economic elapsed time.
# Leave ~2.7ms of a 60Hz frame for progress UI/rendering. One tick may overrun;
# browser settlement frame gaps are measured separately from steady gameplay.
const SLICE_USEC := 14000
var deadline := 0
func begin() -> void:
	deadline = Time.get_ticks_usec() + SLICE_USEC
func has_time() -> bool:
	return Time.get_ticks_usec() < deadline
