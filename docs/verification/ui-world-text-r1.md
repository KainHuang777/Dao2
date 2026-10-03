# M2-D-UI3 R1：縮小空島文字可讀性

2026-10-03，IN_PROGRESS：實作、CLI 與桌面 Web 已驗；使用者美術、高 DPR 與實體手機待驗。

接續 Roadmap M2-D 視覺驗收與 UI3 世界文字，依使用者回饋修正。原建築名稱已使用思源黑體 600，洞府題字已用明體 800，但都隨 Camera2D 縮小；山域標籤仍用正文 400，遠景洞府／山域没有實底。舊 building.has_node("caption") 也未對上無命名的 Label，且子物件每幀強制顯示。

本輪沿用 UiTypography 600／800，統一深墨不透明底板、淺絹文字，移除小字陰影。文字以父世界 canvas transform 補償鏡頭縮小，名稱／採收浮字最低 18、遠景洞府題字最低 24 邏輯像素；仍跟隨世界錨點。zoom < 0.34 顯示洞府題字並隱藏建築銘牌，山域名稱在 0.12 <= zoom < 0.34 顯示；題字不再隨地形淡出。世界標籤 mouse_filter IGNORE。

修改來源：`src/presentation/ui_material.gd`、`src/abode/living_abode.gd`、`src/abode/abode_building.gd`、`src/abode/abode_scenery_prop.gd`、`src/abode/abode_tree.gd`。living_abode 與狀態／updata 原先已有未提交工作，本輪僅增量修改。不改經濟／保存格式，不新增圖形資產；底板由 Godot StyleBoxFlat 繪製。

命令使用 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`：

- `--version`：4.7.2.stable.official.ed1daf0bf，exit 0。
- `--headless --path . --script res://tests/m2d_responsive_ui_runner.gd`：最終 PASS，exit 0；`living_abode_runner.gd` PASS，exit 0。
- `abode_scenery_ui_runner.gd` 與 `abode_presentation_parity_runner.gd` 初跑受沙箱 user:// 寫入限制，保存斷言失敗；小景 Runner 遇 Nil 中止流程後仍運行，已用該 session Ctrl+C 結束。依專案授權升權重跑兩項隔離測試，均 PASS、exit 0。初跑／重跑日誌均保留。
- `--headless --path . --export-release Web build/web/index.html`：exit 0。
- `python -m http.server 4190 --bind 127.0.0.1 --directory build/web`：隔離新 origin，IAB 成功載入；未觸碰玩家 origin。

日誌：`docs/verification/artifacts/world-text-*.log`。既有退出 Font RID／CanvasItem／ObjectDB 清理診斷仍存在；不宣稱零錯誤日誌。初次靜態查找不存在的 abode_region.gd／Windows glob 失敗，已改用實際 living_abode 來源定位，不影響交付。

真實 IAB（DPR 約 1）：1280×720 關閉離線摘要／收起訊息，按 `-` 縮小至山域遠景／最小鏡頭，洞府粗明體与山域黑體、底板清晰。844×390 resize 保留遠景視角後，題字部分落在左 HUD 後；實際拖曳到右側後完整可讀，底板不攔截世界拖曳。console warn/error 空。未以 AX canvas fallback 判斷畫面。截圖：

- [桌面遠景](artifacts/world-text-desktop.png)
- [桌面山域縮放](artifacts/world-text-far.png)
- [最小縮放 0.06](artifacts/world-text-minimum.png)：真實鍵盤輸入，console target=0.06，洞府題字仍可讀；區域名稱收起。
- [短橫向拖曳後](artifacts/world-text-short.png)

限制：本轮浏览器新檔未建茅屋，建築銘牌／採收浮字最低字級只完成來源及相關 Runner 回歸，仍待實際 Web 建成／採收畫面；本輪未測滾輪、觸控、高 DPR 或效能。短橫向保留玩家遠景時可能被左 HUD 遮擋，未宣稱自動避讓。下一步收使用者縮小文字視覺回饋，再補上述裝置／建築案例；不展開 M1-C/D 大型工作。
