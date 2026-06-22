# GitHub Copilot Instructions Reference

This document explains how to maintain the repository-wide Copilot instructions without duplicating the canonical instruction file.

## Canonical Instruction File

The active repository-wide instructions live at:

- `/.github/copilot-instructions.md`

That file is the source of truth for Copilot generation and review behavior in repositories created from this template.

Do not copy the full instruction text into this reference document. Keeping one canonical file reduces drift and makes the applied rules easier to audit.

## Governance Relationship

The Copilot instructions translate the broader AI governance model into concrete repository behavior.

Related governance documents:

- `/docs/ai-behavioral-contract.md`
- `/docs/ai-interaction-loop.md`
- `/docs/powershell-ai-operating-model.md`

Use those documents for rationale and operating model guidance. Use `/.github/copilot-instructions.md` for enforceable generation constraints.

## When To Update Copilot Instructions

Update `/.github/copilot-instructions.md` when the template changes in a way that should affect generated code, tests, reviews, or documentation.

Common reasons include:

- changing the preferred source, test, or template folder structure
- adding or removing reusable templates
- changing PowerShell version support
- changing validation, testing, or security expectations
- adding a new recurring pattern that downstream repositories should inherit

Do not update it for one-off project preferences that belong only in a downstream repository.

## Maintenance Checklist

Before changing the Copilot instructions:

1. Confirm the rule should apply broadly to repositories created from this template.
2. Check that the rule does not conflict with `README.md`, `templates/`, or validation configuration.
3. Keep the language direct and enforceable.
4. Prefer one clear rule over several overlapping rules.
5. Run repo checks after changes:

   ```powershell
   pwsh -NoProfile -File ./scripts/Invoke-RepoChecks.ps1 -IncludeTemplates
   ```

## Additional Instruction Files

Use `/.github/Instructions/` only for narrower guidance that should not live in the repository-wide instruction file.

Good candidates:

- Pester-specific conventions
- module-structure guidance
- documentation conventions
- workflow-specific expectations

Avoid extra instruction files that restate the same rules in different places.
