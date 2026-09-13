extends SceneTree

func _init() -> void:
	for input in ["0", "-3.5", "123.45", "1e100", "1.5e100", "1e1000000", "ee5", "ee20", "eee20", "1e-100"]:
		var parsed := Amount.try_parse(input)
		if parsed.ok:
			var value: Amount = parsed.value
			print("AMOUNT ", input, " => ", value.to_string(), " ", JSON.stringify(value.to_components()))
		else:
			print("AMOUNT_ERROR ", input, " => ", parsed.error)
	quit()
