# ECON-R1-C：Era1–3 新版規則切片

執行結果與結案判定只記於[開發狀態](../development-status.md#econ-r1-c)；方向與候選數字沿[重構參考](../52-economy-reconstruction-reference.md)。

## 啟用與版本

`EconomySlice.create()` 回傳新版專用 `content` 與正式 `catalog`，再明確呼叫 `EconomyProfile.open(content, isolated_adapter, catalog, true, seed)` 建新檔。現版 launcher 不呼叫此入口。新增內容標記 `+econ-r1-c-1`；外層 rules/economy 為 `econ-r1-rules-2`／`econ-r1-economy-2`，schema 與研究格式仍為 1。B 的舊研究表與版本不自動遷移；拒載保持來源原文，原版存檔繼續走原入口。

研究上下文只存在候選 Session 的獨立 content/catalog，隨候選研究完成集合更新。每個命令、時間交易、載入均重新綁定；不放到全域 static、不加入現版 GameState。拒寫仍暫停並重試相同候選 bytes。直接呼叫新版 Session 命令也受相同 gate，UI 隱藏不是資格機制。

## 起手設備與工藝

| 設備 | 資格與首購 | 用途 |
| --- | --- | --- |
| `research_seat` 研習席 | Era2；錢30＋木20＋下石10；不需研究／技能點／加工品 | R01–R07 單槽研究；每世重建 |
| `craft_workshop` 工坊一階 | Era2＋R01；錢30＋木20＋下石10 | 所有新增研究所控制的加工資格；不贈原料／產物 |
| 同工坊二階 | R03；靈材／銅精各5的基價沿既有第1級成本曲線計價，實付各6 | 下一批工時原始減免0.2，進 work_time DR |

新版築基五層起原有丹液5付款改為額外靈材5＋銅精5（合計靈材25＋銅精15），並要求R03；這是配合丹液後移Era3的明確v2變更。否則築基升層會反過來要求金丹丹霞／R06，構成跨階循環。現版 Era2 表不變。

兩項設備只供新版規則使用，沒有新增世界地標或 UI。本階段只提供規則／程式入口；共用研究頁與玩家引導仍屬 E。

正式研究為 `content/research/econ_r1.json` 的 R01 木作、R02 冶煉、R03 營造工程、R04 倉儲工程、R05 陣紋入門、R06 藥理凝液、R07 凝石。成本、秒數、DAG 沿 docs52 表；設施用新版研習席。R02 另需已開玄礦，R06 另需已開丹霞。只取得材料或加入宗門不能替代研究。

| 權威消費者 | 當世研究／設備 |
| --- | --- |
| 靈材／銅精 | R01／R02，工坊一階，已啟用 hub 與既有產線／Era 資格 |
| 陣芯／符咒 | R05＋工坊一階；原 Era3 限制仍生效 |
| 丹液／金丹配方產物 | R06＋工坊一階；R06 在 Era3，丹液不再以原 Era2 標籤提前開工 |
| 中石 | R07＋工坊一階 |
| 地方採集／加工工程升階 | R03；原開島與材料付款仍必須滿足 |
| 地方倉儲升階、金丹聚靈庫首購 | R04；原容量／材料條件仍生效 |

`craft`、`switch_processing`、`refine_pill`、建造與地方工程命令有具名拒絕；每次自動開始下一批亦重新核對 recipe gate。築基丹保留無研究起步。C 最遠到 Era3 Lv10，突破 Era4、後三島與後段配方／建築暫返回 `ECON_SLICE_NOT_AVAILABLE`，由 D 擴充。

## 構件取捨與效果

不新增 `new_spirit_module`：工坊二階與地方採集／加工工程均已直接消耗靈材、銅精；地方倉儲亦有靈材用途。新物品沒有獨立能力或必要的第二用途，新增只會重複陣芯／舊材料的工程付款。陣芯仍支撐金丹修行與聚靈庫，材料→設備→供給／容量→修行形成實際閉環。

新版建築 quote 與付款共用 `EconomySlice.building_quote`。R04 對 `storage_*`／`core_storehouse_3` 提供原始建築材料減免0.1；必要離散件不折。加工原料走 `EconomyEffects.cost`；既有 heavenly_craft 的指定靈力減耗在此轉成一次來源後 DR，不再先套舊折扣。C 不新加全面加工減耗。

工時將地方工坊級數換成 `1-1/level`、新版工坊二階0.2與適用宗門工時來源按同 scope 加總，再一次 work_time DR，至少1秒；不同來源不再乘算。材料至少1e-6、必要離散件不折、每件取整後再乘批數。普通產率、容量、突破機率保持原路徑，不套新 DR。

已付款工作沿原 remaining 完成；工程只影響下一批。輪迴清除研究與設備；研究傳承只縮短下一世研究秒數，不減材料、不免前置、不送構件。

## 浮點與貨運修正

兩世賺得路徑重現原貨運邊界：祖島庫存與十秒在途預留的 JSON 往返差約4e-13，精確容量比較誤拒；極小正貨物的 Amount 顯示序列化又可成零貨載。新版貨運預覽先向下量化到1e-6，扣貨／保存使用相同數量；cargo 以固定小數保存，不借用顯示格式。容量預留驗證只容許既有付款精度1e-6內差額，真正超量仍拒絕，不裁掉已付款物品或在途貨物。容量容差為共用精度修復；貨載固定精度僅用於新版，現版貨運／快徑維持原計量。這不是新產率或免費材料來源。

新版時間交易仍逐秒呼叫 GameSession，沿用 TimeAdvancer 已有的無命令區間 prepare 快取，避免每秒重建相同容量／倍率；研究完工順序、clock、revision 與所有 tick 保持原語意。有侍女時每秒清除快取，避免內部自動建造／製造命令使下一秒沿用舊數值。

歷史保存另修正 JSON 整數表示的計量邊界：version／omitted 讀回可呈浮點形式，驗證大小依宣告的整數型別計算；6KiB上限、觀測資料與schema保持。這是唯讀驗證，不修補、不刪除載入資料；真正超出1 byte仍拒絕。

## 驗證邊界

`econ_r1_slice_runner.gd` 從空白 profile 開始，只送合法命令與權威秒數；Era1 每模擬秒最多採集一次。兩世皆無宗門、選修技能或注入庫存／Era。只有明確隔離的精度負例使用複製 fixture，該狀態不交回賺得主線。報告保留研究／建築付款前容量、命令、等待分類與末態指紋。

日常直接選此 runner 只跑短 smoke，沿預設45秒上限。完整兩世分析明確設 `DAO_ECON_C_EARNED=1`，專用上限1200秒，不併入日常 L1。先用 `-List` 確認範圍，再執行：

```powershell
$daoPreviousEarned = $env:DAO_ECON_C_EARNED
try {
    $env:DAO_ECON_C_EARNED = '1'
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'econ_r1_slice_runner.gd' -TimeoutSeconds 1200
} finally { $env:DAO_ECON_C_EARNED = $daoPreviousEarned }
```

首世達 Era3 Lv10 後把隔離 adapter 的完整原文與控制器軌跡寫到 `.test-output/.../econ-r1-c/first-life-checkpoint.json`。若長測中斷，可設 `DAO_ECON_C_RESUME` 指向該檔，沿正常 `EconomyProfile.open` 的版本／checksum／catalog 驗證恢復，再跑自然壽盡與第二世；不修補數值或跳過研究。這是測試存檔，禁止拿玩家存檔替代。歷史A控制器的共用輔助改用 `buildings.get(id,0)`，正確讀取輪迴後的稀疏建築字典。

這是加速規則模擬，不是自然時間 Chrome 滑鼠通關或80–160h長線平衡。UI／Web 新入口在 E，五宗與 Era4–6 在 D，候選包與大型 L3 收尾在 F。
