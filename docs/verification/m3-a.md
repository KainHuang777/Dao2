# M3-A 輪迴轉世機制驗證紀錄

狀態：DONE（CLI／Domain／Simulation／Persistence 全閉環）。

規格依據：[Roadmap M3-A](../../ROADMAP.md)、[來源基線 00-source-baseline.md](../00-source-baseline.md)。

---

## 交付項目

1. **GameState 跨世持久化欄位**：
   - `reincarnation_count: int`（累計輪迴次數）
   - `highest_era: int`（歷史最高達到境界）
   - `dao_heart: AmountCompat`（可用道心總量，支援天賦消耗）
   - `dao_proof: int`（大道位格道證）
   - `talents: Dictionary`（跨世天賦等級）
2. **存檔向後相容**：
   - `SaveCodec` 支援新欄位序列化與安全反序列化，舊版存檔無這些欄位時回退至預設值（0, 1, "0", 0, {}）。
3. **輪迴規則模組 (`src/simulation/reincarnation_rules.gd`)**：
   - 嚴格對齊黃金測資：
     - $B = \sum \text{building\_level}$
     - 境界保底：Era 1 (0), Era 2 (15), Era 3 (20), Era 4+ (25)
     - 道心：$\max(\lfloor B / 10 \rfloor, \text{保底})$
     - 道證：$\lfloor B / 50 \rfloor$（normal）或 $\lfloor B / 30 \rfloor$（advanced）
     - 起始傳承：第 1 次 40%、第 2 次及以上 80%，天賦每級 +10%，受新開局容量上限限制。
   - 資格檢查：壽元耗盡 或 境界達到 Era 2（築基期）以上。
   - 狀態重置：建築清空、修為歸一、當世時間歸零，傳承基礎資源發放。
4. **天賦模組 (`src/simulation/talent_system.gd`)**：
   - 首批天賦：`resource_inheritance`（資源傳承）、`lifespan_extension`（長生久視）、`innate_dao_body`（先天道體）。
   - 消耗道心升級，提供全局產率加成（$0.15 \times \log_{10}(\text{dao\_heart} + 1)$）與壽元上限倍率。
5. **整合**：
   - `CommandProcessor` 接入 `reincarnate` 與 `learn_talent`。
   - `TimeAdvancer` 接入天賦壽元倍率與產率倍率。
   - `GameSession` 提供 `reincarnate()`、`learn_talent()` 與 `get_reincarnation_preview()`。
6. **專屬測試**：
   - `tests/m3a_reincarnation_runner.gd`（exit 0）。

---

## 驗證證據

1. **CLI 測試**：
   - `tests/m3a_reincarnation_runner.gd`：PASS。
   - 全量 15 項 Runner 全部 PASS（退出碼 0）。
2. **Web 匯出**：
   - `Godot --export-release Web build/web/index.html`：PASS（退出碼 0）。
