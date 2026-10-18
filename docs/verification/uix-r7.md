2026-10-17 最新結案：使用者明確回覆「R7 美術接受」。UIX-R7-REINCARNATION於桌面／Web有界範圍標記DONE；最終以F3無空白槽版本為準，F1／F2技術證據沿用，下方待接受／下一輪回饋記載保留為歷史。觸控／實機延期，非當前阻擋。本次僅文件／既有log與hash核對，未重跑遊戲或改玩家資料；R8尚未開工。

# UIX-R7-REINCARNATION · 輪迴與傳承

2026-10-17後續：使用者美術回饋已實作[UIX-R7-F1](uix-r7-f1.md)：熄滅命燈、收益卡與置中主動作、展開重置詳情、壽盡主動開頁。短式保留72px主圖與收益，覆蓋下方較早撤主圖／160px桌面敘述；原技術結果保留日期，R7美術仍待接受。

2026-10-17：程式／素材／CLI／三橫式原生與桌面 Web 已交付，**IN_PROGRESS（最終美術待使用者接受）**。本輪使用者「R7開工」覆蓋此前交接中的「不開R7」；R6桌面／Web有界DONE為相依基線。下一步只收R7回饋，不於本輪展開R8。

## 交付

- 內建 ImageGen 四張獨立透明圖：輪迴盤、資源傳承、長生久視、先天道體。原圖、逐字提示及生成路徑在 `artifacts/uix-r7/generation-records.json`；runtime、來源、用途、切層及授權邊界在 `assets/ui/reincarnation-painted/manifest.json`。無第三方參考圖；沒有宣稱第三方商用授權。
- 固定貨幣／GameTab、內容內捲、固定轉世動作與頁內確認／取消；CloseSeal沿共用規範。桌面輪迴盤160px、天賦112px；短式撤主題裝飾，天賦最多80px，保存回饋出現時依可用高度縮至至少44px。成本、效果與44px動作保持可讀；完整敘述保留TIP，短式顯示當前效果。
- 本世資格／建築階數、預期道心與道證、傳承比例、保留與重置分開呈現。圖片不送命令。確認／取消是此次新增的呈現防誤觸，核心資格／成本／收益不變。
- 天賦參悟送原Session命令，保存失敗顯示重試；重試只保存，不再參悟。一般保存與背景恢復均清除過期錯誤。
- 實際Web發現並修復舊結算世次少一世、導覽蓋到結算卡及跳過按鈕被拉成整條的問題。結算紙底深墨；演出z=100且移到HUD最後攔截輸入；第一輪轉世顯示第2世。演出及跳過不發獎。
- 一般Web已同步；新增獨立R7Acceptance preset、feature main scene與僅限本機的隔離服務工具。沒有修改規則、解鎖、RNG、schema或玩家存檔，沒有commit/push。

主要修改：`src/presentation/reincarnation_panel.gd`、`reincarnation_sequence.gd`、`abode_modal_manager.gd`；`src/abode/living_abode.gd`僅追加R7保存恢復與演出輸入順序，保留原有dirty修改。另有R7素材／工具／fixture／專項測試、既有輪迴UI測試、export設定、runtime字型清單及交接文件。

## CLI 與原生證據

引擎：Godot **4.7.2.stable.official.ed1daf0bf**，Compatibility。APPDATA隔離至`build/uix-r7-tests`／`build/uix-r7-preview`，各runner亦有專用user資料夾。

| 命令／工具 | 實際結果 |
| --- | --- |
| Godot `--version`、`--headless --path . --import` | exit0；未更新引擎或模板 |
| `--headless --path . --script res://tests/m3a_reincarnation_runner.gd` | exit0；資格、獎勵、繼承／清除、保存roundtrip |
| 同上 `tests/m3a_reincarnation_ui_runner.gd` | 最終exit0；真Session天賦付費、壽盡入口、確認取消、轉世／新世、演出跳過／相機解鎖、第二世標示與輸入順序 |
| 同上 `tests/uix_r7_reincarnation_ui_runner.gd` | **55 checks，failed=false，exit0**；拒寫／仍拒寫／恢復不重扣、磁碟重載、背景恢復、滿級、三尺寸圖卡／44px／內捲／確認邊界 |
| `feature_navigation`、`m2d_responsive_ui`、`uix_r1_components` runners | 各exit0 |
| `uix_r6_achievement_ui_runner.gd` | 221 checks，failed=false，exit0；保存共用接線回歸 |
| `--path . --script res://tools/uix_r7_preview.gd` | 最終exit0；1280×720、844×390、800×360各結算／天賦／確認／拒寫／演出結果，共15張PNG |
| bundled Python `tools/uix_r7_assets.py` | exit0；四圖alpha、完整邊界配適、manifest及預覽 |
| bundled Python `tools/subset_game_fonts.py`，再`--check` | 最終均exit0；初次check發現字元／corpus不符，已重建衍生字型與清單，原始字型未變 |
| Godot `--export-release R7Acceptance build/r7-acceptance/index.html` 與 `--export-release Web build/web/index.html` | 最終均exit0 |
| bundled Node `tools/prepare_web_compression.mjs build/r7-acceptance`／`build/web` | 最終均exit0；壓縮roundtrip與音樂companions |

完整log、原生圖及Web JPG在`docs/verification/artifacts/uix-r7/`。未跑全量runner；此次僅跑受影響回歸。既有Font/CanvasItem/ObjectDB退出診斷仍有，不能稱零錯誤log。中間匯出因瀏覽器JPEG誤用.png副檔名出現證據圖import錯誤；已按檔頭改正本輪12張為.jpg，最終兩匯出沒有該錯誤或SCRIPT ERROR。精確移除本輪新生成、未追蹤的205份驗收圖.import sidecar，清單留檔；未刪來源圖或.uid。

## 桌面 Web 實際互動

工具：CUA in-app browser，滑鼠；CSS 1280×720、844×390、800×360，DPR約1。初次sandbox HTTP逾時，停止同一服務後以host執行loopback服務成功；舊錯誤頁無法重新綁定，未繞過URL政策。只有本輪服務48770／48771；不接觸玩家4306／4175。

這是明示fixture的UI／保存驗收，**不是自然修行流程證據**。fixture僅在該origin首次啟動準備道心50、蓮臺1並保存標記；重載沿原進度，沒有反覆seed。後續參悟、取消、轉世及入世皆真實滑鼠。

1. `127.0.0.1:48770`：桌面檢查圖卡，真參悟資源傳承0→1，道心50→45；正常重載保留45／一階及10%傳承預覽。844／800切頁、捲到第三天賦、固定返回與分頁；800確認／取消保留第一世，結算及重置全文可內捲閱讀，無body捲軸。
2. 同origin `/fault.html`：拒寫後真參悟1→2，道心45→35；全屏保存阻擋、仍拒寫重試、恢復儲存及重試通過。返回天賦顯示二階／35／結果已保存、頁內重試消失；正常頁重載仍35。故障console的SecurityError為刻意注入。此證據對應最初PCK `284944ea2b56218e4f5dc4af848440512029965ccc395db2917f3e5d8550bea7`。
3. 同origin確認轉世並入世，保存繼承資源20；當時發現結算世次／導覽遮擋，原圖`web-result-before-fix.jpg`保留為失敗證據，不當最終PASS。
4. `localhost:48770`獨立origin：修正後真確認轉世、結果第2世、入世與正常重載仍第2世／無蓮臺資格。PCK `c778e1d7db0af3dc8e71c153f95562d4d364fc3e1c5ac2eef1c817c25c49dfbe`。
5. **最終** `127.0.0.1:48771`：追加HUD輸入順序修復後800×360重驗確認／轉世／結果第2世／入世／重載與固定返回洞府，警告／錯誤console為空。PCK `965ea9b7c5075d7d8a44035ab5a29743c4f3e1d418d4c8c624f3574fd75083ff`。未把前版完整矩陣重新標為此hash；這版僅多出演出輸入排序，CLI已回歸。提前跳過主要以CLI明確證據驗證，Web點擊時亦可能已自然到達結算。

一般Web最終PCK：`d975f1fb00840aa763235c1874d7951c6199b696bf506fef1b5d1261e440827c`。獨立驗收版多了fixture入口，不以其hash冒充一般Web。權威Web保存為localStorage＋Web Lock；未宣稱IndexedDB證據。正常Web尚未另跑完整相同矩陣，UI本體相同，匯出成功。

## 結案範圍與接手

最終美術比例／呈現待使用者接受，故R7維持IN_PROGRESS；已完成的技術證據不重做。觸控／實機依最新政策為「延期，非當前阻擋」，不列下一任務。既有FPS／冷啟動與其他歷史缺口不在本輪重跑或提升狀態。

下一New Chat只接R7美術回饋與必要局部修訂；本輪已到Context Guard交接點，不開R8。重開隔離預覽可用 `python tools/uix_r7_server.py --port 48771`，該origin已有第二世進度；不可當新檔再次seed。若只是看美術，可看本頁原生圖與Web證據，不需改玩家進度。

收尾：本輪48770／48771服務已停止、成功測試分頁已關閉、viewport覆寫已還原；`git diff --check`、最終字型`--check`與UTF-8回讀皆通過。
