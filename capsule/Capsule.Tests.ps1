[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$refresh = Join-Path $PSScriptRoot 'Refresh-Capsule.ps1'
$verify = Join-Path $PSScriptRoot 'Verify-Capsule.ps1'
$bootstrap = Join-Path $PSScriptRoot 'Bootstrap-Capsule.ps1'
$backup = Join-Path $repoRoot 'recovery\Backup-AgentWorkspace.ps1'
if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
    $backup = Join-Path $repoRoot 'tools\Backup-AgentWorkspace.ps1'
}

foreach ($required in @($refresh, $verify, $bootstrap, $backup)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required script is missing: $required"
    }
}

$testRoot = Join-Path $env:TEMP ('capsule-test-' + [Guid]::NewGuid().ToString('N'))
try {
    $projectsRoot = Join-Path $testRoot 'source\projects'
    $projectDataRoot = Join-Path $testRoot 'source\Data\Projects'
    $backupRoot = Join-Path $testRoot 'source\Agent Backups\Workspace'
    $capsuleRoot = Join-Path $testRoot 'Capsule'
    $restoreRoot = Join-Path $testRoot 'restored-user'
    $project = Join-Path $projectsRoot 'sample-project'
    $bareRemote = Join-Path $testRoot 'remote.git'

    New-Item -ItemType Directory -Path $project, (Join-Path $projectDataRoot 'sample-project') -Force | Out-Null
    git init --bare $bareRemote | Out-Null
    git -C $project init | Out-Null
    git -C $project config user.email 'capsule-test@example.invalid'
    git -C $project config user.name 'Capsule Test'
    [System.IO.File]::WriteAllText((Join-Path $project 'README.md'), "# sample-project`n")
    git -C $project add README.md
    git -C $project commit -m 'fixture' | Out-Null
    git -C $project remote add origin $bareRemote
    git -C $project push -u origin HEAD | Out-Null
    [System.IO.File]::WriteAllText(
        (Join-Path $projectDataRoot 'sample-project\portable.txt'),
        "portable application data`n"
    )
    [System.IO.File]::WriteAllText(
        (Join-Path $projectDataRoot 'sample-project\Screenshot 4.32.21 PM.txt'),
        "unicode path`n"
    )
    New-Item -ItemType Directory -Path (Join-Path $project '.agents\tools') -Force | Out-Null
    [System.IO.File]::WriteAllText(
        (Join-Path $project '.agents\tools\credential-command-policy.json'),
        "{`"schemaVersion`":2,`"commands`":[]}`n"
    )

    & $backup `
        -ProjectsRoot $projectsRoot `
        -ProjectDataRoot $projectDataRoot `
        -BackupRoot $backupRoot `
        -ProductConfig @{} `
        -SQLiteSources @() `
        -SnapshotName 'test-snapshot' `
        -SkipQuickAccess | Out-Null

    $offlineBundle = Join-Path $backupRoot 'Snapshots\test-snapshot\Handoffs\sample-project\Repository.bundle'
    if (-not (Test-Path -LiteralPath $offlineBundle -PathType Leaf)) {
        throw 'Remote-backed repositories must also receive an offline recovery bundle.'
    }

    & $refresh `
        -CapsuleRoot $capsuleRoot `
        -SnapshotRoot (Join-Path $backupRoot 'Snapshots\test-snapshot') `
        -HarnessRepository $project `
        -AccountMapPath (Join-Path $PSScriptRoot 'templates\accounts.template.json') | Out-Null

    & $verify -CapsuleRoot $capsuleRoot | Out-Null

    $remoteName = $bareRemote + '.offline'
    Move-Item -LiteralPath $bareRemote -Destination $remoteName
    & $bootstrap `
        -CapsuleRoot $capsuleRoot `
        -UserRoot $restoreRoot `
        -SkipPackageInstall `
        -SkipAccountLogin `
        -SkipQuickAccess | Out-Null

    $restoredProject = Join-Path $restoreRoot 'projects\sample-project'
    if (-not (Test-Path -LiteralPath (Join-Path $restoredProject 'README.md') -PathType Leaf)) {
        throw 'Bootstrap did not restore the project from its offline bundle.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $restoreRoot 'Data\Projects\sample-project\portable.txt') -PathType Leaf)) {
        throw 'Bootstrap did not restore portable project application data.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $restoreRoot 'Data\Projects\sample-project\Screenshot 4.32.21 PM.txt') -PathType Leaf)) {
        throw 'Bootstrap did not restore a UTF-8 project-data filename.'
    }

    $approvedMetadataFiles = @(
        'credential-command-allowlist.json',
        'credential-command-policy.json',
        'bws-command-allowlist.json'
    )
    $secretLikeFiles = @(Get-ChildItem -LiteralPath $capsuleRoot -File -Recurse -Force | Where-Object {
        $_.Name -notin $approvedMetadataFiles -and
        $_.Name -match '^(?i)\.env($|\.)|credential|token|password|passcode|recovery.?key|cookies?$'
    })
    if ($secretLikeFiles.Count) {
        throw 'Capsule contains a forbidden secret-like filename.'
    }

    [pscustomobject]@{
        Result = 'PASS'
        OfflineProjectRestore = $true
        PortableDataRestore = $true
        CapsuleVerification = $true
    }
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolved = (Resolve-Path -LiteralPath $testRoot).Path
        if ($resolved.StartsWith([System.IO.Path]::GetTempPath(), [StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}
