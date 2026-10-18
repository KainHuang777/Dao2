2026-10-17 最新結案：使用者明確回覆「R7 美術接受」。UIX-R7-REINCARNATION於桌面／Web有界範圍標記DONE；最終以F3無空白槽版本為準，F1／F2技術證據沿用，下方待接受／下一輪回饋記載保留為歷史。觸控／實機延期，非當前阻擋。本次僅文件／既有log與hash核對，未重跑遊戲或改玩家資料；R8尚未開工。

# UIX-R7-F1 · 壽盡圖像化與主動輪迴提醒

2026-10-17。使用者截圖回饋：輪迴頁更像圖像式遊戲、適度減字、重要資訊揭露、按鈕置中；壽盡需要視覺表現並自動開頁。本輪實作／技術驗收交付，R7 最終美術仍待使用者接受，不開 R8。

## 交付與檔案

- `src/presentation/reincarnation_panel.gd`：熄滅命燈／殘煙獨立透明主視覺、耗盡壽元槽與暖灰朱砂狀態、道心／道證收益卡、精簡世次與資格。原輪迴盤保留給非壽盡狀態。主動作與確認／取消組置中。
- 貨幣併入固定分頁列；桌面主圖192px，短橫式72px並將收益放到命燈旁。完整傳承／重置改為44px按鈕展開，確認時自動展開；取消恢復概覽。全部維持容器與內容內捲，未縮小共用命中規範。成功的天賦保存收據不擠壓輪迴概覽，失敗與重試保留。
- `src/abode/living_abode.gd`：依正式Session View壽盡狀態延後開啟canonical輪迴路由，固定回轉世分頁。儲存暫停、離線報告、突破／輪迴／九界演出優先；之後再提醒。同一壽盡狀態關閉後不反覆搶頁；重新載入、下一世，以及延壽恢復後再次壽盡可重新提醒。只呈現，不自動轉世／扣款／發獎，不新增保存欄位。
- `src/verification/uix_r7_acceptance.gd`：僅獨立驗收版支援 `?r7f1=1`。首次空白測試origin準備壽盡前5秒並啟用真Session時間；之後不重複seed。不是自然新手流程證據。
- `assets/ui/reincarnation-painted/life_lamp_spent.png` 與 `manifest.json`：內建ImageGen原創；無第三方參考圖。原圖、完整提示詞在 `artifacts/uix-r7-f1/`；`tools/uix_r7f1_assets.py`只配適完整alpha邊界與16px留白，保留透明度。圖／文字／操作分層，不把概念圖當互動場景。
- `tests/uix_r7_reincarnation_ui_runner.gd`、`tools/uix_r7f1_preview.gd`及規範／交接文件同步。

## 命令與結果

引擎實測 `4.7.2.stable.official.ed1daf0bf`，Compatibility，未更新環境。所有測試／預覽APPDATA與user資料位於隔離的 `build/uix-r7f1-*`，未覆寫玩家進度。

| 工具／命令 | 結果 |
| --- | --- |
| Godot `--version`、`--headless --path . --import` | exit0 |
| bundled Python `tools/uix_r7f1_assets.py` | exit0；alpha 0–255、完整輪廓與manifest/hash |
| Godot `--headless --path . --script res://tests/uix_r7_reincarnation_ui_runner.gd` | 最終68 checks、failed=false、exit0；保存拒寫／恢復／重試、三尺寸、確認取消、阻擋報告優先、主動開頁／關閉不搶頁／重載與新世／延壽後再耗盡 |
| `m3a_reincarnation`、`m3a_reincarnation_ui`、`feature_navigation`、`m2d_responsive_ui` runners | 各exit0；輪迴UI在後續修訂後另重跑exit0 |
| Godot `--path . --script res://tools/uix_r7f1_preview.gd` | 最終exit0；1280×720、844×390、800×360各五狀態共15 PNG |
| bundled Python `tools/subset_game_fonts.py` 與 `--check` | exit0；更新衍生字型，原始字型保持 |
| Godot `--headless --path . --export-release R7Acceptance build/r7-acceptance/index.html`／`Web build/web/index.html` | 最終各exit0 |
| bundled Node `tools/prepare_web_compression.mjs build/r7-acceptance`／`build/web` | 最終各exit0；roundtrip與音樂companions |
| `git diff --check`、嚴格UTF-8回讀、最終字型`--check` | 均通過，diff/font exit0 |

原生截圖初版曾壓到短式收益及桌面詳情入口，已在配適後重產；天賦成功收據佔高亦修正。既有Font RID／CanvasItem／ObjectDB退出診斷仍存在，不能宣稱日誌零錯誤。未跑全量runner或重做既有FPS／冷啟動矩陣。

## 桌面瀏覽器證據

使用CUA IAB與真實滑鼠、獨立 `127.0.0.1:48772` origin。沙箱HTTP首次ERR_CONNECTION_TIMED_OUT；停止同一服務後以host權限僅綁127.0.0.1啟動成功，舊錯誤分頁未繞過瀏覽器安全限制。只測本輪服務，不接觸玩家origin。

- 1280×720：先看到洞府，核心時間前進5秒後自動開啟壽盡輪迴；熄滅命燈、空槽與收益可見。關閉後留在洞府，無反覆搶頁。
- 844×390：壽盡進度重載後再次提醒；確認、內捲完整重置說明、取消保持第一世通過。
- 800×360：固定分頁／貨幣／主動作、天賦實付50→45／資源傳承0→1與保存通過。短式CSS視窗與Godot實際畫布有約1px瀏覽器取整差，DPR約1；不是實機證據。

最終版 `81ea812332d3740c10c49c6d3e74443cc126298c6c41dd17a70c33d0cbb2fd1a`：重開同origin自動提醒，貨幣45／資源傳承10%沿用；1280概覽與800概覽、內捲確認、取消自動回概覽通過。800實際再次確認轉世→第2世結果→入世→重載通過，未再seed或重彈壽盡頁；console warn/error查詢空。最終畫面為 `web-final-*.jpg`。較早自動跨過5秒／844／天賦付款證據取自前版，只差取消回概覽、成功收據避讓與延壽後重設提醒，沒有把前版全矩陣冒稱同一hash。

一般Web最終PCK `25bc4d3c9fa9a372d2ef7623a3ed692ca6ee8fba4d14374aaba96ea1aae19288`；已匯出／壓縮，沒有把含fixture的獨立版當一般版hash。保存權威仍為localStorage＋Web Lock，不宣稱IndexedDB實測。服務48772已停止，成功測試分頁已關閉、viewport覆寫還原；停止服務的exit1為Ctrl+C主動終止。最早逾時的錯誤分頁關閉被Browser Use URL policy拒絕，未繞過限制；不影響測試頁成功保存與關閉。

## 接手

本輪只交付R7-F1；R7維持IN_PROGRESS（美術待接受）。下一New Chat收R7圖像比例、氛圍與密度回饋，必要時局部修訂，不開R8。觸控／實機為延期，非當前阻擋，不列下一任務。
