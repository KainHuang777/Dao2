# 開發狀態與交接紀錄

更新：2026-09-28；重構基線：`d77bca3`。日常只讀本頁與當次任務涉及的文件。

## 目前任務與下一步

- **REF-A：洞府呈現層拆分與文件瘦身**。前項已交付；DONE（範圍、CLI、Web smoke 均通過；手機版面缺陷另列 M2-D-R1）。
- 保持玩法、存檔格式、根場景公共屬性與函式／訊號接線相容。
- 下一優先：先做 **M4-A-R1 Session 命令接線**，再做 **M2-D-R1 窄版 CSS 視口**；通過後進入 **M4-B 尺度與法則**。
- M3-B 天時、機緣、靈獸、成就按 Roadmap 相依交錯推進。

## 精簡任務板

| 任務 | 狀態與證據邊界 | 入口 |
| --- | --- | --- |
| M0-A | 桌面已驗；指定實體手機手勢／效能待補 | [驗收](verification/m0-a.md) |
| M0-B/C | DONE；來源 fixture、Amount/RNG 契約 | [M0-B](verification/m0-b.md)、[M0-C](verification/m0-c.md) |
| M1-A/B | DONE；正式核心、時間、修煉與壽元；後續正流程修正已有測試 | [正流程](verification/core-positive-flow.md) |
| M1-C/D/E | CLI 契約已通過；IndexedDB、跨程序、quota、多分頁與真實舊檔 corpus 仍依各驗收表補證 | [保存](verification/m1-c.md)、[離線](verification/m1-d.md)、[相容矩陣](legacy-compatibility.md) |
| M2-A/B/C | 已交付；新檔首升境、演出、九界鉤子均有 Runner | [M2-A](verification/m2-a.md)、[M2-B](verification/m2-b.md)、[M2-C](verification/m2-c.md) |
| M2-D | 桌面 Web 於 2026-09-28 放行；窄版 CSS viewport 列 M2-D-R1 修復，實體手機另待驗 | [M2-D](verification/m2-d.md)、[演出](verification/island-breakthrough.md) |
| M3-A | 已交付雙軌輪迴門檻、壽盡橫幅、天賦與轉生演出 | [M3-A](verification/m3-a.md) |
| M3-B | 丹藥／BUFF／宗門規則與面板已交付；`apply_buff`、宗門命令目前被正式 Session 白名單拒絕，M4-A-R1 修復；天時等仍 TODO | [M3-B](verification/m3-b.md) |
| M4-A | 領域／存檔／面板程式已交付；`switch_realm`／據點命令未進正式 Session 白名單，M4-A-R1 修復 | [M4-A](verification/m4-a.md)、[本輪發現](verification/ref-a.md) |
| REF-A | DONE（重構／CLI／Web smoke） | [本輪驗收](verification/ref-a.md)、[呈現層索引](abode-presentation-map.md) |
| M4-A-R1 | TODO；Session 白名單與宗門／跨界／BUFF 成功路徑 | [REF-A](verification/ref-a.md)、[Roadmap](../ROADMAP.md) |
| M2-D-R1 | TODO；Godot 邏輯 viewport 與 360 CSS px 映射／可讀性 | [REF-A](verification/ref-a.md)、[UI 規格](07-responsive-ui-web-spec.md) |
| M4-B | TODO；待 M4-A-R1、M2-D-R1 通過 | [Roadmap](../ROADMAP.md) |
| M5-A/B | TODO；依 M4-B 與三種手工法則驗證推進 | [Roadmap](../ROADMAP.md) |

## 本輪交付與驗證

- `src/abode/living_abode.gd`：2,285 → 1,097 行；保留世界、時間／保存協調、突破運鏡及既有呼叫入口。
- `src/presentation/abode_hud_controller.gd`：HUD 組裝、版型、數值／修煉／BUFF、引導與日誌。
- `src/presentation/abode_modal_manager.gd`：彈窗組裝、位置與事件分發；維持原堆疊與開關方式。
- `tests/abode_presentation_parity_runner.gd`：追加場景層回歸；同一組斷言對原版／重構版皆通過。
- 文件：歷史歸檔、精簡狀態、呈現層索引、交接命令、Roadmap REF-A 與驗收紀錄。
- Godot `--version`：`4.7.2.stable.official.ed1daf0bf`。
- 重構前後 `powershell -File .\tools\run_all_runners.ps1`：各 25/25 PASS、exit 0。
- `--headless --path . --import`：exit 0；Web `--export-release Web .\build\web\index.html`：exit 0。
- 新增呈現層回歸 Runner：原版與重構版皆 exit 0；測試只使用隔離資料。
- Runner 仍有原版就存在的字型／CanvasItem 退出洩漏診斷，以及損壞輸入測試的預期錯誤；未新增腳本編譯錯誤。
- Edge 隔離 profile、127.0.0.1:4176：WebGL 2.0 載入、煉丹／存檔開關、更多選單及四種 CSS viewport 切換，console/page/HTTP errors 為 0。
- 窄版視覺發現：360 CSS px 下 HUD 字級／按鈕過小，未通過 docs/07 可讀性／44px 觸控門檻；沿用既有 stretch／版型計算，本次不改行為。
- 完整命令、證據與未通過項見 [REF-A](verification/ref-a.md)。

2026-09-28 DOC-A 文件現況同步：README 收斂為現況／入口／驗證／文件地圖；Roadmap 移除早期「M0-A 建議下一項」誤導，新增 M4-A-R1 與 M2-D-R1 並更新 M4-B 相依；M3-B／M4-A 驗收頁重新界定為模組交付、Session 整合待驗；環境探針與核心正流程中的日期狀態標為歷史。M0–M4 原狀態段落保留於 archive，不覆寫測試／交付歷史。README 46 行、development-status 62 行；文件 UTF-8、現行入口相對連結檢查通過，本輪未執行遊戲測試。

## 必須保留的限制

- `CommandProcessor` 已有宗門、跨界／據點與 `apply_buff` 分支，但 `GameSession.KNOWN_COMMAND_TYPES` 尚未放行它們；因此部分元件／Domain 測試通過仍不足以證明正式場景可玩。
- 本輪在原版場景用宗門／靈界訊號重現 `UNKNOWN_COMMAND`；純重構保留現況，另案修復並補正式 Session 成功路徑。
- 面板／ViewModel 會沿用既有 `ensure_*` 初始化宗門／靈界資料；REF-A 未改此狀態語意。
- 目前一般彈窗依原行為可同時開啟；突破演出 HUD 遮罩／鏡頭鎖定仍由根場景維護。
- 真實手機手勢／GPU／效能與 IndexedDB 落盤不能由 CLI 或桌面瀏覽器取代。

## 歷史與按需閱讀

- [M0–M2 舊記錄與舊交接](archive/development-status-m0-m2.md)：保留原段落，不作當前任務入口。
- [M3–M4 詳細交付歷史](archive/development-status-m3-m4.md)：丹藥、BUFF、宗門、輪迴與靈界的歷史說明。
- [呈現層索引](abode-presentation-map.md)：依修改類型定位檔案，不再一律讀完整主場景。
- [AI 交接](ai-handoff.md)：環境、完整 Runner 與 Web 匯出命令。
