$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$reviewRoot = Join-Path $PSScriptRoot '../docs/verification/artifacts/uix-r7-f5a'
$font = New-Object System.Drawing.Font('Microsoft JhengHei', 22)
$brush = [System.Drawing.Brushes]::White
function Add-ReviewLabels($source, $target, $labels, $cols, $cell) {
    $bitmap = [System.Drawing.Bitmap]::FromFile((Join-Path $reviewRoot $source))
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    for ($i = 0; $i -lt $labels.Count; $i++) {
        $x = ($i % $cols) * $cell
        $y = [math]::Floor($i / $cols) * $cell
        $graphics.FillRectangle([System.Drawing.Brushes]::Black, $x, $y, $cell, 44)
        $graphics.DrawString($labels[$i], $font, $brush, ($x + 12), ($y + 6))
    }
    $bitmap.Save((Join-Path $reviewRoot $target), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}
Add-ReviewLabels 'layers-contact.png' 'layers-labeled.png' @('01 後霧', '02 旋轉盤面', '03 固定外殼', '04 掛飾', '05 蓮花', '06 花瓣發光遮罩', '07 往生流光', '08 左前霧', '09 右前霧') 3 512
Add-ReviewLabels 'four-angles.png' 'four-angles-labeled.png' @('0°', '90° 順時針', '180°', '270° 順時針') 2 1024
Add-ReviewLabels 'four-angles-bare.png' 'four-angles-bare-labeled.png' @('0° 裸盤', '90° 裸盤', '180° 裸盤', '270° 裸盤') 2 1024
$font.Dispose()
Write-Output 'PASS: labeled layer and four-angle review sheets'
