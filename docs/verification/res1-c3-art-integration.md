# RES1-C3 首批正式美術與正常版接入

2026-10-04。實作與本輪 CLI／桌面瀏覽器交付完成，**玩家美術／節奏驗收待實玩，RES1-C 整體仍 IN_PROGRESS**。本輪依使用者新指示先做正式資產及正常版接入，覆蓋 C2-R1 的預覽限定／先效能順序；沒有把原效能失敗改記為通過。

## 交付與邊界

- 祖島、青木島、玄礦島是首段築基切片。產品入口稱「空島」。[擴充與考據](../15-island-expansion-and-art-direction.md)記錄 30+ 島容量方向、36 島盤點草案及「多產地共用有限材料鏈」；目前只有首批三島可玩。
- 四張獨立透明 PNG：兩個 foundation 島體＋兩個產業地標。兩张 dressed reference 只供設計，沒有拿整幅概念圖作 runtime 世界。內建 image_gen 共六次生成，提示詞、來源、尺寸、hash、alpha 與切層／放置契約在 `assets/abode/res1c3/manifest.json` 和六份 `.prompt.txt`。沒有下載或重用外部遊戲圖。
- 正常 `living_abode` 初始化附掛 IslandProgression／processing_catalog；ContentLoader 基礎 manifest 仍維持原內容，純規則測試可獨立選擇內容。正常 Web 使用原 `dao2_saves` namespace；測試 preset 仍使用 `dao2_islands_preview`。
- 舊檔載入不自動改造經濟。築基後「經營 → 空島 → 保留原檔並啟用空島」沿用源檔保存、`save_before_islands` 歸檔核驗、候選提交及失敗重試。每島開拓費為祖島靈木20＋下品靈石10；祖業不搬移、不重複計產。
- 新地標開拓後顯示；島面點擊及「管理此島」進同一管理頁。相機依實際尺寸重新取景，短橫向島名為一行。展示不發放收益。

## 命令與結果

引擎：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`。

| 命令 | 結果與證據 |
| --- | --- |
| Godot `--headless --path . --editor --quit` | exit 0，六張 PNG import；`artifacts/res1-c3-import.log` |
| `python tools/res1c3_asset_audit.py` | PASS：6 RGBA、1536×1024、透明與實心像素、非空提示詞、hash；4 runtime、2 reference-only |
| `tools/run_all_runners.ps1` | 最終 50／50 PASS、exit 0；`artifacts/res1-c3-all-runners.log`。導航／呈現回歸改為計入正式島管理頁，而非只計舊靈界彈窗 |
| Godot `--headless --path . --script tests/res1c2_world_runner.gd` | 正常版 22 checks PASS、exit 0；`artifacts/res1-c3-world.log`。無預覽開關、舊檔不自動啟用、PNG地標、50次切島、命中路由、兩版型、摘要關閉、原地 resize 重新取景 |
| Godot `--headless --path . --export-release Web build/web/index.html` | exit 0；`artifacts/res1-c3-web-export.log`；正常版包中四張新runtime圖，排除 SVG 舊候選與 dressed reference |
| Godot `--headless --path . --export-release IslandProgressionTest build/island-preview/index.html` | exit 0；`artifacts/res1-c3-preview-export.log`；預覽版同樣使用新圖 |
| Godot `--script tools/res1c2_review_fixture.gd -- --unopened` | PASS：只重封築基來源檔 UTC，state 一致；`artifacts/res1-c3-unopened-fixture.json` |
| Godot `--script tools/res1c2_review_fixture.gd` | PASS：雙鏈試玩檔只更新UTC／save_id，沒有送資源；`artifacts/res1-c3-review-fixture.log` |
| `python tools/island_preview_server.py --port 4206 --normal-build --unopened-fixture` | HTTP 正常；正式匯出在獨立測試 origin 完成啟用／開拓／重載／精煉；此驗證服務驗完停止 |
| `python tools/island_preview_server.py --port 4207 --normal-build --review-fixture` | 本輪交付試玩入口，已有雙鏈與航線；獨立 origin，不讀其他 origin 玩家進度 |
| `git diff --check` | exit 0；只見工作區既有 LF／CRLF 提示，沒有空白錯誤 |

world runner 退出時仍有 TextServer font／CanvasItem／ObjectDB 資源清理警告（最終 8 objects、1 resource），雖然 22 checks／exit 0 通過，不能將其寫成完全無警告。50次切島 node count 有界不代表 Web／GPU 長時間記憶體已驗完。

## 真實瀏覽器操作

Codex IAB，正常 Web export，獨立 `127.0.0.1:4206` origin，使用命令走出的築基 fixture；不使用 Debug，不改玩家進度。

1. 1280×720 關閉離線摘要 → 經營 → 空島；可看到原檔／開拓／輪迴政策及後續島群提示。
2. 點「保留原檔並啟用空島」顯示「操作完成，已保存」；青木島開拓前可看費用，點開拓由祖島扣20木／10石，再前往世界；木作坊作独立地標落在清理區。
3. 切玄礦島時未開拓只顯島體；管理 → 開拓 → 前往世界，新增礦口與爐房。重整遊戲後兩島開拓保留，沒有再次要求啟用。
4. 844×390 進玄礦島，島體／地標與單行底列可見；仍在島上直接切回1280×720，無須重進島，恢復桌面取景。初版切尺寸保留舊倍率遮擋的問題已修正並重驗。
5. 點玄礦島島面進同一管理頁；點「持續製作」正常啟動、扣玄銅10／石5，10秒批次結算，後續實際看到銅精19與進行中預留1。此輪不重宣稱未實測的觸控／DPR2或3。

![正常版啟用政策](E:/WORK/Dao2/docs/verification/artifacts/res1-c3-normal-activation.jpg)
![青木島實際分層世界](E:/WORK/Dao2/docs/verification/artifacts/res1-c3-wood-desktop.jpg)
![玄礦島實際分層世界](E:/WORK/Dao2/docs/verification/artifacts/res1-c3-ore-desktop.jpg)
![玄礦島短橫向](E:/WORK/Dao2/docs/verification/artifacts/res1-c3-ore-short.jpg)
![正常版精煉](E:/WORK/Dao2/docs/verification/artifacts/res1-c3-normal-refining.jpg)

## 玩家驗收方式與下一步

原正常入口 `http://127.0.0.1:4175/index.html` 已確認 HTTP200，刷新載入最新匯出；正常進度到築基後依上述啟用／開拓流程。快速看美術／加工：`http://127.0.0.1:4207/launcher` 已載入可試玩檔；已有進度時按「開啟隔離遊戲」，工具拒絕覆寫。

驗收看兩岛是否可辨識、屋頂／地基是否一致、短畫面是否能看清操作，以及四條航線（青木→玄礦木、玄礦→青木石、靈材／銅精回祖島）與持續加工的節奏。靈材、銅精回祖島後用於工坊／倉儲／運力升階，有實際消耗。

下一個大型工作仍為 **C2-PERF＋玩家驗收**：原量測包體／冷啟動／幀時間未達預算，裝置／高DPR／自然背景凍結與長期記憶體待補。本輪未重做效能測量，不把舊量測當新PNG版成績；第四島與30+內容需後續契約與逐批驗收，尚未開始。依 Context Guard 在 New Chat 接續大型工作。
