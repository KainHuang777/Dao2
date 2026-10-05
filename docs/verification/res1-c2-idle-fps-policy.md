# RES1-C2-PERF-R2｜放置遊戲 FPS 標準修訂

2026-10-04。標準／工具修訂子階段DONE；**R2／C／C2仍IN_PROGRESS，D TODO**。使用者授權常態60、偶發30後回升可接受，持續劣化需修。依[ADR-010](../decisions/ADR-010-idle-frame-recovery-budget.md)取代嚴格平均≥60；不是程式效能改善。

修改：`tools/summarize_frame_metrics.py`加入5秒窗口／時間比例／尾端恢復，低谷10秒警示不直接阻擋；`res1c2_metrics.js`支援正常模式`?sampleSeconds=60`及300；`island_preview_server.py`轉交正常取樣參數；`test_frame_metrics.mjs`與Python內建self-test補契約。同步README／Roadmap／docs07／handoff／status／updata與ADR。沒有Godot來源／規則／保存／素材／匯出變更。

## 判定與回歸

目標60；5秒窗≥55視為接近目標，時間占比≥80%，末10秒恢復；至少一個正常60秒樣本。15秒快照診斷保留。固定30、持續下降、取樣末端未恢復不可PASS；短暫5秒或10秒30FPS後回升可以PASS。p95／p99／max只作診斷，不用原20ms硬門檻否決可恢復30FPS。

Bundled Python `tools/summarize_frame_metrics.py --self-test`：**16 contracts PASS／exit0**，含59.997不被零容差否決、5／10秒30後恢復、持續30、末段下降、逐步下降、長interval跨窗口、profile／無效樣本／短樣本拒放行。Bundled Node `tools/test_frame_metrics.mjs`：**13 contracts PASS／exit0**，含正常60／300秒、無效duration回退、profile仍獨立。日誌：[contracts](artifacts/res1-c2-idle-policy-contracts.log)。首版測試誤以5秒30低谷會使按幀計數的p95>20，assert失敗；校正為p99，沒有調產品判定來迎合該錯誤預期。後續另補10秒可恢復通過，最終以上述16／13為準。

舊正常三組15秒raw原文重算：57.9990／57.8636／57.7992，全部窗口接近55以上、尾端已恢復，**短樣本恢復條件3/3通過**；因沒有連續60秒，整體`desktopRecoveryGate=INSUFFICIENT_EVIDENCE`，不把政策修訂冒稱新的60秒實測或效能提升。[新政策重算](artifacts/res1-c2-idle-policy-reanalysis.json)；原strict60失敗與raw保留。

命令：`python tools/summarize_frame_metrics.py docs/verification/artifacts/res1-c2-task-fps-metrics.jsonl --output docs/verification/artifacts/res1-c2-idle-policy-reanalysis.json`，exit0；Python AST／Node syntax及`git diff --check`另記policy-checks.log。本輪沒有新真實瀏覽器／5分鐘操作驗收，沒有新Godot51 Runner／匯出；前輪51/51為已日期化歷史，不宣稱本輪重跑。

下一：正常（無CPU profile） `/metrics.html?sampleSeconds=60` 做恢復測試，`?sampleSeconds=300`做5分鐘趋势，另記50次操作／reload，觀察是否回升；launcher參數轉交須服務重啟載入新版Python PAGE，直接metrics路徑可由現有服務動態載入新版JS。不為單一平均59.x或偶發33ms續開無限優化。手機／高DPR／自然背景／跨瀏覽器／長期GPU／人工美術節奏保持待驗。

本階段依Context Guard停止，英文checkpoint置updata頂部；New Chat續同R2恢復驗收，不重做已通過規則或桌面保存矩陣。
