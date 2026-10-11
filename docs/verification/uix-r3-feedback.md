# UIX-R3-F1 — 卷首分頁與未開放排序

2026-10-11 有界修訂 DONE；人工美術、實體觸控與高 DPR 保持待驗。當次使用者要求覆蓋 R3 原青玉方塊／底線與解鎖 tooltip 契約。

GameTab 改明體墨字章目，選中朱砂文字與小菱形印記；紙底由父卷軸提供，沒有矩形底色或底線。44px 命中與容器／橫向內捲保持。可用項目先排，未開放項目灰化加「未開」排後，各組內保留 canonical 順序；遠期隱藏保持。解鎖時重排現有按鈕，不重建連線或更動記憶頁；全部分頁 tooltip 清空。預告仍能點入原頁閱讀條件，核心禁用與成本不變。

修改：src/presentation/components/game_tab.gd、src/presentation/feature_navigation.gd、tests/feature_navigation_runner.gd；README、ROADMAP、docs07/12/18、ai-handoff、development-status、updata 及本頁。保留既有 dirty 成果，無規則／存檔變更，無新圖形素材或生成資產。

命令與結果：

- tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version：4.7.2.stable.official.ed1daf0bf。
- 隔離 APPDATA=build/uix-r3f1-*；--headless --path . --script res://tests/<name>_runner.gd：feature_navigation、uix_r1_components（74 checks）、m2d_responsive_ui、ui_material_states 四項 exit0。增加順序、解鎖即時更新、無 tooltip 與無方塊樣式的斷言；未重跑全量。既有 Font／CanvasItem／ObjectDB 退出診斷保留，不宣稱日誌零錯誤。
- --headless --path . --export-release Web build/web/index.html：exit0。
- bundled Node tools/prepare_web_compression.mjs build/web：exit0，一般 Web 已同步。
- bundled Python tools/island_preview_server.py --port 48221 --normal-build --gzip：隔離服務成功。首次未啟動及沙箱服務 browser 連線失敗，改為正常授權的隔離服務後成功；初始 Python launcher 有 real location 診斷，改用 bundled Python。測試服務以 Ctrl+C 結束（exit1 為主動中止）。

真實 IAB 同一新 origin，未 Seed、未觸碰玩家 origin：1280×720、844×390、800×360 CSS iframe。煉丹→成就→技能未開實際滑鼠切頁、選中印記移動、未開標示及排序、44px 固定關閉返回通過。console warn/error query 空。viewport override 已 reset，驗收 tab 關閉。兩次初始失敗建立的錯誤頁為工具臨時頁。

證據：[桌面](artifacts/uix-r3-feedback/web-1280.png)、[844](artifacts/uix-r3-feedback/web-844.png)、[800](artifacts/uix-r3-feedback/web-800.png)、[分頁近照](artifacts/uix-r3-feedback/chapters.png)，命令日誌同目錄。未新增 FPS、保存重載、IndexedDB 或實體裝置證據。

下一步：收本輪分頁美術回饋；大型 UIX-R5 使用 New Chat 另定範圍。完整 C/D、人工节奏、實體觸控與高 DPR 原缺口不提升。
