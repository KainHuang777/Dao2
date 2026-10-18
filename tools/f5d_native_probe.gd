extends SceneTree
## F5-D Native Frame Performance Probe for Reincarnation Dynamic Artwork
const OUT_DIR := "res://docs/verification/artifacts/uix-r7-f5d"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var dir = DirAccess.open("res://docs/verification/artifacts")
	if dir and not dir.dir_exists("uix-r7-f5d"):
		dir.make_dir("uix-r7-f5d")
	
	print("[F5-D] Starting native reincarnation dynamic performance probe...")
	var art = load("res://src/presentation/reincarnation_mandala.gd").new()
	root.add_child(art)
	art.size = Vector2(300, 300)
	root.size = Vector2i(1280, 720)
	
	# Warm up for 60 frames
	for i in range(60):
		await process_frame
		
	var frame_times: Array[float] = []
	var total_frames := 3600 # 60 seconds at 60 FPS
	var start_usec := Time.get_ticks_usec()
	var last_tick := start_usec
	
	for i in range(total_frames):
		await process_frame
		var now_tick := Time.get_ticks_usec()
		var delta_ms := float(now_tick - last_tick) / 1000.0
		last_tick = now_tick
		frame_times.append(delta_ms)
		
	var total_usec := Time.get_ticks_usec() - start_usec
	var total_sec := float(total_usec) / 1000000.0
	var avg_fps := float(total_frames) / total_sec
	
	frame_times.sort()
	var median_ms := frame_times[int(total_frames * 0.5)]
	var p95_ms := frame_times[int(total_frames * 0.95)]
	var p99_ms := frame_times[int(total_frames * 0.99)]
	var max_ms := frame_times[total_frames - 1]
	var over_16ms := 0
	var over_20ms := 0
	var over_33ms := 0
	for t in frame_times:
		if t > 16.67: over_16ms += 1
		if t > 20.0: over_20ms += 1
		if t > 33.34: over_33ms += 1
		
	var result := {
		"test": "native_reincarnation_mandala_60s",
		"total_frames": total_frames,
		"total_seconds": total_sec,
		"measured_fps": avg_fps,
		"median_ms": median_ms,
		"p95_ms": p95_ms,
		"p99_ms": p99_ms,
		"max_ms": max_ms,
		"over_16_67ms_count": over_16ms,
		"over_20ms_count": over_20ms,
		"over_33_34ms_count": over_33ms
	}
	
	print("[F5-D] Native probe complete: ", JSON.stringify(result, "\t"))
	var file = FileAccess.open("res://docs/verification/artifacts/uix-r7-f5d/native-mandala-probe.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
		
	art.queue_free()
	await process_frame
	quit(0)
