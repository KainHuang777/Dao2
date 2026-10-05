# 2026-10-05 Git 分支與工作樹同步稽核

範圍：依使用者要求檢查是否需要 merge，避免遠端拉取造成版本誤認。未執行 merge、pull、commit、push、reset 或刪除工作樹。

## 已驗證狀態

- `git fetch origin --prune` 成功（exit 0）；遠端預設為 `main`。
- 唯一本地分支 `main`：`d0e528290b051fee726ff392faa2224631850cf2`。
- `origin/main`：`f20d3ef`；`main...origin/main` 為 **1 / 0**（本地獨有／遠端獨有）。沒有需從遠端 main 合併的提交；本地既有提交尚未推送。
- `origin/master`：`ff86f85`；`main...origin/master` 為 **7 / 1**。共同祖先 `b9f6685`。`git cherry main origin/master` 顯示 `+ ff86f85`，不是可認定已套用的等價 patch。
- master 獨有提交為 `feat: complete M3-B content, skill purchase, and skill effects pipeline`（2026-10-02）。涉及 content schema/progression、skill system、content reconciliation 與相關 runners；main 的檔案結構／manifest 已不同。是否保留這套舊設計需逐項檢查，不能直接認定應全量 merge，也不能當作已整合。
- 主目錄 `E:/WORK/Dao2`：稽核記錄寫入前 **45 個 tracked 修改、273 個 untracked 檔案**（`--untracked-files=all`）。大量較新 D1/D2/R2 成果尚不在提交中，遠端拉取不會取得這些成果。
- 另一工作樹 `C:/Users/asus/.codex/worktrees/7c23/Dao2`：detached HEAD `4dd4ddbab3993e23ec0025904691d57ed6512537`。此提交是 main 祖先，`main...4dd4ddb` 為 **5 / 0**，沒有工作樹獨有的已提交內容。
- 工作樹仍有 **17 個 tracked 修改**及未追蹤 VFX 資產／程式／證據，包括 `native_vfx.gd`、`title_glow.gd`、`assets/vfx/`。主目錄沒有 `src/presentation/native_vfx.gd` 或 `assets/vfx/`。不能視為已整合或安全刪除。工作樹本身不是額外分支，其未提交內容不能直接用 git merge 帶回。
- main upstream 正確指向 `origin/main`；目前 `pull.rebase=false`，未設定 `pull.ff`。一般 main pull 不會拉入 master 或 detached 工作樹修改。

## 建議順序

1. 先盤點並保存主目錄與舊工作樹的未提交成果；依內容分組提交，保留原資產與驗證證據。不要先 reset/clean 或移除工作樹。
2. 針對舊工作樹 VFX 逐項移植到目前 main，解決與較新 HUD／流程的重疊，再依呈現規格測試；先保存成分支／提交可使差異可追溯。
3. 對 master 獨有內容做功能稽核，決定採用、調整或記錄為已被新設計取代；不可未審查便合併旧 manifest／技能模型。
4. 整合並通過必要驗證後，同步 main 到 origin/main（普通 push，無需 force）。其他環境明確追蹤 main。
5. 未來拉取使用 `git pull --ff-only origin main`，讓真正的提交分歧明確停止，避免自動生成 merge；這不會保存或同步未提交內容。此輪未更改 Git 設定。

## 命令與限制

執行 `git status`、`branch -avv`、`remote -v`、`worktree list --porcelain`、`fetch origin --prune`、`rev-list --left-right --count`、`log`、`merge-base`、`cherry`、`diff --stat/--name-status` 與 upstream/pull 設定讀取。Git 稽核不修改遊戲，未重跑 Godot 或瀏覽器遊戲驗收。

初次 sandbox fetch 因 `.git/FETCH_HEAD` 拒寫失敗；sandbox `ls-remote` 因網路失敗。升權同一 fetch 成功，以上遠端比較使用更新後 refs。工作樹 sandbox status 回報 must be run in a work tree，升權 `git -C ... status` 成功取得實際修改；初次失敗不代表工作樹乾淨。沒有 automatic approval review rejection。部分 diff 顯示 LF/CRLF 提醒。
