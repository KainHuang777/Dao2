# UIX-R4-F5：固定建築材料排列

2026-10-16。來源／CLI／原生渲染已交付；Web實際互動及人工／實體觸控／高DPR待驗，整體 IN_PROGRESS。

使用者指出營造簿材料隨庫存文字長短在橫排與兩行間切換。相依R4-F3卡片已存在，本輪有界修正為材料VBox：每種資源固定一行，保留ICON＋庫存／需求、兩位小數格式、缺料色、原建築雙欄與動作。不修改經濟、保存版本、玩家進度或資產。

修改：src/presentation/building_catalog.gd、tests/uix_r4_building_cards_runner.gd、tools/uix_r4f5_preview.gd（及.uid）、docs/19-ui-ux-guidelines.md、ROADMAP.md、docs/development-status.md、updata.txt與本紀錄。開工git status乾淨。Web export自動生成其他歷史證據PNG的未追蹤.import已精確清除，不變更原證據PNG。

驗證環境：Windows／本機Godot 4.7.2.stable.official.ed1daf0bf／Compatibility；APPDATA隔離在build/uix-r4-f5-{user,tests,export}。

- `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，同版。
- `--headless --path . --script res://tests/<name>_runner.gd`：uix_r4_building_cards、ui_material_states、m2d_responsive_ui、feature_navigation四項皆exit0。新增延遲容器幾何回歸：清單寬680／768／724／352，庫存0→11.96→999.99→0→10000.25→1，材料固定各一行、位置與卡片尺寸不變、材料仍包含在卡框內。未重跑全量。
- `--path . --script res://tools/uix_r4f5_preview.gd`：exit0；1280×720、844×390、800×360各輸出庫存0／999.99畫面，共六張，原生渲染檢查保持直排。直接設定隔離場景fixture不代表玩家正常遊玩或瀏覽器命中證據。
- `--headless --path . --export-release Web build/web/index.html`：exit0；`node tools/prepare_web_compression.mjs build/web`：exit0，一般Web包已更新。
- 首次未隔離APPDATA的卡片runner exit0，但有user://logs寫入失敗；後續隔離重跑無該錯誤。既有Font RID／CanvasItem／ObjectDB退出診斷保留，不能稱零錯誤日誌。
- `python tools/web_static_server.py --port 48865 --directory build/web`成功啟動；IAB開啟該隔離origin回報`net::ERR_CONNECTION_TIMED_OUT`，未進入可互動畫面，不宣稱Web通過。測試服務以Ctrl+C停止（exit1為主動終止），未操作玩家origin。

日誌／六張原生PNG：[證據目錄](artifacts/uix-r4-f5/)。

待驗步驟：瀏覽器重載新版，開營造簿並觀察採集／建造扣料前後；在1280×720、844×390、800×360檢查每項資源固定一行、清單內捲與關閉可操作。原生與CLI不代替實體觸控／高DPR。下一步收本輪視覺回饋或補Web驗收；大型下一任務用New Chat，不重做已放行FPS或暫緩冷啟動。
