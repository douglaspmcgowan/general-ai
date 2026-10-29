#requires -Version 7
# Thin forwarder. The one safe-apply owner is .agents/conductor/Apply-CloudTask.ps1
# (CLOUD-PROTOCOL.md section 7.1); this path is kept only so existing callers and the
# installed .agents/cloud tree keep working. Add behavior to the conductor copy, never here.
[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory)][string]$Repository,
  [Parameter(Mandatory)][string]$TaskId,
  [string]$CodexBinary,
  [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$ExpectedPath,
  [string]$ExpectedPatchSha256,
  [string]$LedgerPath
)
$ErrorActionPreference = 'Stop'
$owner = Join-Path (Split-Path -Parent $PSScriptRoot) 'conductor\Apply-CloudTask.ps1'
if (-not (Test-Path -LiteralPath $owner -PathType Leaf)) {
  [ordered]@{ verdict = 'apply-failed'; message = "safe-apply owner missing: $owner" } | ConvertTo-Json -Compress
  exit 3
}
& $owner @PSBoundParameters
exit $LASTEXITCODE
