# UIX-R1 收尾 — 2026-10-10

**DONE（元件／接入修正／CLI／桌面Web三橫式有界範圍），可推進 UIX-R2。** 人工最終美術、實體觸控／高DPR、EARLY-FLOW1-D整段自然流程與原C/D門檻獨立保留，不由本頁提升。

## 修正

- `feature_unlocks.gd`：正式 `skills/beasts/decisions/realms` IDs；加入alchemy／achievements，未知ID隱藏；library讀正式View的level字典。保留呈現helper，尚未套用導覽隐藏政策，核心命令繼續自己驗資格。
- `components/close_seal.gd`：最小可點區44×44；DockButton紅點與DaoSeal裝飾忽略滑鼠；ResourceChip未知資源清空舊圖示。
- `abode_hud_controller.gd`：主操作用右下錨點，從可見按鈕計算尺寸；主頁之外及離線摘要／存檔／Debug暫收。資源籤／設定右上錨點。只在offset變更時更新，避免每0.25秒重設錨點造成reflow；纸底訊息改深墨及深狀態色。
- `feature_navigation.gd`：設定已換父容器，頁面標題避讓改讀global rect。
- `living_abode.gd`：播放曲目時同步已知境界，境界切換以選中路徑識別曲目，支援尚未下載stream。原BGM測試直接跨境播放後記錄未更新造成early return；不歸因於UIX。BGM runner改非掛起式失敗／exit1。
- `m2d_responsive_ui_runner.gd`：恢复兩項訊息置中、resource ribbon邊界與避讓、模式2→0→1訊號操作；補三橫式真實可見主操作幾何／導航避讓與離線摘要遮罩。
- `uix_r1_components_runner.gd`：正式View藏經閣、全部canonical routes與裝飾／舊圖示檢查，74 checks。
- `tools/uix_r1_review_fixture.gd`及UID：空白新檔正常建設、採集、晉階命令與1010模擬等待秒，輸出突破前fixture，沒有直接注入境界／庫存。它不是完整Web自然等待證據。

## 命令與結果

固定Godot `4.7.2.stable.official.ed1daf0bf`。所有CLI使用進程級`APPDATA=E:/WORK/Dao2/build/uix-r1-finish-user`，不改系統設定，不覆寫玩家user://。

- `tools/run_all_runners.ps1`：**60/60／exit0**，[全量log](artifacts/uix-r1-finish/all-runners.log)，含BGM與74元件契約。
- 全量後最後的彈窗暫收／延後尺寸／offset值比對修正，再跑responsive、feature_navigation、m2b_breakthrough、res1d2_world、early_flow1b、early_flow1d，六項全部exit0；`final-*.log`。這是最終版本的相關回歸，不把較早全量log冒稱為最後補丁之後再跑60項。
- `--headless --path . --export-release Web build/web/index.html`與bundled Node `tools/prepare_web_compression.mjs build/web`：最終exit0，[export](artifacts/uix-r1-finish/export-final.log)／[compression](artifacts/uix-r1-finish/compression-final.log)。一般Web已更新，Windows未匯出。
- `--headless --path . --script res://tools/uix_r1_review_fixture.gd`：exit0，[fixture log](artifacts/uix-r1-finish/fixture.log)；先前新測試用錯Session建構式、未附掛skills內容與fixture未標明content型別已修正，再取最終證據。
- `git diff --check`受影響來源／測試：exit0，換行正規化提示保留。Font／CanvasItem／ObjectDB退出診斷仍在，損壞保存負面案例預期ERROR仍在，不宣稱所有日誌零錯誤。

## 真實Web

CUA IAB，最終實測DPR1.25、iframe1280×720（DOM rect）。兩個新origin，玩家4175不碰，每個只seed一次。服務為bundled Python `tools/island_preview_server.py --port <48210|48211> --normal-build --gzip --fixture <early-flow1d-ready.json|uix-r1-prebreak.json>`。初次沙箱服務啟動但通訊端存取拒絕，改用已授權的sandbox escalation後成功，無auto-review拒絕；第一次分頁停在連線錯誤，重新建立隔離分頁成功。

- 48210：1280×720真實滑鼠點右下「修為晉階」，金丹1→2，庫存實際扣料；844×390點設定出現選單。
- 48211：800×360真實點「突破至築基期」，世界演出遮罩→結果顯示練氣→築基／進度已保存→圓滿出關；經營／固定返回可點。1280×720、844×390、800×360版面，360×640旋轉遮罩轉回，真正reload→Play（不再seed）保留築基；最終包追加reload／主操作遮罩核對。
- [突破800證據](artifacts/uix-r1-finish/web-breakthrough-800.png)、[桌面恢復](artifacts/uix-r1-finish/web-home-1280.png)，其他最終版截圖同目錄。

真實點擊與CLI幾何分開記錄；本輪不量FPS、IndexedDB矩陣或實體触控，冷啟動暫緩不阻擋。800／844短橫式壽元單位換行、資源摘要與清單重複及空間密度列入R2，未冒稱新主HUD已完成。

## 接手

最新使用者回覆R2有指定設計、稍後提供；R2等待設計稿，[暫擬範圍與DoD](../18-uix-components-and-hud-plan.md)尚未核定，不开始實作。依AGENTS的Context Guard，在R1收尾通過後checkpoint；下一New Chat按使用者設計修訂範圍。最終包844×390實際晉階築基1→2通過，三張web-final截圖與offline overlay截圖已保存，console error/warn查詢空。兩驗收遊戲分頁已關閉、viewport reset；初次連線錯誤分頁的明確close被URL policy阻擋，保留臨時分頁自動清理。48210／48211服務已Ctrl+C停止（exit1為主動停止）。未commit／push、未覆寫玩家資料。
