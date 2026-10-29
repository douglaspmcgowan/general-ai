#requires -Version 7
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'Test-DispatchLanded.ps1'
$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'conductor/CloudTask.psm1'
$pwshBase = @('-NoProfile'); if ($IsWindows) { $pwshBase += @('-WindowStyle', 'Hidden') }

function New-Fixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('dispatch-landed-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $origin = Join-Path $root 'origin.git'
    git init -q --bare $origin
    $work = Join-Path $root 'work'
    git init -q -b master $work
    git -C $work config user.email test@example.invalid
    git -C $work config user.name fixture
    Set-Content (Join-Path $work 'seed.txt') 'seed'
    git -C $work add seed.txt; git -C $work commit -q -m seed
    git -C $work remote add origin $origin
    git -C $work push -q -u origin master
    # landed: a real change on top of master
    git -C $work checkout -q -b agent/landed
    Set-Content (Join-Path $work 'landed.txt') 'work product'
    git -C $work add landed.txt; git -C $work commit -q -m landed
    git -C $work push -q origin agent/landed
    # empty: pushed, but identical to the merge-base
    git -C $work checkout -q master
    git -C $work checkout -q -b agent/no-diff
    git -C $work push -q origin agent/no-diff
    git -C $work checkout -q master
    return [PSCustomObject]@{ Root = $root; Work = $work; Origin = $origin }
}

function Invoke-Tool {
    param([string[]]$ToolArguments)
    $out = & pwsh @pwshBase -File $scriptPath @ToolArguments 2>&1
    return [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Lines = @($out | ForEach-Object { [string]$_ }) }
}

function Get-Records {
    param($Result)
    $parsed = @()
    foreach ($line in $Result.Lines) { if ($line.Trim().StartsWith('{')) { $parsed += ($line | ConvertFrom-Json) } }
    return $parsed
}

$failures = @()
$fixture = New-Fixture
try {
    # 1. landed
    $r = Invoke-Tool @('-Branch', 'agent/landed', '-Repository', $fixture.Work, '-SkipPullRequest')
    $rows = Get-Records $r
    $landedRow = $rows | Where-Object { $_.PSObject.Properties['branch'] -and $_.branch -eq 'agent/landed' }
    $summary = $rows | Where-Object { $_.PSObject.Properties['summary'] }
    if ($landedRow.state -ne 'landed') { $failures += "landed branch classified $($landedRow.state)" }
    if ($landedRow.changedFiles -lt 1) { $failures += 'landed branch reported no changed files' }
    if ($r.ExitCode -ne 0) { $failures += "landed-only run exited $($r.ExitCode), expected 0" }
    if ($summary.reason -ne 'all-landed') { $failures += "unexpected summary reason $($summary.reason)" }
    "LANDED: state=$($landedRow.state) changedFiles=$($landedRow.changedFiles) exit=$($r.ExitCode) reason=$($summary.reason)"

    # 2. empty by empty diff
    $r = Invoke-Tool @('-Branch', 'agent/no-diff', '-Repository', $fixture.Work, '-SkipPullRequest')
    $rows = Get-Records $r
    $row = $rows | Where-Object { $_.PSObject.Properties['branch'] }
    if ($row.state -ne 'empty') { $failures += "empty-diff branch classified $($row.state)" }
    if ($row.reason -ne 'branch-equals-base') { $failures += "empty-diff reason was $($row.reason)" }
    if ($r.ExitCode -ne 1) { $failures += "empty run exited $($r.ExitCode), expected 1" }
    "EMPTY-DIFF: state=$($row.state) reason=$($row.reason) exit=$($r.ExitCode)"

    # 3. the case that matters most: a branch that does not exist on the remote is empty, not an error
    $r = Invoke-Tool @('-Branch', 'agent/never-pushed', '-Repository', $fixture.Work, '-SkipPullRequest')
    $rows = Get-Records $r
    $row = $rows | Where-Object { $_.PSObject.Properties['branch'] }
    if ($row.state -ne 'empty') { $failures += "absent branch classified $($row.state), expected empty" }
    if ($row.reason -ne 'branch-absent-on-remote') { $failures += "absent branch reason was $($row.reason)" }
    if ($r.ExitCode -ne 1) { $failures += "absent-branch run exited $($r.ExitCode), expected 1" }
    "ABSENT-BRANCH: state=$($row.state) reason=$($row.reason) exit=$($r.ExitCode)"

    # 4. an unreachable remote is could-not-tell, never empty
    $dead = Join-Path $fixture.Root 'no-such-remote.git'
    git -C $fixture.Work remote add dead $dead
    $r = Invoke-Tool @('-Branch', 'agent/landed,agent/never-pushed', '-Repository', $fixture.Work, '-Remote', 'dead', '-SkipPullRequest')
    $rows = Get-Records $r
    $rowsWithBranch = @($rows | Where-Object { $_.PSObject.Properties['branch'] })
    $states = @($rowsWithBranch | ForEach-Object { $_.state } | Sort-Object -Unique)
    if ($states.Count -ne 1 -or $states[0] -ne 'could-not-tell') { $failures += "unreachable remote produced states: $($states -join ',')" }
    if ($rowsWithBranch.Count -ne 2) { $failures += "unreachable remote returned $($rowsWithBranch.Count) rows, expected 2" }
    if ($r.ExitCode -ne 2) { $failures += "unreachable run exited $($r.ExitCode), expected 2" }
    "UNREACHABLE-REMOTE: states=$($states -join ',') rows=$($rowsWithBranch.Count) exit=$($r.ExitCode)"

    # 5. mixed set: exactly one state per branch, and could-not-tell is never folded into empty
    $recordFile = Join-Path $fixture.Root 'dispatch-landed.jsonl'
    $r = Invoke-Tool @('-Branch', 'agent/landed,agent/no-diff,agent/never-pushed', '-Repository', $fixture.Work, '-SkipPullRequest', '-RecordPath', $recordFile)
    $rows = @(Get-Records $r | Where-Object { $_.PSObject.Properties['branch'] })
    $summary = (Get-Records $r) | Where-Object { $_.PSObject.Properties['summary'] }
    if ($rows.Count -ne 3) { $failures += "mixed run returned $($rows.Count) rows, expected 3" }
    foreach ($row in $rows) { if (@('landed', 'empty', 'could-not-tell') -notcontains $row.state) { $failures += "unknown state $($row.state)" } }
    if ($summary.landed -ne 1 -or $summary.empty -ne 2 -or $summary.couldNotTell -ne 0) { $failures += "mixed summary wrong: $($summary | ConvertTo-Json -Compress)" }
    if ($summary.reason -notmatch 'agent/no-diff \(empty\)' -or $summary.reason -notmatch 'agent/never-pushed \(empty\)') { $failures += "summary reason did not name the branches: $($summary.reason)" }
    if ($r.ExitCode -ne 1) { $failures += "mixed run exited $($r.ExitCode), expected 1" }
    "MIXED: landed=$($summary.landed) empty=$($summary.empty) couldNotTell=$($summary.couldNotTell) exit=$($r.ExitCode) reason=$($summary.reason)"

    # 6. the record file is the receipt the dispatch gate reads
    $recorded = @(Get-Content $recordFile | Where-Object { $_.Trim() } | ConvertFrom-Json)
    if ($recorded.Count -ne 3) { $failures += "record file holds $($recorded.Count) lines, expected 3" }
    "RECORDED: $($recorded.Count) classifications written to dispatch-landed.jsonl"

    # 6b. once merged, the branch's commits are contained in the base: still exactly one state,
    #     and the reason separates it from a branch that never moved.
    git -C $fixture.Work merge -q --no-ff -m 'merge landed' agent/landed
    git -C $fixture.Work push -q origin master
    $r = Invoke-Tool @('-Branch', 'agent/landed', '-Repository', $fixture.Work, '-SkipPullRequest')
    $row = Get-Records $r | Where-Object { $_.PSObject.Properties['branch'] }
    if ($row.state -ne 'empty') { $failures += "contained branch classified $($row.state)" }
    if ($row.reason -ne 'already-contained-in-base') { $failures += "contained branch reason was $($row.reason)" }
    "ALREADY-CONTAINED: state=$($row.state) reason=$($row.reason) exit=$($r.ExitCode)"

    # 7. dispatch gate: an unclassified previous-wave branch blocks the next wave
    Import-Module $modulePath -Force -WarningAction SilentlyContinue
    $taskFile = Join-Path $fixture.Root 'cloud-tasks.jsonl'
    ([ordered]@{ timestamp = 'x'; loop = 'demo'; taskId = 'task_1'; branch = 'agent/landed' } | ConvertTo-Json -Compress) | Add-Content $taskFile
    ([ordered]@{ timestamp = 'x'; loop = 'demo'; taskId = 'task_2'; branch = 'agent/unseen' } | ConvertTo-Json -Compress) | Add-Content $taskFile
    $blocked = @(Get-UnclassifiedDispatchBranches -TaskFile $taskFile -RecordFile $recordFile -Loop 'demo')
    if ($blocked -notcontains 'agent/unseen') { $failures += 'gate did not block on an unclassified branch' }
    if ($blocked -contains 'agent/landed') { $failures += 'gate blocked on an already-classified branch' }
    "GATE-BLOCKS: $($blocked -join ',')"

    # 8. gate: could-not-tell does not classify, because an unreadable remote is not a result
    $unknownRecord = Join-Path $fixture.Root 'unknown-only.jsonl'
    ([ordered]@{ timestamp = 'x'; branch = 'agent/unseen'; state = 'could-not-tell' } | ConvertTo-Json -Compress) | Add-Content $unknownRecord
    $stillBlocked = @(Get-UnclassifiedDispatchBranches -TaskFile $taskFile -RecordFile $unknownRecord -Loop 'demo')
    if ($stillBlocked -notcontains 'agent/unseen') { $failures += 'could-not-tell wrongly counted as a classification' }
    "GATE-COULD-NOT-TELL-STILL-BLOCKS: $($stillBlocked -join ',')"

    # 9. gate: once every branch is landed or empty, the next wave is free to go
    $fullRecord = Join-Path $fixture.Root 'full.jsonl'
    ([ordered]@{ timestamp = 'x'; branch = 'agent/landed'; state = 'landed' } | ConvertTo-Json -Compress) | Add-Content $fullRecord
    ([ordered]@{ timestamp = 'x'; branch = 'agent/unseen'; state = 'empty' } | ConvertTo-Json -Compress) | Add-Content $fullRecord
    $clear = @(Get-UnclassifiedDispatchBranches -TaskFile $taskFile -RecordFile $fullRecord -Loop 'demo')
    if ($clear.Count -ne 0) { $failures += "gate still blocked after full classification: $($clear -join ',')" }
    "GATE-CLEARS: $($clear.Count) unclassified branches remain"
}
finally {
    Remove-Item -LiteralPath $fixture.Root -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { "FAIL: $_" }
    exit 1
}
'PASS: Test-DispatchLanded classifies landed, empty, and could-not-tell, and the dispatch gate holds'
exit 0
