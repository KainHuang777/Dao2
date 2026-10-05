# RES1-C2-PERF-R2｜長幀入口與前置檢查追蹤

2026-10-04，診斷子階段交付。**R2／C／C2 IN_PROGRESS、D TODO**。正常模式嚴格60FPS未通過，沒有效能改善可宣稱。本輪依既有View／encode階段交接，追蹤未覆蓋的task／引擎工作，不增加島嶼或修改玩法。

## 修改與證據邊界

- `src/abode/living_abode.gd`：診斷frame從 `_process` 入口開始，新增 `preflight`，含session／Web存檔鎖／輪迴檢查與同步時間準備；三個提前返回都結束計時。背景結算await前結束，成功恢復後重開，不能將等待當同步CPU。其餘既有span不变，profile仍預設關閉。
- `tools/res1c2_runtime_profile.js`：加入Long Animation Frames的支援偵測、1000筆上限、開始清空／停止取pending、窗口過濾與scalar腳本來源欄位；不保存Window物件。profile payload version2，舊字段保留。LongTasks／LoAF都是elapsed timing；腳本來源是入口，並非函式內call stack或GPU量測。
- `tools/summarize_runtime_profile.py`：保留LoAF原始資料與rAF重疊，新增有限／非負時間與drop拒收；不將LoAF／LongTask加進GDScript成本。兩個現有契約test文件補unsupported／窗口／pending／reset／容量／來源序列化／損壞時間案例。
- 未改收益、RNG、schema3、rules版本、即時命令保存、15秒保存、重試／兩槽順序、美術或引擎。原有dirty／untracked保留，沒有commit／push／部署；build僅由引擎與既有壓縮工具生成。

API依據：[Chrome Long Animation Frames](https://developer.chrome.com/docs/web-platform/long-animation-frames)與[W3C規格](https://www.w3.org/TR/long-animation-frames/)。腳本入口歸屬不代表入口函式內哪段最慢；renderStart包含rAF，不能把整個render phase當GPU時間。

## 真實瀏覽器診斷

Windows／IAB Chromium154，本機Brotli無節流，預設音樂與正常特效、祖島、數量模式、系統訊息開啟、離線摘要關閉、原始報告收起。原01／02 MP3載入資料保留，未獨立驗證可聽輸出；cache未清。所有取樣期間沒有Runner／匯出／壓縮並行。frameSample有效，CPU／LongTask／LoAF drop皆0，每筆raw約466KB，HTTP POST204。三组診斷全部排除FPS gate。

| 60秒診斷 | 實際CSS／DPR | CPU列 | rAF max | LongTask | LoAF |
| --- | --- | ---: | ---: | --- | --- |
| iframe，seq1 | 1280×721／約1 | 3523 | 216.8ms | 222ms | 支援true，0筆；不能解釋成無渲染問題 |
| 頂層頁面，seq1 | 1280×720／約1 | 3511 | 33.6ms | 0筆 | 52.3ms，MainLoop_runner 17.3ms |
| 頂層頁面，seq2 | 1280×720／約1 | 3417 | 83.3ms | 84ms、51ms | 85.3／56.7／51.5ms |

第一組216.8ms窗口，已量完整 `_process` 0.4ms，其中preflight0.1ms，HUD／View／保存0。這輪preflight平均0.098–0.101ms／p95 0.2ms，不支持將該尖峰指定為存檔鎖檢查；不能據此排除所有未量工作。

頂層第二組83.3ms窗口（end125973.5）：LongTask84ms，LoAF85.3ms，**`index.js` 的 `MainLoop_runner` 腳本回呼84.1ms**；styleAndLayoutStart125983.9，LoAF結尾125984.0，尾段約0.1ms；forcedStyleAndLayout／pause皆0。同窗GDScript0.4ms、preflight0.1ms、HUD／View／保存0。唯讀檢查生成JS char73085確認為Emscripten MainLoop runner入口。這將本次尖峰縮小到引擎迴圈回呼範圍，**沒有WASM內call stack，仍不能指定GC、GPU等待、其他節點、引擎函式或OS為根因**。iframe216.8ms沒有LoAF來源，亦不能把這次84.1ms歸屬套到之前所有大尖峰。

同組另一次50.1ms rAF窗對應51ms LongTask／51.5ms LoAF，MainLoop_runner50.8ms；已量process34.2ms，保存30.0ms（encode24.3、commit5.7），HUD3.6。保存與長幀有關聯，但不可把兩種尖峰視作相同原因或把inclusive spans相加。

原始與摘要：[raw](artifacts/res1-c2-task-profile-metrics.jsonl)、[profile摘要](artifacts/res1-c2-task-profile-summary.json)。同一URL的seq1分屬iframe／頂層reload，UTC不同；不要只按sequence去重。

## 正常FPS與驗收

同4247 origin頂層 `/metrics.html`，沒有RuntimeProfile bridge，正常preset（空custom_features）；與正常Web export PCK完全相同。1280×720／DPR1.0000000149、visible且stable，三組15秒全部有效：**57.9990／57.8636／57.7992FPS，pooled57.8873，p95均16.9ms，max均33.5ms**。嚴格60三組皆未過，p95≤20三組通過。歷史59.619為不同iframe／DPR／狀態，不宣稱本輪因果退步或改善。本輪沒有新無遊戲對照或配對優化基線。

[FPS raw](artifacts/res1-c2-task-fps-metrics.jsonl)是完整raw中非profile frameSample行的原文過濾；[重算摘要](artifacts/res1-c2-task-fps-summary.json)。正常重載摘要只有新4秒，保持當輪進度；正常console warn/error為空：[console](artifacts/res1-c2-task-console.json)。本輪未做新升級／窄版操作／完整保存故障矩陣，不用這個smoke代替前輪獨立操作證據。

![正常模式桌面畫面](artifacts/res1-c2-task-normal.png)

## 命令與結果

以下均於專案根目錄；引擎為 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，Node/Python為Codex bundled runtime（路徑可由load_workspace_dependencies取得）。

| 命令 | 結果／日誌 |
| --- | --- |
| Godot `--version` | 4.7.2.stable.official.ed1daf0bf，exit0 |
| `node tools/test_runtime_profile.mjs` | 基礎／LongTask／新增LoAF契約全部PASS，exit0 |
| `python tools/test_runtime_profile_summary.py` | 5 tests，OK，exit0 |
| `node tools/test_frame_metrics.mjs` | 9 observer contracts PASS，exit0 |
| `python tools/summarize_frame_metrics.py --self-test` | 8 summary contracts PASS，exit0 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | **51/51 exit0**，含resource754、精確145、async27；[log](artifacts/res1-c2-task-all-runners.log) |
| Godot `--headless --path . --script res://tests/res1c2_world_runner.gd` | 26 checks PASS／exit0；[log](artifacts/res1-c2-task-world.log) |
| Godot `--headless --path . --export-release Web build/web-profile/index.html`；`node tools/prepare_web_compression.mjs build/web-profile` | 各exit0；[export](artifacts/res1-c2-task-export.log)／[compression](artifacts/res1-c2-task-compression.log) |
| 相同兩命令，目錄改 `build/web` | 各exit0；[export](artifacts/res1-c2-task-normal-export.log)／[compression](artifacts/res1-c2-task-normal-compression.log) |
| Godot `--script res://tools/res1c2_review_fixture.gd` | 狀態不變，只重封UTC/save_id，exit0；[log](artifacts/res1-c2-task-fixture.log)，user://log拒寫診斷保留 |
| `python tools/summarize_runtime_profile.py … --output …`、`summarize_frame_metrics.py … --output …` | 3診斷／3正常有效樣本，exit0；見上述raw／summary |
| `git diff --check` | exit0，CRLF提醒保留；沒有whitespace error |

首次sandbox世界Runner拒user://寫入，STORAGE_STARTUP_FAILED後Nil／停滯；Ctrl+C停止exit1，[失敗日誌](artifacts/res1-c2-task-world-sandbox.log)保留。按AGENTS授權正常環境重跑後26 PASS。固定入口有預期故障JSON診斷，世界退出仍有Font／CanvasItem／ObjectDB／resource清理診斷，不宣稱零錯誤退出。沒有auto-review拒絕。

初始4244舊隔離入口可開；沿用已有進度開啟，遊戲正常推進／保存，未重新播種覆寫。新4246第一次載入因review UTC過舊，11921秒／壽元耗盡，不取樣；已停止本輪4246服務（Ctrl+C exit1）。重新封UTC後以全新4247取得32秒正常離線／之後reload6與4秒，沒有重新播種覆寫已有origin。Runner重生隔離earned／offline fixture，review工具只改隔離檔envelope；沒有操作玩家origin。

正常與profile PCK同為 `134334491bd68be37fec0cdc292916c5f93020fae986e7ae3a6ecfec5e216eba`；WASM仍 `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。本輪保留4247服務，命令：`python tools/island_preview_server.py --port 4247 --profile-build --gzip --review-fixture --metrics-log res1-c2-task-profile-metrics.jsonl`。正常遊戲用[launcher?metrics=1](http://127.0.0.1:4247/launcher?metrics=1)，既有資料按開啟隔離遊戲，seed拒覆寫；診斷頂層用 `/profile.html?profileSeconds=60`。瀏覽器override最後reset，分頁停launcher以釋放writer；其他服務未中斷。

下一同R2：對MainLoop_runner內WASM／SceneTree其他節點／繪圖階段做可重現追蹤，並調查目前正常樣本的33ms頻繁掉幀；保持保存與60門檻。手機觸控／DPR2/3／自然凍結／跨瀏覽器／長期WASM與GPU／人工美術節奏仍待驗，節流48h與完整146案未重跑。依AGENTS Context Guard，英文checkpoint置updata頂部，使用New Chat接同R2，不在本輪展開下一大型工作。
