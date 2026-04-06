# GitHub Copilot Instructions Reference

This file is a quick reference for maintaining GitHub Copilot instructions in this repository.

## Repository-Wide Instructions

`/.github/copilot-instructions.md` is the repository-wide instruction file.

Use it for guidance that should apply broadly across the repository, such as:

- PowerShell coding expectations
- testing expectations
- review expectations
- security and safety defaults

## Additional Instruction Files

The `/.github/Instructions/` folder can be used for narrower instruction files when you want Copilot guidance that is more specific than the repository-wide defaults.

These files are useful for topic-specific or context-specific guidance, such as:

- Pester-specific conventions
- module-structure guidance
- documentation conventions
- workflow-specific expectations

## When To Add Another Instruction File

Add another file in this folder when:

- the guidance is too narrow to belong in `copilot-instructions.md`
- the guidance applies only to a certain kind of work
- keeping it separate will make the main instruction file easier to maintain

Do not create extra files just to restate the same rules in different places.

## Suggested Naming

Use descriptive names that make the file's purpose obvious.

Examples:

- `pester.instructions.md`
- `module-structure.instructions.md`
- `documentation.instructions.md`
- `governance.instructions.md`

## Maintenance Notes

- Keep repository-wide rules in `copilot-instructions.md`.
- Use files in `/.github/Instructions/` only when the narrower scope is helpful.
- If a helper file stops being useful, remove it instead of letting it drift.

## Reference

For the current GitHub behavior and supported instruction patterns, review the official GitHub Docs page on adding repository custom instructions for GitHub Copilot.
