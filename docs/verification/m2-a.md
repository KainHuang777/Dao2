# M2-A 驗收紀錄｜現有洞府接入正式核心規則

日期：2026-09-19。狀態：**DONE**（CLI／桌面路徑；實機觸控與高負載留待 M2-D）。

## 目標與邊界

依據 [ROADMAP.md](file:///e:/WORK/Dao2/ROADMAP.md) §6 M2-A：
1. 將主場景 `scenes/living_abode.tscn` 及其控制器 `src/abode/living_abode.gd` 從展示用浮點數 `abode_state.gd` 徹底轉移至 M1 的正式領域層（`GameSession`、`CommandProcessor`、`TimeAdvancer`、`SaveManager`、`OfflineCoordinator`）。
2. 在畫面配置 Era 1 的 10 個建築（`hut`, `wooden_house`, `forest_farm`, `stone_mine`, `herb_farm` 與 5 種倉庫）。
3. 依照 `Onboarding` 規範實現連鎖解鎖（空白開局僅見茅屋；升級茅屋解鎖木屋與倉庫；提升木屋解鎖林場等）。
4. 支援「聚氣引靈」（手動 `gather`）累積 20 靈氣啟動首次營造。
5. 整合離線結算彈窗與存檔管理介面，定時自動存檔。
6. 保留向後相容轉接層 `AbodeStateCompat`，確保舊有場景測試（`living_abode_runner.gd`）與相依腳本平滑過渡。

## 交付產物

- `src/abode/living_abode.gd`：重構主場景控制器，接入 `GameSession`、`SaveManager`、`OfflineCoordinator`、`Onboarding`，實現 10 個建築的動態可見性與營造升級交互。
- `src/abode/abode_building.gd`：支援未建造狀態（0階）、`contains_point` 可見性檢查與選取特效。
- `src/domain/amount_compat.gd`：補充 `to_float()` 方法，支援直觀數值轉換。
- `src/persistence/web_storage_adapter.gd`：修正保留字 `namespace` 為 `p_namespace`。
- `tests/m2a_abode_runner.gd`：專屬 M2-A 驗收測試，覆蓋空白開局、手動引氣、自動產出、連鎖解鎖、存檔重載、低特效確定性。
- `tests/living_abode_runner.gd`：更新場景回歸測試，相容 M2-A 的正式建築與狀態。

## 驗收環境與執行命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m2a_abode_runner.gd
& $daoEngine --headless --path . --script res://tests/living_abode_runner.gd
& $daoEngine --headless --path . --quit-after 3
& $daoEngine --headless --path . --export-release Web '.\build\web\index.html'
```

### 實測結果（2026-09-19）
- `--import`：退出碼 0。
- `m2a_abode_runner.gd`：退出碼 0，輸出 `PASS: M2-A abode blank opening, manual start, auto production, chained unlocks, save/reload, and determinism.`。
- `living_abode_runner.gd`：退出碼 0，輸出 `PASS: living abode selects buildings, upgrades, pauses production, and changes scale.`。
- 全量 10 個 Runner 迴歸：全部退出碼 0，無任何 SCRIPT ERROR。
- `--quit-after 3`：正常啟動退出碼 0，輸出 `ABODE_READY`。
- Web Release 匯出：成功產出 `build/web/index.html`，退出碼 0。

## DoD 對照

| 驗收條款 | 驗證證據 |
| :--- | :--- |
| 從展示 state 轉至 GameSession | `living_abode.gd` 統一使用 `GameSession.submit()` 與 `get_view()` 驅動 HUD 與邏輯 |
| 10 個建築獨立 ID、位置、命中區與狀態 | `props` 下掛載 10 個建築，座標分散佈局，`contains_point` 響應命中 |
| 空白開局（0 資源） | `m2a_abode_runner.gd` 第一步斷言靈氣 0，茅屋 0 階，僅茅屋可見 |
| 手動啟動（Gather） | 點擊茅屋「聚氣引靈」20 次，累積 20 靈氣後升級按鈕解鎖 |
| 自動產出 | 茅屋升至 1 階後，時間推進 60 秒產出 +0.3/s 靈氣（累加 18 靈氣） |
| 連鎖解鎖 | 茅屋升至 2 階後，木屋、聚靈壇、靈石庫立即成為可見並可交互 |
| 重開恢復狀態 | 存檔後銷毀場景重開，茅屋 2 階與解鎖建築全部正確重載 |
| 特效切換收益一致 | 低特效模式推進 60 秒與標準模式產率及秒數嚴格一致 |

## 未實作／留待後續任務

1. 實體手機觸控與 360 CSS px 排版適配留待 M2-D 統一驗收。
2. 突破升境（筑基與首次修為突破演出）留待 M2-B。
3. 九界神識一瞥第一分鐘引氣演出留待 M2-C。
