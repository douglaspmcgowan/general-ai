#requires -Version 7
<#
.SYNOPSIS
Classifies dispatched branches as landed, empty, or could-not-tell.

.DESCRIPTION
A delegated agent's status is not its result. This tool looks only at the artifact:
the branch on the remote and its diff against the merge-base with the base branch.

    landed          the branch exists on the remote and its diff against the
                    merge-base with the base branch is non-empty
    empty           the branch exists on the remote with an empty diff, or the
                    branch does not exist on the remote at all. A real outcome,
                    recorded once, never silently re-dispatched.
    could-not-tell  the remote was unreachable, authentication failed, or the
                    branch state is unreadable. Never folded into empty.

Exit 0 when every branch is landed, 1 when any branch is empty, 2 when any branch
is could-not-tell. The summary line names the branches that were not landed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)][string[]]$Branch,
    [string[]]$TaskId,
    [string]$Repository = (Get-Location).Path,
    [string]$Remote = 'origin',
    [string]$BaseBranch = 'master',
    [string]$RecordPath,
    [switch]$SkipPullRequest,
    [switch]$AsObject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $stdout = & git @Arguments 2>&1
    $code = $LASTEXITCODE
    [PSCustomObject]@{
        ExitCode = $code
        Output   = (@($stdout) -join "`n").Trim()
        Ok       = ($code -eq 0)
    }
}

function New-Record {
    param(
        [string]$BranchName, [string]$State, [string]$Reason, [string]$Sha = '',
        [string]$MergeBase = '', [int]$ChangedFiles = 0, $PrNumber = $null,
        [string]$PrState = '', [string]$Task = ''
    )
    [PSCustomObject][ordered]@{
        branch       = $BranchName
        state        = $State
        reason       = $Reason
        sha          = $Sha
        mergeBase    = $MergeBase
        changedFiles = $ChangedFiles
        prNumber     = $PrNumber
        prState      = $PrState
        taskId       = $Task
    }
}

function Get-PullRequests {
    param([string[]]$BranchNames)
    $result = @{}
    foreach ($name in $BranchNames) { $result[$name] = [PSCustomObject]@{ Number = $null; State = '' } }
    if ($SkipPullRequest) { return $result }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        foreach ($name in $BranchNames) { $result[$name] = [PSCustomObject]@{ Number = $null; State = 'could-not-tell' } }
        return $result
    }
    $raw = & gh pr list --state all --json headRefName,number,state --limit 1000 2>&1
    if ($LASTEXITCODE -ne 0) {
        foreach ($name in $BranchNames) { $result[$name] = [PSCustomObject]@{ Number = $null; State = 'could-not-tell' } }
        return $result
    }
    try { $parsed = @((@($raw) -join '') | ConvertFrom-Json) }
    catch {
        foreach ($name in $BranchNames) { $result[$name] = [PSCustomObject]@{ Number = $null; State = 'could-not-tell' } }
        return $result
    }
    foreach ($pr in $parsed) {
        $head = [string]$pr.headRefName
        if ($result.ContainsKey($head)) {
            $result[$head] = [PSCustomObject]@{ Number = [int]$pr.number; State = [string]$pr.state }
        }
    }
    return $result
}

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "repository-unavailable: $Repository"
}

# `pwsh -File` hands every argument over as a literal string, so a comma-separated
# list is the only way to name several branches from a command line.
$branches = @($Branch | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($branches.Count -eq 0) { throw 'no-branches: at least one branch name is required' }

$taskMap = @{}
$tasks = @($TaskId | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
for ($i = 0; $i -lt $branches.Count -and $i -lt $tasks.Count; $i++) { $taskMap[$branches[$i]] = $tasks[$i] }
function Get-TaskFor { param([string]$Name) if ($taskMap.ContainsKey($Name)) { return [string]$taskMap[$Name] } return '' }

$records = [System.Collections.Generic.List[object]]::new()

Push-Location -LiteralPath $Repository
try {
    $pullRequests = Get-PullRequests -BranchNames $branches
    # One reachability probe. An unreachable remote is never proof of an absent branch.
    $ls = Invoke-Git @('ls-remote', '--heads', $Remote)
    if (-not $ls.Ok) {
        $probe = if ($ls.Output) { ($ls.Output -split "`n" | Select-Object -First 1) } else { 'no output' }
        $reason = "remote-unreachable: $probe"
        foreach ($name in $branches) {
            $records.Add((New-Record -BranchName $name -State 'could-not-tell' -Reason $reason -Task (Get-TaskFor $name)))
        }
    }
    else {
        $remoteHeads = @{}
        foreach ($line in ($ls.Output -split "`n")) {
            if ($line -match '^([0-9a-f]{40})\s+refs/heads/(.+)$') { $remoteHeads[$Matches[2].Trim()] = $Matches[1] }
        }

        $baseReadable = $true
        $baseSha = ''
        if (-not $remoteHeads.ContainsKey($BaseBranch)) { $baseReadable = $false }
        else {
            $baseSha = $remoteHeads[$BaseBranch]
            $fetchBase = Invoke-Git @('fetch', '--quiet', $Remote, $BaseBranch)
            if (-not $fetchBase.Ok) { $baseReadable = $false }
        }

        foreach ($name in $branches) {
            $task = Get-TaskFor $name
            if (-not $remoteHeads.ContainsKey($name)) {
                $records.Add((New-Record -BranchName $name -State 'empty' -Reason 'branch-absent-on-remote' -Task $task))
                continue
            }
            $sha = $remoteHeads[$name]
            if (-not $baseReadable) {
                $records.Add((New-Record -BranchName $name -State 'could-not-tell' -Reason "base-branch-unreadable: $BaseBranch" -Sha $sha -Task $task))
                continue
            }
            $fetch = Invoke-Git @('fetch', '--quiet', $Remote, $name)
            if (-not $fetch.Ok) {
                $records.Add((New-Record -BranchName $name -State 'could-not-tell' -Reason 'branch-fetch-failed' -Sha $sha -Task $task))
                continue
            }
            $mb = Invoke-Git @('merge-base', $baseSha, $sha)
            if (-not $mb.Ok -or -not $mb.Output) {
                $records.Add((New-Record -BranchName $name -State 'could-not-tell' -Reason 'merge-base-unreadable' -Sha $sha -Task $task))
                continue
            }
            $mergeBase = ($mb.Output -split "`n" | Select-Object -First 1).Trim()
            $diff = Invoke-Git @('diff', '--name-only', $mergeBase, $sha)
            if (-not $diff.Ok) {
                $records.Add((New-Record -BranchName $name -State 'could-not-tell' -Reason 'diff-unreadable' -Sha $sha -MergeBase $mergeBase -Task $task))
                continue
            }
            $changed = @($diff.Output -split "`n" | Where-Object { $_.Trim() })
            $pr = $pullRequests[$name]
            if ($changed.Count -eq 0) {
                # Still exactly one state. The reason separates a branch that never moved off
                # the base from one whose commits are already contained in the base, and the
                # pull-request fields say which of those was merged rather than abandoned.
                $emptyReason = if ($sha -eq $baseSha) { 'branch-equals-base' }
                elseif ($mergeBase -eq $sha) { 'already-contained-in-base' }
                else { 'diff-empty-against-merge-base' }
                $records.Add((New-Record -BranchName $name -State 'empty' -Reason $emptyReason -Sha $sha -MergeBase $mergeBase -PrNumber $pr.Number -PrState $pr.State -Task $task))
            }
            else {
                $records.Add((New-Record -BranchName $name -State 'landed' -Reason 'diff-non-empty' -Sha $sha -MergeBase $mergeBase -ChangedFiles $changed.Count -PrNumber $pr.Number -PrState $pr.State -Task $task))
            }
        }
    }
}
finally { Pop-Location }

if ($RecordPath) {
    $recordDir = Split-Path -Parent $RecordPath
    if ($recordDir -and -not (Test-Path -LiteralPath $recordDir)) { New-Item -ItemType Directory -Path $recordDir -Force | Out-Null }
    $stamp = [DateTime]::UtcNow.ToString('o')
    foreach ($record in $records) {
        $line = [ordered]@{
            timestamp = $stamp; branch = $record.branch; state = $record.state
            reason = $record.reason; sha = $record.sha; prNumber = $record.prNumber; taskId = $record.taskId
        } | ConvertTo-Json -Compress
        Add-Content -LiteralPath $RecordPath -Value $line -Encoding UTF8
    }
}

$landed = @($records | Where-Object { $_.state -eq 'landed' })
$empty = @($records | Where-Object { $_.state -eq 'empty' })
$unknown = @($records | Where-Object { $_.state -eq 'could-not-tell' })
$notLanded = @($records | Where-Object { $_.state -ne 'landed' })

$reason = if ($notLanded.Count -eq 0) { 'all-landed' }
else { 'not-landed: ' + (($notLanded | ForEach-Object { "$($_.branch) ($($_.state))" }) -join ', ') }

$summary = [ordered]@{
    summary = 'dispatch-landed'; total = $records.Count; landed = $landed.Count
    empty = $empty.Count; couldNotTell = $unknown.Count
    notLanded = @($notLanded | ForEach-Object { $_.branch }); reason = $reason
}

if ($AsObject) {
    [PSCustomObject]@{ records = $records.ToArray(); summary = [PSCustomObject]$summary }
}
else {
    foreach ($record in $records) { $record | ConvertTo-Json -Compress }
    [PSCustomObject]$summary | ConvertTo-Json -Compress
}

if ($unknown.Count -gt 0) { exit 2 }
if ($empty.Count -gt 0) { exit 1 }
exit 0
