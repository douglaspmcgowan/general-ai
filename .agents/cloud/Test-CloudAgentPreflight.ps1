#requires -Version 7
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Repository,
  [Parameter(Mandatory)][string]$BriefFile,
  [string]$EnvironmentId,
  [string]$RemoteBranch,
  [string[]]$SetupOutput = @(),
  [switch]$RequireClean
)
$ErrorActionPreference = 'Stop'
function GitText([string[]]$a) { $o=& git -C $Repository @a 2>$null; if($LASTEXITCODE -ne 0){return $null}; (($o -join "`n").Trim()) }
# `GitText` collapses "git ran and answered nothing" and "git could not answer at all" onto the
# same $null, so a refusal -- not a repository, denied for dubious ownership, remote unreachable --
# read as a clean repository with no remotes and reported `remote-missing`. That sent the operator
# to fix a remote that was never the problem. `GitProbe` keeps the exit code beside the text. The
# conductor copy of this preflight already made this distinction; the kit copy that ships to every
# enrolled project did not.
function GitProbe([string[]]$a) { $o=& git -C $Repository @a 2>$null; [pscustomobject]@{Code=$LASTEXITCODE;Text=(($o -join "`n").Trim())} }
function Result([string]$verdict,[hashtable]$extra=@{}) { $o=[ordered]@{verdict=$verdict}; foreach($p in $extra.GetEnumerator()){$o[$p.Key]=$p.Value}; $o|ConvertTo-Json -Compress }
function Refuse([string]$command,[int]$code) { Result 'git-inspection-failed' @{command=$command;exitCode=$code;environment=$EnvironmentId;remoteVisible=$false}; exit 1 }
# A cloud agent reads the remote branch head and nothing else, so a file a brief depends on must exist
# A cloud agent reads the remote branch head and nothing else, so a file a brief depends on must exist
# at that commit. A brief names required inputs on an `Input-path stop` line (DISPATCH-CHECKLIST.md
# item 11); those stop the task. Every other backtick-quoted path is advice, because a brief
# legitimately names files it will create. Paths are looked up with `git cat-file --batch-check`
# against the local object store, one `<sha>:<path>` line each: git reads a token only as the path half
# of an object name, never as an option, a revision or a shell word. Nothing is written, and nothing is
# fetched: the lookup runs with GIT_NO_LAZY_FETCH=1 and asks for the object name only, so a partial
# clone never reaches for its remote and a lookup git cannot answer is `could-not-tell`, never a stop.
# `.agents/conductor/Test-CloudAgentPreflight.ps1` carries a copy of this logic; keep the two in step
# (this file also ships standalone to enrolled projects, so it cannot import that one).
#
# WHAT THE PARSER UNDERSTANDS. Only backtick-quoted tokens (one or two backticks) are read. A token is a
# required path, when it is on the stop block, only if it reads as a file or folder: it ends in `/`, or
# its last segment has an extension that begins with a letter (a dot-file is that case). A trailing line
# reference (`:12`, `:12-20`, `:12:3`, `:36,53,54`, `#L3`, `#L3-L9`) is removed first. A token is not a
# path, and is neither required nor listed, when it names an existing ref (a branch, a tag, a remote
# branch, or the branch being submitted), when its "extension" begins with a digit (a model id, a
# version), or when a colon is left in it (`rev:path`). An extensionless token with a slash (`bin/tool`)
# is advice only: write the folder with a trailing slash or give the file an extension to require it.
# A dotted configuration key with no slash (`a.b_c`) cannot be told from a file name and is read as one.
# NOT UNDERSTOOD, so never required (the pull request names each): a fenced block under the stop line, a
# table row, an unquoted or double-quoted path, an extensionless file without a slash (`Makefile`), a
# path with a space, a markdown link, an absolute path, a field other than `Input-path stop`, and a path
# inside a submodule. A path the task itself creates, named on the stop line, stops the task.
function ConvertTo-BriefRepositoryPath {
  param([string]$Token)
  $t = $Token.Trim()
  $t = $t -replace '(:\d+(?:[-,:]\d+)*|#L\d+(?:-L?\d+)?)$', ''
  if ($t.Length -eq 0 -or $t.Length -gt 500) { return $null }
  if ($t -match '[\s\x00-\x1f*?<>{}$%|"]') { return $null }
  if ($t -match '^[A-Za-z][A-Za-z0-9+.\-]*:') { return $null }
  if ($t -match '^[/\\~]') { return $null }
  if ($t.Contains(':')) { return $null }
  $t = $t.Replace('\', '/')
  $t = $t -replace '^(\./)+', ''
  $isFolder = $t.EndsWith('/')
  $t = ($t -replace '/{2,}', '/').TrimEnd('/')
  if ($t.Length -eq 0) { return $null }
  $segments = @($t -split '/')
  if ($segments -contains '..' -or $segments -contains '.') { return $null }
  $ext = if ($segments[-1] -match '\.([^.]*)$') { $Matches[1] } else { '' }
  $required = $true
  if (-not ($isFolder -or $ext -match '^[A-Za-z]')) {
    if ($ext -match '^[0-9]') { return $null }
    if ($segments.Count -eq 1) { return $null }
    $required = $false
  }
  return [PSCustomObject]@{ Path = $t; Required = $required; IsFolder = $isFolder }
}

function Get-BriefLineTokens {
  param([string]$Line)
  $found = New-Object 'System.Collections.Generic.List[object]'
  foreach ($match in [regex]::Matches($Line, '(?<!`)(`{1,2})(?!`)([^\r\n]+?)(?<!`)\1(?!`)')) {
    $token = ConvertTo-BriefRepositoryPath $match.Groups[2].Value
    if ($token) { $found.Add($token) }
  }
  return ,$found
}

function Get-BriefLineIndent {
  param([string]$Line)
  $width = 0
  foreach ($c in $Line.ToCharArray()) { if ($c -eq ' ') { $width++ } elseif ($c -eq "`t") { $width += 4 } else { break } }
  return $width
}

$script:BriefStopRx = '(?i)^(?:[\s>*_~`#+•-]|\d{1,3}[.)]|\[[ xX]?\])*Input[-_ ]?path(?:s|\(s\))?[-_ ]?stops?(?![A-Za-z0-9])'
$script:BriefNothingRx = '(?i)^(?:none|n/a|\(none\)|not applicable|check each exact input path)(?![A-Za-z0-9])'
$script:BriefReferBackRx = '(?i)\b(?:those|these|the above|above|listed)\b'
$script:BriefCountRx = '(?i)\b(\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\b'
$script:BriefCountWords = @{ one = 1; two = 2; three = 3; four = 4; five = 5; six = 6; seven = 7; eight = 8; nine = 9; ten = 10; eleven = 11; twelve = 12 }
$script:BriefHeadingRx = '^\s{0,3}#{1,6}\s'
$script:BriefItemRx = '^\s*(?:[-*+•]|\d{1,3}[.)])\s'
$script:BriefFieldRx = '^\s*(?:(?:[-*+•]|\d{1,3}[.)])\s+)?[*_]*[A-Za-z][A-Za-z0-9 _/()\-]{0,40}[*_]*\s*:[*_]*(?:\s|$)'

# Index one past the last line that continues the block opened by the line before $From: lines up to the
# next blank line or heading, ending early at a new "Field:" line, or a new list item when the block is one.
# Used when the stop line carries no path: a heading or a bare label, whose inputs follow it.
function Get-BriefBlockEnd {
  param([string[]]$Lines, [int]$From, [int]$Base, [bool]$IsItem)
  $k = $From
  while ($k -lt $Lines.Count) {
    $line = $Lines[$k]
    if ($line.Trim().Length -eq 0 -or $line -match $script:BriefHeadingRx) { break }
    if ((Get-BriefLineIndent $line) -le $Base -and ($line -match $script:BriefFieldRx -or ($IsItem -and $line -match $script:BriefItemRx))) { break }
    $k++
  }
  return $k
}

# Index one past the last line of the block of a stop line that already names a path: only list items
# (a bullet, a number, a checkbox), blockquote lines and indented lines directly below it, ending at a
# blank line, a heading, a new "Field:" line or, for a list item, a new item at the same level. A plain
# paragraph line below is not part of the block: it is where a brief says what the lane will create.
function Get-BriefListBlockEnd {
  param([string[]]$Lines, [int]$From, [int]$Base, [bool]$IsItem)
  $k = $From
  while ($k -lt $Lines.Count) {
    $line = $Lines[$k]
    if ($line.Trim().Length -eq 0 -or $line -match $script:BriefHeadingRx) { break }
    $indent = Get-BriefLineIndent $line
    $item = $line -match $script:BriefItemRx
    if (-not ($item -or $line -match '^\s*>' -or $indent -gt $Base)) { break }
    if ($indent -le $Base -and ($line -match $script:BriefFieldRx -or ($IsItem -and $item))) { break }
    $k++
  }
  return $k
}

function Test-BriefRefToken {
  param($Token, $Refs)
  return (-not $Token.IsFolder) -and $Refs.Contains($Token.Path)
}

function Get-BriefPathScan {
  param([string]$Text, $Refs)
  $lines = @($Text -split "`r?`n")
  $all = New-Object 'System.Collections.Generic.SortedSet[string]' ([StringComparer]::Ordinal)
  $required = New-Object 'System.Collections.Generic.SortedSet[string]' ([StringComparer]::Ordinal)
  $lineTokens = New-Object 'System.Collections.Generic.List[object]'
  foreach ($line in $lines) {
    $tokens = Get-BriefLineTokens $line
    $lineTokens.Add($tokens)
    foreach ($t in $tokens) { if (-not (Test-BriefRefToken $t $Refs)) { [void]$all.Add($t.Path) } }
  }
  $notParsed = ''
  $candidates = New-Object 'System.Collections.Generic.List[object]'
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $stop = [regex]::Match($lines[$i], $script:BriefStopRx)
    if (-not $stop.Success) { continue }
    $value = $lines[$i].Substring($stop.Length) -replace '^[*_`\s:]+', ''
    if ($value -match $script:BriefNothingRx) { continue }
    $first = $lineTokens[$i]
    $base = Get-BriefLineIndent $lines[$i]
    $isItem = $lines[$i] -match $script:BriefItemRx
    if ($first.Count -gt 0) {
      foreach ($t in $first) { $candidates.Add($t) }
      $end = Get-BriefListBlockEnd -Lines $lines -From ($i + 1) -Base $base -IsItem $isItem
      for ($k = $i + 1; $k -lt $end; $k++) { foreach ($t in $lineTokens[$k]) { $candidates.Add($t) } }
      continue
    }
    # "Input-path stop: if any of those four is missing": the inputs are the paths in the list items
    # directly above (blank lines skipped). Anything else directly above (a paragraph, a "Label:" line,
    # a heading, nothing) is not read: no path is required from it and the result says so.
    if ($value -match $script:BriefReferBackRx) {
      $j = $i - 1
      while ($j -ge 0 -and $lines[$j].Trim().Length -eq 0) { $j-- }
      $above = New-Object 'System.Collections.Generic.List[object]'
      $sawItem = $false
      if ($j -ge 0 -and ($lines[$j] -match $script:BriefItemRx -or (Get-BriefLineIndent $lines[$j]) -gt 0)) {
        while ($j -ge 0 -and $lines[$j].Trim().Length -gt 0 -and $lines[$j] -notmatch $script:BriefHeadingRx -and $lines[$j] -notmatch $script:BriefStopRx) {
          $isListLine = $lines[$j] -match $script:BriefItemRx
          if (-not ($isListLine -or (Get-BriefLineIndent $lines[$j]) -gt 0)) { break }
          if ($isListLine) { $sawItem = $true }
          foreach ($t in $lineTokens[$j]) { $above.Add($t) }
          $j--
        }
      }
      $count = [regex]::Match($value, $script:BriefCountRx)
      if (-not $sawItem -or ($above.Count -eq 0 -and -not $count.Success)) {
        if (-not $notParsed) { $notParsed = 'no-list' }
        continue
      }
      $listed = $above.Count
      $stated = if (-not $count.Success) { $listed } elseif ($count.Groups[1].Value -match '^\d+$') { [int]$count.Groups[1].Value } else { $script:BriefCountWords[$count.Groups[1].Value.ToLowerInvariant()] }
      if ($stated -ne $listed) { if (-not $notParsed) { $notParsed = 'count' } } else { foreach ($t in $above) { $candidates.Add($t) } }
      continue
    }
    $end = Get-BriefBlockEnd -Lines $lines -From ($i + 1) -Base $base -IsItem $isItem
    for ($k = $i + 1; $k -lt $end; $k++) { foreach ($t in $lineTokens[$k]) { $candidates.Add($t) } }
    # "## Input-path stop:" or "Input-path stop:" with its inputs in the block that follows.
    if ($end -eq $i + 1 -and ($lines[$i] -match $script:BriefHeadingRx -or $lines[$i] -match ':[*_`\s]*$')) {
      $n = $i + 1
      while ($n -lt $lines.Count -and $lines[$n].Trim().Length -eq 0) { $n++ }
      if ($n -lt $lines.Count -and $lines[$n] -notmatch $script:BriefHeadingRx -and $lines[$n] -notmatch $script:BriefStopRx) {
        $blockEnd = Get-BriefBlockEnd -Lines $lines -From ($n + 1) -Base (Get-BriefLineIndent $lines[$n]) -IsItem $false
        for ($k = $n; $k -lt $blockEnd; $k++) { foreach ($t in $lineTokens[$k]) { $candidates.Add($t) } }
      }
    }
  }
  foreach ($t in $candidates) { if ($t.Required -and -not (Test-BriefRefToken $t $Refs)) { [void]$required.Add($t.Path) } }
  return [PSCustomObject]@{ Required = [string[]]@($required); All = [string[]]@($all); StopLineNotParsed = $notParsed }
}

# Names a token may be mistaken for: every branch, tag and remote branch (with and without its
# `refs/<kind>/` prefix), the branch being submitted and its `origin/` form.
function Get-BriefRefNames {
  param([string]$Repository, [string[]]$Branch = @())
  $refs = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
  foreach ($b in $Branch) { if ($b) { [void]$refs.Add($b); [void]$refs.Add("origin/$b") } }
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $names = @(& git -C $Repository for-each-ref '--format=%(refname)' 2>$null); $code = $LASTEXITCODE
  $ErrorActionPreference = $old
  if ($code -eq 0) {
    foreach ($name in $names) {
      [void]$refs.Add([string]$name)
      if ([string]$name -match '^refs/(?:heads|remotes|tags)/(.+)$') { [void]$refs.Add($Matches[1]) }
    }
  }
  return ,$refs
}

# CouldNotTell is true when the commit is not in the local object store (or git could not answer);
# then no path was checked. Otherwise Absent lists every scanned path missing at $Sha, sorted.
function Get-BriefPathCheck {
  param([string]$Sha, [string[]]$Branch = @())
  $scan = Get-BriefPathScan ([string](Get-Content -LiteralPath $BriefFile -Raw -Encoding utf8)) (Get-BriefRefNames -Repository $Repository -Branch $Branch)
  $none = [PSCustomObject]@{ CouldNotTell = $false; MissingRequired = [string[]]@(); Absent = [string[]]@(); StopLineNotParsed = $scan.StopLineNotParsed }
  if ($scan.All.Count -eq 0) { return $none }
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $oldLazy = $env:GIT_NO_LAZY_FETCH; $env:GIT_NO_LAZY_FETCH = '1'
  try {
    $null = & git -C $Repository cat-file '-e' ($Sha + '^{commit}') 2>$null
    $commitCode = $LASTEXITCODE
    $answers = @()
    if ($commitCode -eq 0) {
      $queries = [string[]]@($scan.All | ForEach-Object { $Sha + ':' + $_ })
      $answers = @($queries | & git -C $Repository cat-file '--batch-check=%(objectname)' 2>$null); $code = $LASTEXITCODE
      if ($code -ne 0) { $answers = @() }
    }
  } finally {
    $ErrorActionPreference = $old
    if ($null -eq $oldLazy) { Remove-Item Env:GIT_NO_LAZY_FETCH -ErrorAction SilentlyContinue } else { $env:GIT_NO_LAZY_FETCH = $oldLazy }
  }
  $unanswered = [PSCustomObject]@{ CouldNotTell = $true; MissingRequired = [string[]]@(); Absent = [string[]]@(); StopLineNotParsed = $scan.StopLineNotParsed }
  if ($commitCode -ne 0 -or $answers.Count -ne $scan.All.Count) { return $unanswered }
  $absent = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $scan.All.Count; $i++) { if ([string]$answers[$i] -match ' missing$') { $absent.Add($scan.All[$i]) } }
  # In a partial clone `missing` also means "the object is not here", so a file that exists at the commit
  # but whose blob was never downloaded looks absent. Resolve each such path through the trees alone
  # (no blob is read); a path that still does not resolve cannot be told from a missing tree, so the
  # whole check is could-not-tell rather than a stop.
  if ($absent.Count -gt 0) {
    $null = & git -C $Repository config --get-regexp '^(remote\..+\.promisor|extensions\.partialclone)$' 2>$null
    if ($LASTEXITCODE -eq 0) {
      if ($absent.Count -gt 200) { return $unanswered }
      $oldLazy = $env:GIT_NO_LAZY_FETCH; $env:GIT_NO_LAZY_FETCH = '1'
      try {
        foreach ($p in @($absent)) {
          $null = & git -C $Repository rev-parse --verify --quiet ($Sha + ':' + $p) 2>$null
          if ($LASTEXITCODE -ne 0) { return $unanswered }
        }
      } finally { if ($null -eq $oldLazy) { Remove-Item Env:GIT_NO_LAZY_FETCH -ErrorAction SilentlyContinue } else { $env:GIT_NO_LAZY_FETCH = $oldLazy } }
      $absent.Clear()
    }
  }

  $absentSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$absent.ToArray(), [StringComparer]::Ordinal)
  $missingRequired = [string[]]@($scan.Required | Where-Object { $absentSet.Contains($_) })
  return [PSCustomObject]@{ CouldNotTell = $false; MissingRequired = $missingRequired; Absent = $absent.ToArray(); StopLineNotParsed = $scan.StopLineNotParsed }
}
try {
  if(-not (Test-Path -LiteralPath $Repository -PathType Container)){ throw 'repository-missing' }
  if(-not (Test-Path -LiteralPath $BriefFile -PathType Leaf)){ Result 'brief-missing'; exit 1 }
  if([string]::IsNullOrWhiteSpace($EnvironmentId)){ Result 'environment-missing'; exit 1 }
  $sig='Environment setup failed, script exited with code 1'; $joined=$SetupOutput -join "`n"; $count=[regex]::Matches($joined,[regex]::Escape($sig)).Count
  if($count -ge 2 -and $joined -match '(?is)echo\s+OK.*exit\s+0'){ Result 'cache-poison-suspected' @{environment=$EnvironmentId; repeatedFailures=$count; resetCacheAction="Codex Cloud -> Environments -> $EnvironmentId -> Reset cache"}; exit 1 }
  $p=GitProbe @('ls-files','-u'); if($p.Code -ne 0){Refuse 'git ls-files -u' $p.Code}
  $unmerged=@($p.Text -split "`r?`n"|? {$_.Trim()}); if($unmerged.Count){Result 'unmerged-entries' @{count=$unmerged.Count};exit 1}
  $p=GitProbe @('remote'); if($p.Code -ne 0){Refuse 'git remote' $p.Code}
  $remotes=@($p.Text -split "`r?`n"|? {$_.Trim()}); if('origin' -notin $remotes){Result 'remote-missing';exit 1}
  $p=GitProbe @('branch','--show-current'); if($p.Code -ne 0){Refuse 'git branch --show-current' $p.Code}
  $branch=$p.Text; if($RemoteBranch){$branch=($RemoteBranch -replace '^refs/heads/','') -replace '^origin/',''}
  if([string]::IsNullOrWhiteSpace($branch)){Result 'branch-missing';exit 1}
  # `ls-remote --exit-code` returns 2 for "ran fine, no matching ref", which IS remote-branch-missing.
  # Any other non-zero code is git failing to reach the remote, not an answer about the branch.
  $p=GitProbe @('ls-remote','--exit-code','--heads','origin',"refs/heads/$branch"); if($p.Code -ne 0 -and $p.Code -ne 2){Refuse 'git ls-remote' $p.Code}
  $remoteLine=if($p.Code -eq 0){$p.Text}else{$null}; if(-not $remoteLine){Result 'remote-branch-missing' @{branch=$branch};exit 1}
  $remoteSha=($remoteLine -split '\s+')[0]; $p=GitProbe @('rev-parse','HEAD'); if($p.Code -ne 0){Refuse 'git rev-parse HEAD' $p.Code}
  $ahead=GitText @('rev-list','--count',"$remoteSha..HEAD"); $n=0; [void][int]::TryParse($ahead,[ref]$n)
  if($n -gt 0){Result 'unpushed-local-commits' @{count=$n;branch=$branch};exit 1}
  if($RequireClean){$p=GitProbe @('status','--porcelain'); if($p.Code -ne 0){Refuse 'git status --porcelain' $p.Code}; if($p.Text){Result 'worktree-dirty' @{branch=$branch};exit 1}}
  $pathCheck=Get-BriefPathCheck -Sha $remoteSha -Branch @($branch)
  if($pathCheck.CouldNotTell){Result 'ready' @{branch=$branch;remoteVisible=$true;environment=$EnvironmentId;pathCheck='could-not-tell (the remote commit could not be read in the local object store)'}; exit 0}
  if($pathCheck.MissingRequired.Count -gt 0){Result 'brief-input-path-missing' @{paths=[string[]]@($pathCheck.MissingRequired);branch=$branch;environment=$EnvironmentId;remoteVisible=$true;explanation='The brief names required input paths that are absent from the remote branch head. The cloud agent will not see these files. If a named path is one the task creates, take it off the stop block; otherwise merge the default branch into this branch and push it before submitting.'}; exit 1}
  $ready=@{branch=$branch;remoteVisible=$true;environment=$EnvironmentId;absentPaths=[string[]]@($pathCheck.Absent | Select-Object -First 50)}
  if($pathCheck.StopLineNotParsed -eq 'no-list'){$ready['pathCheck']='stop-line-not-parsed (the stop line refers back, and no list sits directly above it, so no path was required from it)'}
  elseif($pathCheck.StopLineNotParsed){$ready['pathCheck']='stop-line-not-parsed (the stop line refers to the list above it and states a count that does not match it, so no path was required from it)'}
  if($pathCheck.Absent.Count -gt 50){$ready['absentPathsTruncated']=$true}
  Result 'ready' $ready; exit 0
} catch { Result 'preflight-failed' @{message=$_.Exception.Message}; exit 2 }
