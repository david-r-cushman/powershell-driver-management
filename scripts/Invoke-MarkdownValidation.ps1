<#
.SYNOPSIS
    Validates Markdown spacing rules used by repository documentation.

.DESCRIPTION
    Runs repository-owned Markdown validation for README workflow surfaces by
    default, with optional path-based validation for other Markdown files. The
    validator enforces the markdownlint-style blank-line rules that most often
    affect README workflow edits:

    - MD022: headings should be surrounded by blank lines
    - MD032: lists should be surrounded by blank lines

    The existing `.markdownlint.json` file remains the rule toggle source of
    truth. If a supported rule is disabled there, this validator skips it.

.PARAMETER RepoRoot
    Repository root containing `.markdownlint.json`. Defaults to the parent of
    the script directory.

.PARAMETER Path
    Optional Markdown files or directories to validate. When omitted, the
    validator checks the repository root `README.md` and the shared downstream
    `templates/downstream/README.md` when present.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path
)

$ErrorActionPreference = 'Stop'

function Get-MarkdownLintConfig {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ConfigPath
    )

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        throw ('Markdown lint configuration file not found: {0}' -f $ConfigPath)
    }

    return (Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json)
}

function Test-MarkdownRuleEnabled {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        $Config,

        [Parameter(Mandatory)]
        [ValidateSet('MD022', 'MD032')]
        [string]$RuleName
    )

    $rule = $Config.PSObject.Properties[$RuleName]
    if ($null -eq $rule) {
        return $true
    }

    if ($rule.Value -is [bool]) {
        return [bool]$rule.Value
    }

    $enabledProperty = $rule.Value.PSObject.Properties['enabled']
    if ($enabledProperty -and $enabledProperty.Value -is [bool]) {
        return [bool]$enabledProperty.Value
    }

    return $true
}

function Get-DefaultMarkdownPath {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BasePath
    )

    $defaultPaths = @(
        'README.md'
        'templates/downstream/README.md'
    )

    foreach ($relativePath in $defaultPaths) {
        $resolvedPath = Join-Path -Path $BasePath -ChildPath $relativePath
        if (Test-Path -LiteralPath $resolvedPath -PathType Leaf) {
            Get-Item -LiteralPath $resolvedPath
        }
    }
}

function Get-MarkdownPath {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BasePath,

        [Parameter()]
        [string[]]$RequestedPath
    )

    if (-not $RequestedPath) {
        return @(Get-DefaultMarkdownPath -BasePath $BasePath) | Sort-Object -Property FullName -Unique
    }

    $items = foreach ($item in $RequestedPath) {
        $resolvedPath = Resolve-Path -LiteralPath $item -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            throw ('Markdown path not found: {0}' -f $item)
        }

        foreach ($resolved in $resolvedPath) {
            if (Test-Path -LiteralPath $resolved.Path -PathType Leaf) {
                if ([System.IO.Path]::GetExtension($resolved.Path) -ieq '.md') {
                    Get-Item -LiteralPath $resolved.Path
                }

                continue
            }

            Get-ChildItem -LiteralPath $resolved.Path -Recurse -File -Filter '*.md' |
                Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
        }
    }

    return $items | Sort-Object -Property FullName -Unique
}

function Test-IsBlankLine {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Line
    )

    return [string]::IsNullOrWhiteSpace($Line)
}

function Test-IsCommentLine {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Line
    )

    return ($Line -match '^\s*<!--.*-->\s*$')
}

function Test-IsBoundaryLine {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Line
    )

    return ((Test-IsBlankLine -Line $Line) -or (Test-IsCommentLine -Line $Line))
}

function Test-IsHeadingLine {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Line
    )

    return ($Line -match '^\s{0,3}#{1,6}(?:\s+|$)')
}

function Test-IsListItemLine {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Line
    )

    return ($Line -match '^\s{0,3}(?:[-+*]|\d+[.)])\s+')
}

function Get-LineClassification {
    [CmdletBinding()]
    [OutputType([bool[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Line
    )

    $outsideFence = [bool[]]::new($Line.Count)
    $inFence = $false
    $fenceMarker = $null

    for ($index = 0; $index -lt $Line.Count; $index++) {
        $outsideFence[$index] = -not $inFence
        $fenceMatch = [regex]::Match($Line[$index], '^\s*(?<Fence>`{3,}|~{3,})')
        if (-not $fenceMatch.Success) {
            continue
        }

        $marker = $fenceMatch.Groups['Fence'].Value
        if (-not $inFence) {
            $inFence = $true
            $fenceMarker = $marker[0]
            continue
        }

        if ($marker[0] -eq $fenceMarker) {
            $inFence = $false
            $fenceMarker = $null
        }
    }

    return $outsideFence
}

function Get-MarkdownIssue {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory)]
        $Config
    )

    $content = Get-Content -Raw -LiteralPath $FilePath
    $lines = [string[]]($content -split "`r?`n")
    $outsideFence = Get-LineClassification -Line $lines
    $issues = [System.Collections.Generic.List[object]]::new()
    $headingRuleEnabled = Test-MarkdownRuleEnabled -Config $Config -RuleName 'MD022'
    $listRuleEnabled = Test-MarkdownRuleEnabled -Config $Config -RuleName 'MD032'
    $relativePath = [System.IO.Path]::GetRelativePath($RepoPath, $FilePath).Replace('\', '/')

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if (-not $outsideFence[$index]) {
            continue
        }

        $line = $lines[$index]
        if ($headingRuleEnabled -and (Test-IsHeadingLine -Line $line)) {
            $previousLine = if ($index -gt 0) { $lines[$index - 1] } else { $null }
            $nextLine = if ($index + 1 -lt $lines.Count) { $lines[$index + 1] } else { $null }

            if ($index -gt 0 -and -not (Test-IsBoundaryLine -Line $previousLine)) {
                $issues.Add([pscustomobject]@{
                        Path = $relativePath
                        Line = $index + 1
                        Rule = 'MD022'
                        Message = 'Headings should be surrounded by blank lines.'
                    })
            }

            if ($index + 1 -lt $lines.Count -and -not (Test-IsBoundaryLine -Line $nextLine)) {
                $issues.Add([pscustomobject]@{
                        Path = $relativePath
                        Line = $index + 1
                        Rule = 'MD022'
                        Message = 'Headings should be surrounded by blank lines.'
                    })
            }
        }
    }

    if (-not $listRuleEnabled) {
        return $issues
    }

    $index = 0
    while ($index -lt $lines.Count) {
        if (-not $outsideFence[$index]) {
            $index++
            continue
        }

        $line = $lines[$index]
        if (-not (Test-IsListItemLine -Line $line)) {
            $index++
            continue
        }

        $blockEnd = $index
        $scanIndex = $index + 1
        while ($scanIndex -lt $lines.Count) {
            if (-not $outsideFence[$scanIndex]) {
                break
            }

            $nextCandidate = $lines[$scanIndex]
            if (Test-IsListItemLine -Line $nextCandidate) {
                $blockEnd = $scanIndex
                $scanIndex++
                continue
            }

            if (Test-IsBlankLine -Line $nextCandidate) {
                $scanIndex++
                continue
            }

            break
        }

        $previousLine = if ($index -gt 0) { $lines[$index - 1] } else { $null }
        if ($index -gt 0 -and -not (Test-IsBoundaryLine -Line $previousLine)) {
            $issues.Add([pscustomobject]@{
                    Path = $relativePath
                    Line = $index + 1
                    Rule = 'MD032'
                    Message = 'Lists should be surrounded by blank lines.'
                })
        }

        $lineAfterBlock = if ($blockEnd + 1 -lt $lines.Count) { $lines[$blockEnd + 1] } else { $null }
        if ($blockEnd + 1 -lt $lines.Count -and -not (Test-IsBoundaryLine -Line $lineAfterBlock)) {
            $issues.Add([pscustomobject]@{
                    Path = $relativePath
                    Line = $blockEnd + 1
                    Rule = 'MD032'
                    Message = 'Lists should be surrounded by blank lines.'
                })
        }

        $index = $scanIndex
    }

    return $issues
}

$resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$configPath = Join-Path -Path $resolvedRepoRoot -ChildPath '.markdownlint.json'
$config = Get-MarkdownLintConfig -ConfigPath $configPath
$markdownFiles = @(Get-MarkdownPath -BasePath $resolvedRepoRoot -RequestedPath $Path)
$allIssues = [System.Collections.Generic.List[object]]::new()

foreach ($markdownFile in $markdownFiles) {
    foreach ($issue in (Get-MarkdownIssue -RepoPath $resolvedRepoRoot -FilePath $markdownFile.FullName -Config $config)) {
        $allIssues.Add($issue)
    }
}

if ($allIssues.Count -gt 0) {
    $formattedIssues = $allIssues | ForEach-Object {
        '{0}:{1} {2} {3}' -f $_.Path, $_.Line, $_.Rule, $_.Message
    }

    throw ("Markdown validation failed with {0} issue(s):{1}{2}" -f $allIssues.Count, [Environment]::NewLine, ($formattedIssues -join [Environment]::NewLine))
}