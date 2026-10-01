# 淚佛背景 v6：中央可視區構圖

日期：2026-09-28；任務：M2-D-R2 背景構圖修訂。

- 編輯來源：`assets/abode/sky_tearfall_island_v5.png`；保留原圖，v6 是新資產。
- 工具：Codex 內建 imagegen 編輯模式，以 v5 作為唯一輸入圖；未使用 API／CLI fallback。
- 成品：`assets/abode/sky_tearfall_island_v6.png`，1672×941，2,617,158 bytes。
- SHA-256：`893242A8E6C294F3B76DEB5BDA1B16EB6BBE8363E13D77735691D9C99370CFF1`。
- 修改目的：將完整淚佛浮島自然重構到畫面約 39% 寬處；左側新增連續雲海與遠方浮山，填滿 HUD 後方畫面，避免 shader 越界 clamp 造成邊緣像素拉伸。
- 保留項目：夕照雲海、佛首石雕、雙眼瀑布、苔石浮島、多層落瀑及右側遠山；沒有加入遊戲 UI、前景洞府島或文字。
- 遊戲使用：`living_abode.gd` 載入 v6；`tearfall_sky.gdshader` 將瀑布動態遮罩移至新版眼下水路。v5 留在來源庫且從 Web Release 排除。
- 提示詞：見同目錄 `sky-tearfall-island-v6.prompt.txt`。
- 用途／授權：Dao2 正式遊戲遠景背景；由內建 imagegen 依本專案 v5 資產編修，適用服務條款。原 v5 的來源與提示詞另存，不改變其授權記錄。
- 目視：imagegen 產出後已檢查全幅圖，左側為自然雲海與遠山、沒有拉伸條帶；遊戲 Web 實際合成視覺待瀏覽器工具恢復後確認。
