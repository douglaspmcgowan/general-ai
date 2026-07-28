[CmdletBinding()]
param(
    [string]$CapsuleRoot,
    [string]$UserRoot = $env:USERPROFILE,
    [switch]$SkipPackageInstall,
    [switch]$SkipAccountLogin,
    [switch]$SkipQuickAccess
)

$ErrorActionPreference = 'Stop'
if (-not $CapsuleRoot) {
    $CapsuleRoot = Split-Path -Parent $PSScriptRoot
}

& (Join-Path $CapsuleRoot 'tools\Verify-Capsule.ps1') -CapsuleRoot $CapsuleRoot | Out-Null

if (-not $SkipPackageInstall) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'Windows Package Manager is required. Install App Installer from Microsoft Store, then rerun.'
    }
    $software = Get-Content -LiteralPath (Join-Path $CapsuleRoot 'manifests\software.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($package in @($software.packages | Where-Object { $_.wingetId })) {
        & $winget.Source install --id ([string]$package.wingetId) --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw "Package installation failed: $($package.name)" }
    }
}

if (-not $SkipAccountLogin) {
    Write-Host ''
    Write-Host 'Sign in with the account identifiers in manifests\accounts.json:'
    Write-Host '1. Google Drive; wait for My Drive to finish its first sync.'
    Write-Host '2. Bitwarden; unlock the desktop app and CLI.'
    Write-Host '3. GitHub CLI: gh auth login.'
    Write-Host '4. Claude, Codex, and Cursor desktop applications.'
    Write-Host ''
    Read-Host 'Press Enter after the account sign-ins are complete'
}

$pointer = Get-Content -LiteralPath (Join-Path $CapsuleRoot 'manifests\capsule.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$snapshotRoot = Join-Path $CapsuleRoot ([string]$pointer.workspaceRelativePath)
& (Join-Path $CapsuleRoot 'tools\Restore-AgentWorkspace.ps1') `
    -BackupRoot $snapshotRoot `
    -UserRoot $UserRoot `
    -SkipQuickAccess:$SkipQuickAccess | Out-Null

$portableAgents = Join-Path $CapsuleRoot 'payload\harness\.agents'
if (Test-Path -LiteralPath $portableAgents -PathType Container) {
    $agentsTarget = Join-Path $UserRoot '.agents'
    if (Test-Path -LiteralPath $agentsTarget) {
        throw "Shared harness target already exists: $agentsTarget"
    }
    Copy-Item -LiteralPath $portableAgents -Destination $agentsTarget -Recurse
}

if (-not $SkipQuickAccess) {
    $quickAccessManifest = Join-Path $snapshotRoot 'Recovery\quick-access.json'
    if (Test-Path -LiteralPath $quickAccessManifest -PathType Leaf) {
        & (Join-Path $CapsuleRoot 'tools\Repair-QuickAccess.ps1') `
            -ManifestPath $quickAccessManifest `
            -UserRoot $UserRoot | Out-Null
    }
}

[pscustomobject]@{
    Result = 'PASS'
    UserRoot = $UserRoot
    SnapshotRoot = $snapshotRoot
    NextStep = 'Open projects\general-ai\START-HERE.md and finish the Bitwarden broker registration.'
}
