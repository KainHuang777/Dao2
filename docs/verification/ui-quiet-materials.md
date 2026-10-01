# M2-D-UI7：常態介面材質與配色統一

2026-10-02，IN_PROGRESS：實作／CLI／native／桌面瀏覽器滑鼠驗證完成，使用者美術放行、實體手機與高 DPR 待補。

## 專案複核與修正範圍

使用者要求在終端修復、可正常讀取專案後，複核已保存提案並開工。讀取 README、Roadmap、handoff、development-status、技術架構、響應式規範、建築呈現規範、材質來源與既有 UI4／UI5 證據，再檢查 UiMaterial、HUD、營造與功能面板。

修正初始提案：左側三態資源不搬到頂部；保留使用者先前指定的不規則泛黃紙邊，僅淡化中央與上下邊緣色差；舊功能面板的淺色文字沿用墨色實底，以避免全面紙底轉換漏改對比。橫式／短橫向／直屏旋轉引導、字型 400／600／800、命中區、內容內縮、捲動與開關行為沿用。

普通按鈕改紙色墨字；選中頁籤與既有世界銘牌為霧面青玉，短金線輔助選中辨識；晉階／突破為朱砂。舊全玉石功能面板改低彩度墨色，薄銅框取代亮面／華麗角飾。資源與修行紙底屬同一暖灰色系。系統訊息降低飽和度，保留語意分類色，移除可能在 Web 換行時獨占一行的裝飾項目符號。輪迴頁籤的舊淺色覆寫修正為依選中／未選中材質給字色。

## 修改檔案與来源

- `src/presentation/ui_material.gd`：共用材質角色、各互動狀態字色、焦點邊框、頁籤與世界銘牌。
- `src/presentation/abode_hud_controller.gd`：修行主要操作與設定圖示對比、訊息配色／裝飾。
- `src/presentation/reincarnation_panel.gd`：避免舊頁籤字色覆蓋新材質。
- `assets/ui/material/{jade_panel,jade_card,silk_panel,silk_row}.svg`：墨色功能面板與中性暖灰紙。
- 新增原創 SVG `paper_button.svg`、`jade_selected.svg`、`cinnabar_button.svg`；直接撰寫向量，無第三方圖像、無 imagegen 提示詞。裝飾與文字／命中分層；來源與授權邊界見同目錄 README。既有 jade_plaque.svg 留存，無新增動畫或效果。
- `tools/ui_material_preview.gd`：`--quiet-material` 保存獨立證據，不覆蓋先前圖片；新增純呈現朱砂操作 fixture。使用原有隔離 preview 保存，不修改玩家檔。
- 提案、Roadmap、development-status、updata 與本驗收文件。

## 命令與實際結果

引擎為既有 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`。

- `--headless --editor --path . --import --quit`：exit 0，`docs/verification/ui-quiet-import.log`。
- 首次 `powershell -NoProfile -File tools/run_all_runners.ps1` 被 Windows 執行政策拒絕；改為僅本程序 `-ExecutionPolicy Bypass`，未改全機政策。沙箱內首次 Runner 因無法寫 `user://web_probe_runner.json` 退出 1；正常授權重跑後 **34/34 PASS、exit 0**，`ui-quiet-runners.log`。該 fixture 與玩家 web_probe_state／正式保存分離。
- `--headless --path . --script res://tests/abode_presentation_parity_runner.gd --quit-after 600`：PASS、exit 0，`ui-quiet-parity.log`。
- Native `--path . --script res://tools/ui_material_preview.gd --quit-after 600 -- --quiet-material` 與追加 `--guidance-hud`：exit 0，共 21 張 PNG。檢查桌面首頁／營造／朱砂操作、短橫向訊息／煉丹、宗門／輪迴／存檔。圖片為 Compatibility GPU 真實渲染；朱砂與完成引導是呈現 fixture，不代表實際玩家資格。
- 最後移除訊息裝飾符號及追加朱砂 fixture 後，重跑 native guidance（exit 0）與 `tests/m2d_responsive_ui_runner.gd`（PASS、exit 0，`ui-quiet-responsive-final.log`），不重跑無關規則。
- `--headless --path . --export-release Web build/web/index.html`：最终 exit 0，`ui-quiet-export.log`。未手改匯出物。
- 全工作區 `git diff --check` 發現其他既有修改的 EOF 空白行（AGENTS、handoff、Session、loader、GameState）；不改動無關共享工作。本任務範圍的檢查另行記錄。
- 範圍限定的 `git diff --check -- ROADMAP.md docs/development-status.md updata.txt src/presentation/abode_hud_controller.gd src/presentation/reincarnation_panel.gd tools/ui_material_preview.gd`：exit 0。未追蹤的新材質與紀錄不在 Git diff 的涵蓋範圍。

## 真實瀏覽器證據

Codex IAB、WebGL Godot canvas，隔離 origin `http://127.0.0.1:4182`，不操作玩家原 4178 origin。以 Python 3.14 HTTP server 只服務 build/web，僅綁定 localhost。首次開 4178 無服務，回覆 connection refused；啟動本次 4182 後正常載入。

- CSS 1280×720、canvas 1280×720，DPR 約 1.0；實際滑鼠關閉離線摘要，開營造，切換資源完整模式，確認選中底色／文字及材料不足的禁用操作；營造／底部頁籤可返回。
- CSS 844×390、canvas 844×390，DPR 約 1.0；管理欄可讀且有可點返回入口、資源完整模式可見；管理時訊息依既有規則暫收，返回空島後恢復。這是桌面 browser resize，不是手機觸控證據。
- CSS 360×640：顯示既有旋轉提示，未宣稱直式完整遊玩。
- Browser captured error／warning logs 查詢為空。DOM 的 canvas fallback 文案不是畫面錯誤。
- 最終匯出重新載入成功，摘要可關閉，訊息正文不再有独占一行的裝飾符號；保存 `web-home-final-1280x720.jpg`。驗收後已恢復預設 browser viewport，保留預覽分頁。
- 一次初始點選遇 IAB 自動視口從 1280×720 變為 614×450，沒有關閉摘要；設定驗收 viewport 後重新觀察與點選成功，不把無效點選計為通過。

Web JPEG 與 native PNG 在 `docs/verification/artifacts/ui-quiet/`。Native 邏輯短視口 779×360 對應物理 844×390；Web 尺寸另以上述 DOM 量測為準。

## 未驗項與下一步

使用者仍需放行本輪美術；高 DPR、實體手機觸控／GPU／長時間閱讀待驗，未量測 FPS、冷啟動或記憶體。既有 Font RID／CanvasItem／ObjectDB 退出警告仍存在。其他功能頁既有稀有度／狀態色與版型缺口不在本次全面重寫範圍，例如 native 九界卡片既有右側裁切；不能把共用材質通過當作所有功能頁完整 DoD。

下一步先收本輪視覺回饋與裝置驗收，在新對話針對回饋微調；不自動新增建築、重繪世界、重排 HUD 或展開其他系統。
