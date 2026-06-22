# AI Coding Instructions For This Repository

## AI Governance Model

This repository follows a structured AI governance model:

- `/docs/ai-behavioral-contract.md`
- `/docs/ai-interaction-loop.md`

Those documents are the canonical source for broad AI behavior, human accountability, and the interaction workflow used to evaluate AI output.

This file translates that model into enforceable repository rules for generated code, tests, reviews, automation, documentation, and commit messages.

---

This repository is a GitHub template for PowerShell projects. Use these instructions for authored PowerShell project code, tests, automation, pull request review comments, and documentation. Do not use these instructions for container bootstrap behavior, editor configuration, or environment initialization unless this file, `README.md`, `/docs`, or the task-specific template explicitly includes that area.

When examples in `/examples`, `/templates`, `/docs`, `README.md`, or comment-based help differ from this file, this file wins unless `README.md` or `/docs/EXCEPTIONS.md` documents a maintainer-approved exception. PowerShell version requirements are resolved by the rule in `PowerShell Compatibility`.

## Conflict Handling

Resolve conflicts in this order:

1. Safety and security.
2. Deterministic automation behavior.
3. Documented PowerShell version and supported platforms.
4. Repository conventions and closest matching template.
5. User preference.

- Ask the user or maintainer for clarification when a prompt is too ambiguous for a safe implementation.
- If clarification is unavailable, make the assumption that requires the least deviation from this file and state it.
- Do not resolve ambiguity by guessing. State assumptions explicitly when required.
- Briefly explain any decision that rejects compatibility, convention, template guidance, or user preference.

## Simplicity And Complexity Management

Code is a liability. Every line of code adds maintenance cost, testing requirements, and potential failure modes.

When generating code:

- Prefer the simplest solution that safely satisfies the requirement.
- Prefer native PowerShell features and standard language capabilities over additional abstractions, wrappers, frameworks, or dependencies.
- Do not introduce helper functions, classes, configuration layers, design patterns, or reusable abstractions unless they provide clear value for the stated requirement.
- Optimize for readability and maintainability over cleverness or theoretical extensibility.
- Keep the happy path easy to follow.
- Apply error handling and validation where risk exists, but avoid unnecessary defensive code that obscures intent.
- When modifying existing code, solve the requested problem with the smallest reasonable change and avoid unrelated refactoring.
- Do not create future-proofing, scalability mechanisms or architectural layers unless explicitly requested or clearly justified by the requirement.

When multiple valid implementations exist, prefer the solution with the lowest operational and cognitive complexity.

## Generation Checklist

For new or changed PowerShell code, prefer this checklist over adding one-off patterns:

- Function shape: use production-quality advanced functions with `CmdletBinding()`, a `param()` block, approved verbs, PascalCase parameters, clear names, and small composable public functions.
- State and output: add `SupportsShouldProcess` for mutations, wrap only the mutation, and return structured objects rather than display-formatted text.
- Errors and security: use terminating errors with useful context, avoid undocumented `Write-Host`, validate external input, and never hardcode or log secrets, credentials, tenant IDs, or tokens.
- Tests and help: include comment-based help for public functions and focused Pester tests that mock file I/O, network calls, service calls, time, and environment access.
- Verifiable output: prefer behavior and output contracts that can be tested, reviewed, or validated.

## Repository Structure And Templates

Place source code in `/src`, tests in `/tests`, docs in `/docs`, and examples in `/examples` unless an existing project structure clearly uses another convention. Do not place executable business logic in the repository root or at module import time, except for required dependency loading, configuration setup, or module initialization.

Start from the closest matching template in `/templates` when it fits the task:

- `/templates/functions/read-only-function-template.ps1`
- `/templates/functions/state-changing-function-template.ps1`
- `/templates/patterns/retry-pattern-template.ps1`
- `/templates/tests/read-only-function-tests-template.ps1`
- `/templates/tests/state-changing-function-tests-template.ps1`
- `/templates/module/ModuleName/ModuleName.psd1`
- `/templates/module/ModuleName/ModuleName.psm1`
- `/templates/scripts/advanced-script-template.ps1`

If multiple templates apply or conflict, choose in this order: state-changing function, read-only function, tests, retry pattern, module, script. Document deviations from any template considered for the task. If no applicable template exists, follow clear repository conventions. If no applicable template exists and conventions are unclear, ask for maintainer guidance; when guidance is unavailable, base the implementation on the most similar existing code and document the reasoning for that choice.

## Repo-Local Skills

Repo-local Codex skills are stored under `.codex/skills/`. When asked to synchronize downstream AI guidance, use `.codex/skills/downstream-guidance-sync/SKILL.md` and operate `scripts/Invoke-TemplateGuidanceSync.ps1` through the documented audit, branch, validation, commit, and pull request workflow. Do not manually edit downstream guidance files outside the sync script allowlist unless the user explicitly asks for manual repair after a script failure.

When asked to update the template runtime, Ubuntu image, GitHub Actions runner, or pinned PowerShell tooling, use `.codex/skills/runtime-policy-update/SKILL.md`. Treat `eng/runtime-policy.json` as the source of truth, use `scripts/Update-GeneratedMarkdown.ps1` for generated Markdown blocks, and validate with `scripts/Test-VersionPolicy.ps1`.

When asked to prepare, validate, tag, publish, or clean up a template release version, use `.codex/skills/template-version-release/SKILL.md`. Keep `VERSION`, the README template-version badge, and `CHANGELOG.md` aligned, validate with `scripts/Test-TemplateVersion.ps1`, and create annotated `vX.Y.Z` tags plus GitHub Releases only after the release PR is merged to `main`.

When adding or updating repo-local skills, add or update Pester coverage in `tests/unit/SkillScaffold.Tests.ps1` for the skill file, metadata, required references, and agent discoverability. The Codex `quick_validate.py` helper may be used as an optional authoring check, but Pester is the repository validation standard.

## PowerShell Compatibility

Target PowerShell 7.4.x unless `README.md`, `/docs`, or the task-specific template declares another version under `PowerShell Version`, `Requirements`, or `Compatibility`. For version conflicts, use this precedence: `README.md`, then `/docs`, then task-specific template. If version requirements are missing, invalid, outdated, or unsupported, provide a PowerShell 7.4.x-compatible fallback and document the assumption.

Avoid syntax, APIs, cmdlets, or modules that conflict with the supported PowerShell version or platform support. Prefer cross-platform approaches; when platform-specific behavior is required, isolate it with `$IsWindows`, `$IsLinux`, or `$IsMacOS`, and test or explicitly mock/skip each supported path.

Avoid deprecated cmdlets, modules, and features. If deprecated behavior is unavoidable, isolate it, add a nearby warning comment, justify the limitation, and include a supported alternative, workaround, or future migration note when one exists.

## External Services

Prefer the Microsoft Graph PowerShell SDK over raw REST calls when the SDK provides equivalent functionality for the required operation. If raw REST is required, document why.

Do not invent external service behavior, cmdlets, parameters, or API contracts. When service behavior is uncertain, provide a way to verify it before relying on it.

Wrap external service interactions in helper functions when it improves consistency, mocking, or testability. Generated external-service code must support unit tests without live service calls.

Apply the deprecation guidance in `PowerShell Compatibility` to external service modules and service-specific cmdlets. Keep unavoidable deprecated service interactions behind helper functions and document the migration path or limitation.

## Formatting And Review

Use 4 spaces for PowerShell indentation, same-line opening braces, single quotes unless interpolation is required, comments above the code they describe, no trailing whitespace, and LF line endings.

When editing text files, preserve the file's existing line-ending behavior and avoid CRLF/LF-sensitive string replacements, especially in Markdown and documentation files. Prefer line-based or parser-aware edits when practical. Before committing text-file changes, run `git diff --check` and fix extra blank lines at EOF, missing expected blank lines, and trailing whitespace.

In review, flag missing tests, missing comment-based help, analyzer violations, weak validation, missing `ShouldProcess`, unsafe secret handling, unmockable external calls, unstable output contracts, unverified claims, and speculative refactors outside the requested scope.

Unless explicitly requested and justified, do not generate `Invoke-Expression`, empty catch blocks, plaintext secret handling, hardcoded credentials, live external service calls in tests, silent breaking changes, or unrelated formatting-only refactors.

## Commit Messages

When asked to generate, review, or revise commit messages, use the Conventional Commits format:

```Markdown

<type>[optional scope]: <description>

[optional body]

[optional footer(s)]

```

Prefer these commit types unless the repository documents another standard:

- `feat`: new user-facing or maintainer-facing functionality
- `fix`: bug fixes or corrected behavior
- `docs`: documentation-only changes
- `test`: adding or updating tests
- `refactor`: code restructuring that does not change behavior
- `style`: formatting, whitespace, or other non-behavioral style changes
- `ci`: CI workflow or automation changes
- `build`: build system, packaging, or dependency changes
- `chore`: maintenance changes that do not fit another type

Use a concise, imperative, lowercase description without a trailing period.

Prefer a scoped commit when it improves clarity, for example:

- feat(templates): add state-changing function scaffold
- fix(tests): mock filesystem access in module tests
- docs(copilot): add simplicity guidance
- ci(pester): run tests on pull requests

Use `!` after the type or scope for breaking changes:

feat(module)!: require PowerShell 7.4

Include a footer beginning with `BREAKING CHANGE:` when the change breaks existing behavior.

Generate commit messages from the actual change being made. Avoid generic descriptions such as "update code", "fix issue", "changes", or "improvements".

Do not invent commit details that are not supported by the diff, staged changes, or user-provided context. If the change is ambiguous, provide the best commit message candidate and briefly state the assumption.
