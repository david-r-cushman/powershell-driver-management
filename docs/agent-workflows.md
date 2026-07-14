# Agent Workflows

This repository includes repo-local agent workflows for repeatable template maintenance tasks.

The workflows are designed around a simple rule: agents may coordinate the work, but deterministic scripts, Pester tests, and human review remain the controls that make the work reliable.

Repo-local skills live under `.codex/skills/`. They tell compatible agents how to use the repository's existing scripts, validation commands, and review expectations. They are not a substitute for reading the repository guidance, inspecting diffs, or opening reviewed pull requests.

## Workflow Index

| Workflow | Use When | Skill | Control | Validation |
| --- | --- | --- | --- | --- |
| Change delivery workflow | Ordinary repository work needs consistent branch, changelog, validation, PR, and post-merge cleanup discipline without inventing repo-specific process. | `.codex/skills/change-delivery-workflow/SKILL.md` | Repository guidance, Git state, repo-specific validators, diff review, and human review | Repo-specific validation entrypoints, staged diff review, and PR review |
| Downstream repo cleanup | A repository was just created from this template and needs immediate first-run normalization before project-specific work begins. | `.codex/skills/downstream-repo-cleanup/SKILL.md` | `scripts/Initialize-DownstreamRepo.ps1` | Audit output, downstream diff review, `scripts/Invoke-RepoChecks.ps1` |
| Downstream guidance sync | An existing downstream repository needs current AI guidance, guardrail docs, ADR scaffold guidance, or newly added README workflow assets from the template. | `.codex/skills/downstream-guidance-sync/SKILL.md` | `scripts/Invoke-TemplateGuidanceSync.ps1` | Audit output, downstream diff review, downstream validation |
| README alignment | A downstream repository README needs to be audited or realigned to the shared portfolio skeleton after cleanup. | `.codex/skills/readme-alignment/SKILL.md` | `scripts/Invoke-ReadmeAlignment.ps1` with `templates/downstream/README.md` | README audit output, downstream diff review, `scripts/Invoke-RepoChecks.ps1` with Markdown validation |
| Runtime policy update | The template needs coordinated PowerShell, Ubuntu, GitHub Actions runner, or pinned tooling updates. | `.codex/skills/runtime-policy-update/SKILL.md` | `eng/runtime-policy.json` | `scripts/Update-GeneratedMarkdown.ps1 -Check`, `scripts/Test-VersionPolicy.ps1`, `scripts/Invoke-RepoChecks.ps1 -IncludeTemplates` |
| Template version release | The template version, changelog, README badge, lightweight release tag, and GitHub Release need to be prepared or finalized. | `.codex/skills/template-version-release/SKILL.md` | `VERSION`, `CHANGELOG.md`, README template badge, lightweight `vX.Y.Z` tags on merged `main` commits under the existing merge-commit ruleset, and GitHub Releases | `scripts/Test-TemplateVersion.ps1` and release PR review |

## Operating Model

Use the repo-local skill when the task matches one of the workflow areas above. The skill should guide the agent through the expected branch or post-create state, script, validation, diff review, commit, and pull request process.

The change delivery workflow is intentionally process-oriented. It standardizes branch, changelog, release-decision, PR, and cleanup behavior for everyday repository work, while still relying on repo guidance, existing validators, diff review, and human review as the controls.

Before planning template maintenance work, agents can run `scripts/Get-TemplateHealth.ps1` for a quick report of generated Markdown, runtime policy, template version metadata, workflow discoverability, and Git release posture.

The agent should not invent a separate process when a deterministic script already exists. If a script reports an error, the correct response is to inspect the failure, fix the cause, and rerun the documented validation. Recovery should still be explicit, reviewable, and consistent with the repository guidance.

Pester is the repository validation standard for repo-local skill behavior and discoverability. When skills or workflow documentation change, update `tests/unit/SkillScaffold.Tests.ps1` so the repository can detect stale skill references, missing metadata, and missing documentation pointers. Codex `quick_validate.py` may still be useful while authoring a skill, but it is not the repository's required validation path.

## Boundaries

Repo-local skills do not make autonomous changes acceptable without review. They should help agents apply known workflows consistently, not broaden the task scope.

The downstream repo cleanup workflow is intentionally a first-run normalization step. It should be run immediately after a repository is created from this template and before project-specific source, tests, ADRs, or CI changes are added. It may remove template-maintainer artifacts and rewrite inherited guidance into downstream form, but it must not invent project-specific business logic, tests, docs, or unrelated CI changes.

The downstream guidance sync workflow is intentionally narrow. It may update AI guidance, guardrail documentation, `docs/decisions/README.md`, the README template-version badge, `docs/agent-workflows.md`, the shared downstream README skeleton, the downstream sync and README alignment workflow assets, and the narrow validation baseline required by those workflows in older downstream repositories. That exception includes `scripts/Invoke-RepoChecks.ps1`, `scripts/Test-VersionPolicy.ps1`, `PesterConfiguration.psd1`, `PSScriptAnalyzerSettings.psd1`, and the runtime-policy README-generation assets. It must not be used to overwrite downstream source code, tests, CI workflows, Dev Container files, module manifests, or numbered project-specific ADRs unless that broader work is requested as a separate repo-specific change. Cleanup itself still runs from the downstream repository.

Runtime policy updates and template version releases are template-repository workflows. Downstream repositories should adopt those changes only through explicit, reviewed project work.
