extends SceneTree

const AbodeState = preload("res://src/abode/abode_state.gd")

func _init() -> void:
	var state = AbodeState.new()
	state.advance(10.0)
	if not is_equal_approx(state.qi, 110.0) or not is_equal_approx(state.herbs, 34.0):
		push_error("Initial autonomous rates do not match the visual prototype contract")
		quit(1)
		return
	if not state.upgrade("altar") or state.levels["altar"] != 2 or not is_equal_approx(state.qi, 85.0):
		push_error("Upgrade contract failed")
		quit(1)
		return
	state.garden_running = false
	var herbs_before: float = state.herbs
	state.advance(8.0)
	if not is_equal_approx(state.herbs, herbs_before) or not is_equal_approx(state.qi, 117.0):
		push_error("Paused garden or upgraded altar rates failed")
		quit(1)
		return
	print("PASS: abode state advances independently from visual flow, upgrades, and garden pause.")
	quit(0)
