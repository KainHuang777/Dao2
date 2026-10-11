# UIX-R4 建築清單圖形化 — 2026-10-10

使用者明確指定 UIX-R4；相依 R3 有界交付已完成。範圍為既有營造簿，沒有新增世界地塊或改變規則／存檔。

## 交付

- `src/presentation/building_catalog.gd`：分組圖卡網格，宽版雙欄／短版單欄，材料圖示＋擁有/需求，局部不足色，既有展開／詳情／篩選／內捲與原升級 signal。
- `src/presentation/building_card_button.gd`：快取建築縮圖、材料需求環與五個等級里程節點。環取最不足材料比例，不是建造時間；節點按實際等級上限分成五段，精確等級保留文字。滿階隱藏材料與環。
- `src/presentation/feature_navigation.gd`、`abode_hud_controller.gd`：共用建築寬度策略，上限680px；≥1100px且高≥500px可雙欄。主動顯示訊息時縮回400px單欄，保留訊息操作；自動訊息在空間不足時暫收。詳情紙面使用墨字。
- `assets/ui/buildings-painted/`：12張獨立192px RGBA手繪縮圖，含來源／SHA256 manifest與提示詞。茅屋、聚靈壇使用已存在世界資產，其餘只用於清單；Era2院落使用本套courtyard。材料沿既有resources-painted。
- 新增 `tests/uix_r4_building_cards_runner.gd` 並登錄全量；同步 navigation／responsive 的雙欄及64px命中區契約。

## 美術管線與失敗

使用 built-in ImageGen（generate2dsprite skill），原稿與逐字提示詞在 `artifacts/uix-r4/`。生成1672×941 magenta圖；初次等高切格QC因模型行距不均，8格source-edge接觸而exit1。使用Pillow決定性裁切及置中補邊成1672×1053，未重繪；再執行 generate2dsprite.py process：prop_pack、rows3、cols4、cell192、fit0.84、aligncenter、componentsall、strict-qc，12格零empty／output-edge／clamped，exit0。保存pipeline-meta.json；正式匯出排除docs/build/raw。

## 命令及證據

**最終有界來源／CLI／桌面Web DONE：全套62/62，exit0。** `tools/run_all_runners.ps1` 最終日誌 `build/uix-r4-all-final.log`；圖卡／響應式於最後字型重建後再驗亦exit0。最終包已重載截圖。人工美術／實體觸控／高DPR保持待驗。

Godot `--version`：4.7.2.stable.official.ed1daf0bf；未更新引擎。

- `--headless --path . --editor --import`：exit0，保留引擎生成uid／import。
- `--headless --path . --script res://tests/uix_r4_building_cards_runner.gd`：PASS、exit0。局部成本色、同節點刷新、上限／隱藏、雙／單欄與核心前置權限均驗證。
- 六項最終相關回歸 navigation／material_states／HUD／UI1-A／UI1-B／scenery_UI：exit0（最後紙面墨字修正後的全套結果另見下方）。
- 第一次全量在responsive舊400px上限斷言停止，exit1；獨立navigation也因舊訊息常顯斷言exit1。實作訊息主動開啟時單欄，更新新契約，navigation重跑exit0。未將失敗命令視為成功。
- `--headless --path . --export-release Web build/web/index.html`、`node tools/prepare_web_compression.mjs build/web`：最終exit0。
- `python tools/island_preview_server.py --port 48218 --normal-build --gzip`：隔離origin，正常新存檔；使用Play，不使用Seed。APPDATA亦採build/uix-r4-*隔離。未覆寫玩家進度。
- 字型初驗因新「擁」字缺glyph而失敗；tooltip改採現有「庫存」用語後，覆蓋集合manifest不同。執行 `tools/subset_game_fonts.py` 重建現有OFL runtime subset，再 `--check`：1831 codepoints、exit0；原完整字型不動。最後import／export／compression亦exit0，R4＋responsive於重建後再驗exit0。
- 最終PCK SHA256：`425AACE65614C2AD62BE43B38D11387913D2B8A33DF8902767923FAD94392AFB`。IAB已捕獲warn/error為空；不代表CLI退出警告已解決。

真實IAB滑鼠：採集20點靈氣→卡片建造→庫存扣到0／茅屋1階；採集升級所需→實付升至2階／解鎖聚靈壇與木屋。重載顯示2階，離線按既有規則結算。寬版1280×720雙欄、844×390及800×360單欄內捲、展開／詳情／收起、旋轉提示及恢复均以截圖記錄。測試尺寸是CSS viewport，不等於實體裝置。

已有Font RID／CanvasItem／ObjectDB／資源退出警告；不當成乾淨退出日誌。全量故障注入的broken/corrupt JSON為測試情境。

## 限制與下一步

人工美術接受、實體觸控／高DPR仍待驗；沒有重跑已接受的FPS／保存故障矩陣或暫緩冷啟動。不承諾全量大數相容；就地成本文字使用AmountCompat比較、有限量兩位小數與完整tooltip。

本階段完成後依Context Guard交接；下一New Chat收R4美術回饋，再界定UIX-R5其他頁面套用，不能在本輪直接擴至Era4–12。

驗收頁已關閉、viewport override已reset；48218伺服器主動Ctrl+C收尾exit1（正常中止）。伺服器favicon404不影響資源／遊戲載入。未commit／push或修改既有玩家origin。
