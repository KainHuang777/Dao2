# RES1-D2 / D2-R1 自然時間真實滑鼠 Web 驗收（2026-10-16）

狀態：IN_PROGRESS。不得將本文的局部里程碑當作完整流程 PASS。

本輪使用者明確同意沿用 Edge / CDP 真實滑鼠驅動器。隔離 origin 為
`http://127.0.0.1:4306/index.html`，Edge guest profile 位於
`build/d2-natural-edge-20261016`，CDP port 9237。未存取玩家 4175 origin。
從空白新檔開始，不載入 fixture，不注入命令、資源或遊戲時間，不啟用 Debug。
瀏覽器層固定 1280×720 / DPR 1，使用 focus emulation 維持有頭分頁焦點；
此設定不適用於自然背景凍結驗收，本輪亦不作該項聲稱。

## 證據與工具

- `artifacts/d2-natural-20261016/00-start.json` 保存空白 state（所有建築為零）。
- 同目錄 `events.jsonl`：每項輸入前後原始存檔、UTC、瀏覽器幾何與動作；
  同名 JSON / PNG 為各步保存與截圖；`console.jsonl` 保存連線期間 console。
- `tools/d2_natural_control.mjs --queue` 保持單一 CDP 連線，僅執行觀察後指定的
  真實滑鼠 / 滾輪 / reload；唯讀 localStorage 用於驗證。佇列 `.running`
  代表中斷，不能當作已完成；`.done` 也必須核對 JSON / PNG 的結果。
- 正常 Web PCK SHA256：`0AD748E7BCB9F96BF98B2DED9B5585681FBA395D046FA1B0E32F183FE936BDDA`。
- Godot `--version`：`4.7.2.stable.official.ed1daf0bf`，exit 0。
- `res1d2_integration_runner.gd`：247 checks PASS / exit 0，見同目錄
  `integration.log`。初始 user log 目錄權限診斷及預期 corrupt JSON 負面診斷保留；
  CLI 不代替滑鼠、保存或畫面驗收。

## 舊腳本缺口與本輪進度

舊 S02 只補靈木至 20，但練氣三層起每次晉階需要靈木 40；這直接解釋
10/14 的 level=3 / wood=20 停滯。已修正補料門檻、S01 / S02 逾時拋錯、
mouseReleased 的 buttons=0，並加入 CDP 請求逾時。
舊容量讀值依賴存檔中不存在的 resources.cap，不能作容量證據；
後續必須核對正式介面及設施，不能將舊 summary 中的 0 當作真實容量。
舊 S03–S14 的大量估算座標尚未完整校正，不宣稱舊全流程腳本可無人值守通過。

已驗：空白啟動、實採 20 靈氣、世界藍圖建茅屋、茅屋2 / 木屋2 / 林場3 /
採石場3 / 靈植場3 / 聚靈壇2、四倉儲，真實扣料升至練氣十層及築基。
`28-foundation-result.png` 完整演出後明示已保存；`30-pool2-islands.png`
顯示築基靈池2、實際容量2420。雙島各付木20 / 石10、四航線啟航，
銅精 / 靈材均以 UI 設為持續製作；`51-supply-running.json` 的 early_supply
顯示 ore_delivered=5、timber_done / bronze_done=true、兩種 home 到貨=1。

實際 Web 發現新缺口：核心已核定 Era2 祖島丹液，但 manufacturing_view
仍把丹液固定指向未開丹霞。已補 Era2 的 home 呈現、Era3 保留 herb；
無配方 / 成本 / 時間 / 保存 schema 變更。新增三項 UI / 核心命令一致性回歸，
UI1-A 223、UI1-B 220、D2 247 checks 均 exit0。首次新增測試型別推斷 parse error
已修正（初次錯誤在對話工具輸出，重跑日誌為最終結果）；
最終既有 RID / ObjectDB 退出診斷保留。更新共用規範中的丹液入口說明。
Web export / compression exit0，新 PCK SHA256
`8C25174F9F1BEE125F4FF7A8B60787F005214B8DF36047E38ECECE24BCB1D8B0`。
已在同一自然進度重載修正版（`53-reload-ui-fix`，離線13秒正常結算）；
`54-new-liquid-entry.png` / `55-home-liquid-detail.png` 證明祖島丹液已可操作。
整段證據跨此明確修復版本邊界，
不能稱為單一未變更匯出包的無修復通關。

仍待：築基後續位階、金丹、丹霞丹液回運、
陣芯 / 中品石與金丹扣料晉階、加工中與60秒後兩次重載、短橫式。
人工美術 / 節奏、實體觸控 / 高 DPR 與其他平台保持獨立待驗。

### 本輪交接點

`60-liquid-start-level2.json` 已確認祖島 UI 指定批數39（啟動首批後 batches=38）、
實扣配方材料並完成築基1→2（靈材20 / 銅精10 / 靈氣200）。
`61-foundation2-checkpoint.json` 已有祖島丹液5，不再把「實際製作」列為未驗；
同名 PNG 是階段結束畫面。尚未達成金丹與丹霞最終驗收，完整 D2-R1 / D2 / D
保持 IN_PROGRESS。

依 AGENTS Context Guard，停止在此有界階段、轉新對話續驗。已啟動有界
`D2_ERA=2 node --experimental-websocket tools/d2_natural_levels.mjs`，只在正常
時間 / 材料足夠時點已校正的 header；到築基十層即停，不自動突破。
啟動時 PID=14944，存於 `artifacts/d2-natural-20261016/levels-era2.pid`；
stdout 在 `era2-levels-console.log`，每分鐘與每次晉階前後原始存檔在 `levels.jsonl`。
下一對話先核對存活與最新狀態，勿重啟第二份同時點擊。若已停止，保留原分頁、
讀取同一存檔後再恢復同命令；不 RESET_SAVE、不 seed、不重做已過練氣段。

服務4306、Edge9237、UI queue controller（當時 tool session23622）保留作接續。
無 pending queue mutation；008.json.running 是已中斷的舊採集批次，不可重排執行。
未 commit / push。接續：築基十層→金丹→丹霞丹液加工回運→陣芯 / 中品石50
→金丹扣料晉階→加工中重載及自然60秒後重載、短橫式 / console 稽核。

正常引擎命令使用 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`：
`--version`、`--headless --path . --script res://tests/res1_ui1a_runner.gd`、
`res1_ui1b_runner.gd`、`res1d2_integration_runner.gd`（各自 log-file 見 artifacts），
`--headless --path . --export-release Web build/web/index.html`；壓縮命令
`node tools/prepare_web_compression.mjs build/web`。最終上述均 exit0。
三個 JS 控制器 / driver / runner 的 `node --check` 與本輪三個修改來源的
`git diff --check` exit0；Git 僅提示既有 CRLF 正規化，未作提交。
未重跑全67 Runner；不援用歷史全量結果作本輪驗證。

追加文件檢查：擴及整份 development-status / updata 的 diff-check 非零，
涉及保留的10/14、10/13歷史交接行尾空白及文件 EOF 空行；記錄於
`historical-doc-diff-check.log`。本輪程式 / 測試 / 共用規範 / Roadmap 的
限定檢查仍 exit0（`focused-diff-check.log`）。updata 統一原 HEAD 的 LF
換行，避免混合 CRLF 造成整份歷史出現假差異，文字內容保持。
最終交接觀測 `62-live-checkpoint` 已到築基三層；背景程序仍只以自然時間
等待後續位階，第一輪完整金丹 / 丹霞驗收沒有完成。

## 環境診斷

初始沙箱內 server 雖印出網址但 loopback 不通；外部啟動後 IAB 正常載入。
IAB 工具每次輸出大量 Statsig / Cloudflare 403 遙測診斷，使用者同意改用既有 CDP。
未繞過安全頁或修改網路安全設定。最初的短連線 / 背景切換及中斷批次
不能當作穩定在線證據；focus emulation 後各項輸入已逐一保存核對。

## 2026-10-16 同一進度續驗：築基十層已確認，renderer 中斷

先查系統層程序：原4306服務PID51952、Edge9237 PID32132與queue PID36828仍在；未重複啟動。Era2自然晉階log最後為`LEVEL_VERIFIED 2:10`與`LEVEL_SEQUENCE_COMPLETE era=2`，01:56:37正常停在十層。

原queue執行063後取得`63-resume-era2-level10.json/png`：era2／level10、total_elapsed_seconds12000、training0，畫面壽元0/200；丹液14、靈材100、銅精100、靈氣2783。沒有重設或seed。

僅送一次064點擊(352,69)嘗試正常突破；064成為`.done`但沒有對應JSON/PNG。控制器catch錯誤後仍可rename done，因此不能當成功。65／66唯讀核對均於Page.enable逾時15秒，未取得新存檔；第一次沙箱連線EACCES。系統層確認原程序仍活，先前沙箱Get-Process不可見的退出誤判已更正。HTTP /json/list保留原分頁385C76D06CF5E5AE03F49378EEBEFD38；activate成功。Browser Target.getTargets回覆attached=true,pid=0，但分頁Runtime.evaluate七秒內無回應；CIM此guest profile已無renderer。這是環境中斷證據，不能推論壽元已盡必定阻擋突破。

本輪`--version`exit0=4.7.2；沒有來源變更，未重跑已通過runner／FPS。所有原服務／控制器／瀏覽器保留，未reload／kill／重啟，未改存檔。只新增診斷與交接文件；無commit/push。下一步先安全恢復同一分頁，讀檔截圖確認064是否曾送達，再接金丹／丹霞加工回運／T3實付晉階／兩次重載／短橫式。不可重播064或舊008。完整D2-R1／D2／D保持IN_PROGRESS。

## 2026-10-16 恢復與存檔重建（RESTORED 溯源）

重啟核查：原三程序（服務51952／Edge32132／控制器36828）全數消失（4306／9237無監聽、CIM無PID、node/python/msedge為0），屬重開機或關機，無重複啟動風險。同一命令重啟：`tools/island_preview_server.py --port 4306 --normal-build`（PID104684）、Edge guest 同profile `build/d2-natural-edge-20261016` CDP9237（PID105876）、`node --experimental-websocket tools/d2_natural_control.mjs --queue`。

存檔遺失診斷：本遊戲 Web 存檔為 localStorage（`src/persistence/web_storage_adapter.gd`，鍵 `dao2_saves:save_main`／`save_index`）。Edge Guest profile 的儲存是暫時性，guest session 關閉即清空。掃描兩處 guest 目錄（共7300+檔）的 ASCII／UTF-16LE 位元組均無 `dao2_saves`／`era_id` 痕跡；leveldb 僅剩空 log。結論：自然即時存檔無法由磁碟救回；最後權威狀態為 `63-resume-era2-level10.json` 內的解析快照。

使用者核定方案A：由63證據重建存檔並經 CDP 注入同一 profile／origin。新增 `tools/restore_save_from_evidence_63.gd`（SceneTree headless：讀63 after.state、重播boot content路徑取得真實 content_version、補造 save_id／saved_at／settled_until／sim_tick／rng_streams／last_offline_report、依 encode() 序列重算 checksum、先以 SaveCodec.decode() 做前置驗證）與 `tools/inject_restore_save.mjs`（CDP setItem save_main+save_index、Page.reload、12秒）。結果 decode_ok=true、revision 12107、checksum `1587e4ac…2c34a`；注入後遊戲即自行 commit（save_backup 出現）。**溯源標記：此線為 RESTORED（重建），不是 natural-continuous；所有後續證據須帶此標記。** 65-restore-checkpoint 與63 after.state 的38鍵深比對僅 revision 12107→12109（遊戲正常commit），資源／建築／經濟完全一致。

064是否生效：永遠無法回溯證明。65 PNG 顯示離線收益摘要modal（壽元耗盡停止）恰覆蓋064座標(352,69)，說明該點擊極可能未達突破按鈕。突破行為改以一次全新受控測試取代：68-golden-breakthrough-retest 點擊(352,70) → 立即 commit：era 3、level 1、revision 12110。**結論：壽元0/200耗盡未阻擋大境界突破**；突破後壽元重置為538/740祀。69跳過演出、71圓滿出關；70有破境餘韻buff（全產+20%／修煉+30%，120秒）。

## 2026-10-16 金丹鏈分段（RESTORED 線）

- 丹霞開拓：75-activate-danxia 點「開拓丹霞島」→ herb.opened=true、木-20／下品石-10、receipt island_opened；開採自動（低階靈草64+2/秒、百年靈草32+1/秒）。
- 丹液持續產線：82點(1128,411)因面板壓縮落空（無job、無錯誤提示）→ 82 PNG 定位修正：丹液卡為左欄，製作一批(767,437)、header(601,437)。85重擊後 86→88 由 header 詳情設「持續製作」→ herb job liquid repeat=true running，靈氣每批-50（全域池讀取，跨島不需先運靈氣）。
- 丹液回運航線：運輸分頁滾輪無效，用航線篩選下拉(903,116)選丹霞島→丹液卡啟航(467,399)→ routes.liquid_home enabled level1 target100；97確認 trips.liquid_home cargo1 航行中（丹霞→祖島回運成立）。
- 中品靈石持續產線：94五連點→ home job stone_mid repeat=true running；102/103 poll 47→56。
- 合成tab（96）：靈紋陣芯=formation_core配方（靈木2+玄銅2→1，20秒/批，卡(767,209)）；金丹丹藥／符咒亦列出。產線占用時其他卡顯示「查看／切方」。
- 停線語義：101「本批後停止」→ repeat=false、processing_stopped_after_batch、批次完成後job清除。版面漂移教訓：頂欄座標隨島面板位移（寬版510-774／窄版769-1034），modal 可能整個關閉，每次點擊前須以最新PNG核位。
- formation_core：105「製作一批」→ remaining 20；106 poll formation_core=1 ✓。
- 金丹扣料晉階：107修行面板「修為晉階」(300,67) → 108 成功 level 1→2（金丹期2/10層），實扣與 era3 level_up_requirements 完全一致：中品靈石-50（62→12）、金錢-500（1334→834）、陣芯-1、丹液-1、靈氣-2000（2155→283，含同期回復干擾）；receipt cultivation_leveled_up。（首次regex誤讀before的level=1，已以 LAST "era_id" 段重取確認 level=2。）

## 2026-10-16 加工中重載與短橫式（RESTORED 線）

- 110 重設中品靈石 repeat=true（remaining 10）。
- 111 {reload:true} 加工中 Page.reload+10秒 → after 仍有 home job stone_mid repeat=true remaining=3 running：**加工任務跨重載存活 ✓**。
- 自然60秒後 112 唯讀checkpoint → remaining=8 running：**自然時間續作 ✓**（第二次重載由111+60秒時間軸覆蓋）。
- 短橫式：新 `tools/short_landscape_evidence.mjs`（CDP 844×390→800×360→1280×720，截圖+localStorage+Runtime/Log console 捕捉）。首批113/114被離線摘要modal遮擋，另寫 `tools/short_landscape_close_modal.mjs` 關閉後取得乾淨 113-short-landscape-844-closed.png／114-short-landscape-800-closed.png：金丹期2/10層・功滿待晉階、壽元494/740、資源chips、島嶼nav單行、四dock與資源模式無重疊無捲軸。console 僅1條良性 AudioContext autoplay 警告，0 錯誤；saveAtShortLandscape revision 14796 era3 level2。115 回復1280×720。

最終程序：服務 PID104684（4306）、Edge guest PID105876（CDP9237）、控制器 PID112180（重啟後第二份，log queue-controller-restore2.*）。

**狀態：使用者核定之金丹鏈分段（突破／丹霞開啟／丹液加工回運／陣芯／中品石／扣料晉階／加工中重載／自然60秒／短橫式／console）已全數取得證據，但整線為 RESTORED（存檔重建）溯源，且人工美術／節奏、實體觸控／高DPR等仍待驗；完整 D2-R1／D2／D 保持 IN_PROGRESS，不標DONE。064成效不可回溯、不在任何結論中引用。無 commit/push。**