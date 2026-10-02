# 築基小院與洞府小景

2026-10-03 · M2-D-ISLAND1 · 使用者指定優先交付；實作／桌面驗證完成，使用者美術與實體裝置驗收待補。

## 外觀與世界呈現

同一浮島、同一 `hut` 建築 ID／等級／詳情／經濟。當世 `era_id >= 2` 自動使用瓦頂、石基、矮牆前庭的「築基小院」素材；Era 1 使用原茅屋。輪迴返回茅屋，不依 `highest_era` 保留外觀；後續 Era 暫沿用小院，沒有新增 Era 2 建築或永久地塊。

移除以靈田圖充當靈木的常駐 +1 物件。改用三張獨立小景素材，直接點擊世界採收，不新增選單、不與「遊歷 → 機緣」的選項奇遇共用狀態。原資源動作槽的手動採集保持既有規則。

| 小景 | 資源 ID | 每件保存的整數獎勵 |
| --- | --- | --- |
| 靈木萌枝 | wood | 5–9 |
| 靈草花簇 | spirit_grass_low | 3–5 |
| 靈石露頭 | stone_low | 2–4 |

只選已解鎖的資源。首次有可用資源後推進 12 秒產生一件，下一件間隔由專用 SeededRandom 選 45–90 秒，同時最多兩件。四個手工島面插槽隨機挑選、不重複占位；盡量避免同種同時出現。物件留到採收、無過期倒數。滿兩件時暫停小景時鐘，不堆積補發。離線沿核心時間推進補出最多兩件，不自動入庫、不要求準時登入。

草地插槽與瓦頂小院屬展示配置；節點、圖片、動畫、幀率與 cosmetic RNG 不決定收益。遠景隱藏小物件；離開人界保留待採收狀態但不顯示／不可採收。短橫式初始／歸家鏡頭以 HUD 實際邊界配適地標與小景範圍；平移或縮放後變更視窗不強制歸家。採收命中區至少按目前 canvas 變換換算 44 邏輯／CSS 級像素，實體觸控另驗。

## 命令、容量與保存

`AbodeScenery.advance` 由 `TimeAdvancer` 的線上／離線共同路徑呼叫；`GameSession.get_view().abode_scenery` 只讀。`claim_abode_scenery` 接收穩定 `find_id`，在核心確認所在界、解鎖與庫容後入庫／移除物件。滿倉拒絕且保留小景；庫容不足一整批時只入剩餘容量，回饋顯示實際入庫量。使用現有 `Production.compute_caps` 基礎容量契約，與既有手動採集一致；跨系統額外容量倍率整併另立任務。

採收和出生後立即嘗試存檔；失敗明示未存妥、15 秒自動保存重試，不重新執行發獎。一般倒數沿用 15 秒自動保存。存檔成功後重載保存 IDs、獎勵、倒數和 RNG，不重新抽物件；已領取 ID 再送不同 command_id 也拒絕。輪迴清空本世小景，下世 ID 帶 reincarnation_count。

保持外層 schema 2，新增 `state.abode_scenery` 內部版本 1：`version/rng_state/serial/remaining/active[{id,kind,slot,amount}]`；`rules_version=core-flow-4-scenery`。缺此欄位的舊 schema-2 存檔遷移為空，沒有追溯發獎；錯誤版本、型別、範圍、重複 ID／插槽或不合法獎勵拒讀，沿現有兩世代有效槽復原。未宣稱全量舊作存檔相容。

## 交付與驗收

實際來源：`src/simulation/abode_scenery.gd`、`src/abode/abode_scenery_prop.gd`、`living_abode.gd`、`abode_camera.gd`，及 GameState／Session／CommandProcessor／TimeAdvancer／ReincarnationRules／SaveCodec 的接線。資產與完整提示詞見 [素材來源](abode-art/island1/README.md)。

規則、保存、重試、輪迴、取景與場景驗證見 [ISLAND1 驗收](verification/island-scenery.md)。使用者最後美術回饋、實體橫式手機／高 DPR、長期平衡仍待補；不由桌面鼠標推定觸控通過。
