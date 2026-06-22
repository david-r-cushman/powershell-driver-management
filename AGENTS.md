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

For downstream AI guidance synchronization, agents should use `.codex/skills/downstream-guidance-sync/SKILL.md` together with `scripts/Invoke-TemplateGuidanceSync.ps1` instead of manually copying guidance files.

For template runtime and tooling policy updates, agents should use `.codex/skills/runtime-policy-update/SKILL.md` together with `eng/runtime-policy.json`, `scripts/Update-GeneratedMarkdown.ps1`, and `scripts/Test-VersionPolicy.ps1`.

For template version release preparation, validation, tagging, GitHub Release publishing, and cleanup, agents should use `.codex/skills/template-version-release/SKILL.md` together with `scripts/Test-TemplateVersion.ps1`.
