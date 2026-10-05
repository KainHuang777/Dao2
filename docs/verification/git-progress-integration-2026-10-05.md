# 2026-10-05 工作樹進度整合與 master 功能審查

使用者授權：保存兩處未提交成果，逐項整合 VFX、審查舊 master，驗證後推送 main；未來 pull 使用 fast-forward only，分歧須明確回報。

## 保存與 VFX 整合

| 提交／參照 | 用途 |
| --- | --- |
| `d54faa3` | 主目錄原有 D1/D2/R2 未提交成果及前次 Git 稽核 checkpoint |
| `codex/preserve-vfx-20261005`／`fb65890` | 原 detached 工作樹的完整非忽略檔案 checkpoint；舊工作樹現在停在此備份分支 |
| `47efd8d` | 真正雙親 merge：將 VFX checkpoint 合併至較新 main，不是覆寫整棵主線 |
| `codex/preserve-master-20261005`／`ff86f85` | 舊 master 原提交的額外本地保留參照；遠端 master 亦保留 |

VFX 合併衝突為 `docs/ai-handoff.md`、`docs/development-status.md`、`updata.txt`、`src/abode/abode_flows.gd`、`src/abode/living_abode.gd`。文件保留雙方日期化歷史；程式保留目前多島／scenery／Web writer protection／保存恢復／R2 View 快取接線，接入原創 Shader、CPU 粒子、WorldEnvironment Glow、題字光暈與設定試播。飛劍改由原生 Sprite2D 呈現，取消重複 draw_texture；低特效下劍位置與靜態視覺採同一時鐘。

瀏覽器發現短橫式試播縮鏡後，較新主線遠景題字與試播標題並存。修正開始演出即隱藏 home／region／building 題字，每幀保持遮罩；返回後原流程恢復顯示。既有突破 runner 增加跨四版型的遮罩回歸，不改遊戲命令、費用、schema 或規則版本。`git merge-base --is-ancestor codex/preserve-vfx-20261005 main` exit0，證明 VFX 原成果已在 main 歷史中。

## master 逐項審查：存在設計分歧

`ff86f85` 是 2026-10-02 的一般內容／技能模型；目前主線已有 2026-10-03–05 的多島供給及使用者核定 ADR-011。它不是主線尚未套用的小補丁。審查依 `git diff b9f6685..origin/master`、實際源碼與其 `m3-b-content2`／`m3-b-skill-effects` 驗收文件，不因舊文件寫 DONE 推定目前正式支援。

| 舊 master 功能 | 與目前 main 的關係／處置 |
| --- | --- |
| ContentSchema／ProgressionEvaluator、recipe／consumable／skill manifest | 舊版一般內容管線；目前 ProcessingCatalog／IslandProgression 管理版本化地方庫存與配方。保留於原分支，不額外啟用第二套權威資料模型。 |
| Era2 11 棟建築、9 資源、3 配方 | 包含 rice／hunting／skill_point 等未在目前首段範圍內的功能，以及直接祖島加工丹液。後者與丹霞唯一加工／運輸契約衝突，不能把舊 manifest 或 era2.json 覆蓋較新主線。 |
| Era2 倍率1.5、時間1.18、三種修行費、石容量1000 | 現行 Era2 倍率2、時間1.2／費用模型不同；一般庫房+50000容量也不等於 ADR-011 的築基靈池+1000／階。明確列為平衡分歧，不宣稱 parity。 |
| learn_skill／skill_point／六技能與產率、容量、等級上限效果 | ADR-011 明文「一般技能／技能點暫不移植」。已向使用者呈報並提出選擇；未收到改變此決策的指示前，保留目前核定設計，不啟用舊技能。 |
| ContentReconciliation／skills／learned_recipes 保存 | 舊存檔模型不是目前 schema3 economy、command receipts、版本遷移與故障復原的直接替代；未混入正式保存。 |
| capacity 去 `_max` 後綴 | main 現行 loader 已正規化並驗證容量 key，Era2 lingli2000 正常；D2 215 checks 保持。此問題不需覆寫整個舊內容集解決。 |
| 動態 Alchemy／Sect／Fortune resources 與一般 skill 效果 | 依賴舊管線，套回會影響較新的祖島權威庫存及加工／BUFF／Beast 結算；本輪不改這些規則。 |
| 四支新增 content／skill runners 與 fixture、来源稽核 | 原始碼及歷史驗收保留於 master／本地備份參照，沒有假稱它們已成為目前53項正式 Runner。若重新採用技能，需另行移植及重跑，而不是僅把舊 PASS 記錄搬入主線。 |

因此本輪 **VFX 已合併，master 完成審查但沒有合併**。master 的獨有提交仍保留；這是明確報告的設計分歧，不是失落工作樹提交。沒有使用 `merge -s ours` 假裝功能整合、沒有刪除 master 或備份分支。後續若使用者改採一般技能，先修訂 ADR-011／供給設計，再做獨立整合與驗證。

## 驗證與界線

- 本機 Godot `4.7.2.stable.official.ed1daf0bf`，既有模板／Compatibility／單執行緒 Web；未更新或重裝環境。
- `--headless --path . --editor --import --quit` exit0，日誌 `git-integration-vfx-import.log`。
- 第一次整合全量53/53／exit0；題字修正後指定 breakthrough exit0；**最終全量53/53／exit0**，`git-integration-final-runners.log`。
- 獨立 `--export-release Web build/git-integration-web/index.html` 初輪與最終 exit0；同版 Node `tools/prepare_web_compression.mjs build/git-integration-web` 兩輪 exit0。原有 web／D2驗證包與服務保留，沒有手改生成 HTML／PCK。
- 真實 IAB 滑鼠使用新 origin `http://127.0.0.1:4264/index.html`：試播、返回、低特效切換、實際重載與重播；最終1280×720（canvas1279×719、DPR約1）／844×390，確認題字避讓，返回仍練氣1/10。截圖 `git-integration-final-compact.jpg`、`git-integration-final-desktop.jpg`、`git-integration-final-home.jpg`；初輪低特效圖記錄修正前重疊。JPEG header 已核對。
- 最終 browser warn/error query `[]`；不是 FPS、觸控、GPU 長期、DPR2–3 或手機驗收。FX3／D2／C／R2 原有未通過 DoD 不因本輪 Git 整合改成 DONE。
- 原有 Font RID／CanvasItem／ObjectDB 退出診斷保留。Git staged diff-check 曾因原始 runner 日誌三行尾端空白回報非零；沒有改寫原始測試日誌以掩飾，源碼／文件另檢查。初始 VFX merge exit1 是上述預期且已解決的合併衝突，不是靜默成功。

## 後續 Git 操作

主開發入口固定為 `E:/WORK/Dao2` 的 `main`。舊工作樹停保存分支，只作保留／比較，不從它接續正式進度。不要把備份分支或 master 的日期化歷史當成最新產品狀態。

本 clone 已設定 `git config --local pull.ff only`；其他 clone 仍須明確使用：

```powershell
git fetch origin --prune
git rev-list --left-right --count main...origin/main
git pull --ff-only origin main
```

遇到兩側都有提交，或 pull 因 dirty／untracked 阻擋時停止並回報具體內容，不自動 rebase、reset、force push 或改從 master 拉取。本輪 main 採普通 `git push origin main`，推送前再 fetch 核對，推送後再次核對遠端 HEAD；遠端同步結果以最後命令驗證為準。
