[CmdletBinding()]
param(
    [string]$CapsuleRoot = (Join-Path $env:USERPROFILE 'Documents\Capsule'),
    [string]$SnapshotRoot,
    [string]$HarnessRepository = (Join-Path $env:USERPROFILE 'projects\agent-harness'),
    [string]$AccountMapPath
)

$ErrorActionPreference = 'Stop'
if (-not $AccountMapPath) {
    $AccountMapPath = Join-Path $PSScriptRoot 'templates\accounts.template.json'
}

function Copy-Tree {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "Required source folder is unavailable: $Source"
    }
    Get-ChildItem -LiteralPath $Source -File -Recurse -Force | ForEach-Object {
        $relative = $_.FullName.Substring($Source.Length).TrimStart('\')
        $target = Join-Path $Destination $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $target
    }
}

function Assert-SafeFileName {
    param([string]$Path)
    $leaf = Split-Path -Leaf $Path
    if ($leaf -in @(
        'credential-command-allowlist.json',
        'credential-command-policy.json',
        'bws-command-allowlist.json'
    )) {
        return
    }
    if ($leaf -match '^(?i)\.env($|\.)|credential|token|password|passcode|recovery.?key|cookies?$') {
        throw "A forbidden secret-like filename was found: $Path"
    }
}

if (-not $SnapshotRoot) {
    $latestPath = Join-Path $env:USERPROFILE 'Documents\Agent Backups\Workspace\Recovery\latest.json'
    if (-not (Test-Path -LiteralPath $latestPath -PathType Leaf)) {
        throw "Latest Agent Backups pointer is unavailable: $latestPath"
    }
    $SnapshotRoot = [string]((Get-Content -LiteralPath $latestPath -Raw -Encoding UTF8 | ConvertFrom-Json).snapshotRoot)
}

$snapshotManifest = Join-Path $SnapshotRoot 'Recovery\project-recovery.json'
if (-not (Test-Path -LiteralPath $snapshotManifest -PathType Leaf)) {
    throw "The selected snapshot is incomplete: $SnapshotRoot"
}
if (-not (Test-Path -LiteralPath $AccountMapPath -PathType Leaf)) {
    throw "Account map is unavailable: $AccountMapPath"
}

$snapshotName = Split-Path -Leaf $SnapshotRoot
$payloadRoot = Join-Path $CapsuleRoot 'payload'
$workspaceTarget = Join-Path $payloadRoot ("workspace\" + $snapshotName)
if (Test-Path -LiteralPath $workspaceTarget) {
    throw "Capsule payload already exists: $workspaceTarget"
}

New-Item -ItemType Directory -Path $CapsuleRoot, (Join-Path $CapsuleRoot 'manifests'), (Join-Path $CapsuleRoot 'tools') -Force | Out-Null
Copy-Tree -Source $SnapshotRoot -Destination $workspaceTarget

foreach ($doc in @('START-HERE.md', 'SYSTEM-MAP.md', 'SECRETS-BITWARDEN.md')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $doc) -Destination (Join-Path $CapsuleRoot $doc)
}
foreach ($tool in @(
    'Bootstrap-Capsule.ps1',
    'Bootstrap-Capsule.cmd',
    'Verify-Capsule.ps1',
    'Verify-Capsule.cmd',
    'Set-CapsuleAccounts.ps1',
    'Set-CapsuleAccounts.cmd',
    'Refresh-Integrity.ps1',
    'Refresh-Integrity.cmd'
)) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $tool) -Destination (Join-Path $CapsuleRoot 'tools')
}
$recoveryRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'recovery'
if (-not (Test-Path -LiteralPath $recoveryRoot -PathType Container)) {
    $recoveryRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'tools'
}
foreach ($recoveryTool in @('Restore-AgentWorkspace.ps1', 'Repair-QuickAccess.ps1')) {
    Copy-Item -LiteralPath (Join-Path $recoveryRoot $recoveryTool) -Destination (Join-Path $CapsuleRoot 'tools')
}
Copy-Item -LiteralPath $AccountMapPath -Destination (Join-Path $CapsuleRoot 'manifests\accounts.json')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'templates\software.json') -Destination (Join-Path $CapsuleRoot 'manifests\software.json')

$harnessAgents = Join-Path $HarnessRepository '.agents'
if (Test-Path -LiteralPath $harnessAgents -PathType Container) {
    Copy-Tree -Source $harnessAgents -Destination (Join-Path $payloadRoot 'harness\.agents')
}

$pointer = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    snapshotName = $snapshotName
    workspaceRelativePath = "payload\workspace\$snapshotName"
    secretsAuthority = 'Bitwarden Password Manager Free'
}
[System.IO.File]::WriteAllText(
    (Join-Path $CapsuleRoot 'manifests\capsule.json'),
    ($pointer | ConvertTo-Json -Depth 5) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

Get-ChildItem -LiteralPath $CapsuleRoot -File -Recurse -Force | ForEach-Object {
    Assert-SafeFileName -Path $_.FullName
}

if (Get-Command gitleaks -ErrorAction SilentlyContinue) {
    & gitleaks dir --no-banner --redact --exit-code 1 $CapsuleRoot
    if ($LASTEXITCODE -ne 0) { throw 'Gitleaks blocked the Capsule.' }
}

$integrityPath = Join-Path $CapsuleRoot 'manifests\integrity.json'
$files = @(Get-ChildItem -LiteralPath $CapsuleRoot -File -Recurse -Force | Where-Object {
    $_.FullName -ne $integrityPath
} | Sort-Object FullName | ForEach-Object {
    [ordered]@{
        path = $_.FullName.Substring($CapsuleRoot.Length).TrimStart('\').Replace('\', '/')
        bytes = $_.Length
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
})
[System.IO.File]::WriteAllText(
    $integrityPath,
    (([ordered]@{
        schemaVersion = 1
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        files = $files
    }) | ConvertTo-Json -Depth 6) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

[pscustomobject]@{
    CapsuleRoot = $CapsuleRoot
    SnapshotName = $snapshotName
    Files = $files.Count + 1
}
