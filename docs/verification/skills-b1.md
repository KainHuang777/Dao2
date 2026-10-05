# SKILL-B1：B 方案一般技能與多島整合驗證

2026-10-05。使用者選 B；技能整合子任務 **DONE**，完整 D2／R2／遊戲放行仍 IN_PROGRESS。決策見 [ADR-012](../decisions/ADR-012-optional-skills-with-islands.md)，取代 ADR-011 的技能暫不移植限制，其他多島／容量規則保持。

## 交付

六技能保留舊master的 ID、最大等阶、研習費及效果值，透過正式 learn_skill 命令扣 Amount 庫存；建築精通限制為四個生產設施，不影響倉儲／茅屋／築基靈池。藏經閣與經書殿接入既有建築清單，修行新增技能頁、費用／禁用原因／建築捷徑。技能點每秒讀数更新不重建整個清單；閾值／等階改變才重建，避免產量更新打斷點擊和捲動。輪迴不保留技能／技能點。

主線兩倍Era2資源、1.2時間倍率、靈力費200、金丹容量2000与多島配方所有權未更改。歷史master／兩處checkpoint／VFX保存分支仍保留；本輪為功能適配提交，不把整份master經濟merge回main。

schema3新增 skill_version／skills，rules core-flow-11-skills-b1。自動載入缺少技能欄位的本地主線存檔時補零；首次提交前以原JSON雜湊命名備份，讀回精確比對。備份拒寫／衝突時原槽不動，可重試。分享字串與舊版匯入也補技能狀態，但不宣稱原master不同保存模型完全相容。

## 命令與結果

- 既有 Godot `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，版本4.7.2.stable.official.ed1daf0bf；無引擎／環境更新。
- `tools/run_all_runners.ps1`：最終54/54、exit0，完整日誌 [delivery](skills-b1-all-runners-delivery.log)。其中D2無技能、正常命令到金丹十層與丹霞供給215 checks續通過；使用模擬秒，不宣稱自然時間滑鼠通關。
- `--headless --path . --script res://tests/skills_b1_runner.gd`：最終41 checks／exit0，[日誌](skills-b1-contract-final.log)。含六技能扣費／效果／防重扣、上限與不足資源原子拒絕、倉儲不受建築精通影響、tick分段、保存與舊JSON備份／故障重試、輪迴、每秒更新保持按鈕身分與保存恢復訊息。
- `--headless --path . --script res://tests/feature_navigation_runner.gd`：exit0，[日誌](skills-b1-navigation-final.log)，導航唯一歸屬與切頁／命令回歸。
- Bundled Python `tools/subset_game_fonts.py` 與 `--check`：exit0。新文字缺字已修正，兩個runtime OFL衍生字型與manifest更新，原TTF及授權未修改。
- `--headless --path . --editor --import`：最終exit0；`--export-release Web build/skills-b1-web/index.html`：最終exit0，[匯出](skills-b1-web-export-delivery.log)。既有build包不覆寫。
- Bundled Node `tools/prepare_web_compression.mjs build/skills-b1-web`：exit0，原音樂companion與Brotli roundtrip通過，[日誌](skills-b1-compression-delivery.log)。
- Bundled Python `tools/skills_b1_preview_server.py`：独立loopback4265，不修改其他origin進度；測試後停止本服務。

失敗留存：首次sandbox import有user://拒寫及語法錯誤；初輪SkillSystem重新驗證Era3時碰到動態加工資源引用，改僅驗證新增資源／建築、Era沿既有已驗證附掛；核心測試修正語法，首次完整suite遇舊狀態唯讀視圖缺skill_point，改以零值鎖定呈現，正式載入仍進備份遷移。首瀏覽器發現缺字，以及技能容量讀數漏計既有全倉bonus，最終修正並重新匯出／跑54。初期故障日誌均保留。既有RID／ObjectDB退出診斷與刻意損壞JSON錯誤不稱零error；最終無SCRIPT ERROR／Parse Error。

## 真實瀏覽器證據與範圍

IAB、隔離origin4265，正常Web包。使用CLI產生的築基研習fixture（藏經閣／經書殿與6002技能點），不是玩家存檔，也不宣稱從零以滑鼠賺到該材料。真正滑鼠：修行→技能、基礎冥想0→1，實際存檔技能點6110，重載後1/5仍在；844×390內部捲動至末项，建築精通0→1，從6200扣200，localStorage保存6000、兩技能均1，按鈕已達上限。字型文字可讀，導航與返回固定在面板外，不靠瀏覽器捲動操控Godot技能清單。

[桌面重載截圖](artifacts/skills-b1-desktop.png)、[短橫式末項截圖](artifacts/skills-b1-compact.png)、[實際保存結果](artifacts/skills-b1-web-save-result.json)／[再次重載](artifacts/skills-b1-web-reload-result.json)。兩技能在再次重載仍為1；技能點隨生產恢復6200。舊PNG/JSON證據不改作本輪通過證據。Browser wrapper的結果區可產生外頁捲軸；Godot清單的捲動以指標位於面板內驗證。這不是實體觸控、手機直式、FPS或長時間R2驗收。

人工平衡／完整自然時間滑鼠、實體裝置及R2原有缺口仍待驗。下一New Chat做有界人工節奏驗收或既定D2／AGY R2，不能把本輪功能接回當作完整D2 DONE。

初預覽尚未建立音樂companions時出現MP3 404／BGM下載警告；準備後11:40／11:41音樂GET各200，最後兩次重載未新增該警告。瀏覽器整段歷史warn/error查詢仍包含早期警告，不稱全程零error。最終來源／文件 git diff --check 通過，raw驗證日誌保留原始輸出。

2026-10-05 推送確認：功能提交 `12c560e` 已普通 push 至 origin/main；fetch 後 HEAD 與 origin/main 完整SHA一致，ahead／behind=0／0，工作區乾淨，pull.ff=only。來源／文件 staged diff-check（排除原始log）exit0。測試服務4265以Ctrl+C停止（程序exit1為主動終止），其餘服務未操作。此紀錄另以文件checkpoint提交，不改已驗證程式。
