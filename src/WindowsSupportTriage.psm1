Set-StrictMode -Version Latest

function Invoke-EvidenceCheck {
    param([scriptblock]$Read)
    try {
        @{ Status = 'Collected'; Data = (& $Read); Error = $null }
    }
    catch {
        # Full exception messages can contain local paths and user information.
        @{ Status = 'Unavailable'; Data = $null; Error = $_.Exception.GetType().Name }
    }
}

function Get-EndpointSnapshot {
    <# .SYNOPSIS
    Read selected local Windows health evidence without changing settings.
    #>
    [CmdletBinding()]
    param([ValidateSet('General', 'Printing', 'Performance')][string]$Symptom = 'General')

    if (-not $IsWindows) {
        throw 'Live collection requires Windows. Use the offline demo on macOS or Linux.'
    }
    $checks = [ordered]@{}
    $checks.OperatingSystem = Invoke-EvidenceCheck {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 10 -ErrorAction Stop
        @{
            Caption = $os.Caption
            Version = $os.Version
            LastBootUtc = $os.LastBootUpTime.ToUniversalTime().ToString('o')
        }
    }
    $checks.SystemDisk = Invoke-EvidenceCheck {
        $drive = [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\')
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$drive'" -OperationTimeoutSec 10 -ErrorAction Stop
        if ($null -eq $disk -or $disk.Size -le 0) { throw 'No valid system disk information returned.' }
        @{ SizeBytes = [long]$disk.Size; FreeBytes = [long]$disk.FreeSpace }
    }
    $checks.RestartIndicators = Invoke-EvidenceCheck {
        $indicators = @()
        $paths = @{
            ComponentServicing = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
            WindowsUpdate = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        }
        foreach ($name in $paths.Keys) {
            if (Test-Path -LiteralPath $paths[$name] -ErrorAction Stop) { $indicators += $name }
        }
        # Do not export file paths held in PendingFileRenameOperations.
        $session = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction Stop
        $pending = $session.PSObject.Properties['PendingFileRenameOperations']
        if ($null -ne $pending -and @($pending.Value).Count -gt 0) { $indicators += 'PendingFileRename' }
        @{ Indicators = @($indicators) }
    }
    $checks.PrintSpooler = @{ Status = 'NotRequested'; Data = $null; Error = $null }
    if ($Symptom -eq 'Printing') {
        $checks.PrintSpooler = Invoke-EvidenceCheck {
            $service = Get-Service -Name Spooler -ErrorAction Stop
            @{ State = $service.Status.ToString(); StartType = $service.StartType.ToString() }
        }
    }
    foreach ($log in @('System', 'Application')) {
        $checks["${log}Events"] = Invoke-EvidenceCheck {
            $events = @()
            try {
                $events = @(Get-WinEvent -FilterHashtable @{
                        LogName = $log; Level = @(1, 2); StartTime = (Get-Date).AddHours(-24)
                    } -MaxEvents 20 -ErrorAction Stop)
            }
            catch {
                if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw }
            }
            @{
                WindowHours = 24
                Limit = 20
                Events = @($events | ForEach-Object {
                        @{
                            Id = $_.Id
                            Provider = $_.ProviderName
                            TimeUtc = $_.TimeCreated.ToUniversalTime().ToString('o')
                        }
                    })
            }
        }
    }
    @{
        SchemaVersion = 1
        Source = 'Live'
        CollectedAtUtc = [DateTime]::UtcNow.ToString('o')
        Symptom = $Symptom
        Checks = $checks
    }
}

function Get-EndpointFinding {
    <# .SYNOPSIS
    Interpret a snapshot. A finding suggests a next check, not a confirmed cause.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Snapshot)

    if ($Snapshot.SchemaVersion -ne 1 -or $null -eq $Snapshot.Checks) {
        throw 'Unsupported or incomplete snapshot.'
    }
    foreach ($name in @('OperatingSystem', 'SystemDisk', 'RestartIndicators', 'PrintSpooler', 'SystemEvents', 'ApplicationEvents')) {
        $check = $Snapshot.Checks[$name]
        if ($null -eq $check -or $check.Status -eq 'Unavailable') {
            [pscustomobject]@{
                Check = $name; State = 'Unknown'
                Evidence = 'Collection was unavailable.'
                NextStep = 'Review access or platform support. Do not treat missing evidence as healthy.'
            }
            continue
        }
        if ($check.Status -eq 'NotRequested') { continue }
        if ($check.Status -ne 'Collected' -or $null -eq $check.Data) { throw "Invalid evidence for $name." }
        $state = 'Info'
        switch ($name) {
            'OperatingSystem' {
                # JSON timestamps can arrive as strings or DateTime objects.
                $boot = [DateTimeOffset]$check.Data.LastBootUtc
                $collected = [DateTimeOffset]$Snapshot.CollectedAtUtc
                $days = [math]::Round(($collected - $boot).TotalDays, 1)
                $evidence = "Windows version $($check.Data.Version). Days since last boot: $days."
                $next = 'Confirm the affected application and recent changes. Uptime alone does not identify the fault.'
            }
            'SystemDisk' {
                $size = [double]$check.Data.SizeBytes
                $free = [double]$check.Data.FreeBytes
                if ($size -le 0 -or $free -lt 0 -or $free -gt $size) { throw 'Invalid disk capacity values.' }
                $gib = [math]::Round($free / 1GB, 1)
                $percent = [math]::Round(100 * $free / $size, 1)
                $evidence = "$gib GiB free ($percent percent) on the system disk."
                $next = 'Compare free space with the application requirement.'
                if ($free -lt 10GB -or (100 * $free / $size) -lt 10) {
                    $state = 'Attention'
                    $next = 'Review approved storage cleanup with the user. Preserve their files and retest the affected application.'
                }
            }
            'RestartIndicators' {
                $count = @($check.Data.Indicators).Count
                $evidence = "$count restart indicators found in the limited registry checks."
                $next = 'No indicator found is not proof that every update is complete.'
                if ($count -gt 0) {
                    $state = 'Attention'
                    $next = 'Agree a suitable restart time and save work first. Recheck after restart; an indicator is not a confirmed cause.'
                }
            }
            'PrintSpooler' {
                $evidence = "Print Spooler state is $($check.Data.State); start type is $($check.Data.StartType)."
                $next = 'If the service is running, check the printer, connection, queue and driver. A running service does not prove printing works.'
                if ($check.Data.State -ne 'Running') {
                    $state = 'Attention'
                    $next = 'Confirm printing is expected on this device and check policy before an authorised service change. Then print a test page.'
                }
            }
            default {
                $count = @($check.Data.Events).Count
                $evidence = "$count recent critical or error events returned, capped at $($check.Data.Limit) for this log."
                $next = 'Correlate event times and providers with the incident. These events do not prove the reported fault.'
            }
        }
        [pscustomobject]@{ Check = $name; State = $state; Evidence = $evidence; NextStep = $next }
    }
}

function ConvertTo-EndpointReport {
    <# .SYNOPSIS
    Create Markdown evidence and a ticket handover that leaves repairs unclaimed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Snapshot,
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]{2,39}$')][string]$CaseReference
    )
    $findings = @(Get-EndpointFinding -Snapshot $Snapshot)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# Endpoint triage: $CaseReference")
    $lines.Add('')
    $timestamp = ([DateTimeOffset]$Snapshot.CollectedAtUtc).ToUniversalTime().ToString('o')
    $lines.Add("Source: $($Snapshot.Source). Collected: $timestamp. Symptom: $($Snapshot.Symptom).")
    $lines.Add('')
    if ($Snapshot.Source -eq 'Demo') { $lines.Add('Fictional example. No device was inspected or repaired.'); $lines.Add('') }
    foreach ($finding in $findings) {
        $lines.Add("## $($finding.Check): $($finding.State)")
        $lines.Add($finding.Evidence)
        $lines.Add("Next check: $($finding.NextStep)")
        $lines.Add('')
    }
    $lines.Add('## Ticket handover')
    $lines.Add('- Impact and affected users: technician to confirm.')
    $lines.Add('- Symptoms and start time: technician to record.')
    $lines.Add('- Checks completed: evidence above. Collection is read only.')
    $lines.Add('- Approved action and owner: not recorded.')
    $lines.Add('- User verification and outcome: not recorded. Do not close the ticket from this report alone.')
    $lines.Add('- Escalation and next update time: technician to record.')
    $lines.Add('')
    $lines.Add('No account, licence, domain trust, device compliance, network connectivity or update compliance checks are performed.')
    $lines -join [Environment]::NewLine
}

Export-ModuleMember -Function Get-EndpointSnapshot, Get-EndpointFinding, ConvertTo-EndpointReport
