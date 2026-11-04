@{
    Severity = @('Error', 'Warning')
    IncludeRules = @(
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseApprovedVerbs'
        'PSAvoidGlobalVars'
        'PSAvoidUsingEmptyCatchBlock'
        'PSPossibleIncorrectComparisonWithNull'
        'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
    )
    Rules = @{
        PSUseConsistentIndentation = @{ Enable = $true; Kind = 'space'; IndentationSize = 4 }
        PSUseConsistentWhitespace = @{ Enable = $true }
    }
}
