# UIX-R4-F1：緊湊單欄與唯一材料環

2026-10-11。有界來源／CLI／桌面Web修訂 DONE；人工美術接受、實體觸控／高DPR待驗。

使用者指出圖示外環和底部材料條重複、圖卡空白偏多，允許恢復每行一座建築。採全尺寸單欄，橫式營造簿上限680→400px（縮窄約41%），列高64→56px（約12.5%），縮圖48→40px。材料圖示24px與庫存/需求、等級點、前置條件及既有操作保留。完全移除橫向ProgressBar與布局覆寫；外環仍取最不足材料比例。未新增翻譯；將來英文版應依實際字串另驗，現有容器／文字省略、展開說明及詳情機制保留，沒有預留英文空白或承諾已驗英文。

修改：src/presentation/building_catalog.gd、feature_navigation.gd；tests/uix_r4_building_cards_runner.gd、ui_material_states_runner.gd、m2d_responsive_ui_runner.gd、feature_navigation_runner.gd；README、ROADMAP、docs07/08/18、ai-handoff、development-status、updata與本頁。既有dirty成果保持；無經濟／存檔／世界資產變更，未commit/push或Windows匯出。

命令：現有tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version確認4.7.2.stable.official.ed1daf0bf。隔離APPDATA=build/uix-r4-feedback-user，--headless --path . --script res://tests/<name>_runner.gd：uix_r4_building_cards、ui_material_states、m2d_responsive_ui、feature_navigation、uix_r2_hud（67 checks）、abode_presentation_parity最終六項皆exit0。沒有重跑全套62，前輪62為歷史證據。首次responsive因舊64px斷言exit1；navigation因舊雙欄自動收訊息假設exit1，修改為400px單欄及訊息可共存，再跑exit0。既有Font／CanvasItem／ObjectDB退出警告保留。rg Windows wildcard曾exit1，改正路徑搜尋。

--headless --path . --export-release Web build/web/index.html exit0；bundled Node tools/prepare_web_compression.mjs build/web exit0（含BGM companions）。PCK SHA256 CDC1AE55BB4DA45BEE3AAD9FCEDE88FC469A0EA86225F7EB6CA1E7DF1999C21C。git diff --check指定六來源／測試通過，僅LF→CRLF提示。

真實IAB：python tools/island_preview_server.py --port48219 --normal-build --gzip；首次未啟動連線拒絕、沙箱服務連入逾時，正常授權啟動後可用。全新隔離origin Play，從未Seed，滑鼠採集20→實付茅屋1階→採集補31→實付2階，材料消耗／外環／解鎖清單可見。1280×720、844×390、800×360 CSS iframe（DPR約1）；短式內捲至錢莊、展開／詳情／收起、寬式恢復及固定關閉返回通過。console warn/error query空。證據與命令日誌：artifacts/uix-r4-feedback/，web-final.jpg／catalog-final.jpg、web-844.jpg、web-800.jpg。沒有新Web重載／IndexedDB故障／FPS數字，不重做已過保存／效能與暫緩冷啟動。

下一步：先收本輪視覺密度回饋；大型UIX-R5另用New Chat界定。實機／高DPR、原C/D與人類節奏缺口保持原狀。

驗收分頁已關閉、viewport override reset，48219服務以Ctrl+C主動停止（exit1為正常中止），隔離origin保留茅屋2階。
