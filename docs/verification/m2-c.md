# M2-C 驗收紀錄｜Godot 第一分鐘九界鉤子

日期：2026-09-19。狀態：**DONE**（CLI／桌面路徑；全量 12 個 Runner 全數 PASS）。

## 目標與邊界

依據 [ROADMAP.md](file:///e:/WORK/Dao2/ROADMAP.md) §6 M2-C：
1. 實現正式 Godot 引氣事件觸發（首次聚氣引靈產生靈氣時，丹田靈息與天地交感）。
2. 6–8 秒可跳過神識抽遠鏡頭（相機從洞府特寫 0.70 平滑抽遠至星域虛空 0.08，洞府作為發光的燈火清晰可辨）。
3. 展現九界預覽面板（人界、靈界、幽冥界、萬妖界、天魔界、仙界、佛界、混沌界、太初界），展示法則願景與一句話特色。
4. 支援「標記嚮往（Aspire）」，將心儀界域記錄於存檔（`tutorial_flags["aspired_realm"]`），**嚴格落實零副作用契約**（不產生任何靈氣、資源、數值或倍率變化）。
5. 確定性返回洞府：收回神識後相機平滑（或低特效瞬移）返回 `0.70`，介面完整恢復洞府操作。
6. 存檔持久化與可重播：已看狀態記錄入存檔（`seen_nine_realms_hook: true`），重開遊戲不強奪鏡頭或強迫重複教學；主畫面提供「九界星圖」按鈕，隨時可手動重溫或標記，且重播嚴格不發放任何獎勵。
7. 低動態模式（`reduced_motion`）：抽遠鏡頭簡化為 0.2 秒平滑切入，避免連續劇烈插值。

## 交付產物

- `content/realms/realms.json`：九大界域（人界、靈界、幽冥、萬妖、天魔、仙、佛、混沌、太初）資料定義，包含各界法則、定位、描述與初始狀態。
- `src/domain/game_state.gd`：新增 `tutorial_flags: Dictionary = {}` 支援快照複製與序列化。
- `src/persistence/save_codec.gd`：相容讀取 `tutorial_flags`，維持存檔往返校驗。
- `src/abode/abode_camera.gd`：調整 `MIN_ZOOM` 為 0.06，新增 `focus_cosmos()` 方法（目標縮放 0.08，對準虛空）。
- `src/presentation/nine_realms_preview.gd`：九界抽遠演出與星圖預覽組件，支援 6-8s 動畫、即時跳過 (ESC)、九界卡片網格、標記嚮往及收回神識。
- `src/abode/living_abode.gd`：首次 `gather` 時自動觸發神識抽遠；toolbar 增加「九界星圖」按鈕；連接標記嚮往事件並自動存檔。
- `tests/m2c_nine_realms_runner.gd`：專屬 M2-C 驗收測試，驗證開局空白、首次引氣觸發、動畫跳過、九界卡片資料、標記嚮往零副作用、返回洞府、存檔重載不重複彈出、重播無二次獎勵全流程。

## 驗收環境與執行命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m2c_nine_realms_runner.gd
& $daoEngine --headless --path . --script res://tests/m2b_breakthrough_runner.gd
& $daoEngine --headless --path . --script res://tests/m2a_abode_runner.gd
& $daoEngine --headless --path . --script res://tests/living_abode_runner.gd
& $daoEngine --headless --path . --quit-after 3
& $daoEngine --headless --path . --export-release Web '.\build\web\index.html'
```

### 實測結果（2026-09-19）
- `--import`：退出碼 0。
- `m2c_nine_realms_runner.gd`：退出碼 0，輸出 `PASS: M2-C first-minute hook, 6-8s skippable zoom-out, 9 realms preview, aspire bookmarking, zero side-effects, and persistence.`。
- 全量 12 個 Runner 迴歸：全部退出碼 0，無任何 SCRIPT ERROR。
- `--quit-after 3`：主場景啟動正常退出碼 0，輸出 `ABODE_READY`。
- Web Release 匯出：成功產出 `build/web/index.html`，退出碼 0。

## DoD 對照

| 驗收條款 | 驗證證據 |
| :--- | :--- |
| 正式引氣事件觸發 | 首次調用 `_gather_lingli()` 時，觸發 `seen_nine_realms_hook = true` 並展開演出 |
| 6–8 秒可跳過神識抽遠 | `NineRealmsPreview` 提供 6 秒平滑相機抽遠；點擊「跳過」按鈕在當前幀即刻切至九界預覽 |
| 九界法則願景展示 | 9 張界域卡片完整呈現名稱、定位與法則願景；人界顯示當前洞府，其餘 8 界標記未解鎖 |
| 標記嚮往零副作用 | 標記「靈界」為嚮往，`state.tutorial_flags["aspired_realm"]` 更新為 `realm_spirit`，靈氣庫存與產率無任何變動 |
| 確定性返回洞府 | 點擊「收回神識」，相機平滑回正至 `0.70`，關閉預覽面板，洞府建築可正常點選互動 |
| 存檔持久化與重開防護 | 存檔後銷毀場景重啟，`seen_nine_realms_hook` 維持 `true`，遊戲啟動絕不強制重複演出 |
| 重播入口與無獎勵保證 | 點擊「九界星圖」隨時重溫九界星圖，關閉後各項資源依然守恆，無任何二次獎勵發放 |
| 低動態適配 | 低特效模式下相機縮放過渡簡化為 0.2 秒，避免連續大幅運鏡造成的視覺不適 |

## 未實作／留待後續任務

1. 實體手機觸控、360 CSS px 排版適配、效能幀率與首切片發布放行留在 M2-D。
2. 跨界通行的法則解鎖與實體第二界據點留在 M4。
