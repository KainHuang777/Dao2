# CONTENT-P2-BEAST／BEAST-1 核心與保存驗收

2026-10-26。**BEAST-1 DONE；整批 IN_PROGRESS，BEAST-2 TODO。** 使用者明確回覆「採 X，接 BEAST-1」，X1／X2／X3／X-save／X-art 原案核定；製圖計畫核定不等於實際美術接受。見[方案 X](../39-content-p2-beast-design.md)與[機讀表](../design-data/content-p2-beasts-proposal.json)。

本段是 **L1＋L2 領域驗收，matrix=single（1280×720）**。保存、輪迴、地方容量與時間為共用依賴，故總計14支唯一相關 runner，分批精選，每批1–5支；未做全量、全尺寸、Web、匯出或L3。合成 fixture 的即時設境／開島／補料／補魂不代表自然取得。

## 交付

- 正式6獸／24獸魂天賦。新增霜角鹿（Era4＋供給＋deep已開，10鐵20草／餵）與銜芝鶴（Era5＋供給＋ancient已開，5百草2千草／餵）；沿單世一獸，無換獸命令。舊4獸／16天賦定義與排序、`compute_multipliers`／`feed_costs` 原文保持。
- 新獸每餵50XP，T2為65XP；累積100／500／1000升階，冷卻300秒。T3逐資源取六成整數且最低1；同一 `feed_costs` 供付款與View。U／W仍只龜鳳，P1仍只靈狐。缺料／冷卻／成熟／壽盡拒絕不扣料、不重設冷卻、不增revision。
- `acquire_requirements` 為命令與View共用純資格投影。核對發現GameSession沒有原設計假定的全面獸命令壽盡鎖，因此**只對本批新獸**明確採既有P2壽元算法；未改舊四獸壽盡行為。正式遷移與保存故障沿既有共同保護。
- `local_rate_multiplier` 僅deep三礦或ancient千草；階段0／10%／15%／20%，T1非卵階段各加1百分點。獨立乘既有調度、SKS、拓脈與古藥丹通道；祖島、錯島、錯資源不增。`local_capacity_bonus` 為永久指定島+30，僅開島生效，與SKS容量相加，不加祖島或運輸容量。
- IslandEconomy rate／tick／tick_prepared、TimeAdvancer、IslandProgression有效容量、製造View與既有預留／到貨通道已接。準備快取以獸版本、生命序號、活動獸／階段及獸魂天賦簽章失效；冷卻逐秒倒數不改XP／獸魂。供給離線沿權威逐秒路徑。
- 新8天賦按同獸前階購入，魂價1／2／3／5，累計11魂。成熟當下不授魂，正式輪迴成熟才1魂、未成熟0魂；六獸達魂上限時在輪迴任何修改前原子拒絕。
- schema5、`beast_version=1`、rules `core-flow-23-content-p2-beasts`、供給tag `+content-p2-beasts`；economy維持`res1-e-46-1`。GameState預設／duplicate／snapshot、正式新Session與供給attach、codec及load/import接線。獸v1規則優先於宗門；legacy0保留舊宗門／丹藥／天賦分支。
- `BeastSaveContract` 限三欄合計64KiB、6獸／24天賦、整數魂／XP上限、階段與XP一致、冷卻[0,300]、未知鍵／未來版本／缺前階拒讀；JSON整值數字正規化為int。legacy0僅4／16，合法資料原值保留，不重驗舊獸開島資格、不送魂；畸形舊檔明確拒讀，沒有全量舊檔相容承諾。
- 獨立`_beasts_original`／`_beasts_candidate`，原文雜湊歸檔＋逐字讀回後才提交同候選；`BEAST_SAVE_REQUIRED`鎖命令、時間與離線。歸檔讀寫／損壞、救援讀寫、主槽讀回與索引失敗只重試保存。第二次share／legacy import不能換原文或候選；供給／獸／宗門／丹藥／天賦五份併行遷移原文均保留。

## 命令與結果

既有引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`。未更新引擎／模板。最終同版`--headless --editor --path . --import --quit` exit0，無SCRIPT ERROR；見[匯入日誌](artifacts/content-p2-beasts/import-complete.log)。

每批由`tools/run_beast1_checks.ps1 -Only '<精選完整檔名>'`先執行`run_all_runners.ps1 -Only ... -List`，再同選取執行；預設45秒，日誌與隔離儲存留在專案。唯一離線長測試以`-TimeoutSeconds 240`重跑。14支最終分段通過，精確路徑見[runner摘要](artifacts/content-p2-beasts/runner-summary.json)：

| 範圍 | 唯一runner |
| --- | --- |
| 新核心／保存 | content_p2_beasts（1656 checks）、content_p2_beasts_save（998 checks） |
| 舊獸／輪迴／Session | m3b_spirit_beast、m3a_reincarnation、m4a_session_integration |
| 保存相依 | m1c_persistence、m1e_import、content_p2_sect_save、content_p2_pills_save |
| 地方／數值／離線 | content_p2_supply_economy、sks_p2_core、content_p2_talents、content_p2_sect、offline_closed_form_parity |

`python tools/beast1_delivery.py restore` exit0：26389份既有JSON核對，1份變動先另存後逐字復原；見[復原紀錄](artifacts/content-p2-beasts/restore.json)。`python tools/beast1_delivery.py audit` exit0：27844項、failures=[]，核對原獸／天賦／排序／舊倍率與餵費、方案逐欄、相關runner及既有來源／資產／content／設定／正常Web PCK保護，見[交付稽核](artifacts/content-p2-beasts/delivery.json)與[來源hash](artifacts/content-p2-beasts/source-hashes.json)。來源`git diff --check` exit0（Git的LF／CRLF提示保留）。

## 失敗沿革與界線

首次新runner有兩個型別推斷錯誤，codec自動插入造成重複區域變數；修正後通過。保存斷言最初將JSON整值float與原始int／cooldown字串序列化差別當進度變動，改為數值正規化後比較，沒有放寬契約。舊獸數量4→6及保存／SKS／供給的規則身份斷言已更新；不是修改遊戲數值來迎合測試。

離線一致性runner預設45秒逾時（失敗保留），確認其兩日逐秒參考工作量後，單支240秒watchdog重跑於95.9秒通過。原命令exit1與全部stdout／stderr留在[runs](artifacts/content-p2-beasts/runs/)，不是初跑全綠。歸檔備份中的GDScript已轉成`.gd.txt`，避免被Godot當第二份全域類別；最終匯入通過。

沙箱無法開`user://` log、預期NaN／畸形JSON負面診斷、既有巢狀project提示均保留；不宣稱日誌零錯誤。測試只用Memory adapter／專案隔離路徑，未讀寫玩家存檔。沒有Web滑鼠／FPS／自然成熟／美術接受聲稱，也未commit或push。

## 修改檔案與下一步

核心：`src/domain/game_state.gd`；`src/simulation/beast_system.gd`、`island_economy.gd`、`island_progression.gd`、`time_advancer.gd`、`reincarnation_rules.gd`、`command_processor.gd`。保存：新增`src/persistence/beast_save_contract.gd`及UID，更新`save_codec.gd`／`save_manager.gd`。

新增兩支beasts runner及UID；更新舊獸、供給economy、P2宗門save、P2丹藥save、SKS核心五支的數量／規則身份斷言。工具：runner清單、`run_beast1_checks.ps1`、`beast1_delivery.py`；一次性實作工具原文與修改前來源保存在本段artifacts。同步方案、proposal、Roadmap、README、擴充計畫、handoff、development-status、英文updata。

依Context Guard在本階段停止。**下一New Chat接同批BEAST-2**：兩卡／兩張內建ImageGen透明獸圖及來源紀錄，兩條獨立已賺得Era4／Era5起點的正式結契／逐次餵養成熟、至少一條正式輪迴1魂→T1→下世保存重載；舊龜鳳代表餵養。當次1280×720桌面Web真滑鼠、八天賦合成魂fixture與保存拒寫／重試／恢復／重載。不可把本段合成補料／補魂當自然養成，不重問X，不開其他P2／P3。兩圖／卡片／節奏接受後才整批唯一L3收尾。
