param([switch]$ExportWeb)
$ErrorActionPreference='Stop'
$daoRoot=Split-Path $PSScriptRoot -Parent
Set-Location $daoRoot
$daoEvidence=Join-Path $daoRoot 'docs/verification/artifacts/trib-b'
$daoStage=Join-Path $daoRoot 'build/trib-b-project'
$env:APPDATA=Join-Path $daoRoot 'build/trib-b-user'
New-Item -ItemType Directory -Force $daoEvidence,$daoStage,$env:APPDATA | Out-Null
Get-ChildItem -LiteralPath 'src/verification/tribb' -File | Where-Object Name -ne '.gdignore' | Copy-Item -Destination $daoStage -Force
foreach($daoFolder in @('assets/tribulation/trib-a','assets/fonts/runtime','assets/abode/fx3art1')) {
 $daoTarget=Join-Path $daoStage $daoFolder
 New-Item -ItemType Directory -Force $daoTarget | Out-Null
 if($daoFolder -eq 'assets/fonts/runtime') { Copy-Item "$daoFolder/Dao2Sans-VF.ttf" $daoTarget -Force }
 elseif($daoFolder -eq 'assets/abode/fx3art1') { Copy-Item "$daoFolder/terrain.png" $daoTarget -Force }
 else { Copy-Item "$daoFolder/*.png" $daoTarget -Force }
}
Copy-Item 'assets/fonts/SourceHanSans-LICENSE.txt' (Join-Path $daoStage 'assets/fonts') -Force
$daoEngine=Join-Path $daoRoot 'tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path $daoStage --import --log-file "$daoEvidence/import.log"
if($LASTEXITCODE -ne 0 -or (Select-String "$daoEvidence/import.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) { throw 'TRIB-B import failed; inspect log' }
Get-ChildItem -LiteralPath $daoStage -Filter '*.uid' -File | Copy-Item -Destination 'src/verification/tribb' -Force
if($ExportWeb) {
 New-Item -ItemType Directory -Force 'build/web-trib-b' | Out-Null
 & $daoEngine --headless --path $daoStage --export-release Web "$daoRoot/build/web-trib-b/index.html" --log-file "$daoEvidence/export.log"
 if($LASTEXITCODE -ne 0 -or (Select-String "$daoEvidence/export.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) { throw 'TRIB-B export failed; inspect log' }
}
