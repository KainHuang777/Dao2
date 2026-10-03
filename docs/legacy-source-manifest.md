# M0-B｜舊版來源 Manifest

固定日期：2026-09-14。此 manifest 指向唯讀來源 `E:\Python\test1`，供跨語言規則核對使用；不代表 Dao2 包含或授權轉散布該來源。

## 來源身分

| 欄位 | 固定值 |
| --- | --- |
| 絕對路徑 | `E:\Python\test1` |
| Git 狀態 | 不存在 Git work tree，無法取得 commit 或 dirty diff |
| package | `cultivation-game@0.46.6` |
| reference runtime | 既有 `node_modules` 的 Vitest `4.1.10` |
| 讀寫界線 | 本任務只讀取及執行純規則；所有新增檔案均在 Dao2 |

來源沒有可用提交 ID，因此本 manifest 以精選規則、測試與資料檔的 SHA-256 作為基準。任何一筆雜湊改變，都必須建立新的 fixture 版本，不能覆寫 `m0-b-v1.json`。

## 規則與測試檔

| 相對於 test1 | SHA-256 | 用途 |
| --- | --- | --- |
| `package.json` | `7E0661AE7F8E0D3A9479B4AE1C7A09B835D416E732D4482A381722EDBF0AA695` | 套件與版本身分 |
| `src/balance/rules/buildingCost.ts` | `769F5DAAE971A823E2B9E84A2E2A12ACD831B02044D41A21E7278BBC438737B5` | 建築費用曲線 |
| `src/balance/rules/talentRules.ts` | `4EDA4BC50EB4C3CC5D1A02DBFCEAD8477A45C5F25E0ADD513B2BD40E35940068` | 成本折扣界線 |
| `src/balance/rules/eraRequirements.ts` | `2602DD71DEB7F59FA3BE8621659ADE78634B08519C5822858885D26970720670` | 修煉時間、容量、功法前置 |
| `src/balance/rules/lifespanRules.ts` | `45E5BC07E54379F0BFDDDEF7CE126A7C73257272A934267D9C372B9B8582B63A` | 壽元、輪迴獎勵 |
| `src/balance/rules/reincarnationInheritance.ts` | `414A89EEFCF331ADC28CF877F91A61DEA6A59A9111C013F4DF017252E145EB38` | 資源與因果繼承 |
| `src/balance/rules/onboardingUnlocks.ts` | `307A817B1017802CC367E2F55C9066CFB075D8FBC94C898A5EC0D3C68F7BC73B` | 新手解鎖鏈 |
| `src/balance/rules/progressionUnlocks.ts` | `2D1221DAFDC69F3EC95BC1ABF86A3FAED69E9770CC3738D2C82B007983019BC9` | EAR1–6 漸進揭露 |
| `src/balance/simulation/SeededRandom.ts` | `015195F1533C2092A90F351551CE5E403FD0E871563FF159B4D97C6B275CAB8F` | UTF-16 字串雜湊、Mulberry32、state 恢復 |
| `src/utils/break_eternity.js` | `F2BBE00B98FBFCED35CBBD62BA013B159B7FF02789C9A1A9AC5CDE2B10808753` | Amount 解析與字串 JSON |
| `tests/balance/formulaParity.test.ts` | `BDB9E333022B3B2D77E4E2E84D9FC50FE374018EBF7614D719D5AE4CE3146464` | 既有公式對照證據 |
| `tests/balance/onboardingUnlocks.test.ts` | `131CB1E4C78A4401E22509001197BE00469CBA44475433051335D0B6F9D28587` | 既有新手鏈證據 |

## 資料 profile

2026-10-03 RES1 統計校正：以 csv.DictReader 按非空 ID 清點，同 SHA-256 的 Resources.csv 實際為 **61 個有效記錄**，storage.csv 為 **10 個有效記錄**；下表 62／11 為原歷史行數記法，不能作有效內容數。完整資源／配方與 hash 重現見 [RES1 稽核](verification/resource-progression-audit.md)，原 M0-B fixture 不覆寫。

資料以 UTF-8 讀取；行數不包含表頭。

| 檔案 | 列數 | SHA-256 |
| --- | ---: | --- |
| `src/data/buildings.csv` | 49 | `DF6B841034C170B66967BB094541EAD768A699CD33D5B38BCCFB89E6E63B8E5E` |
| `src/data/eras.csv` | 12 | `E71F03ABD8755993FF874B5CBD2C9ED7B428423BC455D3C44950EB715DECA404` |
| `src/data/Resources.csv` | 62 | `41B3E762C40EEB813885A08BD078E5C848C70683428E562D826971843EDC74DE` |
| `src/data/skills.csv` | 35 | `C45F39DC1AA43661BC4834C32FFF5C5A432305D1D2381886A982BA86B082710D` |
| `src/data/storage.csv` | 11 | `A3D7AD8E07DCEF03E235AACD34F49D587606B6E84A85F379A253EEB12AC6F62B` |

`eras.csv` 的前三筆壽元為 80、120、540；M0-B fixture 的壽元案例使用這三筆，並刻意測一次第 4 境資料缺失時的後援值。開局核心建築資料使用 `hut`、`wooden_house`、`forest_farm`、`stone_mine`、`herb_farm` 五筆，解鎖門檻由規則模組而非 CSV 順序決定。

## 重跑方法

在 Dao2 的 PowerShell 執行：

```powershell
& 'E:\Python\test1\node_modules\.bin\vitest.cmd' run --root 'E:\WORK\Dao2' --reporter verbose 'tests/fixtures/legacy/m0b_reference.test.ts'
```

這個 runner 位於 Dao2，直接匯入固定路徑下的純規則模組，並對照 [m0-b-v1.json](../tests/fixtures/legacy/m0-b-v1.json)。它不寫入 `E:\Python\test1`。若來源不存在，測試必須失敗而非改用猜測值。

直接對舊專案使用其 `vitest.config.ts` 時，Vite 會嘗試在來源的 `node_modules/.vite-temp` 寫入暫存檔；唯讀界線會拒絕該行為。因此本任務沒有修改來源以執行其整套測試，而是用上述隔離 runner 驗證實際舊規則模組。

## 2026-10-03 RES1-A 配方參照

新增 `tests/fixtures/legacy/res1-a-source.json`：首批 13 個來源資源、六配方、Era1–4 原始需求及來源 hash；另加 craft.ts／recipe.ts／ResourceManager.ts SHA-256。`res1a_reference.test.ts` 在 Dao2 執行原純規則、先驗所有 hash，8/8 PASS。沒有寫入來源專案或啟動 Manager runtime；number 純規則向量不等於 Decimal runtime 大數 parity。命令與差異見 [RES1-A](verification/res1-a.md)。
