# UIX-R10-FORTUNE：天機奇遇

日期：2026-10-17；2026-10-18 收結。**DONE（桌面／Web有界；使用者美術接受）。** 使用者當輪「R10」授權覆蓋R9交接的不開R10限制；不代表R8／R9美術已接受。下一大型任務仍為R11，再RES1-E-SKILLS-PLAN；本輪停在R10。

## 2026-10-18 美術接受／收結

使用者明確回覆「R10 美術接受」。本頁六張題材圖、圖文與短式排版、選項／代價／動作呈現獲接受，結合下列既有技術與桌面Web證據，UIX-R10-FORTUNE 在桌面／Web有界範圍標 DONE。下方歷史「美術待接受／不標DONE」聲明保留日期，由本段覆蓋。

本輪 PowerShell 唯讀核對 final-uix_r10_fortune_ui_runner.log 的「58 checks failed=false」、相關log與既有R10Acceptance PCK SHA256，後者仍為 7451E64DC85A5FE9D2B7CEAAD1B4A55130103CAF6A3759D5E8913EE82FC23339。既有退出診斷保留。文件採嚴格UTF-8回讀與 git diff --check 驗證；未重跑Godot／Web，未重新匯出，不把歷史72項結果當成較新SKS-P1全專案重測。

修改 README.md、ROADMAP.md、docs/ai-handoff.md、docs/development-status.md、docs/20-feature-interface-art-plan.md、本頁及updata.txt；保留程式、資產、匯出、玩家進度及其他既有dirty成果，未commit/push。裝置項依既定政策延期，非當前阻擋。R8／R9美術不由本次核定；下一候選UIX-R11天道決策，待New Chat由使用者核定開工，本輪停止。

## 交付

- 內建ImageGen各自生成六張透明手繪圖：遺跡、靈泉、訪客、靈獸、異象與空閒感應；前五組完整映射26個既有事件，不新增事件、不承諾隱藏掉落。題材圖為分組意象，不代表每位訪客的精確肖像。原圖、逐字提示詞及生成紀錄在[artifacts/uix-r10](artifacts/uix-r10/)，正式圖與manifest在`assets/ui/fortune-painted/`。保留生成alpha，完整輪廓縮入480px圖，16px邊界；非分割大圖或以假背景代替透明。來源為原創AI生成，不宣稱取得第三方商用授權。
- `fortune_modal.gd`沿共用黑體、紙底深墨、CloseSeal、正式／細卷軸與內容安全內距。1120px工作區；面板寬至少950且非短式時256px題圖與圖文分欄，其餘112px／短式64px題圖。敘事、契合與選項內捲；頁首及狀態／保存回饋固定。短式採canonical固定導覽關閉鈕。各選項獨立文案、可知代價及72×44選擇動作；成本復用物品圖、短數字，精確數字／資源名稱留TIP。
- 選項只在事件內容變更時重建；冷卻／庫存刷新保留按鈕實體、捲動與RNG。單次提交鎖避免同頁重送；正式Session仍驗證。結算文字不被下一輪refresh蓋掉。修復長文初次排版的暫態最小高度撐出面板，容器穩定後重新配適。
- `abode_modal_manager.gd`接推演／結算保存結果與只保存重試；`living_abode.gd`同步正常／背景恢復。Web拒寫仍沿既有全畫面保護，恢復後頁內清除失敗且不重送命令。
- 發現原機緣資料`herb`／`lingqi`未對應正式資源，持有正式靈草仍付不了款，獎勵可能成為不顯示的欄位。`FortuneSystem.resource_key()`優先選當前經濟的`spirit_grass_low`／`lingli`，UI與核心共用；純舊ID隔離測試仍可運作。數量不變，屬v2接線修復；未做歷史孤立資源合併或存檔schema遷移，不宣稱全量舊檔相容。

## 檔案

來源：`src/presentation/fortune_modal.gd`、`feature_navigation.gd`、`abode_modal_manager.gd`、`src/abode/living_abode.gd`、`src/simulation/fortune_system.gd`。保存版本／經濟資料／事件內容未修改。

測試／工具：`tests/uix_r10_fortune_ui_runner.gd`、`tests/m3b_fortune_ui_runner.gd`（舊整顆按鈕改讀分離操作）、`tools/run_all_runners.ps1`（納入專項與可選StartAt分段續跑）、`tools/uix_r10_assets.py`、`tools/uix_r10_preview.gd`、`tools/uix_r10_server.py`、`src/verification/uix_r10_acceptance.gd/.tscn`、project／export presets。Godot產生的.uid保留。既有OFL字型子集及manifest重建；原始字型不改。

## 命令與結果

引擎均為`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，`--version`為`4.7.2.stable.official.ed1daf0bf`。隔離APPDATA位於`build/uix-r10-*`，玩家資料未碰觸。

- `python tools/uix_r10_assets.py`：六張alpha／來源／runtime與26唯一映射PASS；[素材總覽](artifacts/uix-r10/art-contact-sheet.jpg)。
- `--headless --path . --editor --import`：最終exit0。`python tools/subset_game_fonts.py`重建後`--check`exit0；初次coverage/hash檢查失敗保留。
- `--headless --path . --script res://tests/uix_r10_fortune_ui_runner.gd`：最終**58 checks、failed=false、exit0**。涵蓋全部ID映射、冷卻／就緒、真實路由推演、待選fresh disk load、30次refresh保留按鈕／state/RNG、缺料後補料、實扣20靈草、單次結算、拒寫／失敗重試／恢復／fresh disk load及三尺寸長文大數／最後操作／44px／底軸安全。
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1`：固定清單共**72項分段exit0**。首20項通過，執行第21項`res1_ui1b`時撞上中途成本字串改動的型別推斷編譯失敗；主動中止，修正後`-StartAt tests/res1_ui1b_runner.gd`續跑剩52項皆exit0。最終再跑R10、機緣UI、導覽、響應式四項皆exit0。兩段log保留，不能將中間失敗稱為通過。
- `--path . --script res://tools/uix_r10_preview.gd`：最終exit0，1280×720／844×390／800×360各7態，共21張PNG；就緒、冷卻、待選、真實缺料、結果、保存失敗與長文。已檢視寬式／短式／長文及代價圖像。
- `--headless --path . --export-release R10Acceptance build/r10-acceptance/index.html`、同命令`Web build/web/index.html`：最終exit0；各接`node tools/prepare_web_compression.mjs <build-dir>`，壓縮與BGM companions皆exit0。最後只調整驗收fixture為Era2／1800秒冷卻，另重匯出與壓縮R10Acceptance；一般Web可玩來源已是最終版。

一般Web PCK SHA256：`EB5508F1C036C6FF57DDD7CCAE5115C0D19BF25E52E1DD1BEBCA2BB7211BAF1B`。
最終R10Acceptance PCK SHA256：`7451E64DC85A5FE9D2B7CEAAD1B4A55130103CAF6A3759D5E8913EE82FC23339`。

最終相關log以`final-*.log`、`r10-final-pass.log`、`native-fixture-final.log`、`export-*-final.log`、`compress-*-final.log`為準。早期錯用Amount API／推斷型別、測試舊資源ID／不存在字串API、長文暫態高度失敗均保留；兩個掛住的隔離runner以Ctrl+C終止exit1，修正後重跑。Font RID／CanvasItem／ObjectDB／resources退出診斷及全量負面資料預期錯誤仍在，不能宣稱零錯誤日誌。

## 桌面Web

`python tools/uix_r10_server.py --port 48820/48821/48822`只綁127.0.0.1。初次沙箱服務IAB `ERR_CONNECTION_TIMED_OUT`，停止自有服務後主機層重啟成功；不修改防火牆。48820為早期樣式驗證，**最終證據用48821／48822**。隔離fixture為Era2、靈草1000、待選游方丹師與1800秒冷卻，不是自然前期遊玩證據。

48821：1280實際付費選項；拒寫前顯示靈草1000／20；拒寫後全畫面保護、拒寫重試仍保持、恢復儲存後重試成功，頁內顯示保存已恢復且結算1次／延壽丹。重載保持1次及冷卻，不重發獎勵；精確980及快照相等由CLI獨立證明，沒有把Web結果文字當作精確庫存證據。三橫式捲到最後選項、洞府返回／遊歷重開保持待選，滑鼠操作通過。

最終截圖：[寬版](artifacts/uix-r10/web-pending-1280.png)、[800最後選項](artifacts/uix-r10/web-last-800.png)、[844最後選項](artifacts/uix-r10/web-last-844.png)、[拒寫](artifacts/uix-r10/web-write-denied.png)、[保存恢復](artifacts/uix-r10/web-save-recovered.png)、[重載1次](artifacts/uix-r10/web-reloaded-one-claim.png)。

48822待選重載：原游方丹師、三選項、靈草1000／20及0次結算保留，[重載截圖](artifacts/uix-r10/web-pending-reloaded.png)。2026-10-18額度恢復後續驗同一最終PCK（hash未變），完成View-only長敘事及30位數庫存的1280／844／800內捲／末項操作可達與成本界內呈現；未按View-only選項，不宣稱它是實際庫存或自然遊玩。證據為本資料夾`web-long-*.png`。瀏覽器尺寸為CSS viewport；原生PNG另提供精確尺寸，不把CSS當作實機測試。

2026-10-18收尾：九檔嚴格UTF-8／六圖／26映射核對通過。初次`git diff --check` exit2只因本輪export_presets.cfg尾端多一空行，移除後exit0，未改匯出設定值。當前工作區已有較新的SKS-P1成果；本輪只補R10既有匯出驗收與文件，沒有覆寫後續來源，也沒有把10/17的72項結果宣稱為10/18全專案重測。R10保留美術待接受。

## 邊界與下一步

2026-10-18最終清理：桌面360×640旋轉提示及回1280橫式恢復已確認（`web-portrait-overlay.png`／`web-landscape-restored.png`），不作實機證據；長文頁warn/error查詢空。自有正常驗收分頁已關閉、viewport覆寫已reset，自有48821／48822服務以Ctrl+C停止（主動exit1）。早期連線失敗的data-URL錯誤頁未重新操作。英文checkpoint與status已補，後續SKS-P1成果保持。

美術仍待使用者接受，完整R10不標DONE；觸控／實體裝置依使用者指令延期，非當前阻擋，不安排為下一任務。未重跑已接受的瀏覽器FPS／暫緩冷啟動門檻。保留全部先前dirty成果，未commit/push。停止本階段、寫英文checkpoint於updata頂部；New Chat先接R10回饋，再由使用者指示R11，不在本輪展開下一大型任務。
