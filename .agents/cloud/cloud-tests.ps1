#requires -Version 7
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
# Three suite names were listed here by hand, and the kit grew two more that this aggregate never
# ran: Capture-DuplicateDiscovery.test.ps1 and codex-sandbox-fallback-documented-check.test.ps1.
# Both ship to every enrolled project through the cloud-kit manifest, so each project carried two
# suites nothing executed. Discover them: a kit suite added later runs with no wiring at all.
$tests = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.test.ps1' -File | Sort-Object Name)
if ($tests.Count -eq 0) { throw "No cloud-kit PowerShell suites found beside $PSScriptRoot." }

foreach ($test in $tests) {
    $output = @(& pwsh -NoProfile -File $test.FullName 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "$($test.Name) exited $LASTEXITCODE.`n$($output -join "`n")" }
    Write-Output "PASS: $($test.Name)"
}

$coverageTest = Join-Path (Split-Path $PSScriptRoot -Parent) 'tools/Measure-CloudKitCoverage.test.ps1'
$output = @(& pwsh -NoProfile -File $coverageTest 2>&1)
if ($LASTEXITCODE -ne 0) { throw "Measure-CloudKitCoverage.test.ps1 exited $LASTEXITCODE.`n$($output -join "`n")" }
Write-Output 'PASS: Measure-CloudKitCoverage.test.ps1'

$output = @(& bash (Join-Path $PSScriptRoot 'setup.test.sh') 2>&1)
if ($LASTEXITCODE -ne 0) { throw "setup.test.sh exited $LASTEXITCODE.`n$($output -join "`n")" }
Write-Output 'PASS: setup.test.sh'

Write-Output "PASS: cloud setup, preflight, safe apply, and rollout classification ($($tests.Count + 2) suites)."
