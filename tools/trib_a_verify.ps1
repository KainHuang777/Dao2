$ErrorActionPreference = 'Stop'
$tribRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tribAssets = Join-Path $tribRoot 'assets/tribulation/trib-a'
$tribEvidence = Join-Path $tribRoot 'docs/verification/artifacts/trib-a'
$tribManifest = Get-Content (Join-Path $tribAssets 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tribPrompts = Get-Content (Join-Path $tribAssets 'generation-prompts.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tribRecords = Get-Content (Join-Path $tribEvidence 'generation-records.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tribQa = Get-Content (Join-Path $tribEvidence 'qa.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tribChecks = 0
function Assert-Trib($condition, $message) {
    if (-not $condition) { throw $message }
    $script:tribChecks++
}
Assert-Trib ($tribManifest.assets.Count -eq 22) 'Asset count'
Assert-Trib (@($tribRecords.PSObject.Properties).Count -eq 16) 'Generation record count'
Assert-Trib ($tribQa.failures.Count -eq 0) 'Offline QA failed'
Assert-Trib ($tribQa.samples.Count -eq 18) 'Storyboard sample count'
foreach ($entry in $tribManifest.assets) {
    $path = Join-Path $tribAssets $entry.file
    $source = Join-Path $tribRoot $entry.source
    Assert-Trib (Test-Path -LiteralPath $path) "Missing $path"
    Assert-Trib ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $entry.sha256) "Pack hash $path"
    Assert-Trib ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -eq $entry.source_sha256) "Source hash $source"
    Assert-Trib (Test-Path -LiteralPath "$path.import") "Missing engine import $path"
    if ($entry.prompt_id) {
        Assert-Trib ($null -ne $tribPrompts.PSObject.Properties[$entry.prompt_id]) "Prompt $($entry.id)"
    }
}
foreach ($record in $tribRecords.PSObject.Properties) {
    Assert-Trib (Test-Path -LiteralPath (Join-Path $tribEvidence "originals/$($record.Name).png")) "Original $($record.Name)"
    Assert-Trib ($null -ne $tribPrompts.PSObject.Properties[$record.Name]) "Original prompt $($record.Name)"
}
$tribTextFiles = @(
    'README.md', 'ROADMAP.md', 'docs/ai-handoff.md', 'docs/development-status.md', 'updata.txt',
    'docs/24-tribulation-and-world-vfx-plan.md', 'docs/verification/trib-a.md',
    'tools/trib_a_assets.gd', 'tools/trib_a_inspect.gd', 'tools/trib_a_texture_check.gd', 'tools/trib_a_review.ps1', 'tools/trib_a_verify.ps1',
    'assets/tribulation/trib-a/README.md', 'assets/tribulation/trib-a/manifest.json',
    'assets/tribulation/trib-a/generation-prompts.json', 'assets/tribulation/trib-a/storyboard.json'
)
$tribUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
foreach ($relative in $tribTextFiles) {
    $null = $tribUtf8.GetString([System.IO.File]::ReadAllBytes((Join-Path $tribRoot $relative)))
    Assert-Trib $true "UTF8 $relative"
}
$tribJson = @{ task = 'TRIB-A'; checks = $tribChecks; assets = 22; originals = 16; utf8Files = $tribTextFiles.Count; failures = @() }
[System.IO.File]::WriteAllText((Join-Path $tribEvidence 'file-checks.json'), ($tribJson | ConvertTo-Json -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "PASS: $tribChecks file/hash/prompt/UTF8 checks, 22 assets, 16 originals"
