# D2 自然滑鼠流程腳本版協議：res1d2-natural-mouse

2026-10-16 續驗：舊 S02 停在三層的直接原因為靈木只補到20（實需40），
另有逾時誤報成功、mouseReleased按鍵旗標、存檔無cap卻讀為0等問題。
本輪已修補部分驅動可靠性，但 S03–S14 估算座標與容量判斷仍未全數校正，
不得視為無人值守完整通關工具。使用者同意改以逐步校正的 Edge/CDP
控制器續驗，最新結果見 [2026-10-16 驗收](../res1-d2-natural-web-20261016.md)。

**日期**：2026-10-14  
**狀態**：腳本已撰寫，待首次實際執行校正與完整驗收  
**對象**：RES1-D2 第一段（T1 茅屋 → 練氣/築基 → 築基靈池 2 級 → 靈力 2300 → 金丹突破 → 丹霞開拓 → 丹液加工/回運 → 祖島 T2 中品靈石/陣芯 → 金丹位階扣料晉階 → 保存重載）  
**原始人工版協議**：`docs/verification/d2-r1-natural-time-playthrough-protocol.md`（本文件不修改它，為平行腳本版）  
**約束**：無 Debug、無 fixture 種子、自然時間；唯一輸入來源為真實 CDP 滑鼠事件（`Input.dispatchMouseEvent`）與真實滾輪；`Runtime.evaluate` 只允許讀取 localStorage 與全域唯讀資訊、清空隔離 origin 的 localStorage 作為「空白開局」準備。

---

## 1. 檔案

| 檔案 | 角色 |
| --- | --- |
| `artifacts/res1d2-natural-mouse-driver.mjs` | 可重用 CDP 驅動庫（連線、畫布座標換算、滑鼠/滾輪、截圖、存檔讀取） |
| `artifacts/res1d2-natural-mouse-runner.mjs` | D2 具體流程腳本（`WAYPOINTS` 常數 + 逐步里程碑） |
| `artifacts/res1d2-natural-mouse/step-NNN-*.png` | 每次點擊／里程碑的畫面證據 |
| `artifacts/res1d2-natural-mouse/res1d2-natural-mouse-events.jsonl` | 全事件 JSONL（含每次 click_attempt 的 viewport 座標與當時 save 摘要） |
| `artifacts/res1d2-natural-mouse/save-dump-*.json` | 失敗／檢查點的存檔傾印 |

## 2. 啟動命令（精確重啟流程）

```powershell
# 1) 隔離 origin 的正常 Web 版（空白、正常 dao2_saves 命名空間、僅綁 loopback）
python tools/island_preview_server.py --port 4277 --normal-build

# 2) 帶 CDP 的本機 Chromium/Edge（專用 profile，避免動到玩家分頁）
& "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" `
  --remote-debugging-port=9225 --user-data-dir="$env:TEMP\dao2-cdp-4277" `
  --window-size=1420,920 --window-position=40,20

# 3) 自然時間 runner（Node 21+ 需旗標；Node 22.4+ 旗標為 no-op 亦可）
node --experimental-websocket docs/verification/artifacts/res1d2-natural-mouse-runner.mjs
```

- 4277 伺服器是**隔離測試 origin**；不會影響玩家常態 origin。
- CDP 連線用 `http://127.0.0.1:9225/json` → page target；如需另指定埠使用 `CDP_PORT=xxxxx`。

## 3. 自然時間與 TIME_SCALE 核查（真話）

- `src` 與 `content` 中不存在任何可在正常 Web 版被玩家或滑鼠啟用的 time-scale／自然時間加速 hook：
  - `src/abode/living_abode.gd:284,754-820` 的 `debug_auto_build_timer` 只在 DEBUG 面板脈絡（`abode_modal_manager.gd:525-588`）中作用，屬遊戲 Debug 工具，本驗收禁用。
  - 舊「自動正常空白模擬秒流程」是 `src/verification/web_persistence_probe.gd` 走引擎內命令派發＋加速模擬秒（見 `docs/verification/res1-d2-web-r1.md:9`）；它不是滑鼠路徑，也不能從 `Runtime.evaluate` 以唯讀方式打開。因此**本腳本無合法加速管道：必須以自然時間等待**。
- 自然時間預估（以 `docs/verification/early-pacing-baseline.md:9-10` 的純時鐘基準）：
  - Era1 練氣全十層 ≈ 1007 秒（約 16.8 分）
  - Era2 築基全十層 ≈ 2496 秒（約 41.6 分）
  - 丹液 10 秒／批、貨運 10 秒／趟；含開拓、設施升級與人工節奏誤差後，**完整 run 至少 1 小時以上**。
- 斷續能力：遊戲本身自動保存；中斷後先開好同一伺服器與瀏覽器（同一隔離 origin），設定 `RESET_SAVE=0` 再跑 runner，驅動會讀既有存檔繼續（未完成 step 會按同一條件輪詢）。

## 4. 環境變數

| 變數 | 預設 | 說明 |
| --- | --- | --- |
| `CDP_PORT` | 9225 | 瀏覽器 remote-debugging 埠 |
| `HTTP_PORT` | 4277 | island_preview_server 埠 |
| `STEP_DIR` | `docs/verification/artifacts/res1d2-natural-mouse` | 證據輸出目錄 |
| `RESET_SAVE` | 1 | 1=啟動時清空隔離 origin localStorage 重開新檔；0=保持既有存檔（續跑） |
| `RUN_STEPS` | 空 | 例 `0-3` 僅跑前四步做座標校正；空=全流程 |
| `CLICK_INTERVAL_MS` | 20000 | 每輪「條件檢查→重複點擊→存檔輪詢」週期 |
| `SHOT_EVERY_ATTEMPTS` | 6 | 每 N 次點擊截一張圖；第 1 次必截 |
| `BUDGET_SCALE` | 1 | 各 step 預警 timeout 之倍數（放寬機速） |
| `ERA1_BUDGET_MS` / `ERA2_BUDGET_MS` / `SHORT_BUDGET_MS` / `CRAFT_BUDGET_MS` | 2,000,000 / 3,400,000 / 240,000 / 1,200,000 | 練氣時鐘／築基時鐘／一般操作／加工與候補掃描之自然時間上限 |
| `VIEW_W` / `VIEW_H` / `VIEW_DPR` | 空（不啟用） | 選用：以 `Emulation.setDeviceMetricsOverride` 固定 CSS viewport（僅瀏覽器層版面，不注入遊戲邏輯）；建議 1280×720×1 |

## 5. 座標換算與 DPR／resize 處理

- 遊戲 `project.godot` 為 `canvas_items` + `expand`，運行期 `living_abode.gd:632-637` 將 content base 設為 1280×720（高度 ≤500 才降為 640×360）。`expand` 的縮放規則為取 `min(cssW/baseW, cssH/baseH)`，等比邊向多餘的部分以放大 logical viewport 呈現（844×390 得到 779×360 的現有證據即符合此規則，見 `docs/07-responsive-ui-web-spec.md:42`）。
- 每次點擊前 driver 都重新讀 `canvas.getBoundingClientRect()`（`res1d2-natural-mouse-driver.mjs` 的 `geo()`），以 `左上角 + point*scale` 折算成 viewport 座標，因此**resize／DPR 驅動都不必重編 waypoint**；DPR 只影響截圖物理像素，不進座標。
- driver 於 CSS 高度 ≤500 時直接報錯（該窗高會切換 640×360 基準，wide 模式 waypoint 不適用），要求改視窗再跑。

## 6. WAYPOINTS 派生依據（檔案:行）

座標為 logical 1280×720 內之中心點；帶「≈」者為依版面常數推導之估計，第一次執行務必以對應 step 截圖校正後再跑完整流程。

| waypoint | 座標 | 派生 |
| --- | --- | --- |
| `header_level_up`「修為晉階」 | (176, 68) | header PanelContainer 在 (28,28)、寬 320（`abode_hud_controller.gd:592-593`）；identity HBox 為第一可見子行，晉階按鈕 min 88×44（`143-148`），與右側突破按鈕相鄰（間距 12）；估面板內文 margin 12，晉階中心 = 336-104-12-44 |
| `header_breakthrough`「突破…」 | (284, 68) | 同上；突破按鈕 min 104×44（`150-155`）右緣 === 336（`28+320-12`），中心 284 |
| `dock_home`(洞府) | (72, 664) | toolbar 在 (28, 636)、高 56（`594-595`）；四主導鈕 (88,56)（`feature_navigation.gd:310`），第一顆中心 28+44 |
| `dock_management`(經營) | (168, 664) | 第二顆中心 28+88+8+44 |
| `dock_cultivation`(修行) | (264, 664) | 第三顆（`feature_navigation.gd:99` 把 reincarnation_button 移至 index 2） |
| `dock_journey`(遊歷) | (360, 664) | 第四顆 |
| `nav_*` 經營頁籤 | (822/906/990/1074, 46) | management 側欄 nav_width=min(560, 1280-320-56)（`feature_navigation.gd:350-352`），bar.x=1264-560=704、y=margin(16)；back seal 44 + 邊框 ~12；頁籤 min 80、間距 4（`356-360`）；GROUPS 順序 buildings/outposts/manufacturing/transport（`feature_navigation.gd:4`） |
| `catalog_scroll_zone` | (946, 400) | building_catalog bounds ≈ Rect2(644,84,620,544)（`feature_navigation.gd:364-366`；`building_workspace_width` = min(620, 1280-280)，`390-395`） |
| `gather_*` 採集 | (906/1194, 265/309/353) | catalog 內容區（邊框 12）：標題列 44 + 目標列 48 + 過濾列 48（`building_catalog.gd:80-129`）→ 資源格 top≈246，行高 38、v gap 6（`137-142,266-270`）；採集鈕 56×30 右貼（`207-221`）；2 欄各寬 ~286（`h_sep 6/8`） |
| `catalog_card_build_hut`(茅屋建造) | (902, 433) | 捲動區 top≈376＋核心群標題 ~24（`286-292`）→ 首卡 top≈403；materials_row 內升級鈕 64×44（`356-369`）右緣 = 卡右-8，中心 902（第 1 欄）；肖像鈕 104×108（`311`） |
| `catalog_card_upgrade_lingli`(聚靈壇) | (1196, 433) | 同上第 2 欄（x 950..1236） |
| `catalog_storage_candidates`(築基靈池/倉儲列) | (902, 433/477/521/565) | 核心群 1 行 + 生產 2 行 + 倉儲群（`living_abode.gd:704-732`）：估 foundation_reservoir 在倉儲第 5 位（era2 檔首筆，`content/buildings/era2.json:3`），以估 raw top ≈ 1027；配合 `wheel 240×3` 捲至可見 |
| `island_selector_wood/ore/herb` | (926/1026/1126, 160) | 空島面板 width=min(400, 1280*0.44)、x=1264-16-400=864、y=84（`feature_navigation.gd:333-334`）；selectors HFlow 鈕寬 ≥100（`island_management_panel.gd:72-78,102-113`） |
| `island_actions`(啟用/開拓列) | (1070, 214/258/302) | 面板 heading ≈90-134（`45-97`）；activation／opening 紐在 body 頂兩列（`140-145,195-208`） |
| `manufacturing_action_scan` | (1188, 190/240/390/540)、(800, 240/390) | 製造面 workspace large：width=min(820,1248)、x=1264-820=444（`feature_navigation.gd:333-341`）；配方單欄卡列（`manufacturing_panel.gd:61-103`），action 鈕 min 112 右貼（`78-81`），羅列以 wheel 240 逐段掃描 |
| `transport_route_scan` | (928, 232/354/476/598) | 運輸面 width=min(680,1248)、x=(1280-680)/2=300（`feature_navigation.gd:333-334`）；航線單欄卡列，每列 actions「啟航/設定」64 min 右貼（`island_transport_panel.gd:44-90`），逐列約 ~122 高掃描 |
| `transport_save_scan` | (400, 540/596) | 設定詳情中 save_button 欄（`island_transport_panel.gd:123-135`） |

## 7. Step 串流與可觀察條件（milestone）

全部條件只讀 `dao2_saves:save_index / save_main|save_backup` 的存檔 envelope：
`state.era_id / state.level / state.buildings.* / state.resources.<id>.value/cap / state.economy.{version,islands,jobs,trips,routes}`（save schema 見 `src/domain/game_state.gd:93-144`、`src/persistence/save_codec.gd`）。

| step | 操作 | 停止條件（observable） |
| --- | --- | --- |
| S00_launch | bringToFront、導航、必要的空白清存＋reload、等 ABODE_READY console 標記 | `consoleLines` 出現 `ABODE_READY:`（`src/abode/living_abode.gd:369`） |
| S01_hut_build | 經營；採集資源卡（讀取格 top 推導）；茅屋卡「建造」 | `state.buildings.hut >= 1` |
| S02_era1_level10 | 每 20 秒按 identity「修為晉階」 | `era_id==1 && level>=10`（自然時鐘 ~1007s） |
| S03_era1_capacity | 經營→候補點擊聚靈壇／倉儲列升級（wheel 240 掃描） | `era_id==1 && lingli cap>=500`（突破容量門檻，`abode_hud_controller.gd:880-884` 顯示「突破 · 容量未足」之需求值） |
| S04_breakthrough_foundation | 按「突破至築基期」 | `era_id>=2`；儲存後 sleep 12s 捕演出結束 |
| S05_era2_capacity | 經營→聚靈壇升到 2 級，再捲動 catalog 以候補座標升築基靈池（foundation_reservoir）到 2 級、待容 | `buildings.storage_lingli>=2` → `buildings.foundation_reservoir>=2` → `lingli cap>=2300 且 value>=2000`（100 基礎 + 儲靈倉儲2級 + 築基靈池2級×1000，對照 `d2-r1-natural-time-playthrough-protocol.md:87`） |
| S06_economy_open_wood_ore | 經營→空島頁籤→「保留原檔並啟用空島」→ 青木/玄礦開拓 | `economy.version>0` → `economy.islands.wood.opened` → `economy.islands.ore.opened` |
| S07_era2_level10 | 按「修為晉階」 | `era_id==2 && level>=10`（自然時鐘 ~2496s） |
| S08_breakthrough_gold | 按「突破至金丹期」 | `era_id>=3` |
| S09_open_herb | 經營→空島→丹霞→「開拓」（木20＋石10，`island_management_panel.gd:208` tooltip） | `economy.islands.herb.opened` |
| S10_route_liquid_home | 經營→運輸頁籤→候補掃航線列（啟航/設定）與設定詳情保存鈕 | `economy.routes` 含 `liquid_home` |
| S11_craft_liquid | 經營→製造頁籤→候補掃配方卡（liquid, 10s）；完成後被動等回運 | `economy.jobs` 有 `herb` 工作實例或 `trips.liquid_home` cargo>0；再被動等待 `resources.liquid.value>=1`（欄位形相對照 `res1d2_contract.gd:204-206`、`web_persistence_probe.gd:236`） |
| S12_t2_formation_core_stone_mid | 製造頁籤掃配方卡：formation_core → stone_mid | `resources.formation_core>=1`、`resources.stone_mid>=1` |
| S13_era3_level_up_consume | 按 identity「修為晉階」一次晉階 | `era_id==3 && level` 增加，且 formation_core / liquid / stone_mid / lingli 至少一項下降（對照 `res1-d2.md:37` 晉階扣料） |
| S14_reload_persistence | `Page.reload` 真實重載、等 load＋ABODE_READY | era／level／revision 保留且丹霞 opened 一致 |

每 step 成功／失敗都會輸出 `D2NATURAL: milestone=<name> ok=... detail=...` 行與 `step_done/step_error` JSONL；失敗追加 fail screenshot 與 save-dump，`exit 1`。

## 8. 證據分類畫面（逐一對照）

- 驅動每次點擊前重新讀畫布 rect（resize 安全），事件裡紀錄 viewport 與 logical 座標，作為「真實 CDP 滑鼠」證據。
- 每 step 首次與每 6 次點擊會有 screenshot；成功／失敗時必定截附 milestone 對照圖。
- milestone 狀態證據是 **save file 內容**（存檔傾印 + 事件中的 state 摘要），不依賴 HUD 可讀文字。
- Console 證據：driver 收集 `Runtime.consoleAPICalled`，ABODE_READY 判定與各 `OFFLINE_SETTLEMENT_/WEB_BACKGROUND_/SAVE_FAILED` 行為可由 events 檔過濾重放。

## 9. 校正巡檢（強制先行）

由於 T1 catalog 候補（storage/foundation 列）、空島、製造與運輸的介面座標部分靠推導，先跑：

```powershell
$env:RUN_STEPS="0-1"; node --experimental-websocket docs/verification/artifacts/res1d2-natural-mouse-runner.mjs
$env:RUN_STEPS="3-5"; node --experimental-websocket docs/verification/artifacts/res1d2-natural-mouse-runner.mjs
$env:RUN_STEPS="6-9"; node --experimental-websocket docs/verification/artifacts/res1d2-natural-mouse-runner.mjs
$env:RUN_STEPS="10-14"; node --experimental-websocket docs/verification/artifacts/res1d2-natural-mouse-runner.mjs
```

校正無誤後再以全流程（`RUN_STEPS` 不設）跑完整自然時間驗收；校正輪可在同一 origin 以 `RESET_SAVE=0` 加速（但里程碑證據必須以 `RESET_SAVE=1` 的完整 run 為準）。

檢查每 step 的 step-*.png 是否點中目標按鈕（茅屋建造、儲靈倉儲、築基靈池、空島啟用、運輸啟航等），若偏移，按實際畫面改 `WAYPOINTS` 對應座標後再升級完整 run。

## 10. 驗收宣告界線（未跑前不可宣稱）

- 未執行 runner 前，本檔案只證明座標派生與腳本存在，**不構成**自然時間滑鼠通關的驗收證據。
- 正式驗收需「完整 run」成功 + S13 重載 PASS + console 無 `SAVE_FAILED/LOAD_FAILED`（既有 Font/ObjectDB 退出診斷除外），並留存 screenshot/jsonl/save-dump。
- 本腳本不覆寫玩家常態 origin（4277 是隔離 origin）；它不使用 fixture、不 Seed 金丹檔、不使用 Debug 面板或任何 Runtime.evaluate 注入遊戲命令。

## 11. 已知限制

- catalog／空島／製造／運輸內部座標是推導估計，會受當時 UI 狀態（卡列數、資源可見數）影響：掃描式候補在錯誤座標上是零作用點擊（Godot 對 disabled 鈕不發 pressed），而在捲動掃描中理論上可能誤觸鄰近 recipe，因此執行時需檢閱事件流對照截圖後才判定 milestone 證據。
- 若中途發生真實 reload、頁面凍結或突破 Fx 序列仍在播放，clickLoop 的下一輪會自然等待後重試；Fx 播放中點擊不會誤發遊戲命令（HUD 期間遮罩）。
- 實機可玩性驗收不在本次範圍：實機觸控、DPR 2-3、跨瀏覽器、自然背景凍結屬 `d2-r1-natural-time-playthrough-protocol.md` 未完成項。
