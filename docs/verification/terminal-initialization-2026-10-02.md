# ENV-TERMINAL：終端初始化修復

日期：2026-10-02（Asia/Taipei）。狀態：DONE，限本輪終端啟動／文件讀取／Godot 版本檢查。使用者優先要求環境修復；未展開遊戲功能或 UI 改版。

## 診斷

- Codex app：26.928.3736.0；Windows build：26200.9457，DisplayVersion 25H2。登錄 ProductName 仍顯示 Windows 10 Home，不據此判定實際產品世代。
- Codex 終端实际使用 bundled PowerShell 7.6.5。一般沙箱的 PowerShell 與 cmd 均在啟動前失敗；同工具獲授權的沙箱外診斷可執行。
- 本機 `C:\Users\asus\.codex\.sandbox\sandbox.2026-10-01.log` 明確記錄 `deny ACE failed on E:\WORK\Dao2\.git: open deny ACL target for update`，繼而 `setup refresh had errors`。
- `.git` 根目錄擁有者為 CodexSandboxOffline；專案根目錄為 asus。故障為沙箱 helper 無法更新該目錄的保護 ACL，非 PowerShell 過舊。
- 無法由現有證據確認 Windows 升級是否直接造成擁有者錯置；不把使用者提供的時間先後當因果證據。

## 修改與命令

- 保存 UI 提案：`docs/ui-material-direction-2026-10-02.md`；待稍後實作。
- 備份 `.git` 根目錄原始 SDDL：`terminal-git-root-acl-before-2026-10-02.txt`。
- 一般使用者 `icacls E:\WORK\Dao2\.git /setowner <current-user>` 回傳 5，拒絕存取；未更改擁有者。
- 新增 `tools/repair_codex_git_owner.ps1`，固定路徑、拒絕 reparse point、核對原擁有者 SID，只改 `.git` 根目錄的擁有者，不遞迴、不更改 DACL、不寫 Git 內容。
- 透過 Windows UAC：`Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden` 執行腳本，退出 0。結果記錄 `terminal-owner-repair-result-2026-10-02.json`：success=true、dacl_unchanged=true、recursive=false，擁有者改回 asus。
- 重跑一般沙箱 `exec_command`：PowerShell 7.6.5、README 讀取成功、Godot `--version` 回傳 `4.7.2.stable.official.ed1daf0bf`，退出 0。
- 修復後沙箱 helper 日誌：`applied deny ACE to protect E:\WORK\Dao2\.git`、`errors=[]`。保護限制正常恢復，不以停用沙箱解決。
- 預設終端啟動（login 預設）也成功；沙箱內直接啟動 Windows PowerShell `5.1.26100.9444` 與 `cmd.exe /c ver`，均退出 0，`.git` owner 核對為 asus。故未升級 Windows PowerShell 5.1 也能正常執行。

## 限制與下一步

本輪不修改遊戲來源、存檔或匯出物，未重跑全量 gameplay Runner。日誌另有隱藏 `C:\Users\Default` 属性被拒的訊息，但本輪終端命令退出 0；不宣稱整個系統無警告。瀏覽器 runtime 未於修復後重新驗證。

下一步以新對話接續保存的配色方向；先讀專案 UI 規範與現有材質實作，選定 Roadmap 任務範圍，再開始試版。現有大量共享工作區修改保留。

官方機制參考：https://learn.chatgpt.com/docs/windows/windows-sandbox 。根因與成功結果來自本機實測，不從網路案例推定。
