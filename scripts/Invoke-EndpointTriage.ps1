#Requires -Version 7.4
[CmdletBinding(DefaultParameterSetName = 'Demo')]
param(
    [Parameter(ParameterSetName = 'Demo')]
    [ValidateSet('printing', 'low-disk', 'healthy', 'unavailable')]
    [string]$Demo = 'printing',
    [Parameter(Mandatory, ParameterSetName = 'Live')][switch]$Live,
    [Parameter(ParameterSetName = 'Live')]
    [ValidateSet('General', 'Printing', 'Performance')][string]$Symptom = 'General',
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]{2,39}$')][string]$CaseReference = 'LAB-1001',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../reports')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/WindowsSupportTriage.psd1') -Force
if ($Live) { $snapshot = Get-EndpointSnapshot -Symptom $Symptom }
else {
    $snapshot = Get-Content -LiteralPath (Join-Path $PSScriptRoot "../examples/$Demo.json") -Raw | ConvertFrom-Json -AsHashtable
}
$report = ConvertTo-EndpointReport -Snapshot $snapshot -CaseReference $CaseReference
$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
$OutputDirectory = (Get-Item -LiteralPath $OutputDirectory).FullName
$markdownPath = Join-Path $OutputDirectory "$CaseReference.md"
$jsonPath = Join-Path $OutputDirectory "$CaseReference.json"
if ((Test-Path -LiteralPath $markdownPath) -or (Test-Path -LiteralPath $jsonPath)) {
    throw 'This case already has output files. Use a new case reference or preserve the existing report elsewhere first.'
}
# CreateNew also prevents overwriting if another process creates the case meanwhile.
foreach ($entry in @(
        @{ Path = $markdownPath; Text = $report },
        @{ Path = $jsonPath; Text = ($snapshot | ConvertTo-Json -Depth 10) }
    )) {
    $stream = [System.IO.File]::Open($entry.Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($entry.Text)
        $stream.Write($bytes, 0, $bytes.Length)
    }
    finally { $stream.Dispose() }
}
Get-Item -LiteralPath $markdownPath, $jsonPath | Select-Object FullName, Length
