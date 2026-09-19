# M1-A 驗收紀錄｜GameState、命令與首批內容

日期：2026-09-16。狀態：**DONE**。

## 目標與邊界

交付 domain／simulation／application 與內容驗證器的最小集合：穩定 ID、state revision、資源／建築定義、Gather／UpgradeBuilding、費用／產率／容量與新手解鎖。不含時間推進（M1-B）、快照與平台儲存（M1-C）、離線收益（M1-D）、舊檔匯入（M1-E）與遊戲場景接線（M2-A）；展示用 `src/abode/` 未修改。

## 產物

- 內容：`content/manifest.json`、`content/resources/era1.json`（7 資源）、`content/buildings/era1.json`（10 建築，era1 onboarding 顯示序）。
- `src/content/game_content.gd`：有序 ID、定義字典與 content_version 存取。
- `src/content/content_loader.gd`：載入與驗證（成本／prereq 引用、效果鍵、effect_weight、重複 ID、prereq 循環可定位），驗證失敗回帶位置的 errors 並拒載；content_version 為正規化內容的 SHA-256。
- `src/domain/game_state.gd`：revision、era／level、資源（Amount 值＋unlocked／ever_obtained）、建築等級、`to_snapshot_dict()`。
- `src/simulation/onboarding.gd`：LP-002 解鎖鏈、里程碑、茅屋靈力容量 150／級。
- `src/simulation/building_costs.gd`：LP-001 三段指數費用、折扣量化與乘法順序；茅屋起手成本雙軌（新檔 lingli 20／舊檔 money 30）。
- `src/simulation/production.gd`：產率（(level+weight)^1.5）與容量（`_max` 平加、茅屋容量、合成資源乘段）。
- `src/simulation/command_processor.gd`：Gather／UpgradeBuilding 純函式，等級上限 min(max_level, 10)（LP-009）、錯誤碼與檢查順序。
- `src/application/game_session.gd`：`create_new_game`／`submit`（冪等登記優先於 revision 檢查、FIFO 256）／`get_view`（費用與 affordability 來自核心）。
- `tests/m1a_core_runner.gd`：headless 契約測試。

## 驗收環境與命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m1a_core_runner.gd
```

2026-09-16 實測（Godot 4.7.2.stable.official.ed1daf0bf）：import 成功；runner 退出碼 0，輸出 `PASS: M1-A core contract, content validation, cost/onboarding parity, commands, idempotency, determinism.`，無 SCRIPT ERROR。

測試涵蓋 13 群：內容載入（content_version 穩定、ID 順序）、內容驗證（缺資源引用、缺建築引用、未知效果鍵、rate 效果缺 weight、重複 ID、prereq 循環 `a -> b -> a` 各自可定位拒載）、費用 parity（`m0-b-v1.json` 全部 5 向量）、onboarding parity（fixture 3 狀態＋era>1／version<1 非活躍）、新檔真實空白初始（全 0、僅 lingli 解鎖、僅茅屋可見、無免費產率）、Gather（+1、clamp、鎖定／未知／非 basic 拒絕、滿容量）、升級（未知／鎖定／ERA／等階上限／前置未滿／缺料不扣款、茅屋 0→1 扣 20、1→2 扣 31、解鎖事件與 changed_ids）、等階上限（茅屋 2、其餘 10）、冪等（重送同 command_id 不重複扣料、STALE 重試回 DUPLICATE 帶原結果）、過時 revision 拒絕且不改狀態、非法命令形狀、確定性（兩 session 同命令序列得到相等 snapshot 與 view）、產率與容量數值。

## 已知限制

1. 場景 UI 尚未接 GameSession（M2-A）；本任務以 `get_view()` 的費用字串／affordable／next_objective 證明「UI 讀核心」的 API 邊界，非畫面行為證據。headless 契約測試不等於瀏覽器互動。
2. 冪等登記僅存在於記憶體 session（FIFO 256、僅成功命令）；跨存檔的 command_id 持久化屬 M1-C。
3. era1 新檔下天賦、costReduction、manual_gathering_boost、building_mastery 加成輸入全為 0：公式分支已移植並有 parity 向量（折扣案例），但無對應遊戲內容；era>1 progression 解鎖未實作（M4）。
4. LP-003 容量升級容差 0.1 的精確語意與 LP-004 修煉時間留 M1-B。
5. ADR-008 指定的早期候選檔（`src/domain/amount.gd`、`amount_compat_v2.gd`、`seeded_random.gd`）仍未刪除；本任務全部程式與 runner 只引用 `AmountCompat`／`SeededRandomCompat`，候選檔無任何活躍引用，刪除留待使用者確認後的提交。
