# Architecture Decision Records

This directory captures durable template decisions that future maintainers should be able to understand without reconstructing pull request discussion.

ADRs are not required for routine documentation updates, patch fixes, release metadata updates, or implementation plans that are fully explained by the pull request. Use a decision record when a change introduces or changes a durable template capability, workflow policy, ownership boundary, or non-obvious tradeoff.

Good ADR candidates include decisions that affect:

- downstream repositories created from this template
- AI-assisted development workflow or governance
- validation and CI expectations
- runtime or tooling policy
- template release policy
- ownership boundaries between the template and downstream projects

## Format

Use a short, numbered Markdown file with this structure:

```markdown
# 0001 - Decision Title

## Status

Accepted

## Context

## Decision

## Alternatives Considered

## Consequences
```

Keep ADRs brief and outcome-focused. They should explain durable reasoning, not replay every implementation step.
