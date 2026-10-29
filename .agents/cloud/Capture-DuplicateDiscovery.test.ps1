#requires -Version 7
<#
.SYNOPSIS
Tests that Capture-WorkDiscovery warns when a semantically equivalent discovery already exists.

.DESCRIPTION
Defect cloud-duplicate-discovery-prevention: items 1, 2, and 3 of the cloud dispatch cluster were
each filed twice with -v2 and -v3 suffixes because nothing warned that the same semantic content
was already captured. This test proves the warning exists.
#>
param([string]$Root)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$testRoot = if ($Root) { $Root } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$captureScript = Join-Path $testRoot '.agents/tools/Capture-WorkDiscovery.ps1'
$workScopeModule = Join-Path $testRoot '.agents/tools/WorkScope.psm1'
$fixtureModule = Join-Path $testRoot '.agents/tools/FixtureSpace.psm1'

if (-not (Test-Path $captureScript)) { throw "Capture script not found: $captureScript" }
Import-Module $workScopeModule -Force -DisableNameChecking
Import-Module $fixtureModule -Force

$fixture = New-FixtureRoot -Path (Join-Path ([IO.Path]::GetTempPath()) ("capture-dup-test-" + [guid]::NewGuid().ToString('N')))
Initialize-WorkScopeProject -Root $fixture -ProjectId 'test-project' -ProjectKind application `
    -InitiativeId 'test-init' -TrackId 'test-track' -CapabilityId 'test.cap' -CapabilityName 'Test Cap' `
    -TargetDepth D1 -OwnerSession 'test-session' | Out-Null

try {
    # Evidence reference points to schema.json which exists after Initialize-WorkScopeProject
    $evidenceSpec = 'verifier=inspection; subject=test; result=verified; reference=.agents/work/schema.json'

    # Capture first discovery
    $firstResult = & $captureScript `
        -Root $fixture `
        -Id 'dup-test-001' `
        -Title 'Test duplicate discovery' `
        -SuggestedTrack 'test-track' `
        -SuggestedCapability 'test.cap' `
        -EntryDepth 'D1' `
        -DiscoveredFrom 'test' `
        -Relationship 'defect' `
        -Value 'medium' `
        -Risk 'low' `
        -SemanticKey 'dup-test-semantic' `
        -Evidence $evidenceSpec `
        -FixRecommendation 'Test fix' `
        -FixLocation 'test.ps1' `
        -FixRationale 'Test rationale' 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "First capture failed: $firstResult"
    }

    # Triage is the only path from intake into Work Scope: accept the record, then drain it.
    $acceptOutput = & $captureScript -Root $fixture -ApplyDisposition -Id 'dup-test-001' -DispositionStatus accepted `
        -Reason 'Fixture triage accepts the first discovery.' -Evidence $evidenceSpec 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Triage acceptance failed: $($acceptOutput -join "`n")" }

    # Drain the queue to apply the first discovery
    $drainOutput = & $captureScript -Root $fixture -Drain 2>&1
    $drainResult = ($drainOutput -join "`n") | ConvertFrom-Json
    if ($drainResult.counts.applied -eq 0 -and $drainResult.counts.refused -gt 0) {
        throw "Drain failed: $($drainOutput -join "`n")"
    }

    # Verify backburner has the first discovery
    # Read-WorkScopeState, not a raw parse of state.json: a drained filing lands in the
    # .agents/work/backburner.json sidecar, which is authoritative once it exists, and state.json's
    # inline backburner is left empty (WorkScope.psm1, Merge-WorkScopeBackburnerSidecar). Reading the
    # raw file made this suite report "not applied to backburner" for an item the drain had applied.
    $stateAfterDrain = Read-WorkScopeState -Root $fixture
    if ($stateAfterDrain.backburner.Count -eq 0) {
        throw "First discovery was not applied to backburner"
    }
    $firstItem = $stateAfterDrain.backburner | Where-Object { $_.id -eq 'dup-test-001' } | Select-Object -First 1
    if ($null -eq $firstItem) {
        throw "First discovery not found on backburner"
    }
    if ($firstItem.semantic_key -ne 'dup-test-semantic') {
        throw "First discovery does not have expected semantic key"
    }

    # Capture second discovery with same semantic key
    # Write a wrapper script to capture stderr cleanly
    $wrapperScript = Join-Path $fixture 'invoke-capture.ps1'
    $stdoutFile = Join-Path $fixture 'stdout.txt'
    $stderrFile = Join-Path $fixture 'stderr.txt'
    @"
`$ErrorActionPreference = 'Stop'
& '$captureScript' ``
    -Root '$fixture' ``
    -Id 'dup-test-002' ``
    -Title 'Same defect different id' ``
    -SuggestedTrack 'test-track' ``
    -SuggestedCapability 'test.cap' ``
    -EntryDepth 'D1' ``
    -DiscoveredFrom 'test' ``
    -Relationship 'defect' ``
    -Value 'medium' ``
    -Risk 'low' ``
    -SemanticKey 'dup-test-semantic' ``
    -Evidence '$evidenceSpec' ``
    -FixRecommendation 'Test fix' ``
    -FixLocation 'test.ps1' ``
    -FixRationale 'Test rationale'
"@ | Set-Content $wrapperScript -Encoding UTF8

    $pwshPath = (Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source
    if (-not $pwshPath) { $pwshPath = '/opt/microsoft/powershell/7/pwsh' }
    $proc = Start-Process -FilePath $pwshPath -ArgumentList @('-NoProfile', '-File', $wrapperScript) `
        -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile `
        -WindowStyle Hidden -Wait -PassThru

    $stdoutContent = if (Test-Path $stdoutFile) { Get-Content $stdoutFile -Raw } else { '' }
    $stderrContent = if (Test-Path $stderrFile) { Get-Content $stderrFile -Raw } else { '' }
    $secondOutput = $stdoutContent + $stderrContent

    # The second capture should produce a warning about the existing semantic key
    if ($secondOutput -notmatch 'semantic.*exist|duplicate.*semantic|already.*semantic') {
        throw "FAIL: Second capture with same semantic key did not produce a duplicate warning.`nstdout: $stdoutContent`nstderr: $stderrContent"
    }

    Write-Output "PASS: Duplicate semantic key detection works"
    exit 0
}
finally {
    if (Test-Path $fixture) {
        Remove-Item -Recurse -Force $fixture -ErrorAction SilentlyContinue
    }
}
