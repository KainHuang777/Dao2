# UI-SHELL-2：完整功能頁共用殼遷移

2026-10-22。使用者指定 `UI-SHELL-2`，承接 SHELL-0／1，依 docs28 §5 遷移其餘十二頁。**DONE（桌面原生／Web有界）**。

## 交付與資料責任

- 所有 canonical route 由 UiShellController 統一套用 HUD、資源、訊息、工具與相機政策。FeatureNavigation 與 AbodeHudController 的舊共用顯示覆寫分支已移除；建築亦使用完整工作區，沒有狹小且不可操作的世界餘幅。
- 洞府完整 HUD；十三個功能頁精簡 HUD，晉階／突破與 BUFF 沿原控制及回呼。寬式庫存工作頁並列資源欄；短式用情境入口／抽屜，卡內原成本與資格保持。
- 新增唯讀 UiShellResources：建築／煉丹沿現有物品庫存；空島、製造與運輸讀 Session View 的當地可用、預留、容量、在途及祖島付款資源，與全島總量分開；技能、靈獸、宗門、付費機緣、法令、輪迴天賦提供對應資源。宗門貢獻增加於 GameSession View，無規則或保存 schema 變更。成就、九界與轉世閱讀不自動展開庫存。
- 子分頁、選島與選航線後立即重算情境；暫收在同 route 子分頁及刷新間保留，跨 route 清除。洞府三態偏好不再被經營頁改寫。數字沿 Amount 顯示格式及共用資源名稱，沒有另算費用。
- 工具／閱讀關閉返回原合法頁；隱藏入口採既有 FeatureUnlocks 回退，畫面與狀態 route 一致。遮罩下的情境捷徑不修改背景草稿。轉世確認按 Escape 先取消，切頁亦取消，不付款；法令沿原直接提交契約，沒有另創不存在的確認。
- 製造設定／批數與運輸未保存草稿保留於原頁物件，開工具、跨頁及 resize 不重設。機緣暫收不重抽，返回時以新 View 刷新負擔能力。
- 小橫式縮減共用分頁留白；宗門回饋併固定頁首。製造／運輸縮減非互動圖與裝飾內距，運輸動作併卡片標題列；保留原字級、成本、來源、44px 動作及內容內捲。
- 小橫式技能將點數／短結果與原「藏經閣」捷徑併固定共用列，省去重複頁首；完整122px技能卡仍能一次閱讀，詳細回饋留同入口TIP，保存異常保持明示。
- 九界首世 hook 沿原生命週期納入演出／報告優先序，正常九界頁沿 canonical route。保存異常仍用共用固定異常列與原重試／保護，不重送收益命令。

## 驗證入口與隔離

使用既有 `Godot 4.7.2.stable.official.ed1daf0bf`、Compatibility、單執行緒 Web。所有命令以 `APPDATA=E:/WORK/Dao2/build/ui-shell-2-user` 隔離；不覆寫玩家進度。

```powershell
$env:APPDATA='E:/WORK/Dao2/build/ui-shell-2-user'
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/ui_shell_matrix_runner.gd
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/ui_shell_matrix_runner.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1
python tools/subset_game_fonts.py --check
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web build/web-ui-shell-2/index.html
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release UiShellMatrixAcceptance build/ui-shell-2-acceptance/index.html
node tools/prepare_web_compression.mjs build/web-ui-shell-2
node tools/prepare_web_compression.mjs build/ui-shell-2-acceptance
python tools/ui_shell_server.py --port 4394 --build build/ui-shell-2-acceptance
```

`UiShellMatrixAcceptance` 是顯式測試 feature，沿已存在的 UiShellAcceptance 場景。`src/verification/ui_shell_2_fixture.json` 來自既有 earned Era3 診斷資料；僅此 feature 載入並加上天賦／藏經閣等頁面測試前置。驗收場景停用自然線上推進，重載仍走正式保存／離線流程；不是自然進度證據。正常候選為 `build/web-ui-shell-2`，凍結 `build/web` 保持。

## 初輪失敗與修正

原始日誌保留在 `artifacts/ui-shell-2/`，不將命令已發出或只看 exit0 當完全通過。

1. 矩陣 Runner 初稿引用不存在的 CultivationRules 名稱及未宣告 Dictionary 型別，修正後執行。
2. SHELL-1 舊專項仍斷言技能頁未遷移，改驗全頁共用殼。
3. 初次驗收匯出目錄未建立而失敗；建目錄後重匯出成功。初次沙箱本機服務於瀏覽器連線逾時，改以正常授權啟動工作區隔離服務，未改防火牆或瀏覽器安全設定。
4. 小橫式法令／機緣、宗門、製造與運輸既有可讀高度／首卡完整性回歸逐項失敗；依上列減留白、固定回饋合列與裝飾圖縮減修正，保留字級與命中斷言。
5. 共用 HUD 實際 minimum height 大於初估，短式分頁位置曾重疊，矩陣直接檢出；改留足 HUD 範圍後再驗。
6. 舊響應式測試仍要求完整左 HUD／620px 右 rail，及旋轉提示下可操作的庫存三態；改驗新精簡 HUD／工作區／旋轉阻擋，資源偏好與捲動改在桌面橫式驗，原收益、扣款、成本、詳情與建築命中斷言保留。
7. 舊九界／輪迴元件測試曾直接開啟隱藏 route。九界手動頁明訂 Era3 preview fixture；輪迴新檔先驗 canonical 隱藏，再用明示元件 fixture 驗不合資格預覽，壽盡快捷入口與首世轉世仍走真實 route／命令。演出結束後亦須結束獨立的首世九界 hook，才期望世界輸入恢復。
8. 瀏覽器驗出天賦切頁的情境依賴下一刷新；加入原按鈕／選擇事件接線，即時更新。
9. 舊導航訊息測試仍假設閱讀擠窄清單，且開閱讀後直接導航；改驗遮罩不穿透、原清單不改寬、先結束閱讀再導航。直接改 fixture 的 Era 後先刷新正式 View，避免讀呈現快取。第一個無法退出的舊導航 Runner 因腳本錯誤由所屬 session Ctrl+C 停止，未停止其他 Godot 程序；CIM 診斷在沙箱不可存取，沒有改系統權限。
10. 技能舊完整首卡斷言檢出共用HUD擠壓後高度不足；以上列固定共用列接法保留122px卡。世界詳情 Escape 改為先返回列表，第二次才回洞府，對應測試亦更新。
11. 最後瀏覽器複核發現工作區殘留洞府目標紙面；在共用 reflow 分支明確收起，矩陣補117個全route／尺寸／偏好斷言，再跑原生1,709項及重匯出，最後瀏覽器圖已確認撤下。

既有 RID／ObjectDB 退出診斷、部分 anchored Control 初始尺寸警告、故障測試預期 JSON／拒寫診斷照實保留；不宣稱零日誌錯誤。沒有新的 FPS 或冷啟動數字。

## 最終結果

- **固定整輪85／85 Runner、exit0，SCRIPT ERROR 0**：[完整日誌](artifacts/ui-shell-2/full-runners-final.log)。包含共用殼整合90、政策263，以及法令、機緣、宗門、製造／運輸、技能、保存與規則回歸；初輪失敗與分段重跑日誌保留，不用分段數量拼成整輪結果。
- **最終原生1,709 checks／failures=[]／exit0**，三橫式十三頁共39圖：[原生日誌](artifacts/ui-shell-2/native-verified.log)。整輪開始後最後一項目標紙面修正另加117斷言，原生1,709項補驗；整輪第一個矩陣當時為1,592項，此界線明示，不回寫舊log。
- 最終字型 `--check` exit0；正常／隔離 Web export、compression 及四首BGM companions 均exit0。正常候選 PCK SHA256 `2749e648b43bef41…`，隔離候選 `ec58750379d69301…`；凍結 `build/web` 保持 `7e7e619dcaa28fb0…`。[20份來源／建置hash](artifacts/ui-shell-2/source-hashes.json)。
- 真實 IAB 桌面滑鼠驗1280×720、844×390、800×360 CSS尺寸、十三個分頁、天賦即時帶出道心、工具返回同天賦子頁、法令內捲可達末項操作、訊息遮罩不穿透、暫收與洞府偏好恢復。844×390透過既有Web縮放對應779×360 Godot邏輯尺寸；沒有把兩者混稱。[觀察](artifacts/ui-shell-2/browser-observations.json)。
- 真實研習0→1階後保存拒寫，Escape與仍拒寫重試均維持必要保護；恢復後回同技能頁1階，重載仍1階、未再研習。診斷點數200→恢復128→重載182包含焦點恢復／重載的正式離線補算，**不是72點費用或完全凍結時鐘證據**；精確扣款與只保存重試另由隔離CLI回歸驗證。[拒寫圖](artifacts/ui-shell-2/web-save-denied.png)、[恢復圖](artifacts/ui-shell-2/web-skills-recovered.png)、[重載圖](artifacts/ui-shell-2/web-skills-reload.png)。
- 真實航線未保存保留量17跨製造／運輸及三尺寸保留，頁面仍明示「已保存保留0／目標100」，沒有自動提交；來源／目的地庫存分開。`typeText("17")`初次只輸入首字，改逐鍵補7後視覺與diagnostic均為17，不把初次1當17。[844草稿圖](artifacts/ui-shell-2/web-draft-844.png)、[寬式來源／目的圖](artifacts/ui-shell-2/web-transport-wide.png)。製造設定、同pending機緣花費後成本刷新與確認取消另有矩陣／專項證據。
- 瀏覽器診斷保留三筆未標來源URL的 MutationObserver observe 錯誤，與前輪同型；不稱console零錯誤。[完整診斷](artifacts/ui-shell-2/browser-diagnostics.json)。必要保護時SceneTree暫停會停止harness診斷刷新，正常時亦可落後0.3秒；以畫面與命令結果為準。
- 十份測試再生且任務開始時乾淨的fixture已依HEAD bytes還原：[還原清單](artifacts/ui-shell-2/fixture-restore.json)。任務開始前dirty成果保留，新增UID保留。三個本輪服務均以各自session Ctrl+C停止（exit1為主動停止）；瀏覽器viewport已還原、驗收頁已關閉。初次逾時error頁的清理被瀏覽器data-URL政策拒絕，未繞過，留工具於回合結束清理。
- 結案41檔嚴格UTF-8、驗收14本地連結、20來源／建置hash核對、字型及每包四首BGM檢查通過，`git diff --check` exit0。移除本輪重生的兩份歷史JPEG誤名PNG之 `.import` sidecar，原圖不改。[結果摘要](artifacts/ui-shell-2/results.json)。

交付保持原正式規則、保存schema與玩家資料；沒有小傳、帳目、永久收據、敘事字型或美術接受完成聲稱。觸控／實機依既定政策延期，非當前阻擋。下一個大型任務請以New Chat接 `LEDGER-0 → ATM-LIFE-A/REPORT-1A`，由使用者指定，本輪停止。

## 圖片

[最終800技能頁（真實Web畫布裁切）](artifacts/ui-shell-2/web-final-skills-800.png)、[800運輸首卡](artifacts/ui-shell-2/web-transport-800.png)、[最終原生800技能](artifacts/ui-shell-2/skills-800x360.png)。各route另有1280×720／844×390／800×360原生圖；原生圖不冒充瀏覽器圖。
