# EARLY-FLOW1-A：現況稽核與流程提案驗收

日期：2026-10-10。**A 規劃交付完成，EARLY-FLOW1 整體 IN_PROGRESS**。

交付：[前期流程提案](../17-early-progression-and-onboarding-plan.md)。相依為已有宗門／技能／煉丹／靈獸／四島規則及UI1製造／運輸介面。具體介紹次序尚未核定；本輪未改遊戲來源、解鎖條件、保存schema、資產或匯出包。

## 核對與結論

- 核對 `Onboarding` 五段建築鏈、正式 `GameSession.get_view`、`FeatureNavigation` 全分頁與 HUD 完成提示；現有跨系統引導尚未實作。
- 核對正式附掛的Era1–3、技能、配方、產地與 `CommandProcessor`，沒有把基礎manifest缺少Era3誤判成正式場景缺少Era3。
- 梳理容量門檻、空島啟用版本、兩島地方庫存、原料送料、祖島單產線與第一次餵食。指出築基丹／金丹道具不是升境必需，以及丹液資料Era2／實際丹霞Era3的差別。
- 建議先供給鏈、再可延後技能／宗門支線；首升級之後介紹靈狐。表列規則資格、真實完成事件、下一提示與卡關恢復，不以提示排序改解鎖。
- 跨重載首次完成紀錄尚需保存設計；256筆命令收據不能當永久教學歷史。已有進度應按狀態跳過，不強制重做；本輪未宣稱已實作。

## 本輪命令與結果

在 `E:/WORK/Dao2` 執行，使用本機既有引擎，未更新環境。

| 命令／工具 | 結果 |
| --- | --- |
| PowerShell `Get-Content`、`rg`／`rg --files` | 核對README、ROADMAP、handoff、status、架構、docs07／08與實際程式；首次探索錯猜三個扁平content路徑和spirit_beast_system檔名，exit1；隨後由檔案清單改讀實際分目錄與beast_system，成功 |
| `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` | exit0，`4.7.2.stable.official.ed1daf0bf` |
| 同引擎 `--headless --path . --log-file docs/verification/artifacts/early-flow1/d2.log --script res://tests/res1d2_integration_runner.gd` | exit0，215 checks PASS；正常命令由空白到Era3 Lv10，11561模擬秒；無贈料／直接設定等級，但以加速模擬等待，不是自然時間滑鼠通關 |
| 同引擎 `--headless --path . --log-file E:/WORK/Dao2/docs/verification/artifacts/early-flow1/alchemy.log --script res://tests/m3b_alchemy_runner.gd` | exit0，煉製／服用／壽元／產率／保存／輪迴回歸PASS |
| 同引擎 `--headless --path . --log-file E:/WORK/Dao2/docs/verification/artifacts/early-flow1/beasts.log --script res://tests/m3b_spirit_beast_runner.gd` | exit0，取得／餵食／冷卻／成長／天賦／輪迴／Session／SaveCodec六組PASS |
| `apply_patch`／PowerShell UTF-8編輯與回讀 | 新增提案、驗收，更新Roadmap／status／handoff／updata；保留開工前四份既有文件變更 |
| `git restore -- docs/verification/artifacts/res1-d2-earned-era3.json`；改用Python `subprocess.check_output(['git','show','HEAD:…'])`＋`Path.write_bytes` | restore因沙箱保護.git、無法建立index.lock而失敗；改以唯讀HEAD原始bytes還原本輪D2 Runner刷新之生成fixture，成功。開工前該檔乾淨，只恢復本輪生成副作用，未動玩家存檔 |

日誌：[D2](artifacts/early-flow1/d2.log)、[煉丹](artifacts/early-flow1/alchemy.log)、[靈獸](artifacts/early-flow1/beasts.log)。D2相對log路徑觸發 `Could not create directory: user://E:` 診斷，檔案仍落在指定專案位置且Runner通過；後續兩項改絕對log路徑，沒有該診斷。D2故障注入的corrupt JSON解析錯誤為預期負面測試，完整保留；不能稱日誌零錯誤。文檔驗證另見 `artifacts/early-flow1/document-check.txt`。

## 證據界線與下一步

本輪沒有新UI或規則，未重跑全量56 Runner／Web匯出／FPS／400保存矩陣。本輪規則回歸用於支持现況，不是尚未接入教學的DoD；未執行新流程真實瀏覽器操作。提案順序、人類理解度、自然等待節奏、保存里程碑、重載／輪迴教學行為與桌面／短橫式滑鼠仍待下一段實作驗證。實體觸控／高DPR及完整UI1-C／C／D待驗不提升；冷啟動預算依使用者指令暫緩阻擋。

下一建議 **EARLY-FLOW1-B：Q1–Q3練氣到首次築基**，在具體順序核定後沿現有HUD與Session接入；不開Era4或30＋島。依Context Guard已將英文checkpoint置於updata頂部，下一大型階段用New Chat。
