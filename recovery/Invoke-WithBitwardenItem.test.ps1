$ErrorActionPreference = 'Stop'

$broker = Join-Path $PSScriptRoot 'Invoke-WithBitwardenItem.ps1'
$root = Join-Path $env:TEMP ("bw-item-broker-test-" + [Guid]::NewGuid().ToString('N'))
$mockBw = Join-Path $root 'mock-bw.cmd'
$child = Join-Path $root 'child.ps1'
$marker = Join-Path $root 'child-marker.txt'
$vaultMarker = Join-Path $root 'vault-marker.txt'
$policyPath = Join-Path $root 'policy.json'
$powershell = (Get-Command powershell.exe -CommandType Application).Source

function Assert-BlockedBeforeVault {
    param(
        [string]$Name,
        [hashtable]$Parameters
    )

    Remove-Item -LiteralPath $vaultMarker -Force -ErrorAction SilentlyContinue
    $blocked = $false
    try {
        & $broker @Parameters
    }
    catch {
        $blocked = $_.Exception.Message -match 'approved full command tuple'
    }
    if (-not $blocked) {
        throw "$Name mismatch was not blocked."
    }
    if (Test-Path -LiteralPath $vaultMarker) {
        throw "$Name mismatch accessed Bitwarden before policy rejection."
    }
}

try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    [System.IO.File]::WriteAllText(
        $mockBw,
        "@echo off`r`n> `"$vaultMarker`" echo accessed`r`necho {`"fields`":[{`"name`":`"REVIEW_SECRET`",`"value`":`"unit-secret`"}]}`r`n",
        [System.Text.Encoding]::ASCII
    )
    [System.IO.File]::WriteAllText(
        $child,
        @'
if ($env:REVIEW_SECRET -ne 'unit-secret') { exit 3 }
if ($env:BW_SESSION) { exit 4 }
[System.IO.File]::WriteAllText($args[0], 'ok')
'@,
        [System.Text.UTF8Encoding]::new($false)
    )

    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $child, $marker)
    $policy = [ordered]@{
        schemaVersion = 2
        commands = @(
            [ordered]@{
                purpose = 'Regression test'
                item = 'project:docket:production'
                field = 'REVIEW_SECRET'
                environmentVariable = 'REVIEW_SECRET'
                executable = $powershell
                argumentList = $arguments
            }
        )
    }
    [System.IO.File]::WriteAllText(
        $policyPath,
        ($policy | ConvertTo-Json -Depth 8) + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )

    $common = @{
        Item = 'project:docket:production'
        Field = 'REVIEW_SECRET'
        EnvironmentVariable = 'REVIEW_SECRET'
        Executable = $powershell
        ArgumentList = $arguments
        BwPath = $mockBw
        PolicyPath = $policyPath
    }

    $priorSession = [Environment]::GetEnvironmentVariable('BW_SESSION', 'Process')
    $priorTarget = [Environment]::GetEnvironmentVariable('REVIEW_SECRET', 'Process')
    [Environment]::SetEnvironmentVariable('BW_SESSION', 'unit-session', 'Process')
    [Environment]::SetEnvironmentVariable('REVIEW_SECRET', 'parent-value', 'Process')
    try {
        & $broker @common
        if (-not (Test-Path -LiteralPath $marker)) {
            throw 'Approved child did not receive the selected field.'
        }
        if ([Environment]::GetEnvironmentVariable('BW_SESSION', 'Process') -ne 'unit-session') {
            throw 'Parent BW_SESSION was not restored.'
        }
        if ([Environment]::GetEnvironmentVariable('REVIEW_SECRET', 'Process') -ne 'parent-value') {
            throw 'Parent destination variable was not restored.'
        }

        $cases = @(
            @{ Name = 'item'; Change = @{ Item = 'project:other:production' } },
            @{ Name = 'field'; Change = @{ Field = 'OTHER_SECRET' } },
            @{ Name = 'environment variable'; Change = @{ EnvironmentVariable = 'OTHER_SECRET' } },
            @{ Name = 'executable'; Change = @{ Executable = (Get-Command cmd.exe -CommandType Application).Source } },
            @{ Name = 'argument list'; Change = @{ ArgumentList = @('-NoProfile') } }
        )
        foreach ($case in $cases) {
            $candidate = $common.Clone()
            foreach ($key in $case.Change.Keys) {
                $candidate[$key] = $case.Change[$key]
            }
            Assert-BlockedBeforeVault -Name $case.Name -Parameters $candidate
        }
    }
    finally {
        [Environment]::SetEnvironmentVariable('BW_SESSION', $priorSession, 'Process')
        [Environment]::SetEnvironmentVariable('REVIEW_SECRET', $priorTarget, 'Process')
    }

    'Bitwarden Password Manager full-tuple broker regression test passed.'
}
finally {
    if (Test-Path -LiteralPath $root) {
        Remove-Item -LiteralPath $root -Recurse -Force
    }
}
