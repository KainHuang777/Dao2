extends SceneTree

const LivingAbode = preload("res://src/abode/living_abode.gd")

func _init() -> void:
	print("=== BGM ERA PLAYLIST TEST START ===")
	var abode = LivingAbode.new()
	abode._init_core()
	
	# 驗證 BGM 庫加載
	var tracks = abode._bgm_tracks
	print("Loaded tracks count: ", tracks.size())
	assert(tracks.size() >= 4, "Expected at least 4 BGM tracks loaded from res://src/BGM/")
	assert(tracks[0]["era_req"] == 1, "Track 0 should be Era 1")
	assert(tracks[1]["era_req"] == 2, "Track 1 should be Era 2")
	assert(tracks[2]["era_req"] == 3, "Track 2 should be Era 3")
	assert(tracks[3]["era_req"] == 4, "Track 3 should be Era 4")
	print("Track 0: ", tracks[0]["filename"])
	print("Track 1: ", tracks[1]["filename"])
	print("Track 2: ", tracks[2]["filename"])
	print("Track 3: ", tracks[3]["filename"])
	
	# 驗證各境界播放清單過濾規則
	var p1 = abode._get_bgm_playlist_for_era(1)
	assert(p1.size() == 1, "Era 1 playlist should have size 1")
	assert(p1[0]["era_req"] == 1, "Era 1 track must be req 1")
	
	var p2 = abode._get_bgm_playlist_for_era(2)
	assert(p2.size() == 2, "Era 2 playlist should have size 2")
	assert(p2[0]["era_req"] == 1 and p2[1]["era_req"] == 2, "Era 2 should contain 01 and 02")
	
	var p3 = abode._get_bgm_playlist_for_era(3)
	assert(p3.size() == 3, "Era 3 playlist should have size 3")
	assert(p3[2]["era_req"] == 3, "Era 3 should contain up to 03")
	
	var p4 = abode._get_bgm_playlist_for_era(4)
	assert(p4.size() == 4, "Era 4 playlist should have size 4")
	
	var p9 = abode._get_bgm_playlist_for_era(9)
	assert(p9.size() == 4, "Era 9 playlist should have size 4 (all tracks)")
	print("Playlist filtering logic verified successfully!")
	
	# 驗證播放排程與循環邏輯
	abode.session.state.era_id = 1
	abode._play_bgm_track_at_index(0)
	assert(abode._current_bgm_index == 0, "Current index should be 0")
	# Era 1 finished -> 仍然播 0
	abode._on_bgm_finished()
	assert(abode._current_bgm_index == 0, "Era 1 finished should loop to 0")
	
	# 升到 Era 2
	abode.session.state.era_id = 2
	abode._play_bgm_track_at_index(0)
	assert(abode._current_bgm_index == 0, "Current index should be 0")
	abode._on_bgm_finished()
	assert(abode._current_bgm_index == 1, "Era 2 next should be index 1 (02)")
	abode._on_bgm_finished()
	assert(abode._current_bgm_index == 0, "Era 2 next should loop back to index 0 (01)")
	print("Era 2 playlist looping verified successfully!")
	
	# 升到 Era 4 (全循環)
	abode.session.state.era_id = 4
	abode._play_bgm_track_at_index(3) # 播放 04
	assert(abode._current_bgm_index == 3, "Current index should be 3 (04)")
	abode._on_bgm_finished()
	assert(abode._current_bgm_index == 0, "Era 4 track 3 finished should loop back to track 0")
	print("Era 4 full playlist looping verified successfully!")
	
	# 驗證輪迴退回 Era 1 時的切換保護
	abode.session.state.era_id = 4
	abode._play_bgm_track_at_index(3) # 播 04
	# 輪迴轉生：境界重置為 1
	abode.session.state.era_id = 1
	abode._check_and_update_bgm_era()
	assert(abode._current_bgm_index == 0, "Reincarnation reset to Era 1 should switch invalid track 3 to track 0")
	print("Reincarnation fallback verified successfully!")
	
	abode.free()
	print("=== BGM ERA PLAYLIST TEST PASS ===")
	quit(0)
