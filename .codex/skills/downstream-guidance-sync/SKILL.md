---
name: downstream-guidance-sync
description: Use when asked to sync, audit, update, or align AI guidance and downstream cleanup workflow assets from pwsh-dev-template into a downstream repository created from the template. Guides agents to operate scripts/Invoke-TemplateGuidanceSync.ps1 safely with audit-first behavior, non-main branches, diff review, validation, commits, and pull requests.
---

# Downstream Guidance Sync

## Overview

Use this skill to synchronize template-owned downstream guidance, workflow documentation, and cleanup workflow assets from `pwsh-dev-template` into an existing downstream repository. The deterministic tool is `scripts/Invoke-TemplateGuidanceSync.ps1`; this skill defines how an agent should operate that tool safely.

This workflow does not perform cleanup itself. For newly created downstream repositories, cleanup still runs locally from the downstream repo through `scripts/Initialize-DownstreamRepo.ps1`.

The sync scope is intentionally narrow and migration-oriented. Do not manually copy, edit, or invent files outside the script allowlist.

## Why This Exists

Repositories created from this template become independent projects after creation. Their source, tests, CI, analyzer settings, runtime policy, and scaffolds are project-owned and should not be clobbered by template updates.

AI guidance is the default sync target because it governs how AI-assisted work is produced, reviewed, and validated. The ADR scaffold README is also safe to sync because it provides a documentation convention without overwriting project-specific decisions. For downstream repositories that predate the cleanup workflow, the sync process can also deliver the cleanup script, cleanup skill, shared downstream README skeleton, README alignment workflow assets, the downstream sync workflow assets, and the README-validation baseline required for those workflows to function consistently, including `scripts/Invoke-MarkdownValidation.ps1`.

## Required Context

Before acting, identify:

- the template repo path, normally the current `pwsh-dev-template` checkout
- the downstream repo path supplied by the user
- whether the downstream repo already contains the cleanup workflow assets
- whether the user wants audit-only output or a branch/PR workflow

If the downstream repo path is missing, ask for it. Do not guess from nearby folders.

## Audit Workflow

Run audit mode first from the template repo:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-TemplateGuidanceSync.ps1 -Path ../downstream-repo
```

Use audit output to determine whether drift exists. Report `Current`, `Outdated`, `Missing`, or `Malformed` statuses in plain language. Do not apply changes during audit mode.

For automation-friendly inspection, use:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-TemplateGuidanceSync.ps1 -Path ../downstream-repo -OutputFormat Json
```

If the downstream repo is missing `scripts/Initialize-DownstreamRepo.ps1` or `.codex/skills/downstream-repo-cleanup/`, treat that as a signal that the repo predates the cleanup workflow and should receive those assets through sync before cleanup is run locally.

## Apply Workflow

When the user requests sync changes, use this sequence:

1. Confirm the downstream repo has a clean working tree.
2. Create or switch to a non-main branch in the downstream repo, for example:

   ```powershell
   git -C ../downstream-repo switch -c chore/sync-template-guidance
   ```

3. Run the sync script from the template repo:

   ```powershell
   pwsh -NoProfile -File ./scripts/Invoke-TemplateGuidanceSync.ps1 -Path ../downstream-repo -Apply
   ```

4. Inspect the downstream diff and verify changes are limited to synced guidance files, the ADR scaffold README, the README template badge, and the cleanup or README workflow assets shipped from the template.
5. If the sync delivered `scripts/Initialize-DownstreamRepo.ps1`, the cleanup skill, or the shared README workflow assets into an older downstream repo, switch into the downstream repo and run cleanup or README alignment there before adding more project-specific changes.
6. Run downstream validation if the repo provides a clear validation entrypoint, such as `scripts/Invoke-RepoChecks.ps1`.
7. Commit with a conventional docs or chore message that reflects the actual change, for example:

   ```text
   chore(repo): sync template guidance and cleanup assets
   ```

8. Open or draft a PR when requested, summarizing changed guidance, delivered cleanup assets, and validation results.

## Success Criteria

The workflow is complete when:

- audit output has been reviewed and explained in plain language
- apply mode, when used, ran only from a non-main downstream branch
- the downstream diff is limited to the sync allowlist, including only the ADR scaffold README under `docs/decisions/`
- downstream validation was run, or a clear reason was reported when validation was unavailable or skipped
- the commit or PR summary states whether the change was a guidance refresh, a cleanup-asset delivery, a README-workflow delivery, or a combination of those, along with the validation result

## Stop Conditions

Stop and report instead of improvising when:

- the downstream repo path is missing or is not a Git repo
- the downstream repo is on `main` or `master` when applying changes
- the downstream working tree is dirty and the user has not explicitly approved continuing
- the sync script reports unexpected failures
- the diff contains files outside the sync allowlist
- validation fails and the failure is not clearly unrelated to the sync

Do not bypass the script by manually editing downstream guidance files unless the user explicitly asks for manual repair after seeing the script failure.

## Sync Boundary

The script may update only:

- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.codex/skills/downstream-guidance-sync/`
- `.codex/skills/downstream-repo-cleanup/`
- `.codex/skills/readme-alignment/`
- `PesterConfiguration.psd1`
- `PSScriptAnalyzerSettings.psd1`
- selected AI governance and operating-model docs under `docs`
- `docs/agent-workflows.md`
- `docs/decisions/README.md`
- `scripts/Initialize-DownstreamRepo.ps1`
- `scripts/Invoke-RepoChecks.ps1`
- `scripts/Invoke-ReadmeAlignment.ps1`
- `scripts/Invoke-TemplateGuidanceSync.ps1`
- `scripts/Test-VersionPolicy.ps1`
- `scripts/Update-GeneratedMarkdown.ps1`
- `eng/runtime-policy.json`
- `templates/downstream/README.md`
- the README template-version badge

It must not update downstream source, tests, CI workflows, Dev Container files, module manifests, scaffolds other than the cleanup, sync, and README workflow assets, or numbered project-specific ADRs. The narrow validation exceptions are the repo-checks entrypoint, `scripts/Invoke-MarkdownValidation.ps1`, `PesterConfiguration.psd1`, `PSScriptAnalyzerSettings.psd1`, `scripts/Test-VersionPolicy.ps1`, and the runtime-policy README-generation assets required by the shared downstream README workflow. It also does not perform cleanup or README alignment itself; it only delivers the assets needed for those workflows to run locally in downstream repositories.

## Agent Role

Treat the script as the source of truth for deterministic behavior. The agent role is to orchestrate: run the script, interpret output, inspect diffs, identify whether cleanup assets were delivered, run validation, prepare commits, and draft PR text.