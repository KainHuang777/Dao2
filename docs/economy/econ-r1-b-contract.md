# ECON-R1-B 新版 profile 與研究契約

> 本文記錄 B 階段契約。C 已提供獨立正式內容工廠、R01–R07 與消費者接線，並提升外層 rules/economy 至2；現行差異見 [C 契約](econ-r1-c-contract.md)。B 空表／無新設備的敘述保留原階段範圍。

這是核心接口規格；結案與執行結果只記於 [開發狀態](../development-status.md#econ-r1-b)。產品方向沿 [docs52](../52-economy-reconstruction-reference.md)。

## 保存與呼叫邊界

`EconomyProfile.open(content, adapter, catalog, create, seed)` 是明確 opt-in 的新版應用入口。`content/research/econ_r1.json` 在 B 為空研究表；C 才加入 R01–R07 與經濟門檻。現有遊戲 launcher／Godot 場景仍走原 GameSession，B 沒有對外發布新版玩法或更換舊入口。

新版使用固定 `econ_r1_` key 前綴，包括 `save_main`／`save_backup`／`save_index`，不讀取或搬入無前綴的舊版槽。正式 Web 接線時 adapter 仍須取得既有 WebStorageAdapter lifetime writer lock；前綴不能代替互斥鎖。本階段只驗證 CLI／隔離檔案與 MemoryAdapter，不把它稱作 Chrome 或真實 localStorage／quota 驗收。

快照是「既有 GameState 的 SaveCodec envelope ＋研究狀態」的組合，避免給舊 GameState／codec 增加未啟用的欄位。外層具 `profile=dao2-econ-r1`、schema=1、rules=`econ-r1-rules-1`、economy=`econ-r1-economy-1`、research=`econ-r1-research-1`、content version、研究表 SHA256、完整 payload checksum。外層 `revision` 是保存代數，`core_revision` 是命令／模擬 revision；小數秒沒有執行 tick 時，保存代數仍能可靠選出新候選。舊版 decoder 拒絕此外層；`inspect_save` 是不安裝狀態的版本／匯入預檢，舊檔返回 `PROFILE_LEGACY_UNSUPPORTED` 並指向原版入口。

每個 `submit`／`advance_time` 先複製 Session 與研究狀態，完整 encode→decode 驗證，保存前歸檔上一份完整原文到固定 `source_before_commit`（保留最近一次來源，不無界累加），再沿既有 SaveSlots 寫入、完整讀回與雙槽輪替。成功後才替換 live state。任何拒寫、拒讀、讀回不符或索引故障保留同一份 `_pending` bytes；期間命令與時間停止，`retry_save` 不再執行支付／收益／輪迴。候選已寫入但未更新索引，重開可選出較新有效代數；命令 receipt 隨候選保存。

已存在、損壞、讀取遭拒與僅剩索引的 profile 都不默認重建。有效checksum的未知版本不能因另一槽仍有舊版而靜默降版覆寫。版本或研究表變更明確拒載；B 不提供自動版本遷移。未來新增版本遷移時必須維持來源原文、候選驗證與同候選重試，不能直接變更版本字串後重算舊工作。新版原版皆保持獨立，整批凍結舊版包／切換入口仍屬 F。

## 研究規則

研究表最多64個節點，穩定 ID、Era2–6、既有研習設施、前置 DAG、正整數材料、10秒至7天基礎工時與具名能力。驗證缺失／重複前置、環、倒置 Era、未知資源與設施；跨研究／設備／首購容量的完整可達證明屬 C／D，單純 DAG 通過不代表經濟已可達。

研究從祖島已解鎖可用庫存一次原子付款；缺一項不扣任何材料。單一工作槽，開工凍結材料、工作版本、有效秒數、效果明細與能力結果。取消不退試製材料、不發傳承、釋放工作槽。未完成不得使用能力；`has_unlock` 只讀當世完成集合。後續配方／設施資格須在 C 權威命令處接此接口，不能只在 UI 隱藏。

時間沿現有 `GameSession.advance_time`，每秒先執行原有生產／運輸／製造／BUFF／壽盡邊界，再為實際執行的同一 tick 推進研究。最後一個存活 tick 可以完工，壽盡後不再進度；不自動排下一項研究。相對時間測試接口 `advance_time` 每次上限48h；正式UTC入口 `settle_to(now_utc_ms)`沿 OfflineSettlement.plan 的24h有效收益上限，超額只推進既有時間效果，不繼續研究。第一次只建立UTC錨點，時鐘倒退不移游標；觀測UTC與候選一起提交，拒寫保留舊游標，重載同UTC不重領、超額時間不成為下次時間債。相對接口若已有UTC錨點亦同步前推游標。尚未提供新的長離線效能快徑或 UI yield coordinator。

輪迴仍先走正式 `reincarnate` 資格與結算；成功的同一候選清除研究完成集合與在研工作，保留 `mastered` 唯一完成集合。沒有新增研究貨幣或每輪可重領的獎勵；既有宗門／道心／技能規則不變。研究設施未新增，因此沒有新建築擠入輪迴獎勵計數。

研究傳承暫採最深已完成研究深度達1／3／6，原始研究時間減免為0.15／0.30／0.50；三檔取最高，不累加、不按重研次數發放。深度從前置 DAG 推導，不能由內容任意填數。這些是 B 的候選參數，C／D 仍須量測。前沿在輪迴同一候選結算到 `inherited_depth`，下一世才生效，首世完成研究不提前獲得研究傳承。它只進研究工時 resolver，不減試製材料、不送設備／成品、不略過當世研究、Era 或設施資格。工時下限10秒。

## 效果與取整

`EconomyEffects` 僅供新版，現版 BuildingCosts／加工／突破機率不改。每項來源有 `effect_id/family/scope/unit/stack_mode/limit/source/value`；同 family 與 scope 先加總再套一次 docs52 的 D(x,L)，重複 effect_id、負數、非有限數及混用單位拒絕。

| family | limit | B 的消費者／邊界 |
| --- | ---: | --- |
| building_cost | 0.80 | 統一成本 quote，C 再接新版建築 |
| processing_cost | 0.50 | 統一成本 quote，C 再接可折原料 |
| work_time | 0.70 | 統一工時 quote，至少1 tick |
| research_inheritance | 0.70 | 已接研究開工，至少10秒 |

成本只支援 Amount layer0、正值與總支付≤1e12；必要離散構件要求整數且不折扣。可折原料逐件向上取到1e-6，再乘批數；單件／批量共用同一 quote，拆批不會少付，極小正費用不變成免費。成本與時間 quote 都重新驗證 resolver 明細，不接受呼叫者偽造 effective reduction。普通產率、容量與突破機率未套此 DR；負面效果不塞進正收益來源抵消。

## 後續接線

C 需先完成前階可造研習席／工坊、R01–R07、研究資格與實際消費接口、首購容量、空白散修賺得路徑與第二世重研證據，再決定首個新構件是否有必要。E 才做共用研究 UI；F 做整批候選與舊入口凍結。此文件的測試 fixture 科技與注入庫存僅為隔離契約，不宣稱新檔主線已完成或80–160h節奏已平衡。
