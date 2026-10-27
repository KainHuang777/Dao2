# 三島世界美術候選

`review.png` 為分層合成比較圖；`deep-preview.png`、`ancient-preview.png`、`void-preview.png` 可分島檢視。這些是預覽，不能作為正式可互動世界完成的證據。

六張候選 PNG 在 `candidates/`，生成原圖在 `originals/`；每次完整手寫提示詞為同名 `.prompt.txt`。`ancient_landmark.png` 初稿保留作歷史，選用薄底的 `ancient_landmark-v2.png`。`manifest.json` 記錄來源、原圖／候選 hash、透明邊界、合成位置與 PENDING 接受狀態。候選僅增加四邊64px透明安全邊，不改原像素；預覽才等比例縮放。

| 島 | 境界 | 島體 | 開拓後地標 | 現有供給 |
| --- | --- | --- | --- | --- |
| 寒銀 `deep` | Era4 元嬰 | 霜藍分層礦岩 | 木架礦口／吊籃 | 精鐵、秘銀、寒鐵 |
| 古藥 `ancient` | Era5 化神 | 苔綠沃土／垂根 | 古樹／竹棚／藥圃 | 千年靈草 |
| 太虛 `void` | Era6 煉虛 | 靛灰裂岩／微紫礦隙 | 石柱遺跡／虛華石盆 | 虛空精華 |

## 接入契約（待美術接受後實作）

- 沿 `src/presentation/island_world.gd` 的 Godot Node2D／獨立 Sprite2D／透明像素地標命中；島體與地標不得合併成唯一正式貼圖。此遊戲無島上行走，不新增角色碰撞系統。
- 既有四島入口保留；新三島依 Era4／5／6門檻與正式供給版本顯示，需分組或選單避免七島按鈕擠滿短橫式。沿共用紙面、字型、44px命中、canonical路由；不新增正式 HTML 核心。
- 未開拓不顯示地標；世界入口與管理選島雙向一致。地標導向當島管理，不能讀取不存在的 `IslandProgression.RECIPES[deep/ancient/void]`，也不能虛構工坊。
- 貨運讀正式 supply catalog 的 routes/trips，不能只迭代 `IslandEconomy.ROUTES` 舊七線；各新航線需有不同的世界端點，不能落回祖島零座標。只顯示實際正貨量，動畫不發收益。
- 遠島貼圖延後載入，輪迴或舊版本回退到祖島；隱藏遠景不接收命中。維持開拓、材料、RNG與保存規則。
- 下一階段 L1 精選世界／供給UI／導航／響應式依賴，先 `-List`；L2領域與1280×720桌面Web抽驗。本候選階段沒有觸發L3或候選Web包。

來源為內建 OpenAI image_gen；只使用本專案圖片作風格參考，未複製第三方作品，未宣稱取得第三方商用授權。`.gdignore` 防止原圖與審稿資產進入Godot資源匯入；接受後再將選定資產接入runtime目錄。
