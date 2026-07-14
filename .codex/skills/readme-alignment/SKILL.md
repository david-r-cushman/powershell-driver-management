---
name: readme-alignment
description: Use when asked to bring a downstream repository README into alignment with the shared pwsh-dev-template README skeleton while preserving repo-specific content and generated Markdown blocks.
---

# README Alignment

## Overview

Use this skill to audit or align a downstream repository `README.md` against the shared README skeleton shipped from `pwsh-dev-template`. The deterministic tool is `scripts/Invoke-ReadmeAlignment.ps1`; this skill defines how an agent should operate that tool safely.

This workflow is intended for template-derived downstream repositories created from `pwsh-dev-template`. It is not a general-purpose README rewriter for unrelated repositories.

## Why This Exists

Downstream repositories should share a recognizable portfolio structure without losing truthful repo-specific documentation. The shared skeleton captures the durable README architecture, while this workflow lets maintainers realign structure later without manually reconstructing it from memory or diff history.

The shared skeleton remains generator-driven. Generated Markdown blocks, the template version badge contract, and the runtime policy assets still matter in downstream repositories that keep that baseline.

## Required Context

Before acting, identify:

- the downstream repo path, normally the current repository
- whether the repo still appears to be derived from `pwsh-dev-template`
- whether the user wants audit-only output or a branch/apply workflow
- whether the repo already contains additional repo-specific README sections that must be preserved

If the repo does not contain the shared skeleton asset or the runtime-policy README-generation assets, use downstream guidance sync first instead of improvising the missing files.

## Audit Workflow

Run audit mode first from the downstream repo:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-ReadmeAlignment.ps1
```

Use audit output to review:

- missing or out-of-order shared sections
- extra repo-specific sections that will be preserved
- whether the template version badge is currently present

For automation-friendly inspection, use:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-ReadmeAlignment.ps1 -OutputFormat Json
```

## Apply Workflow

When the user requests alignment changes, use this sequence:

1. Confirm the repo is a supported downstream repository.
2. Create or switch to a non-main branch before applying changes.
3. Run the alignment script:

   ```powershell
   pwsh -NoProfile -File ./scripts/Invoke-ReadmeAlignment.ps1 -Apply
   ```

4. Inspect the diff and verify:
   - shared sections were normalized to the skeleton order
   - `Portfolio Context` and `Template Versioning` were preserved
   - repo-specific extra sections were not discarded
5. Run downstream validation. The repo checks entrypoint includes Markdown validation for the aligned README:

   ```powershell
   pwsh -NoProfile -File ./scripts/Invoke-RepoChecks.ps1
   ```

6. Commit with a conventional docs or chore message that reflects the actual change.

## Success Criteria

The workflow is complete when:

- audit output has been reviewed and explained in plain language
- apply mode, when used, ran from a non-main branch
- the resulting README follows the shared skeleton order
- repo-specific extra sections were preserved
- `Portfolio Context` and `Template Versioning` remain present
- downstream validation was run, including Markdown validation for the README, or a clear reason was reported when validation was unavailable or skipped

## Stop Conditions

Stop and report instead of improvising when:

- the repo is not a Git repository
- the repo does not appear to be derived from `pwsh-dev-template`
- the shared skeleton asset is missing
- required README-generation assets are missing
- validation fails and the failure is not clearly unrelated to the README alignment

Do not use this workflow to invent project-specific claims, implementation details, or CI behavior.

## Boundary

The script may:

- align `README.md` to the shared downstream skeleton
- preserve repo-specific extra sections
- preserve the template version badge when it already exists
- use the synced runtime-policy README-generation assets that support generated blocks

It must not:

- overwrite source code, tests, CI, module manifests, or numbered project-specific ADRs
- fabricate repo-specific functionality or project history
- treat unrelated repositories as supported targets

## Agent Role

Treat the shared skeleton and `scripts/Invoke-ReadmeAlignment.ps1` as the source of truth for deterministic structure. The agent role is to run the script, interpret audit output, inspect diffs, preserve truthful repo-specific documentation, validate the result, and summarize any remaining manual follow-up.
