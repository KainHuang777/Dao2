# ART-A1-HOME-GROUND — 聚靈壇透視與接地

2026-10-07，使用者回報右側壇體像懸浮，要求用3D透視理解生成角度並以泥土包邊。完成接地版美術及實際場景替換；完整ART-A1／FX3保持IN_PROGRESS，等待最終美術、裝置／長效能。

## 處理

Built-in image_gen單次透明編輯，目標altar.png，terrain.png角度／光源／材質與前版場景作參考。低矮底座、廣橢圓頂面、同左上暖光；土石與苔草遮住最低邊、貼合暗部，避免底沿整圈清楚像貼紙。輸出複製至assets/abode/altar-grounded/altar-grounded-v2.png，提示詞／來源／用途／權利與hash保存在同目錄README及prompt.txt。未Python改圖、未改整島地形、原圖保留。

living_abode.gd新增GROUNDED_ALTAR只供storage_lingli；寬250與錨點保持。abode_building.gd撤下壇面常態旋轉光圈，選取環改到貼地投影中心；同命中、建成條件／輪迴／保存不變。home_landmarks_preview.gd改輸出artifacts/altar-grounded，保留前階段圖片，增加實際texture alpha診斷。home-landmarks.json更新v2來源。

## 命令與驗證

- Godot --version：4.7.2.stable.official.ed1daf0bf。
- Godot --headless --path . --editor --import：exit0；初次sandbox user://診斷保留。
- Godot --path . --script res://tools/home_landmarks_preview.gd：隔離user://原生兩橫式建前／建後，exit0且已比較前版／新版實際場景。native844×390對應logical779×360，非browser CSS證據。
- 最後QC初次錯用Image.has_alpha造成診斷腳本runtime error，停止後改為從import Texture.get_image()檢查corner alpha，重跑exit0；runtime1254×1254、used_rect(0,21,1244,1233)、corner_alpha0.0，未冒稱严格全邊空白margin通過。失敗log保留。
- 四項隔離runner living_abode／abode_scenery_ui／m3a_reincarnation_ui／res1d2_world全部exit0，world58 checks。涵蓋點選不改規則、短橫式全壇入鏡、輪迴移除及世界切換。來源未動規則／保存，未重跑全量54；前輪54不計為本輪結果。
- Godot Web release至build/web與node prepare_web_compression.mjs build/web均exit0，BGM companions完整，PCK SHA256 c9447c64eee30375d4be31ba0b32bd91a26bafed3d4abe948e2485a2549f9a95。
- diff-check通過。日誌位於ignored build/verification/altar-grounded。既有Font／CanvasItem／ObjectDB退出警告仍存在。

IAB獨立4269重載既有隔離進度，實際看到低矮土石包邊新版，正常橫式滑鼠點壇開同一聚靈壇3階詳情。未存取4175玩家資料。短橫式結果以下方追加為準；本輪無實體觸控／高DPR或FPS長觀測。

下一步使用者檢視接地感／泥土包邊，再New Chat逐島代表地標。一般Web包更新，Windows未匯出；未commit／push，其他dirty成果保留。
最終Web追加：DOM按既有launcher設定844×390，穩定resize後三核心全可見，新壇體最低邊呈土石／苔草接合，原祖島目的島單排導覽保留；本輪browser只點選詳情，不再次升級。
