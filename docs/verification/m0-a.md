# M0-A：可重現的原型驗收

日期：2026-09-13。狀態：**桌面 Web 完成；實體觸控／雙指為待驗證項。**

## 目標與邊界

本項驗證現有 Godot 原型可以重跑、匯出並以真實瀏覽器輸入操作。它不建立正式 GameState、Amount、離線結算或洞府存檔。洞府的 `abode_state.gd` 是展示數值，頁面重載後重置；周天計數另以獨立專案及 origin 驗證保存。

## 新增／調整內容

| 檔案 | 用途 |
| --- | --- |
| `tools/run_m0a.ps1` | 失敗即停止的 root＋獨立周天探針匯入、runner、啟動與雙 Web export 指令 |
| `probes/cycle/` | 獨立 Godot 專案、字型副本、計數 Scene／runner；其 Web export 到 `build/web-probe/` |
| `probes/.gdignore`、`build/.gdignore` | 避免 root Godot 把隔離專案和生成輸出當作來源掃描 |
| `src/abode/abode_camera.gd` | 原型層加入平移、縮放、歸家可觀察 console 記錄 |
| `src/abode/living_abode.gd` | 原型層加入歸家與低特效狀態記錄 |

兩個 Web origin 固定為 `http://127.0.0.1:4175`（洞府）與 `http://127.0.0.1:4176`（周天探針）。port 是 origin 的一部分；改 port 後不應期待探針沿用保存資料。

## CLI 驗收

在 `E:\WORK\Dao2` 執行：

```powershell
& .\tools\run_m0a.ps1
```

2026-09-13 實際結果：退出碼 0。通過 root JSON／繁中 font runner、洞府 state runner、洞府 scene runner、洞府啟動、周天探針 runner、兩個 Web export。最後另執行 root `--import`，確認隔離 project 和 build 已不產生巢狀專案／輸出資產掃描警告。

已看到的必要輸出：

```text
PASS: project script, JSON serialization, user storage, and Traditional Chinese font glyphs are available.
PASS: abode state advances independently from visual flow, upgrades, and garden pause.
PASS: living abode selects buildings, upgrades, pauses production, and changes scale.
PASS: isolated cycle probe storage fixture and Traditional Chinese font are available.
[M0-A] CLI checks and both Web exports passed.
```

## 瀏覽器驗收

環境：Codex in-app Chromium、2026-09-13、1280×720 browser screenshot；Godot 直式 canvas 在此視窗有左右黑邊。依當次截圖重取座標，未沿用舊固定座標。畫布 AX tree 只會顯示 fallback canvas 文字，故以實際畫面和 Godot console event 一起判定。

| 案例 | 操作與觀察 | 結果 |
| --- | --- | --- |
| CYCLE-01 | 周天探針首載 | `CYCLE_PROBE_READY count=1`；繁中畫面可讀 | PASS |
| CYCLE-02 | 點「運轉一次周天」 | `CYCLE_PROBE_INCREMENT count=2` | PASS |
| CYCLE-03 | 重載同一 `127.0.0.1:4176` origin | `CYCLE_PROBE_READY count=3`；符合 1 → 2 → 3 | PASS |
| ABODE-01 | 首載洞府 | `ABODE_READY`；地形、三建築、飛劍／靈氣、HUD 顯示 | PASS |
| ABODE-02 | 點茅屋、按升級 | `ABODE_SELECT: hut`、`ABODE_UPGRADE: hut level=2` | PASS |
| ABODE-03 | 點藥圃、暫停再恢復 | `ABODE_SELECT: garden`、`ABODE_GARDEN_RUNNING: false`、`true` | PASS |
| ABODE-04 | 點低特效、展開神識、返回 | 按鈕改為「標準特效」；多浮島遠景出現，`ABODE_REGION`；歸家後近景恢復 | PASS |
| ABODE-05 | 世界空白處拖曳 | `ABODE_CAMERA_PAN position=(-210.0, -40.0)`；島嶼位置改變 | PASS |
| ABODE-06 | 世界空白處滾輪向上 | `ABODE_CAMERA_ZOOM target=0.632`；近景放大 | PASS |
| ABODE-07 | 拖曳／縮放後點 HUD「歸家」 | `ABODE_CAMERA_HOME`、`ABODE_HOME`；鏡頭回初始近景，沒有多餘世界點選 | PASS |

## 尚未通過／未適用

- 沒有實體手機或可注入真實 touch event 的瀏覽器測試，因此單指、雙指 pinch、手勢取消和不同手機 DPI 為 **PARTIAL**。程式有 InputEventScreenTouch／ScreenDrag／MagnifyGesture 路徑，不能以此取代實機證據。
- 沒有 FPS、GPU、冷啟動網路節流或記憶體長時量測；它們屬 M2-D 的裝置放行。
- 這項的 Web 保存只證明獨立 probe 的 `user://` 計數可重載；不證明未來正式快照、IndexedDB transaction、雙分頁或洞府存檔。這些留給 M1-C。
- `src/效果圖` 仍被 root all_resources 匯出；已停止作為 Godot import 資產掃描。正式 release 最小化留給 M2-D，不能在本驗收任意刪參考素材。

## 後續

M0-A 的桌面驗收可讓 M0-B 進行。M2-D 前，以真實手機補 ABODE-05／06／07 的手勢、文字及觸控區證據；如果發現輸入差異，修 camera 層並重跑本紀錄的桌面案例。
