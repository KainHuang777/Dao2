# 可直接貼給 AGY 的 Prompt

以下區塊可整段複製。AGY指你接手使用的開發代理；本文件未替你發送或啟動它。

```text
請接手 E:\WORK\Dao2 的 RES1-C2-PERF-R2 持續FPS劣化定位與修復。使用者已決定R2由AGY處理，Codex並行推進RES1-D1（Era3前置／丹霞島T3隔離核心契約）。請實際調查並完成可驗證的修復，不只給建議。

先完整讀AGENTS.md、README.md、ROADMAP.md、docs/ai-handoff.md、docs/development-status.md、updata.txt最新頂部，以及docs/handoffs/2026-10-05-r2-agy.md。R2詳細資料讀docs/verification/res1-c2-recovery-browser.md、res1-c2-sustained-degradation.md、res1-c2-main-loop-tracing.md；FPS政策依docs/decisions/ADR-010-idle-frame-recovery-budget.md。UI／Web必讀docs/07，架構讀docs/02。先確認實際dirty檔與Godot4.7.2版本，不更新環境或回滾既有改動。

關鍵狀態：前輪正常頂層1280x720／DPR1.25，初60s59.880與300s59.823通過；追加管理操作300s54.740、同頁延長300s48.088、reload60s35.105均未恢復。本輪同版DPR約1，三組300s59.744／59.564（50次有間隔管理開關）／59.744及reload60s59.847恢復4/4 PASS。DPR和存檔不同（前輪最後木屋3階，此輪2階），不代表修好；先同進度重現／對照DPR1和1.25，不預設DPR是根因。

既有profile把某83.3ms長幀縮小到Godot MainLoop_runner84.1ms，但已量_process僅0.4ms，没有完整WASM stack／其他節點／繪圖耗時。同期系統GPU-process高CPU時遊戲仍近60；heap大小也不單獨對應FPS。不能直接宣布GC、GPU或節點洩漏。raw／summary與命令在上述交接。4248服務與存檔可先確認；已有進度只開遊戲，不重新種檔；不同browser profile不一定共享存檔，必要時用新空origin與命令賺得fixture。PID/session ID不要當目前仍有效。保留玩家資料與舊失敗證據。

工作要求：固定當前R2 dirty來源與build hash基線，先有正常版實際重現。取樣期間與Codex協調，不同時import／export／跑全量Runner／壓縮，隔離checkout也共用同機CPU/GPU。低谷重現後依證據增加opt-in完整主迴圈／節點数／orphan／draw calls與同期系統診斷，再選低特效A/B／渲染／配置釋放／UI／保存路径；診斷profile不算正常FPS放行。規則／RNG／收益與動畫獨立，正式UI走Command／View，保存頻率／版本／復原／重試不得為掩蓋卡頓任意改。保留.uid，不手改.godot或build。

分工：你主攻abode／presentation與profile／metrics／Web工具；Codex先做D1隔離資料與純規則契約。Session、SaveCodec、TimeAdvancer、ContentLoader、manifest、project/export、共用fixtures与Runner入口要單方協調修改，防止相互覆蓋；真正根因需碰共享核心時先說明範圍。共用文件更新前重新讀，保留另一方進度。

验收仍按ADR-010：常態目標60、偶發約30且回升可接受；不用每組平均必須60.000或desktop p95<=20硬gate。正常≥60s、5s窗>=55FPS占>=80%觀測時間、末10s恢复；另正常5分鐘、至少50次管理／切島、同頁延長與reload趋势。持續低FPS／末段未恢復要解決，保留失敗樣本。手機／高DPR／触控／自然凍結／跨瀏覽器／長期GPU與人工美術沒實測仍待驗，不以桌面或空白rAF對照代替。只修孤立尖峰或59.x不是本任務目标。

修改後跑適當Godot／保存／規則／工具契約與正常Web真實互動，全部記exit碼；新export補音樂companions。建立docs/verification/res1-c2-agy-r2.md，列root-cause證據、修改檔案、前後同條件數據、raw／summary／console／截图、命令、失敗與剩餘限制。達成有界DoD才改狀態；若未重現，記錄條件和下一驗證假設，R2保持IN_PROGRESS，不能用本輪DPR1 PASS消除舊失敗。保留C/C2未過範圍，D1并行不代表完整C/D已放行。

完成本階段更新development-status和英文updata頂部，依Context Guard交接到New Chat。先回報本次重現計畫／驗收與碰觸檔案，然後直接執行一般已授權命令，不為常態工具操作重複問確認。
```
