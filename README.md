# 修仙問道 v2

Godot 修仙放置遊戲原型：由洞府建設、修行與突破開始，逐步探索輪迴、宗門與不同世界。主場景、HUD 和互動由 Godot/GDScript 負責；Web 匯出供瀏覽器執行。

## 目前狀態｜2026-09-28

已交付多世輪迴、丹藥、BUFF、宗門與靈界系統，Godot 4.7.2 的 25 個 Runner 通過。使用者已驗收 M2-D 桌面 Web 視覺與操作；後續回歸另發現 360 CSS px 版型縮放不足。最新檢查也發現宗門、跨界及 BUFF 命令雖有 `CommandProcessor` 分支，卻未列入 `GameSession` 命令白名單，正式場景會回覆 `UNKNOWN_COMMAND`。

因此下一步先補 Session 命令整合，再修正 Godot 邏輯視口與窄螢幕 CSS 的縮放；完成後繼續 M4-B 尺度與法則。各項證據與限制以[目前狀態](docs/development-status.md)為準，過往里程碑名稱不代表最近回歸發現的缺口已修好。

## 開始接手

依序閱讀：

1. [AGENTS.md](AGENTS.md)：工作規則、安全執行與驗收要求。
2. [ROADMAP.md](ROADMAP.md)：任務依賴、範圍及完成定義。
3. [開發狀態](docs/development-status.md)：目前任務、驗證結果與後續順序。
4. [AI 交接指南](docs/ai-handoff.md)：環境與可重跑命令。

若修改洞府呈現，先看[按需檔案索引](docs/abode-presentation-map.md)，再讀實際涉及的控制器或元件；版面、Web、輸入修改必讀[響應式 UI 規格](docs/07-responsive-ui-web-spec.md)。不要為了接手重讀整份歷史紀錄。

## 開發與驗證

- Godot `4.7.2.stable.official.ed1daf0bf`、GDScript、Compatibility、單執行緒 Web。
- 使用 PowerShell 從專案根目錄執行完整 25 Runner：

  ```powershell
  powershell -File .\tools\run_all_runners.ps1
  ```

- Web Release、單獨 Runner 及瀏覽器操作命令見[交接指南](docs/ai-handoff.md)。Headless Runner 不代表瀏覽器輸入、窄版可讀性、實機觸控或 IndexedDB 已驗收。
- 每項工作記錄 ID、修改檔案、命令與結果、未通過項及下一步於 `docs/development-status.md`，只有符合 Roadmap 的 DoD 才標 DONE。

## 文件地圖

| 需要了解 | 文件 |
| --- | --- |
| 產品玩法與範圍 | [產品與世界規劃](docs/01-product-and-world-plan.md) |
| 核心模組、時間與保存架構 | [技術架構](docs/02-technical-architecture.md) |
| 舊版規則證據 | [來源基線](docs/00-source-baseline.md)、[差異紀錄](docs/rule-differences.md) |
| Godot/Web 畫布、裝置與輸入 | [響應式 UI/Web 規格](docs/07-responsive-ui-web-spec.md) |
| 建築呈現與 Era 擴充 | [建築呈現規格](docs/08-building-presentation-and-era-expansion.md) |
| 功能驗收與已知限制 | `docs/verification/`；入口見[開發狀態](docs/development-status.md) |
| 舊進度原文 | `docs/archive/`；保留日期供查考，不作目前狀態依據 |

技術基線與尚未完成的設計見 [ROADMAP](ROADMAP.md) 及專題文件；規則實際狀態以程式和測試為準。舊參考專案 `E:\Python\test1`、`E:\WORK\GodTower` 僅唯讀。
