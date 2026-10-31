<# Fresh isolated export + verified itch ZIP; no upload. #>
param(
    [string]$OutputDir = 'build',
    [string]$ZipName = 'dao2-itch-web.zip',
    [string]$EnginePath = 'tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe',
    [string]$Version = '',
    [switch]$ReuseExport,
    [switch]$ForceExport
)
$ErrorActionPreference = 'Stop'
$daoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Set-Location -LiteralPath $daoRoot
function Assert-Exit([string]$Step) {
    if ($LASTEXITCODE -ne 0) { throw "$Step failed (exit $LASTEXITCODE)." }
}
if ($ZipName -ne [IO.Path]::GetFileName($ZipName) -or $ZipName -notmatch '\.zip$') {
    throw 'ZipName must be a ZIP filename, without a directory.'
}
$daoBuild = [IO.Path]::GetFullPath((Join-Path $daoRoot 'build'))
$daoOutput = [IO.Path]::GetFullPath((Join-Path $daoRoot $OutputDir))
if ($daoOutput -ne $daoBuild -and -not $daoOutput.StartsWith($daoBuild + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDir must stay inside this project build directory.'
}
New-Item -ItemType Directory -Path $daoOutput -Force | Out-Null
$daoZip = Join-Path $daoOutput $ZipName
$daoEngine = [IO.Path]::GetFullPath((Join-Path $daoRoot $EnginePath))
if (-not (Test-Path -LiteralPath $daoEngine -PathType Leaf)) { throw "Godot not found: $daoEngine" }
$daoEngineVersion = (& $daoEngine --version | Out-String).Trim()
Assert-Exit 'Godot version check'
if ($daoEngineVersion -notmatch '^4\.7\.2\.') { throw "Expected Godot 4.7.2; found $daoEngineVersion" }
Write-Host "[ENGINE] $daoEngineVersion"
if ($ReuseExport -and -not $ForceExport) {
    & python tools/itch_web_package.py verify --zip $daoZip
    Assert-Exit 'Existing package/source verification'
    Write-Host "[READY] $daoZip (verified reuse)"
    exit 0
}
if (-not $Version) {
    $daoCommit = (& git rev-parse --short HEAD | Out-String).Trim()
    Assert-Exit 'Git version lookup'
    $Version = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $daoCommit
}
$daoFingerprint = (& python tools/itch_web_package.py fingerprint | Out-String).Trim()
Assert-Exit 'Source fingerprint'
$daoWeb = Join-Path $daoBuild 'itch-web'
$daoLogs = Join-Path $daoRoot ('.test-output/itch-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $daoWeb,$daoLogs -Force | Out-Null
$daoExportLog = Join-Path $daoLogs 'export.log'
$daoPreviousAppdata = $env:APPDATA
$daoPreviousErrors = $ErrorActionPreference
try {
    $env:APPDATA = Join-Path $daoLogs 'appdata'
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    # Native stderr is an ErrorRecord in Windows PowerShell; check exit and log below.
    $ErrorActionPreference = 'Continue'
    & $daoEngine --headless --path $daoRoot --export-release Web (Join-Path $daoWeb 'index.html') *> $daoExportLog
    $daoExportExit = $LASTEXITCODE
} finally {
    $env:APPDATA = $daoPreviousAppdata
    $ErrorActionPreference = $daoPreviousErrors
}
if ($daoExportExit -ne 0 -or (Select-String -LiteralPath $daoExportLog -Pattern 'SCRIPT ERROR:|Parse Error:|Failed to export' -Quiet)) {
    throw "Godot export failed. See $daoExportLog"
}
Write-Host "[EXPORT] PASS; log=$daoExportLog"
& node tools/prepare_web_compression.mjs $daoWeb > (Join-Path $daoLogs 'compression.json')
Assert-Exit 'Compression and BGM companions'
& python tools/itch_web_package.py pack --web-dir $daoWeb --zip $daoZip --version $Version --source-fingerprint $daoFingerprint
Assert-Exit 'itch.io package'
& python tools/itch_web_package.py verify --zip $daoZip
Assert-Exit 'Package/source verification'
& python tools/delivery_check.py --web $daoWeb
Assert-Exit 'Delivery check'
Write-Host "[READY] $daoZip"
Write-Host "[LOGS] $daoLogs"
