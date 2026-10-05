# 原生特效資源來源

2026-10-03，M2-D-FX3。此目錄由本專案原創 Shader／Godot 程式化資源組成，未複製第三方特效庫的程式、貼圖或模型。

| 檔案 | 用途與層級 |
| --- | --- |
| sword_emission.gdshader | 飛劍 Sprite2D 的發光邊緣與流光；不更改原劍圖 |
| spirit_ring.gdshader | 以極座標生成小光環及突破上下陣圈，透明加色合成 |
| tribulation_lightning.gdshader | 固定 seed 的分段噪聲雷電、光芯與柔光層，最多六條 |
| title_glow.gdshader | 題字獨立透明 SubViewport 的 25 次取樣 Gaussian 光暈；不讀整幅畫面或字型 atlas |
| spark.tres | 32×32 GradientTexture2D 光點，全部粒子共用；没有外部圖片來源 |

資產是即時計算的圖層，不需 bitmap 提示詞或切圖。既有 `assets/abode/sword.png` 的來源紀錄沿用 `docs/abode-art/`，本輪未重新生成它。

技術與庫評估、低特效、預算及驗收邊界見 [FX3 紀錄](../../docs/verification/native-vfx.md)。原創資源按專案授權政策處理，不能把參考庫的 MIT 標章當作本專案授權或其他庫美術的授權。
