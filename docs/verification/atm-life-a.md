# ATM-LIFE-A／REPORT-1A：正式一世卷末

2026-10-22。**DONE（CLI／原生及桌面 Web 有界）**。設計、正式接入與本輪桌面驗收完成；本階段停止。

## 核定與範圍

本輪使用者指定任務，先選擇審閱，再回覆「布局OK」與「優先序與文稿沿用」。ATM-LIFE-DESIGN 的布局、十題條件／優先序與逐句文稿接受；F-C 題名800／題簽900、文楷及最近9世／352KiB沿既定決策，不重問。LEDGER-0 先決條件已完成。

正式 Godot 輪迴頁接題名、生命狀態卷末句、逐句小傳與最多三件留痕。「查記錄」列本世事件序號與年歲；沒有第三件就留白。保留 canonical 群組、GameTab、CloseSeal、原資格／收益／確認取消／演出／保存。短式將兩個頁內分頁併固定底列，題名及卷末句首屏可讀，正文與來源單區內捲，收益與44px操作固定。保存拒寫保護內可讀當次凍結卷末，世界操作仍鎖住，只能閱讀與沿原流程重試保存。

完整資源帳目、權威機緣收據、前世卷冊導覽與事件回聲屬後續批次；沒有新增空分頁或新經濟規則。未覆寫玩家保存或凍結 build/web，未 commit／push。

## 來源與契約

- 新 `src/domain/life_report.gd`：純確定性選文，只讀同一已驗證生命記錄。十題依核定順序；失敗後須有較後晉階；取得成熟須同獸instance且排序成立。garden 反序採已核定中性替代句。cloud 的「其後／及至」要求建屋→兩島→結丹，存在性足夠但時序不符則退到有充分證據的題目，不改事件順序。
- `src/domain/life_ledger.gd`：轉世封存時寫 `text_version=report-1a-1` 及 JSON 字串 `frozen_text`（題名ID／正文／卷末句／來源序號／最多三件留痕）。仍是原 schema5／ledger version1 的預留欄位；文字4096 UTF-8 bytes、封存32KiB及總352KiB上限保持。
- `src/application/game_session.gd`：顯式 `get_life_report(life_id=0)` 深複製 API；不把歷史塞進每幀 HUD View。頁內依 state identity＋revision＋生命時機快取；相同revision載入另一狀態亦不沿用舊故事。
- `src/presentation/life_report_view.gd`、`reincarnation_panel.gd`、`abode_modal_manager.gd`、`src/abode/living_abode.gd`：正式閱讀與保存故障只讀接線。先選題不封存；取消不轉世；實際轉世以最新提交事實封存。重試沿既有保存／背景結算，不重送轉世命令。
- `src/presentation/ui_typography.gd`：集中敘事字型角色；復用原 OFL 資產，重新產生兩份 runtime 子集及 manifest，沒有下載新字型／美術。控制與數值仍黑體。舊封存若無小傳就明示未記錄，不於讀取時補寫；已有凍結文字不隨內容更新重算。
- 驗證來源 `tests/life_report_runner.gd`、`tests/life_report_ui_runner.gd`、固定 runner 清單；隔離 `src/verification/life_report_fixture.gd`、`life_report_acceptance.gd/.tscn` 及 LifeReportAcceptance preset／feature。正式 Web 排除驗證來源，主場景仍 living_abode。
- 文件：docs30 接受、docs19 共用通則、README／ROADMAP／交接／本驗收與 updata。

## 命令與證據

引擎版本實測 `4.7.2.stable.official.ed1daf0bf`。原生 Compatibility／GTX1660Ti；測試 APPDATA 導向專案 build 下隔離資料。桌面 IAB／DPR約1，遊戲畫布1280×720、844×390、800×360；外層測試工具可捲，不代表遊戲依賴瀏覽器捲軸。

| 命令 | 結果 |
| --- | --- |
| Godot `--version` | exit0，同版引擎，未更新或重裝。 |
| Godot `--headless --path . --import` | exit0；保留既有 JPEG 以PNG命名、user目錄等診斷，不稱乾淨匯入。 |
| Godot `--headless --path . --script res://tests/life_report_runner.gd` | 最終16,400 checks／failures=[]／exit0。8,192條件組合、反序、異獸、來源／容量、只讀／RNG、凍結／重載／內容版本及跨世最高反例。 |
| Godot `--path . --script res://tests/life_report_ui_runner.gd` | 最終137 checks／failures=[]／exit0；四生命狀態×三橫式12圖、三保存故障圖，低特效、換頁／取消、同revision狀態替換與44px。 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 初輪及最終88／88 exit0；最終SCRIPT ERROR 0。最後頁內立即刷新亦由最終原生137項補驗。追加一個cloud時序反例後專項16,400 exit0，未因只增測試再重跑整輪。 |
| `python tools/subset_game_fonts.py`／`--check` | 重建exit0，最後check exit0；原字型缺本輪字元，初次check失敗如實保留。 |
| Godot `--export-release Web build/web-atm-life-a/index.html` | 最終exit0，正常候選；未覆寫build/web。 |
| Godot `--export-release LifeReportAcceptance build/life-report-acceptance/index.html` | 最終exit0，隔離合成進度與故障adapter。 |
| `node tools/prepare_web_compression.mjs <各候選目錄>` | 兩候選最終壓縮與BGM companion均exit0，原文與br往返核對通過。 |
| `python tools/ui_shell_server.py --build build/life-report-acceptance --port 4399/4400` | 正常授權localhost服務；首輪沙箱4399不可達，保留timeout；未修改防火牆或系統保護。 |

原始輸出與截圖位於 [artifacts/atm-life-a](artifacts/atm-life-a)。實際瀏覽器操作、hash及逐項觀察見下方；不將CLI或輸出DOM當成滑鼠證據。

## 初輪失敗與界線

選文 runner 初次型別推導解析失敗，其後測試工具誤用 `to_snapshot`（正確為 `to_snapshot_dict`）；修正測試入口。凍結JSON數字解析後的浮點／整數差異造成兩個相等判定失敗，正式 reader 已按事件序號恢復整數，最終通過。最初原生測試因預設user目錄拒寫未初始化，改用專案內隔離APPDATA重跑；無玩家資料操作。

初輪footer獎勵換行過高及短式首屏只剩重複摘要，已改固定單列收益／短式分頁，並增加題名／卷末句首屏包含檢查。Web初次拒寫確認原有保護層遮住卷末；補只讀閱讀區後須以新包再驗。初輪DOM觀測會隨tree pause停住，不把停住數據當已提交結果；新fixture只讓觀測根節點 ALWAYS，遊戲子樹明訂 PAUSABLE，沒有解鎖世界或跳過保存保護。

Godot退出 Font RID／CanvasItem／ObjectDB 診斷保留；不聲稱日誌零錯誤或 FPS。合成 fixture 不代表自然一生試玩、全舊檔corpus、IndexedDB或quota全矩陣。觸控／實機依既定政策延期，非當前阻擋。


## 最終桌面 Web 結果與交接

- 4399初包：實際滑鼠開來源並捲到三件留痕、確認取消、844／800重排及天賦→卷末返回；取消前後事實及收益相同。初包拒寫保護遮住小傳，修正後以4400新origin重驗，未把初包算成完整通過。
- 4400最終包：1280卷末可讀；800取消不封存。實際滑鼠拒寫→確認轉世，count1→2、道心0→20、僅一份life_id2封存／current3；固定保護訊息與重試之外可閱讀凍結題名、小傳、逐句來源與最多三件留痕。拒寫再試仍相同封存／20道心。保護中844／1280重排保留來源展開、訊息與重試固定。
- 恢復寫入→保存重試→跳過原演出，結果畫面實際顯示第3世／+20道心。重載仍20及完全相同封存字串／settlement_id，沒有第二份或重發；本世預覽回新世行跡。保存恢復會沿原背景結算補經過秒數，新世until可增加，不宣稱重試完全凍結時間。
- `browser-observations.json` 七項均true，含原生滑鼠／捲動觀察及DOM狀態核對；DOM觀測只是隔離輔助，不取代截圖與真實輸入。最終fixture觀測根 ALWAYS，遊戲子樹 PAUSABLE；拒寫期間觀測仍更新，但世界原保護保持。
- `browser-console.json` 留有一則未附來源URL的 MutationObserver TypeError（工具／頁面歸屬未定），與既有輪次相同；不聲稱console乾淨。首次data錯誤頁的分頁綁定／清理也被瀏覽器URL政策阻擋，未繞過；成功驗收分頁已關閉、viewport override已reset，失敗臨時分頁由工具回收。
- 本輪自建4399／4400服務均Ctrl+C停止（exit1為主動停止）；沙箱初服務exit-1073741510也是中斷，不當作成功服務驗收。未終止其他程序。
- 對照測試前status，10份原先乾淨的tracked合成fixture於整輪完成後精確還原HEAD；生成結果另存 `generated-fixtures/`，逐檔hash／依據見 `fixture-restoration.json`。既有dirty來源與文件均保留。

最終PCK SHA256：

| 產物 | SHA256 |
| --- | --- |
| 正常候選 `build/web-atm-life-a/index.pck` | `87e8bd0871ff2c09ac88e03827f566b7be1c021005f3d8728c0f1b316a2ed504` |
| 隔離候選 `build/life-report-acceptance/index.pck` | `755420ff74cbbe5ac2a670a8b92b538f2167ecb186ef420394323d51191e72ba` |
| 原凍結 `build/web/index.pck`（保持） | `7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400` |

[正式寬式Web](artifacts/atm-life-a/web-final-1280.jpg)、[短式原生](artifacts/atm-life-a/exhausted-800x360.png)、[故障閱讀](artifacts/atm-life-a/web-final-protection-800.jpg)、[故障來源](artifacts/atm-life-a/web-final-protection-1280.jpg)、[演出結果20](artifacts/atm-life-a/web-final-result-20.jpg)、[重載](artifacts/atm-life-a/web-final-reload.jpg)。截圖實際副檔名依bytes辨識；原生PNG、瀏覽器JPEG，未把JPEG冒作PNG。

本任務沒有未完成的當輪桌面阻擋。下一個大型任務建議 **DECISION-1**（權威抉擇收據與待決流程），由使用者在 **New Chat** 指定；不要在本輪續開。REPORT-1B完整帳目、REPORT-2前世卷冊與事件回聲仍後續。英文checkpoint已置於updata.txt頂部。

結案文件檢查：47份來源／文件／UID／候選hash盤點（42份嚴格UTF-8）、本驗收本地連結全部存在；瀏覽器7項全true、凍結包hash相同。首次diff-check發現新增preset尾端多餘空行，僅修正空白後重跑；最終diff-check exit0。詳見final-manifest.json。
