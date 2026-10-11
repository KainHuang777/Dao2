# EARLY-FLOW1-D 自然流程與節奏 — 2026-10-10

**同一隔離 Web 進度 F7→G4 自然時間／桌面操作有界驗收 PASS；EARLY-FLOW1-D 仍 IN_PROGRESS。** 使用者決定「先保留基線，試玩後判定」，人類節奏接受、實體觸控／高 DPR 待驗；不提升完整 EARLY-FLOW1 或原 UI1-C／C／D。

## 方法與起點

- 正式 Godot 4.7.2／正常 Web 匯出；CUA IAB、localhost **48214**。以真實滑鼠操作、正常自動生產與實際牆鐘等待推進，不加速模擬、不贈料、不服丹、不學技能／入宗門。玩家 4175 origin 未碰。
- 起點是上一輪正常命令取得的 `early-flow1d-foundation.json`：築基一層、雙島 F1–F4 已完成、聚靈壇一階。此前練氣與雙島的時間是 CLI 模擬／上一輪證據，不計為本輪新檔自然通關。
- 舊 fixture 保存時間已過期。48213 初次載入結算 8672 秒离線，不能當本輪起點，該服務已停止，進度未重用。新增 `tools/early_flow1d_natural_fixture.gd`／UID，用正式 SaveCodec decode/encode 只更新保存／結算 UTC，驗證完整 `GameState.to_snapshot_dict()` 一致，再輸出 `early-flow1d-natural-foundation.json`；未更改原 fixture 的遊戲狀態。後續既有 runner 會重生 checkpoint UTC，詳見下方。新 origin 48214 只 seed 一次，後續真正重載一律 Play。
- 副本 UTC=1791617036445（2026-10-10 07:23:56.445 UTC），實際開啟前約 27 秒自然離線；此正常間隔包含在本輪牆鐘經過，並非模擬加速。精確後续觀測時間在 [timeline](artifacts/early-flow1d-natural/timeline.json)，HUD 秒數／壽元為當下畫面，不冒稱逐幀 stopwatch。
- launcher DOM 已核對 iframe 844×390、DPR≈1；桌面 1280×720 與短橫式切換真實操作。不是實體觸控或高 DPR 證據。

## 已觀測

### 自然流程揭露的突破阻擋（已修）

同一進度真正到築基十層後，HUD 顯示可突破、F7 顯示突破至金丹，但主按鈕被 `cur_era == 1` 硬門檻隱藏；修行分頁沒有替代正式突破入口。先前由金丹 checkpoint 起跑的 Web 子段無法覆蓋這一步。本輪不以直接呼叫函式跳過：GameSession 的唯讀 View 增加 `breakthrough_target_name`，只在已有下一境界時提供名稱；HUD 依本境圓滿／實際名稱顯示主按鈕，disabled 仍讀 `can_breakthrough`，文案顯示真正下一境界。規則／成本／保存 schema 不變。

`early_flow1d_runner.gd` 捕捉正常命令取得的築基十層，新增三橫式可見／資格／44px與畫布邊界及真正 Button 信號送命令、G1交接檢查，專項 **132 checks、exit0**。相關 R2 HUD52／B110／responsive／M2-B突破回歸通過。responsive 初次失敗是強制显示合成按鈕時 `_process` 在下一幀依新檔資格收起按鈕，造成檢查隱藏物件；只在該人工幾何區段關閉 process，結束後恢復，不刪斷言。真正築基資格／命令由新增D測試和實際Web驗證覆蓋。

修正後同一origin重新載入新包，保留原十層，真實滑鼠「突破至金丹期」→演出→功成出關，確認金丹一層與「進度已保存」，G1主目標改開拓丹霞。修復期間約數分鐘另列診斷時間，不充當正常玩法等待。此樣本有呈現層修正／重新匯出，但沒有重設遊戲狀態、加速或贈料；不宣稱 final PCK 從初始築基一層整段未換版重跑。

最終突破修正版 PCK **8828C81712F7516494D0C1F5DD8A3476C6739C959A5588EE720CF98572712EE3**；export／compression exit0。此前74031…只修年歲標示，R2原包與各中間包均為本輪歷史。D／B runner會重新生成其正常命令 checkpoint 檔／UTC，起始 `early-flow1d-natural-foundation.json` 保留不變，且不重新seed測試進度；起始hash見本輪hashes.txt。

- 支線未做可直行 F7；聚靈壇 1→2、築基靈池 0→1→2 正常支付。F7 說明確認容量 **2300／2000**，升境不需滿倉或金丹道具；錢莊一階、靈石庫一階在修煉等待期間建成，為金丹首升級準備金錢與下品石庫容。
- 築基晉階以真實按鈕付靈力200；三層 173 秒、四層207秒、五層249秒的滿條畫面後實際支付，此為當時六層觀測（需求299秒），後續已正常付至十層。截圖與時間點在 [artifacts](artifacts/early-flow1d-natural)。此為無丹藥的基線樣本，不能用 CLI 通關時長冒充。
- 真正重載保留築基四層及後續五層的建設、庫存與修煉，17／12 秒正常離線结算，未再次 seed。
- 短橫式營造詳情需內捲至升級操作；桌面 F7 掛軸／說明可讀容量與修煉等待。短橫式主掛軸依既有策略暫收，後續需連同使用者試玩觀察介紹入口可發現性。
- 真實金丹開拓丹霞後，主目標定位丹液詳細配方；地方草5＋全域靈力50正常支付、10秒單批完工，主目標轉至 `liquid_home`。來源丹液1／祖島0、載貨1與倒數已觀測，實際到貨才改 G2。
- G2主目標定位祖島中品靈石；金丹修煉240/240時材料未足仍不能晉階。指定50批、10秒／批串行工作已開始，材料逐批支付、產物逐顆增加。CUA `typeText("50")` 初次只顯示5，未開始工作；以實際0鍵補足後確認50，再提交，不能把部分輸入當成功。

## 本輪修正與 CLI

發現離線摘要「年歲變化」讀取的是結算後累計 `age_seconds`，容易把重載12秒誤讀為老化31.4年。將 `src/presentation/offline_summary.gd` 改為「目前年歲」，並調整 `tests/m1d_offline_runner.gd` 現有語意斷言。沒有改報告 schema、時間、收益、壽元、成本或保存規則。新 Web 真正重載已显示「目前年歲：31.4 年」。

- 本地 Godot --version：`4.7.2.stable.official.ed1daf0bf`，exit0；測試進程 APPDATA=`build/early-flow1d-natural-user`。
- `--headless --path . --script res://tools/early_flow1d_natural_fixture.gd`：完整狀態一致的時間重封裝，exit0。
- `--headless --path . --script res://tests/m1d_offline_runner.gd`：離線結算、24h上限、游標提交與不重複發放 PASS，exit0。
- `--headless --path . --script res://tests/uix_r2_hud_runner.gd`：52 checks、0 failures、exit0；既有 RID／CanvasItem／ObjectDB 退出診斷保留。
- bundled Python `tools/subset_game_fonts.py --check` 首次因目前來源缺3字失敗（exit1），重建1831 codepoints後 final --check exit0；原字型未改。
- `--headless --path . --editor --import --quit`：exit0，但首次本輪 screenshot API 的 JPEG bytes 誤存 `.png` 造成匯入診斷；已只將本輪檔案改正為 `.jpg`，移除本輪新產生舊名 import sidecars，再 import exit0、此目錄成功。此前 UIX PNG 匯入 ERROR 保留，不宣稱日誌零錯誤。
- 正常 Web `--export-release Web build/web/index.html` 與 bundled Node `tools/prepare_web_compression.mjs build/web`：exit0。文案修正後 PCK SHA256 **74031FCC7DF17D3517C08B58FCB085DD33B5EA952D8F6DB665FF3EED75921937**；本輪早段先使用 R2 原包，之後相同 origin 重載新包，規則不變。Windows未更新。
- [命令日誌、hash、字型檢查](artifacts/early-flow1d-natural)。沒有新全量61／FPS／quota／IndexedDB故障矩陣聲明。

服務：bundled Python `tools/island_preview_server.py --port 48214 --normal-build --gzip --fixture early-flow1d-natural-foundation.json`。沙箱服務第一次 48213 瀏覽器連線超時，停止後正常授權 localhost 啟動成功；沒有 auto-review 拒絕。重開48214時只按「開啟隔離遊戲」，不覆寫既有自然進度。

## 最終自然流程與節奏結果

| 區段 | 實際觀測與限制 |
| --- | --- |
| 起始築基一層／F7→付至十層 | 約41分20秒，含操作與取樣、已有初始修煉進度；十層觀測剩餘壽元140／200。無丹藥、技能、宗門樣本 |
| 築基→金丹 | 實際發現主按鈕缺失，修復／測試／換包約7分鐘屬診斷時間；同一進度正常突破，G1交接成功 |
| G1 丹液 | 丹霞單批10秒完工，開啟一級回運；看到載貨1倒數，真正到貨後才顯示G2 |
| G2 中品石50／陣芯1 | 中品石規則500秒串行；開工至看到陣芯目標約9分18秒，含操作與107秒真實重載離線。50顆全數完工，木材2／青銅2正常製成陣芯1（20秒） |
| G3 金丹首升級 | 240／240秒且五項材料足夠後，真實滑鼠支付→金丹二層；支付前壽元656／740 |
| G4 靈狐首次餵養 | 結契後成長0→支付靈草50→成長50、冷卻286秒、按鈕禁用；沒有第二次餵養，也不需等孵化才繼續修行 |
| 最終真正重載 | 同一origin Play、96秒自然離線，金丹二層／成長50保留；800×360文字與操作可讀，冷卻自然歸零。最終回洞府時壽元649／740 |

起點 UTC 至觀測首次餵養完成共4138.989秒（約69分鐘），包含修復、診斷、頁面檢查、換包與重載，**不能當乾淨玩家通關預算**。本輪只證明既有基線可走通且壽元有餘裕，不代替使用者的等待接受。使用者回覆：**「先保留基線，試玩後判定」**。維持所有成本、工時與修煉規則；50顆串行等待列入後續試玩關注項。

[最終重載成長50截圖](artifacts/early-flow1d-natural/final-reload-feed50-800.jpg)、[完整時間線](artifacts/early-flow1d-natural/timeline.json)、[相對時間表](artifacts/early-flow1d-natural/timing-summary.json)。最終此tab的error／warn查詢為空（limit20），見[console紀錄](artifacts/early-flow1d-natural/final-console.json)；不推論所有退出日誌無診斷或全裝置通過。

## 本輪檔案與收尾

- 正式來源：`src/application/game_session.gd`、`src/presentation/abode_hud_controller.gd`、`src/presentation/offline_summary.gd`。
- 測試／工具：`tests/early_flow1d_runner.gd`、`tests/m1d_offline_runner.gd`、`tests/m2d_responsive_ui_runner.gd`、新增 `tools/early_flow1d_natural_fixture.gd`／UID。更新兩個runtime子集字型與manifest、新自然起點fixture與本輪證據；既有D／B測試重生其checkpoint時間。
- 最後來源後的驗證：D132、R2 HUD52、B110、responsive、M2-B突破均exit0；離線標示專項exit0。font check1831、Web export／compression exit0，最終包hash以上方8828…為準。沒有重跑全61、效能或保存故障矩陣；Windows未匯出、未commit／push。
- 更新 README、ROADMAP、docs17、原D驗收、development-status、ai-handoff、updata。保留歷史結果和開工既有dirty。
- 本輪48214服務已以Ctrl+C停止（刻意中止exit1）、臨時分頁關閉、viewport reset；4175玩家進度未操作。

依 Context Guard，本階段停止並交接。**下一 New Chat：使用者試玩後判定等待節奏，補實體觸控／高 DPR 驗收。** R2有界DONE保持；D完整DoD尚未滿足，不開UIX-R3或Era4–12，不重做B／C自然接入、已過保存／FPS或暫緩冷啟動。
