# M2-D-ISLAND1 驗收紀錄

2026-10-03；Godot `4.7.2.stable.official.ed1daf0bf`，Compatibility、同版單執行緒 Web。**IN_PROGRESS：實作／CLI／桌面 Web 已交付，使用者美術與實機待補。** [設計契約](../13-island-scenery-and-courtyard-spec.md)。

## 實際檔案與行為

- `assets/abode/island1/`：四份獨立透明素材；[提示詞、來源、參數、QC／hash](../abode-art/island1/README.md)。
- `src/simulation/abode_scenery.gd`、GameState／SaveCodec：內部版本 1、專用 RNG、穩定 ID／獎勵／倒數保存，舊 schema-2 缺欄位讀為空，非法欄位拒讀。
- GameSession／CommandProcessor／TimeAdvancer／ReincarnationRules：正式採收命令、線上／離線共同出現路徑、輪迴清除。
- `abode_scenery_prop.gd`／`living_abode.gd`／`abode_camera.gd`：四個島面插槽、最多兩件、44px 等級命中、文字回饋、即時保存及重試、Era 2 外觀、短橫式初始／歸家構圖。點地標原本未切入導覽群組，實測 Escape 無法返回；已補接經營／建築 route。
- 兩個小景 Runner、living_abode_runner、固定 Runner 清單、`tools/island_scenery_preview.gd`、規格與交接文件。

## 命令與結果

| 入口 | 結果 |
| --- | --- |
| Godot console `--version` | 4.7.2.stable.official.ed1daf0bf |
| `--headless --editor --path . --import --quit` | exit 0；新腳本無 Parse／Compile／Script error。[匯入紀錄](island1-import.log)。[初次全目錄 scan](island1-import-initial.log) 遇既有 NAV1 portrait 圖片副檔名／內容不符，未修改該歷史檔 |
| `--headless --path . --script res://tests/abode_scenery_runner.gd` | PASS、exit 0；解鎖、三種類型、1200 秒整段／分段等價、最多兩件、批量、滿倉／局部容量、重送／重載不重給、快照／隔離槽、格式拒讀、輪迴。[規則紀錄](island1-core.log) |
| `--headless --path . --script res://tests/abode_scenery_ui_runner.gd` | PASS；外觀不改規則／新世回復、世界採收／即時保存、失敗明示與重試、短橫式完整地標／平移保留、遠景／他界隱藏、地標導覽／Escape。最終結果含於完整回歸紀錄 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1` | **38/38 PASS、exit 0**，含最終地標導覽修正。[完整紀錄](island1-all-runners.log) |
| Godot `--path . --script res://tools/island_scenery_preview.gd` | 八張 PNG、exit 0；Era 1/2 × 1280×720/844×390 × 兩組小景，涵蓋四插槽／三種類型。[紀錄](island1-native.log)、[畫面](artifacts/island1/) |
| `--headless --path . --export-release Web .\build\web\index.html` | exit 0；[匯出紀錄](island1-web-export.log) |

初期測試抓出測試 API 誤用、JSON 浮點還原與 int 欄位比較、輪迴 fixture 壽元設定，已修正。外觀中立案例針對已有 View 的 `_update_buildings_visual`，不把既有 get_view lazy 初始化視為美術改變。場景關閉仍有既有 Font／CanvasItem／ObjectDB／resource-in-use 警告；exit 0 不等於零診斷。沒有量測新 FPS／GPU／長期記憶體。

## 真實瀏覽器

Codex IAB、滑鼠、DPR 約 1。Python HTTP 只服務靜態檔，專用 localhost:4184／4185 與既有玩家 origin 隔離。`artifacts/island1/fixture-loader.html` 僅在兩指定 origin 且沒有存檔時，透過按鈕載入 Godot 生成的 QA fixture；此 setup 不算玩家正常匯入驗收，docs 不進正式 export。

- 1280×720：小院／兩件獨立小景；實點靈木 +5、靈草 +3；木材採收後 reload 庫存仍為 5、原物件不復活、另一件待採收保留。
- 844×390：屋頂完整且位於左 HUD 旁；實點靈石 +2，有實際 Godot 回饋／console 命令成功。畫布 843×389 CSS px、document 844×390，無瀏覽器捲軸。
- 小院點擊讀同一 hut 詳情；最後導覽接線修正再驗經營／建築分頁與 Escape 返回。
- 兩 origin 的本輪 error console 皆空；[console 紀錄](artifacts/island1/web-console.json)。

圖片：`web-home-before-1280x720.jpg`、`web-wood-claimed-1280x720.jpg`、`web-after-reload-1280x720.jpg`、`web-herb-claimed-1280x720.jpg`、`web-stone-before-1280x720.jpg`、`web-stone-before-844x390.jpg`、`web-stone-claimed-844x390.jpg`、`web-landmark-route-844x390.jpg`、`web-home-final-844x390.jpg`。CUA 實際輸出 JPEG，因此用 .jpg；native renderer 為 PNG。

## 未完成項與下一步

使用者美術／尺寸回饋、指定實體橫式手機觸控／高 DPR、長期獎勵平衡待驗。既有直式冷啟動提示可讀性、全遊戲 quota／多分頁／額外容量倍率整合不由本輪推定完成。現有分享字串匯入按鈕只驗證未套用進度，另列保存 UX 待改善，本輪使用明示的隔離 fixture loader。

先依使用者回饋微調本輪圖與節奏；大型後續工作以 New Chat 與 checkpoint 接手。
