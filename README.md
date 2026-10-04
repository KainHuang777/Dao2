# 修仙問道 v2

2026-10-04 R2最新[耗時定位](docs/verification/res1-c2-perf-r2-profile.md)：三組1280×720／DPR約1，HUD平均12.7–12.8ms（導覽5.0–5.1ms、建築／資源清單3.7–3.9ms），保存18.1–22.7ms、編碼佔大部。本輪交付預設關閉的profile工具，未做效能改善；未重現200ms、嚴格60未放行。基礎版51/51、最終世界26通過。下一同R2改善HUD重複View／資源卡刷新，**不跳D**。

2026-10-04 R2最新[桌面FPS複測](docs/verification/res1-c2-perf-r2-fps.md)：1280×650／DPR1.25三組遊戲pooled **59.019FPS**、p95均16.8ms／max200ms；三組無遊戲對照59.997。量測工具13契約通過，嚴格60仍未過；下一同R2定位秒級更新／保存成本，裝置／人工待驗，**不跳D**。本輪未改Godot，下面51/51與節流啟動屬前輪結果。

2026-10-04 PERF-R2 續輪（最新）：20Mbps／100ms長離線 ready **9.801／9.777秒**，兩個新origin通過10秒；原生48h CPU **2.662→0.886秒**、完整終態hash不變。最終51/51、145精確檢查、async27、world26、Web C2 retry49通過。桌面 **59.930FPS／p95 16.8ms**，嚴格60仍未過；人工／手機／高DPR等仍待驗，R2／C／C2維持IN_PROGRESS，不跳D。 [本輪證據](docs/verification/res1-c2-perf-r2.md#2026-10-04-續輪交付節流長離線缺口)。下方同日較早結果保留歷史。

Godot 修仙放置遊戲原型：由洞府建設、修行與突破開始，逐步探索輪迴、宗門與不同世界。主場景、HUD 和互動由 Godot/GDScript 負責；Web 匯出供瀏覽器執行。

## 目前狀態｜2026-10-04

**同日較早 RES1-C2-PERF-R2：離線改善交付，整體 IN_PROGRESS**。同條件本機48h恢復 **18.03→7.75秒**，逐秒終態／事件保持；最終 **51/51 Runner、121精確檢查、Web retry49** 通過。20Mbps／100ms新檔8.45秒，但長離線13.55秒仍超10秒；桌面59.80FPS／p95 16.8ms，嚴格60仍未過。詳 [R2驗收](docs/verification/res1-c2-perf-r2.md)。下一仍PERF-R2缺口／裝置與人工，不跳D；以下保留前輪歷史。

**同日較早 RES1-C2-PERF：桌面效能改善交付，整體 IN_PROGRESS**。正常Web核心Brotli **14.44MB**（含四首原音樂19.79MB）、20Mbps／100ms新檔ready **8.49秒**；600秒規則CPU約減少49.8%，終態hash不變。最終桌面p95 **16.8ms**，平均59.45–59.85FPS仍未嚴格達60；48h恢復本機18.19秒仍待改善。**51/51 Runner**、107精確tick/font、世界26、真實Web retry49、兩橫式操作及50次Web切島通過。[驗收與隔離試玩](docs/verification/res1-c2-perf.md)。人工美術／高DPR／手機／自然凍結／跨瀏覽器／長期GPU記憶體仍待驗，下一C2-PERF-R2，不跳D。以下保留較早分輪紀錄。

**本輪 RES1-C3 最新**：四張青木／玄礦正式PNG分層美術已接正常版「經營 → 空島」，築基後玩家保留原檔並啟用。三島是首段切片，[30+容量與考據規格](docs/15-island-expansion-and-art-direction.md)採多产地共用有限材料鏈，後續島群尚未實作。最終50/50、正常world22及兩版型Web開拓／重開／精煉通過；人工美術／節奏與C2效能／裝置仍待驗。[本輪交付與試玩](docs/verification/res1-c3-art-integration.md)。下方預覽限定／正式未附掛為前輪歷史，由當次使用者要求覆蓋。

**最新：RES1-C2-R1 桌面保存追加矩陣完成；整體仍 IN_PROGRESS**。async故障／真實quota／兩次重載／雙分頁／拒讀／損壞146 checks、全量50/50及世界15 checks通過。獨立桌面實測48.60FPS／p95 33.4ms、20Mbps／100ms含48h恢復ready67.84秒、gzip下載估算44.72MB，效能未達預算。使用者美術／節奏保留待驗，實機／高DPR等仍待補；正式manifest未啟用。見 [收尾驗收與預覽](docs/verification/res1-c2-closure.md)。下一C2-PERF，不跳D；C1／原C2證據保留。

**最新產品方向：RES1 多島資源主線**。依使用者要求，Era 逐步解鎖專業空島，基礎資源經加工／融合形成 T2、T3 材料，透過實際供給與運輸支撐建設與修行。已完成[設計修訂](docs/14-multi-island-resource-progression.md)與[DAO1 資源稽核](docs/verification/resource-progression-audit.md)，尚未實作新玩法。DAO1 有 61 資源／30 配方；本作 manifest 目前僅 7 資源／10 建築／Era 1–2，另有少量子系統資源，不能宣稱已完整承接 DAO1。RES1-A 首批契約／隔離 Craft 核心已交付（15 資源／8 配方、145 checks、DAO1 8/8、42 Runner PASS），見[驗收](docs/verification/res1-a.md)。RES1-B 原型核心與桌面 Web 保存故障範圍 DONE（251 checks、三程序保存／載入／離線、真實quota／重載／雙分頁與受控Web幀恢復），見[核心](docs/verification/res1-b.md)／[Web驗收](docs/verification/res1-b-web-r1.md)。最新固定入口47/47 PASS、exit0；正式manifest仍未啟用，下一RES1-C三島操作。實機／自然背景凍結／高DPR／長離線CPU預算仍待驗。

已實作多世輪迴、丹藥、BUFF、宗門、靈界、天時、機緣奇遇、四種靈獸與 18 項成就；九界法則、世界地址、確定性世界描述生成與界域戰略決策已有規則／資料／保存測試。宗門、跨界與 BUFF 的 Session 白名單已補上。2026-10-03 UI8 R1 全量回歸 **39/39 Runner 通過、exit 0**；後續建造訊息修復另重跑導覽／響應式兩項，使用者測試 OK；引擎 Godot `4.7.2.stable.official.ed1daf0bf`。

主導覽已重整為「洞府／經營／修行／遊歷」：洞天據點與建築共用經營分頁，煉丹／靈獸／輪迴歸修行，九界／宗門／機緣／天道決策歸遊歷；移除重複 More 入口。新增功能須遵守[入口整合規範](docs/12-feature-navigation-and-integration-spec.md)。分類／視覺回饋與實機驗收待完成，見 [NAV1](docs/verification/feature-navigation.md)。

9/29–10/2 另實作系統設定與境界 BGM 排程、橫式響應式／直式旋轉提示、介面材質迭代、思源黑體＋粗明體、引導／訊息改善，以及升境光環雷電與過場文字樣板。最新 UI7 採紙色墨字、霧面青玉與朱砂重點；既有紀錄已驗桌面瀏覽器 1280×720、844×390 滑鼠與 360×640 旋轉提示，使用者美術放行、高 DPR 與實體手機仍待驗。九界資料交付不代表九界完整可玩、美術與長期負載都已驗收。

M4-A-R1 正式 Session／桌面 Web 整合驗收已完成：251 checks、40/40 Runner 與 1280×720／844×390 實際操作通過，修正命令收據保存、宗門獎勵入庫及按鈕重建。見 [驗收](docs/verification/m4-a-r1.md)。此為原有系統整合範圍，多島加工／運輸與完整 DAO1 資源內容另依 RES1 交付；裝置、M1-C/D Web 持久化／離線故障證據仍待補。詳細變更與未完成 DoD 見[文件複核](docs/verification/doc-a-r1.md)及[目前狀態](docs/development-status.md)。原始碼已同步至 [GitHub 專案](https://github.com/KainHuang777/Dao2)；引擎、模板、快取與 Web 匯出不納入版本控制，複製倉庫後須備妥同版環境。

築基小院外觀與三種洞府小景已接入同一 Godot 世界：靈木／靈草／靈石隨機出現、點擊批次採收、最多兩件並保存狀態；短橫式修正初始屋頂取景。38 Runner、八張 native 與 Web 鼠標／重載已驗，使用者美術及實機待補，見 [ISLAND1](docs/verification/island-scenery.md)。

## 開始接手

依序閱讀：

1. [AGENTS.md](AGENTS.md)：工作規則、安全執行與驗收要求。
2. [ROADMAP.md](ROADMAP.md)：任務依賴、範圍及完成定義。
3. [開發狀態](docs/development-status.md)：目前任務、驗證結果與後續順序。
4. [AI 交接指南](docs/ai-handoff.md)：環境與可重跑命令。

若修改洞府呈現，先看[按需檔案索引](docs/abode-presentation-map.md)，再讀實際涉及的控制器或元件；版面、Web、輸入修改必讀[響應式 UI 規格](docs/07-responsive-ui-web-spec.md)。不要為了接手重讀整份歷史紀錄。

## 開發與驗證

- Godot `4.7.2.stable.official.ed1daf0bf`、GDScript、Compatibility、單執行緒 Web。
- 使用 PowerShell 從專案根目錄執行現有 51 Runner（清單以腳本為準）：

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
| 功能入口、分頁及資源整合 | [入口整合規範](docs/12-feature-navigation-and-integration-spec.md) |
| 建築呈現與 Era 擴充 | [建築呈現規格](docs/08-building-presentation-and-era-expansion.md) |
| 功能驗收與已知限制 | `docs/verification/`；入口見[開發狀態](docs/development-status.md) |
| 舊進度原文 | `docs/archive/`；保留日期供查考，不作目前狀態依據 |

技術基線與尚未完成的設計見 [ROADMAP](ROADMAP.md) 及專題文件；規則實際狀態以程式和測試為準。舊參考專案 `E:\Python\test1`、`E:\WORK\GodTower` 僅唯讀。
