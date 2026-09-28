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
   - **資格檢查（對齊 Dao1 經典雙軌門檻，移除過渡性築基直接放行）**：
     - **被動觸發**：壽元耗盡（`is_exhausted == true`，含丹藥與 BUFF 累加壽元）。
     - **主動提前輪迴**：需修築特定輪迴建築【往生蓮臺】（`rebirth_lotus`）或【太虛輪迴境】（`void_mirror`）。
     - 未滿足者一律拒絕（`REINCARNATION_NOT_ELIGIBLE`）。
   - 狀態重置：建築清空、修為歸一、當世時間歸零，肉身丹藥/普通BUFF清空，傳承基礎資源發放。
4. **天賦模組 (`src/simulation/talent_system.gd`)**：
   - 首批天賦：`resource_inheritance`（資源傳承）、`lifespan_extension`（長生久視）、`innate_dao_body`（先天道體）。
   - 消耗道心升級，提供全局產率加成（$0.15 \times \log_{10}(\text{dao\_heart} + 1)$）與壽元上限倍率。
5. **轉生互動面板與壽盡橫幅 (`reincarnation_panel.gd` & `living_abode.gd`)**：
   - 提供雙分頁對比彈窗，支援世次概覽、資格高亮、保底收益預覽、傳承試算、入定轉世與天賦參悟升級。
   - 主場景實作高醒目度懸浮警示卡 `LifespanBanner`（亮橘暖金發光邊框），壽元耗盡時自動彈出並配備「🪷 輪迴證道」專用直達按鈕；平時自動隱藏零佔位。
6. **轉生儀式感演出組件 (`src/presentation/reincarnation_sequence.gd`)**：
   - 3 階段動態插值（總時長 3.4 秒）：階段一太虛出神至 Cosmos 視野（zoom 0.08，偈語「肉身有盡，道心無窮。」）；階段二穿梭輪迴俯衝下沉至 Home 視野（zoom 0.70，16 條虛空穿梭粒子，偈語「歷經千劫，神返靈山。」）；階段三仙身聚頂擴散青藍金靈環波，浮現「重塑仙身，再問長生！」並彈出結算卡。
   - 支援「跳過演出（Skip）」與 `reduced_motion` 低動態模式。
7. **整合與測試**：
   - `CommandProcessor` 接入 `reincarnate` 與 `learn_talent`。
   - `TimeAdvancer` 接入天賦壽元倍率與產率倍率。
   - `GameSession` 提供 `reincarnate()`、`learn_talent()` 與 `get_reincarnation_preview()`。
   - `tests/m3a_reincarnation_runner.gd`（exit 0，黃金測資、雙軌門檻、狀態重置、天賦生效全 PASS）。
   - `tests/m3a_reincarnation_ui_runner.gd`（exit 0，雙分頁面板、按鈕響應、轉生 3 階段運鏡、徽章與跳過機制全 PASS）。

---

## 驗證證據

1. **CLI 測試**：
   - `tests/m3a_reincarnation_runner.gd`：PASS。
   - `tests/m3a_reincarnation_ui_runner.gd`：PASS。
   - 全量 25 項 Runner 全部 PASS（退出碼 0）。
2. **Web 匯出**：
   - `Godot --export-release Web build/web/index.html`：PASS（退出碼 0）。
