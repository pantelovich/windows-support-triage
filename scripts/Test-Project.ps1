#Requires -Version 7.4
[CmdletBinding()]
param([switch]$WindowsSmoke)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module PSScriptAnalyzer -ErrorAction Stop
$issues = @(Invoke-ScriptAnalyzer -Path $root -Recurse -Settings "$root/PSScriptAnalyzerSettings.psd1")
if ($issues.Count) { $issues | Format-Table; throw 'PowerShell analysis failed.' }
Import-Module Pester -MinimumVersion 5.6.1 -ErrorAction Stop
$result = Invoke-Pester -Path "$root/tests" -PassThru -Output Detailed
if ($result.FailedCount -gt 0 -or $result.PassedCount -lt 14) { throw 'Unit checks failed or did not run.' }
if ($WindowsSmoke) {
    if (-not $IsWindows) { throw 'Windows smoke requires Windows.' }
    Import-Module "$root/src/WindowsSupportTriage.psd1" -Force
    $snapshot = Get-EndpointSnapshot -Symptom Printing
    foreach ($name in @('OperatingSystem', 'SystemDisk', 'RestartIndicators', 'PrintSpooler', 'SystemEvents', 'ApplicationEvents')) {
        if ($snapshot.Checks[$name].Status -ne 'Collected') { throw "Windows collection failed: $name" }
    }
    $report = ConvertTo-EndpointReport -Snapshot $snapshot -CaseReference 'CI-1001'
    if ($report -notmatch 'Source: Live') { throw 'Live smoke report was not generated.' }
    Write-Output 'Windows live collection smoke passed. No live reports uploaded.'
}
