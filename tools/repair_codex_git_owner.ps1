# Scoped recovery for Codex sandbox initialization. No recursive ACL changes.
$ErrorActionPreference = 'Stop'
$taskTarget = 'E:\WORK\Dao2\.git'
$taskExpectedOwnerSid = 'S-1-5-21-3414281524-1333866162-4245884016-1003'
$taskUserSid = 'S-1-5-21-3414281524-1333866162-4245884016-1001'
$taskReport = 'E:\WORK\Dao2\docs\verification\terminal-owner-repair-result-2026-10-02.json'
try {
    $taskResolved = (Resolve-Path -LiteralPath $taskTarget).Path
    if ($taskResolved -ne $taskTarget) { throw 'Unexpected target path' }
    if ((Get-Item -LiteralPath $taskTarget -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse-point target refused' }
    $taskAclBefore = Get-Acl -LiteralPath $taskTarget
    $taskOwnerBefore = $taskAclBefore.GetOwner([Security.Principal.SecurityIdentifier]).Value
    if ($taskOwnerBefore -ne $taskExpectedOwnerSid) { throw "Unexpected owner: $taskOwnerBefore" }
    $taskDaclBefore = $taskAclBefore.GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access)
    & "$env:SystemRoot\System32\icacls.exe" $taskTarget /setowner "*$taskUserSid"
    if ($LASTEXITCODE -ne 0) { throw "icacls failed: $LASTEXITCODE" }
    $taskAclAfter = Get-Acl -LiteralPath $taskTarget
    $taskOwnerAfter = $taskAclAfter.GetOwner([Security.Principal.SecurityIdentifier]).Value
    $taskDaclAfter = $taskAclAfter.GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access)
    if ($taskOwnerAfter -ne $taskUserSid) { throw 'Owner verification failed' }
    if ($taskDaclAfter -ne $taskDaclBefore) { throw 'Unexpected DACL change; inspect backup before continuing' }
    @{ success = $true; target = $taskTarget; owner_before = $taskOwnerBefore; owner_after = $taskOwnerAfter; dacl_unchanged = $true; recursive = $false } | ConvertTo-Json | Set-Content -LiteralPath $taskReport -Encoding UTF8
    exit 0
} catch {
    @{ success = $false; target = $taskTarget; error = $_.Exception.Message } | ConvertTo-Json | Set-Content -LiteralPath $taskReport -Encoding UTF8
    exit 1
}
