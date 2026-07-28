[CmdletBinding()]
param(
    [string]$CapsuleRoot
)

$ErrorActionPreference = 'Stop'
if (-not $CapsuleRoot) {
    $CapsuleRoot = Split-Path -Parent $PSScriptRoot
}
$integrityPath = Join-Path $CapsuleRoot 'manifests\integrity.json'
$pointerPath = Join-Path $CapsuleRoot 'manifests\capsule.json'
foreach ($required in @(
    (Join-Path $CapsuleRoot 'START-HERE.md'),
    (Join-Path $CapsuleRoot 'SYSTEM-MAP.md'),
    (Join-Path $CapsuleRoot 'SECRETS-BITWARDEN.md'),
    $integrityPath,
    $pointerPath,
    (Join-Path $CapsuleRoot 'tools\Bootstrap-Capsule.ps1'),
    (Join-Path $CapsuleRoot 'tools\Restore-AgentWorkspace.ps1')
)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Capsule file is missing: $required"
    }
}

$integrity = Get-Content -LiteralPath $integrityPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($record in @($integrity.files)) {
    $path = Join-Path $CapsuleRoot ([string]$record.path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Integrity file is missing: $($record.path)"
    }
    $file = Get-Item -LiteralPath $path
    if ($file.Length -ne [long]$record.bytes) {
        throw "Integrity size mismatch: $($record.path)"
    }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne [string]$record.sha256) {
        throw "Integrity hash mismatch: $($record.path)"
    }
}

$pointer = Get-Content -LiteralPath $pointerPath -Raw -Encoding UTF8 | ConvertFrom-Json
$snapshot = Join-Path $CapsuleRoot ([string]$pointer.workspaceRelativePath)
if (-not (Test-Path -LiteralPath (Join-Path $snapshot 'Recovery\project-recovery.json') -PathType Leaf)) {
    throw 'Capsule workspace recovery manifest is unavailable.'
}

[pscustomobject]@{
    Result = 'PASS'
    CapsuleRoot = $CapsuleRoot
    VerifiedFiles = @($integrity.files).Count
    SnapshotName = [string]$pointer.snapshotName
}
