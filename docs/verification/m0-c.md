# M0-C：Amount 與 RNG 相容探針

狀態：DONE（有明確支援邊界）  
日期：2026-09-14  
來源：唯讀 `E:\Python\test1` v0.46.6；Decimal SHA-256 為 `F2BBE00B98FBFCED35CBBD62BA013B159B7FF02789C9A1A9AC5CDE2B10808753`。

## 交付

- `src/domain/amount_compat.gd`：sign/layer/mag 的大數模型、格式解析、比較、加減乘除、冪、log10、floor、clamp。
- `src/domain/seeded_random_compat.gd`：舊版 xfnv1a UTF-16 雜湊與 Mulberry32，含 state 還原、整數範圍、trial、weighted、fork。
- `tests/fixtures/legacy/m0-c-v1.json`：舊版抽出的 Amount 與 RNG 黃金資料，包含 `ee20`、`eee20`、負指數、非法輸入與 BMP 外字元 `𠮷`。
- `tests/m0c_compat_v3_runner.gd`：Godot headless 契約測試。

## 驗收

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m0c_compat_v3_runner.gd
& 'E:\Python\test1\node_modules\.bin\vitest.cmd' run --root 'E:\WORK\Dao2' --reporter verbose 'tests/fixtures/legacy/m0b_reference.test.ts'
```

2026-09-14 實測：Godot 4.7.2 import 成功，M0-C runner 輸出 `PASS: M0-C AmountCompat canonical contract and SeededRandomCompat match the fixture.`；M0-B legacy reference test 1 passed。

## 支援邊界

`SeededRandomCompat` 的 state 與上述所有抽樣結果逐值相容。`AmountCompat` 保存 legacy 的 sign/layer/mag 結構，並驗證 layer 0 至 3 的解析、比較與一層運算；layer 大於 1 的複雜四則運算、tetration、slog、Gamma 等 `break_eternity` 全 API 尚未移植。

Godot 與 JavaScript 對 IEEE-754 顯示尾數不同：例如 legacy `1.5e100` 顯示 `1.5000000000000004e100`，Godot canonical 字串顯示 `1.5e100`；數值 components 一致。`m0-c-v3.json` 固定 Godot 的 canonical 序列化，舊版原字串仍保留在 v1，尚不能聲稱任意舊存檔的 byte-for-byte 文字相容。

M0-C 只提供下一個核心切片可用的 Amount/RNG 邊界，不能作為完整 legacy save importer 的完成證據。M1-E 必須先決定是否擴充 Decimal API 或採用受控遷移格式。
