2026-10-17 最新結案：使用者明確回覆「R7 美術接受」。UIX-R7-REINCARNATION於桌面／Web有界範圍標記DONE；最終以F3無空白槽版本為準，F1／F2技術證據沿用，下方待接受／下一輪回饋記載保留為歷史。觸控／實機延期，非當前阻擋。本次僅文件／既有log與hash核對，未重跑遊戲或改玩家資料；R8尚未開工。

# UIX-R7-F3 · 移除空白壽元槽

2026-10-17。有界修訂 DONE；R7整體仍待最終美術接受，不開R8。

使用者指出的空白框是僅壽盡時出現、固定為0的ProgressBar。移除該元件及layout/refresh參照，以現有熄滅命燈與壽盡文字表達；收益、轉世確認取消、自動提醒保持。無新增美術、規則、保存schema或玩家資料變更。

修改：src/presentation/reincarnation_panel.gd；tests/uix_r7_reincarnation_ui_runner.gd既有spent-state斷言去除已刪成員；新增tools/uix_r7f3_preview.gd（沿F2隔離預覽）；README、ROADMAP、handoff、status、19、20與updata追加現況。

## 驗證

- 本機Godot --version：4.7.2.stable.official.ed1daf0bf，exit0。
- --headless --path . --script res://tests/uix_r7_reincarnation_ui_runner.gd：75 checks，failed=false，exit0；涵蓋確認取消、天賦保存失敗重試、自動提醒與三橫式安全邊界。未新增僅檢查刪除程式的測試。
- --path . --script res://tools/uix_r7f3_preview.gd：exit0，1280×720、844×390、800×360共24張原生圖；逐一檢視三尺寸reincarnate圖，無空槽、主資訊與按鈕可見。預覽使用獨立user路徑；CLI/preview APPDATA分別在build/uix-r7f3-cli-appdata與build/uix-r7f3-preview-appdata。
- --headless --path . --export-release R7Acceptance build/r7-acceptance/index.html及Web build/web/index.html：各exit0。
- node tools/prepare_web_compression.mjs build/r7-acceptance與build/web：各exit0，含音樂companions。
- git diff --check及本輪文字檔嚴格UTF-8回讀：通過；rg確認src/tests無_life_gauge殘留。
- 未跑全量Runner；既有Font RID、CanvasItem、ObjectDB與resource退出診斷仍在，不宣稱零錯誤。

## 桌面瀏覽器

CUA IAB，獨立127.0.0.1:48774/index.html?r7f1=1。fixture僅測試origin，沿正式Session時間觸發壽盡自動開頁。1280×720確認空槽消失、滑鼠主操作進確認、取消恢復；844×390與800×360完成resize繪製後核對命燈／收益／主操作。web-1280.jpg、web-844.jpg、web-800.jpg為原始瀏覽器截圖，console warn/error查詢空。尺寸切換第一個frame尚未完成重繪，後續穩定畫面才作證據。未將本輪小修宣稱完整自然流程或保存矩陣重驗。

初次在服務啟動前開頁為ERR_CONNECTION_REFUSED；沙箱服務啟動後逾時。停止同一服務並用host權限僅綁127.0.0.1重啟成功；舊錯誤分頁的data URL遭瀏覽器政策拒絕存取，未繞過，改用正常新分頁載入已啟動URL成功。完成後停止本輪服務、關閉成功分頁並還原viewport。

一般Web PCK SHA256：241e5848d0717f4172213b5863d07a45fe88b8b77ae0238bc8029e9ddc9f8532。
R7Acceptance PCK SHA256：baacb0de7be4c638439908740cf26a61f51f894e9d3c658b772e60f0ea0d0404。
日誌與圖：artifacts/uix-r7-f3/。未commit/push。下一New Chat收R7最終視覺回饋／接受。
