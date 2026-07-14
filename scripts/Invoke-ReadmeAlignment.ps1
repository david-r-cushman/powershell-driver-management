<#
.SYNOPSIS
    Audits or aligns a downstream README to the shared pwsh-dev-template skeleton.

.DESCRIPTION
    Uses the shared downstream README skeleton shipped with pwsh-dev-template
    to report drift or rewrite README.md for template-derived downstream
    repositories while preserving repo-specific sections and generated blocks.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SkeletonPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryName,

    [Parameter()]
    [switch]$Apply,

    [Parameter()]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

$ErrorActionPreference = 'Stop'

function Resolve-DirectoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath
    )

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Container)) {
        throw ('Directory not found: {0}' -f $LiteralPath)
    }

    return (Resolve-Path -LiteralPath $LiteralPath).Path
}

function Get-RepoPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RelativePath
    )

    return (Join-Path -Path $BasePath -ChildPath $RelativePath)
}

function Get-FileContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return Get-Content -Raw -LiteralPath $Path
}

function Write-Utf8File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Get-NewLine {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$Content
    )

    if ($Content -match "`r`n") {
        return "`r`n"
    }

    return "`n"
}

function Test-GitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath
    )

    $output = & git -C $RepoPath rev-parse --is-inside-work-tree 2>&1
    return ($LASTEXITCODE -eq 0 -and ($output | Select-Object -First 1) -eq 'true')
}

function Get-ReadmeDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]]($Content -split "`r?`n"))

    $lead = [System.Collections.Generic.List[string]]::new()
    $sections = [System.Collections.Generic.List[object]]::new()
    $currentHeading = $null
    $currentBody = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $lines) {
        if ($line -match '^##\s+(?<Heading>.+?)\s*$') {
            if ($null -ne $currentHeading) {
                $sections.Add([pscustomobject]@{
                        Heading = $currentHeading
                        Body = @($currentBody)
                    })
            }

            $currentHeading = $Matches.Heading
            $currentBody = [System.Collections.Generic.List[string]]::new()
            continue
        }

        if ($null -eq $currentHeading) {
            $lead.Add($line)
        }
        else {
            $currentBody.Add($line)
        }
    }

    if ($null -ne $currentHeading) {
        $sections.Add([pscustomobject]@{
                Heading = $currentHeading
                Body = @($currentBody)
            })
    }

    return [pscustomobject]@{
        Lead = @($lead)
        Sections = @($sections)
    }
}

function Get-LeadTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]$LeadLines
    )

    foreach ($line in $LeadLines) {
        if ($line -match '^#\s+(?<Title>.+?)\s*$') {
            return $Matches.Title
        }
    }

    return $null
}

function Get-TemplateBadgeLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$ReadmeContent
    )

    $match = [regex]::Match($ReadmeContent, '!\[Template Version\]\(https://img\.shields\.io/badge/template-[^)]+\)')
    if ($match.Success) {
        return $match.Value
    }

    return $null
}

function Get-LeadSummaryBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]$LeadLines
    )

    $summary = [System.Collections.Generic.List[string]]::new()
    $capturing = $false

    foreach ($line in $LeadLines) {
        if ($line -match '^Quick navigation:\s*$') {
            break
        }

        if ($line -match '^#\s+' -or
            $line -match '^<!-- .* -->$' -or
            $line -match '^!\[.+\]\(.+\)$' -or
            $line -match '^\[!\[.+\]\(.+\)\]\(.+\)$' -or
            $line -match '^\s*-\s+\[.+\]\(#.+\)\s*$') {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($capturing) {
                $summary.Add('')
            }

            continue
        }

        $capturing = $true
        $summary.Add($line)
    }

    while ($summary.Count -gt 0 -and [string]::IsNullOrWhiteSpace($summary[0])) {
        $summary.RemoveAt(0)
    }

    while ($summary.Count -gt 0 -and [string]::IsNullOrWhiteSpace($summary[$summary.Count - 1])) {
        $summary.RemoveAt($summary.Count - 1)
    }

    return @($summary)
}

function Get-RenderedSkeletonContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$SkeletonContent,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ResolvedRepositoryName,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]$SummaryLines,

        [Parameter()]
        [string]$TemplateBadgeLine
    )

    $rendered = $SkeletonContent.Replace('{{REPOSITORY_NAME}}', $ResolvedRepositoryName)
    $summaryText = if ($SummaryLines.Count -gt 0) {
        ($SummaryLines -join "`n")
    }
    else {
        'Add a concise repository summary that explains what this project does and why it exists.'
    }

    $badgeText = if ($TemplateBadgeLine) { $TemplateBadgeLine } else { '' }
    $rendered = $rendered.Replace('{{REPOSITORY_SUMMARY}}', $summaryText)
    $rendered = $rendered.Replace('{{TEMPLATE_VERSION_BADGE}}', $badgeText)

    return ($rendered.TrimEnd("`r", "`n") + "`n")
}

function Convert-ReadmeDocumentToText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Document,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$NewLine
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $leadLines = [string[]]$Document.Lead

    for ($index = 0; $index -lt $leadLines.Count; $index++) {
        $lines.Add($leadLines[$index])
    }

    while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
        $lines.RemoveAt($lines.Count - 1)
    }

    foreach ($section in $Document.Sections) {
        if ($lines.Count -gt 0) {
            $lines.Add('')
        }

        $lines.Add('## {0}' -f $section.Heading)

        $bodyLines = [System.Collections.Generic.List[string]]::new()
        $bodyLines.AddRange([string[]]$section.Body)
        while ($bodyLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($bodyLines[$bodyLines.Count - 1])) {
            $bodyLines.RemoveAt($bodyLines.Count - 1)
        }

        foreach ($bodyLine in $bodyLines) {
            $lines.Add($bodyLine)
        }
    }

    return (($lines -join $NewLine).TrimEnd("`r", "`n") + $NewLine)
}

$resolvedRepoRoot = Resolve-DirectoryPath -LiteralPath $RepoRoot
if (-not (Test-GitRepository -RepoPath $resolvedRepoRoot)) {
    throw ('Repository is not a Git work tree: {0}' -f $resolvedRepoRoot)
}

$resolvedSkeletonPath = if ($SkeletonPath) {
    (Resolve-Path -LiteralPath $SkeletonPath).Path
}
else {
    Get-RepoPath -BasePath $resolvedRepoRoot -RelativePath 'templates/downstream/README.md'
}

$requiredPaths = @(
    'README.md'
    'AGENTS.md'
    'eng/runtime-policy.json'
    'scripts/Update-GeneratedMarkdown.ps1'
    'scripts/Invoke-RepoChecks.ps1'
    'scripts/Invoke-TemplateGuidanceSync.ps1'
    '.codex/skills/downstream-guidance-sync/SKILL.md'
)

$missingRequiredPaths = @(
    foreach ($relativePath in $requiredPaths) {
        if (-not (Test-Path -LiteralPath (Get-RepoPath -BasePath $resolvedRepoRoot -RelativePath $relativePath))) {
            $relativePath
        }
    }
)

if (-not (Test-Path -LiteralPath $resolvedSkeletonPath -PathType Leaf)) {
    $missingRequiredPaths += 'templates/downstream/README.md'
}

if ($missingRequiredPaths.Count -gt 0) {
    throw ('README alignment is only supported for template-derived downstream repositories with synced README assets. Missing: {0}' -f ($missingRequiredPaths -join ', '))
}

$readmePath = Get-RepoPath -BasePath $resolvedRepoRoot -RelativePath 'README.md'
$currentContent = Get-FileContent -Path $readmePath
if ($null -eq $currentContent) {
    throw ('README.md not found: {0}' -f $readmePath)
}

$resolvedRepositoryName = if ($RepositoryName) {
    $RepositoryName
}
else {
    $currentTitle = Get-LeadTitle -LeadLines (Get-ReadmeDocument -Content $currentContent).Lead
    if ($currentTitle) {
        $currentTitle
    }
    else {
        Split-Path -Path $resolvedRepoRoot -Leaf
    }
}

$currentDocument = Get-ReadmeDocument -Content $currentContent
$skeletonContent = Get-FileContent -Path $resolvedSkeletonPath
$summaryLines = Get-LeadSummaryBlock -LeadLines $currentDocument.Lead
$templateBadgeLine = Get-TemplateBadgeLine -ReadmeContent $currentContent
$renderedSkeletonContent = Get-RenderedSkeletonContent -SkeletonContent $skeletonContent -ResolvedRepositoryName $resolvedRepositoryName -SummaryLines $summaryLines -TemplateBadgeLine $templateBadgeLine
$skeletonDocument = Get-ReadmeDocument -Content $renderedSkeletonContent

$standardSections = [System.Collections.Generic.List[string]]::new()
foreach ($section in $skeletonDocument.Sections) {
    $standardSections.Add($section.Heading)
}

$currentSectionMap = @{}
$currentSectionOrder = [System.Collections.Generic.List[string]]::new()
foreach ($section in $currentDocument.Sections) {
    $currentSectionMap[$section.Heading.ToLowerInvariant()] = $section
    $currentSectionOrder.Add($section.Heading)
}

$alignedSections = [System.Collections.Generic.List[object]]::new()
$sectionStates = [System.Collections.Generic.List[object]]::new()

foreach ($skeletonSection in $skeletonDocument.Sections) {
    $key = $skeletonSection.Heading.ToLowerInvariant()
    if ($currentSectionMap.ContainsKey($key)) {
        $alignedSections.Add([pscustomobject]@{
                Heading = $skeletonSection.Heading
                Body = @($currentSectionMap[$key].Body)
            })

        $originalIndex = $currentSectionOrder.IndexOf($currentSectionMap[$key].Heading)
        $expectedIndex = $standardSections.IndexOf($skeletonSection.Heading)
        $status = if ($originalIndex -eq $expectedIndex) { 'Current' } else { 'Realigned' }

        $sectionStates.Add([pscustomobject]@{
                Heading = $skeletonSection.Heading
                Status = $status
                Source = 'Existing'
            })
    }
    else {
        $alignedSections.Add([pscustomobject]@{
                Heading = $skeletonSection.Heading
                Body = @($skeletonSection.Body)
            })

        $sectionStates.Add([pscustomobject]@{
                Heading = $skeletonSection.Heading
                Status = 'Missing'
                Source = 'Skeleton'
            })
    }
}

$extraSections = [System.Collections.Generic.List[object]]::new()
foreach ($section in $currentDocument.Sections) {
    if ($standardSections -notcontains $section.Heading) {
        $alignedSections.Add([pscustomobject]@{
                Heading = $section.Heading
                Body = @($section.Body)
            })

        $extraSections.Add([pscustomobject]@{
                Heading = $section.Heading
                Status = 'Preserved'
            })
    }
}

$alignedDocument = [pscustomobject]@{
    Lead = @($skeletonDocument.Lead)
    Sections = @($alignedSections)
}

$newLine = Get-NewLine -Content $currentContent
$alignedContent = Convert-ReadmeDocumentToText -Document $alignedDocument -NewLine $newLine
$hasChanges = $alignedContent -ne $currentContent

$manualFollowUp = [System.Collections.Generic.List[string]]::new()
if ($summaryLines.Count -eq 0) {
    $manualFollowUp.Add('Replace the placeholder repository summary near the top of README.md.')
}

if (-not $templateBadgeLine) {
    $manualFollowUp.Add('Add or refresh the template version badge through downstream guidance sync before relying on template alignment metadata.')
}

$result = [pscustomobject]@{
    RepoRoot = $resolvedRepoRoot
    ReadmePath = $readmePath
    SkeletonPath = $resolvedSkeletonPath
    RepositoryName = $resolvedRepositoryName
    Applied = [bool]$Apply
    HasChanges = [bool]$hasChanges
    TemplateBadgePresent = [bool]($null -ne $templateBadgeLine)
    StandardSections = @($sectionStates)
    ExtraSections = @($extraSections)
    ManualFollowUp = @($manualFollowUp)
}

if ($Apply -and $hasChanges) {
    if ($PSCmdlet.ShouldProcess($readmePath, 'Align README to shared downstream skeleton')) {
        Write-Utf8File -Path $readmePath -Content $alignedContent
    }
}

if ($OutputFormat -eq 'Json') {
    $result | ConvertTo-Json -Depth 6
}
else {
    Write-Output ('Repository: {0}' -f $result.RepoRoot)
    Write-Output ('README: {0}' -f $result.ReadmePath)
    Write-Output ('Skeleton: {0}' -f $result.SkeletonPath)
    Write-Output ('Changes needed: {0}' -f $result.HasChanges)
    Write-Output ('Template badge present: {0}' -f $result.TemplateBadgePresent)
    Write-Output ''
    Write-Output 'Standard sections:'
    $result.StandardSections | Format-Table -Property Heading, Status, Source -AutoSize | Out-String | Write-Output

    if ($result.ExtraSections.Count -gt 0) {
        Write-Output 'Extra sections:'
        $result.ExtraSections | Format-Table -Property Heading, Status -AutoSize | Out-String | Write-Output
    }

    if ($result.ManualFollowUp.Count -gt 0) {
        Write-Output 'Manual follow-up:'
        foreach ($item in $result.ManualFollowUp) {
            Write-Output ('- {0}' -f $item)
        }
    }
}
