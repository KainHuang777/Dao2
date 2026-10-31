# 修仙問道 v2：itch.io 部署工作流

專案 **Dao Ascendant**：https://kainhuang.itch.io/dao-ascendant

編輯頁：https://itch.io/game/edit/5261584

固定上傳目標：`kainhuang/dao-ascendant:html5`

目前採 **Draft／$0 or Donate**。這套工具只更新遊戲檔案，不會公開頁面或更改價格、AI 揭露、收款設定。日後若頁面已改 Public，再執行上傳就會更新公開版本。

## 第一次設定

需要既有 Godot **4.7.2** 與同版 Web 模板、Python 3.11 以上、Node.js。Godot 使用 Compatibility／單執行緒 Web；工具不更新引擎或模板。

1. **先驗證 itch.io 帳號的電子郵件**。未驗證會收到 `Please verify your account's email address before uploading a build`，不能上傳。
2. 在本專案 PowerShell 執行官方 butler 安裝與登入：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/setup_itch_butler.ps1
.\deploy_itch_web.bat -Action Login
```

安裝腳本只從 itch.io 官方 broth 下載穩定版到被 Git 忽略的 `build/tools/butler/`；已存在時沿用，不修改系統 PATH。第一次登入請使用本人 itch.io 帳號，自行確認授權。butler 使用其標準使用者目錄保存憑證；不要將 token、驗證信連結或登入日誌貼進專案文件／Git。

3. 首次上傳後，到編輯頁的 html5 頻道勾選 **This file will be played in the browser**，再 Save。HTML5 標記必須在網站設定，單靠頻道名稱不會自動完成。

## 日常一鍵部署

雙擊根目錄 **deploy_itch_web.bat**，或：

```powershell
.\deploy_itch_web.bat
# 自訂可追溯版本；不指定時使用「本機時間-Git短SHA」
.\deploy_itch_web.bat -Version 2026.10.30-preview1
```

流程依序為：

1. 核對本機 Godot 4.7.2，取得遊戲來源指紋。
2. 隔離 APPDATA，重新匯出到 `build/itch-web/`，不改一般 `build/web/`。
3. 準備 Brotli 校驗與四首原始 MP3 companion。
4. 以明確允許的執行檔清單封裝 ZIP；`index.html` 位於根目錄，不打包來源、日誌、金鑰、測試 fixture、壓縮副本或 manifest。
5. 校驗來源／輸出／ZIP 一致、HTML5 容量與路徑限制，產生 sidecar manifest，執行通用 delivery_check。
6. butler 上傳同一個 html5 頻道，帶上版本號。上傳失敗會傳回非零退出碼，不顯示為成功。
7. 到 itch.io View page 等待處理完成，點 Run game／Launch game，做實際遊玩與重載保存抽驗。

**按一次上傳不代表驗收通過或公開發布。** 公開版本／大型里程碑仍依 AGENTS.md 的 L3 與使用者核定處理。本次先試部署到 Draft；既有遊戲回歸失敗不會因部署而視為已解決。

## 其他入口、重試與核對

```powershell
# 只匯出及打包，完全不上傳
.\deploy_itch_web.bat -Action Prepare
# 只檢查現有包，完全不上傳
.\deploy_itch_web.bat -Action Verify
# 預覽會上傳的檔案，不建立遠端版本
.\deploy_itch_web.bat -Action Push -ReuseExport -DryRun
# 網路／Email驗證／登入修復後，重試同一份已校驗包
.\deploy_itch_web.bat -Action Push -ReuseExport
# 瀏覽器手動上傳備援：準備新包並開啟編輯頁
.\deploy_itch_web.bat -Action Browser
# 保留舊的一鍵打包入口（僅打包）
.\package_itch_web.bat
```

`-ReuseExport` 只接受本工具先前產生且仍與來源、匯出檔一致的 ZIP／manifest；缺檔、來源變更、ZIP 或輸出被修改都會拒絕。需要不同版本號時重新準備，不在重試時偷換版本。

產出：

- `build/dao2-itch-web.zip`：實際上傳檔。
- `build/dao2-itch-web.manifest.json`：版本、來源指紋、目標、各檔與 ZIP SHA256；不含帳號憑證。
- `.test-output/itch-*/`：每次匯出獨立日誌；失敗依工具輸出的 [LOGS]／錯誤路徑查閱。

如果明確指定其他 butler 執行檔：

```powershell
.\deploy_itch_web.bat -Action Push -ButlerPath C:\Tools\butler\butler.exe
```

## itch.io 設定與測試

- Classification：Games；Kind：HTML；Release status：In development。
- 正式託管設定為 **Click to launch in fullscreen**：點 Run game 後以整個瀏覽器內容視窗執行，不依賴作業系統原生全螢幕。外層捲軸、SharedArrayBuffer 關。1280×720 仍為遊戲橫式構圖基準，Godot 畫布依實際可用視窗響應。
- 目前以桌面滑鼠體驗為主，不勾 Mobile friendly；語言為 Chinese (Traditional)。
- 使用者已確認圖像、音樂、文字與程式均有生成式 AI；四類揭露皆勾選。
- 每次測試至少確認：完成下載後世界可操作、基本命令有回饋、重新載入仍讀得到本次進度、console 沒有阻擋啟動的錯誤。規則 runner 不替代瀏覽器輸入／IndexedDB 證據。
- 現有 itch.io 存檔視為玩家資料，不清除 storage 或注入 fixture。首次使用空白專案來源時才作新檔測試。
- 公開前另備妥封面、實際遊戲截圖與頁面資訊；收款由帳號本人處理。

Chrome 擴充功能上傳若回報 file URLs 權限：在同一個 Chrome 個人資料的 ChatGPT 擴充功能詳細資料開啟 **Allow access to file URLs**；未生效可使用已登入 butler，或由使用者在網站手動選 ZIP，不變更瀏覽器安全機制。

## 封裝限制與驗證

依 itch.io 官方 HTML5 規範：最多 1000 檔、路徑最多 240 字元、解壓後合計最多 500 MB、單檔最多 200 MB。網站顯示的上傳 ZIP 容量額度與 HTML5 解壓限制是不同限制；工具保守以十進位 MB 檢查。

```powershell
python -m unittest discover -s tools -p test_itch_web_package.py -v
python tools/delivery_check.py --web build/itch-web
git diff --check
```

這些只驗證部署工具與交付物，不代稱全遊戲 L3。當來源與環境未改時可引用既有規則驗收，並明列既有未通過項。當輪部署的實際結果只記在 [開發狀態](development-status.md#itch-deploy-workflow)。

官方依據：[HTML5 上傳規範](https://itch.io/docs/creators/html5)、[butler 安裝](https://itch.io/docs/butler/installing.html)、[butler 上傳／HTML5 頻道設定](https://itch.io/docs/butler/pushing.html)。
