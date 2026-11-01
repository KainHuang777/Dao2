# 糯美子美術：R2 已獲美術接受

2026-11-01 依使用者回饋改約20歲成年女性、圓頰嬰兒肥、較嬌小緊實體型；補正／側／背設定與完整劍結構。R1 留作歷史，不再作最新體型基準。參見 [三人比例設定](../character-proportions-r2.md)、[OpenCode R2交接](../../handoffs/2026-11-01-maid-art-nd-r2-opencode.md)。

- `turnaround-r2.png`：三向設定、臉部近景、完整出鞘劍＋空鞘細節。
- `portrait-r2.png`：透明全身 R2，持出鞘劍，完整劍柄／護手／劍刃可辨。
- `first-meeting-r2.png`：沿 R2 人物的雲海初遇。
- 三個 `*-r2-prompt.json` 保存各圖完整提示詞；`assets/characters/nuomeizi/manifest-r2.json` 保存來源／hash／切層／靜態觀察。

2026-11-01 使用者「美術確認」，R2 三向設定、立繪與初遇 CG 已接受；[接受紀錄](../nd-r2-acceptance.json)。遊戲接入交 OpenCode。設定圖為合層參照，非動畫／精確3D藍圖。圖片依完整 contain 使用，不強拉高至與丹霞相同身材比例。

## R1 歷史交付

角色 ID：`nuomeizi`，成年劍侍。墨黑高馬尾、琥珀瞳、紅緞與古金髮飾、墨紅短披、黑白漢服及單把入鞘長劍；爽朗、自信、護短。此為沿青蘅精緻二次元畫風延伸的新角色稿，使用者美術接受仍待確認。

- `portrait-r1.png`：透明全身主立繪，人物／髮衣／佩劍合層。
- `first-meeting-r1.png`：雲海試劍初遇 CG，人物／環境合層；對話與 UI 另由 Godot 繪製。
- `prompts-r1.json`：完整提示詞與參照用途。
- `assets/characters/nuomeizi/manifest.json`：原稿／接入副本、尺寸、SHA256、來源與切層紀錄。

主立繪生成留白少於提示詞要求，接入須完整 contain，不裁髮尾、靴子或劍鞘。初遇保持同一髮色、眼色、短披與劍；裝飾細節有生成差異，不宣稱像素一致。

來源：內建 image_gen。青蘅僅作畫風參照；其上游使用者例圖作者／授權未知的限制沿用，不聲稱第三方商用授權或獨占性。未另引入外部參照圖。
