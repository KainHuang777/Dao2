# UIX-R7-F5 簡單驗收與結案

日期：2026-10-18。狀態：**DONE（本次使用者核定的簡單桌面／Web驗收範圍）**。

使用者指令：「進行簡單的驗收 效能不需要過度要求」。本次以正式功能、實際演出與操作可回應作放行，取代原F5-D強制60秒＋5分鐘操作／重開效能矩陣。沒有取得新的FPS數據，不宣稱嚴格效能測試通過。

## 本輪結果

- Godot版本：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`，4.7.2.stable.official.ed1daf0bf，exit0。
- 隔離APPDATA=`build/f5-simple-user`；`--headless --path . --script res://tests/reincarnation_motion_runner.gd`：exit0、failures=0。實際材質載入、轉盤層序、隱藏停算、低特效靜止、命燈、三尺寸、skip／結束清理與低特效自然結束通過。
- 同引擎執行`tests/uix_r7_reincarnation_ui_runner.gd`：exit0，75 checks failed=false，含確認取消、保存拒寫重試、三尺寸。既有退出資源診斷保留，不稱原生日誌零警告。
- 正式`build/web`以`python tools/island_preview_server.py --port 48921 --normal-build --fixture uix-r7-f5-simple-fixture.json`服務，新隔離origin、IAB桌面滑鼠實測。
- 可見正式頁之旋轉盤面、固定蓮花／外框、雲霧與豎字；實際點入定轉世→確認→演出→跳過位置→結算→入世→重開輪迴，演出遮罩／圖層已清除。Web實際skip點擊與結算可達；確定的即時skip行為另由CLI runner覆蓋，不以截圖推算精確點擊時刻。
- 測試從第2世、道心50轉至第3世、道心65（收益+15）；重新載入遊戲後第3世／65保留，無重複發放。
- 低特效透過正式設定切換，畫面保持靜態；800×360與844×390瀏覽器iframe實際版面可見、正文與控制未被裝飾遮住。大尺寸為IAB預設1280×650遊戲區（整個瀏覽器1280×720，啟動列佔70）；1280×720原生幾何另由CLI覆蓋，勿混稱本輪Web遊戲區為1280×720。
- 簡單效能觀察：多次開關／結算／尺寸切換均可回應，未遇明顯停住；不是持續FPS或記憶體測試。`tab.dev.logs`查詢warn／error為空。

## 證據與限制

證據目錄：[uix-r7-f5-simple](artifacts/uix-r7-f5-simple/)。包含motion.log、ui.log、fixture.log、fixture-revealed.log、browser-errors.json及web-page／motion／result／low／800／844／reload PNG。

測試fixture由`tools/f5_simple_fixture.gd`讀既有命令產生的Era2資料，以正式SaveCodec重新封裝；明示加入往生蓮臺1、道心50及輪迴次數1以揭露入口。首次候選只加蓮臺而入口仍隱藏，後續獨立48921使用修訂fixture；前一origin未覆寫。此為演出驗收fixture，不是自然新手進度。測試進度和玩家origin分離。

先前AGY的60秒／300秒數據保留為背景運行證據；其截圖停離線摘要，腳本沒有輪迴開關／重開操作，故不能把該PASS外推為輪迴效果負載或記憶體驗收。本次遵使用者簡化驗收，不再以該缺口阻擋F5結案。

原始沙箱服務48918的IAB連線逾時；正常升權啟動後48919／48920／48921可連線。所有測試只使用本專案工具與新隔離origin，不調整防火牆或瀏覽器安全設定。

## 最終狀態

F5-PLAN、F5-A（素材交付）、F5-B（使用者最終組合視覺接受，含F1／F2修訂）、F5-C（正式接入）、F5-D（依本次簡單驗收範圍）均DONE。A的獨立靜態審查不另追認；其素材工作隨最終B組合接受收結。舊TODO／待接受段落保留為當時歷史，由本記錄覆蓋。

本輪僅新增隔離fixture工具／證據及更新文件，沒有修改正式遊戲、重新匯出、commit或push。下一步由使用者選下一內容任務；F5不再反覆壓測。依Context Guard停止本階段，大型新任務使用New Chat。
收尾：本輪建立的瀏覽器分頁已關閉；48918／48919／48920／48921測試服務以Ctrl+C停止（主動終止，不作測試失敗）。原有使用者分頁／服務未操作。git diff --check exit0（僅CRLF提示）。
