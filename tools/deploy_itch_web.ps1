<# Push is a fresh verified build + butler upload; Login and Browser are explicit alternatives. #>
param(
    [ValidateSet('Prepare','Browser','Push','Verify','Login')][string]$Action = 'Push',
    [string]$Version = '',
    [string]$ButlerPath = '',
    [switch]$ReuseExport,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$daoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Set-Location -LiteralPath $daoRoot
$daoZip = Join-Path $daoRoot 'build/dao2-itch-web.zip'
$daoTarget = 'kainhuang/dao-ascendant:html5'
$daoEditor = 'https://itch.io/game/edit/5261584'
if ($Action -in @('Push','Login')) {
    if (-not $ButlerPath) {
        $daoLocalButler = Join-Path $daoRoot 'build/tools/butler/butler.exe'
        if (Test-Path -LiteralPath $daoLocalButler -PathType Leaf) { $ButlerPath = $daoLocalButler }
        else {
            $daoCommand = Get-Command butler -ErrorAction SilentlyContinue
            if ($daoCommand) { $ButlerPath = $daoCommand.Source }
        }
    }
    if (-not $ButlerPath -or -not (Test-Path -LiteralPath $ButlerPath -PathType Leaf)) {
        throw 'Run tools/setup_itch_butler.ps1, then -Action Login once, or use -Action Browser.'
    }
    if ($Action -eq 'Login') {
        & $ButlerPath login
        if ($LASTEXITCODE -ne 0) { throw 'butler login did not complete.' }
        exit 0
    }
}
if ($Action -eq 'Verify') {
    & python tools/itch_web_package.py verify --zip $daoZip
    if ($LASTEXITCODE -ne 0) { throw 'Package verification failed.' }
    exit 0
}
$daoPrepareArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'package_itch_web.ps1'))
if ($Version) { $daoPrepareArgs += @('-Version', $Version) }
if ($ReuseExport) { $daoPrepareArgs += '-ReuseExport' }
& powershell.exe @daoPrepareArgs
if ($LASTEXITCODE -ne 0) { throw 'Preparation failed. Nothing was uploaded.' }
$daoManifest = Get-Content -LiteralPath ([IO.Path]::ChangeExtension($daoZip, '.manifest.json')) -Raw -Encoding UTF8 | ConvertFrom-Json
if ($Action -eq 'Push') {
    Write-Host "[TARGET] $daoTarget; version=$($daoManifest.version)"
    $daoPushArgs = @('push', $daoZip, $daoTarget, '--userversion', $daoManifest.version)
    if ($DryRun) { $daoPushArgs += '--dry-run' }
    & $ButlerPath @daoPushArgs
    if ($LASTEXITCODE -ne 0) { throw 'butler push failed. Retry with -ReuseExport after fixing the connection/login.' }
    if ($DryRun) { Write-Host '[DRY RUN] No build was uploaded.' }
    else { Write-Host '[UPLOAD] butler completed. Check processing and launch in the itch.io editor.' }
} elseif ($Action -eq 'Browser') {
    Write-Host "[UPLOAD] Select $daoZip at $daoEditor"
    Write-Host '[UPLOAD] Enable This file will be played in the browser, Save, then test View page.'
    if (-not $DryRun) { Start-Process $daoEditor -WindowStyle Hidden }
}
Write-Host '[NOTE] Visibility is unchanged. If the project is Public, uploads update the public build.'
