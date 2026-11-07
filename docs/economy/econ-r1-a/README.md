# ECON-R1-A 現版基線與門檻圖

此檔由 `tools/econ_r1_graph.py` 產生；結案、命令與未通過項統一記於 [development-status](../../development-status.md#econ-r1-a)。

Godot 4.7.2-stable (official)；runtime SHA256 `d651a7623433255d21e981c1ba995016546cbd10897cf854ed97ec10cbecdf26`。

正式組裝：23 資源、22 建築、6 境、24 技能、11 配方、7 島、15 航線（含退役／舊地方產物航線）。

## 讀取方式

`runtime-baseline.json` 保留引擎組裝的定義、無折扣逐階成本、修行扣料／工時、三策略命令與停點。`dependency-graph.json` 為 AND／OR 門檻圖，包含逐次購買、材料與容量雙條件、地方來源／實際到貨、配方設備與資源解鎖。容量來源邊只是候選，不代表已買得起；升境的 capacity 是資格而非扣料。

範圍為 Era1–6 主線經濟；技能保留原定義作選修索引，宗門、天賦、靈獸、丹藥等可選加成不列為主線門票。現版沒有通用研究，第三策略使用修行優先；不冒稱已測先研究策略。

## 空白新局三策略

所有策略相同 seed=1、無宗門／技能／傳承、相同起手建設。Era1 每模擬秒最多一次合法 gather；Era2 後只等權威生產／運輸。這是高頻命令策略，不是真實滑鼠自然時間試玩。

| 策略 | 起手後額外投資 | 入築基秒數 | 停點秒數 | 結果 |
| --- | --- | ---: | ---: | --- |
| 產能優先 | 居所／木／礦／草各加一階 | 1434 | 127754 | Era6 Lv10，era6_level10 |
| 容量優先 | 靈力／錢／木／石／草倉各建一座 | 1448 | 126868 | Era6 Lv10，era6_level10 |
| 修行優先 | 僅主線所需庫容 | 1347 | 129737 | Era6 Lv10，era6_level10 |

### 分境停點與等待

每格為完成該境修行／升境後的累計模擬秒；最後一境以 Era6 Lv10 為目標。失敗格保留實際停止時間，空白表示未觀察。

| 策略 | Era1 | Era2 | Era3 | Era4 | Era5 | Era6 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 產能優先 | 1434 | 5644 | 13544 | 27524 | 53264 | 127754 |
| 容量優先 | 1448 | 5358 | 13438 | 26638 | 52378 | 126868 |
| 修行優先 | 1347 | 5677 | 13517 | 27497 | 53237 | 129737 |

| 策略 | 採集等待 | 供給等待 | 製作等待 | 修行等待 | 命令數 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 產能優先 | 354 | 8220 | 24650 | 94530 | 933 |
| 容量優先 | 338 | 3660 | 24650 | 98220 | 686 |
| 修行優先 | 267 | 21000 | 24650 | 83820 | 843 |

等待欄位是策略當下呼叫時間推進的原因分類；等待製作時修行和供給也持續累積，不能把此分類當作互斥的因果瓶頸或無選擇等待比例。三策略只比較起手分支，後段共用同一按需求投資控制器，不代表搜尋過所有最優策略。

本報告 stage_limit=6。預設回歸只驗至金丹入口；完整 Era1–6 觀察需明確設定 `DAO_ECON_A_FULL_BASELINE=1`。checkpoint 是觀察範圍終點，不代表後段阻擋或通過。不能外推未測範圍時長、主導策略、80–160h 新版節奏或首世完成率。等待按 gather／供給／製作／修行分類保留於 JSON；未實作的研究利用率、設備回本、多世收益不填造數值。

## 首購容量證據

成功購買前的真實 caps 與原價已逐項比對；不把未走到的建築說成可達。

| 建築 | 首購原價 | 實際付款前容量（首份證據） | 證據 |
| --- | --- | --- |
| ancient_focus | {"liquid": 5.0, "mithril": 10.0} | {"liquid": 1000000.0, "mithril": 3000.0} | PASS |
| core_storehouse_3 | {"formation_core": 2.0, "money": 500.0, "stone_low": 100.0, "wood": 100.0} | {"formation_core": 1000000.0, "money": 540.0, "stone_low": 150.0, "wood": 150.0} | PASS |
| core_storehouse_4 | {"cold_iron": 5.0, "formation_core": 3.0, "money": 1000.0} | {"cold_iron": 3000.0, "formation_core": 1000000.0, "money": 10540.0} | PASS |
| core_storehouse_5 | {"mithril": 10.0, "money": 2000.0, "stone_high": 10.0} | {"mithril": 3000.0, "money": 30540.0, "stone_high": 10000.0} | PASS |
| cultivation_focus_4 | {"golden_core_pill": 1.0, "stone_mid": 50.0} | {"golden_core_pill": 1000000.0, "stone_mid": 1000000.0} | PASS |
| cultivation_focus_5 | {"cold_iron": 5.0, "formation_core": 3.0, "mithril": 5.0} | {"cold_iron": 3000.0, "formation_core": 1000000.0, "mithril": 3000.0} | PASS |
| cultivation_focus_6 | {"spirit_grass_1000y": 5.0, "stone_high": 10.0} | {"spirit_grass_1000y": 3000.0, "stone_high": 10000.0} | PASS |
| forest_farm | {"lingli": 20.0, "money": 20.0} | {"lingli": 400.0, "money": 460.0} | PASS |
| foundation_reservoir | {"money": 100.0, "stone_low": 20.0, "wood": 50.0} | {"money": 540.0, "stone_low": 150.0, "wood": 150.0} | PASS |
| herb_farm | {"stone_low": 10.0, "wood": 20.0} | {"stone_low": 150.0, "wood": 150.0} | PASS |
| hut | {"lingli": 20.0} | {"lingli": 100.0} | PASS |
| library | {"money": 500.0, "spirit_grass_low": 20.0, "stone_low": 50.0, "wood": 200.0} | {"money": 540.0, "spirit_grass_low": 50.0, "stone_low": 150.0, "wood": 450.0} | PASS |
| mineral_focus | {"formation_core": 2.0, "refined_iron": 30.0} | {"formation_core": 1000000.0, "refined_iron": 3000.0} | PASS |
| scripture_hall | {"black_copper": 50.0, "money": 500.0, "stone_low": 300.0, "wood": 500.0} | {"black_copper": 300.0, "money": 540.0, "stone_low": 450.0, "wood": 750.0} | PASS |
| stone_mine | {"money": 20.0, "wood": 10.0} | {"money": 460.0, "wood": 150.0} | PASS |
| storage_herb | {"money": 60.0, "wood": 30.0} | {"money": 1160.0, "wood": 450.0} | PASS |
| storage_lingli | {"money": 50.0, "wood": 20.0} | {"money": 540.0, "wood": 150.0} | PASS |
| storage_money | {"money": 100.0, "wood": 50.0} | {"money": 460.0, "wood": 150.0} | PASS |
| storage_stone | {"money": 40.0, "stone_low": 10.0} | {"money": 1160.0, "stone_low": 150.0} | PASS |
| storage_wood | {"money": 30.0, "wood": 10.0} | {"money": 1160.0, "wood": 150.0} | PASS |
| void_focus | {"stone_high": 5.0, "void_essence": 10.0} | {"stone_high": 10000.0, "void_essence": 3000.0} | PASS |
| wooden_house | {"lingli": 30.0, "money": 20.0} | {"lingli": 400.0, "money": 300.0} | PASS |

藏經閣／經書樓另以空白新局的 `optional_purchases` 支線付款驗證；其投資與時間不混入上方三策略。支線的購買命令與付款前容量保留於 runtime JSON 的 purchase_probes。

起手茅屋需靈力20；舊版非 onboarding 首購仍需金錢30。兩種成本都保留於快照。茅屋每階靈力容量150只在 Era1 有效；後續容量需另建，不把起手紅利永久帶入築基。

## 配方、能力與加工深度

| 配方 | 定義Era | 工序 | 單批投入 → 產出 | 秒 |
| --- | ---: | --- | --- | ---: |
| bronze_essence | 2 | 1 | {"black_copper": "10", "stone_low": "5"} → bronze_essence×1 | 10 |
| formation_core | 3 | 2 | {"bronze_essence": "2", "spirit_timber": "2"} → formation_core×1 | 20 |
| foundation_pill | 1 | 1 | {"black_copper": "20", "lingli": "200", "spirit_grass_low": "50"} → foundation_pill×1 | 20 |
| golden_core_pill | 3 | 2 | {"foundation_pill": "3", "spirit_grass_100y": "2", "stone_mid": "5"} → golden_core_pill×1 | 30 |
| liquid | 2 | 1 | {"lingli": "50", "spirit_grass_low": "5"} → liquid×1 | 10 |
| spirit_timber | 2 | 1 | {"stone_low": "5", "wood": "10"} → spirit_timber×1 | 10 |
| stone_high | 5 | 2 | {"lingli": "50", "stone_mid": "3"} → stone_high×1 | 10.0 |
| stone_mid | 3 | 1 | {"lingli": "10", "stone_low": "5"} → stone_mid×1 | 10 |
| stone_mid_bulk | 4 | 1 | {"lingli": "1000", "stone_low": "500"} → stone_mid×100 | 10.0 |
| talisman | 3 | 1 | {"lingli": "50", "stone_low": "5", "wood": "10"} → talisman×1 | 10 |
| trans_pill | 5 | 3 | {"golden_core_pill": "2", "mithril": "2", "spirit_grass_1000y": "1"} → trans_pill×1 | 30.0 |

工序按配方圖推導，與 rarity／tier／Era 分開；寒銀三金屬是直接採集。中石批量是相同物品替代配方，不增加工序。靈材／銅精在 wood／ore 產線，付款與新產物均在祖島；丹液另有 home／herb 產線替代，herb 需 Era3 開島。

## 解鎖同步與證據邊界

啟用時 migrate_processing 對缺少及既有資源槽一律按當前 Era 同步 unlocked，保留既有數量及 ever_obtained；後續成功升境繼續同步。這修復了先前空白築基首批 RESOURCE_LOCKED 的反例，未更動數值或配方門檻。

runner 以實際賺得的築基快照驗證候選保存拒寫不改 live state、重試保留來源歸檔、重新載入、重複啟用拒絕與缺槽初始化。三策略的首批靈材／銅精及首次築基扣料升層均須通過，不能用手動開槽代替。

本報告三條既定策略均實際到達 Era6 Lv10；首購容量見證 22/22。PROVEN 僅涵蓋本次 seed／策略／無選修加成的主線範圍，不代表所有隨機種子、所有高階建築升級、最優解或新版平衡已驗。B 尚未開始。
