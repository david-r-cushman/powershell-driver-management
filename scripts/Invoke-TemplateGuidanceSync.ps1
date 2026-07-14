<#
.SYNOPSIS
    Audits or syncs template-owned downstream guidance and cleanup assets into downstream repositories.

.DESCRIPTION
    Compares a downstream repository with this template repository for the
    files that are safe to keep aligned after a project has been created from
    the template: AI guidance, downstream workflow documentation, cleanup workflow assets for older downstream repositories, the ADR scaffold README, and the README template
    version badge.

    The README badge represents template guidance alignment. It does not mean
    the downstream repository's implementation, tooling, CI, devcontainer, or
    tests match this template.

.PARAMETER Path
    One or more downstream repository paths to audit or update.

.PARAMETER TemplatePath
    Optional template repository path. Defaults to the repository containing
    this script.

.PARAMETER Apply
    Applies safe guidance synchronization changes. Without this switch, the
    script reports drift without changing files.

.PARAMETER AllowDirty
    Allows applying changes when the downstream repository already has
    uncommitted changes.

.PARAMETER FailOnDrift
    Returns a nonzero exit code when drift is detected.

.PARAMETER OutputFormat
    Controls output format. Text is intended for humans; Json is intended for
    agents and automation.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TemplatePath = (Join-Path -Path $PSScriptRoot -ChildPath '..'),

    [Parameter()]
    [switch]$Apply,

    [Parameter()]
    [switch]$AllowDirty,

    [Parameter()]
    [switch]$FailOnDrift,

    [Parameter()]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

$ErrorActionPreference = 'Stop'

$guidanceFiles = @(
    'PesterConfiguration.psd1'
    'PSScriptAnalyzerSettings.psd1'
    'AGENTS.md'
    '.github/copilot-instructions.md'
    '.codex/skills/change-delivery-workflow/SKILL.md'
    '.codex/skills/change-delivery-workflow/agents/openai.yaml'
    '.codex/skills/downstream-guidance-sync/SKILL.md'
    '.codex/skills/downstream-guidance-sync/agents/openai.yaml'
    '.codex/skills/downstream-repo-cleanup/SKILL.md'
    '.codex/skills/downstream-repo-cleanup/agents/openai.yaml'
    '.codex/skills/readme-alignment/SKILL.md'
    '.codex/skills/readme-alignment/agents/openai.yaml'
    'docs/agent-workflows.md'
    'docs/ai-behavioral-contract.md'
    'docs/ai-interaction-loop.md'
    'docs/copilot-instructions-reference.md'
    'docs/powershell-ai-operating-model.md'
    'docs/decisions/README.md'
    'scripts/Initialize-DownstreamRepo.ps1'
    'scripts/Invoke-RepoChecks.ps1'
    'scripts/Invoke-MarkdownValidation.ps1'
    'scripts/Invoke-ReadmeAlignment.ps1'
    'scripts/Invoke-TemplateGuidanceSync.ps1'
    'scripts/Test-VersionPolicy.ps1'
    'scripts/Update-GeneratedMarkdown.ps1'
    'eng/runtime-policy.json'
    'templates/downstream/README.md'
)

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

function Invoke-Git {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Arguments
    )

    $output = & git -C $RepoPath @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ('git -C {0} {1} failed: {2}' -f $RepoPath, ($Arguments -join ' '), ($output -join [Environment]::NewLine))
    }

    return $output
}

function Test-GitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath
    )

    try {
        $isWorkTree = Invoke-Git -RepoPath $RepoPath -Arguments @('rev-parse', '--is-inside-work-tree')
    }
    catch {
        return $false
    }

    return (($isWorkTree | Select-Object -First 1) -eq 'true')
}

function Get-FileHashText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath
    )

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        return $null
    }

    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash
}

function Get-TemplateVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath
    )

    $versionPath = Join-Path -Path $RepoPath -ChildPath 'VERSION'
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) {
        throw ('Template VERSION file not found: {0}' -f $versionPath)
    }

    $version = (Get-Content -Raw -LiteralPath $versionPath).Trim()
    if ([string]::IsNullOrWhiteSpace($version)) {
        throw ('Template VERSION file is empty: {0}' -f $versionPath)
    }

    return $version
}

function Get-NewLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    if ($Content -match "`r`n") {
        return "`r`n"
    }

    return "`n"
}

function Get-ReadmeBadgeState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TemplateVersion
    )

    $readmePath = Join-Path -Path $RepoPath -ChildPath 'README.md'
    $expectedLine = '![Template Version](https://img.shields.io/badge/template-{0}-blue)' -f $TemplateVersion

    if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
        return [pscustomobject]@{
            Status = 'Missing'
            CurrentVersion = $null
            ExpectedVersion = $TemplateVersion
            Path = 'README.md'
            ExpectedLine = $expectedLine
        }
    }

    $content = Get-Content -Raw -LiteralPath $readmePath
    $escapedLine = [regex]::Escape($expectedLine)
    $versionPattern = '!\[Template Version\]\(https://img\.shields\.io/badge/template-(?<version>[^-)\s]+)-blue\)'
    $templateBadgePattern = '!\[Template Version\]\(https://img\.shields\.io/badge/template-[^)]+\)'

    if ($content -match $escapedLine) {
        $status = 'Current'
        $currentVersion = $TemplateVersion
    }
    elseif ($content -match $versionPattern) {
        $status = 'Outdated'
        $currentVersion = $Matches.version
    }
    elseif ($content -match $templateBadgePattern -or $content -match '!\[Template Version\]') {
        $status = 'Malformed'
        $currentVersion = $null
    }
    else {
        $status = 'Missing'
        $currentVersion = $null
    }

    return [pscustomobject]@{
        Status = $status
        CurrentVersion = $currentVersion
        ExpectedVersion = $TemplateVersion
        Path = 'README.md'
        ExpectedLine = $expectedLine
    }
}

function Set-ReadmeTemplateBadge {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TemplateVersion
    )

    $readmePath = Join-Path -Path $RepoPath -ChildPath 'README.md'
    if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
        throw ('README.md not found in downstream repository: {0}' -f $readmePath)
    }

    $content = Get-Content -Raw -LiteralPath $readmePath
    $newLine = Get-NewLine -Content $content
    $expectedLine = '![Template Version](https://img.shields.io/badge/template-{0}-blue)' -f $TemplateVersion
    $templateBadgePattern = '!\[Template Version\]\(https://img\.shields\.io/badge/template-[^)]+\)'

    if ($content -match $templateBadgePattern) {
        $templateBadgeRegex = [regex]::new($templateBadgePattern)
        $updatedContent = $templateBadgeRegex.Replace($content, $expectedLine, 1)
    }
    else {
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.AddRange([string[]]($content -split "`r?`n"))

        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
            $lines.RemoveAt($lines.Count - 1)
        }

        $insertIndex = 0
        if ($lines.Count -gt 0 -and $lines[0] -match '^#\s+') {
            $insertIndex = 1
            $hasSeenBadge = $false
            while ($insertIndex -lt $lines.Count) {
                $line = $lines[$insertIndex]

                if ($line -match '^\s*$') {
                    if ($hasSeenBadge) {
                        break
                    }

                    $insertIndex++
                    continue
                }

                if ($line -match '^!?\[.+\]\(.+\)$' -or $line -match '^\[!\[.+\]\(.+\)\]\(.+\)$' -or $line -match '^<!-- .* -->$') {
                    if ($line -match '^!?\[.+\]\(.+\)$' -or $line -match '^\[!\[.+\]\(.+\)\]\(.+\)$') {
                        $hasSeenBadge = $true
                    }

                    $insertIndex++
                    continue
                }

                break
            }
        }

        $lines.Insert($insertIndex, $expectedLine)
        $updatedContent = ($lines -join $newLine).TrimEnd("`r", "`n") + $newLine
    }

    if ($updatedContent -ne $content -and $PSCmdlet.ShouldProcess($readmePath, 'Update template guidance badge')) {
        [System.IO.File]::WriteAllText($readmePath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    }
}

function Copy-GuidanceFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TemplateRepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetRepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RelativePath
    )

    $sourcePath = Join-Path -Path $TemplateRepoPath -ChildPath $RelativePath
    $targetPath = Join-Path -Path $TargetRepoPath -ChildPath $RelativePath

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw ('Template guidance file not found: {0}' -f $sourcePath)
    }

    $targetDirectory = Split-Path -Path $targetPath -Parent
    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($targetDirectory, 'Create guidance directory')) {
            New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
        }
    }

    if ($PSCmdlet.ShouldProcess($targetPath, 'Copy template guidance file')) {
        $content = Get-Content -Raw -LiteralPath $sourcePath
        [System.IO.File]::WriteAllText($targetPath, $content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-GuidanceFileState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TemplateRepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetRepoPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$RelativePaths
    )

    $states = foreach ($relativePath in $RelativePaths) {
        $sourcePath = Join-Path -Path $TemplateRepoPath -ChildPath $relativePath
        $targetPath = Join-Path -Path $TargetRepoPath -ChildPath $relativePath

        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw ('Template guidance file not found: {0}' -f $sourcePath)
        }

        $sourceHash = Get-FileHashText -LiteralPath $sourcePath
        $targetHash = Get-FileHashText -LiteralPath $targetPath

        if (-not $targetHash) {
            $status = 'Missing'
        }
        elseif ($sourceHash -eq $targetHash) {
            $status = 'Current'
        }
        else {
            $status = 'Outdated'
        }

        [pscustomobject]@{
            Path = $relativePath
            Status = $status
            Applied = $false
        }
    }

    return @($states)
}

function Write-TextReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$Results
    )

    foreach ($result in $Results) {
        Write-Output ('Target: {0}' -f $result.TargetPath)
        Write-Output ('Template version: {0}' -f $result.TemplateVersion)
        Write-Output ('Drift: {0}' -f $result.HasDrift)
        Write-Output ''
        Write-Output 'Synced files:'
        $result.Files | Format-Table -Property Path, Status, Applied -AutoSize | Out-String | Write-Output
        Write-Output 'README badge:'
        $result.ReadmeBadge | Format-Table -Property Path, Status, CurrentVersion, ExpectedVersion, Applied -AutoSize | Out-String | Write-Output
    }
}

$resolvedTemplatePath = Resolve-DirectoryPath -LiteralPath $TemplatePath
$templateVersion = Get-TemplateVersion -RepoPath $resolvedTemplatePath
$results = [System.Collections.Generic.List[object]]::new()

foreach ($targetPathInput in $Path) {
    $targetPath = Resolve-DirectoryPath -LiteralPath $targetPathInput

    if (-not (Test-GitRepository -RepoPath $targetPath)) {
        throw ('Target path is not a Git repository: {0}' -f $targetPath)
    }

    $branch = (Invoke-Git -RepoPath $targetPath -Arguments @('branch', '--show-current') | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($branch)) {
        throw ('Could not determine current branch for target repository: {0}' -f $targetPath)
    }

    $gitStatus = @(Invoke-Git -RepoPath $targetPath -Arguments @('status', '--porcelain'))
    if ($Apply -and -not $AllowDirty -and $gitStatus.Count -gt 0) {
        throw ('Refusing to apply changes because target repository has uncommitted changes: {0}' -f $targetPath)
    }

    if ($Apply -and $branch -in @('main', 'master')) {
        $branchName = 'chore/sync-template-guidance'
        throw ('Refusing to apply changes on protected branch "{0}". Create or switch to a working branch first: git -C "{1}" switch -c {2}' -f $branch, $targetPath, $branchName)
    }

    $fileStates = Get-GuidanceFileState -TemplateRepoPath $resolvedTemplatePath -TargetRepoPath $targetPath -RelativePaths $guidanceFiles
    $readmeBadge = Get-ReadmeBadgeState -RepoPath $targetPath -TemplateVersion $templateVersion

    if ($Apply) {
        foreach ($fileState in $fileStates | Where-Object { $_.Status -ne 'Current' }) {
            Copy-GuidanceFile -TemplateRepoPath $resolvedTemplatePath -TargetRepoPath $targetPath -RelativePath $fileState.Path
            $fileState.Applied = $true
        }

        if ($readmeBadge.Status -ne 'Current') {
            Set-ReadmeTemplateBadge -RepoPath $targetPath -TemplateVersion $templateVersion
            $readmeBadge | Add-Member -NotePropertyName Applied -NotePropertyValue $true -Force
        }
        else {
            $readmeBadge | Add-Member -NotePropertyName Applied -NotePropertyValue $false -Force
        }
    }
    else {
        $readmeBadge | Add-Member -NotePropertyName Applied -NotePropertyValue $false -Force
    }

    $hasDrift = ($fileStates | Where-Object { $_.Status -ne 'Current' } | Select-Object -First 1) -or $readmeBadge.Status -ne 'Current'

    $result = [pscustomobject]@{
        TargetPath = $targetPath
        TemplatePath = $resolvedTemplatePath
        TemplateVersion = $templateVersion
        Branch = $branch
        HasDrift = [bool]$hasDrift
        Applied = [bool]$Apply
        Files = @($fileStates)
        ReadmeBadge = $readmeBadge
    }

    $results.Add($result)
}

if ($OutputFormat -eq 'Json') {
    $results | ConvertTo-Json -Depth 6
}
else {
    Write-TextReport -Results @($results)
}

if ($FailOnDrift -and ($results | Where-Object { $_.HasDrift } | Select-Object -First 1)) {
    throw 'Template guidance drift detected.'
}