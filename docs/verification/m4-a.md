# M4-A 手工第二界（靈界 · 天靈洞天）驗證紀錄
2026-10-03 M4-A-R1 正式整合驗收 **DONE**：251 checks、40/40 Runner、最後相容修正四項相關回歸、Web 匯出及 IAB 桌面兩版型滑鼠／保存重整通過。修正按鈕重建、正式獎勵庫存與保存命令收據；完整命令／通知／BUFF TIP 矩陣與證據邊界見 [R1 驗收](m4-a-r1.md)。以下記錄保留各自歷史日期，不代表 R1 仍待開發。

2026-10-03 ART-A1 美術複核：目前靈界切換仍沿用人界地形，改題字與遮罩色，尚未交付不同據點的專屬場景美術；人界 Era 演出亦尚未依據點分開。下文規則／面板與歷史匯出結果不代表美術完成。依使用者要求，靈界據點須設計自己的場景，與人界境界升級分開；見 [來源核對與未完成項](landmark-and-spirit-art-audit.md)。

2026-10-02 DOC-A-R1 現況補記：GameSession 白名單與宗門／跨界／BUFF 呼叫已補上；以下 9/28 UNKNOWN_COMMAND 記錄是歷史發現，不再表示目前尚未接線。宗門 Session 成功路徑已有 runner，本輪固定入口 34/34 PASS；全部新命令拒絕／冪等／保存及實際 Web 操作仍按 R1 補證，未宣稱完整端到端驗收。見 [複核](doc-a-r1.md)。

2026-09-28 歷史狀態複核：靈界領域、存檔與面板已實作，但正式場景 `switch_realm`／據點命令仍被 `GameSession.KNOWN_COMMAND_TYPES` 拒絕。Domain／UI Runner 不代表 Session 閉環。M4-A-R1 完成前，以下紀錄只代表模組曾通過其涵蓋測試，不作整合 DONE 證據；詳見 [REF-A](ref-a.md)。

2026-09-28 歷史狀態：領域／存檔／面板已實作；當時 Session 命令整合未通過，追蹤任務 M4-A-R1。原始測試結果保留如下。

規格依據：[Roadmap M4-A](../../ROADMAP.md)、[技術架構 02-technical-architecture.md](../02-technical-architecture.md)。

---

## 交付項目

1. **第二界世界觀與據點架構 (`src/simulation/realm_system.gd`)**：
   - 定義手工第二界：**靈界 · 天靈洞天（`spirit_realm`）**。
   - 三大專屬活躍據點（支援 1~10 級修築與擴建）：
     - **天樞陣眼 (`celestial_hub`)**：每級每秒消耗人界下品靈石 5 枚，凝練靈界專屬資源「極品靈晶」0.5/秒。
     - **化靈仙池 (`pure_pool`)**：每級每秒消耗極品靈晶 0.2，提純專屬資產「天青靈液」0.05/秒；每級提供全洞府修煉速度 +15% 跨界反哺加成。
     - **虛空引靈台 (`void_beacon`)**：每級擴充極品靈晶儲量上限 500、天青靈液儲量上限 50。
   - 跨界解鎖門檻：築基期（`era_id >= 2`）或轉世次數 $\ge 1$ 且凝聚道心 $\ge 15$。

2. **跨界法則與機會成本供給取捨**：
   - 雙界並行模擬（Dual-Realm Parallel Simulation）：不論玩家當前身處人界洞府或靈界洞天，`TimeAdvancer` 統一驅動雙界產能與消耗。
   - 機會成本：天樞陣眼運轉需穩定扣除人界下品靈石，若人界靈石匱乏則天樞陣眼自動停滯，產能鏈具備嚴格因果防禦。

3. **領域模型與存檔擴充 (`GameState` & `SaveCodec`)**：
   - `current_realm: String`（當前視界，預設 `human_realm`）。
   - `realms_data: Dictionary` 持久化靈界三大據點等級與專屬產能狀態。
   - `SaveCodec` 實現向後相容解碼。

4. **指令擴充 (`CommandProcessor` & `GameSession`)**：
   - 指令 `switch_realm`：在人界與靈界間自由切換神遊視角。
   - 指令 `upgrade_realm_outpost`：消耗人界與靈界物資晉階天樞陣眼、化靈仙池與虛空引靈台。
   - `GameSession` 暴露 `switch_realm()`、`upgrade_realm_outpost()`、`get_realm_view()` 與 `get_realm_bonus()`。

5. **視覺表現與主場景接入 (`src/abode/living_abode.gd`)**：
   - **遠景金色天標**：山域遠景東方顯現金色光暈標記「靈界方向 · 【跨界神遊】」，點擊直接呼出傳送面板。
   - **次級選單入口**：「更多功能」增加第 9 項「靈界洞天」直達。
   - **自適應傳送視窗 (`src/presentation/realm_teleport_modal.gd`)**：
     - 人界與靈界雙界切換卡。
     - 靈界三大據點等級、產率、消耗與反哺倍率監控。
     - 一鍵切換神遊界域與據點升級指令。
   - **天幕與運鏡調諧**：神遊靈界時背景色調調諧為玄金紫光，返家時無縫重置空島標準相機視角。

6. **專屬測試**：
   - `tests/m4a_realm_runner.gd`（exit 0，解鎖條件、切界返家、據點升級、並行模擬與機會成本、修煉反哺、存檔往返、UI 面板全通）。

---

## 驗證證據

1. **CLI 測試**：
   - `tests/m4a_realm_runner.gd`：PASS（退出碼 0）。
   - 全量 25 項 Runner 經 `tools/run_all_runners.ps1` 執行全部 PASS（退出碼 0）。
2. **Web 匯出**：
   - `Godot --export-release Web build/web/index.html`：PASS（退出碼 0）。
