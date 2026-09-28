# 洞府呈現層：按需閱讀索引

2026-09-28 REF-A。先讀目前狀態，再按本表定位；普通 HUD 或彈窗修改不需通讀 2,000 多行根腳本。

| 修改內容 | 優先讀取 | 相關驗證 |
| --- | --- | --- |
| 場景啟動、GameSession、時間／自動保存、世界點選、突破運鏡 | `src/abode/living_abode.gd` | living_abode、m2a、island_breakthrough |
| HUD 組裝、斷點與版型、資源／修煉／壽元／BUFF、引導與日誌 | `src/presentation/abode_hud_controller.gd` | m2d_responsive_ui、abode_presentation_parity |
| 彈窗掛載／位置、更多選單、開關、訊號事件分發 | `src/presentation/abode_modal_manager.gd` | abode_presentation_parity、各功能 UI Runner |
| 單一彈窗內容 | `src/presentation/` 對應 panel / modal 腳本 | 對應 UI Runner |
| 營造列、資源卡、捲動與詳情容器 | `src/presentation/building_catalog.gd` | m2d_responsive_ui、core_positive_flow |
| 真正的費用、資格、命令結果 | `src/application/game_session.gd`、對應 simulation 模組 | core、功能規則與正式 Session 成功路徑 |
| 存檔與遷移 | `src/persistence/`、`src/domain/game_state.gd` | m1c / m1d / m1e |

## 相容邊界

- 根場景仍是公共屬性與服務的唯一持有者。控制器通过 `_abode` 讀取相同欄位，避免替換 Session／Control 後出現過期副本。
- 兩個控制器為 `RefCounted`，只保存不擁有生命週期的 Node 引用。所有 Control 仍掛在原 HUD 下；scene free 時一起釋放。
- 根場景保留原方法簽名和薄委託入口，既有 Runner、訊號接線與 `Callable(scene, ...)` 仍以原場景為接收者。
- HUD 控制器是唯一版型斷點入口；彈窗管理器接收相同尺寸／margin／portrait，處理次級面板座標。
- 彈窗建立順序、初始可見性、事件先提交／保存再刷新及既有失敗訊息保留。每個功能仍使用既有 GameSession 呼叫。
- 目前一般彈窗可以同時打開；不因叫作 manager 就新增強制互斥。突破的 HUD 遮罩與相機鎖定維持原作用域。
- Debug 的直接狀態變更仍留在根場景既有方法；本次只搬移面板事件分發，不擴充或修理 Debug 功能。
- 這是保留公共 API 的第一階段拆分；不加入泛用事件匯流排、第二份狀態或存檔欄位。

## 驗證入口

```powershell
powershell -File .\tools\run_all_runners.ps1
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/abode_presentation_parity_runner.gd
```

原 25 項清單維持不變；REF-A 場景回歸另行執行。完整結果與真實瀏覽器證據見 [REF-A 驗收](verification/ref-a.md)。

## 下個優先項

`GameSession.KNOWN_COMMAND_TYPES` 未納入宗門、跨界／據點、apply_buff 等新增命令，造成 Domain／元件 Runner 通過而正式場景回覆 `UNKNOWN_COMMAND`。先建立正式 Session 成功路徑再修復白名單，屬獨立行為修正，不併入 REF-A。
