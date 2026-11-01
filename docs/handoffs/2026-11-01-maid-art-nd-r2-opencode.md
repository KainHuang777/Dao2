# MAID-ART-ND-R2 → OpenCode

**最新：2026-11-01 使用者「美術確認」，R2 六張美術已接受，見 [接受紀錄](../maid-art/nd-r2-acceptance.json)。現在由 OpenCode 接續正式接入，無須重問已核定畫風／體型。**

2026-11-01 最新使用者回饋覆蓋 R1：三人體態太相似；糯美子需約 20 歲嬰兒肥成年劍侍，丹霞需成熟御姐；糯美子佩劍不可看成只有劍鞘。本輪 Codex 補兩位三向設定，並修訂各自立繪及初遇 CG，遊戲接入仍交 OpenCode。

先讀 [比例設定](../maid-art/character-proportions-r2.md)、兩位目錄 README 與 `assets/characters/{nuomeizi,danxia}/manifest-r2.json`。採 R2 參照鏈：`turnaround-r2.png` → `portrait-r2.png` → `first-meeting-r2.png`，避免混用 R1 年齡／體型。R1 原檔與既有 `portrait.png`／`first-meeting.png` 保存歷史，R2 接入副本採帶版本檔名；尚未改正式程式路徑；美術接受依上方使用者明示紀錄。

- 糯美子：成年約20歲、圓頰與較短頭身，收袖短披／分片裙＋長褲／平底靴。立繪採完整出鞘劍，握持劍柄、護手、劍首、刀刃和獨立空鞘可辨，禁止回退只見劍鞘的 R1。
- 丹霞：成熟約32–35歲、長臉細長眼、高挑與較明確肩腰胯，藕紫合身長衣／梅紫外袍；青蘅保持已接受的纖柔書卷型，不在本輪重畫。
- 三向設定是角色參照合層圖，不是動畫幀、像素精確正投影或正式世界小像。身高／頭身為設計目標，不是已量測的精確數值。

接入內容沿 [R1交接](2026-11-01-maid-art-nd-opencode.md)：現有 `maid_character_panel.gd` 的按角色圖片／簡介／初遇台詞與 `maid_system.gd` 的 `art_ready` 均待接；不可把看圖接成新獎勵或放寬招募。共用布局沿 docs/07、docs/19，完整 contain 不裁劍尖／鞋／髮尾。

使用者美術接受已完成；本輪依既有指示不跑 Godot／runner／Web／瀏覽器測試，只有目視與素材檔案靜態檢查。OpenCode 的後續實作／驗收依使用者新指令與 AGENTS 辦理，不重做已完成核心／UI 階段，不宣稱 MAID-CLOSE 完成。

可手動 commit：美術修訂階段結束，整體大型仙侍任務未結束；代理未 commit／push。用新對話接續。
