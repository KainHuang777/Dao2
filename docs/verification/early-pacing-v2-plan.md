# EARLY-PACING v2 調參 執行計畫（2026-10-11 核准）

v2 規則變更，不考慮舊存檔相容（E 強制清除）。核准依據：使用者 2026-10-11 對話核准。

## 定案

- A 分級資源門：era JSON 白名單 `level_up_requirements.graded_resources = [{from_level:int>=1, resources:{id:float>=0}}]`；`Cultivation.level_up_cost(era_def, era_level, cost_reduction)` 簽名不變，合併規則 total[id] = flat[id] + Σ graded[id] (from_level <= era_level)，再乘 (1-reduction) 後 floor_amount。era1：L3 木40、L5 石40、L7 靈草30。era2：L1 靈木20+銅精10、L5 百年靈草5。loader `_validate_era_references` 允許 DEFERRED_RESOURCE_IDS（catalog 注入資源）置於 base-load。
- B 聚靈丹不溢滿：`AlchemySystem.consume(state, pill_id, count, training_ceiling:=-1.0)`；ceiling>0 時 gain=min(60*count, max(ceiling-training_seconds,0))；service 點 `command_processor._apply_consume_pill` 傳 `next_level_required_seconds(era_def, level, 0,1)`，滿員回 TRAINING_ALREADY_COMPLETE 不扣料。pacing_sim 同步。
- C 倉儲/成本再平衡（初值，Wave 2 依審批收斂）：wooden_house cf1.6→1.45 money_max50→80；herb_farm cf2.0→1.7；storage_lingli cf→1.2 lingli_max→160；storage_money cf→1.3 money_max→700；storage_stone/wood/herb cf→1.3，caps→300/300/160；base caps money300 wood150 stone150。島： extractor {wood100*L, bronze5*L}；workshop {timber5*L, bronze5*L}；storage {timber5*L, stone100*L}；capacity 150*storage_level；路線升級 {timber10, bronze10}。
- D 由 A/era2 graded + C 島sink 承擔；不引用 stone_mid（era3 才解鎖）。
- E 存檔：SCHEMA_VERSION 3→4（僅接受 4）；RULES_VERSION=early-pacing-v2-1；`SaveCodec.classify_envelope()->String`；int<4 → rescue 備份 raw（save_pre_v2_rescue）→ SaveSlots.reset() 三槽清除 → `_forced_reset` 旗標 → 全新局 + 一次性 modal（OfflineSummary 模式，`tutorial_flags["v2_rules_notice_seen"]`）；erase 不可用時維持 brick 重試、不誤刪；int>4/損壞維持 brick。
- 審批閾值（orchestrator 獨占 tools/early_pacing_targets.json）：C3 高限 120s→600s。

## 分區（單一寫者）

- W-A：cultivation.gd、content_loader.gd、eras/era1.json、eras/era2.json、tests/early_pacing2_runner.gd（新）
- W-B：alchemy_system.gd、command_processor.gd（僅 consume 路徑）、pacing_sim.gd、tests/early_pacing2_pill_runner.gd（新）
- W-C：island_progression.gd、island_economy.gd、buildings/era1.json、resources/era1.json
- W-E：save_codec.gd、save_manager.gd、living_abode.gd、abode_modal_manager.gd、v2_rules_notice.gd（新）、受影響之 persistence 測試
- orchestrator：tools/early_pacing_targets.json、run_all_runners.ps1 註冊、docs、Wave 2 調參、runner 全量驗證

## 驗證

Wave 1 fan out → orchestrator `--import` + 全 runner 一次 → 跑 early_pacing_audit --enforce 收斂數值 → 第二輪 runner + 審批 → 更新 docs/verification/early-pacing-v2.md、development-status、rule-differences → fusion-auditor 獨立複核。
