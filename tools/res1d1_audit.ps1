$ErrorActionPreference = 'Stop'
# Read-only DAO1 audit. All generated evidence stays in Dao2.
$daoRoot = Split-Path -Parent $PSScriptRoot
$daoLegacyRoot = 'E:\Python\test1'
$daoFixture = Get-Content -LiteralPath (Join-Path $daoRoot 'tests/fixtures/legacy/res1-a-source.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$daoSources = @($daoFixture.sources | Sort-Object path -Unique | ForEach-Object {
    $daoHash = (Get-FileHash -LiteralPath (Join-Path $daoLegacyRoot $_.path) -Algorithm SHA256).Hash.ToLower()
    [pscustomobject][ordered]@{path=$_.path; expected_sha256=$_.sha256; actual_sha256=$daoHash; matches=($daoHash -eq $_.sha256)}
})
$daoSkills = @(Import-Csv -LiteralPath (Join-Path $daoLegacyRoot 'src/data/skills.csv') -Encoding UTF8 | Where-Object id -In @('basic_meditation', 'foundation_building', 'golden_core_formation', 'nascent_soul_incubation'))
$daoSkillBuildings = @(Import-Csv -LiteralPath (Join-Path $daoLegacyRoot 'src/data/buildings.csv') -Encoding UTF8 | Where-Object id -In @('library', 'scripture_hall'))
$daoAudit = [ordered]@{
    audit_version='res1-d1-source-1'; date='2026-10-05'
    evidence='Read-only source/hash audit, not DAO1 runtime parity'
    sources=$daoSources; skills=$daoSkills; skill_buildings=$daoSkillBuildings
    era_requirements=$daoFixture.era_requirements; resources=$daoFixture.resources
    release_lingli_capacity=[ordered]@{base=100; storage_effect=100; global_level_cap=10; max=1100; era2_breakthrough_required=2000}
    proposal='tests/fixtures/res1d1/era3.json only; production files unchanged'
}
if ($daoSources.Count -ne 8 -or $daoSources.matches -contains $false) { throw 'Legacy source hash mismatch/count' }
if ($daoSkills.Count -ne 4 -or $daoSkillBuildings.Count -ne 2) { throw 'Legacy skill evidence incomplete' }
$daoAudit | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $daoRoot 'docs/verification/artifacts/res1-d1-source-audit.json') -Encoding utf8
Write-Output "PASS: RES1-D1 source audit $($daoSources.Count) hashes, $($daoSkills.Count) skills, $($daoSkillBuildings.Count) source buildings; no DAO1 writes."
