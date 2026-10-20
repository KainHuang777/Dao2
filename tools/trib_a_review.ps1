$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$tribReview = Join-Path $PSScriptRoot '../docs/verification/artifacts/trib-a'
$tribQa = Get-Content (Join-Path $tribReview 'qa.json') -Raw | ConvertFrom-Json
$tribFont = New-Object System.Drawing.Font('Microsoft JhengHei', 18)
function Add-TribLabels($source, $destination, $labels, $columns, $cellWidth, $cellHeight) {
    $bitmap = [System.Drawing.Bitmap]::FromFile((Join-Path $tribReview $source))
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    for ($i = 0; $i -lt $labels.Count; $i++) {
        $x = ($i % $columns) * $cellWidth
        $y = [math]::Floor($i / $columns) * $cellHeight
        $graphics.FillRectangle([System.Drawing.Brushes]::Black, $x, $y, $cellWidth, 32)
        $graphics.DrawString($labels[$i], $tribFont, [System.Drawing.Brushes]::White, ($x + 8), ($y + 2))
    }
    $bitmap.Save((Join-Path $tribReview $destination), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}
$tribStoryboard = Get-Content (Join-Path $PSScriptRoot '../assets/tribulation/trib-a/storyboard.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Add-TribLabels 'six-keyframes.png' 'six-keyframes-labeled.png' @($tribStoryboard.labels) 2 960 540
foreach ($bg in @('black', 'gray', 'white')) {
    Add-TribLabels "layers-$bg.png" "layers-$bg-labeled.png" @($tribQa.transparent_order) 4 400 320
}
$tribFont.Dispose()
Write-Output 'PASS: six-keyframe and black/gray/white labeled review sheets'
