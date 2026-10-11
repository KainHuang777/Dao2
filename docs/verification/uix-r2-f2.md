# UIX-R2-F2：BUFF核對、資源圖示與固定Dock

2026-10-11，IN_PROGRESS；來源、CLI及原生渲染已交付，Web互動與使用者比例接受待驗。

BUFF功能沒有移除。沒有生效增益／可用提醒時不顯示；有狀態時在天時下方顯示44px圖字，hover名稱／效果／剩餘時間，點BUFF開原生詳情。短橫式開建築全抽屜沿R4-F2暫收整個HUD，返回洞府恢復。此輪未改BUFF規則或其顯示政策。

修改 src/presentation/building_catalog.gd：數量與完整資源列前加24px既有ResourceArt手繪物品，忽略輸入；尚無圖的共用貨幣／獸魂用名稱字印。修改 abode_hud_controller.gd：移除開建築清單時Dock靠右分支，洞府／經營／修行／遊歷沿相同左下邊距。沿既有圖示來源與授權，沒有新圖形資產。新增 tools/uix_r2f2_preview.gd 與擴充 tests/uix_r2_hud_runner.gd。

命令與結果：固定 tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version 為4.7.2.stable.official.ed1daf0bf，exit0。APPDATA隔離於build/uix-r2-f2-user；--headless --path . --script res://tests/<runner>_runner.gd：uix_r2_hud **92 checks／0 failures／exit0**；buff_system、feature_navigation、m2d_responsive_ui均exit0。包含兩模式圖示／字印、三尺寸Dock切頁前後相同，以及有效BUFF在洞府／桌面建築／返回仍可見。未重跑全量62。初測test-only節點自動命名／Label型別假設錯誤，兩次以Ctrl+C停掉測試（exit1），修正後重跑通過。

--headless --path . --export-release Web build/web/index.html exit0；bundled Node tools/prepare_web_compression.mjs build/web exit0。git diff --check受影響來源／測試exit0。既有Font RID／CanvasItem／ObjectDB退出診斷保持，不稱日誌零錯誤。

--path . --script res://tools/uix_r2f2_preview.gd exit0：隔離新檔＋規則施加spirit_surge的原生展示，不是正常玩家取得BUFF的流程。1280×720、844×390、800×360各產洞府／建築六張PNG；工具關閉content scale僅作1:1邏輯幾何渲染，正式canvas_items／expand設定不變。確認有BUFF的桌面左側圖示與資源圖、建築抽屜與四Dock分離，短式Dock仍在左下。短式有效BUFF增加HUD高度，800×360資源列表可視空間有限；完整多資源與兩模式文字密度仍需實際Web回饋。

瀏覽器：bundled Python tools/island_preview_server.py --port48764 --normal-build --gzip服務啟動；沙箱Invoke-WebRequest socket拒絕，IAB localhost導航ERR_CONNECTION_TIMED_OUT；正常授權服務重啟後仍未取得頁面，error-page data URL亦阻擋清理API。服務以Ctrl+C停止，exit1為主動中止。未改防火牆／系統網路，未碰玩家origin。**不宣稱Web滑鼠、hover／popup、觸控、高DPR、保存、FPS已驗。**

證據：[log與六圖](artifacts/uix-r2-f2/)，[桌面洞府](artifacts/uix-r2-f2/home-1280x720.png)、[桌面建築](artifacts/uix-r2-f2/buildings-1280x720.png)、[844洞府](artifacts/uix-r2-f2/home-844x390.png)、[800建築](artifacts/uix-r2-f2/buildings-800x360.png)。

同步README、ROADMAP、docs07／19、development-status與updata英文checkpoint；既有dirty工作保留，沒有commit／push。下一New Chat先補Web三橫式：數量／完整ICON、實際採集、建築開關四Dock固定，以及生效BUFF的hover／點詳情／返回；再收多資源比例／人工回饋。觸控／高DPR與既有C/D待驗保持，不開大型下一任務。
