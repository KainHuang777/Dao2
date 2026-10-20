# EARLY-V1-D 驗收：RES1-D 與前期放行（同版空白新檔 → 金丹首升級：D-1 持續自然實玩）

## 2026-10-21 人工節奏接受／正式收結

**EARLY-V1-D／RES1-D DONE（桌面／Web有界）**。使用者明確回覆「放行 EARLY-V1-D／RES1-D」，完成本次前期節奏人工閘門；此前審閱的資源等待、首世金丹／壽盡循環、四島取捨、天賦選擇與結丹法容量前置納入本次接受。沿用2026-10-19 D-1／D-2及2026-10-20 MFG-3、A／B／C各自既有證據；EARLY-V1 A–D閉環收結。

人工接受不新增測試證據：D自然流程使用凍結包；MFG、天賦與技能另有候選包／隔離fixture驗證，不改稱整段最新候選包重跑。自然宗門貢獻取得時間未實測的界線保留。下方2026-10-20待判定及更早待辦按日期保留為歷史，由本節覆蓋其目前狀態。

本輪只同步README、ROADMAP、docs14／23、ai-handoff、development-status、D驗收／人工判定資料及英文updata，共9份文件。PowerShell／Python嚴格UTF-8、接受原話、現況狀態與本地連結核對，另執行指定檔案git diff --check。沒有重新執行Godot／Runner／瀏覽器／匯出，未改程式、數值、素材、存檔schema、玩家資料或凍結Web包，未commit/push。下一大型任務使用New Chat，由使用者指定；本輪停止。

## 2026-10-20 現況校正：僅待人工節奏判定

D-1／D-2已達成；MFG受控桌面回歸已由[MFG-3](mfg-3.md)補齊。EARLY-V1-D／RES1-D整體維持IN_PROGRESS，僅待使用者明確節奏判定；下方「MFG尚未回歸」為2026-10-19歷史，本節覆蓋其現況。審閱[人工節奏判定資料](early-v1-d-human-pacing.md)，包含等待、首世壽元與技能容量前置。此次任務名稱不是放行聲明；未重跑遊戲或改寫歷史證據。

狀態：**D-1 已達成（2026-10-19；單一不中斷 Session 由空白新檔自然跑到金丹首升，四島交叉勾稽、壽元、離線結算、保存故障恢復、首尾原始存檔版本鏈皆已取得實機證據）。D-2 已達成（2026-10-19 晚間；同版凍結 Web、同一 origin 存檔、真實桌面滑鼠、自然遊玩與自然離線缺口使壽元耗盡至 44400 模擬秒 → 首次輪迴 → 第二世可採集／建造／升階並持久化；無 Debug、無資源／時間注入）**。本檔記錄 D-1 與 D-2 之證據與座標校正，並保留先前分段驅動的可追溯歷史。**EARLY-V1-D 整體尚待 MFG 受控 UI 回歸與人工節奏判定後方能標 DONE；D-2 本段已達其自身驗收。**

## 範圍與分段裁定

- 使用者於 2026-10-19 核定 **D 分段**：
  - **D-1（本次 Session）**：同版正式 Web、隔離空白新檔、**真實桌面滑鼠**、自然時間走到**金丹（Era3）首次升級**；核對四島加工／航運、壽元、離線、保存故障恢復；首尾原始存檔、事件與版本可追溯；**無 Debug、無資源／時間注入**。
  - **D-2（另行排程）**：壽元耗盡（Era3 44400 模擬秒 ≈12.3 小時自然時間）→ 首次輪迴 → 第二世可操作供給。
- 分段 fixture 僅能證明子段；D 不因子段通過自動 DONE。

## 環境與版本

| 項目 | 值 |
| --- | --- |
| 引擎 | Godot 4.7.2.stable.official.ed1daf0bf |
| 服務 | `python tools\island_preview_server.py --port 4380 --normal-build`（pid 472888），服務 `build/web`，命名空間 `dao2_saves` |
| 瀏覽器 | （分段期）`msedge.exe --remote-debugging-port=9240 --user-data-dir=build\earlyv1d-edge2 --app=http://127.0.0.1:4380/index.html`（含 `--disable-backgrounding-occluded-windows --disable-renderer-backgrounding`）。**（單一 Session）另起全新 profile `--remote-debugging-port=9242 --user-data-dir=build\earlyv1d-run-edge`**（origin 空白，全程未 reload） |
| 視口鎖定 | 驅動以 env `VIEW_W=1280 VIEW_H=720 VIEW_DPR=1` 套用 `Emulation.setDeviceMetricsOverride` → canvas ≈1280×720、scale 1、設計座標 1:1 |
| Node | v20.20.0，**必須** `node --experimental-websocket`（全域 WebSocket） |
| build | **併發 Session 於 2026-10-19 00:12 重新匯出**（含 tribulation 變更）；index.pck 45,692,732 bytes（EARLY-V1-C 時為 34,690,504）。此匯出與本段來源不保證同版，見「待辦／風險」 |

## 已建立工具（docs/verification/artifacts/early-v1-d/）

- `drive_era1.mjs`：**智慧目標驅動**（Era1）。每輪讀存檔 → 依 NEEDS 鏈算目標 → 僅在**前置滿足且資源足夠**時點該建築按鈕（避免點到停用按鈕導致卡片內展開、版面漂移）；否則採集最缺資源；每輪亦點晉階。已驗證可從 lv5 補齊 stone_mine3/herb_farm3/storage_lingli1 並升到 Era1 Lv10（cap 560）。
- `runner.mjs`：S00..S18 全段跑者（WAYPOINTS 多為舊幾何值，Era1 段需改用 drive_era1 邏輯；Era2/Era3 段未校正）。
- `drive_era2.mjs`：Era2 驅動（建 `foundation_reservoir` L1→L2、啟動靈材／銅精持續製作、開通 `bronze_home` 等航線、被動迴圈點晉階至 Lv10）。環境變數 `CDP_PORT/HTTP_PORT/DIR/MAX_MS`。
- `drive_era3.mjs`：Era3 驅動（Phase A 造 `formation_core`×1、Phase B 持續產 `stone_mid` 至 ≥50、Phase C 點晉階完成金丹首升）。**同一 CDP target 不可同時跑兩個驅動**（reload 會互撞 `Not attached to an active page`）。
- `calib.mjs`、`geo.mjs`、`dumpstate.mjs`、`gatherdiag.mjs`、`catalogshot.mjs`：校正／取像／狀態傾印。
- `drive_unified2.mjs`：**單一不中斷 Session 驅動**（Era1 建築鏈 → Era2 開島／航線／加工／升階／突破 → Era3 `formation_core`＋`stone_mid`＋金丹首升）；全程不 reload，逐段匯出原始存檔（`unified-run/`）。
- `crosscheck.mjs`：四島產運交叉勾稽樣本（`crosscheck-t*.json`、`cc-*.png`）。
- `probe_offline.mjs`：離線結算探針（away gap → `last_offline_report`）。
- `probe_savefail.mjs`／`probe_savefail2.mjs`：保存故障注入與「重試保存」恢復探針。
- 證據：`drive-era1-t1/`（log.jsonl、progress PNG、periodic 原始存檔）、`gatherdiag*/`、`catalogshot/`、`look-era2-*.png`、`era2-*.png`。

## 已驗證事實（原始碼／實機）

### 採集與存讀時間差
- 採集為 `CommandProcessor._apply_gather`（command_processor.gd:77-100），每次 +1，夾在執行期 `caps[resource_id]`；`era!=1` 回 MANUAL_GATHER_ERA（**採集僅限 Era1**，Era2 以上 HUD 無採集鈕）。
- 存檔自動儲存週期 **15.0 秒**（living_abode.gd:902-904），故 `readSave` 最多落後 15 秒——**單次讀值不可信**。

### 容量公式（Era 相依，非單一公式）
- 執行期 `Production.compute_caps`（production.gd:39-80）= 資源定義 max + 建築 caps/all_max + `Onboarding.hut_lingli_capacity`（hut_level×150，**僅 Era1 套用**）+ 技能 '*_max'。
- 實測：Era1 cap 560 = 100 + hut(2)×150 + storage_lingli(1)×160；Era2 cap 420 = 100 + storage_lingli(2)×160；Era2 money cap 1400。`summarizeSave().helpers.lingliCap` 讀到 0，**不可用**，須自算。

### Era1 建築鏈與突破（已實機驗證）
- NEEDS 順序：hut2 → wooden_house2 → forest_farm3 → stone_mine3 → herb_farm3 → storage_lingli1（cap 560 ≥ 500）。
- `drive_era1.mjs` 已成功完成上述鏈並升至 **Era1 Lv10**（真實滑鼠、僅點啟用按鈕、無注入）。
- 突破按鈕『★ 突破至築基期 ★』≈(252,112)；點擊後 **era=2 level=1**（Era1→2 無需天劫）。突破後出現全屏演出：按鈕 重溫突破(~569,650)／**圓滿出關(~706,650)**（點此關閉）。

### Era2 資源與加工（實機驗證）
- 空島開拓：青木島（林業·靈木 +2/s）、玄礦島（探礦·下品靈石+玄銅）；各花 **20 靈木 + 10 下品靈石（由祖島支付）**。已實機開拓兩島（wood 150→130→…；rev4282）。
- 航線（運輸頁）：可啟航 靈木 青木島→玄礦島、下品靈石 玄礦島→青木島、靈材 青木島→祖島、銅精 玄礦島→祖島（後者初次點擊未命中，待補）。丹霞島航線為『端點未開拓』（Era2 尚不可開）。
- 加工（製造頁，精鍊模式）：銅精·玄礦島（玄銅10+下品靈石5，10秒/批）、靈材·青木島（靈木10+下品靈石5，10秒/批）、丹液·祖島（靈草5+靈力50）、中品靈石·祖島（下品靈石5+靈力10，**境界未解鎖**，Era3 才開）。
- 完成之加工批數確實進入祖島庫存（銅精 庫存 1.0→2.0）。
- 加工批次預設『單批』；詳情頁量級下拉有 **單批／指定批數／持續製作**，另有『進階設定·原料保留量』。**已確認啟動方式**：選『持續製作』後必須按詳情頁『開始製造』（按『返回配方』不會啟動）→ 存檔出現 `repeat:true` 產線。

### 面板座標（@1280×720，全部實測）

**恆定（主 HUD）**
- 資源緞帶模式列（數量模式）y≈114：關閉(75) 數量(184) 完整(276)。Era2 資源列 y≈156/200/244/288/332/374/419/458/497（x≈75）。
- Dock y≈664-668：洞府(95) 經營(191) 修行(287) 遊歷(382)（Era1 時 x 約 78/176/279/378、y=668）。
- 身分卡：Era1 晉階鈕 (323,75)；Era1 Lv10 突破鈕 (252,112)；Era2 晉階鈕 ≈(279,79)。**卡片高度隨狀態變化**（Lv10/可突破多一行，會把下方緞帶整體下推約 60px）。

**營造簿（建築）**：面板 x≈644-1264（rail）。分頁 全部(754,213)/生產(960,213)/倉儲(1161,213)。按鈕格（2 欄）：左欄 x≈908、右欄 x≈1212；列 y≈328/451/573（右欄首列 ≈297）。**注意**：點到停用（材料不足／前置不足）按鈕會穿透到卡片本體使其**行內展開**並推下後續卡片——必須只點啟用按鈕。

**管理分頁列（bar）x 隨頁面策略而異**（feature_navigation.gd `bar.position.x = 面板 x`）：
- 運輸頁（large，面板 x≈230）：洞府建築(297) 空島(391) 製造(479) 運輸(558)；X(1010,45)。
- 製造頁（wide_stock，面板 x≈455）：洞府建築(~510) 空島(~607) 製造(~692) 運輸(~781)；X(1164,45)；齒輪(1235,45)。
- 空島頁（rail，面板 x≈864）：約 775/897/1002/1112（**不穩定，勿硬信**）。

**空島頁**：島選擇列 y≈176：祖島(916) 青木島(981) 玄礦島(1047) 丹霞島(1112)；開拓鈕 (1063,428)；前往X島 (1063,229)；關閉 (1210,124)。

**製造頁（列表）**：標題列 全部空島(~994,126)；精鍊(1092,126)／合成(1160,126)／關閉(1222,126)；產線狀態 (473,167)。卡片 2 欄：**標題鈕**（開啟詳情）x=613(左)／1006(右)，**動作鈕** x=780(左)／1158(右)，同列同 y。列 y=220(列1)／424(列2，**無產線時**)；**列1 有產線時整列2 下移至 y=488**。標題鈕可點範圍約 y±20（例：丹液標題中心 y=446，點 y=488 會落空）。

**運輸頁**：路由卡片 2 欄；有貨的路由多顯示一行使按鈕下移（y≈318），僅『停航』一行者按鈕 y≈280(列1)/445(列2)；啟航 x 左欄≈477、右欄≈877，設定 各 +60。

**輪迴面板**（舊幾何推估，**待 1280×720 重新校正**）：入定轉世鈕 ≈(640,600)；演出 跳過(1208,46)／完成(640,438)。

## D-1 已達成里程碑（2026-10-19，真實滑鼠、無注入）

### 持續製作（先前 blocker 已解）
- 詳情頁量級下拉『**持續製作**』必須接著按詳情頁下方『**開始製造**』才會生效；按『返回配方』不會啟動（先前誤判）。
- 實測啟動成功：存檔 `economy.jobs[island]` 出現 `{recipe_id, remaining, repeat:true, reserves, status:'running'}`；`repeat:true` 即持續製作。
- 詳情頁座標（@1280×720）：模式下拉框 (855,468)；下拉項 單批(560,518)／指定批數(560,558)／**持續製作(560,596)**；『開始製造』≈(848,577)（短配方無需捲動）。
- **注意**：`jobs` 以**島**為鍵 → 同一島同時僅一條產線；祖島需在『中品靈石』與『靈紋陣芯』之間**輪流**啟動。

### Era2 → Era2 Lv10 / cap ≥2000（已達成）
- 建 `foundation_reservoir` L1→L2（營造簿・倉儲・築基靈池，按鈕中心 (909,543)；成本合計 money250/wood125/stone_low50）。
- 持續產線：靈材·青木島、銅精·玄礦島（丹液·祖島僅在缺量時短開，因 50 靈力/批 會抽乾靈力、拖慢晉階）。
- 航線全通：`bronze_home`（銅精 玄礦島→祖島，真正 id 為 **bronze_home**，非 ore_home）、`ore_wood`、`timber_home`、`wood_ore`。
- 驅動 `drive_era2.mjs`（被動迴圈每 ~2 秒點晉階鈕 (278,82)）：Era2 L2 19:25 → L5 19:25:54 → L6 19:28:44 → L7 19:33:57 → L8 19:39:20 → L9 19:45:39 → **L10 19:53:44**；`drive-era2/save-final.json` = era2 lvl10、靈力 2498.3、foundation_reservoir 2、storage_lingli 2。

### Era2 → Era3 突破（已達成）
- Lv10 身分卡顯示『築基期 10/10 層・可突破』，紅鈕『★ 突破至金丹期 ★』中心 **(254,114)**；點擊即 `era_id=3 level=1`（無天劫、無資源提示）。
- 演出：標題『天地同感・境界突破』、跳過鈕 (1200,84)；結算卡按鈕 重溫突破(582,650)／**圓滿出關(700,650)（必點此關閉）**。

### Era3 金丹首升級 L1→L2（已達成，2026-10-18T20:09:19Z）
- 驅動 `drive_era3.mjs` Phase A 造 `formation_core`×1（合成頁）、Phase B 持續產 `stone_mid`（精鍊頁 1006,488）至 ≥50、Phase C 點晉階鈕 (278,82) → **era3 level2**。
- 原始存檔狀態差（`drive-era3/save-*.json`）：`save-002-stone_mid` era3 lvl1 / training_seconds **240**（恰好達標，按鈕才變『修為晉階』）／stone_mid 50／formation_core 1／liquid 70／lingli 2420／money 1610；`save-final` era3 **lvl2**／training_seconds 0／lingli 410／money 1110／stone_mid 2／formation_core 0／liquid 69。
- **五項成本精確扣除**（對照 content/eras/era3.json L1→L2）：money −500、liquid −1、formation_core −1、stone_mid −50（後 +2 產出）、lingli −2000（+ 回復）。
- 事件收據 `lvl_11424100_3708299097`（new_level 2）存在於 events.jsonl。
- 機制（原始碼）：升級為顯式命令 `level_up_cultivation`（command_processor.gd:22-23→`_apply_level_up`:158），要求 `training_seconds >= req_time（誤差容忍）`（:165-166）才執行；`training_seconds` 由 time_advancer.gd:147 以 **+1.0/s 累積**（非倒數）；達成後清零（:186）。按鈕可見性／文字於 abode_hud_controller.gd:851-935；無任何執行期自動升級。

## D-1 單一不中斷 Session（2026-10-19，關鍵結果）

**結論**：由**空白新檔（revision 1）**起，於**同一個 Edge 分頁 Session 內、全程未 reload**，以真實桌面滑鼠自然時間跑到 **Era3 金丹 L1→L2（golden core 首升）**；並完成四島產運交叉勾稽、壽元、離線結算、保存故障恢復與首尾原始存檔版本鏈。無 Debug、無資源／時間注入。

### 執行環境（本段）
| 項目 | 值 |
| --- | --- |
| 服務 | `python tools\island_preview_server.py --port 4380 --normal-build`（pid 472888），服務凍結的 `build/web`（index.pck 45,692,732 bytes，SHA-256 `7E7E619D…`，2026-10-18T16:12:56Z，**不含 MFG 改動**） |
| 瀏覽器 | `msedge.exe --remote-debugging-port=9242 --user-data-dir=E:\WORK\Dao2\build\earlyv1d-run-edge --app=http://127.0.0.1:4380/index.html`（全新 profile → 該 origin 空白；全程未 reload） |
| 驅動 | `docs/verification/artifacts/early-v1-d/drive_unified2.mjs`（`node --experimental-websocket`；`CDP_PORT=9242 HTTP_PORT=4380`） |
| 證據目錄 | `docs/verification/artifacts/early-v1-d/unified-run/`（`events.jsonl`、`save-head.json`／`save-tail.json`、逐段 `save-era*.json`、`crosscheck-*.json`、`probe-*.jsonl`、`cc-*.png`、`probe-*.png`） |

### 首尾原始存檔版本鏈（可追溯）
- **head**：`save-head.json` 信封 `revision=1`，state = era1 level1 全零；`last_offline_report` 為 **bootstrap**（`bootstrap:true, away_ms:0`）。即空白檔第一次載入即寫入的鏈首。
- **tail**：`save-tail.json` 信封 `revision=8657`，state = **era3 level2**、`total_elapsed_seconds=8420`；`achievements` 含 `era_golden_core`（new_revision 6870）、`era_foundation`、`era_qi`、`build_first_hut`、`build_sum_10`。
- **事件收據鏈**（`save-tail.json.command_receipts`）：`era_breakthrough` from_era1→2（new_revision 1566）、from_era2→3（7102）；`island_opened`（1578/2810/7121）；`route_configured`（1641/3926/4426/7132）；`processing_started`（3952/3967/3981/4475/8052/8094；含 `processing_stopped_after_batch`）；`cultivation_leveled_up` 覆蓋 era1 lvl2..10、era2 lvl2..10、era3 lvl2；`building_upgraded` 含 storage_lingli 1..5、foundation_reservoir 1（4410）與 2（4414）。
- 逐段原始存檔另存 `save-era1-*.json`、`save-era2-*.json`／`save-era2-tick-*.json`、`save-era3-*.json`，可對照 revision 遞增。

### 四島產運交叉勾稽（`crosscheck-t0|t1|t2.json`、`cc-*.png`）
- 同一 Session 內四島**全部開拓**（home/wood/ore/herb）；`economy.routes` 啟用 `bronze_home`、`grass_home`、`ore_wood`、`timber_home`。
- 島庫存樣本（t2−t0 = 206 模擬秒）：herb `{spirit_grass_100y:150, spirit_grass_low:150}`、ore `{black_copper:150, bronze_essence:150, stone_low:150}`、wood `{spirit_timber:150, stone_low:100, wood:150}`；home 庫存為空（別名 resources）。
- 祖島資源：`spirit_timber 100`、`bronze_essence 100`、`stone_low 150`、`stone_mid 38→49→59`、`lingli +432`。**關鍵**：`spirit_timber`／`bronze_essence` 只有 wood／ore 島能產（祖島無此配方），卻出現在祖島 → 由 `timber_home`／`bronze_home` 運抵；wood 島持有本地無法生產的 `stone_low 100` → 由 `ore_wood` 自 ore 運抵。
- `save-tail.json.economy.trips` = `{ore_wood:{cargo:5, remaining:7}}`（**在途貨運即時樣本**）。

### 壽元（壽元）／離線結算／保存故障恢復
- **壽元**：累積上限 740 祀（Era1 80＋Era2 120＋Era3 540）；tail `total_elapsed_seconds=8420` ≈ 140 祀 已用；HUD 讀值見 `cc-hud-t0.png`（Era3 早期）。未跑滿 740 祀（屬 D-2）。
- **離線結算**（`probe_offline.mjs`／`probe-offline.jsonl`）：讀 `settled_until_utc_ms=1792376004686`（rev 9254）→ `navigate('about:blank')` → 實等 90 秒 → 返回 `index.html` → console `OFFLINE_SETTLEMENT_BEGIN`／`OFFLINE_SETTLEMENT_END: ok=true`；`last_offline_report` 驗證 `{away_ms:102904, effective_ms:102904, effective_ticks:103, forfeited_ms:0, cap_applied:false, bootstrap:false, rollback:false}`；rev→9255。**長時間（12h+）離線未實測**（超出 D-1 範圍，屬 D-2；已誠實標示）。
- **保存故障恢復**（`probe_savefail.mjs`／`probe-savefail.jsonl`／`probe-state.png`）：注入 `Storage.prototype.setItem` 對 `dao2_saves:save*` 拋 `QuotaExceededError` 後，rev **凍結於 9221**（自動存檔無法落盤），畫面出現全屏阻擋『進度尚未存妥，請保留此畫面。恢復儲存權限或空間後，按重試保存；操作不會再次扣料。』與 **重試保存** 鈕（設計座標 (638,414)）；還原 `setItem` 後按重試保存，rev 由 9221→9238→**9254 恢復**（`probe-savefail-3-recovered.png`）。

### 時間線（單一 Session）
- Era1 完整建築鏈 → Lv10 → 突破（era=2）t≈1336s。
- Era2 被動升階 Lv2→…→Lv9（t 約 112→2061s）→ **2026-10-19T01:37:08Z 突破 era2→3（level1）**；01:37:24 開拓丹霞島；啟用 `grass_home`。
- Era3：01:52:36 `formation_core`×1；01:52:51 啟動 `stone_mid` 持續產線（0→52）；**02:01:52 金丹首升 era3 level2**（`save-tail` rev 8657）。

## D-2 壽元耗盡 → 首次輪迴 → 第二世（2026-10-19 晚間，真實滑鼠、無注入）

**結論**：同版凍結 Web、D-1 同一 origin 存檔（`save_index.active_slot=save_backup`），以**真實桌面滑鼠**、**自然遊玩＋自然離線缺口**使 `total_elapsed_seconds` 到達壽元上限 **44400**（740 祀），離線結算因**壽元耗盡**停止；接著完成**首次輪迴**（道心 +20、最高境界保留 Era3），並在**第二世**以真實滑鼠採集（靈氣／金錢）、建造（茅屋→2 階）、再建木屋，資源持續產出；reload 後第二世持久化、無重複輪迴與重複獎勵。全程無 Debug、無資源／時間注入、未改時鐘。

### 執行環境（D-2）
| 項目 | 值 |
| --- | --- |
| 服務 | `python tools\island_preview_server.py --port 4380 --normal-build`（pid 472888），服務凍結 `build/web`（index.pck 45,692,732 bytes，SHA-256 `7E7E619D…`） |
| 瀏覽器 | `msedge.exe --remote-debugging-port=9242 --user-data-dir=E:\WORK\Dao2\build\earlyv1d-run-edge --app=http://127.0.0.1:4380/index.html`（D-1 同 profile／同 origin；Edg/155.0.4283.62） |
| 視口鎖定 | 驅動 env `VIEW_W=1280 VIEW_H=720 VIEW_DPR=1` → `Emulation.setDeviceMetricsOverride` → canvas 1279×719、scale 0.9986；**未套用時 viewport 為 1265×762 dpr1.25，座標會偏移約 1.2% 而誤擊**（曾使點擊穿過摘要落到下層 靈獸 頁） |
| 驅動 | `docs/verification/artifacts/early-v1-d/d2/drive_d2_*.mjs`（`node --experimental-websocket`） |
| 證據目錄 | `docs/verification/artifacts/early-v1-d/d2/`（`events-*.jsonl`、`save-*.json`、`summary-after-settlement.json`、`*.png`） |
| 備份 | 啟動前複製 profile 的 `Local Storage`＋`IndexedDB` → `build\earlyv1d-run-edge-backup-20261019-223321`（27 檔，400,941 bytes） |

### 自然離線缺口與壽元耗盡（事實精確界定）
- D-1 最後結算 `settled_until_utc_ms=1792376004686`（2026-10-19T10:13:24+08:00）；本次啟動約 22:33（+08:00），**未動系統時鐘**。
- 離線結算結果（`phase1-after-settlement.png`、`phase2-before-close.png`）：離線收益摘要顯示 實際離開時間 **19975 秒**、有效收益時間 **19975 秒**、目前年歲 **740 年**、停止原因 **壽元耗盡**、是否套用上限 **否**。
- 存檔 `save-after-settlement.json`：`revision=33974`、`era=3`、`level=2`、`total_elapsed_seconds=44400`、`reincarnation_count=0`、`dao_heart="0"`、`highest_era=1`；建築與 D-1 相同（hut2/forest_farm3/foundation_reservoir2/herb_farm3/stone_mine3/storage_lingli5/wooden_house2）。
- **界定（勿誇大）**：這是「**自然遊玩累積 24425 秒＋合法自然離線缺口 19975 秒**」恰好到達 12.3 遊戲小時（= 740 祀 = 44400 秒）的壽元上限；**不是**單一連續 12 小時離線缺口。`last_offline_report` 不寫入存檔（存檔層無此欄），故離線摘要僅以 UI 截圖為證。
- 壽元上限公式：`max = Σ era_cap(years) × 60s = (80+120+540)×60 = 44400s`（`src/simulation/lifespan.gd`；`is_exhausted(total>=max)`）；`time_advancer._advance_legacy` 在耗盡時以 `{"stopped":"lifespan_exhausted"}` 停止並夾住剩餘秒數。

### 首次輪迴（真實滑鼠、兩段確認）
- 關閉離線摘要（真實滑鼠點 **關閉** ≈(268,290)）後，`living_abode._offer_lifespan_reincarnation` 於後續 refresh 自動開啟**輪迴面板**（`after-close-720-b.png`）：`輪迴 · 累世傳承`、分頁 `轉世輪迴`、道心:0｜道證:0、卡片 `第 1 世 · 最高 1 階`、`命燈已熄`、`壽元已盡 · 修行停滯`、獎勵 **道心 +20／道證 +0**、`資源傳承 0%`；底列鈕 **入定轉世** ≈(640,586)。
  - 與 `reincarnation_rules.gd` 相符：era3 道心底 20；獎勵 = max(floor(建築和/10)=2, 20)=20；道證 = floor(20/50)=0。
- 第一段：點 **入定轉世**(640,586) → 底列改為 **取消**(≈577,586)／**確認轉世**(≈670,586)（`confirm-step1-b.png`）。
- 第二段：點 **確認轉世**(670,586) → 存檔 +0.8 秒內即 `revision=33977`、`era=1`、`level=1`、`total_elapsed_seconds=0`、`reincarnation_count=1`、`dao_heart="20"`（`save-second-life-start.json`）。
- 演出自動走完至尾幕（`seq-8.8s.png`）：`第 2 世 · 練氣初境（肉身重塑）`、`本次轉世凝聚道心：+20 點`；主鈕 `重聚仙靈・入世修行` ≈(640,459)，後接 `九界諸天 · 神識星圖` 覆蓋層，鈕 `收回神識・回到洞府` ≈(640,626) 返回遊戲。

### 第二世可操作供給（真實滑鼠，逐步截圖）
- 返回洞府（`second-life-abode-4s.png`）：`練氣期 1/10 層`、`缺靈氣`、`壽元 1/80 祀`；建築清空、資源全 0。
- 打開資源緞帶（點 **數量** ≈(185,350)），資源列出現 靈氣 0.00 並有 **採集** 鈕（`second-life-resource-list-b.png`）；點靈氣採集按鈕 15 次 → 畫面 15.00。
- 點 **經營**（開啟營造簿）→ 提示 `下一步：建造【茅屋】`；茅屋卡 靈氣 **27/20** → 點 **建造**(≈911,312) → 存檔 `buildings={hut:1}`（`save-second-life-hut.json`，`revision=34341`），茅屋 `1 階` 開始產靈氣；資源列新增 金錢／靈木 採集鈕（`second-life-hut-built-7s.png`）。
- 點金錢採集 25 次 → 金錢 25.00；提示 `將茅屋升至 2 階`；點 **升級**(≈918,312) → 茅屋 `2 階·已滿`，存檔 `{hut:2}`（`revision=34429`）。
- 木屋卡解鎖（money 25/20、lingli 47/30）→ 點 **建造**(≈910,453) → `{hut:2, wooden_house:1}`；待 20 秒再讀存檔（`save-second-life-operable.json`，`revision=34475`、`total=443`、靈氣 101.08、金錢 33.64），確認**自動存檔落盤**且產線持續（`second-life-steady-20s.png`）。
- 成就：`first_reincarnate` 已解鎖（unlocked tick 0）；`dao_heart="20"`、`highest_era=3` 保留。

### reload 後持久化與無重複獎勵
- 真實 reload → 離線摘要（`reload-after-9s.png`）：實際離開 **12 秒**、目前年歲 **7.8 年**、停止原因 **無（正常結算）**、上限 **否**（正常短缺口結算，**未**再觸發壽元耗盡或輪迴）。
- 存檔 `save-after-reload.json`：`revision=34492`、`total=470`、`era=1`、`level=1`、`reincarnation_count=1`、`dao_heart="20"`、`highest_era=3`、`buildings={hut:2, wooden_house:1, library:0, scripture_hall:0}`、金錢 67.27、靈氣 151.5。
- 未出現第二次輪迴演出、無再次 +20 道心。關閉摘要後留存 `reload-after-close.png`。

### 座標校正（@1280×720，D-2 實測；面板會隨 header／提示高度位移）
- 離線摘要：**關閉** ≈(268,290)。
- 輪迴面板底列：**入定轉世** (640,586)；**取消** (577,586)；**確認轉世** (670,586)。
- 輪迴尾幕：**重聚仙靈・入世修行** (640,459)；**收回神識・回到洞府** (640,626)。
- 資源緞帶模式列：**關閉**(86,350)／**數量**(185,350)／**完整**(289,350)。資源列採集鈕 y 隨面板高度變動（實測 靈氣採集 (307,397) 與 (307,319) 兩態；金錢採集 (297,362)）——**每次點擊前應以截圖重新確認**。
- Dock 底列 y≈665：洞府(68)／**經營＝營造簿**(183)／修行(295)／遊歷(376)。



1. **單一連續 Session（已解除）**：早期里程碑原由 `drive_era1.mjs`＋`drive_era2.mjs`＋`drive_era3.mjs` 分段（含多次 reload）完成；已由 `drive_unified2.mjs` 於**同一未 reload 分頁**自空白新檔一口氣跑到金丹首升（見上節），解除此阻擋。上述分段驅動保留為歷史可追溯記錄。
2. **併發風險已排除（build 凍結）**：另一代理交付之 **MFG-0／MFG-1 製造 UI 重構**發生在本次匯出**之後**；伺服中的 `build/web`（index.pck 45,692,732 bytes，SHA-256 `7E7E619D…`，2026-10-18T16:12:56Z）**不含 MFG 改動**，本段全部結果不受其影響；已另存凍結副本 `build/earlyv1d-frozen-web`。MFG 面板本身待 MFG 完工後再做一次受控 UI 回歸。
3. **Era2／Era3 段驅動**：`drive_era2.mjs`／`drive_era3.mjs` 已可用；僅需在正式記錄時把相對 `DIR` 改指 `docs/verification/artifacts/early-v1-d/`（目前輸出於 repo 根目錄 `drive-era2/`、`drive-era3/`，已複製歸檔）。
4. **D-1 已驗證**（見上節）：四島加工／航運完整交叉勾稽、壽元、離線結算（90 秒實等 gap）、保存故障恢復、版本可追溯之首尾原始存檔連續鏈（head rev1 → tail rev8657）。**D-2 已驗證**：自然壽元耗盡（total 44400）→ 首次輪迴 → 第二世採集／建造／升階＋reload 持久化（見 D-2 節）。**仍待辦**：MFG 製造面板受控 UI 回歸、人工節奏判定；此二項未完成前 EARLY-V1-D **整體**不標 DONE（D-2 本段已達其自身驗收）。
5. 延期（非阻擋）：觸控／實機／高 DPR、冷啟動、跨瀏覽器、OS 休眠。

## 尚未證明

- **已證明**「空白新檔 → 金丹首升」之單一連續自然時跑（rev1→rev8657，分頁全程未 reload）。
- **已證明 D-2**：自然遊玩＋自然離線缺口使壽元於 44400 秒耗盡（離線摘要 停止原因 壽元耗盡、上限 否），經真實滑鼠兩段確認完成首次輪迴（dao_heart 20、highest_era 3、reincarnation_count 1、era1 lv1 total 0），第二世可採集／建造茅屋→2 階／再建木屋並持續產出，reload 後持久化且無重複輪迴或重複 +20 獎勵。
- 未測：單一連續 12h+ 離線缺口本身（D-2 為自然遊玩＋自然缺口，見界定）；未重跑 ERA1 校正後之 `runner.mjs` 全段。
- 尚未進行 MFG 製造面板受控 UI 回歸、人工節奏判定（待 MFG 完工後執行；本段凍結 `build/web` 不含 MFG 改動）。此二項完成前 EARLY-V1-D **整體**不標 DONE。
