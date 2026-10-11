extends SceneTree

func _init() -> void:
	print("PROBE start")
	var loaded := ContentLoader.load_directory("res://content")
	print("PROBE load ok=", loaded.ok)
	var content: GameContent = loaded.content
	var ContractLess := preload("res://tests/fixtures/res1d1/contract.gd")
	var fixture := ContractLess.attach(content)
	print("PROBE attach done version=", fixture.get("fixture_version"))
	var s := GameSession.create_new_game(content)
	print("PROBE session created")
	quit(0)
