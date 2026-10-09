# 聚靈壇接地修訂 v2

2026-10-07 ART-A1-HOME-GROUND。使用者回報右壇懸浮，要求以透視、土壤包邊與接合處理修正。

- Built-in image_gen precise-object-edit，transparent_background=true，單次生成；檔案altar-grounded-v2.png。未使用API金鑰／CLI或Python圖片編輯，工具輸出直接複製至專案。
- 編輯目標：assets/abode/altar.png；地面角度／材質參考：assets/abode/fx3art1/terrain.png；位置參考：docs/verification/artifacts/home-landmarks/built-1280x720.png。前版與之前預覽保留。
- 完整提示詞：prompt.txt。美術方向為約35度仰角之正交俯視（頂面橢圓約0.57比例，屬生成指引而非相機量測），減少外露底座高度，暖黃褐土石遮住最低底沿、少量苔草，接觸暗部與左上暖光。無新增角色／背景／UI。
- 透明sprite包含壇體與緊鄰土石接合裙邊；不是整島背景、另一座浮島或規則地塊。Godot沿用寬250／錨點(290,-100)，土石裙邊不另取得命中／收益。圖片alpha保留，runtime1254×1254，角落alpha0；四張隔離原生預覽見docs/verification/artifacts/altar-grounded。
- SHA256：1601d7c314e5def3f2dcec65d4568e131c222e35b2de3b6b77cb63ea144f1ed5；檔案1,990,719 bytes。Godot自動import記錄／UID保留。
- 原創AI生成／專案既有圖的衍生編輯；來源、用途、提示詞與切層保留。參考图既有第三方商用權利限制不因本次編輯獲得獨立清除。
- 本輪已接一般Web供使用者視覺審閱，實機／高DPR／長效能與最終美術驗收仍待確認。