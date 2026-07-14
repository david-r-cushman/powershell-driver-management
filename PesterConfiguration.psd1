@{
    Run = @{
        Path = @(
            'tests'
        )
        PassThru = $true
        Exit = $false
    }

    Output = @{
        Verbosity = 'Detailed'
    }

    TestResult = @{
        Enabled = $true
        OutputPath = 'TestResults.xml'
        OutputFormat = 'NUnitXml'
    }

    CodeCoverage = @{
        Enabled = $false
    }
}
