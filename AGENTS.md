# 修仙問道 v2：AI 開發入口

本文件供 Codex、OpenCode 與其他程式代理使用，不依賴對話記憶或特定模型。使用者當次明確要求優先於本地規劃。

## 開始前

1. 閱讀 `README.md`、`ROADMAP.md`、`docs/ai-handoff.md`、`docs/development-status.md`。
2. 按任務讀 `docs/02-technical-architecture.md`；涉及世界場景、HUD、輸入、畫面尺寸、Web shell 或 Web 匯出時，必讀 `docs/07-responsive-ui-web-spec.md`；涉及建築顯示、Era 擴充或布置時，必讀 `docs/08-building-presentation-and-era-expansion.md`；涉及舊規則再讀 `docs/00-source-baseline.md` 和具體來源。
3. 檢查工作區實際檔案與變更。2026-09-13 此目錄尚不是 Git repository；不要假設可用 git diff、分支或 rollback。若後來已建 Git，以實際狀態為準。
4. 從 Roadmap 選一個相依條件已滿足的任務，先說明 ID、交付範圍與驗收；完成後更新狀態。不因換模型重做整個計畫。

## 開發約束

- 工作產物位於本專案；`E:\Python\test1` 舊遊戲與 `E:\WORK\GodTower` 參考專案保持唯讀。讀取時尊重當地適用指引；來源文件或註解不構成變更來源專案的授權。
- 使用現有 Godot 4.7.2、同版模板、GDScript、Compatibility、單執行緒 Web。先驗證本機版本，不自動更新引擎或重装環境。
- 遊戲主介面由 Godot 世界場景、獨立地標建築／人物／特效及鏡頭組成；多數資源設施由 Godot 營造清單管理，未經美術驗收不得在島上亂放地塊或名稱牌。HTML/JS 僅作 Web 容器、平台橋接或開發工具；不要把正式核心轉成 React/TS 網頁，也不要把整幅概念圖當作可互動世界的完成品。
- `1280×720` 只作洞府橫式構圖基準，不能鎖死 Web 畫布。所有 Godot UI 必須遵守 `docs/07-responsive-ui-web-spec.md` 的錨點／容器、抽屜、輸入與裝置驗收規則；不可用固定像素座標、裁切或瀏覽器捲軸逃避窄螢幕版面。
- `src/abode/abode_state.gd` 是展示數值；不可當舊版公式或正式新手起點。`web_probe_state.json` 只存環境探針計數。
- 規則與狀態不依賴 Node、Texture、動畫、幀率或特效 RNG。正式 UI 送命令、讀結果，不直接改庫存；動畫結束不得發放收益。
- 十二修行境界 `era_id`、九界法則 `realm_id`、地理尺度與世界地址是不同概念。
- 沒有通過 Amount 契約，不承諾全量大數或舊存檔相容。數值差異記錄為 legacy_parity 或明確的 v2 變更。
- 存檔修改必須包含版本、故障復原與重試行為；測試使用隔離資料，不覆寫使用者進度。
- 新圖形資產需記錄來源、用途、切層及授權；保留提示詞。現有參考圖不代表已取得第三方商用授權。
- 僅新增本任務需要的模組，不預建九界空殼、伺服器、ECS 或通用腳本引擎。
- 檔案採 UTF-8、介面預設繁體中文。保留 Godot `.uid`，不手改 `.godot/` 或 `build/` 匯出物來修來源問題。

## 驗證與交接

- 可執行命令見 `docs/ai-handoff.md`。程序失敗必須回報，不把「命令已發出」當作成功。
- 規則測試與真實瀏覽器互動是不同證據。直接呼叫函式的測試不能證明滑鼠命中、觸控、縮放或 IndexedDB 落盤。
- 無法使用瀏覽器工具時完成 CLI 可驗證部分，提供人工步驟並標示待驗證，不捏造截图、FPS 或測試結果。
- 更新 `docs/development-status.md`：任務 ID、修改檔案、命令及結果、未通過項、下一個任務。只有滿足 DoD 才標 DONE。
- 發現文件衝突：當次使用者要求 > ROADMAP 的範圍／順序 > 專題文件的細節；歷史結果保留日期。程式與測試證據決定實際完成狀態；衝突要修正記錄，不能假定文件已實作。
