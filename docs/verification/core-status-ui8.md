# M2-D-UI8 核心資訊與狀態提示

2026-10-03，IN_PROGRESS：實作與本輪指定證據交付，使用者視覺、實體觸控、高 DPR 待驗；全量回歸有既有成就契約失敗。

使用者提供舊 HUD 及人物 Mockup，要求乾淨字型／斷行、減少連排字級與色彩差異、將其他系統完成提示加入 BUFF 區、採文字與圖字／小 icon。參考其層級、留白及細進度條，沒有複製人物肖像、名稱或虛構玩家身份。

交付：原生 Godot 容器內的「道」圓印、22 境界題字、16 層級與一致墨色正文，細青玉修煉條。桌面修煉、壽元、天時各成行；短橫向秒數改由進度條提示承載，壽元／天時併排，保留資源區空間。圓滿容量說明縮為一行，詳細條件留 tooltip；晉階／突破成本亦留 tooltip，資格與命令不變。功滿數值顯示上限，實際累計可查 tooltip；壽盡優先明示於層級狀態，冗長橫幅收為 44px 輪迴捷徑。

共用狀態列：宗門 active_expedition elapsed >= duration 且已解鎖時顯示任務完成；靈獸 view.can_feed（冷卻結束、非成熟且材料足夠）時顯示可以餵養；fortune.has_pending 顯示機緣待決；BUFF 保留倒數、名稱與完整效果提示。先列可處理通知，再列增益；宗／獸／緣／符等圖字沿用共同字型角色。點提示只發 route_requested，前往現有 sect／beasts／fortune；不自動領獎／餵養／結算。狀態解除即移除，無新增存檔欄位或通知持久狀態。按 ID 比對，只在項目集合變更時重建，倒數更新不打斷按鈕。橫向捲動與＋N 循環查看維持固定高度。

來源／資產：道印及版面為本輪原創 Godot Control／StyleBox；既有 UiIcon、lotus.svg、UiMaterial 及思源黑體／粗明體沿用專案授權。沒有新增 raster、複製附件人物、美術素材下載、遊戲規則或保存變更。

修改檔案：src/presentation/abode_hud_controller.gd、buff_hud_bar.gd；tests/buff_system_runner.gd、core_positive_flow_runner.gd、m2d_responsive_ui_runner.gd；tools/core_status_preview.gd；ROADMAP、docs/07、development-status、此紀錄及 updata。呈現測試改為各別境界／層級／壽元行；短直式資源測試保留顯示模式，承認既有短管理欄空間保留規則。

必要編譯修復：本輪開始時工作區已有未提交成就開發。feature_navigation.gd 的 narrow 未宣告，achievement_panel.gd 引用不存在的 GOLD，將 JADE 貼圖當顏色；僅補變數與合法 Color／INK，保留其餘成就內容。沒有把其來源改動算成本輪功能交付。

命令與證據（現有 Godot tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe）：

- `--version`：4.7.2.stable.official.ed1daf0bf，exit 0。
- `--headless --path . --import`：exit 0，但首輪日誌出現上述依賴腳本編譯錯誤；不能只依 exit 0 稱成功。後續修復後原生 Runner／Web 匯出未見 Parse／SCRIPT ERROR。
- `--headless --path . --script res://tests/<name>.gd --quit-after 600`：m2d_responsive_ui_runner、buff_system_runner、feature_navigation_runner、core_positive_flow_runner、abode_presentation_parity_runner、m3a_reincarnation_ui_runner 六項 PASS／exit 0。最後＋N 改動後再次重跑響應式、BUFF、輪迴三項，exit 0。日志 artifacts/ui8-<name>.log。
- `--path . --script res://tools/core_status_preview.gd --quit-after 600`：最後 exit 0，八張 new／full／notices／notices-more × 1280×720／844×390 原生 PNG，artifacts/ui8/；fixture 僅在 user://ui8_core_preview，不觸碰玩家槽位。
- `--headless --path . --export-release Web build/web/index.html`：最後 exit 0，artifacts/ui8-export.log。
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1`：exit 1，m1a hut 1 changed_ids 預期 hut／money／wood，實際多 achievements。這是工作區成就接線的契約差異，需由成就任务定義，不修改 fixture 讓它假通過。日志 artifacts/ui8-runners.log。之前 38/38 歷史結果不代表本輪全量成功。

瀏覽器：CUA IAB 使用既有 NAV1 測試 origin http://127.0.0.1:4183/index.html?ui=ui8-core-20261003，沒有重置資料或操作 4175／4178 玩家 origin。CSS 1280×720／844×390、DPR 約 1；關閉摘要、讀取新核心資訊、點機緣提示進同一機緣頁並返回，短橫向視覺及輪迴入口檢查；點輪迴進資格頁再返回，沒有執行轉世。console error/warn 查詢為空，已恢復 viewport override。機緣提示觀察到正式頁，未選擇獎勵。JPEG 為 artifacts/ui8/web-desktop.jpg、web-short.jpg。宗門／靈獸提醒條件、穩定按鈕與 route emission 由隔離 Runner 驗證，原生多提醒圖已檢查；尚未在瀏覽器從真實派遣／餵養週期完成兩類端到端通知。

已知限制：短橫向左側資源列表可用高度仍很有限，數量列可讀性需另補；全量成就 fixture 失敗、實體觸控／高 DPR／手機 hover 替代細節／效能待驗，既有 Font RID、CanvasItem、ObjectDB 退出診斷保留。首輪預覽沙箱日志寫入／憑證警告，授權隔離重跑完成。沒有 commit／push。本階段交接完成後，不接續大型功能；下一步先收 UI8 視覺回饋，另由成就任務補齊 changed_ids 契約。

## 2026-10-03 R1：圖示狀態列與 TIP

使用者指出多 BUFF 遮擋／重疊，改為 44×44 圖字小圖示（18 字印），名稱／效果／剩餘時間移入 tooltip。BUFF 可點開原生 PopupPanel 詳情，點外側關閉；通知圖示仍進 canonical route。依可用寬度計算完整圖示容量，超出項目以 +N 分頁循環，取消橫向捲動與半截按鈕。没有新增圖形資產、規則、庫存或保存變更。

修改：src/presentation/buff_hud_bar.gd、abode_hud_controller.gd；tests/buff_system_runner.gd；tools/core_status_preview.gd；ROADMAP、docs/07、development-status、此文件與 updata。

驗證（Godot 4.7.2.stable.official.ed1daf0bf）：
- `--headless --path . --script res://tests/buff_system_runner.gd --quit-after 600` PASS、exit 0；首次沙箱執行有 user:// 日誌權限／憑證診斷，授權全量重跑完成。
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1`：39/39 PASS、exit 0；artifacts/ui8-icons-runners.log。成就 changed_ids 前輪阻塞已由 M3-B 修復；保留下方早期歷史。預期損壞存檔測試診斷及既有退出資源警告仍留在日誌，不等於所有日誌無 ERROR。
- `--path . --script res://tools/core_status_preview.gd --quit-after 600`：exit 0，10 張原生圖，1280×720／844×390；11 項狀態 fixture、可見圖示矩形皆在容器內、換頁、viewport 滑鼠 press/release 開啟 BUFF 詳情皆通過。隔離 user://ui8_core_preview。artifacts/ui8-icons-native.log 及 ui8-icons/*.png；退出 Font RID／CanvasItem／ObjectDB 診斷保留。
- `--headless --path . --export-release Web build/web/index.html`：exit 0；artifacts/ui8-icons-export.log。
- 真實 IAB，既有隔離 origin 4183：844×390／1280×720 畫面、點機緣圖示開功能頁並返回，console error/warn 空；JPEG ui8-icons/web-short、web-desktop、web-fortune-route。未操作 4175／4178 玩家 origin，已恢復 viewport override。

TIP 點擊由原生真實 viewport 輸入驗證；本輪瀏覽器未建立多 BUFF fixture，瀏覽器多 BUFF／hover 與實體手機觸控、高 DPR 仍待驗。UI8 保留 IN_PROGRESS 待使用者視覺與裝置驗收。人工步驟：多 BUFF 時停留查看名稱／效果／時間，點圖示開詳情、點外側關閉，循環 +N，縮窄視窗後確認圖示不裁切。下一步收視覺回饋；大型工作使用 New Chat。