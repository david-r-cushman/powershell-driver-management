# AGENTS.md

## Repository Instructions

This repository's primary AI guidance is maintained in:

```text
.github/copilot-instructions.md
```

Before performing coding, review, documentation, test, automation, or repository-maintenance work, coding agents must read and follow `.github/copilot-instructions.md`.

That file is the authoritative instruction source for:

- AI governance requirements
- conflict resolution rules
- code generation standards
- complexity management guidance
- PowerShell compatibility requirements
- external service guidance
- commit message conventions
- review expectations

If `.github/copilot-instructions.md` is missing or unavailable, stop and report that the repository guidance cannot be loaded rather than guessing.

If guidance in this file conflicts with `.github/copilot-instructions.md`, `.github/copilot-instructions.md` is authoritative.

## Repo-Local Skills

Repo-local Codex skills are stored under `.codex/skills/`.

For general repository change delivery, agents should use `.codex/skills/change-delivery-workflow/SKILL.md` to handle sandbox escalation, non-`main` branches, changelog updates, release decisions, commits, pull requests, and post-merge cleanup consistently.

For immediate post-create normalization of repositories created from this template, agents should use `.codex/skills/downstream-repo-cleanup/SKILL.md` together with `scripts/Initialize-DownstreamRepo.ps1` before adding project-specific implementation, docs, tests, ADRs, or CI changes.

For downstream AI guidance synchronization and delivery of newly added cleanup workflow assets into older downstream repositories, agents should use `.codex/skills/downstream-guidance-sync/SKILL.md` together with `scripts/Invoke-TemplateGuidanceSync.ps1` instead of manually copying guidance files. Cleanup itself still runs from the downstream repository through `scripts/Initialize-DownstreamRepo.ps1`.

For downstream README audits or structural realignment against the shared portfolio skeleton, agents should use `.codex/skills/readme-alignment/SKILL.md` together with `scripts/Invoke-ReadmeAlignment.ps1`.

For template runtime and tooling policy updates, agents should use `.codex/skills/runtime-policy-update/SKILL.md` together with `eng/runtime-policy.json`, `scripts/Update-GeneratedMarkdown.ps1`, and `scripts/Test-VersionPolicy.ps1`.

For template version release preparation, validation, tagging, GitHub Release publishing, and cleanup, agents should use `.codex/skills/template-version-release/SKILL.md` together with `scripts/Test-TemplateVersion.ps1`.
