# 修仙問道 v2：Web 部署與 itch.io 發布指南

本文件記錄《修仙問道 v2》Web 版本的發布架構、評估背景、打包工具用法以及 itch.io 的詳細部署設定流程，供後續發布時對照操作。

---

## 一、平台選型背景與評估

### 1. 為什麼不直接使用 Vercel？
* **單檔大小硬限制（Hard Limit）**：
  * Vercel Hobby（免費方案）對單一靜態檔案的大小上限為 **100 MB**。
  * 本專案 Godot 資源封裝檔 `index.pck` 大小約為 **126.3 MB**，直接部署或透過 GitHub 連動會被直接拒絕（413 Payload Too Large / GitHub 100MB push limit）。
* **傳輸量爆炸風險（Bandwidth Quota）**：
  * Vercel 免費配額為 **100 GB / 月**。
  * 玩家初次進入遊戲需下載 `index.pck` (~125MB) + `index.wasm` (~8~38MB) + BGM 音訊 (~5MB)，單次完整載入約消耗 **140~170 MB**。
  * 100 GB 僅能支撐約 **700~730 次新玩家初次訪問**。一旦發布到社群引起關注，流量將在短期內耗盡並面臨網站中斷或額外費用帳單。

### 2. 為什麼選擇 itch.io？
* **完全免費且無流量限制**：不限下載人次、不限頻寬流量，最適合獨立遊戲分享與試玩。
* **容量寬裕**：單一 Web ZIP 封裝包上限高達 **1 GB**（本專案約 136 MB，綽綽有餘）。
* **隱私與權限彈性**：提供「Draft（草稿）」、「Restricted（限制公開：密碼保護 / 專屬秘密連結）」等多種模式，在尚未公開前僅讓特定測試人員體驗。

---

## 二、Web 核心規格與架構

1. **引擎與架構**：Godot 4.7.2 Web Export，採用單執行緒（Single-threaded WebAssembly，`variant/thread_support=false`）。
2. **無特殊安全標頭依賴**：不需要 `SharedArrayBuffer`，不需要伺服器配置 `Cross-Origin-Opener-Policy (COOP)` 或 `Cross-Origin-Embedder-Policy (COEP)`。
3. **存檔機制**：使用瀏覽器本機 IndexedDB（`user://` 虛擬檔案系統），同網域下重整網頁或關閉後再次開啟進度不遺失。
4. **音訊架構**：背景音樂採外部 Web Audio 串流載入（位於 `audio/bgm/`，共 4 首 MP3）。

---

## 三、一鍵打包工具

專案已內建 itch.io 專屬自動打包腳本，能自動清理多餘暫存檔並符合 itch.io 目錄結構。

### 1. 執行方式
* **便捷批次檔（雙擊執行）**：
  `package_itch_web.bat`
* **PowerShell 指令**：
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\package_itch_web.ps1
  ```

### 2. 產出檔案
* 檔案位置：[`build/dao2-itch-web.zip`](file:///e:/WORK/Dao2/build/dao2-itch-web.zip)
* 檔案大小：約 **136.5 MB**

### 3. 封裝規則與包含項目
* `index.html`（保證置於 ZIP 根目錄，這是 itch.io 辨識 HTML5 遊戲的核心條件）
* `index.js`、`index.wasm`（WebAssembly 引擎主體）
* `index.pck`（遊戲資源與場景）
* `index.audio.worklet.js`、`index.audio.position.worklet.js`（音訊處理腳本）
* `audio/bgm/*.mp3`（四首完整背景音樂）
* 圖標與 Splash 圖像檔
* *自動排除*：`.br` 壓縮備份、`.import` 來源索引、`.log` 檔案、`compression.json` 等非執行所需冗餘檔案。

---

## 四、itch.io 上架詳細設定 SOP

當準備好發布時，請依照下列步驟於 [itch.io](https://itch.io) 後台設定：

### 1. 建立專案
1. 登入 itch.io，點擊右上角頭像 ➔ **Create new project**。
2. **Title**：輸入遊戲名稱（例如：`修仙問道 v2`）。
3. **Classification**：選擇 **Games**。
4. **Kind of project**：務必選取 **HTML**（*You have a ZIP or HTML file that will play in the browser*）。

### 2. 上傳遊戲壓縮檔
1. 在 **Uploads** 區塊點擊 **Upload files**。
2. 選取專案產出的 [`build/dao2-itch-web.zip`](file:///e:/WORK/Dao2/build/dao2-itch-web.zip)。
3. 上傳完成後，在該檔案項目勾選：
   * ☑ **This file will be played in the browser**

### 3. 畫面與嵌入設定（Embed options）
向下捲動到 **Embed options** 區塊：
* **Viewport dimensions**：
  * **Width**：`1280`
  * **Height**：`720`
* **Orientation**：選取 **Landscape**（橫式構圖基準）
* **Frame options**：
  * ☑ **Fullscreen button**（**強烈建議勾選**，提供右下角全螢幕按鈕，玩家全螢幕體驗最佳）
  * ☐ **Enable scrollbars**（不勾選，遊戲內部已具備響應式排版，避免出現外層雙捲軸）
  * ☑ **Automatically start on page load**（可依喜好勾選；勾選則進入網頁自動載入遊戲，不勾則顯示點擊「Run Game」按鈕）
* **Mobile friendly**：可勾選或暫緩（目前觸控專項驗收暫緩，建議標註優先使用電腦/滑鼠體驗）
* **SharedArrayBuffer support**：
  * ❌ **不要勾選**（本專案已為單執行緒，無需開啟此選項）

### 4. 存檔與安全性提示
* itch.io 內嵌 iframe 預設支援 IndexedDB 本地存檔。玩家只要使用相同瀏覽器訪問該網址，遊戲進度將自動保留於本地。

### 5. 存取權限控制（Visibility & Access）
* 若僅供自己與特定好友測試：
  * 選擇 **Restricted**（限制公開）。
  * 於 **Secret URL** 取得專屬分享連結，或勾選 **Password protected** 設定密碼。
* 確認後點擊頁面最下方 **Save & view page**，即可立即開始遊戲測試。
