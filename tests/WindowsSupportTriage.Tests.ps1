BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    Import-Module "$root/src/WindowsSupportTriage.psd1" -Force
    function Read-Fixture([string]$Name) {
        Get-Content "$root/examples/$Name.json" -Raw | ConvertFrom-Json -AsHashtable
    }
}

Describe 'Evidence interpretation' {
    It 'preserves timestamp meaning when the JSON parser returns DateTime values' {
        $snapshot = Read-Fixture 'healthy'
        $snapshot.CollectedAtUtc = [DateTime]::new(2026, 11, 4, 12, 0, 0, [DateTimeKind]::Utc)
        $snapshot.Checks.OperatingSystem.Data.LastBootUtc = [DateTime]::new(2026, 11, 3, 12, 0, 0, [DateTimeKind]::Utc)
        (Get-EndpointFinding $snapshot | Where-Object Check -EQ 'OperatingSystem').Evidence | Should -Match '1 days'
    }
    It 'flags a stopped spooler in a printing case' {
        $findings = @(Get-EndpointFinding (Read-Fixture 'printing'))
        $spooler = $findings | Where-Object Check -EQ 'PrintSpooler'
        $spooler.State | Should -Be 'Attention'
        $spooler.NextStep | Should -Match 'policy'
        $spooler.NextStep | Should -Match 'test page'
    }
    It 'does not call low disk space a proven root cause' {
        $findings = @(Get-EndpointFinding (Read-Fixture 'low-disk'))
        ($findings | Where-Object Check -EQ 'SystemDisk').State | Should -Be 'Attention'
        ($findings | Where-Object Check -EQ 'RestartIndicators').State | Should -Be 'Attention'
        ($findings.Evidence -join ' ') | Should -Not -Match 'caused|root cause'
    }
    It 'uses the unrounded free percentage at the threshold' {
        $snapshot = Read-Fixture 'healthy'
        $snapshot.Checks.SystemDisk.Data = @{ SizeBytes = 1000GB; FreeBytes = 99.96GB }
        (Get-EndpointFinding $snapshot | Where-Object Check -EQ 'SystemDisk').State | Should -Be 'Attention'
    }
    It 'does not flag disk space at the exact limits' {
        $snapshot = Read-Fixture 'healthy'
        $snapshot.Checks.SystemDisk.Data = @{ SizeBytes = 100GB; FreeBytes = 10GB }
        (Get-EndpointFinding $snapshot | Where-Object Check -EQ 'SystemDisk').State | Should -Be 'Info'
    }
    It 'marks failed collection as unknown rather than healthy' {
        $findings = @(Get-EndpointFinding (Read-Fixture 'unavailable'))
        @($findings | Where-Object State -EQ 'Unknown').Count | Should -Be 4
    }
    It 'marks a missing check as unknown' {
        $snapshot = Read-Fixture 'healthy'
        $snapshot.Checks.Remove('SystemDisk')
        (Get-EndpointFinding $snapshot | Where-Object Check -EQ 'SystemDisk').State | Should -Be 'Unknown'
    }
    It 'does not flag a spooler that was not requested' {
        $findings = @(Get-EndpointFinding (Read-Fixture 'healthy'))
        @($findings | Where-Object Check -EQ 'PrintSpooler').Count | Should -Be 0
        @($findings | Where-Object State -EQ 'Attention').Count | Should -Be 0
    }
    It 'rejects an impossible free disk value' {
        $snapshot = Read-Fixture 'healthy'
        $snapshot.Checks.SystemDisk.Data.FreeBytes = -1
        { Get-EndpointFinding $snapshot } | Should -Throw '*disk capacity*'
    }
    It 'rejects an unsupported schema' {
        $snapshot = Read-Fixture 'healthy'
        $snapshot.SchemaVersion = 2
        { Get-EndpointFinding $snapshot } | Should -Throw '*snapshot*'
    }
    It 'does not confuse unrecognised collection state with success' {
        $snapshot = Read-Fixture 'healthy'
        $snapshot.Checks.SystemDisk.Status = 'Anything'
        { Get-EndpointFinding $snapshot } | Should -Throw '*evidence*'
    }
}

Describe 'Ticket output' {
    It 'clearly labels demo evidence and does not claim resolution' {
        $report = ConvertTo-EndpointReport (Read-Fixture 'printing') -CaseReference 'INC-1001'
        $report | Should -Match 'Fictional example'
        $report | Should -Match '2026-11-04T12:00:00'
        $report | Should -Match 'No device was inspected or repaired'
        $report | Should -Match 'User verification and outcome: not recorded'
    }
    It 'does not claim that an event count is the full log total' {
        $report = ConvertTo-EndpointReport (Read-Fixture 'printing') -CaseReference 'INC-1001'
        $report | Should -Match 'capped at 20'
        $report | Should -Match 'do not prove'
    }
    It 'rejects path traversal in a case reference' {
        { ConvertTo-EndpointReport (Read-Fixture 'healthy') -CaseReference '../outside' } | Should -Throw
    }
    It 'creates both output formats without overwriting a previous case' {
        $folder = Join-Path $TestDrive 'case'
        & "$root/scripts/Invoke-EndpointTriage.ps1" -Demo printing -CaseReference 'LAB-1001' -OutputDirectory $folder
        Test-Path "$folder/LAB-1001.md" | Should -BeTrue
        $raw = Get-Content "$folder/LAB-1001.json" -Raw | ConvertFrom-Json
        $raw.Source | Should -Be 'Demo'
        $hash = (Get-FileHash "$folder/LAB-1001.md").Hash
        { & "$root/scripts/Invoke-EndpointTriage.ps1" -Demo healthy -CaseReference 'LAB-1001' -OutputDirectory $folder } | Should -Throw '*already*'
        (Get-FileHash "$folder/LAB-1001.md").Hash | Should -Be $hash
    }
}

Describe 'Platform boundary' {
    It 'rejects live collection on a non-Windows host' -Skip:$IsWindows {
        { Get-EndpointSnapshot } | Should -Throw '*requires Windows*'
    }
}
