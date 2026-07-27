[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Item,

    [Parameter(Mandatory = $true)]
    [string]$Field,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')]
    [string]$EnvironmentVariable,

    [Parameter(Mandatory = $true)]
    [string]$Executable,

    [string[]]$ArgumentList = @(),

    [string]$BwPath = 'bw.cmd',

    [string]$PolicyPath = (Join-Path $PSScriptRoot 'credential-command-policy.json')
)

$ErrorActionPreference = 'Stop'

if ($EnvironmentVariable -in @('BW_SESSION', 'BWS_ACCESS_TOKEN')) {
    throw "Reserved bootstrap credential cannot be used as the child destination: $EnvironmentVariable"
}
if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
    throw "Credential command policy is missing: $PolicyPath"
}

$resolvedExecutable = if (Test-Path -LiteralPath $Executable -PathType Leaf) {
    (Resolve-Path -LiteralPath $Executable).Path
}
else {
    (Get-Command $Executable -CommandType Application -ErrorAction Stop).Source
}

$policy = Get-Content -LiteralPath $PolicyPath -Raw | ConvertFrom-Json
$approval = @($policy.commands | Where-Object {
    [string]::Equals([string]$_.item, $Item, [StringComparison]::Ordinal) -and
    [string]::Equals([string]$_.field, $Field, [StringComparison]::Ordinal) -and
    [string]::Equals([string]$_.environmentVariable, $EnvironmentVariable, [StringComparison]::Ordinal) -and
    [string]::Equals([string]$_.executable, $resolvedExecutable, [StringComparison]::OrdinalIgnoreCase)
})

$matchingApproval = $null
foreach ($candidate in $approval) {
    $expected = @($candidate.argumentList)
    if ($expected.Count -ne $ArgumentList.Count) { continue }
    $same = $true
    for ($i = 0; $i -lt $expected.Count; $i += 1) {
        if (-not [string]::Equals([string]$expected[$i], [string]$ArgumentList[$i], [StringComparison]::Ordinal)) {
            $same = $false
            break
        }
    }
    if ($same) {
        $matchingApproval = $candidate
        break
    }
}
if (-not $matchingApproval) {
    throw 'The request does not match an approved full command tuple.'
}

$bwCommand = if (Test-Path -LiteralPath $BwPath -PathType Leaf) {
    (Resolve-Path -LiteralPath $BwPath).Path
}
else {
    (Get-Command $BwPath -CommandType Application -ErrorAction Stop).Source
}
if ([string]::IsNullOrWhiteSpace($env:BW_SESSION)) {
    throw 'Bitwarden is locked. Douglas must unlock it interactively in this terminal.'
}

$rawItem = $null
$vaultItem = $null
$secretValue = $null
$previousValue = [Environment]::GetEnvironmentVariable($EnvironmentVariable, 'Process')
$previousSession = [Environment]::GetEnvironmentVariable('BW_SESSION', 'Process')

try {
    $rawItem = & $bwCommand get item $Item
    if ($LASTEXITCODE -ne 0) {
        throw 'Bitwarden could not retrieve the approved item.'
    }
    $vaultItem = $rawItem | ConvertFrom-Json
    $matches = @($vaultItem.fields | Where-Object {
        [string]::Equals([string]$_.name, $Field, [StringComparison]::Ordinal)
    })
    if ($matches.Count -ne 1 -or [string]::IsNullOrEmpty([string]$matches[0].value)) {
        throw 'The approved Bitwarden custom field was missing, ambiguous, or empty.'
    }
    $secretValue = [string]$matches[0].value

    [Environment]::SetEnvironmentVariable($EnvironmentVariable, $secretValue, 'Process')
    [Environment]::SetEnvironmentVariable('BW_SESSION', $null, 'Process')
    & $resolvedExecutable @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "Approved credential-dependent command failed with exit code $LASTEXITCODE."
    }
}
finally {
    [Environment]::SetEnvironmentVariable($EnvironmentVariable, $previousValue, 'Process')
    [Environment]::SetEnvironmentVariable('BW_SESSION', $previousSession, 'Process')
    $secretValue = $null
    $rawItem = $null
    $vaultItem = $null
    $previousSession = $null
    $previousValue = $null
}
