#requires -Version 7
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'Test-CloudAgentPreflight.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('cloud-preflight-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
  $repo = Join-Path $root 'repo'; New-Item -ItemType Directory $repo | Out-Null
  git -C $repo init -q -b master
  git -C $repo config user.email test@example.invalid; git -C $repo config user.name fixture
  Set-Content (Join-Path $repo 'seed.txt') seed; git -C $repo add .; git -C $repo commit -qm seed
  git -C $repo remote add origin https://example.invalid/repo.git
  $brief = Join-Path $root 'brief.txt'; Set-Content $brief objective
  function Invoke-Case([hashtable]$case) {
    $args = @('-NoProfile','-NonInteractive','-File',$script,'-Repository',$case.Repository,'-BriefFile',$case.BriefFile)
    if ($case.ContainsKey('EnvironmentId')) { $args += @('-EnvironmentId',$case.EnvironmentId) }
    if ($case.ContainsKey('SetupOutput')) { $args += @('-SetupOutput',($case.SetupOutput -join "`n")) }
    $o = & pwsh @args 2>$null
    [pscustomobject]@{ Exit=$LASTEXITCODE; Json=($o | Select-Object -Last 1 | ConvertFrom-Json) }
  }
  $r = Invoke-Case @{ Repository=$repo; BriefFile=$brief; EnvironmentId='env'; SetupOutput=@('Environment setup failed, script exited with code 1','echo OK; exit 0','Environment setup failed, script exited with code 1') }
  if ($r.Json.verdict -ne 'cache-poison-suspected' -or $r.Json.resetCacheAction -notmatch 'Reset cache') { throw 'cache diagnosis missing' }
  git -C $repo remote remove origin
  $r = Invoke-Case @{ Repository=$repo; BriefFile=$brief; EnvironmentId='env' }
  if ($r.Json.verdict -ne 'remote-missing') { throw "remote case was $($r.Json.verdict)" }
  git -C $repo remote add origin2 https://example.invalid/other.git
  git -C $repo remote set-url origin https://example.invalid/repo.git
  $r = Invoke-Case @{ Repository=$repo; BriefFile=$brief }
  if ($r.Json.verdict -ne 'environment-missing') { throw "environment case was $($r.Json.verdict)" }
  # A directory that is not a repository made every Git call exit non-zero, which the script read
  # as "no unmerged entries, no remotes" and reported as remote-missing -- sending the operator to
  # fix a remote that never existed. A refusal is not an answer.
  $bare = Join-Path $root 'not-a-repo'; New-Item -ItemType Directory $bare | Out-Null
  $r = Invoke-Case @{ Repository=$bare; BriefFile=$brief; EnvironmentId='env' }
  if ($r.Json.verdict -ne 'git-inspection-failed') { throw "non-repository case was $($r.Json.verdict)" }
  if ($r.Json.command -ne 'git ls-files -u') { throw "non-repository case blamed $($r.Json.command)" }
  if ($r.Exit -ne 1) { throw "non-repository case exited $($r.Exit)" }
  # A cloud agent reads the remote head and nothing else: required inputs (an `Input-path stop` line)
  # must exist there and stop the task when they do not; every other named path is advice.
  $pathOrigin = Join-Path $root 'path-origin.git'; git init -q --bare -b main $pathOrigin
  $pathRepo = Join-Path $root 'path-repo'; git clone -q $pathOrigin $pathRepo 2>$null
  git -C $pathRepo config user.email test@example.invalid; git -C $pathRepo config user.name fixture
  git -C $pathRepo checkout -q -B main
  foreach ($rel in 'docs/present.md', 'src/[id]/page+x.ts', '-opt/y.md') {
    $full = Join-Path $pathRepo $rel; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $full) | Out-Null; Set-Content -LiteralPath $full -Value fixture
  }
  git -C $pathRepo add -- docs src '-opt'; git -C $pathRepo commit -qm fixtures; git -C $pathRepo push -q origin main
  $pathBrief = Join-Path $root 'path-brief.md'
  function Invoke-PathCase([string]$Text, [string]$Repo = $pathRepo) {
    [IO.File]::WriteAllText($pathBrief, $Text, [Text.UTF8Encoding]::new($false))
    Invoke-Case @{ Repository=$Repo; BriefFile=$pathBrief; EnvironmentId='env' }
  }
  $r = Invoke-PathCase 'Input-path stop: `docs/present.md` `src/[id]/page+x.ts` `-opt/y.md`'
  if ($r.Json.verdict -ne 'ready' -or $r.Exit -ne 0 -or @($r.Json.absentPaths).Count -ne 0) { throw "required paths present was $($r.Json | ConvertTo-Json -Compress)" }
  $r = Invoke-PathCase ('- **Input-path stop:** `docs/present.md`' + "`n" + '  and `docs/gone.md` `-opt/missing.md` `<path>` `/abs/x.md` `src/*.ts`' + "`n`n" + '- Owned paths: `docs/new.md`')
  if ($r.Json.verdict -ne 'brief-input-path-missing' -or $r.Exit -ne 1 -or (@($r.Json.paths) -join ',') -ne '-opt/missing.md,docs/gone.md' -or $r.Json.remoteVisible -ne $true) { throw "required paths absent was $($r.Json | ConvertTo-Json -Compress)" }
  $r = Invoke-PathCase ('Input-path stop: `docs/present.md`' + "`n" + 'Owned paths: `docs/new.md`, `src/[id]/page+y.ts`')
  if ($r.Json.verdict -ne 'ready' -or $r.Exit -ne 0 -or (@($r.Json.absentPaths) -join ',') -ne 'docs/new.md,src/[id]/page+y.ts') { throw "advisory path was $($r.Json | ConvertTo-Json -Compress)" }
  $many = (1..53 | ForEach-Object { 'Mention `gen/f{0:D2}.txt`.' -f $_ }) -join "`n"
  $r = Invoke-PathCase $many
  if ($r.Json.verdict -ne 'ready' -or @($r.Json.absentPaths).Count -ne 50 -or $r.Json.absentPathsTruncated -ne $true) { throw "advisory cap was $($r.Json | ConvertTo-Json -Compress)" }
  # Second round: line references, tokens that are not paths, where the stop block ends, a stop line that
  # refers back to a list above it. Each row: N name, T lines, V verdict, then optional P (paths), A
  # (absentPaths) and C (pathCheck pattern).
  git -C $pathRepo branch feature/v1.beta; git -C $pathRepo tag release/notes.final
  $four = @('- `docs/present.md`', '- `src/[id]/page+x.ts`', '- `-opt/y.md`', '- `docs/gone.md`', '')
  $rounds = @(
    @{ N = 'suffix-range-present'; T = @('Input-path stop: `docs/present.md:12-20` `docs/present.md:36,53,54`'); V = 'ready'; A = '' }
    @{ N = 'suffix-range-absent'; T = @('Input-path stop: `docs/gone.md:12-20` `docs/gone2.md:36,53,54` `docs/gone3.md:4:5`'); V = 'brief-input-path-missing'; P = 'docs/gone.md,docs/gone2.md,docs/gone3.md' }
    @{ N = 'suffix-advisory'; T = @('Mention `docs/present.md:12-20` and `docs/new.md#L3-L9`.'); V = 'ready'; A = 'docs/new.md' }
    @{ N = 'not-path-refs-and-ids'; T = @('Input-path stop: `origin/main` `gpt-6-luna` `2026.08.31-4057e58` `origin/main:docs/present.md` `:docs/present.md` `feature/v1.beta` `release/notes.final`'); V = 'ready'; A = '' }
    @{ N = 'not-path-unknown-ref-still-stops'; T = @('Input-path stop: `feature/v9.beta`'); V = 'brief-input-path-missing'; P = 'feature/v9.beta' }
    @{ N = 'extensionless-slash-is-advice'; T = @('Input-path stop: `bin/tool`'); V = 'ready'; A = 'bin/tool' }
    @{ N = 'folder-slash-required'; T = @('Input-path stop: `gone-dir/` `bin/tool/`'); V = 'brief-input-path-missing'; P = 'bin/tool,gone-dir' }
    @{ N = 'dotfile-required'; T = @('Input-path stop: `.gone-rc`'); V = 'brief-input-path-missing'; P = '.gone-rc' }
    @{ N = 'end-na-then-paragraph'; T = @('Input-path stop: n/a', 'Creates `docs/new.md`.'); V = 'ready'; A = 'docs/new.md' }
    @{ N = 'end-parens-none-then-paragraph'; T = @('Input-path stop: (none)', 'Creates `docs/new.md`.'); V = 'ready'; A = 'docs/new.md' }
    @{ N = 'end-not-applicable-then-paragraph'; T = @('Input-path stop: not applicable.', 'Creates `docs/new.md`.'); V = 'ready'; A = 'docs/new.md' }
    @{ N = 'end-none-dot-then-paragraph'; T = @('Input-path stop: none.', 'Creates `docs/new.md`.'); V = 'ready'; A = 'docs/new.md' }
    @{ N = 'end-template-sentence-then-paragraph'; T = @('Input-path stop: check each exact input path before loading unrelated workflows; stop if a required path is missing.', 'Creates `docs/new.md`.'); V = 'ready'; A = 'docs/new.md' }
    @{ N = 'end-path-line-then-paragraph'; T = @('Input-path stop: `docs/present.md`', 'Create `docs/new.md` yourself.'); V = 'ready'; A = 'docs/new.md' }
    @{ N = 'end-keeps-nested-list'; T = @('Input-path stop: `docs/present.md`', '  - `docs/gone.md`'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'end-keeps-column-zero-list'; T = @('Input-path stop: `docs/present.md`', '- `docs/gone.md`'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'end-keeps-heading-then-next-line'; T = @('## Input-path stop', '`docs/gone.md`'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'end-keeps-heading-blank-list'; T = @('## Input-path stop', '', '- `docs/gone.md`'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'end-keeps-label-blank-paragraph'; T = @('Input-path stop:', '', 'See `docs/gone.md`.'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'refer-back-absent'; T = ($four + 'Input-path stop: if any of those four is missing, stop and say which.'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'refer-back-present'; T = @('- `docs/present.md`', '- `src/[id]/page+x.ts`', '- `-opt/y.md`', '- `docs/`', '', 'Input-path stop: if any of those four is missing, stop and say which.'); V = 'ready'; A = '' }
    @{ N = 'refer-back-count-mismatch'; T = ($four + 'Input-path stop: if any of those three is missing, stop and say which.'); V = 'ready'; C = 'stop-line-not-parsed*' }
    @{ N = 'refer-back-no-count'; T = @('- `docs/gone.md`', '', 'Input-path stop: the paths above must exist.'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'refer-back-over-paragraph-blank'; T = @('We will later write `docs/gone.md` as a new doc.', '', 'Input-path stop: if any of these is missing, stop.'); V = 'ready'; C = 'stop-line-not-parsed*no list sits directly above*'; A = 'docs/gone.md' }
    @{ N = 'refer-back-over-paragraph-no-blank'; T = @('We will later write `docs/gone.md` as a new doc.', 'Input-path stop: if any of these is missing, stop.'); V = 'ready'; C = 'stop-line-not-parsed*no list sits directly above*'; A = 'docs/gone.md' }
    @{ N = 'refer-back-over-label-line'; T = @('Owned paths: `docs/gone.md`', 'Input-path stop: if any of these is missing, stop.'); V = 'ready'; C = 'stop-line-not-parsed*no list sits directly above*'; A = 'docs/gone.md' }
    @{ N = 'refer-back-over-heading-cut'; T = @('- `docs/gone.md`', '', '## Notes', '', 'Input-path stop: if any of those four is missing, stop.'); V = 'ready'; C = 'stop-line-not-parsed*no list sits directly above*' }
    @{ N = 'refer-back-over-nothing'; T = @('Input-path stop: if any of these is missing, stop.'); V = 'ready'; C = 'stop-line-not-parsed*no list sits directly above*' }
    @{ N = 'refer-back-bullets-these-no-count'; T = ($four + 'Input-path stop: if any of these is missing, stop.'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'refer-back-numbered-list'; T = @('1. `docs/present.md`', '2. `docs/gone.md`', '', 'Input-path stop: if any of these is missing, stop.'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'refer-back-checkbox-list'; T = @('- [ ] `docs/present.md`', '- [x] `docs/gone.md`', '', 'Input-path stop: if any of those two is missing, stop.'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'refer-back-count-repeat-matched'; T = @('- `docs/present.md`', '- `docs/gone.md`', '- `docs/gone.md`', '- `-opt/y.md`', '', 'Input-path stop: if any of those four is missing, stop.'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'label-plural-stops'; T = @('Input-path stops: `docs/gone.md`'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
    @{ N = 'label-path-s'; T = @('Input path(s) stop: `docs/gone.md`'); V = 'brief-input-path-missing'; P = 'docs/gone.md' }
  )
  $roundFailures = @()
  foreach ($c in $rounds) {
    $r = Invoke-PathCase ($c.T -join "`n"); $j = $r.Json
    $ok = $j.verdict -eq $c.V
    if ($ok -and $c.ContainsKey('P')) { $ok = (@($j.paths) -join ',') -eq $c.P }
    if ($ok -and $c.ContainsKey('A')) { $ok = (@($j.absentPaths) -join ',') -eq $c.A }
    if ($ok -and $c.ContainsKey('C')) { $ok = [string]$j.pathCheck -like $c.C }
    if (-not $ok) { $roundFailures += "FAIL [$($c.N)] verdict=$($j.verdict) paths=$(@($j.paths) -join ',') absent=$(@($j.absentPaths) -join ',') pathCheck=$($j.pathCheck)" }
  }
  $r = Invoke-PathCase 'Input-path stop: `docs/gone.md`'
  if ($r.Json.explanation -notmatch 'take it off the stop block' -or $r.Json.explanation -notmatch 'merge') { $roundFailures += "FAIL [explanation-offers-take-it-off] explanation=$($r.Json.explanation)" }
  if ($roundFailures.Count) { $roundFailures; throw "$($roundFailures.Count) brief path case(s) failed" }
  Set-Content -LiteralPath (Join-Path $pathRepo 'local-only.md') -Value local; git -C $pathRepo add -- local-only.md; git -C $pathRepo commit -qm local
  $r = Invoke-PathCase 'Input-path stop: `local-only.md`'
  if ($r.Json.verdict -ne 'unpushed-local-commits') { throw "unpushed local path was $($r.Json | ConvertTo-Json -Compress)" }
  git -C $pathRepo reset -q --hard HEAD~1
  # A partial clone must not be asked to fetch: the lookup runs with lazy fetching off, so a blob that is not
  # local is never fetched and never reported as absent. Checked with GIT_TRACE: no fetch is run.
  git -C $pathOrigin config uploadpack.allowFilter true; git -C $pathOrigin config uploadpack.allowAnySHA1InWant true
  $blobless = Join-Path $root 'path-blobless'; $traceFile = Join-Path $root 'trace.txt'
  git clone -q -n -b main --filter=blob:none ('file:///' + ($pathOrigin -replace '\\', '/')) $blobless 2>$null
  if ($LASTEXITCODE -ne 0) { throw 'blobless-fixture: could not build a blobless clone on this host' }
  $env:GIT_TRACE = $traceFile
  try { $r = Invoke-PathCase 'Input-path stop: `docs/present.md` `docs/gone.md`' $blobless } finally { Remove-Item Env:GIT_TRACE -ErrorAction SilentlyContinue }
  $traceText = if (Test-Path -LiteralPath $traceFile) { Get-Content -LiteralPath $traceFile -Raw } else { '' }
  $fetches = @([regex]::Matches([string]$traceText, '(?m)run_command:.*\s(?:fetch|fetch-pack)(?:\s|$)|\bfetch-pack\b'))
  if ($fetches.Count -ne 0) { throw "blobless clone: the check ran $($fetches.Count) fetch: $($fetches | Select-Object -First 1)" }
  $right = ($r.Json.verdict -eq 'brief-input-path-missing' -and (@($r.Json.paths) -join ',') -eq 'docs/gone.md') -or ($r.Json.verdict -eq 'ready' -and [string]$r.Json.pathCheck -like 'could-not-tell*')
  if (-not $right) { throw "blobless clone was $($r.Json | ConvertTo-Json -Compress)" }
  $r = Invoke-PathCase 'Input-path stop: `docs/present.md`' $blobless
  if ($r.Json.verdict -ne 'ready' -or @($r.Json.absentPaths).Count -ne 0) { throw "blobless clone, blob not downloaded, was $($r.Json | ConvertTo-Json -Compress)" }
  # The remote head is a commit this checkout has never fetched: the path check cannot run, the verdict stays.
  $other = Join-Path $root 'path-other'; git clone -q $pathOrigin $other 2>$null
  git -C $other config user.email test@example.invalid; git -C $other config user.name fixture
  Set-Content -LiteralPath (Join-Path $other 'later.md') -Value later; git -C $other add -- later.md; git -C $other commit -qm later; git -C $other push -q origin main
  $r = Invoke-PathCase 'Input-path stop: `later.md` `docs/gone.md`'
  if ($r.Json.verdict -ne 'ready' -or $r.Json.pathCheck -notlike 'could-not-tell*' -or $null -ne $r.Json.absentPaths) { throw "unfetched remote head was $($r.Json | ConvertTo-Json -Compress)" }
  'PASS: preflight diagnoses cache poison, refuses missing environment/remote, separates a Git refusal from an answer, and checks the brief paths at the remote head'
} finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
