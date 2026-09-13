# 修仙問道 v2

以 Godot 建立可由 AI 持續編碼、驗證與打包的修仙放置遊戲。從一座會自行運轉的洞府出發，經歷突破與輪迴，逐步把神識和經營範圍延伸到九界與諸天宇宙。

目前階段：**Godot 環境與可操作洞府原型已建立；正式經濟、洞府存檔與離線仍未完成。**

## 後續開發入口（含 GPT-5.6／OpenCode 交接）

1. [AGENTS.md](AGENTS.md)：AI 必讀約束。
2. [ROADMAP.md](ROADMAP.md)：M0–M5 任務、相依順序、交付與驗收條件；開發順序以此為準。
3. [AI 交接指南](docs/ai-handoff.md)：現有檔案、可重跑命令與可直接貼用的接手提示。
4. [開發狀態](docs/development-status.md)：已實測／未完成／下一項工作。

桌面 Web 的 **M0-A 原型驗收** 已完成，紀錄見 [M0-A 驗收](docs/verification/m0-a.md)；實體觸控／雙指會在 M2-D 補測。下一個主線為 **M0-B 固定舊版 fixture**，再建立 Amount／RNG 契約。周天計數已由獨立 probe 驗證保存，小洞府目前重載仍會重置，兩者是獨立探針。

## 專題設計參考

建議閱讀順序：

1. [產品、玩法與世界規劃](docs/01-product-and-world-plan.md)：遊玩體驗、舊玩法承接、九界、視覺與版本範圍。
2. [Godot AI-first 技術架構](docs/02-technical-architecture.md)：模組、模擬、離線、存檔、世界生成與工具鏈。
3. [前期里程碑與 Codex 開發交接](docs/03-delivery-plan.md)：切片內容、驗收、工作順序與第一個實作任務。
4. [需求來源與舊版基線](docs/00-source-baseline.md)：已確認的事實、待核對規則與技術來源。
5. [塔防圖譜承接與具體視覺設計](docs/04-meridian-visual-integration.md)：工筆人物、經脈／五行、洞府與九界的整合，以及護山試煉提案。
6. [Godot 環境與最小 Web 專案探針](docs/05-godot-environment-probe.md)：4.7.2 可攜式環境、Web export 與實際驗證結果。
7. [第一分鐘的視覺與九界鉤子](docs/06-first-minute-visual-direction.md)：初入洞府、天外一瞥、後期九界的介面方向與 Godot 落地邊界。可直接開啟 [互動視覺原型](docs/visual-prototype/index.html) 體驗。

方向基線：Godot 4.7.2／GDScript／Compatibility／單執行緒 Web 起步；以 2D 分層美術與 2.5D 視差呈現宏觀世界。先驗證一界的玩法與畫面，再以資料內容擴展九界與宇宙。

舊版來源為 `E:\Python\test1`，已唯讀核對代表性公式、存檔與測試。九界名稱、v2 新機制、裝置效能預算及里程碑内容為可調整提案；公式移植同等性與舊存檔相容性仍需執行測試。
