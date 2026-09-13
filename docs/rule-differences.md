# 規則差異帳本

更新：2026-09-14。此表只記錄已固定的舊版規則、明確 v2 決策及尚未決定的差異；不把展示場景的數值當作遊戲規則。

| ID | 主題 | 狀態 | v2 目前處理 | 證據／後續 |
| --- | --- | --- | --- | --- |
| LP-001 | 建築費用三段指數、線性段與折扣 | `legacy_parity` | M0-B 固定等級 0／20／21／50／51 的 Decimal 字串結果 | `m0-b-v1.json`；M1-A 必須用 Amount 接入 |
| LP-002 | 新手僅靈力與茅屋，功能等級逐步解鎖 | `legacy_parity` | 固定空白、茅屋 2 級與完整 EAR1 鏈的可見項目 | M1-A 的真實空白初始狀態不得沿用展示洞府 |
| LP-003 | 升級看容量上限，容差 0.1 | `legacy_parity` | 固定 `499.89` 失敗、`499.9` 通過的案例 | M1-B 以 Amount 比較重新定義精確語意，不可暗用 float |
| LP-004 | 修煉時間幾何累積與多層加速下限 | `legacy_parity` | 固定累積、單級與兩個加速邊界 | M1-B 建立可注入 Clock／整數 tick |
| LP-005 | 壽元按已經歷 Era 配額累加 | `legacy_parity` | 固定 80 年、含天賦與丹藥、資料缺失後援值 | M1-B 補全 12 Era CSV 與壽盡事件順序 |
| LP-006 | 輪迴道心、道證與資源繼承 | `legacy_parity` | 固定普通／大道比例、境界保底、40%／80%起手、因果倉儲 | M3-A 補全資格、清除／保留清單與存檔往返 |
| LP-007 | Amount 的 `break_eternity` 字串／JSON | `legacy_parity` | 固定 0、十進位、`1e100`、`1e1000000`、`ee5` 的字串結果 | M0-C 實作完整 Amount 契約、算術及非法值邊界 |
| LP-008 | SeededRandom | `legacy_parity` | 固定 ASCII、繁中 UTF-16 seed、數字 seed 及 state 恢復序列 | M0-C 建立 GDScript 同序列實作或明確 bridge ADR |
| V2-001 | 展示洞府的 float 每幀產出 | `v2_prototype_only` | 不可作為舊版或正式公式來源 | M2-A 移除展示 state，改讀正式 GameSession |
| V2-002 | 離線收益最多 24 小時 | `decision_pending` | 是 v2 暫定政策，不屬舊版 parity | M1-D 需規則版本、冪等保存與回歸案例 |
| V2-003 | 九界、無限宇宙與跨界物流 | `v2_new_content` | 不映射為舊版 Era；遠景不產生第二份經濟 | M4–M5 逐項驗證 |

`legacy_parity` 表示需要先與已固定來源一致，並不表示該規則永久不可改善。改動舊行為時，必須新增帶版本的 v2 決策與相對應案例，保留原 fixture 供遷移與回歸。
