# OpenCode：羈絆終章 CG 接入交接

使用者分工：Codex 製作三張 CG，其餘程式工作由 OpenCode 處理。本文件是本地交接，未透過工具發送訊息。

先讀 [正式狀態](../development-status.md#maid-art-bond-cg)、[manifest](../maid-art/bond-cg-manifest-r1.json)、[acceptance](../maid-art/bond-cg-acceptance-r1.json)。使用者於 2026-11-01 明確表示「三張羈絆終章 CG 接受」，三張新圖已各自獲得本輪 ACCEPTED；遊戲接入仍由 OpenCode 處理。

| 角色／第三章 | 已存專案素材 |
| --- | --- |
| 青蘅／前世燈火 | `assets/characters/qingheng/bond-lamplight-r1.png` |
| 糯美子／劍鳴舊世 | `assets/characters/nuomeizi/bond-sword-rain-r1.png` |
| 丹霞／丹心照夜 | `assets/characters/danxia/bond-night-vigil-r1.png` |

接入要求：

1. 新圖美術已接受，按 docs/49 第三章既有章節旗標連接回憶／重播；請自行檢查目前程式，本文不假定 CG 解鎖與回憶接線已完成。
2. 圖片都是單層 RGB 1672×941，2560×1440 為未達原生尺寸的製作目標，無拆層。完整 contain，不用 cover 裁掉頭飾、劍尖或右側劍鞘／流蘇；狹窄版型以完整看圖保留內容，不拉伸。
3. 圖片不帶 UI／台詞，文字與操作由既有 Godot 元件呈現；接入前必讀 docs/07、docs/19。只載當前所需 CG，不把三張加進常駐預載。
4. 重播不得發收益、改庫存或重領章節；保存與遷移沿用現有契約。若變更核心，依依賴選 L1／L2，完成 UI 功能後使用含本次來源的包做一次桌面瀏覽器 1280×720 抽驗。
5. 提示詞、兩輪局部修訂、參照 hash、來源／授權、全部最終 PNG SHA256 都在 `docs/maid-art/bond-cg-*.json`。既有角色 manifest 不因新圖而覆寫；既有使用者變更須保留。

本輪最終圖／檢查結果與未通過項只在正式狀態頁記錄。不要把素材已存放當成遊戲已接入。
