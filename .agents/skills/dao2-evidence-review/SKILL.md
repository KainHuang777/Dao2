---
name: dao2-evidence-review
description: 唯讀審查 Dao2 任務或里程碑的驗收證據，逐項對照 runner、Chrome 操作、候選包與玩家回饋，找出證據缺口或狀態摘要落差。
---

# Dao2 驗收證據審查

以使用者核定範圍、Roadmap、任務契約及 `AGENTS.md` 的驗收級別為準。從 `docs/development-status.md` 和實際證據找出每項驗收條件對應的日期、版本、命令或操作、結果及證據位置。工作樹若有未提交修改，記來源範圍或包的雜湊，單靠 Git HEAD 無法辨識版本。

- runner：確認實際選取、矩陣範圍、退出碼、逾時／重試與關鍵 assertion。分批結果核對唯一入口聯集，列明排除入口及理由。
- Chrome：區分啟動／版面、真實點擊／路由、實際重載與保存、自然時間及人工體感。截圖應標版號、尺寸及當下狀態。共用包有多個入口時分別核對。需要檢查交付包時沿用 `tools/delivery_check.py --web <目錄>`。
- 摘要：對照 README、Roadmap、最新狀態及交接文字。區分歷史記錄、最新階段狀態與確切待辦。

回覆「條件 → 證據 → 已證實／有界／待驗／失敗 → 最小補驗」。有權威且相符的既有證據就引用其範圍。文件落差本身採靜態檢查；補驗或修改按當次任務和分級規則處理。

流程參考 [Claude Code Game Studios 的 test-evidence-review](https://github.com/Donchitos/Claude-Code-Game-Studios/blob/main/.claude/skills/test-evidence-review/SKILL.md)。
