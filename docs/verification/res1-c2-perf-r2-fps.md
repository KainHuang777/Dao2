# RES1-C2-PERF-R2｜桌面 FPS 重複量測

後續2026-10-04：[耗時定位已交付](res1-c2-perf-r2-profile.md)，已量出HUD導覽／資源清單及保存編碼成本。下方「下一先profile」為本階段歷史，現在下一同R2改善HUD重複工作；原60FPS門檻維持。

2026-10-04。接續 R2 的量測子階段；**R2／C／C2 IN_PROGRESS、D TODO**。本輪交付量測防護及六組真實瀏覽器樣本，沒有遊戲效能改善或完整放行。60 FPS／p95≤20ms／節流啟動≤10秒門檻保持。

## 結果與可用證據

Windows／IAB Chromium 154，同一分頁與 iframe **1280×650 CSS px、DPR 1.25**，Brotli／gzip 協商、無節流。先取兩組空白頁 rAF 對照，載入正常版命令賺得三島檔、關閉離線摘要後取三組遊戲樣本，最後取一組空白頁對照。每組至少15秒，整段可見、尺寸及 DPR 沒有變動，沒有 Runner／匯出並行。

| 樣本 | FPS（不四捨五入判通過） | p95 ms | p99 ms | max ms | >20ms 間隔 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 對照前1 | 59.997200 | 16.8 | 16.9 | 17.0 | 0 |
| 對照前2 | 59.996800 | 16.8 | 17.0 | 17.2 | 0 |
| 遊戲1 | 59.130180 | 16.8 | 33.3 | 33.5 | 13 |
| 遊戲2 | 58.397275 | 16.8 | 33.3 | 200.0 | 14 |
| 遊戲3 | 59.530158 | 16.8 | 16.9 | 33.4 | 7 |
| 對照後1 | 59.997200 | 16.9 | 17.0 | 17.1 | 0 |

遊戲 pooled FPS（總間隔數／總時長）**59.019206**，對照 **59.997067**。三組遊戲 p95 通過，嚴格60全部未過；共34個>20ms間隔，包含一個200ms尖峰。完整[原始JSONL](artifacts/res1-c2-perf-r2-fps-v3-metrics.jsonl)及[重算摘要](artifacts/res1-c2-perf-r2-fps-v3-summary.json)保留所有間隔，不挑最快樣本。摘要程式 exit0 表示分析成功，`strictDesktopGate=NOT_PASSED` 才是效能結論。六組互相比較條件相同；量測報告在遊戲取樣時收起、對照時顯示短取樣提示，工具覆蓋層仍屬量測負擔。

空白頁也略低於60，證明本環境的觀測排程接近門檻；不能把遊戲除以對照、四捨五入或放寬門檻來判通過。遊戲有額外長幀，仍需定位。rAF不是GPU profiler，沒有證據可把200ms指定為存檔、GC或GPU成本。JS heap 59.5／94.4／113.2MB只是三個端點，不能據此宣布記憶體洩漏或長期穩定。

本輪1280×650／DPR1.25、fixture已自然經過8814秒；前輪59.930FPS為1280×720／DPR約1，兩者**不是同條件前後效能比較**。初次連線逾時工具回報約8591秒，不能忽略此期間的fixture老化。沒有清除瀏覽器profile／WASM快取。ready3.829秒只是無節流、8814秒離線個案，不代替前輪20Mbps／100ms的48h啟動證據。

## 修改與契約

- `tools/res1c2_metrics.js` v3：明確記錄game／raf_control、UTC與樣本序號、開始／結束條件與整段visibility／resize事件；中途隱藏、改尺寸／DPR或未ready標無效。增加median／p99／>20ms計數，保留v2 FPS分母與rawWindowFps、完整gaps；重點擊不清掉進行中的樣本。
- `tools/island_preview_server.py`：同一iframe切換rAF對照／遊戲，保留尺寸；修正切回遊戲仍顯示對照狀態文字。種檔拒覆寫與正常origin namespace保持。
- `tools/summarize_frame_metrics.py`：從raw gaps重新計算，拒絕v2缺少整段條件、非正間隔、數量／時長不符、未ready與不穩定樣本，去重並核對瀏覽器／尺寸／DPR／網路條件。至少三組遊戲且每組均達原60／20門檻才報PASS；對照不能代替遊戲。
- `tools/test_frame_metrics.mjs`：Node內建VM的observer契約案例；Python工具另有`--self-test`。這些是量測工具測試，不能代替真實瀏覽器FPS。
- 交接：README、ROADMAP、docs/07、ai-handoff、development-status、R2入口及updata；本頁及fps-v3證據。

Godot來源／素材／保存schema與rules未改，沒有手改build。測試檔工具只重封UTC／save_id並驗證state相同；fixture輸出`res1-c2-review-fixture.json`更新。正常PCK SHA256仍`7264ee1fccf17062f7e0c17c93177f5d836e5d30a3fcaa4fd66f4ef61215c11d`，WASM仍`fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。沒有讀寫其他origin玩家檔、commit／push／部署。

## 命令、結果與失敗紀錄

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version
# 4.7.2.stable.official.ed1daf0bf，exit0
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/res1c2_review_fixture.gd
# state保真PASS／exit0；仍有user://logs/godot.log拒寫診斷
node tools/test_frame_metrics.mjs
# 6 observer契約PASS／exit0
node --check tools/res1c2_metrics.js
# exit0
$daoPython = 'C:/Users/asus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $daoPython tools/summarize_frame_metrics.py --self-test
# 7 summary契約PASS／exit0
& $daoPython -m py_compile tools/island_preview_server.py tools/summarize_frame_metrics.py
# exit0
& $daoPython tools/summarize_frame_metrics.py docs/verification/artifacts/res1-c2-perf-r2-fps-v3-metrics.jsonl --output docs/verification/artifacts/res1-c2-perf-r2-fps-v3-summary.json
# 分析exit0；效能NOT_PASSED，6有效樣本／0拒絕
& $daoPython tools/island_preview_server.py --port 4238 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-r2-fps-v3-metrics.jsonl
# 正常環境綁定127.0.0.1；瀏覽器GET成功，證據POST204
git diff --check
```

[observer日誌](artifacts/res1-c2-perf-r2-fps-observer-tests.log)／[summary日誌](artifacts/res1-c2-perf-r2-fps-summary-tests.log)。本輪只改開發工具與文件，未重跑51 Runner、Godot import／export、完整保存矩陣；前輪通過數保留日期，不冒充新結果。

首次sandbox服務雖顯示啟動，但瀏覽器連線逾時；sandbox `Invoke-WebRequest`亦明確拒絕通訊端。依正常工具授權重啟服務及唯讀HTTP檢查後，入口200；原分頁停在data錯誤頁，reload／goto／close被URL policy拒絕，改用文件允許的新分頁後正常。未繞過URL policy或改防火牆。自己啟動的服務以Ctrl-C結束exit1後重啟套用狀態文字；這不是測試失敗或正常測試exit0。favicon404保留，正常測試分頁[warn/error記錄](artifacts/res1-c2-perf-r2-fps-v3-console.json)為空。

真實reload→Play摘要只新增19秒，未重套8814秒；滑鼠關閉摘要、隱藏量測覆蓋層後保存[交付畫面](artifacts/res1-c2-perf-r2-fps-v3-review.png)，它是试玩畫面，不是FPS報告截图。最後正常版分頁／4238服務保留：<http://127.0.0.1:4238/launcher?metrics=1>；已有進度按Play，不能重新覆寫。上一輪4236是否仍運作本輪未驗，不宣稱它仍在。

## 下一步與人工補證

先接續**同一R2**，用隔離開發profile定位`living_abode._process`：每秒Session推進及View重建、每0.25秒HUD刷新、每15秒同步SaveManager保存都是原碼可見候選；目前未量其耗時，不能宣稱任一是200ms原因。量出後才改善，規則／保存改動須補精確終態、async retry與必要全量回歸，再以相同fixture／1280×720／DPR／音樂與HUD條件比較。不得為了FPS取消即時命令保存、失敗重試或改收益。

人工可重跑：開4238入口、載入（已有檔則Play）、等實際畫面且關閉離線摘要，三次按「量測15秒」全程保持可見；同尺寸對照在遊戲前後各取樣並保留JSONL，用上方summary命令重算。指定手機觸控／30FPS／p95≤40ms、DPR2/3最大zoom、自然背景凍結、跨瀏覽器、長期WASM／GPU與人工美術／節奏仍待驗。loopback不是手機可連線部署。

此量測子階段驗證完畢，因本Session已有大量交接讀取與連線故障輸出，依[AGENTS Context Guard](../../AGENTS.md)停止展開下一大型profile階段；英文checkpoint置updata頂部，下一New Chat續R2，不跳D。
