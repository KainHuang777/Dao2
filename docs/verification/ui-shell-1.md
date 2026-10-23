# UI-SHELL-1：洞府＋煉丹正式接線

2026-10-22。使用者指定本任務；首個工作頁選煉丹，沿用正式 GameSession／AlchemyPanel、既有黑體、紙面、GameTab 與 CloseSeal。沒有新玩法、敘事字型或美術接受聲稱。

## 交付

- `src/presentation/ui_shell_controller.gd` 把 SHELL-0 的 state／policy 接上正式洞府和煉丹。HUD、資源、訊息、工具與相機輸入依目前意圖重算；這兩頁略過舊 HUD／Navigation 的共用顯示覆寫。
- 洞府保留完整 HUD 與三態資源偏好。寬式煉丹使用精簡 HUD＋庫存欄；短式使用靈草摘要與完整庫存抽屜。當頁暫收不被刷新打開，跨 route 清除暫收，返回洞府恢復原偏好。資源 drawer 在洞府亦可操作三態；關閉模式會收起 drawer。
- 晉階／突破保留原按鈕、回呼、即時費用與資格，僅切換唯一可見的共用 host；BUFF／通知沿原元件，壽元沿原值與門檻色，壽盡明示。沒有殼內數值公式。
- 主動訊息閱讀與存檔／Debug 工具遮罩阻擋後方操作，關閉／Escape 留在原 route。閱讀中的目標捷徑先結束閱讀再導航。`show_messages` 是確保開啟，toggle 才切換；resize 不改偏好。短式初建茅屋的自動訊息避讓沿既有規則，作 resolver context，不寫回偏好。
- 覆層同時一個；繪製層級與 sibling 命中順序一併處理。CloseSeal 置於共用紙面承載區。報告／演出／保存保護沿原生命週期觀測；過期工具 token 不可結束新保護，相機不以舊 lock bit 解鎖。直式保留 route 並阻擋玩法。
- 保存失敗有獨立異常列與只保存的重試，煉丹內容為它預留一列；Web 必要保護仍使用原儲存保護。背景保存恢復亦清除殼的失敗狀態，不再次煉製。
- 存檔工具改固定 CloseSeal＋內容內捲；匯出／匯入原功能不變。

`build/web-ui-shell-1` 是正常場景候選；`build/ui-shell-acceptance` 是顯式測試 feature。驗收 fixture 只在獨立 origin 放測試材料、停用自然線上推進及包裝既有 adapter 作拒寫注入；不是自然進度證據。正式 `build/web` 未覆寫，無規則／schema／玩家資料變更。

## 遷移邊界

**本階段只遷移 `home`／`alchemy`。** buildings、outposts、manufacturing、transport、skills、beasts、achievements、reincarnation、realms、sect、fortune、decisions 仍用既有布局；從已遷移頁進出時恢復原按鈕 host 與 z_index。設定選單仍為原 MenuButton；殼接管這兩頁的工具內容與返回，其他頁的工具返回及完整頁矩陣屬 UI-SHELL-2。沒有預先遷移卷末、帳目或新增保存欄位。

## 驗證入口

本機 Godot `4.7.2.stable.official.ed1daf0bf`，所有測試使用專用 `APPDATA=E:/WORK/Dao2/build/ui-shell-1-user` 及 runner 各自的 user:// 目錄。

```powershell
$env:APPDATA='E:/WORK/Dao2/build/ui-shell-1-user'
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/ui_shell_integration_runner.gd --log-file E:/WORK/Dao2/docs/verification/artifacts/ui-shell-1/integration-engine.log
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/ui_shell_integration_runner.gd --log-file E:/WORK/Dao2/docs/verification/artifacts/ui-shell-1/native-delivery-engine.log
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1
python tools/subset_game_fonts.py --check
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web build/web-ui-shell-1/index.html
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release UiShellAcceptance build/ui-shell-acceptance/index.html
node tools/prepare_web_compression.mjs build/web-ui-shell-1
node tools/prepare_web_compression.mjs build/ui-shell-acceptance
python tools/ui_shell_server.py --port 4391
```

## 初輪發現與修正

保留各輪原始 log，不把發出命令視為通過：

1. 初輪整合的 HUD minimum height 碰分頁；共用內距修正後通過。
2. 關閉離線報告後保留舊阻擋 token；導航／工具入口先同步生命週期。
3. 遮罩原只調 sibling、未處理導航 z_index；實際 Web 發現導航畫在遮罩之上及叉號缺底，修正繪製層級與紙面關閉承載。
4. 舊回歸有未結束離線報告便送導航、演出未結束便開頁，以及直式結尾期待 world unlock；改成明確完成報告／演出、轉回橫式後驗，或驗新的旋轉阻擋。收益／扣款／保存斷言保留。相機返回檢查改依當前殼狀態，不沿任意舊 lock bit。
5. `show_messages` 曾誤用 toggle；重複 show 改為保持開啟。
6. Web 背景恢復成功仍殘留失敗標記；由正式背景結算成功路徑清除，異常列另預留空間。
7. 初次 Edge 入口未提供；改用可用 IAB。初次本機 sandbox server 連線逾時，授權啟動工作區 server 後 HTTP 200，重建分頁成功；未改防火牆或瀏覽器安全設定。
8. 全量曾 exit0 卻含宗門 Runner 的 `Claim should succeed` 斷言：手工 fixture 沒有稀有任務可能獎勵的 black_copper。只補 fixture 的 canonical 空庫存，不改宗門／RNG；專項及最終全量重跑均無 SCRIPT ERROR。沒有把該次 exit0 當完全通過。
9. 額外 PowerShell HTTP 診斷因自動審核額度限制未執行，並非安全判定；改用既有瀏覽器核對。4392 初次讀到舊原型快取，帶 `?shell1=final` 後確認正式 Godot 空白檔報告／洞府入口，不把原型當正式證據。瀏覽器工具另有一則未標 URL 的 MutationObserver observe 錯誤，保留診斷、不宣稱 console 零錯誤。

import exit0 仍含既有 `early-v1-c/final-reload.png` 的 JPEG 誤名 PNG 診斷；沒有修改該歷史圖。原生／部分回歸仍有既有 Font RID／CanvasItem／ObjectDB 退出診斷，故障案例有預期 JSON／拒寫錯誤。初次驗收包缺 BGM companions 的警告在補齊四首音檔後重載；不是零診斷聲稱。

## 最終結果

**DONE（洞府＋煉丹，桌面／Web有界）**。

- 最終原生整合 **90 checks／failures=[]／exit0**，三尺寸共18圖；政策 **263 checks／failures=[]／exit0**；HUD 壽元／資格 **58 checks／failed=false／exit0**。涵蓋三態偏好、跨頁與resize、暫收、覆層替換／輸入阻擋、工具返回、真實煉製與拒寫重試／隔離落盤重讀及過期token。
- 最終固定入口 **84／84 Runner、exit0、SCRIPT ERROR 0**，見 [全量日誌](artifacts/ui-shell-1/full-runners-verified.log)。最後全量在全部正式來源與 fixture 修正後執行；不以此前失敗分段或較早狀態代替。[結果摘要](artifacts/ui-shell-1/results.json)、[原生日誌](artifacts/ui-shell-1/native-delivery.log)、[政策日誌](artifacts/ui-shell-1/ui_shell_policy-delivery.log)。
- 字型 `--check`、正常／隔離 Web export、兩包 compression／四首 BGM companions 均成功。正常候選 PCK SHA256 `7e24028eb695fd4e…`；凍結 `build/web` 仍 `7e7e619dcaa28fb0…`，未覆寫。[12份來源與三包hash](artifacts/ui-shell-1/source-hashes.json)。
- 真實 IAB 桌面滑鼠：1280×720、844×390、800×360 CSS（DPR約1）開關／跨頁／resize、訊息遮罩擋後方煉製、庫存抽屜Escape、工具留原頁均已驗。844×390沿原scale adapter約為779×360 Godot邏輯尺寸，不把兩者混稱。
- 保存拒寫→必要保護／Escape不能繞過→仍拒寫重試→恢復寫入／保存→回原煉丹→重載：首例靈草100→90／丹藥0→1；最終包另例90→80／1→2，恢復與重載仍80／2，`save_failed=false`，不重扣／不重發。洞府完整模式2跨頁及resize保留；重載呈現意圖按原規則重建。正常候選另在獨立4392空白新檔檢查正式報告、洞府與工作頁入口。[瀏覽器觀察](artifacts/ui-shell-1/browser-observations.json)。
- 結案檢查37檔嚴格UTF-8、報告10連結、15來源／建置hash通過，diff-check exit0；全量再生的10份原先乾淨fixture已按HEAD bytes還原，記錄於 [還原清單](artifacts/ui-shell-1/fixture-restore.json)。移除本輪再生的兩份歷史誤名圖片.import sidecar，未改原圖。兩個本輪server以Ctrl+C停止（程序exit1為主動停止）；還原瀏覽器viewport並關閉正式／驗收頁，初次逾時錯誤頁由工具於本輪結束自動清理。保留任務開始前既有dirty成果，未commit／push。

本輪沒有新FPS或冷啟動效能數字，沒有新增觸控／實機證據。範圍依既定延期政策，不擴大為完整頁矩陣、美術接受或自然前期進度通過。下一任務為新對話的 UI-SHELL-2；本輪不展開它。

## 圖片索引

原生三橫式：每尺寸有 `alchemy-inventory`、`resources`、`messages`、`save-tool`、`alchemy`、`home`，共18張。截圖來自真實 Godot 渲染，不是 HTML 樣張。

- [寬式煉丹](artifacts/ui-shell-1/alchemy-inventory-1280x720.png)
- [800 庫存抽屜](artifacts/ui-shell-1/resources-800x360.png)
- [800 工具](artifacts/ui-shell-1/save-tool-800x360.png)

瀏覽器截圖由本輪 CUA 工具回傳於對話；未把原生圖當 Web 截圖。獨立 harness 的可見 output 是診斷輔助，保存保護時 SceneTree 暫停會停止刷新，不能將停在舊值的 output 當保護未成立。
