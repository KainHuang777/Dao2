# TRIB-0 — 渡劫結果語意與當次重播

日期：2026-10-18。狀態：DONE（桌面／Web有界）；相依 VFX-TRIB-PLAN 已滿足。

本輪修正命令 `ok` 與渡劫結局混淆。`ok=true` 只代表命令已執行；正式 `tribulation_failed`、`tribulation_passed`、普通 `era_breakthrough` 事件決定結果。成功率、擲骰、降境、訓練歸零及丹藥疊層重置規則均未改動。

## 交付

- GameSession View 提供唯讀 `tribulation_preview`，沿 TribulationRules／AlchemySystem 計算。金丹起的風險確認列目標、含丹藥的成功率、疊層、失敗後果及開始／取消；普通升境維持短流程。
- LivingAbode 記錄正式事件及提交前後唯讀快照。失敗列原境界→實際降至境界滿層、實際訓練前後值及疊層重置；返回修煉。TRIB-0 使用靜態失敗結果，不冒用功成演出。後續新分鏡／美術仍屬 A–D。
- 命令拒絕不播渡劫失敗；當次記憶體重播不 submit。重載不從目前 Era 推造歷史，設定入口停用；轉世清除當次結果。引擎特效試播仍為獨立示意。
- 結果與保存分開。原生保存拒寫保留結果與重試；Web 既有儲存保護畫面同步顯示實際結局／損失。恢復後沿既有背景時間結算保存，不重送渡劫；保存 schema 未變。

## 內容與證據邊界

正式 content 目前只有 Era1–3，沒有下一個 Era4，故正常金丹流程目前不會進入雷劫判定。隔離 acceptance 沿既有 batch_a_pills 測試方式，追加最小 Era4、免除該 fixture 的金丹容量門檻並指定已知 RNG index；不是自然進程或新境界開放。正式 Web preset 排除 `src/verification/*`；普通 content／主場景保持。兩個 loopback origin 48930（失敗）及 48931（成功）只存測試進度。

## 修改檔案

正式來源：`src/application/game_session.gd`、`src/abode/living_abode.gd`、`src/presentation/breakthrough_sequence.gd`、`abode_hud_controller.gd`、`abode_modal_manager.gd`。

測試／工具：`tests/trib0_outcome_runner.gd`、`tests/m2b_breakthrough_runner.gd`、`tools/run_all_runners.ps1`、`src/verification/trib0_fixture.gd`、`trib0_acceptance.gd/.tscn`、`tools/trib0_server.py`、`project.godot` 及 `export_presets.cfg`（新增獨立 feature／preset）；保留 Godot 生成的 UID。

文件：本驗收、README、ROADMAP、ai-handoff、development-status、docs24、共用 UI 規範及 updata checkpoint。全量 runner 另重生既有隔離 fixture（early-flow1c／1d、res1-c-earned-era2、res1-c2-offline、res1-d2-active／earned-era3）；不是玩家進度。其他既有與並行 EARLY-V1 工作均保留，未 commit／push。

## 命令與結果

引擎：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`，exit0。下列命令以專案為 `--path .`：

| 命令 | 結果 |
| --- | --- |
| `--headless --script res://tests/trib0_outcome_runner.gd` | 最終 46 checks，failures=[]，exit0，outcome-final.log |
| `--script res://tests/trib0_outcome_runner.gd -- --capture` | Compatibility 原生 58 checks，failures=[]，exit0；12 PNG，native.log |
| `--headless --script res://tests/island_breakthrough_runner.gd` | PASS，exit0，保留既有鏡頭／HUD／skip／失焦／低特效生命週期回歸 |
| m2b_breakthrough／batch_a_pills／m2d_responsive_ui／abode_presentation_parity runners | 各 exit0，個別 log |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 76/76 PASS，exit0，all-runners.log；當時專項40項，新增準備三尺寸檢查後另跑最終46項及原生58項皆通過 |
| `--headless --export-release Trib0Acceptance build/trib0-acceptance/index.html` | exit0，獨立 acceptance |
| `--headless --export-release Web build/web/index.html` | exit0，正式 Web |
| `node tools/prepare_web_compression.mjs build/trib0-acceptance` 及 `build/web` | exit0，Brotli 往返／4 BGM companion 檢查，JSON 報告 |

所有證據位於 [artifacts/trib0](artifacts/trib0/)。專項涵蓋準備／取消不擲骰、含丹藥 83% 預覽、兩結局事件、單次擲骰、雙提交攔截、保存拒寫／恢復不變更狀態、內部與設定重播、命令拒絕、重載無歷史及三尺寸版面／44px。

初次 island runner 受沙箱 user://／log 寫入阻擋，未初始化 HUD 而產生 Nil 錯誤，已中斷；經正常權限流程重跑 exit0。初輪專項 40 checks 有一項 800×360 失敗，原因是測試 Window 仍套縮放；明確設 CONTENT_SCALE_MODE_DISABLED／content_scale_size 後實際三尺寸通過，未以改小 UI 避過。初次 diff-check 發現新增 preset 尾端空行，已移除。既有 anchor、Font／CanvasItem／ObjectDB 退出診斷及全量負面 fixture 預期錯誤保留，不宣稱日誌零錯誤。

## 真實桌面瀏覽器

Codex IAB，1280×720、844×390、800×360 實際 CSS／遊戲畫布；DPR1.25（桌面瀏覽器，非實機驗收）。1280×720 以 DOM canvas bounding rect 核對。

1. 48930 由 HUD 滑鼠開渡劫準備，83%／1 疊層及降境後果可讀；注入寫入拒絕後按開始，先發現舊共用遮罩不顯示結果，已修正為遮罩同步展示真實結局及保存失敗。修訂後重跑確認未再顯示功成。
2. 恢復儲存→滑鼠重試，顯示「渡劫未成」「金丹期→築基期滿層 LV10」「進度已保存」。1280 重播保持失敗；844 及 800 版面可讀，800 真實重播／返回命中。
3. 重載仍為築基滿層。診斷 `TRIB0_FIXTURE_READY`：原 Era3 index10，恢復／重載 Era2 index11，恰增一次；設定重溫突破灰化，沒有假成功回放。
4. 48931 獨立成功 fixture，滑鼠準備→開始→成功演出／跳過→金丹→元嬰功成結算與已保存；重播仍成功。Era4 只是測試資料。
5. 初次 acceptance 尚未複製可選 BGM companions，瀏覽器留下 download failed warning；隨後執行既有 prepare_web_compression 補齊，不把該輪稱零 console error。未新增音效／FPS量測。

畫面：web-denied.png、web-failure.png、web-failure-844.png、web-failure-800.png、web-reload-no-replay.png、web-success.png；原生 prepare／result success／false 三尺寸 PNG。browser-diagnostics.json 保留原日誌。

## 後續

只結束 TRIB-0。本輪不新增心境值、懲罰、境界內容或完整渡劫分鏡。下一個有界任務為 TRIB-A 拆層素材與關鍵構圖，使用 New Chat 承接 docs24；本輪不展開 A。

收尾：22份來源／文件嚴格UTF-8、3份JSON報告與git diff --check通過；hashes.json記錄來源與兩版PCK SHA256。正式Web export log未包含trib0_fixture。初次IAB連線逾時，loopback服務改由正常權限流程啟動後恢復。BGM配套補齊後48931服務實際回應兩首曲目HTTP200，未宣稱主觀聽感驗收。已關閉本輪兩個驗收分頁，48930／48931服務以Ctrl+C停止（exit1為主動終止），未操作其他服務。當輪DoD無未通過項；新素材／完整渡劫仍按後續批次。
