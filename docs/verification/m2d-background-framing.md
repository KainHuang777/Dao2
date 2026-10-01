# M2-D-R2｜淚佛背景常態版型取景

日期：2026-09-28

## 目標

使用者指出常態洞府 HUD 左右面板會長期遮住背景淚佛。需求是把淚佛往兩側面板之間的中央可視區移一些。

## 實作

- 先前以 UV 平移試做時，把焦點移到來源圖 x=0.28，導致越界取樣被 clamp，左邊緣像素拉成橫線；該試做已撤除，不納入最終方案。
- 新增 `assets/abode/sky_tearfall_island_v6.png`：以 v5 為底圖重新構圖，淚佛移至畫面約 x=0.39，左側補繪連續雲海與遠山，保持全幅 1672×941；v5 保留不覆寫。
- `src/abode/living_abode.gd` 改載 v6。Shader 不再用寬版越界平移；`background_focal_x` 回到安全取樣範圍，直式置中值配合新圖改為 0.39，寬版維持 0.5。
- `assets/abode/tearfall_sky.gdshader` 的眼下流水遮罩橫向跟隨新版佛首移動約 0.16；瀑布範圍與波動保留。
- `export_presets.cfg` 排除未使用 v5，Release 只打包目前使用的 v6。
- Camera2D、主島、建築世界座標與輸入命中都不變。
- `tests/m2d_responsive_ui_runner.gd` 驗證寬、橫窄、直式焦點值，以及採樣 UV 完整落在來源圖內。
- `docs/abode-art/sky-tearfall-island-v6.md` 與提示詞檔記錄資產來源、用途、授權與 SHA-256；`export_presets.cfg` 保留 v6 並排除未使用 v5。

## 前景洞府島構圖修訂（M2-D-R3）

使用者回報前景浮島遮住佛首及瀑布主體。`src/abode/living_abode.gd` 新增「洞府浮島構圖」父節點，統一變換地形、建築、靈木、飛劍、突破法陣與洞府標記：等比例縮放至 0.92，Y 軸下移 18 世界單位。未改背景焦點、HUD、相機、規則狀態或存檔；`abode_building.gd`／`abode_tree.gd` 的區域命中使用 `to_local()`，因此跟隨場景變換。`tests/living_abode_runner.gd` 點擊輸入改採節點 `to_global()` 座標，M2-D Runner 新增構圖值與命中轉換斷言。

此幅度預期讓浮島稍微讓出更多佛首／瀑布可視面積，同時保持畫面下方留白；需在實際遊戲畫面確認視覺平衡，若仍被遮擋可再依截圖調整比例或位移。

## 驗證

- Godot 4.7.2 `--headless --path . --script res://tests/m2d_responsive_ui_runner.gd`：PASS。
- `powershell -File .\tools\run_all_runners.ps1`：25/25 PASS，exit 0（含 M2-D-R3）。
- `Godot --headless --editor --path . --import --quit`：PASS；v6 PNG 匯入成功。
- `Godot --headless --path . --export-release Web build/web/index.html`：PASS，匯出檔存在。
- `git diff --check`：PASS。
- 瀏覽器視覺複查尚未完成：Computer Use kernel 啟動失敗。不能用 CLI Runner 代替畫面確認。
