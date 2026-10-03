# RES1-DESIGN：資源主線差距稽核與規劃驗收

日期：2026-10-03。狀態：**DONE（靜態稽核／規劃修訂範圍）**；RES1-A–E 玩法開發 TODO。本轮没有聲稱完成新加工／多島／物流。

使用者要求重新調整 Era 解鎖空島、多階資源、融合與供給運輸。工作區開始時 Git clean；DAO1 `E:\Python\test1` 唯讀，已讀其 AGENTS.md／user_rules.md，沒有執行舊 runtime 或改來源。輸出全部在 Dao2。

## 可重跑證據

```powershell
python tools/audit_resource_progression.py --legacy-root E:/Python/test1 --output docs/verification/artifacts/resource-progression-audit-2026-10-03.json
```

exit 0。工具只讀 CSV／規則源碼並計算 SHA-256，按非空 ID 統計記錄，不讀取玩家存檔。輸出 [JSON](artifacts/resource-progression-audit-2026-10-03.json) 含 61 項資源／30 配方、解鎖欄位、DAO2 manifest 交集、12 境界需求與建築 ID 分組；這是來源清點，不是 runtime 可達性／相容性測試。

| 比較項 | DAO1 靜態資料 | DAO2 目前正式內容／程式 | 判斷 |
| --- | --- | --- | --- |
| 資源 | 61 有效 ID：12 basic、19 advance、30 crafted | manifest 7；另有丹藥、靈界等子系統資源 | 不能以 7/61 作完成百分比，但資源表承接明顯不足 |
| 配方 | 30 個 recipe，部分帶 Era／技能／丹方門檻 | AlchemySystem 3 丹藥；RealmSystem 2 條轉換，無通用多階配方表 | 丹藥已實作不等於 Craft 體系承接 |
| 建築／倉儲 | buildings.csv 49、storage.csv 10 | manifest 10；另有硬編碼靈界設施 | 不同表／設施含義不能直接加總為 parity 比例 |
| 境界 | eras.csv 12 行，已含多資源／技能／Lv9 特殊物料 | manifest 僅 Era 1／2 | 缺口從 Era 2 的完整依賴與 Era 3 開始，不是只有 Era 9–12 |
| 世界 | 本輪未以舊版模型推導多島規則 | 遠景裝飾、返回自己洞府、跨界狀態／色調，靈界三設施 | 多島屬本輪明確 v2 方向，需要新增真正島身分與產業 |
| 物流 | 不假定 DAO1 已有島間運輸 | 飛劍視覺不持有貨物／運力／交貨狀態 | RES1-B 新機制，不能標「只需補圖」 |

M0-B manifest 曾將同 hash 的 Resources.csv 記為 62、storage.csv 記為 11。本輪 csv.DictReader 按非空 ID 得 61／10，兩檔 SHA-256 與原 manifest 相同，完整 hash 見 JSON。歷史列數不改寫原 fixture，此處校正統計口徑。

## 代表配方與升境需求

以下數值直接摘自 DAO1 CSV，仅證明來源，不代表 DAO2 當前已實作或 v2 最終價格。

| 來源 ID／名稱 | 配方或需求 | 證據意義 |
| --- | --- | --- |
| bronze_essence／銅精，Era 2 | 玄銅 10＋下品靈石 5 | 非丹藥進階材料已在 DAO1 |
| liquid／丹液，Era 2 | 靈草 5＋靈氣 50 | 加工中間物 |
| stone_mid／中品靈石，Era 3 | 下品靈石 5＋靈氣 10 | 基礎材料可轉更高階材料 |
| golden_core_pill／金丹，Era 3 | 築基丹 3＋百年靈草 2＋中品靈石 5 | 已合成物繼續作配方原料 |
| stone_high／上品靈石，Era 5 | 中品靈石 3＋靈氣 50 | 跨 Era 層層加工 |
| Era 3 境內晉階 | 基礎消耗欄位含靈氣 2000、金錢 500、中品靈石 50；Lv9 欄位另列符咒 10 | 高階資源有明確修行用途，實際乘數／觸發由 runtime 核對 |
| Era 4 境內晉階 | 含金丹 3、中品靈石 200 | 加工產品不是只作展示數字 |

靈木＋靈石→靈材是使用者提出的新例子，不在已讀 DAO1 配方表，須登記新 resource/recipe ID。

DAO1 `ResourceManager.canCraft/craft` 與 `balance/rules/craft.ts` 包含已解鎖／配方、空間、原料檢查，以及技能／設施／宗門／靈獸加成、合成暴擊；`recipe.ts` 另列丹方 gating。RES1-A 必須核對 runtime 與純規則差異、建立獨立 fixture，本次没有執行舊公式或標為 parity PASS。

重要的既有差異：DAO1 築基丹配方為靈草 3＋靈氣 50；DAO2 AlchemySystem 為靈草 50＋玄銅 20＋靈氣 200，且附產率效果。DAO1 Era 2 CSV 也包含不同的修煉價格、倍率、技能與容量需求。下一輪需逐項選擇承接或 v2 明確變更，不能只將舊資源名稱補回畫面就稱完成。

## 本輪交付與驗證邊界

- 新增 tools/audit_resource_progression.py、上方 JSON、docs/14、ADR-009、此驗收；更新 README、ROADMAP、docs/01／02／03／07／08／12、來源 manifest 統計說明、M3-B 現況、差異帳本、ai-handoff、development-status、updata。
- 工具 exit 0；輸出 61 資源、30 配方、49 建築、10 倉儲、12 境界；DAO2 7／10／Era [1,2]。
- 初次臨時 Python 清點因主控台 cp950 不能輸出 emoji 而失敗，改 stdout UTF-8 後正確取得中文；正式工具 stdout 只輸出 ASCII JSON，證據檔 UTF-8。曾嘗試不存在的 managers/ResourceManager.ts，後由 rg 找到 utils/ResourceManager.ts；未將失敗讀取當證據。
- 正式 audit 重跑兩次 exit 0、JSON 位元組一致；JSON／UTF-8／Python 語法、來源 hash 重算均 PASS，166 個本地 Markdown 連結全可解析，git diff --check exit 0（僅 LF/CRLF 提示）。此輪沒有 runtime 變更，不執行 Godot Runner、Web 匯出或 UI 驗收，不沿用前輪測試充當新玩法證據。
- 外部參考只採開發者商店頁、Kittens wiki 與 Evolve 作者程式，見 docs/14；未複製第三方素材或數值。

## 下一步

RES1-A：先完成 Era 1–3 的来源／配方／技能／需求閉環與通用 Craft 契約，再 RES1-B 的地方庫存、時間／物流與保存，之後做可見三島→四島切片。已完成當前規劃階段，依 Context Guard 使用 New Chat 開始實作；不要在本輪繼續堆入大型經濟改造。
