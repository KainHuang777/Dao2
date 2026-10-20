# 2026-10-20 未完成進度盤點（DOC-A-R2）

本輪只核對文件、工作區原始碼及既有證據，沒有重新執行 Godot、Runner、Web 匯出或瀏覽器測試。以下測試數字均為既有紀錄，並非本輪重測結果。

## 當前未完成項

| 任務 | 實際已有進度 | 剩餘工作 |
| --- | --- | --- |
| MFG-3／製造介面收尾 | MFG-0/1 邏輯及 MFG-2 RecipeRow 已交付；MFG-2 記錄 81/81 Runner 通過 | 列內模式籌碼、單語意啟停與就地手風琴設定；完成後以實際桌面 Web 三橫式操作做受控回歸。現有面板仍有獨立詳情頁與 OptionButton，不把 MFG-1 的邏輯拆分當作 MFG-3 介面完成 |
| EARLY-V1-B | 三天賦成本、跨世效果、零傳承再築基與保存故障已有 CLI 證據 | 真實瀏覽器購買天賦、轉世、重載與零傳承重建；靈界 realms_data 跨世保留仍是獨立待決政策，不算天賦效果。D-2 證明第二世可操作，沒有取代 B 的天賦購買矩陣 |
| EARLY-V1-C／SKS-P1 | 七項技能正式命令路徑、成本／容量／縮時／輪迴清除、字型及 Web 匯出已有證據 | 結丹法金丹題材圖、來源／manifest／人工接受；1280×720、844×390、800×360 真實滑鼠研習、拒寫恢復及重載。manifest 的 golden_core_formation 仍為 pending_art |
| EARLY-V1-D／RES1-D、D2、D2-R1 收結 | D-1 單一不中斷空白新檔至金丹首升、四島產運、離線與保存恢復已達成；D-2 自然壽盡、首次輪迴、第二世採集／建造／升階及重載已達成 | MFG 完工後受控 UI 回歸，以及人工節奏判定；母任務仍 IN_PROGRESS。既有自然流程無須重新當作未做 |
| TRIB-B/F1、C、D | 0 與 A 已完成；B/F1 視覺／雷聲已交付。C 已有正式接線、原生測試與匯出產物 | B/F1 人工視覺／聽感接受記錄未收結；C 需核對接受記錄、補真實桌面 Web 成功／失敗、跳過／重播、拒寫恢復／重載及清理驗收並補交付文件；D 簡單完整流程收結仍待做 |

## 必須釐清的證據邊界

- EARLY-V1-D 使用的 Web 包早於 MFG-0/1/2，因此不能拿 D-1/D-2 的滑鼠流程證明新製造介面通過。依既有交接保留凍結包與 origin 存檔，受控回歸前不直接重匯出覆蓋 build/web。
- TRIB-C 的「未開工」文字已落後於實際工作區：`src/presentation/breakthrough_sequence.gd` preload 正式 `tribulation/stage.gd` 並載入雷聲；`tests/tribc_integration_runner.gd` 已列入總入口。`artifacts/trib-c/native.log` 記錄 `TRIB-C checks=113 failures=[]`；`all-runners.log` 記錄 `ALL 79 RUNNERS PASSED WITH EXIT CODE 0!`，另有正式 Web 匯出和壓縮紀錄。原生日誌亦有 layout 呼叫堆疊診斷，不能只憑最後通過行推定全部乾淨；未找到 C 的獨立交付報告／瀏覽器驗收紀錄，故本輪只認定「已有實作及部分驗證，未收結」，不追認接受或 DONE。
- D-2 達到 44400 秒是自然遊玩加自然離線缺口，並非單次連續 12 小時離線。本輪不新增此驗收要求。
- UIX-R6～R11 現版美術、輪迴 F5 全系列與 RES1-C/C3 已有最新核定，不因舊段落的 IN_PROGRESS／待接受再列未完成。

## 後續大型內容

- RES1-E：Era4–12 的資源、建築、加工、消耗與輪迴承接；SKS-P2～P4 技能批次依其內容相依逐段交付。
- 九界／M4–M5：三種手工法則可玩差異、逐界場景美術與事件、生成版本保留既有世界及長期負載等完整驗收；現有資料／核心契約不等於九界全部可玩。
- 舊檔相容：真實玩家存檔 corpus、瀏覽器匯入 UI 與完整相容宣稱仍有邊界；以 `docs/legacy-compatibility.md` 為準，不列作新玩家前期版本的新增阻擋。
- 較早 UI／世界特效母任務仍有未收結歷史，後續按最新接受與子項證據合併整理，不將每一條舊 IN_PROGRESS 當作新的重做任務。

觸控／實機／實機高 DPR 與慢網冷啟動依既定政策延期，非當前阻擋，亦非已通過。

## 建議接續

優先 MFG-3 → 製造介面受控桌面 Web 回歸；補齊 EARLY-V1-B/C → 人工節奏判定與 EARLY-V1-D／RES1-D 收結。渡劫線先核對 B/F1 接受與既有 C 成果，再補 C/D 驗收。Era4–12 與九界擴充留在前期版本收結之後。

## 本輪檢查與限制

- PowerShell `Get-Content`、`Get-Item`、`Get-ChildItem`、`rg`、`git status --short`：核對 README、ROADMAP、ai-handoff、development-status、updata、專題計畫、原始碼／manifest 與既有 log；工作區為 Git repository，已有大量 modified／untracked 成果，全部保留。
- 初次合併讀取輸出遭截斷，後改用分段與定點搜尋；搜尋誤指不存在的 `docs/feature-parity-matrix.md` 曾回報錯誤，改以實際 Roadmap／legacy 相容文件核對，無來源變更。
- 只新增本報告、更新開發狀態／英文 checkpoint，並校正 docs/23 頂端 D 仍 TODO 的過時摘要；沒有遊戲、資產、匯出或玩家資料變更，未 commit/push。
