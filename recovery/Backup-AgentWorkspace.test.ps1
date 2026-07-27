$ErrorActionPreference = 'Stop'

$runner = Join-Path $PSScriptRoot 'Backup-AgentWorkspace.ps1'
$root = Join-Path $env:TEMP ("agent-backup-test-" + [Guid]::NewGuid().ToString('N'))
$projects = Join-Path $root 'projects'
$data = Join-Path $root 'Data\Projects'
$product = Join-Path $root '.cursor'
$destination = Join-Path $root 'backup'
$project = Join-Path $projects 'sample'
$remote = Join-Path $root 'remote.git'

try {
    New-Item -ItemType Directory -Path $project, (Join-Path $data 'sample\inputs'), $product -Force | Out-Null
    git init --bare $remote | Out-Null
    git -C $project init | Out-Null
    git -C $project config user.name 'Backup Test'
    git -C $project config user.email 'backup-test@example.invalid'
    [System.IO.File]::WriteAllText((Join-Path $project 'README.md'), "# sample`n")
    git -C $project add README.md
    git -C $project commit -m 'sample' | Out-Null
    git -C $project remote add origin $remote
    git -C $project push -u origin HEAD:master | Out-Null

    [System.IO.File]::WriteAllText((Join-Path $data 'sample\inputs\ordinary.txt'), 'portable-data')
    [System.IO.File]::WriteAllText((Join-Path $data 'sample\.env'), 'MUST_NOT_COPY')
    [System.IO.File]::WriteAllText((Join-Path $product 'settings.json'), '{"safe":true}')

    $result = & $runner `
        -ProjectsRoot $projects `
        -ProjectDataRoot $data `
        -BackupRoot $destination `
        -ProductConfig @{ cursor = @((Join-Path $product 'settings.json')) } `
        -SnapshotName 'test-snapshot' `
        -SkipQuickAccess

    $snapshot = [string]$result.SnapshotRoot
    $manifest = Get-Content -LiteralPath (Join-Path $snapshot 'Recovery\project-recovery.json') -Raw | ConvertFrom-Json
    if (@($manifest.projects).Count -ne 1) { throw 'Repository recovery manifest is incomplete.' }
    if ($manifest.projects[0].remote -ne $remote) { throw 'Repository authority was not recorded.' }
    if (-not (Test-Path -LiteralPath (Join-Path $snapshot 'Application Data\Projects\sample\inputs\ordinary.txt'))) {
        throw 'Approved application data was not copied.'
    }
    if (Test-Path -LiteralPath (Join-Path $snapshot 'Application Data\Projects\sample\.env')) {
        throw 'A forbidden environment file entered Agent Backups.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $snapshot 'Product Configuration\cursor\settings.json'))) {
        throw 'Selected value-safe product configuration was not copied.'
    }

    'Agent workspace backup regression test passed.'
}
finally {
    if (Test-Path -LiteralPath $root) {
        Remove-Item -LiteralPath $root -Recurse -Force
    }
}
