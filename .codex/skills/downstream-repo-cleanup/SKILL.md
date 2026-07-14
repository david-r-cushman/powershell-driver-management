---
name: downstream-repo-cleanup
description: Use when asked to handle downstream repository cleanup, normalization, initialization, or first-run preparation for a newly created repository from pwsh-dev-template before project-specific work begins. Guides agents to operate scripts/Initialize-DownstreamRepo.ps1 safely in audit-first mode, preserve or insert the README template version badge, validate changes, and stop when the repository has already moved beyond the immediate post-create window.
---

# Downstream Repo Cleanup

## Overview

Use this skill to normalize a repository immediately after it is created from `pwsh-dev-template`. The deterministic tool is `scripts/Initialize-DownstreamRepo.ps1`; this skill defines how an agent should operate that tool safely.

This workflow is intentionally for first-run cleanup only. Do not use it as a general-purpose restructuring tool after meaningful project-specific work has started.

## Why This Exists

Repositories created from the template inherit both a useful development baseline and a set of template-maintainer artifacts. Running cleanup immediately after creation makes it clear which inherited files become downstream-owned and which ones should be removed before the repository starts diverging.

The README template version badge should remain in the downstream repository. It indicates inherited guidance and baseline alignment, not full parity with the template.

## Required Context

Before acting, identify:

- the downstream repo path, normally the current repository
- the intended `ProjectType`: `script`, `module`, or `hybrid`
- the repository name to use in downstream text normalization
- the module name when `ProjectType` is `module` or `hybrid`

If the repository already contains project-specific source files, tests, ADRs, or materially rewritten guidance docs, stop and report that the repo is no longer in the intended immediate post-create window.

## Audit Workflow

Run audit mode first from the downstream repo:

```powershell
pwsh -NoProfile -File ./scripts/Initialize-DownstreamRepo.ps1 -RepositoryName winget-pwsh-automation
```

Choose `ProjectType` explicitly when the repo is not script-first:

```powershell
pwsh -NoProfile -File ./scripts/Initialize-DownstreamRepo.ps1 -ProjectType module -ModuleName WingetAutomation -RepositoryName winget-pwsh-automation
```

Use audit output to review planned `Remove`, `Rewrite`, `Rename`, `Keep`, and `ManualFollowUp` actions before changing files.

For automation-friendly inspection, use:

```powershell
pwsh -NoProfile -File ./scripts/Initialize-DownstreamRepo.ps1 -OutputFormat Json
```

## Apply Workflow

When the user requests cleanup changes, use this sequence:

1. Confirm the repository is still in the immediate post-create window.
2. Run the cleanup script with the intended project shape.
3. Preserve or insert the README template version badge during cleanup.
4. Inspect the diff and confirm changes are limited to template-maintainer artifact removal, inherited guidance rewrites, and project-type scaffold normalization.
5. Run downstream validation:

   ```powershell
   pwsh -NoProfile -File ./scripts/Invoke-RepoChecks.ps1
   ```

6. Commit with a conventional message, for example:

   ```text
   chore(repo): initialize downstream baseline
   ```

## Success Criteria

The workflow is complete when:

- audit output has been reviewed and explained in plain language
- apply mode, when used, ran before project-specific work was added
- the README template version badge exists after cleanup
- template-maintainer files were removed or rewritten according to the workflow contract
- downstream validation was run, or a clear reason was reported when validation was unavailable or skipped

## Stop Conditions

Stop and report instead of improvising when:

- the repo path is missing or is not a Git repo
- `ProjectType` is invalid
- `ModuleName` is missing for `module` or `hybrid`
- the repo already contains project-specific source files, tests, ADRs, or materially rewritten guidance
- validation fails and the failure is not clearly unrelated to cleanup

Do not use this workflow to invent business logic, project-specific docs, or unrelated CI changes.

## Cleanup Boundary

The script may remove template-maintainer artifacts such as:

- `VERSION`
- `CHANGELOG.md`
- template release and runtime-policy workflow skills
- template-maintainer tests and ADR seed files

It should preserve downstream README workflow assets such as the shared README skeleton, `scripts/Invoke-ReadmeAlignment.ps1`, and `.codex/skills/readme-alignment/`.

It may rewrite inherited downstream-owned guidance such as:

- `README.md`
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `docs/agent-workflows.md`
- `docs/decisions/README.md`

It must preserve downstream baseline infrastructure such as:

- `.devcontainer/`
- CI workflow scaffolding
- runtime policy files
- `scripts/Invoke-RepoChecks.ps1`
- `scripts/Invoke-TemplateGuidanceSync.ps1`
- `.codex/skills/downstream-guidance-sync/`

## Agent Role

Treat the script as the source of truth for deterministic behavior. The agent role is to choose the right project profile, run the script, interpret audit output, inspect diffs, run validation, and summarize any remaining manual follow-up items.
