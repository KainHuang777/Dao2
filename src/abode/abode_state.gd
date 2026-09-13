extends RefCounted
## Demonstration economy only. Never reads or overwrites the legacy/probe save.
var qi: float = 80.0
var herbs: float = 24.0
var elapsed: float = 0.0
var levels: Dictionary = {"hut": 1, "garden": 1, "altar": 1}
var garden_running: bool = true

func advance(seconds: float) -> void:
	if seconds <= 0.0 or not is_finite(seconds):
		return
	elapsed += seconds
	qi += seconds * qi_rate()
	if garden_running:
		herbs += seconds * float(levels["garden"])

func qi_rate() -> float:
	return 1.0 + float(levels["hut"]) + float(levels["altar"])

func cost(id: String) -> float:
	return 25.0 * float(levels.get(id, 1))

func upgrade(id: String) -> bool:
	if not levels.has(id) or int(levels[id]) >= 5 or qi < cost(id):
		return false
	qi -= cost(id)
	levels[id] = int(levels[id]) + 1
	return true

func snapshot() -> Dictionary:
	return {"qi": qi, "herbs": herbs, "elapsed": elapsed, "levels": levels.duplicate(), "garden_running": garden_running}
