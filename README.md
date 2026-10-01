# 修仙問道 v2

Godot 修仙放置遊戲原型：由洞府建設、修行與突破開始，逐步探索輪迴、宗門與不同世界。主場景、HUD 和互動由 Godot/GDScript 負責；Web 匯出供瀏覽器執行。

## 目前狀態｜2026-10-02

已實作多世輪迴、丹藥、BUFF、宗門、靈界、天時與機緣奇遇；九界法則、世界地址、確定性世界描述生成與界域戰略決策已有規則／資料／保存測試。宗門、跨界與 BUFF 的 Session 白名單已補上。2026-10-02 複核重跑現有 **34/34 Runner 通過、exit 0**；引擎 Godot `4.7.2.stable.official.ed1daf0bf`。

9/29–10/2 另實作系統設定與境界 BGM 排程、橫式響應式／直式旋轉提示、介面材質迭代、思源黑體＋粗明體、引導／訊息改善，以及升境光環雷電與過場文字樣板。最新 UI7 採紙色墨字、霧面青玉與朱砂重點；既有紀錄已驗桌面瀏覽器 1280×720、844×390 滑鼠與 360×640 旋轉提示，使用者美術放行、高 DPR 與實體手機仍待驗。九界資料交付不代表九界完整可玩、美術與長期負載都已驗收。

下一步先完成最新 UI／字型／演出回饋與裝置驗收，再依 Roadmap 推進靈獸或成就。詳細變更與未完成 DoD 見[文件複核](docs/verification/doc-a-r1.md)及[目前狀態](docs/development-status.md)。原始碼已同步至 [GitHub 專案](https://github.com/KainHuang777/Dao2)；引擎、模板、快取與 Web 匯出不納入版本控制，複製倉庫後須備妥同版環境。

## 開始接手

依序閱讀：

1. [AGENTS.md](AGENTS.md)：工作規則、安全執行與驗收要求。
2. [ROADMAP.md](ROADMAP.md)：任務依賴、範圍及完成定義。
3. [開發狀態](docs/development-status.md)：目前任務、驗證結果與後續順序。
4. [AI 交接指南](docs/ai-handoff.md)：環境與可重跑命令。

若修改洞府呈現，先看[按需檔案索引](docs/abode-presentation-map.md)，再讀實際涉及的控制器或元件；版面、Web、輸入修改必讀[響應式 UI 規格](docs/07-responsive-ui-web-spec.md)。不要為了接手重讀整份歷史紀錄。

## 開發與驗證

- Godot `4.7.2.stable.official.ed1daf0bf`、GDScript、Compatibility、單執行緒 Web。
- 使用 PowerShell 從專案根目錄執行現有 34 Runner（清單以腳本為準）：

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
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
