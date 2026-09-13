# 開發狀態與交接紀錄

更新：2026-09-13。此檔描述實際進度；順序與 DoD 見根目錄 ROADMAP。下列歷史通過結果來自本對話先前的工具／使用者驗證，本次 Roadmap 整理沒有重新執行 Godot 或瀏覽器。

## 目前可用成果

- Godot 4.7.2.stable.official.ed1daf0bf／同版模板、Compatibility、單執行緒 Web 已安裝並成功匯出。
- 主場景為 `scenes/living_abode.tscn`；獨立圖片位於 assets/abode；美術提示詞位於 docs/abode-art。
- 2026-09-13 先前 CLI：`abode_state_runner.gd` 通過；`living_abode_runner.gd` 通過，輸出 `PASS: living abode selects buildings, upgrades, pauses production, and changes scale.`；主場景啟動輸出 ABODE_READY；Web export 成功。主洞府的最新工作基線為 1280×720 橫版桌面優先；手機版需另做直式適配，不能等比例縮小本 HUD。
- 同日先前瀏覽器：點茅屋有 ABODE_SELECT: hut 與詳情；點升級有 ABODE_UPGRADE: hut level=2 與畫面更新；點神識展開有 ABODE_REGION 與多浮島遠景。橫版重排後重新檢查 1280×720 16:9 畫布：繁中標題、資源、建築底牌與右側詳情均清楚可見，點茅屋後右側升級卡正常出現。
- 使用者先前確認舊周天探針繁中正常，點擊計數重載後保留；洞府展示無存檔。兩者不能混用。
- 上一輪服務使用 localhost:4175，當前是否仍在運行必須重新檢查。不可把暫時服務當作已部署產品。

## 任務板

| 任務 | 狀態 | 剩餘工作 |
| --- | --- | --- |
| M0-A | IN_PROGRESS（桌面 Web 完成） | 可重跑整合入口、獨立計數探針 export、瀏覽器重載／HUD／滑鼠拖曳與滾輪已通過；實體觸控／雙指與裝置矩陣待 M2-D 前補證 |
| M0-B | DONE | 2026-09-14 已固定唯讀來源的雜湊／資料 profile，建立代表性黃金 fixture 與隔離 reference runner；詳見 `docs/verification/m0-b.md`。完整 Amount 契約留給 M0-C。 |
| M0-C | TODO | 正式 Amount／RNG 相容探針 |
| M1-A/B/C/D/E | TODO | 核心、時間、新存檔、離線、舊檔匯入皆未交付 |
| M2-A/B/C/D | TODO | 現有美術與互動可重用，正式經濟接入、首升境、Godot 九界一瞥及完整畫質／裝置驗收待做 |
| M3-A/B | TODO | 多世循環與舊系統矩陣 |
| M4-A/B | TODO | 第二界可玩差異、正式尺度與法則資料 |
| M5-A/B | TODO | 按需生成、封存與逐界內容 |

目前無已確認的外部阻塞；未選定基準手機與實機測量仍待安排。不因這一項未知而停掉可做的 CLI／fixture 工作。

## 已知限制與檢查線索

1. 展示 state 用 float、每幀 delta 推進，未含容量、正式解鎖、壽元、輪迴、離線或快照。
2. 目前場景測試直接呼叫函式；2026-09-13 已額外在桌面 Web 實測建築命中、HUD、拖曳、滾輪、歸家及遠景。雙指／實體觸控、拖出 HUD 後釋放和不同手機 DPI 仍待 M2-D 前補證。
3. 主場景已改為 1280×720 桌面橫版設計，完整 CLI／Web 匯出與瀏覽器畫面已於本輪重驗。手機直式適配、360 CSS px 可讀性與44px觸控區仍需在 M2-D 前量測，不能由桌面畫面推定通過。
4. region 是重用地形的視覺示範，没有新據點經濟；飛劍／靈流已有動畫程式，但視覺強度、位置對齊與手機效能待實測。
5. all_resources 匯出會帶入 src/效果圖 和 tests；正式發布前需明確排除開發／參考內容，保留來源原圖。
6. 正式資料目錄與 domain/simulation/application/persistence 仍是文件設計，不是已存在的架構。
7. 本輪檢查 `git status` 回覆不是 Git repository；檔案仍在本地，不把版本控制備份視為已完成。

## 下一個動作

M0-B 已完成；下一個主線是 M0-C 的 Amount 與 RNG 相容探針。實體觸控 M0-A 證據記入 M2-D 前的裝置驗收，不得忘記。

## 本輪交付

2026-09-13：新增 ROADMAP、AGENTS、AI handoff 與本狀態檔，更新 README 和舊規劃入口。只修改文件，未改遊戲程式或再次跑遊戲測試；已核對現有檔案與測試入口，並檢查新增文件 UTF-8、相對連結和 Roadmap 任務覆蓋。

2026-09-13 M0-A：新增 `tools/run_m0a.ps1`、隔離周天 probe、兩個 Godot source-scan ignore 及鏡頭觀察記錄。完整 CLI 匯入／runner／雙 Web export 成功；桌面瀏覽器實測周天保存 1→2→3、洞府選取／升級／藥圃停復／低特效／遠景／歸家／拖曳／滾輪。詳見 [M0-A 驗收紀錄](verification/m0-a.md)。實體 touch/pinch 與效能未測，故 M0-A 保持 IN_PROGRESS。

2026-09-13 可讀性調整：主場景設計尺寸改為 1280×720；HUD 改為左側狀態、中央洞府、右側詳情與底部操作，面板提高不透明度、字級與按鈕尺寸，建築名稱加深色底牌；低優先的常駐操作提示移出主畫面，保留操作說明按鈕。初始洞府鏡頭提高至 0.70，讓地形在桌面畫布成為主視覺。`tools/run_m0a.ps1` 最後一次完整匯入、三個 runner、啟動與兩個 Web export 均成功；localhost Web 實測茅屋選取及右側升級詳情通過。此調整未改展示數值、經濟或保存。手機直式適配仍未做。

2026-09-14 M0-B：新增 `docs/legacy-source-manifest.md`、`docs/rule-differences.md`、`tests/fixtures/legacy/m0-b-v1.json`、`tests/fixtures/legacy/m0b_reference.test.ts` 與驗收紀錄。`E:\Python\test1` 不是 Git work tree，故以 package 版本、精選規則／測試／CSV 的 SHA-256 和資料列數固定來源。隔離 Vitest runner 直接從唯讀舊規則模組驗證建築成本、容量容差、修煉時間、Amount 代表字串、壽元、輪迴、新手解鎖與 ASCII／繁中／數字 SeededRandom state 恢復；1 test 通過。完整 Amount 演算與 GDScript RNG 實作尚未開始，列入 M0-C。
