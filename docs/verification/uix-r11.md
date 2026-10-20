# UIX-R11-DECISIONS：界域法令

2026-10-18 美術接受：使用者核定 R6～R11 現版美術全數接受。本頁人界／靈界四項決策既有技術、原生及桌面Web驗收範圍標 DONE；其餘10項不可達界域仍只列清單。下方待接受聲明為歷史；裝置項延期，未重跑測試或修改遊戲。

日期：2026-10-18。**IN_PROGRESS：實作／CLI／原生及桌面Web驗收交付，美術待使用者接受。** 本輪使用者「R11 天道決策」授權開工，覆蓋R10交接的等待核定限制。相依R10已接受；R8／R9美術狀態保持。

## 交付

- 正式可達人界／靈界四項決策各一張內建ImageGen透明手繪物件：編纂道藏、疏通靈脈、引渡天青靈潮、仙池靈露催熟。原圖與逐字提示詞、生成路徑見 [artifacts/uix-r11](artifacts/uix-r11/)，正式圖與manifest在 `assets/ui/decisions-painted/`。全alpha輪廓縮入480px畫布、448px內容／16px邊界；無文字／按鈕烘焙。其餘10項不可達界域決策只列manifest清單，沒有生成整包九界美術。原創AI生成，未借第三方參考圖、不宣稱第三方商用授權。
- 新增 `realm_decision_view.gd`，由原 `system_actions_panel.gd` decisions mode承載；技能／靈獸mode保持。1120px工作區，內容寬1000起雙欄，其餘單欄；固定當前界域、卡片內捲、112px／短式80px圖印、24px成本物品圖與持有／需求、至少80×44施行。名稱TIP提供敘述、效果TIP提供BUFF效果及時長；資格、缺料、冷卻、就緒和已施行次數明示。操作對齊卡片底部，長卡捲到底可達；倒數／資源就地更新，不重建按鈕或改RNG。
- 沿共用紙面／黑體／CloseSeal／正式與細卷軸安全邊界。頁內保存失敗及只保存重試沿既有路由；成功回饋顯示正式命令log_text。技能與靈獸不用此頁樣式。
- 發現原決策資源 `herb`／`lingqi` 未對應正式靈草／靈力。`RealmDecisionSystem.resource_key()` 按活躍經濟映射至 `spirit_grass_low`／`lingli`，成本及收益共用；純舊ID fixture仍有效。屬v2接線修復，數量／成本／冷卻／BUFF不變；未合併歷史孤立欄位，不宣稱全量舊檔遷移。CommandProcessor補目前界域驗證，阻止提交其他界域payload繞過頁面。保存schema與規則數值未變，重試不重送施行。

## 檔案與環境

來源：`src/presentation/realm_decision_view.gd`、`system_actions_panel.gd`、`feature_navigation.gd`、`src/simulation/realm_decision_system.gd`、`command_processor.gd`。工具／測試：`tests/uix_r11_decisions_ui_runner.gd`、`tools/uix_r11_assets.py`、`uix_r11_preview.gd`、`uix_r11_server.py`、固定Runner入口；驗收fixture為 `src/verification/uix_r11_acceptance.gd/.tscn`、project／export presets。保留Godot生成.uid；既有OFL字型子集及manifest重建，原字型未改。

Windows、Godot `4.7.2.stable.official.ed1daf0bf`、Compatibility／單執行緒Web。APPDATA只設於 `build/uix-r11-*`；CLI資料用獨立user://目錄，瀏覽器origin48830／48831與正常玩家origin隔離，未覆寫玩家進度。保留既有SKS-P1與所有其他dirty成果，未commit／push。

## 命令與結果

引擎：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`。以下皆已實跑，不以命令已發出代替成功。

- `--version`：上述4.7.2版本；`--headless --path . --editor --import`：exit0。
- `python tools/uix_r11_assets.py`：四原圖alpha／逐字提示詞／runtime及10項延期清單PASS；[素材總覽](artifacts/uix-r11/art-contact-sheet.jpg)。
- `--headless --path . --script res://tests/uix_r11_decisions_ui_runner.gd`：最終 **63 checks、failed=false、exit0**（`final2-uix_r11_decisions_ui_runner.log`）。涵蓋兩界四圖、缺料、30次refresh保留命中／state、實扣50金錢30木、修煉／BUFF、冷卻與到期、切界卡片替換、跨界payload拒絕、Era不足、正式靈力／靈草／靈晶收益、拒寫／拒寫重試／恢復／fresh disk load一次、長標題30位大數及三尺寸末項44px／內捲／卷軸安全／返回、技能／靈獸mode。
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1`：**74／74、exit0**，`all-runners.log`。此全量過程首項為當時62項R11；之後單頁精簡成本圖／次數文字及TIP修訂另由最終63項與五項相關回歸覆蓋，不宣稱74項在最後所有小改後再跑一次。五相關為R11、M5B、feature_navigation、R8 skills UI、responsive，皆exit0（`final-*.log`）；最後重跑R11為63項。後續只加驗收fixture的靈界／長文選擇，未再改正式玩法。
- `--path . --script res://tools/uix_r11_preview.gd`：exit0，三尺寸1280×720／844×390／800×360各七態，**21 PNG**；人界／靈界、缺料、Era不足、冷卻、保存失敗、長文大數。檢視寬式、短式、長卡及保存提示；最終log `native-final2.log`。
- `python tools/subset_game_fonts.py` 與 `--check`：exit0，保留OFL／字重軸。新增fixture後另重建；最終再check。
- `--headless --path . --export-release R11Acceptance build/r11-acceptance/index.html` 與 `Web build/web/index.html`：exit0；各執行 `node tools/prepare_web_compression.mjs <dir>`，壓縮及BGM companions exit0。最終為 `*-delivery.log`。

最終驗收PCK SHA256：`3BF1797770013AACAE0B956E1EBF53B8E4EA7C27D80E17708A37D2A2711ADCC3`。
最終一般Web PCK SHA256：`0F296277DE78DC6BA71604B73753261B2FBA840595CCE3ED0DA0B683151C91A0`。

初輪尚未匯入圖印時六項art失敗；匯入後長卡置中動作造成末項不可見，改卡底對齊後通過。早期Web發現次數字串重複，刪除重複append並加一次呈現斷言；修正後重匯出與重載核對。既有Font RID／CanvasItem／ObjectDB／resources退出診斷，以及全量預期的損壞JSON負面資料診斷保留，不能稱日誌零錯誤。

## 桌面Web證據

`python tools/uix_r11_server.py --port 48830/48831`，僅綁127.0.0.1。初次沙箱服務ERR_CONNECTION_TIMED_OUT；停止自有服務、改主機層啟動後新分頁連通，未改防火牆。舊錯誤分頁再導航被工具URL policy攔住，另開新分頁恢復。驗收fixture初始化Era2／1000資源，不代表自然前期流程；瀏覽器為IAB、CSS viewport，非實機。

- 48830，1280×720真實滑鼠施行道藏：1000→950金錢、1000→970木，顯示正式效果與冷卻；重載保持已施行1次。844×390內捲到疏通靈脈並實按，950→910金錢與正式收益log；800×360末項動作可達、返回洞府與遊歷重開通過。證據 `web-human-executed.png`（早版重複字串歷史）、`web-reloaded-one-execution.png`（已修正）、`web-last-844.png`、`web-last-800.png`。
- 48831，首次帶拒寫啟動被既有讀取／離線保護擋住，恢復後重新載入再測。正常畫面開拒寫→實按道藏→全畫面保存保護→仍拒寫時重試→恢復儲存再重試，頁內顯示已恢復、950金錢／970木、施行1次；重載保持1次，無重扣。證據 `web-write-denied.png`／`web-save-recovered.png`／`web-fault-reloaded.png`。snapshot精確相等由CLI另證，未把Web畫面當作完整存檔位元組比較。
- 最終fixture `?r11case=spirit` 以正式Session切界後開同一頁（不是正式切界入口的滑鼠證據）。寬式兩靈界卡、910→810實付靈潮、正式效果／300s／1次通過，見 `web-spirit-1280.png`／`web-spirit-executed.png`。四項命令精確收益由63項CLI另證。長文案例 `?r11case=long` 僅改View、不點虛構大數動作；三尺寸內捲／末項及旋轉恢復見同資料夾 `web-long-*.png` 與 `web-portrait-*.png`。

## 收結邊界

本頁等待使用者美術接受，**不標完整DONE**。觸控／實體裝置依既定政策延期、非當前阻擋；本輪不重跑既有FPS或暫緩冷啟動門檻。R8／R9與技能既有交付不因R11被覆寫。下一New Chat先收R11圖印／排版回饋，後續內容按使用者與既有docs21技能清單核定；本輪不展開下一大型任務。英文checkpoint置於updata頂部。

2026-10-18收尾：16檔嚴格UTF-8、四資產來源／提示詞／hash、10項延期清單及驗收連結檢查PASS；字型最終check與本輪tracked檔案git diff --check exit0。長文頁warn/error查詢空。三尺寸長文、桌面直式遮罩與橫式恢復截圖已保存；首次開長文同origin仍有遊戲分頁，觸發既有單一存檔鎖，關閉原分頁再按重新載入後成功，未繞過鎖。正常驗收分頁關閉、viewport覆寫reset，自有48830／48831服務Ctrl+C停止（主動exit1）；未停止其他程序。
