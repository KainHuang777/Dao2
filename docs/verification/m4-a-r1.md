# M4-A-R1 正式系統整合驗收

2026-10-03 · **DONE（本任務 Session／桌面 Web 範圍）**。實體手機、高 DPR、完整 M1-C/D 儲存故障矩陣仍為獨立待驗項。

相依：既有 GameSession、CommandProcessor、SaveCodec／SaveSlots、正式洞府及四入口導覽已存在。引擎實測 `4.7.2.stable.official.ed1daf0bf`，Windows、Compatibility、單執行緒 Web；未更新引擎或模板。

## 修正與交付

- `game_session.gd`、`game_state.gd`、`save_codec.gd`：成功命令收據與結果狀態一起保存，最多最近 256 筆；重送不改 revision／庫存／效果，也不重播 events。保存後 JSON key 排序不影響淘汰順序，按成功 revision 淘汰。結果使用深複製。schema 2 採新增選填欄位 `command_receipts`，缺欄預設空，驗證型別、筆數及 revision；`rules_version=core-flow-5-session-receipts`。
- `sect_system.gd`、`realm_system.gd`：拒絕命令不因檢查費用／資格而初始化宗門或洞天。宗門獎勵、坊市靈草改為正式 `spirit_grass_low`，玄銅使用 `black_copper`；坊市靈晶寫入 `realms_data.realm_spirit.spirit_crystal`。保存中的旧任務 `herb`／`bronze` 在領取時映射至正式庫存，未知獎勵資源在任何發獎前拒絕。
- `command_processor.gd`：領取任務標記 BUFF 變更，坊市標記界域庫存變更。
- `sect_panel.gd`、`realm_teleport_modal.gd`：修正每幀重建可操作按鈕造成滑鼠 press/release 失效。資料簽名未變時保留節點，資料改變但按鈕仍按住時延後重建；宗門呈現不再初始化核心狀態。
- 新增 `tests/m4a_session_integration_runner.gd`（251 checks）並加入固定入口；補宗門／洞天 UI 節點保留回歸。小景全快照比較改用既有 checksum 的 JSON 數值正規化：JSON 的 int／float 表示不同不視為進度不同，仍比較全部欄位。
- 新增 `tools/m4a_web_fixture.gd`、`tools/m4a_web_server.py`：隔離 origin 4186 的測試工具，正式 release HTML 未修改。fixture 明示築基、短程 30 秒任務與測試資源，無正式起點／節奏承諾；setup 遇到已存進度即拒絕覆寫。

## Session 矩陣

全部經 `GameSession.submit`，成功驗證 revision +1、同 ID 原命令重送、保存解碼後重送、中立 stale revision；拒絕同命令重試兩次並比較完整快照。

| 命令 | 成功／拒絕涵蓋 |
| --- | --- |
| join_sect | 加入；未解鎖、已加入 |
| refresh_sect_tasks | 刷新；未解鎖、冷卻 |
| start_sect_expedition | 派遣；缺 task ID、未知任務、已有派遣 |
| claim_sect_expedition | 領取且只加一次獎勵；未解鎖、未完成、無任務、未知獎勵資源 |
| learn_sect_technique | 功法升級並扣木材／貢獻；缺 ID、未知功法、缺貢獻／木材、最高級 |
| buy_sect_market_item | 靈草／丹藥／靈晶入正確庫存；缺 ID、未知物品、缺貢獻、購買上限 |
| switch_realm | 進靈界；未解鎖、未知界域 |
| upgrade_realm_outpost | 三據點各成功；未解鎖、未知 ID、缺人界物料／靈晶、最高級 |
| apply_buff／remove_buff | 施加及移除、持續時間與倍率；空 ID |

保存補證：未完成派遣 elapsed 恢復、不誤通知；完成派遣重載會通知；領取後重載不再通知；BUFF 效果／剩餘時間及洞天等級／資產恢復。MemoryStorage 故障注入驗證保存失敗返回、同命令重試不扣第二次、再保存與槽位載入、最新槽損壞回復舊世代。另驗證旧 schema-2 缺收據可載入、壞收據拒絕及 256 筆窗口跨重載淘汰。

## 命令與結果

| 命令 | 結果／日誌 |
| --- | --- |
| Godot `--version` | exit 0，上述 4.7.2 |
| Godot `--headless --path . --import` | exit 0；`artifacts/m4a-r1-import.log` |
| Godot `--headless --path . --script res://tests/m4a_session_integration_runner.gd` | 最終 251 checks、0 failures、exit 0；`artifacts/m4a-r1-final-m4a_session_integration_runner.log` |
| PowerShell `-NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1` | 40/40 PASS、exit 0；`artifacts/m4a-r1-all-runners-verified.log` |
| 最後旧任務 alias 修正後四項相關 Runner | sect／sect_ui／session_integration／realm 皆 exit 0；`artifacts/m4a-r1-final-*.log` |
| Godot `--headless --path . --export-release Web .\build\web\index.html` | exit 0；`artifacts/m4a-r1-export-final.log` |
| Godot `--headless --path . --script res://tools/m4a_web_fixture.gd` | exit 0；`artifacts/m4a-r1-fixture.log` |
| Python `tools/m4a_web_server.py` | 4186 loopback 啟動並實際提供 setup／release；完成後停止本輪服務 |

初次全量在沙箱因 Godot 無法寫隔離 user:// 探針而 exit 1，正常授權重跑。第一輪去重回歸另揭露 int／float 全快照斷言差異，已用既有 JSON canonical checksum 核對。歷史失敗日誌保留。故障注入預期 JSON Parse error、退出 Font RID／CanvasItem／ObjectDB 診斷與沙箱下 root certificate／log 寫入訊息不能稱為零錯誤。

## 真實瀏覽器操作

Codex IAB、滑鼠、同一 `http://127.0.0.1:4186` origin；1280×720 及 844×390 CSS px，DPR 約 1。短橫向 DOM 實測 canvas 843×389 CSS px（Godot shell 一像素取整）；正式畫面滿足捲動與返回契約。先在 `/r1-setup` 點「載入隔離測試檔」，再由連結進入正式 `index.html`。未寫入 4175 玩家 origin。

| 操作與觀察 | 截圖（artifacts/） |
| --- | --- |
| 點「湧」：天靈氣湧名稱、+30% 全產率／+50% 靈氣、剩餘時間；外側點擊關閉 | m4a-r1-buff-tip.jpg |
| 遊歷→宗門，派遣實際提交，顯示 0%／30 秒；修正前點擊無效已重現 | m4a-r1-expedition-start.jpg |
| 經營→洞天→跨界；天樞陣眼 0→1，金錢 200→100、下品石 100→50，後續受供給消耗 | m4a-r1-realm-upgrade.jpg |
| 時間自然推進後「宗」出現；尚未領獎 | m4a-r1-completion-notice.jpg |
| 重整、關閉離線摘要，「宗」及既有 BUFF 恢復；點「宗」跳至唯一宗門頁且貢獻仍 1000 | m4a-r1-notice-reloaded.jpg |
| 點領獎：貢獻 1000→1080、領獎卡移除；返回 HUD「宗」消失、出現「悟」 | m4a-r1-claim.jpg、m4a-r1-claimed-hud.jpg |
| 頓悟 TIP：修煉速度 +100%、剩餘時間。自然到期後消失 | m4a-r1-reward-buff.jpg |
| 神農功法 0→1、貢獻 1080→1030；再點缺木材被拒絕，仍 1 級／1030；返回 HUD 可讀 INSUFFICIENT_WOOD | m4a-r1-technique-rejected.jpg、m4a-r1-claimed-hud.jpg |
| 坊市買靈草，購入次數 0→1、貢獻 1030→1000 | m4a-r1-market.jpg |
| 再重整：已領任務不復活；短橫向宗門貢獻 1000、無活躍任務 | m4a-r1-short-sect-reloaded.jpg |
| 短橫向「壽」TIP 可點／可關、效果 +10 祀／常駐 | m4a-r1-short-buff-tip.jpg |
| 短橫向洞天恢復靈界；內容區真實捲動後天樞陣眼仍 1/10、材料不足；固定導航可返回 | m4a-r1-short-realm-reloaded.jpg |

IAB console warn/error 為空，保存 `artifacts/m4a-r1-browser-errors.json`。UI 畫面與 CLI 是不同證據：同 command_id 冪等、精確入庫與保存故障由 Session runner 證明；Web 以真實按鈕／重整／畫面觀察證明命中與恢復。滿倉資源受既有時間推進 clamp，Web 不以滿倉讀數證明每份獎勵的即時 Amount 增量。

最後相容修正重新匯出後另重整抽驗：常駐龜息 TIP 仍有 +10 祀、到期的暫時 BUFF 與已領宗門通知保持消失，見 `artifacts/m4a-r1-final-reload-tip.jpg`。HTTP 啟動時另有 `/favicon.ico` 404，release 資產皆成功提供；此非空 HTTP 診斷不能與空 console 日誌混稱。測試頁關閉、viewport override 復原，Python 服務以 Ctrl+C 結束（中斷退出碼 1，非啟動失敗）。

## 邊界與下一步

- 收據窗口只保證最近 256 筆成功命令；旧檔缺收據無法重建歷史去重紀錄。保存失敗後重載回到最後有效快照；未成功提交的新操作和收據一同回退，不能承諾未保存操作仍保留。
- Web 實際 adapter 是 **localStorage**，本輪證明同 origin 重整恢復，沒有宣稱 IndexedDB transaction、quota、拒絕儲存、多分頁單一寫入者或完整 M1-C/D DoD。
- 桌面兩版型滑鼠已驗；未持有實體手機，不推定觸控、高 DPR、GPU／效能、美術或整體 NAV1／UI8 放行。
- 下一大型任務：M1-C/D Web 持久化權威契約、離線及故障／重試矩陣；請開 New Chat。宗門任務生成仍有既存全域 `randi()` 用法，確定性 RNG 是另項契約缺口，本輪不擴張為全規則 determinism 放行。
