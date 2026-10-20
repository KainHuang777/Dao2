extends SceneTree
const OUT="E:/WORK/Dao2/docs/verification/artifacts/trib-b-f1/"
var failures := []
var checks := 0
func _init() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func run() -> void:
	var start := Time.get_ticks_msec()
	var page=load("res://preview.tscn").instantiate()
	root.add_child(page)
	await process_frame
	var generation_ms := Time.get_ticks_msec()-start
	page.effect.paused=true
	for failed in [false,true]:
		var wav: AudioStreamWAV=page.streams[1 if failed else 0]
		var name := "failure" if failed else "success"
		check(wav.stereo,"stereo "+name)
		check(is_equal_approx(wav.get_length(),20),"20 seconds "+name)
		check(wav.save_to_wav(OUT+name+".wav")==OK,"save "+name)
		page.effect.failed=failed
		page.effect.seek(1.5)
		page.effect.paused=false
		page.muted=false
		page.sync_audio()
		check(page.audio.playing,"precursor playback "+name)
		page.effect.paused=true
		page.sync_audio()
		check(not page.audio.playing,"pause stops "+name)
		page.effect.paused=false
		page.effect.seek(9.4)
		page.sync_audio()
		check(page.audio.playing,"seek thunder "+name)
		page._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not page.audio.playing and page.effect.paused,"focus stops "+name)
		page.focused=true
		page.effect.paused=false
		page.effect.seek(20)
		page.sync_audio()
		check(not page.audio.playing,"skip stops "+name)
	page.queue_free()
	for i in 4: await process_frame
	var report={"task":"TRIB-B-F1","checks":checks,"failures":failures,"generation_and_setup_ms":generation_ms,"engine":Engine.get_version_info().string,"scope":"PCM export and native lifecycle; no human listening or FPS claim"}
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("TRIBB_AUDIO_CHECKS ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
