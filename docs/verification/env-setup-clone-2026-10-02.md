# ENV-CLONE-1：乾淨 clone 環境安裝與 Runner 複跑

任務 ID／日期／狀態：ENV-CLONE-1／2026-10-02／DONE（本機；Web 與裝置驗收未在此執行）

## 目標與非目標
- 目標：在 `D:\Temp\temp\Dao2`（origin/main `b9f6685` 的乾淨 clone）備妥 README 要求的同版 Godot 4.7.2 環境，並複跑固定入口 Runner。
- 非目標：Web 匯出、瀏覽器／高 DPR／實機觸控驗收、rule change、玩家存檔。

## 已滿足相依
- 無；初始環境任務。

## 修改檔案
- `tests/bgm_era_playlist_runner.gd`（唯一程式修改）：輪迴重置案例補 `_check_and_update_bgm_era()` 以模擬每幀流程；bare assert 改為 `_assert/_fail(quit(1))`，失敗以 exit 1 退出不再掛起整組 Runner。
- 未修改任何 `src/`、`docs/` 規則、資產或存檔。

## 驗收環境
- OS：Windows 11（PowerShell 7）；Godot `4.7.2.stable.official.ed1daf0bf`；headless。

## 命令／退出碼／結果
1. `git pull origin main`（補 remote）→ 856 檔案更新。
2. 引擎安裝：官方 release `Godot_v4.7.2-stable_win64.exe.zip`（內含 console 版）解壓至 `tools\godot\4.7.2\`；`Godot_v4.7.2-stable_export_templates.tpz` 解壓至 `tools\godot\4.7.2\editor_data\export_templates\4.7.2.stable\`；建立 `_sc_` 標記啟用自包含模式。
3. `--version` → `4.7.2.stable.official.ed1daf0bf`，exit 0。
4. `--headless --path . --import` → 196 素材匯入完成，exit 0。
5. `tools\run_all_runners.ps1` 首跑：前 27 個 PASS；`bgm_era_playlist_runner.gd` 第 28 個在 line 75 斷言失敗且程序掛起至 shell timeout → **33/34**；其餘 6 個單獨複跑全 PASS。
6. 修正測試後單跑 bgm runner → PASS exit 0。
7. 整組複跑 → **ALL 34 RUNNERS PASSED WITH EXIT CODE 0**。

## 失敗根因與證據
- `_check_and_update_bgm_era()`（`src/abode/living_abode.gd:1005`）以 `_last_known_era_id`（init 時記錄為 1，living_abode.gd:922）為改變偵測防護；真實流程由每幀 `_process`（living_abode.gd:642）驅動，但 Runner 直接改 `state.era_id` 未經 `_check`，`era 4→1` 時 `cur_era == _last_known_era_id` 提前 return，`_current_bgm_index` 停在 3。
- 斷言失敗路徑未 `quit(1)`，headless SceneTree 永不退出，阻塞 `run_all_runners.ps1`。
- 兩個檔案同期進庫（commit `53b864f`），故 DOC-A-R1 的「34/34 PASS」宣稱對 `b9f6685` 不成立；本頁是本機第一份 34/34 通過證據（含該修正）。

## 資料安全／存檔相容影響
- Runner 使用 user:// 隔離 fixture；未更動玩家存檔；規則未改。

## 未通過項、阻塞原因、下一步
- 本機未驗：Web release 匯出（`--export-release Web`）、`http://127.0.0.1:4175` 瀏覽器互動、高 DPR／實機；Python 3.9.13 已可提供 HTTP 服務。
- 引擎／模板已按 `.gitignore` 排除版本控制；每台機器照 `.gitignore` 註解自行安裝。
