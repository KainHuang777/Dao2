extends GameSession
## Keeps the existing scene's Session interface while the profile owns every commit.

var profile: EconomyProfile

func _init(owner: EconomyProfile) -> void:
	profile = owner
	_sync()

func submit(command: Dictionary) -> Dictionary:
	var result := profile.submit(command)
	if result.ok: _sync()
	return result

func advance_time(_seconds: float, _prepared: Dictionary = {}) -> Dictionary:
	var now := now_ms()
	if now - profile.settled_until() < 1000 or profile.save_pending():
		return {}
	var result := profile.settle_to(now)
	if result.ok: _sync()
	return result

func settle_background(tree: SceneTree, progress: Callable) -> Dictionary:
	var result := await profile.settle_to_async(now_ms(), tree, progress)
	if result.ok: _sync()
	return result

func retry_save() -> Dictionary:
	var result := profile.retry_save()
	if result.ok: _sync()
	return result

func get_view() -> Dictionary:
	var view := super.get_view()
	view["research"] = profile.research_view()
	return view

func _sync() -> void:
	var game := profile.committed_game()
	state = game.state
	content = game.content
	clock = game.clock

static func now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
