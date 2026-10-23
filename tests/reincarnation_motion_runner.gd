extends SceneTree
var failures := 0
func _init() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var art = load("res://src/presentation/reincarnation_mandala.gd").new()
	root.add_child(art)
	art.size = Vector2(300,300)
	await process_frame
	for layer in art._effect.layers.values():
		check(layer.texture != null, "all accepted layers loaded")
	check(art._effect.rotor.get_index() > art._effect.layers.disc_rim_fixed.get_index(), "accepted plate above housing")
	var before: float = art.elapsed
	await create_timer(0.1).timeout
	check(art.elapsed > before, "visible artwork animates")
	art.hide()
	before = art.elapsed
	await create_timer(0.1).timeout
	check(art.elapsed == before and not art.is_processing(), "hidden artwork stops")
	var frozen_angle: float = art._effect.rotor.rotation
	await create_timer(0.1).timeout
	check(art._effect.rotor.rotation == frozen_angle, "hidden plate and shader pose freeze")
	art.show()
	art.reduced_motion = true
	before = art.elapsed
	await create_timer(0.1).timeout
	check(art.elapsed == before and art.rotation == 0.0 and art.scale == Vector2.ONE, "reduced motion is static")
	check(art._effect.rotor.rotation == 0.0, "reduced plate is static")
	art.texture = load("res://assets/ui/reincarnation-painted/life_lamp_spent.png")
	await create_timer(0.05).timeout
	check(not art._effect.visible and art.self_modulate.a == 1.0, "exhausted lamp preserved")
	art.texture = load("res://assets/ui/reincarnation-painted/reincarnation_wheel.png")
	art.size = Vector2(56,56)
	await create_timer(0.05).timeout
	check(art._effect.visible and not art._effect.glyphs[0].visible, "compact art omits decorative text")
	var sequence := ReincarnationSequence.new()
	root.add_child(sequence)
	for vp in ([Vector2(1280,720),Vector2(844,390),Vector2(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280,720)]):
		sequence.set_layout_bounds(Rect2(Vector2.ZERO,vp))
		sequence.play(null, 1, 15, Callable(), false)
		for frame in 8: await process_frame
		check(sequence.get_global_rect().encloses(sequence._mandala.get_global_rect()), "mandala fits viewport")
		check(sequence._mandala.get_global_rect().end.y <= sequence._stage_badge.global_position.y, "art clears caption")
		sequence.skip()
		check(sequence._result_card.visible and not sequence._mandala.visible, "skip clears animation and shows result")
		sequence._on_finish_pressed()
		check(not sequence.visible and not sequence._is_playing, "finish releases sequence")
	sequence.play(null,1,0,Callable(),true)
	await create_timer(1.0).timeout
	check(sequence._result_card.visible, "reduced sequence completes")
	sequence._on_finish_pressed()
	sequence.queue_free()
	art.queue_free()
	await process_frame
	print("REINCARNATION-MOTION failures=", failures)
	quit(0 if failures == 0 else 1)
