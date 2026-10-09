# RES1-UI1-R3：手繪資源ICON

2026-10-09，**DONE（有界實作與桌面驗證）**。使用者接受R2方向，要求改善資源ICON、避免明顯色塊／SVG感。相依R2已完成；本輪驗收為材質化圖示接線、44px及三橫式呈現、原需求／不足色／製造命令回歸與一般Web同步。最終美術接受與實體觸控／高DPR保留待驗，完整UI1-C／C/D不提升。

## 變更／來源

- `src/presentation/resource_icon.gd`撤下多邊形／平塗繪圖，改共用預載透明PNG，以44邏輯像素、linear filter繪製。無動畫／每幀處理／磁碟重讀；原UID保留。
- `recipe_material_tile.gd`移除材料格常態邊框／底色，紙面直接襯托物件；缺料保留朱紅數字與來源、6%淡紅底，不染壞原物件材質。需求量、來源、tooltip、進度與Session命令保持。
- 新增`assets/ui/resources-painted/`：16張160×160透明PNG、引擎import sidecar、manifest與完整prompt。15個既有content資源＋原renderer已有stone_high支持；後者不是新增解鎖或配方。
- 內建`image_gen`生成一份4×4靜態prop pack；依`generate2dsprite`技能用其原processor去洋紅、分格、居中及縮放。原始圖保留在Codex generated_images及本輪`artifacts/res1-ui1-r3/raw-sheet.png`，不引用專案外路徑運行。沒有複製第三方圖示，也沒有以程序幾何代替新美術。
- 木紋／樹皮、銅礦與金屬、玉石、藥草、釉面藥瓶、丹丸、符紙、陣芯、錢幣與靈力各有材質。生成提示全文／各PNG hash／原圖來源／用途／切層／權利說明見`assets/ui/resources-painted/manifest.json`與`prompt-used.txt`。本輪是AI生成原創資產，未承諾第三方商用授權。
- 新增隔離`tools/res1_ui1r3_preview.gd`與引擎UID；原生12圖／Web圖／review fixture另存R3。未改經濟、schema、玩家存檔、世界美術、Windows包、既有AGY成果，未commit／push。

## 命令／結果

使用現有Godot`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`及bundled Python／Node，沒有更新環境。

| 命令 | 結果與`artifacts/`證據 |
| --- | --- |
| Godot `--version` | exit0，4.7.2.stable.official.ed1daf0bf |
| 內建 `image_gen` | 成功生成4×4原圖，完整prompt在本輪資料與資產目錄 |
| Python skill `scripts/generate2dsprite.py process --input .../raw-sheet.png --target asset --mode prop_pack_4x4 --rows 4 --cols 4 --cell-size 160 --fit-scale 0.90 --align center --component-mode all --min-component-area 20 --threshold 30 --edge-threshold 120 --edge-clean-depth 1 --strict-qc --output-dir .../processed-clean --prompt-file .../prompt-used.txt` | 最終exit0；`res1-ui1-r3-process-clean.log`及`processed-clean/pipeline-meta.json`；16有效、empty／edge／clamp皆0 |
| Python PIL讀取QC（不繪圖） | 16張160×160、alpha0–255、非空且無邊界裁切、共615161bytes；`res1-ui1-r3-asset-audit.json` |
| Godot `--headless --path . --import` | exit0；`res1-ui1-r3-import.log`，無新SCRIPT ERROR／載入失敗 |
| Godot `--headless --path . --script res://tests/res1_ui1a_runner.gd` | **207 checks／exit0**；`res1-ui1-r3-res1_ui1a_runner.log` |
| 同上`abode_presentation_parity_runner.gd`與`m2d_responsive_ui_runner.gd` | PASS／exit0，對應`res1-ui1-r3-*.log` |
| Godot `--path . --script res://tools/res1_ui1r3_preview.gd` | exit0，三尺寸各basic／refining／synthesis／detail共12圖；`res1-ui1-r3-native.log`，無OVERSIZE／新SCRIPT ERROR |
| Python `tools/subset_game_fonts.py --check` | exit0，1823 codepoints／字型hash不變；`res1-ui1-r3-font-check.log` |
| Godot `--headless --path . --export-release Web build/web/index.html` | exit0；`res1-ui1-r3-web-export.log` |
| Node `tools/prepare_web_compression.mjs build/web` | exit0，Brotli往返與四BGM companions；`res1-ui1-r3-compression.log` |
| Python `tools/island_preview_server.py --port 4298 --normal-build --fixture res1-ui1-r3-review.json --gzip` | 正常提供隔離正式包；驗後Ctrl+C停止，exit1為人工中止 |

最終PCK SHA256：`6d85a7d24466c1f7980314a38eb146a3995b4a70939bd67f31eff771d45ef9c5`。本輪僅美術／材料底色，採三相關Runner，未重跑全量56，也不援用R2的56作R3結果。既有Font RID／CanvasItem／ObjectDB退出診斷保留。

處理過程：初版預設threshold100把紫晶內部顏色一併去掉，CLI QC雖過但視覺不接受；改threshold30保留材質，再將邊緣threshold調到120清除洋紅細邊。保留各版processed metadata，只有processed-clean進正式資產。一次錯誤查找processor不存在的frames子目錄已依實際平鋪輸出修正；一次同檔delete/add patch被工具拒絕、未套用，之後正常更新来源成功。沒有手改`.godot`或匯出物。

## Web實測

IAB／cua_repl，暫時browser1380×850容納測試iframe，DOM核對CSS1280×720、844×390、800×360／DPR約1；正式畫布仍Adaptive。4298新origin只seed一次earned Era3 fixture，未存取4175玩家資料。原生preview在review寫出後的ore remaining4／丹霞草0僅顯示診斷，不當正常進度證據。

1. 桌面精煉、合成各四卡：手繪PNG載入無背景方塊，木材／銅塊、原礦／晶石、丹丸／陣芯可辨，缺料紅色不遮材質。`web-recipes-1280.jpg`、`web-synthesis-1280.jpg`。
2. 真實點築基丹製作一批，祖島靈力200／玄銅20／草50扣除，成功收據與20秒進度出现；自然完工後丹1，按鈕恢复。`web-start-1280.jpg`、`web-final-1280.jpg`。這是earned fixture上的有界操作，不是空白完整新手通關。
3. 844首卡材料與動作同屏，內部wheel捲到三材料符咒；改800仍完整圖示／數字／動作，無橫向溢出。點標題開符咒詳情，固定返回仍可點，放大後恢復兩欄。`web-compact-844.jpg`、`web-three-inputs-800.jpg`、`web-detail-800.jpg`。最後browser warn/error查詢空。

圖片位於`artifacts/res1-ui1-r3/`。瀏覽器截圖為JPEG，使用`.jpg`；原生為PNG。本輪未補物理觸控、高DPR、完整旋轉矩陣或長FPS，不能當上述門檻放行。

## 交接

一般Web已同步。服務4298已停止、本輪分頁關閉／viewport override復原，origin資料保留；重開同命令按Play，勿重新seed。效能與冷啟動依使用者／AGY已接受政策，不重做已過保存400矩陣。最終圖示質感／辨識、實體觸控／高DPR及完整C裝置清單待驗。

英文checkpoint追加updata頂部、development-status同步。依Context Guard止於本輪美術修訂，下一New Chat收使用者對質感／辨識的回饋或剩餘裝置，不開Era4。
