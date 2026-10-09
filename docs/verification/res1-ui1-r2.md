# RES1-UI1-R2：圖形化製造卡片

2026-10-09，**DONE（有界實作／桌面子範圍）**。使用者已確認R1介面區分清楚，要求依附圖將材料改ICON＋需求量，不滿足只變色。本輪不重新開啟效能定位，也不提升完整UI1-C／RES1-C/D的裝置與人工放行狀態。

## 交付

- 八配方清單改為材料圖示／本批需求數量 → 產物图示／本批產出；材料格只在可用量低於需求時改朱紅底／邊／數字，數量不因缺料改变。滿足恢復正常色，產物淡青綠。
- 移除清單中逐行材料名、可用／需求句子與重複「可製作／缺料」狀態；材料來源保留小字，名稱／來源／可用量／需求在tooltip及配方詳情可核對。加工、排隊與設施／滿倉等狀態保留。
- 真實剩餘秒數、進度、啟停／切方與Session命令不變。已扣料的當批即使材料格轉紅仍正常完工；紅色表示下一批材料不足，沒有取消／額外扣料。
- 寬式保留兩欄與左祖島資源；短橫式材料與操作側欄並排，總覽收起，第一張材料不需先捲動。短側欄加工狀態縮為狀態／秒數／收尾或待切方；固定篩選、返回與內部捲動保留。
- 配方詳情同樣加入圖形材料列，保留精確庫存、在途、保留容量及進階設定。規則、存檔schema、經濟、世界美術未改。

修改：`src/presentation/manufacturing_panel.gd`、`tests/res1_ui1a_runner.gd`。新增`src/presentation/resource_icon.gd`、`recipe_material_tile.gd`、`tools/res1_ui1r2_preview.gd`及引擎生成的三份UID。本輪文件、review fixture、原生／Web證據另存R2；保留既有dirty／AGY成果，未commit／push，Windows包未更新。

## 圖形來源與授權紀錄

提示／需求原文：「需求材料用ICON顯示，並且顯示需求數量，如果不滿足則變色就好。」附圖僅作材料→產物與進度布局參考，沒有複製第三方圖示、背景或文字。

`resource_icon.gd`是本輪原創Godot向量繪圖，15個已定義資源以枝材／礦塊／晶石／草葉／藥瓶／丹丸／符紙／陣芯／錢幣／靈力等形狀區分。用途限製造材料與產物。切層為材料格背景與邊框、獨立向量Control、數量Label、來源Label，分開更新；沒有新增bitmap、ImageGen資產或第三方授權依賴。程式隨本專案管理，最終圖示辨識／美術接受仍由使用者確認。

## 命令與結果

使用既有`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`（以下Godot）；Python／Node使用既有bundled runtime。

| 命令 | 結果／`artifacts/`日誌 |
| --- | --- |
| Godot `--version` | exit0，4.7.2.stable.official.ed1daf0bf |
| Godot `--headless --path . --import` | 修復後exit0，`res1-ui1-r2-import-repaired.log` |
| PowerShell `-NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | **56/56，exit0**；當轮A205／B140，`res1-ui1-r2-all-runners.log`，在最後短卡片排列修訂前 |
| Godot `--headless --path . --script res://tests/res1_ui1a_runner.gd` | 最後 **207 checks，exit0**；`res1-ui1-r2-runner-compact.log`，包含原命令／保存及八配方圖示、需求、可用不足、剛好滿足變色、第一張材料可視幾何 |
| 同上 B、parity、responsive、world Runner | 最後B140、world59及兩項PASS，均exit0；`res1-ui1-r2-{res1_ui1b_runner,abode_presentation_parity_runner,m2d_responsive_ui_runner,res1d2_world_runner}.log` |
| Godot `--path . --script res://tools/res1_ui1r2_preview.gd` | 最後exit0，三尺寸各basic／recipe／synthesis／detail共12圖，無SCRIPT ERROR／OVERSIZE／polygon錯誤；`res1-ui1-r2-native-compact.log` |
| Python `tools/subset_game_fonts.py --check` | exit0，1823 codepoints，字型hash不變；`res1-ui1-r2-font-check-final.log` |
| Godot `--headless --path . --export-release Web build/web/index.html` | 最後exit0，`res1-ui1-r2-web-export-final.log` |
| Node `tools/prepare_web_compression.mjs build/web` | 最後exit0，Brotli往返及四首BGM companions，`res1-ui1-r2-compression-final.log` |
| Python `tools/island_preview_server.py --port 4297 --normal-build --fixture res1-ui1-r2-review.json --gzip` | 正常隔離Web；驗後Ctrl+C停止（exit1為人工中止） |

最終PCK SHA256：`14cada469dd6b115b31e22d72b9f78670f7e913da752b193ba0fec4d6f65d451`。完整56當輪205不寫成最終207；短版改動後已補四相關Runner與207。一般Web已同步。

過程問題保留：首次import發現R1的11張瀏覽器JPEG誤用PNG副檔名，已僅更名`.jpg`、移除過時的相鄰import sidecar並更新R1證據連結，未改圖像bytes／`.godot`。隔離preview首次使用不存在的state.economy.inventory而中止（Ctrl+C），改既有IslandEconomy._put；符咒初版折線誤當polygon導致triangulation錯誤，改draw_polyline。修復後重跑通過；原生日誌仍有既有Font RID／CanvasItem／ObjectDB退出診斷，不稱零錯誤。

## 真實Web操作

IAB／cua_repl，1380×850臨時browser override容納測試iframe；DOM核對CSS1280×720、844×390、800×360，DPR約1。正式畫布仍Adaptive。新origin4297首次seed一份命令earned Era3 fixture，其後只Play，未讀寫4175玩家進度。

1. 桌面精煉／合成各四卡、三材料配方、左資源與紅色缺料格清楚。實際點築基丹「製作一批」，祖島靈力／玄銅／草扣除，卡片進度與收據出現；靈力不足下一批時200需求格轉紅，當批繼續完成。`web-recipes-1280.jpg`、`web-synthesis-shortage-1280.jpg`、`web-start-1280.jpg`在最後短版修訂前，桌面實作一致。
2. 重載最後PCK後保留完成的築基丹1與已進行的兩島產線，未覆寫測試origin資料。最後844橫向銅精卡，材料、動作、2秒與進度同屏。合成內部wheel捲到三材料符咒，固定分類與导航不動；縮800後全部材料及操作仍可見。`web-compact-844.jpg`、`web-three-inputs-844.jpg`、`web-three-inputs-800.jpg`。
3. 800點符咒標題進詳情，內捲讀祖島木345／需10、石345／需5及靈力可用／需50，固定返回可點。360旋轉罩下點背景分頁無作用，回800仍符咒詳情；返回後放大桌面恢复兩欄。`web-detail-stock-800.jpg`、`web-portrait.jpg`、`web-rotation-restored.jpg`、**`web-final-1280.jpg`**。最後browser warn/error查詢空。

全部圖片在`artifacts/res1-ui1-r2/`，瀏覽器截圖實際JPEG故副檔名`.jpg`。原生review在診斷修改前re-envelope earned fixture；原生圖的ore remaining4及丹霞草0僅呈現診斷，不當正常進度或保存證據。原生844映射與WebCSS量測分開，未以native冒充裝置。

## 未通過／交接

使用者對這版圖示辨識與視覺密度的最終接受、實體觸控／高DPR／完整UI1-C裝置清單仍待驗。本輪沒有新增FPS或冷啟動數據，沿用AGY／使用者已接受政策；不重做保存400矩陣。服務停止、本輪分頁已關閉，browser override復原，4297隔離進度保留。下次用上述服務命令重開、按Play，勿再seed。

依Context Guard在updata頂部寫英文checkpoint並同步development-status。下一New Chat接圖示／密度回饋或剩餘裝置驗收，不開Era4。
