# M2-D-UI5：引導完成顯示與系統訊息閱讀

2026-10-01，IN_PROGRESS：實作、CLI 與 native 視覺檢查完成，使用者／真實 Web／手機驗收待補。

使用者指定兩項：完成新手引導後移除按鈕，待下個 Era 有目標時再出現；系統訊息預設開啟並增加可讀尺寸。

修行面板及營造簿以 Session view 的 `next_objective` 決定引導按鈕；null 時隱藏且清空文字，詳情返回、密度與模式切換不會重新顯示「營造引導已完成」。有效目標恢復時兩處恢復。目前 Domain 引導仍只有 Era 1，沒有新增其他 Era 里程碑或擅自產生假目標。

系統訊息每次啟動預設開啟，正文由 14 調為 17、行距 6，標題 17；開關／展開操作高度 44。桌面正常高度最高 220、展開最高 300，並依可用視口限制為高度 48%；寬度最高 540，管理模式限制於左 HUD 與右營造簿間的空間。短橫向空島將訊息放在 HUD 右側；短橫向管理模式暫收以保留營造空間，返空島恢復。使用者手動透過操作說明／引導重新開啟時可作浮層顯示，明確收起則保留本次執行的關閉選擇。直向沿用旋轉提示。初始化時將當前引導加入訊息，不顯示空白框。未變更存檔或遊戲收益。

修改檔案：`src/presentation/abode_hud_controller.gd`、`src/presentation/building_catalog.gd`、`src/abode/living_abode.gd`、`tests/m2d_responsive_ui_runner.gd`、`tools/ui_material_preview.gd`。沒有新增美術素材。

命令（引擎為現有 Godot 4.7.2 console）：

- `--headless --path . --script tests/m2d_responsive_ui_runner.gd --quit-after 600`：PASS、exit 0。追加真实里程碑完成／有效目標恢復、完成後詳情與密度切換、預設訊息、尺寸與不遮 HUD、手動收起保持測試。初次編譯遇動態節點布林推導錯誤；停止該程序並明確宣告 bool 後通過。
- `tools/run_all_runners.ps1`：33/33 PASS、exit 0（`artifacts/ui-guidance/runners.log`）；其他執行緒既有新增 Runner 依實際清單保留。
- `--headless --path . --script tests/abode_presentation_parity_runner.gd --quit-after 600`：PASS、exit 0（`artifacts/ui-guidance/parity.log`）。
- `--path . --script tools/ui_material_preview.gd --quit-after 600 -- --guidance-hud`：exit 0，四張 native Compatibility 圖（`artifacts/ui-guidance/`）。只在隔離 preview Session 推進里程碑，沒有改玩家存檔。桌面營造完成後兩處按鈕消失、訊息與營造區分開，短橫向字級與閱讀區已檢查。
- `--headless --path . --export-release Web build/web/index.html`：exit 0（`artifacts/ui-guidance/export.log`）；既有 4178 HTTP 200。

未通過／待補：真實瀏覽器操作、DPR 與實體手機、使用者訊息尺寸驗收。Font RID／CanvasItem／ObjectDB 退出資源警告仍保留。規則測試與 HTTP 200 不能替代實際滑鼠／觸控證據。

下一步：`http://127.0.0.1:4178/index.html?ui=messages-20261001` 驗收完成引導後畫面、系統訊息閱讀及手動收起／重新開啟；先處理本輪回饋，不自動展開下一個大型功能。
