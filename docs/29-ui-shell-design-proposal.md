2026-10-22 **ATM-LIFE-DESIGN 專項候選已交**：承接已核定F-C題名800／題簽900／小傳文楷；[docs30](30-atm-life-design.md)補十題逐句來源、三種生命時機／缺紀錄、待決流程與保存10世容量提案。上述布局、條件與容量仍待審閱，未成為正式共用通則；共用殼0～2已完成，勿沿下文歷史待實作文字重做。正式選文／事實保存仍TODO。

2026-10-22 **UI-SHELL-0 接入契約**：依使用者「接續正式遊戲接入」，政策／呈現意圖與canonical registry開始實作，見[驗收](verification/ui-shell-0.md)。洞府偏好與當頁暫收分離；resize只重算輸出；工具返回合法原route／子頁，覆層以token拒絕過期回呼；保存保護不受訊息開關或Escape繞過。新resolver集中使用寬≥960／比例≥1.45且高≥500的寬式條件，其餘橫式短式；尚未接管Control布局，正式畫面沿既有行為直到UI-SHELL-1／2遷移。共用顯示將由殼唯一套用，單頁只管自身內容；本階段沒有全頁顯示／字型接線完成或新畫面驗收聲稱。F-C800／900決定保留，題名條件／保存世數未因接續指令接受。
2026-10-21 **F-C粗明體修訂已交付**：依使用者「執行」，樣張卷末題名改Noto Serif TC真實字重800、題簽900；小傳／卷末句文楷、數字與操作黑體保持。比較頁預設開啟卷末F-C。三橫式含長文保存異常共6張專項圖通過（字重800／900、字型載入、44px與布局無溢出），見[新版樣張](verification/artifacts/ui-shell-design/heavy-serif/fc800-1280x720.png)。本次只調設計樣張與共用規範，正式Godot字型接線留待共用殼實作；整體布局仍待確認，UI-SHELL-DESIGN仍IN_PROGRESS。未改GDScript／build／玩家資料，未commit/push。

2026-10-21 **UI-SHELL-DESIGN 字體F-C已選定；布局仍待確認**：使用者明確回覆「F-C」。核定卷末題名用明體、小傳與卷末句用文楷；數字、帳目、收據、按鈕及分頁仍用思源黑體。此為限定敘事角色的共用規範例外，後續經UiTypography集中接入，不授權各頁自行載字或全面換字。正式字型接線尚未實作；整體布局、題名條件與保存世數未因本次字體選擇接受，任務仍IN_PROGRESS。[方案與比較](29-ui-shell-design-proposal.md)。本輪僅記錄決策，未重跑引擎／瀏覽器／匯出，未改正式程式／build／玩家資料，未commit/push。

# 共用介面殼：三橫式設計樣張

2026-10-21 · `UI-SHELL-DESIGN` · **樣張交付，IN_PROGRESS：待使用者選擇布局／字體。正式實作 TODO。**

依 [docs28](28-unified-ui-shell-and-visibility-plan.md) 與 [docs27](27-life-report-and-decision-ux-integration-plan.md)交付可比較設計。敘事視角沿已核定的「有人為修士立傳」；本頁其餘建議均未視為接受。現有正式 Godot UI、黑體政策與已接受圖像繼續有效。

## 開啟與比較

在專案執行 `python tools/ui_shell_design_server.py --port 4392`，開啟 [本機比較頁](http://127.0.0.1:4392/index.html)。服務僅讀取本案 HTML 與現有圖片／字檔，不讀玩家資料。若服務未啟動，連結不會可用。

上方比較工具可切六個頁面、1280×720／844×390／800×360、F-B／F-C、生命狀態、長文與保存異常。畫框按原尺寸展示，外層比較工具的捲動僅供設計審閱；畫框內沒有瀏覽器頁面捲軸，長內容在所屬閱讀區內捲。這是 `docs/visual-prototype/` 的設計工具，**不是把正式玩法轉為 HTML，也不是 Godot 渲染驗收**。

| 類型 | 1280×720 | 844×390 | 800×360 |
| --- | --- | --- | --- |
| 洞府 | [圖](verification/artifacts/ui-shell-design/home-1280x720.png) | [圖](verification/artifacts/ui-shell-design/home-844x390.png) | [圖](verification/artifacts/ui-shell-design/home-800x360.png) |
| 建築 | [圖](verification/artifacts/ui-shell-design/buildings-1280x720.png) | [圖](verification/artifacts/ui-shell-design/buildings-844x390.png) | [圖](verification/artifacts/ui-shell-design/buildings-800x360.png) |
| 製造 | [圖](verification/artifacts/ui-shell-design/manufacturing-1280x720.png) | [圖](verification/artifacts/ui-shell-design/manufacturing-844x390.png) | [圖](verification/artifacts/ui-shell-design/manufacturing-800x360.png) |
| 技能 | [圖](verification/artifacts/ui-shell-design/skills-1280x720.png) | [圖](verification/artifacts/ui-shell-design/skills-844x390.png) | [圖](verification/artifacts/ui-shell-design/skills-800x360.png) |
| 機緣 | [圖](verification/artifacts/ui-shell-design/fortune-1280x720.png) | [圖](verification/artifacts/ui-shell-design/fortune-844x390.png) | [圖](verification/artifacts/ui-shell-design/fortune-800x360.png) |
| 卷末 F-B | [圖](verification/artifacts/ui-shell-design/life-1280x720.png) | [圖](verification/artifacts/ui-shell-design/life-844x390.png) | [圖](verification/artifacts/ui-shell-design/life-800x360.png) |
| 卷末 F-C | [圖](verification/artifacts/ui-shell-design/life-fc-1280x720.png) | [圖](verification/artifacts/ui-shell-design/life-fc-844x390.png) | [圖](verification/artifacts/ui-shell-design/life-fc-800x360.png) |
| 長文＋異常 | [圖](verification/artifacts/ui-shell-design/life-long-error-1280x720.png) | [圖](verification/artifacts/ui-shell-design/life-long-error-844x390.png) | [圖](verification/artifacts/ui-shell-design/life-long-error-800x360.png) |

樣張僅繪製本輪涵蓋的群組分頁；正式版仍須完整保留canonical分頁、開放門檻與共用未開規則，不依樣張省略正式入口。

## 候選布局

推薦採同一個共用殼：洞府完整修行資訊；功能頁頂端精簡狀態列；四入口固定左下；群組分頁與 CloseSeal 固定在工作區頁首。精簡列常駐境界／層級、進度、壽元已用／上限、晉階位置及既有通知／訊息／設定。功未滿仍保留禁用動作；正式版須使用真實資格／材料 TIP，樣張不定新公式。時辰天候在短式收入詳情。

樣張分界候選為寬≥1100且高≥500用寬式，否則短式；實作時由共用解析器依可用空間決定，不能把此 HTML 斷點當作已核定的新 Godot 常數。

| 場景 | 寬式 | 短式 | 收起／恢復 |
| --- | --- | --- | --- |
| 洞府 | 左側完整修行、庫存；中央歷程按偏好顯示 | 左側修行與庫存三態入口；詳細庫存用閱讀抽屜，保留世界可見區 | 開玩法頁不改洞府庫存及訊息偏好 |
| 建築／製造 | 庫存左欄＋雙欄卡片 | 資源摘要／44px資源入口＋單欄卡片 | 本頁收起不被tick重開；換route重新套政策 |
| 技能 | 點數固定在頁內，卡內費用與研習 | 同語義；圖縮80，單欄 | 不自動展開全部物資 |
| 機緣 | 題圖／敘事與選項分欄 | 題圖64，選項內捲；成本／選擇同卡 | 關閉暫收原pending的正式契約由UI-SHELL-0核對 |
| 卷末 | 命燈與世次摘要左欄，小傳／留痕右側閱讀 | 世次摘要短列；題名與判詞先讀，小傳／留痕內捲 | 底部持有／當次所得、保留重置、轉世預覽固定 |

建築此次比較採完整工作區，沒有另交 `world_rail` 右欄變體。候選建議在本輪範圍內先選工作區；若使用者希望寬式保留可操作世界，另補同殼右欄樣張後再核定該配置。洞府背景只用既有島體及居所展示層次，不代表重新驗收世界構圖或地標擺位。

## 資源、訊息與異常比較

| 狀態 | 應見資訊 | 樣張操作 |
| --- | --- | --- |
| 洞府資源關閉→建築 | 建築自帶祖島可用材料；洞府仍記關閉 | 洞府點關閉→經營→資源→關閉→回洞府 |
| 寬式欄收起 | 工作區擴展、資源入口保留 | 左欄收起→資源開覆層；換頁採新政策 |
| 短式資源 | 抽屜覆蓋工作頁，後方付款停用 | [800資源層](verification/artifacts/ui-shell-design/resource-drawer-800x360.png) |
| 洞府中央訊息開 | 只在洞府中央出現 | 收起後進功能頁，不留中央長文 |
| 功能頁主動讀訊息 | 閱讀覆層；不擠壓卡片寬度 | 關閉回原route；[訊息與保存異常](verification/artifacts/ui-shell-design/message-overlay-error-800x360.png) |
| 頁內操作結果 | 原頁回饋位置 | 樣張研習／選擇只顯位置提示，不付款、不發獎 |
| 保存失敗 | 工作頁外固定異常列，持續到重試／處置 | 設定可切換異常範例；樣張重試只移除範例banner |
| 壽盡／提前／在世 | 精簡HUD與摘要一致，只有壽盡寫壽盡 | [提前](verification/artifacts/ui-shell-design/life-early-800x360.png)、[在世](verification/artifacts/ui-shell-design/life-living-800x360.png) |

工具最多一層、關閉回原頁；Escape關最上層可取消對象，樣張有基本鍵盤焦點圈限。**保存重試、成本刷新、草稿／捲動保留、確認取消、演出保護及fallback路由仍須正式Godot驗收**；樣張簡化轉世為示意確認層，不能當成原頁內確認流程已改。尺寸切換工具會重新載入樣張，測試另直接resize確認route意圖未變。資料tick、真正命令、離線報告及保存後端未接入。

## 字體與同文比較

使用同一虛構fixture：築屋、開拓青木／玄礦、結丹三類事實，題名「雲外初行」，小傳40字（不含標點），長版加同一段原創敘述。這些數字與故事不是玩家紀錄或已通過自然進程的證據。機緣亦為原創設計情境，不冒充正式事件定義。

| 角色 | F-B | F-C |
| --- | --- | --- |
| 題名 | 思源黑體600 | Noto Serif TC 800（本次核定加粗） |
| 小傳 | 思源黑體400 | 霞鶩文楷TC |
| 判詞 | 霞鶩文楷TC | 霞鶩文楷TC |
| 資源／數字／控制／分頁 | 思源黑體 | 思源黑體 |

推薦 **F-C僅用於卷末敘事角色**，讓小傳與操作區形成閱讀差別；若希望長段延續現有密集介面的閱讀感，選F-B。短式正文18、題名22、判詞20；其他正文16，Dock18；寬式小傳20、題名26、判詞22。這些是候選度量；正式實作仍需Godot TextServer／缺字／容器驗證與共用UiTypography角色，不能從樣張CSS直接推定正式字寬。沒有新增或下載字檔。

800×360＋長文＋保存異常同時存在時，題名／判詞置於同一閱讀起始行，小傳往下捲；不能縮字或把保存錯誤變成短暫toast。生命摘要與收益不隨故事捲動。

## 選文條件草案

以下10個候選題名用於 `ATM-LIFE-DESIGN` 的選文討論。只讀**同一世已提交事實**；不從庫存量、跨世highest_era或HUD訊息推定。穩定依最高優先可用題名，前6按表序、7–9僅前6不成立時採用，最後中性回退；重開不抽RNG。尚未新增正式選文程式或里程碑。

| 優先 | 題名 | 必要事實／允許的敘述 |
| --- | --- | --- |
| 1 | 雲外初行 | 本世首次建屋＋青木／玄礦均開拓＋首次結丹；可用本輪小傳 |
| 2 | 劫後續途 | 有本世正式渡劫失敗結果，且其後仍有已提交修行里程碑；不稱成功渡劫 |
| 3 | 丹成有記 | 本世有首次結丹事實；不宣稱最終仍在金丹 |
| 4 | 雲路相連 | 本世至少兩個不同島開拓及一條首次實際到貨事實；不把設定航線當到貨 |
| 5 | 同行一程 | 本世靈獸取得及成熟事實；跨世獸魂不足以成立 |
| 6 | 山門留跡 | 本世入宗與委託完成事實；只有派遣不可寫已歸 |
| 7 | 草木成居 | 本世首次建屋＋一項其他建設完成事實 |
| 8 | 一屋初築 | 本世首次建屋事實；不補造島嶼／人際故事 |
| 9 | 靜修有痕 | 本世至少一項已提交修行里程碑；文字只述已知里程碑 |
| 10 | 此世行跡 | 無足夠事件或覆蓋不完整；明示「未有完整紀錄」，不寫「一生無事」 |

題名不決定壽終、提前轉世或在世；此三種視角由真實生命狀態另選。最多三件留痕，去重後不足三件即少顯；不補假事件。第一版不提供空帳目、空抉擇頁籤；待相關資料與保存契約完成再接。歷世保存數量未在本輪決定。

## 決策與後續

字體已由使用者選定F-C。仍待確認：① 共用殼布局是否採用（含建築寬式工作區、短式洞府庫存入口）；② 題名／小傳條件是否需調整。字體選擇不等於全部布局或美術接受。

選定後下一個獨立任務為 `UI-SHELL-0`：整理純政策／狀態、單一visibility責任與canonical路由恢復，盤點原機緣pending／時間規則。接著 `UI-SHELL-1` 共用外框與一個工作頁，再 `UI-SHELL-2` 全route遷移。小傳事實層仍沿docs27後接；本輪不展開大型實作。

來源、命令、初次失敗及最終證據見 [驗收紀錄](verification/ui-shell-design.md)。
