# M3-B-CONTENT-AUDIT：Dao1／Dao2 資源、建築與合成承接檢查

日期：2026-10-02。狀態：**DONE（檢查與模型評估）**；內容承接與缺陷修復尚未實作。

使用者本次要求優先核對三份清單及 Era 2 新內容缺口，並在搬資料前評估數據模型。本輪不調整玩家數值、不改存檔、不修改 Dao1、不開展下一個大型實作。

## 結論

Dao2 採用的是 **Dao1 開局資源／建築子集＋另外設計的簡化丹藥**，並非完整移植。Era 2 沒有新建築／資源，是內容缺席與承接架構尚未補齊的實際問題，不只是 UI 沒刷新。目前能首次升境、輪迴與跨界，不等同於完整的十二境界經濟進程。

| 清單 | 本機 Dao1 | Dao2 正式載入 | 核對結論 |
| --- | ---: | ---: | --- |
| 資源 | 61（basic 12／advance 19／crafted 30） | 7 | 七筆的 type／基礎 max／rate／unlocked 都與 Dao1 相符，但未保留解鎖與配方欄位 |
| 建築（含倉儲） | 59（buildings 49＋storage 10） | 10 | 十筆 Era 1 的成本、倍率、等級上限、建築前置、產率／容量效果與權重的映射一致；不是全境界資料 |
| 通用合成 | 30 個帶 recipe 的資源 | 0 個通用 craft 命令／配方表 | 另有 hardcode 三種煉丹：聚靈丹、延壽丹、築基丹；不等於 Dao1 的三十個配方 |

逐項完整清單見 [inventory.md](artifacts/content-progression-audit/inventory.md)；原始列、數值對照與 SHA-256 見 [catalogs.json](artifacts/content-progression-audit/catalogs.json)。只計算有 ID 的有效 CSV 記錄，不以空白列湊數。

## 來源身分與邊界

- 使用者提供的 Dao1Root：`D:\Temp\temp\Dao\Dao`，對應歷史 `E:\Python\test1`。Dao2Root：`D:\Temp\temp\Dao2`。
- Dao1 HEAD：`bdaca10c3b351387830a3c86f3eac175f3a1d803`；唯一已觀察 dirty 項為 `update.txt`。唯讀查詢，不啟動 Dao1／安裝套件／修改來源。
- Dao2 HEAD：`b9f6685`，本機分支 `master`；本輪保留既有 BGM runner 修正、驗收 PNG、ENV／WEB 文件與交接變更。
- 五份 CSV 的 `src/data` 與 `public/data` bytes 一致；沒有發現這五份資料的來源／公開副本分歧。
- 對比 2026-09-14 的固定 manifest：只有 `buildings.csv` SHA-256 相同；Resources／storage／eras／skills 四份不同。歷史來源 profile 與此 clone 不可直接視為相同。保留原 M0-B／C fixture，不覆寫其標準答案；後續承接建立新 profile 與實際 reference fixtures。
- Git 首次唯讀查詢因來源 ownership 檢查失敗。之後使用單次 `git -c safe.directory=...`，重跑工具另加 `--no-optional-locks`；未寫 global Git config、未修改 ACL。

## 三份清單的具體承接

### 資源與建築

現有資源：`lingli`、`money`、`wood`、`stone_low`、`black_copper`、`spirit_grass_low`、`foundation_pill`。

現有建築：`hut`、`wooden_house`、`forest_farm`、`stone_mine`、`herb_farm`，以及 `storage_lingli/money/wood/stone/herb` 五種倉儲。基礎 JSON 並非亂造；但它們只覆蓋練氣期切片，顯示名稱及部分正式規則已有 v2 修正，不能以 JSON 欄位一致推論全部 runtime 行為一致。參見 [規則差異](../rule-differences.md)。

Dao1 築基期有 **11 項新建築候選**（6 生產／知識＋5 倉儲）：

| ID | 名稱／作用 | 漸進揭露重點 |
| --- | --- | --- |
| library | 藏書閣；技能點與靈力 | Era 2 的第一個知識入口 |
| scripture_hall | 藏經閣；技能點容量 | 藏書閣＋基礎吐納後 |
| hunter_camp | 狩獵營；獸皮、獸骨 | 基礎吐納後 |
| iron_mine | 鐵礦；精鐵 | 狩獵營後 |
| stone_mine_mid | 靈石礦脈；提高下品靈石產量 | 鐵礦後，另檢查 CSV 建築／功法前置 |
| rice_field | 靈田；靈米 | 鐵礦 2 級後，另檢查功法前置 |
| storage_lingli_mid | 中級聚靈陣 | 藏書閣與基礎聚靈陣 |
| storage_stone_mid | 中級靈石庫 | 中級聚靈陣後 |
| storage_wood_mid | 中級木料場 | 中級靈石庫後 |
| storage_money_mid | 中級錢莊 | 中級木料場後 |
| storage_herb_mid | 中級百草閣 | 中級錢莊後 |

此表概括 Dao1 `src/balance/rules/progressionUnlocks.ts` 的 reveal／unlockWhen，並非宣稱升境就全量可建。Dao1 同時檢查 CSV 的 `prereqBuilding`／`prereqTech`；承接時要保存兩層語意，不能只搬 `era=2`。

Era 2 資源進程包括技能點、獸皮、獸骨、精鐵、靈米，以及銅精／丹液加工。初級妖丹雖然 CSV 為 Era 2 配方，漸進條件要求曾取得初級獸晶，而獸晶主來源是 Era 3 獵殺營；不能把它當成正常築基初期即時可用的新配方。CSV 中四種資源的 prereqEra=2 不等於所有實際築基新增資源，因為其他資源由產地建築揭露。

### 合成與丹藥：已有明確重設計

| 項目 | Dao1 | Dao2 |
| --- | --- | --- |
| foundation_pill／築基丹原料 | 低階靈草 3＋靈力 50 | 低階靈草 50＋玄銅 20＋靈力 200 |
| 築基丹使用語意 | 通用合成物品，突破輔助另經原作系統處理 | 服用累積當世產率加成 10%；是另一套 consumable 語意 |
| longevity_pill／延壽丹 | ID longevity_pill，Era 4＋heavenly_craft；百年靈草／中品靈石／丹液／秘銀配方 | ID lifespan_pill，草 25＋木 20＋金錢 30；當世加壽 5 祀；名稱相近但非同一物品 |
| 聚靈丹 | CSV 無 cultivation_pill 同 ID 配方 | cultivation_pill；草 10＋靈力 50，增加修煉 60 秒 |
| 銅精、丹液、中品靈石等 | 通用 recipe 合成 | 尚無通用合成系統 |
| 配方條件／數量／容量／暴擊 | 原作 ResourceManager／craft 純規則處理材料、已學配方、容量與倍率；暴擊／加成需另固定來源案例 | 三丹硬編碼、統一面板解鎖；tier 並非各丹的境界解鎖限制，沒有一般 recipe 模型 |

Dao2 的煉丹面板在靈植場 3 級或 Era 2 開啟，三種丹藥一起列出，升到 Era 2 不會新增一批丹方。這一點也解釋了使用者看不到新的合成內容。相關來源為 `src/simulation/alchemy_system.gd` 與 `src/presentation/alchemy_panel.gd`。

## Era 2 缺口的因果鏈與實測

1. `content/manifest.json` 只載入 `resources/era1.json`、`buildings/era1.json`；`eras` 也只有 1／2，未載 Era 3。manifest 的 era=1 並不是動態載入下一境內容的機制。
2. 正式 breakthrough 命令增加 era_id、重置等級／修煉、套突破 BUFF，沒有通用跨境界資源解鎖步驟。建築視圖已有「當境及較早境界可見」判斷，但根本沒有 Era 2 建築定義可列出。
3. `Onboarding.unlock_state` 僅服務 Era 1；Era 2 回傳空 resources／buildings。直接新增資源 JSON 的 unlocked=true 也不足以修復，因新遊戲仍依 onboarding 顯式清單建立旗標。
4. 完成練氣的記憶體 fixture 經正式 `session.submit(breakthrough_era)` 成功升到 Era 2，**新增可見建築=[]、新增可見資源=[]**，印證內容缺口。不是瀏覽器畫面驗收或真實遊玩時間的證據。
5. Era 2 沒有 Era 3 定義，正常升境鏈到此截止；高階 BGM／九界法則／Debug 可以演示更高 Era，不證明正式經濟已延伸至十二境界。

Runtime 原始結果：[runtime.json](artifacts/content-progression-audit/runtime.json)。

## 資料模型評估

現有 **穩定 ID＋GameContent＋GameSession 命令＋Amount 庫存** 的分層適合繼續用 GDScript 承接，無須換引擎或重寫為網頁。現有 **內容 schema／解鎖契約／丹藥庫存** 則不足以直接搬 Dao1 全量 CSV。

| 現況與已確認問題 | 必要調整 |
| --- | --- |
| resource 僅 basic／crafted，19 種 advance 會被拒絕 | 增加受驗證的 advanced 類別或受控分類映射；保留舊分類來源，不能默默全部當 basic 開放手採 |
| loader 只留下 id/type/max/rate/unlocked，忽略 name／prereqEra／prereqSkill／recipe；被忽略欄位的變動也不改 content hash | schema 明列名稱、分類、解鎖條件、配方引用；未知關鍵欄位拒載，不再靜默丟棄；hash 包含所有玩法欄位與配方 |
| building 只有單個建築 prerequisite；無 prereqTech；GameState 無一般功法狀態，只有 talents／宗門自身資料 | 增加各功法 ID／等級與有型別的要求集合；輪迴天賦、宗門秘術、一般功法分開，不借用 talents 充數 |
| 只有 Era 1 新手解鎖函式 | 共用 ProgressionEvaluator：hidden／teased／available／owned，同時提供缺境界／缺功法／缺建築的原因；核心命令與 UI 共用，升境、建造、學功法、讀檔後均可重算 |
| 資源卡建立依 RESOURCE_NAMES.keys()、HUD 另有七項固定順序；建築列雖迭代 content IDs，名稱／用途仍硬編碼 | 資料提供 name_key、group、display_order；UI 動態讀內容，世界地標仍依既有美術契約，只在營造清單增加一般設施 |
| PILLS hardcode，不是 GameContent 配方，materials／product／effects 不經引用驗證 | RecipeDefinition 分離 inputs／output／unlock；ConsumableDefinition 分離使用效果；一般加工與丹藥使用共用庫存，不把 recipe 和效果混成一個 class |
| foundation_pill 同時放 state.resources Amount 與 state.pills int；只有 resource 庫存時 can_consume 回覆 INSUFFICIENT_PILL | 以資源 Amount 庫存為唯一權威；消耗品面板讀同一值；遷移兩份舊庫存需衝突報告，絕不可直接相加而重複發放 |
| refine_pill(201) 在足料 fixture 可產出 201，超過 foundation_pill 基礎容量 200 | 通用合成命令明定 count、材料、capacity、加成／RNG、扣料與產物同次提交；依新 reference fixtures 決定滿倉及加成裁切語意 |
| 內容增加 ID 後，SaveCodec 往返的舊 state 沒有新 ID；SaveManager 目前直接回傳 decode state | 載入協調層執行版本化 content reconciliation：只補缺少 ID 的 0 庫存／0 建築，不重置既有項；未知／衝突項保留原文並明示；失敗回復與重試冪等 |
| 生產只處理資源產率／容量與少數 aggregate，負值效果會遭 loader 拒載；自動化等 special effect 未建契約 | 先以白名單支援本階段效果；不能把 auto_feed／auto_build／負維持費當一般資源產率，缺 handler 要拒載並指出來源行 |
| 定義數量經 float 後才建 Amount，進階資料與全量大數承諾不足 | 內容金額以版本化 Amount 字串驗證；時間／次數可用有界數字；避免引入新的散落 float 數值路徑 |

同輪額外發現：茅屋容量加成在 `Onboarding.hut_lingli_capacity` 也被 Era 1 active 判斷關閉。fixture 升境前靈力容量 1400、升境後 1100；這與早期文件「跨境界保留」有衝突。實際本輪未修復，需與 content 模型／容量策略一併做回歸，不能透過調整測試標準掩蓋。

推薦最小模型（設計評估，尚未實作）：

```text
ResourceDefinition(id, name_key, category, base_capacity:Amount, base_rate:Amount,
                   unlock_rule_id, display_group, display_order)
BuildingDefinition(id, costs:Map<ResourceId,Amount>, cost_factor, max_level,
                   requirements, typed_effects, presentation_id)
RecipeDefinition(id, inputs:Map<ResourceId,Amount>, output:{resource_id, amount:Amount},
                 requirements, learned_recipe_id?, output_policy)
ConsumableDefinition(resource_id, consume_requirements, effects, lifetime_policy)
GameState.resources[id] = {value:Amount, unlocked, ever_obtained}
GameState.buildings[id] = level
GameState.skills[id] = level
GameState.learned_recipes = IDs  # 僅承接有「已學丹方」語意的配方
```

requirements 用有型別的有限條件（era／building_level／skill_level／ever_obtained），不建立任意腳本文字執行器。煉丹／合成仍走有 revision、command_id 的原子命令。`era_id` 不和 `realm_id` 混用。只納入本切片所需欄位，不先架設全部九界／伺服器。

## 建議交付順序與驗收

1. **M3-B-CONTENT1／模型與升版**：固定此機 Dao1 新 profile；擴充受驗證的資源／建築／配方／功法要求，統一庫存，補內容 reconciliation。驗收未知引用、循環、錯誤金額與不支援效果拒載；舊 v2 快照保存既有數值、補零不提前解鎖；庫存衝突與保存失敗可復原／重試，不重發丹藥；新／舊 fixture 各自保留。
2. **M3-B-CONTENT2／完整築基內容切片**：先接藏書閣→技能點／基礎吐納→狩獵營→鐵礦→靈田／靈石礦脈，以及五種中級倉儲；銅精／丹液為早期加工。初級妖丹只保留符合來源的預告／等待獸晶行為。每個資源有可達產地，每個建築可負擔且不構成容量死鎖；考察成長節奏，不只增加列表行數。建築呈現在營造簿，不在島上放未驗收地標。
3. **後續按 Era 分批承接**：補 Era 2→3 必需功法、配方與容量門檻，再展開金丹內容；不用十二境界資料全部塞入未測系統。一般合成與丹藥效果中保留／改寫者逐項標 legacy_parity／v2_change，尤其不以同名丹藥暗示同規則。

本輪模型為提案，不是已實作 ADR 或已完成內容升版；實作時先確認採用的來源 profile／保留現有 v2 丹藥效果策略，記錄確切 rules／content／schema 版本及遷移，才進玩家資料。

## 執行、修改與證據

本輪新增：兩個只讀來源／隔離記憶體審核工具、本報告、完整 inventory 與兩份 JSON（catalogs／runtime），並同步 Roadmap、development-status、規則差異與 M3-B／來源交接入口、updata checkpoint。未修改 src、正式 content、既有 tests 或 Dao1。

```powershell
python tools/audit_legacy_content.py --dao1 'D:\Temp\temp\Dao\Dao'
& ./tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/content_progression_audit.gd
```

- CSV 工具 exit 0；7/7 資源基礎欄位、10/10 建築映射一致，無各表重複 ID，完整 inventory 已產生。
- Godot 記憶體審核 exit 0；正式突破、新 ID 缺席、advanced 拒載、解鎖／配方欄位丟失及 hash 不變、丹藥雙庫存、容量／新 content ID 未遷入舊快照等均有實際輸出。
- 首跑引擎診斷包含 sandbox 無法寫預設 user:// log、根憑證讀取失敗；不稱零錯誤。第二次相對 --log-file 被解析至 user:// 仍報目錄建立失敗；第三次改成 workspace 絕對路徑後保存 engine.log／runtime-audit.log，exit 0，只餘根憑證診斷。工具不呼叫 SaveManager、不開玩家槽位，不執行 HTTP 或網路請求。
- 最終 UTF-8、Python AST、文件相對連結、JSON 證據一致性與 git diff --check 均通過；Dao1 dirty 清單仍只有既有 update.txt。
- 未重跑全部 34 Runner、未匯出 Web／操作瀏覽器；本輪未改正式玩法，審核 exit 0 只代表成功收集證據，不代表發現的缺陷已修好。
- 本輪完成檢查階段即 checkpoint。下一大型工作以 New Chat 接 M3-B-CONTENT1，再接 CONTENT2，並保留 UI／實體裝置未驗項。
