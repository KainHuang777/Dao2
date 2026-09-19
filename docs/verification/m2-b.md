# M2-B 驗收紀錄｜首次升境與可重播演出

日期：2026-09-19。狀態：**DONE**（CLI／桌面路徑；全量 11 個 Runner 全數 PASS）。

## 目標與邊界

依據 [ROADMAP.md](file:///e:/WORK/Dao2/ROADMAP.md) §6 M2-B：
1. 實現首次境界突破規則（煉氣期 Era 1 突破至 築基期 Era 2）。
2. 在領域層實作修煉小階提升（`level_up_cultivation`）與大境界突破（`breakthrough_era`）。
3. 嚴格遵守大境界突破契約：要求靈氣上限容量達到 500（`caps["lingli"] >= 500`），**嚴格不扣除靈氣庫存**。
4. 交付突破演出組件 `src/presentation/breakthrough_sequence.gd`：包含天地異象、靈氣聚頂、神光貫通、祥雲環繞等動態特效，提供「跳過」按鈕，並支援「重播演出」且重播嚴格不發放任何重複獎勵。
5. 突破成功後，洞府主場景 `living_abode.gd` 天幕呈現築基祥雲異象，聚靈壇亮起護體靈光。
6. 支援存檔與載入，境界、小階與洞府天象在重啟後正確維持。

## 交付產物

- `content/eras/era2.json`：Era 2（築基期）內容定義，包含資源倍率（2.0）、壽元上限（120 祀）、晉階條件與突破容量限制。
- `content/manifest.json`：註冊 `era2.json`。
- `src/simulation/command_processor.gd`：新增 `level_up_cultivation` 與 `breakthrough_era` 指令處理邏輯，嚴格落實容量門檻檢查與非扣除契約。
- `src/application/game_session.gd`：提供 `level_up_cultivation()` 與 `breakthrough_era()` 應用層轉接方法。
- `src/presentation/breakthrough_sequence.gd`：可重複使用的獨立突破演出場景控制器，支援即時跳過、平滑淡出、音效／視覺觸發及純重播模式（`is_replay`）。
- `src/abode/living_abode.gd`：整合修煉進度條、晉階與突破按鈕、掛載突破演出節點、天幕祥雲與聚靈光環特效，並支援測試隔離目錄 `save_dir_override`。
- `tests/m2b_breakthrough_runner.gd`：專屬 M2-B 驗收測試，驗證小階修煉晉階、容量門檻防護、Era 2 突破、庫存不扣除、演出跳過與重播不重發、存檔重載與天象變化。
- `tests/living_abode_runner.gd` & `tests/m2a_abode_runner.gd`：新增存檔目錄隔離，確保各 Runner 測試環境互不污染。

## 驗收環境與執行命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m2b_breakthrough_runner.gd
& $daoEngine --headless --path . --script res://tests/m2a_abode_runner.gd
& $daoEngine --headless --path . --script res://tests/living_abode_runner.gd
& $daoEngine --headless --path . --quit-after 3
& $daoEngine --headless --path . --export-release Web '.\build\web\index.html'
```

### 實測結果（2026-09-19）
- `--import`：退出碼 0。
- `m2b_breakthrough_runner.gd`：退出碼 0，輸出 `PASS: M2-B cultivation level up, capacity check, breakthrough to Era 2, inventory preserved, sequence skip & replay, save/reload.`。
- `m2a_abode_runner.gd`：退出碼 0，輸出 `PASS: M2-A abode blank opening, manual start, auto production, chained unlocks, save/reload, and determinism.`。
- `living_abode_runner.gd`：退出碼 0，輸出 `PASS: living abode selects buildings, upgrades, pauses production, and changes scale.`。
- 全量 11 個 Runner 迴歸：全部退出碼 0，無任何 SCRIPT ERROR。
- `--quit-after 3`：正常啟動退出碼 0，輸出 `ABODE_READY`。
- Web Release 匯出：成功產出 `build/web/index.html`，退出碼 0。

## DoD 對照

| 驗收條款 | 驗證證據 |
| :--- | :--- |
| 修煉小階積累與晉階 | `GameSession.level_up_cultivation()` 累計修煉進度，小階由 1 升至 9 |
| 突破容量門檻檢查 | 靈氣上限未達 500 時呼叫突破被拒絕；升級聚靈壇使容量達 500 後通過突破 |
| 大境界突破不扣庫存 | 突破前靈氣庫存 250，突破至 Era 2（築基期）後庫存維持 250 嚴格未被扣減 |
| 突破演出與跳過 | `BreakthroughSequence` 播放動畫，點擊「跳過」按鈕在 0.1 秒內平滑結束演出 |
| 重播演出不重發獎勵 | 呼叫 `play_breakthrough(..., is_replay=true)` 播放演出，結束後靈氣庫存維持原樣，無任何二次獎勵發放 |
| 洞府外觀反饋 | 突破後 `clouds` 祥雲可見性啟用，`altar` 聚靈壇靈光環繞特效顯現 |
| 存檔重載維持狀態 | 重載場景後 `session.state.era_id == "era2"`，天幕祥雲維持開啟 |

## 未實作／留待後續任務

1. 九界神識一瞥第一分鐘引氣演出留待 M2-C。
2. 實體手機觸控與 360 CSS px 排版適配留待 M2-D 統一驗收。
