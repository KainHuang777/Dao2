# M0-B 驗收紀錄｜固定舊版來源與黃金測試資料

日期：2026-09-14。狀態：**DONE**。

## 目標與邊界

固定唯讀舊來源、建立可重跑的代表性黃金數據，供 M0-C 和後續 GDScript 規則移植使用。本任務不改寫舊版、不實作正式 GameState、不宣稱舊存檔已可匯入。

## 產物

- [來源 manifest](../legacy-source-manifest.md)：來源身分、雜湊、資料列數與重跑規則。
- [黃金 fixture](../../tests/fixtures/legacy/m0-b-v1.json)：建築成本、容量、修煉時間、Amount、壽元、輪迴、新手解鎖及 SeededRandom。
- [reference test](../../tests/fixtures/legacy/m0b_reference.test.ts)：從 Dao2 匯入舊版純規則，直接和 fixture 比較。
- [差異帳本](../rule-differences.md)：保真規則、v2 提案與待決事項分開記錄。

## 驗收環境與命令

- 來源：`E:\Python\test1`，`cultivation-game@0.46.6`，無 Git work tree。
- runner：來源既有 `node_modules` 的 Vitest 4.1.10；測試 root 為 `E:\WORK\Dao2`。

```powershell
& 'E:\Python\test1\node_modules\.bin\vitest.cmd' run --root 'E:\WORK\Dao2' --reporter verbose 'tests/fixtures/legacy/m0b_reference.test.ts'
```

結果：退出碼 0；1 個檔案、1 個測試通過。測試直接驗證舊規則輸出與 `m0-b-v1.json` 完全一致，包含繁中 seed `修仙問道` 與 RNG state 恢復。

## 已知限制

1. 舊來源沒有 Git commit 或 dirty 狀態可記錄，故以清單中的 SHA-256 取代提交指紋。
2. 這是代表性 fixture，不是舊版所有系統的完成證明；宗門、靈獸、丹藥、天時、完整存檔與完整 12 Era 流程仍待各自任務。
3. `break_eternity` 只固定了代表性解析／JSON 向量。完整解析、算術、比較、非法輸入與跨語言數值模型屬 M0-C。
4. 來源專案的原生 Vitest config 會嘗試寫入 `.vite-temp`；本任務保持來源唯讀，改採 Dao2 內的隔離 runner，不把該寫入失敗誤記為規則錯誤。
