# ISLAND1 獨立素材來源與製作

2026-10-03；使用 generate2dsprite 與 imagegen 技能，所有原始美術透過內建 `image_gen` 生成；沒有外部下載素材、CLI 生圖或程式代畫。四份完整提示詞存於各素材目錄的 `prompt-used.txt`，原始生成圖保留為 `raw.png`。

| 名稱 | 原始生成檔 ID | 正式 Godot 資產 | 用途／尺寸 |
| --- | --- | --- | --- |
| 築基小院 | exec-a5e7675f-42fb-442a-b6f6-5bc08e18d1bf.png | assets/abode/island1/courtyard.png | 512²；hut 在 Era >= 2 的獨立外觀 |
| 靈木萌枝 | exec-e1ca1f79-9d47-4520-99f2-99f0fdb39ae8.png | assets/abode/island1/wood.png | 256²；靈木批次採收物件 |
| 靈草花簇 | exec-ab0c57ce-3bcb-4c9b-9fe6-312d91f7aa16.png | assets/abode/island1/herb.png | 256²；靈草批次採收物件 |
| 靈石露頭 | exec-e1b20346-2fbb-430b-b43b-a38893e10b4c.png | assets/abode/island1/stone.png | 256²；下品靈石批次採收物件 |

參考來源為本專案既有 `assets/abode/terrain.png`（風格、光線、島面透視），小院另參考 `hut.png`（相同鏡頭、屋形）。這些是視覺參考，不是將島面背景切下當新物件；每張生成圖只含一件完整物件。生成結果依 OpenAI 服務之輸出使用條件使用，沒有新增第三方素材授權；既有參考素材原來源／授權仍依原專案美術紀錄，不能由本記錄推定第三方商用權。

處理器：已安裝技能的 `generate2dsprite.py process`；僅做色鍵去背、抽出單格、縮放／對齊與 QC。參數：target asset、mode single、rows/cols 1/1、align bottom、fit_scale 小院 0.90／小景 0.86、component all、min_component_area 20、threshold 180、edge_threshold 220、edge_clean_depth 6、strict_qc。初稿預設去背邊緣有粉色雜點，調整色鍵清理後重新檢視。

每項 `processed/pipeline-meta.json` 保留參數、錨點、bbox 與 QC：四項皆無空幀、來源／輸出邊緣碰觸或 paste clamp。單張透明 PNG 直接接 Sprite2D；沒有動畫格或將整幅概念圖當可互動場景。小院與小景各為獨立層；地形、角色、飛劍／採收文字回饋仍由各自 Godot 節點呈現。正式資產來源 hash 見 `asset-manifest.json`。

QC 無裁切只代表素材技術檢查；最終使用者美術放行仍待取得。八張 Godot 實際構圖及 Web 鼠標紀錄見 [驗收](../../verification/island-scenery.md)。
