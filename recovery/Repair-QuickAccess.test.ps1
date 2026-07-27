$ErrorActionPreference = 'Stop'

$repair = Join-Path $PSScriptRoot 'Repair-QuickAccess.ps1'
$root = Join-Path $env:TEMP ("quick-access-test-" + [Guid]::NewGuid().ToString('N'))
$manifest = Join-Path $root 'quick-access.json'
$userRoot = Join-Path $root 'Douglas'

try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $data = [ordered]@{
        schemaVersion = 1
        pinnedFolders = @(
            '%USERPROFILE%\projects',
            '%GOOGLE_DRIVE_ROOT%\UC Berkeley',
            '%USERPROFILE%\OneDrive\Documents'
        )
    }
    [System.IO.File]::WriteAllText($manifest, ($data | ConvertTo-Json -Depth 4))
    $actions = @(& $repair -ManifestPath $manifest -UserRoot $userRoot -WhatIf)
    if ($actions.Count -ne 3) { throw 'Quick Access plan did not include every portable pin.' }
    if ($actions[0].Path -ne (Join-Path $userRoot 'projects')) { throw 'User profile pin expansion failed.' }
    if ($actions[1].Path -ne (Join-Path $userRoot 'Documents')) { throw 'Retired known-folder pin translation failed.' }
    if ($actions[2].Path -ne (Join-Path $userRoot 'My Drive\UC Berkeley')) { throw 'Google Drive pin expansion failed.' }
    if (@($actions | Where-Object Action -ne 'Pin').Count) { throw 'Quick Access dry run returned an unexpected action.' }
    'Quick Access repair regression test passed.'
}
finally {
    if (Test-Path -LiteralPath $root) {
        Remove-Item -LiteralPath $root -Recurse -Force
    }
}
