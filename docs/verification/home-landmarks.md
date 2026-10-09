# ART-A1-HOME — 祖島居所、修士與聚靈壇

2026-10-07。使用者接受三核心配置並要求先完成祖島。實作／CLI與桌面Web子範圍已交付；最终人工美術、實機／高DPR與長效能仍待驗，完整ART-A1與FX3不合併標DONE。

## 最終配置與來源

沿用既有獨立美術：左側 hut（Era2起同建築換courtyard）、中央披風修士、右側 storage_lingli 聚靈壇。壇體使用既有 assets/abode/altar.png，寬250、島內腳點(290,-100)，只讀正式建築level>0；未建／輪迴空地無藍圖或隱形命中，升境不發放建築。點選壇體開同一營造詳情與Session命令，標籤只在選取時顯示。原壇圖／提示詞／處理紀錄保留，無新生成或像素修改；來源、圖層、尺寸及權利紀錄見assets/abode/home-landmarks.json。壇圖SHA256 1d7db90abe9f4bda394757f1e3e7a7f780631eea16cd4ad82614a01463f381c7。

此配置由當次使用者要求覆蓋10/3中央陣台聚靈壇方案：中央留給修士／渡劫，右平台放壇。兩個小景slot搬離壇體，保持slot ID／存檔不變；無建築自由布置、收益或schema修改。短橫式home bounds擴至775 world units；Era2+祖島短橫式導覽只保留目的島一排，移除該情境的重複祖島返回／管理按鈕及標題，遠島保留返回／管理與標題，主經營入口仍可管理祖島。

## 檔案與命令

修改 living_abode.gd、abode_building.gd、island_world.gd；living_abode、abode_scenery_ui、m3a_reincarnation_ui、island_breakthrough及res1d2_world runner增加已建／未建、點選不改狀態、短橫式壇體全入鏡、正式輪迴移除、保存重載顯示與祖島／遠島導覽差異檢查。新增home_landmarks_preview.gd／Godot UID、home-landmarks.json與本驗收。island_preview_server.py增加受限於artifacts單一JSON檔名的--fixture選項，拒絕路徑與預設fixture混用，用於獨立測試origin。

Godot4.7.2 import exit0；原生預覽exit0，1280×720及844×390建前／建後四PNG見artifacts/home-landmarks。後者logical779×360，不宣稱等於browser CSS；預覽使用已賺得fixture複本降Era作呈現診斷，不作正常新手可達證據。原生完整快照不變。

living runner與scenery UI runner exit0。全量tools/run_all_runners.ps1 54/54 PASS／exit0（最後短橫式導覽收合之前）；最後針對性世界runner 58 checks／exit0、m2d_responsive_ui runner exit0。中途compact_home型別推斷造成parse error／Nil，程序停止後改明確bool，後續兩項通過，失敗log保留。Font／CanvasItem／ObjectDB退出警告仍存在。

最後Godot --headless --path . --export-release Web build/web/index.html及node tools/prepare_web_compression.mjs build/web均exit0。一般Web PCK SHA256 823cc21ecfb41512f0c26503b4097e3e64569651fd796ec03a2b02f1a3be7731。日誌在ignored build/verification/home-landmarks。Python server py_compile及來源diff-check通過。

## 瀏覽器與限制

IAB獨立4269／normal build，載入已賺得金丹fixture後正常時間運行；本輪不使用4175玩家進度。實際滑鼠壇體→聚靈壇2階詳情→升級3階，扣34靈木、詳情／選取名稱同步3階；此為正式命令但不是從空白完整流程。畫面使用既有小院；練氣茅屋以native診斷補驗。Browser iframe一般填滿為1280×650，短橫式DOM確認844×390。重載與最終短橫式避讓結果另以下方追加為準。

下一步使用者檢視右壇大小／色調及三核心布局，再在New Chat逐島補代表地標。未commit／push；Windows包本輪未更新。商用權利／實機／DPR／長FPS既有門檻保持，不把部署包成功當作全部驗收。
最終Web追加：重載保留聚靈壇3階；844×390 resize完成後三地標全可見，目的島導覽一排位於下方，實際滑鼠點壇開3階詳情。未以resize過渡幀作最終驗收。一般版型iframe1280×650／短橫式DOM844×390；截圖在本輪工具記錄，檔案附件為native四PNG。

工具追加：sandbox Python複核曾報無法定位C:/Python314/python.exe；獲准同一已安裝Python重跑py_compile exit0，--fixture ../outside.json按預期拒絕exit2，未啟動服務或讀取外部檔案。

2026-10-07後續美術覆蓋：聚靈壇接地版v2改用altar-grounded/altar-grounded-v2.png，低矮透視／土石遮底及撤下旋轉圈；原文v1來源與檢查保留為歷史，最新見[接地修訂](altar-grounded.md)。
