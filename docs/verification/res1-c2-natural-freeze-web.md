# RES1-C2｜自然背景凍結／切分頁恢復 真實瀏覽器驗收

2026-10-13（Asia/Taipei）。針對 [res1-c2-closure.md](res1-c2-closure.md) 尾段所列程式可驗剩餘項「自然 OS 凍結／切分頁恢復」做真實瀏覽器證據收集；本輪為純驗證（test-only evidence pass），**沒有修改任何 src 來源、規則、schema、存檔結構或匯出物**。使用 build/web 既有匯出（閉式路徑定稿後版本），未重匯出。

## 方法

隔離 origin `http://127.0.0.1:4199`（正常 build，`--review-fixture` 種入 res1-c2-review-fixture.json 三島狀態）。以 CDP 驅動真實有頭 Edge 155 guest視窗（非 headless、非模擬 visibility 事件）：

1. 啟動另一空白分頁並以瀏覽器層 `Target.activateTarget` 聚焦，讓遊戲分頁**自然**失去焦點與可視性（rAF 停擺，等同使用者切分頁／最小化）；以 `document.visibilityState==='hidden'` 在遊戲頁確認。
2. 隱藏期間只讀輪詢存檔 revision／cursor，確認無狀態推進。
3. `Target.activateTarget` 聚焦回遊戲分頁，確認 `visible`，輪詢至存檔 revision＋cursor 前進（自然恢復），再做 8 秒穩定檢查確認沒有雙重結算。
4. 依 CDP `Runtime.consoleAPICalled` 擷取遊戲輸出，以 `OFFLINE_SETTLEMENT_*` 與 `WEB_BACKGROUND_SETTLED:`／`WEB_BACKGROUND_SAVE_FAILED:`（src/abode/living_abode.gd 1647/1660 行）為成功／失敗標記。

命令（從專案根目錄）：

```powershell
python tools/island_preview_server.py --port 4199 --normal-build --review-fixture
node --experimental-websocket docs/verification/artifacts/res1c2-natural-freeze-runner.js
```

- Runner 腳本存檔：[res1c2-natural-freeze-runner.js](artifacts/res1c2-natural-freeze-runner.js)（工作副本位於 Temp/opencode/freeze_web_verify_runner.js；node 20 需 `--experimental-websocket`）。
- Edge guest：`msedge.exe --guest --user-data-dir=<Temp>/edge_guest_freeze --remote-debugging-port=9225 --window-size=1280,760`（Edg/155.0.4283.45；測後已全部停止）。

## 結果：兩輪獨立重跑、兩個凍結週期全 PASS

兩次完整執行（間隔約 4 分鐘）結果一致，第二輪為留有完整 console 擷取之正式證據。每輪依序做 120 秒與 45 秒兩段凍結。

| 週期 | 實際隱藏時長 | 聚焦後恢復耗時 | cursor 前進量 | 前進−隱藏差值 |
| --- | ---: | ---: | ---: | ---: |
| Run2 freeze1 | 120245ms | 5051ms | 138635ms | +18.4s |
| Run2 freeze2 | 45075ms | 5071ms | 63103ms | +18.0s |
| Run1 freeze1／2 | （數值在 ±1s 內） | 同上 | 同上 | 同上 |

- 差值 +18s 來自「結算落盤以恢復後的 now 為準」的 catch-up 語意（含聚焦後落盤延遲），與 `settle_state_async(cursor → now)` 設計一致；非重複結算。
- Console 證據：啟動時 `OFFLINE_SETTLEMENT_BEGIN/END ok=true`（fixture 老化結算）；**每個凍結週期恰好一次** `WEB_BACKGROUND_SETTLED:`（freeze1：`age_seconds=132, away_ms=123442, effective_ticks=123, cap_applied=false, forfeited_ms=0, rollback=false`；freeze2：`age_seconds=195, away_ms=48249, effective_ticks=48`）；**全程零** `WEB_BACKGROUND_SAVE_FAILED`。
- 恢復期間 revision 跳升（1→11→17）為計時批次提交次數，非額外結算；復原後 8 秒 idle 檢查 revision 穩定，無雙重結算攪動。

## 證據與限制

- 原始事件流：[res1c2-freeze-2026-10-13.jsonl](artifacts/res1c2-freeze-2026-10-13.jsonl)（30 事件：origincleared、fixtureseeded revision=1327、ready、baseline、hiddenentered、refocused、recoverycheck、recoveryadvance、idleafterrestore、consolediagnostic、done；console 行嵌於 consolediagnostic）。第一輪故意覆寫，證據以第二輪（含完整 console）為準。
- 隱藏期間 rAF 停擺屬瀏覽器自然行為；恢復走 `NOTIFICATION_APPLICATION_FOCUS_IN`／`_process` step_delta 偵測 → `_settle_web_background` 路徑（living_abode.gd 742-1642），本輪未改任何遊戲端代碼。
- 限制：僅桌面 Edge 155 guest、DPR 1.25、滑鼠載具；**跨瀏覽器（Firefox／Safari／Chrome 獨立驗證）、實體裝置觸控／高 DPR、使用者美術／節奏核可、正式 manifest 放行仍待驗**，不因本輪提升。OS 級凍結（系統休眠）屬 OS 時鐘語意，另一待辦。
- 伺服器（port 4199）於測後保留存活，供美術／節奏人工檢視入口 http://127.0.0.1:4199/launcher 使用（見 updata checkpoint：人工檢視前應先清空該隔離 origin 或改用自有 profile）。
