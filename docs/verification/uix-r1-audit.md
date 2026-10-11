# UIX-R1 接手稽核 — 2026-10-10

結論：元件與測試已交付，但 R1 不宜按完整 DONE 放行 R2。先補 R1 收尾；本輪僅稽核與交接，不修改 Sonnet 的正式來源、不開始 R2。

## 範圍與證據

使用者要求確認 Sonnet 的 UIX-R1 是否完成及可否推進。讀取 README、ROADMAP、ai-handoff、development-status、technical-architecture、responsive-ui-web-spec、updata 及來源／Git 工作區。工作區已有 Git，包含前期流程與 UIX 混合未提交變更；未 reset、commit 或 push。在 Roadmap／正式文件找不到 UIX 計畫與 R1/R2 DoD，只有 updata 聲稱 R1 DONE、下一 R2 Main HUD layout modernization；不可把此稽核自行當成原設計核定。

已建立 FeatureUnlocks 與六個元件（DockButton、ResourceChip、SegmentChips、GameTab、CloseSeal、DaoSeal），DaoSeal／ResourceChip 已接 HUD。FeatureUnlocks 尚無正式呼叫點，其餘元件多為待接入工具。這些成果應保留。

## 放行前缺口

1. **功能 ID 不一致**：feature_navigation.gd 正式 ID 是 `skills/beasts/realms/decisions`；feature_unlocks.gd 使用 `skill/beast/nine_realms/realm_decision`。探針以正式 ID 查 era1 全得到 AVAILABLE（state=2），原 57 項測試使用同一組錯誤 ID 因而未抓到。先對齊正式導覽及實際 View／規則門檻，再補契約；勿把 UI 顯示條件當規則授權。
2. **晉階／突破新容器未定位**：abode_hud_controller.gd 把按鈕移到 `_main_action_box`，但定位條件為 `"main_action_box" in _abode`，該屬性不存在。探針實測 844×390 時容器 position=(0,0)。條件內的 toolbar 寬度修正還會被緊接的 size 指派覆寫。需要補各橫式版型下可見、可點、避讓／旋轉／演出遮罩驗證。
3. **舊驗收被弱化**：m2d_responsive_ui_runner 註解了洞府訊息置中、resource ribbon 邊界、資源模式 2→0→1 的真實訊號操作，並移除訊息與資源避讓檢查。當前 PASS 不再代表原有完整契約。需恢復仍適用檢查；若 R2 正式替換舊資源布局，提供等價新元件測試與文件規格。
4. **CloseSeal 命中區**：元件只有 32×32 的 minimum，Runner 也固定期待 32×32；沒有獨立 44px 命中包覆證據。接入前需確保實際 CSS 點擊區符合規格。
5. **正式交接缺失**：UIX R1/R2 範圍、相依與 DoD 未入 Roadmap；沒有新版 HUD 的 Web 匯出／真實滑鼠三橫式證據。EARLY-FLOW1-D 的自然流程／人工／裝置待驗不能由 UIX Runner 清除。

## 本輪命令

- 固定引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：4.7.2.stable.official.ed1daf0bf，exit0。
- 初次 `tools/run_all_runners.ps1`：exit1，首個 runner 因沙箱不可寫預設 user:// 而無法建立 web_probe fixture；見 artifacts/uix-r1-audit/runners.log，這不是來源功能失敗。
- 以進程級 APPDATA 指向專案 `build/uix-r1-audit-user` 重跑全量：**未全通過**，在 `tests/bgm_era_playlist_runner.gd:75` 斷言失敗（Reincarnation reset to Era 1 should switch invalid track 3 to track 0），之後 runner 未自行退出，以 Ctrl+C 中止／exit1，剩餘 Runner 未由全量完成。隔離資料不覆寫玩家進度，結果見 runners-isolated.log。這不是 UIX 因果歸屬證據，但本輪不能重現歷史 60/60 聲明；後續需定位此斷言／fixture並重跑，不能默默跳過。
- 隔離 `--headless --path . --script res://tests/uix_r1_components_runner.gd`：57 checks／0 failures／exit0，components.log。
- 隔離 `--headless --path . --script res://tests/m2d_responsive_ui_runner.gd`：PASS／exit0，responsive.log；仍有 Font RID／CanvasItem／ObjectDB 退出診斷。
- 隔離 `--headless --path . --script res://docs/verification/artifacts/uix-r1-audit/behavior_probe.gd`：exit0，behavior-probe.log，證明正式 ID fallback、容器 position 和 32px minimum。DockButton 與 GameTab 的自動 toggle 樣式有變化，此處沒有缺陷。首次探針錯把 GameTab 的 StyleBoxTexture 當 Flat 讀 bg_color，錯誤後以 Ctrl+C 中止／exit1，修正探針重跑；未改正式來源。探針亦有退出資源診斷。

未在本輪執行 Web 匯出／瀏覽器、觸控／高 DPR 或 FPS 量測，不宣稱通過。冷啟動暫緩不作本次阻擋。

`git diff --check -- docs/development-status.md updata.txt`：exit0（換行正規化提示保留）。

下一有界任務：**UIX-R1 收尾修正＋等價驗收**。先核定既有 UIX 設計範圍、修 ID／新容器定位、補關閉命中與新版布局測試、隔離 Web 三橫式實際晉階／突破／設定與返回；通過後再 UIX-R2。依 Context Guard，大型實作請用 New Chat 接續此頁。
