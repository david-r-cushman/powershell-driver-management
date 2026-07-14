# {{REPOSITORY_NAME}}

<!-- BEGIN generated:readme-powershell-badge -->
![PowerShell 7.4](https://img.shields.io/badge/PowerShell-7.4-blue)
<!-- END generated:readme-powershell-badge -->
{{TEMPLATE_VERSION_BADGE}}

{{REPOSITORY_SUMMARY}}

Quick navigation:

- [Portfolio Context](#portfolio-context)
- [Engineering Principles in Practice](#engineering-principles-in-practice)
- [Validation And Maintenance](#validation-and-maintenance)
- [Repository Structure](#repository-structure)

<!-- BEGIN generated:readme-runtime-focus -->
- PowerShell 7.4 development
<!-- END generated:readme-runtime-focus -->

## Portfolio Context

This repository is part of a PowerShell portfolio built from `pwsh-dev-template`. Customize this section to explain what this repository demonstrates, why it exists, and what a reviewer should pay attention to first.

## Engineering Principles in Practice

<!-- BEGIN generated:readme-runtime-philosophy -->
- **Deterministic Base Runtime:** The development container is built from a pinned PowerShell 7.4 on Ubuntu 22.04 base image to reduce environmental drift
<!-- END generated:readme-runtime-philosophy -->

- **Deterministic Workflows:** Prefer repeatable scripts, explicit validation, and reviewable changes over one-off manual steps
- **Small Safe Changes:** Solve the requested problem with the smallest reasonable change before introducing more structure
- **Validation First:** Use analyzer, tests, and diff review as normal delivery controls rather than optional cleanup
- **Human Accountability:** AI assistance accelerates drafting, but review and ownership remain human responsibilities

For the deeper operating model behind that approach, see [`docs/powershell-ai-operating-model.md`](docs/powershell-ai-operating-model.md). Add repository-specific decisions under [`docs/decisions/`](docs/decisions/) when durable implementation choices need to be explained.

## Use This Repository

1. Replace the placeholder summary near the top of this README with a repository-specific description.
2. Update `Portfolio Context` so readers understand the goal, scope, and value of the repository.
3. Add repository-specific implementation under `src/`.
4. Add repository-specific tests under `tests/`.
5. Review `AGENTS.md` and `.github/copilot-instructions.md` before using AI-generated changes.

## Runtime And Environment

<!-- BEGIN generated:readme-runtime-stack -->
- **Runtime:** PowerShell 7.4.x (LTS) on Ubuntu 22.04
<!-- END generated:readme-runtime-stack -->

- **Development Modes:** Local VS Code, Docker Dev Containers, and GitHub Codespaces
- **Isolation Strategy:** Use the container to reduce host tooling and credential exposure during development work
- **Environment Ownership:** Customize runtime details when the repository intentionally diverges from the template baseline

## Tooling

<!-- BEGIN generated:readme-tooling-list -->
- **Pester 6.0.0:** For unit and integration testing
- **PSScriptAnalyzer 1.25.0:** To enforce PowerShell best practices and security rules
- **Azure CLI:** Pre-installed for cloud resource management
- **PSReadLine 2.4.5:** Configured for a more efficient terminal experience
<!-- END generated:readme-tooling-list -->

When runtime or tooling versions are updated, keep `eng/runtime-policy.json`, generated Markdown, and validation scripts aligned.

## Repository Structure

- `src/`: repository implementation
- `tests/`: Pester tests and test helpers
- `scripts/`: validation, maintenance, and workflow entrypoints
- `docs/`: operating model, decisions, and supporting documentation
- `templates/`: reusable scaffolds and template-owned starter assets

## Validation And Maintenance

Run the standard repository checks before committing meaningful changes:

```powershell
pwsh -NoProfile -File ./scripts/Invoke-RepoChecks.ps1
```

If this repository keeps the template-managed generated Markdown blocks, refresh or validate them through:

```powershell
pwsh -NoProfile -File ./scripts/Update-GeneratedMarkdown.ps1 -Check
```

## Downstream Guidance Sync

Use `.codex/skills/downstream-guidance-sync/SKILL.md` with `scripts/Invoke-TemplateGuidanceSync.ps1` when you want to adopt newer template guidance or README workflow assets from `pwsh-dev-template` without overwriting repository-owned implementation.

## Prerequisites And Setup

- Install PowerShell 7.4 or use the repository Dev Container / Codespace baseline.
- Install pinned modules for local validation when they are not already available.
- Review `docs/agent-workflows.md` for repo-local workflow entrypoints before asking an agent to make changes.

## Template Versioning

The template version badge tracks inherited guidance and workflow baseline alignment. It does not mean this repository remains fully identical to the source template. Customize this section if you need to explain intentional divergence from the parent template.
