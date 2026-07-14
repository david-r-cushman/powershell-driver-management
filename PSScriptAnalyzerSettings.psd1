@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @()

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
            CheckParameter = $true
            IgnoreWhitespaceAroundPipe = $false
        }
    }
}
