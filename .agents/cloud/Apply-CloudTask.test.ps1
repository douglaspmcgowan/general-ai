#requires -Version 7
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'Apply-CloudTask.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('cloud-apply-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
  $repo = Join-Path $root 'repo'; New-Item -ItemType Directory $repo | Out-Null
  git -C $repo init -q; git -C $repo config user.email test@example.invalid; git -C $repo config user.name fixture
  Set-Content (Join-Path $repo 'seed.txt') seed; git -C $repo add .; git -C $repo commit -qm seed
  $source = Join-Path $repo 'source'; New-Item -ItemType Directory $source | Out-Null; Set-Content (Join-Path $source 'new.txt') 'new'
  $patch = Join-Path $root 'patch'; Push-Location $repo; & git diff --no-index -- /dev/null source/new.txt 2>$null | Set-Content $patch; Pop-Location
  Remove-Item (Join-Path $source 'new.txt')
  if ($IsWindows) {
    $codex = Join-Path $root 'codex.cmd'
    Set-Content $codex '@echo off'
    Add-Content $codex ('type "{0}"' -f $patch)
  }
  else {
    $codex = Join-Path $root 'codex'
    Set-Content $codex "#!/bin/sh`ncat '$patch'" -Encoding utf8NoBOM
    & chmod +x $codex
  }
  $r = & pwsh -NoProfile -File $script -Repository $repo -TaskId task_fixture -CodexBinary $codex -ExpectedPath 'source/new.txt' 2>&1
  if ($LASTEXITCODE -ne 0) { throw "apply exited $LASTEXITCODE`n$r" }
  if (-not (Test-Path (Join-Path $repo 'source/new.txt'))) { throw 'expected file was not applied' }
  $r = & pwsh -NoProfile -File $script -Repository $repo -TaskId task_fixture -CodexBinary $codex -ExpectedPath missing.txt 2>&1
  if ($LASTEXITCODE -eq 0 -or (($r | Out-String) -notmatch 'patch-path-mismatch')) { throw 'path mismatch was accepted' }
  'PASS: apply requires an exact non-empty diff and leaves expected paths landed'
} finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
