# 修仙問道 v2

以 Godot 建立可由 AI 持續編碼、驗證與打包的修仙放置遊戲。從一座會自行運轉的洞府出發，經歷突破與輪迴，逐步把神識和經營範圍延伸到九界與諸天宇宙。

目前階段：**M0~M2 全切片已完成，M2-D 視覺與 Web 回歸驗收合格（DONE）；M3-A 雙軌輪迴與演出全閉環（DONE）；M3-B 子系統持續交付（丹藥 DONE、BUFF DONE、宗門 DONE）；M4-A 手工第二界（靈界 · 天靈洞天）已全閉環（DONE）。下一個主線實作排入 M4-B（尺度與法則）。** 2026-09-23 的資源來源與正流程修復見 [核心正流程稽核](docs/verification/core-positive-flow.md)。

## 後續開發入口（含 GPT-5.6／OpenCode 交接）

1. [AGENTS.md](AGENTS.md)：AI 必讀約束。
2. [ROADMAP.md](ROADMAP.md)：M0–M5 任務、相依順序、交付與驗收條件；開發順序以此為準。
3. [AI 交接指南](docs/ai-handoff.md)：現有檔案、可重跑命令與可直接貼用的接手提示。
4. [開發狀態](docs/development-status.md)：已實測／未完成／下一項工作。

**M2-D 視覺、裝置與首切片放行**已於 2026-09-28 在真實 Web 環境完成遠景 v5、Shader 瀑布、背景穩定度與突破演出之回歸驗收（見 [M2-D 驗收](docs/verification/m2-d.md)）。M3-A 經典雙軌輪迴門檻、轉生演出與天賦面板已交付（見 [M3-A 驗收](docs/verification/m3-a.md)）；M3-B 已陸續交付丹藥、BUFF 與宗門系統（見 [M3-B 驗收](docs/verification/m3-b.md)）；M4-A 第二界已全閉環（見 [M4-A 驗收](docs/verification/m4-a.md)）。下一個主線任務為 **M4-B 尺度與法則**（九界法則資料擴充、正式地理尺度與遠界旅程），M3-B 剩餘子系統（天時、靈獸、成就）依相依逐步交錯推進。


## 專題設計參考

建議閱讀順序：

1. [產品、玩法與世界規劃](docs/01-product-and-world-plan.md)：遊玩體驗、舊玩法承接、九界、視覺與版本範圍。
2. [Godot AI-first 技術架構](docs/02-technical-architecture.md)：模組、模擬、離線、存檔、世界生成與工具鏈。
3. [前期里程碑與 Codex 開發交接](docs/03-delivery-plan.md)：切片內容、驗收、工作順序與第一個實作任務。
4. [需求來源與舊版基線](docs/00-source-baseline.md)：已確認的事實、待核對規則與技術來源。
5. [塔防圖譜承接與具體視覺設計](docs/04-meridian-visual-integration.md)：工筆人物、經脈／五行、洞府與九界的整合，以及護山試煉提案。
6. [Godot 環境與最小 Web 專案探針](docs/05-godot-environment-probe.md)：4.7.2 可攜式環境、Web export 與實際驗證結果。
7. [第一分鐘的視覺與九界鉤子](docs/06-first-minute-visual-direction.md)：初入洞府、天外一瞥、後期九界的介面方向與 Godot 落地邊界。可直接開啟 [互動視覺原型](docs/visual-prototype/index.html) 體驗。
8. [響應式介面與 Web 畫布規格](docs/07-responsive-ui-web-spec.md)：Godot 世界與 UI 的尺寸、抽屜、輸入及桌面／手機 Web 驗收規則。
9. [建築呈現與修行境界擴充規格](docs/08-building-presentation-and-era-expansion.md)：資源設施清單、少量場景地標、Era 擴充與自由布置的前置條件。

方向基線：Godot 4.7.2／GDScript／Compatibility／單執行緒 Web 起步；以 2D 分層美術與 2.5D 視差呈現宏觀世界。先驗證一界的玩法與畫面，再以資料內容擴展九界與宇宙。

舊版來源為 `E:\Python\test1`，已唯讀核對代表性公式、存檔與測試。九界名稱、v2 新機制、裝置效能預算及里程碑内容為可調整提案；公式移植同等性與舊存檔相容性仍需執行測試。
