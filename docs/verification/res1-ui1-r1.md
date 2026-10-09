# RES1-UI1-R1：空島操作回饋與配方內進度

2026-10-09（Asia/Taipei）。**DONE：有界實作與桌面滑鼠驗證**。當次使用者要求插入 UI1-A/B 後的修訂；完整 UI1-C／RES1-C/D 的實體裝置與人工美術／節奏接受仍待驗。效能沿用 AGY 與使用者最新政策：近目標 ≥55 FPS 時間至少80%、最後10秒高於30 FPS；冷啟動預算暫緩常態阻擋。本輪沒有重新量FPS或冷啟動，不撤銷既有PASS。

## 發現與交付

規則與命令原本可以運作；呈現缺口是成功操作清空訊息、島選擇缺少選中樣式、製造清單上方以四組大型按鈕／進度條重複工作，以及單批自然結束文案混同停止操作。短橫式的島篩選與分类另把首張卡片擠到可視區外。

- `src/presentation/manufacturing_panel.gd`：移除上方每島大型工作列，保留一行加工／等待／閒置數及工作資源名稱。島篩選改固定標題列 OptionButton，精煉／合成同列；詳情時隱藏篩選、保留返回。每張卡片標題與動作並排，卡片內直接显示實際秒數、進度、排程切方、原料來源島與可用／需求、產出及加工地庫存。只有當前配方顯示進度，pending 配方不假裝已運作；詳情進度讀同一工作。單批或停止安排進入收尾時顯示「完成本批後閒置」，卡片提供設定，詳情不再接受無效的重複停止。短工作區的成功收據暫代總覽列，讓5秒批次開始時進度仍可見。
- `src/presentation/feature_navigation.gd`：寬 ≥1100、高 ≥500 的製造頁保留左側祖島資源三態清單，工作區依可用寬度移至右側且不重疊；短橫式依卡片與詳情核對材料。離開恢復原資源模式。開拓／升階／製造／切方／停工／航線設定提供成功收據，5秒後收起；保存失敗與重試入口持續保留，不被成功收據抹掉。
- `src/presentation/island_management_panel.gd`：島選擇有選中回饋。專業島直接顯示祖島工程庫存，升階成本逐項顯示可用量；原採集摘要保留，另可展開本島原料與產物，區分可花庫存和容量預留。展開只改呈現，不合計全世界庫存。
- `tests/res1_ui1a_runner.gd`：更新新布局斷言，追加原料來源、實際tick推進、卡片／詳情一致、完成後清除、pending不雙跑、升階／停止成功回饋與本島庫存展開；保留命令扣料、產出、拒絕與保存重試測試。
- `tools/res1_ui1r1_preview.gd`／Godot UID：新增本輪隔離三尺寸擷取；review envelope 在視覺診斷修改前輸出，只重封既有 earned Era3 source。Native 圖中的玄礦 remaining=4 覆寫是呈現診斷，不能當規則／正常玩家流程證據。

本輪沒有改規則、配方、schema、存檔版本、收益或世界美術，也未commit／push；前輪與AGY的dirty成果保持。未新增圖形資產；既有字型子集覆蓋檢查通過，不需重產。

## 參考

已查[開發者商店介紹](https://play.google.com/store/apps/details?id=com.TironiumTech.IdlePlanetMiner)；當前商店圖是宣傳圖，不能據此推定精確操作。另實際檢視[Smelting / Crafting Guide 的介面截圖](https://gameplay.tips/guides/idle-planet-miner-smelting-crafting-guide.html)：製造槽把原料／產物、進度／秒數、配方入口放在同一區。採用同區回饋的結構，不複製圖片、圖示、樣式或遊戲公式；該截圖為歷史參考，未宣稱操作了其最新版本。

## 命令與結果

引擎版本：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`，**exit0／4.7.2.stable.official.ed1daf0bf**；Compatibility與同版單執行緒Web保持。

| 命令 | 結果 |
| --- | --- |
| Godot `--headless --path . --import` | exit0；`artifacts/res1-ui1-r1-import.log` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | **56/56、exit0**；當輪A155／B140，`artifacts/res1-ui1-r1-all-runners.log` |
| Godot `--headless --path . --script res://tests/res1_ui1a_runner.gd` | 最終 **164 checks、exit0**；`artifacts/res1-ui1-r1-runner-final.log` |
| 同上 `tests/res1_ui1b_runner.gd` | 最後140 checks、exit0；`artifacts/res1-ui1-r1-res1_ui1b_runner.log` |
| 同上 `tests/abode_presentation_parity_runner.gd`、`tests/m2d_responsive_ui_runner.gd`、`tests/res1d2_world_runner.gd` | 各exit0；世界59 checks，對應 `artifacts/res1-ui1-r1-*_runner.log` |
| Godot `--path . --script res://tools/res1_ui1r1_preview.gd` | exit0、三尺寸各basics／recipes／detail共9圖；`artifacts/res1-ui1-r1-native-final.log`；無OVERSIZE。844×390原生window下Godot logical為779×360，不能冒充CSS像素驗收 |
| bundled Python `tools/subset_game_fonts.py --check` | exit0，1823 codepoints及原字型／子集hash保持；`artifacts/res1-ui1-r1-font-check.log` |
| Godot `--headless --path . --export-release Web build/web/index.html` | 最終exit0；`artifacts/res1-ui1-r1-web-export-final.log` |
| bundled Node `tools/prepare_web_compression.mjs build/web` | 最終exit0、Brotli往返與四首BGM companions；`artifacts/res1-ui1-r1-compression-final.log` |
| bundled Python `tools/island_preview_server.py --port 4296 --normal-build --fixture res1-ui1-r1-review.json --gzip` | 正常提供最終隔離包；新origin不讀4175玩家資料 |
| `git diff --check -- src/presentation/island_management_panel.gd src/presentation/feature_navigation.gd tests/res1_ui1a_runner.gd` | exit0；只有LF→CRLF提示，未替換既有dirty工作區 |

最終PCK SHA256：`19602fd5d55b939d979f613b01332f3ca7a44eea169d018fe3da97ff9b3f8a6d`。首次sandbox runner因user://日誌／隔離保存目錄不可寫失敗並停掉（初始log後被成功重跑覆寫）；以專案授權的正常提權流程重跑成功。初次sandbox localhost服務不能由IAB存取，停止後依既有授權重啟成功。Godot退出仍有既有Font RID／CanvasItem／ObjectDB診斷，不能稱零錯誤。完整56回歸後的最後修改僅固定篩選／卡片排列／停止文案／短收據布局，已用最終164、運輸140與相關呈現回歸補驗，不把56當輪155寫成164。

## 真實Web證據

IAB／cua_repl、滑鼠、DPR約1，1380×850 browser override容納測試iframe。唯讀DOM量得 **1280×720、844×390、800×360 CSS**。正式畫布維持Adaptive；下面是隔離測試iframe，外部頁面留白不代表正式遊戲採固定畫布。

1. 桌面經營→空島→玄礦：選中顏色正確；點採集升階後显示成功收據、祖島靈木／銅精支付，採集設施1→2與速率2→4。重載最終包後仍2階／4秒率；展開本島庫存可見原料與銅精23，產線閒置。`artifacts/res1-ui1-r1/web-island-stock-final.jpg`。
2. 桌面製造：左祖島清單与四精煉卡並列，卡片原料明示來源；點丹液「製作一批」显示原料已扣除、單批進度，完成後丹液入庫且回到可製作。篩選玄礦後停止持續銅精，收據說明當前加工繼續，卡片進度保留、完批後閒置。`web-manufacturing-start-1280.jpg`、`web-manufacturing-stop-1280.jpg`、`web-manufacturing-final-1280.jpg`。前兩張在最終短收據布局修訂前擷取，桌面實作一致；final為最後PCK。
3. **最終PCK** 844×390：點銅精立即看到收據與卡片進度，總覽暫收；內部wheel可捲到丹液原料／當地與祖島可用量，上方篩選與底導航維持。`web-progress-844x390.jpg`、`web-stock-scroll-844x390.jpg`。
4. 800×360銅精詳情可以查看庫存，固定返回配方可點；360×640旋轉罩下點背景分頁無作用，回800×360仍同一銅精詳情，點返回復原清單。`web-detail-800x360.jpg`、`web-portrait.jpg`、`web-rotation-restored.jpg`。實體觸控／高DPR另待驗，不以此放行。

以上檔案位於 `docs/verification/artifacts/res1-ui1-r1/`。原生圖是呈現診斷，Web測試以正常命令操作earned fixture並自然秒數結算；未宣稱完整空白滑鼠通關。既有UI1-C保存400矩陣不重做、不列未開始。一般Web包已同步，Windows包本輪未更新。

## 交接

清理：4296隔離測試服務已用Ctrl+C正常停止（exit1為人工中止）；遊戲與參考頁分頁已關閉，browser viewport override已復原。首次連線失敗留下的空白錯誤頁為data URL，瀏覽器URL政策拒絕取得／關閉，未繞過；該頁沒有遊戲或存檔writer。

下一工作是使用者對操作密度／回饋與美術節奏的接受，以及完整UI1-C未過的裝置清單；不開Era4、不重做已過保存矩陣或效能定位。依Context Guard追加英文checkpoint到updata頂部並更新狀態，下一大型工作在New Chat接續。
