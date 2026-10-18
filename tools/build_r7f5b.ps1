param([switch]$ExportWeb,[ValidatePattern('^[a-z0-9-]+$')][string]$EvidenceName='uix-r7-f5b-f1')
$ErrorActionPreference='Stop'
$daoRoot=Split-Path $PSScriptRoot -Parent
Set-Location $daoRoot
$daoEvidence=Join-Path $daoRoot "docs/verification/artifacts/$EvidenceName"
New-Item -ItemType Directory -Force $daoEvidence | Out-Null
$env:APPDATA=Join-Path $daoRoot 'build/r7f5b-user'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$daoStage=Join-Path $daoRoot 'build/r7f5b-project'
New-Item -ItemType Directory -Force $daoStage | Out-Null
Get-ChildItem -Path 'src/verification/r7f5b' -File | Where-Object { $_.Name -ne '.gdignore' } | Copy-Item -Destination $daoStage -Force
foreach($daoFolder in @('assets/ui/reincarnation-layered-f5a','assets/ui/reincarnation-layered-f5b-f1','assets/fonts/reincarnation-f5b','assets/fonts/runtime')) {
  $daoTarget=Join-Path $daoStage $daoFolder
  New-Item -ItemType Directory -Force $daoTarget | Out-Null
  if($daoFolder -eq 'assets/fonts/runtime') {
    Copy-Item 'assets/fonts/runtime/Dao2Sans-VF.ttf' $daoTarget -Force
  } else {
    Copy-Item -Path "$daoFolder/*" -Destination $daoTarget -Force
  }
}
Copy-Item 'assets/fonts/SourceHanSans-LICENSE.txt' (Join-Path $daoStage 'assets/fonts') -Force
$daoEngine=Join-Path $daoRoot 'tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path $daoStage --import --log-file "$daoEvidence/import.log"
if($LASTEXITCODE -ne 0) { throw 'F5-B import failed' }
if(Select-String -Path "$daoEvidence/import.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'F5-B import contains errors' }
if($ExportWeb) {
  New-Item -ItemType Directory -Force build/web-r7-f5b | Out-Null
  & $daoEngine --headless --path $daoStage --export-release Web "$daoRoot/build/web-r7-f5b/index.html" --log-file "$daoEvidence/export.log"
  if($LASTEXITCODE -ne 0) { throw 'F5-B isolated export failed' }
  if(Select-String -Path "$daoEvidence/export.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'F5-B export contains errors' }
}
