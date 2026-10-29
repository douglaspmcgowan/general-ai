<#
.SYNOPSIS
    Proves that this environment can perform a guarded Work Scope write.

.DESCRIPTION
    `verify.sh` runs this. It is deliberately a real round-trip against a
    disposable project rather than a feature probe: it initializes state, claims
    ownership through the guard, declares a task with an executable acceptance
    check, executes that check to earn a receipt, closes the task and the cell
    with that receipt, captures a discovery, and then reconciles.

    Every one of those steps goes through the same module a Windows session uses,
    so a Linux write lands in `events.jsonl` in the same shape, with the same
    SHA-256 payload chain, as a Windows one. If this script passes, a hosted agent
    can legally change Work Scope state; if it fails, the agent must treat Work
    Scope as read-only and say so rather than hand-editing anything.

    It writes only inside -Root (default: a fresh directory under the system temp
    directory) and removes it on success.
#>
[CmdletBinding()]
param(
    [string]$ToolsRoot,
    [string]$Root,
    [switch]$KeepArtifacts
)

$ErrorActionPreference = 'Stop'

if (-not $ToolsRoot) {
    $ToolsRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'tools'
}
if (-not $Root) {
    $Root = Join-Path ([System.IO.Path]::GetTempPath()) ("work-scope-cloud-" + [guid]::NewGuid().ToString('N'))
}

$module = Join-Path $ToolsRoot 'WorkScope.psm1'
if (-not (Test-Path -LiteralPath $module)) {
    throw "Work Scope module not found at '$module'."
}
Import-Module $module -Force -DisableNameChecking

# PowerShell's warning stream renders on the host, which is this process's stdout once verify.sh
# redirects it, so a module warning lands inside the one JSON document this script exists to emit.
# Measured 2026-08-23: an acceptance-check warning made that document unparseable and verify.sh
# reported "Work Scope guarded write produced an unusable result" -- reading a warning as a broken
# write, on every hosted agent, which is the opposite of what this check is for. Warnings are
# suppressed rather than rerouted because this script already has a channel for anything a caller
# acts on: Note writes progress to stderr, and a condition that should change the verdict belongs
# in the payload below, not in a stream the caller has to guess at.
$WarningPreference = 'SilentlyContinue'

$session = 'cloud-verify'
$steps = [System.Collections.Generic.List[string]]::new()
# Progress goes to stderr so stdout stays a single parseable JSON document for
# `verify.sh`. Mixing the two is how a verifier ends up asserting on log noise.
function Note { param([string]$Text) $steps.Add($Text); [Console]::Error.WriteLine("  $Text") }

try {
    New-Item -ItemType Directory -Path $Root -Force | Out-Null

    Initialize-WorkScopeProject -Root $Root -ProjectId 'cloud-verify' -ProjectKind 'agent-harness' `
        -InitiativeId 'portability' -TrackId 'linux-writes' -CapabilityId 'guarded-write' `
        -CapabilityName 'Guarded write from a hosted Linux agent' -TargetDepth 'D1' `
        -FrontierMode 'drilldown' -DepthCeiling 'D2' -BreadthBoundary 'track' `
        -SelectionStrategy 'dependency-first' -OwnerSession $session | Out-Null
    Note 'initialized authoritative state'

    $validation = Test-WorkScopeState -Root $Root
    if (-not $validation.valid) { throw "state invalid after init: $($validation.errors -join '; ')" }
    Note 'state validates'

    $resume = Get-WorkScopeResume -Root $Root
    if ($resume.cell_id -ne 'guarded-write@D0') { throw "unexpected resume cell '$($resume.cell_id)'." }
    Note "resume reports cell $($resume.cell_id)"

    Set-WorkScopeOwnership -Root $Root -SessionId $session -Artifacts @('results.json') | Out-Null
    Note 'claimed artifact ownership'

    $guard = Invoke-WorkScopeGuard -Root $Root -SessionId $session -ActionKind 'create' `
        -Artifact 'results.json' -CapabilityId 'guarded-write'
    if (-not $guard.allowed) { throw "guard rejected an in-cell write: $($guard.reasons -join '; ')" }
    Note 'scope guard allowed an in-cell write'

    # The guard must also refuse work outside the active cell, or "guarded" means nothing.
    $outside = Invoke-WorkScopeGuard -Root $Root -SessionId $session -ActionKind 'modify' `
        -Artifact '../escape.txt' -CapabilityId 'guarded-write'
    if ($outside.allowed) { throw 'guard allowed an artifact outside the project boundary.' }
    Note 'scope guard refused an out-of-boundary write'

    $checkDir = Join-Path $Root 'checks'
    New-Item -ItemType Directory -Path $checkDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $checkDir 'accept.ps1') `
        -Value 'Set-Content -LiteralPath "results.json" -Value "{""ok"":true}"; exit 0' -Encoding utf8NoBOM

    $interpreter = (Get-Process -Id $PID).Path
    $arguments = @('-NoProfile', '-File', 'checks/accept.ps1')

    Add-WorkScopeTask -Root $Root -TaskId 'TASK-1' -Title 'Prove a guarded Linux write' `
        -Acceptance 'The declared check exits zero and produces results.json' `
        -CheckId 'accept' -CheckVerifier 'test' -CheckExecutable $interpreter `
        -CheckArguments $arguments -CheckInputs @('checks/accept.ps1') `
        -CheckArtifacts @('results.json') -CheckTimeoutSeconds 120 -CheckMaxOutputBytes 1048576 | Out-Null
    Note "declared a task bound to $interpreter"

    $receipt = Invoke-WorkScopeVerification -Root $Root -CheckId 'accept' -Verifier 'test' `
        -Subject 'TASK-1' -Executable $interpreter -Arguments $arguments -Artifacts @('results.json')
    if ($receipt.result -ne 'pass' -or $receipt.exit_code -ne 0) { throw 'declared check did not pass.' }
    Note "earned execution receipt $($receipt.receipt_id)"

    # A caller-written pass string must not be able to close anything.
    $assertedClosure = $false
    try {
        Complete-WorkScopeTask -Root $Root -TaskId 'TASK-1' -Evidence @('result=pass') | Out-Null
        $assertedClosure = $true
    }
    catch { }
    if ($assertedClosure) { throw 'an asserted pass string closed a task; evidence gating is broken.' }
    Note 'asserted evidence was refused'

    Complete-WorkScopeTask -Root $Root -TaskId 'TASK-1' -Evidence @("receipt=$($receipt.receipt_id)") | Out-Null
    Note 'closed the task with its bound receipt'

    Add-WorkScopeDiscovery -Root $Root -Id 'BB-001' -Title 'Cloud verification follow-up' `
        -SuggestedTrack 'linux-writes' -SuggestedCapability 'guarded-write' -EntryDepth 'D1' `
        -DiscoveredFrom 'TASK-1' -Relationship 'follow-up' -Value 'low' -Risk 'low' `
        -Evidence @('verifier=inspection; subject=cloud-verify; result=verified; reference=checks/accept.ps1') | Out-Null
    Note 'captured a discovery without widening the cell'

    Close-WorkScopeCell -Root $Root -Evidence @("receipt=$($receipt.receipt_id)") | Out-Null
    Note 'closed the scope cell'

    $reconciliation = Test-WorkScopeReconciliation -Root $Root
    if (-not $reconciliation.reconciled) {
        throw "reconciliation failed: $($reconciliation.state_errors -join '; '); drift: $($reconciliation.drifted_files -join ', ')"
    }
    Note 'generated views and the event hash chain reconcile'

    $eventsPath = Join-Path $Root '.agents/work/events.jsonl'
    $events = @(Get-Content -LiteralPath $eventsPath | ForEach-Object { $_ | ConvertFrom-Json })
    $required = @('project_initialized', 'ownership_updated', 'task_added', 'verification_executed',
                  'task_completed', 'discovery_captured', 'scope_cell_closed')
    foreach ($type in $required) {
        if (@($events | Where-Object { $_.type -eq $type }).Count -lt 1) {
            throw "event log is missing a '$type' transition."
        }
    }
    # Every event after the first must name its predecessor's hash, or the chain is decorative.
    for ($i = 1; $i -lt $events.Count; $i++) {
        if ($events[$i].previous_event_hash -ne $events[$i - 1].event_hash) {
            throw "event chain broken between index $($i - 1) and $i."
        }
    }
    Note "$($events.Count) chained events written, all required transitions present"

    [pscustomobject]@{
        ok        = $true
        root      = $Root
        platform  = if ($IsWindows) { 'windows' } else { 'linux' }
        events    = $events.Count
        receipt   = $receipt.receipt_id
        last_hash = $events[-1].event_hash
        steps     = $steps
    } | ConvertTo-Json -Depth 5
}
finally {
    if (-not $KeepArtifacts -and (Test-Path -LiteralPath $Root)) {
        Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
    }
}
