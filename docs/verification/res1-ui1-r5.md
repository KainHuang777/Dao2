# RES1-UI1-R5：運輸圖形化與簡化

2026-10-09，**DONE（有界呈現修訂／桌面驗證）**。依使用者要求參考本次製造圖形與簡化，同步處理運輸。相依 UI1-B／製造 R4 已完成；七航線、來源／目的物品框、實際庫存／載貨／倒數／進度、設定與原有命令回歸為本輪 DoD。最終美術接受、實機觸控／高 DPR 仍待驗，完整 UI1-C／C／D 不提升。

## 交付

- `src/presentation/island_transport_panel.gd`：清單與詳情重用 R4 的 `recipe_material_tile.gd`，兩端同貨種手繪 ICON＋可用庫存＋島名，以箭頭連接；来源灰青、目的青玉，真正 NO_SURPLUS 為朱紅，補足後恢復。未開拓／未啟用顯示「—」，避免冒充已量測零庫存。大數縮寫，完整可用量／保留／餘貨／目標／容量預留與空間保留 tooltip 及設定資訊。
- 寬式兩欄航線卡；短橫式單欄，物品格與狀態／操作並排。清單保留物品名稱與實際載貨、到達秒數；進度直接讀當趟 `remaining`，沒有用動畫決定到貨。停航中的當趟仍有倒數與進度，詳情新增同一命令的啟停按鈕。
- 保留量／目標在設定頁寬式並排；清單政策長句移入設定 tooltip。草稿在標題標「草稿」，寬式另有完整說明，短式透過篩選 tooltip 保留說明。短版成功回饋暫放固定標題「已保存」，完整內容可讀 tooltip，避免擠掉首卡；保存失敗訊息／重試不收起。
- `tests/res1_ui1b_runner.gd`：追加貨種／端點／庫存、缺貨恢復、實際在途進度、未知庫存、四尺寸卡片邊界與短版收據／保存失敗檢查。原七航線啟停、草稿、成本、到貨／去重、來源定位與保存重試仍測。
- 新增 `tools/res1_ui1r5_preview.gd`／Godot 生成 UID、隔離 review fixture、12 張原生 PNG、9 張 Web JPEG 及本驗收。preview 只重置 `user://res1_ui1r5_preview`；測試只重置 `user://res1_ui1b_runner`，不覆寫玩家資料。
- 既有 R3 的 16 張手繪圖重用，[來源／prompt／授權](../../assets/ui/resources-painted/manifest.json)保持；框線及箭頭為既有 Godot 元件，沒有新外部圖形資產。經濟／規則／保存 schema 未改。

## 命令與結果

引擎為 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`；Python／Node 使用 Codex bundled runtime。需 user:// 寫入的 Runner／preview 按專案授權直接經正常提升執行，不重複嘗試受限玩家路徑。

| 命令 | 本輪結果／紀錄 |
| --- | --- |
| Godot `--version` | exit0，`4.7.2.stable.official.ed1daf0bf` |
| Godot `--headless --path . --import` | 初次不能推導 missing 型別；顯式 bool 修復後 exit0，`artifacts/res1-ui1-r5-import-repaired.log` |
| Godot `--headless --path . --script res://tests/res1_ui1b_runner.gd` | 原版 140、圖形追加 210、最後收據修订 **220 checks／exit0**；最終 `res1-ui1-r5-final-res1_ui1b_runner.log` |
| PowerShell `tools/run_all_runners.ps1` | **56/56／exit0**，此時 B210／A207；之後只改短版收據，補跑下面三項，不將全量當輪寫成 B220。`res1-ui1-r5-all-runners.log` |
| 最終 Godot `abode_presentation_parity_runner.gd`、`m2d_responsive_ui_runner.gd` | 皆 PASS／exit0，`res1-ui1-r5-final-*.log` |
| Godot `--path . --script res://tools/res1_ui1r5_preview.gd` | 最終 exit0，12 PNG；無 OVERSIZE／新 SCRIPT ERROR，`res1-ui1-r5-native-final.log`。名義 844 捕捉時 root 實際為779×360，不能冒称原生844；1280×720／800×360實際相符，Web補驗精確844。 |
| Python `tools/subset_game_fonts.py --check` | 初稿 tooltip 加「包」需新字；改用既有字元後最後 PASS／exit0，1823 glyphs／hash保持，`res1-ui1-r5-font-check.log`；未重生成字型。 |
| Godot `--headless --path . --export-release Web build/web/index.html` | 初版／最終皆 exit0；`res1-ui1-r5-web-export-final.log` |
| Node `tools/prepare_web_compression.mjs build/web` | 最終 exit0，Brotli往返及四首 BGM companions；`res1-ui1-r5-compression-final.log` |
| Python `tools/island_preview_server.py --port 4300 --normal-build --fixture res1-ui1-r5-review.json --gzip` | 隔離 localhost 正式包服務正常；完成後 Ctrl+C 停止，exit1 是主動終止。 |
| `git diff --check -- tests/res1_ui1b_runner.gd`、Pillow 格式／尺寸檢查 | exit0；9 JPEG／12 PNG均核對。首次圖片 glob 混入 .import 引發 UnidentifiedImageError，改為 *.jpg 後通過。 |

最終 PCK SHA256：`8375f0925ccd33bc083c654513893a6d7d2cb6b5d891fc3c0f2e0cf9a6174e28`。引擎／模板未更新，Compatibility／單執行緒 Web 保持。既有 Font RID／CanvasItem／ObjectDB／resource 退出診斷保留，不稱零錯誤。一次 Windows `rg` glob 路徑錯誤改 `-g` 後正常。沒有 auto-review 拒絕。

## 真實瀏覽器

computer-use／cua_repl IAB，測試用 1380×850 browser viewport 容納既有 launcher；DOM 核對 iframe **1280×720／844×390／800×360 CSS px，DPR約1**。4300 為獨立 origin 的 `dao2_saves`；只 seed 一次命令走出的 Era3 fixture，重載用 Play，沒有讀其他 origin 的玩家進度。

1. 雙欄圖形航線、兩端庫存及島名、缺貨框、實際載貨與進度均可辨。`artifacts/res1-ui1-r5/web-routes-1280.jpg`。
2. 下品靈石設定內實際停航：載貨5／倒數6秒與「當趟仍會到貨」保留，隨後到達／收起進度。設定保留5.125／目標90，返回仍有草稿標記，回設定保留完整字串；保存後升運力10→20，仍維持停航。`web-stop-in-transit.jpg`、`web-upgrade-stopped.jpg`。快速 typeText／貼上工具在 Godot canvas 只寫入首字或無效果，核對畫面後使用每鍵80ms輸入完整字串；沒有把工具發出當作成功。
3. 844首卡完整物品格／啟停／設定；內部 wheel 到第七航線。800丹液來源紅框／數字與操作完整，不橫向溢出；設定內捲與固定返回可操作。`web-routes-844.jpg`、`web-shortage-800.jpg`。
4. 丹液來源供給實際直達丹霞精確配方，單批扣料並自然完成；回運輸顯示載貨1／6秒到達與進度，來源框恢復正常；到貨祖島丹液1，停止新出航。`web-cargo-800.jpg`。本輪不是完整新手通關或保存故障矩陣。
5. 最終包重新載入後，運力20、停航、reserve5.125、target90仍在；360×640顯示旋轉遮罩，回800恢復原下品靈石詳情，固定返回與桌面雙欄恢復。`web-reload-settings.jpg`。未把旋轉遮罩當實體觸控證據。
6. 最終800實際停航後固定標題顯示「已保存」，首卡物品格與所有動作仍完整；最後1280恢復正常。`web-receipt-final-800.jpg`、`web-final-1280.jpg`。最後 console warn/error 查詢為空；服務有favicon404，非遊戲資源。

## 交接

一般 Web 已同步；Windows 包／commit／push 未做，已有 dirty／untracked 成果保留。4300服務停止、驗收分頁關閉、browser viewport override reset；該 origin 保留三條停航與祖島丹液1，若重開只按 Play，勿 seed。

未驗：使用者最終圖形／密度接受、實體觸控／高 DPR 與完整 UI1-C 裝置清單。遵守使用者已核定 FPS 尾10秒>30／≥55佔80%政策與冷啟動暫緩；本輪不重做既有 FPS／400保存矩陣，沒有新FPS數字。英文 checkpoint置updata頂部；本階段結束，下一 New Chat 收運輸回饋或剩餘裝置，不展開 Era4。
