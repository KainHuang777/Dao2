# ADR-008：M0-C 的 Amount 與 RNG 相容邊界

日期：2026-09-14  
狀態：Accepted for M1 core slice

## 決策

核心使用 `AmountCompat` 的 sign/layer/mag 表示，禁止以單一 `float` 假裝支援後期大數。隨機數使用 `SeededRandomCompat`，以舊版 UTF-16 xfnv1a 與 Mulberry32 state 演算法保證相同 seed 的決定性。

Amount 的 v0 合約涵蓋 layer 0 至 3 的解析與序列化、比較、layer 0/1 的主要經濟運算，以及明確的非法輸入錯誤。高 layer 的完整 `break_eternity` 運算與任意舊 save 的原文字串 round-trip 暫不承諾。

## 理由

早期洞府、資源、境界與離線快照需要不會溢位的表示與可重現 RNG；完整移植六千餘行 Decimal 庫會拖慢 M1 核心驗證，且尚無足夠舊存檔樣本證明整個 API 是必要範圍。

## 影響與後續

- 新 simulation 只依賴 `AmountCompat` 已驗收的方法；UI 不直接處理 float 金額。
- Save schema 要保留可演進的 Amount 結構或受控 canonical 字串，並記錄版本。
- M1-E 匯入任務前要補 layer 2 以上算術與真實舊存檔 corpus；若需要完整 byte-for-byte JSON，移植或包裝原 Decimal 實作。
- `src/domain/amount.gd` 與 `src/domain/seeded_random.gd` 是本輪早期候選，因工作區 patch helper 無法覆寫既有檔案而保留做稽核；M1-A 開始前應整併並刪除候選檔，只以 `AmountCompat`、`SeededRandomCompat` 作為此 ADR 的有效 API。
