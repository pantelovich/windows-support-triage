@{
    RootModule = 'WindowsSupportTriage.psm1'
    ModuleVersion = '0.1.0'
    GUID = '3687b817-321d-4ba0-b90e-90de9cedc038'
    Author = 'Panteleimon Tzompanakis'
    Description = 'Read-only Windows endpoint evidence and support reports.'
    PowerShellVersion = '7.4'
    FunctionsToExport = @('Get-EndpointSnapshot', 'Get-EndpointFinding', 'ConvertTo-EndpointReport')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
