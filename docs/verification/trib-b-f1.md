# TRIB-B-F1：預備遠雷與近距離落雷聲修訂

2026-10-19（承接10/18晚間回饋）。使用者要求先有天空雷鳴、落雷更像打雷。**音效修訂已交付，聽感待接受；TRIB-B仍IN_PROGRESS，C未開。**

## 變更

- 0.65與3.65秒開始遠雷：慢起音、低沉雲層滾雷，在7.6秒第一道雷之前建立劫兆。
- 7.6／9.3／11.1秒三次落雷：濾波噪聲裂雷與短促次裂聲，約85ms後低頻轟鳴湧入、不規則起伏衰減，三擊逐次增強。移除原雷擊的下降正弦音，避免電子脈衝感。
- 四組左右不同延遲的實際回聲副本；22,050Hz／16-bit立體聲。結局音壓低在雷聲後方，柔性限幅與尾端靜音，保留既有播放-5dB。
- 只改隔離演出音效；沒有新下載sample、第三方音源、規則／玩家資料／正式場景變更。視覺時間軸與先前影格沿用，不假稱重驗666項視覺檢查。

## 審聽

[Web試演](http://127.0.0.1:48942/)：已重新載入；開啟「音效」並「重播」可從預備遠雷開始聽。預設仍靜音；本次驗收操作開啟後已恢復關閉。

- [成功新版錄影](artifacts/trib-b-f1/success.mp4)／[失敗新版錄影](artifacts/trib-b-f1/failure.mp4)：保留B原Godot渲染的視覺串流，ffmpeg只重配新版AAC聲軌，不重新壓縮畫面。
- [成功WAV](artifacts/trib-b-f1/success.wav)／[失敗WAV](artifacts/trib-b-f1/failure.wav)：完整20秒原始音訊。
- 舊`trib-b`錄影／WAV保留供比較；本輪新版位於`trib-b-f1`，不是舊錄影已更新的聲稱。

## 命令與結果

| 工具／命令 | 結果 |
| --- | --- |
| Godot `--version` | 4.7.2.stable.official.ed1daf0bf，exit0 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_trib_b.ps1 -ExportWeb` | 最終import／隔離export exit0，工具掃描SCRIPT ERROR／ERROR未發現；[build-final.log](artifacts/trib-b-f1/build-final.log) |
| Godot `--path build/trib-b-project --script res://audio_check.gd --log-file .../audio-native.log` | 原生16 checks／failures=[]／exit0；兩結局WAV、播放／暫停／seek／失焦／skip生命週期；[log](artifacts/trib-b-f1/audio-native.log)、[結果](artifacts/trib-b-f1/checks.json) |
| Python `wave`／`struct` PCM檢查 | 兩結局各20秒／雙聲道，peak0.81757，削波樣本0；1–3秒遠雷RMS0.07189、第一擊0.17217，末樣本0；[量測](artifacts/trib-b-f1/pcm-analysis.json)。只證明數位資料特性，不證明擬真聽感 |
| ffmpeg `-map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 160k -shortest` | 成功／失敗MP4重配新版音軌exit0；[成功log](artifacts/trib-b-f1/encode-success.log)、[失敗log](artifacts/trib-b-f1/encode-failure.log) |
| IAB現有48942頁reload、滑鼠音效／重播 | 新版完整成功演出自然結束，error／warn查詢空；[Web紀錄](artifacts/trib-b-f1/browser.json)。未宣稱代理已透過揚聲器聽測 |

最初headless測試16checks通過但退出有3個ObjectDB診斷，已保留`audio-headless.log`。測試清理多等4個process frame後，以真正原生渲染重跑，最終log沒有該診斷。首次apply_patch因同檔delete/add格式遭拒，改用update後成功；不是遊戲測試失敗。

音效來源`src/verification/tribb/sound.gd`，專項`audio_check.gd`及UID保存，export preset排除兩個驗證script；來源README同步記錄音效設計。全量遊戲Runner與三尺寸視覺不因純音效修訂重跑；無新FPS數字。保留既有dirty工作，未commit／push。

本階段已更新狀態與英文checkpoint；下一New Chat先收F1聽感回饋，未接受前不開TRIB-C。
