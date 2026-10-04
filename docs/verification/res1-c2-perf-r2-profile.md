# RES1-C2-PERF-R2｜活躍場景 CPU 耗時定位

2026-10-04。**定位子階段交付，R2／C／C2 IN_PROGRESS，D TODO**。使用者要求「接續 R2 耗時定位」。本輪只增加可關閉的診斷量測，未實作效能改善、調整收益或保存契約；嚴格 60 FPS 門檻不變。

## 結論與下一個改善範圍

本次 Windows／IAB Chromium 154、1280×720 CSS iframe、DPR 1.0000000149011612，三島雙鏈命令生成 fixture、祖島畫面／資源數量模式／正常特效，關閉離線摘要、收起量測報告後，三組各15秒可見且尺寸穩定。沒有 Runner、匯出或壓縮工作與取樣並行。音樂保持遊戲預設設定；raw記錄01／02原MP3外載成功，未以音訊工具確認可聽輸出，也未分離量測解碼／播放成本。

| 細分版樣本 | HUD平均 ms | 導覽刷新＋排版 ms | 建築／資源清單刷新 ms | 規則有tick平均 ms | 保存單次 ms | 編碼／提交 ms | rAF FPS／max ms |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 12.814 | 5.039 | 3.947 | 1.188 | 18.8 | 14.6／4.2 | 59.531／49.9 |
| 2 | 12.795 | 5.135 | 3.860 | 1.306 | 18.1 | 13.8／4.2 | 59.265／33.5 |
| 3 | 12.704 | 5.056 | 3.688 | 1.294 | 22.7 | 18.5／4.1 | 59.531／33.4 |

HUD每0.25秒刷新，三組各59／57／57次，是已量測區段內最頻繁的高成本工作；細分 CPU body 最大19.7／21.1／23.1ms。BUFF列平均僅約0.02–0.03ms、島嶼世界refresh約0.06ms，優先順序較低。每秒規則tick約1.2–1.3ms，沒有證據支持優先改收益核心。保存每組各一次；三個保存事件不足以估計儲存延遲的長尾分布。

**下一同R2先改善 HUD 重複工作，再配對量測**：

1. `FeatureNavigation.layout()` 每次仍呼叫 `session.get_view()`；目前 `hud_navigation` 包含這次 View 與 shared-resource refresh、選中樣式及排版。可先沿用已傳入刷新流程的 View，驗證命令／debug／重載／切頁／resize不讀舊資料。此重建在原碼可見，但本輪沒有把它單獨計時，不能把整段5ms全算成這次View成本。
2. `BuildingCatalog.refresh()` 與 `refresh_shared_resources()` 都執行 `_update_resource_values()`；後者會重新生成並覆寫資源卡StyleBox。可量測減少同一HUD週期的重複格式化、樣式配置，保留滿倉／模式／資源可見性／共同貨幣即時更新。`hud_catalog`約3.7–3.9ms是整個refresh，不是純StyleBox成本。
3. 保存以 `SaveCodec.encode()` 約13.8–18.5ms為主；commit含寫入、回讀、比較和索引提交約4.1–4.2ms。後續若改善編碼，必須保留checksum、兩槽故障回復、版本與重試／精確狀態回歸，不能取消即時命令保存或15秒保存來追FPS。

## 證據與限制

- 初步三組[raw](artifacts/res1-c2-perf-r2-profile-metrics.jsonl)／[摘要](artifacts/res1-c2-perf-r2-profile-summary.json)：HUD平均12.816–12.996ms、保存17.9／19.5／20.4ms，rAF 59.330–59.664FPS。先定位HUD後才追加細分量測。
- 最終細分三組[raw](artifacts/res1-c2-perf-r2-profile-detail-metrics.jsonl)／[摘要](artifacts/res1-c2-perf-r2-profile-detail-summary.json)：共24個>20ms rAF間隔。16個時間窗與HUD CPU區段重疊、2個與保存重疊，6個窗內CPU body合計僅0.2–0.4ms（HUD與保存分類可按raw重算；窗口重疊可能重複計同一CPU frame，不能把它們加總為總成本）。**這只是時間關聯，並非把完整長幀歸因給該工作。**
- 本輪未重現200ms；render、GPU、其他節點、引擎延遲配置、OS／瀏覽器排程等不在這份GDScript計時內，不能推定200ms屬於存檔或GC。
- `process`計時邊界是living_abode通過儲存／輪迴／背景恢復檢查後的`state.advance`前，至`_mask_breakthrough_hud`後；**不是完整引擎幀**，不包含前置Web Lock檢查、await背景結算、其他節點、繪圖和輸出bridge成本。未包在此區段的使用者命令保存不會被本次probe收集。
- 所有span均為inclusive；`hud_total`包含其中的View／catalog／navigation，`save_total`包含encode／commit，不能相加。每列是同一CPU body中的累加耗時；summary的count是含該span的frame數，並非通用函式呼叫次數。`view_build`只包living_abode兩個已標記呼叫點，**不包含navigation內部get_view**。
- 原始單位µs但本環境常呈100µs階梯；不能宣稱微秒精度。JS endMs為bridge進入時間，包含JSON stringify／跨橋接延遲；rAF時間窗對齊為近似相關分析。
- 量測本身有額外負擔；profile樣本不作正式FPS驗收。`summarize_frame_metrics.py`新增拒絕`runtimeProfile`樣本的契約。沒有用profile與關閉profile的分數宣稱改善或扣除量測成本。
- 兩階段fixture來自同一命令生成state，但自然離線64秒／295秒，時辰與庫存會不同；這是逐步診斷，**不是效能修正的前後配對**。兩次非節流ready約2.74／2.86秒不代替前輪20Mbps／100ms的48h證據。

## 修改與啟用方式

- `src/platform/runtime_profile.gd`：預設關閉；僅隔離頁面提供`dao2RuntimeProfile`bridge時啟用。未讀寫遊戲資料、收益、RNG或存檔。正常路徑僅保留關閉分支呼叫成本。
- `src/abode/living_abode.gd`、`src/presentation/abode_hud_controller.gd`、`src/persistence/save_manager.gd`：加入上述區段計時；沒有改既有執行順序、保存結果或狀態版本。
- `tools/res1c2_runtime_profile.js`、`res1c2_metrics.js`：取樣期間保留CPU原始列與rAF結束時間，最多10000列並標記dropped；重點不重置進行中的sample。
- `tools/island_preview_server.py`：`--profile-build`指向獨立`build/web-profile`；`/launcher?profile=1`載入instrumented endpoint。正常`?metrics=1`沒有profile bridge。证據POST上限1MiB，以容納原始列；仍只綁loopback。
- 新增`tools/summarize_runtime_profile.py`、`test_runtime_profile.mjs`、`test_runtime_profile_summary.py`；原FPS摘要工具加profile排除防護。

正常`build/web`本輪沒有重新匯出，PCK仍`7264ee1fccf17062f7e0c17c93177f5d836e5d30a3fcaa4fd66f4ef61215c11d`。三組細分量測的PCK `2d1fe67a9201d391c2b03576c7ef8bfee167b3c5b28a55ce7010fac53184c546`；最後僅補初始化bridge存在檢查的PCK `1e42e85d8bd54551583c1ccfb5cfd26fb4e48096d8a9c70937741cc1bed0f244`，WASM `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。沒有手改build、commit、push或部署，既有dirty變更保留。

## 命令與結果

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$daoPython = 'C:/Users/asus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $daoEngine --version
# 4.7.2.stable.official.ed1daf0bf，exit0
& $daoEngine --headless --path . --import
# exit0；前輪fps-v3-review.png匯入失敗診斷保留
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
# 初次sandbox fixture拒寫exit1；正常授權重跑51/51 exit0（基礎profile版）
& $daoEngine --headless --path . --script res://tests/res1c2_world_runner.gd
# 基礎版及最後HUD細分版各26 checks／exit0；既有退出RID/ObjectDB診斷保留
& $daoEngine --headless --path . --script res://tools/res1c2_review_fixture.gd
# command-earned state保真／只重封UTC與save_id，exit0
& $daoEngine --headless --path . --export-release Web build/web-profile/index.html
# 首次資料夾不存在exit1；建立資料夾後基礎及細分版均exit0
node tools/prepare_web_compression.mjs build/web-profile
# 兩版均exit0；BGM companions／gzip／Brotli
node tools/test_frame_metrics.mjs
node tools/test_runtime_profile.mjs
& $daoPython tools/test_runtime_profile_summary.py
& $daoPython tools/summarize_frame_metrics.py --self-test
# observer6、profile契約、summary3 tests、FPS summary8契約PASS
& $daoPython tools/island_preview_server.py --port 4241 --profile-build --gzip --review-fixture --metrics-log res1-c2-perf-r2-profile-detail-metrics.jsonl
# 正常授權loopback服務，真實瀏覽器GET成功／POST204
& $daoPython tools/summarize_runtime_profile.py docs/verification/artifacts/res1-c2-perf-r2-profile-detail-metrics.jsonl --output docs/verification/artifacts/res1-c2-perf-r2-profile-detail-summary.json
# 三組有效／無drop，exit0
```

完整命令日誌位於`artifacts/res1-c2-perf-r2-profile-*`。全量51/51之後只追加HUD細分計時，最終受影響世界/HUD26項重跑通過；沒有將先前全量誤稱為最後細分版全量。沒有新跑完整Web保存故障矩陣或節流48h矩陣，先前證據保留日期。

最後修正：非profile頁面直接`get_interface`曾輸出缺少`dao2RuntimeProfile`錯誤，保留[原console](artifacts/res1-c2-perf-r2-profile-missing-bridge-console.json)。補存在檢查後，重新export/compression及world26通過；新分頁真實正常啟動、重載摘要只新增15秒，console為空。再次啟用profile收集898 CPU frames、零drop、樣本valid，證明開關兩條路徑均可用，[final raw](artifacts/res1-c2-perf-r2-profile-final-metrics.jsonl)／[final摘要](artifacts/res1-c2-perf-r2-profile-final-summary.json)／[console](artifacts/res1-c2-perf-r2-profile-console-final.json)。這次功能複驗採還原後的783×542 CSS／DPR1.25，59.864FPS，不能併入上表或當效能前後比較。較早未修防護的非profile smoke為58.730FPS，只有一組，也不作驗收。沒有宣稱嚴格60通過。

只停止自己建立的4240與舊4241服務（Ctrl-C exit1），新4241服務與[隔離profile頁](http://127.0.0.1:4241/launcher?profile=1)保留。切換`?metrics=1`則不啟用CPU profile，已有隔離進度按「開啟隔離遊戲」；種檔仍拒覆寫。沒有中斷既有其他服務，瀏覽器暫時viewport override已還原。

![最終隔離遊戲與profile開關複驗畫面，非FPS報告](artifacts/res1-c2-perf-r2-profile-review-final.jpg)

下一個大型工作使用New Chat，續同R2的HUD重複View／資源卡刷新改善，再收同fixture／尺寸／DPR／音樂／HUD條件的非profile配對樣本。裝置／高DPR／自然背景凍結／跨瀏覽器／長期GPU與人工美術、節奏仍待驗；不跳D。
