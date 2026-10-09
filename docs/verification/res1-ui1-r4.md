# RES1-UI1-R4：製造物品格辨識

2026-10-09，**DONE（有界呈現修訂／桌面驗證）**。使用者以實際畫面及紅框示意要求讓製造物品格更明顯；相依 R3 已交付。本輪只修改共用物品格，驗收為材料／數量／來源整組框線、產出與缺料辨識、三橫式顯示與原製造操作回歸。最終美術接受與實體觸控／高DPR仍待驗，完整UI1-C／C/D不提升。

## 修改

- `src/presentation/recipe_material_tile.gd`：恢復2邏輯像素圓角框，微陰影；材料為紙白底／灰青框，產出為淡青玉底／深青玉框，缺料為淡赭底／朱紅框，保留紅數字。框涵蓋ICON、數量與来源／產出文字；44px ICON、72px格寬及既有容器間距保持，不新增動態繪製或互動按鈕。
- 清單與詳情共用此元件；名稱／可用量tooltip、Session命令、庫存／收益／保存規則未改。
- 新增 `tools/res1_ui1r4_preview.gd` 及Godot生成UID，衍生R3隔離preview；輸出本輪review fixture與三尺寸12張原生PNG。只重置專用 `user://res1_ui1r4_preview`，不覆寫玩家資料。
- 框線由Godot StyleBoxFlat繪製，不新增圖形資產；保留R3手繪ICON及原來源／提示詞／授權紀錄。

## 命令與結果

Godot執行檔：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`；Python／Node使用桌面bundled runtime。

| 命令 | 結果 |
| --- | --- |
| Godot `--version` | exit0，4.7.2.stable.official.ed1daf0bf |
| Godot `--headless --path . --import` | exit0，`artifacts/res1-ui1-r4-import.log` |
| Godot `--headless --path . --script res://tests/res1_ui1a_runner.gd` | 授權重跑exit0，207 checks；`res1-ui1-r4-res1_ui1a_runner-repaired.log` |
| 同上 `abode_presentation_parity_runner.gd`、`m2d_responsive_ui_runner.gd` | 授權重跑皆PASS／exit0；對應 `res1-ui1-r4-*-repaired.log` |
| Godot `--path . --script res://tools/res1_ui1r4_preview.gd` | 授權重跑exit0；三尺寸12圖，無OVERSIZE／新SCRIPT ERROR，`res1-ui1-r4-native-repaired.log` |
| Godot `--headless --path . --export-release Web build/web/index.html` | exit0，`res1-ui1-r4-web-export.log` |
| Node `tools/prepare_web_compression.mjs build/web` | exit0；Brotli往返及四BGM companions，`res1-ui1-r4-compression.log` |
| Python `tools/island_preview_server.py --port 4299 --normal-build --fixture res1-ui1-r4-review.json --gzip` | 本機隔離服務提供新版正式包；驗後Ctrl+C停止exit1為主動中止 |

PCK SHA256：`6a2b4c2d1daf4a28056110268eed3f1c075bd65cb8ec7c6e9fffa3ea4cdd4f7a`。未重跑全量56、不把前輪全量結果當本輪；僅樣式修改，無新增介面文字，不需重生成字型。既有Font RID／CanvasItem／ObjectDB退出診斷保留。

首次沙箱preview／Runner無法寫user://，導致啟動失敗與Nil hide错误；受阻程序停止，經正常授權流程重跑成功。首次CIM程序查詢被沙箱拒絕，授權後只停止本輪指定受阻Godot；初次回歸shell後續程序亦Ctrl+C終止，最後CIM確認兩個Runner無残留。首次Web連線在服務啟動前失敗；啟動後另開分頁成功。錯誤分頁的data URL受Browser Use policy阻擋，未讀取／操作；成功分頁已關閉，viewport override已reset。一次rg將Windows glob當路徑失敗，改 `-g` 後正常讀取。沒有auto-review拒絕，沒有手改build或.godot修來源。

## 真實瀏覽器

使用computer-use／cua_repl IAB；暫時browser1380×850容納驗收iframe，DOM確認1280×720／844×390／800×360 CSS，DPR約1。4299為新origin，僅seed一次本輪command-earned Era3 review fixture。未存取4175玩家資料。

1. 桌面精煉／合成：材料、產出、缺料框均可辨；圖示、數量與來源有完整包圍。`artifacts/res1-ui1-r4/web-recipes-1280.jpg`、`web-synthesis-1280.jpg`。
2. 真實滑鼠築基丹製作：草150→100、玄銅300→280、靈力扣200，顯示20秒單批進度；自然完成築基丹1、產線恢復閒置與製作按鈕。`web-final-1280.jpg`。有界操作，不是完整新手通關或本輪保存故障矩陣。
3. 844×390首卡材料／動作同屏；內部wheel可至符咒三材料。800×360完整四格（3材料＋產出）與箭頭／動作未橫向溢出。`web-compact-844.jpg`、`web-three-inputs-800.jpg`。
4. 800詳情使用相同框，內部捲動／固定返回可操作，恢复1280兩欄成功。短詳情沿用既有內捲，未宣稱所有詳情資訊無須捲動。
5. 最後browser warn/error查詢為空；服務access log有favicon404，與遊戲資源無關，不宣稱HTTP零404。Web截圖為JPEG，原生為PNG。

## 交接

一般build/web已更新；Windows包／commit／push未做。4299服務停止，成功分頁關閉／override reset；隔離origin保留築基丹1，重開上述命令按開啟隔離遊戲，勿再seed。英文checkpoint追加updata頂部，狀態與接手入口同步。依Context Guard止於R4；下一New Chat收框線／底色美術回饋或剩餘裝置驗收，不開Era4、不重做已過保存／FPS，也不集中優化暫緩冷啟動。
